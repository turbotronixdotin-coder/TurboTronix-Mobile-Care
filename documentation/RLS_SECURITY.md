# RLS Security Checklist
- Enable RLS on every exposed table.
- Never permit self-service role escalation.
- Verify customer ownership for every booking, payment, invoice and warranty.
- Restrict technician access to assigned jobs only.
- Keep provider secrets and service-role keys server-side.
- Test policies using customer, technician, staff and owner test accounts.
- Review storage bucket policies separately; database RLS does not secure Storage objects automatically.
