STATUS: IN_PROGRESS
Agent: claude — 2026-11-16 (après-midi)

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

## Reste à faire
- Bascule CVS (hors de portée de l'agent : prod injoignable) : confirmer zone OHADA + reprise historique ; déclarer stock d'ouverture au 28/08/2026 (bouton Calculer) ; admin plateforme : POST /platform-admin/ledger-cutover {companyId, dryRun} puis dryRun:false. (prochaine étape en premier)
- Audit chiffres réels CVS : attendre identifiants (compte Comptable « Audit Claude ») ; compta-up.org répond 502 via le proxy (hôte autorisé mais injoignable depuis le cloud).
- Partie double : brancher les acomptes et livraisons poussins sur le grand livre après fusion des deux branches ; sous-comptes clients codés 411-<uuid> → proposer 411-<code client>.
- Ouvrir la PR de claude/partie-double-pilote-cvs quand RKO valide.

## Notes / pièges
- Tests API locaux : Postgres 16 lancé à la main (su postgres; pg_ctl -D /home/postgres/pgdata -o "-p 5433 -k /tmp" start).
- La base de test doit être recréée en changeant de branche (migrations différentes).
