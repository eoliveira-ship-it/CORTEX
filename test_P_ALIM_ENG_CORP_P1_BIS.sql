-- Test de P_ALIM_ENG_CORP_P1_BIS  (SIRL-1224)
-- Prerequis : ENG_CORP_P1_BIS.sql execute + package compile.
-- MASYSDATE = date extraction yyyymmddHHMI (cf. spool L66), 12 car.

SET SERVEROUTPUT ON
SET LINESIZE 200

-- 1) Etat avant
SELECT COUNT(*) AS avant FROM ENG_CORP_P1_BIS;

-- 2) Execution
DECLARE
    v_entite    VARCHAR2(10) := 'TOTAL';   -- ou un CD_CONSO_CPT precis
    v_masysdate VARCHAR2(12) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MI');
    v_t0        TIMESTAMP := SYSTIMESTAMP;
BEGIN
    pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS(v_entite, v_masysdate);
    DBMS_OUTPUT.PUT_LINE('OK - duree : '||TO_CHAR(SYSTIMESTAMP - v_t0));
END;
/

-- 3) Volumetrie par perimetre
SELECT CD_PERIMETRE, COUNT(*) AS lignes
  FROM ENG_CORP_P1_BIS GROUP BY CD_PERIMETRE ORDER BY 1;

-- 4) CONTROLE : attendu (source) vs insere (table)
--    Chaque ligne doit donner ecart = 0.
WITH attendu AS (
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
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('TRE100')
    UNION ALL
    SELECT 5 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5')
    UNION ALL
    SELECT 6 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('EQU101')
    UNION ALL
    SELECT 7 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101')
    UNION ALL
    SELECT 8 AS variante, 'HORS_NAT02' AS perimetre, COUNT(*) AS nb
      FROM ENG_CORP_P1 C_ENR WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = 'TOTAL' OR 'TOTAL' = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%'
)
SELECT a.variante, a.perimetre, a.nb AS attendu FROM attendu a ORDER BY 1;

-- Total attendu (somme) doit egaler :
SELECT COUNT(*) AS insere FROM ENG_CORP_P1_BIS;

-- 5) Taux de remplissage : colonnes alimentees vs restees NULL
--    Les colonnes non mappees (docs/posicoes-a-mapear.md) sont NULL : normal.
SELECT COUNT(*) AS lignes,
       COUNT(P1_10_2) AS P1_10_2,
       COUNT(P1_21_22) AS P1_21_22,
       COUNT(P1_21_23) AS P1_21_23,
       COUNT(P1_21_25) AS P1_21_25,
       COUNT(P1_21_26) AS P1_21_26,
       COUNT(P1_21_27) AS P1_21_27,
       COUNT(P1_21_28) AS P1_21_28,
       COUNT(P1_21_3) AS P1_21_3,
       COUNT(CD_PERIMETRE) AS CD_PERIMETRE
  FROM ENG_CORP_P1_BIS;

