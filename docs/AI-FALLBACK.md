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

## Démarrage rapide (Windows)

Dans **Windows PowerShell**, depuis le dossier du projet :
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1   # une seule fois
.\ai "décrivez votre tâche"                                            # à chaque tâche
```
- `.\ai "tâche"` : Claude travaille ; si son crédit est épuisé, OpenCode (gratuit) prend le relais ;
  toutes les 15 min le script vérifie si Claude a de nouveau du crédit et **revient sur Claude**.
- `.\ai -Mode opencode "tâche"` : OpenCode uniquement.
- `.\ai` : reprendre la tâche en cours.
- `AI_CLAUDE_RETRY_MIN` : changer l'intervalle de vérification du crédit Claude (15 par défaut).

## Installation manuelle (une fois, sur votre PC)

```bash
npm install -g opencode-ai            # OpenCode
npm install -g @anthropic-ai/claude-code   # Claude Code (si pas déjà installé)
```

Créez une clé sur https://openrouter.ai/settings/keys (aucun crédit nécessaire : le projet
utilise **uniquement des modèles gratuits** `:free`).

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
- **Modèles gratuits uniquement.** Par défaut, le script essaie dans l'ordre : qwen3-coder,
  deepseek-chat-v3.1, glm-4.5-air, kimi-k2, gpt-oss-120b (tous `:free`). Si l'un est limité ou
  indisponible, il passe au suivant. Si tous sont limités, il fait une pause de 15 min et reprend.
- Tout modèle sans `:free` est **refusé** (sauf si vous mettez `AI_ALLOW_PAID=1`).
- `OPENCODE_MODELS` : votre propre liste, ex. `"openrouter/qwen/qwen3-coder:free openrouter/z-ai/glm-4.5-air:free"`.
  Modèles gratuits disponibles : https://openrouter.ai/models?max_price=0
- Limite OpenRouter sur les modèles gratuits : environ 50 requêtes/jour sans crédit acheté
  (1000/jour après un achat unique de 10 $). Un agent consomme vite des requêtes : les grosses
  tâches peuvent s'étaler sur plusieurs jours.
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
