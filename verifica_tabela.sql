-- Verifica se a ENG_CORP_P1_BIS ficou criada como o DDL manda.
-- 1) contagem de colunas   2) as 3 alargadas (ORA-01438)
SET LINESIZE 200
COLUMN column_name FORMAT A14
COLUMN data_type   FORMAT A10

-- 1) devem ser 666 colunas (662 P1 + 4 tecnicas)
SELECT COUNT(*) AS total_colunas
  FROM ALL_TAB_COLUMNS WHERE table_name = 'ENG_CORP_P1_BIS';

-- 2) as tres alargadas : esperado 21,2 / 24,9 / 24,9
SELECT column_name, data_type, data_precision AS prec, data_scale AS escala
  FROM ALL_TAB_COLUMNS
 WHERE table_name = 'ENG_CORP_P1_BIS'
   AND column_name IN ('P1_21_30','P1_21_43','P1_21_60')
 ORDER BY column_name;
