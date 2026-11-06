#!/usr/bin/env bash
set -euo pipefail
# Requires Supabase CLI login and a linked project.
supabase gen types typescript --linked > customer-website/src/types/database.types.ts
