# Relais Claude Code → OpenCode (OpenRouter)

Objectif : quand les crédits Claude sont épuisés, **OpenCode** reprend le travail là où il s'est
arrêté et continue jusqu'au résultat. Vous pouvez aussi travailler **uniquement avec OpenCode**.

## Comment ça marche

- `AGENTS.md` : règles communes. OpenCode le lit directement, Claude Code via `CLAUDE.md`.
- `.ai/HANDOFF.md` : le « carnet de relais ». Chaque agent y note l'objectif, ce qui est fait et
  la prochaine étape, et committe souvent. L'agent suivant repart de là.
- `STATUS: DONE` dans ce fichier = tâche terminée. Le script s'arrête seulement à ce moment
  (et, si `AI_CHECK_CMD` est défini, seulement si la vérification passe).
- `opencode.json` : OpenCode branché sur OpenRouter, avec toutes les permissions accordées
  (pour travailler sans interruption).

## Installation (une fois, sur votre PC)

```bash
npm install -g opencode-ai            # OpenCode
npm install -g @anthropic-ai/claude-code   # Claude Code (si pas déjà installé)
```

Créez une clé sur https://openrouter.ai/settings/keys et **ajoutez du crédit OpenRouter**
(votre tableau de bord affiche 0 $ : sans crédit, seuls les modèles `:free` fonctionnent).

Windows (PowerShell, permanent) :
```powershell
setx OPENROUTER_API_KEY "sk-or-..."
```
macOS / Linux : ajoutez `export OPENROUTER_API_KEY=sk-or-...` à `~/.bashrc` ou `~/.zshrc`.

## Utilisation

| Besoin | Windows | macOS / Linux |
|---|---|---|
| Claude puis relais auto OpenCode | `.\scripts\ai-dev.ps1 "Ma tâche"` | `scripts/ai-dev.sh "Ma tâche"` |
| OpenCode uniquement | `.\scripts\ai-dev.ps1 -Mode opencode "Ma tâche"` | `scripts/ai-dev.sh --mode opencode "Ma tâche"` |
| Claude uniquement | `.\scripts\ai-dev.ps1 -Mode claude "Ma tâche"` | `scripts/ai-dev.sh --mode claude "Ma tâche"` |
| Reprendre la tâche en cours | `.\scripts\ai-dev.ps1` | `scripts/ai-dev.sh` |
| OpenCode interactif | `opencode` | `opencode` |

Options :
- `OPENCODE_MODEL` : changer de modèle, ex. `openrouter/qwen/qwen3-coder` (moins cher).
  Liste des modèles : commande `/models` dans OpenCode.
- `AI_CHECK_CMD` : commande qui doit réussir avant d'accepter « terminé », ex. `npm test`.
- `AI_MAX_ROUNDS` / `-MaxRounds` : nombre max de tours (20 par défaut) pour éviter de vider
  votre crédit OpenRouter en boucle.

## Depuis GitHub (sans votre PC)

1. Dépôt → Settings → Secrets and variables → Actions → ajouter `OPENROUTER_API_KEY`.
2. Actions → **opencode** → *Run workflow* : choisissez la branche et la tâche. OpenCode
   travaille et pousse ses commits sur cette branche.
3. Optionnel : installez https://github.com/apps/opencode-agent puis commentez `/oc <demande>`
   sur une issue ou une PR.

## Ajouter le relais à d'autres projets

```powershell
.\scripts\install-ai-fallback.ps1 C:\chemin\vers\autre-projet
```
```bash
scripts/install-ai-fallback.sh /chemin/vers/autre-projet
```
Puis adaptez `AGENTS.md` au projet et committez.

## Limites

- Une session Claude Code **dans le cloud** (claude.ai/code) ne peut pas lancer OpenCode toute
  seule quand ses crédits s'arrêtent. Le relais automatique passe par `ai-dev` sur votre PC ou par
  le workflow GitHub. Dans tous les cas, `.ai/HANDOFF.md` + les commits permettent à OpenCode de
  reprendre exactement où Claude s'est arrêté.
- La détection « crédits épuisés » repose sur les messages d'erreur de Claude Code
  (« usage limit », « credit balance », 429…). Si un message change, ajoutez-le à `LIMIT_RE`.
