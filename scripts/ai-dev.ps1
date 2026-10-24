# Version Windows de scripts/ai-dev.sh
# Claude Code d'abord, relais OpenCode (OpenRouter) quand les crédits Claude sont épuisés.
#
#   .\scripts\ai-dev.ps1 "Ma tâche"                  # auto
#   .\scripts\ai-dev.ps1 -Mode opencode "Ma tâche"   # OpenCode uniquement
#   .\scripts\ai-dev.ps1 -Mode claude "Ma tâche"     # Claude uniquement
#   .\scripts\ai-dev.ps1                             # reprend .ai\HANDOFF.md
#
# Variables : $env:OPENROUTER_API_KEY (obligatoire pour OpenCode), $env:OPENCODE_MODEL,
#             $env:AI_CHECK_CMD (ex: "npm test")
param(
  [ValidateSet("auto", "claude", "opencode")][string]$Mode = "auto",
  [int]$MaxRounds = 20,
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$Task
)
$ErrorActionPreference = "Continue"
$TaskText = ($Task -join " ").Trim()
$root = (git rev-parse --show-toplevel 2>$null); if ($root) { Set-Location $root }
$Handoff = ".ai/HANDOFF.md"; $LogDir = ".ai/logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
if (-not (Test-Path $Handoff)) { "STATUS: IN_PROGRESS`n`n## Objectif`n$TaskText" | Set-Content $Handoff -Encoding utf8 }

$LimitRe = 'usage limit|limit reached|rate.?limit|credit balance|insufficient.?credit|out of credits|quota|overloaded|429|5-hour limit|weekly limit'

function Get-Prompt {
  $base = "Lis AGENTS.md puis .ai/HANDOFF.md et continue le travail là où il s'est arrêté, sans t'arrêter avant la fin. Mets à jour .ai/HANDOFF.md et committe après chaque étape. Écris 'STATUS: DONE' seulement quand tout est terminé et vérifié."
  if ($script:TaskText) { "$base Tâche demandée : $script:TaskText" } else { $base }
}

function Test-Done {
  if (-not (Select-String -Path $Handoff -Pattern '^STATUS: DONE' -Quiet)) { return $false }
  if ($env:AI_CHECK_CMD) {
    Write-Host "→ Vérification : $env:AI_CHECK_CMD"
    cmd /c $env:AI_CHECK_CMD
    if ($LASTEXITCODE -ne 0) {
      (Get-Content $Handoff) -replace '^STATUS: DONE', 'STATUS: IN_PROGRESS' | Set-Content $Handoff -Encoding utf8
      $script:TaskText += " (La vérification '$env:AI_CHECK_CMD' a échoué : corrige-la.)"
      return $false
    }
  }
  return $true
}

function Invoke-Claude {
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Write-Host "claude introuvable"; return 2 }
  $log = "$LogDir/claude-$(Get-Date -Format yyyyMMdd-HHmmss).log"
  claude -p (Get-Prompt) --dangerously-skip-permissions 2>&1 | Tee-Object -FilePath $log | Out-Host
  $rc = $LASTEXITCODE
  $out = Get-Content $log -Raw
  if ($out -match $LimitRe -and ($rc -ne 0 -or (Get-Content $log).Count -lt 5)) { return 3 }
  return $rc
}

function Invoke-OpenCode {
  if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) { Write-Host "opencode introuvable : npm i -g opencode-ai"; return 2 }
  if (-not $env:OPENROUTER_API_KEY) { Write-Host "OPENROUTER_API_KEY manquante"; return 2 }
  $log = "$LogDir/opencode-$(Get-Date -Format yyyyMMdd-HHmmss).log"
  $a = @("run", "--auto"); if ($env:OPENCODE_MODEL) { $a += @("--model", $env:OPENCODE_MODEL) }
  opencode @a (Get-Prompt) 2>&1 | Tee-Object -FilePath $log | Out-Host
  return $LASTEXITCODE
}

$current = if ($Mode -eq "auto") { "claude" } else { $Mode }
for ($round = 1; $round -le $MaxRounds; $round++) {
  Write-Host "=== Tour $round/$MaxRounds — agent : $current ==="
  if ($current -eq "claude") {
    $rc = Invoke-Claude
    if (($rc -eq 3 -or $rc -eq 2) -and $Mode -eq "auto") {
      Write-Host "⚠ Claude indisponible (crédits/limite) → relais OpenCode."
      $current = "opencode"; continue
    }
  } else {
    $rc = Invoke-OpenCode
    if ($rc -eq 2) { exit 2 }
  }
  if (Test-Done) { Write-Host "✓ Tâche terminée (STATUS: DONE)."; exit 0 }
  if ($rc -ne 0) { Start-Sleep -Seconds 10 }
}
Write-Host "✗ Nombre max de tours atteint ($MaxRounds). Voir $Handoff et $LogDir/."
exit 1
