-- =====================================================================
-- NAO-REGRESSAO : o spool ATUAL contra o spool vPACT          (SIRL-1224)
--
-- Gera os dois ficheiros na mesma sessao e com os MESMOS binds, para que a
-- unica diferenca possivel seja o pave P1. Depois compara-se com um diff.
--
-- COMO CORRER (SQL Developer: F5, nao F9)
--   1. a procedure ja tem de ter corrido : @run_procedure.sql
--   2. @comparar_spools.sql <diretorio>
--      ex.: @comparar_spools.sql C:\temp
--
-- Os dois spools abrem o ficheiro em APPEND -- e assim que o shell
-- 030_CREATION_SPOOL_CRR.sh os usa, escrevendo a linha ENTETE antes. Se os
-- ficheiros ja existirem de uma execucao anterior, o conteudo acumula-se e o
-- diff fica ilegivel: APAGA-OS PRIMEIRO.
--
-- Falta nos dois ficheiros a linha ENTETE, que o shell escreve. Falta nos
-- dois por igual, por isso o diff continua valido.
-- =====================================================================

-- Os dois binds que o shell declara. Sao os mesmos do spool atual:
--   ENTITE    : entidade a extrair (= cd_conso_cpt), ou 'TOTAL'
--   MASYSDATE : horodatage da extracao (yyyymmddHHMI), 12 caracteres
--
-- O MASYSDATE vai em TODAS as linhas dos dois ficheiros. Tem de ser o MESMO
-- nas duas extracoes -- por isso se fixa aqui, uma so vez, e nao dentro de
-- cada spool. Se cada um apanhasse o seu, o diff acusava as 120789 linhas.
VARIABLE ENTITE    VARCHAR2(10)
VARIABLE MASYSDATE VARCHAR2(12)

BEGIN
    :ENTITE    := 'TOTAL';
    :MASYSDATE := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MI');
END;
/

PROMPT
PROMPT === 1/2 : spool ATUAL -> CRRCORP_antigo.dat
@030_spool_Extract_CRRCORP-antigo.sql &1 CRRCORP_antigo.dat

PROMPT
PROMPT === 2/2 : spool vPACT -> CRRCORP_novo.dat
@030_spool_Extract_CRRCORP-novo.sql &1 CRRCORP_novo.dat

SET TERM ON
SET FEED ON
SET HEADING ON
PROMPT
PROMPT Feito. Agora, fora do SQL Developer :
PROMPT     fc /L CRRCORP_antigo.dat CRRCORP_novo.dat      (Windows)
PROMPT     diff CRRCORP_antigo.dat CRRCORP_novo.dat       (Unix)
PROMPT
PROMPT Sem saida = ficheiro identico = nao-regressao provada.
PROMPT
PROMPT Se houver diferencas, para ver a PRIMEIRA linha divergente e a coluna:
PROMPT     diff <(cat -A CRRCORP_antigo.dat) <(cat -A CRRCORP_novo.dat) | head
PROMPT
