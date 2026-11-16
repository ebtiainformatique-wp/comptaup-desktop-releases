# Commandes de poussins — mode d'emploi et règles

Livré le 16/11/2026 (branche `claude/practical-turing-q0ssas`). Menu : **Commandes de poussins** (secteur Vétérinaire), page `/poussins`.

## Le cycle

1. **Arrivage** : créé dans *Ma vitrine* (libellé, souche/catégorie, date, places, prix de vente).
2. **Commande** : au comptoir (bouton *Nouvelle commande*) ou par le client sur la vitrine. Le prix est **figé** à la commande. Les places de l'arrivage sont décomptées (pas de surréservation possible).
   - Une commande saisie au comptoir est directement *Confirmée*. Une réservation vitrine arrive en *Reçue* et devient une fiche client à la confirmation.
3. **Acomptes** : un ou plusieurs (espèces, MTN MoMo, Orange Money, virement…). L'argent entre en caisse ou sur le compte, mais **ce n'est pas encore du chiffre d'affaires** : c'est une avance du client.
4. **Réception de l'arrivage** (onglet *Arrivages*) : quantité reçue, morts à l'arrivée, coût unitaire. Les poussins vivants sont répartis **par ordre de commande** ; les commandes entièrement couvertes passent en *Prête*, et l'écran signale le manque éventuel.
5. **Livraison** (totale ou partielle) : une **vente** est créée pour la quantité livrée. Les acomptes y sont imputés automatiquement, sans nouveau mouvement de caisse. On peut encaisser le solde à la livraison, et le reste éventuel devient une **créance** client.
6. **Annulation** (patron ou comptable uniquement) : on indique le montant remboursé (sortie de caisse ou de compte). La part non remboursée est **conservée** et comptée en vente « Acompte conservé ».

## Ce qu'on peut suivre
- **Fiche commande** : montant, livré / reste, payé, acompte détenu, reste dû, liste des paiements, des livraisons (avec n° de vente) et **historique daté** de chaque action (qui, quand, quoi).
- **Liste** filtrable par statut, arrivage, nom, téléphone ou n° de commande.
- **Par arrivage** : commandés, encaissé, reçus vivants, livrés / à livrer, ventes, coût par poussin vivant, marge sur les poussins livrés.
- **Par souche** : commandés / livrés.
- **Acomptes détenus** (dette envers les clients) et **reste à encaisser**.

## Points à confirmer avec RKO (paramètres par défaut retenus)
- Les poussins sont **hors stock** (pas d'article en inventaire). À changer si vous voulez un article « Poussin J1 ».
- Répartition d'un arrivage incomplet : **premier commandé, premier servi**.
- Pas d'acompte minimum obligatoire.
- Pas de frais de livraison automatiques.

## Technique
- Modèles : `ChickOrder`, `ChickOrderDelivery`, `ChickOrderEvent` ; champs de réception sur `ShowcaseArrival` ; `Payment.chickOrderId`.
- Migration `20261116100000_chick_orders` : reprend automatiquement les réservations vitrine existantes (codes `CMD-VITR-xxxx`).
- API : `/api/v1/chick-orders` (voir `apps/api/src/routes/chick-order.route.ts`). Tests : `apps/api/test/chick-order.test.ts` (11 scénarios, dont la concordance trésorerie du bilan = caisse + Mobile Money).
