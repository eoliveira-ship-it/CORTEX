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
    v_t0        TIMESTAMP    := SYSTIMESTAMP;
BEGIN
    -- Uma chamada so, sem parametros: esvazia a tabela e corre os 8 INSERT
    -- (todas as entidades, NAT02 e Hors NAT02 juntos).
    pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS;

    DBMS_OUTPUT.PUT_LINE('OK - duracao : '||TO_CHAR(SYSTIMESTAMP - v_t0));
END;
/

-- Resultado
SELECT CD_PERIMETRE, COUNT(*) AS linhas
  FROM ENG_CORP_P1_BIS
 GROUP BY CD_PERIMETRE
 ORDER BY 1;
