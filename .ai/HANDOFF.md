STATUS: DONE
Agent: claude — 2026-11-24

## Objectif
Etats financiers conformes SYSCOHADA (bilan, compte de resultat, tableau de bord coherents),
code dans INTENDANCE-BUSINESS-, branche `claude/etats-financiers-normes` (pas de PR, pas en prod).
Demande RKO du 24/11 : verifier si CVS est sur le grand livre + brancher tout ce qui doit l'etre.

## Fait
- Script lecture seule `npm run ledger:check -- --name "CVS"` (a lancer par RKO sur la prod).
- Ventes 701/706, achats ventiles par nature, migration 20261124200000_financial_statements_roles.
- A-nouveaux des creances/dettes manuelles (+ openingDate), etape dans la reprise d'historique.
- syscohada-statements.service.ts : CR SYSCOHADA (soldes intermediaires, CMV) + bilan decompose,
  rapports version 2 (methodVersion), tableau de bord et score de sante alignes.
- Bug date comptable : entryDate en jour metier (toBusinessDate / toBusinessDateBound).
- Garde-fous de saisie, scripts/ledger-realign.ts (simulation par defaut), vues web SYSCOHADA.
- Tests : etats-financiers-syscohada.test.ts (8) + garde-fous-saisie.test.ts (4) ;
  suite complete 1175/1175 au 1er passage (avant garde-fous), 2e passage en cours.
- AUDIT.md, fixtures/attendu.md a la racine de INTENDANCE-BUSINESS-.

## Reste a faire (prochaine etape en premier)
- Code termine et verifie (suite API 1179/1179, web 28/28). Decisions RKO en attente : voir
  RAPPORT.md §6 dans INTENDANCE-BUSINESS- (lancer ledger:check sur CVS, fusion avec la branche
  claude/partie-double-avant-cvs de l'autre session AVANT la bascule CVS, ledger:realign, PR).

## Notes / pieges
- Base de test locale : Postgres 16 du conteneur sur le port 5433 (data /var/tmp/pgdata),
  pas de Docker. `npm run test:db:setup` apres chaque migration.
- La reprise d'historique met les soldes inexpliques en RESERVES (111) alors que le stock
  d'ouverture va en REPORT_A_NOUVEAU (121) : a trancher par RKO.
