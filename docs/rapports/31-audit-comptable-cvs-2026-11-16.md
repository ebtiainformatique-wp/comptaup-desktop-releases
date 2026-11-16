# Audit complet ComptaUp — Pharmacie / Clinique vétérinaire CVS

**Date :** 16 novembre 2026 · **Auteur :** Claude (agent IA) · **Code audité :** dépôt `INTENDANCE-BUSINESS-`, branche `main`, commit `1c5864c`

> **Limite à connaître d'abord.** J'ai audité le **code** de ComptaUp (la logique des calculs et les liens entre les modules), pas les **données réelles** de CVS. Je n'ai pas accès à la base de production (Neon). Pour vérifier que *la balance de CVS* est équilibrée et à jour, il me faut un export : liste des ventes, achats, créances, dettes, caisses/banques, stock, ou bien un accès en lecture seule à la base. Voir les questions (§9).

---

## 1. Résumé en 10 lignes

1. **ComptaUp n'est pas un logiciel de comptabilité en partie double.** Il n'y a ni plan comptable SYSCOHADA, ni journal, ni grand livre, ni balance des comptes. Les états (bilan, compte de résultat) sont **recalculés** à partir des ventes, achats, créances, dettes et paiements.
2. **Le bilan est « équilibré » par construction, pas par contrôle.** Les capitaux propres sont calculés comme *Actif − Dettes* (`report.service.ts:181-185`). Le badge « équilibré » est donc **toujours vrai**, même quand les données sont fausses. Il ne prouve rien.
3. **Trois sources de trésorerie ne concordent pas.** Le bilan lit la table `Payment`, le tableau de bord lit les soldes caisse/banque, et une partie des mouvements n'existe que d'un côté (apports, retraits, déblocage d'emprunt, annulations).
4. **Annuler une vente ou un achat ne retire pas le paiement de la table `Payment`.** La caisse est bien corrigée, mais la trésorerie du bilan reste gonflée (ventes) ou dégonflée (achats).
5. **Le compte de résultat compte les achats, pas le coût des marchandises vendues.** Il n'y a pas de variation de stock. Un mois où CVS achète beaucoup de stock paraît en perte, et le mois suivant paraît trop bénéficiaire.
6. **TVA incohérente.** Les ventes sont prises hors taxes, les achats toutes taxes comprises, et aucune dette de TVA n'existe au bilan.
7. **Paie incomplète.** Seul le salaire net est passé en charge, à la date du paiement. Les charges patronales CNPS et les retenues (CNPS salariale, IRPP) ne sont ni en charge ni en dette.
8. **Côté vétérinaire, les 3 alertes rouges de l'audit du 26/10 sont corrigées** (suppression d'un animal, chaînage du registre, sortie de stock à la délivrance). En revanche, **les consultations et les vaccins ne sont pas facturés automatiquement et ne sortent pas le stock.**
9. **Commandes de poussins : une base existe, mais elle est incomplète.** Le client peut réserver depuis la vitrine et suivre 5 statuts. Il manque : la saisie au comptoir, l'acompte, la réception de l'arrivage, la livraison transformée en vente, et l'historique. **C'est le chantier que je lance aujourd'hui** (§6).
10. **Par rapport aux référentiels** (SYSCOHADA révisé, facture électronique Cameroun 2026, loi anti-fraude française, CRA au Canada, IRS aux USA), ComptaUp est un très bon **outil de gestion**. Ce n'est pas encore un **logiciel comptable opposable** à l'administration fiscale ou à un commissaire aux comptes.

---

## 2. Méthode

- Lecture du schéma de base de données : 260 modèles et enums (`apps/api/prisma/schema.prisma`, 6 202 lignes).
- Lecture des services qui produisent les chiffres : `report.service.ts` (bilan et résultat), `sale.service.ts`, `purchase.service.ts`, `treasury.service.ts`, `cash-register.service.ts`, `receivable/payable.service.ts`, `payroll.service.ts`, `regulated-drug.service.ts`, `animal.service.ts`, `vet-consultation.service.ts`, `showcase.service.ts` (vitrine et poussins).
- Croisement avec l'audit du 26/10/2026 (`docs/audit/00-SYNTHESE.md` et suivants), pour distinguer **ce qui est corrigé** de **ce qui reste à corriger**.
- Recherche documentaire sur la digitalisation de la comptabilité (sources en §8).

Gravité : 🔴 fausse un chiffre officiel ou crée un risque légal · 🟠 incohérence ou trou fonctionnel · 🟢 confort.

---

## 3. Comptabilité générale : les calculs sont-ils justes ?

### 3.1 Bilan (`generateBalanceSheet`)

| # | Constat | Gravité | Preuve | Effet concret pour CVS |
|---|---|---|---|---|
| B1 | Capitaux propres = Actif − Dettes (valeur forcée). Le champ `balanced` est donc toujours vrai. | 🔴 | `report.service.ts:181-185, 201` | L'équilibre affiché ne garantit rien. Toute erreur ailleurs est absorbée silencieusement par les capitaux propres. |
| B2 | La trésorerie du bilan = somme des `Payment` entrants − sortants. Les apports en capital, subventions, retraits de l'exploitant, déblocages d'emprunt et virements à sens unique passent par `CashMovement` ou `BankMovement`, **sans** créer de `Payment`. | 🔴 | `report.service.ts:72-85`, `treasury.service.ts`, `cash-register.service.ts` (`creditCashManual`) | La trésorerie du bilan ≠ caisse + banque + Mobile Money du tableau de bord. Exemple : un apport de 500 000 FCFA en caisse n'apparaît pas au bilan. |
| B3 | L'annulation d'une vente reverse la caisse ou la banque, mais **ne touche pas** au `Payment` IN d'origine. Il en va de même pour l'annulation d'un achat (Payment OUT conservé). | 🔴 | `sale.service.ts:1315-1438` (`cancelSale`), `purchase.service.ts:1070+` (`cancelPurchase`) | Chaque vente annulée qui avait été encaissée gonfle la trésorerie du bilan du montant encaissé. |
| B4 | Créances et dettes « à une date passée » : le filtre porte sur le statut **actuel** et le montant payé **actuel**. | 🟠 | `report.service.ts:87-101` | Un bilan au 31/10 généré le 16/11 omet une créance de fin octobre réglée le 5/11. Le bilan d'une date passée change donc avec le temps. |
| B5 | Le stock est toujours valorisé « aujourd'hui », quelle que soit la date du bilan. | 🟠 | `report.service.ts:150-163` | Un bilan de clôture d'exercice est impossible à reproduire. |
| B6 | Les dettes financières et les placements sont pris à leur valeur actuelle, pas à la date du bilan. | 🟠 | `report.service.ts:128-148` | Même problème que B5. |
| B7 | Pas de TVA collectée ou déductible à payer, ni de dettes sociales ou fiscales (CNPS, IRPP) au passif. | 🔴 | absence dans `BalanceSheet` | Le passif est sous-évalué et les capitaux propres sont gonflés d'autant. |
| B8 | Pas de capital social, de report à nouveau ni de résultat de l'exercice distingués : un seul bloc « capitaux propres ». | 🟠 | `BalanceSheet.passif` | Ce n'est pas le format SYSCOHADA. L'expert-comptable doit tout refaire. |
| B9 | Créances créées manuellement (`createReceivable`) sans vente ni produit associé. | 🟠 | `receivable.service.ts:184-222` | L'actif augmente sans produit au résultat. L'écart part dans les capitaux propres (B1). |
| B10 | Suppression définitive possible d'une créance ou d'une dette, même partiellement payée. | 🟠 | `receivable.service.ts:391`, `payable.service.ts:295` | Aucune trace pour un contrôle fiscal (le CGI et l'AUDCIF exigent l'intangibilité des écritures). |

### 3.2 Compte de résultat (`generateIncomeStatement`)

| # | Constat | Gravité | Preuve | Effet |
|---|---|---|---|---|
| R1 | Les charges = **achats** de la période, sans variation de stock (comptes 6031 et 6032 en SYSCOHADA). | 🔴 | `report.service.ts:357-413` | Une pharmacie vétérinaire constitue des stocks : son résultat mensuel oscille artificiellement. Le résultat du compte de résultat ≠ la variation des capitaux propres du bilan. |
| R2 | Ventes en **HT** (`lineTotal / (1+TVA)`), achats en **TTC** (`totalAmount`). | 🔴 | `report.service.ts:318-336` vs `:375-385` | Pour une entreprise assujettie, les charges sont gonflées de la TVA déductible et le résultat est sous-évalué. |
| R3 | Salaires = **net payé**, à la date du paiement, via un achat technique « Salaires ». | 🔴 | `payroll.service.ts:533-570` | Les charges patronales CNPS sont absentes, et le salaire d'octobre payé le 5 novembre tombe en novembre. |
| R4 | Aucune dotation aux amortissements, alors que le bilan déduit l'amortissement de l'actif. | 🔴 | absent de `computeExpensesByCategory` | Incohérence bilan/résultat : la perte de valeur des immobilisations n'apparaît jamais comme une charge. |
| R5 | Classement des charges par **nom** de catégorie (« Loyer », « Transport »…), pas par compte. | 🟠 | `report.service.ts:341-355` | Une catégorie personnalisée tombe dans « Autres charges ». Pas de passage vers les comptes 60 à 66. |
| R6 | Pas de distinction exploitation / financier / HAO, ni de soldes intermédiaires (marge commerciale, VA, EBE). | 🟠 | commentaire `:548-555` | Ce n'est pas le format SYSCOHADA du compte de résultat. |
| R7 | Les consommations d'intrants s'ajoutent aux achats : risque de **double comptage** si l'intrant a été acheté dans la catégorie « Marchandise » la même période. | 🟠 | `report.service.ts:397`, `stock-consumption.service.ts` | Pour CVS (aliments, médicaments utilisés en soins), la charge risque d'être comptée deux fois. À vérifier sur les données. |
| R8 | « Autres produits » saisis à la main au moment de générer, puis répartis également entre les mois. | 🟢 | `:466-469` | Pratique, mais ce n'est pas une écriture : rien n'est conservé ni justifié. |

### 3.3 Trésorerie, caisse, banque

- ✅ Une vente au comptant crée bien **ensemble** le paiement, le crédit de caisse ou de banque, la créance et la sortie de stock, dans **une seule transaction** (`sale.service.ts:960-1140`). C'est solide.
- ✅ L'annulation reverse correctement la caisse et la banque (mouvements `ANNULATION_VENTE_OUT`).
- 🔴 Mais il existe trois « vérités » : `Payment` (bilan), `CashRegister.balance` et `BankAccount.balance` (tableau de bord), et `CashMovement`/`BankMovement` (historique). Il manque un **contrôle de concordance** automatique.
- 🟠 Le solde négatif de caisse est autorisé par défaut (`allowNegativeBalance @default(true)`). Une caisse physique ne peut pas être négative : c'est le signe d'une sortie non saisie.
- 🟠 Pas de rapprochement bancaire (import de relevé, pointage), déjà signalé le 26/10.

### 3.4 Intangibilité et clôture

- 🔴 **Pas de clôture d'exercice ni de verrouillage de période.** On peut créer ou modifier une vente ou un achat daté d'un mois déjà « clos », supprimer une créance, etc. Les rapports enregistrés sont des **photos** (`dataSnapshot`) qui ne correspondent plus aux données après modification.
- 🟠 Une vente à crédit non réglée peut voir ses articles modifiés (`updateSale`). Une facture émise ne devrait plus changer (seulement être annulée par un avoir).
- 🟢 Point fort : un journal d'audit existe (`AuditLog`, `middleware/auditTrail.ts`), et le registre des médicaments réglementés est chaîné par hachage. **Il faut étendre ce principe aux ventes** (exigence de type « loi anti-fraude » et facture électronique).

---

## 4. Liens entre modules : ce qui est relié, ce qui devrait l'être

| Flux | Relié ? | Détail |
|---|---|---|
| Vente → stock, caisse/banque, créance, paiement | ✅ | Atomique (une transaction). |
| Achat → stock, caisse/banque, dette fournisseur | ✅ | Idem. |
| Annulation vente/achat → caisse/banque/stock | ✅ | |
| Annulation vente/achat → table `Payment` (bilan) | ❌ | Constat B3. |
| Apport, retrait, emprunt → bilan | ❌ | Constat B2. |
| Paie → charges | ⚠️ partiel | Net seulement (R3). |
| Paie → dettes sociales | ❌ | |
| Immobilisation → dotation aux amortissements | ❌ | R4. |
| **Consultation vétérinaire → vente** | ❌ manuel | `VetConsultation.saleId` est posé à la main (`vet-consultation.service.ts:146-171`). Risque d'**actes non facturés**. |
| **Acte vétérinaire avec produit → sortie de stock** | ❌ | `VetActLine.productId` existe, mais aucun mouvement de stock n'est créé. |
| **Vaccination → sortie de stock du vaccin** | ❌ | `VaccinationRecord.productId` existe, sans sortie de stock. |
| Délivrance réglementée → stock | ✅ corrigé | `regulated-drug.service.ts:131-200` (corrigé depuis le 26/10). |
| Suppression d'un animal avec historique | ✅ corrigé | Bloquée avec un message clair (`animal.service.ts`). |
| Valeur du stock (bilan = indicateurs = fiche produit) | ✅ corrigé | Une seule formule partout : `COALESCE(costPrice, 0)`. |
| **Réservation de poussins → client** | ⚠️ | Rattachée si le numéro de téléphone correspond. |
| **Réservation de poussins → paiement / acompte** | ❌ | Aucun lien : l'argent reçu est soit hors système, soit saisi comme vente avant livraison (produit constaté trop tôt). |
| **Arrivage de poussins → achat fournisseur / stock** | ❌ | `ShowcaseArrival` n'est qu'une annonce publique (libellé, date, places). |
| **Livraison de poussins → vente / facture** | ❌ | Le statut « Livré » ne crée rien en comptabilité. |
| Vente d'animaux d'une bande → cheptel | ✅ | `applyLivestockMovement`. |

---

## 5. Spécifique CVS (vétérinaire et pharmacie vétérinaire)

### Ce qui fonctionne bien
- Fiches animaux, dossier médical, agenda avec protection contre le double rendez-vous (verrou Postgres), rappels de vaccins automatiques par email, satisfaction client, page « Pilote cabinet ».
- Registre des médicaments réglementés en ajout seul, chaîné, avec contre-passation et (désormais) sortie de stock.
- Lots, péremption et FEFO sur les ventes.

### Ce qui manque ou est fragile
1. 🔴 **Facturation automatique des consultations** : à la clôture d'une consultation, proposer « Créer la facture » qui reprend les actes et les produits. Sinon, risque de perte de chiffre d'affaires.
2. 🔴 **Sortie de stock des produits utilisés en soins et vaccinations.** Aujourd'hui, le stock théorique reste supérieur au stock réel, et l'écart d'inventaire part en perte inexpliquée.
3. 🟠 Double notion de chiffre d'affaires vétérinaire (actes déclarés ≠ ventes facturées), déjà signalée le 26/10, toujours ouverte.
4. 🟠 Rappels uniquement par email : au Cameroun, **WhatsApp ou SMS** sont le canal réel.
5. 🟠 Pas de page de saisie de présence du personnel (l'API existe).
6. 🟢 Ordonnance vétérinaire imprimable (format réglementaire), avec lien vers le registre.

---

## 6. Commandes de poussins : état des lieux et chantier du jour

### Ce qui existe déjà (vitrine publique)
- Le cabinet publie des **arrivages** (`ShowcaseArrival` : libellé, catégorie, date, places disponibles, prix unitaire).
- Le client réserve en ligne : quantité, retrait au cabinet ou livraison à la ferme. Les places sont décomptées sans surréservation possible.
- Le cabinet fait avancer un statut : Reçue → Confirmée → Prête → Livrée / Annulée. L'annulation rend les places.
- Notification interne, email et message WhatsApp pré-rempli.

### Ce qui manque pour le besoin exprimé
| Besoin | Statut |
|---|---|
| Saisir une commande **au comptoir ou par téléphone** (pas seulement via la vitrine) | ❌ |
| Enregistrer **un ou plusieurs acomptes** (espèces, Mobile Money, banque), avec reçu | ❌ |
| Montant total figé à la commande (prix × quantité) et reste à payer | ❌ (la quantité est dans du JSON libre) |
| **Réceptionner l'arrivage** : quantité réellement reçue, morts à l'arrivée, fournisseur (couvoir), coût d'achat | ❌ |
| Répartir les poussins reçus entre les commandes (servies en totalité, en partie ou reportées) | ❌ |
| **Livrer** : quantité livrée, date, transformation en **vente** avec reprise des acomptes | ❌ |
| **Historique** : journal daté de chaque événement d'une commande | ❌ |
| Synthèse **par arrivage** (commandé, payé, reçu, livré, reste) et **par client** | ❌ |
| Synthèse **par souche ou type de poussin** (chair, pondeuse, race locale…) | ❌ |
| Remboursement ou avoir en cas d'annulation après acompte | ❌ |

### Ce que je développe aujourd'hui (branche `claude/practical-turing-q0ssas`)
1. **Données :** commande de poussins (client, arrivage, souche, quantité, prix figé, total, payé, livré, statut), paiements d'acompte, événements d'historique, et réception d'arrivage (quantité reçue, pertes, coût, fournisseur).
2. **Comptabilité :** chaque acompte crée un `Payment` + mouvement de caisse/banque (donc visible en trésorerie), rattaché à la commande. À la livraison, une **vente** est créée pour la quantité livrée ; les acomptes y sont imputés, et le chiffre d'affaires est donc constaté **à la livraison** (règle comptable correcte : l'acompte est une dette envers le client tant que rien n'est livré).
3. **Écrans :** liste des commandes avec filtres, fiche commande (paiements, historique, livraison), page arrivage (réception et tableau de synthèse).
4. **Tests automatisés** de bout en bout.

---

## 7. Comparaison avec les pratiques et référentiels

| Exigence | Référence | ComptaUp aujourd'hui |
|---|---|---|
| Plan comptable, journaux, grand livre, balance | SYSCOHADA révisé (obligatoire depuis 2018 dans les 17 pays OHADA) | ❌ Absent : états reconstruits, pas d'écritures |
| États financiers au format normalisé (bilan, compte de résultat, TFT, notes) | AUDCIF / SYSCOHADA | ⚠️ Format simplifié maison |
| Système minimal de trésorerie (SMT) pour les très petites entités | SYSCOHADA révisé | ✅ C'est en fait ce que ComptaUp fait le mieux. **Il faudrait l'assumer et le nommer** pour les petits clients |
| Facture électronique normalisée et certifiée | Cameroun, loi de finances 2026 (plateforme DGI) ; Côte d'Ivoire FNE ; RDC, Burkina SECEF | ❌ Aucune connexion ; numérotation propre seulement |
| Inaltérabilité, sécurisation, conservation, archivage des encaissements | France, CGI art. 286 I-3° bis (NF525) | ⚠️ Journal d'audit présent, mais ventes modifiables ou supprimables et pas de chaînage |
| Facture électronique entre entreprises | France : réception obligatoire depuis le 01/09/2026, émission par les PME au 01/09/2027 | ❌ (pertinent seulement pour un lancement en Europe) |
| Registres électroniques exportables dans un format courant, conservation 6 ans | Canada, ARC (circulaire IC05-1) | ⚠️ Exports listes Excel et PDF, pas d'export comptable complet (type FEC) |
| Méthode d'engagement dès qu'il y a des stocks ; mêmes méthodes pour la fiscalité et les livres | États-Unis, IRS Publication 583 | ⚠️ Mélange : trésorerie pour certaines choses, engagement pour d'autres |
| Pas de double saisie avec Excel ; sauvegardes | Bonnes pratiques PME Afrique | ✅ Hors ligne, multi-agence, mobile, vitrine : nettement au-dessus des outils importés |

**Lecture :** sur le terrain africain, la force de ComptaUp est d'être un **outil de gestion quotidienne** (caisse, stock, créances, Mobile Money, secteurs métiers) très au-dessus de la moyenne. Sa faiblesse est l'absence de **couche comptable normée**. Les éditeurs qui réussissent en zone OHADA combinent les deux : la saisie métier simple génère automatiquement des **écritures** dans un vrai plan comptable.

---

## 8. Propositions (par ordre de priorité)

### Priorité 1 — Fiabilité des chiffres (1 à 2 semaines)
1. **Corriger B3** : à l'annulation d'une vente ou d'un achat, créer un `Payment` inverse (ou marquer le paiement annulé et l'exclure du bilan).
2. **Corriger B2** : créer un `Payment` (ou une source unique) pour les apports, retraits, emprunts et virements. Mieux : calculer la trésorerie du bilan **à partir des mouvements caisse et banque**, qui sont la vérité physique.
3. **Remplacer le badge « équilibré »** par un vrai contrôle de concordance : trésorerie du bilan = soldes caisse + banque ; capitaux propres d'ouverture + résultat + apports − retraits = capitaux propres de clôture. Afficher l'écart s'il existe.
4. **Variation de stock au compte de résultat** (coût des marchandises vendues), pour CVS.
5. **TVA homogène** : achats en HT + compte de TVA à payer (si l'entreprise est assujettie).
6. **Créances et dettes historisées** au bilan (B4).

### Priorité 2 — Couche comptable SYSCOHADA (3 à 6 semaines)
7. Ajouter un **plan comptable SYSCOHADA** et une table **Écriture** (journal, compte, débit, crédit, pièce, date). Chaque opération métier existante (vente, achat, paiement, paie, amortissement) **génère** ses écritures automatiquement. L'utilisateur ne change pas ses habitudes.
8. **Balance des comptes, grand livre, journaux, export de type FEC.** La balance est alors équilibrée *par les écritures*, ce qui constitue une vraie preuve.
9. **Clôture de période et d'exercice** (verrouillage), avec à-nouveaux.
10. **Paie complète** : charges patronales, dettes CNPS et IRPP, rattachement à la période.
11. **Dotations aux amortissements** mensuelles automatiques.

### Priorité 3 — Métier vétérinaire et terrain
12. **Commandes de poussins** (en cours aujourd'hui).
13. Consultation → facture en un clic ; acte, vaccin ou soin → sortie de stock.
14. Rappels par **WhatsApp ou SMS** (le service WhatsApp existe déjà dans le code).
15. Ordonnance vétérinaire imprimable.

### Priorité 4 — Conformité fiscale
16. Ventes **non modifiables** une fois validées (correction par avoir), avec chaînage par hachage comme le registre.
17. Préparer le **connecteur facture électronique DGI Cameroun** (loi de finances 2026) dès que les spécifications techniques sont publiées.
18. Corriger la promesse marketing « TVA et liasses OHADA » tant que ce n'est pas livré (déjà signalé le 26/10).

---

## 9. Questions — première vague

**Données CVS**
1. Pouvez-vous me donner un accès **en lecture seule** à la base de CVS, ou un export (ventes, achats, créances, dettes, caisses/banques, stock) ? Sans cela, je ne peux auditer que le code, pas *vos* chiffres.
2. CVS est-elle **assujettie à la TVA** (régime réel) ou à l'impôt libératoire ou au forfait ? Cela change la priorité des points R2 et B7.
3. CVS a-t-elle un **expert-comptable externe** qui produit la liasse DSF ? Si oui, quel format d'export lui faciliterait la vie (Excel, FEC, Sage) ?

**Poussins**
4. Les poussins sont-ils **achetés à un couvoir** puis revendus (négoce), ou **produits par CVS** ? (Je pars sur le négoce par défaut.)
5. Quelles **souches ou types** proposez-vous (chair Cobb/Ross, pondeuses, race locale, pintadeaux…) ? Le prix varie-t-il selon la souche ?
6. **Acompte** : un pourcentage minimum est-il exigé (par exemple 50 %) ? Faut-il bloquer la confirmation tant qu'il n'est pas payé ?
7. Si l'arrivage livre **moins** que prévu (mortalité, retard du couvoir) : servez-vous les commandes par **ordre d'arrivée** (premier payé, premier servi) ou au prorata ?
8. Annulation après acompte : **remboursement**, **avoir** pour un prochain arrivage, ou acompte conservé ?
9. Livraison à la ferme : y a-t-il des **frais de transport** facturés ?
10. Les poussins doivent-ils entrer **en stock** (article « Poussin chair J1 ») ou rester hors stock (commandés et livrés directement) ?

**Organisation**
11. Quelle adresse email utiliser en priorité pour les rapports ? J'écris à **momene.rko@gmail.com**. Je n'ai pas pu vérifier l'orthographe exacte de l'adresse « Eric Bruno Tiano Soué » (les accents ne sont pas possibles dans une adresse Gmail).
12. Je ne peux **pas envoyer de WhatsApp** depuis cet environnement. Le canal disponible est l'email et l'application Claude (notifications sur votre téléphone).

---

## Sources consultées
- OHADA — SYSCOHADA révisé, d'application obligatoire depuis le 1er janvier 2018 : https://www.ohada.com/actualite/2238/syscoa-revise-ou-systeme-comptable-ohada-syscohada-quel-referentiel-appliquer.html
- OHADA — Avis techniques relatifs à l'AUDCIF : https://ohada.com/uploads/actualite/4422/Avis-techniques-relatifs-a-l-AUDCIF.pdf
- Edicom — Facturation électronique obligatoire au Cameroun (loi de finances 2026) : https://edicomgroup.com/fr/blog/facturation-electronique-obligatoire-au-cameroun
- Banqup — Radar de conformité Afrique : https://www.banqup.com/fr-be/resources/radar-de-conformite/afrique
- Ecomatin — BAD : 100 milliards FCFA de recettes grâce à la facture électronique : https://ecomatin.net/recettes-fiscales-le-cameroun-pourrait-capter-100-milliards-fcfa-de-plus-grace-a-la-facturation-electronique-bad
- Service-public.fr — Facturation électronique : https://entreprendre.service-public.gouv.fr/actualites/A17450
- Keobiz — Logiciel de caisse certifié anti-fraude (CGI 286 I-3° bis) : https://www.keobiz.fr/fiches-pratiques/logiciel-caisse-certifie-anti-fraude/
- ARC Canada — IC05-1 Tenue de registres électroniques : https://www.canada.ca/en/revenue-agency/services/forms-publications/publications/ic05-1/electronic-record-keeping.html
- IRS — Publication 583, Starting a Business and Keeping Records : https://irs.gov/publications/p583
- Cameroun24 — Production de poussins d'un jour : https://cameroun24.net/article/25246-production-de-poussins-dun-jour-le-commerce-prend-des-ailes.html
- Kolonell — Comptabilité SaaS Afrique 2026 (source éditeur, à prendre avec prudence) : https://kolonell.com/fr/blog/comptabilite-saas-afrique-outils-2026
