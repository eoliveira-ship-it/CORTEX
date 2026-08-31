-- Tipos reais das colunas de origem (ENG_CORP_P1).
-- Responde a duas perguntas de uma so vez, sem varrer a tabela:
--   1. que colunas de texto estao a alimentar colunas NUMBER  (-> ORA-01722)
--   2. que precisao/escala e precisa de facto              (-> ORA-01438)
SET LINESIZE 200
SET PAGESIZE 500
COLUMN column_name FORMAT A32
COLUMN data_type   FORMAT A12

SELECT column_name,
       data_type,
       data_precision AS prec,
       data_scale     AS escala,
       data_length    AS tamanho
  FROM ALL_TAB_COLUMNS
 WHERE table_name = 'ENG_CORP_P1'
 ORDER BY column_name;
