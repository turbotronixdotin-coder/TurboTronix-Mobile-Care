# TurboTronix Mobile Care

Monorepo starter for a doorstep mobile repair business:
- `customer-website/`: Next.js customer booking website
- `owner-app/`: Flutter owner/technician Android app
- `supabase/`: PostgreSQL migrations, seed data and Edge Function starter
- `shared/`: shared domain notes/types
- `documentation/`: architecture and workflow docs

## Status
Core implementation is included for the customer website, Supabase workflow backend, atomic booking and inventory functions, and Flutter owner dashboard. Configure a real Supabase project, apply migrations and seed data, then complete provider-specific payment credentials before accepting production payments.

## Prerequisites
- Node.js LTS + pnpm
- Flutter stable + Android SDK
- Supabase CLI
- A Supabase project

## Setup
1. Copy `customer-website/.env.local.example` to `customer-website/.env.local`.
2. Fill in the Supabase project URL and publishable/anon key.
3. Run the SQL migrations in `supabase/migrations/` in order, or use the Supabase CLI.
4. Website: `cd customer-website && pnpm install && pnpm dev`
5. Flutter: `cd owner-app && flutter pub get && flutter run`

Never put a Supabase `service_role`/secret key in browser or mobile app configuration. Use RLS and trusted server-side functions for privileged actions.
