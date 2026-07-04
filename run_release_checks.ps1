$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host '=============================================='
Write-Host 'SaneApp - Release Checks'
Write-Host '=============================================='

function Invoke-Step {
  param(
    [string]$Name,
    [string[]]$Command
  )

  Write-Host "`n$Name"
  & .\flutterw.ps1 @Command
  if ($LASTEXITCODE -ne 0) {
    throw "Fallo: $Name"
  }
}

function Invoke-NodeStep {
  param(
    [string]$Name,
    [string]$WorkingDirectory,
    [string[]]$Command
  )

  Write-Host "`n$Name"
  Push-Location $WorkingDirectory
  try {
    & $Command[0] $Command[1..($Command.Length - 1)]
    if ($LASTEXITCODE -ne 0) {
      throw "Fallo: $Name"
    }
  }
  finally {
    Pop-Location
  }
}

Invoke-Step '[1/4] Flutter pub get' @('pub', 'get')
Invoke-Step '[2/4] Flutter analyze (codigo principal)' @('analyze', '--no-fatal-infos', '--no-fatal-warnings', 'lib', 'test')
Invoke-Step '[3/4] Unit tests estables' @('test', 'test/services/payment_service_test.dart')
Invoke-Step '[3/4] Unit tests estables - register' @('test', 'test/register_page_test.dart')
Invoke-Step '[3/4] Unit tests estables - provider flow' @('test', 'test/provider_flow_test.dart')
Invoke-Step '[4/4] Integracion critica - onboarding/home' @('test', 'test/integration/onboarding_login_home_flow_test.dart')
Invoke-Step '[4/4] Integracion critica - app startup' @('test', 'test/integration/app_startup_test.dart')
Invoke-Step '[4/4] Integracion critica - provider registration' @('test', 'test/integration/provider_registration_flow_test.dart')

$functionsPath = Join-Path $root 'functions'
$strictCatalogAudit = $true
if ($env:RELEASE_STRICT_CATALOG_AUDIT -eq '0') {
  $strictCatalogAudit = $false
}
$credPath = $env:GOOGLE_APPLICATION_CREDENTIALS
$canRunCatalogGate = -not [string]::IsNullOrWhiteSpace($credPath) -and (Test-Path $credPath)

if ($canRunCatalogGate) {
  Invoke-NodeStep '[5/5] Gate catalogo categorias/subcategorias' $functionsPath @('npm', 'run', 'audit:categories:gate')
}
elseif ($strictCatalogAudit) {
  throw 'Fallo: [5/5] Gate catalogo obligatorio pero falta GOOGLE_APPLICATION_CREDENTIALS valido.'
}
else {
  Write-Host "`n[5/5] Gate catalogo omitido (sin GOOGLE_APPLICATION_CREDENTIALS valido)."
}

Write-Host "`n=============================================="
Write-Host 'Release checks OK'
Write-Host '=============================================='
