# Règles communes aux agents IA (Claude Code + OpenCode)

Ce fichier est lu automatiquement par **OpenCode** (`AGENTS.md`) et par **Claude Code** (via `CLAUDE.md`).
Les deux agents travaillent sur le même dépôt et doivent pouvoir se passer le relais à tout moment.

## Protocole de relais (obligatoire)

1. **Au début de chaque session**, lire `.ai/HANDOFF.md` : il contient la tâche en cours, ce qui est fait et la suite.
2. **Pendant le travail**, mettre à jour `.ai/HANDOFF.md` après chaque étape significative
   (pas seulement à la fin : les crédits peuvent s'arrêter n'importe quand).
3. **Committer souvent** avec des messages clairs. Un travail non commité peut être perdu lors du relais.
4. Quand la tâche est entièrement terminée **et vérifiée** (build/tests OK), écrire exactement
   `STATUS: DONE` sur la ligne de statut de `.ai/HANDOFF.md`. Sinon laisser `STATUS: IN_PROGRESS`.
5. Ne jamais écrire `STATUS: DONE` si quelque chose reste à faire ou a échoué.

## Format de `.ai/HANDOFF.md`

```
STATUS: IN_PROGRESS | DONE | BLOCKED
Agent: <claude|opencode> — <date>

## Objectif
## Fait
## Reste à faire (prochaine étape en premier)
## Notes / pièges
```

## Conventions du projet

- Langue des échanges : français.
- Ne jamais committer de secrets (clés API, tokens). Les clés passent par variables d'environnement.
