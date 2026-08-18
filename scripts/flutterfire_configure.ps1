# Gera google-services.json, GoogleService-Info.plist e lib/firebase_options.dart
# Pre-requisito: firebase login (conta com acesso ao projeto opadocaexpress-c3810)
#
#   dart pub global activate flutterfire_cli
#   firebase login
#   powershell -File scripts/flutterfire_configure.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

dart pub global activate flutterfire_cli
flutterfire configure `
  --project=opadocaexpress-c3810 `
  --platforms=android,ios,web `
  --yes `
  --android-package-name=com.opadocaexpress.app `
  --ios-bundle-id=com.opadocaexpress.app
