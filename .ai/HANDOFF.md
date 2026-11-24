STATUS: IN_PROGRESS
Agent: claude — 2026-11-24

## Objectif
Etats financiers conformes SYSCOHADA (bilan, compte de resultat, tableau de bord coherents),
code dans INTENDANCE-BUSINESS-, branche `claude/etats-financiers-normes` (pas de PR, pas en prod).
Demande RKO du 24/11 : verifier si CVS est sur le grand livre + brancher tout ce qui doit l'etre.

## Fait
- Script lecture seule `npm run ledger:check -- --name "CVS"` (apps/api/scripts/check-ledger-status.ts) :
  a lancer par RKO sur la prod (pas d'acces base ici).
- Ventes 701/706, achats ventiles (601 / 622 / 618 / 605 / 6281 / 627 / repli 628), migration
  20261124200000_financial_statements_roles.
- Bornes de mois en heure metier (listBusinessMonthBuckets), fin de periode affichee inclusive (web).
- Repartition comptant/credit du tableau de bord basee sur les creances nees des ventes.
- A-nouveaux des creances/dettes manuelles (opening-balance-accounting.service.ts) + etape migration.
- Base de reference : 1167/1167 tests verts avant modifications ; tests comptables verts apres.

## Reste a faire (prochaine etape en premier)
1. Compte de resultat SYSCOHADA lu au grand livre (soldes intermediaires, par code de compte).
2. Bilan SYSCOHADA au grand livre : capitaux propres decomposes, ecart affiche, stock 31x.
3. Tableau de bord branche sur la meme source quand ledgerReportsEnabled.
4. Script de realignement (dry-run) pour entreprises deja migrees (701->706, charges par nature,
   a-nouveaux manquants).
5. Garde-fous de saisie (categorie charge sur produit, prix d'achat obligatoire, alerte achat).
6. Jeu de test + fixtures/attendu.md + tests d'invariants ; AUDIT.md, RAPPORT.md.

## Notes / pieges
- Base de test locale : Postgres 16 du conteneur sur le port 5433 (data /var/tmp/pgdata),
  pas de Docker. `npm run test:db:setup` apres chaque migration.
- La reprise d'historique met les soldes inexpliques en RESERVES (111) alors que le stock
  d'ouverture va en REPORT_A_NOUVEAU (121) : a trancher par RKO.
