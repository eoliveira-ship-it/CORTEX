-- ======================================================================
-- PACK_HIST_ENG_CORP_P1_BIS.sql
-- VERSAO 2026-10-06a -- SIRL-1472, historizacao da ENG_CORP_P1_BIS no HCRR.
--   GERADO por gen_hcrr.py a partir de ENG_CORP_P1_BIS.sql -- nao editar a mao.
--   668 colunas, na ordem do CREATE TABLE da tabela de origem.
--   Escreve um ficheiro com UTL_FILE: uma linha por registo, os campos
--   separados por ";". No maximo 9170 octetos por linha.
--   Conferir no servidor com:  grep VERSAO PACK_HIST_ENG_CORP_P1_BIS.sql
-- ======================================================================

CREATE OR REPLACE PACKAGE PACK_HIST_ENG_CORP_P1_BIS
AS

    -- Escreve a ENG_CORP_P1_BIS inteira num ficheiro, para o HCRR carregar.
    --   p_chemin        o directory do Oracle (UTL_FILE)
    --   p_nom_fichier   o nome do ficheiro, ja com a data do arrete
    PROCEDURE P_HIST_ENG_CORP_P1_BIS (p_chemin      IN VARCHAR2,
                                      p_nom_fichier IN VARCHAR2);

END PACK_HIST_ENG_CORP_P1_BIS;
/

CREATE OR REPLACE PACKAGE BODY PACK_HIST_ENG_CORP_P1_BIS
AS

PROCEDURE P_HIST_ENG_CORP_P1_BIS (p_chemin      IN VARCHAR2,
                                  p_nom_fichier IN VARCHAR2)
IS
    v_fic     UTL_FILE.FILE_TYPE;
    v_ligne   VARCHAR2(32767);
    v_nb      NUMBER := 0;
    v_arrete  DATE;
BEGIN
    SELECT MAX(DT_ARRETE) INTO v_arrete FROM ENG_CORP_P1_BIS;

    -- 'w' e nao 'a': o ficheiro e reescrito de cada vez. Com 'a' uma
    -- segunda corrida no mesmo mes duplicava as linhas, sem dar erro.
    v_fic := UTL_FILE.FOPEN(p_chemin, p_nom_fichier, 'w', 32767);

    -- Cabecalho. O formato e PROPOSTA: nao temos o do HCRR.
    UTL_FILE.PUT_LINE(v_fic, '00' || ';' || 'ENG_CORP_P1_BIS' || ';'
        || TO_CHAR(v_arrete, 'YYYYMMDD') || ';'
        || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || ';'
        || TO_CHAR(668));

    FOR C IN (SELECT * FROM ENG_CORP_P1_BIS
               ORDER BY DT_ARRETE, ID_ENGAGEMENT, CD_PERIMETRE, NO_VARIANTE)
    LOOP
        v_ligne := 
            TRANSLATE(C.ID_ENGAGEMENT, ';', '.')                           || ';' ||
            TRANSLATE(C.CD_PERIMETRE, ';', '.')                            || ';' ||
            TO_CHAR(C.NO_VARIANTE, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''') || ';' ||
            TO_CHAR(C.DT_ARRETE, 'YYYYMMDDHH24MISS')                       || ';' ||
            TO_CHAR(C.DT_TRAITEMENT, 'YYYYMMDDHH24MISS')                   || ';' ||
            TO_CHAR(C.P1_H_0_1, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_H_0_2, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_3, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_4, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_5, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_6, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_7, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_8, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_9, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_0_99, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_H_1_1, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_1_2, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_1_4, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_1_6, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_1_8, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_H_1_11, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_H_1_16, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_H_1_97, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_H_1_98, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_H_1_99, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_1_1, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_1_2, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_2_0, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_2_4, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_2_6, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_2_18, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_2_29, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_2_99, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_2, 'YYYYMMDDHH24MISS')                          || ';' ||
            TO_CHAR(C.P1_3_3, 'YYYYMMDDHH24MISS')                          || ';' ||
            TO_CHAR(C.P1_3_4, 'YYYYMMDDHH24MISS')                          || ';' ||
            TRANSLATE(C.P1_3_7, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_3_8, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_3_9, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_3_10, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_11, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_12, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_13, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_15, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_16, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_17, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_19, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_20, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_31, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_32, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_33, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_36, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_40, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_41, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_42, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_43, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_44, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_45, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_46, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_47, ';', '.')                                 || ';';

        v_ligne := v_ligne ||
            TO_CHAR(C.P1_3_50, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_51, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_52, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_53, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_54, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_55, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_56, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_57, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_58, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_59, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_60, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_61, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_62, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_63, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_64, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_65, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_66, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_70, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_71, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_72, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_73, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_74, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_75, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_76, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_77, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_80, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_81, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_82, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_83, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_84, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_85, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_3_86, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_3_87, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_88, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_89, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_90, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_98, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_3_99, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_1, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_4_2, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_4_3, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_4_4, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_4_5, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_4_6, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_4_7, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_4_8, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_4_9, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_4_13, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_14, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_4_15, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_16, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_4_17, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_18, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_19, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_20, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TO_CHAR(C.P1_4_21, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_4_22, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_23, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_24, 'YYYYMMDDHH24MISS')                         || ';' ||
            TO_CHAR(C.P1_4_25, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_4_26, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_27, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_4_28, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_29, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_30, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_4_31, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_32, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_33, 'YYYYMMDDHH24MISS')                         || ';' ||
            TRANSLATE(C.P1_4_34, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_35, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_36, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_37, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_38, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_39, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_40, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_41, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_42, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_43, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_44, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_45, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_46, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_4_47, 'YYYYMMDDHH24MISS')                         || ';' ||
            TRANSLATE(C.P1_4_48, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_49, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_98, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_4_99, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_5_2, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_5_3, 'YYYYMMDDHH24MISS')                          || ';' ||
            TRANSLATE(C.P1_5_5, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_5_6, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_5_7, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_5_8, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_5_10, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_5_11, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_5_19, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_5_20, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_5_99, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_6_99, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_7_0, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TO_CHAR(C.P1_7_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_7_2, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_7_3, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_7_6, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_7_7, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_7_8, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_7_9, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_7_10, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_11, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_7_12, 'YYYYMMDDHH24MISS')                         || ';' ||
            TRANSLATE(C.P1_7_13, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_14, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_15, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_16, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_17, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_18, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_19, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_20, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_7_21, 'YYYYMMDDHH24MISS')                         || ';' ||
            TRANSLATE(C.P1_7_22, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_23, ';', '.')                                 || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_7_24, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_25, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_7_99, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_8_1, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_8_2, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_8_11, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_8_12, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_8_13, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_8_99, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_9_5, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_9_99, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_10_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_10_2, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_10_4, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TO_CHAR(C.P1_10_5, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_10_20, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_10_21, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_10_22, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_10_23, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_10_24, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_10_99, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_11_1, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_11_2, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_11_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_11_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_11_12, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_11_13, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_11_14, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_11_15, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_11_16, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_11_33, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_12_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_12_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_12_5, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_12_6, 'YYYYMMDDHH24MISS')                         || ';' ||
            TRANSLATE(C.P1_12_16, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_12_17, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_12_18, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_12_19, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_13_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_13_2, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_13_4, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_13_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_13_10, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_14, ';', '.')                                   || ';' ||
            TRANSLATE(C.P1_15, ';', '.')                                   || ';' ||
            TRANSLATE(C.P1_15_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_15_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_16, ';', '.')                                   || ';' ||
            TRANSLATE(C.P1_16_3, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_16_6, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_16_9, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_16_12, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_13, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_15, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_16, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_17, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_18, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_19, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_20, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_16_21, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_22, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_23, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_24, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_25, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_26, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_27, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_28, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_29, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_30, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_31, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_32, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_33, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_34, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_35, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_36, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_37, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_38, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_39, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_40, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_16_41, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_16_42, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_16_99, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_18_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TO_CHAR(C.P1_18_5, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TO_CHAR(C.P1_18_10, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_18_17, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_18_18, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_19_5, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_20_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_20_2, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_20_3, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_20_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_21_1, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_21_2, 'YYYYMMDDHH24MISS')                         || ';' ||
            TRANSLATE(C.P1_21_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_21_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_21_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_21_6, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_21_7, 'YYYYMMDDHH24MISS')                         || ';' ||
            TO_CHAR(C.P1_21_8, 'YYYYMMDDHH24MISS')                         || ';' ||
            TO_CHAR(C.P1_21_9, 'YYYYMMDDHH24MISS')                         || ';' ||
            TO_CHAR(C.P1_21_10, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_21_11, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_21_12, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_21_13, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_21_14, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_21_15, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_21_16, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_21_17, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_18, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_19, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_20, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_21, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_22, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_23, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_21_25, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_26, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_27, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_28, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TO_CHAR(C.P1_21_29, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_30, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_31, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_32, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_33, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_34, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_35, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_36, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_37, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_38, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_39, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_40, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_41, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_42, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_43, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_44, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_45, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_46, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_47, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_48, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_49, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_50, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_51, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_52, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_53, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_54, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_55, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_56, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_57, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_58, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_59, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_60, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_61, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_62, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_63, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_64, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_65, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_66, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_67, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_68, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_69, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_71, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_72, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_73, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_74, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_75, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_76, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_77, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_78, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_79, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_80, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_81, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_82, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_83, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_84, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_21_85, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_86, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_87, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_88, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_89, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_21_90, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_21_91, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_21_92, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_93, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_94, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_95, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_98, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_21_99, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_6, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_7, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_22_8, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_22_9, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_22_11, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_12, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_13, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_14, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_15, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_16, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_17, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_18, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_19, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_20, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_21, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_22, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_23, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_24, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_25, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_26, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_27, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_28, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_29, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_30, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_31, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_32, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_33, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_34, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_35, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_36, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_37, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_38, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_39, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_40, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_41, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_42, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_43, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_44, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_45, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_46, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_47, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_48, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_49, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_50, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_51, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_52, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_53, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_22_54, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_55, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_56, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_57, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_58, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_59, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_22_60, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_61, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_62, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_63, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_22_64, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_65, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_66, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_67, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_22_68, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_69, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_70, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_71, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_22_72, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_22_73, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_22_74, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_22_222, ';', '.')                               || ';' ||
            TRANSLATE(C.P1_23_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_6, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_7, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_8, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_9, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_23_10, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_23_11, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_23_12, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_23_13, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_23_99, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_24_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_24_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_24_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_24_5, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_24_6, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_24_7, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_24_8, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_24_9, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_24_10, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_24_11, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_24_12, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_24_13, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_24_14, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_24_15, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_24_16, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_24_17, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_24_18, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_24_19, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_20, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_21, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_22, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_22_1, ';', '.')                              || ';' ||
            TRANSLATE(C.P1_24_23, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_24_24, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_25, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_24_26, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_24_27, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_28, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_29, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_30, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_31, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_24_32, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_24_33, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_34, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_35, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_36, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_37, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_97, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_98, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_24_99, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_25_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_25_2, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_25_3, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_25_4, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_25_5, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_25_6, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_25_7, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TO_CHAR(C.P1_25_8, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_25_99, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_26_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_26_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_26_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_26_99, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_27_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_27_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_27_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_27_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_27_99, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_28_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_28_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_28_3, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_28_4, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_28_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_28_6, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_28_7, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_28_8, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TO_CHAR(C.P1_28_9, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_28_10, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_28_11, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_28_12, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_28_13, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_28_14, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_29_1, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_29_2, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_29_3, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_29_4, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_29_5, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_29_6, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_30_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_30_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_30_3, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_30_4, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_30_5, ';', '.')                                 || ';';

        v_ligne := v_ligne ||
            TO_CHAR(C.P1_30_6, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_30_7, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_30_8, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_30_9, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_30_10, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_30_11, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_30_12, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_30_13, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_30_14, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_30_15, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_16, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_30_17, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_30_18, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_19, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_30_20, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_30_21, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_22, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_23, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_24, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_25, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_26, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_30_27, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_2, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_3, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_31_4, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_31_5, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_6, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_7, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_8, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_9, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_31_10, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_11, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_12, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_13, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_14, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_15, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_31_16, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_17, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_18, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_19, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_31_20, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_21, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_22, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_23, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_31_24, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_25, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_26, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_27, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_28, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TO_CHAR(C.P1_31_29, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_31_30, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_31, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_32, 'YYYYMMDDHH24MISS')                        || ';' ||
            TO_CHAR(C.P1_31_33, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_31_34, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_35, 'YYYYMMDDHH24MISS')                        || ';' ||
            TRANSLATE(C.P1_31_36, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_37, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_31_38, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TRANSLATE(C.P1_31_51, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_31_52, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_31_53, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_50_1, ';', '.')                                 || ';' ||
            TRANSLATE(C.P1_50_2, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_50_3, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_50_4, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_50_5, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_50_8, ';', '.')                                 || ';' ||
            TO_CHAR(C.P1_50_9, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')     || ';' ||
            TRANSLATE(C.P1_50_14, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_50_15, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_50_16, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_50_17, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_50_18, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_50_19, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_50_20, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_50_21, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')    || ';' ||
            TRANSLATE(C.P1_99_99, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_600, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_601, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_602, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_603, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_603_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_604, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_604_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_605, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_605_1, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_606, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_607, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_608, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_608_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_609, 'YYYYMMDDHH24MISS')                          || ';' ||
            TO_CHAR(C.P1_610, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_610_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_611, 'YYYYMMDDHH24MISS')                          || ';' ||
            TO_CHAR(C.P1_612, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_612_1, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_613, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_614, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_614_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_615, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_616, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_617, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_618, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_619, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_620, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_622, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_623, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_624, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_625, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_626, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_627, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_628, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_628_1, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_629, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_630, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_630_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_631, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_631_1, ';', '.')                                || ';';

        v_ligne := v_ligne ||
            TO_CHAR(C.P1_632, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_632_1, ';', '.')                                || ';' ||
            TO_CHAR(C.P1_633, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')      || ';' ||
            TRANSLATE(C.P1_633_1, ';', '.')                                || ';' ||
            TRANSLATE(C.P1_635, ';', '.')                                  || ';' ||
            TRANSLATE(C.P1_621, ';', '.')                                  || ';' ||
            TO_CHAR(C.P1_1001, 'YYYYMMDDHH24MISS')                         || ';' ||
            TO_CHAR(C.P1_1002, 'YYYYMMDDHH24MISS')                         ;

        UTL_FILE.PUT_LINE(v_fic, v_ligne);
        v_nb := v_nb + 1;
    END LOOP;

    -- Rodape: o numero de linhas de detalhe, em 12 digitos.
    UTL_FILE.PUT_LINE(v_fic, '99' || ';'
        || TO_CHAR(v_nb, 'FM000000000000'));

    UTL_FILE.FCLOSE(v_fic);
    DBMS_OUTPUT.PUT_LINE('P_HIST_ENG_CORP_P1_BIS : ' || v_nb || ' lignes, arrete '
        || TO_CHAR(v_arrete, 'DD/MM/YYYY'));

EXCEPTION
    WHEN OTHERS THEN
        -- fecha o ficheiro antes de propagar, senao o descritor fica preso
        IF UTL_FILE.IS_OPEN(v_fic) THEN
            UTL_FILE.FCLOSE(v_fic);
        END IF;
        RAISE;
END P_HIST_ENG_CORP_P1_BIS;

END PACK_HIST_ENG_CORP_P1_BIS;
/
