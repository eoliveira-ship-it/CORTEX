-- Que versao do package esta REALMENTE compilada na base?
-- Nao adivinha: le o codigo-fonte instalado no dicionario.
SET LINESIZE 200
COLUMN codigo FORMAT A96
COLUMN object_name FORMAT A34

-- 1) Estado e data de compilacao
SELECT object_name, object_type, status,
       TO_CHAR(last_ddl_time,'YYYY-MM-DD HH24:MI') AS compilado_em
  FROM ALL_OBJECTS
 WHERE object_name = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW'
 ORDER BY object_type;

-- 2) A PROVA: como esta escrito o P1_3_20 no codigo instalado
--    ATUAL  -> NVL(C_ENR.MATURITE_EFF, 0)          AS P1_3_20
--    ANTIGO -> Substr(NVL(C_ENR.MATURITE_EFF,0),4,6) AS P1_3_20
SELECT line, TRIM(text) AS codigo
  FROM ALL_SOURCE
 WHERE name = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW'
   AND type = 'PACKAGE BODY'
   AND UPPER(text) LIKE '%AS P1_3_20,%'
 ORDER BY line;

-- 3) Assinatura da procedure (a atual tem 3 parametros)
SELECT argument_name, data_type, position
  FROM ALL_ARGUMENTS
 WHERE object_name = 'P_ALIM_ENG_CORP_P1_BIS'
   AND package_name = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW'
 ORDER BY position;

-- 4) E o valor que ficou na tabela (se ~2,95 esta certo; se 520547 e o antigo)
SELECT MIN(P1_3_20) AS minimo, MAX(P1_3_20) AS maximo,
       ROUND(AVG(P1_3_20),4) AS media
  FROM ENG_CORP_P1_BIS;
