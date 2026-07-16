# ============================================================
#  GECAMA — Deploy a Vercel con auto-incremento de version
#  Uso: powershell -ExecutionPolicy Bypass -File deploy.ps1
#
#  - Lee version.json, incrementa el 4º numero (build)
#  - Hace git commit + push (Vercel se despliega automaticamente)
# ============================================================

$SRC      = $PSScriptRoot
$VER_FILE = "$SRC\version.json"
$SITE_URL = "https://gecama-trabajos.vercel.app"

Write-Host ""
Write-Host "=== GECAMA Deploy ===" -ForegroundColor Cyan

# ── 1. Leer y actualizar version ──────────────────────────────
$json = Get-Content $VER_FILE -Raw | ConvertFrom-Json
$current = $json.v

# Parsear formato A.B.C.D
$parts = $current -split '\.'
if($parts.Count -ne 4){
  Write-Host "ERROR: formato de version invalido en version.json: $current" -ForegroundColor Red
  Write-Host "  Se esperaba A.B.C.D (ej: 2.7.3.0)" -ForegroundColor Yellow
  exit 1
}

$parts[3] = [int]$parts[3] + 1
$newVer = $parts -join '.'

Set-Content -Path $VER_FILE -Value "{`"v`":`"$newVer`"}`n" -Encoding utf8
Write-Host "[1/3] Version: $current  ->  $newVer" -ForegroundColor Green

# ── 2. Git commit + push ──────────────────────────────────────
Write-Host "[2/3] Preparando commit..." -ForegroundColor Yellow

git -C $SRC add -A
if(-not $?){ Write-Host "  ERROR en git add" -ForegroundColor Red; exit 1 }

$msg = "v$newVer — deploy"
git -C $SRC commit -m $msg
if(-not $?){ Write-Host "  Nada que commitear o error en commit" -ForegroundColor Yellow }

Write-Host "[3/3] Publicando en GitHub -> Vercel..." -ForegroundColor Yellow
git -C $SRC push origin main
if($?){
  Write-Host ""
  Write-Host "  DEPLOY LANZADO  v$newVer" -ForegroundColor Green
  Write-Host "  Vercel desplegara en ~30 seg: $SITE_URL" -ForegroundColor Cyan
  Write-Host "  La app se actualiza en todos los dispositivos automaticamente." -ForegroundColor Green
}else{
  Write-Host "  ERROR en git push. Revisa la conexion y credenciales." -ForegroundColor Red
}

Write-Host ""
