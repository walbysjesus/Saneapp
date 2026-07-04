param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ArgsList
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$localProperties = Join-Path $projectRoot 'android/local.properties'

$flutterExe = $null
if (Test-Path $localProperties) {
  $line = Get-Content $localProperties | Where-Object { $_ -like 'flutter.sdk=*' } | Select-Object -First 1
  if ($line) {
    $sdk = $line.Substring('flutter.sdk='.Length).Trim().Replace('\\', '\')
    $candidate = Join-Path $sdk 'bin/flutter.bat'
    if (Test-Path $candidate) {
      $flutterExe = $candidate
    }
  }
}

if (-not $flutterExe) {
  Write-Host '[flutterw] No se encontro flutter.sdk valido. Usando flutter del PATH...'
  $flutterExe = 'flutter'
}

& $flutterExe @ArgsList
exit $LASTEXITCODE
