<#
  deploy.ps1 — Deploy da galeria MRV Vila de Setiba para o AWS S3.

  Uso:
    ./deploy.ps1            # sync completo + cache-control no HTML/JS
    ./deploy.ps1 -QuickHtml # atualiza só index.html e inject.js (rápido)

  Pré-requisitos (uma única vez):
    1. AWS CLI instalado  -> https://aws.amazon.com/cli/
    2. Credenciais        -> aws configure   (regiao: sa-east-1)
#>

param(
  [switch]$QuickHtml
)

$ErrorActionPreference = 'Stop'
$Bucket = 's3://skylineip/Tour Virtual/MRV/galeria-vila-de-setiba'
$NoCache = 'no-cache,no-store,must-revalidate'

# Garante que o script roda a partir da pasta do projeto
Set-Location -Path $PSScriptRoot

# Verifica AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  Write-Host 'ERRO: AWS CLI nao encontrado no PATH.' -ForegroundColor Red
  Write-Host 'Instale em https://aws.amazon.com/cli/ e rode "aws configure".' -ForegroundColor Yellow
  exit 1
}

# ── Normaliza o case das pastas de assets para minusculas ──────────
# O S3 e case-sensitive; a config referencia caminhos minusculos.
# Se o OneDrive/Explorer estiver segurando uma pasta, tenta com retry e
# ABORTA se nao conseguir (para nunca subir um estado com case divergente).
function Normalize-FolderCase($parent, $tries) {
  $changed = $false
  foreach ($d in (Get-ChildItem -LiteralPath $parent -Directory)) {
    $lower = $d.Name.ToLower()
    if ($d.Name -cne $lower) {
      $ok = $false
      for ($i=0; $i -lt $tries; $i++) {
        try {
          Rename-Item -LiteralPath $d.FullName -NewName ($lower + '_x') -ErrorAction Stop
          Rename-Item -LiteralPath (Join-Path $parent ($lower + '_x')) -NewName $lower -ErrorAction Stop
          Write-Host "  case: $($d.Name) -> $lower" -ForegroundColor DarkGray
          $ok = $true; $changed = $true; break
        } catch { Start-Sleep -Milliseconds 1500 }
      }
      if (-not $ok) {
        Write-Host "ERRO: nao foi possivel renomear '$($d.Name)' para minusculo." -ForegroundColor Red
        Write-Host 'Feche janelas do Explorer/VS Code nessa pasta ou pause o OneDrive e rode novamente.' -ForegroundColor Yellow
        exit 1
      }
    }
  }
  return $changed
}

$assetsDir = Join-Path $PSScriptRoot 'assets'
if (Test-Path -LiteralPath $assetsDir) {
  Write-Host 'Normalizando case das pastas de assets...' -ForegroundColor Green
  Normalize-FolderCase $assetsDir 6 | Out-Null
}

function Copy-Html($file) {
  Write-Host "  -> $file" -ForegroundColor Cyan
  aws s3 cp $file "$Bucket/$file" --cache-control $NoCache
}

if ($QuickHtml) {
  Write-Host 'Atualizando apenas index.html e inject.js...' -ForegroundColor Green
  Copy-Html 'index.html'
  Copy-Html 'inject.js'
}
else {
  Write-Host 'Sync completo para o S3...' -ForegroundColor Green
  aws s3 sync . "$Bucket/" `
    --exclude ".git/*" --exclude ".claude/*" --exclude "*.py" --exclude "*.ps1" `
    --exclude "README.md" --exclude ".gitattributes" --exclude "*.md" `
    --exclude "*.pdf" --exclude "Thumbs.db" --exclude "*/Thumbs.db" `
    --delete

  # HTML/JS precisam de cache-control para o 3DVista nunca servir versao cacheada
  Write-Host 'Aplicando cache-control no HTML/JS...' -ForegroundColor Green
  Copy-Html 'index.html'
  Copy-Html 'inject.js'
  Copy-Html 'video-gallery.html'
  Copy-Html 'diferenciais.html'
}

Write-Host 'Deploy concluido.' -ForegroundColor Green
Write-Host "Base: https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/MRV/galeria-vila-de-setiba/" -ForegroundColor DarkGray
