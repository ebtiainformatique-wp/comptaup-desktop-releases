#!/usr/bin/env bash
# Lance une tâche de code avec Claude Code, et bascule sur OpenCode (OpenRouter)
# quand les crédits / la limite Claude sont épuisés. Boucle jusqu'à STATUS: DONE.
#
# Usage :
#   scripts/ai-dev.sh "Ma tâche"                 # auto : Claude puis relais OpenCode
#   scripts/ai-dev.sh --mode opencode "Ma tâche" # OpenCode uniquement
#   scripts/ai-dev.sh --mode claude "Ma tâche"   # Claude uniquement
#   scripts/ai-dev.sh                            # reprend la tâche décrite dans .ai/HANDOFF.md
#
# Variables utiles :
#   OPENROUTER_API_KEY  (obligatoire pour OpenCode)
#   OPENCODE_MODELS     modèles :free séparés par des espaces (défaut : liste gratuite ci-dessous)
#   AI_MAX_ROUNDS       nombre max de tours (défaut 20)
#   AI_CHECK_CMD        commande de vérification, ex: "npm test" (optionnel)
set -uo pipefail

MODE="auto"
MAX_ROUNDS="${AI_MAX_ROUNDS:-20}"
HANDOFF=".ai/HANDOFF.md"
LOG_DIR=".ai/logs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --max-rounds) MAX_ROUNDS="$2"; shift 2 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) break ;;
  esac
done
TASK="${*:-}"

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
mkdir -p "$LOG_DIR" .ai
[[ -f "$HANDOFF" ]] || printf 'STATUS: IN_PROGRESS\n\n## Objectif\n%s\n' "$TASK" > "$HANDOFF"

# Messages typiques quand Claude n'a plus de crédit / atteint sa limite.
LIMIT_RE='usage limit|limit reached|rate.?limit|credit balance|insufficient.?credit|out of credits|quota|overloaded|429|5-hour limit|weekly limit'

prompt_for() {
  local base="Lis AGENTS.md puis .ai/HANDOFF.md et continue le travail là où il s'est arrêté, sans t'arrêter avant la fin. Mets à jour .ai/HANDOFF.md et committe après chaque étape. Écris 'STATUS: DONE' seulement quand tout est terminé et vérifié."
  if [[ -n "$TASK" ]]; then echo "$base Tâche demandée : $TASK"; else echo "$base"; fi
}

is_done() {
  grep -q '^STATUS: DONE' "$HANDOFF" 2>/dev/null || return 1
  if [[ -n "${AI_CHECK_CMD:-}" ]]; then
    echo "→ Vérification : $AI_CHECK_CMD"
    if ! bash -c "$AI_CHECK_CMD"; then
      echo "✗ Vérification échouée, on continue."
      sed -i.bak 's/^STATUS: DONE/STATUS: IN_PROGRESS/' "$HANDOFF" && rm -f "$HANDOFF.bak"
      TASK="${TASK} (La vérification '$AI_CHECK_CMD' a échoué : corrige-la.)"
      return 1
    fi
  fi
  return 0
}

run_claude() {
  command -v claude >/dev/null || { echo "claude introuvable"; return 2; }
  local log="$LOG_DIR/claude-$(date +%Y%m%d-%H%M%S).log"
  claude -p "$(prompt_for)" --dangerously-skip-permissions 2>&1 | tee "$log"
  local rc=${PIPESTATUS[0]}
  if grep -Eiq "$LIMIT_RE" "$log" && [[ $rc -ne 0 || $(wc -l < "$log") -lt 5 ]]; then
    return 3   # crédits / limite épuisés
  fi
  return $rc
}

# Modèles GRATUITS uniquement (suffixe :free), essayés dans l'ordre.
if [[ -n "${OPENCODE_MODELS:-}" ]]; then read -ra FREE_MODELS <<< "$OPENCODE_MODELS"
elif [[ -n "${OPENCODE_MODEL:-}" ]]; then FREE_MODELS=("$OPENCODE_MODEL")
else FREE_MODELS=(
  openrouter/qwen/qwen3-coder:free
  openrouter/deepseek/deepseek-chat-v3.1:free
  openrouter/z-ai/glm-4.5-air:free
  openrouter/moonshotai/kimi-k2:free
  openrouter/openai/gpt-oss-120b:free
); fi
for m in "${FREE_MODELS[@]}"; do
  if [[ "$m" != *:free && "${AI_ALLOW_PAID:-}" != 1 ]]; then
    echo "✗ Modèle payant refusé : $m (seuls les modèles :free sont autorisés)"; exit 2
  fi
done
MODEL_FAIL_RE="$LIMIT_RE|not found|no endpoints|unavailable|invalid model|ProviderModelNotFound|402"

run_opencode() {
  command -v opencode >/dev/null || { echo "opencode introuvable : npm i -g opencode-ai"; return 2; }
  [[ -n "${OPENROUTER_API_KEY:-}" ]] || { echo "OPENROUTER_API_KEY manquante"; return 2; }
  local m log rc
  for m in "${FREE_MODELS[@]}"; do
    log="$LOG_DIR/opencode-$(date +%Y%m%d-%H%M%S).log"
    echo "→ OpenCode avec $m"
    opencode run --auto --model "$m" "$(prompt_for)" 2>&1 | tee "$log"
    rc=${PIPESTATUS[0]}
    if [[ $rc -eq 0 ]] && ! { grep -Eiq "$MODEL_FAIL_RE" "$log" && [[ $(wc -l < "$log") -lt 15 ]]; }; then
      return 0
    fi
    echo "⚠ $m indisponible ou limité → modèle gratuit suivant."
  done
  return 4   # tous les modèles gratuits sont limités pour l'instant
}

# Petit test : Claude a-t-il de nouveau du crédit ? (coûte très peu)
CLAUDE_RETRY_SEC=$(( ${AI_CLAUDE_RETRY_MIN:-15} * 60 ))
last_claude_check=$(date +%s)
claude_available() {
  command -v claude >/dev/null || return 1
  local out; out=$(claude -p "Réponds uniquement OK" 2>&1) || return 1
  ! grep -Eiq "$LIMIT_RE" <<< "$out"
}

current="$MODE"; [[ "$MODE" == "auto" ]] && current="claude"

for ((round = 1; round <= MAX_ROUNDS; round++)); do
  if [[ "$MODE" == "auto" && "$current" == "opencode" ]] && (( $(date +%s) - last_claude_check >= CLAUDE_RETRY_SEC )); then
    last_claude_check=$(date +%s)
    echo "→ Vérification du crédit Claude..."
    if claude_available; then echo "✓ Crédit Claude disponible → retour sur Claude Code."; current="claude"
    else echo "✗ Toujours pas de crédit Claude, OpenCode continue."; fi
  fi
  echo "=== Tour $round/$MAX_ROUNDS — agent : $current ==="
  if [[ "$current" == "claude" ]]; then
    run_claude; rc=$?
    if [[ $rc -eq 3 || $rc -eq 2 ]] && [[ "$MODE" == "auto" ]]; then
      echo "⚠ Claude indisponible (crédits/limite) → relais OpenCode."
      current="opencode"; last_claude_check=$(date +%s); continue
    fi
  else
    run_opencode; rc=$?
    [[ $rc -eq 2 ]] && exit 2
    if [[ $rc -eq 4 ]]; then
      echo "⏳ Tous les modèles gratuits sont limités, pause de ${AI_FREE_WAIT:-900}s puis reprise."
      sleep "${AI_FREE_WAIT:-900}"; continue
    fi
  fi
  if is_done; then echo "✓ Tâche terminée (STATUS: DONE)."; exit 0; fi
  [[ $rc -ne 0 ]] && sleep 10
done

echo "✗ Nombre max de tours atteint ($MAX_ROUNDS). Voir $HANDOFF et $LOG_DIR/."
exit 1
