# ============================================================
#  GECAMA - Deploy a Vercel via git push
#  Uso: powershell -ExecutionPolicy Bypass -File deploy.ps1
#
#  Actualiza version.json (timestamp) y hace git push.
#  Vercel despliega automaticamente al detectar el push.
# ============================================================

$SRC      = $PSScriptRoot
$VER_FILE = "$SRC\version.json"
$SITE_URL = "https://gecama-trabajos.vercel.app"

Write-Host ""
Write-Host "=== GECAMA Deploy ===" -ForegroundColor Cyan

# 1. Actualizar version.json con timestamp actual (cache busting)
$v = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Set-Content -Path $VER_FILE -Value "{`"v`":`"$v`"}" -Encoding utf8
Write-Host "[1/3] version.json -> $v" -ForegroundColor Green

# 2. Git add + commit
Write-Host "[2/3] Preparando commit..." -ForegroundColor Yellow
git -C $SRC add -A
if(-not $?){ Write-Host "  ERROR en git add" -ForegroundColor Red; exit 1 }

git -C $SRC commit -m "deploy $v"
if(-not $?){ Write-Host "  Nada nuevo que commitear" -ForegroundColor Yellow }

# 3. Git push -> Vercel se despliega automaticamente
Write-Host "[3/3] Publicando..." -ForegroundColor Yellow
git -C $SRC push origin main
if($?){
  Write-Host ""
  Write-Host "  DEPLOY LANZADO" -ForegroundColor Green
  Write-Host "  Vercel desplegara en ~30 seg: $SITE_URL" -ForegroundColor Cyan
  Write-Host "  La app se actualiza en todos los dispositivos automaticamente." -ForegroundColor Green
}else{
  Write-Host "  ERROR en git push. Revisa la conexion y credenciales." -ForegroundColor Red
}

Write-Host ""
