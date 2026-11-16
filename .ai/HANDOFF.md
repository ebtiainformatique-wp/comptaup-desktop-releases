STATUS: IN_PROGRESS
Agent: claude — 2026-11-16

## Objectif
1. Audit complet ComptaUp (code : dépôt ebtiainformatique-wp/INTENDANCE-BUSINESS-) pour la pharmacie/clinique vétérinaire CVS.
2. Module complet de commandes de poussins.

## Fait
- Audit : docs/rapports/31-audit-comptable-cvs-2026-11-16.md (+ copie dans INTENDANCE-BUSINESS- docs/audit/). Publié (claude.ai/artifact/Fsjwqs3zvMB3mMQ3YNEamb) et envoyé par email (momene.rko@gmail.com) avec 10 questions.
- Module poussins TERMINÉ et poussé sur INTENDANCE-BUSINESS-, branche claude/practical-turing-q0ssas (3 commits) :
  migration 20261116100000_chick_orders (avec reprise des réservations vitrine), service/routes /api/v1/chick-orders,
  écrans /poussins et /poussins/[orderId], mode d'emploi docs/spec-commandes-poussins.md.
  Vérifié : typecheck + lint OK, 128 fichiers / 1040 tests API OK (dont 11 nouveaux), tests web OK, rendu navigateur desktop + téléphone OK.
- Rappels quotidiens programmés à 20h/21h/22h (Africa/Douala).

## Reste à faire (prochaine étape en premier)
- Attendre les réponses de RKO (questions §9 du rapport) puis ajuster les paramètres poussins (stock, acompte minimum, répartition, frais de livraison).
- Ouvrir une PR de la branche vers main sur INTENDANCE-BUSINESS- quand RKO valide (non faite : pas demandée).
- Priorité 1 de l'audit : corriger l'annulation vente/achat (Payment inverse), trésorerie du bilan, contrôle d'équilibre réel.

## Notes / pièges
- Le dépôt comptaup-desktop-releases ne contient PAS le code de ComptaUp.
- Pas d'accès à la base de production de CVS : audit sur le code seulement.
- Tests API locaux : Postgres 16 lancé à la main sur le port 5433 (pas de Docker dans l'environnement cloud).
