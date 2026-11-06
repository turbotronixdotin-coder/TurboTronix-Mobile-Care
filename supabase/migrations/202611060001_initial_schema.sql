-- TurboTronix Mobile Care initial schema.
-- Apply to a fresh Supabase project. Review policies before production launch.
create extension if not exists pgcrypto;

create type public.app_role as enum ('customer','owner','technician','staff');
create type public.booking_status as enum (
  'requested','accepted','technician_assigned','on_the_way','inspecting',
  'awaiting_approval','in_progress','quality_check','completed','cancelled'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  role public.app_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  label text,
  address_line text not null,
  city text not null,
  state text not null default 'Telangana',
  pincode text not null,
  latitude numeric(10,7),
  longitude numeric(10,7),
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.technicians (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  active boolean not null default true,
  joining_date date not null default current_date
);

create table public.mobile_brands (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  logo_url text,
  active boolean not null default true
);

create table public.mobile_models (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid not null references public.mobile_brands(id),
  model_name text not null,
  model_number text,
  image_url text,
  active boolean not null default true,
  unique (brand_id, model_name)
);

create table public.repair_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text
);

create table public.repair_services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.repair_categories(id),
  name text not null,
  description text,
  active boolean not null default true
);

create table public.model_services (
  id uuid primary key default gen_random_uuid(),
  model_id uuid not null references public.mobile_models(id),
  service_id uuid not null references public.repair_services(id),
  estimated_labour numeric(12,2) not null default 0 check (estimated_labour >= 0),
  active boolean not null default true,
  unique(model_id, service_id)
);

create table public.spare_parts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  quality_grade text,
  sku text unique,
  purchase_price numeric(12,2) not null default 0 check (purchase_price >= 0),
  selling_price numeric(12,2) not null default 0 check (selling_price >= 0),
  warranty_days integer not null default 0 check (warranty_days >= 0),
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.part_compatibility (
  id uuid primary key default gen_random_uuid(),
  part_id uuid not null references public.spare_parts(id) on delete cascade,
  model_id uuid not null references public.mobile_models(id) on delete cascade,
  unique(part_id, model_id)
);

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  address text,
  notes text,
  created_at timestamptz not null default now()
);

create table public.inventory (
  part_id uuid primary key references public.spare_parts(id),
  quantity integer not null default 0 check (quantity >= 0),
  minimum_stock integer not null default 1 check (minimum_stock >= 0),
  updated_at timestamptz not null default now()
);

create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  part_id uuid not null references public.spare_parts(id),
  movement_type text not null check (movement_type in ('purchase','consumed','return','adjustment')),
  quantity integer not null check (quantity > 0),
  reference text,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid references public.suppliers(id),
  status text not null default 'draft' check (status in ('draft','ordered','received','cancelled')),
  total_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create table public.purchase_order_items (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders(id) on delete cascade,
  part_id uuid not null references public.spare_parts(id),
  quantity integer not null check (quantity > 0),
  unit_cost numeric(12,2) not null check (unit_cost >= 0)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_number text not null unique,
  customer_id uuid not null references public.profiles(id),
  address_id uuid references public.customer_addresses(id),
  model_id uuid references public.mobile_models(id),
  device_issue text not null,
  customer_notes text,
  appointment_at timestamptz,
  status public.booking_status not null default 'requested',
  estimated_total numeric(12,2) not null default 0,
  final_total numeric(12,2),
  assigned_technician uuid references public.technicians(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.booking_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  service_id uuid references public.repair_services(id),
  description text not null,
  estimated_amount numeric(12,2) not null default 0,
  approved_amount numeric(12,2)
);

create table public.repairs (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id),
  technician_id uuid references public.technicians(id),
  device_condition text,
  imei_last4 text,
  diagnosis text,
  repair_status text not null default 'inspection',
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.repair_parts (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid not null references public.repairs(id) on delete cascade,
  part_id uuid not null references public.spare_parts(id),
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0)
);

create table public.repair_notes (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid not null references public.repairs(id) on delete cascade,
  note text not null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.repair_images (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid not null references public.repairs(id) on delete cascade,
  image_path text not null,
  image_stage text not null check (image_stage in ('before','after','inspection')),
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  amount numeric(12,2) not null check (amount > 0),
  method text not null check (method in ('cash','upi','online')),
  status text not null default 'pending' check (status in ('pending','success','failed','refunded')),
  provider_reference text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id),
  invoice_number text not null unique,
  subtotal numeric(12,2) not null,
  tax_amount numeric(12,2) not null default 0,
  total numeric(12,2) not null,
  document_path text,
  issued_at timestamptz not null default now()
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  description text,
  amount numeric(12,2) not null check (amount >= 0),
  spent_on date not null default current_date,
  created_by uuid references public.profiles(id)
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id),
  amount numeric(12,2) not null check (amount > 0),
  status text not null default 'requested',
  reason text,
  created_at timestamptz not null default now()
);

create table public.warranties (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid not null references public.repairs(id),
  customer_id uuid not null references public.profiles(id),
  part_id uuid references public.spare_parts(id),
  warranty_number text not null unique,
  starts_on date not null,
  expires_on date not null,
  terms text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  check (expires_on >= starts_on)
);

create table public.warranty_claims (
  id uuid primary key default gen_random_uuid(),
  warranty_id uuid not null references public.warranties(id),
  description text not null,
  status text not null default 'submitted',
  resolution text,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.business_settings (
  id integer primary key default 1 check (id = 1),
  business_name text not null default 'TurboTronix Mobile Care',
  phone text,
  email text,
  address text,
  currency text not null default 'INR',
  updated_at timestamptz not null default now()
);

create table public.service_areas (
  id uuid primary key default gen_random_uuid(),
  city text not null,
  pincode text not null,
  active boolean not null default true,
  unique(city, pincode)
);

create table public.service_slots (
  id uuid primary key default gen_random_uuid(),
  weekday smallint check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  active boolean not null default true,
  check (end_time > start_time)
);

create index bookings_customer_idx on public.bookings(customer_id, created_at desc);
create index bookings_status_idx on public.bookings(status);
create index mobile_models_brand_idx on public.mobile_models(brand_id);
create index stock_movements_part_idx on public.stock_movements(part_id, created_at desc);
create index notifications_user_idx on public.notifications(user_id, created_at desc);

-- Helper functions. Role assignment must be performed by a trusted admin process.
create or replace function public.current_app_role()
returns public.app_role
language sql stable security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_owner_or_staff()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce(public.current_app_role() in ('owner','staff'), false)
$$;

alter table public.profiles enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.technicians enable row level security;
alter table public.mobile_brands enable row level security;
alter table public.mobile_models enable row level security;
alter table public.repair_categories enable row level security;
alter table public.repair_services enable row level security;
alter table public.model_services enable row level security;
alter table public.spare_parts enable row level security;
alter table public.part_compatibility enable row level security;
alter table public.suppliers enable row level security;
alter table public.inventory enable row level security;
alter table public.stock_movements enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.purchase_order_items enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_items enable row level security;
alter table public.repairs enable row level security;
alter table public.repair_parts enable row level security;
alter table public.repair_notes enable row level security;
alter table public.repair_images enable row level security;
alter table public.payments enable row level security;
alter table public.invoices enable row level security;
alter table public.expenses enable row level security;
alter table public.refunds enable row level security;
alter table public.warranties enable row level security;
alter table public.warranty_claims enable row level security;
alter table public.notifications enable row level security;
alter table public.business_settings enable row level security;
alter table public.service_areas enable row level security;
alter table public.service_slots enable row level security;

-- Profile: user can read/update own basic profile; owner can read all.
create policy "profile read own or owner" on public.profiles for select
using (id = auth.uid() or public.current_app_role() = 'owner');
create policy "profile update own" on public.profiles for update
using (id = auth.uid()) with check (id = auth.uid());

-- Public catalogue read; only owner manages catalogue/prices.
create policy "active brands readable" on public.mobile_brands for select using (active or public.is_owner_or_staff());
create policy "active models readable" on public.mobile_models for select using (active or public.is_owner_or_staff());
create policy "categories readable" on public.repair_categories for select using (true);
create policy "services readable" on public.repair_services for select using (active or public.is_owner_or_staff());
create policy "model services readable" on public.model_services for select using (active or public.is_owner_or_staff());
create policy "parts visible to owner staff" on public.spare_parts for select using (public.is_owner_or_staff());
create policy "compatibility visible to owner staff" on public.part_compatibility for select using (public.is_owner_or_staff());
create policy "inventory visible to owner staff" on public.inventory for select using (public.is_owner_or_staff());

-- Customer-owned records and owner access.
create policy "addresses own or owner" on public.customer_addresses for all
using (customer_id = auth.uid() or public.is_owner_or_staff())
with check (customer_id = auth.uid() or public.is_owner_or_staff());

create policy "bookings customer or owner" on public.bookings for select
using (customer_id = auth.uid() or public.is_owner_or_staff());
create policy "customer can create booking" on public.bookings for insert
with check (customer_id = auth.uid());
create policy "owner updates bookings" on public.bookings for update
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());

create policy "booking items via booking" on public.booking_items for select
using (exists(select 1 from public.bookings b where b.id = booking_id and (b.customer_id = auth.uid() or public.is_owner_or_staff())));
create policy "booking items create own" on public.booking_items for insert
with check (exists(select 1 from public.bookings b where b.id = booking_id and b.customer_id = auth.uid()));

create policy "technician own record or owner" on public.technicians for select
using (profile_id = auth.uid() or public.is_owner_or_staff());
create policy "repairs customer technician owner" on public.repairs for select
using (
 public.is_owner_or_staff()
 or technician_id in (select id from public.technicians where profile_id = auth.uid())
 or exists(select 1 from public.bookings b where b.id = booking_id and b.customer_id = auth.uid())
);
create policy "owner manages repairs" on public.repairs for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());

create policy "repair parts customer owner" on public.repair_parts for select
using (public.is_owner_or_staff() or exists(
 select 1 from public.repairs r join public.bookings b on b.id=r.booking_id
 where r.id=repair_id and b.customer_id=auth.uid()
));
create policy "owner manages repair parts" on public.repair_parts for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());

create policy "repair notes owner or assigned technician" on public.repair_notes for select
using (public.is_owner_or_staff() or created_by=auth.uid());
create policy "owner inserts repair notes" on public.repair_notes for insert
with check (public.is_owner_or_staff() or created_by=auth.uid());

create policy "repair images customer owner" on public.repair_images for select
using (public.is_owner_or_staff() or exists(
 select 1 from public.repairs r join public.bookings b on b.id=r.booking_id
 where r.id=repair_id and b.customer_id=auth.uid()
));
create policy "owner manages repair images" on public.repair_images for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());

create policy "payments own or owner" on public.payments for select
using (public.is_owner_or_staff() or exists(select 1 from public.bookings b where b.id=booking_id and b.customer_id=auth.uid()));
create policy "invoices own or owner" on public.invoices for select
using (public.is_owner_or_staff() or exists(select 1 from public.bookings b where b.id=booking_id and b.customer_id=auth.uid()));
create policy "warranties own or owner" on public.warranties for select
using (customer_id=auth.uid() or public.is_owner_or_staff());
create policy "claims own or owner" on public.warranty_claims for select
using (public.is_owner_or_staff() or exists(select 1 from public.warranties w where w.id=warranty_id and w.customer_id=auth.uid()));
create policy "customer submits claim" on public.warranty_claims for insert
with check (exists(select 1 from public.warranties w where w.id=warranty_id and w.customer_id=auth.uid()));

create policy "notifications own or owner" on public.notifications for select
using (user_id=auth.uid() or public.is_owner_or_staff());
create policy "notification update own" on public.notifications for update
using (user_id=auth.uid()) with check (user_id=auth.uid());

-- Owner/staff-only operational tables.
create policy "owner staff manages suppliers" on public.suppliers for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());
create policy "owner staff manages stock movements" on public.stock_movements for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());
create policy "owner staff manages purchase orders" on public.purchase_orders for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());
create policy "owner staff manages purchase items" on public.purchase_order_items for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());
create policy "owner staff manages expenses" on public.expenses for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());
create policy "owner staff manages refunds" on public.refunds for all
using (public.is_owner_or_staff()) with check (public.is_owner_or_staff());
create policy "business settings readable" on public.business_settings for select using (true);
create policy "owner manages settings" on public.business_settings for all
using (public.current_app_role()='owner') with check (public.current_app_role()='owner');
create policy "service areas readable" on public.service_areas for select using (active or public.is_owner_or_staff());
create policy "service slots readable" on public.service_slots for select using (active or public.is_owner_or_staff());

-- NOTE: This starter intentionally does not grant users permission to set their own role.
-- Create owner/technician profiles through a trusted dashboard/SQL admin process.
