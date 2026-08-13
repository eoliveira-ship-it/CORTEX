-- =====================================================================
-- SIRL-1224 : alimentation de la table ENG_CORP_P1_BIS
-- Package  : pack_alim_tab_envoi_crrv4
-- Procedure: P_ALIM_ENG_CORP_P1_BIS
--
-- But : sortir les regles de gestion du pave P1 hors du spool
--       030_spool_Extract_CRRCORP.sql et les porter dans cette procedure,
--       qui remplit ENG_CORP_P1_BIS a partir de ENG_CORP_P1.
--       Le spool vPACT ne fera plus qu'un SELECT unique sur la table.
--
-- Le pave P1 est aujourd'hui produit par 8 SELECT sur ENG_CORP_P1 C_ENR,
-- qui partitionnent la population (perimetre NAT02 vs Hors-NAT, arriere de
-- paiement, montant, type de risque). Chaque SELECT devient ici un INSERT
-- qui garde SON filtre (clause WHERE) a l'identique.
--
--   #  ligne spool  FLAG_HN  filtre principal
--   1     590         N       risque std,  (CRD-VR)>=1 ou VR>=1
--   2    1089         N       arriere='Y', SOLD_K_A>=1, pas TRE2%
--   3    1592         N       arriere='Y', (CRD-VR)>=1 ou VR>=1, pas TRE2%
--   4    2894         O       CD_TYPE_RISQUE = 'TRE100'
--   5    3462         O       CD_TYPE_RISQUE LIKE 'TRE2/TRE4/TRE5'
--   6    4026         O       CD_TYPE_RISQUE = 'EQU101'
--   7    4606         O       CD_TYPE_RISQUE IN ('SIG201','INR101')
--   8    5061         O       CD_TYPE_RISQUE LIKE '%VAR1%'
--
-- ---------------------------------------------------------------------
-- REGLES DE CONVERSION  format spool  ->  valeur typee dans la table
-- ---------------------------------------------------------------------
--   RPAD(NVL(C_ENR.X,' '),n)              ->  C_ENR.X              (VARCHAR)
--   RPAD(C_ENR.X,n)                       ->  C_ENR.X
--   RPAD(' ',n)  (champ vide dans le spool)->  NULL   (colonne non listee)
--   to_char(C_ENR.DT,'YYYYMMDD')          ->  C_ENR.DT             (DATE, brute)
--   RPAD(NVL(TO_CHAR(C_ENR.DT,'YYYYMMDD'),' '),8) -> C_ENR.DT
--   'M' / 'P1' / 'Y' ... (litteral)       ->  litteral conserve
--   pack_utilitaire.F_FORMAT_TAUX(C_ENR.X)         -> C_ENR.X       (NUMBER)
--   pack_utilitaire.f_format_montant_bis2(<expr>)  -> <expr>        (NUMBER)
--   CASE ... THEN '+' ELSE '-' END (signe)-> supprime (le signe est porte
--                                            par le NUMBER)
--   NVL/CASE metier (ex defaut 'STD', '99990630', EAD<0 -> 0)
--                                         ->  CONSERVE (c'est une regle
--                                            de gestion, pas du formatage)
--
-- FLAG_HN -> CD_PERIMETRE :  'N' => 'NAT02'   ,  'O' => 'HORS_NAT02'
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) A AJOUTER DANS LA SPEC DU PACKAGE  pack_alim_tab_envoi_crrv4
-- ---------------------------------------------------------------------
--   PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite IN VARCHAR2);


-- ---------------------------------------------------------------------
-- 2) CORPS DE LA PROCEDURE (a inserer dans le PACKAGE BODY)
-- ---------------------------------------------------------------------
PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite IN VARCHAR2)
IS
BEGIN
    ------------------------------------------------------------------
    -- Etape 1 : vider la table avant de la remplir (SFG SIRL-1224)
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ENG_CORP_P1_BIS';

    ------------------------------------------------------------------
    -- INSERT #1  (standard NAT02 - spool L590)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'NAT02'                                              AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 )
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104');

    ------------------------------------------------------------------
    -- INSERT #2  (NAT02 arriere='Y' solde - spool L1089)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'NAT02'                                              AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND NVL(C_ENR.MNT_SOLD_K_A,0) >= 1
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' );

    ------------------------------------------------------------------
    -- INSERT #3  (NAT02 arriere='Y' CRD/VR - spool L1592)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'NAT02'                                              AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' )
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 );

    ------------------------------------------------------------------
    -- INSERT #4  (Hors-NAT TRE100 - spool L2894)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'HORS_NAT02'                                         AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('TRE100');

    ------------------------------------------------------------------
    -- INSERT #5  (Hors-NAT TRE2/4/5 - spool L3462)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'HORS_NAT02'                                         AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5');

    ------------------------------------------------------------------
    -- INSERT #6  (Hors-NAT EQU101 - spool L4026)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'HORS_NAT02'                                         AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('EQU101');

    ------------------------------------------------------------------
    -- INSERT #7  (Hors-NAT SIG201/INR101 - spool L4606)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'HORS_NAT02'                                         AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101');

    ------------------------------------------------------------------
    -- INSERT #8  (Hors-NAT VAR1 - spool L5061)
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,     -- 0.1  Date d'arrete
        P1_H_0_2,     -- 0.2  Entite porteuse
        P1_H_0_3,     -- 0.3  Application source
        P1_H_0_4,     -- 0.4  Frequence transmission
        P1_H_0_6,     -- 0.6  Type d'enregistrement
        P1_H_1_1,     -- 1.1  Id local du tiers
        P1_H_1_4,     -- 1.4  Ref autorisation
        P1_H_1_6,     -- 1.6  Ref ligne de detail
        P1_H_1_11,    -- 1.11 Identifiant engagement
        P1_1_1,       -- Methodologie Baloise
        P1_1_2,       -- Traitement moteur balois
        P1_4_34,      -- Traitement GRR
        P1_2_0,       -- Type de risque
        P1_2_4,       -- Portefeuille de booking
        P1_2_6,       -- Ligne Metier
        P1_2_18,      -- Portefeuille Bale Operation
        P1_2_29,      -- Nature d'operation
        P1_3_2,       -- Date debut engagement
        P1_3_4,       -- Date fin engagement
        P1_18_1,      -- LGD (a confirmer position)
        P1_18_10,     -- CCF/TRC (a confirmer position)
        P1_18_5,      -- Montant EAD
        P1_18_17,     -- Devise montant expo
        P1_18_18,     -- Devise d'origine contrat
        P1_21_2      -- Date de Restructuration
        -- >>> A COMPLETER : suite du pave (memes regles de conversion)
    )
    SELECT
        'HORS_NAT02'                                         AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                      AS P1_H_0_1,
        C_ENR.CD_CONSO_CPT                                   AS P1_H_0_2,
        NVL(C_ENR.APPLI_SOURCE,'C_BTR')                      AS P1_H_0_3,
        'M'                                                  AS P1_H_0_4,
        'P1'                                                 AS P1_H_0_6,
        C_ENR.ID_TIERS_CALC                                  AS P1_H_1_1,
        C_ENR.ID_AUTORISATION                                AS P1_H_1_4,
        C_ENR.ID_LIGNE_DET                                   AS P1_H_1_6,
        C_ENR.ID_ENGAGEMENT || '_C'                          AS P1_H_1_11,
        NVL(C_ENR.CD_METHODO_BALE2,'STD')                    AS P1_1_1,
        NVL(C_ENR.CODE_TRAIT_MOTEUR,'01')                    AS P1_1_2,
        'Y'                                                  AS P1_4_34,
        C_ENR.CD_TYPE_RISQUE                                 AS P1_2_0,
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')               AS P1_2_4,
        C_ENR.CD_LIGNE_METIER                                AS P1_2_6,
        C_ENR.CD_PORTEFEUILLE_BALE2                          AS P1_2_18,
        NVL(C_ENR.CD_NATURE_OPE,'NA020')                     AS P1_2_29,
        C_ENR.DT_DEBUT_ENG                                   AS P1_3_2,
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,
        C_ENR.TX_LGD_PREDICTIF_LOCAL                         AS P1_18_1,
        C_ENR.TX_TRC                                         AS P1_18_10,
        CASE WHEN NVL(C_ENR.MNT_EAD_TOT,0) < 0 THEN 0 ELSE NVL(C_ENR.MNT_EAD_TOT,0) END AS P1_18_5,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_17,
        C_ENR.CD_DEVISE_MNT_RISQ                             AS P1_18_18,
        C_ENR.DT_RESTRUCTURATION                             AS P1_21_2
        -- >>> A COMPLETER ...
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%';

    COMMIT;
END P_ALIM_ENG_CORP_P1_BIS;
