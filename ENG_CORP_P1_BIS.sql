-- =====================================================================
-- Objet   : Creation table ENG_CORP_P1_BIS  (SIRL-1224)
-- Source  : Notice PACTV4.5_Grande Clientele_Corporate_V45.00
--           Toutes les lignes OBJET DE COLLECTE = 'P1'
-- Nommage : corps      'P1 X.Y'   -> P1_X_Y
--           en-tete    'X.Y (P1)' -> P1_H_X_Y
-- Types   : ALPHA->VARCHAR2(long) | DATE->DATE | NUM->NUMBER(p,s)
--           p = long - signe - separateur ; s = nb decimales (col 21)
--           Champ vide dans le spool => NULL
-- Sans cle : pas de PRIMARY KEY (table de travail / historisation)
-- Colonnes ELARGIES por rapport a la notice : la precision de la notice
-- borne le FICHIER, pas la valeur stockee. Voir docs/SIRL-1224.md.
-- Champs   : 662 P1 (642 corps + 20 en-tete) + 4 techniques
-- =====================================================================

CREATE TABLE ENG_CORP_P1_BIS (
    -- ---- Colonnes techniques ---------------------------------------
    ID_ENGAGEMENT      VARCHAR2(40),             -- ref engagement (ENG_CORP_P1.ID_ENGAGEMENT)
    CD_PERIMETRE       VARCHAR2(10),             -- 'NAT02' / 'HORS_NAT02' (M2 BTR vs post-compta)
    NO_VARIANTE        NUMBER(1),                -- 1..8 : qual dos 8 SELECT do spool deu esta linha.
                                                 -- Serve o spool vPACT: ORDER BY NO_VARIANTE devolve
                                                 -- os registos pela ordem em que o ficheiro os tem hoje.
    DT_ARRETE          DATE,                     -- date d'arrete du traitement
    DT_TRAITEMENT      DATE DEFAULT SYSDATE,     -- horodatage d'alimentation
    -- ---- En-tete technique du pave P1  ('X.Y (P1)') ----------------
    P1_H_0_1   DATE           , -- 0.1 (P1)    DATE/8  Date d'arrêté
    P1_H_0_2   VARCHAR2(5)    , -- 0.2 (P1)    ALPHA/5  Entité Porteuse de Risques
    P1_H_0_3   VARCHAR2(12)   , -- 0.3 (P1)    ALPHA/12  Application source
    P1_H_0_4   VARCHAR2(1)    , -- 0.4 (P1)    ALPHA/1  Fréquence de transmission
    P1_H_0_5   VARCHAR2(12)   , -- 0.5 (P1)    ALPHA/12  Date et Heure de traitement
    P1_H_0_6   VARCHAR2(2)    , -- 0.6 (P1)    ALPHA/2  Type d'enregistrement
    P1_H_0_7   VARCHAR2(1)    , -- 0.7 (P1)    ALPHA/1  Nature de flux (Zone réservée DRG)
    P1_H_0_8   VARCHAR2(2)    , -- 0.8 (P1)    ALPHA/2  Centre de Responsabilité Comptable (Zone réservée CAsa so
    P1_H_0_9   VARCHAR2(4)    , -- 0.9 (P1)    ALPHA/4  Unité d'exploitation (Zone réservée CACIB)
    P1_H_0_99  VARCHAR2(3)    , -- 0.99 (P1)   ALPHA/3  Filler
    P1_H_1_1   VARCHAR2(20)   , -- 1.1 (P1)    ALPHA/20  Identifiant local du tiers en risque
    P1_H_1_2   VARCHAR2(10)   , -- 1.2 (P1)    ALPHA/10  Identifiant central du tiers en risque
    P1_H_1_4   VARCHAR2(30)   , -- 1.4 (P1)    ALPHA/30  Référence de l'Autorisation Mise En Place
    P1_H_1_6   VARCHAR2(30)   , -- 1.6 (P1)    ALPHA/30  Référence de la ligne de détail de l'Autorisation Mise E
    P1_H_1_8   VARCHAR2(40)   , -- 1.8 (P1)    ALPHA/40  Identifiant de la sûreté reçue
    P1_H_1_11  VARCHAR2(40)   , -- 1.11 (P1)   ALPHA/40  Identifiant de l'engagement
    P1_H_1_16  VARCHAR2(40)   , -- 1.16 (P1)   ALPHA/40  Référence de la provision sur tiers
    P1_H_1_97  VARCHAR2(2)    , -- 1.97 (P1)   ALPHA/2  Filler
    P1_H_1_98  VARCHAR2(7)    , -- 1.98 (P1)   ALPHA/7  Filler
    P1_H_1_99  VARCHAR2(11)   , -- 1.99 (P1)   ALPHA/11  Filler
    -- ---- Corps du pave P1  ('P1 X.Y', notice) ----------------------
    P1_1_1     VARCHAR2(7)    , -- P1 1.1      ALPHA/7  Méthodologie Bâloise
    P1_1_2     VARCHAR2(2)    , -- P1 1.2      ALPHA/2  Traitement moteur bâlois
    P1_2_0     VARCHAR2(6)    , -- P1 2.0      ALPHA/6  Type de risque
    P1_2_4     VARCHAR2(1)    , -- P1 2.4      ALPHA/1  Portefeuille de booking Intention de Gestion
    P1_2_6     VARCHAR2(5)    , -- P1 2.6      ALPHA/5  Ligne Métier
    P1_2_18    VARCHAR2(3)    , -- P1 2.18     ALPHA/3  Portefeuille Bâle Opération
    P1_2_29    VARCHAR2(12)   , -- P1 2.29     ALPHA/12  NATure d'Opération de l'engagement
    P1_2_99    VARCHAR2(20)   , -- P1 2.99     ALPHA/20  Code méthode IFRS9 - PD à l'origine
    P1_3_2     DATE           , -- P1 3.2      DATE/8  Date de début de l'engagement
    P1_3_3     DATE           , -- P1 3.3      DATE/8  Date de valeur de prise d'effet du contrat
    P1_3_4     DATE           , -- P1 3.4      DATE/8  Date de fin de l'engagement
    P1_3_7     NUMBER(1)      , -- P1 3.7      NUM/1  Sens de la transaction
    P1_3_8     NUMBER(18,2)   , -- P1 3.8      NUM/19 19 dont signe et 2 décimales  Montant nominal
    P1_3_9     VARCHAR2(3)    , -- P1 3.9      ALPHA/3  Devise du montant nominal
    P1_3_10    NUMBER(18,2)   , -- P1 3.10     NUM/19 19 dont signe et 2 décimales  Montant notionnel de la jambe
    P1_3_11    VARCHAR2(3)    , -- P1 3.11     ALPHA/3  Devise du montant du notionnel de la jambe payée des déri
    P1_3_12    NUMBER(18,2)   , -- P1 3.12     NUM/19 19 dont signe et 2 décimales  Montant du notionnel de la ja
    P1_3_13    VARCHAR2(3)    , -- P1 3.13     ALPHA/3  Devise du montant du notionnel de la jambe vendue des dér
    P1_3_15    VARCHAR2(1)    , -- P1 3.15     ALPHA/1  Indicateur accord de collatéralisation
    P1_3_16    VARCHAR2(1)    , -- P1 3.16     ALPHA/1  Indicateur accord de netting prudentiel
    P1_3_17    VARCHAR2(25)   , -- P1 3.17     ALPHA/25  Référence du contrat de netting prudentiel
    P1_3_19    VARCHAR2(3)    , -- P1 3.19     ALPHA/3  Devise de règlement de l'accord de netting prudentiel
    P1_3_20    NUMBER(18,10)    , -- P1 3.20     NUM/6 6 dont 4 décimales  Maturité résiduelle
    P1_3_31    VARCHAR2(12)   , -- P1 3.31     ALPHA/12  Zone libre (Ex PCCO – Nominal)
    P1_3_32    VARCHAR2(2)    , -- P1 3.32     ALPHA/2  Rôle du Tiers dans l'opération d'affacturage
    P1_3_33    VARCHAR2(2)    , -- P1 3.33     ALPHA/2  Nature d'OPCVM Garanti
    P1_3_36    VARCHAR2(1)    , -- P1 3.36     ALPHA/1  Indicateur compensation centrale
    P1_3_40    NUMBER(18,2)   , -- P1 3.40     NUM/19 19 dont signe et 2 décimales  Valeur de marché du bien immo
    P1_3_41    VARCHAR2(3)    , -- P1 3.41     ALPHA/3  Devise de la valeur de marché du bien immobilier loué à l
    P1_3_42    NUMBER(18,2)   , -- P1 3.42     NUM/19 19 dont signe et 2 décimales  Valeur hypothécaire du bien i
    P1_3_43    VARCHAR2(3)    , -- P1 3.43     ALPHA/3  Devise de la valeur hypothécaire du bien immobilier loué 
    P1_3_44    VARCHAR2(2)    , -- P1 3.44     ALPHA/2  Zone libre (Ex Localisation du bien immobilier)
    P1_3_45    VARCHAR2(1)    , -- P1 3.45     ALPHA/1  Achat en fin de contrat du bien loué
    P1_3_46    VARCHAR2(1)    , -- P1 3.46     ALPHA/1  Usage du bien immobilier apporté en garantie
    P1_3_47    VARCHAR2(1)    , -- P1 3.47     ALPHA/1  Respect des conditions réglementaires
    P1_3_50    NUMBER(18,2)   , -- P1 3.50     NUM/19 19 dont signe et 2 décimales  Montant du coût d'acquisition
    P1_3_51    VARCHAR2(3)    , -- P1 3.51     ALPHA/3  Devise du montant du coût d'acquisition
    P1_3_52    NUMBER(18,2)   , -- P1 3.52     NUM/19 19 dont signe et 2 décimales  Montant du Mark-to-Market (Mt
    P1_3_53    VARCHAR2(3)    , -- P1 3.53     ALPHA/3  Devise du montant du Mark-to-Market (MtM)
    P1_3_54    NUMBER(18,2)   , -- P1 3.54     NUM/19 19 dont signe et 2 décimales  Montant du coût amorti
    P1_3_55    VARCHAR2(3)    , -- P1 3.55     ALPHA/3  Devise du montant du coût amorti
    P1_3_56    VARCHAR2(12)   , -- P1 3.56     ALPHA/12  Zone libre (Ex PCCO – Valeur du titre en norme IFRS)
    P1_3_57    NUMBER(18,2)   , -- P1 3.57     NUM/19 19 dont signe et 2 décimales  Montant des coupons restant d
    P1_3_58    VARCHAR2(3)    , -- P1 3.58     ALPHA/3  Devise du montant des coupons restant dû
    P1_3_59    NUMBER(18,2)   , -- P1 3.59     NUM/19 19 dont signe et 2 décimales  Montant du solde du compte co
    P1_3_60    VARCHAR2(3)    , -- P1 3.60     ALPHA/3  Devise du solde du compte courant d'associé
    P1_3_61    VARCHAR2(1)    , -- P1 3.61     ALPHA/1  Traitement prudentiel des titres et créances subordonnées
    P1_3_62    VARCHAR2(20)   , -- P1 3.62     ALPHA/20  Identifiant local du tiers Garant des titres garantis (C
    P1_3_63    VARCHAR2(10)   , -- P1 3.63     ALPHA/10  Identifiant central du tiers Garant des titres garantis 
    P1_3_64    VARCHAR2(1)    , -- P1 3.64     ALPHA/1  Zone libre (Ex Indicateur titre déprécié)
    P1_3_65    VARCHAR2(19)   , -- P1 3.65     ALPHA/19  Zone libre (Ex Montant d'ajustement de valeur)
    P1_3_66    VARCHAR2(3)    , -- P1 3.66     ALPHA/3  Zone libre (Ex Devise du montant d'ajustement de valeur)
    P1_3_70    NUMBER(18,2)   , -- P1 3.70     NUM/19 19 dont signe et 2 décimales  Montant du Mark-to-Market (Mt
    P1_3_71    VARCHAR2(3)    , -- P1 3.71     ALPHA/3  Devise du montant du Mark-to-Market (MtM) net si accord d
    P1_3_72    NUMBER(18,2)   , -- P1 3.72     NUM/19 19 dont signe et 2 décimales  Montant de l'assiette régleme
    P1_3_73    VARCHAR2(3)    , -- P1 3.73     ALPHA/3  Devise du montant de l'assiette réglementaire
    P1_3_74    VARCHAR2(1)    , -- P1 3.74     ALPHA/1  Eligibilité des actifs sous-jacents des CDS TRS
    P1_3_75    VARCHAR2(2)    , -- P1 3.75     ALPHA/2  Instrument financier
    P1_3_76    VARCHAR2(1)    , -- P1 3.76     ALPHA/1  Indicateur de dénouement du CDS
    P1_3_77    VARCHAR2(1)    , -- P1 3.77     ALPHA/1  Eligibilité du dérivé de crédit à la couverture du risque
    P1_3_80    NUMBER(18,2)   , -- P1 3.80     NUM/19 19 dont signe et 2 décimales  Montant du Mark-to-Market (Mt
    P1_3_81    VARCHAR2(3)    , -- P1 3.81     ALPHA/3  Devise du montant du Mark-to-Market (MtM) brut
    P1_3_82    VARCHAR2(12)   , -- P1 3.82     ALPHA/12  Zone libre (Ex PCCO – MtM brut)
    P1_3_83    VARCHAR2(1)    , -- P1 3.83     ALPHA/1  Modèle de l'assiette interne du risque de variation
    P1_3_84    NUMBER(18,2)   , -- P1 3.84     NUM/19 19 dont signe et 2 décimales  Montant de l'assiette interne
    P1_3_85    VARCHAR2(3)    , -- P1 3.85     ALPHA/3  Devise de l'assiette interne du risque de variation
    P1_3_86    NUMBER(18,2)   , -- P1 3.86     NUM/19 19 dont signe et 2 décimales  Montant Credit Valuation Adju
    P1_3_87    VARCHAR2(3)    , -- P1 3.87     ALPHA/3  Devise de Credit Valuation Adjustment (CVA) comptable
    P1_3_88    VARCHAR2(1)    , -- P1 3.88     ALPHA/1  Indicateur de risque spécifique de corrélation défavorabl
    P1_3_89    VARCHAR2(3)    , -- P1 3.89     ALPHA/3  Méthode réglementaire de calcul de l'exposition
    P1_3_90    VARCHAR2(3)    , -- P1 3.90     ALPHA/3  Méthode de calcul CVA
    P1_3_98    VARCHAR2(50)   , -- P1 3.98     ALPHA/50  Zone réservée locale
    P1_3_99    VARCHAR2(2)    , -- P1 3.99     ALPHA/2  Filler
    P1_4_1     VARCHAR2(1)    , -- P1 4.1      ALPHA/1  Indicateur Impayé prudentiel
    P1_4_2     NUMBER(18,2)   , -- P1 4.2      NUM/19 19 dont signe et 2 décimales  Montant du solde de compte
    P1_4_3     VARCHAR2(3)    , -- P1 4.3      ALPHA/3  Devise du montant du solde de compte
    P1_4_4     NUMBER(18,2)   , -- P1 4.4      NUM/19 19 dont signe et 2 décimales  Montant du découvert
    P1_4_5     VARCHAR2(3)    , -- P1 4.5      ALPHA/3  Devise du montant du découvert
    P1_4_6     NUMBER(18,2)   , -- P1 4.6      NUM/19 19 dont signe et 2 décimales  Montant des intérêts restant 
    P1_4_7     VARCHAR2(3)    , -- P1 4.7      ALPHA/3  Devise du montant des intérêts restant dus
    P1_4_8     VARCHAR2(1)    , -- P1 4.8      ALPHA/1  Indicateur bilan hors bilan
    P1_4_9     NUMBER(18,2)   , -- P1 4.9      NUM/19 19 dont signe et 2 décimales  Montant du capital restant dû
    P1_4_13    VARCHAR2(3)    , -- P1 4.13     ALPHA/3  Devise du montant du capital restant dû
    P1_4_14    NUMBER(18,2)   , -- P1 4.14     NUM/19 19 dont signe et 2 décimales  Montant des loyers
    P1_4_15    VARCHAR2(3)    , -- P1 4.15     ALPHA/3  Devise d'origine des loyers
    P1_4_16    NUMBER(18,2)   , -- P1 4.16     NUM/19 19 dont signe et 2 décimales  Montant du nominal de l'engag
    P1_4_17    VARCHAR2(3)    , -- P1 4.17     ALPHA/3  Devise du nominal de l'engagement
    P1_4_18    VARCHAR2(12)   , -- P1 4.18     ALPHA/12  Zone libre (Ex PCCO du montant demandé)
    P1_4_19    VARCHAR2(12)   , -- P1 4.19     ALPHA/12  Zone libre (Ex PCCO – des intérêts restant dus)
    P1_4_20    NUMBER(9,5)    , -- P1 4.20     NUM/10 10 dont signe et 5 décimales  Taux facial du prêt fixe
    P1_4_21    NUMBER(18,2)   , -- P1 4.21     NUM/19 19 dont signe et 2 décimales  Montant de la décote sur acti
    P1_4_22    VARCHAR2(3)    , -- P1 4.22     ALPHA/3  Devise du montant de la décote sur actif déprécié à l'ach
    P1_4_23    VARCHAR2(2)    , -- P1 4.23     ALPHA/2  Circuit de distribution
    P1_4_24    DATE           , -- P1 4.24     DATE/8  Date de signature du contrat
    P1_4_25    NUMBER(18,2)   , -- P1 4.25     NUM/19 19 dont signe et 2 décimales  Montant du Add-on affacturage
    P1_4_26    VARCHAR2(3)    , -- P1 4.26     ALPHA/3  Devise du montant du Add-on affacturage
    P1_4_27    NUMBER(18,2)   , -- P1 4.27     NUM/19 19 dont signe et 2 décimales  Montant de la part de finance
    P1_4_28    VARCHAR2(3)    , -- P1 4.28     ALPHA/3  Devise du montant de la part de financement garanti par d
    P1_4_29    VARCHAR2(1)    , -- P1 4.29     ALPHA/1  Indicateur créance titrisée
    P1_4_30    NUMBER(14,10)    , -- P1 4.30     NUM/10 10 dont signe et 5 décimales  Expected Loss Best Estimate (
    P1_4_31    VARCHAR2(1)    , -- P1 4.31     ALPHA/1  Indicateur Produit à sous-jacent
    P1_4_32    VARCHAR2(1)    , -- P1 4.32     ALPHA/1  Indicateur de granularité
    P1_4_33    DATE           , -- P1 4.33     DATE/8  Date d'acquisition de la dernière part
    P1_4_34    VARCHAR2(1)    , -- P1 4.34     ALPHA/1  Traitement GRR
    P1_4_35    VARCHAR2(1)    , -- P1 4.35     ALPHA/1  Indicateur opinion juridique
    P1_4_36    VARCHAR2(1)    , -- P1 4.36     ALPHA/1  Indicateur de transparence de la structure
    P1_4_37    VARCHAR2(1)    , -- P1 4.37     ALPHA/1  Indicateur de ségrégation
    P1_4_38    VARCHAR2(1)    , -- P1 4.38     ALPHA/1  Indicateur autonomie patrimoniale de l'actif en cas de dé
    P1_4_39    VARCHAR2(1)    , -- P1 4.39     ALPHA/1  Indicateur portabilité de l'actif en cas de défaut d'un m
    P1_4_40    VARCHAR2(3)    , -- P1 4.40     ALPHA/3  Identifiant du Fonds Commun de Titrisation (SPV)
    P1_4_41    VARCHAR2(1)    , -- P1 4.41     ALPHA/1  Mode de Titrisation
    P1_4_42    VARCHAR2(6)    , -- P1 4.42     ALPHA/6  Type de produit bancaire
    P1_4_43    VARCHAR2(2)    , -- P1 4.43     ALPHA/2  Segment de notation du groupe de risque
    P1_4_44    VARCHAR2(5)    , -- P1 4.44     ALPHA/5  Ligne produit
    P1_4_45    VARCHAR2(12)   , -- P1 4.45     ALPHA/12  NATure d'Opération des intérêts dus / coupons non échus
    P1_4_46    VARCHAR2(12)   , -- P1 4.46     ALPHA/12  Zone libre (Ex PCCO – Montant des coupons non échus)
    P1_4_47    DATE           , -- P1 4.47     DATE/8  Date de mise à disposition des fonds
    P1_4_48    VARCHAR2(1)    , -- P1 4.48     ALPHA/1  Indicateur créance titrisée SRT
    P1_4_49    VARCHAR2(1)    , -- P1 4.49     ALPHA/1  Indicateur d'engagement de valeur minimale sur OPC
    P1_4_98    VARCHAR2(45)   , -- P1 4.98     ALPHA/45  Zone réservée TRUE SALE
    P1_4_99    VARCHAR2(4)    , -- P1 4.99     ALPHA/4  Filler
    P1_5_2     VARCHAR2(1)    , -- P1 5.2      ALPHA/1  Indicateur Engagement en défaut
    P1_5_3     DATE           , -- P1 5.3      DATE/8  Date de passage en engagement en défaut
    P1_5_5     VARCHAR2(1)    , -- P1 5.5      ALPHA/1  Indicateur Arriéré de paiement
    P1_5_6     VARCHAR2(1)    , -- P1 5.6      ALPHA/1  Indicateur 'Prêt Revolving Roll-over'
    P1_5_7     VARCHAR2(20)   , -- P1 5.7      ALPHA/20  Identifiant local du bénéficiaire final de l'EPS
    P1_5_8     VARCHAR2(10)   , -- P1 5.8      ALPHA/10  Identifiant central du bénéficiaire final de l'EPS
    P1_5_10    VARCHAR2(1)    , -- P1 5.10     ALPHA/1  Indicateur Accord de Fusion
    P1_5_11    VARCHAR2(25)   , -- P1 5.11     ALPHA/25  Référence de la lettre de Fusion
    P1_5_19    NUMBER(18,2)   , -- P1 5.19     NUM/19 19 dont signe et 2 décimales  Valeur estimée en fin de péri
    P1_5_20    VARCHAR2(3)    , -- P1 5.20     ALPHA/3  Devise de la valeur estimée en fin de période du bien lou
    P1_5_99    VARCHAR2(1)    , -- P1 5.99     ALPHA/1  Filler
    P1_6_99    VARCHAR2(7)    , -- P1 6.99     ALPHA/7  Filler
    P1_7_0     NUMBER(3)      , -- P1 7.0      NUM/3  Périodicité de réévaluation
    P1_7_1     NUMBER(18,2)   , -- P1 7.1      NUM/19 19 dont signe et 2 décimales  Montant Mark-to-Market (MtM) 
    P1_7_2     VARCHAR2(3)    , -- P1 7.2      ALPHA/3  Devise du montant Mark-to-Market (MtM) de la jambe prêteu
    P1_7_3     NUMBER(18,2)   , -- P1 7.3      NUM/19 19 dont signe et 2 décimales  Montant Mark-to-Market (MtM) 
    P1_7_6     VARCHAR2(12)   , -- P1 7.6      ALPHA/12  Zone libre (Ex PCCO du MtM de la jambe prêteuse)
    P1_7_7     VARCHAR2(2)    , -- P1 7.7      ALPHA/2  Jambe prêteuse du repo : nature du sous-jacent
    P1_7_8     VARCHAR2(2)    , -- P1 7.8      ALPHA/2  Jambe prêteuse du repo : localisation bourse de cotation
    P1_7_9     VARCHAR2(2)    , -- P1 7.9      ALPHA/2  Jambe prêteuse du repo : indice dont les titres font part
    P1_7_10    VARCHAR2(12)   , -- P1 7.10     ALPHA/12  Jambe prêteuse du repo : référence des titres
    P1_7_11    VARCHAR2(1)    , -- P1 7.11     ALPHA/1  Jambe prêteuse du repo : échelon de qualité de crédit des
    P1_7_12    DATE           , -- P1 7.12     DATE/8  Jambe prêteuse du repo : échéance du titre sous-jacent
    P1_7_13    VARCHAR2(20)   , -- P1 7.13     ALPHA/20  Jambe prêteuse du repo : identifiant local de l'émetteur
    P1_7_14    VARCHAR2(10)   , -- P1 7.14     ALPHA/10  Jambe prêteuse du repo : identifiant central de l'émette
    P1_7_15    VARCHAR2(12)   , -- P1 7.15     ALPHA/12  Zone libre (Ex PCCO du MtM de la jambe emprunteuse)
    P1_7_16    VARCHAR2(2)    , -- P1 7.16     ALPHA/2  Jambe emprunteuse du repo : nature du sous-jacent
    P1_7_17    VARCHAR2(2)    , -- P1 7.17     ALPHA/2  Jambe emprunteuse du repo : localisation bourse de Cotati
    P1_7_18    VARCHAR2(2)    , -- P1 7.18     ALPHA/2  Jambe emprunteuse du repo : indice dont les titres font p
    P1_7_19    VARCHAR2(12)   , -- P1 7.19     ALPHA/12  Jambe emprunteuse du repo : référence des titres
    P1_7_20    VARCHAR2(1)    , -- P1 7.20     ALPHA/1  Jambe emprunteuse du repo : Echelon de qualité de crédit 
    P1_7_21    DATE           , -- P1 7.21     DATE/8  Jambe emprunteuse du repo : échéance du titre sous-jacent
    P1_7_22    VARCHAR2(20)   , -- P1 7.22     ALPHA/20  Jambe emprunteuse du repo : identifiant local de l'émett
    P1_7_23    VARCHAR2(10)   , -- P1 7.23     ALPHA/10  Jambe emprunteuse du repo : identifiant central de l'éme
    P1_7_24    VARCHAR2(1)    , -- P1 7.24     ALPHA/1  Indicateur de période de liquidation 20 jours
    P1_7_25    VARCHAR2(1)    , -- P1 7.25     ALPHA/1  Indicateur de période de liquidation à doubler
    P1_7_99    VARCHAR2(20)   , -- P1 7.99     ALPHA/20  Filler
    P1_8_1     VARCHAR2(1)    , -- P1 8.1      ALPHA/1  Type du taux payé du dérivé
    P1_8_2     VARCHAR2(14)   , -- P1 8.2      ALPHA/14  Indice de référence du taux payé
    P1_8_11    VARCHAR2(1)    , -- P1 8.11     ALPHA/1  Type du taux reçu du dérivé
    P1_8_12    VARCHAR2(14)   , -- P1 8.12     ALPHA/14  Indice de référence du taux reçu
    P1_8_13    VARCHAR2(1)    , -- P1 8.13     ALPHA/1  Usage du bien immobilier financé
    P1_8_99    VARCHAR2(10)   , -- P1 8.99     ALPHA/10  Filler
    P1_9_5     NUMBER(9,5)    , -- P1 9.5      NUM/10 10 dont signe et 5 décimales  Prix spot en taux
    P1_9_99    VARCHAR2(30)   , -- P1 9.99     ALPHA/30  Filler
    P1_10_1    VARCHAR2(3)    , -- P1 10.1     ALPHA/3  Nature de l'Option
    P1_10_2    VARCHAR2(1)    , -- P1 10.2     ALPHA/1  Indicateur Call Put
    P1_10_4    NUMBER(18,2)   , -- P1 10.4     NUM/19 19 dont signe et 2 décimales  Prix d'exercice de l'option
    P1_10_5    NUMBER(9,5)    , -- P1 10.5     NUM/10 10 dont signe et 5 décimales  Prix d'exercice en taux
    P1_10_20   VARCHAR2(2)    , -- P1 10.20    ALPHA/2  Type de swap
    P1_10_21   VARCHAR2(3)    , -- P1 10.21    ALPHA/3  Devise du prix d'exercice de l'option
    P1_10_22   VARCHAR2(1)    , -- P1 10.22    ALPHA/1  Type d'exercice de l'option
    P1_10_23   NUMBER(18,2)   , -- P1 10.23    NUM/19 19 dont signe et 2 décimales  Montant cours spot
    P1_10_24   VARCHAR2(3)    , -- P1 10.24    ALPHA/3  Devise du montant cours spot
    P1_10_99   VARCHAR2(24)   , -- P1 10.99    ALPHA/24  Filler
    P1_11_1    VARCHAR2(3)    , -- P1 11.1     ALPHA/3  Type de dérivé de crédit
    P1_11_2    NUMBER(9,5)    , -- P1 11.2     NUM/10 10 dont signe et 5 décimales  Spread de marché du dérivé
    P1_11_4    VARCHAR2(20)   , -- P1 11.4     ALPHA/20  Identifiant local du tiers couvert par le Dérivé de créd
    P1_11_5    VARCHAR2(10)   , -- P1 11.5     ALPHA/10  Identifiant central du tiers couvert par le Dérivé de cr
    P1_11_12   VARCHAR2(2)    , -- P1 11.12    ALPHA/2  Source du rating de la tranche
    P1_11_13   NUMBER(9,5)    , -- P1 11.13    NUM/10 10 dont signe et 5 décimales  Point d'attachement
    P1_11_14   NUMBER(9,5)    , -- P1 11.14    NUM/10 10 dont signe et 5 décimales  Point de détachement
    P1_11_15   VARCHAR2(20)   , -- P1 11.15    ALPHA/20  Identifiant local de la chambre de compensation
    P1_11_16   VARCHAR2(10)   , -- P1 11.16    ALPHA/10  Identifiant central de la chambre de compensation
    P1_11_33   VARCHAR2(5)    , -- P1 11.33    ALPHA/5  Rating de la tranche
    P1_12_1    VARCHAR2(2)    , -- P1 12.1     ALPHA/2  Nature du sous-Jacent
    P1_12_3    VARCHAR2(12)   , -- P1 12.3     ALPHA/12  Référence du titre sous-jacent
    P1_12_5    VARCHAR2(3)    , -- P1 12.5     ALPHA/3  Devise du montant Mark-to-Market (MtM) de la jambe emprun
    P1_12_6    DATE           , -- P1 12.6     DATE/8  Date d'échéance du titre sous-jacent
    P1_12_16   VARCHAR2(3)    , -- P1 12.16    ALPHA/3  Code séniorité
    P1_12_17   VARCHAR2(20)   , -- P1 12.17    ALPHA/20  Identifiant local du tiers émetteur du titre sous-jacent
    P1_12_18   VARCHAR2(10)   , -- P1 12.18    ALPHA/10  Identifiant central du tiers émetteur du titre sous-jace
    P1_12_19   VARCHAR2(1)    , -- P1 12.19    ALPHA/1  Echelon de qualité de crédit du titre sous-jacent
    P1_13_1    NUMBER(18,2)   , -- P1 13.1     NUM/19 19 dont signe et 2 décimales  Montant du seuil de déclenche
    P1_13_2    VARCHAR2(3)    , -- P1 13.2     ALPHA/3  Devise du montant du seuil de déclenchement de l'appel de
    P1_13_4    NUMBER(18,2)   , -- P1 13.4     NUM/19 19 dont signe et 2 décimales  Montant minimum de transfert 
    P1_13_5    VARCHAR2(3)    , -- P1 13.5     ALPHA/3  Devise du montant minimum de transfert de l'appel de marg
    P1_13_10   VARCHAR2(25)   , -- P1 13.10    ALPHA/25  Référence du contrat de collatéralisation
    P1_14      VARCHAR2(12)   , -- P1 14       ALPHA/12  Numéro de compte PCCA de l'encours en NF
    P1_15      VARCHAR2(12)   , -- P1 15       ALPHA/12  Numéro de compte local (PCI) de l'encours
    P1_15_1    VARCHAR2(2)    , -- P1 15.1     ALPHA/2  Indice boursier auquel appartient le titre sous-jacent
    P1_15_2    VARCHAR2(2)    , -- P1 15.2     ALPHA/2  Localisation bourse de cotation du titre sous-jacent
    P1_16      VARCHAR2(12)   , -- P1 16       ALPHA/12  Numéro de compte PCCA de l'encours en norme IFRS
    P1_16_3    VARCHAR2(3)    , -- P1 16.3     ALPHA/3  Séniorité de la tranche dans le véhicule
    P1_16_6    NUMBER(9,5)    , -- P1 16.6     NUM/10 10 dont signe et 5 décimales  Pondération Bâloise de l'enga
    P1_16_9    VARCHAR2(1)    , -- P1 16.9     ALPHA/1  Indicateur 'Granularité des parts'
    P1_16_12   VARCHAR2(1)    , -- P1 16.12    ALPHA/1  Code position de la banque dans le programme
    P1_16_13   VARCHAR2(1)    , -- P1 16.13    ALPHA/1  Indicateur Clause de remboursement anticipé
    P1_16_15   VARCHAR2(7)    , -- P1 16.15    ALPHA/7  Méthode de pondération titrisation
    P1_16_16   VARCHAR2(1)    , -- P1 16.16    ALPHA/1  Nature de la titrisation
    P1_16_17   VARCHAR2(1)    , -- P1 16.17    ALPHA/1  Re-titrisation
    P1_16_18   VARCHAR2(1)    , -- P1 16.18    ALPHA/1  Type de titrisation
    P1_16_19   NUMBER(9,5)    , -- P1 16.19    NUM/10 10 dont signe et 5 décimales  Pondération à l'origine
    P1_16_20   VARCHAR2(1)    , -- P1 16.20    ALPHA/1  Indicateur titrisation STS
    P1_16_21   VARCHAR2(1)    , -- P1 16.21    ALPHA/1  Eligibilité au traitement différentiel
    P1_16_22   VARCHAR2(1)    , -- P1 16.22    ALPHA/1  Position sénior en titrisation des PME
    P1_16_23   VARCHAR2(2)    , -- P1 16.23    ALPHA/2  Motif titrisation ERBA
    P1_16_24   VARCHAR2(7)    , -- P1 16.24    ALPHA/7  Méthode de titrisation
    P1_16_25   VARCHAR2(2)    , -- P1 16.25    ALPHA/2  Echelon qualité de crédit de la tranche à date d'origine
    P1_16_26   VARCHAR2(2)    , -- P1 16.26    ALPHA/2  Type de cotation échelon de qualité de crédit de la tranc
    P1_16_27   VARCHAR2(2)    , -- P1 16.27    ALPHA/2  Echelon qualité de crédit de la tranche à date d'arrêté
    P1_16_28   VARCHAR2(2)    , -- P1 16.28    ALPHA/2  Type de cotation échelon de qualité de crédit de la tranc
    P1_16_29   NUMBER(18,2)   , -- P1 16.29    NUM/19 19 dont signe et 2 décimales  Montant escompte d'achats non
    P1_16_30   VARCHAR2(3)    , -- P1 16.30    ALPHA/3  Devise du montant escompte d'achats non remboursables
    P1_16_31   NUMBER(18,2)   , -- P1 16.31    NUM/19 19 dont signe et 2 décimales  Montant de l'ajustement spéci
    P1_16_32   VARCHAR2(3)    , -- P1 16.32    ALPHA/3  Devise du montant de l'ajustement spécifique du risque de
    P1_16_33   NUMBER(18,2)   , -- P1 16.33    NUM/19 19 dont signe et 2 décimales  Valeur exposée au risque des 
    P1_16_34   VARCHAR2(3)    , -- P1 16.34    ALPHA/3  Devise de la valeur exposée au risque des positions dédui
    P1_16_35   NUMBER(18,2)   , -- P1 16.35    NUM/19 19 dont signe et 2 décimales  Montant de l'ajustement des r
    P1_16_36   VARCHAR2(3)    , -- P1 16.36    ALPHA/3  Devise du montant de l'ajustement des risques pondérés li
    P1_16_37   NUMBER(18,2)   , -- P1 16.37    NUM/19 19 dont signe et 2 décimales  Montant de RWA supplémentaire
    P1_16_38   VARCHAR2(3)    , -- P1 16.38    ALPHA/3  Devise du montant de RWA supplémentaire pour non-conformi
    P1_16_39   NUMBER(18,2)   , -- P1 16.39    NUM/19 19 dont signe et 2 décimales  Montant du gain RWA obtenu pa
    P1_16_40   VARCHAR2(3)    , -- P1 16.40    ALPHA/3  Devise du montant du gain RWA obtenu par le CAP sur la po
    P1_16_41   NUMBER(18,2)   , -- P1 16.41    NUM/19 19 dont signe et 2 décimales  Montant du gain RWA obtenu pa
    P1_16_42   VARCHAR2(3)    , -- P1 16.42    ALPHA/3  Devise du montant du gain RWA obtenu par le CAP sur les e
    P1_16_99   VARCHAR2(3)    , -- P1 16.99    ALPHA/3  Filler
    P1_18_1    NUMBER(14,10)    , -- P1 18.1     NUM/10 10 dont signe et 5 décimales  Loss Given Default (LGD)
    P1_18_5    NUMBER(18,2)   , -- P1 18.5     NUM/19 19 dont signe et 2 décimales  Montant de l'Exposition en ca
    P1_18_10   NUMBER(14,10)    , -- P1 18.10    NUM/10 10 dont signe et 5 décimales  Crédit Conversion Factor (CCF
    P1_18_17   VARCHAR2(3)    , -- P1 18.17    ALPHA/3  Devise du montant de l'Exposition en cas de Défaut (EAD)
    P1_18_18   VARCHAR2(3)    , -- P1 18.18    ALPHA/3  Devise d'origine du contrat
    P1_19_5    VARCHAR2(3)    , -- P1 19.5     ALPHA/3  Classification comptable de référence des actifs
    P1_20_1    NUMBER(18,2)   , -- P1 20.1     NUM/19 19 dont signe et 2 décimales  Quantité à recevoir
    P1_20_2    VARCHAR2(3)    , -- P1 20.2     ALPHA/3  Unité de mesure de la quantité à recevoir
    P1_20_3    NUMBER(18,2)   , -- P1 20.3     NUM/19 19 dont signe et 2 décimales  Quantité à livrer
    P1_20_4    VARCHAR2(3)    , -- P1 20.4     ALPHA/3  Unité de mesure de la quantité à livrer
    P1_21_1    VARCHAR2(2)    , -- P1 21.1     ALPHA/2  Indicateur Type de Restructuration
    P1_21_2    DATE           , -- P1 21.2     DATE/8  Date de Restructuration
    P1_21_3    VARCHAR2(1)    , -- P1 21.3     ALPHA/1  Evénement de crédit
    P1_21_4    VARCHAR2(1)    , -- P1 21.4     ALPHA/1  Nature Contextuelle au moment de l'évènement de crédit
    P1_21_5    VARCHAR2(1)    , -- P1 21.5     ALPHA/1  Statut du crédit au sens de la Forbearance
    P1_21_6    VARCHAR2(2)    , -- P1 21.6     ALPHA/2  Indicateur créance performante
    P1_21_7    DATE           , -- P1 21.7     DATE/8  Date de première action de forbearance
    P1_21_8    DATE           , -- P1 21.8     DATE/8  Date de dernière restructuration commerciale
    P1_21_9    DATE           , -- P1 21.9     DATE/8  Date de la dernière restructuration pour risque
    P1_21_10   DATE           , -- P1 21.10    DATE/8  Date d'entrée de la créance en période d'observation
    P1_21_11   DATE           , -- P1 21.11    DATE/8  Date de sortie de la créance de la période d'observation
    P1_21_12   DATE           , -- P1 21.12    DATE/8  Date d'entrée de la créance en période probatoire
    P1_21_13   DATE           , -- P1 21.13    DATE/8  Date de sortie de la créance de la période probatoire
    P1_21_14   DATE           , -- P1 21.14    DATE/8  Date théorique de fin de situation forborne
    P1_21_15   DATE           , -- P1 21.15    DATE/8  Date de sortie effective de situation forborne
    P1_21_16   DATE           , -- P1 21.16    DATE/8  Date de début de l'état de performance de la créance
    P1_21_17   VARCHAR2(2)    , -- P1 21.17    ALPHA/2  Zone libre (ex Motif de l'état de performance de la créan
    P1_21_18   NUMBER(2)      , -- P1 21.18    NUM/2  Nombre de restructuration pour risque
    P1_21_19   VARCHAR2(2)    , -- P1 21.19    ALPHA/2  Méthode de restructuration
    P1_21_20   NUMBER(18,2)   , -- P1 21.20    NUM/19 19 dont signe et 2 décimales  Montant des passages en perte
    P1_21_21   VARCHAR2(3)    , -- P1 21.21    ALPHA/3  Devise du montant des passages en pertes cumulées
    P1_21_22   VARCHAR2(2)    , -- P1 21.22    ALPHA/2  Motif du moratoire
    P1_21_23   DATE           , -- P1 21.23    DATE/8  Date de début du moratoire
    P1_21_25   VARCHAR2(2)    , -- P1 21.25    ALPHA/2  Statut du moratoire
    P1_21_26   VARCHAR2(1)    , -- P1 21.26    ALPHA/1  Indicateur de moratoire législatif
    P1_21_27   VARCHAR2(1)    , -- P1 21.27    ALPHA/1  Indicateur de moratoire contractuel
    P1_21_28   VARCHAR2(2)    , -- P1 21.28    ALPHA/2  Champ d'application du moratoire
    P1_21_29   NUMBER(5)      , -- P1 21.29    NUM/6 6 dont signe  Durée du moratoire
    P1_21_30   NUMBER(21,2)   , -- P1 21.30    NUM/19 19 dont signe et 2 décimales  Montant des échéances reporté
    P1_21_31   VARCHAR2(3)    , -- P1 21.31    ALPHA/3  Devise du montant des échéances reportées
    P1_21_32   VARCHAR2(15)   , -- P1 21.32    ALPHA/15  Méthode de convention des taux sans risque (RFR)
    P1_21_33   VARCHAR2(3)    , -- P1 21.33    ALPHA/3  Durée de convention des taux sans risque (RFR)
    P1_21_34   VARCHAR2(1)    , -- P1 21.34    ALPHA/1  Indicateur de créance titrisable
    P1_21_35   VARCHAR2(1)    , -- P1 21.35    ALPHA/1  Indicateur de créance pour émission de covered bonds
    P1_21_36   NUMBER(18,2)   , -- P1 21.36    NUM/19 19 dont signe et 2 décimales  Montants liquidatifs estimés
    P1_21_37   VARCHAR2(3)    , -- P1 21.37    ALPHA/3  Devise des montants liquidatifs estimés
    P1_21_38   VARCHAR2(1)    , -- P1 21.38    ALPHA/1  Indicateur d'exposition garantie par un bien immobilier g
    P1_21_39   VARCHAR2(1)    , -- P1 21.39    ALPHA/1  Indicateur d'exposition sur acquisition, développement et
    P1_21_40   VARCHAR2(1)    , -- P1 21.40    ALPHA/1  Réalisation des conditions de pondération préférentielle
    P1_21_41   VARCHAR2(1)    , -- P1 21.41    ALPHA/1  Indicateur de dépôt en espèces substantiel
    P1_21_42   VARCHAR2(1)    , -- P1 21.42    ALPHA/1  Indicateur d'apport en fonds propres substantiels
    P1_21_43   NUMBER(24,9)   , -- P1 21.43    NUM/15 15 dont signe et 9 décimales  Ratio prudentiel d'Exposition
    P1_21_44   VARCHAR2(1)    , -- P1 21.44    ALPHA/1  Indicateur d'exposition de qualité élevée
    P1_21_45   VARCHAR2(1)    , -- P1 21.45    ALPHA/1  Indicateur de la phase opérationnelle du projet financé
    P1_21_46   VARCHAR2(1)    , -- P1 21.46    ALPHA/1  Indicateur de conformité des critères opérationnels du pr
    P1_21_47   NUMBER(9,5)    , -- P1 21.47    NUM/10 10 dont signe et 5 décimales  Pondération Bâloise de l'enga
    P1_21_48   VARCHAR2(7)    , -- P1 21.48    ALPHA/7  Méthode de titrisation pour le calcul de l'Output Floor
    P1_21_49   NUMBER(18,2)   , -- P1 21.49    NUM/19 19 dont signe et 2 décimales  Montant des ajustements de ri
    P1_21_50   VARCHAR2(3)    , -- P1 21.50    ALPHA/3  Devise du montant des ajustements de risques pondérés lié
    P1_21_51   NUMBER(18,2)   , -- P1 21.51    NUM/19 19 dont signe et 2 décimales  Montant de RWA supplémentaire
    P1_21_52   VARCHAR2(3)    , -- P1 21.52    ALPHA/3  Devise du montant de RWA supplémentaire pour non-conformi
    P1_21_53   NUMBER(18,2)   , -- P1 21.53    NUM/19 19 dont signe et 2 décimales  Montant du gain RWA obtenu pa
    P1_21_54   VARCHAR2(3)    , -- P1 21.54    ALPHA/3  Devise du gain RWA obtenu par le CAP sur la pondération p
    P1_21_55   VARCHAR2(12)   , -- P1 21.55    ALPHA/12  NATure d'Opération de l'engagement pour le calcul Output
    P1_21_56   VARCHAR2(1)    , -- P1 21.56    ALPHA/1  Indicateur Intention de revente à court terme
    P1_21_57   VARCHAR2(1)    , -- P1 21.57    ALPHA/1  Indicateur d'investissement en Capital Risque
    P1_21_58   VARCHAR2(1)    , -- P1 21.58    ALPHA/1  Indicateur d'investissement dans un programme législatif
    P1_21_59   VARCHAR2(1)    , -- P1 21.59    ALPHA/1  Indicateur de participation stratégique depuis plus de 6 
    P1_21_60   NUMBER(24,9)   , -- P1 21.60    NUM/15 15 dont signe et 9 décimales  Taux historique de pondératio
    P1_21_61   NUMBER(9,5)    , -- P1 21.61    NUM/10 10 dont signe et 5 décimales  Perte en cas de défaut (LGD) 
    P1_21_62   NUMBER(9,5)    , -- P1 21.62    NUM/10 10 dont signe et 5 décimales  Perte en cas de défaut (LGD) 
    P1_21_63   NUMBER(18,2)   , -- P1 21.63    NUM/19 19 dont signe et 2 décimales  Montant d'encours pour la par
    P1_21_64   VARCHAR2(3)    , -- P1 21.64    ALPHA/3  Devise du montant d'encours pour la partie couverte des s
    P1_21_65   VARCHAR2(50)   , -- P1 21.65    ALPHA/50  Entité juridique de rattachement du contrat de netting p
    P1_21_66   VARCHAR2(1)    , -- P1 21.66    ALPHA/1  Indicateur d'engagement hors bilan annulable sans conditi
    P1_21_67   VARCHAR2(1)    , -- P1 21.67    ALPHA/1  Indicateur de l'application de l'approche par mandat
    P1_21_68   VARCHAR2(1)    , -- P1 21.68    ALPHA/1  Niveau de risque CRR3
    P1_21_69   VARCHAR2(1)    , -- P1 21.69    ALPHA/1  Indicateur de calcul de l'ajustement de l'évaluation de c
    P1_21_71   VARCHAR2(40)   , -- P1 21.71    ALPHA/40  Lieu d'investissement du bien principal financé : Nom co
    P1_21_72   VARCHAR2(40)   , -- P1 21.72    ALPHA/40  Lieu d'investissement du bien principal financé : numéro
    P1_21_73   VARCHAR2(40)   , -- P1 21.73    ALPHA/40  Lieu d'investissement du bien principal financé : extens
    P1_21_74   VARCHAR2(40)   , -- P1 21.74    ALPHA/40  Lieu d'investissement du bien principal financé : type d
    P1_21_75   VARCHAR2(40)   , -- P1 21.75    ALPHA/40  Lieu d'investissement du bien principal financé : libell
    P1_21_76   VARCHAR2(40)   , -- P1 21.76    ALPHA/40  Lieu d'investissement du bien principal financé : lieu d
    P1_21_77   VARCHAR2(11)   , -- P1 21.77    NUM/11 11 dont signe, séparateur et 7 décimales  Lieu d'investisse
    P1_21_78   VARCHAR2(12)   , -- P1 21.78    NUM/12 12 dont signe, séparateur et 7 décimales  Lieu d'investisse
    P1_21_79   VARCHAR2(1)    , -- P1 21.79    ALPHA/1  Indicateur Titre de Participation
    P1_21_80   VARCHAR2(3)    , -- P1 21.80    ALPHA/3  Classification comptable de l'élément couvert par le déri
    P1_21_81   NUMBER(14,10)    , -- P1 21.81    NUM/10 10 dont signe et 5 décimales  DSCR (ratio de couverture des
    P1_21_82   NUMBER(14,10)    , -- P1 21.82    NUM/10 10 dont signe et 5 décimales  DSCR (ratio de couverture des
    P1_21_83   NUMBER(14,9)   , -- P1 21.83    NUM/15 15 dont signe et 9 décimales  Ratio de couverture des intér
    P1_21_84   NUMBER(14,9)   , -- P1 21.84    NUM/15 15 dont signe et 9 décimales  Ratio prêts-coûts (LTC) à l'o
    P1_21_85   NUMBER(14,9)   , -- P1 21.85    NUM/15 15 dont signe et 9 décimales  Taux de précommercialisation 
    P1_21_86   VARCHAR2(1)    , -- P1 21.86    ALPHA/1  Type de bien commercial
    P1_21_87   VARCHAR2(1)    , -- P1 21.87    ALPHA/1  Emplacement du bien immobilier commercial
    P1_21_88   VARCHAR2(1)    , -- P1 21.88    ALPHA/1  Indicateur d'opération avec recours
    P1_21_89   VARCHAR2(20)   , -- P1 21.89    ALPHA/20  Identifiant local du client de l'intermédiaire compensat
    P1_21_90   VARCHAR2(10)   , -- P1 21.90    ALPHA/10  Identifiant central du client de l'intermédiaire compens
    P1_21_91   NUMBER(18,2)   , -- P1 21.91    NUM/19 19 dont signe et 2 décimales  Montant des variations cumulé
    P1_21_92   VARCHAR2(3)    , -- P1 21.92    ALPHA/3  Devise du montant des variations cumulées de la juste val
    P1_21_93   VARCHAR2(5)    , -- P1 21.93    ALPHA/5  Numéro du dernier billet financier apériodique
    P1_21_94   VARCHAR2(1)    , -- P1 21.94    ALPHA/1  Indicateur d'actif liquide de haute qualité (HQLA)
    P1_21_95   VARCHAR2(2)    , -- P1 21.95    ALPHA/2  Niveau de l'actif liquide de haute qualité (HQLA)
    P1_21_98   VARCHAR2(50)   , -- P1 21.98    ALPHA/50  Identifiant du deal Back-to-Back avec CACIB
    P1_21_99   VARCHAR2(2)    , -- P1 21.99    ALPHA/2  Filler
    P1_22_1    VARCHAR2(40)   , -- P1 22.1     ALPHA/40  Référence unique du contrat
    P1_22_2    VARCHAR2(1)    , -- P1 22.2     ALPHA/1  Indicateur niveau de risque
    P1_22_3    VARCHAR2(4)    , -- P1 22.3     ALPHA/4  Famille de risque de l'opération couverte par l'engagemen
    P1_22_4    VARCHAR2(40)   , -- P1 22.4     ALPHA/40  Zone libre (Ex Référence unique du contrat couvert)
    P1_22_5    VARCHAR2(2)    , -- P1 22.5     ALPHA/2  Note finale retenue à l'origine
    P1_22_6    VARCHAR2(2)    , -- P1 22.6     ALPHA/2  Organisme de notation à l'origine
    P1_22_7    VARCHAR2(2)    , -- P1 22.7     ALPHA/2  Objet du financement
    P1_22_8    NUMBER(18,2)   , -- P1 22.8     NUM/19 19 dont signe et 2 décimales  Montant du contrat à l'origin
    P1_22_9    VARCHAR2(3)    , -- P1 22.9     ALPHA/3  Devise du montant du contrat à l'origine
    P1_22_11   VARCHAR2(1)    , -- P1 22.11    ALPHA/1  Indicateur éligibilité de l'actif à une mobilisation banq
    P1_22_12   VARCHAR2(1)    , -- P1 22.12    ALPHA/1  Indicateur échéancier fourni
    P1_22_13   NUMBER(9,5)    , -- P1 22.13    NUM/10 10 dont signe et 5 décimales  Taux d'intérêt effectif (TIE)
    P1_22_14   VARCHAR2(1)    , -- P1 22.14    ALPHA/1  Type de taux
    P1_22_15   VARCHAR2(12)   , -- P1 22.15    ALPHA/12  Indice de référence
    P1_22_16   VARCHAR2(1)    , -- P1 22.16    ALPHA/1  Type d'amortissement du capital
    P1_22_17   VARCHAR2(1)    , -- P1 22.17    ALPHA/1  Fréquence d'amortissement du capital
    P1_22_18   VARCHAR2(1)    , -- P1 22.18    ALPHA/1  Fréquence de paiement des intérêts
    P1_22_19   NUMBER(14,10)    , -- P1 22.19    NUM/10 10 dont signe et 5 décimales  Taux client à l'octroi
    P1_22_20   VARCHAR2(1)    , -- P1 22.20    ALPHA/1  Modalité de remboursement de la créance
    P1_22_21   DATE           , -- P1 22.21    DATE/8  Date de première échéance
    P1_22_22   DATE           , -- P1 22.22    DATE/8  Date de fin du différé d'amortissement
    P1_22_23   NUMBER(14,10)    , -- P1 22.23    NUM/10 10 dont signe et 5 décimales  Taux plafond
    P1_22_24   NUMBER(14,10)    , -- P1 22.24    NUM/10 10 dont signe et 5 décimales  Taux plancher
    P1_22_25   VARCHAR2(1)    , -- P1 22.25    ALPHA/1  Fréquence de révision du taux
    P1_22_26   NUMBER(3)      , -- P1 22.26    NUM/3  Périodicité de révision du taux en nombre
    P1_22_27   NUMBER(14,10)    , -- P1 22.27    NUM/10 10 dont signe et 5 décimales  Taux client de la période en 
    P1_22_28   NUMBER(14,10)    , -- P1 22.28    NUM/10 10 dont signe et 5 décimales  Taux de marge additive
    P1_22_29   NUMBER(14,10)    , -- P1 22.29    NUM/10 10 dont signe et 5 décimales  Taux de marge multiplicative
    P1_22_30   VARCHAR2(7)    , -- P1 22.30    ALPHA/7  Base de calcul des intérêts
    P1_22_31   DATE           , -- P1 22.31    DATE/8  Date du premier déblocage de fonds
    P1_22_32   NUMBER(18,2)   , -- P1 22.32    NUM/19 19 dont signe et 2 décimales  Montant du premier déblocage 
    P1_22_33   VARCHAR2(3)    , -- P1 22.33    ALPHA/3  Devise du montant du premier déblocage de fonds
    P1_22_34   NUMBER(18,2)   , -- P1 22.34    NUM/19 19 dont signe et 2 décimales  Montant du capital théorique 
    P1_22_35   VARCHAR2(3)    , -- P1 22.35    ALPHA/3  Devise du montant du capital théorique restant dû
    P1_22_36   VARCHAR2(1)    , -- P1 22.36    ALPHA/1  Option de remboursement anticipé
    P1_22_37   DATE           , -- P1 22.37    DATE/8  Date du premier arriéré de paiement
    P1_22_38   DATE           , -- P1 22.38    DATE/8  Date de passage de l'encours en douteux compromis
    P1_22_39   NUMBER(18,2)   , -- P1 22.39    NUM/19 19 dont signe et 2 décimales  Montant de l'encours en doute
    P1_22_40   VARCHAR2(3)    , -- P1 22.40    ALPHA/3  Devise du montant de l'encours en douteux compromis
    P1_22_41   DATE           , -- P1 22.41    DATE/8  Date de déchéance du terme
    P1_22_42   NUMBER(9,5)    , -- P1 22.42    NUM/10 10 dont signe et 5 décimales  Loan-to-value ratio (LTV) loc
    P1_22_43   NUMBER(9,5)    , -- P1 22.43    NUM/10 10 dont signe et 5 décimales  Loan-to-value ratio (LTV) loc
    P1_22_44   NUMBER(18,2)   , -- P1 22.44    NUM/19 19 dont signe et 2 décimales  Montant à l'acquisition du bi
    P1_22_45   VARCHAR2(3)    , -- P1 22.45    ALPHA/3  Devise du montant à l'acquisition du bien financé
    P1_22_46   DATE           , -- P1 22.46    DATE/8  Date de revalorisation du bien
    P1_22_47   NUMBER(18,2)   , -- P1 22.47    NUM/19 19 dont signe et 2 décimales  Montant revalorisé du bien fi
    P1_22_48   VARCHAR2(3)    , -- P1 22.48    ALPHA/3  Devise du montant revalorisé du bien financé
    P1_22_49   NUMBER(9,5)    , -- P1 22.49    NUM/10 10 dont signe et 5 décimales  Loan-to-income ratio (LTI) lo
    P1_22_50   NUMBER(9,5)    , -- P1 22.50    NUM/10 10 dont signe et 5 décimales  Loan-to-income ratio (LTI) lo
    P1_22_51   VARCHAR2(40)   , -- P1 22.51    ALPHA/40  Référence Unique de l'élément du contrat
    P1_22_52   VARCHAR2(10)   , -- P1 22.52    ALPHA/10  Note externe à l'origine
    P1_22_53   VARCHAR2(2)    , -- P1 22.53    ALPHA/2  Segment de notation à l'origine
    P1_22_54   VARCHAR2(46)   , -- P1 22.54    ALPHA/46  Grille Modèle de notation à l'origine
    P1_22_55   VARCHAR2(3)    , -- P1 22.55    ALPHA/3  Méthodologie de notation à l'origine
    P1_22_56   VARCHAR2(3)    , -- P1 22.56    ALPHA/3  Indicateur produit échéancé
    P1_22_57   VARCHAR2(1)    , -- P1 22.57    ALPHA/1  Indicateur objet métier palier fourni
    P1_22_58   DATE           , -- P1 22.58    DATE/8  Date de début de palier
    P1_22_59   DATE           , -- P1 22.59    DATE/8  Date de fin de palier
    P1_22_60   NUMBER(18,2)   , -- P1 22.60    NUM/19 19 dont signe et 2 décimales  Montant de l'échéance en cour
    P1_22_61   VARCHAR2(3)    , -- P1 22.61    ALPHA/3  Devise du montant de l'échéance en cours
    P1_22_62   VARCHAR2(1)    , -- P1 22.62    ALPHA/1  Indicateur pré / post fixé
    P1_22_63   DATE           , -- P1 22.63    DATE/8  Date de début de l'engagement renouvelé
    P1_22_64   VARCHAR2(2)    , -- P1 22.64    ALPHA/2  Type de prêt habitat
    P1_22_65   NUMBER(9,5)    , -- P1 22.65    NUM/10 10 dont signe et 5 décimales  Taux d'endettement à l'octroi
    P1_22_66   VARCHAR2(2)    , -- P1 22.66    ALPHA/2  Pays de juridiction du contrat
    P1_22_67   DATE           , -- P1 22.67    DATE/8  Date de signature du contrat initial
    P1_22_68   VARCHAR2(2)    , -- P1 22.68    ALPHA/2  Evénement déclencheur de la garantie
    P1_22_69   VARCHAR2(1)    , -- P1 22.69    ALPHA/1  Indicateur Différé carte de paiement
    P1_22_70   VARCHAR2(5)    , -- P1 22.70    ALPHA/5  Nombre de jours de retard de paiement
    P1_22_71   VARCHAR2(3)    , -- P1 22.71    ALPHA/3  Motif du passage en engagement en défaut
    P1_22_72   VARCHAR2(2)    , -- P1 22.72    ALPHA/2  Bucket IFRS9
    P1_22_73   NUMBER(9,5)    , -- P1 22.73    NUM/10 10 dont signe et 5 décimales  Probabilité de défaut à l'ori
    P1_22_74   NUMBER(9,5)    , -- P1 22.74    NUM/10 10 dont signe et 5 décimales  Probabilité de défaut à date 
    P1_22_222  VARCHAR2(1)    , -- P1 22.222   ALPHA/1  Indicateur différé d'amortissement
    P1_23_1    VARCHAR2(1)    , -- P1 23.1     ALPHA/1  Eligibilité Outil Mutualisé de provisionnement
    P1_23_2    VARCHAR2(7)    , -- P1 23.2     ALPHA/7  Centre de résultat
    P1_23_3    VARCHAR2(20)   , -- P1 23.3     ALPHA/20  Système de gestion source
    P1_23_4    VARCHAR2(3)    , -- P1 23.4     ALPHA/3  Classification comptable des actifs en norme IFRS9
    P1_23_5    VARCHAR2(3)    , -- P1 23.5     ALPHA/3  Classification comptable des actifs en norme nationale
    P1_23_6    VARCHAR2(1)    , -- P1 23.6     ALPHA/1  Indicateur Actif déprécié dès l'origination
    P1_23_7    VARCHAR2(40)   , -- P1 23.7     ALPHA/40  Zone libre d'appariement comptable
    P1_23_8    VARCHAR2(12)   , -- P1 23.8     ALPHA/12  Code méthode IFRS9 - PD
    P1_23_9    VARCHAR2(12)   , -- P1 23.9     ALPHA/12  Code méthode IFRS9 - Loss Given Default (LGD)
    P1_23_10   VARCHAR2(12)   , -- P1 23.10    ALPHA/12  Code méthode IFRS9 - CCF
    P1_23_11   VARCHAR2(12)   , -- P1 23.11    ALPHA/12  Code méthode IFRS9 - Taux de remboursement anticipé
    P1_23_12   VARCHAR2(5)    , -- P1 23.12    ALPHA/5  Zone OMP locale 1
    P1_23_13   VARCHAR2(5)    , -- P1 23.13    ALPHA/5  Zone OMP locale 2
    P1_23_99   VARCHAR2(2)    , -- P1 23.99    ALPHA/2  Filler
    P1_24_1    VARCHAR2(1)    , -- P1 24.1     ALPHA/1  Eligibilité Prudent Valuation
    P1_24_2    VARCHAR2(2)    , -- P1 24.2     ALPHA/2  Motif d'exemption déclaré à l'ajustement à la juste valeu
    P1_24_3    VARCHAR2(1)    , -- P1 24.3     ALPHA/1  Hiérarchie de la juste valeur
    P1_24_4    VARCHAR2(1)    , -- P1 24.4     ALPHA/1  Complexité du produit
    P1_24_5    VARCHAR2(1)    , -- P1 24.5     ALPHA/1  Indicateur actif coté
    P1_24_6    NUMBER(12,2)   , -- P1 24.6     NUM/13 13 dont signe et 2 décimales  Quantité de titres ou de déri
    P1_24_7    VARCHAR2(50)   , -- P1 24.7     ALPHA/50  Libellé du titre
    P1_24_8    VARCHAR2(1)    , -- P1 24.8     ALPHA/1  Type d'identification des valeurs mobilières
    P1_24_9    VARCHAR2(1)    , -- P1 24.9     ALPHA/1  Fréquence de valorisation
    P1_24_10   NUMBER(18,2)   , -- P1 24.10    NUM/19 19 dont signe et 2 décimales  Montant actif net comptable d
    P1_24_11   VARCHAR2(3)    , -- P1 24.11    ALPHA/3  Devise du montant actif net comptable du fonds
    P1_24_12   NUMBER(9,5)    , -- P1 24.12    NUM/10 10 dont signe et 5 décimales  Ratio d'emprise
    P1_24_13   NUMBER(9,5)    , -- P1 24.13    NUM/10 10 dont signe et 5 décimales  Cotation spread émetteur (%)
    P1_24_14   NUMBER(18,2)   , -- P1 24.14    NUM/19 19 dont signe et 2 décimales  Montant d'acquisition initial
    P1_24_15   VARCHAR2(3)    , -- P1 24.15    ALPHA/3  Devise du montant d'acquisition initial unitaire
    P1_24_16   NUMBER(18,2)   , -- P1 24.16    NUM/19 19 dont signe et 2 décimales  Montant du Mark-to-Market (Mt
    P1_24_17   VARCHAR2(3)    , -- P1 24.17    ALPHA/3  Devise du montant du Mark-to-Market (MtM) Pied de coupon
    P1_24_18   NUMBER(18,2)   , -- P1 24.18    NUM/19 19 dont signe et 2 décimales  Montant du Mark-to-Market (Mt
    P1_24_19   VARCHAR2(3)    , -- P1 24.19    ALPHA/3  Devise du montant du Mark-to-Market (MtM) de la part non 
    P1_24_20   VARCHAR2(1)    , -- P1 24.20    ALPHA/1  Indicateur back to back
    P1_24_21   VARCHAR2(40)   , -- P1 24.21    ALPHA/40  Référence unique de l'opération associée en back to back
    P1_24_22   VARCHAR2(40)   , -- P1 24.22    ALPHA/40  Référence unique de l'opération de dérivé en couverture
    P1_24_22_1 VARCHAR2(1)    , -- P1 24.22.1  ALPHA/1  Indicateur dérivé en couverture
    P1_24_23   VARCHAR2(1)    , -- P1 24.23    ALPHA/1  Intention de couverture
    P1_24_24   VARCHAR2(1)    , -- P1 24.24    ALPHA/1  Type de relation de couverture
    P1_24_25   VARCHAR2(1)    , -- P1 24.25    ALPHA/1  Jambe prêteuse : Indicateur actif coté
    P1_24_26   NUMBER(10)     , -- P1 24.26    NUM/10  Jambe prêteuse : quantité de titres
    P1_24_27   VARCHAR2(50)   , -- P1 24.27    ALPHA/50  Jambe prêteuse : libellé du titre
    P1_24_28   VARCHAR2(1)    , -- P1 24.28    ALPHA/1  Jambe prêteuse : type d'identification des valeurs mobili
    P1_24_29   VARCHAR2(1)    , -- P1 24.29    ALPHA/1  Jambe prêteuse : indicateur mobilisation de l'actif
    P1_24_30   VARCHAR2(1)    , -- P1 24.30    ALPHA/1  Jambe prêteuse : indicateur collatéral reçu
    P1_24_31   VARCHAR2(1)    , -- P1 24.31    ALPHA/1  Jambe emprunteuse : Indicateur actif coté
    P1_24_32   NUMBER(10)     , -- P1 24.32    NUM/10  Jambe emprunteuse : quantité de titres
    P1_24_33   VARCHAR2(50)   , -- P1 24.33    ALPHA/50  Jambe emprunteuse : libellé du titre
    P1_24_34   VARCHAR2(1)    , -- P1 24.34    ALPHA/1  Jambe emprunteuse : type d'identification des valeurs mob
    P1_24_35   VARCHAR2(1)    , -- P1 24.35    ALPHA/1  Jambe emprunteuse : indicateur mobilisation de l'actif
    P1_24_36   VARCHAR2(1)    , -- P1 24.36    ALPHA/1  Jambe emprunteuse : indicateur collatéral reçu
    P1_24_37   VARCHAR2(12)   , -- P1 24.37    ALPHA/12  Référence unique du titre couvert par l'opération de dér
    P1_24_97   VARCHAR2(30)   , -- P1 24.97    ALPHA/30  Jambe prêteuse : zone réservée
    P1_24_98   VARCHAR2(30)   , -- P1 24.98    ALPHA/30  Jambe emprunteuse : zone réservée
    P1_24_99   VARCHAR2(10)   , -- P1 24.99    ALPHA/10  Filler
    P1_25_1    NUMBER(18,2)   , -- P1 25.1     NUM/19 19 dont signe et 2 décimales  Montant Add-on CAD
    P1_25_2    VARCHAR2(3)    , -- P1 25.2     ALPHA/3  Devise du montant de add-on CAD
    P1_25_3    NUMBER(18,2)   , -- P1 25.3     NUM/19 19 dont signe et 2 décimales  Montant de l'Exposition en ca
    P1_25_4    VARCHAR2(3)    , -- P1 25.4     ALPHA/3  Devise du montant de l'Exposition en cas de Défaut (EAD) 
    P1_25_5    NUMBER(18,2)   , -- P1 25.5     NUM/19 19 dont signe et 2 décimales  Montant de l'Exposition en ca
    P1_25_6    VARCHAR2(3)    , -- P1 25.6     ALPHA/3  Devise du montant de l'Exposition en cas de Défaut (EAD) 
    P1_25_7    NUMBER(6,4)    , -- P1 25.7     NUM/6 6 dont 4 décimales  Maturité effective en méthode IMM (inter
    P1_25_8    NUMBER(6,4)    , -- P1 25.8     NUM/6 6 dont 4 décimales  Maturité effective stressée en méthode I
    P1_25_99   VARCHAR2(100)  , -- P1 25.99    ALPHA/100  Filler
    P1_26_1    VARCHAR2(1)    , -- P1 26.1     ALPHA/1  Indicateur mobilisation de l'actif
    P1_26_3    VARCHAR2(3)    , -- P1 26.3     ALPHA/3  Référence de mobilisation de l'actif
    P1_26_4    VARCHAR2(3)    , -- P1 26.4     ALPHA/3  Code organisme de mobilisation
    P1_26_99   VARCHAR2(44)   , -- P1 26.99    ALPHA/44  Zone réservée Asset Encumbrance
    P1_27_1    NUMBER(18,2)   , -- P1 27.1     NUM/19 19 dont signe et 2 décimales  Montant cumulé des recouvreme
    P1_27_2    VARCHAR2(3)    , -- P1 27.2     ALPHA/3  Devise du montant cumulé des recouvrements depuis le défa
    P1_27_3    VARCHAR2(1)    , -- P1 27.3     ALPHA/1  Eligibilité Outil Central ANACREDIT
    P1_27_4    VARCHAR2(2)    , -- P1 27.4     ALPHA/2  Motif exclusion à la déclaration ANACREDIT
    P1_27_99   VARCHAR2(23)   , -- P1 27.99    ALPHA/23  Filler
    P1_28_1    VARCHAR2(1)    , -- P1 28.1     ALPHA/1  Indicateur opération effet de levier
    P1_28_2    VARCHAR2(1)    , -- P1 28.2     ALPHA/1  Indicateur sponsor financier majoritaire au capital
    P1_28_3    VARCHAR2(2)    , -- P1 28.3     ALPHA/2  Nature du financement
    P1_28_4    VARCHAR2(2)    , -- P1 28.4     ALPHA/2  Type d'origination opération à effet de levier
    P1_28_5    VARCHAR2(2)    , -- P1 28.5     ALPHA/2  Type clause contrat covenant
    P1_28_6    VARCHAR2(20)   , -- P1 28.6     ALPHA/20  Identifiant local du tiers sponsor financier
    P1_28_7    VARCHAR2(10)   , -- P1 28.7     ALPHA/10  Identifiant central du tiers sponsor financier
    P1_28_8    NUMBER(14,9)   , -- P1 28.8     NUM/15 15 dont signe et 9 décimales  Ratio de levier de l'opératio
    P1_28_9    NUMBER(18,2)   , -- P1 28.9     NUM/19 19 dont signe et 2 décimales  Montant de la part de la pris
    P1_28_10   VARCHAR2(3)    , -- P1 28.10    ALPHA/3  Devise du montant de la part de la prise ferme du montant
    P1_28_11   NUMBER(18,2)   , -- P1 28.11    NUM/19 19 dont signe et 2 décimales  Montant de la part à syndique
    P1_28_12   VARCHAR2(3)    , -- P1 28.12    ALPHA/3  Devise du montant de la part à syndiquer du montant du co
    P1_28_13   NUMBER(18,2)   , -- P1 28.13    NUM/19 19 dont signe et 2 décimales  Montant de la part à syndique
    P1_28_14   VARCHAR2(3)    , -- P1 28.14    ALPHA/3  Devise du montant de la part à syndiquer non cédé
    P1_29_1    NUMBER(18,2)   , -- P1 29.1     NUM/19 19 dont signe et 2 décimales  Montant de l'indemnité de rés
    P1_29_2    VARCHAR2(3)    , -- P1 29.2     ALPHA/3  Devise du montant de l'indemnité de résiliation
    P1_29_3    NUMBER(18,2)   , -- P1 29.3     NUM/19 19 dont signe et 2 décimales  Montant des subventions
    P1_29_4    VARCHAR2(3)    , -- P1 29.4     ALPHA/3  Devise du montant des subventions
    P1_29_5    NUMBER(18,2)   , -- P1 29.5     NUM/19 19 dont signe et 2 décimales  Montant de l'avance preneur e
    P1_29_6    VARCHAR2(3)    , -- P1 29.6     ALPHA/3  Devise du montant de l'avance preneur en crédit-bail
    P1_30_1    VARCHAR2(2)    , -- P1 30.1     ALPHA/2  Type de contrat cadre
    P1_30_2    VARCHAR2(1)    , -- P1 30.2     ALPHA/1  Indicateur protocole ISDA de niveau entité
    P1_30_3    VARCHAR2(1)    , -- P1 30.3     ALPHA/1  Indicateur protocole ISDA de niveau contrepartie
    P1_30_4    NUMBER(18,2)   , -- P1 30.4     NUM/19 19 dont signe et 2 décimales  Montant du nominal des titres
    P1_30_5    VARCHAR2(3)    , -- P1 30.5     ALPHA/3  Devise du montant du nominal des titres de la jambe prête
    P1_30_6    NUMBER(18,2)   , -- P1 30.6     NUM/19 19 dont signe et 2 décimales  Montant des coupons courus no
    P1_30_7    VARCHAR2(3)    , -- P1 30.7     ALPHA/3  Devise du montant des coupons courus non échus de la jamb
    P1_30_8    NUMBER(18,2)   , -- P1 30.8     NUM/19 19 dont signe et 2 décimales  Montant du nominal des titres
    P1_30_9    VARCHAR2(3)    , -- P1 30.9     ALPHA/3  Devise du montant du nominal des titres de la jambe empru
    P1_30_10   NUMBER(18,2)   , -- P1 30.10    NUM/19 19 dont signe et 2 décimales  Montant des coupons courus no
    P1_30_11   VARCHAR2(3)    , -- P1 30.11    ALPHA/3  Devise du montant des coupons courus non échus de la jamb
    P1_30_12   NUMBER(18,2)   , -- P1 30.12    NUM/19 19 dont signe et 2 décimales  Montant des coupons courus no
    P1_30_13   VARCHAR2(3)    , -- P1 30.13    ALPHA/3  Devise du montant des coupons courus non échus de la jamb
    P1_30_14   NUMBER(18,2)   , -- P1 30.14    NUM/19 19 dont signe et 2 décimales  Montant des coupons courus no
    P1_30_15   VARCHAR2(3)    , -- P1 30.15    ALPHA/3  Devise du montant des coupons courus non échus de la jamb
    P1_30_16   VARCHAR2(1)    , -- P1 30.16    ALPHA/1  Fréquence de paiement du taux reçu
    P1_30_17   NUMBER(9,5)    , -- P1 30.17    NUM/10 10 dont signe et 5 décimales  Taux de marge additive reçue
    P1_30_18   VARCHAR2(7)    , -- P1 30.18    ALPHA/7  Base de calcul des intérêts reçus
    P1_30_19   VARCHAR2(1)    , -- P1 30.19    ALPHA/1  Fréquence de paiement du taux payé
    P1_30_20   NUMBER(9,5)    , -- P1 30.20    NUM/10 10 dont signe et 5 décimales  Taux de marge additive payée
    P1_30_21   VARCHAR2(7)    , -- P1 30.21    ALPHA/7  Base de calcul des intérêts payés
    P1_30_22   VARCHAR2(25)   , -- P1 30.22    ALPHA/25  Référence du contrat cadre
    P1_30_23   VARCHAR2(1)    , -- P1 30.23    ALPHA/1  Indicateur accord de netting contractuel
    P1_30_24   VARCHAR2(25)   , -- P1 30.24    ALPHA/25  Référence du contrat de netting contractuel
    P1_30_25   VARCHAR2(1)    , -- P1 30.25    ALPHA/1  Indicateur accord de netting comptable
    P1_30_26   VARCHAR2(25)   , -- P1 30.26    ALPHA/25  Référence du contrat de netting comptable
    P1_30_27   VARCHAR2(1)    , -- P1 30.27    ALPHA/1  Finalité de l'opération
    P1_31_1    VARCHAR2(5)    , -- P1 31.1     ALPHA/5  Code entité de la succursale à l'origine de l'opération
    P1_31_2    VARCHAR2(40)   , -- P1 31.2     ALPHA/40  Référence unique du contrat à l'origine
    P1_31_3    VARCHAR2(40)   , -- P1 31.3     ALPHA/40  Référence unique de l'élément de contrat à l'origine
    P1_31_4    NUMBER(18,2)   , -- P1 31.4     NUM/19 19 dont signe et 2 décimales  Montant en euros de l'engagem
    P1_31_5    VARCHAR2(1)    , -- P1 31.5     ALPHA/1  Indicateur responsabilité solidaire
    P1_31_6    VARCHAR2(1)    , -- P1 31.6     ALPHA/1  Indicateur dossier infrastructure éligible au facteur de 
    P1_31_7    VARCHAR2(6)    , -- P1 31.7     ALPHA/6  Rang dans la hiérarchie des créanciers
    P1_31_8    VARCHAR2(1)    , -- P1 31.8     ALPHA/1  Droit d'un pays tiers : reconnaissance de la clause de ba
    P1_31_9    VARCHAR2(15)   , -- P1 31.9     ALPHA/15  Lieu d'investissement du bien principal financé : code p
    P1_31_10   VARCHAR2(2)    , -- P1 31.10    ALPHA/2  Lieu d'investissement du bien principal financé : Code pa
    P1_31_11   VARCHAR2(1)    , -- P1 31.11    ALPHA/1  Indicateur permis de construire à l'octroi
    P1_31_12   VARCHAR2(1)    , -- P1 31.12    ALPHA/1  Etat du bien financé à l'octroi
    P1_31_13   VARCHAR2(1)    , -- P1 31.13    ALPHA/1  Catégorie énergétique du bien immobilier à l'octroi
    P1_31_14   NUMBER(14,9)   , -- P1 31.14    NUM/15 15 dont signe et 9 décimales  Taux de réservation du progra
    P1_31_15   NUMBER(18,2)   , -- P1 31.15    NUM/19 19 dont signe et 2 décimales  Montant de l'apport à l'octro
    P1_31_16   VARCHAR2(3)    , -- P1 31.16    ALPHA/3  Devise du montant de l'apport à l'octroi
    P1_31_17   NUMBER(5)      , -- P1 31.17    NUM/6 6 dont signe  Durée initiale du prêt
    P1_31_18   NUMBER(5)      , -- P1 31.18    NUM/6 6 dont signe  Durée totale du prêt à date
    P1_31_19   NUMBER(5)      , -- P1 31.19    NUM/6 6 dont signe  Durée de la période d'anticipation à date d'ar
    P1_31_20   VARCHAR2(1)    , -- P1 31.20    ALPHA/1  Méthode de valorisation du bien
    P1_31_21   VARCHAR2(2)    , -- P1 31.21    ALPHA/2  Type de sécurisation à l'octroi
    P1_31_22   VARCHAR2(2)    , -- P1 31.22    ALPHA/2  Type de sécurisation à date
    P1_31_23   NUMBER(18,2)   , -- P1 31.23    NUM/19 19 dont signe et 2 décimales  Montant des fonds remis à dat
    P1_31_24   VARCHAR2(3)    , -- P1 31.24    ALPHA/3  Devise du montant des fonds remis à date
    P1_31_25   NUMBER(14,9)   , -- P1 31.25    NUM/15 15 dont signe et 9 décimales  Interest Coverage Ratio (ICR)
    P1_31_26   NUMBER(14,9)   , -- P1 31.26    NUM/15 15 dont signe et 9 décimales  Loan-to-rent ratio (LTR) à l'
    P1_31_27   NUMBER(14,9)   , -- P1 31.27    NUM/15 15 dont signe et 9 décimales  LSTI à l'octroi
    P1_31_28   NUMBER(14,9)   , -- P1 31.28    NUM/15 15 dont signe et 9 décimales  DSTI à l'octroi
    P1_31_29   NUMBER(14,9)   , -- P1 31.29    NUM/15 15 dont signe et 9 décimales  Taux de marge du crédit brut 
    P1_31_30   VARCHAR2(1)    , -- P1 31.30    ALPHA/1  Motif déclaration JV
    P1_31_31   VARCHAR2(1)    , -- P1 31.31    ALPHA/1  Mode de cotation du titre
    P1_31_32   DATE           , -- P1 31.32    DATE/8  Date d'émission du titre
    P1_31_33   DATE           , -- P1 31.33    DATE/8  Date de maturité du titre
    P1_31_34   VARCHAR2(1)    , -- P1 31.34    ALPHA/1  Etat du titre
    P1_31_35   DATE           , -- P1 31.35    DATE/8  Date de l'état du titre
    P1_31_36   VARCHAR2(1)    , -- P1 31.36    ALPHA/1  Indicateur prise ferme sur les titres
    P1_31_37   VARCHAR2(1)    , -- P1 31.37    ALPHA/1  Indicateur garantie sans limite
    P1_31_38   VARCHAR2(1)    , -- P1 31.38    ALPHA/1  Etendue de la garantie donnée
    P1_31_51   VARCHAR2(20)   , -- P1 31.51    ALPHA/20  Identifiant du contrat maître en responsabilité solidair
    P1_31_52   NUMBER(18,2)   , -- P1 31.52    NUM/19 19 dont signe et 2 décimales  Montant en responsabilité sol
    P1_31_53   VARCHAR2(3)    , -- P1 31.53    ALPHA/3  Devise du montant en responsabilité solidaire
    P1_50_1    VARCHAR2(3)    , -- P1 50.1     ALPHA/3  Devise de liasse de l'entité
    P1_50_2    VARCHAR2(12)   , -- P1 50.2     ALPHA/12  PCCO - Montant du principal 1
    P1_50_3    NUMBER(18,2)   , -- P1 50.3     NUM/19 19 dont signe et 2 décimales  Montant du principal 1
    P1_50_4    VARCHAR2(12)   , -- P1 50.4     ALPHA/12  PCCO - Montant du principal 2
    P1_50_5    NUMBER(18,2)   , -- P1 50.5     NUM/19 19 dont signe et 2 décimales  Montant du principal 2
    P1_50_8    VARCHAR2(12)   , -- P1 50.8     ALPHA/12  PCCO - Montant des Dettes et créances rattachées
    P1_50_9    NUMBER(18,2)   , -- P1 50.9     NUM/19 19 dont signe et 2 décimales  Montant des Dettes et créance
    P1_50_14   VARCHAR2(12)   , -- P1 50.14    ALPHA/12  PCCO - Montant Marge initiale - Fonds de défaut
    P1_50_15   NUMBER(18,2)   , -- P1 50.15    NUM/19 19 dont signe et 2 décimales  Montant Marge initiale - Fond
    P1_50_16   VARCHAR2(12)   , -- P1 50.16    ALPHA/12  PCCO - Montant Marge variable
    P1_50_17   NUMBER(18,2)   , -- P1 50.17    NUM/19 19 dont signe et 2 décimales  Montant Marge variable
    P1_50_18   VARCHAR2(12)   , -- P1 50.18    ALPHA/12  PCCO - Montant Impacts JV
    P1_50_19   NUMBER(18,2)   , -- P1 50.19    NUM/19 19 dont signe et 2 décimales  Montant Impacts JV
    P1_50_20   VARCHAR2(12)   , -- P1 50.20    ALPHA/12  PCCO - Montant du principal 3
    P1_50_21   NUMBER(18,2)   , -- P1 50.21    NUM/19 19 dont signe et 2 décimales  Montant du principal 3
    P1_99_99   VARCHAR2(1185) , -- P1 99.99    ALPHA/1185  Filler
    P1_600     VARCHAR2(1)    , -- P1 600      ALPHA/1  Indicateur Présence de recouvrement
    P1_601     VARCHAR2(1)    , -- P1 601      ALPHA/1  Type de recouvrement à l'amiable ou contentieux
    P1_602     VARCHAR2(1)    , -- P1 602      ALPHA/1  Statut de recouvrement
    P1_603     NUMBER(18,2)   , -- P1 603      NUM/19 19 dont signe et 2 décimales  Montant recouvré depuis le dé
    P1_603_1   VARCHAR2(3)    , -- P1 603.1    ALPHA/3  Devise du montant recouvré depuis le défaut
    P1_604     NUMBER(18,2)   , -- P1 604      NUM/19 19 dont signe et 2 décimales  Montant passé à perte depuis 
    P1_604_1   VARCHAR2(3)    , -- P1 604.1    ALPHA/3  Devise du montant passé à perte depuis le défaut
    P1_605     NUMBER(18,2)   , -- P1 605      NUM/19 19 dont signe et 2 décimales  Montant tiré depuis le défaut
    P1_605_1   VARCHAR2(3)    , -- P1 605.1    ALPHA/3  Devise du montant tiré depuis le défaut
    P1_606     VARCHAR2(40)   , -- P1 606      ALPHA/40  Identifiant du contrat restructuré en cas de changement 
    P1_607     VARCHAR2(1)    , -- P1 607      ALPHA/1  Indicateur de multi financement par plusieurs entités
    P1_608     NUMBER(18,2)   , -- P1 608      NUM/19 19 dont signe et 2 décimales  Montant des prélèvements supp
    P1_608_1   VARCHAR2(3)    , -- P1 608.1    ALPHA/3  Devise du montant des prélèvements supplémentaires après 
    P1_609     DATE           , -- P1 609      DATE/8  Date des prélèvements supplémentaires après le défaut
    P1_610     NUMBER(18,2)   , -- P1 610      NUM/19 19 dont signe et 2 décimales  Montant des coûts directs ass
    P1_610_1   VARCHAR2(3)    , -- P1 610.1    ALPHA/3  Devise du montant des coûts directs associés à la procédu
    P1_611     DATE           , -- P1 611      DATE/8  Date des coûts directs associés à la procédure de recouvre
    P1_612     NUMBER(18,2)   , -- P1 612      NUM/19 19 dont signe et 2 décimales  Montant des frais divers
    P1_612_1   VARCHAR2(3)    , -- P1 612.1    ALPHA/3  Devise du montant des frais divers
    P1_613     VARCHAR2(1)    , -- P1 613      ALPHA/1  Indicateur engagement renouvelable
    P1_614     NUMBER(18,2)   , -- P1 614      NUM/19 19 dont signe et 2 décimales  Exposure at default (EAD) sta
    P1_614_1   VARCHAR2(3)    , -- P1 614.1    ALPHA/3  Devise de l'Exposure at default (EAD) standard local
    P1_615     NUMBER(5,4)    , -- P1 615      NUM/6 6 dont signe et 4 décimales  Maturité Exposure at default (E
    P1_616     VARCHAR2(1)    , -- P1 616      ALPHA/1  Indicateur calcul de RWA en local au titre de la CVA prud
    P1_617     VARCHAR2(1)    , -- P1 617      ALPHA/1  Plan de roll-out
    P1_618     VARCHAR2(1)    , -- P1 618      ALPHA/1  Type de crypto-actifs au sens de l'article 501 quinquies 
    P1_619     NUMBER(18,2)   , -- P1 619      NUM/19 19 dont signe et 2 décimales  Coefficient « Beta » pour mod
    P1_620     VARCHAR2(1)    , -- P1 620      ALPHA/1  Indicateur Exposition financée en devise locale
    P1_622     VARCHAR2(1)    , -- P1 622      ALPHA/1  Intention de gestion de l’opération pour compte propre (O
    P1_623     VARCHAR2(40)   , -- P1 623      ALPHA/40  Identifiant Markit
    P1_624     NUMBER(14,9)   , -- P1 624      NUM/15 15 dont signe et 9 décimales  Taux de recouvrement du Credi
    P1_625     VARCHAR2(2)    , -- P1 625      ALPHA/2  Note estimée du groupe de risque à l'origination des fina
    P1_626     VARCHAR2(1)    , -- P1 626      ALPHA/1  Indicateur nouvelle production (trimestriel)
    P1_627     VARCHAR2(1)    , -- P1 627      ALPHA/1  Indicateur période de fronting
    P1_628     NUMBER(18,2)   , -- P1 628      NUM/19 19 dont signe et 2 décimales  Montant d'exposition réglemen
    P1_628_1   VARCHAR2(3)    , -- P1 628.1    ALPHA/3  Devise du montant d'exposition réglementaire soumise au f
    P1_629     VARCHAR2(1)    , -- P1 629      ALPHA/1  Indicateur Reserve Based Lending (RBL)
    P1_630     NUMBER(18,2)   , -- P1 630      NUM/19 19 dont signe et 2 décimales  Exposition réglementaire soum
    P1_630_1   VARCHAR2(3)    , -- P1 630.1    ALPHA/3  Devise de l'exposition réglementaire soumise au RBL
    P1_631     NUMBER(18,2)   , -- P1 631      NUM/19 19 dont signe et 2 décimales  Expositions à date d'arrêté (
    P1_631_1   VARCHAR2(3)    , -- P1 631.1    ALPHA/3  Devise des expositions à date d'arrêté (vision stock) sur
    P1_632     NUMBER(18,2)   , -- P1 632      NUM/19 19 dont signe et 2 décimales  Expositions arrangées par la 
    P1_632_1   VARCHAR2(3)    , -- P1 632.1    ALPHA/3  Devise des expositions arrangées par la banque au cours d
    P1_633     NUMBER(18,2)   , -- P1 633      NUM/19 19 dont signe et 2 décimales  Montant du Mark-to-market hor
    P1_633_1   VARCHAR2(3)    , -- P1 633.1    ALPHA/3  Devise du montant du Mark-to-market hors part à syndiquer
    P1_635     VARCHAR2(1)    , -- P1 635      ALPHA/1  Indicateur Facteur de Conversion de Crédit (CCF) modèle i
    P1_1001    DATE           , -- P1 1001     DATE/8  Date de réalisation du tirage
    P1_1002    DATE             -- P1 1002     DATE/8  Date d'échéance du tirage
)
TABLESPACE HCRR ;

COMMENT ON TABLE ENG_CORP_P1_BIS IS 'SIRL-1224 - Donnees pave P1 (regles de gestion sorties du spool 030_spool_Extract_CRRCORP)';