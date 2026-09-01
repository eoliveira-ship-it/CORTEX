-- =====================================================================
-- SIRL-1224 : ENG_CORP_P1_BIS -- ficheiro unico de testes
--
-- Correr no SQL Developer com F5 (Run Script), nao F9.
--
-- Ordem: 1. ENG_CORP_P1_BIS.sql            (cria a tabela)
--        2. pack_alim_tab_envoi_crrv4.sql  (compila o package)
--        3. este ficheiro
--
-- T1 ESTRUTURA   a tabela na base e a que o DDL manda?
-- T2 PACKAGE     o codigo compilado e o do repositorio?
-- T3 VOLUMETRIA  o nr de linhas e o que os 8 WHERE do spool devolvem?
-- T4 ROUND-TRIP  o valor guardado reproduz o que o spool escreve hoje?
-- =====================================================================
SET SERVEROUTPUT ON
SET LINESIZE 32000
SET PAGESIZE 200

-- ---------------------------------------------------------------------
-- T1  ESTRUTURA DA TABELA
-- ---------------------------------------------------------------------
COLUMN column_name FORMAT A14
COLUMN esperado    FORMAT A14
COLUMN instalado   FORMAT A14

-- T1.1  contagem : esperado 666 colunas
SELECT 666 AS esperado_colunas, COUNT(*) AS instalado_colunas,
       CASE WHEN COUNT(*) = 666 THEN 'OK' ELSE 'FALHA' END AS veredicto
  FROM ALL_TAB_COLUMNS WHERE table_name = 'ENG_CORP_P1_BIS';

-- T1.2  as colunas alargadas (as que causaram ORA-01438 ou perda de
--       decimais). Um FALHA aqui = tabela criada com um DDL antigo.
SELECT t.column_name, t.esperado,
       'NUMBER('||c.data_precision||','||c.data_scale||')' AS instalado,
       CASE WHEN 'NUMBER('||c.data_precision||','||c.data_scale||')' = t.esperado
            THEN 'OK' ELSE 'FALHA' END AS veredicto
  FROM (
        SELECT 'P1_18_1'    AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_18_10'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_21_30'   AS column_name, 'NUMBER(21,2)'  AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_21_43'   AS column_name, 'NUMBER(24,9)'  AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_21_60'   AS column_name, 'NUMBER(24,9)'  AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_21_81'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_21_82'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_22_19'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_22_23'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_22_24'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_22_27'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_22_28'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_22_29'   AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_3_20'    AS column_name, 'NUMBER(18,10)' AS esperado FROM DUAL
        UNION ALL
        SELECT 'P1_4_30'    AS column_name, 'NUMBER(14,10)' AS esperado FROM DUAL
       ) t
  LEFT JOIN ALL_TAB_COLUMNS c ON c.table_name  = 'ENG_CORP_P1_BIS'
                             AND c.column_name = t.column_name
 ORDER BY t.column_name;

-- ---------------------------------------------------------------------
-- T2  PACKAGE INSTALADO
--     Nao se adivinha o que esta compilado: le-se o dicionario. Um
--     package obsoleto ja produziu P1_3_20 = 520547 em vez de 2,95.
-- ---------------------------------------------------------------------
COLUMN object_name   FORMAT A34
COLUMN argument_name FORMAT A14

-- T2.1  estado e data de compilacao (STATUS tem de ser VALID)
SELECT object_name, object_type, status,
       TO_CHAR(last_ddl_time,'YYYY-MM-DD HH24:MI') AS compilado_em
  FROM ALL_OBJECTS WHERE object_name = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW' ORDER BY object_type;

-- T2.2  assinatura : a procedure atual tem 3 parametros
SELECT position, argument_name, data_type
  FROM ALL_ARGUMENTS
 WHERE object_name = 'P_ALIM_ENG_CORP_P1_BIS' AND package_name = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW'
 ORDER BY position;

-- ---------------------------------------------------------------------
-- T3  VOLUMETRIA : esperado (fonte) vs inserido (tabela)
--     Os 8 SELECT abaixo sao os 8 WHERE dos 8 INSERT da procedure,
--     copiados do spool. ECART tem de ser 0.
-- ---------------------------------------------------------------------
DECLARE
    v_masysdate VARCHAR2(12) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MI');
    v_t0        TIMESTAMP    := SYSTIMESTAMP;
BEGIN
    -- p_perimetre : 'NAT02' (M2 BTR) | 'HORS_NAT02' (apos compta) | 'TOTAL'
    pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS('TOTAL', v_masysdate, 'TOTAL');
    DBMS_OUTPUT.PUT_LINE('procedure OK - duracao : '||TO_CHAR(SYSTIMESTAMP - v_t0));
END;
/

WITH esperado AS (
    SELECT 1 AS variante, 'NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 )
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
    UNION ALL
    SELECT 2 AS variante, 'NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND NVL(C_ENR.MNT_SOLD_K_A,0) >= 1
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' )
    UNION ALL
    SELECT 3 AS variante, 'NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' )
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 )
    UNION ALL
    SELECT 4 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.FLAG_HN = 'O'
      AND C_ENR.CD_TYPE_RISQUE IN ('TRE100')
    UNION ALL
    SELECT 5 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.FLAG_HN = 'O'
      AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5')
    UNION ALL
    SELECT 6 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.FLAG_HN = 'O'
      AND C_ENR.CD_TYPE_RISQUE IN ('EQU101')
    UNION ALL
    SELECT 7 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.FLAG_HN = 'O'
      AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101')
    UNION ALL
    SELECT 8 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.FLAG_HN = 'O'
      AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%'
)
SELECT e.perimetre,
       SUM(e.nb) AS esperado,
       NVL(MAX(i.nb),0) AS inserido,
       SUM(e.nb) - NVL(MAX(i.nb),0) AS ecart
  FROM esperado e
  -- LEFT JOIN: se um perimetro nao foi alimentado tem de aparecer com ecart
  LEFT JOIN (SELECT CD_PERIMETRE, COUNT(*) AS nb
          FROM ENG_CORP_P1_BIS GROUP BY CD_PERIMETRE) i
    ON i.CD_PERIMETRE = e.perimetre
 GROUP BY e.perimetre ORDER BY 1;

-- ---------------------------------------------------------------------
-- T4  ROUND-TRIP -- o teste central
--
-- Para cada coluna corre-se, na MESMA linha e na MESMA data:
--    a expressao do spool sobre ENG_CORP_P1      (A)
--    a mesma expressao    sobre ENG_CORP_P1_BIS  (B)
-- Se a conversao esta certa as duas strings sao iguais: o valor guardado,
-- reformatado, reproduz o que o spool escreve hoje.
--
-- Sao 176 colunas x 200 engajamentos.
-- Coluna de resultado VAZIA = engajamento totalmente conforme.
-- ---------------------------------------------------------------------
COLUMN id_engagement FORMAT A26
COLUMN colunas_que_nao_reproduzem FORMAT A120

SELECT C_ENR.ID_ENGAGEMENT,
         CASE WHEN NVL(to_char(C_ENR.dt_arrete, 'YYYYMMDD'),'@') <> NVL(to_char(B.P1_H_0_1, 'YYYYMMDD'),'@')
              THEN 'P1_H_0_1 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5),'@') <> NVL(RPAD(NVL(B.P1_H_0_2,' '), 5),'@')
              THEN 'P1_H_0_2 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.APPLI_SOURCE,'C_BTR'), 12),'@') <> NVL(RPAD(NVL(B.P1_H_0_3,'C_BTR'), 12),'@')
              THEN 'P1_H_0_3 ' END ||
         CASE WHEN NVL('M','@') <> NVL(B.P1_H_0_4,'@')
              THEN 'P1_H_0_4 ' END ||
         CASE WHEN NVL('P1','@') <> NVL(B.P1_H_0_6,'@')
              THEN 'P1_H_0_6 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20),'@') <> NVL(RPAD(NVL(B.P1_H_1_1, ' '), 20),'@')
              THEN 'P1_H_1_1 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30),'@') <> NVL(RPAD(NVL(B.P1_H_1_4, ' '), 30),'@')
              THEN 'P1_H_1_4 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30),'@') <> NVL(RPAD(NVL(B.P1_H_1_6, ' '), 30),'@')
              THEN 'P1_H_1_6 ' END ||
         CASE WHEN NVL(RPAD(C_ENR.ID_ENGAGEMENT || '_C',40),'@') <> NVL(RPAD(B.P1_H_1_11,40),'@')
              THEN 'P1_H_1_11 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_METHODO_BALE2, 'STD'),7),'@') <> NVL(RPAD(B.P1_1_1,7),'@')
              THEN 'P1_1_1 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR, '01'),2),'@') <> NVL(RPAD(B.P1_1_2,2),'@')
              THEN 'P1_1_2 ' END ||
         CASE WHEN NVL('Y','@') <> NVL(B.P1_4_34,'@')
              THEN 'P1_4_34 ' END ||
         CASE WHEN NVL(RPAD(C_ENR.CD_TYPE_RISQUE,6),'@') <> NVL(RPAD(B.P1_2_0,6),'@')
              THEN 'P1_2_0 ' END ||
         CASE WHEN NVL(NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B'),'@') <> NVL(NVL(B.P1_2_4,'B'),'@')
              THEN 'P1_2_4 ' END ||
         CASE WHEN NVL(RPAD(C_ENR.CD_LIGNE_METIER,5),'@') <> NVL(RPAD(B.P1_2_6,5),'@')
              THEN 'P1_2_6 ' END ||
         CASE WHEN NVL(RPAD(C_ENR.CD_PORTEFEUILLE_BALE2,3),'@') <> NVL(RPAD(B.P1_2_18,3),'@')
              THEN 'P1_2_18 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CD_NATURE_OPE, 'NA020'),12),'@') <> NVL(RPAD(nvl(B.P1_2_29, 'NA020'),12),'@')
              THEN 'P1_2_29 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_3_2, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_3_2 ' END ||
         CASE WHEN NVL(NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'),'99990630'),'@') <> NVL(NVL(TO_CHAR(B.P1_3_4, 'YYYYMMDD'),'99990630'),'@')
              THEN 'P1_3_4 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_LGD_PREDICTIF_LOCAL),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_18_1),'@')
              THEN 'P1_18_1 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_TRC),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_18_10),'@')
              THEN 'P1_18_10 ' END ||
         CASE WHEN NVL(pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.MNT_EAD_TOT),0) <0 THEN 0 ELSE nvl((C_ENR.MNT_EAD_TOT),0)END ),'@') <> NVL(pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((B.P1_18_5),0) <0 THEN 0 ELSE nvl((B.P1_18_5),0)END ),'@')
              THEN 'P1_18_5 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3),'@') <> NVL(RPAD(NVL(B.P1_18_17, ' '), 3),'@')
              THEN 'P1_18_17 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3),'@') <> NVL(RPAD(NVL(B.P1_18_18, ' '), 3),'@')
              THEN 'P1_18_18 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_2, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_2 ' END ||
         CASE WHEN NVL(NVL(C_ENR.CD_ARR_PAIEMENT, 'N'),'@') <> NVL(B.P1_5_5,'@')
              THEN 'P1_5_5 ' END ||
         CASE WHEN NVL(NVL(C_ENR.CD_IMP_PRUDENT, 'N'),'@') <> NVL(B.P1_4_1,'@')
              THEN 'P1_4_1 ' END ||
         CASE WHEN NVL(NVL(C_ENR.TOP_ENG_DOUTEUX, 'N'),'@') <> NVL(B.P1_5_2,'@')
              THEN 'P1_5_2 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR'), 3),'@') <> NVL(RPAD(B.P1_4_3, 3),'@')
              THEN 'P1_4_3 ' END ||
         CASE WHEN NVL(pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_RISQUE),0)),'@') <> NVL(pack_utilitaire.f_format_montant_bis2(nvl((B.P1_4_9),0)),'@')
              THEN 'P1_4_9 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3),'@') <> NVL(RPAD(NVL(B.P1_4_13, ' '), 3),'@')
              THEN 'P1_4_13 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.PCCO_MNT_CRD,' '), 12),'@') <> NVL(RPAD (nvl(B.P1_4_18,' '), 12),'@')
              THEN 'P1_4_18 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3),'@') <> NVL(RPAD(NVL(B.P1_4_7, ' '), 3),'@')
              THEN 'P1_4_7 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12),'@') <> NVL(RPAD(NVL(B.P1_4_19, ' '), 12),'@')
              THEN 'P1_4_19 ' END ||
         CASE WHEN NVL(CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR),0)) END,'@') <> NVL(CASE WHEN B.P1_4_21 IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((B.P1_4_21),0)) END,'@')
              THEN 'P1_4_21 ' END ||
         CASE WHEN NVL(CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 3) ELSE 'EUR' END,'@') <> NVL(CASE WHEN B.P1_4_22 IS null THEN RPAD (' ', 3) ELSE 'EUR' END,'@')
              THEN 'P1_4_22 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.CD_CIRCUIT_DISTRIB, 'CL'),2),'@') <> NVL(RPAD (nvl(B.P1_4_23, 'CL'),2),'@')
              THEN 'P1_4_23 ' END ||
         CASE WHEN NVL(NVL(C_ENR.CD_USAGE_BIEN_IMM,' '),'@') <> NVL(NVL(B.P1_3_46,' '),'@')
              THEN 'P1_3_46 ' END ||
         CASE WHEN NVL(NVL(C_ENR.CD_RESPECT_COND, ' '),'@') <> NVL(NVL(B.P1_3_47, ' '),'@')
              THEN 'P1_3_47 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CD_LOC_BIEN, ' '), 2,' '),'@') <> NVL(RPAD(nvl(B.P1_3_44, ' '), 2,' '),'@')
              THEN 'P1_3_44 ' END ||
         CASE WHEN NVL(C_ENR.CD_ACHAT_FIN_LOC,'@') <> NVL(B.P1_3_45,'@')
              THEN 'P1_3_45 ' END ||
         CASE WHEN NVL(Case when nvl(C_ENR.MNT_VR,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)) else pack_utilitaire.f_format_montant_bis2(0) END,'@') <> NVL(Case when nvl(B.P1_5_19,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((B.P1_5_19),0)) else pack_utilitaire.f_format_montant_bis2(0) END,'@')
              THEN 'P1_5_19 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CD_DEVISE_VR,'EUR'),3),'@') <> NVL(RPAD(nvl(B.P1_5_20,'EUR'),3),'@')
              THEN 'P1_5_20 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.cla_comp_ref_act,' '),3),'@') <> NVL(RPAD(nvl(B.P1_19_5,' '),3),'@')
              THEN 'P1_19_5 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20),'@') <> NVL(RPAD(NVL(B.P1_2_99,' '), 20),'@')
              THEN 'P1_2_99 ' END ||
         CASE WHEN NVL(RPAD(C_ENR.IND_PROD_SS_JACENT, 1,' '),'@') <> NVL(RPAD(B.P1_4_31, 1,' '),'@')
              THEN 'P1_4_31 ' END ||
         CASE WHEN NVL(Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(C_ENR.MATURITE_EFF,0)) ,4,6),'@') <> NVL(Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(B.P1_3_20,0)) ,4,6),'@')
              THEN 'P1_3_20 ' END ||
         CASE WHEN NVL(NVL(C_ENR.TOP_ENG,'B'),'@') <> NVL(NVL(B.P1_4_8,'B'),'@')
              THEN 'P1_4_8 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' '),'@') <> NVL(RPAD(nvl(B.P1_4_42,' '),6,' '),'@')
              THEN 'P1_4_42 ' END ||
         CASE WHEN NVL(RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8),'@') <> NVL(RPAD(nvl(TO_CHAR(B.P1_3_3, 'YYYYMMDD'),' '),8),'@')
              THEN 'P1_3_3 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_4_47, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_4_47 ' END ||
         CASE WHEN NVL(Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END,'@') <> NVL(B.P1_4_29,'@')
              THEN 'P1_4_29 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.EVENMT_CRDT,' '),1),'@') <> NVL(RPAD(nvl(B.P1_21_3,' '),1),'@')
              THEN 'P1_21_3 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.NAT_CONT_EVENMT_CRDT,' '),1),'@') <> NVL(RPAD(nvl(B.P1_21_4,' '),1),'@')
              THEN 'P1_21_4 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.STA_CRDT,' '),1),'@') <> NVL(RPAD(nvl(B.P1_21_5,' '),1),'@')
              THEN 'P1_21_5 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_CRE_PERF,' '),2),'@') <> NVL(RPAD(nvl(B.P1_21_6,' '),2),'@')
              THEN 'P1_21_6 ' END ||
         CASE WHEN NVL(RPAD (NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD (NVL(TO_CHAR(B.P1_21_7, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_7 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_COMM, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_8, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_8 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_RSQ, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_9, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_9 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_10, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_10 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_11, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_11 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_12, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_12 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_13, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_13 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_14, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_14 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_15, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_15 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_16, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_21_16 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_PROD_ECH,' '),3),'@') <> NVL(RPAD(nvl(B.P1_22_56,' '),3),'@')
              THEN 'P1_22_56 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_OBJ_MET_PAL,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_57,' '),1),'@')
              THEN 'P1_22_57 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40),'@') <> NVL(RPAD(nvl(B.P1_22_1,' '),40),'@')
              THEN 'P1_22_1 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40),'@') <> NVL(RPAD(nvl(B.P1_22_51,' '),40),'@')
              THEN 'P1_22_51 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.NOTE_EXT_ORI,' '),10),'@') <> NVL(RPAD(nvl(B.P1_22_52,' '),10),'@')
              THEN 'P1_22_52 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' '),'@') <> NVL(RPAD(nvl(B.P1_22_6,' '),2,' '),'@')
              THEN 'P1_22_6 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.SEG_NOT_ORI,' '),2),'@') <> NVL(RPAD(nvl(B.P1_22_53,' '),2),'@')
              THEN 'P1_22_53 ' END ||
         CASE WHEN NVL(CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END,'@') <> NVL(CASE WHEN B.P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(B.P1_22_54,21)||'FR',' '),46) END,'@')
              THEN 'P1_22_54 ' END ||
         CASE WHEN NVL(CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE RPAD(upper(nvl(C_ENR.METH_NOT_ORI,' ')),3) END,'@') <> NVL(CASE WHEN B.P1_22_55 = 'C3' THEN '999' ELSE RPAD(upper(nvl(B.P1_22_55,' ')),3) END,'@')
              THEN 'P1_22_55 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2),'@') <> NVL(RPAD(nvl(B.P1_22_7,'97'),2),'@')
              THEN 'P1_22_7 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE),'@') <> NVL(pack_utilitaire.F_FORMAT_MONTANT_BIS2(B.P1_22_8),'@')
              THEN 'P1_22_8 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3),'@') <> NVL(RPAD(nvl(B.P1_22_9, 'EUR'), 3),'@')
              THEN 'P1_22_9 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_ECH_FOUR,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_12,' '),1),'@')
              THEN 'P1_22_12 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_INT_EFF_ORI),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_13),'@')
              THEN 'P1_22_13 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.TYPE_TAUX,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_14,' '),1),'@')
              THEN 'P1_22_14 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_REF,' '),12),'@') <> NVL(RPAD(nvl(B.P1_22_15,' '),12),'@')
              THEN 'P1_22_15 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.TYPE_AMOR_CAP,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_16,' '),1),'@')
              THEN 'P1_22_16 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.PRD_AMOR_CAP,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_17,' '),1),'@')
              THEN 'P1_22_17 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.PRD_PMT_INT,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_18,' '),1),'@')
              THEN 'P1_22_18 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_OCT),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_19),'@')
              THEN 'P1_22_19 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.MOD_REMB_CRE,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_20,' '),1),'@')
              THEN 'P1_22_20 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_PREM_ECH, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_21, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_21 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_DIFF_AMOR, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_22, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_22 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAFOND),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_23),'@')
              THEN 'P1_22_23 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLANCHER),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_24),'@')
              THEN 'P1_22_24 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.PRD_REV_TAUX_UNIT_TMP,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_25,' '),1),'@')
              THEN 'P1_22_25 ' END ||
         CASE WHEN NVL(LPAD(nvl((C_ENR.PRD_REV_TAUX_NBR),0),3,0),'@') <> NVL(LPAD(nvl((B.P1_22_26),0),3,0),'@')
              THEN 'P1_22_26 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_PRD_EN_CRS),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_27),'@')
              THEN 'P1_22_27 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_ADD),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_28),'@')
              THEN 'P1_22_28 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_MULT),'@') <> NVL(pack_utilitaire.F_FORMAT_TAUX(B.P1_22_29),'@')
              THEN 'P1_22_29 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.BASE_CAL_INT,' '),7),'@') <> NVL(RPAD(nvl(B.P1_22_30,' '),7),'@')
              THEN 'P1_22_30 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DBLQ_FONDS, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_31, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_31 ' END ||
         CASE WHEN NVL(case when C_ENR.MNT_PREM_DBLQ_FONDS is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_PREM_DBLQ_FONDS) end,'@') <> NVL(case when B.P1_22_32 is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(B.P1_22_32) end,'@')
              THEN 'P1_22_32 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.DEVISE_PREM_DBLQ_FONDS,'EUR'),3),'@') <> NVL(RPAD(nvl(B.P1_22_33,'EUR'),3),'@')
              THEN 'P1_22_33 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_MONTANT_BIS2( CASE WHEN C_ENR.CAP_THEO_REST<0 THEN 0 ELSE C_ENR.CAP_THEO_REST END),'@') <> NVL(pack_utilitaire.F_FORMAT_MONTANT_BIS2( B.P1_22_34),'@')
              THEN 'P1_22_34 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.DEVI_CAP_THEO_REST,' '),3),'@') <> NVL(RPAD(nvl(B.P1_22_35,' '),3),'@')
              THEN 'P1_22_35 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' '),'@') <> NVL(RPAD(NVL(B.P1_22_36,' '),1,' '),'@')
              THEN 'P1_22_36 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.dt_exigte_prem_impy, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_37, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_37 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_38, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_38 ' END ||
         CASE WHEN NVL(pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0)),'@') <> NVL(pack_utilitaire.f_format_montant_bis2(nvl((B.P1_22_44),0)),'@')
              THEN 'P1_22_44 ' END ||
         CASE WHEN NVL(RPAD('EUR', 3),'@') <> NVL(RPAD(B.P1_22_45, 3),'@')
              THEN 'P1_22_45 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_PALL, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_58, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_58 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_PALL, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_59, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_59 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(C_ENR.MNT_ECH_EN_COURS),'@') <> NVL(pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(B.P1_22_60),'@')
              THEN 'P1_22_60 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.DEVI_MNT_ECH_EN_COURS,' '),3),'@') <> NVL(RPAD(nvl(B.P1_22_61,' '),3),'@')
              THEN 'P1_22_61 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_PRE_POST_FIX,' '),1),'@') <> NVL(RPAD(nvl(B.P1_22_62,' '),1),'@')
              THEN 'P1_22_62 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENVL,'YYYYMMDD'),' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_63,'YYYYMMDD'),' '), 8),'@')
              THEN 'P1_22_63 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CD_PAYS_JURIDICTION, ' '), 2),'@') <> NVL(RPAD(nvl(B.P1_22_66, ' '), 2),'@')
              THEN 'P1_22_66 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_22_67, 'YYYYMMDD'), ' '), 8),'@')
              THEN 'P1_22_67 ' END ||
         CASE WHEN NVL(LPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), ' '),5,'0'),'@') <> NVL(LPAD(NVL(to_char(B.P1_22_70), ' '),5,'0'),'@')
              THEN 'P1_22_70 ' END ||
         CASE WHEN NVL(CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END,'@') <> NVL(CASE WHEN B.P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(B.P1_22_71,3,'0') END,'@')
              THEN 'P1_22_71 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.BUCKET_IFRS9,' '),2),'@') <> NVL(RPAD(nvl(B.P1_22_72,' '),2),'@')
              THEN 'P1_22_72 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.ELI_OUT_MUT_PROV,' '),1),'@') <> NVL(RPAD(nvl(B.P1_23_1,' '),1),'@')
              THEN 'P1_23_1 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CENTRE_RES,' '),7),'@') <> NVL(RPAD(nvl(B.P1_23_2,' '),7),'@')
              THEN 'P1_23_2 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.SYS_GEST_SRC,' '),20),'@') <> NVL(RPAD(nvl(B.P1_23_3,' '),20),'@')
              THEN 'P1_23_3 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CLA_COMP_ACT_IFRS9,' '),3),'@') <> NVL(RPAD(nvl(B.P1_23_4,' '),3),'@')
              THEN 'P1_23_4 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3),'@') <> NVL(RPAD(nvl(B.P1_23_5,' '),3),'@')
              THEN 'P1_23_5 ' END ||
         CASE WHEN NVL(RPAD(nvl(C_ENR.IND_ACT_DEP_ORI,' '),1),'@') <> NVL(RPAD(nvl(B.P1_23_6,' '),1),'@')
              THEN 'P1_23_6 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12),'@') <> NVL(RPAD (nvl(B.P1_23_8,' '), 12),'@')
              THEN 'P1_23_8 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12),'@') <> NVL(RPAD (nvl(B.P1_23_9,' '), 12),'@')
              THEN 'P1_23_9 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12),'@') <> NVL(RPAD (nvl(B.P1_23_10,' '), 12),'@')
              THEN 'P1_23_10 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12),'@') <> NVL(RPAD (nvl(B.P1_23_11,' '), 12),'@')
              THEN 'P1_23_11 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' '),'@') <> NVL(RPAD(NVL(B.P1_24_1,' '),1,' '),'@')
              THEN 'P1_24_1 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' '),'@') <> NVL(RPAD(NVL(B.P1_26_1,' '),1,' '),'@')
              THEN 'P1_26_1 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1),'@') <> NVL(RPAD(NVL(B.P1_22_11, ' '), 1),'@')
              THEN 'P1_22_11 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3),'@') <> NVL(RPAD(NVL(B.P1_26_3, ' '), 3),'@')
              THEN 'P1_26_3 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3),'@') <> NVL(RPAD(NVL(B.P1_26_4, ' '), 3),'@')
              THEN 'P1_26_4 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1),'@') <> NVL(RPAD(B.P1_27_3, 1),'@')
              THEN 'P1_27_3 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2),'@') <> NVL(RPAD(NVL(B.P1_27_4, ' '), 2),'@')
              THEN 'P1_27_4 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.IND_OPE_EFFET_LEVIER,' '), 1),'@') <> NVL(RPAD (nvl(B.P1_28_1,' '), 1),'@')
              THEN 'P1_28_1 ' END ||
         CASE WHEN NVL(pack_utilitaire.F_FORMAT_MONTANT_BIS3(C_ENR.MNT_IDEMNITE_RES),'@') <> NVL(pack_utilitaire.F_FORMAT_MONTANT_BIS3(B.P1_29_1),'@')
              THEN 'P1_29_1 ' END ||
         CASE WHEN NVL(RPAD (nvl(C_ENR.CD_DEV_MNT_INDEMNITE,' '), 3),'@') <> NVL(RPAD (nvl(B.P1_29_2,' '), 3),'@')
              THEN 'P1_29_2 ' END ||
         CASE WHEN NVL('N','@') <> NVL(B.P1_30_22,'@')
              THEN 'P1_30_22 ' END ||
         CASE WHEN NVL('N','@') <> NVL(B.P1_30_24,'@')
              THEN 'P1_30_24 ' END ||
         CASE WHEN NVL(RPAD (NVL(C_ENR.IND_ISF,'2'), 1),'@') <> NVL(RPAD (NVL(B.P1_31_5,'2'), 1),'@')
              THEN 'P1_31_5 ' END ||
         CASE WHEN NVL(RPAD ('+', 1),'@') <> NVL(RPAD (B.P1_31_17, 1),'@')
              THEN 'P1_31_17 ' END ||
         CASE WHEN NVL(RPAD ('+', 1),'@') <> NVL(RPAD (B.P1_31_18, 1),'@')
              THEN 'P1_31_18 ' END ||
         CASE WHEN NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END,'@') <> NVL(B.P1_31_22,'@')
              THEN 'P1_31_22 ' END ||
         CASE WHEN NVL(RPAD ('EUR', 3),'@') <> NVL(RPAD (B.P1_29_4, 3),'@')
              THEN 'P1_29_4 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2),'@') <> NVL(RPAD(NVL(B.P1_21_22,' '),2),'@')
              THEN 'P1_21_22 ' END ||
         CASE WHEN NVL(RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8),'@') <> NVL(RPAD(NVL(TO_CHAR(B.P1_21_23, 'YYYYMMDD'), ' '),8),'@')
              THEN 'P1_21_23 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.STATUT_MRTR,' '),2),'@') <> NVL(RPAD(NVL(B.P1_21_25,' '),2),'@')
              THEN 'P1_21_25 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_26,' '),1),'@')
              THEN 'P1_21_26 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_27,' '),1),'@')
              THEN 'P1_21_27 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2),'@') <> NVL(RPAD(NVL(B.P1_21_28,' '),2),'@')
              THEN 'P1_21_28 ' END ||
         CASE WHEN NVL(case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_MRTR),19) else RPAD(' ',19) end,'@') <> NVL(case when B.P1_21_30 is not null then RPAD(pack_utilitaire.f_format_montant_bis2(B.P1_21_30),19) else RPAD(' ',19) end,'@')
              THEN 'P1_21_30 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_44,' '),1),'@')
              THEN 'P1_21_44 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_45,' '),1),'@')
              THEN 'P1_21_45 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_46,' '),1),'@')
              THEN 'P1_21_46 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_IPRE,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_38,' '),1),'@')
              THEN 'P1_21_38 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_39,' '),1),'@')
              THEN 'P1_21_39 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_40,' '),1),'@')
              THEN 'P1_21_40 ' END ||
         CASE WHEN NVL(RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15),'@') <> NVL(RPAD(pack_utilitaire.F_FORMAT_TAUX_15(B.P1_21_43),15),'@')
              THEN 'P1_21_43 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_UCC,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_66,' '),1),'@')
              THEN 'P1_21_66 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_68,' '),1),'@')
              THEN 'P1_21_68 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12),'@') <> NVL(RPAD(NVL(B.P1_21_55,' '),12),'@')
              THEN 'P1_21_55 ' END ||
         CASE WHEN NVL(RPAD(NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_69,' '),1),'@')
              THEN 'P1_21_69 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1),'@') <> NVL(RPAD(NVL(B.P1_8_13,' '),1),'@')
              THEN 'P1_8_13 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.COMMUNE,' '),40),'@') <> NVL(RPAD(NVL(B.P1_21_71,' '),40),'@')
              THEN 'P1_21_71 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.NUM_VOIE,' '),40),'@') <> NVL(RPAD(NVL(B.P1_21_72,' '),40),'@')
              THEN 'P1_21_72 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.EXTENSION,' '),40),'@') <> NVL(RPAD(NVL(B.P1_21_73,' '),40),'@')
              THEN 'P1_21_73 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.TYPE_VOIE,' '),40),'@') <> NVL(RPAD(NVL(B.P1_21_74,' '),40),'@')
              THEN 'P1_21_74 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.LIB_VOIE,' '),40),'@') <> NVL(RPAD(NVL(B.P1_21_75,' '),40),'@')
              THEN 'P1_21_75 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.LIEU_DIT,' '),40),'@') <> NVL(RPAD(NVL(B.P1_21_76,' '),40),'@')
              THEN 'P1_21_76 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE,' '),3),'@') <> NVL(RPAD(NVL(B.P1_21_80,' '),3),'@')
              THEN 'P1_21_80 ' END ||
         CASE WHEN NVL(RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10),'@') <> NVL(RPAD(pack_utilitaire.F_FORMAT_TAUX(B.P1_21_81),10),'@')
              THEN 'P1_21_81 ' END ||
         CASE WHEN NVL(RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10),'@') <> NVL(RPAD(pack_utilitaire.F_FORMAT_TAUX(B.P1_21_82),10),'@')
              THEN 'P1_21_82 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_86,' '),1),'@')
              THEN 'P1_21_86 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_87,' '),1),'@')
              THEN 'P1_21_87 ' END ||
         CASE WHEN NVL(RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1),'@') <> NVL(RPAD(NVL(B.P1_21_88,' '),1),'@')
              THEN 'P1_21_88 ' END
           AS colunas_que_nao_reproduzem
  FROM ENG_CORP_P1 C_ENR
  JOIN ENG_CORP_P1_BIS B ON B.P1_H_1_11 = C_ENR.ID_ENGAGEMENT || '_C'
  -- so engajamentos com UMA linha na tabela: evita cruzar variantes
  JOIN (SELECT P1_H_1_11 FROM ENG_CORP_P1_BIS
         GROUP BY P1_H_1_11 HAVING COUNT(*) = 1) U
    ON U.P1_H_1_11 = B.P1_H_1_11
 WHERE C_ENR.A_EXTRAIRE = 'O'
   AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'
   AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
   AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1 OR NVL(C_ENR.MNT_VR,0) >= 1 )
   AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
   AND ROWNUM <= 200;
