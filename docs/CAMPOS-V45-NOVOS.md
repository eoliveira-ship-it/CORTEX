# Campos criados na V45 que o ficheiro nao escreve hoje

Fonte: `Notice PACTV4.5_Grande Clientele_Corporate_V45.02.xlsx`, aba `PACT Corp`,
coluna `VERSION DE CREATION` (coluna X na V45.02) a comecar por 45.

Total: 105 campos — P1 51 (50 na 45.00 + `P1 621` na 45.01), P2 42, M1 12.
Os paves C1, F1, F2 e P9 nao ganharam campos novos.

### P1 — 51 campos

| N° | Campo | Fmt/Tam | Criado | Nome |
|---|---|---|---|---|
| 612 | `P1 1001` | DATE/8 | 45 | Date de réalisation du tirage |
| 613 | `P1 1002` | DATE/8 | 45 | Date d'échéance du tirage |
| 614 | `P1 22.222` | ALPHA/1 | 45 | Indicateur différé d'amortissement |
| 615 | `P1 24.22.1` | ALPHA/1 | 45 | Indicateur dérivé en couverture |
| 616 | `P1 600` | ALPHA/1 | 45 | Indicateur Présence de recouvrement |
| 617 | `P1 601` | ALPHA/1 | 45 | Type de recouvrement à l'amiable ou contentieux |
| 618 | `P1 602` | ALPHA/1 | 45 | Statut de recouvrement |
| 619 | `P1 603` | NUM/19 | 45 | Montant recouvré depuis le défaut |
| 620 | `P1 603.1` | ALPHA/3 | 45 | Devise du montant recouvré depuis le défaut |
| 621 | `P1 604` | NUM/19 | 45 | Montant passé à perte depuis le défaut |
| 622 | `P1 604.1` | ALPHA/3 | 45 | Devise du montant passé à perte depuis le défaut |
| 623 | `P1 605` | NUM/19 | 45 | Montant tiré depuis le défaut |
| 624 | `P1 605.1` | ALPHA/3 | 45 | Devise du montant tiré depuis le défaut |
| 625 | `P1 606` | ALPHA/40 | 45 | Identifiant du contrat restructuré en cas de changement d’identifiant post restr |
| 626 | `P1 607` | ALPHA/1 | 45 | Indicateur de multi financement par plusieurs entités |
| 627 | `P1 608` | NUM/19 | 45 | Montant des prélèvements supplémentaires après le défaut |
| 628 | `P1 608.1` | ALPHA/3 | 45 | Devise du montant des prélèvements supplémentaires après le défaut |
| 629 | `P1 609` | DATE/8 | 45 | Date des prélèvements supplémentaires après le défaut |
| 630 | `P1 610` | NUM/19 | 45 | Montant des coûts directs associés à la procédure de recouvrement |
| 631 | `P1 610.1` | ALPHA/3 | 45 | Devise du montant des coûts directs associés à la procédure de recouvrement |
| 632 | `P1 611` | DATE/8 | 45 | Date des coûts directs associés à la procédure de recouvrement |
| 633 | `P1 612` | NUM/19 | 45 | Montant des frais divers |
| 634 | `P1 612.1` | ALPHA/3 | 45 | Devise du montant des frais divers |
| 635 | `P1 613` | ALPHA/1 | 45 | Indicateur engagement renouvelable |
| 636 | `P1 614` | NUM/19 | 45 | Exposure at default (EAD) standard local |
| 637 | `P1 614.1` | ALPHA/3 | 45 | Devise de l'Exposure at default (EAD) standard local |
| 638 | `P1 615` | NUM/6 | 45 | Maturité Exposure at default (EAD) standard local |
| 639 | `P1 616` | ALPHA/1 | 45 | Indicateur calcul de RWA en local au titre de la CVA prudentiel |
| 640 | `P1 617` | ALPHA/1 | 45 | Plan de roll-out |
| 641 | `P1 618` | ALPHA/1 | 45 | Type de crypto-actifs au sens de l'article 501 quinquies de CRR3 |
| 642 | `P1 619` | NUM/19 | 45 | Coefficient « Beta » pour modèles IRBA |
| 643 | `P1 620` | ALPHA/1 | 45 | Indicateur Exposition financée en devise locale |
| 644 | `P1 635` | ALPHA/1 | 45 | Indicateur Facteur de Conversion de Crédit (CCF) modèle interne |
| 645 | `P1 622` | ALPHA/1 | 45 | Indicateur de l'intention de gestion de l'opération |
| 646 | `P1 623` | ALPHA/40 | 45 | Identifiant Markit |
| 647 | `P1 624` | NUM/15 | 45 | Taux de recouvrement du Credit Default Swap (CDS) |
| 648 | `P1 625` | ALPHA/2 | 45 | Note estimée du groupe de risque ou du Tiers à l'origination des financements LB |
| 649 | `P1 626` | ALPHA/1 | 45 | Indicateur nouvelle production (trimestriel) |
| 650 | `P1 627` | ALPHA/1 | 45 | Indicateur période de fronting |
| 651 | `P1 628` | NUM/19 | 45 | Montant d'exposition réglementaire soumise au fronting |
| 652 | `P1 628.1` | ALPHA/3 | 45 | Devise du montant d'exposition réglementaire soumise au fronting |
| 653 | `P1 629` | ALPHA/1 | 45 | Indicateur Reserve Based Lending (RBL) |
| 654 | `P1 630` | NUM/19 | 45 | Exposition réglementaire soumise au RBL |
| 655 | `P1 630.1` | ALPHA/3 | 45 | Devise de l'exposition réglementaire soumise au RBL |
| 656 | `P1 631` | NUM/19 | 45 | Expositions à date d'arrêté (vision stock) sur High Yield Bonds |
| 657 | `P1 631.1` | ALPHA/3 | 45 | Devise des expositions à date d'arrêté (vision stock) sur High Yield Bonds |
| 658 | `P1 632` | NUM/19 | 45 | Expositions arrangées par la banque au cours du trimestre sur High Yield Bonds |
| 659 | `P1 632.1` | ALPHA/3 | 45 | Devise des expositions arrangées par la banque au cours du trimestre sur High Yi |
| 660 | `P1 633` | NUM/19 | 45 | Montant du Mark-to-market hors part à syndiquer |
| 661 | `P1 633.1` | ALPHA/3 | 45 | Devise du montant du Mark-to-market hors part à syndiquer |
| 662 | `P1 621` | ALPHA/8 | 45.01 | Intention de gestion de l'opération |

### P2 — 42 campos

| N° | Campo | Fmt/Tam | Criado | Nome |
|---|---|---|---|---|
| 356 | `P2 1001` | DATE/8 | 45 | Date de réalisation du tirage |
| 357 | `P2 1002` | DATE/8 | 45 | Date d'échéance du tirage |
| 358 | `P2 22.222` | ALPHA/1 | 45 | Indicateur différé d'amortissement |
| 359 | `P2 600` | ALPHA/1 | 45 | Indicateur Présence de recouvrement |
| 360 | `P2 601` | ALPHA/1 | 45 | Type de recouvrement à l'amiable ou contentieux |
| 361 | `P2 602` | ALPHA/1 | 45 | Statut de recouvrement |
| 362 | `P2 603` | NUM/19 | 45 | Montant recouvré depuis le défaut |
| 363 | `P2 603.1` | ALPHA/3 | 45 | Devise du montant recouvré depuis le défaut |
| 364 | `P2 604` | NUM/19 | 45 | Montant passé à perte depuis le défaut |
| 365 | `P2 604.1` | ALPHA/3 | 45 | Devise du montant passé à perte depuis le défaut |
| 366 | `P2 605` | NUM/19 | 45 | Montant tiré depuis le défaut |
| 367 | `P2 605.1` | ALPHA/3 | 45 | Devise du montant tiré depuis le défaut |
| 368 | `P2 606` | ALPHA/40 | 45 | Identifiant du contrat restructuré en cas de changement d’identifiant post restr |
| 369 | `P2 607` | ALPHA/1 | 45 | Indicateur de multi financement par plusieurs entités |
| 370 | `P2 608` | NUM/19 | 45 | Montant des prélèvements supplémentaires après le défaut |
| 371 | `P2 608.1` | ALPHA/3 | 45 | Devise du montant des prélèvements supplémentaires après le défaut |
| 372 | `P2 609` | DATE/8 | 45 | Date des prélèvements supplémentaires après le défaut |
| 373 | `P2 610` | NUM/19 | 45 | Montant des coûts directs associés à la procédure de recouvrement |
| 374 | `P2 610.1` | ALPHA/3 | 45 | Devise du montant des coûts directs associés à la procédure de recouvrement |
| 375 | `P2 611` | DATE/8 | 45 | Date des coûts directs associés à la procédure de recouvrement |
| 376 | `P2 612` | NUM/19 | 45 | Montant des frais divers |
| 377 | `P2 612.1` | ALPHA/3 | 45 | Devise du montant des frais divers |
| 378 | `P2 613` | ALPHA/1 | 45 | Indicateur engagement renouvelable |
| 379 | `P2 617` | ALPHA/1 | 45 | Plan de roll-out |
| 380 | `P2 618` | ALPHA/1 | 45 | Type de crypto-actifs au sens de l'article 501 quinquies de CRR3 |
| 381 | `P2 619` | NUM/19 | 45 | Coefficient « Beta » pour modèles IRBA |
| 382 | `P2 620` | ALPHA/1 | 45 | Indicateur Exposition financée en devise locale |
| 383 | `P2 635` | ALPHA/1 | 45 | Indicateur Facteur de Conversion de Crédit (CCF) modèle interne |
| 384 | `P2 625` | ALPHA/2 | 45 | Note estimée du groupe de risque ou du Tiers à l'origination des financements LB |
| 385 | `P2 626` | ALPHA/1 | 45 | Indicateur nouvelle production (trimestriel) |
| 386 | `P2 627` | ALPHA/1 | 45 | Indicateur période de fronting |
| 387 | `P2 628` | NUM/19 | 45 | Montant d'exposition réglementaire soumise au fronting |
| 388 | `P2 628.1` | ALPHA/3 | 45 | Devise du montant d'exposition réglementaire soumise au fronting |
| 389 | `P2 629` | ALPHA/1 | 45 | Indicateur Reserve Based Lending (RBL) |
| 390 | `P2 630` | NUM/19 | 45 | Exposition réglementaire soumise au RBL |
| 391 | `P2 630.1` | ALPHA/3 | 45 | Devise de l'exposition réglementaire soumise au RBL |
| 392 | `P2 631` | NUM/19 | 45 | Expositions à date d'arrêté (vision stock) sur High Yield Bonds |
| 393 | `P2 631.1` | ALPHA/3 | 45 | Devise des expositions à date d'arrêté (vision stock) sur High Yield Bonds |
| 394 | `P2 632` | NUM/19 | 45 | Expositions arrangées par la banque au cours du trimestre sur High Yield Bonds |
| 395 | `P2 632.1` | ALPHA/3 | 45 | Devise des expositions arrangées par la banque au cours du trimestre sur High Yi |
| 396 | `P2 633` | NUM/19 | 45 | Montant du Mark-to-market hors part à syndiquer |
| 397 | `P2 633.1` | ALPHA/3 | 45 | Devise du montant du Mark-to-market hors part à syndiquer |

### M1 — 12 campos

| N° | Campo | Fmt/Tam | Criado | Nome |
|---|---|---|---|---|
| 146 | `M1 202` | ALPHA/50 | 45 | Code produit local |
| 147 | `M1 500` | ALPHA/12 | 45 | Plan Produit Liquidité |
| 148 | `M1 4.44` | ALPHA/5 | 45 | Ligne Produit |
| 149 | `M1 512` | ALPHA/3 | 45 | Segment de Clientèle au sens de la liquidité |
| 150 | `M1 149` | ALPHA/5 | 45 | Sous entité |
| 151 | `M1 522` | ALPHA/1 | 45 | Indicateur Collateral réutilisable |
| 152 | `M1 636` | NUM/19 | 45 | Valeur prudente initiale |
| 153 | `M1 636.1` | ALPHA/3 | 45 | Devise de la valeur prudente initiale |
| 154 | `M1 637` | NUM/19 | 45 | Valeur prudente revalorisée |
| 155 | `M1 637.1` | ALPHA/3 | 45 | Devise de la valeur prudente revalorisée |
| 156 | `M1 638` | NUM/19 | 45 | Valeur moyenne de long terme |
| 157 | `M1 638.1` | ALPHA/3 | 45 | Devise de la valeur moyenne de long terme |
