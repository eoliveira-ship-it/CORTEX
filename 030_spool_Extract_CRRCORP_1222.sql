-- =====================================================================
-- 030_spool_Extract_CRRCORP_1222.sql               (SIRL-1222)
--
-- O pave P1 com separador ";" entre todos os campos. Parte do spool vPACT
-- (SIRL-1224 + 1223) e troca a forma de montar a linha: cada campo da
-- notice V45.02 e escrito separado, seguido de ";".
--
-- A LINHA        663 campos: 6162 de dados + 662 separadores + filler
--                final de 1176 = 8000 caracteres. O ultimo campo (o
--                filler) NAO leva ";" depois. Os 51 campos criados na
--                V45 sao escritos, em branco, lendo as colunas da tabela.
--
-- DUAS COLUNAS  a linha e montada em colunas que o SQL*Plus escreve
--                lado a lado, com um espaco entre elas (o COLSEP, que nao
--                se desliga). 4000 + 1 + 3999 = 8000, como nos outros
--                paves. O corte cai dentro do filler P1 25.99, em branco:
--                39 na coluna 1, o espaco do COLSEP, 60 na coluna 2.
--                O CAST fixa a largura de cada coluna.
--
-- Os restantes paves (P2, M1, P9, C1, F1, F2) ficam como estavam: o P1 e
-- o piloto, para validar a convencao antes de a repetir sete vezes.
--
-- GERADO por gen_spool_1222.py -- nao editar a mao.
-- =====================================================================
-- =====================================================================
-- 030_spool_Extract_CRRCORP_vPACT.sql          (SIRL-1224)
--
-- Versao vPACT do 030_spool_Extract_CRRCORP.sql : o pave P1 deixa de ser
-- calculado aqui. As regras de negocio passaram para a procedure
-- pack_alim_tab_envoi_crrv4.P_ALIM_ENG_CORP_P1_BIS, que alimenta a
-- tabela ENG_CORP_P1_BIS. Aqui fica so a formatacao.
--
-- Os 8 select sobre ENG_CORP_P1 dao lugar a 6 select sobre a tabela:
--   1 para o perimetro NAT02  (variantes 1-3, que partilham o layout,
--     o que esta provado por dados: 113368 registos byte a byte iguais)
--   5 para o Hors NAT02       (variantes 4-8, uma cada, porque cada uma
--     escreve campos DIFERENTES nas mesmas posicoes da linha)
--
-- Ficam nos dois lugares que os blocos originais ocupavam, porque o
-- ficheiro traz as variantes 1-3 antes dos paves P2/M1/P9 e as 4-8
-- depois. Assim o ficheiro sai na mesma ordem.
--
-- Os restantes paves (C1/C5, P2, M1, P9) ficam exatamente como estavam.
--
-- SIRL-1223 : P1 21.65 passa de 5 para 50 (notice V45.00). Os campos
-- seguintes andam 45 posicoes; os comentarios pos ja o refletem.
--
-- GERADO por gen_spool_vpact.py -- nao editar a mao.
-- =====================================================================
--------------------------------------------------------------------------------
-- CAL-Version : 1.31                                                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Script        : 030_spool_Extract_CRRCORP.sql                              --
-- Objet         : spool fichier Export_CRRCORP                               --
-- Type          : Script SQL et PL/SQL                                       --
--------------------------------------------------------------------------------
-- Domaine       : RINT                                                       --
-- Application   : 030  - Declarations Des Risques                            --
--------------------------------------------------------------------------------
-- Notice        : CRRCV4.4_Grande ClientËle_Corporate_V44.02.xlsx            --
--------------------------------------------------------------------------------
-- Creation      : le 18/05/2021 par DUGUET MARC                              --
-- Modifications :                                                            --
--------------------------------------------------------------------------------
-- 18/03/2026 MESQUIPE: SIRL-500 - [QDD B‚le 4] Absence mnt acquisition dans  --
--                                 extraction CRR                             --
-- 22/01/2026 GOMESHU : Projet FED- CRR C3RD                                  --
-- 19/01/2026 GOMESHU : SIRL-519                                              --
-- 25/09/2025 ALMEIDBR: SIRL-378 - QDD M1:50.2 + M1:50.3                      -- 
-- 23/07/2025 ALMEIBR : v1.28 + projet OMP > SIRL-191                         --
-- 05/03/2025 CUNHAVI : M73513 - Correction 72074 qui a introduit un score 7  --
-- 03/03/2025 GOMESHU : M73302 - P1 30.20 et P1 30.17                         --
-- 06/12/2024 KLx_Risq: M_72574 - score 7: P1 22.45 devise du mnt du bien fin --
-- 03/11/2024 GOMESHU : M71371                                                --
-- 30/10/2024 BARTOLMI: M72074 - QDD                                          -- 
-- 23/09/2024 BARTOLMI: M71368                                                --
-- 12/07/2024 KLx_Risq: Score 7                                               --
-- 10/01/2024 GOMESHU : BALE4                                                 --
-- 29/01/2024 KLx_Risq: v1.24 + M67006: evolution sur alimentation P9 1.16    --
-- 24/01/2024 KLx_Risq: v1.23 + M67006 - modification extractions C_CRD_B1_B2 --
--                      , C_SOLD_B1_B2 et C_PNU_B1_B2                         --
-- 14/06/2023 GOMESHU : Mantis 66813                                          --
-- 23/03/2023 GOMESHU : Mantis 65476 - Alimentation P1 3.40                   --
-- 09/01/2023 GOMESHU : Mantis 64749 - Alimentation P1 31.9 31.10             --
-- 16/11/2022 CUNHAVI : Mantis 64443 - Correction Score 7 - non alimentation  --
--                      de P9 1.20                                            --
-- 04/02/2022 CUNHAVI : Mantis 11841 - Taille Ligne                           --
-- 07/01/2022 CUNHAVI : CRRV4.3 Correction US 278 - P2 50.4 et 50.5           --
-- 06/01/2022 ALMEIDBR: US275 - Score 6 Duree initiale/totale du pret         --
-- 23/12/2021 CUNHAVI : Correction formatage Date US 273 CRRv4.3              --
-- 14/12/2021 CUNHAVI : CRRV4.3 Correction US 260 - TOP_ENG_DOUTEUX           --
-- 07/12/2021 CUNHAVI : 1.13 Corriger CRRv4.3                                 --
-- 06/12/2021 CUNHAVI : 1.11 + US 262 + US 263 (Partial) CRRv4.3              --
-- 06/12/2021 GOMESHU : v1.10 + CRRV4.3 US 265 (P1)                           --
-- 06/12/2021 GOMESHU : v1.9 + CRRV4.3 US 265                                 --
-- 02/12/2021 CUNHAVI : CRRV4.3 US 261                                        --
-- 13/09/2021 DUGUETMA : M11667                                               --
-- 08/09/2021 DUGUETMA : MR11664 MR11665 MR11666                              --
-- 31/08/2021 MIPAMES : Correction score 7                                    --
-- 28/07/2021 DUGUETMA : Mantis 11611 (recette)                               --
-- 23/07/2021 MIPAMES : Rajout CD_AGENT_ECO US 92 CRRv4.3                     --
-- 19/07/2021 MIPAMES : Retrait CD_AGEBT_ECO                                  --
-- 13/07/2021 MIPAMES : US 194 CRRv4.3                                        --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- spool fichier Export_CRRCORP

/*
Nom du fichier d'export : en parametre 2 
Creation dans le repertoire : en parametre 1
2 bind variable : 
       ENTITE  : entite a extraire (= cd_conso_cpt )
       MASYSDATE : date d'extraction (yyyymmddHHMI): idem sur ttes les lignes et l'entete
Formats  :  char 4201

   /!\    Dans les select : pas de lignes vides , 
  / ! \                     pas de point-virgule dans commentaires
  -----   

select ( champ1 || champ2 ) as lignedetail1 from table : lignedetail1 limitÔøΩ a 4000 car 
Pour avoir les 4201 car : 
select ( champ1 || champ2 ) as lignedetail1, champ3 as lignedetail2  from table  : 
le spool va ecrire la ligne "lignedetail1 lignedetail2"  (avec 1 blanc entre les 2)
On va determiner les tailles de lignedetail1 et lignedetail2 de facon a ce que le
blanc entre les 2 corresponde a une valeur a extraire toujours renseignee a blanc

requetes developpees a partir de 030_create_pack_utl_file_envoi_crrv4.sql  v1.98
*/


SET TERM OFF
SET serveroutput on size unlimited;
SET sqlprompt ""
SET SHOWMODE OFF
SET SHOW OFF
SET VERIFY OFF
SET PAGESIZE 0
SET ECHO OFF
SET HEADING OFF
SET FEED OFF
set trimspool OFF
--30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
--SET linesize 4201   --4201  mais requete SQL limite ÔøΩ 4000 !
-- Mantis 11841 - Modification linesize
--SET linesize 5099   --5100  mais lignedetail1 fera 4000 et lignedetail2 fera 1099
--SET linesize 5699   --5100  mais lignedetail1 fera 4000 et lignedetail2 fera 1099
SET linesize 8000   --8000  mais lignedetail1 fera 4000 et lignedetail2 fera 3999
--Fin EMM


-- append : ecriture du spool a la suite de la ligne ENTETE ecrite ds shell
spool &1/&2 append;

------------------------------------------------------------------------------------------------------------------------
-- ENTETE : ecrite ds shell
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- ÔøΩ01: a partir de P_UTLF_TIERS_C1 
-- 2 select 
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- ÔøΩ01a: a partir de C_C1 
------------------------------------------------------------------------------------------------------------------------
select 
        to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       -- Retour arriere scores 7 - annulation 731 pour appli_source dans l utl file
       -- 18/02/2019 - CDS ATOS (GBD) - US731 >remplace 
       (
       CASE WHEN C_ENR.FLAG_HN = 'N' THEN
             RPAD('C_BTR', 12)
       ELSE
             RPAD('C_DDR', 12)
        END)||
       -- 18/02/2019 - CDS ATOS (GBD) - US731
       'M'||
       :MASYSDATE||
       'C1'||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
       RPAD(' ', 10)||
       RPAD(' ', 30)||
       RPAD(' ', 30)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(NVL(translate(upper(C_ENR.NOM_TIERS), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 40)||
       --RPAD(NVL(translate(upper(C_ENR.RAISON_SOCLE), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 90)||
       TO_CHAR(nvl(C_ENR.DT_REVISION_NOTE,sysdate),'YYYYMMDDHH24MISS')|| -- a modifier
-- 29/05/2018 CDS Atos (JMP) ANACREDIT  US346 
-- Remplacement de la zone libre de 76 blancs par :
-- * 25 Blancs destinÔøΩs ÔøΩ C 14.30 ÔøΩ C 14.34 dans les US a venir,
-- * Le nombre de salariÔøΩs sur 6 chiffres,
-- * Puis 45 Blancs.
       --07/01/2019 CDS Atos (SQN) US 615
--       RPAD(' ',76)||
--       RPAD(' ',25)|| On split le 25 en 10+1+5+1+8 pour C 14.30 ÔøΩ C 14.34
       -- 13/05/2019 - CDS ATOS (LFD) - US 791
       --RPAD(' ',10)||--RPAD(NVL(C_ENR.ID_ENT_MERE_IMMEDIAT, ' '), 10)||
       --RPAD(' ',1)||--RPAD(NVL(C_ENR.IND_ENT_MERE_IMMEDIAT, ' '), 1)||
       RPAD(NVL(C_ENR.ID_ENT_MERE_IMMEDIAT, ' '), 10)||
       RPAD(NVL(C_ENR.IND_ENT_MERE_IMMEDIAT, ' '), 1)||
       -- FIN LFD
       RPAD(NVL(C_ENR.CD_NUTS, ' '), 5)||
       RPAD(NVL(C_ENR.ETAT_AVNCT_PJ, ' '), 1)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_OUV_PJ, 'YYYYMMDD'), ' '),8)||
       LPAD(NVL(to_char(C_ENR.NB_SALARIE), '      '),6,'0')||
       --30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
		RPAD(NVL(C_ENR.IND_CEL, ' '), 1) ||
		RPAD(NVL(C_ENR.NIV_INTG_GROUPE_TIE, ' '), 1) ||
		RPAD(NVL(C_ENR.IND_OPCVM_EFFET_LEV, ' '), 1) ||
		RPAD(' ', 4) ||
		RPAD(NVL(C_ENR.CD_AGENT_ECO, ' '), 6) ||
		RPAD(' ', 4)||
		RPAD(' ', 21)||
		RPAD(' ', 6)||
		RPAD(' ',1)||
		--Fin EMM 
       --Fin SQN
-- Fin 29/05/2018 CDS Atos (JMP) ANACREDIT  US346        
       RPAD(NVL(C_ENR.REF_IDENT_NATIO, ' '), 2)||
       RPAD(NVL(C_ENR.IDENT_NATIO, ' '), 20)||
       --30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 1)||
	   RPAD(' ', 10)||
	   RPAD(' ', 1)||
		--Fin EMM
       RPAD(NVL(C_ENR.AGENCE_NOTATION, ' '), 2)||
       RPAD(NVL(C_ENR.CD_TYPE_COTATION, ' '), 2)||
       RPAD(NVL(C_ENR.COTATION, ' '), 10)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_COTATION, 'YYYYMMDD'), ' '),8)||
       RPAD(NVL(C_ENR.CD_PAYS_NATIONALITE, ' '), 2)||
       RPAD(NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), 2)||
       RPAD(NVL(C_ENR.CD_PAYS_CONTROLE, ' '), 2)||
       RPAD(NVL(translate(upper(C_ENR.ADRESSE), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 70)||
       RPAD(NVL(translate(upper(C_ENR.VILLE), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 30)||
       RPAD(NVL(C_ENR.CD_POSTAL, ' '), 15)||
       --29/01/2019 CDS Atos (SQN) US 649
       --15/01/18 CDS ATOS (EMM) Sprint 3 US 2 Rework
       --(CASE WHEN C_ENR.NOTE_INTERNE <> 'ND' THEN RPAD(NVL(TO_CHAR(C_ENR.DT_CLOTURE_CPT_NOTE, 'YYYYMMDD'), ' '), 8) ELSE RPAD(' ', 8) END)||
       --Fin EMM
       RPAD(NVL(TO_CHAR(C_ENR.DT_CLOTURE_CPT_NOTE, 'YYYYMMDD'), ' '), 8)||
       --Fin SQN
       RPAD(NVL(C_ENR.NOTE_INTERNE, ' '), 2)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_REVISION_NOTE, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_ENTREE_DEFAUT, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(C_ENR.CD_METHODO_NOTE, ' '), 3)||
       RPAD(NVL(C_ENR.CD_MOTIF_NOTE, ' '), 3)||
       RPAD(NVL(C_ENR.NOTE_NAFA, ' '),2)||
       RPAD(NVL(C_ENR.NOTE_APR_CORR_GRPE,' '),2)||
       ' '||
       RPAD(NVL(C_ENR.CD_GRILLE_NOTE, ' '), 46)||
       RPAD(NVL(C_ENR.CD_CATEG_CONTREPARTIE, ' '), 5)||
       RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BAL_TIERS, ' '), 3)||
       RPAD(NVL(C_ENR.CD_SECTEUR_ACTIVITE, ' '), 6)||
       '  '||
       RPAD(NVL(C_ENR.CD_NORME_LOCAL_ACT, ' '), 1)||
       RPAD(NVL(C_ENR.CD_ACTIVITE_LOCALE, ' '), 6)||
       --RPAD(NVL(C_ENR.CD_FORM_JUR, ' '), 2)|| -- BALE4
       RPAD(NVL(C_ENR.IND_RATIO_CET, ' '), 1)|| -- C1 8.81 pos 694 - BALE4
       RPAD(NVL(C_ENR.IND_RATIO_LEVIER, ' '), 1)|| -- C1 8.82 pos 695 - BALE4
       LPAD(NVL(to_char(C_ENR.CD_STATUT_FILIATION), ' '), 1)||
       RPAD(NVL(C_ENR.IND_WL, '9'), 1)|| --C1 4.18	Indicateur Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.23	Date d'entrÈe en Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.24	Date de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_WL_CASA  , ' '), 2)||--C1 4.25	Motif d'entrÈe en Watch List
       RPAD(NVL(C_ENR.CD_MOTIF_SORTIE_WL, ' '), 5)||--C1 4.26	Motif de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_ACTEUR, ' '), 26)||
       '  '||
       RPAD(NVL(C_ENR.CD_TYPE_RELATION, ' '), 1)||
       --29/01/2019 CDS Atos (SQN) US 649
       --(CASE WHEN length(to_char(C_ENR.MNT_CA)) > 12 THEN RPAD(' ', 12) WHEN C_ENR.MNT_CA < 0 THEN RPAD(' ', 12) WHEN C_ENR.MNT_CA > 0 THEN LPAD(NVL(to_char(C_ENR.MNT_CA), ' '), 12, 0) ELSE RPAD(' ', 12) END)||
       -- US739 LPAD(NVL(to_char(C_ENR.MNT_CA), ' '), 12, 0)||  
       LPAD(NVL(C_ENR.MNT_CA, '0'), 12, 0)||  -- 27/02/2019 - CDS ATOS (GBD) - US739  (C1 5.2) (col 750) Chiffre d'affaire
       --Fin SQN
       RPAD(NVL(C_ENR.TOP_CA_CONSO, ' '), 1)||
       RPAD(NVL(C_ENR.CD_DEVISE_CA, ' '), 3)||
       LPAD(NVL(to_char(C_ENR.ANNEE_CA), ' '), 4, ' ')||
       ' '||
       LPAD(nvl(C_ENR.NBRE_JOUR_EXERCICE, 0), 3, 0)||
       NVL(C_ENR.NATURE_CA, ' ')||
       LPAD(NVL(C_ENR.CA_IFRS, 0),12, 0)||
       NVL(C_ENR.RES_NET_RETRAITE_SIGN, ' ')||
       LPAD(NVL(C_ENR.RES_NET_RETRAITE_MNT,0),12,0)||
       ' '||
       RPAD(NVL(C_ENR.CD_ACTIVITE_LOCALE, ' '),6)||
       NVL(C_ENR.STATUT_ACTIVITE_LOC,'A')||
       RPAD(NVL(TO_CHAR(C_ENR.DT_STATUT_ACTIVITE_LOC, 'YYYYMMDD'), ' '),8)||
       RPAD(NVL(C_ENR.REF_IDENT_NAT_2, ' '),2)||    --- champ ref_ident_nat_2 de 2 caracteres dans la table -- 18/02/2019 - CDS ATOS (GBD) - US731  (C1 8.6)
       RPAD(NVL(C_ENR.IDENT_NATION_2, ' '), 20)||
       RPAD(NVL(translate(upper(NVL(C_ENR.RAIS_SOCL_KBIS,C_ENR.RAISON_SOCLE)), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 114)||
       LPAD(NVL(C_ENR.TOT_BILAN_RETRAITE, 0),15,0)||
       '     '||
       RPAD(NVL(C_ENR.CD_SECT_RISQ_SYST, ' '),6)||
       '  '||
       RPAD(NVL(C_ENR.NOTE_CALC_FIN,' '),2)||
	   --30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 7)|| 		--C1 8.16
	   LPAD(' ', 3011) 		--4000 - 989
     as lignedetail1,  -- debut ligne (taille <= 4000)
     -- (compter 1 blanc de separation entre les 2 champs dans le spool)
       LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841  
     as lignedetail2
		--Fin EMM
    From  tie_tiers_c1_c5 C_ENR
    Where C_ENR.a_extraire = 'O'
    AND C_ENR.CD_TYPE_SEGMENT = 'CORP'
    and (cd_conso_cpt = :ENTITE  or :ENTITE = 'TOTAL' );

------------------------------------------------------------------------------------------------------------------------
-- ÔøΩ01b: a partir de C_C2 
------------------------------------------------------------------------------------------------------------------------
select   
          to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       -- Retour arriere scores 7 - annulation 731 pour appli_source dans l utl file
       -- 18/02/2019 - CDS ATOS (GBD) - US731  >remplace
       RPAD('R_BTR', 12)||
       -- 18/02/2019 - CDS ATOS (GBD) - US731
       'M'||
       :MASYSDATE||
       'C1'||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
       RPAD(' ', 10)||
       RPAD(' ', 30)||
       RPAD(' ', 30)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(NVL(translate(upper(C_ENR.NOM_TIERS), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 40)||
       --RPAD(NVL(translate(upper(C_ENR.RAISON_SOCLE), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 90)||
       TO_CHAR(nvl(C_ENR.DT_REVISION_NOTE,sysdate),'YYYYMMDDHH24MISS')|| --a modifier
       --07/01/2019 CDS Atos (SQN) US 615
       --RPAD(' ',76)||
      -- 13/05/2019 - CDS ATOS (LFD) - US 791
       --RPAD(' ',10)||--RPAD(NVL(C_ENR.ID_ENT_MERE_IMMEDIAT, ' '), 10)||
       --RPAD(' ',1)||--RPAD(NVL(C_ENR.IND_ENT_MERE_IMMEDIAT, ' '), 1)||
       RPAD(NVL(C_ENR.ID_ENT_MERE_IMMEDIAT, ' '), 10)||
       RPAD(NVL(C_ENR.IND_ENT_MERE_IMMEDIAT, ' '), 1)||
       -- FIN LFD
       RPAD(NVL(C_ENR.CD_NUTS, ' '), 5)||
       RPAD(NVL(C_ENR.ETAT_AVNCT_PJ, ' '), 1)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_OUV_PJ, 'YYYYMMDD'), ' '),8)||
       LPAD(NVL(to_char(C_ENR.NB_SALARIE), '      '),6,'0')||
       --30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(NVL(C_ENR.IND_CEL, ' '), 1) ||
		RPAD(NVL(C_ENR.NIV_INTG_GROUPE_TIE, ' '), 1) ||
		RPAD(NVL(C_ENR.IND_OPCVM_EFFET_LEV, ' '), 1) ||
		RPAD(' ', 4) ||
		RPAD(NVL(C_ENR.CD_AGENT_ECO, ' '), 6) ||
		RPAD(' ', 4)||
		RPAD(' ', 21)||
		RPAD(' ', 6)||
		RPAD(' ',1)||
       --Fin EMM 
       --Fin SQN
       RPAD(NVL(C_ENR.REF_IDENT_NATIO, ' '), 2)||
       RPAD(NVL(C_ENR.IDENT_NATIO, ' '), 20)||
       --30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 1)||
	   RPAD(' ', 10)||
	   RPAD(' ', 1)||
	  --Fin EMM
       RPAD(NVL(C_ENR.AGENCE_NOTATION, ' '), 2)||
       RPAD(NVL(C_ENR.CD_TYPE_COTATION, ' '), 2)||
       RPAD(NVL(C_ENR.COTATION, ' '), 10)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_COTATION, 'YYYYMMDD'), ' '),8)||
       RPAD(NVL(C_ENR.CD_PAYS_NATIONALITE, ' '), 2)||
       RPAD(NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), 2)||
       RPAD(NVL(C_ENR.CD_PAYS_CONTROLE, ' '), 2)||
       RPAD(NVL(translate(upper(C_ENR.ADRESSE), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 70)||
       RPAD(NVL(translate(upper(C_ENR.VILLE), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 30)||
       RPAD(NVL(C_ENR.CD_POSTAL, ' '), 15)||
       --29/01/2019 CDS Atos (SQN) US 649
       --15/01/18 CDS ATOS (EMM) Sprint 3 US 2 Rework
       --(CASE WHEN C_ENR.NOTE_INTERNE <> 'ND' THEN RPAD(NVL(TO_CHAR(C_ENR.DT_CLOTURE_CPT_NOTE, 'YYYYMMDD'), ' '), 8) ELSE RPAD(' ', 8) END)||
       --Fin EMM
       RPAD(NVL(TO_CHAR(C_ENR.DT_CLOTURE_CPT_NOTE, 'YYYYMMDD'), ' '), 8)||
       --Fin SQN
       RPAD(NVL(C_ENR.NOTE_INTERNE, ' '), 2)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_REVISION_NOTE, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_ENTREE_DEFAUT, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(C_ENR.CD_METHODO_NOTE, ' '), 3)||
       RPAD(NVL(C_ENR.CD_MOTIF_NOTE, ' '), 3)||
       RPAD(NVL(C_ENR.NOTE_NAFA, ' '),2)||
       RPAD(NVL(C_ENR.NOTE_APR_CORR_GRPE,' '),2)||
       ' '||
       RPAD(NVL(C_ENR.CD_GRILLE_NOTE, ' '), 46)||
       RPAD(NVL(C_ENR.CD_CATEG_CONTREPARTIE, ' '), 5)||
       RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BAL_TIERS, ' '), 3)||
       RPAD(NVL(C_ENR.CD_SECTEUR_ACTIVITE, ' '), 6)||
       '  '||
       RPAD(NVL(C_ENR.CD_NORME_LOCAL_ACT, ' '), 1)||
       RPAD(NVL(C_ENR.CD_ACTIVITE_LOCALE, ' '), 6)||
       --RPAD(NVL(C_ENR.CD_FORM_JUR, ' '), 2)|| -- BALE4
       RPAD(NVL(C_ENR.IND_RATIO_CET, ' '), 1)|| -- C1 8.81 pos 694 - BALE4
       RPAD(NVL(C_ENR.IND_RATIO_LEVIER, ' '), 1)|| -- C1 8.82 pos 695 - BALE4
       LPAD(NVL(to_char(C_ENR.CD_STATUT_FILIATION), ' '), 1)||
       RPAD(NVL(C_ENR.IND_WL, '9'), 1)|| --C1 4.18	Indicateur Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.23	Date d'entrÈe en Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.24	Date de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_WL_CASA  , ' '), 2)||--C1 4.25	Motif d'entrÈe en Watch List
       RPAD(NVL(C_ENR.CD_MOTIF_SORTIE_WL, ' '), 5)||--C1 4.26	Motif de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_ACTEUR, ' '), 26)||
       '  '||
       RPAD(NVL(C_ENR.CD_TYPE_RELATION, ' '), 1)||
       --29/01/2019 CDS Atos (SQN) US 649
       --(CASE WHEN length(to_char(C_ENR.MNT_CA)) > 12 THEN RPAD(' ', 12) WHEN C_ENR.MNT_CA < 0 THEN RPAD(' ', 12) WHEN C_ENR.MNT_CA > 0 THEN LPAD(NVL(to_char(C_ENR.MNT_CA), ' '), 12, 0) ELSE RPAD(' ', 12) END)||
       --US739 LPAD(NVL(to_char(C_ENR.MNT_CA), ' '), 12, 0)||
       LPAD(NVL(C_ENR.MNT_CA, '0'), 12, 0)||  -- 27/02/2019 - CDS ATOS (GBD) - US739  (C1 5.2) (col 750) Chiffre d'affaire
       --Fin SQN
       RPAD(NVL(C_ENR.TOP_CA_CONSO, ' '), 1)||
       RPAD(NVL(C_ENR.CD_DEVISE_CA, ' '), 3)||
       LPAD(NVL(to_char(C_ENR.ANNEE_CA), ' '), 4, ' ')||
       ' '||
       LPAD(nvl(C_ENR.NBRE_JOUR_EXERCICE, 0), 3, 0)||
       NVL(C_ENR.NATURE_CA, ' ')||
       LPAD(NVL(C_ENR.CA_IFRS, 0),12, 0)||
       NVL(C_ENR.RES_NET_RETRAITE_SIGN, ' ')||
       LPAD(NVL(C_ENR.RES_NET_RETRAITE_MNT,0),12,0)||
       ' '||
       RPAD(NVL(C_ENR.CD_ACTIVITE_LOCALE, ' '),6)||
       NVL(C_ENR.STATUT_ACTIVITE_LOC,' ')||
       RPAD(NVL(TO_CHAR(C_ENR.DT_STATUT_ACTIVITE_LOC, 'YYYYMMDD'), ' '),8)||
       RPAD(NVL(C_ENR.REF_IDENT_NAT_2, ' '),2)||    --- champ ref_ident_nat_2 de 2 caracteres dans la table -- 18/02/2019 - CDS ATOS (GBD) - US731  (C1 8.6)
       RPAD(NVL(C_ENR.IDENT_NATION_2, ' '), 20)||
       RPAD(NVL(translate(upper(NVL(C_ENR.RAIS_SOCL_KBIS,C_ENR.RAISON_SOCLE)), '¿¬«…» ÀŒ›‘÷Ÿ€‹', 'AACEEEEIIOOUUU'), ' '), 114)||
       LPAD(NVL(C_ENR.TOT_BILAN_RETRAITE, 0),15,0)||
       '     '||
       RPAD(NVL(C_ENR.CD_SECT_RISQ_SYST, ' '),6)||
       '  '||
       RPAD(NVL(C_ENR.NOTE_CALC_FIN,' '),2)||
	   --30/06/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 7)||
       LPAD(' ', 3011) ---4000 - 989
     as lignedetail1,  -- debut ligne (taille <= 4000)
     -- (compter 1 blanc de separation entre les 2 champs dans le spool)
       LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
	 as lignedetail2
	 --Fin EMM
    From  tie_tiers_c1_c5 C_ENR
    Where C_ENR.a_extraire = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE  or :ENTITE = 'TOTAL' )
    AND C_ENR.CD_TYPE_SEGMENT = 'CORP'
    AND C_ENR.FLAG_HN='N'
    AND C_ENR.ID_TIERS_CALC IN (SELECT ID_TIERS_CALC_GARANT FROM SURETE_AGREG_M5 WHERE A_EXTRAIRE='O') ;



------------------------------------------------------------------------------------------------------------------------
-- ÔøΩ02: a partir de P_UTLF_AUTORISATION_F1     
------------------------------------------------------------------------------------------------------------------------
select
       to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       -- 23/01/18 - CDS ATOS (LFD) - CRRV4.2 US 652
       --RPAD('C_BTR', 12)||
       RPAD(C_ENR.APPLI_SOURCE, 12)||
       -- FIN LFD
       'M'||
       :MASYSDATE||
       'F1'||
       RPAD(' ', 10)||  -- longueur : 1+2+7
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(' ', 30)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(' ', 50)||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD(NVL(C_ENR.id_tiers_calc,' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '), 10)||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.cd_type_ope,' '), 2)||
       RPAD(NVL(C_ENR.cd_objet_credit,' '), 2)||
       RPAD(NVL(C_ENR.cd_hierarchie_accord,' '), 2)||
       RPAD(NVL(C_ENR.cd_confirmation_auto,' '), 1)||
       pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_GLOBAL_INITIAL,0))||
       pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_GLOBAL_REVISE,0))||
       RPAD(NVL(C_ENR.CD_DEVISE_AUTO, ' '), 3)||
       RPAD(NVL(C_ENR.top_auto_specifique,' '), 1)||
       --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 4)||
	   RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '), 6,' ')|| 
       RPAD(' ', 10)||
       -- Fin EMM 
       RPAD(NVL(TO_CHAR(C_ENR.dt_deb_validite_auto, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.dt_fin_validite_auto, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.dt_fin_validite_auto, 'YYYYMMDD'), ' '), 8)||
       RPAD(' ', 8)||
       RPAD(' ', 20)||
       RPAD(NVL(C_ENR.top_syndication,' '), 1)||
       RPAD(NVL(C_ENR.cd_position_entite_risque,' '), 1)||
       RPAD(NVL(C_ENR.cd_entite_groupe_pilote,' '), 5)||
       RPAD(' ', 20)||
       RPAD(' ', 10)||
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_INIT_GLOB_BANQ_TT_TRANCHES),0))||
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_MAJ_GLOB_BANQ_TT_TRANCHES),0))||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_SYND_TT_TRANCHES,'EUR'), 3)||
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_INIT_GLOB_BANQ_TRANCHE_AUT),0))||
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_MAJ_GLOB_BANQ_TRANCHE_AUT),0))||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_SYND_TRANCHE_AUT,'EUR'), 3)||
       -- 23/01/18 - CDS ATOS (LFD) - CRRV4.2 US 652
       --CASE WHEN C_ENR.TOP_SYNDICATION='N' THEN RPAD(' ', 10) ELSE pack_utilitaire.f_format_taux(C_ENR.TX_PART_RISK_TRANCHE) END||
       CASE WHEN C_ENR.TX_PART_RISK_TRANCHE is null THEN RPAD(' ', 10) ELSE pack_utilitaire.f_format_taux(C_ENR.TX_PART_RISK_TRANCHE) END||
       -- FIN LFD
       RPAD(' ', 1)||RPAD(' ', 16)||RPAD(' ', 2)||
       RPAD(' ', 1)||RPAD(' ', 4)||RPAD(' ', 5)||
       RPAD(' ', 1)||RPAD(' ', 16)||RPAD(' ', 2)||
       --23/01/2019 CDS Atos (SQN) US 655
       --RPAD(' ', 20)||
       RPAD(' ', 4)||
       -- 06/02/2019 - CDS ATOS (LFD) - US655 CORRECTION
       --CASE WHEN C_ENR.TOP_SYNDICATION = 'Y' THEN 'L' END|| --IND_POSITION_ENTITE
       CASE WHEN C_ENR.TOP_SYNDICATION = 'Y' THEN 'L' ELSE ' ' END|| --IND_POSITION_ENTITE
       -- FIN LFD
       --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD('0', 1)||		--F1 4.18
	   RPAD('T', 1)||		--f1 4.19
	   RPAD(' ', 13)||
	   -- FIN EMM
       --Fin SQN
       NVL(C_ENR.top_titrisation,' ')||
       RPAD(' ', 20)||
       RPAD(' ', 10)||
       RPAD(' ', 3)||
       RPAD(' ', 1)||
	   RPAD(' ', 16)||
	   RPAD(' ', 2)||
       RPAD(' ', 3)||
       RPAD(' ', 20)||
       -- 23/01/18 - CDS ATOS (LFD) - CRRV4.2 US 652
       --RPAD(NVL(C_ENR.cd_niv_seniorite,'SEN'), 3)||
       RPAD(NVL(C_ENR.cd_niv_seniorite,' '), 3)||
       -- FIN LFD
       RPAD(NVL(C_ENR.cd_segment_casa,' '), 3)||
       --12/09/2018 CDS Atos (EMM) US 509
       --CASE WHEN C_ENR.TOP_SYNDICATION='Y' THEN RPAD(NVL(C_ENR.ID_ENGAGEMENT,' '), 40) ELSE RPAD(' ', 40) END||
       --Fin EMM
       --09/11/2018 - CDS ATOS (LFD) - ANACREDIT US552
       RPAD(NVL(C_ENR.REF_SYNDICATION,' '), 40)||
       -- FIN LFD
	   --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20)|| --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Syst√®me de gestion source'
	   RPAD(' ', 5)||
       lPAD(' ', 3169)		--4000 - 831
     as lignedetail1,  -- debut ligne (taille <= 4000)
     -- (compter 1 blanc de separation entre les 2 champs dans le spool)
       LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
     as lignedetail2
	 --Fin EMM
    from
    AUTORISATION_F1  C_ENR  
    Where  A_EXTRAIRE = 'O'   
    and (C_ENR.cd_conso_cpt = :ENTITE  or :ENTITE = 'TOTAL' );


------------------------------------------------------------------------------------------------------------------------
-- ÔøΩ03: a partir de P_UTLF_AUTORISATION_DETAIL_F2
------------------------------------------------------------------------------------------------------------------------
select
         to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD('C_BTR', 12)||
       'M'||
       :MASYSDATE||
       'F2'||
       RPAD(' ', 10)||  -- longueur : 1+2+7 
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(NVL(C_ENR.CD_TYPE_RISQUE, ' '), 6)||
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_AUTORISE_ORIGINE),0))||
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_AUTORISE_REVISE),0))||
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_AUTORISE_LIGNE),0))||
       RPAD(NVL(C_ENR.CD_DEVISE_LIGNE_AUTO, ' '), 3)||
       RPAD(' ', 20)||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.CD_METHODO_BALE2, ' '), 7)||
       --28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur erronÔøΩ pour P2 et F2
       RPAD(NVL(C_ENR.CD_MOTEUR, ' '), 2)||
       --Fin SQN
       --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '), 6,' ')||
	   RPAD(' ', 5)||
	   --Fin EMM
       RPAD(NVL(TO_CHAR(C_ENR.DT_DEB_VALIDITE_LIGNE, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_VALIDITE_LIGNE, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_VALIDITE_LIGNE, 'YYYYMMDD'), ' '), 8)||
       LPAD(NVL(C_ENR.DUREE_MAX_ENGMT, '0'), 5, 0)||
       RPAD(' ', 20)||
       RPAD(' ', 28)|| --3+1+2+1+16+2+3
       -- 18/05/2018 - CDS ATOS (PSR) - ANACREDIT US 348 (F2 4.3)
       --RPAD(NVL(C_ENR.ID_ENGAGEMENT, ' '), 40)||
       RPAD(' ', 40)||
       -- FIN - CDS ATOS (PSR) - ANACREDIT US 348
	   --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
       RPAD(' ', 5)||
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20)||--KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Syst√®me de gestion source'
	   RPAD(' ', 5)||
	   RPAD(' ', 3456)  --4000 - 544
     as lignedetail1,  -- debut ligne (taille <= 4000)
     -- (compter 1 blanc de separation entre les 2 champs dans le spool)
       LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
     as lignedetail2
	 --Fin EMM
    from
    AUTORISATION_DETAIL_F2 C_ENR
    Where  A_EXTRAIRE = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' );


------------------------------------------------------------------------------------------------------------------------
-- PAVE P1 - perimetre NAT02 (variantes 1-3) - com separador ;
------------------------------------------------------------------------------------------------------------------------
select
     CAST(
       to_char(P1_H_0_1, 'YYYYMMDD')||';'||   -- 0.1 (P1)     EXATO
       RPAD(NVL(P1_H_0_2,' '), 5)||';'||   -- 0.2 (P1)     EXATO
       RPAD(NVL(P1_H_0_3,'C_BTR'), 12)||';'||   -- 0.3 (P1)     EXATO
       'M'||';'||   -- 0.4 (P1)     EXATO
       :MASYSDATE||';'||   -- 0.5 (P1)     EXATO
       'P1'||';'||   -- 0.6 (P1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (P1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (P1)     BRANCO
       RPAD(' ', 4)||';'||   -- 0.9 (P1)     BRANCO
       RPAD(' ', 3)||';'||   -- 0.99 (P1)    BRANCO
       RPAD(NVL(P1_H_1_1, ' '), 20)||';'||   -- 1.1 (P1)     EXATO
       RPAD(' ', 10)||';'||   -- 1.2 (P1)     BRANCO
       RPAD(NVL(P1_H_1_4, ' '), 30)||';'||   -- 1.4 (P1)     EXATO
       RPAD(NVL(P1_H_1_6, ' '), 30)||';'||   -- 1.6 (P1)     EXATO
       RPAD(' ', 40)||';'||   -- 1.8 (P1)     BRANCO
       RPAD(P1_H_1_11,40)||';'||   -- 1.11 (P1)    EXATO
       RPAD(' ', 40)||';'||   -- 1.16 (P1)    BRANCO
       RPAD(' ', 11)||';'||   -- 1.99 (P1)    BRANCO
       RPAD(' ', 7)||';'||   -- 1.98 (P1)    BRANCO
       RPAD(' ', 2)||';'||   -- 1.97 (P1)    BRANCO
       RPAD(P1_1_1,7)||';'||   -- P1 1.1       EXATO
       RPAD(P1_1_2,2)||';'||   -- P1 1.2       EXATO
       'Y'||';'||   -- P1 4.34      EXATO
       RPAD(P1_2_0,6)||';'||   -- P1 2.0       EXATO
       NVL(P1_2_4,'B')||';'||   -- P1 2.4       EXATO
       RPAD(P1_2_6,5)||';'||   -- P1 2.6       EXATO
       RPAD(P1_2_18,3)||';'||   -- P1 2.18      EXATO
       RPAD(nvl(P1_2_29, 'NA020'),12)||';'||   -- P1 2.29      EXATO
       RPAD(NVL(TO_CHAR(P1_3_2, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 3.2       EXATO
       NVL(TO_CHAR(P1_3_4, 'YYYYMMDD'),'99990630')||';'||   -- P1 3.4       EXATO
       RPAD(' ', 10)||';'||   -- P1 16.6      BRANCO
       pack_utilitaire.F_FORMAT_TAUX(P1_18_1)||';'||   -- P1 18.1      EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_18_10)||';'||   -- P1 18.10     EXATO
       pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((P1_18_5),0) <0 THEN 0 ELSE nvl((P1_18_5),0)END )||';'||   -- P1 18.5      EXATO
       RPAD(NVL(P1_18_17, ' '), 3)||';'||   -- P1 18.17     EXATO
       RPAD(NVL(P1_18_18, ' '), 3)||';'||   -- P1 18.18     EXATO
       RPAD(' ', 50)||';'||   -- P1 3.98      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.1      BRANCO
       RPAD(NVL(TO_CHAR(P1_21_2, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.2      EXATO
       P1_5_5||';'||   -- P1 5.5       EXATO
       P1_4_1||';'||   -- P1 4.1       EXATO
       P1_5_2||';'||   -- P1 5.2       EXATO
       NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 5.3       EXATO
       RPAD(' ', 19)||';'||   -- P1 4.2       BRANCO
       RPAD(P1_4_3, 3)||';'||   -- P1 4.3       EXATO
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END||';'||   -- P1 4.4       REGRA
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END||';'||   -- P1 4.5       REGRA
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_9),0))||';'||   -- P1 4.9       EXATO
       RPAD(NVL(P1_4_13, ' '), 3)||';'||   -- P1 4.13      EXATO
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END||';'||   -- P1 4.14      REGRA
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END||';'||   -- P1 4.15      REGRA
       RPAD(' ', 19)||';'||   -- P1 4.16      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.17      BRANCO
       RPAD (nvl(P1_4_18,' '), 12)||';'||   -- P1 4.18      EXATO
       CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END||';'||   -- P1 4.6       EXATO
       RPAD(NVL(P1_4_7, ' '), 3)||';'||   -- P1 4.7       EXATO
       RPAD(NVL(P1_4_19, ' '), 12)||';'||   -- P1 4.19      EXATO
       RPAD(' ', 10)||';'||   -- P1 4.20      BRANCO
       CASE WHEN P1_4_21 IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((P1_4_21),0)) END||';'||   -- P1 4.21      EXATO
       CASE WHEN P1_4_22 IS null THEN RPAD (' ', 3) ELSE 'EUR' END||';'||   -- P1 4.22      EXATO
       RPAD (nvl(P1_4_23, 'CL'),2)||';'||   -- P1 4.23      EXATO
       RPAD(' ', 1)||';'||   -- P1 5.6       BRANCO
       RPAD(' ', 20)||';'||   -- P1 5.7       BRANCO
       RPAD(' ', 10)||';'||   -- P1 5.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.33      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.10      BRANCO
       RPAD(' ', 25)||';'||   -- P1 5.11      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.32      BRANCO
       NVL(P1_3_46,' ')||';'||   -- P1 3.46      EXATO
       NVL(P1_3_47, ' ')||';'||   -- P1 3.47      EXATO
       CASE WHEN P1_3_40 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_3_40) END||';'||   -- P1 3.40      EXATO
       RPAD(NVL(P1_3_41, ' '), 3)||';'||   -- P1 3.41      EXATO
       CASE WHEN P1_3_42 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_3_42) END||';'||   -- P1 3.42      EXATO
       RPAD(NVL(P1_3_43, ' '), 3)||';'||   -- P1 3.43      EXATO
       RPAD(nvl(P1_3_44, ' '), 2,' ')||';'||   -- P1 3.44      EXATO
       P1_3_45||';'||   -- P1 3.45      EXATO
       Case when nvl(P1_5_19,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((P1_5_19),0)) else pack_utilitaire.f_format_montant_bis2(0) END||';'||   -- P1 5.19      EXATO
       RPAD(nvl(P1_5_20,'EUR'),3)||';'||   -- P1 5.20      EXATO
       RPAD(nvl(P1_19_5,' '),3)||';'||   -- P1 19.5      EXATO
       RPAD(' ', 12)||';'||   -- P1 3.56      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.50      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.51      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.52      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.53      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.54      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.55      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.57      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.58      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.59      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.60      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.61      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.8       BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.31      BRANCO
       RPAD(' ', 2)||';'||   -- P1 12.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.7       BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.70      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.71      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.74      BRANCO
       RPAD(NVL(P1_2_99,' '), 20)||';'||   -- P1 2.99      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.80      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.81      BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.82      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.83      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.15      BRANCO
       RPAD(' ', 25)||';'||   -- P1 13.10     BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.16      BRANCO
       RPAD(' ', 25)||';'||   -- P1 3.17      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.19      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.84      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.85      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.72      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.73      BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.0       BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.1       BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.2       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.6       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.7       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.10      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.11      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.12      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.13      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.14      BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.3       BRANCO
       RPAD(' ', 3)||';'||   -- P1 12.5      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.15      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.16      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.17      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.18      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.19      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.20      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.21      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.22      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.3      BRANCO
       RPAD(' ', 5)||';'||   -- P1 11.33     BRANCO
       RPAD(' ', 2)||';'||   -- P1 11.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.9      BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.13     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 16.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.20     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.22     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.99     BRANCO
       RPAD(P1_4_31, 1,' ')||';'||   -- P1 4.31      EXATO
       RPAD(' ', 1)||';'||   -- P1 4.32      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.33      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.13     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.36      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.49      BRANCO
       RPAD(' ', 4)||';'||   -- P1 4.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.45      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.46      BRANCO
       Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(P1_3_20,0)) ,4,6)||';'||   -- P1 3.20      EXATO
       NVL(P1_4_8,'B')||';'||   -- P1 4.8       EXATO
       RPAD(' ', 3)||';'||   -- P1 12.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.75      BRANCO
       RPAD(nvl(P1_4_42,' '),6,' ')||';'||   -- P1 4.42      EXATO
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8)||';'||   -- P1 3.3       EXATO
       RPAD(' ', 2)||';'||   -- P1 4.43      BRANCO
       RPAD(' ', 5)||';'||   -- P1 4.44      BRANCO
       RPAD(NVL(TO_CHAR(P1_4_47, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 4.47      EXATO
       RPAD(' ', 1)||';'||   -- P1 5.99      BRANCO
       RPAD(' ', 20)||';'||   -- P1 3.62      BRANCO
       RPAD(' ', 10)||';'||   -- P1 3.63      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.64      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.65      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.66      BRANCO
       RPAD(' ', 7)||';'||   -- P1 6.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.26      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.27      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.28      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.30      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.99      BRANCO
       P1_4_29||';'||   -- P1 4.29      EXATO
       RPAD(' ', 3)||';'||   -- P1 4.40      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.41      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.48      BRANCO
       RPAD(' ', 45)||';'||   -- P1 4.98      BRANCO
       RPAD(' ', 10)||';'||   -- P1 8.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.38      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.39      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.37      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.35      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.36      BRANCO
       RPAD(' ', 30)||';'||   -- P1 9.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 12.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 12.19     BRANCO
       RPAD(' ', 8)||';'||   -- P1 12.6      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.1      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.2      BRANCO
       RPAD(' ', 20)||';'||   -- P1 12.17     BRANCO
       RPAD(' ', 10)||';'||   -- P1 12.18     BRANCO
       RPAD(' ', 24)||';'||   -- P1 10.99     BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.89      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.90      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.86      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.87      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.88      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.15     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 11.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.76      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.77      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.4      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.10      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.11      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.12      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.13      BRANCO
       RPAD(' ', 2)||';'||   -- P1 10.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.1       BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.2       BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.11      BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.12      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.22     BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.21     BRANCO
       RPAD(' ', 10)||';'||   -- P1 10.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 9.5       BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.24     BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.5      BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.98     BRANCO
       RPAD(nvl(P1_21_3,' '),1)||';'||   -- P1 21.3      EXATO
       RPAD(nvl(P1_21_4,' '),1)||';'||   -- P1 21.4      EXATO
       RPAD(nvl(P1_21_5,' '),1)||';'||   -- P1 21.5      EXATO
       RPAD(nvl(P1_21_6,' '),2)||';'||   -- P1 21.6      EXATO
       RPAD (NVL(TO_CHAR(P1_21_7, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.7      EXATO
       RPAD(NVL(TO_CHAR(P1_21_8, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.8      EXATO
       RPAD(NVL(TO_CHAR(P1_21_9, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.9      EXATO
       RPAD(NVL(TO_CHAR(P1_21_10, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.10     EXATO
       RPAD(NVL(TO_CHAR(P1_21_11, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.11     EXATO
       RPAD(NVL(TO_CHAR(P1_21_12, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.12     EXATO
       RPAD(NVL(TO_CHAR(P1_21_13, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.13     EXATO
       RPAD(NVL(TO_CHAR(P1_21_14, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.14     EXATO
       RPAD(NVL(TO_CHAR(P1_21_15, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.15     EXATO
       RPAD(NVL(TO_CHAR(P1_21_16, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.16     EXATO
       RPAD(' ', 2)||';'||   -- P1 21.17     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.18     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.99     BRANCO
       RPAD(nvl(P1_22_56,' '),3)||';'||   -- P1 22.56     EXATO
       RPAD(nvl(P1_22_57,' '),1)||';'||   -- P1 22.57     EXATO
       RPAD(nvl(P1_22_1,' '),40)||';'||   -- P1 22.1      EXATO
       RPAD(nvl(P1_22_51,' '),40)||';'||   -- P1 22.51     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.2      BRANCO
       RPAD(' ', 4)||';'||   -- P1 22.3      BRANCO
       RPAD(' ', 40)||';'||   -- P1 22.4      BRANCO
       RPAD(nvl(P1_22_5, 'ND'),2)||';'||   -- P1 22.5      EXATO
       RPAD(nvl(P1_22_52,' '),10)||';'||   -- P1 22.52     EXATO
       RPAD(nvl(P1_22_6,' '),2,' ')||';'||   -- P1 22.6      EXATO
       RPAD(nvl(P1_22_53,' '),2)||';'||   -- P1 22.53     EXATO
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||';'||   -- P1 22.54     EXATO
       CASE WHEN P1_22_55 = 'C3' THEN '999' ELSE RPAD(upper(nvl(P1_22_55,' ')),3) END||';'||   -- P1 22.55     EXATO
       RPAD(nvl(P1_22_7,'97'),2)||';'||   -- P1 22.7      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||';'||   -- P1 22.8      EXATO
       RPAD(nvl(P1_22_9, 'EUR'), 3)||';'||   -- P1 22.9      EXATO
       RPAD(nvl(P1_22_12,' '),1)||';'||   -- P1 22.12     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_13)||';'||   -- P1 22.13     EXATO
       RPAD(nvl(P1_22_14,' '),1)||';'||   -- P1 22.14     EXATO
       RPAD(nvl(P1_22_15,' '),12)||';'||   -- P1 22.15     EXATO
       RPAD(nvl(P1_22_16,' '),1)||';'||   -- P1 22.16     EXATO
       RPAD(nvl(P1_22_17,' '),1)||';'||   -- P1 22.17     EXATO
       RPAD(nvl(P1_22_18,' '),1)||';'||   -- P1 22.18     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_19)||';'||   -- P1 22.19     EXATO
       RPAD(nvl(P1_22_20,' '),1)||';'||   -- P1 22.20     EXATO
       RPAD(NVL(TO_CHAR(P1_22_21, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.21     EXATO
       RPAD(NVL(TO_CHAR(P1_22_22, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.22     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_23)||';'||   -- P1 22.23     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_24)||';'||   -- P1 22.24     EXATO
       RPAD(nvl(P1_22_25,' '),1)||';'||   -- P1 22.25     EXATO
       LPAD(nvl((P1_22_26),0),3,0)||';'||   -- P1 22.26     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_27)||';'||   -- P1 22.27     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_28)||';'||   -- P1 22.28     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_29)||';'||   -- P1 22.29     EXATO
       RPAD(nvl(P1_22_30,' '),7)||';'||   -- P1 22.30     EXATO
       RPAD(NVL(TO_CHAR(P1_22_31, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.31     EXATO
       case when P1_22_32 is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(P1_22_32) end||';'||   -- P1 22.32     EXATO
       RPAD(nvl(P1_22_33,'EUR'),3)||';'||   -- P1 22.33     EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2( P1_22_34)||';'||   -- P1 22.34     EXATO
       RPAD(nvl(P1_22_35,' '),3)||';'||   -- P1 22.35     EXATO
       RPAD(NVL(P1_22_36,' '),1,' ')||';'||   -- P1 22.36     EXATO
       RPAD(NVL(TO_CHAR(P1_22_37, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.37     EXATO
       RPAD(NVL(TO_CHAR(P1_22_38, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.38     EXATO
       RPAD(' ', 19)||';'||   -- P1 22.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.40     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.41     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.42     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.43     BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_22_44),0))||';'||   -- P1 22.44     EXATO
       RPAD('EUR', 3)||';'||   -- P1 22.45     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.46     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.47     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.48     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.49     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.50     BRANCO
       RPAD(NVL(TO_CHAR(P1_22_58, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.58     EXATO
       RPAD(NVL(TO_CHAR(P1_22_59, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.59     EXATO
       pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(P1_22_60)||';'||   -- P1 22.60     EXATO
       RPAD(nvl(P1_22_61,' '),3)||';'||   -- P1 22.61     EXATO
       RPAD(nvl(P1_22_62,' '),1)||';'||   -- P1 22.62     EXATO
       RPAD(NVL(TO_CHAR(P1_22_63,'YYYYMMDD'),' '), 8)||';'||   -- P1 22.63     EXATO
       RPAD(' ', 2)||';'||   -- P1 22.64     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.65     BRANCO
       RPAD(nvl(P1_22_66, ' '), 2)||';'||   -- P1 22.66     EXATO
       RPAD(NVL(TO_CHAR(P1_22_67, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.67     EXATO
       RPAD(' ', 2)||';'||   -- P1 22.68     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.69     BRANCO
       LPAD(NVL(to_char(P1_22_70), ' '),5,'0')||';'||   -- P1 22.70     EXATO
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||';'||   -- P1 22.71     EXATO
       RPAD(nvl(P1_22_72,' '),2)||';'||   -- P1 22.72     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.73     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.74     BRANCO
       RPAD(nvl(P1_23_1,' '),1)||';'||   -- P1 23.1      EXATO
       RPAD(nvl(P1_23_2,' '),7)||';'||   -- P1 23.2      EXATO
       RPAD(nvl(P1_23_3,' '),20)||';'||   -- P1 23.3      EXATO
       RPAD(nvl(P1_23_4,' '),3)||';'||   -- P1 23.4      EXATO
       RPAD(nvl(P1_23_5,' '),3)||';'||   -- P1 23.5      EXATO
       RPAD(nvl(P1_23_6,' '),1)||';'||   -- P1 23.6      EXATO
       RPAD(NVL(P1_23_7, ' '), 40)||';'||   -- P1 23.7      EXATO
       RPAD(' ', 5)||';'||   -- P1 23.12     BRANCO
       RPAD(' ', 5)||';'||   -- P1 23.13     BRANCO
       RPAD (nvl(P1_23_8,' '), 12)||';'||   -- P1 23.8      EXATO
       RPAD (nvl(P1_23_9,' '), 12)||';'||   -- P1 23.9      EXATO
       RPAD (nvl(P1_23_10,' '), 12)||';'||   -- P1 23.10     EXATO
       RPAD (nvl(P1_23_11,' '), 12)||';'||   -- P1 23.11     EXATO
       RPAD(' ', 2)||';'||   -- P1 23.99     BRANCO
       RPAD(NVL(P1_24_1,' '),1,' ')||';'||   -- P1 24.1      EXATO
       RPAD(' ', 2)||';'||   -- P1 24.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.5      BRANCO
       RPAD(' ', 13)||';'||   -- P1 24.6      BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.8      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.11     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.12     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.15     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.17     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.18     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.20     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.21     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.22     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.23     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.25     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.26     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.27     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.28     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.29     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.30     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.97     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.31     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.32     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.36     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.98     BRANCO
       RPAD(' ', 12)||';'||   -- P1 24.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.6      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.7      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.8      BRANCO
       RPAD(' ', 39)     -- P1 25.99     CORTE-A
     AS VARCHAR2(4000)) as lignedetail1,
     CAST(
       RPAD(' ', 60)||';'||   -- P1 25.99     CORTE-B
       RPAD(NVL(P1_26_1,' '),1,' ')||';'||   -- P1 26.1      EXATO
       RPAD(NVL(P1_22_11, ' '), 1)||';'||   -- P1 22.11     EXATO
       RPAD(NVL(P1_26_3, ' '), 3)||';'||   -- P1 26.3      EXATO
       RPAD(NVL(P1_26_4, ' '), 3)||';'||   -- P1 26.4      EXATO
       RPAD(' ', 44)||';'||   -- P1 26.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 27.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 27.2      BRANCO
       RPAD(P1_27_3, 1)||';'||   -- P1 27.3      EXATO
       RPAD(NVL(P1_27_4, ' '), 2)||';'||   -- P1 27.4      EXATO
       RPAD(' ', 23)||';'||   -- P1 27.99     BRANCO
       RPAD (nvl(P1_28_1,' '), 1)||';'||   -- P1 28.1      EXATO
       RPAD(' ', 1)||';'||   -- P1 28.2      BRANCO
       pack_utilitaire.F_FORMAT_MONTANT_BIS3(P1_29_1)||';'||   -- P1 29.1      EXATO
       RPAD (nvl(P1_29_2,' '), 3)||';'||   -- P1 29.2      EXATO
       RPAD(' ', 2)||';'||   -- P1 30.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.3      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.5      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.6      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.7      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.8      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.11     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.12     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.16     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.17     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.18     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.19     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.20     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.21     BRANCO
       RPAD(' ', 25)||';'||   -- P1 30.22     REGRA
       'N'||';'||   -- P1 30.23     REGRA
       RPAD(' ', 25)||';'||   -- P1 30.24     REGRA
       'N'||';'||   -- P1 30.25     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.27     BRANCO
       RPAD(' ', 5)||';'||   -- P1 31.1      BRANCO
       RPAD(NVL(P1_31_2, ' '), 40)||';'||   -- P1 31.2      EXATO
       RPAD(NVL(P1_31_3, ' '), 40)||';'||   -- P1 31.3      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||';'||   -- P1 31.4      EXATO
       RPAD(NVL(P1_31_5, ' '), 1)||';'||   -- P1 31.5      EXATO
       RPAD (NVL(P1_31_6,'2'), 1)||';'||   -- P1 31.6      EXATO
       RPAD(' ', 6)||';'||   -- P1 31.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.8      BRANCO
       RPAD(NVL(P1_31_9, ' '),15,' ')||';'||   -- P1 31.9      EXATO
       RPAD(NVL(P1_31_10, ' '),2,' ')||';'||   -- P1 31.10     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.11     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.13     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.15     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.16     BRANCO
       RPAD ('+', 1)||LPAD(P1_31_17, 5, '0')||';'||   -- P1 31.17     EMENDA
       RPAD ('+', 1)||LPAD(P1_31_18, 5, '0')||';'||   -- P1 31.18     EMENDA
       RPAD(' ', 6)||';'||   -- P1 31.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.20     BRANCO
       RPAD(NVL(P1_31_21,' '), 2)||';'||   -- P1 31.21     EXATO
       P1_31_22||';'||   -- P1 31.22     EXATO
       RPAD(' ', 19)||';'||   -- P1 31.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.24     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.25     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.26     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.27     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.28     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.29     BRANCO
       RPAD(NVL(P1_31_37,' '),1)||';'||   -- P1 31.37     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.38     BRANCO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||';'||   -- P1 29.3      EXATO
       RPAD ('EUR', 3)||';'||   -- P1 29.4      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.6      BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.30     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.31     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.32     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.34     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.36     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.24     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.25     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.26     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.29     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.30     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.31     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.32     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.33     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.34     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.35     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.36     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.37     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.40     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.41     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.42     BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.3      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.4      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.5      BRANCO
       RPAD(' ', 20)||';'||   -- P1 28.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 28.7      BRANCO
       RPAD(' ', 15)||';'||   -- P1 28.8      BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.9      BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.11     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.12     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.13     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.14     BRANCO
       'EUR'||';'||   -- P1 50.1      EXATO
       RPAD(NVL(P1_50_2, ' '), 12)||';'||   -- P1 50.2      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||';'||   -- P1 50.3      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.5      BRANCO
       RPAD(NVL(P1_50_8, ' '), 12)||';'||   -- P1 50.8      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||';'||   -- P1 50.9      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.15     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.16     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.17     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.18     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.19     BRANCO
       RPAD(NVL(P1_21_22,' '),2)||';'||   -- P1 21.22     EXATO
       RPAD(NVL(TO_CHAR(P1_21_23, 'YYYYMMDD'), ' '),8)||';'||   -- P1 21.23     EXATO
       case when P1_21_29 is not null then '+'||LPAD(P1_21_29,5,'0') else RPAD(' ',6) end||';'||   -- P1 21.29     EXATO
       RPAD(NVL(P1_21_25,' '),2)||';'||   -- P1 21.25     EXATO
       RPAD(NVL(P1_21_26,' '),1)||';'||   -- P1 21.26     EXATO
       RPAD(NVL(P1_21_27,' '),1)||';'||   -- P1 21.27     EXATO
       RPAD(NVL(P1_21_28,' '),2)||';'||   -- P1 21.28     EXATO
       case when P1_21_30 is not null then RPAD(pack_utilitaire.f_format_montant_bis2(P1_21_30),19) else RPAD(' ',19) end||';'||   -- P1 21.30     EXATO
       RPAD(NVL(P1_21_31, ' '), 3)||';'||   -- P1 21.31     EXATO
       RPAD(' ', 15)||';'||   -- P1 21.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.33     BRANCO
       RPAD(' ', 12)||';'||   -- P1 15        BRANCO
       RPAD(' ', 12)||';'||   -- P1 16        BRANCO
       RPAD(' ', 12)||';'||   -- P1 14        BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.20     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.35     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.36     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.47     BRANCO
       RPAD(' ', 7)||';'||   -- P1 21.48     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.49     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.50     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.51     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.52     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.53     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.54     BRANCO
       RPAD(NVL(P1_21_44,' '),1)||';'||   -- P1 21.44     EXATO
       RPAD(NVL(P1_21_45,' '),1)||';'||   -- P1 21.45     EXATO
       RPAD(NVL(P1_21_46,' '),1)||';'||   -- P1 21.46     EXATO
       RPAD(NVL(P1_21_38,' '),1)||';'||   -- P1 21.38     EXATO
       RPAD(NVL(P1_21_39,' '),1)||';'||   -- P1 21.39     EXATO
       RPAD(NVL(P1_21_40,' '),1)||';'||   -- P1 21.40     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.41     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.42     BRANCO
       RPAD(pack_utilitaire.F_FORMAT_TAUX_15(P1_21_43),15)||';'||   -- P1 21.43     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.56     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.57     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.58     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.59     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.60     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.61     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.62     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.63     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.64     BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.65     REGRA
       RPAD(NVL(P1_21_66,' '),1)||';'||   -- P1 21.66     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.67     BRANCO
       RPAD(NVL(P1_21_68,' '),1)||';'||   -- P1 21.68     EXATO
       RPAD(NVL(P1_21_55,' '),12)||';'||   -- P1 21.55     EXATO
       RPAD(NVL(P1_21_69,' '),1)||';'||   -- P1 21.69     EXATO
       RPAD(' ', 20)||';'||   -- P1 21.89     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.90     BRANCO
       RPAD(NVL(P1_8_13,' '),1)||';'||   -- P1 8.13      EXATO
       RPAD(NVL(P1_21_71,' '),40)||';'||   -- P1 21.71     EXATO
       RPAD(NVL(P1_21_72,' '),40)||';'||   -- P1 21.72     EXATO
       RPAD(NVL(P1_21_73,' '),40)||';'||   -- P1 21.73     EXATO
       RPAD(NVL(P1_21_74,' '),40)||';'||   -- P1 21.74     EXATO
       RPAD(NVL(P1_21_75,' '),40)||';'||   -- P1 21.75     EXATO
       RPAD(NVL(P1_21_76,' '),40)||';'||   -- P1 21.76     EXATO
       RPAD(NVL(P1_21_77,' '),11)||';'||   -- P1 21.77     EXATO
       RPAD(NVL(P1_21_78,' '),12)||';'||   -- P1 21.78     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.94     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.95     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.79     BRANCO
       RPAD(NVL(P1_21_80,' '),3)||';'||   -- P1 21.80     EXATO
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_81),10)||';'||   -- P1 21.81     EXATO
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_82),10)||';'||   -- P1 21.82     EXATO
       RPAD(' ', 15)||';'||   -- P1 21.83     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.84     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.85     BRANCO
       RPAD(NVL(P1_21_86,' '),1)||';'||   -- P1 21.86     EXATO
       RPAD(NVL(P1_21_87,' '),1)||';'||   -- P1 21.87     EXATO
       RPAD(NVL(P1_21_88,' '),1)||';'||   -- P1 21.88     EXATO
       RPAD(' ', 19)||';'||   -- P1 21.91     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.92     BRANCO
       RPAD(' ', 5)||';'||   -- P1 21.93     BRANCO
       RPAD(' ', 20)||';'||   -- P1 31.51     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.52     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.53     BRANCO
       RPAD(NVL(TO_CHAR(P1_1001,'YYYYMMDD'),' '), 8)||';'||   -- P1 1001      NOVO
       RPAD(NVL(TO_CHAR(P1_1002,'YYYYMMDD'),' '), 8)||';'||   -- P1 1002      NOVO
       RPAD(NVL(P1_22_222,' '), 1)||';'||   -- P1 22.222    NOVO
       RPAD(NVL(P1_24_22_1,' '), 1)||';'||   -- P1 24.22.1   NOVO
       RPAD(NVL(P1_600,' '), 1)||';'||   -- P1 600       NOVO
       RPAD(NVL(P1_601,' '), 1)||';'||   -- P1 601       NOVO
       RPAD(NVL(P1_602,' '), 1)||';'||   -- P1 602       NOVO
       CASE WHEN P1_603 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_603) END||';'||   -- P1 603       NOVO
       RPAD(NVL(P1_603_1,' '), 3)||';'||   -- P1 603.1     NOVO
       CASE WHEN P1_604 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_604) END||';'||   -- P1 604       NOVO
       RPAD(NVL(P1_604_1,' '), 3)||';'||   -- P1 604.1     NOVO
       CASE WHEN P1_605 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_605) END||';'||   -- P1 605       NOVO
       RPAD(NVL(P1_605_1,' '), 3)||';'||   -- P1 605.1     NOVO
       RPAD(NVL(P1_606,' '), 40)||';'||   -- P1 606       NOVO
       RPAD(NVL(P1_607,' '), 1)||';'||   -- P1 607       NOVO
       CASE WHEN P1_608 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_608) END||';'||   -- P1 608       NOVO
       RPAD(NVL(P1_608_1,' '), 3)||';'||   -- P1 608.1     NOVO
       RPAD(NVL(TO_CHAR(P1_609,'YYYYMMDD'),' '), 8)||';'||   -- P1 609       NOVO
       CASE WHEN P1_610 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_610) END||';'||   -- P1 610       NOVO
       RPAD(NVL(P1_610_1,' '), 3)||';'||   -- P1 610.1     NOVO
       RPAD(NVL(TO_CHAR(P1_611,'YYYYMMDD'),' '), 8)||';'||   -- P1 611       NOVO
       CASE WHEN P1_612 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_612) END||';'||   -- P1 612       NOVO
       RPAD(NVL(P1_612_1,' '), 3)||';'||   -- P1 612.1     NOVO
       RPAD(NVL(P1_613,' '), 1)||';'||   -- P1 613       NOVO
       CASE WHEN P1_614 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_614) END||';'||   -- P1 614       NOVO
       RPAD(NVL(P1_614_1,' '), 3)||';'||   -- P1 614.1     NOVO
       LPAD(NVL(TO_CHAR(P1_615),' '), 6)||';'||   -- P1 615       NOVO
       RPAD(NVL(P1_616,' '), 1)||';'||   -- P1 616       NOVO
       RPAD(NVL(P1_617,' '), 1)||';'||   -- P1 617       NOVO
       RPAD(NVL(P1_618,' '), 1)||';'||   -- P1 618       NOVO
       CASE WHEN P1_619 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_619) END||';'||   -- P1 619       NOVO
       RPAD(NVL(P1_620,' '), 1)||';'||   -- P1 620       NOVO
       RPAD(NVL(P1_635,' '), 1)||';'||   -- P1 635       NOVO
       RPAD(NVL(P1_622,' '), 1)||';'||   -- P1 622       NOVO
       RPAD(NVL(P1_623,' '), 40)||';'||   -- P1 623       NOVO
       CASE WHEN P1_624 IS NULL THEN RPAD(' ', 15) ELSE pack_utilitaire.f_format_taux_15(P1_624) END||';'||   -- P1 624       NOVO
       RPAD(NVL(P1_625,' '), 2)||';'||   -- P1 625       NOVO
       RPAD(NVL(P1_626,' '), 1)||';'||   -- P1 626       NOVO
       RPAD(NVL(P1_627,' '), 1)||';'||   -- P1 627       NOVO
       CASE WHEN P1_628 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_628) END||';'||   -- P1 628       NOVO
       RPAD(NVL(P1_628_1,' '), 3)||';'||   -- P1 628.1     NOVO
       RPAD(NVL(P1_629,' '), 1)||';'||   -- P1 629       NOVO
       CASE WHEN P1_630 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_630) END||';'||   -- P1 630       NOVO
       RPAD(NVL(P1_630_1,' '), 3)||';'||   -- P1 630.1     NOVO
       CASE WHEN P1_631 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_631) END||';'||   -- P1 631       NOVO
       RPAD(NVL(P1_631_1,' '), 3)||';'||   -- P1 631.1     NOVO
       CASE WHEN P1_632 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_632) END||';'||   -- P1 632       NOVO
       RPAD(NVL(P1_632_1,' '), 3)||';'||   -- P1 632.1     NOVO
       CASE WHEN P1_633 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_633) END||';'||   -- P1 633       NOVO
       RPAD(NVL(P1_633_1,' '), 3)||';'||   -- P1 633.1     NOVO
       RPAD(NVL(P1_621,' '), 8)||';'||   -- P1 621       NOVO
       RPAD(' ', 1176)     -- P1 99.99     FILLER
     AS VARCHAR2(3999)) as lignedetail2
  from ENG_CORP_P1_BIS
 where CD_PERIMETRE = 'NAT02'
   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
 order by NO_VARIANTE;

 
 

  


    
------------------------------------------------------------------------------------------------------------------------
-- N05: a partir de P_UTLF_ENG_CORP_P2   
------------------------------------------------------------------------------------------------------------------------
select
       to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD(NVL(C_ENR.APPLI_SOURCE,'C_BTR'), 12)||                                                       -- 08/02/2019 - CDS ATOS (GBD)- US677 : APPLI_SOURCE  (P2 0.3)
       NVL(C_ENR.FREQUENCE,'M')||     --   CASE WHEN C_ENR.CD_TYPE_RISQUE = 'EQU101' THEN 'T' ELSE 'M'END|| -- 08/02/2019 - CDS ATOS (GBD)- US677  :  Frequence (P2 0.4)
       :MASYSDATE||
       'P2'||
       RPAD(' ', 10)||  -- longueur : 1+2+7
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||   --dans la synthese il est dit a blanc pour les tre5 mais aujourd hui nous la renseignons pour tous
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(' ', 40)||
       RPAD(C_ENR.ID_ENGAGEMENT,40)||  --pour les TRE2 a TRE4 pas de champ mais c'est une clef de la table -- a revoir si besoin
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(NVL(C_ENR.CD_METHODO_BALE2, 'STD'),7)||
       --28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur errone pour P2 et F2
        RPAD(NVL(C_ENR.CD_MOTEUR, ' '), 2)||
       --Fin SQN
       NVL(C_ENR.CODE_TRAIT_GRR,'Y')||   -- 08/02/2019 - CDS ATOS (GBD)- US677 : Traitement GRR (P2 4.34)
       RPAD(nvl(C_ENR.CD_TYPE_RISQUE,' '),6)||
       NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')||
       RPAD(nvl(C_ENR.CD_LIGNE_METIER,' '),5)||
       RPAD(nvl(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3)||
       RPAD(nvl(C_ENR.CD_NATURE_OPE,' '),12)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8)||
       NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'),'99990630')||
       RPAD(' ', 10)||    --taux pondÔøΩration baloise
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_LGD_PREDICTIF)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_CCF)||        -- 08/02/2019 - CDS ATOS (GBD)- US677 : Taux CCF (P2 18.10)  ( *100 fait a l'alimentation)
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_EAD)||   -- 08/02/2019 - CDS ATOS (GBD)- US677 : Montant EAD (P2 18.5) 
       RPAD(NVL(C_ENR.CD_DEVISE_EAD, 'EUR'), 3)||
       RPAD(NVL(C_ENR.CD_DEVISE, ' '), 3)||
       RPAD(' ', 50)||
       RPAD(NVL(C_ENR.TOP_RESTRUCTURATION, ' '), 2)||
       RPAD(NVL(to_char(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '),8)||
       NVL(C_ENR.CD_IMP_PRUDENT,'N')||
       NVL(C_ENR.CD_ENG_DTX,'N')||
       RPAD(NVL(to_char(C_ENR.DT_EGT_DTX, 'YYYYMMDD'), ' '),8)||
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PNU),0))||
       RPAD(nvl(C_ENR.CD_DEVISE_PNU, ' '), 3)||
       RPAD(nvl(C_ENR.PCCO_MNT_PNU, ' '), 12)||
       NVL(C_ENR.CD_CIRCUIT_DISTRIB,'CL')||
       RPAD(' ', 33)||  --1+20+10+2
       NVL(C_ENR.IND_ACCORD_FUSION,'N')||  -- 08/02/2019 - CDS ATOS (GBD)- US677 : Indic Accord de Fusion (P2 5.10)
       RPAD(' ', 25)||
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 33)|| -- 3+5+2+1+1+1+7+1+1+1+1+4+5
       RPAD(' ', 1)||
       RPAD(' ', 1)||
       RPAD(' ', 1)||
       RPAD(' ', 2)||
       RPAD(' ', 3)|| --fin donnees 3.10
       --FIN EMM
       NVL(C_ENR.TOP_PRODUIT,'N')||           -- 08/02/2019 - CDS ATOS (GBD)- US677  : Produit ss jacent (P2 4.31)
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 30)|| --1+1+4+5+1+4+5+8+1
       RPAD(' ', 1)||
       RPAD(' ', 29)||
        --FIN EMM
       Substr(pack_utilitaire.F_FORMAT_TAUX (C_ENR.MATURITE_EFF)  ,4,6)||
       NVL(C_ENR.TOP_ENG, 'H')||
       RPAD(' ', 13)|| --3+10
       NVL(C_ENR.CD_USAGE_BIEN_IMM,' ')||
       NVL(C_ENR.RESPECT_COND_REG,'Y')||   -- 08/02/2019 - CDS ATOS (GBD)- US677  : Respect des conditions reglementaires (P2 3.47)
--      RPAD(' ', 13)||
       --24/01/2019 - CDS Atos (SQN) US 670
       --RPAD(' ', 76)||    --1+16+2+3+1+16+2+3+2+30
       RPAD(' ', 46)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_EL)||
       RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '),20) || -- P2 6.99 :: projet OMP - sous-tache SIRL-238
       --Fin SQN
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 6)|| --1+3+1+1 
	   RPAD(' ', 45)||
	   RPAD(' ', 10)||	 --  Fin 42 c 
		--Fin EMM
       RPAD(' ', 1)||
       RPAD(' ', 17)||
       RPAD(nvl(C_ENR.CLASS_CPT_REF_ACT, ' '), 3)||
       RPAD(nvl(C_ENR.EVT_CREDIT, ' '), 1)||
       RPAD(nvl(C_ENR.NAT_EVN_CREDIT, ' '), 1)||
       RPAD(nvl(C_ENR.STATU_CREDIT, ' '), 1)||                                    --23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 (P2 21.5)
       RPAD(nvl(C_ENR.IND_CREANCE_PER, ' '), 2)||
       RPAD (NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8)||        --23/04/2018 CDS ATOS (EMM) Sprint 8 US 274 (P2 21.7)
       RPAD(NVL(TO_CHAR(C_ENR.DAT_DER_REST_COM, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DAT_DER_REST_RIS, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8)  ||                --23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 (P2 21.10)
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8)  ||                --23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 (P2 21.11)
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8)  ||                --23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 (P2 21.12)
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8)  ||                --23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 (P2 21.13)
       RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8)  ||            --23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 (P2 21.14)
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8)  ||            --23/04/2018 CDS ATOS (EMM) Sprint 8 US 274 (P2 21.15)
       --24/01/2019 - CDS Atos (SQN) US 670
       --RPAD (' ', 16)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL, 'YYYYMMDD'), ' '), 8)  ||
       RPAD(nvl(C_ENR.CD_MOTIF_PL_NPL, ' '), 2)||
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	    RPAD (' ', 2)||
	   RPAD (' ', 2)||
	   RPAD (' ', 2)||	--zone libre
	   --Fin EMM
       --Fin SQN
       RPAD(nvl(C_ENR.IND_PRD_NON_ECH, ' '), 3)||
       RPAD(nvl(C_ENR.IND_OBJ_MET_PAL_DAT_FOURNI, ' '), 1)||
       RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
       RPAD(nvl(C_ENR.REF_UNI_CONTRAT, ' '), 40)||
       RPAD(nvl(C_ENR.REF_UNI_ELEM_CONTRAT, ' '), 40)||
       --09/11/18 CDS Atos (EMM) US 546
       RPAD(nvl(C_ENR.IND_NIV_RISQUE, ' '), 1)||
       --Fin EMM
       RPAD(' ', 4)||
       RPAD(' ', 40)||       
       RPAD(nvl(C_ENR.NOT_FIN_RET_ORG, 'ND'), 2)||      
       RPAD(nvl(C_ENR.NOT_EXT_ORG, ' '), 10)||
       --RPAD(nvl(C_ENR.ORG_NOTATION_ORG, ' '), 2)||
       RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG, 'I'), 2)||  -- 08/02/2019 - CDS ATOS (GBD)- US677 : Organisme de notation a l'origine (P2 22.6)
       RPAD(nvl(C_ENR.SEG_NOTATION_ORG, ' '), 2)||
       --RPAD(nvl(C_ENR.GRI_NOT_ORG, ' '), 46)||
       CASE WHEN C_ENR.GRI_NOT_ORG IS NULL THEN RPAD(' ',46)    
       ELSE RPAD(nvl(rpad(C_ENR.GRI_NOT_ORG,21)||'FR',' '),46) END ||
       --RPAD(upper(nvl(C_ENR.METH_NOTATION_ORG, ' ')), 3)||
       CASE WHEN C_ENR.METH_NOTATION_ORG = 'C3' THEN '999'
       ELSE RPAD(nvl(C_ENR.METH_NOTATION_ORG,' '),3) END||
       RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2)||
       --01/06/2018 - CDS ATOS (PSR) - US 292 - CRRV4.1 Instruments (A)
       --RPAD(' ', 1)|| 
       --RPAD(' ', 16)||
       --RPAD(' ', 2)|| 
       --RPAD(' ', 3)||
        -- 05/07/2018 - CDS AtoS (FAD) - Mantis 44080 : 
        --  Si le montant du contrat ? l'origine est null alors n'afficher que des blancs pour le montant et la devise associ?e
        --pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
        --RPAD(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 3)||--P1 22.9 : Devise du montant du contrat ? l'origine
        pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
        RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3)||--P1 22.9 : Devise du montant du contrat ? l'origine
        -- Fin - CDS AtoS (FAD) - Mantis 44080
        -- fin US 292 - CDS ATOS(PSR)
       RPAD(nvl(C_ENR.IND_ECH_FOURNI, ' '), 1)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_INT_EF_ORG)||
       RPAD(nvl(C_ENR.TYP_TAUX, ' '), 1)||
       RPAD(nvl(C_ENR.IND_REF, ' '), 12)||
       RPAD(nvl(C_ENR.TYP_AMOR_CAP, ' '), 1)||
       RPAD(nvl(C_ENR.PER_AMOR_CAP, ' '), 1)||
       RPAD(nvl(C_ENR.PER_PAI_INTERET, ' '), 1)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLI_OCTROI)||
       RPAD(nvl(C_ENR.MOD_REMB_CREANCE, ' '), 1)||
       RPAD(NVL(TO_CHAR(C_ENR.DATE_PRM_ECHEANCE, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_DIF_AMOR, 'YYYYMMDD'), ' '), 8)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAF)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAN)||
       RPAD(nvl(C_ENR.PER_REV_TAUX_UNITE_TMP, ' '), 1)||
       LPAD(nvl((C_ENR.PER_REV_TAUX_NBR),0),3,0)||
                 pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_PRD_EN_CRS)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MARG_ADDTIV)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MARG_MULTP)||
       RPAD(nvl(C_ENR.BASE_CALCUL_INTERET, ' '), 7)||
       RPAD(NVL(TO_CHAR(C_ENR.DATE_PRE_DEB_FOND, 'YYYYMMDD'), ' '), 8)||
       RPAD(' ', 1)||
       RPAD(' ', 16)||
       RPAD(' ', 2)||
       RPAD(' ', 3)||
       pack_utilitaire.f_format_montant_bis2(C_ENR.CAP_THEO_REST_DU)||
       RPAD(nvl(C_ENR.DEV_CAP_THEO_REST_DU, ' '), 3)||
       RPAD('3', 1)||
       RPAD(' ', 8)||
       RPAD(' ',130 )||--8+1+16+2+3+8+1+4+5+1+16+2+38+16+2+3+1+4+5+1+4+5
       RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_PALL, 'YYYYMMDD'), ' '), 8)||
       RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_PALL, 'YYYYMMDD'), ' '), 8)||
       pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ECHEANCE_EN_COURS)||
       RPAD(nvl(C_ENR.DEV_MNT_ECHEANCE_EN_COURS, 'EUR'), 3)|| 
       RPAD(nvl(C_ENR.IND_PRE_POST_FIX, ' '), 1)|| 
       RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENOUV,'YYYYMMDD'),' '), 8) || -- P2 22.63 :: projet OMP - sous-tache SIRL-236
       --24/01/2019 - CDS Atos (SQN) US 670
       --RPAD(' ', 55)||
       RPAD(' ', 12)||    --2+1+4+5
       RPAD(nvl(C_ENR.CD_PAYS_JURIDICTION, ' '), 2)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8)||
       RPAD(nvl(C_ENR.EVT_DECL_GAR, ' '), 2)||
       RPAD(' ', 5)||
       --13/02/2019 - CDS ATOS (SQN) - CRRV4.2 - Correctif : CD_MOTIF_SCO_LC0267 : completer le code a gauche a 0.
       --RPAD(nvl(C_ENR.CD_MOTIF_SCO_LC0267, ' '), 3)||
       --LPAD(nvl(C_ENR.CD_MOTIF_SCO_LC0267,' '),3,'0')||
       --15/02/19 CDS ATOS (EMM) Correctif 2 score 7
       CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3)
       ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||
       --Fin EMM
       RPAD(nvl(C_ENR.BUCKET_IFRS9, ' '), 2)||
       RPAD(' ', 21)||    --1+4+5+1+4+5+1
       --Fin SQN
       RPAD(nvl(C_ENR.ELIG_OUTIL_MUT_PROV, ' '), 1)|| 
       RPAD(nvl(C_ENR.CENT_RESULT, ' '), 7)||
       RPAD(nvl(C_ENR.SYS_GEST_SOURCE, ' '), 20)|| 
       RPAD(nvl(C_ENR.CLASS_CPT_ACT_NOR_IFRS9, ' '), 3)|| 
       RPAD(nvl(C_ENR.CLASS_CPT_ACT_NOR_NAT, ' '), 3)||  
       RPAD(nvl(C_ENR.IND_ACT_DEP_ORG, ' '), 1)|| 
       RPAD(nvl(C_ENR.ZONE_APP_COMPTA, ' '), 40)|| 
       RPAD (' ', 10)||
       RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
       RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
       RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
       RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
       --24/01/2019 - CDS Atos (SQN) US 670
       --RPAD(' ', 54)||  1+1+1+16+2+3
       -- 06/02/2019 - CDS ATOS (LFD) - CRRV4.2 US 718
       --RPAD(' ', 30)||
       RPAD(' ', 2)||
       nvl(C_ENR.IND_MOBIL_ACTIF,'1')||              -- 08/02/2019 - CDS ATOS (GBD)- US677 : Indic mobilisation actif (P2 26.1)
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD (nvl(C_ENR.ELIG_MOB_BANQUE_CENTRALE,' '), 1)||
	   RPAD (nvl(C_ENR.REF_MOB_ACTIF,' '), 3)||
	   RPAD (nvl(C_ENR.CD_ORGA_MOBIL,' '), 3)||
	   RPAD(' ', 20)||
	   -- FIN EMM
       -- FIN LFD
       RPAD (nvl(C_ENR.IND_OPE_EFFET_LEVIER,' '), 1)||
       RPAD (nvl(C_ENR.IND_SPONSOR_FIN,' '), 1)||
       pack_utilitaire.F_FORMAT_MONTANT_BIS3(C_ENR.MNT_IDEMNITE_RES)||
       RPAD (nvl(C_ENR.CD_DEV_MNT_INDEMNITE,' '), 3)||
       --Fin SQN
	   --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 19)|| --DEBUT 27
	   RPAD(' ', 3)||
	   RPAD (nvl(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD,' '), 1)||
	   RPAD (nvl(C_ENR.MOTIF_EXCLU_ANACREDIT,' '), 2)||
	   RPAD(' ', 23)||
	   RPAD(' ', 5)|| --DEBUT 31a
	   RPAD(' ', 40)||
	  RPAD(' ', 40)||
	  case when C_ENR.MNT_ENG_DT_SIGN_CTRT is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT) end ||
	  RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '),1,' ')||
  	RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
	  RPAD(' ',6)|| --P2 31.7
	  RPAD(' ',1)|| --P2 31.8 --Fin 31a
    RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| --P2 31.9--debut 31b
	  RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| --P2 31.10
	  RPAD(' ',1)|| --P2 31.11
	  RPAD(' ',1)|| --P2 31.12
	  RPAD(' ',1)|| --P2 31.13
	  RPAD(' ',15)|| --P2 31.14
	  RPAD(' ',19)|| --P2 31.15
	  RPAD(' ',3)|| --P2 31.16
    case when C_ENR.DUREE_INIT_PRET is not null then '+'||LPAD(C_ENR.DUREE_INIT_PRET,5,'0') else RPAD(' ',6) end ||--P2 31.17 --M71784 pos 1966
    case when C_ENR.DUREE_TOTALE_PRET_DATE is not null then '+'||LPAD(C_ENR.DUREE_TOTALE_PRET_DATE,5,'0') else RPAD(' ',6) end ||--P2 31.18 --M71784 pos 1972
	  RPAD(' ',6)|| --P2 31.19
	  RPAD(' ',1)|| --P2 31.20
	  RPAD(NVL(C_ENR.CDTYPEGARPRINCOCTROI,' '), 2)|| --Debut P2 31.21 M71371
	  RPAD(' ',2)|| --P2 31.22
    -- US 261 - KLx Risque (VDC) [CRRv4.3] Leasing - CRR Corporate - Score 7 'Montant des fonds remis √† date '
    -- P2 32.23 
	  case when C_ENR.MNT_FOND_REMIS_DATE is null then RPAD(' ',19) else pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_FOND_REMIS_DATE) end ||
	  case when C_ENR.DEV_FOND_REMIS_DATE is null then RPAD(' ',3) else RPAD(C_ENR.DEV_FOND_REMIS_DATE,3,' ') end ||
    -- FIN VDC
	  RPAD(' ',15)||
	  RPAD(' ',15)||
	  RPAD(' ',15)||
	  RPAD(' ',15)||
	  RPAD(' ',15)|| 
	  RPAD(' ',1)|| --DEBUT 31c
	  RPAD(' ',1)||
	  RPAD(' ',19)|| --DEBUT 31d
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)|| --DEBUT 31e
	  RPAD(' ',3)||
	  RPAD(' ',7)|| --DEBUT 31g
	  RPAD(' ',2)||
	  RPAD(' ',2)|| 
	  RPAD(' ',2)||
	  RPAD(' ',2)|| 
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',2)|| --DEBUT 31h
	  RPAD(' ',2)||
	  RPAD(' ',2)|| 
	  RPAD(' ',20)||
	  RPAD(' ',10)|| 
	  RPAD(' ',15)||
	  RPAD(' ',19)||
	  RPAD(' ',3)|| 
	  RPAD(' ',19)||
	  RPAD(' ',3)||
	  RPAD(' ',19)||
	  RPAD(' ',3)||	  
	  RPAD (nvl(C_ENR.CD_DEVISE,' '), 3)|| --DEBUT 50
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(nvl(C_ENR.PCCO_MNT_PNU,' '),12)|| -- P2 50.4 --KLX Risque (VDC) - US 278 - CRR Corporate - Score 6 'PCCO - Valeur du principal 2''
	  pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_PNU)|| --P2 50.5 --KLX Risque (VDC) - US 278 - CRR Corporate - Score 6 'PCCO - Valeur du principal 2''
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)|| --P2 15 pos 2629 - VIDE
	  RPAD(' ',12)|| --P2 16 pos 2641 - VIDE
	  RPAD(' ',12)|| --P2 14 pos 2653 - VIDE
	  RPAD(' ',7)|| --P2 21.48 pos 2665 - VIDE
	  RPAD(' ',19)|| --P2 21.49 pos 2672 - VIDE
	  RPAD(' ',3)|| --P2 21.50 pos 2691 - VIDE
	  RPAD(' ',19)|| --P2 21.51 pos 2694 - VIDE
	  RPAD(' ',3)|| --P2 21.52 pos 2713 - VIDE
	  RPAD(' ',19)|| --P2 21.53 pos 2716 - VIDE
	  RPAD(' ',3)|| --P2 21.54 pos 2735 - VIDE
	  RPAD(NVL(C_ENR.IND_UCC,' '),1)|| -- P2 21.66 pos 2738  
	  RPAD(' ',10)|| --P2 21.61 pos 2739 --VIDE
	  RPAD(' ',10)|| --P2 21.62 pos 2749 --VIDE
	  RPAD(' ',19)|| --P2 21.63 pos 2759 --VIDE
	  RPAD(' ',3)|| --P2 21.64 pos 2778 --VIDE
	  RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1)|| --P2 21.44 pos 2781
	  RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1)|| --P2 21.45 pos 2782
	  RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P2 21.46 pos 2783
	  RPAD(' ',1)|| --P2 21.67 pos 2784 - VIDE
	  RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P2 21.68 pos 2785
	  RPAD(nvl(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P2 21.55 pos 2786
	  RPAD(' ',20)|| --P2 21.89 pos 2798 - VIDE
	  RPAD(' ',10)|| --P2 21.90 pos 2818 - VIDE
	  RPAD(' ',10)|| --P2 21.47 pos 2828 - VIDE
	  RPAD(' ',1)|| --P2 21.56 pos 2838 - VIDE
		RPAD(NVL(C_ENR.IND_INVEST_CAPITAL_RISQ,' '),1)|| --P2 21.57 pos 2839 
		RPAD(NVL(C_ENR.IND_INVEST_PROG_LEGISLATIF,' '),1)|| --P2 21.58 pos 2840 
	  RPAD(NVL(C_ENR.IND_IPRE,' '),1)|| --P2 21.38 pos 2841 
	  RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)|| --P2 21.39 pos 2842
    RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1)|| --P2 21.40 pos 2843
	  RPAD(' ',1)|| --P2 21.41 pos 2844 - VIDE
	  RPAD(' ',1)|| --P2 21.42 pos 2845 - VIDE
	  RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15)|| -- P2 21.43 pos 2846 
	  RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P2 8.13 pos 2861
	  RPAD(' ',40)|| --P2 21.71 pos 2862 - VIDE
	  RPAD(' ',40)|| --P2 21.72 pos 2902 - VIDE
	  RPAD(' ',40)|| --P2 21.73 pos 2942 - VIDE
	  RPAD(' ',40)|| --P2 21.74 pos 2982 - VIDE
	  RPAD(' ',40)|| --P2 21.75 pos 3022 - VIDE
	  RPAD(' ',40)|| --P2 21.76 pos 3062 - VIDE
	  RPAD(' ',11)|| --P2 21.77 pos 3102 - VIDE
	  RPAD(' ',12)|| --P2 21.78 pos 3113 - VIDE
	  RPAD(' ',1)|| --P2 21.94 pos 3125 - VIDE
	  RPAD(' ',2)|| --P2 21.95 pos 3126 - VIDE
	  RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10)|| --P2 21.81 pos 3128
	  RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10)|| --P2 21.82 pos 3138
	  RPAD(' ',15)|| --P2 21.83 pos 3148 -- VIDE
	  RPAD(' ',15)|| --P2 21.84 pos 3163 -- VIDE
	  RPAD(' ',15)|| --P2 21.85 pos 3178 - VIDE
	  RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P2 21.86 pos 3193
	  RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P2 21.87 pos 3194 
    RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| -- P2 21.88 pos 3195 
	  RPAD(' ',20)|| --P2 31.51 pos 3196 - VIDE
	  RPAD(' ',19)|| --P2 31.52 pos 3216 - VIDE
	  RPAD(' ',3)|| --P2 31.53 pos 3235 - VIDE    
	  LPAD (' ', 762)   -- 4000 - 3238
    --LPAD (' ', 1371)   -- 4000 - 2629
    as lignedetail1,  -- debut ligne (taille <= 4000)
    -- (compter 1 blanc de separation entre les 2 champs dans le spool)
    LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
     as lignedetail2
    from
    ENG_CORP_P2   C_ENR
    WHERE A_EXTRAIRE = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' ) ;


       
------------------------------------------------------------------------------------------------------------------------
-- N06: a partir de P_UTLF_SURETE_M1   
------------------------------------------------------------------------------------------------------------------------
select
        to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --RPAD('C_BTR', 12)||
       RPAD(C_ENR.APPLI_SOURCE, 12)||
       -- FIN LFD
       'M'||
       :MASYSDATE||
       'M1'||
       RPAD(' ', 10)||  -- longueur : 1+2+7
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(NVL(C_ENR.ID_SURETE, ' '), 40)||
       RPAD(' ', 40)||
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(NVL(C_ENR.CD_NATOP_CPT, ' '), 12)||
       -- NVL(CD_GRR, 'N')|| A checker
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 1)||
	   RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
	   RPAD(' ', 13)||
	   --FIN EMM
       RPAD(NVL(C_ENR.ID_TIERS_CALC_GAR, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS_GAR,' '), 10)||
       RPAD(' ', 10)||
       RPAD(' ', 20)||
       RPAD(' ', 10)||
       RPAD(nvl(C_ENR.CD_LIEU_DEPOT,' '), 1)||
       RPAD(' ', 20)||
       NVL(C_ENR.CD_ETENDUE_SURETE, ' ')||
       NVL(C_ENR.CD_ARROSAGE, ' ')||
       RPAD(' ', 20)||
       RPAD(NVL(C_ENR.CD_NATURE_SURETE,' '),7)||
       RPAD(' ', 28)||    --2+2+2+2+20
       -- 17/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE WHEN C_ENR.MNT_INITIAL>0 AND C_ENR.MNT_INITIAL<1 THEN pack_utilitaire.f_format_montant_bis2(1)
    --ELSE pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_INITIAL),0)) END || 
        pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_INITIAL)||
        -- FIN LFD
       --pack_utilitaire.F_FORMAT_TAUX(nvl(C_ENR.POURCENT_INITIAL,0))||
    RPAD(' ', 10)||
        -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE WHEN C_ENR.VAL_GARANTIE>0 AND C_ENR.VAL_GARANTIE<1 THEN pack_utilitaire.f_format_montant_bis2(1)
    --ELSE pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.VAL_GARANTIE),0) <0 THEN 0 else nvl((C_ENR.VAL_GARANTIE),0) END ) END ||
        pack_utilitaire.f_format_montant_bis2(C_ENR.VAL_GARANTIE)||
        -- FIN LFD
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.CD_DEVISE, ' '),3)||
       --12/09/2018 - CDS ATOS (EMM) -  US 489
       RPAD(NVL(to_char(C_ENR.DT_REV_MNT, 'YYYYMMDD'),' '),8)||
       --Fin EMM
       -- 07/02/2019 - CDS ATOS (LFD) - CRRV4.2 US 716
       --RPAD(' ', 20)||
       RPAD(NVL(C_ENR.CD_DEV_HYPO, ' '),3)||
       RPAD(' ', 17)||
       -- FIN LFD
       RPAD(NVL(to_char(C_ENR.DT_DEB_EFFET, 'YYYYMMDD'), ' '),8)||
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --RPAD(NVL(to_char(C_ENR.DT_FIN_EFFET, 'YYYYMMDD'), '20991231'),8)||
       RPAD(NVL(to_char(C_ENR.DT_FIN_EFFET, 'YYYYMMDD'), ' '),8)||
       -- FIN LFD
       nvl(C_ENR.ELIGIBILITE_SURETE_PERS,' ')||
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --NVL(C_ENR.cd_pays_recours, 'FR')||
       NVL(C_ENR.cd_pays_recours, '  ')||
       -- FIN LFD 
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --NVL(C_ENR.CD_RANG_SURETE, '1')||
       NVL(C_ENR.CD_RANG_SURETE, ' ')||
       -- FIN LFD
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       -- NVL(C_ENR.CD_SORTIE_RISQ_PAYS, '0')||
       NVL(C_ENR.CD_SORTIE_RISQ_PAYS, ' ')||
       -- FIN LFD
       NVL(C_ENR.cd_methodo_valorisation, ' ')||
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --LPAD(NVL(C_ENR.CD_PERIODICITE, 30),5,0) ||
       LPAD(C_ENR.CD_PERIODICITE,5,0) ||
       -- FIN LFD
       -- 07/02/2019 - CDS ATOS (LFD) - CRRV4.2 US 716
       --RPAD(' ', 20)||
       LPAD(TO_CHAR(C_ENR.EVT_DECL_GAR),2,0)||
       --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(' ', 1)|| -- IND_MOB_ACTIF
	   RPAD(' ', 17)||
	   --FIN EMM
       -- FIN LFD
       RPAD(' ', 25)||   --1+1+1+1+1+20--------
       RPAD(' ', 22)||   --1+16+2+3
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE WHEN substr(nvl(C_ENR.CD_NATURE_SURETE, '     '),-7,5) = 'SEC01'
       --     THEN NVL(C_ENR.CD_BOURSE_COTATION, '  ')
       --     ELSE '  '
       --END||
       NVL(C_ENR.CD_BOURSE_COTATION, '  ')||
       -- FIN LFD
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE WHEN substr(nvl(C_ENR.CD_NATURE_SURETE, '     '),-7,5) = 'SEC01'
       --     THEN NVL(C_ENR.TOP_COT_BAL_2, 'Y')
       --     ELSE ' '
       --END||
       NVL(C_ENR.TOP_COT_BAL_2, ' ')||
       -- FIN LFD
       CASE WHEN substr(nvl(C_ENR.CD_NATURE_SURETE, '     '),-7,5) = 'SEC01'
            THEN '1 '
            ELSE '  '
       END||
       RPAD(' ', 68)||   ---12+1+10+8+5+2+20+10
       RPAD(NVL(C_ENR.CD_NATIO_EMET, ' '), 2)||
       NVL(C_ENR.CD_PER_LIQUID,' ')||
       NVL(C_ENR.CD_PER_LIQUID2, ' ')||
       RPAD(' ', 12)||    --2+1+4+2+2+1
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE WHEN substr(nvl(C_ENR.CD_NATURE_SURETE,'   '),-7,3) in ('REE', 'TAS')
       --            THEN RPAD(NVL(C_ENR.ANNEE_EVT_MIM, ' '),4)||
       --                     RPAD(NVL(C_ENR.ANNEE_CONSTRUIT_BIEN, ' '),4)||
       --                     NVL(C_ENR.CD_METHO_VAL_BIEN,' ')||
       --                     NVL(C_ENR.CD_QUAL_MONTAGE,'2')||
       --                     NVL(C_ENR.CD_QUAL_ACTIF,'3')
       --    ELSE RPAD(' ', 11)
       RPAD(NVL(C_ENR.ANNEE_EVT_MIM, ' '),4)||
       RPAD(NVL(C_ENR.ANNEE_CONSTRUIT_BIEN, ' '),4)||
       NVL(C_ENR.CD_METHO_VAL_BIEN,' ')||
       NVL(C_ENR.CD_QUAL_MONTAGE,' ')||
       NVL(C_ENR.CD_QUAL_ACTIF,' ')||
       --FIN LFD
       pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.MNT_HYPOTHEQUE),0) <0 THEN 0 else nvl((C_ENR.MNT_HYPOTHEQUE),0) END )||
       -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE WHEN substr(nvl(C_ENR.CD_NATURE_SURETE, '   '),-7,3) in ('REE', 'TAS', 'IAS')
       --     THEN NVL(C_ENR.CD_BORRO_BASE,'Y')
       --     ELSE ' '
       --END||
       NVL(C_ENR.CD_BORRO_BASE,' ')||
       -- FIN LFD
       ' '||
       -- 16/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
       --CASE  WHEN substr(nvl(C_ENR.CD_NATURE_SURETE,'   '),-7,3) in ('GUA', 'CDE')
       --     THEN 'FR'
       --     ELSE '  '
       --END||
       NVL(C_ENR.CD_PAYS_LOCAL_GARANT,'  ')||
       -- FIN LFD
      --IFRS9: (longueur:1+1+16+2+3+2+40+40+5)
       --RPAD(' ', 110)||
      --IFRS9: modification de la taille
       RPAD(' ', 98)||
       RPAD(NVL(C_ENR.ID_ENGAGEMENT, ' '), 40)|| -- M1 7.16
       RPAD(NVL(C_ENR.ID_ENGAGEMENT, ' '), 40)|| -- M1 7.17
       --15/01/2018 CDS ATOS (EMM) Sprint 3 US 26 (M1 7.18)
       RPAD(NVL(C_ENR.CD_NUTS, ' '),5)|| --M1 7.18
       --Fin EMM
       -- 07/02/2019 - CDS ATOS (LFD) - CRRV4.2 US 716
       case when C_ENR.MNT_TITRES_RECUS is null  then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_TITRES_RECUS) end || --M1 8.43
       RPAD(NVL(C_ENR.CD_DEV_MNT_TITRES_RECUS, ' '), 3)|| --M1 8.44
       case when C_ENR.MNT_CCNE_RECUS_GAR is null  then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_CCNE_RECUS_GAR) end || --M1 8.45
       RPAD(NVL(C_ENR.CD_DEV_MNT_CCNE_RECUS_GAR, ' '), 3)|| --M1 8.46
	   --02/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_INIT_SURETE_SING_CTRT) || --M1 6.8 - B‚le 4 - MR12731 
	   RPAD(' ', 19) || --M1 6.9
	   RPAD(' ', 3) || --M1 6.10
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20) ||--KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Syst√®me de gestion source' --M1 1.40
	   RPAD(' ', 5) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 15) ||
	   RPAD(' ', 40) ||
	   RPAD(' ', 2) ||
	   RPAD(' ', 11) ||
	   RPAD(' ', 12) ||
	   RPAD(' ', 1) ||
	   RPAD(' ', 1) ||
	   RPAD(' ', 1) ||
	   RPAD(' ', 1) ||
	   RPAD(' ', 100) ||
	   RPAD(' ', 1) ||
	   RPAD(' ', 50) ||
	   -- 50 DONNEES COMPTABLES 
	   RPAD(NVL(C_ENR.CD_DEVISE, ' '), 3)||
	   RPAD('91290000', 12) ||                                      -- M1 50.2 :: valeur par defaut
	   pack_utilitaire.f_format_montant_bis2(C_ENR.VAL_GARANTIE) || -- M1 50.3 :: avant: RPAD(' ', 19) ||
	   RPAD(' ',10)|| --M1 18.1 pos 1559 - VIDE
	   RPAD(' ',1)|| --M1 13.11 pos 1569 - VIDE
	   RPAD(' ',1)|| --M1 13.12 pos 1570 - VIDE
	   RPAD(NVL(C_ENR.METHOD_BALE_GARANT, ' '),7)|| --M1 13.13 pos 1571 
	   RPAD(NVL(C_ENR.METHOD_BALE_GARANT_CALC_SIMUL, ' '),7)|| --M1 13.14 pos 1578 
	   RPAD(' ',40)|| --M1 21.73 pos 1585 - VIDE
	   RPAD(' ',40)|| --M1 21.75 pos 1625 - VIDE
     --RPAD (' ', 2241)   -- 4000 - 1559 - BALE4
     RPAD (' ', 2335)   -- 4000 - 1665 - BALE4
     as lignedetail1,  -- debut ligne (taille <= 4000)
     -- (compter 1 blanc de separation entre les 2 champs dans le spool)
       LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
     as lignedetail2
	 --Fin EMM
    from
    SURETE_M1   C_ENR
    WHERE A_EXTRAIRE = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' ) ;

   
------------------------------------------------------------------------------------------------------------------------
-- N07: a partir de P_UTLF_PROVISIONS_DECOTES_P9 
-- 5 select
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- N07a: a partir de C_PROVISIONS_DECOTES_P9_CRD
------------------------------------------------------------------------------------------------------------------------

 SELECT
     to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
    RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
    RPAD(NVL(C_ENR.APPLI_SOURCE, 'C_BTR'), 12)||  -- 18/02/2019 - CDS ATOS (GBD) - US731
    'M'||
    :MASYSDATE||
    'P9'||
    RPAD(' ', 10)||  -- longueur : 1+2+7
    RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
    --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
    RPAD(' ', 10)||
    RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
    RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
    RPAD(' ', 40)||
    CASE WHEN C_ENR.CD_PERIM_PROV= 'P' THEN RPAD(C_ENR.ID_ENGAGEMENT || '_C',40) ELSE RPAD(' ', 40) END || --P9 1.11 :: M72074
    CASE WHEN C_ENR.CD_PERIM_PROV= 'T' THEN RPAD(C_ENR.ID_PROVISION,40) ELSE RPAD(' ', 40)  END || -- P9 1.16 :: M72074
    -- Les champs 1.11 et 1.16 ont pas la mÍme regle d'alimentation que dans la table  provisions_decotes_p9 
    RPAD(' ', 20)||
    NVL(C_ENR.CD_NAT_DEPRE, ' ')||
    NVL(C_ENR.CD_PERIM_PROV, ' ')||
    RPAD(' ', 12)||
    --22/01/2019 CDS Atos (SQN) US 656
    --RPAD(' ', 20)||
    -- 18/04/2019 - CDS ATOS (LFD) - US 774
    --'2'||
    NVL(C_ENR.ORIGINE_CALCUL_PROVISION, ' ')|| -- 2.4
    -- FIN LFD
    --05/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
	RPAD(' ', 13)||
	--fin EMM
    --Fin SQN
    pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_CRD),0))||
    pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_TRIM_CRD),0))||
    RPAD(NVL(C_ENR.CD_DEVISE, ' '),3)||
    RPAD(NVL(C_ENR.CD_PCCO_CRD, ' '),12)||
    --05/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	-- Debut section 4 -COMPLEMENT DONNEES CLE DE REFERENCE
	RPAD(COALESCE(C_ENR.APPLI_SOURCE,'C_BTR'), 20)|| -- 16/11/2022 - Mantis 64443 - Correction du Score 7 P9 1.20
	RPAD(' ', 5)||  -- P9 4.1
	RPAD(' ', 30)|| -- P9 4.99 :: filler
	RPAD(NVL(C_ENR.CD_DEVISE, ' '),3)||    -- P9 50.1
	RPAD(NVL(C_ENR.CD_PCCO_CRD, ' '),12)|| -- P9 50.10
	pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_CRD),0))|| -- P9 50.11
	RPAD(' ', 12)|| -- P9 50.12
	RPAD(' ', 19)|| -- P9 50.13
	LPAD(' ', 3512)   --4000 - 488
    as lignedetail1,  -- debut ligne (taille <= 4000)
    -- (compter 1 blanc de separation entre les 2 champs dans le spool)
    LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
    --Fin EMM
    as lignedetail2
 FROM PROVISIONS_DECOTES_P9  C_ENR 
 WHERE A_EXTRAIRE                  = 'O'
   and (cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
   AND NVL(FLAG_HN, 'N')             = 'N'
   AND NVL(CD_TYPE_RISQUE, '1') NOT IN ('EQU101')
   AND NVL(MNT_PROVISION_CRD,0)      >0
   AND EXISTS
      (SELECT 1
       FROM ENG_CORP_P1 P1
       WHERE 1                     =1
         AND P1.ID_ENGAGEMENT        = C_ENR.ID_ENGAGEMENT
         AND (NVL(MNT_CRD,0)-NVL(MNT_VR,0) >= 1
             OR
             NVL(MNT_VR,0)>=1)
         AND NVL(P1.A_EXTRAIRE, 'N') = 'O'
       )
   AND ORIGINE_CALCUL_PROVISION ='2' -- 18/04/2019 - CDS ATOS (LFD) - US 774
 ;

------------------------------------------------------------------------------------------------------------------------
-- N07b: a partir de C_PROVISIONS_DECOTES_P9_SOLD
------------------------------------------------------------------------------------------------------------------------
SELECT  
    	to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD('C_BTR', 12)||
       'M'||
       :MASYSDATE||
       'P9'||
       RPAD(' ', 10)||  -- longueur : 1+2+7
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(' ', 40)||
       CASE WHEN C_ENR.CD_PERIM_PROV= 'P' THEN RPAD(C_ENR.ID_ENGAGEMENT || '_S',40) ELSE RPAD(' ', 40) END || --P9 1.11 :: M72074 
       CASE WHEN C_ENR.CD_PERIM_PROV= 'T' THEN RPAD(C_ENR.ID_PROVISION,40) ELSE RPAD(' ', 40) END || -- P9 1.16 :: M72074 
    -- Les champs 1.11 et 1.16 ont pas la mÍme regle d'alimentation que dans la table  provisions_decotes_p9  -- P9 1.16
	   -- FIN LFD
       RPAD(' ', 20)||
       NVL(C_ENR.CD_NAT_DEPRE, ' ')||
       NVL(C_ENR.CD_PERIM_PROV, ' ')||
       RPAD(' ', 12)||
       --22/01/2019 CDS Atos (SQN) US 656
	   --RPAD(' ', 20)||
	   -- 18/04/2019 - CDS ATOS (LFD) - US 774
	   --'2'||
	   NVL(C_ENR.ORIGINE_CALCUL_PROVISION, ' ')|| -- 2.4
	   -- FIN LFD
	   --05/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
	   RPAD(' ', 13)||
	   --fin EMM
	   --Fin SQN
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_SOLD),0))||
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_TRIM_SOLD),0))||
       RPAD(NVL(C_ENR.CD_DEVISE, ' '),3)||
       RPAD(NVL(C_ENR.CD_PCCO_SOLD, ' '),12)||
       --05/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		-- Debut section 4 -COMPLEMENT DONNEES CLE DE REFERENCE
		RPAD(COALESCE(C_ENR.APPLI_SOURCE,'C_BTR'), 20)|| -- 16/11/2022 - Mantis 64443 - Correction du Score 7 P9 1.20
		RPAD(' ', 5)||
		RPAD(' ', 30)||
		RPAD(NVL(C_ENR.CD_DEVISE, ' '),3)||
		RPAD(NVL(C_ENR.CD_PCCO_SOLD, ' '),12)||
		pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_SOLD),0))||
        RPAD(' ', 12)||
		RPAD(' ', 19)||
		LPAD(' ', 3512)   --4000 - 488
     as lignedetail1,  -- debut ligne (taille <= 4000)
     -- (compter 1 blanc de separation entre les 2 champs dans le spool)
       LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
     as lignedetail2
	   --Fin EMM
FROM PROVISIONS_DECOTES_P9  C_ENR 
WHERE A_EXTRAIRE                  = 'O'
  and (cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
  AND NVL(FLAG_HN, 'N')             = 'N'
  AND NVL(CD_TYPE_RISQUE, '1') NOT IN ('EQU101')
  AND NVL(MNT_PROVISION_SOLD,0)     >0
  AND EXISTS
    (SELECT 1
    FROM ENG_CORP_P1 P1
    WHERE 1                     =1
    AND P1.ID_ENGAGEMENT        = C_ENR.ID_ENGAGEMENT
    --AND NVL(P1.MNT_SOLDE, 0)    >=1
    AND NVL(P1.MNT_SOLD_K_A,0) >=1 -- 17/07/2019 - CDS ATOS (LFD) - Mantis 48678
    AND NVL(P1.A_EXTRAIRE, 'N') = 'O'
    )
    AND ORIGINE_CALCUL_PROVISION ='2' -- 18/04/2019 - CDS ATOS (LFD) - US 774
 ;

-- ============================================================================================================
--  Description: modification/ adaptation du perimetre des provisions B1 et B2 - M67006
--               C_CRD_B1_B2 + C_SOLD_B1_B2 + C_PNU_B1_B2
--  Date       : 26/01/2024
--  Developper : KLx_Risques           
-- ============================================================================================================
-- DEBUT :: M67006 - spec 2.4
SELECT  
  to_char(C_ENR.DT_ARRETE, 'YYYYMMDD')                                         || -- 0.1   :: DT_ARRETE
  RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)                                         || -- 0.2   :: ENTITE
  RPAD(NVL(C_ENR.APPLI_SOURCE,'DDR'), 12)                                      || -- 0.3   :: APPLI_SOURCE
  'M'                                                                          || -- 0.4   :: FREQUENCE TRANSMISSION
  :MASYSDATE                                                                   || -- 0.5   :: DATE/ HEURE TRAITEMENT
  'P9'                                                                         || -- 0.6   :: TYPE ENREGISTREMENT
  RPAD(' ', 10)                                                                || -- 0.7(1) + 0.8(2) 0.9(4) + 0.99(3) = 10
  RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)                                      || -- 1.1   :: ID_TIERS_CALC
  RPAD(' ', 10)                                                                || -- 1.2   :: ID_CENTRAL_TIERS
  RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)                                    || -- 1.4   :: ID_AUTORISATION
  RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)                                       || -- 1.6   :: ID_LIGNE_DET
  RPAD(' ', 40)                                                                || -- 1.8   :: IDENTIFIANT SURETE RECUE
  CASE WHEN C_ENR.CD_PERIM_PROV= 'P' THEN RPAD(C_ENR.ID_ENGAGEMENT, 40)           -- 1.11  :: ID_ENGAGEMENT || M72074
    ELSE RPAD(' ', 40)                                                            -- La regle du spool n'est pas la mÍme que la regle 
  END                                                                          ||    -- d'alimentation de la table provisions_decotes_p9 
  CASE WHEN C_ENR.CD_PERIM_PROV= 'T' THEN RPAD(C_ENR.ID_PROVISION,40)           -- 1.16  :: ID_PROVISION || M72074
    ELSE  RPAD(' ', 40)                                                         -- La regle du spool n'est pas la mÍme que la regle
  END                                                                          ||    -- d'alimentation de la table provisions_decotes_p9 
  RPAD(' ', 20)                                                                || -- 1.99(11) + 1.98(7) + 1.97(2) = 20
  NVL(C_ENR.CD_NAT_DEPRE, ' ')                                                 || -- 2.3   :: CD_NAT_DEPRE
  NVL(C_ENR.CD_PERIM_PROV, ' ')                                                || -- 2.1   :: CD_PERIM_PROV
  RPAD(' ', 12)                                                                || -- 2.2   :: FILLER
  NVL(C_ENR.ORIGINE_CALCUL_PROVISION, ' ')                                     || -- 2.4   :: ORIGINE_CALCUL_PROVISION
  RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')                             || -- 2.5   :: CD_TYPE_PROD_BANCAIRE
  RPAD(' ', 13)                                                                || -- 2.99  :: FILLER
  pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_DEPRECIATION,0))         || -- 3.2   :: MNT_PROVISION_CRD
  pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_PROVISION_TRIM_CRD,0))   || -- 3.3   :: MNT_PROVISION_TRIM_CRD
  RPAD(NVL(C_ENR.CD_DEVISE, ' '),3)                                            || -- 3.1   :: CD_DEVISE
  RPAD(NVL(C_ENR.CD_PCCO_CRD, ' '),12)                                         || -- 3.15  :: CD_PCCO_CRD
  RPAD(NVL(C_ENR.SYSTEME_SOURCE,'DDR'), 20)                                    || -- 1.20  :: SYSTEME_SOURCE 
  RPAD(' ', 5)                                                                 || -- 4.1   :: CODE ENTITE SUCCURSALE
  RPAD(' ', 30)                                                                || -- 4.99  :: FILLER
  RPAD(NVL(C_ENR.CD_DEVISE_LIASSE, ' '),3)                                     || -- 50.1  :: CD_DEVISE_LIASSE
  RPAD(NVL(C_ENR.PCCO_DEPRECIATION, ' '),12)                                   || -- 50.10 :: PCCO_DEPRECIATION
  pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_DEPRECIATION),0))       || -- 50.11 :: MNT_DEPRECIATION
  RPAD(' ', 12)                                                                || -- 50.12 :: PCCO - SURCOTES
  RPAD(' ', 19)                                                                || -- 50.13 :: MONTANT DES SURCOTES
  LPAD(' ', 3512) as lignedetail1                                               , -- debut ligne (taille <= 4000) :: 4000 - 488
  --- compter 1 blanc de separation entre les 2 champs dans le spool
  LPAD(' ', 1098) as lignedetail2 -- fin de ligne -- Mantis 11841
 FROM provisions_decotes_p9 C_ENR
WHERE (C_ENR.cd_conso_cpt = :ENTITE
   OR  :ENTITE            = 'TOTAL')
  AND C_ENR.origine_calcul_provision = '1'
  AND C_ENR.a_extraire               = 'O'
  AND substr(C_ENR.id_provision, -2) IN ('BL','HB')
;
-- FIN :: M67006 - spec 2.4

------------------------------------------------------------------------------------------------------------------------
-- PAVE P1 - Hors NAT02, variante 4 - com separador ;
------------------------------------------------------------------------------------------------------------------------
select
     CAST(
       RPAD(TO_CHAR(P1_H_0_1,'YYYYMMDD'),8,' ')||';'||   -- 0.1 (P1)     EXATO
       RPAD(P1_H_0_2,5,' ')||';'||   -- 0.2 (P1)     EXATO
       RPAD('C_DDR',12,' ')||';'||   -- 0.3 (P1)     EXATO
       'M'||';'||   -- 0.4 (P1)     EXATO
       :MASYSDATE||';'||   -- 0.5 (P1)     EXATO
       'P1'||';'||   -- 0.6 (P1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (P1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (P1)     BRANCO
       RPAD(' ', 4)||';'||   -- 0.9 (P1)     BRANCO
       RPAD(' ', 3)||';'||   -- 0.99 (P1)    BRANCO
       RPAD(NVL(P1_H_1_1,' '),20,' ')||';'||   -- 1.1 (P1)     EXATO
       RPAD(' ', 10)||';'||   -- 1.2 (P1)     BRANCO
       RPAD(NVL(P1_H_1_4,' '),30,' ')||';'||   -- 1.4 (P1)     EXATO
       RPAD(NVL(P1_H_1_6,' '),30,' ')||';'||   -- 1.6 (P1)     EXATO
       RPAD(' ', 40)||';'||   -- 1.8 (P1)     BRANCO
       RPAD(NVL(P1_H_1_11,' '),40,' ')||';'||   -- 1.11 (P1)    EXATO
       RPAD(' ', 40)||';'||   -- 1.16 (P1)    BRANCO
       RPAD(' ', 11)||';'||   -- 1.99 (P1)    BRANCO
       RPAD(' ', 7)||';'||   -- 1.98 (P1)    BRANCO
       RPAD(' ', 2)||';'||   -- 1.97 (P1)    BRANCO
       RPAD(NVL(P1_1_1,' '),7,' ')||';'||   -- P1 1.1       EXATO
       RPAD(NVL(P1_1_2,' '),2,' ')||';'||   -- P1 1.2       EXATO
       RPAD(NVL(P1_4_34,' '),1,' ')||';'||   -- P1 4.34      EXATO
       RPAD(NVL(P1_2_0,' '),6,' ')||';'||   -- P1 2.0       EXATO
       RPAD(NVL(P1_2_4,' '),1,' ')||';'||   -- P1 2.4       EXATO
       RPAD(NVL(P1_2_6,' '),5,' ')||';'||   -- P1 2.6       EXATO
       RPAD(NVL(P1_2_18,' '),3,' ')||';'||   -- P1 2.18      EXATO
       RPAD(NVL(P1_2_29,' '),12,' ')||';'||   -- P1 2.29      EXATO
       RPAD(TO_CHAR(P1_3_2,'YYYYMMDD'),8,' ')||';'||   -- P1 3.2       EXATO
       RPAD(TO_CHAR(P1_3_4,'YYYYMMDD'),8,' ')||';'||   -- P1 3.4       EXATO
       RPAD(' ', 10)||';'||   -- P1 16.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.1      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 18.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 18.17     BRANCO
       RPAD(NVL(P1_18_18,' '),3,' ')||';'||   -- P1 18.18     EXATO
       RPAD(' ', 50)||';'||   -- P1 3.98      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.1      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.2      BRANCO
       NVL(P1_5_5,'N')||';'||   -- P1 5.5       EXATO
       RPAD(' ', 1)||';'||   -- P1 4.1       BRANCO
       NVL(P1_5_2,'N')||';'||   -- P1 5.2       EXATO
       RPAD(' ', 8)||';'||   -- P1 5.3       BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_2),0))||';'||   -- P1 4.2       EXATO
       RPAD(NVL(P1_4_3,' '),3,' ')||';'||   -- P1 4.3       EXATO
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END||';'||   -- P1 4.4       REGRA
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END||';'||   -- P1 4.5       REGRA
       RPAD(' ', 19)||';'||   -- P1 4.9       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.13      BRANCO
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END||';'||   -- P1 4.14      REGRA
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END||';'||   -- P1 4.15      REGRA
       RPAD(' ', 19)||';'||   -- P1 4.16      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.17      BRANCO
       RPAD(NVL(P1_4_18,' '),12,' ')||';'||   -- P1 4.18      EXATO
       RPAD(' ', 19)||';'||   -- P1 4.6       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.7       BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.19      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.20      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.21      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.22      BRANCO
       RPAD(' ', 2)||';'||   -- P1 4.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.6       BRANCO
       RPAD(' ', 20)||';'||   -- P1 5.7       BRANCO
       RPAD(' ', 10)||';'||   -- P1 5.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.33      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.10      BRANCO
       RPAD(' ', 25)||';'||   -- P1 5.11      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.32      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.46      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.47      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.40      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.41      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.42      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.43      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.44      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.45      BRANCO
       RPAD(' ', 19)||';'||   -- P1 5.19      BRANCO
       RPAD(' ', 3)||';'||   -- P1 5.20      BRANCO
       RPAD(nvl(P1_19_5,' '),3)||';'||   -- P1 19.5      EXATO
       RPAD(' ', 12)||';'||   -- P1 3.56      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.50      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.51      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.52      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.53      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.54      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.55      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.57      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.58      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.59      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.60      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.61      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.8       BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.31      BRANCO
       RPAD(' ', 2)||';'||   -- P1 12.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.7       BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.70      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.71      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.74      BRANCO
       RPAD(NVL(P1_2_99,' '), 20)||';'||   -- P1 2.99      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.80      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.81      BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.82      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.83      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.15      BRANCO
       RPAD(' ', 25)||';'||   -- P1 13.10     BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.16      BRANCO
       RPAD(' ', 25)||';'||   -- P1 3.17      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.19      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.84      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.85      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.72      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.73      BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.0       BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.1       BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.2       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.6       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.7       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.10      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.11      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.12      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.13      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.14      BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.3       BRANCO
       RPAD(' ', 3)||';'||   -- P1 12.5      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.15      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.16      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.17      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.18      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.19      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.20      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.21      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.22      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.3      BRANCO
       RPAD(' ', 5)||';'||   -- P1 11.33     BRANCO
       RPAD(' ', 2)||';'||   -- P1 11.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.9      BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.13     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 16.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.20     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.22     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.99     BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.31      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.32      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.33      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.13     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.36      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.49      BRANCO
       RPAD(' ', 4)||';'||   -- P1 4.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.45      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.46      BRANCO
       LPAD(ABS(TRUNC(P1_3_20)),2,'0')||LPAD(ABS(MOD(P1_3_20 *10000,10000)),4,'0')||';'||   -- P1 3.20      EMENDA
       RPAD(NVL(P1_4_8, ' '),1,' ')||';'||   -- P1 4.8       EXATO
       RPAD(' ', 3)||';'||   -- P1 12.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.75      BRANCO
       RPAD(NVL(P1_4_42, ' '),6,' ')||';'||   -- P1 4.42      EXATO
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8)||';'||   -- P1 3.3       EXATO
       RPAD(' ', 2)||';'||   -- P1 4.43      BRANCO
       RPAD(' ', 5)||';'||   -- P1 4.44      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.47      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.99      BRANCO
       RPAD(' ', 20)||';'||   -- P1 3.62      BRANCO
       RPAD(' ', 10)||';'||   -- P1 3.63      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.64      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.65      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.66      BRANCO
       RPAD(' ', 7)||';'||   -- P1 6.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.26      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.27      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.28      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.30      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.29      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.40      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.41      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.48      BRANCO
       RPAD(' ', 45)||';'||   -- P1 4.98      BRANCO
       RPAD(' ', 10)||';'||   -- P1 8.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.38      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.39      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.37      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.35      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.36      BRANCO
       RPAD(' ', 30)||';'||   -- P1 9.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 12.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 12.19     BRANCO
       RPAD(' ', 8)||';'||   -- P1 12.6      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.1      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.2      BRANCO
       RPAD(' ', 20)||';'||   -- P1 12.17     BRANCO
       RPAD(' ', 10)||';'||   -- P1 12.18     BRANCO
       RPAD(' ', 24)||';'||   -- P1 10.99     BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.89      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.90      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.86      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.87      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.88      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.15     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 11.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.76      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.77      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.4      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.10      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.11      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.12      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.13      BRANCO
       RPAD(' ', 2)||';'||   -- P1 10.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.1       BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.2       BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.11      BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.12      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.22     BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.21     BRANCO
       RPAD(' ', 10)||';'||   -- P1 10.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 9.5       BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.24     BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.5      BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.98     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.5      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.6      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.7      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.8      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.9      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.10     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.11     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.12     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.13     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.15     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.17     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.18     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.99     BRANCO
       RPAD(NVL(P1_22_56, ' '),3,' ')||';'||   -- P1 22.56     EXATO
       RPAD(NVL(P1_22_57, ' '),1,' ')||';'||   -- P1 22.57     EXATO
       RPAD(NVL(P1_22_1, ' '),40,' ')||';'||   -- P1 22.1      EXATO
       RPAD(NVL(P1_22_51, ' '),40,' ')||';'||   -- P1 22.51     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.2      BRANCO
       RPAD(' ', 4)||';'||   -- P1 22.3      BRANCO
       RPAD(' ', 40)||';'||   -- P1 22.4      BRANCO
       RPAD(P1_22_5,2,' ')||';'||   -- P1 22.5      EXATO
       RPAD(NVL(P1_22_52, ' '),10,' ')||';'||   -- P1 22.52     EXATO
       RPAD(nvl(P1_22_6,' '),2,' ')||';'||   -- P1 22.6      EXATO
       RPAD(NVL(P1_22_53, ' '),2,' ')||';'||   -- P1 22.53     EXATO
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||';'||   -- P1 22.54     EXATO
       RPAD(upper(NVL(P1_22_55, ' ')),3,' ')||';'||   -- P1 22.55     EXATO
       RPAD('97',2)||';'||   -- P1 22.7      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||';'||   -- P1 22.8      EXATO
       RPAD(nvl(P1_22_9, 'EUR'), 3)||';'||   -- P1 22.9      EXATO
       RPAD(NVL(P1_22_12, ' '),1,' ')||';'||   -- P1 22.12     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.13     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.14     BRANCO
       RPAD(' ', 12)||';'||   -- P1 22.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.20     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.21     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.22     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.23     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.25     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.26     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.27     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.28     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.29     BRANCO
       RPAD(' ', 7)||';'||   -- P1 22.30     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.31     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.33     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.34     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.35     BRANCO
       RPAD(NVL(P1_22_36,' '),1,' ')||';'||   -- P1 22.36     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.37     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.40     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.41     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.42     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.43     BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_22_44),0))||';'||   -- P1 22.44     EXATO
       RPAD('EUR', 3)||';'||   -- P1 22.45     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.46     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.47     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.48     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.49     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.50     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.58     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.59     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.60     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.61     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.62     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.63     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.64     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.65     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.66     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.67     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.68     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.69     BRANCO
       RPAD(' ', 5)||';'||   -- P1 22.70     BRANCO
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||';'||   -- P1 22.71     EXATO
       RPAD(NVL(P1_22_72, ' '),2,' ')||';'||   -- P1 22.72     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.73     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.74     BRANCO
       RPAD(NVL(P1_23_1, ' '),1,' ')||';'||   -- P1 23.1      EXATO
       RPAD(NVL(P1_23_2, ' '),7,' ')||';'||   -- P1 23.2      EXATO
       RPAD(NVL(P1_23_3, ' '),20,' ')||';'||   -- P1 23.3      EXATO
       RPAD(NVL(P1_23_4, ' '),3,' ')||';'||   -- P1 23.4      EXATO
       RPAD(NVL(P1_23_5, ' '),3,' ')||';'||   -- P1 23.5      EXATO
       RPAD(NVL(P1_23_6, ' '),1,' ')||';'||   -- P1 23.6      EXATO
       RPAD(NVL(P1_23_7, ' '),40,' ')||';'||   -- P1 23.7      EXATO
       RPAD(' ', 5)||';'||   -- P1 23.12     BRANCO
       RPAD(' ', 5)||';'||   -- P1 23.13     BRANCO
       RPAD (nvl(P1_23_8,' '), 12)||';'||   -- P1 23.8      EXATO
       RPAD (nvl(P1_23_9,' '), 12)||';'||   -- P1 23.9      EXATO
       RPAD (nvl(P1_23_10,' '), 12)||';'||   -- P1 23.10     EXATO
       RPAD (nvl(P1_23_11,' '), 12)||';'||   -- P1 23.11     EXATO
       RPAD(' ', 2)||';'||   -- P1 23.99     BRANCO
       RPAD(NVL(P1_24_1,' '),1,' ')||';'||   -- P1 24.1      EXATO
       RPAD(' ', 2)||';'||   -- P1 24.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.5      BRANCO
       RPAD(' ', 13)||';'||   -- P1 24.6      BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.8      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.11     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.12     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.15     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.17     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.18     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.20     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.21     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.22     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.23     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.25     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.26     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.27     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.28     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.29     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.30     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.97     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.31     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.32     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.36     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.98     BRANCO
       RPAD(' ', 12)||';'||   -- P1 24.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.6      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.7      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.8      BRANCO
       RPAD(' ', 39)     -- P1 25.99     CORTE-A
     AS VARCHAR2(4000)) as lignedetail1,
     CAST(
       RPAD(' ', 60)||';'||   -- P1 25.99     CORTE-B
       RPAD(NVL(P1_26_1,' '),1,' ')||';'||   -- P1 26.1      EXATO
       RPAD(NVL(P1_22_11, ' '), 1)||';'||   -- P1 22.11     EXATO
       RPAD(NVL(P1_26_3, ' '), 3)||';'||   -- P1 26.3      EXATO
       RPAD(NVL(P1_26_4, ' '), 3)||';'||   -- P1 26.4      EXATO
       RPAD(' ', 44)||';'||   -- P1 26.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 27.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 27.2      BRANCO
       RPAD(P1_27_3, 1)||';'||   -- P1 27.3      EXATO
       RPAD(NVL(P1_27_4, ' '), 2)||';'||   -- P1 27.4      EXATO
       RPAD(' ', 23)||';'||   -- P1 27.99     BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 29.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.2      BRANCO
       RPAD(' ', 2)||';'||   -- P1 30.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.3      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.5      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.6      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.7      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.8      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.11     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.12     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.16     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.17     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.18     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.19     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.20     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.21     BRANCO
       RPAD(' ', 25)||';'||   -- P1 30.22     REGRA
       'N'||';'||   -- P1 30.23     REGRA
       RPAD(' ', 25)||';'||   -- P1 30.24     REGRA
       'N'||';'||   -- P1 30.25     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.27     BRANCO
       RPAD(' ', 5)||';'||   -- P1 31.1      BRANCO
       RPAD(NVL(P1_31_2, ' '),40,' ')||';'||   -- P1 31.2      EXATO
       RPAD(NVL(P1_31_3,' '),40)||';'||   -- P1 31.3      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||';'||   -- P1 31.4      EXATO
       RPAD(NVL(P1_31_5, ' '),1,' ')||';'||   -- P1 31.5      EXATO
       RPAD (NVL(P1_31_6,'2'), 1)||';'||   -- P1 31.6      EXATO
       RPAD(' ', 6)||';'||   -- P1 31.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.8      BRANCO
       RPAD(NVL(P1_31_9, ' '),15,' ')||';'||   -- P1 31.9      EXATO
       RPAD(NVL(P1_31_10, ' '),2,' ')||';'||   -- P1 31.10     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.11     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.13     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.15     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.16     BRANCO
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.17     EMENDA
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.18     EMENDA
       RPAD(' ', 6)||';'||   -- P1 31.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.20     BRANCO
       RPAD(' ', 2)||';'||   -- P1 31.21     BRANCO
       P1_31_22||';'||   -- P1 31.22     EXATO
       RPAD(' ', 19)||';'||   -- P1 31.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.24     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.25     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.26     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.27     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.28     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.29     BRANCO
       RPAD(NVL(P1_31_37,' '),1)||';'||   -- P1 31.37     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.38     BRANCO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||';'||   -- P1 29.3      EXATO
       RPAD ('EUR', 3)||';'||   -- P1 29.4      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.6      BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.30     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.31     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.32     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.34     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.36     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.24     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.25     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.26     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.29     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.30     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.31     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.32     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.33     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.34     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.35     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.36     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.37     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.40     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.41     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.42     BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.3      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.4      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.5      BRANCO
       RPAD(' ', 20)||';'||   -- P1 28.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 28.7      BRANCO
       RPAD(' ', 15)||';'||   -- P1 28.8      BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.9      BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.11     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.12     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.13     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.14     BRANCO
       'EUR'||';'||   -- P1 50.1      EXATO
       RPAD(NVL(P1_50_2, ' '), 12)||';'||   -- P1 50.2      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||';'||   -- P1 50.3      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.5      BRANCO
       RPAD(NVL(P1_50_8, ' '), 12)||';'||   -- P1 50.8      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||';'||   -- P1 50.9      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.15     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.16     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.17     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.18     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.19     BRANCO
       RPAD(NVL(P1_21_22,' '),2)||';'||   -- P1 21.22     EXATO
       RPAD(NVL(TO_CHAR(P1_21_23, 'YYYYMMDD'), ' '),8)||';'||   -- P1 21.23     EXATO
       case when P1_21_29 is not null then '+'||LPAD(P1_21_29,5,'0') else RPAD(' ',6) end||';'||   -- P1 21.29     EXATO
       RPAD(NVL(P1_21_25,' '),2)||';'||   -- P1 21.25     EXATO
       RPAD(NVL(P1_21_26,' '),1)||';'||   -- P1 21.26     EXATO
       RPAD(NVL(P1_21_27,' '),1)||';'||   -- P1 21.27     EXATO
       RPAD(NVL(P1_21_28,' '),2)||';'||   -- P1 21.28     EXATO
       case when P1_21_30 is not null then RPAD(pack_utilitaire.f_format_montant_bis2(P1_21_30),19) else RPAD(' ',19) end||';'||   -- P1 21.30     EXATO
       RPAD(NVL(P1_21_31, ' '), 3)||';'||   -- P1 21.31     EXATO
       RPAD(' ', 15)||';'||   -- P1 21.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.33     BRANCO
       RPAD(' ', 12)||';'||   -- P1 15        BRANCO
       RPAD(' ', 12)||';'||   -- P1 16        BRANCO
       RPAD(' ', 12)||';'||   -- P1 14        BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.20     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.35     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.36     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.47     BRANCO
       RPAD(' ', 7)||';'||   -- P1 21.48     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.49     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.50     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.51     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.52     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.53     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.54     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.44     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.45     BRANCO
       RPAD(NVL(P1_21_46,' '),1)||';'||   -- P1 21.46     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.38     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.39     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.40     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.41     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.42     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.43     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.56     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.57     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.58     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.59     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.60     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.61     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.62     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.63     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.64     BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.65     REGRA
       RPAD(' ', 1)||';'||   -- P1 21.66     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.67     BRANCO
       RPAD(NVL(P1_21_68,' '),1)||';'||   -- P1 21.68     EXATO
       RPAD(NVL(P1_21_55,' '),12)||';'||   -- P1 21.55     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.69     BRANCO
       RPAD(' ', 20)||';'||   -- P1 21.89     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.90     BRANCO
       RPAD(NVL(P1_8_13,' '),1)||';'||   -- P1 8.13      EXATO
       RPAD(' ', 40)||';'||   -- P1 21.71     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.72     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.73     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.74     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.75     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.76     BRANCO
       RPAD(' ', 11)||';'||   -- P1 21.77     BRANCO
       RPAD(' ', 12)||';'||   -- P1 21.78     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.94     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.95     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.79     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.80     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.81     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.82     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.83     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.84     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.85     BRANCO
       RPAD(NVL(P1_21_86,' '),1)||';'||   -- P1 21.86     EXATO
       RPAD(NVL(P1_21_87,' '),1)||';'||   -- P1 21.87     EXATO
       RPAD(NVL(P1_21_88,' '),1)||';'||   -- P1 21.88     EXATO
       RPAD(' ', 19)||';'||   -- P1 21.91     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.92     BRANCO
       RPAD(' ', 5)||';'||   -- P1 21.93     BRANCO
       RPAD(' ', 20)||';'||   -- P1 31.51     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.52     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.53     BRANCO
       RPAD(NVL(TO_CHAR(P1_1001,'YYYYMMDD'),' '), 8)||';'||   -- P1 1001      NOVO
       RPAD(NVL(TO_CHAR(P1_1002,'YYYYMMDD'),' '), 8)||';'||   -- P1 1002      NOVO
       RPAD(NVL(P1_22_222,' '), 1)||';'||   -- P1 22.222    NOVO
       RPAD(NVL(P1_24_22_1,' '), 1)||';'||   -- P1 24.22.1   NOVO
       RPAD(NVL(P1_600,' '), 1)||';'||   -- P1 600       NOVO
       RPAD(NVL(P1_601,' '), 1)||';'||   -- P1 601       NOVO
       RPAD(NVL(P1_602,' '), 1)||';'||   -- P1 602       NOVO
       CASE WHEN P1_603 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_603) END||';'||   -- P1 603       NOVO
       RPAD(NVL(P1_603_1,' '), 3)||';'||   -- P1 603.1     NOVO
       CASE WHEN P1_604 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_604) END||';'||   -- P1 604       NOVO
       RPAD(NVL(P1_604_1,' '), 3)||';'||   -- P1 604.1     NOVO
       CASE WHEN P1_605 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_605) END||';'||   -- P1 605       NOVO
       RPAD(NVL(P1_605_1,' '), 3)||';'||   -- P1 605.1     NOVO
       RPAD(NVL(P1_606,' '), 40)||';'||   -- P1 606       NOVO
       RPAD(NVL(P1_607,' '), 1)||';'||   -- P1 607       NOVO
       CASE WHEN P1_608 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_608) END||';'||   -- P1 608       NOVO
       RPAD(NVL(P1_608_1,' '), 3)||';'||   -- P1 608.1     NOVO
       RPAD(NVL(TO_CHAR(P1_609,'YYYYMMDD'),' '), 8)||';'||   -- P1 609       NOVO
       CASE WHEN P1_610 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_610) END||';'||   -- P1 610       NOVO
       RPAD(NVL(P1_610_1,' '), 3)||';'||   -- P1 610.1     NOVO
       RPAD(NVL(TO_CHAR(P1_611,'YYYYMMDD'),' '), 8)||';'||   -- P1 611       NOVO
       CASE WHEN P1_612 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_612) END||';'||   -- P1 612       NOVO
       RPAD(NVL(P1_612_1,' '), 3)||';'||   -- P1 612.1     NOVO
       RPAD(NVL(P1_613,' '), 1)||';'||   -- P1 613       NOVO
       CASE WHEN P1_614 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_614) END||';'||   -- P1 614       NOVO
       RPAD(NVL(P1_614_1,' '), 3)||';'||   -- P1 614.1     NOVO
       LPAD(NVL(TO_CHAR(P1_615),' '), 6)||';'||   -- P1 615       NOVO
       RPAD(NVL(P1_616,' '), 1)||';'||   -- P1 616       NOVO
       RPAD(NVL(P1_617,' '), 1)||';'||   -- P1 617       NOVO
       RPAD(NVL(P1_618,' '), 1)||';'||   -- P1 618       NOVO
       CASE WHEN P1_619 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_619) END||';'||   -- P1 619       NOVO
       RPAD(NVL(P1_620,' '), 1)||';'||   -- P1 620       NOVO
       RPAD(NVL(P1_635,' '), 1)||';'||   -- P1 635       NOVO
       RPAD(NVL(P1_622,' '), 1)||';'||   -- P1 622       NOVO
       RPAD(NVL(P1_623,' '), 40)||';'||   -- P1 623       NOVO
       CASE WHEN P1_624 IS NULL THEN RPAD(' ', 15) ELSE pack_utilitaire.f_format_taux_15(P1_624) END||';'||   -- P1 624       NOVO
       RPAD(NVL(P1_625,' '), 2)||';'||   -- P1 625       NOVO
       RPAD(NVL(P1_626,' '), 1)||';'||   -- P1 626       NOVO
       RPAD(NVL(P1_627,' '), 1)||';'||   -- P1 627       NOVO
       CASE WHEN P1_628 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_628) END||';'||   -- P1 628       NOVO
       RPAD(NVL(P1_628_1,' '), 3)||';'||   -- P1 628.1     NOVO
       RPAD(NVL(P1_629,' '), 1)||';'||   -- P1 629       NOVO
       CASE WHEN P1_630 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_630) END||';'||   -- P1 630       NOVO
       RPAD(NVL(P1_630_1,' '), 3)||';'||   -- P1 630.1     NOVO
       CASE WHEN P1_631 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_631) END||';'||   -- P1 631       NOVO
       RPAD(NVL(P1_631_1,' '), 3)||';'||   -- P1 631.1     NOVO
       CASE WHEN P1_632 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_632) END||';'||   -- P1 632       NOVO
       RPAD(NVL(P1_632_1,' '), 3)||';'||   -- P1 632.1     NOVO
       CASE WHEN P1_633 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_633) END||';'||   -- P1 633       NOVO
       RPAD(NVL(P1_633_1,' '), 3)||';'||   -- P1 633.1     NOVO
       RPAD(NVL(P1_621,' '), 8)||';'||   -- P1 621       NOVO
       RPAD(' ', 1176)     -- P1 99.99     FILLER
     AS VARCHAR2(3999)) as lignedetail2
  from ENG_CORP_P1_BIS
 where NO_VARIANTE = 4
   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
 order by NO_VARIANTE;

------------------------------------------------------------------------------------------------------------------------
-- PAVE P1 - Hors NAT02, variante 5 - com separador ;
------------------------------------------------------------------------------------------------------------------------
select
     CAST(
       RPAD(TO_CHAR(P1_H_0_1,'YYYYMMDD'),8,' ')||';'||   -- 0.1 (P1)     EXATO
       RPAD(P1_H_0_2,5,' ')||';'||   -- 0.2 (P1)     EXATO
       RPAD('C_DDR',12,' ')||';'||   -- 0.3 (P1)     EXATO
       'M'||';'||   -- 0.4 (P1)     EXATO
       :MASYSDATE||';'||   -- 0.5 (P1)     EXATO
       'P1'||';'||   -- 0.6 (P1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (P1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (P1)     BRANCO
       RPAD(' ', 4)||';'||   -- 0.9 (P1)     BRANCO
       RPAD(' ', 3)||';'||   -- 0.99 (P1)    BRANCO
       RPAD(NVL(P1_H_1_1,' '),20,' ')||';'||   -- 1.1 (P1)     EXATO
       RPAD(' ', 10)||';'||   -- 1.2 (P1)     BRANCO
       RPAD(NVL(P1_H_1_4,' '),30,' ')||';'||   -- 1.4 (P1)     EXATO
       RPAD(NVL(P1_H_1_6,' '),30,' ')||';'||   -- 1.6 (P1)     EXATO
       RPAD(' ', 40)||';'||   -- 1.8 (P1)     BRANCO
       RPAD(NVL(P1_H_1_11,' '),40,' ')||';'||   -- 1.11 (P1)    EXATO
       RPAD(' ', 40)||';'||   -- 1.16 (P1)    BRANCO
       RPAD(' ', 11)||';'||   -- 1.99 (P1)    BRANCO
       RPAD(' ', 7)||';'||   -- 1.98 (P1)    BRANCO
       RPAD(' ', 2)||';'||   -- 1.97 (P1)    BRANCO
       RPAD(NVL(P1_1_1,' '),7,' ')||';'||   -- P1 1.1       EXATO
       RPAD(NVL(P1_1_2,' '),2,' ')||';'||   -- P1 1.2       EXATO
       RPAD(NVL(P1_4_34,' '),1,' ')||';'||   -- P1 4.34      EXATO
       RPAD(NVL(P1_2_0,' '),6,' ')||';'||   -- P1 2.0       EXATO
       RPAD(NVL(P1_2_4,' '),1,' ')||';'||   -- P1 2.4       EXATO
       RPAD(NVL(P1_2_6,' '),5,' ')||';'||   -- P1 2.6       EXATO
       RPAD(NVL(P1_2_18,' '),3,' ')||';'||   -- P1 2.18      EXATO
       RPAD(NVL(P1_2_29,' '),12,' ')||';'||   -- P1 2.29      EXATO
       RPAD(NVL(TO_CHAR(P1_3_2,'YYYYMMDD'),' '),8,' ')||';'||   -- P1 3.2       EXATO
       RPAD(NVL(TO_CHAR(P1_3_4,'YYYYMMDD'),' '),8,' ')||';'||   -- P1 3.4       EXATO
       RPAD(' ', 10)||';'||   -- P1 16.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.1      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 18.5      BRANCO
       RPAD(NVL(P1_18_17,' '),3,' ')||';'||   -- P1 18.17     EXATO
       RPAD(NVL(P1_18_18,' '),3,' ')||';'||   -- P1 18.18     EXATO
       RPAD(' ', 50)||';'||   -- P1 3.98      BRANCO
       RPAD(NVL(P1_21_1,' '),2,' ')||';'||   -- P1 21.1      EXATO
       NVL(TO_CHAR(P1_21_2, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.2      EXATO
       NVL(P1_5_5,'N')||';'||   -- P1 5.5       EXATO
       RPAD(NVL(P1_4_1,' '),1,' ')||';'||   -- P1 4.1       EXATO
       RPAD(NVL(P1_5_2,' '),1,' ')||';'||   -- P1 5.2       EXATO
       NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 5.3       EXATO
       RPAD(' ', 19)||';'||   -- P1 4.2       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.3       BRANCO
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END||';'||   -- P1 4.4       REGRA
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END||';'||   -- P1 4.5       REGRA
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_9),0))||';'||   -- P1 4.9       EXATO
       NVL(P1_4_13,'EUR')||';'||   -- P1 4.13      EXATO
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END||';'||   -- P1 4.14      REGRA
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END||';'||   -- P1 4.15      REGRA
       RPAD(' ', 19)||';'||   -- P1 4.16      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.17      BRANCO
       RPAD(NVL(P1_4_18,' '),12,' ')||';'||   -- P1 4.18      EXATO
       CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END||';'||   -- P1 4.6       EXATO
       RPAD(NVL(P1_4_7, ' '), 3)||';'||   -- P1 4.7       EXATO
       RPAD(NVL(P1_4_19,' '),12,' ')||';'||   -- P1 4.19      EXATO
       RPAD(' ', 10)||';'||   -- P1 4.20      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.21      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.22      BRANCO
       RPAD(' ', 2)||';'||   -- P1 4.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.6       BRANCO
       RPAD(' ', 20)||';'||   -- P1 5.7       BRANCO
       RPAD(' ', 10)||';'||   -- P1 5.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.33      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.10      BRANCO
       RPAD(' ', 25)||';'||   -- P1 5.11      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.32      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.46      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.47      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.40      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.41      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.42      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.43      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.44      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.45      BRANCO
       RPAD(' ', 19)||';'||   -- P1 5.19      BRANCO
       RPAD(' ', 3)||';'||   -- P1 5.20      BRANCO
       RPAD(nvl(P1_19_5,' '),3)||';'||   -- P1 19.5      EXATO
       RPAD(' ', 12)||';'||   -- P1 3.56      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.50      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.51      BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl(P1_3_52, 0))||';'||   -- P1 3.52      EXATO
       RPAD(nvl(P1_3_53,'EUR'),3, ' ')||';'||   -- P1 3.53      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.54      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.55      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.57      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.58      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.59      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.60      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.61      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.8       BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.31      BRANCO
       RPAD(' ', 2)||';'||   -- P1 12.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.7       BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.70      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.71      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.74      BRANCO
       RPAD(NVL(P1_2_99,' '), 20)||';'||   -- P1 2.99      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.80      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.81      BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.82      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.83      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.15      BRANCO
       RPAD(' ', 25)||';'||   -- P1 13.10     BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.16      BRANCO
       RPAD(' ', 25)||';'||   -- P1 3.17      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.19      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.84      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.85      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.72      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.73      BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.0       BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.1       BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.2       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.6       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.7       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.10      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.11      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.12      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.13      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.14      BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.3       BRANCO
       RPAD(' ', 3)||';'||   -- P1 12.5      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.15      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.16      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.17      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.18      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.19      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.20      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.21      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.22      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.3      BRANCO
       RPAD(' ', 5)||';'||   -- P1 11.33     BRANCO
       RPAD(' ', 2)||';'||   -- P1 11.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.9      BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.13     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 16.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.20     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.22     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.99     BRANCO
       RPAD(NVL(P1_4_31,' '), 1,' ')||';'||   -- P1 4.31      EXATO
       RPAD(' ', 1)||';'||   -- P1 4.32      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.33      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.13     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.36      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.49      BRANCO
       RPAD(' ', 4)||';'||   -- P1 4.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.45      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.46      BRANCO
       LPAD(ABS(TRUNC(NVL(P1_3_20,0))),2,'0')||LPAD(ABS(MOD(NVL(P1_3_20,0) *10000,10000)),4,'0')||';'||   -- P1 3.20      EMENDA
       RPAD(NVL(P1_4_8,' '),1,' ')||';'||   -- P1 4.8       EXATO
       RPAD(' ', 3)||';'||   -- P1 12.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.75      BRANCO
       RPAD(NVL(P1_4_42,' '),6,' ')||';'||   -- P1 4.42      EXATO
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8)||';'||   -- P1 3.3       EXATO
       RPAD(' ', 2)||';'||   -- P1 4.43      BRANCO
       RPAD(' ', 5)||';'||   -- P1 4.44      BRANCO
       RPAD(NVL(TO_CHAR(P1_4_47,'YYYYMMDD'), ' '),8,' ')||';'||   -- P1 4.47      EXATO
       RPAD(' ', 1)||';'||   -- P1 5.99      BRANCO
       RPAD(' ', 20)||';'||   -- P1 3.62      BRANCO
       RPAD(' ', 10)||';'||   -- P1 3.63      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.64      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.65      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.66      BRANCO
       RPAD(' ', 7)||';'||   -- P1 6.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.26      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.27      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.28      BRANCO
       pack_utilitaire.f_format_taux(P1_4_30)||';'||   -- P1 4.30      EXATO
       RPAD(' ', 20)||';'||   -- P1 7.99      BRANCO
       RPAD(NVL(P1_4_29,' '),1,' ')||';'||   -- P1 4.29      EXATO
       RPAD(' ', 3)||';'||   -- P1 4.40      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.41      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.48      BRANCO
       RPAD(' ', 45)||';'||   -- P1 4.98      BRANCO
       RPAD(' ', 10)||';'||   -- P1 8.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.38      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.39      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.37      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.35      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.36      BRANCO
       RPAD(' ', 30)||';'||   -- P1 9.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 12.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 12.19     BRANCO
       RPAD(' ', 8)||';'||   -- P1 12.6      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.1      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.2      BRANCO
       RPAD(' ', 20)||';'||   -- P1 12.17     BRANCO
       RPAD(' ', 10)||';'||   -- P1 12.18     BRANCO
       RPAD(' ', 24)||';'||   -- P1 10.99     BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.89      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.90      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.86      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.87      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.88      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.15     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 11.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.76      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.77      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.4      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.10      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.11      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.12      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.13      BRANCO
       RPAD(' ', 2)||';'||   -- P1 10.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.1       BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.2       BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.11      BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.12      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.22     BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.21     BRANCO
       RPAD(' ', 10)||';'||   -- P1 10.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 9.5       BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.24     BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.5      BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.98     BRANCO
       RPAD(nvl(P1_21_3, ' '), 1)||';'||   -- P1 21.3      EXATO
       RPAD(nvl(P1_21_4, ' '), 1)||';'||   -- P1 21.4      EXATO
       RPAD(nvl(P1_21_5, ' '), 1)||';'||   -- P1 21.5      EXATO
       RPAD(NVL(P1_21_6,' '),2)||';'||   -- P1 21.6      EXATO
       RPAD (NVL(TO_CHAR(P1_21_7, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.7      EXATO
       RPAD(NVL(TO_CHAR(P1_21_8, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.8      EXATO
       RPAD(NVL(TO_CHAR(P1_21_9, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 21.9      EXATO
       NVL(TO_CHAR(P1_21_10, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.10     EXATO
       NVL(TO_CHAR(P1_21_11, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.11     EXATO
       NVL(TO_CHAR(P1_21_12, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.12     EXATO
       NVL(TO_CHAR(P1_21_13, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.13     EXATO
       NVL(TO_CHAR(P1_21_14, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.14     EXATO
       NVL(TO_CHAR(P1_21_15, 'YYYYMMDD'), RPAD(' ', 8))||';'||   -- P1 21.15     EXATO
       RPAD(NVL(TO_CHAR(P1_21_16,'YYYYMMDD'), ' '),8,' ')||';'||   -- P1 21.16     EXATO
       RPAD(NVL(P1_21_17, ' '), 2, ' ')||';'||   -- P1 21.17     EXATO
       RPAD(' ', 2)||';'||   -- P1 21.18     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.99     BRANCO
       RPAD(NVL(P1_22_56,' '),3)||';'||   -- P1 22.56     EXATO
       RPAD(NVL(P1_22_57,' '),1)||';'||   -- P1 22.57     EXATO
       RPAD(NVL(P1_22_1, ' '),40,' ')||';'||   -- P1 22.1      EXATO
       RPAD(NVL(P1_22_51,' '),40)||';'||   -- P1 22.51     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.2      BRANCO
       RPAD(' ', 4)||';'||   -- P1 22.3      BRANCO
       RPAD(' ', 40)||';'||   -- P1 22.4      BRANCO
       RPAD('ND',2)||';'||   -- P1 22.5      EXATO
       RPAD(NVL(P1_22_52,' '),10)||';'||   -- P1 22.52     EXATO
       RPAD(nvl(P1_22_6,' '),2,' ')||';'||   -- P1 22.6      EXATO
       RPAD(NVL(P1_22_53,' '),2)||';'||   -- P1 22.53     EXATO
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||';'||   -- P1 22.54     EXATO
       RPAD(upper(NVL(P1_22_55,' ')),3)||';'||   -- P1 22.55     EXATO
       RPAD('97',2)||';'||   -- P1 22.7      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||';'||   -- P1 22.8      EXATO
       RPAD(nvl(P1_22_9, 'EUR'), 3)||';'||   -- P1 22.9      EXATO
       RPAD(NVL(P1_22_12,' '),1)||';'||   -- P1 22.12     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_13)||';'||   -- P1 22.13     EXATO
       RPAD(NVL(P1_22_14,' '),1)||';'||   -- P1 22.14     EXATO
       RPAD(NVL(P1_22_15,' '),12)||';'||   -- P1 22.15     EXATO
       RPAD(NVL(P1_22_16,' '),1)||';'||   -- P1 22.16     EXATO
       RPAD(NVL(P1_22_17,' '),1)||';'||   -- P1 22.17     EXATO
       RPAD(NVL(P1_22_18,' '),1)||';'||   -- P1 22.18     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_19)||';'||   -- P1 22.19     EXATO
       RPAD(NVL(P1_22_20,' '),1)||';'||   -- P1 22.20     EXATO
       RPAD(NVL(TO_CHAR(P1_22_21, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.21     EXATO
       RPAD(NVL(TO_CHAR(P1_22_22, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.22     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_23)||';'||   -- P1 22.23     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_24)||';'||   -- P1 22.24     EXATO
       RPAD(NVL(P1_22_25,' '),1)||';'||   -- P1 22.25     EXATO
       LPAD(nvl((P1_22_26),0),3,0)||';'||   -- P1 22.26     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_27)||';'||   -- P1 22.27     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_28)||';'||   -- P1 22.28     EXATO
       pack_utilitaire.F_FORMAT_TAUX(P1_22_29)||';'||   -- P1 22.29     EXATO
       RPAD(NVL(P1_22_30,' '),7)||';'||   -- P1 22.30     EXATO
       RPAD(NVL(TO_CHAR(P1_22_31, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.31     EXATO
       case when P1_22_32 is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(P1_22_32) end||';'||   -- P1 22.32     EXATO
       RPAD(nvl(P1_22_33,'EUR'),3)||';'||   -- P1 22.33     EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2( P1_22_34)||';'||   -- P1 22.34     EXATO
       RPAD(NVL(P1_22_35,' '),3)||';'||   -- P1 22.35     EXATO
       RPAD('3',1)||';'||   -- P1 22.36     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.37     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.40     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.41     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.42     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.43     BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_22_44),0))||';'||   -- P1 22.44     EXATO
       RPAD('EUR', 3)||';'||   -- P1 22.45     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.46     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.47     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.48     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.49     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.50     BRANCO
       RPAD(NVL(TO_CHAR(P1_22_58, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.58     EXATO
       RPAD(NVL(TO_CHAR(P1_22_59, 'YYYYMMDD'), ' '), 8)||';'||   -- P1 22.59     EXATO
       pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(P1_22_60)||';'||   -- P1 22.60     EXATO
       RPAD(NVL(P1_22_61,' '),3)||';'||   -- P1 22.61     EXATO
       RPAD(NVL(P1_22_62,' '),1)||';'||   -- P1 22.62     EXATO
       RPAD(NVL(TO_CHAR(P1_22_63,'YYYYMMDD'),' '), 8)||';'||   -- P1 22.63     EXATO
       RPAD(' ', 2)||';'||   -- P1 22.64     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.65     BRANCO
       RPAD(NVL(P1_22_66, ' '), 2, ' ')||';'||   -- P1 22.66     EXATO
       RPAD(NVL(TO_CHAR(P1_22_67,'YYYYMMDD'), ' '),8,' ')||';'||   -- P1 22.67     EXATO
       RPAD(' ', 2)||';'||   -- P1 22.68     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.69     BRANCO
       LPAD(NVL(to_char(P1_22_70), ' '),5,'0')||';'||   -- P1 22.70     EXATO
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||';'||   -- P1 22.71     EXATO
       RPAD(NVL(P1_22_72, ' '), 2, ' ')||';'||   -- P1 22.72     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.73     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.74     BRANCO
       RPAD(NVL(P1_23_1,' '),1)||';'||   -- P1 23.1      EXATO
       RPAD(NVL(P1_23_2,' '),7)||';'||   -- P1 23.2      EXATO
       RPAD(NVL(P1_23_3,' '),20)||';'||   -- P1 23.3      EXATO
       RPAD(NVL(P1_23_4,' '),3)||';'||   -- P1 23.4      EXATO
       RPAD(NVL(P1_23_5,' '),3)||';'||   -- P1 23.5      EXATO
       RPAD(NVL(P1_23_6,' '),1)||';'||   -- P1 23.6      EXATO
       RPAD(NVL(P1_23_7,' '),40)||';'||   -- P1 23.7      EXATO
       RPAD(' ', 5)||';'||   -- P1 23.12     BRANCO
       RPAD(' ', 5)||';'||   -- P1 23.13     BRANCO
       RPAD (nvl(P1_23_8,' '), 12)||';'||   -- P1 23.8      EXATO
       RPAD (nvl(P1_23_9,' '), 12)||';'||   -- P1 23.9      EXATO
       RPAD (nvl(P1_23_10,' '), 12)||';'||   -- P1 23.10     EXATO
       RPAD (nvl(P1_23_11,' '), 12)||';'||   -- P1 23.11     EXATO
       RPAD(' ', 2)||';'||   -- P1 23.99     BRANCO
       RPAD(NVL(P1_24_1,' '),1,' ')||';'||   -- P1 24.1      EXATO
       RPAD(' ', 2)||';'||   -- P1 24.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.5      BRANCO
       RPAD(' ', 13)||';'||   -- P1 24.6      BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.8      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.11     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.12     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.15     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.17     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.18     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.20     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.21     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.22     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.23     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.25     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.26     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.27     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.28     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.29     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.30     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.97     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.31     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.32     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.36     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.98     BRANCO
       RPAD(' ', 12)||';'||   -- P1 24.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.6      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.7      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.8      BRANCO
       RPAD(' ', 39)     -- P1 25.99     CORTE-A
     AS VARCHAR2(4000)) as lignedetail1,
     CAST(
       RPAD(' ', 60)||';'||   -- P1 25.99     CORTE-B
       RPAD(NVL(P1_26_1,' '),1,' ')||';'||   -- P1 26.1      EXATO
       RPAD(NVL(P1_22_11, ' '), 1)||';'||   -- P1 22.11     EXATO
       RPAD(NVL(P1_26_3, ' '), 3)||';'||   -- P1 26.3      EXATO
       RPAD(NVL(P1_26_4, ' '), 3)||';'||   -- P1 26.4      EXATO
       RPAD(' ', 44)||';'||   -- P1 26.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 27.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 27.2      BRANCO
       RPAD(P1_27_3, 1)||';'||   -- P1 27.3      EXATO
       RPAD(NVL(P1_27_4, ' '), 2)||';'||   -- P1 27.4      EXATO
       RPAD(' ', 23)||';'||   -- P1 27.99     BRANCO
       RPAD (nvl(P1_28_1, ' '), 1, ' ')||';'||   -- P1 28.1      EXATO
       RPAD (nvl(P1_28_2, ' '), 1, ' ')||';'||   -- P1 28.2      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.2      BRANCO
       RPAD(' ', 2)||';'||   -- P1 30.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.3      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.5      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.6      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.7      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.8      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.11     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.12     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.16     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.17     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.18     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.19     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.20     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.21     BRANCO
       RPAD(' ', 25)||';'||   -- P1 30.22     REGRA
       'N'||';'||   -- P1 30.23     REGRA
       RPAD(' ', 25)||';'||   -- P1 30.24     REGRA
       'N'||';'||   -- P1 30.25     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.27     BRANCO
       RPAD(' ', 5)||';'||   -- P1 31.1      BRANCO
       RPAD(NVL(P1_31_2, ' '),40,' ')||';'||   -- P1 31.2      EXATO
       RPAD(NVL(P1_31_3,' '),40)||';'||   -- P1 31.3      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||';'||   -- P1 31.4      EXATO
       RPAD(NVL(P1_31_5, ' '),1,' ')||';'||   -- P1 31.5      EXATO
       RPAD (NVL(P1_31_6,'2'), 1)||';'||   -- P1 31.6      EXATO
       RPAD(' ', 6)||';'||   -- P1 31.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.8      BRANCO
       RPAD(NVL(P1_31_9, ' '),15,' ')||';'||   -- P1 31.9      EXATO
       RPAD(NVL(P1_31_10, ' '),2,' ')||';'||   -- P1 31.10     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.11     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.13     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.15     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.16     BRANCO
       RPAD ('+', 1)||LPAD(P1_31_17, 5, '0')||';'||   -- P1 31.17     EMENDA
       RPAD ('+', 1)||LPAD(P1_31_18, 5, '0')||';'||   -- P1 31.18     EMENDA
       RPAD(' ', 6)||';'||   -- P1 31.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.20     BRANCO
       RPAD(NVL(P1_31_21,' '), 2)||';'||   -- P1 31.21     EXATO
       P1_31_22||';'||   -- P1 31.22     EXATO
       RPAD(' ', 19)||';'||   -- P1 31.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.24     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.25     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.26     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.27     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.28     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.29     BRANCO
       RPAD(NVL(P1_31_37,' '),1)||';'||   -- P1 31.37     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.38     BRANCO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||';'||   -- P1 29.3      EXATO
       RPAD ('EUR', 3)||';'||   -- P1 29.4      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.6      BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.30     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.31     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.32     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.34     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.36     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.24     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.25     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.26     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.29     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.30     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.31     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.32     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.33     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.34     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.35     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.36     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.37     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.40     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.41     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.42     BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.3      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.4      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.5      BRANCO
       RPAD(' ', 20)||';'||   -- P1 28.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 28.7      BRANCO
       RPAD(' ', 15)||';'||   -- P1 28.8      BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.9      BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.11     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.12     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.13     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.14     BRANCO
       'EUR'||';'||   -- P1 50.1      EXATO
       RPAD(NVL(P1_50_2, ' '), 12)||';'||   -- P1 50.2      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||';'||   -- P1 50.3      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.5      BRANCO
       RPAD(NVL(P1_50_8, ' '), 12)||';'||   -- P1 50.8      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||';'||   -- P1 50.9      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.15     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.16     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.17     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.18     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.19     BRANCO
       RPAD(NVL(P1_21_22,' '),2)||';'||   -- P1 21.22     EXATO
       RPAD(NVL(TO_CHAR(P1_21_23, 'YYYYMMDD'), ' '),8)||';'||   -- P1 21.23     EXATO
       case when P1_21_29 is not null then '+'||LPAD(P1_21_29,5,'0') else RPAD(' ',6) end||';'||   -- P1 21.29     EXATO
       RPAD(NVL(P1_21_25,' '),2)||';'||   -- P1 21.25     EXATO
       RPAD(NVL(P1_21_26,' '),1)||';'||   -- P1 21.26     EXATO
       RPAD(NVL(P1_21_27,' '),1)||';'||   -- P1 21.27     EXATO
       RPAD(NVL(P1_21_28,' '),2)||';'||   -- P1 21.28     EXATO
       case when P1_21_30 is not null then RPAD(pack_utilitaire.f_format_montant_bis2(P1_21_30),19) else RPAD(' ',19) end||';'||   -- P1 21.30     EXATO
       RPAD(NVL(P1_21_31, ' '), 3)||';'||   -- P1 21.31     EXATO
       RPAD(' ', 15)||';'||   -- P1 21.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.33     BRANCO
       RPAD(' ', 12)||';'||   -- P1 15        BRANCO
       RPAD(' ', 12)||';'||   -- P1 16        BRANCO
       RPAD(' ', 12)||';'||   -- P1 14        BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.20     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.35     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.36     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.47     BRANCO
       RPAD(' ', 7)||';'||   -- P1 21.48     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.49     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.50     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.51     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.52     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.53     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.54     BRANCO
       RPAD(NVL(P1_21_44,' '),1)||';'||   -- P1 21.44     EXATO
       RPAD(NVL(P1_21_45,' '),1)||';'||   -- P1 21.45     EXATO
       RPAD(NVL(P1_21_46,' '),1)||';'||   -- P1 21.46     EXATO
       RPAD(NVL(P1_21_38,' '),1)||';'||   -- P1 21.38     EXATO
       RPAD(NVL(P1_21_39,' '),1)||';'||   -- P1 21.39     EXATO
       RPAD(NVL(P1_21_40,' '),1)||';'||   -- P1 21.40     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.41     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.42     BRANCO
       RPAD(pack_utilitaire.F_FORMAT_TAUX_15(P1_21_43),15)||';'||   -- P1 21.43     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.56     BRANCO
       RPAD(NVL(P1_21_57,' '),1)||';'||   -- P1 21.57     EXATO
       RPAD(NVL(P1_21_58,' '),1)||';'||   -- P1 21.58     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.59     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.60     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.61     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.62     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.63     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.64     BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.65     REGRA
       RPAD(NVL(P1_21_66,' '),1)||';'||   -- P1 21.66     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.67     BRANCO
       RPAD(NVL(P1_21_68,' '),1)||';'||   -- P1 21.68     EXATO
       RPAD(NVL(P1_21_55,' '),12)||';'||   -- P1 21.55     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.69     BRANCO
       RPAD(' ', 20)||';'||   -- P1 21.89     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.90     BRANCO
       RPAD(NVL(P1_8_13,' '),1)||';'||   -- P1 8.13      EXATO
       RPAD(NVL(P1_21_71,' '),40)||';'||   -- P1 21.71     EXATO
       RPAD(NVL(P1_21_72,' '),40)||';'||   -- P1 21.72     EXATO
       RPAD(NVL(P1_21_73,' '),40)||';'||   -- P1 21.73     EXATO
       RPAD(NVL(P1_21_74,' '),40)||';'||   -- P1 21.74     EXATO
       RPAD(NVL(P1_21_75,' '),40)||';'||   -- P1 21.75     EXATO
       RPAD(NVL(P1_21_76,' '),40)||';'||   -- P1 21.76     EXATO
       RPAD(NVL(P1_21_77,' '),11)||';'||   -- P1 21.77     EXATO
       RPAD(NVL(P1_21_78,' '),12)||';'||   -- P1 21.78     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.94     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.95     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.79     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.80     BRANCO
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_81),10)||';'||   -- P1 21.81     EXATO
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_82),10)||';'||   -- P1 21.82     EXATO
       RPAD(' ', 15)||';'||   -- P1 21.83     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.84     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.85     BRANCO
       RPAD(NVL(P1_21_86,' '),1)||';'||   -- P1 21.86     EXATO
       RPAD(NVL(P1_21_87,' '),1)||';'||   -- P1 21.87     EXATO
       RPAD(NVL(P1_21_88,' '),1)||';'||   -- P1 21.88     EXATO
       RPAD(' ', 19)||';'||   -- P1 21.91     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.92     BRANCO
       RPAD(' ', 5)||';'||   -- P1 21.93     BRANCO
       RPAD(' ', 20)||';'||   -- P1 31.51     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.52     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.53     BRANCO
       RPAD(NVL(TO_CHAR(P1_1001,'YYYYMMDD'),' '), 8)||';'||   -- P1 1001      NOVO
       RPAD(NVL(TO_CHAR(P1_1002,'YYYYMMDD'),' '), 8)||';'||   -- P1 1002      NOVO
       RPAD(NVL(P1_22_222,' '), 1)||';'||   -- P1 22.222    NOVO
       RPAD(NVL(P1_24_22_1,' '), 1)||';'||   -- P1 24.22.1   NOVO
       RPAD(NVL(P1_600,' '), 1)||';'||   -- P1 600       NOVO
       RPAD(NVL(P1_601,' '), 1)||';'||   -- P1 601       NOVO
       RPAD(NVL(P1_602,' '), 1)||';'||   -- P1 602       NOVO
       CASE WHEN P1_603 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_603) END||';'||   -- P1 603       NOVO
       RPAD(NVL(P1_603_1,' '), 3)||';'||   -- P1 603.1     NOVO
       CASE WHEN P1_604 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_604) END||';'||   -- P1 604       NOVO
       RPAD(NVL(P1_604_1,' '), 3)||';'||   -- P1 604.1     NOVO
       CASE WHEN P1_605 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_605) END||';'||   -- P1 605       NOVO
       RPAD(NVL(P1_605_1,' '), 3)||';'||   -- P1 605.1     NOVO
       RPAD(NVL(P1_606,' '), 40)||';'||   -- P1 606       NOVO
       RPAD(NVL(P1_607,' '), 1)||';'||   -- P1 607       NOVO
       CASE WHEN P1_608 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_608) END||';'||   -- P1 608       NOVO
       RPAD(NVL(P1_608_1,' '), 3)||';'||   -- P1 608.1     NOVO
       RPAD(NVL(TO_CHAR(P1_609,'YYYYMMDD'),' '), 8)||';'||   -- P1 609       NOVO
       CASE WHEN P1_610 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_610) END||';'||   -- P1 610       NOVO
       RPAD(NVL(P1_610_1,' '), 3)||';'||   -- P1 610.1     NOVO
       RPAD(NVL(TO_CHAR(P1_611,'YYYYMMDD'),' '), 8)||';'||   -- P1 611       NOVO
       CASE WHEN P1_612 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_612) END||';'||   -- P1 612       NOVO
       RPAD(NVL(P1_612_1,' '), 3)||';'||   -- P1 612.1     NOVO
       RPAD(NVL(P1_613,' '), 1)||';'||   -- P1 613       NOVO
       CASE WHEN P1_614 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_614) END||';'||   -- P1 614       NOVO
       RPAD(NVL(P1_614_1,' '), 3)||';'||   -- P1 614.1     NOVO
       LPAD(NVL(TO_CHAR(P1_615),' '), 6)||';'||   -- P1 615       NOVO
       RPAD(NVL(P1_616,' '), 1)||';'||   -- P1 616       NOVO
       RPAD(NVL(P1_617,' '), 1)||';'||   -- P1 617       NOVO
       RPAD(NVL(P1_618,' '), 1)||';'||   -- P1 618       NOVO
       CASE WHEN P1_619 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_619) END||';'||   -- P1 619       NOVO
       RPAD(NVL(P1_620,' '), 1)||';'||   -- P1 620       NOVO
       RPAD(NVL(P1_635,' '), 1)||';'||   -- P1 635       NOVO
       RPAD(NVL(P1_622,' '), 1)||';'||   -- P1 622       NOVO
       RPAD(NVL(P1_623,' '), 40)||';'||   -- P1 623       NOVO
       CASE WHEN P1_624 IS NULL THEN RPAD(' ', 15) ELSE pack_utilitaire.f_format_taux_15(P1_624) END||';'||   -- P1 624       NOVO
       RPAD(NVL(P1_625,' '), 2)||';'||   -- P1 625       NOVO
       RPAD(NVL(P1_626,' '), 1)||';'||   -- P1 626       NOVO
       RPAD(NVL(P1_627,' '), 1)||';'||   -- P1 627       NOVO
       CASE WHEN P1_628 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_628) END||';'||   -- P1 628       NOVO
       RPAD(NVL(P1_628_1,' '), 3)||';'||   -- P1 628.1     NOVO
       RPAD(NVL(P1_629,' '), 1)||';'||   -- P1 629       NOVO
       CASE WHEN P1_630 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_630) END||';'||   -- P1 630       NOVO
       RPAD(NVL(P1_630_1,' '), 3)||';'||   -- P1 630.1     NOVO
       CASE WHEN P1_631 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_631) END||';'||   -- P1 631       NOVO
       RPAD(NVL(P1_631_1,' '), 3)||';'||   -- P1 631.1     NOVO
       CASE WHEN P1_632 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_632) END||';'||   -- P1 632       NOVO
       RPAD(NVL(P1_632_1,' '), 3)||';'||   -- P1 632.1     NOVO
       CASE WHEN P1_633 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_633) END||';'||   -- P1 633       NOVO
       RPAD(NVL(P1_633_1,' '), 3)||';'||   -- P1 633.1     NOVO
       RPAD(NVL(P1_621,' '), 8)||';'||   -- P1 621       NOVO
       RPAD(' ', 1176)     -- P1 99.99     FILLER
     AS VARCHAR2(3999)) as lignedetail2
  from ENG_CORP_P1_BIS
 where NO_VARIANTE = 5
   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
 order by NO_VARIANTE;

------------------------------------------------------------------------------------------------------------------------
-- PAVE P1 - Hors NAT02, variante 6 - com separador ;
------------------------------------------------------------------------------------------------------------------------
select
     CAST(
       RPAD(TO_CHAR(P1_H_0_1,'YYYYMMDD'),8,' ')||';'||   -- 0.1 (P1)     EXATO
       RPAD(P1_H_0_2,5,' ')||';'||   -- 0.2 (P1)     EXATO
       RPAD('C_DDR',12,' ')||';'||   -- 0.3 (P1)     EXATO
       'M'||';'||   -- 0.4 (P1)     EXATO
       :MASYSDATE||';'||   -- 0.5 (P1)     EXATO
       'P1'||';'||   -- 0.6 (P1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (P1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (P1)     BRANCO
       RPAD(' ', 4)||';'||   -- 0.9 (P1)     BRANCO
       RPAD(' ', 3)||';'||   -- 0.99 (P1)    BRANCO
       RPAD(NVL(P1_H_1_1,' '),20,' ')||';'||   -- 1.1 (P1)     EXATO
       RPAD(' ', 10)||';'||   -- 1.2 (P1)     BRANCO
       RPAD(NVL(P1_H_1_4,' '),30,' ')||';'||   -- 1.4 (P1)     EXATO
       RPAD(NVL(P1_H_1_6,' '),30,' ')||';'||   -- 1.6 (P1)     EXATO
       RPAD(' ', 40)||';'||   -- 1.8 (P1)     BRANCO
       RPAD(NVL(P1_H_1_11,' '),40,' ')||';'||   -- 1.11 (P1)    EXATO
       RPAD(' ', 40)||';'||   -- 1.16 (P1)    BRANCO
       RPAD(' ', 11)||';'||   -- 1.99 (P1)    BRANCO
       RPAD(' ', 7)||';'||   -- 1.98 (P1)    BRANCO
       RPAD(' ', 2)||';'||   -- 1.97 (P1)    BRANCO
       RPAD(NVL(P1_1_1,' '),7,' ')||';'||   -- P1 1.1       EXATO
       RPAD(NVL(P1_1_2,' '),2,' ')||';'||   -- P1 1.2       EXATO
       RPAD(NVL(P1_4_34,' '),1,' ')||';'||   -- P1 4.34      EXATO
       RPAD(NVL(P1_2_0,' '),6,' ')||';'||   -- P1 2.0       EXATO
       RPAD(NVL(P1_2_4,' '),1,' ')||';'||   -- P1 2.4       EXATO
       RPAD(NVL(P1_2_6,' '),5,' ')||';'||   -- P1 2.6       EXATO
       RPAD(NVL(P1_2_18,' '),3,' ')||';'||   -- P1 2.18      EXATO
       RPAD(NVL(P1_2_29,' '),12,' ')||';'||   -- P1 2.29      EXATO
       RPAD(TO_CHAR(P1_3_2,'YYYYMMDD'),8,' ')||';'||   -- P1 3.2       EXATO
       RPAD(TO_CHAR(P1_3_4,'YYYYMMDD'),8,' ')||';'||   -- P1 3.4       EXATO
       RPAD(' ', 10)||';'||   -- P1 16.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.1      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 18.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 18.17     BRANCO
       RPAD(NVL(P1_18_18,' '),3,' ')||';'||   -- P1 18.18     EXATO
       RPAD(' ', 50)||';'||   -- P1 3.98      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.1      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.2      BRANCO
       NVL(P1_5_5,'N')||';'||   -- P1 5.5       EXATO
       RPAD(' ', 1)||';'||   -- P1 4.1       BRANCO
       RPAD(NVL(P1_5_2,' '),1, ' ')||';'||   -- P1 5.2       EXATO
       RPAD(' ', 8)||';'||   -- P1 5.3       BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.2       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.3       BRANCO
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END||';'||   -- P1 4.4       REGRA
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END||';'||   -- P1 4.5       REGRA
       RPAD(' ', 19)||';'||   -- P1 4.9       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.13      BRANCO
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END||';'||   -- P1 4.14      REGRA
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END||';'||   -- P1 4.15      REGRA
       RPAD(' ', 19)||';'||   -- P1 4.16      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.17      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.18      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.6       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.7       BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.19      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.20      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.21      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.22      BRANCO
       RPAD(' ', 2)||';'||   -- P1 4.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.6       BRANCO
       RPAD(' ', 20)||';'||   -- P1 5.7       BRANCO
       RPAD(' ', 10)||';'||   -- P1 5.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.33      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.10      BRANCO
       RPAD(' ', 25)||';'||   -- P1 5.11      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.32      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.46      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.47      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.40      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.41      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.42      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.43      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.44      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.45      BRANCO
       RPAD(' ', 19)||';'||   -- P1 5.19      BRANCO
       RPAD(' ', 3)||';'||   -- P1 5.20      BRANCO
       RPAD(NVL(P1_19_5,' '),3,' ')||';'||   -- P1 19.5      EXATO
       RPAD(NVL(P1_3_56,' '),12,' ')||';'||   -- P1 3.56      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_50),0))||';'||   -- P1 3.50      EXATO
       RPAD(NVL(P1_3_51,'EUR'),3)||';'||   -- P1 3.51      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl(P1_3_52,0))||';'||   -- P1 3.52      EXATO
       RPAD(NVL(P1_3_53,' '),3,' ')||';'||   -- P1 3.53      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl(P1_3_54,0))||';'||   -- P1 3.54      EXATO
       RPAD(NVL(P1_3_55,'EUR'),3,' ')||';'||   -- P1 3.55      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.57      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.58      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.59      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.60      BRANCO
       RPAD(P1_3_61, 1,' ')||';'||   -- P1 3.61      EXATO
       RPAD(' ', 2)||';'||   -- P1 3.99      BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_8),0))||';'||   -- P1 3.8       EXATO
       RPAD(NVL(P1_3_9,' '),3,' ')||';'||   -- P1 3.9       EXATO
       RPAD(NVL(P1_3_31,' '),12,' ')||';'||   -- P1 3.31      EXATO
       RPAD(P1_12_1, 2,' ')||';'||   -- P1 12.1      EXATO
       RPAD(' ', 1)||';'||   -- P1 3.7       BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.70      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.71      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.74      BRANCO
       RPAD(NVL(P1_2_99,' '), 20)||';'||   -- P1 2.99      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.80      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.81      BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.82      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.83      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.15      BRANCO
       RPAD(' ', 25)||';'||   -- P1 13.10     BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.16      BRANCO
       RPAD(' ', 25)||';'||   -- P1 3.17      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.19      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.84      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.85      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.72      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.73      BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.0       BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.1       BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.2       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.6       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.7       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.10      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.11      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.12      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.13      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.14      BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.3       BRANCO
       RPAD(' ', 3)||';'||   -- P1 12.5      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.15      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.16      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.17      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.18      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.19      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.20      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.21      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.22      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.3      BRANCO
       RPAD(' ', 5)||';'||   -- P1 11.33     BRANCO
       RPAD(' ', 2)||';'||   -- P1 11.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.9      BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.13     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 16.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.20     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.22     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.99     BRANCO
       RPAD(P1_4_31, 1,' ')||';'||   -- P1 4.31      EXATO
       RPAD(' ', 1)||';'||   -- P1 4.32      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.33      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.13     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.36      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.49      BRANCO
       RPAD(' ', 4)||';'||   -- P1 4.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.45      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.46      BRANCO
       LPAD(ABS(TRUNC(P1_3_20)),2,'0')||LPAD(ABS(MOD(P1_3_20 *10000,10000)),4,'0')||';'||   -- P1 3.20      EMENDA
       RPAD(NVL(P1_4_8,' '),1,' ')||';'||   -- P1 4.8       EXATO
       RPAD(' ', 3)||';'||   -- P1 12.16     BRANCO
       RPAD(NVL(P1_3_75, ' '),2,' ')||';'||   -- P1 3.75      EXATO
       RPAD(NVL(P1_4_42,' '),6,' ')||';'||   -- P1 4.42      EXATO
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8,' ')||';'||   -- P1 3.3       EXATO
       RPAD(' ', 2)||';'||   -- P1 4.43      BRANCO
       RPAD(' ', 5)||';'||   -- P1 4.44      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.47      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.99      BRANCO
       RPAD(' ', 20)||';'||   -- P1 3.62      BRANCO
       RPAD(' ', 10)||';'||   -- P1 3.63      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.64      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.65      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.66      BRANCO
       RPAD(' ', 7)||';'||   -- P1 6.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.26      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.27      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.28      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.30      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.29      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.40      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.41      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.48      BRANCO
       RPAD(' ', 45)||';'||   -- P1 4.98      BRANCO
       RPAD(' ', 10)||';'||   -- P1 8.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.38      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.39      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.37      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.35      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.36      BRANCO
       RPAD(' ', 30)||';'||   -- P1 9.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 12.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 12.19     BRANCO
       RPAD(' ', 8)||';'||   -- P1 12.6      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.1      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.2      BRANCO
       RPAD(' ', 20)||';'||   -- P1 12.17     BRANCO
       RPAD(' ', 10)||';'||   -- P1 12.18     BRANCO
       RPAD(' ', 24)||';'||   -- P1 10.99     BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.89      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.90      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.86      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.87      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.88      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.15     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 11.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.76      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.77      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.4      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.10      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.11      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.12      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.13      BRANCO
       RPAD(' ', 2)||';'||   -- P1 10.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.1       BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.2       BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.11      BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.12      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.22     BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.21     BRANCO
       RPAD(' ', 10)||';'||   -- P1 10.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 9.5       BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.24     BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.5      BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.98     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.5      BRANCO
       RPAD(NVL(P1_21_6,'PE'),2,' ')||';'||   -- P1 21.6      EXATO
       RPAD(' ', 8)||';'||   -- P1 21.7      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.8      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.9      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.10     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.11     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.12     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.13     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.15     BRANCO
       RPAD(NVL(TO_CHAR(P1_21_16,'YYYYMMDD'), ' '),8,' ')||';'||   -- P1 21.16     EXATO
       RPAD(NVL(P1_21_17,' '),2,' ')||';'||   -- P1 21.17     EXATO
       RPAD(' ', 2)||';'||   -- P1 21.18     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.99     BRANCO
       RPAD(NVL(P1_22_56,' '),3,' ')||';'||   -- P1 22.56     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.57     BRANCO
       RPAD(NVL(P1_22_1,' '),40,' ')||';'||   -- P1 22.1      EXATO
       RPAD(NVL(P1_22_51,' '),40,' ')||';'||   -- P1 22.51     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.2      BRANCO
       RPAD(' ', 4)||';'||   -- P1 22.3      BRANCO
       RPAD(' ', 40)||';'||   -- P1 22.4      BRANCO
       RPAD('ND',2)||';'||   -- P1 22.5      EXATO
       RPAD(' ', 10)||';'||   -- P1 22.52     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.6      BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.53     BRANCO
       RPAD(' ', 46)||';'||   -- P1 22.54     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.55     BRANCO
       RPAD('97',2)||';'||   -- P1 22.7      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||';'||   -- P1 22.8      EXATO
       RPAD(nvl(P1_22_9, 'EUR'), 3)||';'||   -- P1 22.9      EXATO
       RPAD(NVL(P1_22_12,' '),1,' ')||';'||   -- P1 22.12     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.13     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.14     BRANCO
       RPAD(' ', 12)||';'||   -- P1 22.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.20     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.21     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.22     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.23     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.25     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.26     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.27     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.28     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.29     BRANCO
       RPAD(' ', 7)||';'||   -- P1 22.30     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.31     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.33     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.34     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.35     BRANCO
       RPAD(NVL(P1_22_36,' '),1,' ')||';'||   -- P1 22.36     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.37     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.40     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.41     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.42     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.43     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.44     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.45     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.46     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.47     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.48     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.49     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.50     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.58     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.59     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.60     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.61     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.62     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.63     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.64     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.65     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.66     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.67     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.68     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.69     BRANCO
       RPAD(' ', 5)||';'||   -- P1 22.70     BRANCO
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||';'||   -- P1 22.71     EXATO
       RPAD(NVL(P1_22_72,' '),2,' ')||';'||   -- P1 22.72     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.73     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.74     BRANCO
       RPAD(NVL(P1_23_1,' '),1,' ')||';'||   -- P1 23.1      EXATO
       RPAD(NVL(P1_23_2,' '),7,' ')||';'||   -- P1 23.2      EXATO
       RPAD(NVL(P1_23_3,' '),20)||';'||   -- P1 23.3      EXATO
       RPAD(NVL(P1_23_4,' '),3,' ')||';'||   -- P1 23.4      EXATO
       RPAD(NVL(P1_23_5,' '),3,' ')||';'||   -- P1 23.5      EXATO
       RPAD(NVL(P1_23_6,' '),1,' ')||';'||   -- P1 23.6      EXATO
       RPAD(NVL(P1_23_7,' '),40,' ')||';'||   -- P1 23.7      EXATO
       RPAD(' ', 5)||';'||   -- P1 23.12     BRANCO
       RPAD(' ', 5)||';'||   -- P1 23.13     BRANCO
       RPAD (nvl(P1_23_8,' '), 12)||';'||   -- P1 23.8      EXATO
       RPAD (nvl(P1_23_9,' '), 12)||';'||   -- P1 23.9      EXATO
       RPAD (nvl(P1_23_10,' '), 12)||';'||   -- P1 23.10     EXATO
       RPAD (nvl(P1_23_11,' '), 12)||';'||   -- P1 23.11     EXATO
       RPAD(' ', 2)||';'||   -- P1 23.99     BRANCO
       RPAD(NVL(P1_24_1,' '),1,' ')||';'||   -- P1 24.1      EXATO
       RPAD(' ', 2)||';'||   -- P1 24.2      BRANCO
       RPAD(NVL(P1_24_3,' '),1)||';'||   -- P1 24.3      EXATO
       RPAD(NVL(P1_24_4,' '),1)||';'||   -- P1 24.4      EXATO
       RPAD(NVL(P1_24_5,' '),1)||';'||   -- P1 24.5      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_13_2(P1_24_6)||';'||   -- P1 24.6      EXATO
       RPAD(' ', 50)||';'||   -- P1 24.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.8      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.11     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.12     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.15     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.17     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.18     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.20     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.21     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.22     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.23     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.25     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.26     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.27     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.28     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.29     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.30     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.97     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.31     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.32     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.36     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.98     BRANCO
       RPAD(' ', 12)||';'||   -- P1 24.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.6      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.7      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.8      BRANCO
       RPAD(' ', 39)     -- P1 25.99     CORTE-A
     AS VARCHAR2(4000)) as lignedetail1,
     CAST(
       RPAD(' ', 60)||';'||   -- P1 25.99     CORTE-B
       RPAD(NVL(P1_26_1,' '),1,' ')||';'||   -- P1 26.1      EXATO
       RPAD(NVL(P1_22_11, ' '), 1)||';'||   -- P1 22.11     EXATO
       RPAD(NVL(P1_26_3, ' '), 3)||';'||   -- P1 26.3      EXATO
       RPAD(NVL(P1_26_4, ' '), 3)||';'||   -- P1 26.4      EXATO
       RPAD(' ', 44)||';'||   -- P1 26.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 27.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 27.2      BRANCO
       RPAD(P1_27_3, 1)||';'||   -- P1 27.3      EXATO
       RPAD(NVL(P1_27_4, ' '), 2)||';'||   -- P1 27.4      EXATO
       RPAD(' ', 23)||';'||   -- P1 27.99     BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 29.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.2      BRANCO
       RPAD(' ', 2)||';'||   -- P1 30.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.3      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.5      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.6      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.7      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.8      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.11     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.12     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.16     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.17     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.18     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.19     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.20     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.21     BRANCO
       RPAD(' ', 25)||';'||   -- P1 30.22     REGRA
       'N'||';'||   -- P1 30.23     REGRA
       RPAD(' ', 25)||';'||   -- P1 30.24     REGRA
       'N'||';'||   -- P1 30.25     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.27     BRANCO
       RPAD(' ', 5)||';'||   -- P1 31.1      BRANCO
       RPAD(NVL(P1_31_2, ' '), 40)||';'||   -- P1 31.2      EXATO
       RPAD(NVL(P1_31_3, ' '), 40)||';'||   -- P1 31.3      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||';'||   -- P1 31.4      EXATO
       RPAD(NVL(P1_31_5, ' '), 1)||';'||   -- P1 31.5      EXATO
       RPAD (NVL(P1_31_6,'2'), 1)||';'||   -- P1 31.6      EXATO
       RPAD(' ', 6)||';'||   -- P1 31.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.8      BRANCO
       RPAD(NVL(P1_31_9, ' '),15,' ')||';'||   -- P1 31.9      EXATO
       RPAD(NVL(P1_31_10, ' '),2,' ')||';'||   -- P1 31.10     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.11     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.13     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.15     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.16     BRANCO
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.17     EMENDA
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.18     EMENDA
       RPAD(' ', 6)||';'||   -- P1 31.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.20     BRANCO
       RPAD(' ', 2)||';'||   -- P1 31.21     BRANCO
       P1_31_22||';'||   -- P1 31.22     EXATO
       RPAD(' ', 19)||';'||   -- P1 31.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.24     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.25     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.26     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.27     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.28     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.29     BRANCO
       RPAD(NVL(P1_31_37,' '),1)||';'||   -- P1 31.37     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.38     BRANCO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||';'||   -- P1 29.3      EXATO
       RPAD ('EUR', 3)||';'||   -- P1 29.4      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.6      BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.30     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.31     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.32     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.34     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.36     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.24     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.25     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.26     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.29     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.30     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.31     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.32     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.33     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.34     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.35     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.36     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.37     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.40     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.41     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.42     BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.3      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.4      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.5      BRANCO
       RPAD(' ', 20)||';'||   -- P1 28.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 28.7      BRANCO
       RPAD(' ', 15)||';'||   -- P1 28.8      BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.9      BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.11     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.12     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.13     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.14     BRANCO
       'EUR'||';'||   -- P1 50.1      EXATO
       RPAD(NVL(P1_50_2, ' '), 12)||';'||   -- P1 50.2      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||';'||   -- P1 50.3      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.5      BRANCO
       RPAD(NVL(P1_50_8, ' '), 12)||';'||   -- P1 50.8      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||';'||   -- P1 50.9      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.15     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.16     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.17     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.18     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.22     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.23     BRANCO
       RPAD(' ', 6)||';'||   -- P1 21.29     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.25     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.30     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.31     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.33     BRANCO
       RPAD(' ', 12)||';'||   -- P1 15        BRANCO
       RPAD(' ', 12)||';'||   -- P1 16        BRANCO
       RPAD(' ', 12)||';'||   -- P1 14        BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.20     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.35     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.36     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.47     BRANCO
       RPAD(' ', 7)||';'||   -- P1 21.48     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.49     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.50     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.51     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.52     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.53     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.54     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.44     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.45     BRANCO
       RPAD(NVL(P1_21_46,' '),1)||';'||   -- P1 21.46     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.38     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.39     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.40     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.41     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.42     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.43     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.56     BRANCO
       RPAD(NVL(P1_21_57,' '),1)||';'||   -- P1 21.57     EXATO
       RPAD(NVL(P1_21_58,' '),1)||';'||   -- P1 21.58     EXATO
       RPAD(NVL(P1_21_59,' '),1)||';'||   -- P1 21.59     EXATO
       RPAD(pack_utilitaire.F_FORMAT_TAUX_15(P1_21_60),15)||';'||   -- P1 21.60     EXATO
       RPAD(' ', 10)||';'||   -- P1 21.61     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.62     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.63     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.64     BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.65     REGRA
       RPAD(' ', 1)||';'||   -- P1 21.66     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.67     BRANCO
       RPAD(NVL(P1_21_68,' '),1)||';'||   -- P1 21.68     EXATO
       RPAD(NVL(P1_21_55,' '),12)||';'||   -- P1 21.55     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.69     BRANCO
       RPAD(' ', 20)||';'||   -- P1 21.89     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.90     BRANCO
       RPAD(NVL(P1_8_13,' '),1)||';'||   -- P1 8.13      EXATO
       RPAD(' ', 40)||';'||   -- P1 21.71     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.72     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.73     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.74     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.75     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.76     BRANCO
       RPAD(' ', 11)||';'||   -- P1 21.77     BRANCO
       RPAD(' ', 12)||';'||   -- P1 21.78     BRANCO
       RPAD(NVL(P1_21_94,' '),1)||';'||   -- P1 21.94     EXATO
       RPAD(' ', 2)||';'||   -- P1 21.95     BRANCO
       RPAD(NVL(P1_21_79,' '),1)||';'||   -- P1 21.79     EXATO
       RPAD(' ', 3)||';'||   -- P1 21.80     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.81     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.82     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.83     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.84     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.85     BRANCO
       RPAD(NVL(P1_21_86,' '),1)||';'||   -- P1 21.86     EXATO
       RPAD(NVL(P1_21_87,' '),1)||';'||   -- P1 21.87     EXATO
       RPAD(NVL(P1_21_88,' '),1)||';'||   -- P1 21.88     EXATO
       RPAD(' ', 19)||';'||   -- P1 21.91     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.92     BRANCO
       RPAD(' ', 5)||';'||   -- P1 21.93     BRANCO
       RPAD(' ', 20)||';'||   -- P1 31.51     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.52     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.53     BRANCO
       RPAD(NVL(TO_CHAR(P1_1001,'YYYYMMDD'),' '), 8)||';'||   -- P1 1001      NOVO
       RPAD(NVL(TO_CHAR(P1_1002,'YYYYMMDD'),' '), 8)||';'||   -- P1 1002      NOVO
       RPAD(NVL(P1_22_222,' '), 1)||';'||   -- P1 22.222    NOVO
       RPAD(NVL(P1_24_22_1,' '), 1)||';'||   -- P1 24.22.1   NOVO
       RPAD(NVL(P1_600,' '), 1)||';'||   -- P1 600       NOVO
       RPAD(NVL(P1_601,' '), 1)||';'||   -- P1 601       NOVO
       RPAD(NVL(P1_602,' '), 1)||';'||   -- P1 602       NOVO
       CASE WHEN P1_603 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_603) END||';'||   -- P1 603       NOVO
       RPAD(NVL(P1_603_1,' '), 3)||';'||   -- P1 603.1     NOVO
       CASE WHEN P1_604 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_604) END||';'||   -- P1 604       NOVO
       RPAD(NVL(P1_604_1,' '), 3)||';'||   -- P1 604.1     NOVO
       CASE WHEN P1_605 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_605) END||';'||   -- P1 605       NOVO
       RPAD(NVL(P1_605_1,' '), 3)||';'||   -- P1 605.1     NOVO
       RPAD(NVL(P1_606,' '), 40)||';'||   -- P1 606       NOVO
       RPAD(NVL(P1_607,' '), 1)||';'||   -- P1 607       NOVO
       CASE WHEN P1_608 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_608) END||';'||   -- P1 608       NOVO
       RPAD(NVL(P1_608_1,' '), 3)||';'||   -- P1 608.1     NOVO
       RPAD(NVL(TO_CHAR(P1_609,'YYYYMMDD'),' '), 8)||';'||   -- P1 609       NOVO
       CASE WHEN P1_610 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_610) END||';'||   -- P1 610       NOVO
       RPAD(NVL(P1_610_1,' '), 3)||';'||   -- P1 610.1     NOVO
       RPAD(NVL(TO_CHAR(P1_611,'YYYYMMDD'),' '), 8)||';'||   -- P1 611       NOVO
       CASE WHEN P1_612 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_612) END||';'||   -- P1 612       NOVO
       RPAD(NVL(P1_612_1,' '), 3)||';'||   -- P1 612.1     NOVO
       RPAD(NVL(P1_613,' '), 1)||';'||   -- P1 613       NOVO
       CASE WHEN P1_614 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_614) END||';'||   -- P1 614       NOVO
       RPAD(NVL(P1_614_1,' '), 3)||';'||   -- P1 614.1     NOVO
       LPAD(NVL(TO_CHAR(P1_615),' '), 6)||';'||   -- P1 615       NOVO
       RPAD(NVL(P1_616,' '), 1)||';'||   -- P1 616       NOVO
       RPAD(NVL(P1_617,' '), 1)||';'||   -- P1 617       NOVO
       RPAD(NVL(P1_618,' '), 1)||';'||   -- P1 618       NOVO
       CASE WHEN P1_619 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_619) END||';'||   -- P1 619       NOVO
       RPAD(NVL(P1_620,' '), 1)||';'||   -- P1 620       NOVO
       RPAD(NVL(P1_635,' '), 1)||';'||   -- P1 635       NOVO
       RPAD(NVL(P1_622,' '), 1)||';'||   -- P1 622       NOVO
       RPAD(NVL(P1_623,' '), 40)||';'||   -- P1 623       NOVO
       CASE WHEN P1_624 IS NULL THEN RPAD(' ', 15) ELSE pack_utilitaire.f_format_taux_15(P1_624) END||';'||   -- P1 624       NOVO
       RPAD(NVL(P1_625,' '), 2)||';'||   -- P1 625       NOVO
       RPAD(NVL(P1_626,' '), 1)||';'||   -- P1 626       NOVO
       RPAD(NVL(P1_627,' '), 1)||';'||   -- P1 627       NOVO
       CASE WHEN P1_628 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_628) END||';'||   -- P1 628       NOVO
       RPAD(NVL(P1_628_1,' '), 3)||';'||   -- P1 628.1     NOVO
       RPAD(NVL(P1_629,' '), 1)||';'||   -- P1 629       NOVO
       CASE WHEN P1_630 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_630) END||';'||   -- P1 630       NOVO
       RPAD(NVL(P1_630_1,' '), 3)||';'||   -- P1 630.1     NOVO
       CASE WHEN P1_631 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_631) END||';'||   -- P1 631       NOVO
       RPAD(NVL(P1_631_1,' '), 3)||';'||   -- P1 631.1     NOVO
       CASE WHEN P1_632 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_632) END||';'||   -- P1 632       NOVO
       RPAD(NVL(P1_632_1,' '), 3)||';'||   -- P1 632.1     NOVO
       CASE WHEN P1_633 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_633) END||';'||   -- P1 633       NOVO
       RPAD(NVL(P1_633_1,' '), 3)||';'||   -- P1 633.1     NOVO
       RPAD(NVL(P1_621,' '), 8)||';'||   -- P1 621       NOVO
       RPAD(' ', 1176)     -- P1 99.99     FILLER
     AS VARCHAR2(3999)) as lignedetail2
  from ENG_CORP_P1_BIS
 where NO_VARIANTE = 6
   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
 order by NO_VARIANTE;

------------------------------------------------------------------------------------------------------------------------
-- PAVE P1 - Hors NAT02, variante 7 - com separador ;
------------------------------------------------------------------------------------------------------------------------
select
     CAST(
       RPAD(TO_CHAR(P1_H_0_1,'YYYYMMDD'),8,' ')||';'||   -- 0.1 (P1)     EXATO
       RPAD(NVL(P1_H_0_2,' '),5,' ')||';'||   -- 0.2 (P1)     EXATO
       RPAD('C_DDR',12,' ')||';'||   -- 0.3 (P1)     EXATO
       'M'||';'||   -- 0.4 (P1)     EXATO
       :MASYSDATE||';'||   -- 0.5 (P1)     EXATO
       'P1'||';'||   -- 0.6 (P1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (P1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (P1)     BRANCO
       RPAD(' ', 4)||';'||   -- 0.9 (P1)     BRANCO
       RPAD(' ', 3)||';'||   -- 0.99 (P1)    BRANCO
       RPAD(NVL(P1_H_1_1,' '),20,' ')||';'||   -- 1.1 (P1)     EXATO
       RPAD(' ', 10)||';'||   -- 1.2 (P1)     BRANCO
       RPAD(NVL(P1_H_1_4,' '),30,' ')||';'||   -- 1.4 (P1)     EXATO
       RPAD(NVL(P1_H_1_6 ,' '),30,' ')||';'||   -- 1.6 (P1)     EXATO
       RPAD(' ', 40)||';'||   -- 1.8 (P1)     BRANCO
       RPAD(NVL(P1_H_1_11,' '),40,' ')||';'||   -- 1.11 (P1)    EXATO
       RPAD(' ', 40)||';'||   -- 1.16 (P1)    BRANCO
       RPAD(' ', 11)||';'||   -- 1.99 (P1)    BRANCO
       RPAD(' ', 7)||';'||   -- 1.98 (P1)    BRANCO
       RPAD(' ', 2)||';'||   -- 1.97 (P1)    BRANCO
       RPAD(NVL(P1_1_1,' '),7,' ')||';'||   -- P1 1.1       EXATO
       RPAD(NVL(P1_1_2,' '),2,' ')||';'||   -- P1 1.2       EXATO
       RPAD(NVL(P1_4_34,' '),1,' ')||';'||   -- P1 4.34      EXATO
       RPAD(NVL(P1_2_0,' '),6,' ')||';'||   -- P1 2.0       EXATO
       RPAD(NVL(P1_2_4,' '),1,' ')||';'||   -- P1 2.4       EXATO
       RPAD(NVL(P1_2_6,' '),5,' ')||';'||   -- P1 2.6       EXATO
       RPAD(NVL(P1_2_18,' '),3,' ')||';'||   -- P1 2.18      EXATO
       RPAD(NVL(P1_2_29,' '),12,' ')||';'||   -- P1 2.29      EXATO
       RPAD(TO_CHAR(P1_3_2,'YYYYMMDD'),8,' ')||';'||   -- P1 3.2       EXATO
       RPAD(TO_CHAR(P1_3_4,'YYYYMMDD'),8,' ')||';'||   -- P1 3.4       EXATO
       RPAD(' ', 10)||';'||   -- P1 16.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.1      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 18.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 18.17     BRANCO
       RPAD(NVL(P1_18_18,' '),3,' ')||';'||   -- P1 18.18     EXATO
       RPAD(' ', 50)||';'||   -- P1 3.98      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.1      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.2      BRANCO
       NVL(P1_5_5,'N')||';'||   -- P1 5.5       EXATO
       RPAD(NVL(P1_4_1,' '),1,' ')||';'||   -- P1 4.1       EXATO
       NVL(P1_5_2,'N')||';'||   -- P1 5.2       EXATO
       RPAD(' ', 8)||';'||   -- P1 5.3       BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.2       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.3       BRANCO
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END||';'||   -- P1 4.4       REGRA
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END||';'||   -- P1 4.5       REGRA
       RPAD(' ', 19)||';'||   -- P1 4.9       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.13      BRANCO
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END||';'||   -- P1 4.14      REGRA
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END||';'||   -- P1 4.15      REGRA
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_16),0))||';'||   -- P1 4.16      EXATO
       RPAD(NVL(P1_4_17,' '),3,' ')||';'||   -- P1 4.17      EXATO
       RPAD(NVL(P1_4_18,' '),12,' ')||';'||   -- P1 4.18      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_6),0))||';'||   -- P1 4.6       EXATO
       RPAD(NVL(P1_4_7,' '),3,' ')||';'||   -- P1 4.7       EXATO
       RPAD(NVL(P1_4_19,' '),12,' ')||';'||   -- P1 4.19      EXATO
       RPAD(' ', 10)||';'||   -- P1 4.20      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.21      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.22      BRANCO
       RPAD(' ', 2)||';'||   -- P1 4.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.6       BRANCO
       RPAD(NVL(P1_5_7,' '),20,' ')||';'||   -- P1 5.7       EXATO
       RPAD(' ', 10)||';'||   -- P1 5.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.33      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.10      BRANCO
       RPAD(' ', 25)||';'||   -- P1 5.11      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.32      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.46      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.47      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.40      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.41      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.42      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.43      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.44      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.45      BRANCO
       RPAD(' ', 19)||';'||   -- P1 5.19      BRANCO
       RPAD(' ', 3)||';'||   -- P1 5.20      BRANCO
       RPAD(NVL(P1_19_5,' '),3,' ')||';'||   -- P1 19.5      EXATO
       RPAD(' ', 12)||';'||   -- P1 3.56      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.50      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.51      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.52      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.53      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.54      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.55      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.57      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.58      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.59      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.60      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.61      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.8       BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.31      BRANCO
       RPAD(' ', 2)||';'||   -- P1 12.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.7       BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.70      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.71      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.74      BRANCO
       RPAD(NVL(P1_2_99,' '), 20)||';'||   -- P1 2.99      EXATO
       RPAD(' ', 19)||';'||   -- P1 3.80      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.81      BRANCO
       RPAD(' ', 12)||';'||   -- P1 3.82      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.83      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.15      BRANCO
       RPAD(' ', 25)||';'||   -- P1 13.10     BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.16      BRANCO
       RPAD(' ', 25)||';'||   -- P1 3.17      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.19      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.84      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.85      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.72      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.73      BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.0       BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.1       BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.2       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.6       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.7       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.10      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.11      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.12      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.13      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.14      BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.3       BRANCO
       RPAD(' ', 3)||';'||   -- P1 12.5      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.15      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.16      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.17      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.18      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.19      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.20      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.21      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.22      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.3      BRANCO
       RPAD(' ', 5)||';'||   -- P1 11.33     BRANCO
       RPAD(' ', 2)||';'||   -- P1 11.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.9      BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.13     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 16.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.20     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.22     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.99     BRANCO
       RPAD(NVL(P1_4_31,' '),1,' ')||';'||   -- P1 4.31      EXATO
       RPAD(' ', 1)||';'||   -- P1 4.32      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.33      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.13     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.36      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.49      BRANCO
       RPAD(' ', 4)||';'||   -- P1 4.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.45      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.46      BRANCO
       LPAD(ABS(TRUNC(NVL(P1_3_20,0))),2,'0')||LPAD(ABS(MOD(NVL(P1_3_20,0) *10000,10000)),4,'0')||';'||   -- P1 3.20      EMENDA
       RPAD(NVL(P1_4_8,' '),1,' ')||';'||   -- P1 4.8       EXATO
       RPAD(' ', 3)||';'||   -- P1 12.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.75      BRANCO
       RPAD(NVL(P1_4_42,' '),6,' ')||';'||   -- P1 4.42      EXATO
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8,' ')||';'||   -- P1 3.3       EXATO
       RPAD(' ', 2)||';'||   -- P1 4.43      BRANCO
       RPAD(' ', 5)||';'||   -- P1 4.44      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.47      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.99      BRANCO
       RPAD(' ', 20)||';'||   -- P1 3.62      BRANCO
       RPAD(' ', 10)||';'||   -- P1 3.63      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.64      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.65      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.66      BRANCO
       RPAD(' ', 7)||';'||   -- P1 6.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.26      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.27      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.28      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.30      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.29      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.40      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.41      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.48      BRANCO
       RPAD(' ', 45)||';'||   -- P1 4.98      BRANCO
       RPAD(' ', 10)||';'||   -- P1 8.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.38      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.39      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.37      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.35      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.36      BRANCO
       RPAD(' ', 30)||';'||   -- P1 9.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 12.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 12.19     BRANCO
       RPAD(' ', 8)||';'||   -- P1 12.6      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.1      BRANCO
       RPAD(' ', 2)||';'||   -- P1 15.2      BRANCO
       RPAD(' ', 20)||';'||   -- P1 12.17     BRANCO
       RPAD(' ', 10)||';'||   -- P1 12.18     BRANCO
       RPAD(' ', 24)||';'||   -- P1 10.99     BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.89      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.90      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.86      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.87      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.88      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.15     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 11.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.76      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.77      BRANCO
       RPAD(' ', 20)||';'||   -- P1 11.4      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.10      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.11      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.12      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.13      BRANCO
       RPAD(' ', 2)||';'||   -- P1 10.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.1       BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.2       BRANCO
       RPAD(' ', 1)||';'||   -- P1 8.11      BRANCO
       RPAD(' ', 14)||';'||   -- P1 8.12      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 20.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 20.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 10.22     BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.21     BRANCO
       RPAD(' ', 10)||';'||   -- P1 10.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 9.5       BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.24     BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.5      BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.98     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.5      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.6      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.7      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.8      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.9      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.10     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.11     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.12     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.13     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.15     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.17     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.18     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.99     BRANCO
       RPAD(NVL(P1_22_56,' '),3,' ')||';'||   -- P1 22.56     EXATO
       RPAD(NVL(P1_22_57,' '),1,' ')||';'||   -- P1 22.57     EXATO
       RPAD(NVL(P1_22_1, ' '),40,' ')||';'||   -- P1 22.1      EXATO
       RPAD(NVL(P1_22_51,' '),40,' ')||';'||   -- P1 22.51     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.2      BRANCO
       RPAD(' ', 4)||';'||   -- P1 22.3      BRANCO
       RPAD(' ', 40)||';'||   -- P1 22.4      BRANCO
       RPAD('ND',2)||';'||   -- P1 22.5      EXATO
       RPAD(NVL(P1_22_52 ,' '),10,' ')||';'||   -- P1 22.52     EXATO
       RPAD(nvl(P1_22_6,' '),2,' ')||';'||   -- P1 22.6      EXATO
       RPAD(NVL(P1_22_53,' '),2,' ')||';'||   -- P1 22.53     EXATO
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||';'||   -- P1 22.54     EXATO
       RPAD(upper(NVL(P1_22_55,' ')),3,' ')||';'||   -- P1 22.55     EXATO
       RPAD('97',2)||';'||   -- P1 22.7      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||';'||   -- P1 22.8      EXATO
       RPAD(nvl(P1_22_9, 'EUR'), 3)||';'||   -- P1 22.9      EXATO
       RPAD(NVL(P1_22_12 ,' '),1,' ')||';'||   -- P1 22.12     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.13     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.14     BRANCO
       RPAD(' ', 12)||';'||   -- P1 22.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.20     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.21     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.22     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.23     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.25     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.26     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.27     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.28     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.29     BRANCO
       RPAD(' ', 7)||';'||   -- P1 22.30     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.31     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.33     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.34     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.35     BRANCO
       RPAD(NVL(P1_22_36,' '),1,' ')||';'||   -- P1 22.36     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.37     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.40     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.41     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.42     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.43     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.44     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.45     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.46     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.47     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.48     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.49     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.50     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.58     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.59     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.60     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.61     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.62     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.63     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.64     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.65     BRANCO
       RPAD(NVL(P1_22_66,' '),2,' ')||';'||   -- P1 22.66     EXATO
       RPAD(NVL(TO_CHAR(P1_22_67,'YYYYMMDD'), ' '),8,' ')||';'||   -- P1 22.67     EXATO
       RPAD(NVL(P1_22_68,' '),2,' ')||';'||   -- P1 22.68     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.69     BRANCO
       LPAD(NVL(to_char(P1_22_70), ' '),5,'0')||';'||   -- P1 22.70     EXATO
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||';'||   -- P1 22.71     EXATO
       RPAD(NVL(P1_22_72,' '),2,' ')||';'||   -- P1 22.72     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.73     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.74     BRANCO
       RPAD(NVL(P1_23_1,' '),1,' ')||';'||   -- P1 23.1      EXATO
       RPAD(NVL(P1_23_2 ,' '),7,' ')||';'||   -- P1 23.2      EXATO
       RPAD(NVL(P1_23_3,' '),20,' ')||';'||   -- P1 23.3      EXATO
       RPAD(NVL(P1_23_4 ,' '),3,' ')||';'||   -- P1 23.4      EXATO
       RPAD(NVL(P1_23_5,' '),3,' ')||';'||   -- P1 23.5      EXATO
       RPAD(NVL(P1_23_6 ,' '),1,' ')||';'||   -- P1 23.6      EXATO
       RPAD(NVL(P1_23_7 ,' '),40,' ')||';'||   -- P1 23.7      EXATO
       RPAD(' ', 5)||';'||   -- P1 23.12     BRANCO
       RPAD(' ', 5)||';'||   -- P1 23.13     BRANCO
       RPAD (nvl(P1_23_8,' '), 12)||';'||   -- P1 23.8      EXATO
       RPAD (nvl(P1_23_9,' '), 12)||';'||   -- P1 23.9      EXATO
       RPAD (nvl(P1_23_10,' '), 12)||';'||   -- P1 23.10     EXATO
       RPAD (nvl(P1_23_11,' '), 12)||';'||   -- P1 23.11     EXATO
       RPAD(' ', 2)||';'||   -- P1 23.99     BRANCO
       RPAD(NVL(P1_24_1,' '),1,' ')||';'||   -- P1 24.1      EXATO
       RPAD(' ', 2)||';'||   -- P1 24.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.5      BRANCO
       RPAD(' ', 13)||';'||   -- P1 24.6      BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.8      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.11     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.12     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.15     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.17     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.18     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.20     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.21     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.22     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.23     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.25     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.26     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.27     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.28     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.29     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.30     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.97     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.31     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.32     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.36     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.98     BRANCO
       RPAD(' ', 12)||';'||   -- P1 24.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.6      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.7      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.8      BRANCO
       RPAD(' ', 39)     -- P1 25.99     CORTE-A
     AS VARCHAR2(4000)) as lignedetail1,
     CAST(
       RPAD(' ', 60)||';'||   -- P1 25.99     CORTE-B
       RPAD(NVL(P1_26_1,' '),1,' ')||';'||   -- P1 26.1      EXATO
       RPAD(NVL(P1_22_11, ' '), 1)||';'||   -- P1 22.11     EXATO
       RPAD(NVL(P1_26_3, ' '), 3)||';'||   -- P1 26.3      EXATO
       RPAD(NVL(P1_26_4, ' '), 3)||';'||   -- P1 26.4      EXATO
       RPAD(' ', 44)||';'||   -- P1 26.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 27.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 27.2      BRANCO
       RPAD(P1_27_3, 1)||';'||   -- P1 27.3      EXATO
       RPAD(NVL(P1_27_4, ' '), 2)||';'||   -- P1 27.4      EXATO
       RPAD(' ', 23)||';'||   -- P1 27.99     BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 29.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.2      BRANCO
       RPAD(' ', 2)||';'||   -- P1 30.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.2      BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.3      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.5      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.6      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.7      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.8      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.11     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.12     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.16     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.17     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.18     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.19     BRANCO
       RPAD(' ', 10)||';'||   -- P1 30.20     BRANCO
       RPAD(' ', 7)||';'||   -- P1 30.21     BRANCO
       RPAD(' ', 25)||';'||   -- P1 30.22     REGRA
       'N'||';'||   -- P1 30.23     REGRA
       RPAD(' ', 25)||';'||   -- P1 30.24     REGRA
       'N'||';'||   -- P1 30.25     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 30.27     BRANCO
       RPAD(' ', 5)||';'||   -- P1 31.1      BRANCO
       RPAD(NVL(P1_31_2, ' '),40,' ')||';'||   -- P1 31.2      EXATO
       RPAD(NVL(P1_31_3,' '),40,' ')||';'||   -- P1 31.3      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||';'||   -- P1 31.4      EXATO
       RPAD(NVL(P1_31_5, ' '), 1,' ')||';'||   -- P1 31.5      EXATO
       RPAD (NVL(P1_31_6,'2'), 1)||';'||   -- P1 31.6      EXATO
       RPAD(' ', 6)||';'||   -- P1 31.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.8      BRANCO
       RPAD(NVL(P1_31_9, ' '),15,' ')||';'||   -- P1 31.9      EXATO
       RPAD(NVL(P1_31_10, ' '),2,' ')||';'||   -- P1 31.10     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.11     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.13     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.15     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.16     BRANCO
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.17     EMENDA
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.18     EMENDA
       RPAD(' ', 6)||';'||   -- P1 31.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.20     BRANCO
       RPAD(' ', 2)||';'||   -- P1 31.21     BRANCO
       P1_31_22||';'||   -- P1 31.22     EXATO
       RPAD(' ', 19)||';'||   -- P1 31.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.24     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.25     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.26     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.27     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.28     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.29     BRANCO
       RPAD(NVL(P1_31_37,' '),1)||';'||   -- P1 31.37     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.38     BRANCO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||';'||   -- P1 29.3      EXATO
       RPAD ('EUR', 3)||';'||   -- P1 29.4      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.6      BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.30     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.31     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.32     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.34     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.36     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.24     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.25     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.26     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.29     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.30     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.31     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.32     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.33     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.34     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.35     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.36     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.37     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.40     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.41     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.42     BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.3      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.4      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.5      BRANCO
       RPAD(' ', 20)||';'||   -- P1 28.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 28.7      BRANCO
       RPAD(' ', 15)||';'||   -- P1 28.8      BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.9      BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.11     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.12     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.13     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.14     BRANCO
       'EUR'||';'||   -- P1 50.1      EXATO
       RPAD(NVL(P1_50_2, ' '), 12)||';'||   -- P1 50.2      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||';'||   -- P1 50.3      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.5      BRANCO
       RPAD(NVL(P1_50_8, ' '), 12)||';'||   -- P1 50.8      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||';'||   -- P1 50.9      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.15     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.16     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.17     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.18     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.22     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.23     BRANCO
       RPAD(' ', 6)||';'||   -- P1 21.29     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.25     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.30     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.31     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.33     BRANCO
       RPAD(' ', 12)||';'||   -- P1 15        BRANCO
       RPAD(' ', 12)||';'||   -- P1 16        BRANCO
       RPAD(' ', 12)||';'||   -- P1 14        BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.20     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.35     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.36     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.47     BRANCO
       RPAD(' ', 7)||';'||   -- P1 21.48     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.49     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.50     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.51     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.52     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.53     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.54     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.44     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.45     BRANCO
       RPAD(NVL(P1_21_46,' '),1)||';'||   -- P1 21.46     EXATO
       RPAD(NVL(P1_21_38,' '),1)||';'||   -- P1 21.38     EXATO
       RPAD(NVL(P1_21_39,' '),1)||';'||   -- P1 21.39     EXATO
       RPAD(NVL(P1_21_40,' '),1)||';'||   -- P1 21.40     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.41     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.42     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.43     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.56     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.57     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.58     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.59     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.60     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.61     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.62     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.63     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.64     BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.65     REGRA
       RPAD(NVL(P1_21_66,' '),1)||';'||   -- P1 21.66     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.67     BRANCO
       RPAD(NVL(P1_21_68,' '),1)||';'||   -- P1 21.68     EXATO
       RPAD(NVL(P1_21_55,' '),12)||';'||   -- P1 21.55     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.69     BRANCO
       RPAD(' ', 20)||';'||   -- P1 21.89     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.90     BRANCO
       RPAD(NVL(P1_8_13,' '),1)||';'||   -- P1 8.13      EXATO
       RPAD(' ', 40)||';'||   -- P1 21.71     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.72     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.73     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.74     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.75     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.76     BRANCO
       RPAD(' ', 11)||';'||   -- P1 21.77     BRANCO
       RPAD(' ', 12)||';'||   -- P1 21.78     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.94     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.95     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.79     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.80     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.81     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.82     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.83     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.84     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.85     BRANCO
       RPAD(NVL(P1_21_86,' '),1)||';'||   -- P1 21.86     EXATO
       RPAD(NVL(P1_21_87,' '),1)||';'||   -- P1 21.87     EXATO
       RPAD(NVL(P1_21_88,' '),1)||';'||   -- P1 21.88     EXATO
       RPAD(' ', 19)||';'||   -- P1 21.91     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.92     BRANCO
       RPAD(' ', 5)||';'||   -- P1 21.93     BRANCO
       RPAD(' ', 20)||';'||   -- P1 31.51     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.52     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.53     BRANCO
       RPAD(NVL(TO_CHAR(P1_1001,'YYYYMMDD'),' '), 8)||';'||   -- P1 1001      NOVO
       RPAD(NVL(TO_CHAR(P1_1002,'YYYYMMDD'),' '), 8)||';'||   -- P1 1002      NOVO
       RPAD(NVL(P1_22_222,' '), 1)||';'||   -- P1 22.222    NOVO
       RPAD(NVL(P1_24_22_1,' '), 1)||';'||   -- P1 24.22.1   NOVO
       RPAD(NVL(P1_600,' '), 1)||';'||   -- P1 600       NOVO
       RPAD(NVL(P1_601,' '), 1)||';'||   -- P1 601       NOVO
       RPAD(NVL(P1_602,' '), 1)||';'||   -- P1 602       NOVO
       CASE WHEN P1_603 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_603) END||';'||   -- P1 603       NOVO
       RPAD(NVL(P1_603_1,' '), 3)||';'||   -- P1 603.1     NOVO
       CASE WHEN P1_604 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_604) END||';'||   -- P1 604       NOVO
       RPAD(NVL(P1_604_1,' '), 3)||';'||   -- P1 604.1     NOVO
       CASE WHEN P1_605 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_605) END||';'||   -- P1 605       NOVO
       RPAD(NVL(P1_605_1,' '), 3)||';'||   -- P1 605.1     NOVO
       RPAD(NVL(P1_606,' '), 40)||';'||   -- P1 606       NOVO
       RPAD(NVL(P1_607,' '), 1)||';'||   -- P1 607       NOVO
       CASE WHEN P1_608 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_608) END||';'||   -- P1 608       NOVO
       RPAD(NVL(P1_608_1,' '), 3)||';'||   -- P1 608.1     NOVO
       RPAD(NVL(TO_CHAR(P1_609,'YYYYMMDD'),' '), 8)||';'||   -- P1 609       NOVO
       CASE WHEN P1_610 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_610) END||';'||   -- P1 610       NOVO
       RPAD(NVL(P1_610_1,' '), 3)||';'||   -- P1 610.1     NOVO
       RPAD(NVL(TO_CHAR(P1_611,'YYYYMMDD'),' '), 8)||';'||   -- P1 611       NOVO
       CASE WHEN P1_612 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_612) END||';'||   -- P1 612       NOVO
       RPAD(NVL(P1_612_1,' '), 3)||';'||   -- P1 612.1     NOVO
       RPAD(NVL(P1_613,' '), 1)||';'||   -- P1 613       NOVO
       CASE WHEN P1_614 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_614) END||';'||   -- P1 614       NOVO
       RPAD(NVL(P1_614_1,' '), 3)||';'||   -- P1 614.1     NOVO
       LPAD(NVL(TO_CHAR(P1_615),' '), 6)||';'||   -- P1 615       NOVO
       RPAD(NVL(P1_616,' '), 1)||';'||   -- P1 616       NOVO
       RPAD(NVL(P1_617,' '), 1)||';'||   -- P1 617       NOVO
       RPAD(NVL(P1_618,' '), 1)||';'||   -- P1 618       NOVO
       CASE WHEN P1_619 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_619) END||';'||   -- P1 619       NOVO
       RPAD(NVL(P1_620,' '), 1)||';'||   -- P1 620       NOVO
       RPAD(NVL(P1_635,' '), 1)||';'||   -- P1 635       NOVO
       RPAD(NVL(P1_622,' '), 1)||';'||   -- P1 622       NOVO
       RPAD(NVL(P1_623,' '), 40)||';'||   -- P1 623       NOVO
       CASE WHEN P1_624 IS NULL THEN RPAD(' ', 15) ELSE pack_utilitaire.f_format_taux_15(P1_624) END||';'||   -- P1 624       NOVO
       RPAD(NVL(P1_625,' '), 2)||';'||   -- P1 625       NOVO
       RPAD(NVL(P1_626,' '), 1)||';'||   -- P1 626       NOVO
       RPAD(NVL(P1_627,' '), 1)||';'||   -- P1 627       NOVO
       CASE WHEN P1_628 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_628) END||';'||   -- P1 628       NOVO
       RPAD(NVL(P1_628_1,' '), 3)||';'||   -- P1 628.1     NOVO
       RPAD(NVL(P1_629,' '), 1)||';'||   -- P1 629       NOVO
       CASE WHEN P1_630 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_630) END||';'||   -- P1 630       NOVO
       RPAD(NVL(P1_630_1,' '), 3)||';'||   -- P1 630.1     NOVO
       CASE WHEN P1_631 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_631) END||';'||   -- P1 631       NOVO
       RPAD(NVL(P1_631_1,' '), 3)||';'||   -- P1 631.1     NOVO
       CASE WHEN P1_632 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_632) END||';'||   -- P1 632       NOVO
       RPAD(NVL(P1_632_1,' '), 3)||';'||   -- P1 632.1     NOVO
       CASE WHEN P1_633 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_633) END||';'||   -- P1 633       NOVO
       RPAD(NVL(P1_633_1,' '), 3)||';'||   -- P1 633.1     NOVO
       RPAD(NVL(P1_621,' '), 8)||';'||   -- P1 621       NOVO
       RPAD(' ', 1176)     -- P1 99.99     FILLER
     AS VARCHAR2(3999)) as lignedetail2
  from ENG_CORP_P1_BIS
 where NO_VARIANTE = 7
   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
 order by NO_VARIANTE;

------------------------------------------------------------------------------------------------------------------------
-- PAVE P1 - Hors NAT02, variante 8 - com separador ;
------------------------------------------------------------------------------------------------------------------------
select
     CAST(
       RPAD(TO_CHAR(P1_H_0_1,'YYYYMMDD'),8,' ')||';'||   -- 0.1 (P1)     EXATO
       RPAD(NVL(P1_H_0_2,' '),5,' ')||';'||   -- 0.2 (P1)     EXATO
       RPAD('C_DDR',12,' ')||';'||   -- 0.3 (P1)     EXATO
       'M'||';'||   -- 0.4 (P1)     EXATO
       :MASYSDATE||';'||   -- 0.5 (P1)     EXATO
       'P1'||';'||   -- 0.6 (P1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (P1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (P1)     BRANCO
       RPAD(' ', 4)||';'||   -- 0.9 (P1)     BRANCO
       RPAD(' ', 3)||';'||   -- 0.99 (P1)    BRANCO
       RPAD(NVL(P1_H_1_1,' '),20,' ')||';'||   -- 1.1 (P1)     EXATO
       RPAD(' ', 10)||';'||   -- 1.2 (P1)     BRANCO
       RPAD(NVL(P1_H_1_4,' '),30,' ')||';'||   -- 1.4 (P1)     EXATO
       RPAD(NVL(P1_H_1_6 ,' '),30,' ')||';'||   -- 1.6 (P1)     EXATO
       RPAD(' ', 40)||';'||   -- 1.8 (P1)     BRANCO
       RPAD(NVL(P1_H_1_11,' '),40,' ')||';'||   -- 1.11 (P1)    EXATO
       RPAD(' ', 40)||';'||   -- 1.16 (P1)    BRANCO
       RPAD(' ', 11)||';'||   -- 1.99 (P1)    BRANCO
       RPAD(' ', 7)||';'||   -- 1.98 (P1)    BRANCO
       RPAD(' ', 2)||';'||   -- 1.97 (P1)    BRANCO
       RPAD(NVL(P1_1_1,' '),7,' ')||';'||   -- P1 1.1       EXATO
       RPAD(NVL(P1_1_2,' '),2,' ')||';'||   -- P1 1.2       EXATO
       RPAD(NVL(P1_4_34,' '),1,' ')||';'||   -- P1 4.34      EXATO
       RPAD(NVL(P1_2_0,' '),6,' ')||';'||   -- P1 2.0       EXATO
       RPAD(NVL(P1_2_4,' '),1,' ')||';'||   -- P1 2.4       EXATO
       RPAD(NVL(P1_2_6,' '),5,' ')||';'||   -- P1 2.6       EXATO
       RPAD(NVL(P1_2_18,' '),3,' ')||';'||   -- P1 2.18      EXATO
       RPAD(NVL(P1_2_29,' '),12,' ')||';'||   -- P1 2.29      EXATO
       RPAD(TO_CHAR(P1_3_2,'YYYYMMDD'),8,' ')||';'||   -- P1 3.2       EXATO
       RPAD(TO_CHAR(P1_3_4,'YYYYMMDD'),8,' ')||';'||   -- P1 3.4       EXATO
       RPAD(' ', 10)||';'||   -- P1 16.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.1      BRANCO
       RPAD(' ', 10)||';'||   -- P1 18.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 18.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 18.17     BRANCO
       RPAD(NVL(P1_18_18, ' '),3,' ')||';'||   -- P1 18.18     EXATO
       RPAD(' ', 50)||';'||   -- P1 3.98      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.1      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.2      BRANCO
       NVL(P1_5_5,'N')||';'||   -- P1 5.5       EXATO
       RPAD(' ', 1)||';'||   -- P1 4.1       BRANCO
       RPAD(NVL(P1_5_2,' '),1, ' ')||';'||   -- P1 5.2       EXATO
       RPAD(' ', 8)||';'||   -- P1 5.3       BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.2       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.3       BRANCO
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END||';'||   -- P1 4.4       REGRA
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END||';'||   -- P1 4.5       REGRA
       RPAD(' ', 19)||';'||   -- P1 4.9       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.13      BRANCO
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END||';'||   -- P1 4.14      REGRA
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END||';'||   -- P1 4.15      REGRA
       RPAD(' ', 19)||';'||   -- P1 4.16      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.17      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.18      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.6       BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.7       BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.19      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.20      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.21      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.22      BRANCO
       RPAD(' ', 2)||';'||   -- P1 4.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.6       BRANCO
       RPAD(' ', 20)||';'||   -- P1 5.7       BRANCO
       RPAD(' ', 10)||';'||   -- P1 5.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.33      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.10      BRANCO
       RPAD(' ', 25)||';'||   -- P1 5.11      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.32      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.46      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.47      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.40      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.41      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.42      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.43      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.44      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.45      BRANCO
       RPAD(' ', 19)||';'||   -- P1 5.19      BRANCO
       RPAD(' ', 3)||';'||   -- P1 5.20      BRANCO
       RPAD(nvl(P1_19_5,' '),3)||';'||   -- P1 19.5      EXATO
       RPAD(' ', 12)||';'||   -- P1 3.56      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.50      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.51      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.52      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.53      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.54      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.55      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.57      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.58      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.59      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.60      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.61      BRANCO
       RPAD(' ', 2)||';'||   -- P1 3.99      BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_8),0))||';'||   -- P1 3.8       EXATO
       RPAD(NVL(P1_3_9,' '),3,' ')||';'||   -- P1 3.9       EXATO
       RPAD(NVL(P1_3_31,' '),12,' ')||';'||   -- P1 3.31      EXATO
       RPAD(P1_12_1, 2,' ')||';'||   -- P1 12.1      EXATO
       RPAD(NVL(P1_3_7, ' '),1,' ')||';'||   -- P1 3.7       EXATO
       RPAD(' ', 19)||';'||   -- P1 3.70      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.71      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.74      BRANCO
       RPAD(NVL(P1_2_99,' '), 20)||';'||   -- P1 2.99      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_80),0))||';'||   -- P1 3.80      EXATO
       RPAD(NVL(P1_3_81,' '),3,' ')||';'||   -- P1 3.81      EXATO
       RPAD(NVL(P1_3_82,' '),12,' ')||';'||   -- P1 3.82      EXATO
       RPAD(NVL(P1_3_83, ' '),1,' ')||';'||   -- P1 3.83      EXATO
       RPAD(NVL(P1_3_15, ' '),1,' ')||';'||   -- P1 3.15      EXATO
       RPAD(NVL(P1_13_10, ' '),25,' ')||';'||   -- P1 13.10     EXATO
       RPAD(NVL(P1_3_16, ' '),1,' ')||';'||   -- P1 3.16      EXATO
       RPAD(NVL(P1_3_17, ' '),25,' ')||';'||   -- P1 3.17      EXATO
       RPAD(NVL(P1_3_19, ' '),3,' ')||';'||   -- P1 3.19      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_84),0))||';'||   -- P1 3.84      EXATO
       RPAD(NVL(P1_3_85, ' '),3,' ')||';'||   -- P1 3.85      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_72),0))||';'||   -- P1 3.72      EXATO
       RPAD(NVL(P1_3_73, ' '),3,' ')||';'||   -- P1 3.73      EXATO
       RPAD(' ', 3)||';'||   -- P1 7.0       BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.1       BRANCO
       RPAD(' ', 3)||';'||   -- P1 7.2       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.6       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.7       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.8       BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.9       BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.10      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.11      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.12      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.13      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.14      BRANCO
       RPAD(' ', 19)||';'||   -- P1 7.3       BRANCO
       RPAD(' ', 3)||';'||   -- P1 12.5      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.15      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.16      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.17      BRANCO
       RPAD(' ', 2)||';'||   -- P1 7.18      BRANCO
       RPAD(' ', 12)||';'||   -- P1 7.19      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.20      BRANCO
       RPAD(' ', 8)||';'||   -- P1 7.21      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.22      BRANCO
       RPAD(' ', 10)||';'||   -- P1 7.23      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 7.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.3      BRANCO
       RPAD(' ', 5)||';'||   -- P1 11.33     BRANCO
       RPAD(' ', 2)||';'||   -- P1 11.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.9      BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.13     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.15     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.16     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 16.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.20     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 16.22     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.99     BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.31      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.32      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.33      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.13     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.24      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.36      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.49      BRANCO
       RPAD(' ', 4)||';'||   -- P1 4.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.45      BRANCO
       RPAD(' ', 12)||';'||   -- P1 4.46      BRANCO
       LPAD(ABS(TRUNC(NVL(P1_3_20,0))),2,'0')||LPAD(ABS(MOD(NVL(P1_3_20,0) *10000,10000)),4,'0')||';'||   -- P1 3.20      EMENDA
       RPAD(NVL(P1_4_8, ' '),1,' ')||';'||   -- P1 4.8       EXATO
       RPAD(' ', 3)||';'||   -- P1 12.16     BRANCO
       RPAD(NVL(P1_3_75, ' '),2,' ')||';'||   -- P1 3.75      EXATO
       RPAD(NVL(P1_4_42,' '),6,' ')||';'||   -- P1 4.42      EXATO
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8,' ')||';'||   -- P1 3.3       EXATO
       RPAD(' ', 2)||';'||   -- P1 4.43      BRANCO
       RPAD(' ', 5)||';'||   -- P1 4.44      BRANCO
       RPAD(' ', 8)||';'||   -- P1 4.47      BRANCO
       RPAD(' ', 1)||';'||   -- P1 5.99      BRANCO
       RPAD(' ', 20)||';'||   -- P1 3.62      BRANCO
       RPAD(' ', 10)||';'||   -- P1 3.63      BRANCO
       RPAD(' ', 1)||';'||   -- P1 3.64      BRANCO
       RPAD(' ', 19)||';'||   -- P1 3.65      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.66      BRANCO
       RPAD(' ', 7)||';'||   -- P1 6.99      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.25      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.26      BRANCO
       RPAD(' ', 19)||';'||   -- P1 4.27      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.28      BRANCO
       RPAD(' ', 10)||';'||   -- P1 4.30      BRANCO
       RPAD(' ', 20)||';'||   -- P1 7.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.29      BRANCO
       RPAD(' ', 3)||';'||   -- P1 4.40      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.41      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.48      BRANCO
       RPAD(' ', 45)||';'||   -- P1 4.98      BRANCO
       RPAD(' ', 10)||';'||   -- P1 8.99      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.38      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.39      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.37      BRANCO
       RPAD(' ', 1)||';'||   -- P1 4.35      BRANCO
       RPAD(NVL(P1_3_36, ' '),1,' ')||';'||   -- P1 3.36      EXATO
       RPAD(' ', 30)||';'||   -- P1 9.99      BRANCO
       RPAD(' ', 12)||';'||   -- P1 12.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 12.19     BRANCO
       RPAD(' ', 8)||';'||   -- P1 12.6      BRANCO
       RPAD(NVL(P1_15_1, ' '),2,' ')||';'||   -- P1 15.1      EXATO
       RPAD(NVL(P1_15_2, ' '),2,' ')||';'||   -- P1 15.2      EXATO
       RPAD(' ', 20)||';'||   -- P1 12.17     BRANCO
       RPAD(' ', 10)||';'||   -- P1 12.18     BRANCO
       RPAD(' ', 24)||';'||   -- P1 10.99     BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.89      BRANCO
       RPAD(' ', 3)||';'||   -- P1 3.90      BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_86),0))||';'||   -- P1 3.86      EXATO
       RPAD(NVL(P1_3_87, ' '),3,' ')||';'||   -- P1 3.87      EXATO
       RPAD(NVL(P1_3_88, ' '),1,' ')||';'||   -- P1 3.88      EXATO
       RPAD(' ', 20)||';'||   -- P1 11.15     BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.16     BRANCO
       RPAD(NVL(P1_11_1, ' '),3,' ')||';'||   -- P1 11.1      EXATO
       RPAD(NVL(P1_3_76, ' '),1,' ')||';'||   -- P1 3.76      EXATO
       RPAD(NVL(P1_3_77, ' '),1,' ')||';'||   -- P1 3.77      EXATO
       RPAD(' ', 20)||';'||   -- P1 11.4      BRANCO
       RPAD(' ', 10)||';'||   -- P1 11.5      BRANCO
       (CASE WHEN P1_11_2 >=0 THEN '+' ELSE '-' END)||LPAD(ABS(TRUNC(NVL(P1_11_2,0))),4,'0')||RPAD(' ',5)||';'||   -- P1 11.2      EMENDA
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_10),0))||';'||   -- P1 3.10      EXATO
       RPAD(NVL(P1_3_11, ' '),3,' ')||';'||   -- P1 3.11      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_3_12),0))||';'||   -- P1 3.12      EXATO
       RPAD(NVL(P1_3_13, ' '),3,' ')||';'||   -- P1 3.13      EXATO
       RPAD(NVL(P1_10_20, ' '),2,' ')||';'||   -- P1 10.20     EXATO
       RPAD(NVL(P1_10_1, ' '),3,' ')||';'||   -- P1 10.1      EXATO
       RPAD(NVL(P1_10_2, ' '),1,' ')||';'||   -- P1 10.2      EXATO
       RPAD(NVL(P1_8_1, ' '),1,' ')||';'||   -- P1 8.1       EXATO
       RPAD(NVL(P1_8_2, ' '),14,' ')||';'||   -- P1 8.2       EXATO
       RPAD(NVL(P1_8_11, ' '),1,' ')||';'||   -- P1 8.11      EXATO
       RPAD(NVL(P1_8_12, ' '),14,' ')||';'||   -- P1 8.12      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_20_1),0))||';'||   -- P1 20.1      EXATO
       RPAD(NVL(P1_20_2, ' '),3,' ')||';'||   -- P1 20.2      EXATO
       pack_utilitaire.f_format_montant_bis2(nvl((P1_20_3),0))||';'||   -- P1 20.3      EXATO
       RPAD(NVL(P1_20_4, ' '),3,' ')||';'||   -- P1 20.4      EXATO
       RPAD(' ', 1)||';'||   -- P1 10.22     BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.21     BRANCO
       RPAD(' ', 10)||';'||   -- P1 10.5      BRANCO
       RPAD(' ', 10)||';'||   -- P1 9.5       BRANCO
       RPAD(' ', 19)||';'||   -- P1 10.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 10.24     BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 13.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 13.5      BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.98     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.3      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.5      BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.6      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.7      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.8      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.9      BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.10     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.11     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.12     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.13     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.14     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.15     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.16     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.17     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.18     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.99     BRANCO
       RPAD(NVL(P1_22_56,' '),3,' ')||';'||   -- P1 22.56     EXATO
       RPAD(NVL(P1_22_57,' '),1,' ')||';'||   -- P1 22.57     EXATO
       RPAD(NVL(P1_22_1, ' '),40,' ')||';'||   -- P1 22.1      EXATO
       RPAD(NVL(P1_22_51,' '),40,' ')||';'||   -- P1 22.51     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.2      BRANCO
       RPAD(' ', 4)||';'||   -- P1 22.3      BRANCO
       RPAD(' ', 40)||';'||   -- P1 22.4      BRANCO
       RPAD('ND',2)||';'||   -- P1 22.5      EXATO
       RPAD(NVL(P1_22_52,' '),10,' ')||';'||   -- P1 22.52     EXATO
       RPAD(nvl(P1_22_6,' '),2,' ')||';'||   -- P1 22.6      EXATO
       RPAD(NVL(P1_22_53,' '),2,' ')||';'||   -- P1 22.53     EXATO
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||';'||   -- P1 22.54     EXATO
       RPAD(upper(NVL(P1_22_55,' ')),3,' ')||';'||   -- P1 22.55     EXATO
       RPAD('97',2)||';'||   -- P1 22.7      EXATO
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||';'||   -- P1 22.8      EXATO
       RPAD(nvl(P1_22_9, 'EUR'), 3)||';'||   -- P1 22.9      EXATO
       RPAD(NVL(P1_22_12,' '),1,' ')||';'||   -- P1 22.12     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.13     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.14     BRANCO
       RPAD(' ', 12)||';'||   -- P1 22.15     BRANCO
       RPAD(NVL(P1_22_16,' '),1)||';'||   -- P1 22.16     EXATO
       RPAD(' ', 1)||';'||   -- P1 22.17     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.18     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.20     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.21     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.22     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.23     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.24     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.25     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.26     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.27     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.28     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.29     BRANCO
       RPAD(' ', 7)||';'||   -- P1 22.30     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.31     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.33     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.34     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.35     BRANCO
       RPAD(NVL(P1_22_36,' '),1,' ')||';'||   -- P1 22.36     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.37     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.40     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.41     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.42     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.43     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.44     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.45     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.46     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.47     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.48     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.49     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.50     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.58     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.59     BRANCO
       RPAD(' ', 19)||';'||   -- P1 22.60     BRANCO
       RPAD(' ', 3)||';'||   -- P1 22.61     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.62     BRANCO
       RPAD(' ', 8)||';'||   -- P1 22.63     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.64     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.65     BRANCO
       RPAD(NVL(P1_22_66, ' '), 2, ' ')||';'||   -- P1 22.66     EXATO
       RPAD(' ', 8)||';'||   -- P1 22.67     BRANCO
       RPAD(' ', 2)||';'||   -- P1 22.68     BRANCO
       RPAD(' ', 1)||';'||   -- P1 22.69     BRANCO
       RPAD(' ', 5)||';'||   -- P1 22.70     BRANCO
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||';'||   -- P1 22.71     EXATO
       RPAD(NVL(P1_22_72,' '), 2, ' ')||';'||   -- P1 22.72     EXATO
       RPAD(' ', 10)||';'||   -- P1 22.73     BRANCO
       RPAD(' ', 10)||';'||   -- P1 22.74     BRANCO
       RPAD(NVL(P1_23_1,' '),1,' ')||';'||   -- P1 23.1      EXATO
       RPAD(NVL(P1_23_2,' '),7,' ')||';'||   -- P1 23.2      EXATO
       RPAD(NVL(P1_23_3,' '),20,' ')||';'||   -- P1 23.3      EXATO
       RPAD(NVL(P1_23_4,' '),3,' ')||';'||   -- P1 23.4      EXATO
       RPAD(NVL(P1_23_5,' '),3,' ')||';'||   -- P1 23.5      EXATO
       RPAD(NVL(P1_23_6,' '),1,' ')||';'||   -- P1 23.6      EXATO
       RPAD(NVL(P1_23_7,' '),40,' ')||';'||   -- P1 23.7      EXATO
       RPAD(' ', 5)||';'||   -- P1 23.12     BRANCO
       RPAD(' ', 5)||';'||   -- P1 23.13     BRANCO
       RPAD (nvl(P1_23_8,' '), 12)||';'||   -- P1 23.8      EXATO
       RPAD (nvl(P1_23_9,' '), 12)||';'||   -- P1 23.9      EXATO
       RPAD (nvl(P1_23_10,' '), 12)||';'||   -- P1 23.10     EXATO
       RPAD (nvl(P1_23_11,' '), 12)||';'||   -- P1 23.11     EXATO
       RPAD(' ', 2)||';'||   -- P1 23.99     BRANCO
       RPAD(NVL(P1_24_1,' '),1,' ')||';'||   -- P1 24.1      EXATO
       RPAD(' ', 2)||';'||   -- P1 24.2      BRANCO
       RPAD(NVL(P1_24_3,' '),1,' ')||';'||   -- P1 24.3      EXATO
       RPAD(' ', 1)||';'||   -- P1 24.4      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.5      BRANCO
       RPAD(' ', 13)||';'||   -- P1 24.6      BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.8      BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.11     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.12     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.13     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.14     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.15     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.16     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.17     BRANCO
       RPAD(' ', 19)||';'||   -- P1 24.18     BRANCO
       RPAD(' ', 3)||';'||   -- P1 24.19     BRANCO
       RPAD(NVL(P1_24_20,' '),1,' ')||';'||   -- P1 24.20     EXATO
       RPAD(' ', 40)||';'||   -- P1 24.21     BRANCO
       RPAD(' ', 40)||';'||   -- P1 24.22     BRANCO
       RPAD(NVL(P1_24_23,' '),1,' ')||';'||   -- P1 24.23     EXATO
       RPAD(NVL(P1_24_24,' '),1,' ')||';'||   -- P1 24.24     EXATO
       RPAD(' ', 1)||';'||   -- P1 24.25     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.26     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.27     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.28     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.29     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.30     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.97     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.31     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.32     BRANCO
       RPAD(' ', 50)||';'||   -- P1 24.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 24.36     BRANCO
       RPAD(' ', 30)||';'||   -- P1 24.98     BRANCO
       RPAD(' ', 12)||';'||   -- P1 24.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 24.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.3      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 25.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 25.6      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.7      BRANCO
       RPAD(' ', 6)||';'||   -- P1 25.8      BRANCO
       RPAD(' ', 39)     -- P1 25.99     CORTE-A
     AS VARCHAR2(4000)) as lignedetail1,
     CAST(
       RPAD(' ', 60)||';'||   -- P1 25.99     CORTE-B
       RPAD(NVL(P1_26_1,' '),1,' ')||';'||   -- P1 26.1      EXATO
       RPAD(NVL(P1_22_11, ' '), 1)||';'||   -- P1 22.11     EXATO
       RPAD(NVL(P1_26_3, ' '), 3)||';'||   -- P1 26.3      EXATO
       RPAD(NVL(P1_26_4, ' '), 3)||';'||   -- P1 26.4      EXATO
       RPAD(' ', 44)||';'||   -- P1 26.99     BRANCO
       RPAD(' ', 19)||';'||   -- P1 27.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 27.2      BRANCO
       RPAD(P1_27_3, 1)||';'||   -- P1 27.3      EXATO
       RPAD(NVL(P1_27_4, ' '), 2)||';'||   -- P1 27.4      EXATO
       RPAD(' ', 23)||';'||   -- P1 27.99     BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.1      BRANCO
       RPAD(' ', 1)||';'||   -- P1 28.2      BRANCO
       RPAD(' ', 19)||';'||   -- P1 29.1      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.2      BRANCO
       RPAD(NVL(P1_30_1,' '), 2, ' ')||';'||   -- P1 30.1      EXATO
       RPAD(NVL(P1_30_2,' '), 1, ' ')||';'||   -- P1 30.2      EXATO
       RPAD(NVL(P1_30_3,' '), 1, ' ')||';'||   -- P1 30.3      EXATO
       RPAD(' ', 19)||';'||   -- P1 30.4      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.5      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.6      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.7      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.8      BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.9      BRANCO
       RPAD(' ', 19)||';'||   -- P1 30.10     BRANCO
       RPAD(' ', 3)||';'||   -- P1 30.11     BRANCO
       pack_utilitaire.f_format_montant_bis2(nvl(P1_30_12,0))||';'||   -- P1 30.12     EXATO
       RPAD(NVL(P1_30_13,' '), 3, ' ')||';'||   -- P1 30.13     EXATO
       pack_utilitaire.f_format_montant_bis2(nvl(P1_30_14,0))||';'||   -- P1 30.14     EXATO
       RPAD(NVL(P1_30_15,' '), 3, ' ')||';'||   -- P1 30.15     EXATO
       RPAD(NVL(P1_30_16,' '), 1, ' ')||';'||   -- P1 30.16     EXATO
       CASE WHEN P1_30_17 IS NULL THEN RPAD(' ', 10) ELSE pack_utilitaire.f_format_taux(P1_30_17) END||';'||   -- P1 30.17     EXATO
       RPAD(NVL(P1_30_18,' '), 7, ' ')||';'||   -- P1 30.18     EXATO
       RPAD(NVL(P1_30_19,' '), 1, ' ')||';'||   -- P1 30.19     EXATO
       CASE WHEN P1_30_20 IS NULL THEN RPAD(' ', 10) ELSE pack_utilitaire.f_format_taux(P1_30_20) END||';'||   -- P1 30.20     EXATO
       RPAD(NVL(P1_30_21,' '), 7, ' ')||';'||   -- P1 30.21     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.22     REGRA
       'N'||';'||   -- P1 30.23     REGRA
       RPAD(' ', 25)||';'||   -- P1 30.24     REGRA
       'N'||';'||   -- P1 30.25     EXATO
       RPAD(' ', 25)||';'||   -- P1 30.26     BRANCO
       RPAD(NVL(P1_30_27,' '), 1, ' ')||';'||   -- P1 30.27     EXATO
       RPAD(' ', 5)||';'||   -- P1 31.1      BRANCO
       RPAD(NVL(P1_31_2, ' '), 40)||';'||   -- P1 31.2      EXATO
       RPAD(NVL(P1_31_3, ' '), 40)||';'||   -- P1 31.3      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||';'||   -- P1 31.4      EXATO
       RPAD(NVL(P1_31_5, ' '), 1)||';'||   -- P1 31.5      EXATO
       RPAD (NVL(P1_31_6,'2'), 1)||';'||   -- P1 31.6      EXATO
       RPAD(' ', 6)||';'||   -- P1 31.7      BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.8      BRANCO
       RPAD(NVL(P1_31_9, ' '),15,' ')||';'||   -- P1 31.9      EXATO
       RPAD(NVL(P1_31_10, ' '),2,' ')||';'||   -- P1 31.10     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.11     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.12     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.13     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.15     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.16     BRANCO
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.17     EMENDA
       RPAD('+',1)||RPAD('00000',5)||';'||   -- P1 31.18     EMENDA
       RPAD(' ', 6)||';'||   -- P1 31.19     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.20     BRANCO
       RPAD(' ', 2)||';'||   -- P1 31.21     BRANCO
       P1_31_22||';'||   -- P1 31.22     EXATO
       RPAD(' ', 19)||';'||   -- P1 31.23     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.24     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.25     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.26     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.27     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.28     BRANCO
       RPAD(' ', 15)||';'||   -- P1 31.29     BRANCO
       RPAD(NVL(P1_31_37,' '),1)||';'||   -- P1 31.37     EXATO
       RPAD(' ', 1)||';'||   -- P1 31.38     BRANCO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||';'||   -- P1 29.3      EXATO
       RPAD ('EUR', 3)||';'||   -- P1 29.4      EXATO
       RPAD(' ', 19)||';'||   -- P1 29.5      BRANCO
       RPAD(' ', 3)||';'||   -- P1 29.6      BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.20     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.30     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.31     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.32     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.33     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.34     BRANCO
       RPAD(' ', 8)||';'||   -- P1 31.35     BRANCO
       RPAD(' ', 1)||';'||   -- P1 31.36     BRANCO
       RPAD(' ', 7)||';'||   -- P1 16.24     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.25     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.26     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 16.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.29     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.30     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.31     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.32     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.33     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.34     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.35     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.36     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.37     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.38     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.39     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.40     BRANCO
       RPAD(' ', 19)||';'||   -- P1 16.41     BRANCO
       RPAD(' ', 3)||';'||   -- P1 16.42     BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.3      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.4      BRANCO
       RPAD(' ', 2)||';'||   -- P1 28.5      BRANCO
       RPAD(' ', 20)||';'||   -- P1 28.6      BRANCO
       RPAD(' ', 10)||';'||   -- P1 28.7      BRANCO
       RPAD(' ', 15)||';'||   -- P1 28.8      BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.9      BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.10     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.11     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.12     BRANCO
       RPAD(' ', 19)||';'||   -- P1 28.13     BRANCO
       RPAD(' ', 3)||';'||   -- P1 28.14     BRANCO
       'EUR'||';'||   -- P1 50.1      EXATO
       RPAD(NVL(P1_50_2, ' '), 12)||';'||   -- P1 50.2      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||';'||   -- P1 50.3      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.4      BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.5      BRANCO
       RPAD(NVL(P1_50_8, ' '), 12)||';'||   -- P1 50.8      EXATO
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||';'||   -- P1 50.9      EXATO
       RPAD(' ', 12)||';'||   -- P1 50.14     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.15     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.16     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.17     BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.18     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.19     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.22     BRANCO
       RPAD(' ', 8)||';'||   -- P1 21.23     BRANCO
       RPAD(' ', 6)||';'||   -- P1 21.29     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.25     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.26     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.27     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.28     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.30     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.31     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.32     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.33     BRANCO
       RPAD(' ', 12)||';'||   -- P1 15        BRANCO
       RPAD(' ', 12)||';'||   -- P1 16        BRANCO
       RPAD(' ', 12)||';'||   -- P1 14        BRANCO
       RPAD(' ', 12)||';'||   -- P1 50.20     BRANCO
       RPAD(' ', 19)||';'||   -- P1 50.21     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.34     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.35     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.36     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.37     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.47     BRANCO
       RPAD(' ', 7)||';'||   -- P1 21.48     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.49     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.50     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.51     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.52     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.53     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.54     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.44     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.45     BRANCO
       RPAD(NVL(P1_21_46,' '),1)||';'||   -- P1 21.46     EXATO
       RPAD(' ', 1)||';'||   -- P1 21.38     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.39     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.40     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.41     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.42     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.43     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.56     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.57     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.58     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.59     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.60     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.61     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.62     BRANCO
       RPAD(' ', 19)||';'||   -- P1 21.63     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.64     BRANCO
       RPAD(' ', 50)||';'||   -- P1 21.65     REGRA
       RPAD(' ', 1)||';'||   -- P1 21.66     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.67     BRANCO
       RPAD(NVL(P1_21_68,' '),1)||';'||   -- P1 21.68     EXATO
       RPAD(NVL(P1_21_55,' '),12)||';'||   -- P1 21.55     EXATO
       RPAD('N',1)||';'||   -- P1 21.69     EXATO
       RPAD(' ', 20)||';'||   -- P1 21.89     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.90     BRANCO
       RPAD(NVL(P1_8_13,' '),1)||';'||   -- P1 8.13      EXATO
       RPAD(' ', 40)||';'||   -- P1 21.71     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.72     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.73     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.74     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.75     BRANCO
       RPAD(' ', 40)||';'||   -- P1 21.76     BRANCO
       RPAD(' ', 11)||';'||   -- P1 21.77     BRANCO
       RPAD(' ', 12)||';'||   -- P1 21.78     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.94     BRANCO
       RPAD(' ', 2)||';'||   -- P1 21.95     BRANCO
       RPAD(' ', 1)||';'||   -- P1 21.79     BRANCO
       RPAD(NVL(P1_21_80,' '),3)||';'||   -- P1 21.80     EXATO
       RPAD(' ', 10)||';'||   -- P1 21.81     BRANCO
       RPAD(' ', 10)||';'||   -- P1 21.82     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.83     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.84     BRANCO
       RPAD(' ', 15)||';'||   -- P1 21.85     BRANCO
       RPAD(NVL(P1_21_86,' '),1)||';'||   -- P1 21.86     EXATO
       RPAD(NVL(P1_21_87,' '),1)||';'||   -- P1 21.87     EXATO
       RPAD(NVL(P1_21_88,' '),1)||';'||   -- P1 21.88     EXATO
       RPAD(' ', 19)||';'||   -- P1 21.91     BRANCO
       RPAD(' ', 3)||';'||   -- P1 21.92     BRANCO
       RPAD(' ', 5)||';'||   -- P1 21.93     BRANCO
       RPAD(' ', 20)||';'||   -- P1 31.51     BRANCO
       RPAD(' ', 19)||';'||   -- P1 31.52     BRANCO
       RPAD(' ', 3)||';'||   -- P1 31.53     BRANCO
       RPAD(NVL(TO_CHAR(P1_1001,'YYYYMMDD'),' '), 8)||';'||   -- P1 1001      NOVO
       RPAD(NVL(TO_CHAR(P1_1002,'YYYYMMDD'),' '), 8)||';'||   -- P1 1002      NOVO
       RPAD(NVL(P1_22_222,' '), 1)||';'||   -- P1 22.222    NOVO
       RPAD(NVL(P1_24_22_1,' '), 1)||';'||   -- P1 24.22.1   NOVO
       RPAD(NVL(P1_600,' '), 1)||';'||   -- P1 600       NOVO
       RPAD(NVL(P1_601,' '), 1)||';'||   -- P1 601       NOVO
       RPAD(NVL(P1_602,' '), 1)||';'||   -- P1 602       NOVO
       CASE WHEN P1_603 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_603) END||';'||   -- P1 603       NOVO
       RPAD(NVL(P1_603_1,' '), 3)||';'||   -- P1 603.1     NOVO
       CASE WHEN P1_604 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_604) END||';'||   -- P1 604       NOVO
       RPAD(NVL(P1_604_1,' '), 3)||';'||   -- P1 604.1     NOVO
       CASE WHEN P1_605 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_605) END||';'||   -- P1 605       NOVO
       RPAD(NVL(P1_605_1,' '), 3)||';'||   -- P1 605.1     NOVO
       RPAD(NVL(P1_606,' '), 40)||';'||   -- P1 606       NOVO
       RPAD(NVL(P1_607,' '), 1)||';'||   -- P1 607       NOVO
       CASE WHEN P1_608 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_608) END||';'||   -- P1 608       NOVO
       RPAD(NVL(P1_608_1,' '), 3)||';'||   -- P1 608.1     NOVO
       RPAD(NVL(TO_CHAR(P1_609,'YYYYMMDD'),' '), 8)||';'||   -- P1 609       NOVO
       CASE WHEN P1_610 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_610) END||';'||   -- P1 610       NOVO
       RPAD(NVL(P1_610_1,' '), 3)||';'||   -- P1 610.1     NOVO
       RPAD(NVL(TO_CHAR(P1_611,'YYYYMMDD'),' '), 8)||';'||   -- P1 611       NOVO
       CASE WHEN P1_612 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_612) END||';'||   -- P1 612       NOVO
       RPAD(NVL(P1_612_1,' '), 3)||';'||   -- P1 612.1     NOVO
       RPAD(NVL(P1_613,' '), 1)||';'||   -- P1 613       NOVO
       CASE WHEN P1_614 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_614) END||';'||   -- P1 614       NOVO
       RPAD(NVL(P1_614_1,' '), 3)||';'||   -- P1 614.1     NOVO
       LPAD(NVL(TO_CHAR(P1_615),' '), 6)||';'||   -- P1 615       NOVO
       RPAD(NVL(P1_616,' '), 1)||';'||   -- P1 616       NOVO
       RPAD(NVL(P1_617,' '), 1)||';'||   -- P1 617       NOVO
       RPAD(NVL(P1_618,' '), 1)||';'||   -- P1 618       NOVO
       CASE WHEN P1_619 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_619) END||';'||   -- P1 619       NOVO
       RPAD(NVL(P1_620,' '), 1)||';'||   -- P1 620       NOVO
       RPAD(NVL(P1_635,' '), 1)||';'||   -- P1 635       NOVO
       RPAD(NVL(P1_622,' '), 1)||';'||   -- P1 622       NOVO
       RPAD(NVL(P1_623,' '), 40)||';'||   -- P1 623       NOVO
       CASE WHEN P1_624 IS NULL THEN RPAD(' ', 15) ELSE pack_utilitaire.f_format_taux_15(P1_624) END||';'||   -- P1 624       NOVO
       RPAD(NVL(P1_625,' '), 2)||';'||   -- P1 625       NOVO
       RPAD(NVL(P1_626,' '), 1)||';'||   -- P1 626       NOVO
       RPAD(NVL(P1_627,' '), 1)||';'||   -- P1 627       NOVO
       CASE WHEN P1_628 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_628) END||';'||   -- P1 628       NOVO
       RPAD(NVL(P1_628_1,' '), 3)||';'||   -- P1 628.1     NOVO
       RPAD(NVL(P1_629,' '), 1)||';'||   -- P1 629       NOVO
       CASE WHEN P1_630 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_630) END||';'||   -- P1 630       NOVO
       RPAD(NVL(P1_630_1,' '), 3)||';'||   -- P1 630.1     NOVO
       CASE WHEN P1_631 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_631) END||';'||   -- P1 631       NOVO
       RPAD(NVL(P1_631_1,' '), 3)||';'||   -- P1 631.1     NOVO
       CASE WHEN P1_632 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_632) END||';'||   -- P1 632       NOVO
       RPAD(NVL(P1_632_1,' '), 3)||';'||   -- P1 632.1     NOVO
       CASE WHEN P1_633 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant(P1_633) END||';'||   -- P1 633       NOVO
       RPAD(NVL(P1_633_1,' '), 3)||';'||   -- P1 633.1     NOVO
       RPAD(NVL(P1_621,' '), 8)||';'||   -- P1 621       NOVO
       RPAD(' ', 1176)     -- P1 99.99     FILLER
     AS VARCHAR2(3999)) as lignedetail2
  from ENG_CORP_P1_BIS
 where NO_VARIANTE = 8
   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')
 order by NO_VARIANTE;

 




 
 

------------------------------------------------------------------------------------------------------------------------
-- N13: a partir de P_UTLF_P9_EQU101             
------------------------------------------------------------------------------------------------------------------------
select
		RPAD(TO_CHAR(C_ENR.DT_ARRETE,'YYYYMMDD'),8,' ')||
		RPAD(TO_CHAR(C_ENR.CD_CONSO_CPT),5,' ')||
		RPAD('C_DDR',12,' ')||     -- 18/02/2019 - CDS ATOS (GBD) - US731  - a remplacer ? (si oui maj RG d'alim)
		'M'||
		:MASYSDATE||
		'P9'||
		RPAD(' ',1)||
		RPAD(' ',2)||
		RPAD(' ',7)||
		RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||
		--RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '),10,' ')||
		RPAD(' ', 10)||
		RPAD(NVL(C_ENR.ID_AUTORISATION,' '),30,' ')||
		RPAD(NVL(C_ENR.ID_LIGNE_DET,' '),30,' ')||
		RPAD(' ',40)||
        CASE WHEN C_ENR.CD_PERIM_PROV= 'P' THEN RPAD(C_ENR.ID_ENGAGEMENT,40) ELSE RPAD(' ', 40) END || --P9 1.11 :: M72074
        CASE WHEN C_ENR.CD_PERIM_PROV= 'T' THEN RPAD(C_ENR.ID_PROVISION,40) ELSE RPAD(' ', 40) END ||  --P9 1.16 :: M72074
    -- Les champs 1.11 et 1.16 ont pas la mÍme regle d'alimentation que dans la table  provisions_decotes_p9 
		RPAD(' ',20)||
		RPAD(NVL(C_ENR.CD_NAT_DEPRE,' '),1,' ')||
		RPAD(NVL(C_ENR.CD_PERIM_PROV,' '),1,' ')||
		RPAD(' ',12)||
		--09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		RPAD(' ',1)||
		RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
		RPAD(' ',13)||
		--Fin EMM
		pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_CRD),0))||
		pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PROVISION_TRIM_CRD),0))||
		RPAD(NVL(C_ENR.CD_DEVISE,' '),3,' ')||
		RPAD(NVL(C_ENR.CD_PCCO_CRD,' '),12,' ')||
		--09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		-- Debut section 4 -COMPLEMENT DONNEES CLE DE REFERENCE
		RPAD(COALESCE(C_ENR.APPLI_SOURCE,'C_BTR'), 20)|| -- 16/11/2022 - Mantis 64443 - Correction du Score 7 P9 1.20
		RPAD(' ',5)||
		RPAD(' ',30)||
		RPAD(NVL(C_ENR.CD_DEVISE,' '),3,' ')|| -- 50 donnees comptables
		RPAD(NVL(C_ENR.CD_PCCO_CRD,' '),12,' ')||
		pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_PROVISION_CRD) ||
		RPAD(' ',12)||
		RPAD(' ',19)||
		LPAD(' ', 3512)   --4000 - 488
		as lignedetail1,  -- debut ligne (taille <= 4000)
		-- (compter 1 blanc de separation entre les 2 champs dans le spool)
		LPAD(' ', 1098)   -- fin de ligne -- Mantis 11841 
		as lignedetail2
		--fin EMM
FROM PROVISIONS_DECOTES_P9   C_ENR
WHERE 1 =1
  AND FLAG_HN      = 'O'
  AND A_EXTRAIRE   ='O'
  and (cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
  AND CD_TYPE_RISQUE IN ('EQU101')
;

------------------------------------------------------------------------------------------------------------------------
-- ENQUEUE : ecrite dans shell
------------------------------------------------------------------------------------------------------------------------

spool off;





