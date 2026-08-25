# Atualiza secrets Asaas das Edge Functions (nunca no Flutter / .env do app).
# A chave NAO e impressa.
#
# Sandbox:
#   $env:ASAAS_API_KEY = '$aact_hmlg_...'
#   powershell -File scripts/set_asaas_secrets.ps1
#
# Producao:
#   $env:ASAAS_API_KEY = '$aact_prod_...'
#   $env:ASAAS_WEBHOOK_TOKEN = '...'   # opcional, rotacionar junto com o painel Asaas
#   powershell -File scripts/set_asaas_secrets.ps1 -Ambiente prod
#
# Depois:
#   1. Admin > Configuracoes > Financeiro > Testar conexao Asaas
#   2. Ligar "Pagamentos online" se estiver desligado
#   3. Testar Pix sandbox ponta a ponta
#
# Go-live (producao):
#   - Par ASAAS_API_KEY ($aact_prod_) + ASAAS_BASE_URL https://api.asaas.com/v3
#   - Webhook no painel Asaas: https://<ref>.supabase.co/functions/v1/asaas-webhook
#     token = ASAAS_WEBHOOK_TOKEN; eventos PAYMENT_* e TRANSFER_*
#   - FINANCE_WORKER_SECRET no vault (scripts/set_finance_secrets.ps1)
#   - Flag pagamentos_online_ativos = true apos health ok
#   - E2E sandbox antes de virar a chave: Pix, cartao, cancelamento/estorno, entrega/repasse

param(
  [ValidateSet('sandbox', 'prod')]
  [string]$Ambiente = ''
)

$ErrorActionPreference = 'Stop'
$key = $env:ASAAS_API_KEY
if (-not $key) { throw 'Defina ASAAS_API_KEY (nunca commitar).' }

$detected = if ($key.StartsWith('$aact_prod_')) { 'prod' }
  elseif ($key.StartsWith('$aact_hmlg_')) { 'sandbox' }
  else { '' }

if (-not $Ambiente) { $Ambiente = $detected }
if (-not $Ambiente) {
  throw 'Chave deve comecar com $aact_hmlg_ (sandbox) ou $aact_prod_ (producao). No PowerShell use aspas simples para preservar o $.'
}
if ($detected -and $detected -ne $Ambiente) {
  throw "A chave parece de $detected, mas -Ambiente e $Ambiente. Use o par correto chave + URL."
}

$baseUrl = if ($Ambiente -eq 'prod') {
  'https://api.asaas.com/v3'
} else {
  'https://api-sandbox.asaas.com/v3'
}

$projectRef = if ($env:SUPABASE_PROJECT_REF) { $env:SUPABASE_PROJECT_REF } else { 'blibxmylxcrztfhvllkj' }

$secretArgs = @(
  "ASAAS_BASE_URL=$baseUrl",
  "ASAAS_API_KEY=$key"
)
if ($env:ASAAS_WEBHOOK_TOKEN) {
  $secretArgs += "ASAAS_WEBHOOK_TOKEN=$($env:ASAAS_WEBHOOK_TOKEN)"
}

npx --yes supabase secrets set --project-ref $projectRef @secretArgs

Write-Output "Secrets Asaas atualizados ($Ambiente). Sem rebuild do app. Valide com asaas-health no admin."
