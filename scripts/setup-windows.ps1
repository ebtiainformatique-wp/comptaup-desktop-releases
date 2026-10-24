# Installation en une fois sur Windows. Lancer depuis le dossier du projet :
#   powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1
Write-Host "=== Vérification de l'installation du relais Claude → OpenCode ==="
$ok = $true
foreach ($t in @(@{n="git"; i="https://git-scm.com/download/win"},
                 @{n="node"; i="https://nodejs.org"},
                 @{n="claude"; i="npm install -g @anthropic-ai/claude-code"},
                 @{n="opencode"; i="npm install -g opencode-ai"})) {
  if (Get-Command $t.n -ErrorAction SilentlyContinue) { Write-Host "✓ $($t.n) installé" }
  else {
    Write-Host "✗ $($t.n) manquant"
    if ($t.i -like "npm *" -and (Get-Command npm -ErrorAction SilentlyContinue)) {
      Write-Host "  → installation : $($t.i)"; cmd /c $t.i
    } else { Write-Host "  → à installer : $($t.i)"; $ok = $false }
  }
}

$key = [Environment]::GetEnvironmentVariable("OPENROUTER_API_KEY", "User")
if (-not $key) {
  Write-Host "`nCréez une clé gratuite sur https://openrouter.ai/settings/keys puis collez-la ici."
  Start-Process "https://openrouter.ai/settings/keys"
  $key = Read-Host "Clé OpenRouter (sk-or-...)"
  if ($key -notlike "sk-or-*") { Write-Host "✗ La clé doit commencer par sk-or-"; exit 1 }
  [Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $key, "User")
  Write-Host "✓ Clé enregistrée (valable aussi dans les prochaines fenêtres)."
} else { Write-Host "✓ Clé OpenRouter déjà enregistrée" }
$env:OPENROUTER_API_KEY = $key

Write-Host "`nTest de la clé OpenRouter..."
try {
  $r = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/key" -Headers @{ Authorization = "Bearer $key" }
  Write-Host "✓ Clé valide (compte gratuit : $($r.data.is_free_tier))"
} catch { Write-Host "✗ Clé refusée par OpenRouter : $($_.Exception.Message)"; $ok = $false }

if ($ok) {
  Write-Host "`n✓ Tout est prêt. Pour lancer une tâche, depuis le dossier du projet :"
  Write-Host '   .\ai "décrivez votre tâche"'
} else { Write-Host "`n✗ Corrigez les points ci-dessus puis relancez ce script." }
