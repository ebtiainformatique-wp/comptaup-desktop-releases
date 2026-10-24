#!/usr/bin/env bash
# Copie la configuration de relais Claude Code → OpenCode dans un autre projet.
#   scripts/install-ai-fallback.sh /chemin/vers/autre-projet
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:?Usage: $0 /chemin/vers/projet}"
mkdir -p "$DEST/scripts" "$DEST/.ai" "$DEST/.github/workflows"
cp -n "$SRC/AGENTS.md" "$SRC/opencode.json" "$DEST/" 2>/dev/null || true
[[ -f "$DEST/CLAUDE.md" ]] && grep -q '@AGENTS.md' "$DEST/CLAUDE.md" || printf '@AGENTS.md\n' >> "$DEST/CLAUDE.md"
cp "$SRC/scripts/ai-dev.sh" "$SRC/scripts/ai-dev.ps1" "$SRC/scripts/setup-windows.ps1" "$DEST/scripts/"
cp "$SRC/ai.cmd" "$DEST/"
chmod +x "$DEST/scripts/ai-dev.sh"
cp -n "$SRC/.github/workflows/opencode.yml" "$DEST/.github/workflows/" 2>/dev/null || true
[[ -f "$DEST/.ai/HANDOFF.md" ]] || printf 'STATUS: IN_PROGRESS\n\n## Objectif\n\n## Fait\n\n## Reste à faire\n\n## Notes / pièges\n' > "$DEST/.ai/HANDOFF.md"
grep -qx '.ai/logs/' "$DEST/.gitignore" 2>/dev/null || printf '.ai/logs/\n' >> "$DEST/.gitignore"
echo "✓ Relais IA installé dans $DEST (pensez à adapter AGENTS.md au projet)."
