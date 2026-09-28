-- =====================================================================
-- VALIDAR_1223_P3.sql                                      (SIRL-1223)
--
-- Gera o ficheiro do pave P3 ANTES e DEPOIS da alteracao, para provar que
-- a unica mudanca e a pedida no chamado:
--     P3C 21.65    RPAD(' ',5)    -> RPAD(' ',50)
--     filler BALE4 RPAD(' ',1132) -> RPAD(' ',1087)
--
-- Nao toca nos ficheiros oficiais: o nome de saida e outro (UC2_P3_ANTES /
-- UC2_P3_DEPOIS em vez de UC2_P3). A procedure apaga o ficheiro antes de
-- escrever (P_UTLF_REMOVE_FILE no inicio), por isso nao acumula linhas.
--
-- O ficheiro sai com o codigo da entidade colado no fim do nome. Em producao
-- o P_UTLF_CREDIT_P3 trata CINCO: 00399, 00936, 00357, 00472, 00370. A 00372
-- foi retirada pelo SIRL-667 em 29/04/2026. Chega levar um par (o 00357 e o
-- maior).
--
-- Se sairem SEIS ficheiros, o package compilado NAO e o de producao: e uma
-- versao anterior ao SIRL-667, e o sexto (o da 00372) sai vazio.
--
-- No SQL Developer: F5 (Run Script), nao F9.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------------------------------------------------------------------
-- PASSO 1 - com o package COMO ESTA HOJE (ainda NAO recompilado)
-- ---------------------------------------------------------------------
-- Confirmar que o package em base ainda e o antigo: tem de devolver 5.
select 'largura do P3C 21.65 em base: ' ||
       regexp_substr(text, 'RPAD\(''( )*'',(\d+)\)', 1, 1, NULL, 2) as antes
  from all_source
 where name = 'PACK_UTL_FILE_ENVOI_C3RD2'
   and type = 'PACKAGE BODY'
   and text like '%P3C 21.65%';

-- E que e mesmo a versao de producao: as listas de entidades tem de ter
-- CINCO codigos, sem o 00372.
select line, text
  from all_source
 where name = 'PACK_UTL_FILE_ENVOI_C3RD2'
   and type = 'PACKAGE BODY'
   and text like '%liste_cd_conso(%'
 order by line;

execute pack_utl_file_envoi_c3RD2.P_UTLF_CREDIT_P3('&&diretorio', 'UC2_P3_ANTES');

-- ---------------------------------------------------------------------
-- PASSO 2 - recompilar o PACK_UTL_FILE_ENVOI_C3RD2_1223.sql (o gerado pelo
--           gen_p3_1223.py a partir da versao de producao)
--           e so depois correr o PASSO 3
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- PASSO 3 - com o package JA recompilado
-- ---------------------------------------------------------------------
-- Agora a mesma consulta tem de devolver 50.
select 'largura do P3C 21.65 em base: ' ||
       regexp_substr(text, 'RPAD\(''( )*'',(\d+)\)', 1, 1, NULL, 2) as depois
  from all_source
 where name = 'PACK_UTL_FILE_ENVOI_C3RD2'
   and type = 'PACKAGE BODY'
   and text like '%P3C 21.65%';

execute pack_utl_file_envoi_c3RD2.P_UTLF_CREDIT_P3('&&diretorio', 'UC2_P3_DEPOIS');

-- ---------------------------------------------------------------------
-- PASSO 4 - levar o par para a comparacao
-- ---------------------------------------------------------------------
-- No servidor, no diretorio indicado:
--     ls -la UC2_P3_ANTES* UC2_P3_DEPOIS*
--     head -c 16 UC2_P3_ANTES00357      -> tem de dar 00;00000471;001;
-- E depois, no repositorio:
--     python comparar_1223.py p3 UC2_P3_ANTES00357 UC2_P3_DEPOIS00357
