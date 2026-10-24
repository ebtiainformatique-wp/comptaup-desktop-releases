# Version Windows de scripts/ai-dev.sh
# Claude Code d'abord, relais OpenCode (OpenRouter) quand les crédits Claude sont épuisés.
#
#   .\scripts\ai-dev.ps1 "Ma tâche"                  # auto
#   .\scripts\ai-dev.ps1 -Mode opencode "Ma tâche"   # OpenCode uniquement
#   .\scripts\ai-dev.ps1 -Mode claude "Ma tâche"     # Claude uniquement
#   .\scripts\ai-dev.ps1                             # reprend .ai\HANDOFF.md
#
# Variables : $env:OPENROUTER_API_KEY (obligatoire pour OpenCode),
#             $env:OPENCODE_MODELS (liste de modèles :free séparés par des espaces),
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

# Modèles GRATUITS uniquement (suffixe :free), essayés dans l'ordre. Le premier qui répond travaille.
$FreeModels = if ($env:OPENCODE_MODELS) { $env:OPENCODE_MODELS -split '\s+' } elseif ($env:OPENCODE_MODEL) { @($env:OPENCODE_MODEL) } else { @(
  "openrouter/qwen/qwen3-coder:free",
  "openrouter/deepseek/deepseek-chat-v3.1:free",
  "openrouter/z-ai/glm-4.5-air:free",
  "openrouter/moonshotai/kimi-k2:free",
  "openrouter/openai/gpt-oss-120b:free"
) }
foreach ($m in $FreeModels) {
  if ($m -notmatch ':free$' -and $env:AI_ALLOW_PAID -ne "1") { Write-Host "✗ Modèle payant refusé : $m (seuls les modèles :free sont autorisés)"; exit 2 }
}
$ModelFailRe = $LimitRe + '|not found|no endpoints|unavailable|invalid model|ProviderModelNotFound|402'

function Invoke-OpenCode {
  if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) { Write-Host "opencode introuvable : npm i -g opencode-ai"; return 2 }
  if (-not $env:OPENROUTER_API_KEY) { Write-Host "OPENROUTER_API_KEY manquante"; return 2 }
  foreach ($m in $FreeModels) {
    $log = "$LogDir/opencode-$(Get-Date -Format yyyyMMdd-HHmmss).log"
    Write-Host "→ OpenCode avec $m"
    opencode run --auto --model $m (Get-Prompt) 2>&1 | Tee-Object -FilePath $log | Out-Host
    $rc = $LASTEXITCODE
    $out = Get-Content $log -Raw
    if ($rc -eq 0 -and -not ($out -match $ModelFailRe -and (Get-Content $log).Count -lt 15)) { return 0 }
    Write-Host "⚠ $m indisponible ou limité → modèle gratuit suivant."
  }
  return 4   # tous les modèles gratuits sont limités pour l'instant
}

# Petit test : Claude a-t-il de nouveau du crédit ? (coûte très peu)
$ClaudeRetryMin = if ($env:AI_CLAUDE_RETRY_MIN) { [int]$env:AI_CLAUDE_RETRY_MIN } else { 15 }
$lastClaudeCheck = Get-Date
function Test-ClaudeAvailable {
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { return $false }
  $out = (claude -p "Réponds uniquement OK" 2>&1 | Out-String)
  return ($LASTEXITCODE -eq 0 -and $out -notmatch $LimitRe)
}

$current = if ($Mode -eq "auto") { "claude" } else { $Mode }
for ($round = 1; $round -le $MaxRounds; $round++) {
  if ($Mode -eq "auto" -and $current -eq "opencode" -and ((Get-Date) - $lastClaudeCheck).TotalMinutes -ge $ClaudeRetryMin) {
    $lastClaudeCheck = Get-Date
    Write-Host "→ Vérification du crédit Claude..."
    if (Test-ClaudeAvailable) { Write-Host "✓ Crédit Claude disponible → retour sur Claude Code."; $current = "claude" }
    else { Write-Host "✗ Toujours pas de crédit Claude, OpenCode continue." }
  }
  Write-Host "=== Tour $round/$MaxRounds — agent : $current ==="
  if ($current -eq "claude") {
    $rc = Invoke-Claude
    if (($rc -eq 3 -or $rc -eq 2) -and $Mode -eq "auto") {
      Write-Host "⚠ Claude indisponible (crédits/limite) → relais OpenCode."
      $current = "opencode"; $lastClaudeCheck = Get-Date; continue
    }
  } else {
    $rc = Invoke-OpenCode
    if ($rc -eq 2) { exit 2 }
    if ($rc -eq 4) { Write-Host "⏳ Tous les modèles gratuits sont limités, pause de 15 min puis reprise."; Start-Sleep -Seconds 900; continue }
  }
  if (Test-Done) { Write-Host "✓ Tâche terminée (STATUS: DONE)."; exit 0 }
  if ($rc -ne 0) { Start-Sleep -Seconds 10 }
}
Write-Host "✗ Nombre max de tours atteint ($MaxRounds). Voir $Handoff et $LogDir/."
exit 1
