# Define FINANCE_WORKER_SECRET da Edge Function asaas-liberar-repasse-pedido / asaas-estornar-pagamento.
# Deve ser o mesmo valor gravado no Vault (nome: finance_worker_secret).
#
# Uso:
#   $env:FINANCE_WORKER_SECRET = '...'
#   powershell -File scripts/set_finance_secrets.ps1

$ErrorActionPreference = 'Stop'
if (-not $env:FINANCE_WORKER_SECRET) { throw 'Defina FINANCE_WORKER_SECRET' }

npx --yes supabase secrets set --project-ref blibxmylxcrztfhvllkj `
  "FINANCE_WORKER_SECRET=$env:FINANCE_WORKER_SECRET"
