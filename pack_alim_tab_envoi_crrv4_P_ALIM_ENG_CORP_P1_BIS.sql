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
-- IMPORTANT - ECART DE VERSION
-- ---------------------------------------------------------------------
-- Le spool implemente la notice V44.02 ; la notice du depot est V45.00.
-- Ecart mesure : 6154 - 5635 = 519 octets (50 champs crees en V45 = 434 o,
-- plus les modifications, ex. P1 21.65 : 5 -> 50).
-- => l'alignement automatique par POSITION spool(V44) vs notice(V45)
--    n'est PAS un oracle valable.
--
-- PERIMETRE DE CETTE VERSION (compilable) :
--   Seules les colonnes dont la cible est CONNUE sont alimentees :
--      - ancre '--P1 X.Y' ecrite dans le spool (source faisant foi) ;
--      - les 6 positions d'en-tete, identiques dans les 8 SELECT.
--   Les positions dont la colonne cible reste a determiner NE SONT PAS
--   inserees : elles restent a NULL dans la table. Leur inventaire complet
--   (INSERT, sequence, ligne du spool, expression deja convertie) est dans
--   docs/posicoes-a-mapear.md -> a completer avec la DSID.
--
--   ATTENTION : tant que ces positions ne sont pas mappees, le fichier
--   CRRCORP.dat regenere depuis la table NE PEUT PAS etre iso au fichier
--   actuel. Le test de non-regression n'est donc pas encore possible.
--
-- PREREQUIS : la table ENG_CORP_P1_BIS doit exister (ENG_CORP_P1_BIS.sql).
-- Les regles de gestion (CASE, NVL par defaut) sont CONSERVEES telles
-- quelles ; seul le formatage (RPAD/LPAD/TO_CHAR/F_FORMAT_*) est retire.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 1) A AJOUTER DANS LA SPEC DU PACKAGE  pack_alim_tab_envoi_crrv4
-- ---------------------------------------------------------------------
--   PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite IN VARCHAR2, p_masysdate IN VARCHAR2);


-- ---------------------------------------------------------------------
-- 2) CORPS DE LA PROCEDURE (a inserer dans le PACKAGE BODY)
-- ---------------------------------------------------------------------
PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite IN VARCHAR2, p_masysdate IN VARCHAR2)
IS
BEGIN
    ------------------------------------------------------------------
    -- Etape 1 : vider la table avant de la remplir (SFG SIRL-1224)
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ENG_CORP_P1_BIS';

    ------------------------------------------------------------------
    -- INSERT #1  (standard NAT02 - spool L590)
    --   colonnes : 63 (dont 57 ancrees --P1) | 178 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_2_18,
        P1_2_99,
        P1_4_31,
        P1_4_8,
        P1_21_3,
        P1_22_56,
        P1_22_5,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_23,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_60,
        P1_22_63,
        P1_23_1,
        P1_23_8,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_22,
        P1_21_23,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_43,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_71,
        P1_21_72,
        P1_21_73,
        P1_21_74,
        P1_21_75,
        P1_21_76,
        P1_21_77,
        P1_21_78,
        P1_21_80,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'NAT02'                                                    AS CD_PERIMETRE,
        C_ENR.dt_arrete                                            AS P1_H_0_1,  -- L590 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L591 [en-tete conv.]
        NVL(C_ENR.APPLI_SOURCE, 'C_BTR')                           AS P1_H_0_3,  -- L592 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L593 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L594 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L595 [en-tete conv.]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L612 [P1 2.18]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L677 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L685 [P1 4.31]
        NVL(C_ENR.TOP_ENG, 'B')                                    AS P1_4_8,  -- L695 [P1 4.8]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L715 [P1 21.3]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L736 [P1 22.56]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L743 [P1 22.5]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L753 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L754 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L761 [P1 22.9]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L775 [P1 22.23]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L793 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L803 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L804 [P1 22.45]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L813 [P1 22.60]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L817 [P1 22.63]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L828 [P1 23.1]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L837 [P1 23.8]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L904 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L909 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L917 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L935 [P1 29.4]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L984 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L985 [P1 21.23]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L987 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L988 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L989 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L990 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L991 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L992 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L1012 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L1013 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L1014 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L1015 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L1016 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L1017 [P1 21.40]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L1020 [P1 21.43]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L1031 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L1033 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L1034 [P1 21.55]
        CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END AS P1_21_69,  -- L1035 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L1038 [P1 8.13]
        C_ENR.COMMUNE                                              AS P1_21_71,  -- L1039 [P1 21.71]
        C_ENR.NUM_VOIE                                             AS P1_21_72,  -- L1040 [P1 21.72]
        C_ENR.EXTENSION                                            AS P1_21_73,  -- L1041 [P1 21.73]
        C_ENR.TYPE_VOIE                                            AS P1_21_74,  -- L1042 [P1 21.74]
        C_ENR.LIB_VOIE                                             AS P1_21_75,  -- L1043 [P1 21.75]
        C_ENR.LIEU_DIT                                             AS P1_21_76,  -- L1044 [P1 21.76]
        C_ENR.LATITUDE                                             AS P1_21_77,  -- L1045 [P1 21.77]
        C_ENR.LONGITUDE                                            AS P1_21_78,  -- L1046 [P1 21.78]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L1050 [P1 21.80]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L1051 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L1052 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L1056 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L1057 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L1058 [P1 21.88]
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
    --   colonnes : 46 (dont 40 ancrees --P1) | 188 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_4_3,
        P1_2_99,
        P1_4_31,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_34,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_63,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_22,
        P1_21_23,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_39,
        P1_21_43,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_80,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'NAT02'                                                    AS CD_PERIMETRE,
        C_ENR.dt_arrete                                            AS P1_H_0_1,  -- L1089 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L1090 [en-tete conv.]
        NVL(C_ENR.APPLI_SOURCE, 'C_BTR')                           AS P1_H_0_3,  -- L1091 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L1092 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L1093 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L1094 [en-tete conv.]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L1137 [P1 4.3]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1182 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1190 [P1 4.31]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1259 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1260 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1261 [P1 22.9]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L1291 [P1 22.34]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L1296 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1297 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1307 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1308 [P1 22.45]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1321 [P1 22.63]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L1411 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L1416 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1424 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L1442 [P1 29.4]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L1491 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L1492 [P1 21.23]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L1494 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L1495 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L1496 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L1497 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L1498 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L1499 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L1519 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L1520 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L1521 [P1 21.46]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L1523 [P1 21.39]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L1527 [P1 21.43]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L1538 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L1540 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L1541 [P1 21.55]
        CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END AS P1_21_69,  -- L1542 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L1545 [P1 8.13]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L1557 [P1 21.80]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L1558 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L1559 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L1563 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L1564 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L1565 [P1 21.88]
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
    --   colonnes : 56 (dont 50 ancrees --P1) | 179 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_2_99,
        P1_4_31,
        P1_4_8,
        P1_22_5,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_63,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_22,
        P1_21_23,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_43,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_71,
        P1_21_72,
        P1_21_73,
        P1_21_74,
        P1_21_75,
        P1_21_76,
        P1_21_77,
        P1_21_78,
        P1_21_80,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'NAT02'                                                    AS CD_PERIMETRE,
        C_ENR.dt_arrete                                            AS P1_H_0_1,  -- L1592 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L1593 [en-tete conv.]
        NVL(C_ENR.APPLI_SOURCE, 'C_BTR')                           AS P1_H_0_3,  -- L1594 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L1595 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L1596 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L1597 [en-tete conv.]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1683 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1691 [P1 4.31]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L1701 [P1 4.8]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L1749 [P1 22.5]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1760 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1761 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1762 [P1 22.9]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1804 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1805 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L1811 [P1 22.58]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1818 [P1 22.63]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L1905 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L1910 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1918 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L1936 [P1 29.4]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L1985 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L1986 [P1 21.23]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L1988 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L1989 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L1990 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L1991 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L1992 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L1993 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L2013 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L2014 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L2015 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L2016 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L2017 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L2018 [P1 21.40]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L2021 [P1 21.43]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L2032 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L2034 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L2035 [P1 21.55]
        CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END AS P1_21_69,  -- L2036 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L2039 [P1 8.13]
        C_ENR.COMMUNE                                              AS P1_21_71,  -- L2040 [P1 21.71]
        C_ENR.NUM_VOIE                                             AS P1_21_72,  -- L2041 [P1 21.72]
        C_ENR.EXTENSION                                            AS P1_21_73,  -- L2042 [P1 21.73]
        C_ENR.TYPE_VOIE                                            AS P1_21_74,  -- L2043 [P1 21.74]
        C_ENR.LIB_VOIE                                             AS P1_21_75,  -- L2044 [P1 21.75]
        C_ENR.LIEU_DIT                                             AS P1_21_76,  -- L2045 [P1 21.76]
        C_ENR.LATITUDE                                             AS P1_21_77,  -- L2046 [P1 21.77]
        C_ENR.LONGITUDE                                            AS P1_21_78,  -- L2047 [P1 21.78]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L2051 [P1 21.80]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L2052 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L2053 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L2057 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L2058 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L2059 [P1 21.88]
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
    --   colonnes : 33 (dont 27 ancrees --P1) | 382 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_5_5,
        P1_5_2,
        P1_4_2,
        P1_2_99,
        P1_22_8,
        P1_22_9,
        P1_22_44,
        P1_22_45,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_22,
        P1_21_23,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_46,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L2894 [en-tete conv.]
        TO_CHAR(C_ENR.CD_CONSO_CPT)                                AS P1_H_0_2,  -- L2895 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L2896 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L2897 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L2898 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L2899 [en-tete conv.]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L2938 [P1 5.5]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L2941 [P1 5.2]
        NVL((C_ENR.MNT_SOLDE), 0)                                  AS P1_4_2,  -- L2943 [P1 4.2]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3043 [P1 2.99]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3215 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3222 [P1 22.9]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L3239 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L3240 [P1 22.45]
        0                                                          AS P1_31_17,  -- L3327 [P1 31.17]
        0                                                          AS P1_31_18,  -- L3329 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3334 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L3346 [P1 29.4]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L3365 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L3366 [P1 21.23]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L3368 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L3369 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L3370 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L3371 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L3372 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L3373 [P1 21.31]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L3395 [P1 21.46]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L3414 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L3415 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L3419 [P1 8.13]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L3437 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L3438 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L3439 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('TRE100');

    ------------------------------------------------------------------
    -- INSERT #5  (Hors-NAT TRE2/TRE4/TRE5 - spool L3462)
    --   colonnes : 65 (dont 59 ancrees --P1) | 219 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_5_2,
        P1_5_3,
        P1_4_4,
        P1_4_9,
        P1_4_13,
        P1_4_7,
        P1_2_99,
        P1_4_31,
        P1_22_8,
        P1_22_9,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_22,
        P1_21_23,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_43,
        P1_21_57,
        P1_21_58,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_71,
        P1_21_72,
        P1_21_73,
        P1_21_74,
        P1_21_75,
        P1_21_76,
        P1_21_77,
        P1_21_78,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L3462 [en-tete conv.]
        TO_CHAR(C_ENR.CD_CONSO_CPT)                                AS P1_H_0_2,  -- L3464 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L3465 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L3466 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L3467 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L3468 [en-tete conv.]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L3519 [P1 5.2]
        (CASE WHEN C_ENR.TOP_ENG_DOUTEUX = 'Y' THEN C_ENR.DT_ENG_DOUTEUX ELSE NULL END) AS P1_5_3,  -- L3520 [P1 5.3]
        (CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' AND NVL(C_ENR.MNT_SOLDE, 0) >=0 THEN NVL((C_ENR.MNT_SOLDE), 0) ELSE NULL END ) AS P1_4_4,  -- L3534 [P1 4.4]
        NVL((C_ENR.MNT_CRD), 0)                                    AS P1_4_9,  -- L3550 [P1 4.9]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS P1_4_13,  -- L3552 [P1 4.13]
        ( CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL(C_ENR.CD_DEVISE_INT_RD, 'EUR') ELSE NULL END ) AS P1_4_7,  -- L3568 [P1 4.7]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3610 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L3621 [P1 4.31]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3698 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3699 [P1 22.9]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L3733 [P1 22.34]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L3735 [P1 22.35]
        '3'                                                        AS P1_22_36,  -- L3736 [P1 22.36]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L3746 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L3747 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L3753 [P1 22.58]
        C_ENR.DATE_FIN_PALL                                        AS P1_22_59,  -- L3754 [P1 22.59]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L3755 [P1 22.60]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L3757 [P1 22.61]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L3758 [P1 22.62]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L3759 [P1 22.63]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) AS P1_31_17,  -- L3846 [P1 31.17]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) AS P1_31_18,  -- L3848 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3853 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L3871 [P1 29.4]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L3926 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L3927 [P1 21.23]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L3929 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L3930 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L3931 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L3932 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L3933 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L3934 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L3954 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L3955 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L3956 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L3957 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L3958 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L3959 [P1 21.40]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L3962 [P1 21.43]
        C_ENR.IND_INVEST_CAPITAL_RISQ                              AS P1_21_57,  -- L3964 [P1 21.57]
        C_ENR.IND_INVEST_PROG_LEGISLATIF                           AS P1_21_58,  -- L3965 [P1 21.58]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L3973 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L3975 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L3976 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L3980 [P1 8.13]
        C_ENR.COMMUNE                                              AS P1_21_71,  -- L3981 [P1 21.71]
        C_ENR.NUM_VOIE                                             AS P1_21_72,  -- L3982 [P1 21.72]
        C_ENR.EXTENSION                                            AS P1_21_73,  -- L3983 [P1 21.73]
        C_ENR.TYPE_VOIE                                            AS P1_21_74,  -- L3984 [P1 21.74]
        C_ENR.LIB_VOIE                                             AS P1_21_75,  -- L3985 [P1 21.75]
        C_ENR.LIEU_DIT                                             AS P1_21_76,  -- L3986 [P1 21.76]
        C_ENR.LATITUDE                                             AS P1_21_77,  -- L3987 [P1 21.77]
        C_ENR.LONGITUDE                                            AS P1_21_78,  -- L3988 [P1 21.78]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L3993 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L3994 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L3998 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L3999 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L4000 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5');

    ------------------------------------------------------------------
    -- INSERT #6  (Hors-NAT EQU101 - spool L4026)
    --   colonnes : 34 (dont 28 ancrees --P1) | 405 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_5_5,
        P1_5_2,
        P1_2_99,
        P1_4_31,
        P1_22_8,
        P1_22_9,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_46,
        P1_21_57,
        P1_21_58,
        P1_21_59,
        P1_21_60,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_94,
        P1_21_79,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L4026 [en-tete conv.]
        TO_CHAR(C_ENR.CD_CONSO_CPT)                                AS P1_H_0_2,  -- L4027 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L4028 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L4029 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L4030 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L4031 [en-tete conv.]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4075 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L4077 [P1 5.2]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4171 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4234 [P1 4.31]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4353 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4354 [P1 22.9]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L4414 [P1 22.11]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L4416 [P1 26.3]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L4417 [P1 26.4]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L4420 [P1 27.3]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L4422 [P1 27.4]
        0                                                          AS P1_31_17,  -- L4454 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4456 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4461 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L4473 [P1 29.4]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L4539 [P1 21.46]
        C_ENR.IND_INVEST_CAPITAL_RISQ                              AS P1_21_57,  -- L4547 [P1 21.57]
        C_ENR.IND_INVEST_PROG_LEGISLATIF                           AS P1_21_58,  -- L4548 [P1 21.58]
        C_ENR.IND_PARTICIP_STRATG_SUP_6A                           AS P1_21_59,  -- L4549 [P1 21.59]
        C_ENR.TX_HIST_POND_PARTICIPATION                           AS P1_21_60,  -- L4550 [P1 21.60]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L4558 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L4559 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L4563 [P1 8.13]
        C_ENR.IND_HQLA                                             AS P1_21_94,  -- L4572 [P1 21.94]
        C_ENR.IND_TITRE_PARTICIP                                   AS P1_21_79,  -- L4574 [P1 21.79]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L4581 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L4582 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L4583 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('EQU101');

    ------------------------------------------------------------------
    -- INSERT #7  (Hors-NAT SIG201/INR101 - spool L4606)
    --   colonnes : 29 (dont 23 ancrees --P1) | 259 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_2_99,
        P1_4_31,
        P1_22_57,
        P1_22_8,
        P1_22_9,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L4606 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L4607 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L4608 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L4609 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L4610 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L4611 [en-tete conv.]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4652 [P1 5.5]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_4_1,  -- L4653 [P1 4.1]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L4654 [P1 5.2]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4733 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4757 [P1 4.31]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L4792 [P1 22.57]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4806 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4807 [P1 22.9]
        0                                                          AS P1_31_17,  -- L4898 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4900 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4906 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L4917 [P1 29.4]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L4995 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L4996 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L4997 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L4998 [P1 21.40]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L5012 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L5014 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L5015 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L5019 [P1 8.13]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L5037 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L5038 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L5039 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101');

    ------------------------------------------------------------------
    -- INSERT #8  (Hors-NAT VAR1 - spool L5061)
    --   colonnes : 41 (dont 35 ancrees --P1) | 318 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_5_5,
        P1_5_2,
        P1_2_99,
        P1_3_75,
        P1_4_42,
        P1_10_2,
        P1_8_1,
        P1_8_2,
        P1_8_11,
        P1_8_12,
        P1_22_56,
        P1_22_57,
        P1_22_8,
        P1_22_9,
        P1_22_16,
        P1_22_66,
        P1_22_72,
        P1_24_3,
        P1_24_20,
        P1_24_23,
        P1_24_24,
        P1_30_23,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_21_46,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_80,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L5061 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L5062 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L5063 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L5064 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L5065 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L5066 [en-tete conv.]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L5111 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L5114 [P1 5.2]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L5222 [P1 2.99]
        C_ENR.INSTRUMENT_FINANCIER                                 AS P1_3_75,  -- L5304 [P1 3.75]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L5305 [P1 4.42]
        C_ENR.IND_CALL_PUT                                         AS P1_10_2,  -- L5365 [P1 10.2]
        C_ENR.TYPE_TAUX_PAYE                                       AS P1_8_1,  -- L5366 [P1 8.1]
        C_ENR.REF_TAUX_PAYE                                        AS P1_8_2,  -- L5367 [P1 8.2]
        C_ENR.TYPE_TAUX_RECU                                       AS P1_8_11,  -- L5368 [P1 8.11]
        C_ENR.REF_TAUX_RECU                                        AS P1_8_12,  -- L5369 [P1 8.12]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L5380 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L5382 [P1 22.57]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L5396 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L5397 [P1 22.9]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L5402 [P1 22.16]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L5411 [P1 22.66]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L5416 [P1 22.72]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS P1_24_3,  -- L5441 [P1 24.3]
        C_ENR.IND_BCK_TO_BCK                                       AS P1_24_20,  -- L5444 [P1 24.20]
        C_ENR.INTENTION_COUVERTURE                                 AS P1_24_23,  -- L5446 [P1 24.23]
        C_ENR.TYPE_REL_COUVERTURE                                  AS P1_24_24,  -- L5447 [P1 24.24]
        'N'                                                        AS P1_30_23,  -- L5486 [P1 30.23]
        0                                                          AS P1_31_17,  -- L5506 [P1 31.17]
        0                                                          AS P1_31_18,  -- L5508 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L5514 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L5525 [P1 29.4]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L5574 [P1 21.46]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L5593 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L5594 [P1 21.55]
        'N'                                                        AS P1_21_69,  -- L5595 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L5598 [P1 8.13]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L5610 [P1 21.80]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L5616 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L5617 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L5618 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%';

    COMMIT;
END P_ALIM_ENG_CORP_P1_BIS;
