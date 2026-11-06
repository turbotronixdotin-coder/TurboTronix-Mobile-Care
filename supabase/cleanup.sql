-- TurboTronix Mobile Care cleanup
-- Run in the Supabase project's SQL Editor.
-- This removes only objects created by this project, but it is destructive and cannot be undone.

begin;

-- Remove auth trigger before deleting its function.
drop trigger if exists on_auth_user_created on auth.users;

-- Delete project files before removing storage buckets.
delete from storage.objects where bucket_id in (
  'booking-photos', 'repair-photos', 'invoices', 'product-images'
);
delete from storage.buckets where id in (
  'booking-photos', 'repair-photos', 'invoices', 'product-images'
);

-- Drop project tables. Dependants are removed first through CASCADE.
drop table if exists public.warranty_claims cascade;
drop table if exists public.warranties cascade;
drop table if exists public.refunds cascade;
drop table if exists public.expenses cascade;
drop table if exists public.invoices cascade;
drop table if exists public.payments cascade;
drop table if exists public.booking_photos cascade;
drop table if exists public.repair_images cascade;
drop table if exists public.repair_notes cascade;
drop table if exists public.repair_parts cascade;
drop table if exists public.repairs cascade;
drop table if exists public.booking_items cascade;
drop table if exists public.bookings cascade;
drop table if exists public.purchase_order_items cascade;
drop table if exists public.purchase_orders cascade;
drop table if exists public.stock_movements cascade;
drop table if exists public.inventory cascade;
drop table if exists public.suppliers cascade;
drop table if exists public.model_service_prices cascade;
drop table if exists public.part_compatibility cascade;
drop table if exists public.spare_parts cascade;
drop table if exists public.model_services cascade;
drop table if exists public.repair_services cascade;
drop table if exists public.repair_categories cascade;
drop table if exists public.mobile_models cascade;
drop table if exists public.mobile_brands cascade;
drop table if exists public.technicians cascade;
drop table if exists public.customer_addresses cascade;
drop table if exists public.notifications cascade;
drop table if exists public.business_settings cascade;
drop table if exists public.service_areas cascade;
drop table if exists public.service_slots cascade;
drop table if exists public.profiles cascade;

-- Remove project functions and triggers created by the migrations.
drop function if exists public.handle_new_user() cascade;
drop function if exists public.current_app_role() cascade;
drop function if exists public.is_owner_or_staff() cascade;
drop function if exists public.next_booking_number() cascade;
drop function if exists public.create_booking_atomic(uuid,uuid,text,text,text,uuid,timestamptz) cascade;
drop function if exists public.consume_repair_part(uuid,uuid,integer) cascade;
drop function if exists public.adjust_stock(uuid,integer,text,boolean) cascade;
drop function if exists public.protect_profile_role() cascade;
drop function if exists public.create_spare_part_inventory() cascade;

drop sequence if exists public.booking_number_seq cascade;
drop type if exists public.booking_service_status cascade;
drop type if exists public.booking_status cascade;
drop type if exists public.app_role cascade;

commit;
