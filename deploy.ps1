# ============================================================
#  GECAMA — Deploy automatico a Vercel
#  Ejecutar: powershell -ExecutionPolicy Bypass -File deploy.ps1
# ============================================================

$SRC      = $PSScriptRoot
$TOKEN    = $env:VERCEL_TOKEN  # set VERCEL_TOKEN in your environment before running
$SITE_URL = "https://gecama-trabajos.vercel.app"

Write-Host ""
Write-Host "=== GECAMA Deploy a Vercel ===" -ForegroundColor Cyan

# 1. Actualizar version.json con timestamp actual
$v = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Set-Content -Path "$SRC\version.json" -Value "{`"v`":`"$v`"}" -Encoding utf8
Write-Host "[1/3] version.json: $v" -ForegroundColor Green

# 2. Preparar archivos en base64
$archivos = @("index.html","sw.js","manifest.json","version.json","instalar.html","icon.svg","icon-192.png","icon-512.png","api/sync.js")
$fileList = @()
foreach ($f in $archivos) {
  $path = Join-Path $SRC $f
  if (-not (Test-Path $path)) { Write-Host "  FALTA: $f" -ForegroundColor Yellow; continue }
  $bytes   = [System.IO.File]::ReadAllBytes($path)
  $b64     = [Convert]::ToBase64String($bytes)
  $fileList += @{ file = $f; data = $b64; encoding = "base64" }
}
Write-Host "[2/3] $($fileList.Count) archivos listos" -ForegroundColor Green

# 3. Desplegar en Vercel
$headers = @{ "Authorization" = "Bearer $TOKEN"; "Content-Type" = "application/json" }
$body = @{
  name            = "gecama-trabajos"
  files           = $fileList
  projectSettings = @{ framework = $null }
  target          = "production"
} | ConvertTo-Json -Depth 10 -Compress

Write-Host "[3/3] Subiendo a Vercel..." -ForegroundColor Yellow

try {
  $resp = Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments" `
    -Method POST -Headers $headers -Body $body

  $deployId = $resp.id
  Write-Host "  Deploy ID: $deployId"

  # Esperar publicacion (max 2 min)
  $ready = $false
  for ($i = 0; $i -lt 24; $i++) {
    Start-Sleep -Seconds 5
    $s = Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments/$deployId" `
      -Headers @{ "Authorization" = "Bearer $TOKEN" }
    if ($s.readyState -eq "READY") { $ready = $true; break }
    if ($s.readyState -eq "ERROR") {
      Write-Host "Error en deploy: $($s.errorMessage)" -ForegroundColor Red
      break
    }
  }

  if ($ready) {
    Write-Host ""
    Write-Host "DEPLOY COMPLETADO" -ForegroundColor Green
    Write-Host "URL: $SITE_URL" -ForegroundColor Cyan
    Write-Host "La app se actualiza sola en todos los dispositivos en ~2 minutos." -ForegroundColor Green
  }
} catch {
  Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
