import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const auth = req.headers.get('Authorization');
  if (!auth) return new Response('Unauthorized', { status: 401 });
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return new Response('Unauthorized', { status: 401 });
  const input = await req.json();
  const required = ['model_id','service_id','device_issue','appointment_at'];
  if (required.some((key) => !input[key])) return new Response('Missing booking fields', { status: 400 });
  if (input.device_issue.length > 2000) return new Response('Issue is too long', { status: 400 });
  const { data, error } = await supabase.rpc('create_booking_atomic', {
    p_model_id: input.model_id, p_service_id: input.service_id, p_quality: input.quality ?? '',
    p_device_issue: input.device_issue, p_customer_notes: input.customer_notes ?? '',
    p_address_id: input.address_id ?? null, p_appointment_at: input.appointment_at,
  });
  if (error) return new Response(error.message, { status: 400 });
  return new Response(JSON.stringify(data), { headers: { 'Content-Type': 'application/json' }, status: 201 });
});
