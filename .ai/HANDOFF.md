STATUS: IN_PROGRESS
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

## Decisions RKO (24/11 soir, travail autonome demande jusqu'a la PR)
1. Fusionner moi-meme claude/partie-double-avant-cvs + claude/etats-financiers-normes (nouvelle branche commune),
   un seul jeu de comptes de charges (622/618/605/6281/627), correction dates, tests 100 %, prevenir l'autre session.
2. Rattrapage (ledger-realign) integre a la bascule ledger-cutover (dryRun = apercu, reel = corrections puis bascule).
3. Prix d'achat : avertissement a la saisie + anomalie sur bilan/CR (articles en stock sans prix d'achat).
4. Soldes d'ouverture inexpliques -> 121 Report a nouveau (pas 111, pas 471).
5. Ecritures deja datees en UTC : ne rien faire (seules les nouvelles sont corrigees) -> retirer la liste du script ? garder liste info.
6. Compte de repli 638 Autres charges externes pour le nouveau ; 628 existant renomme "ancien compte divers" ;
   rattrapage reclasse 628 divers -> 638 sur exercices ouverts.
7. Amortissement : mois de 30 jours (annee 360), dotation mensuelle constante.
8. Ouvrir une PR vers main, NE PAS fusionner.

## Reste a faire (prochaine etape en premier)
1. Recuperer la branche de l'autre session et fusionner.
2. Appliquer decisions 2,3,4,6,7. 3. Tests 100 %. 4. PR + RAPPORT.md.

## Notes / pieges
- Base de test locale : Postgres 16 du conteneur sur le port 5433 (data /var/tmp/pgdata),
  pas de Docker. `npm run test:db:setup` apres chaque migration.
- La reprise d'historique met les soldes inexpliques en RESERVES (111) alors que le stock
  d'ouverture va en REPORT_A_NOUVEAU (121) : a trancher par RKO.
