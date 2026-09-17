-- =====================================================================
-- Consultas de conferencia para levar ao cliente            SIRL-1224
--
-- C1  TRE502 sem devise (P1 3.41 / P1 3.43): o que muda entre o spool
--     antigo e o novo quando a devise esta vazia
-- C2  Tipos de risco Fora do NAT02 com e sem dados nesta data de arrete
--
-- Rodar no SQL Developer, no esquema do DEV2, com F5 (Run Script).
-- Nada aqui altera dados: so SELECT.
-- =====================================================================


-- ---------------------------------------------------------------------
-- C1  TRE502 sem devise
--
--     Cada campo ocupa um lugar fixo na linha. A devise ocupa 3 caracteres.
--     Spool antigo : RPAD(devise, 3)            -> devise vazia = nada escrito,
--                    a linha encolhe 3 caracteres e o resto desalinha.
--     Spool novo   : RPAD(NVL(devise, ' '), 3)  -> 3 espacos, linha alinhada.
--     O chamado nao pediu isto: e consequencia da regra "vazio = NULL".
-- ---------------------------------------------------------------------

-- C1.1  Devise vazia: os colchetes mostram onde o campo comeca e termina
SELECT '[' || RPAD(NULL, 3)           || ']' AS antigo,      -- []
       LENGTH(RPAD(NULL, 3))                  AS tam_antigo,  -- (nulo) = 0 caracteres
       '[' || RPAD(NVL(NULL, ' '), 3) || ']' AS novo,        -- [   ]
       LENGTH(RPAD(NVL(NULL, ' '), 3))        AS tam_novo     -- 3
  FROM DUAL;

-- C1.2  Devise preenchida: os dois escrevem igual
SELECT '[' || RPAD('EUR', 3) || ']'            AS antigo,    -- [EUR]
       '[' || RPAD(NVL('EUR', ' '), 3) || ']' AS novo        -- [EUR]
  FROM DUAL;

-- C1.3  Casos reais na base. Esperado hoje: 0 e 0
--       (se nao fosse 0, a comparacao dos arquivos teria dado diferenca)
SELECT COUNT(*)                                               AS total_tre502,
       SUM(CASE WHEN CD_DEV_VTR    IS NULL THEN 1 ELSE 0 END) AS sem_devise_vtr,     -- P1 3.41
       SUM(CASE WHEN CD_DEV_HYPOTH IS NULL THEN 1 ELSE 0 END) AS sem_devise_hypoth   -- P1 3.43
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
   AND NVL(FLAG_HN,'N') = 'N'
   AND CD_TYPE_RISQUE = 'TRE502';


-- ---------------------------------------------------------------------
-- C2  Tipos de risco Fora do NAT02
--
--     Cada tipo que o spool trata no Fora do NAT02 e quantos existem na
--     base. qtd = 0 -> o tipo nao existe nesta data: o codigo dele so foi
--     validado pelo gerador, nao pela comparacao dos arquivos.
-- ---------------------------------------------------------------------

-- C2.1  Tipos esperados, com a situacao de cada um
WITH esperado AS (
    SELECT 4 AS variante, 'TRE100' AS tipo FROM DUAL UNION ALL
    SELECT 5, 'TRE2*'  FROM DUAL UNION ALL
    SELECT 5, 'TRE4*'  FROM DUAL UNION ALL
    SELECT 5, 'TRE5*'  FROM DUAL UNION ALL
    SELECT 6, 'EQU101' FROM DUAL UNION ALL
    SELECT 7, 'SIG201' FROM DUAL UNION ALL
    SELECT 7, 'INR101' FROM DUAL UNION ALL
    SELECT 8, '*VAR1*' FROM DUAL
)
SELECT e.variante,
       e.tipo,
       COUNT(p.CD_TYPE_RISQUE) AS qtd,
       CASE WHEN COUNT(p.CD_TYPE_RISQUE) = 0
            THEN 'SEM DADOS - validado so pelo gerador'
            ELSE 'testado na comparacao' END AS situacao
  FROM esperado e
  LEFT JOIN ENG_CORP_P1 p
    ON p.CD_TYPE_RISQUE LIKE REPLACE(e.tipo, '*', '%')
   AND p.A_EXTRAIRE = 'O'
   AND p.FLAG_HN    = 'O'
 GROUP BY e.variante, e.tipo
 ORDER BY e.variante, e.tipo;

-- C2.2  Detalhe: todos os tipos Fora do NAT02 que existem nesta data
SELECT CD_TYPE_RISQUE, COUNT(*) AS qtd
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
   AND FLAG_HN = 'O'
 GROUP BY CD_TYPE_RISQUE
 ORDER BY CD_TYPE_RISQUE;
