# Atualiza ASAAS_API_KEY da Edge Function (conta master sandbox).
# Nao imprime a chave.
#
# Uso:
#   $env:ASAAS_API_KEY = '$aact_hmlg_...'
#   powershell -File scripts/set_asaas_secrets.ps1

$ErrorActionPreference = 'Stop'
$key = $env:ASAAS_API_KEY
if (-not $key) { throw 'Defina ASAAS_API_KEY (sandbox, prefixo $aact_hmlg_)' }
if (-not $key.StartsWith('$aact_hmlg_')) {
  throw 'A chave precisa ser de sandbox e comecar com $aact_hmlg_'
}

npx --yes supabase secrets set --project-ref blibxmylxcrztfhvllkj `
  "ASAAS_BASE_URL=https://api-sandbox.asaas.com/v3" `
  "ASAAS_API_KEY=$key"

Write-Output 'Secret ASAAS_API_KEY atualizado. Tente o Pix de novo (nao precisa rebuild).'
