STATUS: IN_PROGRESS
Agent: claude — 2026-11-24

## Objectif
Audit des incohérences bilan / compte de résultat / tableau de bord (cas cabinet vétérinaire),
code dans le dépôt INTENDANCE-BUSINESS- (branche main). Phase actuelle : explication à RKO,
aucune modification de code encore.

## Fait
- Exploration de main (2dfea4d, 24/11) : le moteur partie double est fusionné sur main
  (journal, ledger-reports, stock-accounting avec stock d'ouverture + variation mensuelle 6031,
  clôture, TVA, paie). Les rapports ne lisent le grand livre que si Company.ledgerReportsEnabled
  (bascule par /platform-admin/ledger-cutover, sans écran).
- Ancien modèle (par défaut) : CR = ventes HT − achats de la période, sans variation de stock ;
  capitaux propres = solde d'équilibrage (report.service.ts buildBalanceSheet).

## Reste à faire (prochaine étape en premier)
- Attendre les décisions de RKO (corriger l'ancien modèle ou finir la bascule grand livre).
- Écarts repérés côté grand livre : ventes de services toutes en 701 (sale-accounting.service.ts:47),
  capitaux propres non lus au grand livre, stock du bilan = quantité actuelle × costPrice,
  tableau de bord jamais branché sur le grand livre, détail des charges perdu (autresCharges).

## Notes / pièges
- Cloner INTENDANCE-BUSINESS- dans /home/user/intendance-business- (add_repo).
