STATUS: IN_PROGRESS
Agent: claude — 2026-11-16

## Objectif
1. Audit complet ComptaUp (code dans le dépôt INTENDANCE-BUSINESS-) pour la pharmacie/clinique vétérinaire CVS.
2. Module complet de commandes de poussins (commande comptoir, acomptes, réception arrivage, livraison -> vente, historique).

## Fait
- Audit rédigé : docs/rapports/31-audit-comptable-cvs-2026-11-16.md (copie aussi dans INTENDANCE-BUSINESS- docs/audit/, commit local 2b3f4d3 sur branche claude/practical-turing-q0ssas, non poussé faute de droit push).
- Rapport publié (artifact claude.ai/artifact/Fsjwqs3zvMB3mMQ3YNEamb) et envoyé par email (momene.rko@gmail.com) avec 10 questions.

## Reste à faire (prochaine étape en premier)
- Module poussins dans INTENDANCE-BUSINESS- (branche claude/practical-turing-q0ssas) : migration Prisma, service, routes, page web, tests.
- Obtenir droit push sur INTENDANCE-BUSINESS-.
- Attendre réponses aux questions (voir §9 du rapport).

## Notes / pièges
- Le dépôt comptaup-desktop-releases ne contient PAS le code de ComptaUp (seulement le relais IA).
- Pas d'accès à la base de production de CVS : audit sur le code seulement.
