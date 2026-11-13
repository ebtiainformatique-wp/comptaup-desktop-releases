STATUS: IN_PROGRESS
Agent: claude — 2026-11-13

## Objectif
Audit + correction des etats financiers de Compta-Up (bilan, compte de resultat, tableau de bord)
selon SYSCOHADA, sur le depot INTENDANCE-BUSINESS-, branche `claude/audit-etats-financiers`.
Le client a demande de travailler en autonomie jusqu'a son retour.

## Fait
- PR ebtiainformatique-wp/INTENDANCE-BUSINESS-#100 (ventes sous prix minimum) fusionnee le 2026-11-12.
- AUDIT.md (causes racines, verdict bug/saisie), fixtures/attendu.md (calcul manuel),
  moteur commun `financial-statements.service.ts` (CMV, 601/6031, capitaux propres decomposes,
  tresorerie unique, creances ventilees, mois locaux), interface web v2, garde-fous de saisie,
  script de reclassement reversible (non execute), RAPPORT.md, fixtures/controle-final.md (44/44).
- Evaluation de la branche partie double de l'autre agent (RAPPORT.md section 6).

## Reste a faire (prochaine etape en premier)
- PR ebtiainformatique-wp/INTENDANCE-BUSINESS-#108 ouverte (924/924 tests, controle final 44/44,
  verification navigateur OK). Surveiller la CI ; NE PAS fusionner sans accord explicite du client
  (change les chiffres affiches a tous les clients). Decisions listees dans RAPPORT.md section 7.
- Ensuite : reporter CMV / classement par ligne dans la branche feat/compta-partie-double-internationale.

## Notes / pieges
- Base de test locale : postgres 16 sur le port 5433 (/var/tmp/pgdata), Docker Hub limite.
- La paie cree deja un achat "Salaires" : ne pas la recompter.
