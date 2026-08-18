# Define os secrets da Edge Function processar-notificacoes-fila.
# Nao commite os valores. Obtenha ONESIGNAL_REST_API_KEY em OneSignal > Settings > Keys & IDs.
# PUSH_WORKER_SECRET deve ser o mesmo valor gravado no Vault (nome: push_worker_secret).
#
# Uso:
#   $env:ONESIGNAL_REST_API_KEY = 'os_v2_...'
#   $env:PUSH_WORKER_SECRET = '...'
#   powershell -File scripts/set_push_secrets.ps1

$ErrorActionPreference = 'Stop'
if (-not $env:ONESIGNAL_REST_API_KEY) { throw 'Defina ONESIGNAL_REST_API_KEY' }
if (-not $env:PUSH_WORKER_SECRET) { throw 'Defina PUSH_WORKER_SECRET' }

npx --yes supabase secrets set --project-ref blibxmylxcrztfhvllkj `
  "ONESIGNAL_APP_ID=6eb88ea6-38cf-4df3-bab5-76beb7e7580d" `
  "ONESIGNAL_REST_API_KEY=$env:ONESIGNAL_REST_API_KEY" `
  "PUSH_WORKER_SECRET=$env:PUSH_WORKER_SECRET"
