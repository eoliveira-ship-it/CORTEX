-- Perguntas decisivas levantadas pelo teste de conteudo.
SET LINESIZE 200

-- 1) A escala das taxas: F_FORMAT_TAUX escala, ou a origem ja esta escalada?
--    Evidencia: ficheiro P1 3.20 = 02.9698 ; tabela = 520547.
--    A razao e exatamente 100000 (5 decimais). Se os valores abaixo forem
--    da ordem das centenas de milhar, a origem guarda o INTEIRO ESCALADO
--    e a tabela devia guardar valor/100000.
SELECT 'MATURITE_EFF' AS coluna, MIN(MATURITE_EFF) AS minimo,
       MAX(MATURITE_EFF) AS maximo, ROUND(AVG(MATURITE_EFF),2) AS media
  FROM ENG_CORP_P1 WHERE A_EXTRAIRE = 'O'
UNION ALL
SELECT 'TX_LGD_PREDICTIF_LOCAL', MIN(TX_LGD_PREDICTIF_LOCAL),
       MAX(TX_LGD_PREDICTIF_LOCAL), ROUND(AVG(TX_LGD_PREDICTIF_LOCAL),2)
  FROM ENG_CORP_P1 WHERE A_EXTRAIRE = 'O'
UNION ALL
SELECT 'TX_TRC', MIN(TX_TRC), MAX(TX_TRC), ROUND(AVG(TX_TRC),2)
  FROM ENG_CORP_P1 WHERE A_EXTRAIRE = 'O';

-- 2) Mapeamentos suspeitos: a tabela poe valor onde o ficheiro esta em branco,
--    e o valor parece de OUTRO campo (indicador numa referencia).
SELECT P1_30_22 AS ref_contrato_quadro, P1_30_24 AS ref_netting,
       P1_31_5 AS ind_solidaria, P1_21_55 AS natureza_op, P1_22_54 AS grelha_notacao
  FROM ENG_CORP_P1_BIS WHERE ROWNUM <= 5;

-- 3) A fotografia: a tabela esta em 2025-05-31, o ficheiro em 2025-06-30.
--    Confirmar que a origem so tem um arrete.
SELECT TO_CHAR(DT_ARRETE,'YYYYMMDD') AS arrete, COUNT(*) AS linhas
  FROM ENG_CORP_P1 WHERE A_EXTRAIRE = 'O'
 GROUP BY TO_CHAR(DT_ARRETE,'YYYYMMDD') ORDER BY 1;
