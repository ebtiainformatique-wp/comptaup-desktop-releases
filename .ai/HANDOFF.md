STATUS: IN_PROGRESS
Agent: claude — 2026-11-12

## Objectif
Ventes sous prix minimum (code dans le depot INTENDANCE-BUSINESS-) :
1. Ne mettre en validation que les articles en conflit, facturer les autres.
2. Apres un refus : permettre au vendeur de « Reprendre » ou « Abandonner » (au lieu de « Dupliquer »).

## Fait
- Point 2 livre sur la branche `claude/reprise-abandon-vente-refusee` du depot INTENDANCE-BUSINESS-
  (migration additive, API, interface, tests OK, parcours verifie au navigateur).
- Point 1 : la scission existe deja depuis le 2026-11-01 (comptant et credit).

## Reste à faire (prochaine étape en premier)
- Decision client attendue : scinder aussi les ventes avec avance partielle / tiers payant
  (aujourd'hui toute la vente reste en attente dans ces deux cas, `canSplit` dans sale.service.ts).
- Ouvrir la PR de la branche si le client la demande.

## Notes / pièges
- Voir PROGRESS_VENTE_SOUS_PRIX_MIN.md (section du 2026-11-12) dans INTENDANCE-BUSINESS-.
