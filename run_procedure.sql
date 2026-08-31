-- =====================================================================
-- Executar a procedure de alimentacao da ENG_CORP_P1_BIS  (SIRL-1224)
--
-- Ordem antes de correr isto:
--   1. ENG_CORP_P1_BIS.sql          (cria a tabela)
--   2. pack_alim_tab_envoi_crrv4.sql (compila o package)
--   3. este script
--
-- No SQL Developer usar F5 (Run Script), nao F9.
-- =====================================================================

SET SERVEROUTPUT ON

DECLARE
    v_entite    VARCHAR2(10) := 'TOTAL';   -- ou um CD_CONSO_CPT preciso
    v_masysdate VARCHAR2(12) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MI');
    v_t0        TIMESTAMP    := SYSTIMESTAMP;
BEGIN
    -- p_perimetre :
    --   'TOTAL'       esvazia tudo e corre os 8 INSERT      (teste)
    --   'NAT02'       so o perimetro NAT02, INSERT #1-#3    (M2 BTR)
    --   'HORS_NAT02'  so o Hors NAT02, INSERT #4-#8         (apos dados contabilisticos)
    pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS(
        p_entite    => v_entite,
        p_masysdate => v_masysdate,
        p_perimetre => 'TOTAL');

    DBMS_OUTPUT.PUT_LINE('OK - duracao : '||TO_CHAR(SYSTIMESTAMP - v_t0));
END;
/

-- Resultado
SELECT CD_PERIMETRE, COUNT(*) AS linhas
  FROM ENG_CORP_P1_BIS
 GROUP BY CD_PERIMETRE
 ORDER BY 1;

-- As duas alimentacoes do ticket, em momentos diferentes:
-- BEGIN pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS('TOTAL', TO_CHAR(SYSDATE,'YYYYMMDDHH24MI'), 'NAT02'); END;
-- /
-- BEGIN pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS('TOTAL', TO_CHAR(SYSDATE,'YYYYMMDDHH24MI'), 'HORS_NAT02'); END;
-- /
