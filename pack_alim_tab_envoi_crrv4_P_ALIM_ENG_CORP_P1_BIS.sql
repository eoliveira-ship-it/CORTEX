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
--   PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite    IN VARCHAR2,
--                                     p_masysdate IN VARCHAR2,
--                                     p_perimetre IN VARCHAR2 DEFAULT 'TOTAL');


-- ---------------------------------------------------------------------
-- 2) CORPS DE LA PROCEDURE (a inserer dans le PACKAGE BODY)
-- ---------------------------------------------------------------------
PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite    IN VARCHAR2,
                                       p_masysdate IN VARCHAR2,
                                       p_perimetre IN VARCHAR2 DEFAULT 'TOTAL')
IS
BEGIN
    ------------------------------------------------------------------
    -- Etape 1 : vider UNIQUEMENT le perimetre traite.
    --   Pas de TRUNCATE : c'est du DDL (commit implicite), les donnees
    --   seraient perdues meme si un INSERT echouait ensuite. Le DELETE
    --   reste dans la transaction et permet les DEUX alimentations
    --   successives prevues par le ticket : NAT02 (M2 BTR) puis
    --   HORS_NAT02 (apres reception des donnees comptables).
    ------------------------------------------------------------------
    IF p_perimetre NOT IN ('NAT02', 'HORS_NAT02', 'TOTAL') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'p_perimetre invalide : '||p_perimetre||
            ' (attendu NAT02, HORS_NAT02 ou TOTAL)');
    END IF;

    IF p_perimetre = 'TOTAL' THEN
        DELETE FROM ENG_CORP_P1_BIS;
    ELSE
        DELETE FROM ENG_CORP_P1_BIS WHERE CD_PERIMETRE = p_perimetre;
    END IF;

    IF p_perimetre IN ('NAT02', 'TOTAL') THEN

    ------------------------------------------------------------------
    -- INSERT #1  (standard NAT02 - spool L590)
    --   colonnes : 190 (dont 57 ancrees --P1) | 178 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_1,
        P1_18_10,
        P1_18_5,
        P1_18_17,
        P1_18_18,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_3,
        P1_4_9,
        P1_4_13,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_4_21,
        P1_4_22,
        P1_4_23,
        P1_3_46,
        P1_3_47,
        P1_3_40,
        P1_3_41,
        P1_3_42,
        P1_3_43,
        P1_3_44,
        P1_3_45,
        P1_5_19,
        P1_5_20,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_29_1,
        P1_29_2,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L597 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L600 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L601 [position V44]
        C_ENR.ID_ENGAGEMENT || '_C'                                AS P1_H_1_11,  -- L603 [position V44]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS P1_1_1,  -- L606 [position V44]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS P1_1_2,  -- L607 [position V44]
        'Y'                                                        AS P1_4_34,  -- L608 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L609 [position V44]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS P1_2_4,  -- L610 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L611 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L612 [P1 2.18]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS P1_2_29,  -- L613 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L614 [position V44]
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD'))      AS P1_3_4,  -- L615 [position V44]
        C_ENR.TX_LGD_PREDICTIF_LOCAL                               AS P1_18_1,  -- L617 [position V44]
        C_ENR.TX_TRC                                               AS P1_18_10,  -- L618 [position V44]
        CASE WHEN NVL((C_ENR.MNT_EAD_TOT), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_EAD_TOT), 0)END AS P1_18_5,  -- L619 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_17,  -- L622 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_18,  -- L623 [position V44]
        C_ENR.DT_RESTRUCTURATION                                   AS P1_21_2,  -- L628 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L629 [position V44]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS P1_4_1,  -- L631 [position V44]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L632 [position V44]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS P1_5_3,  -- L633 [position V44]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L636 [position V44]
        NVL((C_ENR.MNT_RISQUE), 0)                                 AS P1_4_9,  -- L641 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_13,  -- L643 [position V44]
        C_ENR.PCCO_MNT_CRD                                         AS P1_4_18,  -- L649 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN CASE WHEN NVL((C_ENR.MNT_SOLD_K_A), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_SOLD_K_A), 0)END ELSE NULL END AS P1_4_6,  -- L650 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_7,  -- L651 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_4_19,  -- L652 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE NVL((C_ENR.MNT_VTR), 0) END AS P1_4_21,  -- L654 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS P1_4_22,  -- L655 [position V44]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS P1_4_23,  -- L656 [position V44]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS P1_3_46,  -- L658 [position V44]
        C_ENR.CD_RESPECT_COND                                      AS P1_3_47,  -- L659 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_VTR), 0) else NULL END AS P1_3_40,  -- L660 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_VTR else NULL END AS P1_3_41,  -- L662 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_HYPOTHEQUE), 0) else NULL END AS P1_3_42,  -- L663 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_HYPOTH else NULL END AS P1_3_43,  -- L664 [position V44]
        C_ENR.CD_LOC_BIEN                                          AS P1_3_44,  -- L665 [position V44]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS P1_3_45,  -- L666 [position V44]
        Case when NVL(C_ENR.MNT_VR, 0) >= 0 then NVL((C_ENR.MNT_VR), 0) else 0 END AS P1_5_19,  -- L669 [position V44]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS P1_5_20,  -- L671 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L672 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L677 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L685 [P1 4.31]
        Substr(NVL(C_ENR.MATURITE_EFF, 0) ,4,6)                    AS P1_3_20,  -- L693 [position V44]
        NVL(C_ENR.TOP_ENG, 'B')                                    AS P1_4_8,  -- L695 [P1 4.8]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L697 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L698 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L700 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS P1_4_29,  -- L705 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L715 [P1 21.3]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L716 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L717 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L718 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L719 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L720 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L721 [position V44]
        C_ENR.DATE_ENTR_PER_PURG                                   AS P1_21_10,  -- L722 [position V44]
        C_ENR.DATE_SORT_PER_PURG                                   AS P1_21_11,  -- L723 [position V44]
        C_ENR.DATE_ENTR_PER_PROB                                   AS P1_21_12,  -- L724 [position V44]
        C_ENR.DATE_SORT_PER_PROB                                   AS P1_21_13,  -- L725 [position V44]
        C_ENR.DATE_THEO_FIN_FORB                                   AS P1_21_14,  -- L726 [position V44]
        C_ENR.DATE_SORT_EFF_FORB                                   AS P1_21_15,  -- L727 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L728 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L736 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L739 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_1,  -- L740 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L741 [position V44]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L743 [P1 22.5]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L744 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L745 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L747 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L748 [position V44]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS P1_22_55,  -- L751 [position V44]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L753 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L754 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L761 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L762 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L765 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L766 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L767 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L768 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L769 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L770 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L771 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L772 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L773 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L774 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L775 [P1 22.23]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L776 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L777 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L778 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L779 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L780 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L781 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L782 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L783 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L785 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L787 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST<0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L789 [position V44]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L791 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L792 [position V44]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L793 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L803 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L804 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L810 [position V44]
        C_ENR.DATE_FIN_PALL                                        AS P1_22_59,  -- L812 [position V44]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L813 [P1 22.60]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L815 [position V44]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L816 [position V44]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L817 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L821 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L822 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L824 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L825 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L826 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L828 [P1 23.1]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L830 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L831 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L832 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L833 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L834 [position V44]
        C_ENR.PCCO_MNT_CRD || C_ENR.ZONE_APP_COMP                  AS P1_23_7,  -- L835 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L837 [P1 23.8]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L838 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L839 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L840 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L842 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L848 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L851 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L853 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L854 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L858 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L860 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L863 [position V44]
        C_ENR.MNT_IDEMNITE_RES                                     AS P1_29_1,  -- L868 [position V44]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS P1_29_2,  -- L870 [position V44]
        'N'                                                        AS P1_30_22,  -- L878 [position V44]
        'N'                                                        AS P1_30_24,  -- L883 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L890 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L891 [position V44]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L904 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L909 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L917 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L931 [position V44]
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
    --   colonnes : 182 (dont 40 ancrees --P1) | 188 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_1,
        P1_18_10,
        P1_18_5,
        P1_18_17,
        P1_18_18,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_3,
        P1_4_9,
        P1_4_13,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_4_21,
        P1_4_22,
        P1_4_23,
        P1_3_46,
        P1_3_47,
        P1_3_40,
        P1_3_41,
        P1_3_42,
        P1_3_43,
        P1_3_44,
        P1_3_45,
        P1_5_19,
        P1_5_20,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_29_1,
        P1_29_2,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L1096 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L1099 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L1100 [position V44]
        C_ENR.ID_ENGAGEMENT || '_S'                                AS P1_H_1_11,  -- L1102 [position V44]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS P1_1_1,  -- L1105 [position V44]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS P1_1_2,  -- L1106 [position V44]
        'Y'                                                        AS P1_4_34,  -- L1107 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L1108 [position V44]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS P1_2_4,  -- L1109 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L1110 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L1111 [position V44]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS P1_2_29,  -- L1112 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L1113 [position V44]
        NVL(add_months(C_ENR.DT_ARRETE,12), TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,  -- L1114 [position V44]
        C_ENR.TX_LGD_PREDICTIF_LOCAL                               AS P1_18_1,  -- L1117 [position V44]
        C_ENR.TX_TRC                                               AS P1_18_10,  -- L1118 [position V44]
        CASE WHEN NVL((C_ENR.MNT_EAD_TOT), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_EAD_TOT), 0)END AS P1_18_5,  -- L1119 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_17,  -- L1122 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_18,  -- L1123 [position V44]
        C_ENR.DT_RESTRUCTURATION                                   AS P1_21_2,  -- L1129 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L1130 [position V44]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS P1_4_1,  -- L1132 [position V44]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L1133 [position V44]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS P1_5_3,  -- L1134 [position V44]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L1137 [P1 4.3]
        0                                                          AS P1_4_9,  -- L1143 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_13,  -- L1145 [position V44]
        NVL(C_ENR.MNT_SOLD_K_A, 0)                                 AS P1_4_14,  -- L1146 [position V44]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS P1_4_15,  -- L1147 [position V44]
        C_ENR.PCCO_MNT_SOLDE                                       AS P1_4_18,  -- L1150 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN CASE WHEN NVL((C_ENR.MNT_SOLD_K_A), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_SOLD_K_A), 0)END ELSE NULL END AS P1_4_6,  -- L1151 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_7,  -- L1152 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_4_19,  -- L1153 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE NVL((C_ENR.MNT_VTR), 0) END AS P1_4_21,  -- L1155 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS P1_4_22,  -- L1157 [position V44]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS P1_4_23,  -- L1158 [position V44]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS P1_3_46,  -- L1160 [position V44]
        C_ENR.CD_RESPECT_COND                                      AS P1_3_47,  -- L1162 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then 0 else NULL END AS P1_3_40,  -- L1163 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then C_ENR.CD_DEV_VTR else NULL END AS P1_3_41,  -- L1165 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then 0 else NULL END AS P1_3_42,  -- L1166 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then C_ENR.CD_DEV_HYPOTH else NULL END AS P1_3_43,  -- L1167 [position V44]
        C_ENR.CD_LOC_BIEN                                          AS P1_3_44,  -- L1168 [position V44]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS P1_3_45,  -- L1171 [position V44]
        Case when NVL(C_ENR.MNT_VR, 0) >= 0 then NVL((C_ENR.MNT_VR), 0) else 0 END AS P1_5_19,  -- L1174 [position V44]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS P1_5_20,  -- L1176 [position V44]
        C_ENR.cla_comp_ref_act_s                                   AS P1_19_5,  -- L1177 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1182 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1190 [P1 4.31]
        Substr(1 ,4,6)                                             AS P1_3_20,  -- L1198 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L1201 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L1203 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L1204 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L1206 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS P1_4_29,  -- L1211 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L1221 [position V44]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L1222 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L1223 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L1224 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L1225 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L1226 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L1227 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS P1_21_10,  -- L1228 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS P1_21_11,  -- L1229 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS P1_21_12,  -- L1230 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS P1_21_13,  -- L1231 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS P1_21_14,  -- L1232 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS P1_21_15,  -- L1233 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L1234 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L1242 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L1245 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_1,  -- L1246 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L1247 [position V44]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L1249 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L1250 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L1251 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L1253 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L1254 [position V44]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS P1_22_55,  -- L1256 [position V44]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1259 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1260 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1261 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L1262 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L1265 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L1266 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L1267 [position V44]
        'F'                                                        AS P1_22_16,  -- L1268 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L1270 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L1271 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L1272 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L1273 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L1274 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L1275 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L1276 [position V44]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L1277 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L1278 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L1279 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L1280 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L1281 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L1282 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L1283 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L1284 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L1286 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L1289 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L1291 [P1 22.34]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L1293 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L1295 [position V44]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L1296 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1297 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1307 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1308 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L1314 [position V44]
        add_months(C_ENR.DT_ARRETE,12)                             AS P1_22_59,  -- L1316 [position V44]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L1317 [position V44]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L1319 [position V44]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L1320 [position V44]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1321 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L1325 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L1326 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L1328 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L1329 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L1330 [position V44]
        C_ENR.ELI_OUT_MUT_PROV_S                                   AS P1_23_1,  -- L1332 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L1334 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L1335 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9_S                                 AS P1_23_4,  -- L1336 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE_S                             AS P1_23_5,  -- L1337 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L1338 [position V44]
        C_ENR.PCCO_MNT_SOLDE || C_ENR.ZONE_APP_COMP                AS P1_23_7,  -- L1339 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L1341 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L1342 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L1343 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L1344 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L1346 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L1352 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L1355 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L1357 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L1358 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L1364 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L1366 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L1369 [position V44]
        C_ENR.MNT_IDEMNITE_RES                                     AS P1_29_1,  -- L1374 [position V44]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS P1_29_2,  -- L1376 [position V44]
        'N'                                                        AS P1_30_22,  -- L1385 [position V44]
        'N'                                                        AS P1_30_24,  -- L1390 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L1397 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L1398 [position V44]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L1411 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L1416 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1424 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L1438 [position V44]
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
    --   colonnes : 191 (dont 50 ancrees --P1) | 179 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_1,
        P1_18_10,
        P1_18_5,
        P1_18_17,
        P1_18_18,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_3,
        P1_4_5,
        P1_4_9,
        P1_4_13,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_4_21,
        P1_4_22,
        P1_4_23,
        P1_3_46,
        P1_3_47,
        P1_3_40,
        P1_3_41,
        P1_3_42,
        P1_3_43,
        P1_3_44,
        P1_3_45,
        P1_5_19,
        P1_5_20,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_29_1,
        P1_29_2,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L1599 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L1602 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L1603 [position V44]
        C_ENR.ID_ENGAGEMENT || '_C'                                AS P1_H_1_11,  -- L1605 [position V44]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS P1_1_1,  -- L1608 [position V44]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS P1_1_2,  -- L1609 [position V44]
        'Y'                                                        AS P1_4_34,  -- L1610 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L1611 [position V44]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS P1_2_4,  -- L1612 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L1613 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L1614 [position V44]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS P1_2_29,  -- L1615 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L1616 [position V44]
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD'))      AS P1_3_4,  -- L1617 [position V44]
        0                                                          AS P1_18_1,  -- L1619 [position V44]
        0                                                          AS P1_18_10,  -- L1620 [position V44]
        0                                                          AS P1_18_5,  -- L1621 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_17,  -- L1624 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_18,  -- L1625 [position V44]
        C_ENR.DT_RESTRUCTURATION                                   AS P1_21_2,  -- L1630 [position V44]
        'N'                                                        AS P1_5_5,  -- L1631 [position V44]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS P1_4_1,  -- L1635 [position V44]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L1636 [position V44]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS P1_5_3,  -- L1637 [position V44]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L1640 [position V44]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L1643 [position V44]
        NVL((C_ENR.MNT_RISQUE), 0)                                 AS P1_4_9,  -- L1644 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_13,  -- L1645 [position V44]
        C_ENR.PCCO_MNT_CRD                                         AS P1_4_18,  -- L1651 [position V44]
        0                                                          AS P1_4_6,  -- L1652 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_7,  -- L1653 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_4_19,  -- L1654 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 0 END       AS P1_4_21,  -- L1656 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS P1_4_22,  -- L1657 [position V44]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS P1_4_23,  -- L1658 [position V44]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS P1_3_46,  -- L1660 [position V44]
        C_ENR.CD_RESPECT_COND                                      AS P1_3_47,  -- L1662 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_VTR), 0) else NULL END AS P1_3_40,  -- L1663 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_VTR else NULL END AS P1_3_41,  -- L1666 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_HYPOTHEQUE), 0) else NULL END AS P1_3_42,  -- L1667 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_HYPOTH else NULL END AS P1_3_43,  -- L1668 [position V44]
        C_ENR.CD_LOC_BIEN                                          AS P1_3_44,  -- L1669 [position V44]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS P1_3_45,  -- L1672 [position V44]
        0                                                          AS P1_5_19,  -- L1675 [position V44]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS P1_5_20,  -- L1677 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L1678 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1683 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1691 [P1 4.31]
        Substr(NVL(C_ENR.MATURITE_EFF, 0) ,4,6)                    AS P1_3_20,  -- L1699 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L1701 [P1 4.8]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L1703 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L1704 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L1706 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS P1_4_29,  -- L1711 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L1721 [position V44]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L1722 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L1723 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L1724 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L1725 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L1726 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L1727 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS P1_21_10,  -- L1728 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS P1_21_11,  -- L1729 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS P1_21_12,  -- L1730 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS P1_21_13,  -- L1731 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS P1_21_14,  -- L1732 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS P1_21_15,  -- L1733 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L1734 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L1742 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L1745 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_1,  -- L1746 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L1747 [position V44]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L1749 [P1 22.5]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L1750 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L1751 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L1753 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L1754 [position V44]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS P1_22_55,  -- L1757 [position V44]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1760 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1761 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1762 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L1763 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L1764 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L1765 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L1766 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L1767 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L1768 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L1769 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L1770 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L1771 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L1772 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L1773 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L1774 [position V44]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L1775 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L1776 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L1777 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L1778 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L1779 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L1780 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L1781 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L1782 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L1784 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L1786 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L1788 [position V44]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L1791 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L1792 [position V44]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L1793 [position V44]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1804 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1805 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L1811 [P1 22.58]
        C_ENR.DATE_FIN_PALL                                        AS P1_22_59,  -- L1813 [position V44]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L1814 [position V44]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L1816 [position V44]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L1817 [position V44]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1818 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L1822 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L1823 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L1825 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L1826 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L1827 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L1829 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L1831 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L1832 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L1833 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L1834 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L1835 [position V44]
        C_ENR.PCCO_MNT_CRD || C_ENR.ZONE_APP_COMP                  AS P1_23_7,  -- L1836 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L1838 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L1839 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L1840 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L1841 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L1843 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L1849 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L1852 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L1854 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L1855 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L1858 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L1860 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L1863 [position V44]
        C_ENR.MNT_IDEMNITE_RES                                     AS P1_29_1,  -- L1868 [position V44]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS P1_29_2,  -- L1870 [position V44]
        'N'                                                        AS P1_30_22,  -- L1879 [position V44]
        'N'                                                        AS P1_30_24,  -- L1884 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L1891 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L1892 [position V44]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L1905 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L1910 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1918 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L1932 [position V44]
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

    END IF;

    IF p_perimetre IN ('HORS_NAT02', 'TOTAL') THEN

    ------------------------------------------------------------------
    -- INSERT #4  (Hors-NAT TRE100 - spool L2894)
    --   colonnes : 96 (dont 27 ancrees --P1) | 382 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_5_2,
        P1_4_2,
        P1_4_3,
        P1_4_5,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_19_5,
        P1_2_99,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_36,
        P1_22_44,
        P1_22_45,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L2903 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L2905 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L2906 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L2908 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L2911 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L2912 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L2913 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L2914 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L2915 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L2916 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L2917 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L2918 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L2919 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L2920 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L2934 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L2938 [P1 5.5]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L2941 [P1 5.2]
        NVL((C_ENR.MNT_SOLDE), 0)                                  AS P1_4_2,  -- L2943 [P1 4.2]
        C_ENR.CD_DEVISE_SOLDE                                      AS P1_4_3,  -- L2951 [position V44]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L2955 [position V44]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L2960 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L2965 [position V44]
        C_ENR.PCCO_MNT_SOLDE                                       AS P1_4_18,  -- L2970 [position V44]
        C_ENR.cla_comp_ref_act_s                                   AS P1_19_5,  -- L3007 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3043 [P1 2.99]
        ABS(TRUNC(C_ENR.MATURITE_EFF))                             AS P1_3_20,  -- L3118 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L3120 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L3123 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L3124 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L3199 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L3201 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L3202 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L3203 [position V44]
        NVL(C_ENR.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L3205 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L3206 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L3207 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L3209 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L3210 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_55,  -- L3213 [position V44]
        '97'                                                       AS P1_22_7,  -- L3214 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3215 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3222 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L3223 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L3227 [position V44]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L3239 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L3240 [P1 22.45]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L3253 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L3256 [position V44]
        C_ENR.ELI_OUT_MUT_PROV_S                                   AS P1_23_1,  -- L3258 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L3268 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L3269 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9_S                                 AS P1_23_4,  -- L3270 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE_S                             AS P1_23_5,  -- L3271 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L3272 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L3273 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L3275 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L3276 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L3277 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L3278 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L3280 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L3283 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L3284 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L3286 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L3287 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L3291 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L3293 [position V44]
        'N'                                                        AS P1_30_22,  -- L3306 [position V44]
        'N'                                                        AS P1_30_24,  -- L3311 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L3318 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L3319 [position V44]
        0                                                          AS P1_31_17,  -- L3327 [P1 31.17]
        0                                                          AS P1_31_18,  -- L3329 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3334 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L3341 [position V44]
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
    --   colonnes : 179 (dont 59 ancrees --P1) | 219 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_17,
        P1_18_18,
        P1_21_1,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_4,
        P1_4_5,
        P1_4_9,
        P1_4_13,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_19_5,
        P1_3_52,
        P1_3_53,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_30,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_21_17,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
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
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_28_2,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L3472 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L3476 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L3477 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L3479 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L3482 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L3484 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L3485 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L3486 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L3487 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L3488 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L3489 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L3490 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L3491 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L3494 [position V44]
        C_ENR.DEVISE_EAD                                           AS P1_18_17,  -- L3507 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L3508 [position V44]
        C_ENR.TOP_RESTRUCTURATION                                  AS P1_21_1,  -- L3510 [position V44]
        (CASE WHEN C_ENR.TOP_RESTRUCTURATION = 'O' THEN C_ENR.DT_RESTRUCTURATION ELSE NULL END) AS P1_21_2,  -- L3512 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L3517 [position V44]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_4_1,  -- L3518 [position V44]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L3519 [P1 5.2]
        (CASE WHEN C_ENR.TOP_ENG_DOUTEUX = 'Y' THEN C_ENR.DT_ENG_DOUTEUX ELSE NULL END) AS P1_5_3,  -- L3520 [P1 5.3]
        (CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' AND NVL(C_ENR.MNT_SOLDE, 0) >=0 THEN NVL((C_ENR.MNT_SOLDE), 0) ELSE NULL END ) AS P1_4_4,  -- L3534 [P1 4.4]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L3541 [position V44]
        NVL((C_ENR.MNT_CRD), 0)                                    AS P1_4_9,  -- L3550 [P1 4.9]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS P1_4_13,  -- L3552 [P1 4.13]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L3553 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L3555 [position V44]
        C_ENR.PCCO_MNT_CRD                                         AS P1_4_18,  -- L3560 [position V44]
        (CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL((C_ENR.MNT_INT_RD), 0) ELSE NULL END ) AS P1_4_6,  -- L3561 [position V44]
        ( CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL(C_ENR.CD_DEVISE_INT_RD, 'EUR') ELSE NULL END ) AS P1_4_7,  -- L3568 [P1 4.7]
        C_ENR.PCCO_INT_RD                                          AS P1_4_19,  -- L3578 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L3595 [position V44]
        NVL(C_ENR.MNT_MTM, 0)                                      AS P1_3_52,  -- L3599 [position V44]
        NVL(C_ENR.CD_DEV_MNT_MTM, 'EUR')                           AS P1_3_53,  -- L3600 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3610 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L3621 [P1 4.31]
        ABS(TRUNC(NVL(C_ENR.MATURITE_EFF, 0)))                     AS P1_3_20,  -- L3631 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L3634 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L3639 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L3640 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L3642 [position V44]
        C_ENR.TX_ELBE                                              AS P1_4_30,  -- L3646 [position V44]
        C_ENR.IND_CREANCE_TITRI                                    AS P1_4_29,  -- L3649 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L3659 [position V44]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L3661 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L3662 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L3663 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L3664 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L3665 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L3666 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS P1_21_10,  -- L3667 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS P1_21_11,  -- L3668 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS P1_21_12,  -- L3669 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS P1_21_13,  -- L3670 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS P1_21_14,  -- L3671 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS P1_21_15,  -- L3672 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L3673 [position V44]
        C_ENR.CD_MOTIF_PL_NPL                                      AS P1_21_17,  -- L3676 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L3681 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L3684 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L3685 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L3686 [position V44]
        'ND'                                                       AS P1_22_5,  -- L3688 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L3689 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L3690 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L3692 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L3693 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_55,  -- L3696 [position V44]
        '97'                                                       AS P1_22_7,  -- L3697 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3698 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3699 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L3700 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L3703 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L3704 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L3707 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L3708 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L3709 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L3710 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L3711 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L3712 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L3713 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L3714 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L3715 [position V44]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L3716 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L3717 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L3718 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L3719 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L3722 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L3724 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L3725 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L3726 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L3729 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L3731 [position V44]
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
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L3764 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L3765 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L3768 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L3769 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L3771 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L3774 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L3776 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L3777 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L3778 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L3779 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L3780 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L3781 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L3783 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L3784 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L3785 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L3786 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L3788 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L3793 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L3794 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L3796 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L3797 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L3801 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L3803 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L3806 [position V44]
        C_ENR.IND_SPONSOR_FIN                                      AS P1_28_2,  -- L3808 [position V44]
        'N'                                                        AS P1_30_22,  -- L3820 [position V44]
        'N'                                                        AS P1_30_24,  -- L3825 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L3832 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L3833 [position V44]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) AS P1_31_17,  -- L3846 [P1 31.17]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) AS P1_31_18,  -- L3848 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3853 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L3867 [position V44]
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
    --   colonnes : 101 (dont 28 ancrees --P1) | 405 fillers -> NULL | 2 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_5_2,
        P1_19_5,
        P1_3_56,
        P1_3_50,
        P1_3_51,
        P1_3_52,
        P1_3_53,
        P1_3_54,
        P1_3_55,
        P1_3_61,
        P1_3_8,
        P1_3_9,
        P1_3_31,
        P1_12_1,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_3_75,
        P1_4_42,
        P1_3_3,
        P1_21_6,
        P1_21_16,
        P1_21_17,
        P1_22_56,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_36,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_24_3,
        P1_24_4,
        P1_24_5,
        P1_24_6,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L4035 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L4039 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L4040 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L4042 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L4045 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L4047 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L4048 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L4049 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L4050 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L4051 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L4052 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L4053 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L4054 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L4057 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L4071 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4075 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L4077 [P1 5.2]
        C_ENR.CD_CPT_ACTIF_IAS                                     AS P1_19_5,  -- L4138 [position V44]
        C_ENR.PCCO_ACQUISITION                                     AS P1_3_56,  -- L4139 [position V44]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_3_50,  -- L4140 [position V44]
        NVL(C_ENR.CD_DEVISE_ACQUISITION, 'EUR')                    AS P1_3_51,  -- L4141 [position V44]
        NVL(C_ENR.MNT_MTM, 0)                                      AS P1_3_52,  -- L4142 [position V44]
        C_ENR.CD_DEVISE_MTM                                        AS P1_3_53,  -- L4144 [position V44]
        NVL(C_ENR.MNT_COUT_AMORTI, 0)                              AS P1_3_54,  -- L4145 [position V44]
        NVL(C_ENR.CD_DEV_COUT_AMORTI, 'EUR')                       AS P1_3_55,  -- L4146 [position V44]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_3_61,  -- L4159 [position V44]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS P1_3_8,  -- L4161 [position V44]
        C_ENR.CD_DEVISE_NOMINAL                                    AS P1_3_9,  -- L4162 [position V44]
        C_ENR.PCCO_NOMINAL                                         AS P1_3_31,  -- L4163 [position V44]
        C_ENR.NATURE_PROD_SS_JACENT                                AS P1_12_1,  -- L4164 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4171 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4234 [P1 4.31]
        ABS(TRUNC(C_ENR.MATURITE_EFF))                             AS P1_3_20,  -- L4249 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L4252 [position V44]
        C_ENR.INSTRUMENT_FINANCIER                                 AS P1_3_75,  -- L4254 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L4255 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L4256 [position V44]
        NVL(C_ENR.IND_CRE_PERF, 'PE')                              AS P1_21_6,  -- L4329 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L4331 [position V44]
        C_ENR.CD_MOTIF_PL_NPL                                      AS P1_21_17,  -- L4332 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L4337 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L4341 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_51,  -- L4342 [position V44]
        'ND'                                                       AS P1_22_5,  -- L4346 [position V44]
        '97'                                                       AS P1_22_7,  -- L4352 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4353 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4354 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L4355 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L4359 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L4365 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L4367 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L4369 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L4371 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L4372 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L4373 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L4374 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L4375 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L4376 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L4378 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L4379 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L4380 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L4381 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L4383 [position V44]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS P1_24_3,  -- L4385 [position V44]
        C_ENR.COMPLEXITE_PRODUIT                                   AS P1_24_4,  -- L4386 [position V44]
        C_ENR.IND_ACTIF_COTE                                       AS P1_24_5,  -- L4387 [position V44]
        C_ENR.NB_TITRES                                            AS P1_24_6,  -- L4388 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L4413 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L4414 [P1 22.11]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L4416 [P1 26.3]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L4417 [P1 26.4]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L4420 [P1 27.3]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L4422 [P1 27.4]
        'N'                                                        AS P1_30_22,  -- L4433 [position V44]
        'N'                                                        AS P1_30_24,  -- L4438 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L4445 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L4446 [position V44]
        0                                                          AS P1_31_17,  -- L4454 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4456 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4461 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L4468 [position V44]
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
    --   colonnes : 100 (dont 23 ancrees --P1) | 259 fillers -> NULL | 2 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_4_5,
        P1_4_14,
        P1_4_15,
        P1_4_16,
        P1_4_17,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_5_7,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_36,
        P1_22_66,
        P1_22_67,
        P1_22_68,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_30_22,
        P1_30_24,
        P1_31_4,
        P1_31_5,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_29,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L4615 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L4619 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L4620 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L4622 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L4625 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L4626 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L4627 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L4628 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L4629 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L4630 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L4631 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L4632 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L4633 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L4634 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L4648 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4652 [P1 5.5]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_4_1,  -- L4653 [P1 4.1]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L4654 [P1 5.2]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L4668 [position V44]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L4673 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L4678 [position V44]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS P1_4_16,  -- L4679 [position V44]
        C_ENR.CD_DEVISE_NOMINAL                                    AS P1_4_17,  -- L4680 [position V44]
        C_ENR.PCCO_NOMINAL                                         AS P1_4_18,  -- L4681 [position V44]
        NVL((C_ENR.MNT_INT_RD), 0)                                 AS P1_4_6,  -- L4682 [position V44]
        C_ENR.CD_DEVISE_INT_RD                                     AS P1_4_7,  -- L4683 [position V44]
        C_ENR.PCCO_INT_RD                                          AS P1_4_19,  -- L4684 [position V44]
        C_ENR.ID_TIERS_CALC                                        AS P1_5_7,  -- L4694 [position V44]
        C_ENR.CLA_COMP_REF_ACT                                     AS P1_19_5,  -- L4703 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4733 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4757 [P1 4.31]
        ABS(TRUNC(NVL(C_ENR.MATURITE_EFF, 0)))                     AS P1_3_20,  -- L4776 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L4779 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L4782 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L4783 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L4790 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L4792 [P1 22.57]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L4793 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L4794 [position V44]
        'ND'                                                       AS P1_22_5,  -- L4796 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L4797 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L4798 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L4800 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L4801 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_55,  -- L4804 [position V44]
        '97'                                                       AS P1_22_7,  -- L4805 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4806 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4807 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L4808 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L4812 [position V44]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L4819 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L4821 [position V44]
        C_ENR.EVT_DECL_GAR                                         AS P1_22_68,  -- L4822 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L4824 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L4825 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L4827 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L4829 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L4839 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L4840 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L4841 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L4842 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L4843 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L4844 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L4846 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L4847 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L4848 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L4849 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L4851 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L4854 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L4855 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L4857 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L4858 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L4862 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L4864 [position V44]
        'N'                                                        AS P1_30_22,  -- L4877 [position V44]
        'N'                                                        AS P1_30_24,  -- L4882 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_4,  -- L4889 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_5,  -- L4890 [position V44]
        0                                                          AS P1_31_17,  -- L4898 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4900 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4906 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_29,  -- L4912 [position V44]
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
    --   colonnes : 116 (dont 35 ancrees --P1) | 318 fillers -> NULL | 3 signes absorbes par le NUMBER
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
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_5_2,
        P1_4_5,
        P1_4_14,
        P1_4_15,
        P1_19_5,
        P1_3_8,
        P1_3_9,
        P1_3_31,
        P1_12_1,
        P1_3_7,
        P1_2_99,
        P1_3_80,
        P1_3_81,
        P1_3_82,
        P1_3_83,
        P1_3_15,
        P1_13_10,
        P1_3_16,
        P1_3_17,
        P1_3_19,
        P1_3_84,
        P1_3_85,
        P1_3_72,
        P1_3_73,
        P1_3_20,
        P1_4_8,
        P1_3_75,
        P1_4_42,
        P1_3_3,
        P1_3_36,
        P1_15_1,
        P1_15_2,
        P1_3_86,
        P1_3_87,
        P1_3_88,
        P1_11_1,
        P1_3_76,
        P1_3_77,
        P1_3_10,
        P1_3_12,
        P1_8_2,
        P1_10_2,
        P1_8_1,
        P1_8_11,
        P1_8_12,
        P1_20_3,
        P1_10_4,
        P1_22_56,
        P1_22_57,
        P1_22_52,
        P1_22_54,
        P1_22_8,
        P1_22_9,
        P1_22_13,
        P1_22_16,
        P1_22_38,
        P1_22_66,
        P1_22_73,
        P1_22_72,
        P1_23_3,
        P1_23_7,
        P1_24_6,
        P1_24_3,
        P1_24_20,
        P1_24_23,
        P1_24_24,
        P1_26_99,
        P1_27_99,
        P1_30_4,
        P1_30_14,
        P1_30_17,
        P1_30_20,
        P1_30_22,
        P1_30_23,
        P1_30_26,
        P1_31_2,
        P1_31_8,
        P1_31_9,
        P1_31_14,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_3,
        P1_29_4,
        P1_50_2,
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
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L5070 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L5074 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L5075 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L5077 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L5080 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L5082 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L5083 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L5084 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L5085 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L5086 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L5087 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L5088 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L5089 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L5092 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L5106 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L5111 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L5114 [P1 5.2]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L5130 [position V44]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L5135 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L5140 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L5185 [position V44]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS P1_3_8,  -- L5211 [position V44]
        C_ENR.CD_DEVISE_NOMINAL                                    AS P1_3_9,  -- L5213 [position V44]
        C_ENR.PCCO_NOMINAL                                         AS P1_3_31,  -- L5214 [position V44]
        C_ENR.NATURE_PROD_SS_JACENT                                AS P1_12_1,  -- L5215 [position V44]
        C_ENR.SENS_TRANSACTION                                     AS P1_3_7,  -- L5216 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L5222 [P1 2.99]
        NVL((C_ENR.MNT_MTM), 0)                                    AS P1_3_80,  -- L5223 [position V44]
        C_ENR.CD_DEVISE_MTM                                        AS P1_3_81,  -- L5225 [position V44]
        C_ENR.PCCO_MTM                                             AS P1_3_82,  -- L5226 [position V44]
        C_ENR.MODELE_ASSIETE_RISQUE                                AS P1_3_83,  -- L5227 [position V44]
        C_ENR.IND_ACCORD_COLLATERISATION                           AS P1_3_15,  -- L5228 [position V44]
        C_ENR.REF_ACCORD_COLLATERISATION                           AS P1_13_10,  -- L5229 [position V44]
        C_ENR.IND_ACCORD_NETTING                                   AS P1_3_16,  -- L5230 [position V44]
        C_ENR.REF_CONTRAT_NETTING                                  AS P1_3_17,  -- L5231 [position V44]
        C_ENR.DEV_CONTRAT_NETTING                                  AS P1_3_19,  -- L5232 [position V44]
        NVL((C_ENR.MT_ASSIETE_INTERNE), 0)                         AS P1_3_84,  -- L5233 [position V44]
        C_ENR.DEV_ASSIETE_INTERNE                                  AS P1_3_85,  -- L5234 [position V44]
        NVL((C_ENR.MT_ASSIETE_REGLEMENTAIRE), 0)                   AS P1_3_72,  -- L5235 [position V44]
        C_ENR.DEV_ASSIETE_REGLEMENTAIRE                            AS P1_3_73,  -- L5236 [position V44]
        ABS(TRUNC(NVL(C_ENR.MATURITE_EFF, 0)))                     AS P1_3_20,  -- L5299 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L5302 [position V44]
        C_ENR.INSTRUMENT_FINANCIER                                 AS P1_3_75,  -- L5304 [P1 3.75]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L5305 [P1 4.42]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L5306 [position V44]
        C_ENR.IND_CCP                                              AS P1_3_36,  -- L5330 [position V44]
        C_ENR.CODE_INDICE_BOURSE                                   AS P1_15_1,  -- L5336 [position V44]
        C_ENR.CODE_PAYS_BOURSE                                     AS P1_15_2,  -- L5337 [position V44]
        NVL((C_ENR.MT_CVA_COMPTA), 0)                              AS P1_3_86,  -- L5341 [position V44]
        C_ENR.DEV_CVA_COMPTA                                       AS P1_3_87,  -- L5343 [position V44]
        C_ENR.IND_RISQ_COLLAT_SPECIF                               AS P1_3_88,  -- L5344 [position V44]
        C_ENR.TYPE_CREDIT_DERIVE                                   AS P1_11_1,  -- L5347 [position V44]
        C_ENR.IND_DENOUEMENT_CDS                                   AS P1_3_76,  -- L5348 [position V44]
        C_ENR.IND_ELLIGIBILITE_CVA                                 AS P1_3_77,  -- L5349 [position V44]
        ABS(TRUNC(NVL(C_ENR.MT_SPREAD, 0)))                        AS P1_3_10,  -- L5357 [position V44]
        C_ENR.DEV_NOTIONNEL_ACH                                    AS P1_3_12,  -- L5360 [position V44]
        C_ENR.TYPE_SWAP                                            AS P1_8_2,  -- L5363 [position V44]
        C_ENR.IND_CALL_PUT                                         AS P1_10_2,  -- L5365 [P1 10.2]
        C_ENR.TYPE_TAUX_PAYE                                       AS P1_8_1,  -- L5366 [P1 8.1]
        C_ENR.TYPE_TAUX_RECU                                       AS P1_8_11,  -- L5368 [P1 8.11]
        C_ENR.REF_TAUX_RECU                                        AS P1_8_12,  -- L5369 [P1 8.12]
        C_ENR.UNITE_QUANTITE_RECUE                                 AS P1_20_3,  -- L5371 [position V44]
        C_ENR.UNITE_QUANTITE_LIVREE                                AS P1_10_4,  -- L5373 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L5380 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L5382 [P1 22.57]
        'ND'                                                       AS P1_22_52,  -- L5386 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_54,  -- L5388 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_8,  -- L5394 [position V44]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L5397 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_13,  -- L5398 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L5402 [P1 22.16]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_38,  -- L5404 [position V44]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L5411 [P1 22.66]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_73,  -- L5414 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L5416 [P1 22.72]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_3,  -- L5418 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_7,  -- L5424 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_6,  -- L5434 [position V44]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS P1_24_3,  -- L5441 [P1 24.3]
        C_ENR.IND_BCK_TO_BCK                                       AS P1_24_20,  -- L5444 [P1 24.20]
        C_ENR.INTENTION_COUVERTURE                                 AS P1_24_23,  -- L5446 [P1 24.23]
        C_ENR.TYPE_REL_COUVERTURE                                  AS P1_24_24,  -- L5447 [P1 24.24]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_99,  -- L5450 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_99,  -- L5459 [position V44]
        C_ENR.TYPE_CTT_CADDRE                                      AS P1_30_4,  -- L5466 [position V44]
        C_ENR.CD_DEV_MNT_CCNE_JB_VENDUE                            AS P1_30_14,  -- L5471 [position V44]
        C_ENR.CD_DEV_MNT_CCNE_JB_ACHETEE                           AS P1_30_17,  -- L5473 [position V44]
        C_ENR.CD_BASE_CALCUL_INT_RECU                              AS P1_30_20,  -- L5477 [position V44]
        C_ENR.CD_BASE_CALCUL_INT_PAYE                              AS P1_30_22,  -- L5481 [position V44]
        'N'                                                        AS P1_30_23,  -- L5486 [P1 30.23]
        'N'                                                        AS P1_30_26,  -- L5490 [position V44]
        C_ENR.FINALITE_OPERATION                                   AS P1_31_2,  -- L5492 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_8,  -- L5497 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_9,  -- L5498 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_14,  -- L5502 [position V44]
        0                                                          AS P1_31_17,  -- L5506 [P1 31.17]
        0                                                          AS P1_31_18,  -- L5508 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L5514 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_29_3,  -- L5520 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L5525 [P1 29.4]
        'EUR'                                                      AS P1_50_2,  -- L5531 [position V44]
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

    END IF;

    COMMIT;
END P_ALIM_ENG_CORP_P1_BIS;
