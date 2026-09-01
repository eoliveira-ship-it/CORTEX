-- =====================================================================
-- O spool vPACT devolveu 0 linhas. Porque?
--
-- COMECA PELO CENSO DOS PAVES -- e um comando de shell, nao SQL, e separa
-- as duas familias de causa numa linha:
--
--     cut -c39-40 $SORTIE/CRRCORP-novo.dat | sort | uniq -c
--
-- Os bytes 39-40 de cada linha sao o codigo do pave (a seguir ao cabecalho
-- arrete 8 + entite 5 + appli 12 + frequence 1 + horodatage 12 = 38).
--
--   C1/C5 aparecem e mais nada  -> o SELECT do P1 deu ERRO. O shell tem
--       "whenever sqlerror exit 1" na linha 203: o sqlplus aborta ali e
--       tudo o que vinha depois (P1, P2, M1, P9) nunca chega a ser escrito.
--       A razao esta em  $V30RACINE/log/030_CREATION_SPOOL_CRRCORP-novo_sql.log
--
--   C1, C5, P2, M1, P9 aparecem e so falta P1  -> nao houve erro: o SELECT
--       correu e devolveu ZERO linhas. Ai sim, corre os blocos abaixo.
--
-- =====================================================================
-- Correr com F5. Cada bloco elimina uma causa. Para na primeira que der
-- zero: e essa.
-- =====================================================================
SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK ON
SET HEADING ON

-- ---------------------------------------------------------------------
-- 1) A tabela tem dados?
--    Se der 0, a procedure nao correu depois de a tabela ser recriada.
--    Solucao: @run_procedure.sql
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS linhas_na_tabela FROM ENG_CORP_P1_BIS;

-- ---------------------------------------------------------------------
-- 2) E o perimetro que o spool procura?
--    O primeiro SELECT do spool pede CD_PERIMETRE = 'NAT02'.
--    Se NAT02 der 0, a procedure correu so para HORS_NAT02 (ou nenhum).
-- ---------------------------------------------------------------------
SELECT CD_PERIMETRE, NO_VARIANTE, COUNT(*) AS linhas
  FROM ENG_CORP_P1_BIS
 GROUP BY CD_PERIMETRE, NO_VARIANTE
 ORDER BY 1, 2;

-- ---------------------------------------------------------------------
-- 3) O filtro da entidade deixa passar alguma coisa?
--    O spool tem:  (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
--    Se :ENTITE ficar NULL, a condicao inteira e NULL e NAO passa NADA.
--    Esta e a causa mais provavel: no SQL Developer o F5 abre uma caixa a
--    pedir o valor do bind, e um valor em branco da exatamente isto.
--
--    A query abaixo simula os dois casos.
-- ---------------------------------------------------------------------
SELECT 'com ENTITE = TOTAL' AS caso, COUNT(*) AS passa
  FROM ENG_CORP_P1_BIS
 WHERE CD_PERIMETRE = 'NAT02'
   AND (P1_H_0_2 = 'TOTAL' OR 'TOTAL' = 'TOTAL')
UNION ALL
SELECT 'com ENTITE = NULL' AS caso, COUNT(*) AS passa
  FROM ENG_CORP_P1_BIS
 WHERE CD_PERIMETRE = 'NAT02'
   AND (P1_H_0_2 = NULL OR NULL = 'TOTAL');

-- ---------------------------------------------------------------------
-- 4) Que entidades existem mesmo na tabela?
--    Se correres o spool com um :ENTITE que nao esta nesta lista, da 0.
-- ---------------------------------------------------------------------
SELECT NVL(P1_H_0_2, '(nulo)') AS entidade, COUNT(*) AS linhas
  FROM ENG_CORP_P1_BIS
 GROUP BY P1_H_0_2
 ORDER BY 2 DESC;

-- ---------------------------------------------------------------------
-- 5) A query do spool, sem formatacao nenhuma.
--    Se isto devolver linhas, o problema nao esta nos dados nem no filtro:
--    esta na forma como o script foi lancado (ver notas no fim).
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS linhas_que_o_spool_deveria_escrever
  FROM ENG_CORP_P1_BIS
 WHERE CD_PERIMETRE IN ('NAT02', 'HORS_NAT02');

-- =====================================================================
-- SE OS CINCO BLOCOS DEREM NUMEROS E O FICHEIRO CONTINUAR VAZIO
--
-- O problema e o lancamento, nao o SQL. O spool foi escrito para SQL*Plus
-- chamado pelo shell 030_CREATION_SPOOL_CRR.sh, e conta com duas coisas
-- que o SQL Developer nao da de graca:
--
--   * &1 e &2  -- os parametros posicionais de "spool &1/&2 append".
--     No SQL*Plus vem de  @030_spool_Extract_CRRCORP-antigo.sql /caminho ficheiro.dat
--     No SQL Developer nao ha parametros posicionais: o &1 vira uma
--     substituicao que ele pede numa caixa. Se lhe deres um caminho que
--     nao existe, o ficheiro fica vazio ou nem se cria.
--
--   * :ENTITE e :MASYSDATE -- binds que o shell declara.
--     O @comparar_spools.sql declara-os por ti. Usa esse, em SQL*Plus:
--
--         sqlplus user/pass@DEV2 @comparar_spools.sql C:\temp
--
--     Assim os dois spools correm com os MESMOS binds e o diff tem sentido.
-- =====================================================================
