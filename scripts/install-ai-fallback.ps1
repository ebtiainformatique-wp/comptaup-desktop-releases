# Copie la configuration de relais Claude Code → OpenCode dans un autre projet.
#   .\scripts\install-ai-fallback.ps1 C:\chemin\vers\autre-projet
param([Parameter(Mandatory = $true)][string]$Dest)
$Src = Split-Path -Parent $PSScriptRoot
foreach ($d in "scripts", ".ai", ".github/workflows") { New-Item -ItemType Directory -Force -Path (Join-Path $Dest $d) | Out-Null }
foreach ($f in "AGENTS.md", "opencode.json", ".github/workflows/opencode.yml") {
  if (-not (Test-Path (Join-Path $Dest $f))) { Copy-Item (Join-Path $Src $f) (Join-Path $Dest $f) }
}
Copy-Item "$Src/scripts/ai-dev.sh", "$Src/scripts/ai-dev.ps1" (Join-Path $Dest "scripts") -Force
$claude = Join-Path $Dest "CLAUDE.md"
if (-not ((Test-Path $claude) -and (Select-String -Path $claude -Pattern '@AGENTS.md' -Quiet))) { Add-Content $claude "@AGENTS.md" }
$h = Join-Path $Dest ".ai/HANDOFF.md"
if (-not (Test-Path $h)) { "STATUS: IN_PROGRESS`n`n## Objectif`n`n## Fait`n`n## Reste à faire`n`n## Notes / pièges" | Set-Content $h -Encoding utf8 }
$gi = Join-Path $Dest ".gitignore"
if (-not ((Test-Path $gi) -and (Select-String -Path $gi -Pattern '^\.ai/logs/' -Quiet))) { Add-Content $gi ".ai/logs/" }
Write-Host "✓ Relais IA installé dans $Dest (pensez à adapter AGENTS.md au projet)."
