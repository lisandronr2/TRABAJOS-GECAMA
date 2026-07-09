# ============================================================
#  GECAMA — Deploy manual a Vercel
#  Uso: powershell -ExecutionPolicy Bypass -File deploy.ps1
#
#  Requiere: $env:VERCEL_TOKEN definido en el entorno
#  Nota: el repo conectado a Vercel se despliega automaticamente
#        en cada git push. Este script es para deploy manual.
# ============================================================

$SRC      = $PSScriptRoot
$TOKEN    = $env:VERCEL_TOKEN
$SITE_URL = "https://gecama-trabajos.vercel.app"

if (-not $TOKEN) {
  Write-Host "ERROR: define VERCEL_TOKEN en tu entorno antes de ejecutar." -ForegroundColor Red
  Write-Host "  $env:VERCEL_TOKEN = 'tu-token-aqui'" -ForegroundColor Yellow
  exit 1
}

Write-Host ""
Write-Host "=== GECAMA Deploy a Vercel ===" -ForegroundColor Cyan

# 1. Actualizar version.json con timestamp actual (cache busting)
$v = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Set-Content -Path "$SRC\version.json" -Value "{`"v`":`"$v`"}" -Encoding utf8
Write-Host "[1/3] version.json actualizado: $v" -ForegroundColor Green

# 2. Preparar archivos para el deploy
$archivos = @(
  "index.html",
  "sw.js",
  "manifest.json",
  "vercel.json",
  "version.json",
  "instalar.html",
  "icon.svg",
  "icon-192.png",
  "icon-512.png",
  "api/sync.js"
)

$fileList = @()
foreach ($f in $archivos) {
  $path = Join-Path $SRC $f
  if (-not (Test-Path $path)) {
    Write-Host "  OMITIDO (no existe): $f" -ForegroundColor Yellow
    continue
  }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $b64   = [Convert]::ToBase64String($bytes)
  $fileList += @{ file = $f; data = $b64; encoding = "base64" }
  Write-Host "  + $f ($([Math]::Round($bytes.Length/1KB,1)) KB)" -ForegroundColor DarkGray
}
Write-Host "[2/3] $($fileList.Count) archivos listos" -ForegroundColor Green

# 3. Desplegar en Vercel via API
$headers = @{
  "Authorization" = "Bearer $TOKEN"
  "Content-Type"  = "application/json"
}
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
  Write-Host "  Deploy ID: $deployId" -ForegroundColor DarkGray

  # Esperar publicacion (max 2 min, poll cada 5 s)
  $ready = $false
  for ($i = 0; $i -lt 24; $i++) {
    Start-Sleep -Seconds 5
    $s = Invoke-RestMethod `
      -Uri "https://api.vercel.com/v13/deployments/$deployId" `
      -Headers @{ "Authorization" = "Bearer $TOKEN" }

    $state = $s.readyState
    Write-Host "  Estado: $state" -ForegroundColor DarkGray

    if ($state -eq "READY") { $ready = $true; break }
    if ($state -eq "ERROR") {
      Write-Host "  Error en deploy: $($s.errorMessage)" -ForegroundColor Red
      break
    }
  }

  if ($ready) {
    Write-Host ""
    Write-Host "  DEPLOY COMPLETADO " -ForegroundColor Green
    Write-Host "  $SITE_URL" -ForegroundColor Cyan
    Write-Host "  La app se actualiza en todos los dispositivos en ~2 min." -ForegroundColor Green
  } else {
    Write-Host "  Tiempo de espera agotado. Revisa el dashboard de Vercel." -ForegroundColor Yellow
    Write-Host "  https://vercel.com/dashboard" -ForegroundColor Cyan
  }

} catch {
  Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "  Revisa que VERCEL_TOKEN sea valido y el proyecto exista." -ForegroundColor Yellow
}

Write-Host ""
