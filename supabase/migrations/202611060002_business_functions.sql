-- Additional production hardening and workflow functions
create type public.booking_service_status as enum ('pending','approved','rejected');

create table if not exists public.model_service_prices (
  id uuid primary key default gen_random_uuid(),
  model_service_id uuid not null references public.model_services(id) on delete cascade,
  quality_grade text not null,
  spare_part_price numeric(12,2) not null default 0 check (spare_part_price >= 0),
  doorstep_charge numeric(12,2) not null default 0 check (doorstep_charge >= 0),
  unique(model_service_id, quality_grade)
);

create table if not exists public.booking_photos (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  storage_path text not null,
  created_at timestamptz not null default now()
);

alter table public.bookings add column if not exists door_address text;
alter table public.bookings add column if not exists service_slot text;
alter table public.bookings add column if not exists rejection_reason text;

-- Create a customer profile automatically; registration cannot choose a privileged role.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name, phone, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), coalesce(new.phone,new.raw_user_meta_data->>'phone'), 'customer')
  on conflict(id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.next_booking_number()
returns text language plpgsql as $$
declare n bigint;
begin
  select count(*) + 1 into n from public.bookings;
  return 'TTMC-' || to_char(current_date, 'YYYY') || '-' || lpad(n::text, 5, '0');
end $$;

create or replace function public.create_booking_atomic(
  p_model_id uuid,
  p_service_id uuid,
  p_quality text,
  p_device_issue text,
  p_customer_notes text,
  p_address_id uuid,
  p_appointment_at timestamptz
)
returns bookings language plpgsql security definer set search_path = public as $$
declare
  b bookings;
  ms public.model_services%rowtype;
  price public.model_service_prices%rowtype;
  total numeric(12,2);
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if coalesce(trim(p_device_issue),'') = '' then raise exception 'Device issue is required'; end if;
  if p_address_id is not null and not exists(select 1 from customer_addresses where id=p_address_id and customer_id=auth.uid()) then
    raise exception 'Invalid service address';
  end if;
  select * into ms from public.model_services where model_id=p_model_id and service_id=p_service_id and active=true;
  if ms.id is null then raise exception 'Service unavailable for this model'; end if;
  select * into price from public.model_service_prices where model_service_id=ms.id and quality_grade=p_quality;
  if price.id is null and p_quality is not null and p_quality <> '' then raise exception 'Selected part quality is unavailable'; end if;
  total := ms.estimated_labour + coalesce(price.spare_part_price,0) + coalesce(price.doorstep_charge,0);
  insert into public.bookings(customer_id,address_id,model_id,device_issue,customer_notes,appointment_at,estimated_total,booking_number)
  values(auth.uid(),p_address_id,p_model_id,p_device_issue,p_customer_notes,p_appointment_at,total,public.next_booking_number())
  returning * into b;
  insert into public.booking_items(booking_id,service_id,description,estimated_amount)
  values(b.id,p_service_id,p_quality,ms.estimated_labour + coalesce(price.spare_part_price,0) + coalesce(price.doorstep_charge,0));
  return b;
end $$;

create or replace function public.consume_repair_part(p_repair_id uuid, p_part_id uuid, p_quantity int)
returns void language plpgsql security definer set search_path=public as $$
declare v_stock int; v_role app_role;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select role into v_role from profiles where id=auth.uid();
  if v_role not in ('owner','staff') then raise exception 'Not permitted'; end if;
  if p_quantity <= 0 then raise exception 'Quantity must be positive'; end if;
  select quantity into v_stock from inventory where part_id=p_part_id for update;
  if coalesce(v_stock,0) < p_quantity then raise exception 'Insufficient stock'; end if;
  update inventory set quantity=quantity-p_quantity, updated_at=now() where part_id=p_part_id;
  insert into stock_movements(part_id,movement_type,quantity,reference,notes,created_by)
  values(p_part_id,'consumed',p_quantity,p_repair_id::text,'Consumed for repair',auth.uid());
  insert into repair_parts(repair_id,part_id,quantity,unit_price)
  select p_repair_id,p_part_id,p_quantity,selling_price from spare_parts where id=p_part_id;
end $$;

create or replace function public.adjust_stock(p_part_id uuid, p_quantity int, p_reason text, p_purchase boolean default false)
returns void language plpgsql security definer set search_path=public as $$
declare v_role app_role;
begin
  select role into v_role from profiles where id=auth.uid();
  if v_role not in ('owner','staff') then raise exception 'Not permitted'; end if;
  if coalesce(trim(p_reason),'')='' then raise exception 'Adjustment reason required'; end if;
  if p_purchase then
    update inventory set quantity=quantity+p_quantity, updated_at=now() where part_id=p_part_id;
    insert into stock_movements(part_id,movement_type,quantity,notes,created_by)
    values(p_part_id,'purchase',abs(p_quantity),p_reason,auth.uid());
  else
    if p_quantity > 0 then
      update inventory set quantity=quantity+p_quantity, updated_at=now() where part_id=p_part_id;
    else
      if (select quantity from inventory where part_id=p_part_id) < abs(p_quantity) then raise exception 'Insufficient stock'; end if;
      update inventory set quantity=quantity+p_quantity, updated_at=now() where part_id=p_part_id;
    end if;
    insert into stock_movements(part_id,movement_type,quantity,notes,created_by)
    values(p_part_id,'adjustment',abs(p_quantity),p_reason,auth.uid());
  end if;
end $$;

alter table public.booking_photos enable row level security;
create policy "booking photos own or staff" on public.booking_photos for select using(public.is_owner_or_staff() or exists(select 1 from bookings b where b.id=booking_id and b.customer_id=auth.uid()));
create policy "booking photos customer insert" on public.booking_photos for insert with check(exists(select 1 from bookings b where b.id=booking_id and b.customer_id=auth.uid()));
create policy "model prices readable" on public.model_service_prices for select using(true);

insert into storage.buckets(id,name,public) values ('booking-photos','booking-photos',false),('repair-photos','repair-photos',false),('invoices','invoices',false),('product-images','product-images',true)
on conflict(id) do nothing;

grant execute on function public.create_booking_atomic(uuid,uuid,text,text,text,uuid,timestamptz) to authenticated;
grant execute on function public.consume_repair_part(uuid,uuid,int) to authenticated;
grant execute on function public.adjust_stock(uuid,int,text,boolean) to authenticated;

create sequence if not exists public.booking_number_seq;
create or replace function public.next_booking_number()
returns text language sql volatile as $$
select 'TTMC-' || to_char(current_date, 'YYYY') || '-' || lpad(nextval('public.booking_number_seq')::text, 5, '0')
$$;

create or replace function public.protect_profile_role()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.role is distinct from old.role then
    if coalesce((select role from public.profiles where id=auth.uid()),'customer') <> 'owner' then
      raise exception 'User-managed role changes are prohibited';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role before update on public.profiles for each row execute function public.protect_profile_role();

create or replace function public.create_spare_part_inventory()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.inventory(part_id,quantity,minimum_stock) values(new.id,0,1) on conflict(part_id) do nothing;
  return new;
end $$;
drop trigger if exists create_spare_part_inventory on public.spare_parts;
create trigger create_spare_part_inventory after insert on public.spare_parts for each row execute function public.create_spare_part_inventory();
