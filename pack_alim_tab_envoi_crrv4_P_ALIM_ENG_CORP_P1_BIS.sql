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
--    n'est PAS un oracle valable. Les colonnes sont donc nommees :
--      - d'apres l'ancre '--P1 X.Y' du spool quand elle existe ;
--      - sinon  COL_A_MAPPER_<insert>_<seq>  (a mapper avec la DSID) ;
--        le commentaire de fin de ligne donne la ligne du spool.
-- Les regles de gestion (CASE, NVL par defaut) sont CONSERVEES telles
-- quelles ; seul le formatage (RPAD/LPAD/TO_CHAR/F_FORMAT_*) est retire.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- IMPORTANT - ECART DE VERSION
-- ---------------------------------------------------------------------
-- Le spool implemente la notice V44.02 ; la notice du depot est V45.00.
-- Ecart mesure : 6154 - 5635 = 519 octets (50 champs crees en V45 = 434 o,
-- plus les modifications, ex. P1 21.65 : 5 -> 50).
-- => l'alignement automatique par POSITION spool(V44) vs notice(V45)
--    n'est PAS un oracle valable. Les colonnes sont donc nommees :
--      - d'apres l'ancre '--P1 X.Y' du spool quand elle existe ;
--      - sinon  COL_A_MAPPER_<insert>_<seq>  (a mapper avec la DSID) ;
--        le commentaire de fin de ligne donne la ligne du spool.
-- Les regles de gestion (CASE, NVL par defaut) sont CONSERVEES telles
-- quelles ; seul le formatage (RPAD/LPAD/TO_CHAR/F_FORMAT_*) est retire.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- IMPORTANT - ECART DE VERSION
-- ---------------------------------------------------------------------
-- Le spool implemente la notice V44.02 ; la notice du depot est V45.00.
-- Ecart mesure : 6154 - 5635 = 519 octets (50 champs crees en V45 = 434 o,
-- plus les modifications, ex. P1 21.65 : 5 -> 50).
-- => l'alignement automatique par POSITION spool(V44) vs notice(V45)
--    n'est PAS un oracle valable. Les colonnes sont donc nommees :
--      - d'apres l'ancre '--P1 X.Y' du spool quand elle existe ;
--      - sinon  COL_A_MAPPER_<insert>_<seq>  (a mapper avec la DSID) ;
--        le commentaire de fin de ligne donne la ligne du spool.
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
    --   colonnes : 204 (dont 57 ancrees --P1) | 178 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        COL_A_MAPPER_01_007,
        COL_A_MAPPER_01_008,
        COL_A_MAPPER_01_009,
        COL_A_MAPPER_01_010,
        COL_A_MAPPER_01_011,
        COL_A_MAPPER_01_012,
        COL_A_MAPPER_01_013,
        COL_A_MAPPER_01_014,
        COL_A_MAPPER_01_015,
        COL_A_MAPPER_01_016,
        P1_2_18,
        COL_A_MAPPER_01_018,
        COL_A_MAPPER_01_019,
        COL_A_MAPPER_01_020,
        COL_A_MAPPER_01_021,
        COL_A_MAPPER_01_022,
        COL_A_MAPPER_01_023,
        COL_A_MAPPER_01_024,
        COL_A_MAPPER_01_025,
        COL_A_MAPPER_01_026,
        COL_A_MAPPER_01_027,
        COL_A_MAPPER_01_028,
        COL_A_MAPPER_01_029,
        COL_A_MAPPER_01_030,
        COL_A_MAPPER_01_031,
        COL_A_MAPPER_01_032,
        COL_A_MAPPER_01_033,
        COL_A_MAPPER_01_034,
        COL_A_MAPPER_01_035,
        COL_A_MAPPER_01_036,
        COL_A_MAPPER_01_037,
        COL_A_MAPPER_01_038,
        COL_A_MAPPER_01_039,
        COL_A_MAPPER_01_040,
        COL_A_MAPPER_01_041,
        COL_A_MAPPER_01_042,
        COL_A_MAPPER_01_043,
        COL_A_MAPPER_01_044,
        COL_A_MAPPER_01_045,
        COL_A_MAPPER_01_046,
        COL_A_MAPPER_01_047,
        COL_A_MAPPER_01_048,
        COL_A_MAPPER_01_049,
        COL_A_MAPPER_01_050,
        COL_A_MAPPER_01_051,
        COL_A_MAPPER_01_052,
        COL_A_MAPPER_01_053,
        P1_2_99,
        P1_4_31,
        COL_A_MAPPER_01_056,
        P1_4_8,
        COL_A_MAPPER_01_058,
        COL_A_MAPPER_01_059,
        COL_A_MAPPER_01_060,
        COL_A_MAPPER_01_061,
        P1_21_3,
        COL_A_MAPPER_01_063,
        COL_A_MAPPER_01_064,
        COL_A_MAPPER_01_065,
        COL_A_MAPPER_01_066,
        COL_A_MAPPER_01_067,
        COL_A_MAPPER_01_068,
        COL_A_MAPPER_01_069,
        COL_A_MAPPER_01_070,
        COL_A_MAPPER_01_071,
        COL_A_MAPPER_01_072,
        COL_A_MAPPER_01_073,
        COL_A_MAPPER_01_074,
        COL_A_MAPPER_01_075,
        P1_22_56,
        COL_A_MAPPER_01_077,
        COL_A_MAPPER_01_078,
        COL_A_MAPPER_01_079,
        P1_22_5,
        COL_A_MAPPER_01_081,
        COL_A_MAPPER_01_082,
        COL_A_MAPPER_01_083,
        COL_A_MAPPER_01_084,
        COL_A_MAPPER_01_085,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_01_089,
        COL_A_MAPPER_01_090,
        COL_A_MAPPER_01_091,
        COL_A_MAPPER_01_092,
        COL_A_MAPPER_01_093,
        COL_A_MAPPER_01_094,
        COL_A_MAPPER_01_095,
        COL_A_MAPPER_01_096,
        COL_A_MAPPER_01_097,
        COL_A_MAPPER_01_098,
        COL_A_MAPPER_01_099,
        P1_22_23,
        COL_A_MAPPER_01_101,
        COL_A_MAPPER_01_102,
        COL_A_MAPPER_01_103,
        COL_A_MAPPER_01_104,
        COL_A_MAPPER_01_105,
        COL_A_MAPPER_01_106,
        COL_A_MAPPER_01_107,
        COL_A_MAPPER_01_108,
        COL_A_MAPPER_01_109,
        COL_A_MAPPER_01_110,
        COL_A_MAPPER_01_111,
        COL_A_MAPPER_01_112,
        COL_A_MAPPER_01_113,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        COL_A_MAPPER_01_118,
        COL_A_MAPPER_01_119,
        P1_22_60,
        COL_A_MAPPER_01_121,
        COL_A_MAPPER_01_122,
        P1_22_63,
        COL_A_MAPPER_01_124,
        COL_A_MAPPER_01_125,
        COL_A_MAPPER_01_126,
        COL_A_MAPPER_01_127,
        COL_A_MAPPER_01_128,
        P1_23_1,
        COL_A_MAPPER_01_130,
        COL_A_MAPPER_01_131,
        COL_A_MAPPER_01_132,
        COL_A_MAPPER_01_133,
        COL_A_MAPPER_01_134,
        COL_A_MAPPER_01_135,
        P1_23_8,
        COL_A_MAPPER_01_137,
        COL_A_MAPPER_01_138,
        COL_A_MAPPER_01_139,
        COL_A_MAPPER_01_140,
        COL_A_MAPPER_01_141,
        COL_A_MAPPER_01_142,
        COL_A_MAPPER_01_143,
        COL_A_MAPPER_01_144,
        COL_A_MAPPER_01_145,
        COL_A_MAPPER_01_146,
        COL_A_MAPPER_01_147,
        COL_A_MAPPER_01_148,
        COL_A_MAPPER_01_149,
        COL_A_MAPPER_01_150,
        COL_A_MAPPER_01_151,
        COL_A_MAPPER_01_152,
        COL_A_MAPPER_01_153,
        COL_A_MAPPER_01_154,
        COL_A_MAPPER_01_155,
        COL_A_MAPPER_01_156,
        COL_A_MAPPER_01_157,
        COL_A_MAPPER_01_158,
        P1_31_17,
        P1_31_18,
        COL_A_MAPPER_01_161,
        P1_31_22,
        COL_A_MAPPER_01_163,
        COL_A_MAPPER_01_164,
        P1_29_4,
        COL_A_MAPPER_01_166,
        COL_A_MAPPER_01_167,
        COL_A_MAPPER_01_168,
        COL_A_MAPPER_01_169,
        COL_A_MAPPER_01_170,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_01_007,  -- L597 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_01_008,  -- L600 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_01_009,  -- L601 [a mapper]
        C_ENR.ID_ENGAGEMENT || '_C'                                AS COL_A_MAPPER_01_010,  -- L603 [a mapper]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS COL_A_MAPPER_01_011,  -- L606 [a mapper]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS COL_A_MAPPER_01_012,  -- L607 [a mapper]
        'Y'                                                        AS COL_A_MAPPER_01_013,  -- L608 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_01_014,  -- L609 [a mapper]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS COL_A_MAPPER_01_015,  -- L610 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_01_016,  -- L611 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L612 [P1 2.18]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS COL_A_MAPPER_01_018,  -- L613 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_01_019,  -- L614 [a mapper]
        NVL(C_ENR.DT_FIN_ENG, '99990630')                          AS COL_A_MAPPER_01_020,  -- L615 [a mapper]
        C_ENR.TX_LGD_PREDICTIF_LOCAL                               AS COL_A_MAPPER_01_021,  -- L617 [a mapper]
        C_ENR.TX_TRC                                               AS COL_A_MAPPER_01_022,  -- L618 [a mapper]
        CASE WHEN NVL((C_ENR.MNT_EAD_TOT), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_EAD_TOT), 0)END AS COL_A_MAPPER_01_023,  -- L619 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_01_024,  -- L622 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_01_025,  -- L623 [a mapper]
        C_ENR.DT_RESTRUCTURATION                                   AS COL_A_MAPPER_01_026,  -- L628 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS COL_A_MAPPER_01_027,  -- L629 [a mapper]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS COL_A_MAPPER_01_028,  -- L631 [a mapper]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS COL_A_MAPPER_01_029,  -- L632 [a mapper]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS COL_A_MAPPER_01_030,  -- L633 [a mapper]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS COL_A_MAPPER_01_031,  -- L636 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE201' THEN 0|| NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, 'EUR') ELSE NULL END AS COL_A_MAPPER_01_032,  -- L637 [a mapper]
        NVL((C_ENR.MNT_RISQUE), 0)                                 AS COL_A_MAPPER_01_033,  -- L641 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_01_034,  -- L643 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE401' THEN NULL ELSE NVL(C_ENR.MNT_LOYER, 0) || NVL(C_ENR.CD_DEVISE_CRD, 'EUR') END AS COL_A_MAPPER_01_035,  -- L644 [a mapper]
        C_ENR.PCCO_MNT_CRD                                         AS COL_A_MAPPER_01_036,  -- L649 [a mapper]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN CASE WHEN NVL((C_ENR.MNT_SOLD_K_A), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_SOLD_K_A), 0)END ELSE NULL END AS COL_A_MAPPER_01_037,  -- L650 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_01_038,  -- L651 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_01_039,  -- L652 [a mapper]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE NVL((C_ENR.MNT_VTR), 0) END AS COL_A_MAPPER_01_040,  -- L654 [a mapper]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS COL_A_MAPPER_01_041,  -- L655 [a mapper]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS COL_A_MAPPER_01_042,  -- L656 [a mapper]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS COL_A_MAPPER_01_043,  -- L658 [a mapper]
        C_ENR.CD_RESPECT_COND                                      AS COL_A_MAPPER_01_044,  -- L659 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_VTR), 0) else NULL END AS COL_A_MAPPER_01_045,  -- L660 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_VTR else NULL END AS COL_A_MAPPER_01_046,  -- L662 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_HYPOTHEQUE), 0) else NULL END AS COL_A_MAPPER_01_047,  -- L663 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_HYPOTH else NULL END AS COL_A_MAPPER_01_048,  -- L664 [a mapper]
        C_ENR.CD_LOC_BIEN                                          AS COL_A_MAPPER_01_049,  -- L665 [a mapper]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS COL_A_MAPPER_01_050,  -- L666 [a mapper]
        Case when NVL(C_ENR.MNT_VR, 0) >= 0 then NVL((C_ENR.MNT_VR), 0) else 0 END AS COL_A_MAPPER_01_051,  -- L669 [a mapper]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS COL_A_MAPPER_01_052,  -- L671 [a mapper]
        C_ENR.cla_comp_ref_act                                     AS COL_A_MAPPER_01_053,  -- L672 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L677 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L685 [P1 4.31]
        Substr(NVL(C_ENR.MATURITE_EFF, 0) ,4,6)                    AS COL_A_MAPPER_01_056,  -- L693 [a mapper]
        NVL(C_ENR.TOP_ENG, 'B')                                    AS P1_4_8,  -- L695 [P1 4.8]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_01_058,  -- L697 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_01_059,  -- L698 [a mapper]
        C_ENR.DT_DISPO_FONDS                                       AS COL_A_MAPPER_01_060,  -- L700 [a mapper]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS COL_A_MAPPER_01_061,  -- L705 [a mapper]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L715 [P1 21.3]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS COL_A_MAPPER_01_063,  -- L716 [a mapper]
        C_ENR.STA_CRDT                                             AS COL_A_MAPPER_01_064,  -- L717 [a mapper]
        C_ENR.IND_CRE_PERF                                         AS COL_A_MAPPER_01_065,  -- L718 [a mapper]
        C_ENR.DATE_PREM_ACT_FORB                                   AS COL_A_MAPPER_01_066,  -- L719 [a mapper]
        C_ENR.DATE_DER_REST_COMM                                   AS COL_A_MAPPER_01_067,  -- L720 [a mapper]
        C_ENR.DATE_DER_REST_RSQ                                    AS COL_A_MAPPER_01_068,  -- L721 [a mapper]
        C_ENR.DATE_ENTR_PER_PURG                                   AS COL_A_MAPPER_01_069,  -- L722 [a mapper]
        C_ENR.DATE_SORT_PER_PURG                                   AS COL_A_MAPPER_01_070,  -- L723 [a mapper]
        C_ENR.DATE_ENTR_PER_PROB                                   AS COL_A_MAPPER_01_071,  -- L724 [a mapper]
        C_ENR.DATE_SORT_PER_PROB                                   AS COL_A_MAPPER_01_072,  -- L725 [a mapper]
        C_ENR.DATE_THEO_FIN_FORB                                   AS COL_A_MAPPER_01_073,  -- L726 [a mapper]
        C_ENR.DATE_SORT_EFF_FORB                                   AS COL_A_MAPPER_01_074,  -- L727 [a mapper]
        C_ENR.DT_PL_NPL                                            AS COL_A_MAPPER_01_075,  -- L728 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L736 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS COL_A_MAPPER_01_077,  -- L739 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_01_078,  -- L740 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_01_079,  -- L741 [a mapper]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L743 [P1 22.5]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_01_081,  -- L744 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_01_082,  -- L745 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_01_083,  -- L747 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_01_084,  -- L748 [a mapper]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS COL_A_MAPPER_01_085,  -- L751 [a mapper]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L753 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L754 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L761 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_01_089,  -- L762 [a mapper]
        C_ENR.TAUX_INT_EFF_ORI                                     AS COL_A_MAPPER_01_090,  -- L765 [a mapper]
        C_ENR.TYPE_TAUX                                            AS COL_A_MAPPER_01_091,  -- L766 [a mapper]
        C_ENR.IND_REF                                              AS COL_A_MAPPER_01_092,  -- L767 [a mapper]
        C_ENR.TYPE_AMOR_CAP                                        AS COL_A_MAPPER_01_093,  -- L768 [a mapper]
        C_ENR.PRD_AMOR_CAP                                         AS COL_A_MAPPER_01_094,  -- L769 [a mapper]
        C_ENR.PRD_PMT_INT                                          AS COL_A_MAPPER_01_095,  -- L770 [a mapper]
        C_ENR.TAUX_CLT_OCT                                         AS COL_A_MAPPER_01_096,  -- L771 [a mapper]
        C_ENR.MOD_REMB_CRE                                         AS COL_A_MAPPER_01_097,  -- L772 [a mapper]
        C_ENR.DATE_PREM_ECH                                        AS COL_A_MAPPER_01_098,  -- L773 [a mapper]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS COL_A_MAPPER_01_099,  -- L774 [a mapper]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L775 [P1 22.23]
        C_ENR.TAUX_PLANCHER                                        AS COL_A_MAPPER_01_101,  -- L776 [a mapper]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS COL_A_MAPPER_01_102,  -- L777 [a mapper]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS COL_A_MAPPER_01_103,  -- L778 [a mapper]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS COL_A_MAPPER_01_104,  -- L779 [a mapper]
        C_ENR.TAUX_MRG_ADD                                         AS COL_A_MAPPER_01_105,  -- L780 [a mapper]
        C_ENR.TAUX_MRG_MULT                                        AS COL_A_MAPPER_01_106,  -- L781 [a mapper]
        C_ENR.BASE_CAL_INT                                         AS COL_A_MAPPER_01_107,  -- L782 [a mapper]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS COL_A_MAPPER_01_108,  -- L783 [a mapper]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS COL_A_MAPPER_01_109,  -- L785 [a mapper]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS COL_A_MAPPER_01_110,  -- L787 [a mapper]
        CASE WHEN C_ENR.CAP_THEO_REST<0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS COL_A_MAPPER_01_111,  -- L789 [a mapper]
        C_ENR.DEVI_CAP_THEO_REST                                   AS COL_A_MAPPER_01_112,  -- L791 [a mapper]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_01_113,  -- L792 [a mapper]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L793 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L803 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L804 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS COL_A_MAPPER_01_118,  -- L810 [a mapper]
        C_ENR.DATE_FIN_PALL                                        AS COL_A_MAPPER_01_119,  -- L812 [a mapper]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L813 [P1 22.60]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS COL_A_MAPPER_01_121,  -- L815 [a mapper]
        C_ENR.IND_PRE_POST_FIX                                     AS COL_A_MAPPER_01_122,  -- L816 [a mapper]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L817 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS COL_A_MAPPER_01_124,  -- L821 [a mapper]
        C_ENR.DT_SIGNATURE                                         AS COL_A_MAPPER_01_125,  -- L822 [a mapper]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS COL_A_MAPPER_01_126,  -- L824 [a mapper]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_01_127,  -- L825 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_01_128,  -- L826 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L828 [P1 23.1]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_01_130,  -- L830 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_01_131,  -- L831 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS COL_A_MAPPER_01_132,  -- L832 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS COL_A_MAPPER_01_133,  -- L833 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_01_134,  -- L834 [a mapper]
        C_ENR.PCCO_MNT_CRD || C_ENR.ZONE_APP_COMP                  AS COL_A_MAPPER_01_135,  -- L835 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L837 [P1 23.8]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_01_137,  -- L838 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_01_138,  -- L839 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_01_139,  -- L840 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_01_140,  -- L842 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_01_141,  -- L848 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_01_142,  -- L851 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_01_143,  -- L853 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_01_144,  -- L854 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_01_145,  -- L858 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_01_146,  -- L860 [a mapper]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS COL_A_MAPPER_01_147,  -- L863 [a mapper]
        C_ENR.MNT_IDEMNITE_RES                                     AS COL_A_MAPPER_01_148,  -- L868 [a mapper]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS COL_A_MAPPER_01_149,  -- L870 [a mapper]
        'N'                                                        AS COL_A_MAPPER_01_150,  -- L878 [a mapper]
        'N'                                                        AS COL_A_MAPPER_01_151,  -- L883 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_01_152,  -- L887 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_01_153,  -- L888 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_01_154,  -- L889 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_01_155,  -- L890 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_01_156,  -- L891 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_01_157,  -- L894 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_01_158,  -- L895 [a mapper]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') else '00000' end AS P1_31_17,  -- L904 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') else '00000' end AS P1_31_18,  -- L909 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS COL_A_MAPPER_01_161,  -- L916 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L917 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_01_163,  -- L931 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_01_164,  -- L934 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L935 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_01_166,  -- L971 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_01_167,  -- L972 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_01_168,  -- L973 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_01_169,  -- L976 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_01_170,  -- L977 [a mapper]
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
    --   colonnes : 195 (dont 40 ancrees --P1) | 188 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        COL_A_MAPPER_02_007,
        COL_A_MAPPER_02_008,
        COL_A_MAPPER_02_009,
        COL_A_MAPPER_02_010,
        COL_A_MAPPER_02_011,
        COL_A_MAPPER_02_012,
        COL_A_MAPPER_02_013,
        COL_A_MAPPER_02_014,
        COL_A_MAPPER_02_015,
        COL_A_MAPPER_02_016,
        COL_A_MAPPER_02_017,
        COL_A_MAPPER_02_018,
        COL_A_MAPPER_02_019,
        COL_A_MAPPER_02_020,
        COL_A_MAPPER_02_021,
        COL_A_MAPPER_02_022,
        COL_A_MAPPER_02_023,
        COL_A_MAPPER_02_024,
        COL_A_MAPPER_02_025,
        COL_A_MAPPER_02_026,
        COL_A_MAPPER_02_027,
        COL_A_MAPPER_02_028,
        COL_A_MAPPER_02_029,
        COL_A_MAPPER_02_030,
        P1_4_3,
        COL_A_MAPPER_02_032,
        COL_A_MAPPER_02_033,
        COL_A_MAPPER_02_034,
        COL_A_MAPPER_02_035,
        COL_A_MAPPER_02_036,
        COL_A_MAPPER_02_037,
        COL_A_MAPPER_02_038,
        COL_A_MAPPER_02_039,
        COL_A_MAPPER_02_040,
        COL_A_MAPPER_02_041,
        COL_A_MAPPER_02_042,
        COL_A_MAPPER_02_043,
        COL_A_MAPPER_02_044,
        COL_A_MAPPER_02_045,
        COL_A_MAPPER_02_046,
        COL_A_MAPPER_02_047,
        COL_A_MAPPER_02_048,
        COL_A_MAPPER_02_049,
        COL_A_MAPPER_02_050,
        COL_A_MAPPER_02_051,
        COL_A_MAPPER_02_052,
        COL_A_MAPPER_02_053,
        COL_A_MAPPER_02_054,
        P1_2_99,
        P1_4_31,
        COL_A_MAPPER_02_057,
        COL_A_MAPPER_02_058,
        COL_A_MAPPER_02_059,
        COL_A_MAPPER_02_060,
        COL_A_MAPPER_02_061,
        COL_A_MAPPER_02_062,
        COL_A_MAPPER_02_063,
        COL_A_MAPPER_02_064,
        COL_A_MAPPER_02_065,
        COL_A_MAPPER_02_066,
        COL_A_MAPPER_02_067,
        COL_A_MAPPER_02_068,
        COL_A_MAPPER_02_069,
        COL_A_MAPPER_02_070,
        COL_A_MAPPER_02_071,
        COL_A_MAPPER_02_072,
        COL_A_MAPPER_02_073,
        COL_A_MAPPER_02_074,
        COL_A_MAPPER_02_075,
        COL_A_MAPPER_02_076,
        COL_A_MAPPER_02_077,
        COL_A_MAPPER_02_078,
        COL_A_MAPPER_02_079,
        COL_A_MAPPER_02_080,
        COL_A_MAPPER_02_081,
        COL_A_MAPPER_02_082,
        COL_A_MAPPER_02_083,
        COL_A_MAPPER_02_084,
        COL_A_MAPPER_02_085,
        COL_A_MAPPER_02_086,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_02_090,
        COL_A_MAPPER_02_091,
        COL_A_MAPPER_02_092,
        COL_A_MAPPER_02_093,
        COL_A_MAPPER_02_094,
        COL_A_MAPPER_02_095,
        COL_A_MAPPER_02_096,
        COL_A_MAPPER_02_097,
        COL_A_MAPPER_02_098,
        COL_A_MAPPER_02_099,
        COL_A_MAPPER_02_100,
        COL_A_MAPPER_02_101,
        COL_A_MAPPER_02_102,
        COL_A_MAPPER_02_103,
        COL_A_MAPPER_02_104,
        COL_A_MAPPER_02_105,
        COL_A_MAPPER_02_106,
        COL_A_MAPPER_02_107,
        COL_A_MAPPER_02_108,
        COL_A_MAPPER_02_109,
        COL_A_MAPPER_02_110,
        COL_A_MAPPER_02_111,
        P1_22_34,
        COL_A_MAPPER_02_113,
        COL_A_MAPPER_02_114,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        COL_A_MAPPER_02_119,
        COL_A_MAPPER_02_120,
        COL_A_MAPPER_02_121,
        COL_A_MAPPER_02_122,
        COL_A_MAPPER_02_123,
        P1_22_63,
        COL_A_MAPPER_02_125,
        COL_A_MAPPER_02_126,
        COL_A_MAPPER_02_127,
        COL_A_MAPPER_02_128,
        COL_A_MAPPER_02_129,
        COL_A_MAPPER_02_130,
        COL_A_MAPPER_02_131,
        COL_A_MAPPER_02_132,
        COL_A_MAPPER_02_133,
        COL_A_MAPPER_02_134,
        COL_A_MAPPER_02_135,
        COL_A_MAPPER_02_136,
        COL_A_MAPPER_02_137,
        COL_A_MAPPER_02_138,
        COL_A_MAPPER_02_139,
        COL_A_MAPPER_02_140,
        COL_A_MAPPER_02_141,
        COL_A_MAPPER_02_142,
        COL_A_MAPPER_02_143,
        COL_A_MAPPER_02_144,
        COL_A_MAPPER_02_145,
        COL_A_MAPPER_02_146,
        COL_A_MAPPER_02_147,
        COL_A_MAPPER_02_148,
        COL_A_MAPPER_02_149,
        COL_A_MAPPER_02_150,
        COL_A_MAPPER_02_151,
        COL_A_MAPPER_02_152,
        COL_A_MAPPER_02_153,
        COL_A_MAPPER_02_154,
        COL_A_MAPPER_02_155,
        COL_A_MAPPER_02_156,
        COL_A_MAPPER_02_157,
        COL_A_MAPPER_02_158,
        COL_A_MAPPER_02_159,
        P1_31_17,
        P1_31_18,
        COL_A_MAPPER_02_162,
        P1_31_22,
        COL_A_MAPPER_02_164,
        COL_A_MAPPER_02_165,
        P1_29_4,
        COL_A_MAPPER_02_167,
        COL_A_MAPPER_02_168,
        COL_A_MAPPER_02_169,
        COL_A_MAPPER_02_170,
        COL_A_MAPPER_02_171,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_02_007,  -- L1096 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_02_008,  -- L1099 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_02_009,  -- L1100 [a mapper]
        C_ENR.ID_ENGAGEMENT || '_S'                                AS COL_A_MAPPER_02_010,  -- L1102 [a mapper]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS COL_A_MAPPER_02_011,  -- L1105 [a mapper]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS COL_A_MAPPER_02_012,  -- L1106 [a mapper]
        'Y'                                                        AS COL_A_MAPPER_02_013,  -- L1107 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_02_014,  -- L1108 [a mapper]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS COL_A_MAPPER_02_015,  -- L1109 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_02_016,  -- L1110 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_02_017,  -- L1111 [a mapper]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS COL_A_MAPPER_02_018,  -- L1112 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_02_019,  -- L1113 [a mapper]
        NVL(add_months(C_ENR.DT_ARRETE,12), '99990630')            AS COL_A_MAPPER_02_020,  -- L1114 [a mapper]
        C_ENR.TX_LGD_PREDICTIF_LOCAL                               AS COL_A_MAPPER_02_021,  -- L1117 [a mapper]
        C_ENR.TX_TRC                                               AS COL_A_MAPPER_02_022,  -- L1118 [a mapper]
        CASE WHEN NVL((C_ENR.MNT_EAD_TOT), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_EAD_TOT), 0)END AS COL_A_MAPPER_02_023,  -- L1119 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_02_024,  -- L1122 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_02_025,  -- L1123 [a mapper]
        C_ENR.DT_RESTRUCTURATION                                   AS COL_A_MAPPER_02_026,  -- L1129 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS COL_A_MAPPER_02_027,  -- L1130 [a mapper]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS COL_A_MAPPER_02_028,  -- L1132 [a mapper]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS COL_A_MAPPER_02_029,  -- L1133 [a mapper]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS COL_A_MAPPER_02_030,  -- L1134 [a mapper]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L1137 [P1 4.3]
        CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE201' THEN 0|| NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, 'EUR') ELSE NULL END AS COL_A_MAPPER_02_032,  -- L1139 [a mapper]
        0                                                          AS COL_A_MAPPER_02_033,  -- L1143 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_02_034,  -- L1145 [a mapper]
        NVL(C_ENR.MNT_SOLD_K_A, 0)                                 AS COL_A_MAPPER_02_035,  -- L1146 [a mapper]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS COL_A_MAPPER_02_036,  -- L1147 [a mapper]
        C_ENR.PCCO_MNT_SOLDE                                       AS COL_A_MAPPER_02_037,  -- L1150 [a mapper]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN CASE WHEN NVL((C_ENR.MNT_SOLD_K_A), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_SOLD_K_A), 0)END ELSE NULL END AS COL_A_MAPPER_02_038,  -- L1151 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_02_039,  -- L1152 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_02_040,  -- L1153 [a mapper]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE NVL((C_ENR.MNT_VTR), 0) END AS COL_A_MAPPER_02_041,  -- L1155 [a mapper]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS COL_A_MAPPER_02_042,  -- L1157 [a mapper]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS COL_A_MAPPER_02_043,  -- L1158 [a mapper]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS COL_A_MAPPER_02_044,  -- L1160 [a mapper]
        C_ENR.CD_RESPECT_COND                                      AS COL_A_MAPPER_02_045,  -- L1162 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then 0 else NULL END AS COL_A_MAPPER_02_046,  -- L1163 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then C_ENR.CD_DEV_VTR else NULL END AS COL_A_MAPPER_02_047,  -- L1165 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then 0 else NULL END AS COL_A_MAPPER_02_048,  -- L1166 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then C_ENR.CD_DEV_HYPOTH else NULL END AS COL_A_MAPPER_02_049,  -- L1167 [a mapper]
        C_ENR.CD_LOC_BIEN                                          AS COL_A_MAPPER_02_050,  -- L1168 [a mapper]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS COL_A_MAPPER_02_051,  -- L1171 [a mapper]
        Case when NVL(C_ENR.MNT_VR, 0) >= 0 then NVL((C_ENR.MNT_VR), 0) else 0 END AS COL_A_MAPPER_02_052,  -- L1174 [a mapper]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS COL_A_MAPPER_02_053,  -- L1176 [a mapper]
        C_ENR.cla_comp_ref_act_s                                   AS COL_A_MAPPER_02_054,  -- L1177 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1182 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1190 [P1 4.31]
        Substr(1 ,4,6)                                             AS COL_A_MAPPER_02_057,  -- L1198 [a mapper]
        C_ENR.TOP_ENG                                              AS COL_A_MAPPER_02_058,  -- L1201 [a mapper]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_02_059,  -- L1203 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_02_060,  -- L1204 [a mapper]
        C_ENR.DT_DISPO_FONDS                                       AS COL_A_MAPPER_02_061,  -- L1206 [a mapper]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS COL_A_MAPPER_02_062,  -- L1211 [a mapper]
        C_ENR.EVENMT_CRDT                                          AS COL_A_MAPPER_02_063,  -- L1221 [a mapper]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS COL_A_MAPPER_02_064,  -- L1222 [a mapper]
        C_ENR.STA_CRDT                                             AS COL_A_MAPPER_02_065,  -- L1223 [a mapper]
        C_ENR.IND_CRE_PERF                                         AS COL_A_MAPPER_02_066,  -- L1224 [a mapper]
        C_ENR.DATE_PREM_ACT_FORB                                   AS COL_A_MAPPER_02_067,  -- L1225 [a mapper]
        C_ENR.DATE_DER_REST_COMM                                   AS COL_A_MAPPER_02_068,  -- L1226 [a mapper]
        C_ENR.DATE_DER_REST_RSQ                                    AS COL_A_MAPPER_02_069,  -- L1227 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS COL_A_MAPPER_02_070,  -- L1228 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS COL_A_MAPPER_02_071,  -- L1229 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS COL_A_MAPPER_02_072,  -- L1230 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS COL_A_MAPPER_02_073,  -- L1231 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS COL_A_MAPPER_02_074,  -- L1232 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS COL_A_MAPPER_02_075,  -- L1233 [a mapper]
        C_ENR.DT_PL_NPL                                            AS COL_A_MAPPER_02_076,  -- L1234 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS COL_A_MAPPER_02_077,  -- L1242 [a mapper]
        C_ENR.IND_OBJ_MET_PAL                                      AS COL_A_MAPPER_02_078,  -- L1245 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_02_079,  -- L1246 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_02_080,  -- L1247 [a mapper]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS COL_A_MAPPER_02_081,  -- L1249 [a mapper]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_02_082,  -- L1250 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_02_083,  -- L1251 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_02_084,  -- L1253 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_02_085,  -- L1254 [a mapper]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS COL_A_MAPPER_02_086,  -- L1256 [a mapper]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1259 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1260 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1261 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_02_090,  -- L1262 [a mapper]
        C_ENR.TAUX_INT_EFF_ORI                                     AS COL_A_MAPPER_02_091,  -- L1265 [a mapper]
        C_ENR.TYPE_TAUX                                            AS COL_A_MAPPER_02_092,  -- L1266 [a mapper]
        C_ENR.IND_REF                                              AS COL_A_MAPPER_02_093,  -- L1267 [a mapper]
        'F'                                                        AS COL_A_MAPPER_02_094,  -- L1268 [a mapper]
        C_ENR.PRD_AMOR_CAP                                         AS COL_A_MAPPER_02_095,  -- L1270 [a mapper]
        C_ENR.PRD_PMT_INT                                          AS COL_A_MAPPER_02_096,  -- L1271 [a mapper]
        C_ENR.TAUX_CLT_OCT                                         AS COL_A_MAPPER_02_097,  -- L1272 [a mapper]
        C_ENR.MOD_REMB_CRE                                         AS COL_A_MAPPER_02_098,  -- L1273 [a mapper]
        C_ENR.DATE_PREM_ECH                                        AS COL_A_MAPPER_02_099,  -- L1274 [a mapper]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS COL_A_MAPPER_02_100,  -- L1275 [a mapper]
        C_ENR.TAUX_PLAFOND                                         AS COL_A_MAPPER_02_101,  -- L1276 [a mapper]
        C_ENR.TAUX_PLANCHER                                        AS COL_A_MAPPER_02_102,  -- L1277 [a mapper]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS COL_A_MAPPER_02_103,  -- L1278 [a mapper]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS COL_A_MAPPER_02_104,  -- L1279 [a mapper]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS COL_A_MAPPER_02_105,  -- L1280 [a mapper]
        C_ENR.TAUX_MRG_ADD                                         AS COL_A_MAPPER_02_106,  -- L1281 [a mapper]
        C_ENR.TAUX_MRG_MULT                                        AS COL_A_MAPPER_02_107,  -- L1282 [a mapper]
        C_ENR.BASE_CAL_INT                                         AS COL_A_MAPPER_02_108,  -- L1283 [a mapper]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS COL_A_MAPPER_02_109,  -- L1284 [a mapper]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS COL_A_MAPPER_02_110,  -- L1286 [a mapper]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS COL_A_MAPPER_02_111,  -- L1289 [a mapper]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L1291 [P1 22.34]
        C_ENR.DEVI_CAP_THEO_REST                                   AS COL_A_MAPPER_02_113,  -- L1293 [a mapper]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_02_114,  -- L1295 [a mapper]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L1296 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1297 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1307 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1308 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS COL_A_MAPPER_02_119,  -- L1314 [a mapper]
        add_months(C_ENR.DT_ARRETE,12)                             AS COL_A_MAPPER_02_120,  -- L1316 [a mapper]
        C_ENR.MNT_ECH_EN_COURS                                     AS COL_A_MAPPER_02_121,  -- L1317 [a mapper]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS COL_A_MAPPER_02_122,  -- L1319 [a mapper]
        C_ENR.IND_PRE_POST_FIX                                     AS COL_A_MAPPER_02_123,  -- L1320 [a mapper]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1321 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS COL_A_MAPPER_02_125,  -- L1325 [a mapper]
        C_ENR.DT_SIGNATURE                                         AS COL_A_MAPPER_02_126,  -- L1326 [a mapper]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS COL_A_MAPPER_02_127,  -- L1328 [a mapper]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_02_128,  -- L1329 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_02_129,  -- L1330 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV_S                                   AS COL_A_MAPPER_02_130,  -- L1332 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_02_131,  -- L1334 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_02_132,  -- L1335 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9_S                                 AS COL_A_MAPPER_02_133,  -- L1336 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE_S                             AS COL_A_MAPPER_02_134,  -- L1337 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_02_135,  -- L1338 [a mapper]
        C_ENR.PCCO_MNT_SOLDE || C_ENR.ZONE_APP_COMP                AS COL_A_MAPPER_02_136,  -- L1339 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_02_137,  -- L1341 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_02_138,  -- L1342 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_02_139,  -- L1343 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_02_140,  -- L1344 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_02_141,  -- L1346 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_02_142,  -- L1352 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_02_143,  -- L1355 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_02_144,  -- L1357 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_02_145,  -- L1358 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_02_146,  -- L1364 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_02_147,  -- L1366 [a mapper]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS COL_A_MAPPER_02_148,  -- L1369 [a mapper]
        C_ENR.MNT_IDEMNITE_RES                                     AS COL_A_MAPPER_02_149,  -- L1374 [a mapper]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS COL_A_MAPPER_02_150,  -- L1376 [a mapper]
        'N'                                                        AS COL_A_MAPPER_02_151,  -- L1385 [a mapper]
        'N'                                                        AS COL_A_MAPPER_02_152,  -- L1390 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_02_153,  -- L1394 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_02_154,  -- L1395 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_02_155,  -- L1396 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_02_156,  -- L1397 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_02_157,  -- L1398 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_02_158,  -- L1401 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_02_159,  -- L1402 [a mapper]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') else '00000' end AS P1_31_17,  -- L1411 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') else '00000' end AS P1_31_18,  -- L1416 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS COL_A_MAPPER_02_162,  -- L1423 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1424 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_02_164,  -- L1438 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_02_165,  -- L1441 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L1442 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_02_167,  -- L1478 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_02_168,  -- L1479 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_02_169,  -- L1480 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_02_170,  -- L1483 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_02_171,  -- L1484 [a mapper]
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
    --   colonnes : 204 (dont 50 ancrees --P1) | 179 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        COL_A_MAPPER_03_007,
        COL_A_MAPPER_03_008,
        COL_A_MAPPER_03_009,
        COL_A_MAPPER_03_010,
        COL_A_MAPPER_03_011,
        COL_A_MAPPER_03_012,
        COL_A_MAPPER_03_013,
        COL_A_MAPPER_03_014,
        COL_A_MAPPER_03_015,
        COL_A_MAPPER_03_016,
        COL_A_MAPPER_03_017,
        COL_A_MAPPER_03_018,
        COL_A_MAPPER_03_019,
        COL_A_MAPPER_03_020,
        COL_A_MAPPER_03_021,
        COL_A_MAPPER_03_022,
        COL_A_MAPPER_03_023,
        COL_A_MAPPER_03_024,
        COL_A_MAPPER_03_025,
        COL_A_MAPPER_03_026,
        COL_A_MAPPER_03_027,
        COL_A_MAPPER_03_028,
        COL_A_MAPPER_03_029,
        COL_A_MAPPER_03_030,
        COL_A_MAPPER_03_031,
        COL_A_MAPPER_03_032,
        COL_A_MAPPER_03_033,
        COL_A_MAPPER_03_034,
        COL_A_MAPPER_03_035,
        COL_A_MAPPER_03_036,
        COL_A_MAPPER_03_037,
        COL_A_MAPPER_03_038,
        COL_A_MAPPER_03_039,
        COL_A_MAPPER_03_040,
        COL_A_MAPPER_03_041,
        COL_A_MAPPER_03_042,
        COL_A_MAPPER_03_043,
        COL_A_MAPPER_03_044,
        COL_A_MAPPER_03_045,
        COL_A_MAPPER_03_046,
        COL_A_MAPPER_03_047,
        COL_A_MAPPER_03_048,
        COL_A_MAPPER_03_049,
        COL_A_MAPPER_03_050,
        COL_A_MAPPER_03_051,
        COL_A_MAPPER_03_052,
        COL_A_MAPPER_03_053,
        P1_2_99,
        P1_4_31,
        COL_A_MAPPER_03_056,
        P1_4_8,
        COL_A_MAPPER_03_058,
        COL_A_MAPPER_03_059,
        COL_A_MAPPER_03_060,
        COL_A_MAPPER_03_061,
        COL_A_MAPPER_03_062,
        COL_A_MAPPER_03_063,
        COL_A_MAPPER_03_064,
        COL_A_MAPPER_03_065,
        COL_A_MAPPER_03_066,
        COL_A_MAPPER_03_067,
        COL_A_MAPPER_03_068,
        COL_A_MAPPER_03_069,
        COL_A_MAPPER_03_070,
        COL_A_MAPPER_03_071,
        COL_A_MAPPER_03_072,
        COL_A_MAPPER_03_073,
        COL_A_MAPPER_03_074,
        COL_A_MAPPER_03_075,
        COL_A_MAPPER_03_076,
        COL_A_MAPPER_03_077,
        COL_A_MAPPER_03_078,
        COL_A_MAPPER_03_079,
        P1_22_5,
        COL_A_MAPPER_03_081,
        COL_A_MAPPER_03_082,
        COL_A_MAPPER_03_083,
        COL_A_MAPPER_03_084,
        COL_A_MAPPER_03_085,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_03_089,
        COL_A_MAPPER_03_090,
        COL_A_MAPPER_03_091,
        COL_A_MAPPER_03_092,
        COL_A_MAPPER_03_093,
        COL_A_MAPPER_03_094,
        COL_A_MAPPER_03_095,
        COL_A_MAPPER_03_096,
        COL_A_MAPPER_03_097,
        COL_A_MAPPER_03_098,
        COL_A_MAPPER_03_099,
        COL_A_MAPPER_03_100,
        COL_A_MAPPER_03_101,
        COL_A_MAPPER_03_102,
        COL_A_MAPPER_03_103,
        COL_A_MAPPER_03_104,
        COL_A_MAPPER_03_105,
        COL_A_MAPPER_03_106,
        COL_A_MAPPER_03_107,
        COL_A_MAPPER_03_108,
        COL_A_MAPPER_03_109,
        COL_A_MAPPER_03_110,
        COL_A_MAPPER_03_111,
        COL_A_MAPPER_03_112,
        COL_A_MAPPER_03_113,
        COL_A_MAPPER_03_114,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        COL_A_MAPPER_03_119,
        COL_A_MAPPER_03_120,
        COL_A_MAPPER_03_121,
        COL_A_MAPPER_03_122,
        P1_22_63,
        COL_A_MAPPER_03_124,
        COL_A_MAPPER_03_125,
        COL_A_MAPPER_03_126,
        COL_A_MAPPER_03_127,
        COL_A_MAPPER_03_128,
        COL_A_MAPPER_03_129,
        COL_A_MAPPER_03_130,
        COL_A_MAPPER_03_131,
        COL_A_MAPPER_03_132,
        COL_A_MAPPER_03_133,
        COL_A_MAPPER_03_134,
        COL_A_MAPPER_03_135,
        COL_A_MAPPER_03_136,
        COL_A_MAPPER_03_137,
        COL_A_MAPPER_03_138,
        COL_A_MAPPER_03_139,
        COL_A_MAPPER_03_140,
        COL_A_MAPPER_03_141,
        COL_A_MAPPER_03_142,
        COL_A_MAPPER_03_143,
        COL_A_MAPPER_03_144,
        COL_A_MAPPER_03_145,
        COL_A_MAPPER_03_146,
        COL_A_MAPPER_03_147,
        COL_A_MAPPER_03_148,
        COL_A_MAPPER_03_149,
        COL_A_MAPPER_03_150,
        COL_A_MAPPER_03_151,
        COL_A_MAPPER_03_152,
        COL_A_MAPPER_03_153,
        COL_A_MAPPER_03_154,
        COL_A_MAPPER_03_155,
        COL_A_MAPPER_03_156,
        COL_A_MAPPER_03_157,
        COL_A_MAPPER_03_158,
        P1_31_17,
        P1_31_18,
        COL_A_MAPPER_03_161,
        P1_31_22,
        COL_A_MAPPER_03_163,
        COL_A_MAPPER_03_164,
        P1_29_4,
        COL_A_MAPPER_03_166,
        COL_A_MAPPER_03_167,
        COL_A_MAPPER_03_168,
        COL_A_MAPPER_03_169,
        COL_A_MAPPER_03_170,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_03_007,  -- L1599 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_03_008,  -- L1602 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_03_009,  -- L1603 [a mapper]
        C_ENR.ID_ENGAGEMENT || '_C'                                AS COL_A_MAPPER_03_010,  -- L1605 [a mapper]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS COL_A_MAPPER_03_011,  -- L1608 [a mapper]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS COL_A_MAPPER_03_012,  -- L1609 [a mapper]
        'Y'                                                        AS COL_A_MAPPER_03_013,  -- L1610 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_03_014,  -- L1611 [a mapper]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS COL_A_MAPPER_03_015,  -- L1612 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_03_016,  -- L1613 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_03_017,  -- L1614 [a mapper]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS COL_A_MAPPER_03_018,  -- L1615 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_03_019,  -- L1616 [a mapper]
        NVL(C_ENR.DT_FIN_ENG, '99990630')                          AS COL_A_MAPPER_03_020,  -- L1617 [a mapper]
        0                                                          AS COL_A_MAPPER_03_021,  -- L1619 [a mapper]
        0                                                          AS COL_A_MAPPER_03_022,  -- L1620 [a mapper]
        0                                                          AS COL_A_MAPPER_03_023,  -- L1621 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_03_024,  -- L1624 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_03_025,  -- L1625 [a mapper]
        C_ENR.DT_RESTRUCTURATION                                   AS COL_A_MAPPER_03_026,  -- L1630 [a mapper]
        'N'                                                        AS COL_A_MAPPER_03_027,  -- L1631 [a mapper]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS COL_A_MAPPER_03_028,  -- L1635 [a mapper]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS COL_A_MAPPER_03_029,  -- L1636 [a mapper]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS COL_A_MAPPER_03_030,  -- L1637 [a mapper]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS COL_A_MAPPER_03_031,  -- L1640 [a mapper]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS COL_A_MAPPER_03_032,  -- L1643 [a mapper]
        NVL((C_ENR.MNT_RISQUE), 0)                                 AS COL_A_MAPPER_03_033,  -- L1644 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_03_034,  -- L1645 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE401' THEN NULL ELSE NVL(C_ENR.MNT_LOYER, 0) || NVL(C_ENR.CD_DEVISE_CRD, 'EUR') END AS COL_A_MAPPER_03_035,  -- L1646 [a mapper]
        C_ENR.PCCO_MNT_CRD                                         AS COL_A_MAPPER_03_036,  -- L1651 [a mapper]
        0                                                          AS COL_A_MAPPER_03_037,  -- L1652 [a mapper]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS COL_A_MAPPER_03_038,  -- L1653 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_03_039,  -- L1654 [a mapper]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 0 END       AS COL_A_MAPPER_03_040,  -- L1656 [a mapper]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS COL_A_MAPPER_03_041,  -- L1657 [a mapper]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS COL_A_MAPPER_03_042,  -- L1658 [a mapper]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS COL_A_MAPPER_03_043,  -- L1660 [a mapper]
        C_ENR.CD_RESPECT_COND                                      AS COL_A_MAPPER_03_044,  -- L1662 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_VTR), 0) else NULL END AS COL_A_MAPPER_03_045,  -- L1663 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_VTR else NULL END AS COL_A_MAPPER_03_046,  -- L1666 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_HYPOTHEQUE), 0) else NULL END AS COL_A_MAPPER_03_047,  -- L1667 [a mapper]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_HYPOTH else NULL END AS COL_A_MAPPER_03_048,  -- L1668 [a mapper]
        C_ENR.CD_LOC_BIEN                                          AS COL_A_MAPPER_03_049,  -- L1669 [a mapper]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS COL_A_MAPPER_03_050,  -- L1672 [a mapper]
        0                                                          AS COL_A_MAPPER_03_051,  -- L1675 [a mapper]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS COL_A_MAPPER_03_052,  -- L1677 [a mapper]
        C_ENR.cla_comp_ref_act                                     AS COL_A_MAPPER_03_053,  -- L1678 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1683 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1691 [P1 4.31]
        Substr(NVL(C_ENR.MATURITE_EFF, 0) ,4,6)                    AS COL_A_MAPPER_03_056,  -- L1699 [a mapper]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L1701 [P1 4.8]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_03_058,  -- L1703 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_03_059,  -- L1704 [a mapper]
        C_ENR.DT_DISPO_FONDS                                       AS COL_A_MAPPER_03_060,  -- L1706 [a mapper]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS COL_A_MAPPER_03_061,  -- L1711 [a mapper]
        C_ENR.EVENMT_CRDT                                          AS COL_A_MAPPER_03_062,  -- L1721 [a mapper]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS COL_A_MAPPER_03_063,  -- L1722 [a mapper]
        C_ENR.STA_CRDT                                             AS COL_A_MAPPER_03_064,  -- L1723 [a mapper]
        C_ENR.IND_CRE_PERF                                         AS COL_A_MAPPER_03_065,  -- L1724 [a mapper]
        C_ENR.DATE_PREM_ACT_FORB                                   AS COL_A_MAPPER_03_066,  -- L1725 [a mapper]
        C_ENR.DATE_DER_REST_COMM                                   AS COL_A_MAPPER_03_067,  -- L1726 [a mapper]
        C_ENR.DATE_DER_REST_RSQ                                    AS COL_A_MAPPER_03_068,  -- L1727 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS COL_A_MAPPER_03_069,  -- L1728 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS COL_A_MAPPER_03_070,  -- L1729 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS COL_A_MAPPER_03_071,  -- L1730 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS COL_A_MAPPER_03_072,  -- L1731 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS COL_A_MAPPER_03_073,  -- L1732 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS COL_A_MAPPER_03_074,  -- L1733 [a mapper]
        C_ENR.DT_PL_NPL                                            AS COL_A_MAPPER_03_075,  -- L1734 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS COL_A_MAPPER_03_076,  -- L1742 [a mapper]
        C_ENR.IND_OBJ_MET_PAL                                      AS COL_A_MAPPER_03_077,  -- L1745 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_03_078,  -- L1746 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_03_079,  -- L1747 [a mapper]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L1749 [P1 22.5]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_03_081,  -- L1750 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_03_082,  -- L1751 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_03_083,  -- L1753 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_03_084,  -- L1754 [a mapper]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS COL_A_MAPPER_03_085,  -- L1757 [a mapper]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1760 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1761 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1762 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_03_089,  -- L1763 [a mapper]
        C_ENR.TAUX_INT_EFF_ORI                                     AS COL_A_MAPPER_03_090,  -- L1764 [a mapper]
        C_ENR.TYPE_TAUX                                            AS COL_A_MAPPER_03_091,  -- L1765 [a mapper]
        C_ENR.IND_REF                                              AS COL_A_MAPPER_03_092,  -- L1766 [a mapper]
        C_ENR.TYPE_AMOR_CAP                                        AS COL_A_MAPPER_03_093,  -- L1767 [a mapper]
        C_ENR.PRD_AMOR_CAP                                         AS COL_A_MAPPER_03_094,  -- L1768 [a mapper]
        C_ENR.PRD_PMT_INT                                          AS COL_A_MAPPER_03_095,  -- L1769 [a mapper]
        C_ENR.TAUX_CLT_OCT                                         AS COL_A_MAPPER_03_096,  -- L1770 [a mapper]
        C_ENR.MOD_REMB_CRE                                         AS COL_A_MAPPER_03_097,  -- L1771 [a mapper]
        C_ENR.DATE_PREM_ECH                                        AS COL_A_MAPPER_03_098,  -- L1772 [a mapper]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS COL_A_MAPPER_03_099,  -- L1773 [a mapper]
        C_ENR.TAUX_PLAFOND                                         AS COL_A_MAPPER_03_100,  -- L1774 [a mapper]
        C_ENR.TAUX_PLANCHER                                        AS COL_A_MAPPER_03_101,  -- L1775 [a mapper]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS COL_A_MAPPER_03_102,  -- L1776 [a mapper]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS COL_A_MAPPER_03_103,  -- L1777 [a mapper]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS COL_A_MAPPER_03_104,  -- L1778 [a mapper]
        C_ENR.TAUX_MRG_ADD                                         AS COL_A_MAPPER_03_105,  -- L1779 [a mapper]
        C_ENR.TAUX_MRG_MULT                                        AS COL_A_MAPPER_03_106,  -- L1780 [a mapper]
        C_ENR.BASE_CAL_INT                                         AS COL_A_MAPPER_03_107,  -- L1781 [a mapper]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS COL_A_MAPPER_03_108,  -- L1782 [a mapper]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS COL_A_MAPPER_03_109,  -- L1784 [a mapper]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS COL_A_MAPPER_03_110,  -- L1786 [a mapper]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS COL_A_MAPPER_03_111,  -- L1788 [a mapper]
        C_ENR.DEVI_CAP_THEO_REST                                   AS COL_A_MAPPER_03_112,  -- L1791 [a mapper]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_03_113,  -- L1792 [a mapper]
        C_ENR.dt_exigte_prem_impy                                  AS COL_A_MAPPER_03_114,  -- L1793 [a mapper]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1804 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1805 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L1811 [P1 22.58]
        C_ENR.DATE_FIN_PALL                                        AS COL_A_MAPPER_03_119,  -- L1813 [a mapper]
        C_ENR.MNT_ECH_EN_COURS                                     AS COL_A_MAPPER_03_120,  -- L1814 [a mapper]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS COL_A_MAPPER_03_121,  -- L1816 [a mapper]
        C_ENR.IND_PRE_POST_FIX                                     AS COL_A_MAPPER_03_122,  -- L1817 [a mapper]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1818 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS COL_A_MAPPER_03_124,  -- L1822 [a mapper]
        C_ENR.DT_SIGNATURE                                         AS COL_A_MAPPER_03_125,  -- L1823 [a mapper]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS COL_A_MAPPER_03_126,  -- L1825 [a mapper]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_03_127,  -- L1826 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_03_128,  -- L1827 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV                                     AS COL_A_MAPPER_03_129,  -- L1829 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_03_130,  -- L1831 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_03_131,  -- L1832 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS COL_A_MAPPER_03_132,  -- L1833 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS COL_A_MAPPER_03_133,  -- L1834 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_03_134,  -- L1835 [a mapper]
        C_ENR.PCCO_MNT_CRD || C_ENR.ZONE_APP_COMP                  AS COL_A_MAPPER_03_135,  -- L1836 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_03_136,  -- L1838 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_03_137,  -- L1839 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_03_138,  -- L1840 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_03_139,  -- L1841 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_03_140,  -- L1843 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_03_141,  -- L1849 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_03_142,  -- L1852 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_03_143,  -- L1854 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_03_144,  -- L1855 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_03_145,  -- L1858 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_03_146,  -- L1860 [a mapper]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS COL_A_MAPPER_03_147,  -- L1863 [a mapper]
        C_ENR.MNT_IDEMNITE_RES                                     AS COL_A_MAPPER_03_148,  -- L1868 [a mapper]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS COL_A_MAPPER_03_149,  -- L1870 [a mapper]
        'N'                                                        AS COL_A_MAPPER_03_150,  -- L1879 [a mapper]
        'N'                                                        AS COL_A_MAPPER_03_151,  -- L1884 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_03_152,  -- L1888 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_03_153,  -- L1889 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_03_154,  -- L1890 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_03_155,  -- L1891 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_03_156,  -- L1892 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_03_157,  -- L1895 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_03_158,  -- L1896 [a mapper]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') else '00000' end AS P1_31_17,  -- L1905 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') else '00000' end AS P1_31_18,  -- L1910 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS COL_A_MAPPER_03_161,  -- L1917 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1918 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_03_163,  -- L1932 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_03_164,  -- L1935 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L1936 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_03_166,  -- L1972 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_03_167,  -- L1973 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_03_168,  -- L1974 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_03_169,  -- L1977 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_03_170,  -- L1978 [a mapper]
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
    --   colonnes : 108 (dont 27 ancrees --P1) | 382 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        COL_A_MAPPER_04_007,
        COL_A_MAPPER_04_008,
        COL_A_MAPPER_04_009,
        COL_A_MAPPER_04_010,
        COL_A_MAPPER_04_011,
        COL_A_MAPPER_04_012,
        COL_A_MAPPER_04_013,
        COL_A_MAPPER_04_014,
        COL_A_MAPPER_04_015,
        COL_A_MAPPER_04_016,
        COL_A_MAPPER_04_017,
        COL_A_MAPPER_04_018,
        COL_A_MAPPER_04_019,
        COL_A_MAPPER_04_020,
        COL_A_MAPPER_04_021,
        P1_5_5,
        P1_5_2,
        P1_4_2,
        COL_A_MAPPER_04_025,
        COL_A_MAPPER_04_026,
        COL_A_MAPPER_04_027,
        COL_A_MAPPER_04_028,
        COL_A_MAPPER_04_029,
        COL_A_MAPPER_04_030,
        P1_2_99,
        COL_A_MAPPER_04_032,
        COL_A_MAPPER_04_033,
        COL_A_MAPPER_04_034,
        COL_A_MAPPER_04_035,
        COL_A_MAPPER_04_036,
        COL_A_MAPPER_04_037,
        COL_A_MAPPER_04_038,
        COL_A_MAPPER_04_039,
        COL_A_MAPPER_04_040,
        COL_A_MAPPER_04_041,
        COL_A_MAPPER_04_042,
        COL_A_MAPPER_04_043,
        COL_A_MAPPER_04_044,
        COL_A_MAPPER_04_045,
        COL_A_MAPPER_04_046,
        COL_A_MAPPER_04_047,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_04_050,
        COL_A_MAPPER_04_051,
        P1_22_44,
        P1_22_45,
        COL_A_MAPPER_04_054,
        COL_A_MAPPER_04_055,
        COL_A_MAPPER_04_056,
        COL_A_MAPPER_04_057,
        COL_A_MAPPER_04_058,
        COL_A_MAPPER_04_059,
        COL_A_MAPPER_04_060,
        COL_A_MAPPER_04_061,
        COL_A_MAPPER_04_062,
        COL_A_MAPPER_04_063,
        COL_A_MAPPER_04_064,
        COL_A_MAPPER_04_065,
        COL_A_MAPPER_04_066,
        COL_A_MAPPER_04_067,
        COL_A_MAPPER_04_068,
        COL_A_MAPPER_04_069,
        COL_A_MAPPER_04_070,
        COL_A_MAPPER_04_071,
        COL_A_MAPPER_04_072,
        COL_A_MAPPER_04_073,
        COL_A_MAPPER_04_074,
        COL_A_MAPPER_04_075,
        COL_A_MAPPER_04_076,
        COL_A_MAPPER_04_077,
        COL_A_MAPPER_04_078,
        COL_A_MAPPER_04_079,
        COL_A_MAPPER_04_080,
        COL_A_MAPPER_04_081,
        COL_A_MAPPER_04_082,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        COL_A_MAPPER_04_086,
        COL_A_MAPPER_04_087,
        P1_29_4,
        COL_A_MAPPER_04_089,
        COL_A_MAPPER_04_090,
        COL_A_MAPPER_04_091,
        COL_A_MAPPER_04_092,
        COL_A_MAPPER_04_093,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_04_007,  -- L2903 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_04_008,  -- L2905 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_04_009,  -- L2906 [a mapper]
        C_ENR.ID_ENGAGEMENT                                        AS COL_A_MAPPER_04_010,  -- L2908 [a mapper]
        C_ENR.CD_METHODO_BALE2                                     AS COL_A_MAPPER_04_011,  -- L2911 [a mapper]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS COL_A_MAPPER_04_012,  -- L2912 [a mapper]
        C_ENR.CODE_TRAIT_GRR                                       AS COL_A_MAPPER_04_013,  -- L2913 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_04_014,  -- L2914 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS COL_A_MAPPER_04_015,  -- L2915 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_04_016,  -- L2916 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_04_017,  -- L2917 [a mapper]
        C_ENR.CD_NATURE_OPE                                        AS COL_A_MAPPER_04_018,  -- L2918 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_04_019,  -- L2919 [a mapper]
        C_ENR.DT_FIN_ENG                                           AS COL_A_MAPPER_04_020,  -- L2920 [a mapper]
        C_ENR.CD_DEVISE_ORIGINE                                    AS COL_A_MAPPER_04_021,  -- L2934 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L2938 [P1 5.5]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L2941 [P1 5.2]
        NVL((C_ENR.MNT_SOLDE), 0)                                  AS P1_4_2,  -- L2943 [P1 4.2]
        C_ENR.CD_DEVISE_SOLDE                                      AS COL_A_MAPPER_04_025,  -- L2951 [a mapper]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS COL_A_MAPPER_04_026,  -- L2955 [a mapper]
        C_ENR.MNT_LOYER                                            AS COL_A_MAPPER_04_027,  -- L2960 [a mapper]
        C_ENR.CD_DEVISE_CRD                                        AS COL_A_MAPPER_04_028,  -- L2965 [a mapper]
        C_ENR.PCCO_MNT_SOLDE                                       AS COL_A_MAPPER_04_029,  -- L2970 [a mapper]
        C_ENR.cla_comp_ref_act_s                                   AS COL_A_MAPPER_04_030,  -- L3007 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3043 [P1 2.99]
        ABS(TRUNC(C_ENR.MATURITE_EFF))                             AS COL_A_MAPPER_04_032,  -- L3118 [a mapper]
        ABS(MOD(C_ENR.MATURITE_EFF *10000,10000))                  AS COL_A_MAPPER_04_033,  -- L3119 [a mapper]
        C_ENR.TOP_ENG                                              AS COL_A_MAPPER_04_034,  -- L3120 [a mapper]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_04_035,  -- L3123 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_04_036,  -- L3124 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS COL_A_MAPPER_04_037,  -- L3199 [a mapper]
        C_ENR.IND_OBJ_MET_PAL                                      AS COL_A_MAPPER_04_038,  -- L3201 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_04_039,  -- L3202 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_04_040,  -- L3203 [a mapper]
        NVL(C_ENR.NOTE_FIN_RET_ORI, 'ND')                          AS COL_A_MAPPER_04_041,  -- L3205 [a mapper]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_04_042,  -- L3206 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_04_043,  -- L3207 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_04_044,  -- L3209 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_04_045,  -- L3210 [a mapper]
        upper(C_ENR.METH_NOT_ORI)                                  AS COL_A_MAPPER_04_046,  -- L3213 [a mapper]
        '97'                                                       AS COL_A_MAPPER_04_047,  -- L3214 [a mapper]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3215 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3222 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_04_050,  -- L3223 [a mapper]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_04_051,  -- L3227 [a mapper]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L3239 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L3240 [P1 22.45]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_04_054,  -- L3253 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_04_055,  -- L3256 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV_S                                   AS COL_A_MAPPER_04_056,  -- L3258 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_04_057,  -- L3268 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_04_058,  -- L3269 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9_S                                 AS COL_A_MAPPER_04_059,  -- L3270 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE_S                             AS COL_A_MAPPER_04_060,  -- L3271 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_04_061,  -- L3272 [a mapper]
        C_ENR.ZONE_APP_COMP                                        AS COL_A_MAPPER_04_062,  -- L3273 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_04_063,  -- L3275 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_04_064,  -- L3276 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_04_065,  -- L3277 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_04_066,  -- L3278 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_04_067,  -- L3280 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_04_068,  -- L3283 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_04_069,  -- L3284 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_04_070,  -- L3286 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_04_071,  -- L3287 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_04_072,  -- L3291 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_04_073,  -- L3293 [a mapper]
        'N'                                                        AS COL_A_MAPPER_04_074,  -- L3306 [a mapper]
        'N'                                                        AS COL_A_MAPPER_04_075,  -- L3311 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_04_076,  -- L3315 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_04_077,  -- L3316 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_04_078,  -- L3317 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_04_079,  -- L3318 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_04_080,  -- L3319 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_04_081,  -- L3322 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_04_082,  -- L3323 [a mapper]
        0                                                          AS P1_31_17,  -- L3327 [P1 31.17]
        0                                                          AS P1_31_18,  -- L3329 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3334 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_04_086,  -- L3341 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_04_087,  -- L3345 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L3346 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_04_089,  -- L3352 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_04_090,  -- L3353 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_04_091,  -- L3354 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_04_092,  -- L3357 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_04_093,  -- L3358 [a mapper]
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
    --   colonnes : 192 (dont 59 ancrees --P1) | 219 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        COL_A_MAPPER_05_007,
        COL_A_MAPPER_05_008,
        COL_A_MAPPER_05_009,
        COL_A_MAPPER_05_010,
        COL_A_MAPPER_05_011,
        COL_A_MAPPER_05_012,
        COL_A_MAPPER_05_013,
        COL_A_MAPPER_05_014,
        COL_A_MAPPER_05_015,
        COL_A_MAPPER_05_016,
        COL_A_MAPPER_05_017,
        COL_A_MAPPER_05_018,
        COL_A_MAPPER_05_019,
        COL_A_MAPPER_05_020,
        COL_A_MAPPER_05_021,
        COL_A_MAPPER_05_022,
        COL_A_MAPPER_05_023,
        COL_A_MAPPER_05_024,
        COL_A_MAPPER_05_025,
        COL_A_MAPPER_05_026,
        P1_5_2,
        P1_5_3,
        P1_4_4,
        COL_A_MAPPER_05_030,
        P1_4_9,
        P1_4_13,
        COL_A_MAPPER_05_033,
        COL_A_MAPPER_05_034,
        COL_A_MAPPER_05_035,
        COL_A_MAPPER_05_036,
        P1_4_7,
        COL_A_MAPPER_05_038,
        COL_A_MAPPER_05_039,
        COL_A_MAPPER_05_040,
        COL_A_MAPPER_05_041,
        P1_2_99,
        P1_4_31,
        COL_A_MAPPER_05_044,
        COL_A_MAPPER_05_045,
        COL_A_MAPPER_05_046,
        COL_A_MAPPER_05_047,
        COL_A_MAPPER_05_048,
        COL_A_MAPPER_05_049,
        COL_A_MAPPER_05_050,
        COL_A_MAPPER_05_051,
        COL_A_MAPPER_05_052,
        COL_A_MAPPER_05_053,
        COL_A_MAPPER_05_054,
        COL_A_MAPPER_05_055,
        COL_A_MAPPER_05_056,
        COL_A_MAPPER_05_057,
        COL_A_MAPPER_05_058,
        COL_A_MAPPER_05_059,
        COL_A_MAPPER_05_060,
        COL_A_MAPPER_05_061,
        COL_A_MAPPER_05_062,
        COL_A_MAPPER_05_063,
        COL_A_MAPPER_05_064,
        COL_A_MAPPER_05_065,
        COL_A_MAPPER_05_066,
        COL_A_MAPPER_05_067,
        COL_A_MAPPER_05_068,
        COL_A_MAPPER_05_069,
        COL_A_MAPPER_05_070,
        COL_A_MAPPER_05_071,
        COL_A_MAPPER_05_072,
        COL_A_MAPPER_05_073,
        COL_A_MAPPER_05_074,
        COL_A_MAPPER_05_075,
        COL_A_MAPPER_05_076,
        COL_A_MAPPER_05_077,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_05_080,
        COL_A_MAPPER_05_081,
        COL_A_MAPPER_05_082,
        COL_A_MAPPER_05_083,
        COL_A_MAPPER_05_084,
        COL_A_MAPPER_05_085,
        COL_A_MAPPER_05_086,
        COL_A_MAPPER_05_087,
        COL_A_MAPPER_05_088,
        COL_A_MAPPER_05_089,
        COL_A_MAPPER_05_090,
        COL_A_MAPPER_05_091,
        COL_A_MAPPER_05_092,
        COL_A_MAPPER_05_093,
        COL_A_MAPPER_05_094,
        COL_A_MAPPER_05_095,
        COL_A_MAPPER_05_096,
        COL_A_MAPPER_05_097,
        COL_A_MAPPER_05_098,
        COL_A_MAPPER_05_099,
        COL_A_MAPPER_05_100,
        COL_A_MAPPER_05_101,
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
        COL_A_MAPPER_05_113,
        COL_A_MAPPER_05_114,
        COL_A_MAPPER_05_115,
        COL_A_MAPPER_05_116,
        COL_A_MAPPER_05_117,
        COL_A_MAPPER_05_118,
        COL_A_MAPPER_05_119,
        COL_A_MAPPER_05_120,
        COL_A_MAPPER_05_121,
        COL_A_MAPPER_05_122,
        COL_A_MAPPER_05_123,
        COL_A_MAPPER_05_124,
        COL_A_MAPPER_05_125,
        COL_A_MAPPER_05_126,
        COL_A_MAPPER_05_127,
        COL_A_MAPPER_05_128,
        COL_A_MAPPER_05_129,
        COL_A_MAPPER_05_130,
        COL_A_MAPPER_05_131,
        COL_A_MAPPER_05_132,
        COL_A_MAPPER_05_133,
        COL_A_MAPPER_05_134,
        COL_A_MAPPER_05_135,
        COL_A_MAPPER_05_136,
        COL_A_MAPPER_05_137,
        COL_A_MAPPER_05_138,
        COL_A_MAPPER_05_139,
        COL_A_MAPPER_05_140,
        COL_A_MAPPER_05_141,
        COL_A_MAPPER_05_142,
        COL_A_MAPPER_05_143,
        COL_A_MAPPER_05_144,
        COL_A_MAPPER_05_145,
        COL_A_MAPPER_05_146,
        P1_31_17,
        P1_31_18,
        COL_A_MAPPER_05_149,
        P1_31_22,
        COL_A_MAPPER_05_151,
        COL_A_MAPPER_05_152,
        P1_29_4,
        COL_A_MAPPER_05_154,
        COL_A_MAPPER_05_155,
        COL_A_MAPPER_05_156,
        COL_A_MAPPER_05_157,
        COL_A_MAPPER_05_158,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_05_007,  -- L3472 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_05_008,  -- L3476 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_05_009,  -- L3477 [a mapper]
        C_ENR.ID_ENGAGEMENT                                        AS COL_A_MAPPER_05_010,  -- L3479 [a mapper]
        C_ENR.CD_METHODO_BALE2                                     AS COL_A_MAPPER_05_011,  -- L3482 [a mapper]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS COL_A_MAPPER_05_012,  -- L3484 [a mapper]
        C_ENR.CODE_TRAIT_GRR                                       AS COL_A_MAPPER_05_013,  -- L3485 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_05_014,  -- L3486 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS COL_A_MAPPER_05_015,  -- L3487 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_05_016,  -- L3488 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_05_017,  -- L3489 [a mapper]
        C_ENR.CD_NATURE_OPE                                        AS COL_A_MAPPER_05_018,  -- L3490 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_05_019,  -- L3491 [a mapper]
        C_ENR.DT_FIN_ENG                                           AS COL_A_MAPPER_05_020,  -- L3494 [a mapper]
        C_ENR.DEVISE_EAD                                           AS COL_A_MAPPER_05_021,  -- L3507 [a mapper]
        C_ENR.CD_DEVISE_ORIGINE                                    AS COL_A_MAPPER_05_022,  -- L3508 [a mapper]
        C_ENR.TOP_RESTRUCTURATION                                  AS COL_A_MAPPER_05_023,  -- L3510 [a mapper]
        (CASE WHEN C_ENR.TOP_RESTRUCTURATION = 'O' THEN C_ENR.DT_RESTRUCTURATION ELSE NULL END) AS COL_A_MAPPER_05_024,  -- L3512 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS COL_A_MAPPER_05_025,  -- L3517 [a mapper]
        C_ENR.CD_IMP_PRUDENT                                       AS COL_A_MAPPER_05_026,  -- L3518 [a mapper]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L3519 [P1 5.2]
        (CASE WHEN C_ENR.TOP_ENG_DOUTEUX = 'Y' THEN C_ENR.DT_ENG_DOUTEUX ELSE NULL END) AS P1_5_3,  -- L3520 [P1 5.3]
        (CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' AND NVL(C_ENR.MNT_SOLDE, 0) >=0 THEN NVL((C_ENR.MNT_SOLDE), 0) ELSE NULL END ) AS P1_4_4,  -- L3534 [P1 4.4]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS COL_A_MAPPER_05_030,  -- L3541 [a mapper]
        NVL((C_ENR.MNT_CRD), 0)                                    AS P1_4_9,  -- L3550 [P1 4.9]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS P1_4_13,  -- L3552 [P1 4.13]
        C_ENR.MNT_LOYER                                            AS COL_A_MAPPER_05_033,  -- L3553 [a mapper]
        C_ENR.CD_DEVISE_CRD                                        AS COL_A_MAPPER_05_034,  -- L3555 [a mapper]
        C_ENR.PCCO_MNT_CRD                                         AS COL_A_MAPPER_05_035,  -- L3560 [a mapper]
        (CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL((C_ENR.MNT_INT_RD), 0) ELSE NULL END ) AS COL_A_MAPPER_05_036,  -- L3561 [a mapper]
        ( CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL(C_ENR.CD_DEVISE_INT_RD, 'EUR') ELSE NULL END ) AS P1_4_7,  -- L3568 [P1 4.7]
        C_ENR.PCCO_INT_RD                                          AS COL_A_MAPPER_05_038,  -- L3578 [a mapper]
        C_ENR.cla_comp_ref_act                                     AS COL_A_MAPPER_05_039,  -- L3595 [a mapper]
        NVL(C_ENR.MNT_MTM, 0)                                      AS COL_A_MAPPER_05_040,  -- L3599 [a mapper]
        NVL(C_ENR.CD_DEV_MNT_MTM, 'EUR')                           AS COL_A_MAPPER_05_041,  -- L3600 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3610 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L3621 [P1 4.31]
        ABS(TRUNC(NVL(C_ENR.MATURITE_EFF, 0)))                     AS COL_A_MAPPER_05_044,  -- L3631 [a mapper]
        ABS(MOD(NVL(C_ENR.MATURITE_EFF, 0) *10000,10000))          AS COL_A_MAPPER_05_045,  -- L3633 [a mapper]
        C_ENR.TOP_ENG                                              AS COL_A_MAPPER_05_046,  -- L3634 [a mapper]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_05_047,  -- L3639 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_05_048,  -- L3640 [a mapper]
        C_ENR.DT_DISPO_FONDS                                       AS COL_A_MAPPER_05_049,  -- L3642 [a mapper]
        C_ENR.TX_ELBE                                              AS COL_A_MAPPER_05_050,  -- L3646 [a mapper]
        C_ENR.IND_CREANCE_TITRI                                    AS COL_A_MAPPER_05_051,  -- L3649 [a mapper]
        C_ENR.EVENMT_CRDT                                          AS COL_A_MAPPER_05_052,  -- L3659 [a mapper]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS COL_A_MAPPER_05_053,  -- L3661 [a mapper]
        C_ENR.STA_CRDT                                             AS COL_A_MAPPER_05_054,  -- L3662 [a mapper]
        C_ENR.IND_CRE_PERF                                         AS COL_A_MAPPER_05_055,  -- L3663 [a mapper]
        C_ENR.DATE_PREM_ACT_FORB                                   AS COL_A_MAPPER_05_056,  -- L3664 [a mapper]
        C_ENR.DATE_DER_REST_COMM                                   AS COL_A_MAPPER_05_057,  -- L3665 [a mapper]
        C_ENR.DATE_DER_REST_RSQ                                    AS COL_A_MAPPER_05_058,  -- L3666 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS COL_A_MAPPER_05_059,  -- L3667 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS COL_A_MAPPER_05_060,  -- L3668 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS COL_A_MAPPER_05_061,  -- L3669 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS COL_A_MAPPER_05_062,  -- L3670 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS COL_A_MAPPER_05_063,  -- L3671 [a mapper]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS COL_A_MAPPER_05_064,  -- L3672 [a mapper]
        C_ENR.DT_PL_NPL                                            AS COL_A_MAPPER_05_065,  -- L3673 [a mapper]
        C_ENR.CD_MOTIF_PL_NPL                                      AS COL_A_MAPPER_05_066,  -- L3676 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS COL_A_MAPPER_05_067,  -- L3681 [a mapper]
        C_ENR.IND_OBJ_MET_PAL                                      AS COL_A_MAPPER_05_068,  -- L3684 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_05_069,  -- L3685 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_05_070,  -- L3686 [a mapper]
        'ND'                                                       AS COL_A_MAPPER_05_071,  -- L3688 [a mapper]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_05_072,  -- L3689 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_05_073,  -- L3690 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_05_074,  -- L3692 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_05_075,  -- L3693 [a mapper]
        upper(C_ENR.METH_NOT_ORI)                                  AS COL_A_MAPPER_05_076,  -- L3696 [a mapper]
        '97'                                                       AS COL_A_MAPPER_05_077,  -- L3697 [a mapper]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3698 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3699 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_05_080,  -- L3700 [a mapper]
        C_ENR.TAUX_INT_EFF_ORI                                     AS COL_A_MAPPER_05_081,  -- L3703 [a mapper]
        C_ENR.TYPE_TAUX                                            AS COL_A_MAPPER_05_082,  -- L3704 [a mapper]
        C_ENR.IND_REF                                              AS COL_A_MAPPER_05_083,  -- L3707 [a mapper]
        C_ENR.TYPE_AMOR_CAP                                        AS COL_A_MAPPER_05_084,  -- L3708 [a mapper]
        C_ENR.PRD_AMOR_CAP                                         AS COL_A_MAPPER_05_085,  -- L3709 [a mapper]
        C_ENR.PRD_PMT_INT                                          AS COL_A_MAPPER_05_086,  -- L3710 [a mapper]
        C_ENR.TAUX_CLT_OCT                                         AS COL_A_MAPPER_05_087,  -- L3711 [a mapper]
        C_ENR.MOD_REMB_CRE                                         AS COL_A_MAPPER_05_088,  -- L3712 [a mapper]
        C_ENR.DATE_PREM_ECH                                        AS COL_A_MAPPER_05_089,  -- L3713 [a mapper]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS COL_A_MAPPER_05_090,  -- L3714 [a mapper]
        C_ENR.TAUX_PLAFOND                                         AS COL_A_MAPPER_05_091,  -- L3715 [a mapper]
        C_ENR.TAUX_PLANCHER                                        AS COL_A_MAPPER_05_092,  -- L3716 [a mapper]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS COL_A_MAPPER_05_093,  -- L3717 [a mapper]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS COL_A_MAPPER_05_094,  -- L3718 [a mapper]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS COL_A_MAPPER_05_095,  -- L3719 [a mapper]
        C_ENR.TAUX_MRG_ADD                                         AS COL_A_MAPPER_05_096,  -- L3722 [a mapper]
        C_ENR.TAUX_MRG_MULT                                        AS COL_A_MAPPER_05_097,  -- L3724 [a mapper]
        C_ENR.BASE_CAL_INT                                         AS COL_A_MAPPER_05_098,  -- L3725 [a mapper]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS COL_A_MAPPER_05_099,  -- L3726 [a mapper]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS COL_A_MAPPER_05_100,  -- L3729 [a mapper]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS COL_A_MAPPER_05_101,  -- L3731 [a mapper]
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
        C_ENR.CD_PAYS_JURIDICTION                                  AS COL_A_MAPPER_05_113,  -- L3764 [a mapper]
        C_ENR.DT_SIGNATURE                                         AS COL_A_MAPPER_05_114,  -- L3765 [a mapper]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS COL_A_MAPPER_05_115,  -- L3768 [a mapper]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_05_116,  -- L3769 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_05_117,  -- L3771 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV                                     AS COL_A_MAPPER_05_118,  -- L3774 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_05_119,  -- L3776 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_05_120,  -- L3777 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS COL_A_MAPPER_05_121,  -- L3778 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS COL_A_MAPPER_05_122,  -- L3779 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_05_123,  -- L3780 [a mapper]
        C_ENR.ZONE_APP_COMP                                        AS COL_A_MAPPER_05_124,  -- L3781 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_05_125,  -- L3783 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_05_126,  -- L3784 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_05_127,  -- L3785 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_05_128,  -- L3786 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_05_129,  -- L3788 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_05_130,  -- L3793 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_05_131,  -- L3794 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_05_132,  -- L3796 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_05_133,  -- L3797 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_05_134,  -- L3801 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_05_135,  -- L3803 [a mapper]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS COL_A_MAPPER_05_136,  -- L3806 [a mapper]
        C_ENR.IND_SPONSOR_FIN                                      AS COL_A_MAPPER_05_137,  -- L3808 [a mapper]
        'N'                                                        AS COL_A_MAPPER_05_138,  -- L3820 [a mapper]
        'N'                                                        AS COL_A_MAPPER_05_139,  -- L3825 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_05_140,  -- L3829 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_05_141,  -- L3830 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_05_142,  -- L3831 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_05_143,  -- L3832 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_05_144,  -- L3833 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_05_145,  -- L3836 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_05_146,  -- L3837 [a mapper]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') AS P1_31_17,  -- L3846 [P1 31.17]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), '00000') AS P1_31_18,  -- L3848 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS COL_A_MAPPER_05_149,  -- L3852 [a mapper]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3853 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_05_151,  -- L3867 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_05_152,  -- L3870 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L3871 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_05_154,  -- L3913 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_05_155,  -- L3914 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_05_156,  -- L3915 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_05_157,  -- L3918 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_05_158,  -- L3919 [a mapper]
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
    --   colonnes : 113 (dont 28 ancrees --P1) | 405 fillers -> NULL | 2 signes absorbes par le NUMBER
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
        COL_A_MAPPER_06_007,
        COL_A_MAPPER_06_008,
        COL_A_MAPPER_06_009,
        COL_A_MAPPER_06_010,
        COL_A_MAPPER_06_011,
        COL_A_MAPPER_06_012,
        COL_A_MAPPER_06_013,
        COL_A_MAPPER_06_014,
        COL_A_MAPPER_06_015,
        COL_A_MAPPER_06_016,
        COL_A_MAPPER_06_017,
        COL_A_MAPPER_06_018,
        COL_A_MAPPER_06_019,
        COL_A_MAPPER_06_020,
        COL_A_MAPPER_06_021,
        P1_5_5,
        P1_5_2,
        COL_A_MAPPER_06_024,
        COL_A_MAPPER_06_025,
        COL_A_MAPPER_06_026,
        COL_A_MAPPER_06_027,
        COL_A_MAPPER_06_028,
        COL_A_MAPPER_06_029,
        COL_A_MAPPER_06_030,
        COL_A_MAPPER_06_031,
        COL_A_MAPPER_06_032,
        COL_A_MAPPER_06_033,
        COL_A_MAPPER_06_034,
        COL_A_MAPPER_06_035,
        COL_A_MAPPER_06_036,
        P1_2_99,
        P1_4_31,
        COL_A_MAPPER_06_039,
        COL_A_MAPPER_06_040,
        COL_A_MAPPER_06_041,
        COL_A_MAPPER_06_042,
        COL_A_MAPPER_06_043,
        COL_A_MAPPER_06_044,
        COL_A_MAPPER_06_045,
        COL_A_MAPPER_06_046,
        COL_A_MAPPER_06_047,
        COL_A_MAPPER_06_048,
        COL_A_MAPPER_06_049,
        COL_A_MAPPER_06_050,
        COL_A_MAPPER_06_051,
        COL_A_MAPPER_06_052,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_06_055,
        COL_A_MAPPER_06_056,
        COL_A_MAPPER_06_057,
        COL_A_MAPPER_06_058,
        COL_A_MAPPER_06_059,
        COL_A_MAPPER_06_060,
        COL_A_MAPPER_06_061,
        COL_A_MAPPER_06_062,
        COL_A_MAPPER_06_063,
        COL_A_MAPPER_06_064,
        COL_A_MAPPER_06_065,
        COL_A_MAPPER_06_066,
        COL_A_MAPPER_06_067,
        COL_A_MAPPER_06_068,
        COL_A_MAPPER_06_069,
        COL_A_MAPPER_06_070,
        COL_A_MAPPER_06_071,
        COL_A_MAPPER_06_072,
        COL_A_MAPPER_06_073,
        COL_A_MAPPER_06_074,
        COL_A_MAPPER_06_075,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        COL_A_MAPPER_06_081,
        COL_A_MAPPER_06_082,
        COL_A_MAPPER_06_083,
        COL_A_MAPPER_06_084,
        COL_A_MAPPER_06_085,
        COL_A_MAPPER_06_086,
        COL_A_MAPPER_06_087,
        COL_A_MAPPER_06_088,
        COL_A_MAPPER_06_089,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        COL_A_MAPPER_06_093,
        COL_A_MAPPER_06_094,
        P1_29_4,
        COL_A_MAPPER_06_096,
        COL_A_MAPPER_06_097,
        COL_A_MAPPER_06_098,
        COL_A_MAPPER_06_099,
        COL_A_MAPPER_06_100,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_06_007,  -- L4035 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_06_008,  -- L4039 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_06_009,  -- L4040 [a mapper]
        C_ENR.ID_ENGAGEMENT                                        AS COL_A_MAPPER_06_010,  -- L4042 [a mapper]
        C_ENR.CD_METHODO_BALE2                                     AS COL_A_MAPPER_06_011,  -- L4045 [a mapper]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS COL_A_MAPPER_06_012,  -- L4047 [a mapper]
        C_ENR.CODE_TRAIT_GRR                                       AS COL_A_MAPPER_06_013,  -- L4048 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_06_014,  -- L4049 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS COL_A_MAPPER_06_015,  -- L4050 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_06_016,  -- L4051 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_06_017,  -- L4052 [a mapper]
        C_ENR.CD_NATURE_OPE                                        AS COL_A_MAPPER_06_018,  -- L4053 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_06_019,  -- L4054 [a mapper]
        C_ENR.DT_FIN_ENG                                           AS COL_A_MAPPER_06_020,  -- L4057 [a mapper]
        C_ENR.CD_DEVISE_ORIGINE                                    AS COL_A_MAPPER_06_021,  -- L4071 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4075 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L4077 [P1 5.2]
        C_ENR.CD_CPT_ACTIF_IAS                                     AS COL_A_MAPPER_06_024,  -- L4138 [a mapper]
        C_ENR.PCCO_ACQUISITION                                     AS COL_A_MAPPER_06_025,  -- L4139 [a mapper]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS COL_A_MAPPER_06_026,  -- L4140 [a mapper]
        NVL(C_ENR.CD_DEVISE_ACQUISITION, 'EUR')                    AS COL_A_MAPPER_06_027,  -- L4141 [a mapper]
        NVL(C_ENR.MNT_MTM, 0)                                      AS COL_A_MAPPER_06_028,  -- L4142 [a mapper]
        C_ENR.CD_DEVISE_MTM                                        AS COL_A_MAPPER_06_029,  -- L4144 [a mapper]
        NVL(C_ENR.MNT_COUT_AMORTI, 0)                              AS COL_A_MAPPER_06_030,  -- L4145 [a mapper]
        NVL(C_ENR.CD_DEV_COUT_AMORTI, 'EUR')                       AS COL_A_MAPPER_06_031,  -- L4146 [a mapper]
        C_ENR.CD_IMP_PRUDENT                                       AS COL_A_MAPPER_06_032,  -- L4159 [a mapper]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS COL_A_MAPPER_06_033,  -- L4161 [a mapper]
        C_ENR.CD_DEVISE_NOMINAL                                    AS COL_A_MAPPER_06_034,  -- L4162 [a mapper]
        C_ENR.PCCO_NOMINAL                                         AS COL_A_MAPPER_06_035,  -- L4163 [a mapper]
        C_ENR.NATURE_PROD_SS_JACENT                                AS COL_A_MAPPER_06_036,  -- L4164 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4171 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4234 [P1 4.31]
        ABS(TRUNC(C_ENR.MATURITE_EFF))                             AS COL_A_MAPPER_06_039,  -- L4249 [a mapper]
        ABS(MOD(C_ENR.MATURITE_EFF *10000,10000))                  AS COL_A_MAPPER_06_040,  -- L4251 [a mapper]
        C_ENR.TOP_ENG                                              AS COL_A_MAPPER_06_041,  -- L4252 [a mapper]
        C_ENR.INSTRUMENT_FINANCIER                                 AS COL_A_MAPPER_06_042,  -- L4254 [a mapper]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_06_043,  -- L4255 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_06_044,  -- L4256 [a mapper]
        NVL(C_ENR.IND_CRE_PERF, 'PE')                              AS COL_A_MAPPER_06_045,  -- L4329 [a mapper]
        C_ENR.DT_PL_NPL                                            AS COL_A_MAPPER_06_046,  -- L4331 [a mapper]
        C_ENR.CD_MOTIF_PL_NPL                                      AS COL_A_MAPPER_06_047,  -- L4332 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS COL_A_MAPPER_06_048,  -- L4337 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_06_049,  -- L4341 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_06_050,  -- L4342 [a mapper]
        'ND'                                                       AS COL_A_MAPPER_06_051,  -- L4346 [a mapper]
        '97'                                                       AS COL_A_MAPPER_06_052,  -- L4352 [a mapper]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4353 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4354 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_06_055,  -- L4355 [a mapper]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_06_056,  -- L4359 [a mapper]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_06_057,  -- L4365 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_06_058,  -- L4367 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV                                     AS COL_A_MAPPER_06_059,  -- L4369 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_06_060,  -- L4371 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_06_061,  -- L4372 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS COL_A_MAPPER_06_062,  -- L4373 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS COL_A_MAPPER_06_063,  -- L4374 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_06_064,  -- L4375 [a mapper]
        C_ENR.ZONE_APP_COMP                                        AS COL_A_MAPPER_06_065,  -- L4376 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_06_066,  -- L4378 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_06_067,  -- L4379 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_06_068,  -- L4380 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_06_069,  -- L4381 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_06_070,  -- L4383 [a mapper]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS COL_A_MAPPER_06_071,  -- L4385 [a mapper]
        C_ENR.COMPLEXITE_PRODUIT                                   AS COL_A_MAPPER_06_072,  -- L4386 [a mapper]
        C_ENR.IND_ACTIF_COTE                                       AS COL_A_MAPPER_06_073,  -- L4387 [a mapper]
        C_ENR.NB_TITRES                                            AS COL_A_MAPPER_06_074,  -- L4388 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_06_075,  -- L4413 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L4414 [P1 22.11]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L4416 [P1 26.3]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L4417 [P1 26.4]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L4420 [P1 27.3]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L4422 [P1 27.4]
        'N'                                                        AS COL_A_MAPPER_06_081,  -- L4433 [a mapper]
        'N'                                                        AS COL_A_MAPPER_06_082,  -- L4438 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_06_083,  -- L4442 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_06_084,  -- L4443 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_06_085,  -- L4444 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_06_086,  -- L4445 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_06_087,  -- L4446 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_06_088,  -- L4449 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_06_089,  -- L4450 [a mapper]
        0                                                          AS P1_31_17,  -- L4454 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4456 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4461 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_06_093,  -- L4468 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_06_094,  -- L4472 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L4473 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_06_096,  -- L4496 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_06_097,  -- L4497 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_06_098,  -- L4498 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_06_099,  -- L4501 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_06_100,  -- L4502 [a mapper]
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
    --   colonnes : 112 (dont 23 ancrees --P1) | 259 fillers -> NULL | 2 signes absorbes par le NUMBER
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
        COL_A_MAPPER_07_007,
        COL_A_MAPPER_07_008,
        COL_A_MAPPER_07_009,
        COL_A_MAPPER_07_010,
        COL_A_MAPPER_07_011,
        COL_A_MAPPER_07_012,
        COL_A_MAPPER_07_013,
        COL_A_MAPPER_07_014,
        COL_A_MAPPER_07_015,
        COL_A_MAPPER_07_016,
        COL_A_MAPPER_07_017,
        COL_A_MAPPER_07_018,
        COL_A_MAPPER_07_019,
        COL_A_MAPPER_07_020,
        COL_A_MAPPER_07_021,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        COL_A_MAPPER_07_025,
        COL_A_MAPPER_07_026,
        COL_A_MAPPER_07_027,
        COL_A_MAPPER_07_028,
        COL_A_MAPPER_07_029,
        COL_A_MAPPER_07_030,
        COL_A_MAPPER_07_031,
        COL_A_MAPPER_07_032,
        COL_A_MAPPER_07_033,
        COL_A_MAPPER_07_034,
        COL_A_MAPPER_07_035,
        P1_2_99,
        P1_4_31,
        COL_A_MAPPER_07_038,
        COL_A_MAPPER_07_039,
        COL_A_MAPPER_07_040,
        COL_A_MAPPER_07_041,
        COL_A_MAPPER_07_042,
        COL_A_MAPPER_07_043,
        P1_22_57,
        COL_A_MAPPER_07_045,
        COL_A_MAPPER_07_046,
        COL_A_MAPPER_07_047,
        COL_A_MAPPER_07_048,
        COL_A_MAPPER_07_049,
        COL_A_MAPPER_07_050,
        COL_A_MAPPER_07_051,
        COL_A_MAPPER_07_052,
        COL_A_MAPPER_07_053,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_07_056,
        COL_A_MAPPER_07_057,
        COL_A_MAPPER_07_058,
        COL_A_MAPPER_07_059,
        COL_A_MAPPER_07_060,
        COL_A_MAPPER_07_061,
        COL_A_MAPPER_07_062,
        COL_A_MAPPER_07_063,
        COL_A_MAPPER_07_064,
        COL_A_MAPPER_07_065,
        COL_A_MAPPER_07_066,
        COL_A_MAPPER_07_067,
        COL_A_MAPPER_07_068,
        COL_A_MAPPER_07_069,
        COL_A_MAPPER_07_070,
        COL_A_MAPPER_07_071,
        COL_A_MAPPER_07_072,
        COL_A_MAPPER_07_073,
        COL_A_MAPPER_07_074,
        COL_A_MAPPER_07_075,
        COL_A_MAPPER_07_076,
        COL_A_MAPPER_07_077,
        COL_A_MAPPER_07_078,
        COL_A_MAPPER_07_079,
        COL_A_MAPPER_07_080,
        COL_A_MAPPER_07_081,
        COL_A_MAPPER_07_082,
        COL_A_MAPPER_07_083,
        COL_A_MAPPER_07_084,
        COL_A_MAPPER_07_085,
        COL_A_MAPPER_07_086,
        COL_A_MAPPER_07_087,
        COL_A_MAPPER_07_088,
        COL_A_MAPPER_07_089,
        COL_A_MAPPER_07_090,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        COL_A_MAPPER_07_094,
        COL_A_MAPPER_07_095,
        P1_29_4,
        COL_A_MAPPER_07_097,
        COL_A_MAPPER_07_098,
        COL_A_MAPPER_07_099,
        COL_A_MAPPER_07_100,
        COL_A_MAPPER_07_101,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_07_007,  -- L4615 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_07_008,  -- L4619 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_07_009,  -- L4620 [a mapper]
        C_ENR.ID_ENGAGEMENT                                        AS COL_A_MAPPER_07_010,  -- L4622 [a mapper]
        C_ENR.CD_METHODO_BALE2                                     AS COL_A_MAPPER_07_011,  -- L4625 [a mapper]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS COL_A_MAPPER_07_012,  -- L4626 [a mapper]
        C_ENR.CODE_TRAIT_GRR                                       AS COL_A_MAPPER_07_013,  -- L4627 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_07_014,  -- L4628 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS COL_A_MAPPER_07_015,  -- L4629 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_07_016,  -- L4630 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_07_017,  -- L4631 [a mapper]
        C_ENR.CD_NATURE_OPE                                        AS COL_A_MAPPER_07_018,  -- L4632 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_07_019,  -- L4633 [a mapper]
        C_ENR.DT_FIN_ENG                                           AS COL_A_MAPPER_07_020,  -- L4634 [a mapper]
        C_ENR.CD_DEVISE_ORIGINE                                    AS COL_A_MAPPER_07_021,  -- L4648 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4652 [P1 5.5]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_4_1,  -- L4653 [P1 4.1]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L4654 [P1 5.2]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS COL_A_MAPPER_07_025,  -- L4668 [a mapper]
        C_ENR.MNT_LOYER                                            AS COL_A_MAPPER_07_026,  -- L4673 [a mapper]
        C_ENR.CD_DEVISE_CRD                                        AS COL_A_MAPPER_07_027,  -- L4678 [a mapper]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS COL_A_MAPPER_07_028,  -- L4679 [a mapper]
        C_ENR.CD_DEVISE_NOMINAL                                    AS COL_A_MAPPER_07_029,  -- L4680 [a mapper]
        C_ENR.PCCO_NOMINAL                                         AS COL_A_MAPPER_07_030,  -- L4681 [a mapper]
        NVL((C_ENR.MNT_INT_RD), 0)                                 AS COL_A_MAPPER_07_031,  -- L4682 [a mapper]
        C_ENR.CD_DEVISE_INT_RD                                     AS COL_A_MAPPER_07_032,  -- L4683 [a mapper]
        C_ENR.PCCO_INT_RD                                          AS COL_A_MAPPER_07_033,  -- L4684 [a mapper]
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_07_034,  -- L4694 [a mapper]
        C_ENR.CLA_COMP_REF_ACT                                     AS COL_A_MAPPER_07_035,  -- L4703 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4733 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4757 [P1 4.31]
        ABS(TRUNC(NVL(C_ENR.MATURITE_EFF, 0)))                     AS COL_A_MAPPER_07_038,  -- L4776 [a mapper]
        ABS(MOD(NVL(C_ENR.MATURITE_EFF, 0) *10000,10000))          AS COL_A_MAPPER_07_039,  -- L4778 [a mapper]
        C_ENR.TOP_ENG                                              AS COL_A_MAPPER_07_040,  -- L4779 [a mapper]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS COL_A_MAPPER_07_041,  -- L4782 [a mapper]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_07_042,  -- L4783 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS COL_A_MAPPER_07_043,  -- L4790 [a mapper]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L4792 [P1 22.57]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_07_045,  -- L4793 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_07_046,  -- L4794 [a mapper]
        'ND'                                                       AS COL_A_MAPPER_07_047,  -- L4796 [a mapper]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_07_048,  -- L4797 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_07_049,  -- L4798 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_07_050,  -- L4800 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_07_051,  -- L4801 [a mapper]
        upper(C_ENR.METH_NOT_ORI)                                  AS COL_A_MAPPER_07_052,  -- L4804 [a mapper]
        '97'                                                       AS COL_A_MAPPER_07_053,  -- L4805 [a mapper]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4806 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4807 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_07_056,  -- L4808 [a mapper]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_07_057,  -- L4812 [a mapper]
        C_ENR.CD_PAYS_JURIDICTION                                  AS COL_A_MAPPER_07_058,  -- L4819 [a mapper]
        C_ENR.DT_SIGNATURE                                         AS COL_A_MAPPER_07_059,  -- L4821 [a mapper]
        C_ENR.EVT_DECL_GAR                                         AS COL_A_MAPPER_07_060,  -- L4822 [a mapper]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS COL_A_MAPPER_07_061,  -- L4824 [a mapper]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_07_062,  -- L4825 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS COL_A_MAPPER_07_063,  -- L4827 [a mapper]
        C_ENR.ELI_OUT_MUT_PROV                                     AS COL_A_MAPPER_07_064,  -- L4829 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_07_065,  -- L4839 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_07_066,  -- L4840 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS COL_A_MAPPER_07_067,  -- L4841 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS COL_A_MAPPER_07_068,  -- L4842 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_07_069,  -- L4843 [a mapper]
        C_ENR.ZONE_APP_COMP                                        AS COL_A_MAPPER_07_070,  -- L4844 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_07_071,  -- L4846 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_07_072,  -- L4847 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_07_073,  -- L4848 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_07_074,  -- L4849 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_07_075,  -- L4851 [a mapper]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_07_076,  -- L4854 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_07_077,  -- L4855 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_07_078,  -- L4857 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_07_079,  -- L4858 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_07_080,  -- L4862 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_07_081,  -- L4864 [a mapper]
        'N'                                                        AS COL_A_MAPPER_07_082,  -- L4877 [a mapper]
        'N'                                                        AS COL_A_MAPPER_07_083,  -- L4882 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_07_084,  -- L4886 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_07_085,  -- L4887 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_07_086,  -- L4888 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_07_087,  -- L4889 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_07_088,  -- L4890 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_07_089,  -- L4893 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_07_090,  -- L4894 [a mapper]
        0                                                          AS P1_31_17,  -- L4898 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4900 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4906 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_07_094,  -- L4912 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_07_095,  -- L4916 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L4917 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_07_097,  -- L4952 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_07_098,  -- L4953 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_07_099,  -- L4954 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_07_100,  -- L4957 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_07_101,  -- L4958 [a mapper]
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
    --   colonnes : 161 (dont 35 ancrees --P1) | 318 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        COL_A_MAPPER_08_007,
        COL_A_MAPPER_08_008,
        COL_A_MAPPER_08_009,
        COL_A_MAPPER_08_010,
        COL_A_MAPPER_08_011,
        COL_A_MAPPER_08_012,
        COL_A_MAPPER_08_013,
        COL_A_MAPPER_08_014,
        COL_A_MAPPER_08_015,
        COL_A_MAPPER_08_016,
        COL_A_MAPPER_08_017,
        COL_A_MAPPER_08_018,
        COL_A_MAPPER_08_019,
        COL_A_MAPPER_08_020,
        COL_A_MAPPER_08_021,
        P1_5_5,
        P1_5_2,
        COL_A_MAPPER_08_024,
        COL_A_MAPPER_08_025,
        COL_A_MAPPER_08_026,
        COL_A_MAPPER_08_027,
        COL_A_MAPPER_08_028,
        COL_A_MAPPER_08_029,
        COL_A_MAPPER_08_030,
        COL_A_MAPPER_08_031,
        COL_A_MAPPER_08_032,
        P1_2_99,
        COL_A_MAPPER_08_034,
        COL_A_MAPPER_08_035,
        COL_A_MAPPER_08_036,
        COL_A_MAPPER_08_037,
        COL_A_MAPPER_08_038,
        COL_A_MAPPER_08_039,
        COL_A_MAPPER_08_040,
        COL_A_MAPPER_08_041,
        COL_A_MAPPER_08_042,
        COL_A_MAPPER_08_043,
        COL_A_MAPPER_08_044,
        COL_A_MAPPER_08_045,
        COL_A_MAPPER_08_046,
        COL_A_MAPPER_08_047,
        COL_A_MAPPER_08_048,
        COL_A_MAPPER_08_049,
        P1_3_75,
        P1_4_42,
        COL_A_MAPPER_08_052,
        COL_A_MAPPER_08_053,
        COL_A_MAPPER_08_054,
        COL_A_MAPPER_08_055,
        COL_A_MAPPER_08_056,
        COL_A_MAPPER_08_057,
        COL_A_MAPPER_08_058,
        COL_A_MAPPER_08_059,
        COL_A_MAPPER_08_060,
        COL_A_MAPPER_08_061,
        COL_A_MAPPER_08_062,
        COL_A_MAPPER_08_063,
        COL_A_MAPPER_08_064,
        COL_A_MAPPER_08_065,
        COL_A_MAPPER_08_066,
        COL_A_MAPPER_08_067,
        COL_A_MAPPER_08_068,
        P1_10_2,
        P1_8_1,
        P1_8_2,
        P1_8_11,
        P1_8_12,
        COL_A_MAPPER_08_074,
        COL_A_MAPPER_08_075,
        COL_A_MAPPER_08_076,
        COL_A_MAPPER_08_077,
        P1_22_56,
        P1_22_57,
        COL_A_MAPPER_08_080,
        COL_A_MAPPER_08_081,
        COL_A_MAPPER_08_082,
        COL_A_MAPPER_08_083,
        COL_A_MAPPER_08_084,
        COL_A_MAPPER_08_085,
        COL_A_MAPPER_08_086,
        COL_A_MAPPER_08_087,
        COL_A_MAPPER_08_088,
        P1_22_8,
        P1_22_9,
        COL_A_MAPPER_08_091,
        P1_22_16,
        COL_A_MAPPER_08_093,
        P1_22_66,
        COL_A_MAPPER_08_095,
        P1_22_72,
        COL_A_MAPPER_08_097,
        COL_A_MAPPER_08_098,
        COL_A_MAPPER_08_099,
        COL_A_MAPPER_08_100,
        COL_A_MAPPER_08_101,
        COL_A_MAPPER_08_102,
        COL_A_MAPPER_08_103,
        COL_A_MAPPER_08_104,
        COL_A_MAPPER_08_105,
        COL_A_MAPPER_08_106,
        COL_A_MAPPER_08_107,
        COL_A_MAPPER_08_108,
        P1_24_3,
        P1_24_20,
        P1_24_23,
        P1_24_24,
        COL_A_MAPPER_08_113,
        COL_A_MAPPER_08_114,
        COL_A_MAPPER_08_115,
        COL_A_MAPPER_08_116,
        COL_A_MAPPER_08_117,
        COL_A_MAPPER_08_118,
        COL_A_MAPPER_08_119,
        COL_A_MAPPER_08_120,
        COL_A_MAPPER_08_121,
        COL_A_MAPPER_08_122,
        COL_A_MAPPER_08_123,
        COL_A_MAPPER_08_124,
        COL_A_MAPPER_08_125,
        COL_A_MAPPER_08_126,
        COL_A_MAPPER_08_127,
        COL_A_MAPPER_08_128,
        COL_A_MAPPER_08_129,
        COL_A_MAPPER_08_130,
        COL_A_MAPPER_08_131,
        P1_30_23,
        COL_A_MAPPER_08_133,
        COL_A_MAPPER_08_134,
        COL_A_MAPPER_08_135,
        COL_A_MAPPER_08_136,
        COL_A_MAPPER_08_137,
        COL_A_MAPPER_08_138,
        COL_A_MAPPER_08_139,
        COL_A_MAPPER_08_140,
        COL_A_MAPPER_08_141,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        COL_A_MAPPER_08_145,
        COL_A_MAPPER_08_146,
        P1_29_4,
        COL_A_MAPPER_08_148,
        COL_A_MAPPER_08_149,
        COL_A_MAPPER_08_150,
        COL_A_MAPPER_08_151,
        COL_A_MAPPER_08_152,
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
        C_ENR.ID_TIERS_CALC                                        AS COL_A_MAPPER_08_007,  -- L5070 [a mapper]
        C_ENR.ID_AUTORISATION                                      AS COL_A_MAPPER_08_008,  -- L5074 [a mapper]
        C_ENR.ID_LIGNE_DET                                         AS COL_A_MAPPER_08_009,  -- L5075 [a mapper]
        C_ENR.ID_ENGAGEMENT                                        AS COL_A_MAPPER_08_010,  -- L5077 [a mapper]
        C_ENR.CD_METHODO_BALE2                                     AS COL_A_MAPPER_08_011,  -- L5080 [a mapper]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS COL_A_MAPPER_08_012,  -- L5082 [a mapper]
        C_ENR.CODE_TRAIT_GRR                                       AS COL_A_MAPPER_08_013,  -- L5083 [a mapper]
        C_ENR.CD_TYPE_RISQUE                                       AS COL_A_MAPPER_08_014,  -- L5084 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS COL_A_MAPPER_08_015,  -- L5085 [a mapper]
        C_ENR.CD_LIGNE_METIER                                      AS COL_A_MAPPER_08_016,  -- L5086 [a mapper]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS COL_A_MAPPER_08_017,  -- L5087 [a mapper]
        C_ENR.CD_NATURE_OPE                                        AS COL_A_MAPPER_08_018,  -- L5088 [a mapper]
        C_ENR.DT_DEBUT_ENG                                         AS COL_A_MAPPER_08_019,  -- L5089 [a mapper]
        C_ENR.DT_FIN_ENG                                           AS COL_A_MAPPER_08_020,  -- L5092 [a mapper]
        C_ENR.CD_DEVISE_ORIGINE                                    AS COL_A_MAPPER_08_021,  -- L5106 [a mapper]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L5111 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L5114 [P1 5.2]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS COL_A_MAPPER_08_024,  -- L5130 [a mapper]
        C_ENR.MNT_LOYER                                            AS COL_A_MAPPER_08_025,  -- L5135 [a mapper]
        C_ENR.CD_DEVISE_CRD                                        AS COL_A_MAPPER_08_026,  -- L5140 [a mapper]
        C_ENR.cla_comp_ref_act                                     AS COL_A_MAPPER_08_027,  -- L5185 [a mapper]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS COL_A_MAPPER_08_028,  -- L5211 [a mapper]
        C_ENR.CD_DEVISE_NOMINAL                                    AS COL_A_MAPPER_08_029,  -- L5213 [a mapper]
        C_ENR.PCCO_NOMINAL                                         AS COL_A_MAPPER_08_030,  -- L5214 [a mapper]
        C_ENR.NATURE_PROD_SS_JACENT                                AS COL_A_MAPPER_08_031,  -- L5215 [a mapper]
        C_ENR.SENS_TRANSACTION                                     AS COL_A_MAPPER_08_032,  -- L5216 [a mapper]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L5222 [P1 2.99]
        NVL((C_ENR.MNT_MTM), 0)                                    AS COL_A_MAPPER_08_034,  -- L5223 [a mapper]
        C_ENR.CD_DEVISE_MTM                                        AS COL_A_MAPPER_08_035,  -- L5225 [a mapper]
        C_ENR.PCCO_MTM                                             AS COL_A_MAPPER_08_036,  -- L5226 [a mapper]
        C_ENR.MODELE_ASSIETE_RISQUE                                AS COL_A_MAPPER_08_037,  -- L5227 [a mapper]
        C_ENR.IND_ACCORD_COLLATERISATION                           AS COL_A_MAPPER_08_038,  -- L5228 [a mapper]
        C_ENR.REF_ACCORD_COLLATERISATION                           AS COL_A_MAPPER_08_039,  -- L5229 [a mapper]
        C_ENR.IND_ACCORD_NETTING                                   AS COL_A_MAPPER_08_040,  -- L5230 [a mapper]
        C_ENR.REF_CONTRAT_NETTING                                  AS COL_A_MAPPER_08_041,  -- L5231 [a mapper]
        C_ENR.DEV_CONTRAT_NETTING                                  AS COL_A_MAPPER_08_042,  -- L5232 [a mapper]
        NVL((C_ENR.MT_ASSIETE_INTERNE), 0)                         AS COL_A_MAPPER_08_043,  -- L5233 [a mapper]
        C_ENR.DEV_ASSIETE_INTERNE                                  AS COL_A_MAPPER_08_044,  -- L5234 [a mapper]
        NVL((C_ENR.MT_ASSIETE_REGLEMENTAIRE), 0)                   AS COL_A_MAPPER_08_045,  -- L5235 [a mapper]
        C_ENR.DEV_ASSIETE_REGLEMENTAIRE                            AS COL_A_MAPPER_08_046,  -- L5236 [a mapper]
        ABS(TRUNC(NVL(C_ENR.MATURITE_EFF, 0)))                     AS COL_A_MAPPER_08_047,  -- L5299 [a mapper]
        ABS(MOD(NVL(C_ENR.MATURITE_EFF, 0) *10000,10000))          AS COL_A_MAPPER_08_048,  -- L5301 [a mapper]
        C_ENR.TOP_ENG                                              AS COL_A_MAPPER_08_049,  -- L5302 [a mapper]
        C_ENR.INSTRUMENT_FINANCIER                                 AS P1_3_75,  -- L5304 [P1 3.75]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L5305 [P1 4.42]
        C_ENR.DT_ARRETE                                            AS COL_A_MAPPER_08_052,  -- L5306 [a mapper]
        C_ENR.IND_CCP                                              AS COL_A_MAPPER_08_053,  -- L5330 [a mapper]
        C_ENR.CODE_INDICE_BOURSE                                   AS COL_A_MAPPER_08_054,  -- L5336 [a mapper]
        C_ENR.CODE_PAYS_BOURSE                                     AS COL_A_MAPPER_08_055,  -- L5337 [a mapper]
        NVL((C_ENR.MT_CVA_COMPTA), 0)                              AS COL_A_MAPPER_08_056,  -- L5341 [a mapper]
        C_ENR.DEV_CVA_COMPTA                                       AS COL_A_MAPPER_08_057,  -- L5343 [a mapper]
        C_ENR.IND_RISQ_COLLAT_SPECIF                               AS COL_A_MAPPER_08_058,  -- L5344 [a mapper]
        C_ENR.TYPE_CREDIT_DERIVE                                   AS COL_A_MAPPER_08_059,  -- L5347 [a mapper]
        C_ENR.IND_DENOUEMENT_CDS                                   AS COL_A_MAPPER_08_060,  -- L5348 [a mapper]
        C_ENR.IND_ELLIGIBILITE_CVA                                 AS COL_A_MAPPER_08_061,  -- L5349 [a mapper]
        ABS(TRUNC(NVL(C_ENR.MT_SPREAD, 0)))                        AS COL_A_MAPPER_08_062,  -- L5357 [a mapper]
        NVL((C_ENR.MT_NOTIONNEL_ACH), 0)                           AS COL_A_MAPPER_08_063,  -- L5359 [a mapper]
        C_ENR.DEV_NOTIONNEL_ACH                                    AS COL_A_MAPPER_08_064,  -- L5360 [a mapper]
        NVL((C_ENR.MT_NOTIONNEL_VENDU), 0)                         AS COL_A_MAPPER_08_065,  -- L5361 [a mapper]
        C_ENR.DEV_NOTIONNEL_VENDU                                  AS COL_A_MAPPER_08_066,  -- L5362 [a mapper]
        C_ENR.TYPE_SWAP                                            AS COL_A_MAPPER_08_067,  -- L5363 [a mapper]
        C_ENR.NATURE_OPTION                                        AS COL_A_MAPPER_08_068,  -- L5364 [a mapper]
        C_ENR.IND_CALL_PUT                                         AS P1_10_2,  -- L5365 [P1 10.2]
        C_ENR.TYPE_TAUX_PAYE                                       AS P1_8_1,  -- L5366 [P1 8.1]
        C_ENR.REF_TAUX_PAYE                                        AS P1_8_2,  -- L5367 [P1 8.2]
        C_ENR.TYPE_TAUX_RECU                                       AS P1_8_11,  -- L5368 [P1 8.11]
        C_ENR.REF_TAUX_RECU                                        AS P1_8_12,  -- L5369 [P1 8.12]
        NVL((C_ENR.MT_QUANTITE_RECUE), 0)                          AS COL_A_MAPPER_08_074,  -- L5370 [a mapper]
        C_ENR.UNITE_QUANTITE_RECUE                                 AS COL_A_MAPPER_08_075,  -- L5371 [a mapper]
        NVL((C_ENR.MT_QUANTITE_LIVREE), 0)                         AS COL_A_MAPPER_08_076,  -- L5372 [a mapper]
        C_ENR.UNITE_QUANTITE_LIVREE                                AS COL_A_MAPPER_08_077,  -- L5373 [a mapper]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L5380 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L5382 [P1 22.57]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_08_080,  -- L5383 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_08_081,  -- L5384 [a mapper]
        'ND'                                                       AS COL_A_MAPPER_08_082,  -- L5386 [a mapper]
        C_ENR.NOTE_EXT_ORI                                         AS COL_A_MAPPER_08_083,  -- L5387 [a mapper]
        C_ENR.ORGA_NOTATION_ORIG                                   AS COL_A_MAPPER_08_084,  -- L5388 [a mapper]
        C_ENR.SEG_NOT_ORI                                          AS COL_A_MAPPER_08_085,  -- L5390 [a mapper]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS COL_A_MAPPER_08_086,  -- L5391 [a mapper]
        upper(C_ENR.METH_NOT_ORI)                                  AS COL_A_MAPPER_08_087,  -- L5394 [a mapper]
        '97'                                                       AS COL_A_MAPPER_08_088,  -- L5395 [a mapper]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L5396 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L5397 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS COL_A_MAPPER_08_091,  -- L5398 [a mapper]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L5402 [P1 22.16]
        C_ENR.IND_RMB_ANTICIPE                                     AS COL_A_MAPPER_08_093,  -- L5404 [a mapper]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L5411 [P1 22.66]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS COL_A_MAPPER_08_095,  -- L5414 [a mapper]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L5416 [P1 22.72]
        C_ENR.ELI_OUT_MUT_PROV                                     AS COL_A_MAPPER_08_097,  -- L5418 [a mapper]
        C_ENR.CENTRE_RES                                           AS COL_A_MAPPER_08_098,  -- L5422 [a mapper]
        C_ENR.SYS_GEST_SRC                                         AS COL_A_MAPPER_08_099,  -- L5423 [a mapper]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS COL_A_MAPPER_08_100,  -- L5424 [a mapper]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS COL_A_MAPPER_08_101,  -- L5425 [a mapper]
        C_ENR.IND_ACT_DEP_ORI                                      AS COL_A_MAPPER_08_102,  -- L5426 [a mapper]
        C_ENR.ZONE_APP_COMP                                        AS COL_A_MAPPER_08_103,  -- L5427 [a mapper]
        C_ENR.CD_METH_IFRS9_PD                                     AS COL_A_MAPPER_08_104,  -- L5429 [a mapper]
        C_ENR.CD_METH_IFRS9_LGD                                    AS COL_A_MAPPER_08_105,  -- L5430 [a mapper]
        C_ENR.CD_METH_IFRS9_CCF                                    AS COL_A_MAPPER_08_106,  -- L5431 [a mapper]
        C_ENR.CD_METH_IFRS9_TX                                     AS COL_A_MAPPER_08_107,  -- L5432 [a mapper]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS COL_A_MAPPER_08_108,  -- L5434 [a mapper]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS P1_24_3,  -- L5441 [P1 24.3]
        C_ENR.IND_BCK_TO_BCK                                       AS P1_24_20,  -- L5444 [P1 24.20]
        C_ENR.INTENTION_COUVERTURE                                 AS P1_24_23,  -- L5446 [P1 24.23]
        C_ENR.TYPE_REL_COUVERTURE                                  AS P1_24_24,  -- L5447 [P1 24.24]
        C_ENR.IND_MOBIL_ACTIF                                      AS COL_A_MAPPER_08_113,  -- L5450 [a mapper]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS COL_A_MAPPER_08_114,  -- L5452 [a mapper]
        C_ENR.REF_MOB_ACTIF                                        AS COL_A_MAPPER_08_115,  -- L5454 [a mapper]
        C_ENR.CD_ORGA_MOBIL                                        AS COL_A_MAPPER_08_116,  -- L5455 [a mapper]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS COL_A_MAPPER_08_117,  -- L5459 [a mapper]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS COL_A_MAPPER_08_118,  -- L5461 [a mapper]
        C_ENR.TYPE_CTT_CADDRE                                      AS COL_A_MAPPER_08_119,  -- L5466 [a mapper]
        C_ENR.IND_PROTOCOLE_ISDA_ENTITE                            AS COL_A_MAPPER_08_120,  -- L5467 [a mapper]
        C_ENR.IND_PROTOCOLE_ISDA_CPTY                              AS COL_A_MAPPER_08_121,  -- L5468 [a mapper]
        NVL(C_ENR.MNT_CCNE_JB_VENDUE, 0)                           AS COL_A_MAPPER_08_122,  -- L5470 [a mapper]
        C_ENR.CD_DEV_MNT_CCNE_JB_VENDUE                            AS COL_A_MAPPER_08_123,  -- L5471 [a mapper]
        NVL(C_ENR.MNT_CCNE_JB_ACHETEE, 0)                          AS COL_A_MAPPER_08_124,  -- L5472 [a mapper]
        C_ENR.CD_DEV_MNT_CCNE_JB_ACHETEE                           AS COL_A_MAPPER_08_125,  -- L5473 [a mapper]
        C_ENR.PRD_PAY_TX_RECU                                      AS COL_A_MAPPER_08_126,  -- L5474 [a mapper]
        CASE WHEN C_ENR.TYPE_TAUX_RECU IN ('V','R') THEN NVL(C_ENR.MRG_TX_RECU, 0) ELSE NULL END AS COL_A_MAPPER_08_127,  -- L5475 [a mapper]
        C_ENR.CD_BASE_CALCUL_INT_RECU                              AS COL_A_MAPPER_08_128,  -- L5477 [a mapper]
        C_ENR.PRD_PAY_TX_PAYE                                      AS COL_A_MAPPER_08_129,  -- L5478 [a mapper]
        CASE WHEN C_ENR.TYPE_TAUX_PAYE IN ('V','R') THEN NVL(C_ENR.MRG_TX_PAYE, 0) ELSE NULL END AS COL_A_MAPPER_08_130,  -- L5479 [a mapper]
        C_ENR.CD_BASE_CALCUL_INT_PAYE                              AS COL_A_MAPPER_08_131,  -- L5481 [a mapper]
        'N'                                                        AS P1_30_23,  -- L5486 [P1 30.23]
        'N'                                                        AS COL_A_MAPPER_08_133,  -- L5490 [a mapper]
        C_ENR.FINALITE_OPERATION                                   AS COL_A_MAPPER_08_134,  -- L5492 [a mapper]
        C_ENR.REF_UNIQ_CONT                                        AS COL_A_MAPPER_08_135,  -- L5494 [a mapper]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS COL_A_MAPPER_08_136,  -- L5495 [a mapper]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS COL_A_MAPPER_08_137,  -- L5496 [a mapper]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS COL_A_MAPPER_08_138,  -- L5497 [a mapper]
        NVL(C_ENR.IND_ISF, '2')                                    AS COL_A_MAPPER_08_139,  -- L5498 [a mapper]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS COL_A_MAPPER_08_140,  -- L5501 [a mapper]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS COL_A_MAPPER_08_141,  -- L5502 [a mapper]
        0                                                          AS P1_31_17,  -- L5506 [P1 31.17]
        0                                                          AS P1_31_18,  -- L5508 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L5514 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS COL_A_MAPPER_08_145,  -- L5520 [a mapper]
        C_ENR.MNT_SUBV_HT                                          AS COL_A_MAPPER_08_146,  -- L5524 [a mapper]
        'EUR'                                                      AS P1_29_4,  -- L5525 [P1 29.4]
        'EUR'                                                      AS COL_A_MAPPER_08_148,  -- L5531 [a mapper]
        C_ENR.PCEC_MNT_RISQUE                                      AS COL_A_MAPPER_08_149,  -- L5532 [a mapper]
        C_ENR.MNT_RISQUE                                           AS COL_A_MAPPER_08_150,  -- L5533 [a mapper]
        C_ENR.PCEC_ICNE                                            AS COL_A_MAPPER_08_151,  -- L5536 [a mapper]
        C_ENR.MNT_ICNE                                             AS COL_A_MAPPER_08_152,  -- L5537 [a mapper]
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
