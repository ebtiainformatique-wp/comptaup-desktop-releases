STATUS: IN_PROGRESS
Agent: claude — 2026-11-24 (soir)

## Objectif
Pilote ComptaUp pour CVS (clinique/pharmacie vétérinaire) : module poussins, partie double, audit des chiffres réels.

## Fait
- Audit (docs/rapports/31-audit-comptable-cvs-2026-11-16.md). Correction : la partie double EXISTE sur la branche feat/compta-partie-double-internationale (non fusionnée), l'audit portait sur main.
- Réponses RKO aux 10 questions : TVA régime réel ; expert-comptable externe → export Excel ; poussins achetés au couvoir ; liste fixe de souches + prix ; acompte libre ; répartition manuelle ; annulation au cas par cas ; livraison gratuite ; poussins en stock.
- Module poussins v2 (souches, stock, achat couvoir, répartition manuelle) : PR https://github.com/ebtiainformatique-wp/INTENDANCE-BUSINESS-/pull/121 (branche claude/practical-turing-q0ssas), 1043 tests OK.
- Partie double : branche claude/partie-double-pilote-cvs = feat/compta-partie-double-internationale + merge de main (143 fichiers / 1107 tests OK) + balance/grand livre/journal/export Excel (/comptabilite/livres).
- Partie double (suite) : sous-comptes tiers séquentiels (4110001…) ; inventaire intermédiaire (311/6031, stock d'ouverture obligatoire, variation mensuelle auto + bouton). 144 fichiers / 1114 tests OK.
- Environnement cloud "ComptaUp" : hôtes compta-up.org autorisés.

- Véto : facturation des consultations en un clic (branche claude/veto-facturation, 1033 tests OK, PR non ouverte).
- Correction audit B2/B3 : trésorerie du bilan sur mouvements caisse/banque (branche claude/audit-tresorerie-bilan, 1032 tests OK, PR non ouverte).
- PR partie double ouverte : https://github.com/ebtiainformatique-wp/INTENDANCE-BUSINESS-/pull/122

- PR ouvertes : #121 poussins, #122 partie double (+ immobilisations/emprunts au grand livre ajoutés), #123 véto facturation, #124 trésorerie bilan. CI suivie.

- 16/11 ~22h : PR #121, #122, #123, #124 FUSIONNÉES dans main (partie double incluse : poussins au grand livre, mouvements de trésorerie, immobilisations/emprunts, stock d'ouverture à une date).

- 17/11 : fusionnées #127 (pagination ventes/achats), #128 (produits pris à crédit affichés avec la créance), #129 (reprise d'une vente refusée à sa date d'origine), #130 (Stock > Changer les unités en masse), #131 (migration : produits 1 L de « Cabinet Vétérinaire Le Suivi » flacon → bidon, appliquée au déploiement, garde-fou une seule entreprise), #132 (historique Dépenses séparé des Achats, onglets + filtre kind).
- Inventaire CVS « remarques AJUSTE » (30/10, annoté 05/11) : DÉJÀ INTÉGRÉ en prod les 6, 14 et 15/11 par la session « Diagnostic cabinet vétérinaire ComptaUp » (PC de RKO) : produits nouveaux créés par script les 6 et 14/11, doublons supprimés/fusionnés (CVS 417 → 370 produits), 7 ajustements STOCKTAKE, achats déjà saisis comptant (n°3, 4, 6, 58). NE PAS RÉIMPORTER. Entreprise CVS id 3bb18d12-0d08-41ab-b61d-297af2ecff74.
- Consigne RKO : ne plus récapituler le travail validé ; seulement tâche en cours / fait / blocages.

- 17/11 soir : PR #136 (claude/poussins-liaisons, CI vert sur le 1er commit) : client existant dans Nouvelle commande, section Commandes de poussins dans la fiche client, souche liée à un article de stock, « Programmer un arrivage » + commande au couvoir (prévisionnel), relevé client avec avances poussins (solde négatif = CVS doit au client). FUSIONNÉE le 17/11 ~23h.
- PR #137 règle relais agents (CLAUDE.md) FUSIONNÉE.

- Nuit du 17→18/11 (RKO dort, consigne : avancer seul, ne rien fusionner, rapport au réveil) :
  - Vitrines : 3 styles ajoutés (Moderne, Magazine, Pagne) → 6 styles × 10 activités, artifact https://claude.ai/artifact/GsNxfN3mx6xC5atf1M6KpZ (photos africaines réutilisées).
  - Couleurs : 4 palettes proposées (A Vert savane recommandée, B Soleil, C Forêt, D Wax), artifact https://claude.ai/artifact/RUqTaw4a4JTJ5ATfKh7RuR. Ne rien modifier dans l'UI avant choix.
  - Audit fait (68 pages, copie locale CVS, bascule partie double testée : balance équilibrée, 571/521/411/401 = réels). Rapport : https://claude.ai/artifact/AWHGESZTV2ewtLBZMZDZEM
  - #138 (acompte couvoir) FUSIONNÉE sur « ok fusion » de RKO.
  - PR #139 (claude/audit-nuit-corrections) : inscription 500 (téléphone d'inscription abandonnée), compte de résultat (achats de stock en achats de marchandises), reprise rétroactive (acomptes poussins → 4191, acomptes couvoir → 4091), menu Prochainement nettoyé, page Livres sans zone. 1158 tests OK. FUSIONNÉE le 18/11 sur « ok fusion » de RKO. Prochaine étape : activer la partie double chez CVS avec RKO (zone OHADA → reprise historique → stock d'ouverture 28/08/2026 → bascule admin).
  - Décisions en attente RKO : régularisation trésorerie 111 → 471 ? ; dashboard marge brute au lieu de résultat net ; palette de couleurs ; vitrines à intégrer.

- 22/11 : test LOCAL complet de la partie double (copie CVS, script scratchpad pd/scenario.ts) : 22 contrôles OK (571, 52, 411, 401, 4191, 4091, 31 = réel ; balance équilibrée ; bascule OK). 3 points trouvés, en attente de décision RKO (pas à pas, point 1 d'abord) :
  1. Reprise : apports/subventions passés (mouvements de caisse APPORT_CAPITAL…) finissent en 111 Réserve légale (après activation, ils vont bien en 1013). Proposé : rejouer par origine + reste en 471.
  2. Stock d'ouverture : si sous-évalué au 28/08, le stock apparu ensuite (inventaire intégré 6/11 et 14/11, ~2,97 M) devient du bénéfice. Proposé : ouverture à la date d'activation (option A) ou écart d'inventaire (B).
  3. Après bascule, toutes les dépenses vont en 628 (détail perdu). Proposé : catégories → comptes OHADA (622 loyer, 61 transport, 605, 627…).

- 22/11 soir : décision RKO « 1 oui, 2 A, 3 oui, travail EN LOCAL, je vérifie avant de pousser ». Fait en LOCAL, NON POUSSÉ, branche locale claude/partie-double-avant-cvs (dépôt intendance-business-, depuis main 754735b) :
  - a7a71ce point 1 : reprise rejoue apports (1013), subventions (71), versements/transferts (585) ; écart de trésorerie restant → 471 (plus 111).
  - 0221be2 point 3 : rôles CHARGES_LOCATIVES 622, TRANSPORTS 61, EAU_ELECTRICITE 605, TELECOMMUNICATIONS 6281, PUBLICITE 627 (migration 20261122200000_expense_nature_roles) ; catégorie de dépense → compte ; compte de résultat (grand livre) détaillé.
  - 3277159 point 2 (option A) : page Livres propose date d'activation + valeur réelle du stock ; /accounting-zone renvoie confirmedAt.
  - Scénario local pd/scenario.ts : 22/22 contrôles OK, 1013 = 1 500 000, 111 absent, 622/61 détaillés.
  - Point soulevé à RKO : avec l'option A, les achats 2026 d'avant l'activation sont en charges (601) alors que le stock correspondant est crédité en 121 → résultat sous-évalué. Solution proposée : contrepartie partagée (stock issu d'achats rejoués → 6031, reste → 121).

- 23/11 : RKO choisit l'option a. Fait en local (b83bd94, toujours NON POUSSÉ) : à la déclaration du stock d'ouverture, la part issue des achats/ventes de l'exercice (entrées fournisseurs − sorties ventes, au coût) va en 6031, le reste en 121 ; /accounting/stock-value-at renvoie flowsValue ; la page Livres affiche la répartition. Copie CVS : résultat -15 050 (au lieu de -227 150), 22/22 OK ; 1166 tests OK.
  - RKO veut tester en local avant d'activer : tunnel public refusé par la politique de la session → fournis un git bundle (main..claude/partie-double-avant-cvs) + seed-cvs-test.mjs (copie de test via l'API locale) + LISEZMOI (scratchpad test-local/).

- 24/11 soir : RKO veut activer la partie double ce soir chez CVS. Message envoyé à la session « Compta-Up audit : bilan/résultat incohérences » (session_01DwRRryomgCk1xEkgiGPPzV). Branche claude/partie-double-avant-cvs rebasée sur origin/main (2dfea4d, PR #143-#145), migration renommée 20261124200000_expense_nature_roles, 1170 tests OK. PUSH REFUSÉ par la sécurité de la session tant que RKO n'a pas écrit explicitement « ok pousse ».
  - Proposé à RKO : 3 espaces (Opérations employés sans numéros de compte / Pilotage propriétaire / Comptabilité comptable) ; à créer en priorité : liste « À justifier » (471) et saisie d'écritures manuelles (OD) pour le comptable.

- 24/11 nuit — DÉCISIONS RKO (AskUserQuestion) : (1) fusionner #146 puis #148 moi-même SI CI vert ; (2) exercice CVS à l'activation = 01/01/2026 → 31/12/2026 ; (3) tableau de bord = marge brute + résultat net ; (4) normes, dans l'ordre : états financiers SYSCOHADA (bilan/CR format officiel + SIG, export), lettrage 411/401, charges/produits constatés d'avance (476/477 + extourne), export du journal type FEC. RKO dort : travailler en boucle jusqu'au bout.
  - PR https://github.com/ebtiainformatique-wp/INTENDANCE-BUSINESS-/pull/146 (claude/partie-double-avant-cvs) et https://github.com/ebtiainformatique-wp/INTENDANCE-BUSINESS-/pull/148 (claude/comptable-espace, empilée : espace Compta, écritures OD, 471, catégorie→compte, contrôles de clôture 471/585). 1175 tests OK.

## Reste à faire
- (prochaine étape) CI vert → fusionner #146 puis #148 (rebaser #148 sur main) ; puis dashboard marge brute ; puis les 4 chantiers normes dans l'ordre.
- (prochaine étape) Sur « ok pousse » : git push -u origin claude/partie-double-avant-cvs, PR vers main, puis « ok fusion » → déploiement → RKO active chez CVS (zone OHADA, reprise, stock d'ouverture, bascule admin).
- (prochaine étape) Attendre le test local de RKO (bundle) puis son feu vert ; ensuite pousser + PR ; puis activer chez CVS ensemble. Attendre la vérification de RKO sur la branche locale claude/partie-double-avant-cvs ; pousser + PR seulement sur son feu vert. Si la branche locale est perdue (conteneur recyclé), refaire à partir de la description ci-dessus.
- PR #138 (claude/poussins-acompte-couvoir) : acompte versé au couvoir (4091), imputé à la réception. Testée (21 + 3 compta), attend CI vert puis « ok fusion » de RKO.
- Bascule CVS (hors de portée de l'agent : prod injoignable) : confirmer zone OHADA + reprise historique ; déclarer stock d'ouverture au 28/08/2026 (bouton Calculer) ; admin plateforme : POST /platform-admin/ledger-cutover {companyId, dryRun} puis dryRun:false. (prochaine étape en premier)
- Audit chiffres réels CVS : attendre identifiants (compte Comptable « Audit Claude ») ; compta-up.org répond 502 via le proxy (hôte autorisé mais injoignable depuis le cloud).
- Partie double : brancher les acomptes et livraisons poussins sur le grand livre après fusion des deux branches ; sous-comptes clients codés 411-<uuid> → proposer 411-<code client>.
- Ouvrir la PR de claude/partie-double-pilote-cvs quand RKO valide.

## Notes / pièges
- Tests API locaux : Postgres 16 lancé à la main (su postgres; pg_ctl -D /home/postgres/pgdata -o "-p 5433 -k /tmp" start).
- La base de test doit être recréée en changeant de branche (migrations différentes).
