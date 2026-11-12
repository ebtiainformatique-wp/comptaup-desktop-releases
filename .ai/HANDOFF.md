STATUS: IN_PROGRESS
Agent: claude — 2026-11-12

## Objectif
Ventes sous prix minimum (code dans le depot INTENDANCE-BUSINESS-) :
1. Ne mettre en validation que les articles en conflit, facturer les autres.
2. Apres un refus : permettre au vendeur de « Reprendre » ou « Abandonner » (au lieu de « Dupliquer »).

## Fait
- Point 2 livre sur la branche `claude/reprise-abandon-vente-refusee` du depot INTENDANCE-BUSINESS-
  (migration additive, API, interface, tests OK, parcours verifie au navigateur).
- Point 1 : scission (depuis 2026-11-01) etendue le 2026-11-12 a l'avance (imputee d'abord sur la
  facture immediate) et au tiers payant (prorata), meme branche, tests OK.

## Reste à faire (prochaine étape en premier)
- Verifier au navigateur une vente scindee avec avance (couvert par les tests API seulement).
- Ouvrir la PR de la branche si le client la demande.

## Notes / pièges
- Voir PROGRESS_VENTE_SOUS_PRIX_MIN.md (section du 2026-11-12) dans INTENDANCE-BUSINESS-.
