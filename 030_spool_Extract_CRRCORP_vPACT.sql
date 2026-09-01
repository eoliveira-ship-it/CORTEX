-- =====================================================================
-- 030_spool_Extract_CRRCORP_vPACT.sql          (SIRL-1224)
--
-- Versao vPACT do 030_spool_Extract_CRRCORP.sql : o pave P1 deixa de ser
-- calculado aqui. As regras de negocio passaram para a procedure
-- pack_alim_tab_envoi_crrv4.P_ALIM_ENG_CORP_P1_BIS, que alimenta a
-- tabela ENG_CORP_P1_BIS. Aqui fica so a formatacao.
--
-- Os 8 select sobre ENG_CORP_P1 dao lugar a 2 select sobre a tabela, um
-- por perimetro, cada um no lugar do bloco que substitui. Sao dois e nao
-- um porque o ficheiro traz hoje as variantes 1-3 antes dos paves
-- P2/M1/P9 e as 4-8 depois: mantendo os dois lugares, e mantendo o
-- ORDER BY NO_VARIANTE dentro de cada um, o ficheiro sai na mesma ordem
-- e a nao-regressao e um diff simples.
--
-- Os restantes paves (C1/C5, P2, M1, P9) ficam exatamente como estavam.
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
-- Notice        : CRRCV4.4_Grande ClientÃ¨le_Corporate_V44.02.xlsx            --
--------------------------------------------------------------------------------
-- Creation      : le 18/05/2021 par DUGUET MARC                              --
-- Modifications :                                                            --
--------------------------------------------------------------------------------
-- 18/03/2026 MESQUIPE: SIRL-500 - [QDD BÃ¢le 4] Absence mnt acquisition dans  --
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

select ( champ1 || champ2 ) as lignedetail1 from table : lignedetail1 limitÃ¯Â¿Â½ a 4000 car 
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
--SET linesize 4201   --4201  mais requete SQL limite Ã¯Â¿Â½ 4000 !
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
-- Ã¯Â¿Â½01: a partir de P_UTLF_TIERS_C1 
-- 2 select 
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Ã¯Â¿Â½01a: a partir de C_C1 
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
       RPAD(NVL(translate(upper(C_ENR.NOM_TIERS), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 40)||
       --RPAD(NVL(translate(upper(C_ENR.RAISON_SOCLE), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 90)||
       TO_CHAR(nvl(C_ENR.DT_REVISION_NOTE,sysdate),'YYYYMMDDHH24MISS')|| -- a modifier
-- 29/05/2018 CDS Atos (JMP) ANACREDIT  US346 
-- Remplacement de la zone libre de 76 blancs par :
-- * 25 Blancs destinÃ¯Â¿Â½s Ã¯Â¿Â½ C 14.30 Ã¯Â¿Â½ C 14.34 dans les US a venir,
-- * Le nombre de salariÃ¯Â¿Â½s sur 6 chiffres,
-- * Puis 45 Blancs.
       --07/01/2019 CDS Atos (SQN) US 615
--       RPAD(' ',76)||
--       RPAD(' ',25)|| On split le 25 en 10+1+5+1+8 pour C 14.30 Ã¯Â¿Â½ C 14.34
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
       RPAD(NVL(translate(upper(C_ENR.ADRESSE), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 70)||
       RPAD(NVL(translate(upper(C_ENR.VILLE), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 30)||
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
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.23	Date d'entrÃ©e en Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.24	Date de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_WL_CASA  , ' '), 2)||--C1 4.25	Motif d'entrÃ©e en Watch List
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
       RPAD(NVL(translate(upper(NVL(C_ENR.RAIS_SOCL_KBIS,C_ENR.RAISON_SOCLE)), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 114)||
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
-- Ã¯Â¿Â½01b: a partir de C_C2 
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
       RPAD(NVL(translate(upper(C_ENR.NOM_TIERS), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 40)||
       --RPAD(NVL(translate(upper(C_ENR.RAISON_SOCLE), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 90)||
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
       RPAD(NVL(translate(upper(C_ENR.ADRESSE), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 70)||
       RPAD(NVL(translate(upper(C_ENR.VILLE), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 30)||
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
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.23	Date d'entrÃ©e en Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.24	Date de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_WL_CASA  , ' '), 2)||--C1 4.25	Motif d'entrÃ©e en Watch List
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
       RPAD(NVL(translate(upper(NVL(C_ENR.RAIS_SOCL_KBIS,C_ENR.RAISON_SOCLE)), 'ÃÃÃÃÃÃÃÃÃÃÃÃÃÃ', 'AACEEEEIIOOUUU'), ' '), 114)||
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
-- Ã¯Â¿Â½02: a partir de P_UTLF_AUTORISATION_F1     
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
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20)|| --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'SystÃÂ¨me de gestion source'
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
-- Ã¯Â¿Â½03: a partir de P_UTLF_AUTORISATION_DETAIL_F2
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
       --28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur erronÃ¯Â¿Â½ pour P2 et F2
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
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20)||--KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'SystÃÂ¨me de gestion source'
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
-- PAVE P1 - perimetre NAT02 (substitui os select E04a/E04b/E04c)
------------------------------------------------------------------------------------------------------------------------
select
       to_char(P1_H_0_1, 'YYYYMMDD')||   -- pos 0     P1_H_0_1
       RPAD(NVL(P1_H_0_2,' '), 5)||   -- pos 8     P1_H_0_2
       RPAD(NVL(P1_H_0_3,'C_BTR'), 12)||   -- pos 13    P1_H_0_3
       'M'||   -- pos 25   
       :MASYSDATE||   -- pos 26   
       'P1'||   -- pos 38   
       RPAD(' ', 10)||   -- pos 40   
       RPAD(NVL(P1_H_1_1, ' '), 20)||   -- pos 50    P1_H_1_1
       RPAD(' ', 10)||   -- pos 70   
       RPAD(NVL(P1_H_1_4, ' '), 30)||   -- pos 80    P1_H_1_4
       RPAD(NVL(P1_H_1_6, ' '), 30)||   -- pos 110   P1_H_1_6
       RPAD(' ', 40)||   -- pos 140  
       RPAD(P1_H_1_11,40)||   -- pos 180   P1_H_1_11
       RPAD(' ', 40)||   -- pos 220  
       RPAD(' ', 20)||   -- pos 260  
       RPAD(P1_1_1,7)||   -- pos 280   P1_1_1
       RPAD(P1_1_2,2)||   -- pos 287   P1_1_2
       'Y'||   -- pos 289  
       RPAD(P1_2_0,6)||   -- pos 290   P1_2_0
       NVL(P1_2_4,'B')||   -- pos 296   P1_2_4
       RPAD(P1_2_6,5)||   -- pos 297   P1_2_6
       RPAD(P1_2_18,3)||   -- pos 302   P1_2_18
       RPAD(nvl(P1_2_29, 'NA020'),12)||   -- pos 305   P1_2_29
       RPAD(NVL(TO_CHAR(P1_3_2, 'YYYYMMDD'), ' '), 8)||   -- pos 317   P1_3_2
       NVL(TO_CHAR(P1_3_4, 'YYYYMMDD'),'99990630')||   -- pos 325   P1_3_4
       RPAD(' ', 10)||   -- pos 333  
       pack_utilitaire.F_FORMAT_TAUX(P1_18_1)||   -- pos 343   P1_18_1
       pack_utilitaire.F_FORMAT_TAUX(P1_18_10)||   -- pos 353   P1_18_10
       pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((P1_18_5),0) <0 THEN 0 ELSE nvl((P1_18_5),0)END )||   -- pos 363   P1_18_5
       RPAD(NVL(P1_18_17, ' '), 3)||   -- pos 382   P1_18_17
       RPAD(NVL(P1_18_18, ' '), 3)||   -- pos 385   P1_18_18
       RPAD(' ', 50)||   -- pos 388  
       RPAD(' ', 2)||   -- pos 438  
       RPAD(NVL(TO_CHAR(P1_21_2, 'YYYYMMDD'), ' '), 8)||   -- pos 440   P1_21_2
       P1_5_5||   -- pos 448   P1_5_5
       P1_4_1||   -- pos 449   P1_4_1
       P1_5_2||   -- pos 450   P1_5_2
       NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))||   -- pos 451   explicita
       RPAD(' ',1)||   -- pos 459  
       RPAD(' ',16)||   -- pos 460  
       RPAD(' ',2)||   -- pos 476  
       RPAD(P1_4_3, 3)||   -- pos 478   P1_4_3
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 22)
            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4)||RPAD(P1_4_5, 3) END||   -- pos 481   composta
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_9),0))||   -- pos 503   P1_4_9
       RPAD(NVL(P1_4_13, ' '), 3)||   -- pos 522   P1_4_13
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 22)
            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14)||RPAD(P1_4_15, 3) END||   -- pos 525   composta
       RPAD (' ', 22)||   -- pos 547  
       RPAD (nvl(P1_4_18,' '), 12)||   -- pos 569   P1_4_18
       CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END||   -- pos 581   explicita
       RPAD(NVL(P1_4_7, ' '), 3)||   -- pos 600   P1_4_7
       RPAD(NVL(P1_4_19, ' '), 12)||   -- pos 603   P1_4_19
       RPAD (' ', 10)||   -- pos 615  
       CASE WHEN P1_4_21 IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((P1_4_21),0)) END||   -- pos 625   P1_4_21
       CASE WHEN P1_4_22 IS null THEN RPAD (' ', 3) ELSE 'EUR' END||   -- pos 644   P1_4_22
       RPAD (nvl(P1_4_23, 'CL'),2)||   -- pos 647   P1_4_23
       RPAD (' ', 61)||   -- pos 649  
       NVL(P1_3_46,' ')||   -- pos 710   P1_3_46
       NVL(P1_3_47, ' ')||   -- pos 711   P1_3_47
       CASE WHEN P1_3_40 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_3_40) END||   -- pos 712   explicita
       RPAD(NVL(P1_3_41, ' '), 3)||   -- pos 731   explicita
       CASE WHEN P1_3_42 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_3_42) END||   -- pos 734   explicita
       RPAD(NVL(P1_3_43, ' '), 3)||   -- pos 753   explicita
       RPAD(nvl(P1_3_44, ' '), 2,' ')||   -- pos 756   P1_3_44
       P1_3_45||   -- pos 758   P1_3_45
       Case when nvl(P1_5_19,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((P1_5_19),0)) else pack_utilitaire.f_format_montant_bis2(0) END||   -- pos 759   P1_5_19
       RPAD(nvl(P1_5_20,'EUR'),3)||   -- pos 778   P1_5_20
       RPAD(nvl(P1_19_5,' '),3)||   -- pos 781   P1_19_5
       RPAD(' ', 185)||   -- pos 784  
       RPAD(NVL(P1_2_99,' '), 20)||   -- pos 969   P1_2_99
       RPAD(' ', 354)||   -- pos 989  
       RPAD(' ', 1)||   -- pos 1343 
       RPAD(' ', 1)||   -- pos 1344 
       RPAD(' ', 1)||   -- pos 1345 
       RPAD(' ', 2)||   -- pos 1346 
       RPAD(' ', 3)||   -- pos 1348 
       RPAD(P1_4_31, 1,' ')||   -- pos 1351  P1_4_31
       RPAD (' ', 38)||   -- pos 1352 
       RPAD(' ', 1)||   -- pos 1390 
       RPAD(' ', 4)||   -- pos 1391 
       RPAD (' ', 24)||   -- pos 1395 
       Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(P1_3_20,0)) ,4,6)||   -- pos 1419  P1_3_20
       NVL(P1_4_8,'B')||   -- pos 1425  P1_4_8
       RPAD (' ', 5)||   -- pos 1426 
       RPAD(nvl(P1_4_42,' '),6,' ')||   -- pos 1431  P1_4_42
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8)||   -- pos 1437  P1_3_3
       RPAD (' ', 7)||   -- pos 1445 
       RPAD(NVL(TO_CHAR(P1_4_47, 'YYYYMMDD'), ' '), 8)||   -- pos 1452  P1_4_47
       RPAD (' ', 1)||   -- pos 1460 
       RPAD (' ', 60)||   -- pos 1461 
       RPAD (' ', 74)||   -- pos 1521 
       P1_4_29||   -- pos 1595  P1_4_29
       RPAD (' ', 3)||   -- pos 1596 
       RPAD (' ', 1)||   -- pos 1599 
       RPAD (' ', 1)||   -- pos 1600 
       RPAD (' ', 45)||   -- pos 1601 
       RPAD (' ', 10)||   -- pos 1646 
       RPAD (' ', 35)||   -- pos 1656 
       RPAD (' ', 466)||   -- pos 1691 
       RPAD(nvl(P1_21_3,' '),1)||   -- pos 2157  P1_21_3
       RPAD(nvl(P1_21_4,' '),1)||   -- pos 2158  P1_21_4
       RPAD(nvl(P1_21_5,' '),1)||   -- pos 2159  P1_21_5
       RPAD(nvl(P1_21_6,' '),2)||   -- pos 2160  P1_21_6
       RPAD (NVL(TO_CHAR(P1_21_7, 'YYYYMMDD'), ' '), 8)||   -- pos 2162  P1_21_7
       RPAD(NVL(TO_CHAR(P1_21_8, 'YYYYMMDD'), ' '), 8)||   -- pos 2170  P1_21_8
       RPAD(NVL(TO_CHAR(P1_21_9, 'YYYYMMDD'), ' '), 8)||   -- pos 2178  P1_21_9
       RPAD(NVL(TO_CHAR(P1_21_10, 'YYYYMMDD'), ' '), 8)||   -- pos 2186  P1_21_10
       RPAD(NVL(TO_CHAR(P1_21_11, 'YYYYMMDD'), ' '), 8)||   -- pos 2194  P1_21_11
       RPAD(NVL(TO_CHAR(P1_21_12, 'YYYYMMDD'), ' '), 8)||   -- pos 2202  P1_21_12
       RPAD(NVL(TO_CHAR(P1_21_13, 'YYYYMMDD'), ' '), 8)||   -- pos 2210  P1_21_13
       RPAD(NVL(TO_CHAR(P1_21_14, 'YYYYMMDD'), ' '), 8)||   -- pos 2218  P1_21_14
       RPAD(NVL(TO_CHAR(P1_21_15, 'YYYYMMDD'), ' '), 8)||   -- pos 2226  P1_21_15
       RPAD(NVL(TO_CHAR(P1_21_16, 'YYYYMMDD'), ' '), 8)||   -- pos 2234  P1_21_16
       RPAD (' ', 2)||   -- pos 2242 
       RPAD (' ', 2)||   -- pos 2244 
       RPAD (' ', 2)||   -- pos 2246 
       RPAD (' ', 2)||   -- pos 2248 
       RPAD(nvl(P1_22_56,' '),3)||   -- pos 2250  P1_22_56
       RPAD(nvl(P1_22_57,' '),1)||   -- pos 2253  P1_22_57
       RPAD(nvl(P1_22_1,' '),40)||   -- pos 2254  P1_22_1
       RPAD(nvl(P1_22_51,' '),40)||   -- pos 2294  P1_22_51
       RPAD (' ', 45)||   -- pos 2334 
       RPAD(nvl(P1_22_5, 'ND'),2)||   -- pos 2379  P1_22_5
       RPAD(nvl(P1_22_52,' '),10)||   -- pos 2381  P1_22_52
       RPAD(nvl(P1_22_6,' '),2,' ')||   -- pos 2391  P1_22_6
       RPAD(nvl(P1_22_53,' '),2)||   -- pos 2393  P1_22_53
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||   -- pos 2395  P1_22_54
       CASE WHEN P1_22_55 = 'C3' THEN '999' ELSE RPAD(upper(nvl(P1_22_55,' ')),3) END||   -- pos 2441  P1_22_55
       RPAD(nvl(P1_22_7,'97'),2)||   -- pos 2444  P1_22_7
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||   -- pos 2446  P1_22_8
       RPAD(nvl(P1_22_9, 'EUR'), 3)||   -- pos 2465  P1_22_9
       RPAD(nvl(P1_22_12,' '),1)||   -- pos 2468  P1_22_12
       pack_utilitaire.F_FORMAT_TAUX(P1_22_13)||   -- pos 2469  P1_22_13
       RPAD(nvl(P1_22_14,' '),1)||   -- pos 2479  P1_22_14
       RPAD(nvl(P1_22_15,' '),12)||   -- pos 2480  P1_22_15
       RPAD(nvl(P1_22_16,' '),1)||   -- pos 2492  P1_22_16
       RPAD(nvl(P1_22_17,' '),1)||   -- pos 2493  P1_22_17
       RPAD(nvl(P1_22_18,' '),1)||   -- pos 2494  P1_22_18
       pack_utilitaire.F_FORMAT_TAUX(P1_22_19)||   -- pos 2495  P1_22_19
       RPAD(nvl(P1_22_20,' '),1)||   -- pos 2505  P1_22_20
       RPAD(NVL(TO_CHAR(P1_22_21, 'YYYYMMDD'), ' '), 8)||   -- pos 2506  P1_22_21
       RPAD(NVL(TO_CHAR(P1_22_22, 'YYYYMMDD'), ' '), 8)||   -- pos 2514  P1_22_22
       pack_utilitaire.F_FORMAT_TAUX(P1_22_23)||   -- pos 2522  P1_22_23
       pack_utilitaire.F_FORMAT_TAUX(P1_22_24)||   -- pos 2532  P1_22_24
       RPAD(nvl(P1_22_25,' '),1)||   -- pos 2542  P1_22_25
       LPAD(nvl((P1_22_26),0),3,0)||   -- pos 2543  P1_22_26
       pack_utilitaire.F_FORMAT_TAUX(P1_22_27)||   -- pos 2546  P1_22_27
       pack_utilitaire.F_FORMAT_TAUX(P1_22_28)||   -- pos 2556  P1_22_28
       pack_utilitaire.F_FORMAT_TAUX(P1_22_29)||   -- pos 2566  P1_22_29
       RPAD(nvl(P1_22_30,' '),7)||   -- pos 2576  P1_22_30
       RPAD(NVL(TO_CHAR(P1_22_31, 'YYYYMMDD'), ' '), 8)||   -- pos 2583  P1_22_31
       case when P1_22_32 is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(P1_22_32) end||   -- pos 2591  P1_22_32
       RPAD(nvl(P1_22_33,'EUR'),3)||   -- pos 2610  P1_22_33
       pack_utilitaire.F_FORMAT_MONTANT_BIS2( P1_22_34)||   -- pos 2613  P1_22_34
       RPAD(nvl(P1_22_35,' '),3)||   -- pos 2632  P1_22_35
       RPAD(NVL(P1_22_36,' '),1,' ')||   -- pos 2635  P1_22_36
       RPAD(NVL(TO_CHAR(P1_22_37, 'YYYYMMDD'), ' '), 8)||   -- pos 2636  P1_22_37
       RPAD(NVL(TO_CHAR(P1_22_38, 'YYYYMMDD'), ' '), 8)||   -- pos 2644  P1_22_38
       RPAD(' ', 19)||   -- pos 2652 
       RPAD(' ', 3)||   -- pos 2671 
       RPAD(' ', 8)||   -- pos 2674 
       RPAD(' ', 10)||   -- pos 2682 
       RPAD(' ', 10)||   -- pos 2692 
       pack_utilitaire.f_format_montant_bis2(nvl((P1_22_44),0))||   -- pos 2702  P1_22_44
       RPAD('EUR', 3)||   -- pos 2721 
       RPAD(' ', 8)||   -- pos 2724 
       RPAD(' ', 19)||   -- pos 2732 
       RPAD(' ', 3)||   -- pos 2751 
       RPAD(' ', 10)||   -- pos 2754 
       RPAD(' ', 10)||   -- pos 2764 
       RPAD(NVL(TO_CHAR(P1_22_58, 'YYYYMMDD'), ' '), 8)||   -- pos 2774  P1_22_58
       RPAD(NVL(TO_CHAR(P1_22_59, 'YYYYMMDD'), ' '), 8)||   -- pos 2782  P1_22_59
       pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(P1_22_60)||   -- pos 2790  P1_22_60
       RPAD(nvl(P1_22_61,' '),3)||   -- pos 2809  P1_22_61
       RPAD(nvl(P1_22_62,' '),1)||   -- pos 2812  P1_22_62
       RPAD(NVL(TO_CHAR(P1_22_63,'YYYYMMDD'),' '), 8)||   -- pos 2813  P1_22_63
       RPAD (' ', 12)||   -- pos 2821 
       RPAD(nvl(P1_22_66, ' '), 2)||   -- pos 2833  P1_22_66
       RPAD(NVL(TO_CHAR(P1_22_67, 'YYYYMMDD'), ' '), 8)||   -- pos 2835  P1_22_67
       RPAD (' ', 3)||   -- pos 2843 
       LPAD(NVL(to_char(P1_22_70), ' '),5,'0')||   -- pos 2846  P1_22_70
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||   -- pos 2851  P1_22_71
       RPAD(nvl(P1_22_72,' '),2)||   -- pos 2854  P1_22_72
       RPAD (' ', 20)||   -- pos 2856 
       RPAD(nvl(P1_23_1,' '),1)||   -- pos 2876  P1_23_1
       RPAD(nvl(P1_23_2,' '),7)||   -- pos 2877  P1_23_2
       RPAD(nvl(P1_23_3,' '),20)||   -- pos 2884  P1_23_3
       RPAD(nvl(P1_23_4,' '),3)||   -- pos 2904  P1_23_4
       RPAD(nvl(P1_23_5,' '),3)||   -- pos 2907  P1_23_5
       RPAD(nvl(P1_23_6,' '),1)||   -- pos 2910  P1_23_6
       RPAD(NVL(P1_23_7, ' '), 40)||   -- pos 2911  explicita
       RPAD (' ', 10)||   -- pos 2951 
       RPAD (nvl(P1_23_8,' '), 12)||   -- pos 2961  P1_23_8
       RPAD (nvl(P1_23_9,' '), 12)||   -- pos 2973  P1_23_9
       RPAD (nvl(P1_23_10,' '), 12)||   -- pos 2985  P1_23_10
       RPAD (nvl(P1_23_11,' '), 12)||   -- pos 2997  P1_23_11
       RPAD (' ', 2)||   -- pos 3009 
       RPAD(NVL(P1_24_1,' '),1,' ')||   -- pos 3011  P1_24_1
       RPAD (' ', 471)||   -- pos 3012 
       RPAD (' ', 178)||   -- pos 3483 
       RPAD(NVL(P1_26_1,' '),1,' ')||   -- pos 3661  P1_26_1
       RPAD(NVL(P1_22_11, ' '), 1)||   -- pos 3662  P1_22_11
       RPAD(NVL(P1_26_3, ' '), 3)||   -- pos 3663  P1_26_3
       RPAD(NVL(P1_26_4, ' '), 3)||   -- pos 3666  P1_26_4
       RPAD (' ', 44)||   -- pos 3669 
       RPAD (' ', 22)||   -- pos 3713 
       RPAD(P1_27_3, 1)||   -- pos 3735  P1_27_3
       RPAD(NVL(P1_27_4, ' '), 2)||   -- pos 3736  P1_27_4
       RPAD (' ', 23)||   -- pos 3738 
       RPAD (nvl(P1_28_1,' '), 1)||   -- pos 3761  P1_28_1
       RPAD (' ', 1)||   -- pos 3762 
       pack_utilitaire.F_FORMAT_MONTANT_BIS3(P1_29_1)||   -- pos 3763  P1_29_1
       RPAD (nvl(P1_29_2,' '), 3)||   -- pos 3782  P1_29_2
       RPAD(' ',190)||   -- pos 3785 
       RPAD(' ',6)||   -- pos 3975 
       'N'||   -- pos 3981 
       RPAD (' ', 18)     -- pos 3982 
     as lignedetail1,
       RPAD (' ', 7)||   -- pos 4000 
       'N'||   -- pos 4007 
       RPAD (' ', 25)||   -- pos 4008 
       RPAD (' ', 1)||   -- pos 4033 
       RPAD (' ', 5)||   -- pos 4034 
       RPAD(NVL(P1_31_2, ' '), 40)||   -- pos 4039  P1_31_2
       RPAD(NVL(P1_31_3, ' '), 40)||   -- pos 4079  P1_31_3
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||   -- pos 4119  P1_31_4
       RPAD(NVL(P1_31_5, ' '), 1)||   -- pos 4138  P1_31_5
       RPAD (NVL(P1_31_6,'2'), 1)||   -- pos 4139  P1_31_6
       RPAD (' ', 6)||   -- pos 4140 
       RPAD (' ', 1)||   -- pos 4146 
       RPAD(NVL(P1_31_9, ' '),15,' ')||   -- pos 4147  P1_31_9
       RPAD(NVL(P1_31_10, ' '),2,' ')||   -- pos 4162  P1_31_10
       RPAD (' ', 1)||   -- pos 4164 
       RPAD (' ', 1)||   -- pos 4165 
       RPAD (' ', 1)||   -- pos 4166 
       RPAD (' ', 15)||   -- pos 4167 
       RPAD (' ', 19)||   -- pos 4182 
       RPAD (' ', 3)||   -- pos 4201 
       RPAD ('+', 1)||   -- pos 4204 
       LPAD(P1_31_17, 5, '0')||   -- pos 4205  explicita
       RPAD ('+', 1)||   -- pos 4210 
       LPAD(P1_31_18, 5, '0')||   -- pos 4211  explicita
       RPAD (' ', 6)||   -- pos 4216 
       RPAD (' ', 1)||   -- pos 4222 
       RPAD(NVL(P1_31_21,' '), 2)||   -- pos 4223  P1_31_21
       P1_31_22||   -- pos 4225  P1_31_22
       RPAD (' ', 19)||   -- pos 4227 
       RPAD (' ', 3)||   -- pos 4246 
       RPAD (' ', 15)||   -- pos 4249 
       RPAD (' ', 15)||   -- pos 4264 
       RPAD (' ', 15)||   -- pos 4279 
       RPAD (' ', 15)||   -- pos 4294 
       RPAD (' ', 15)||   -- pos 4309 
       RPAD(NVL(P1_31_37,' '),1)||   -- pos 4324  P1_31_37
       RPAD(' ',1)||   -- pos 4325 
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||   -- pos 4326  P1_29_3
       RPAD ('EUR', 3)||   -- pos 4345 
       RPAD (' ', 22)||   -- pos 4348 
       RPAD (' ', 19)||   -- pos 4370 
       RPAD (' ', 3)||   -- pos 4389 
       RPAD (' ', 28)||   -- pos 4392 
       RPAD (' ', 7)||   -- pos 4420 
       RPAD (' ', 2)||   -- pos 4427 
       RPAD (' ', 2)||   -- pos 4429 
       RPAD (' ', 2)||   -- pos 4431 
       RPAD (' ', 2)||   -- pos 4433 
       RPAD (' ', 19)||   -- pos 4435 
       RPAD (' ', 3)||   -- pos 4454 
       RPAD (' ', 19)||   -- pos 4457 
       RPAD (' ', 3)||   -- pos 4476 
       RPAD (' ', 19)||   -- pos 4479 
       RPAD (' ', 3)||   -- pos 4498 
       RPAD (' ', 19)||   -- pos 4501 
       RPAD (' ', 3)||   -- pos 4520 
       RPAD (' ', 19)||   -- pos 4523 
       RPAD (' ', 3)||   -- pos 4542 
       RPAD (' ', 19)||   -- pos 4545 
       RPAD (' ', 3)||   -- pos 4564 
       RPAD (' ', 19)||   -- pos 4567 
       RPAD (' ', 3)||   -- pos 4586 
       RPAD (' ', 2)||   -- pos 4589 
       RPAD (' ', 2)||   -- pos 4591 
       RPAD (' ', 2)||   -- pos 4593 
       RPAD (' ', 20)||   -- pos 4595 
       RPAD (' ', 10)||   -- pos 4615 
       RPAD (' ', 15)||   -- pos 4625 
       RPAD (' ', 19)||   -- pos 4640 
       RPAD (' ', 3)||   -- pos 4659 
       RPAD (' ', 19)||   -- pos 4662 
       RPAD (' ', 3)||   -- pos 4681 
       RPAD (' ', 19)||   -- pos 4684 
       RPAD (' ', 3)||   -- pos 4703 
       'EUR'||   -- pos 4706 
       RPAD(NVL(P1_50_2, ' '), 12)||   -- pos 4709  P1_50_2
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||   -- pos 4721  P1_50_3
       RPAD(' ',12)||   -- pos 4740 
       RPAD(' ',19)||   -- pos 4752 
       RPAD(NVL(P1_50_8, ' '), 12)||   -- pos 4771  P1_50_8
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||   -- pos 4783  P1_50_9
       RPAD(' ',12)||   -- pos 4802 
       RPAD(' ',19)||   -- pos 4814 
       RPAD(' ',12)||   -- pos 4833 
       RPAD(' ',19)||   -- pos 4845 
       RPAD(' ',12)||   -- pos 4864 
       RPAD(' ',19)||   -- pos 4876 
       RPAD(NVL(P1_21_22,' '),2)||   -- pos 4895  P1_21_22
       RPAD(NVL(TO_CHAR(P1_21_23, 'YYYYMMDD'), ' '),8)||   -- pos 4897  P1_21_23
       case when P1_21_29 is not null then '+'||LPAD(P1_21_29,5,'0') else RPAD(' ',6) end||   -- pos 4905  P1_21_29
       RPAD(NVL(P1_21_25,' '),2)||   -- pos 4911  P1_21_25
       RPAD(NVL(P1_21_26,' '),1)||   -- pos 4913  P1_21_26
       RPAD(NVL(P1_21_27,' '),1)||   -- pos 4914  P1_21_27
       RPAD(NVL(P1_21_28,' '),2)||   -- pos 4915  P1_21_28
       case when P1_21_30 is not null then RPAD(pack_utilitaire.f_format_montant_bis2(P1_21_30),19) else RPAD(' ',19) end||   -- pos 4917  P1_21_30
       RPAD(NVL(P1_21_31, ' '), 3)||   -- pos 4936  explicita
       RPAD(' ',15)||   -- pos 4939 
       RPAD(' ',3)||   -- pos 4954 
       RPAD(' ',12)||   -- pos 4957 
       RPAD(' ',12)||   -- pos 4969 
       RPAD(' ',12)||   -- pos 4981 
       RPAD(' ',12)||   -- pos 4993 
       RPAD(' ',19)||   -- pos 5005 
       RPAD(' ',1)||   -- pos 5024 
       RPAD(' ',1)||   -- pos 5025 
       RPAD(' ',19)||   -- pos 5026 
       RPAD(' ',3)||   -- pos 5045 
       RPAD(' ',10)||   -- pos 5048 
       RPAD(' ',7)||   -- pos 5058 
       RPAD(' ',19)||   -- pos 5065 
       RPAD(' ',3)||   -- pos 5084 
       RPAD(' ',19)||   -- pos 5087 
       RPAD(' ',3)||   -- pos 5106 
       RPAD(' ',19)||   -- pos 5109 
       RPAD(' ',3)||   -- pos 5128 
       RPAD(NVL(P1_21_44,' '),1)||   -- pos 5131  P1_21_44
       RPAD(NVL(P1_21_45,' '),1)||   -- pos 5132  P1_21_45
       RPAD(NVL(P1_21_46,' '),1)||   -- pos 5133  P1_21_46
       RPAD(NVL(P1_21_38,' '),1)||   -- pos 5134  P1_21_38
       RPAD(NVL(P1_21_39,' '),1)||   -- pos 5135  P1_21_39
       RPAD(NVL(P1_21_40,' '),1)||   -- pos 5136  P1_21_40
       RPAD(' ',1)||   -- pos 5137 
       RPAD(' ',1)||   -- pos 5138 
       RPAD(pack_utilitaire.F_FORMAT_TAUX_15(P1_21_43),15)||   -- pos 5139  P1_21_43
       RPAD(' ',1)||   -- pos 5154 
       RPAD(' ',1)||   -- pos 5155 
       RPAD(' ',1)||   -- pos 5156 
       RPAD(' ',1)||   -- pos 5157 
       RPAD(' ',15)||   -- pos 5158 
       RPAD(' ',10)||   -- pos 5173 
       RPAD(' ',10)||   -- pos 5183 
       RPAD(' ',19)||   -- pos 5193 
       RPAD(' ',3)||   -- pos 5212 
       RPAD(' ',5)||   -- pos 5215 
       RPAD(NVL(P1_21_66,' '),1)||   -- pos 5220  P1_21_66
       RPAD(' ',1)||   -- pos 5221 
       RPAD(NVL(P1_21_68,' '),1)||   -- pos 5222  P1_21_68
       RPAD(NVL(P1_21_55,' '),12)||   -- pos 5223  P1_21_55
       RPAD(NVL(P1_21_69,' '),1)||   -- pos 5235  P1_21_69
       RPAD(' ',20)||   -- pos 5236 
       RPAD(' ',10)||   -- pos 5256 
       RPAD(NVL(P1_8_13,' '),1)||   -- pos 5266  P1_8_13
       RPAD(NVL(P1_21_71,' '),40)||   -- pos 5267  P1_21_71
       RPAD(NVL(P1_21_72,' '),40)||   -- pos 5307  P1_21_72
       RPAD(NVL(P1_21_73,' '),40)||   -- pos 5347  P1_21_73
       RPAD(NVL(P1_21_74,' '),40)||   -- pos 5387  P1_21_74
       RPAD(NVL(P1_21_75,' '),40)||   -- pos 5427  P1_21_75
       RPAD(NVL(P1_21_76,' '),40)||   -- pos 5467  P1_21_76
       RPAD(NVL(P1_21_77,' '),11)||   -- pos 5507  P1_21_77
       RPAD(NVL(P1_21_78,' '),12)||   -- pos 5518  P1_21_78
       RPAD(' ',1)||   -- pos 5530 
       RPAD(' ',2)||   -- pos 5531 
       RPAD(' ',1)||   -- pos 5533 
       RPAD(NVL(P1_21_80,' '),3)||   -- pos 5534  P1_21_80
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_81),10)||   -- pos 5537  P1_21_81
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_82),10)||   -- pos 5547  P1_21_82
       RPAD(' ',15)||   -- pos 5557 
       RPAD(' ',15)||   -- pos 5572 
       RPAD(' ',15)||   -- pos 5587 
       RPAD(NVL(P1_21_86,' '),1)||   -- pos 5602  P1_21_86
       RPAD(NVL(P1_21_87,' '),1)||   -- pos 5603  P1_21_87
       RPAD(NVL(P1_21_88,' '),1)||   -- pos 5604  P1_21_88
       RPAD(' ',19)||   -- pos 5605 
       RPAD(' ',3)||   -- pos 5624 
       RPAD(' ',5)||   -- pos 5627 
       RPAD(' ',20)||   -- pos 5632 
       RPAD(' ',19)||   -- pos 5652 
       RPAD(' ',3)||   -- pos 5671 
       lPAD(' ', 24)     -- pos 5674 
     as lignedetail2
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
       RPAD(' ', 10)||    --taux pondÃ¯Â¿Â½ration baloise
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
    -- US 261 - KLx Risque (VDC) [CRRv4.3] Leasing - CRR Corporate - Score 7 'Montant des fonds remis ÃÂ  date '
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
	   pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_INIT_SURETE_SING_CTRT) || --M1 6.8 - BÃ¢le 4 - MR12731 
	   RPAD(' ', 19) || --M1 6.9
	   RPAD(' ', 3) || --M1 6.10
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20) ||--KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'SystÃÂ¨me de gestion source' --M1 1.40
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
    -- Les champs 1.11 et 1.16 ont pas la mÃªme regle d'alimentation que dans la table  provisions_decotes_p9 
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
    -- Les champs 1.11 et 1.16 ont pas la mÃªme regle d'alimentation que dans la table  provisions_decotes_p9  -- P9 1.16
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
    ELSE RPAD(' ', 40)                                                            -- La regle du spool n'est pas la mÃªme que la regle 
  END                                                                          ||    -- d'alimentation de la table provisions_decotes_p9 
  CASE WHEN C_ENR.CD_PERIM_PROV= 'T' THEN RPAD(C_ENR.ID_PROVISION,40)           -- 1.16  :: ID_PROVISION || M72074
    ELSE  RPAD(' ', 40)                                                         -- La regle du spool n'est pas la mÃªme que la regle
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
-- PAVE P1 - perimetre Hors NAT02 (substitui os 5 select E05a..E05e)
------------------------------------------------------------------------------------------------------------------------
select
       to_char(P1_H_0_1, 'YYYYMMDD')||   -- pos 0     P1_H_0_1
       RPAD(NVL(P1_H_0_2,' '), 5)||   -- pos 8     P1_H_0_2
       RPAD(NVL(P1_H_0_3,'C_BTR'), 12)||   -- pos 13    P1_H_0_3
       'M'||   -- pos 25   
       :MASYSDATE||   -- pos 26   
       'P1'||   -- pos 38   
       RPAD(' ', 10)||   -- pos 40   
       RPAD(NVL(P1_H_1_1, ' '), 20)||   -- pos 50    P1_H_1_1
       RPAD(' ', 10)||   -- pos 70   
       RPAD(NVL(P1_H_1_4, ' '), 30)||   -- pos 80    P1_H_1_4
       RPAD(NVL(P1_H_1_6, ' '), 30)||   -- pos 110   P1_H_1_6
       RPAD(' ', 40)||   -- pos 140  
       RPAD(P1_H_1_11,40)||   -- pos 180   P1_H_1_11
       RPAD(' ', 40)||   -- pos 220  
       RPAD(' ', 20)||   -- pos 260  
       RPAD(P1_1_1,7)||   -- pos 280   P1_1_1
       RPAD(P1_1_2,2)||   -- pos 287   P1_1_2
       'Y'||   -- pos 289  
       RPAD(P1_2_0,6)||   -- pos 290   P1_2_0
       NVL(P1_2_4,'B')||   -- pos 296   P1_2_4
       RPAD(P1_2_6,5)||   -- pos 297   P1_2_6
       RPAD(P1_2_18,3)||   -- pos 302   P1_2_18
       RPAD(nvl(P1_2_29, 'NA020'),12)||   -- pos 305   P1_2_29
       RPAD(NVL(TO_CHAR(P1_3_2, 'YYYYMMDD'), ' '), 8)||   -- pos 317   P1_3_2
       NVL(TO_CHAR(P1_3_4, 'YYYYMMDD'),'99990630')||   -- pos 325   P1_3_4
       RPAD(' ', 10)||   -- pos 333  
       pack_utilitaire.F_FORMAT_TAUX(P1_18_1)||   -- pos 343   P1_18_1
       pack_utilitaire.F_FORMAT_TAUX(P1_18_10)||   -- pos 353   P1_18_10
       pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((P1_18_5),0) <0 THEN 0 ELSE nvl((P1_18_5),0)END )||   -- pos 363   P1_18_5
       RPAD(NVL(P1_18_17, ' '), 3)||   -- pos 382   P1_18_17
       RPAD(NVL(P1_18_18, ' '), 3)||   -- pos 385   P1_18_18
       RPAD(' ', 50)||   -- pos 388  
       RPAD(' ', 2)||   -- pos 438  
       RPAD(NVL(TO_CHAR(P1_21_2, 'YYYYMMDD'), ' '), 8)||   -- pos 440   P1_21_2
       P1_5_5||   -- pos 448   P1_5_5
       P1_4_1||   -- pos 449   P1_4_1
       P1_5_2||   -- pos 450   P1_5_2
       NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))||   -- pos 451   explicita
       RPAD(' ',1)||   -- pos 459  
       RPAD(' ',16)||   -- pos 460  
       RPAD(' ',2)||   -- pos 476  
       RPAD(P1_4_3, 3)||   -- pos 478   P1_4_3
       CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 22)
            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4)||RPAD(P1_4_5, 3) END||   -- pos 481   composta
       pack_utilitaire.f_format_montant_bis2(nvl((P1_4_9),0))||   -- pos 503   P1_4_9
       RPAD(NVL(P1_4_13, ' '), 3)||   -- pos 522   P1_4_13
       CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 22)
            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14)||RPAD(P1_4_15, 3) END||   -- pos 525   composta
       RPAD (' ', 22)||   -- pos 547  
       RPAD (nvl(P1_4_18,' '), 12)||   -- pos 569   P1_4_18
       CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END||   -- pos 581   explicita
       RPAD(NVL(P1_4_7, ' '), 3)||   -- pos 600   P1_4_7
       RPAD(NVL(P1_4_19, ' '), 12)||   -- pos 603   P1_4_19
       RPAD (' ', 10)||   -- pos 615  
       CASE WHEN P1_4_21 IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((P1_4_21),0)) END||   -- pos 625   P1_4_21
       CASE WHEN P1_4_22 IS null THEN RPAD (' ', 3) ELSE 'EUR' END||   -- pos 644   P1_4_22
       RPAD (nvl(P1_4_23, 'CL'),2)||   -- pos 647   P1_4_23
       RPAD (' ', 61)||   -- pos 649  
       NVL(P1_3_46,' ')||   -- pos 710   P1_3_46
       NVL(P1_3_47, ' ')||   -- pos 711   P1_3_47
       CASE WHEN P1_3_40 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_3_40) END||   -- pos 712   explicita
       RPAD(NVL(P1_3_41, ' '), 3)||   -- pos 731   explicita
       CASE WHEN P1_3_42 IS NULL THEN RPAD(' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(P1_3_42) END||   -- pos 734   explicita
       RPAD(NVL(P1_3_43, ' '), 3)||   -- pos 753   explicita
       RPAD(nvl(P1_3_44, ' '), 2,' ')||   -- pos 756   P1_3_44
       P1_3_45||   -- pos 758   P1_3_45
       Case when nvl(P1_5_19,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((P1_5_19),0)) else pack_utilitaire.f_format_montant_bis2(0) END||   -- pos 759   P1_5_19
       RPAD(nvl(P1_5_20,'EUR'),3)||   -- pos 778   P1_5_20
       RPAD(nvl(P1_19_5,' '),3)||   -- pos 781   P1_19_5
       RPAD(' ', 185)||   -- pos 784  
       RPAD(NVL(P1_2_99,' '), 20)||   -- pos 969   P1_2_99
       RPAD(' ', 354)||   -- pos 989  
       RPAD(' ', 1)||   -- pos 1343 
       RPAD(' ', 1)||   -- pos 1344 
       RPAD(' ', 1)||   -- pos 1345 
       RPAD(' ', 2)||   -- pos 1346 
       RPAD(' ', 3)||   -- pos 1348 
       RPAD(P1_4_31, 1,' ')||   -- pos 1351  P1_4_31
       RPAD (' ', 38)||   -- pos 1352 
       RPAD(' ', 1)||   -- pos 1390 
       RPAD(' ', 4)||   -- pos 1391 
       RPAD (' ', 24)||   -- pos 1395 
       Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(P1_3_20,0)) ,4,6)||   -- pos 1419  P1_3_20
       NVL(P1_4_8,'B')||   -- pos 1425  P1_4_8
       RPAD (' ', 5)||   -- pos 1426 
       RPAD(nvl(P1_4_42,' '),6,' ')||   -- pos 1431  P1_4_42
       RPAD(nvl(TO_CHAR(P1_3_3, 'YYYYMMDD'),' '),8)||   -- pos 1437  P1_3_3
       RPAD (' ', 7)||   -- pos 1445 
       RPAD(NVL(TO_CHAR(P1_4_47, 'YYYYMMDD'), ' '), 8)||   -- pos 1452  P1_4_47
       RPAD (' ', 1)||   -- pos 1460 
       RPAD (' ', 60)||   -- pos 1461 
       RPAD (' ', 74)||   -- pos 1521 
       P1_4_29||   -- pos 1595  P1_4_29
       RPAD (' ', 3)||   -- pos 1596 
       RPAD (' ', 1)||   -- pos 1599 
       RPAD (' ', 1)||   -- pos 1600 
       RPAD (' ', 45)||   -- pos 1601 
       RPAD (' ', 10)||   -- pos 1646 
       RPAD (' ', 35)||   -- pos 1656 
       RPAD (' ', 466)||   -- pos 1691 
       RPAD(nvl(P1_21_3,' '),1)||   -- pos 2157  P1_21_3
       RPAD(nvl(P1_21_4,' '),1)||   -- pos 2158  P1_21_4
       RPAD(nvl(P1_21_5,' '),1)||   -- pos 2159  P1_21_5
       RPAD(nvl(P1_21_6,' '),2)||   -- pos 2160  P1_21_6
       RPAD (NVL(TO_CHAR(P1_21_7, 'YYYYMMDD'), ' '), 8)||   -- pos 2162  P1_21_7
       RPAD(NVL(TO_CHAR(P1_21_8, 'YYYYMMDD'), ' '), 8)||   -- pos 2170  P1_21_8
       RPAD(NVL(TO_CHAR(P1_21_9, 'YYYYMMDD'), ' '), 8)||   -- pos 2178  P1_21_9
       RPAD(NVL(TO_CHAR(P1_21_10, 'YYYYMMDD'), ' '), 8)||   -- pos 2186  P1_21_10
       RPAD(NVL(TO_CHAR(P1_21_11, 'YYYYMMDD'), ' '), 8)||   -- pos 2194  P1_21_11
       RPAD(NVL(TO_CHAR(P1_21_12, 'YYYYMMDD'), ' '), 8)||   -- pos 2202  P1_21_12
       RPAD(NVL(TO_CHAR(P1_21_13, 'YYYYMMDD'), ' '), 8)||   -- pos 2210  P1_21_13
       RPAD(NVL(TO_CHAR(P1_21_14, 'YYYYMMDD'), ' '), 8)||   -- pos 2218  P1_21_14
       RPAD(NVL(TO_CHAR(P1_21_15, 'YYYYMMDD'), ' '), 8)||   -- pos 2226  P1_21_15
       RPAD(NVL(TO_CHAR(P1_21_16, 'YYYYMMDD'), ' '), 8)||   -- pos 2234  P1_21_16
       RPAD (' ', 2)||   -- pos 2242 
       RPAD (' ', 2)||   -- pos 2244 
       RPAD (' ', 2)||   -- pos 2246 
       RPAD (' ', 2)||   -- pos 2248 
       RPAD(nvl(P1_22_56,' '),3)||   -- pos 2250  P1_22_56
       RPAD(nvl(P1_22_57,' '),1)||   -- pos 2253  P1_22_57
       RPAD(nvl(P1_22_1,' '),40)||   -- pos 2254  P1_22_1
       RPAD(nvl(P1_22_51,' '),40)||   -- pos 2294  P1_22_51
       RPAD (' ', 45)||   -- pos 2334 
       RPAD(nvl(P1_22_5, 'ND'),2)||   -- pos 2379  P1_22_5
       RPAD(nvl(P1_22_52,' '),10)||   -- pos 2381  P1_22_52
       RPAD(nvl(P1_22_6,' '),2,' ')||   -- pos 2391  P1_22_6
       RPAD(nvl(P1_22_53,' '),2)||   -- pos 2393  P1_22_53
       CASE WHEN P1_22_54 IS NULL THEN RPAD(' ',46) ELSE RPAD(nvl(rpad(P1_22_54,21)||'FR',' '),46) END||   -- pos 2395  P1_22_54
       CASE WHEN P1_22_55 = 'C3' THEN '999' ELSE RPAD(upper(nvl(P1_22_55,' ')),3) END||   -- pos 2441  P1_22_55
       RPAD(nvl(P1_22_7,'97'),2)||   -- pos 2444  P1_22_7
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(P1_22_8)||   -- pos 2446  P1_22_8
       RPAD(nvl(P1_22_9, 'EUR'), 3)||   -- pos 2465  P1_22_9
       RPAD(nvl(P1_22_12,' '),1)||   -- pos 2468  P1_22_12
       pack_utilitaire.F_FORMAT_TAUX(P1_22_13)||   -- pos 2469  P1_22_13
       RPAD(nvl(P1_22_14,' '),1)||   -- pos 2479  P1_22_14
       RPAD(nvl(P1_22_15,' '),12)||   -- pos 2480  P1_22_15
       RPAD(nvl(P1_22_16,' '),1)||   -- pos 2492  P1_22_16
       RPAD(nvl(P1_22_17,' '),1)||   -- pos 2493  P1_22_17
       RPAD(nvl(P1_22_18,' '),1)||   -- pos 2494  P1_22_18
       pack_utilitaire.F_FORMAT_TAUX(P1_22_19)||   -- pos 2495  P1_22_19
       RPAD(nvl(P1_22_20,' '),1)||   -- pos 2505  P1_22_20
       RPAD(NVL(TO_CHAR(P1_22_21, 'YYYYMMDD'), ' '), 8)||   -- pos 2506  P1_22_21
       RPAD(NVL(TO_CHAR(P1_22_22, 'YYYYMMDD'), ' '), 8)||   -- pos 2514  P1_22_22
       pack_utilitaire.F_FORMAT_TAUX(P1_22_23)||   -- pos 2522  P1_22_23
       pack_utilitaire.F_FORMAT_TAUX(P1_22_24)||   -- pos 2532  P1_22_24
       RPAD(nvl(P1_22_25,' '),1)||   -- pos 2542  P1_22_25
       LPAD(nvl((P1_22_26),0),3,0)||   -- pos 2543  P1_22_26
       pack_utilitaire.F_FORMAT_TAUX(P1_22_27)||   -- pos 2546  P1_22_27
       pack_utilitaire.F_FORMAT_TAUX(P1_22_28)||   -- pos 2556  P1_22_28
       pack_utilitaire.F_FORMAT_TAUX(P1_22_29)||   -- pos 2566  P1_22_29
       RPAD(nvl(P1_22_30,' '),7)||   -- pos 2576  P1_22_30
       RPAD(NVL(TO_CHAR(P1_22_31, 'YYYYMMDD'), ' '), 8)||   -- pos 2583  P1_22_31
       case when P1_22_32 is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(P1_22_32) end||   -- pos 2591  P1_22_32
       RPAD(nvl(P1_22_33,'EUR'),3)||   -- pos 2610  P1_22_33
       pack_utilitaire.F_FORMAT_MONTANT_BIS2( P1_22_34)||   -- pos 2613  P1_22_34
       RPAD(nvl(P1_22_35,' '),3)||   -- pos 2632  P1_22_35
       RPAD(NVL(P1_22_36,' '),1,' ')||   -- pos 2635  P1_22_36
       RPAD(NVL(TO_CHAR(P1_22_37, 'YYYYMMDD'), ' '), 8)||   -- pos 2636  P1_22_37
       RPAD(NVL(TO_CHAR(P1_22_38, 'YYYYMMDD'), ' '), 8)||   -- pos 2644  P1_22_38
       RPAD(' ', 19)||   -- pos 2652 
       RPAD(' ', 3)||   -- pos 2671 
       RPAD(' ', 8)||   -- pos 2674 
       RPAD(' ', 10)||   -- pos 2682 
       RPAD(' ', 10)||   -- pos 2692 
       pack_utilitaire.f_format_montant_bis2(nvl((P1_22_44),0))||   -- pos 2702  P1_22_44
       RPAD('EUR', 3)||   -- pos 2721 
       RPAD(' ', 8)||   -- pos 2724 
       RPAD(' ', 19)||   -- pos 2732 
       RPAD(' ', 3)||   -- pos 2751 
       RPAD(' ', 10)||   -- pos 2754 
       RPAD(' ', 10)||   -- pos 2764 
       RPAD(NVL(TO_CHAR(P1_22_58, 'YYYYMMDD'), ' '), 8)||   -- pos 2774  P1_22_58
       RPAD(NVL(TO_CHAR(P1_22_59, 'YYYYMMDD'), ' '), 8)||   -- pos 2782  P1_22_59
       pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(P1_22_60)||   -- pos 2790  P1_22_60
       RPAD(nvl(P1_22_61,' '),3)||   -- pos 2809  P1_22_61
       RPAD(nvl(P1_22_62,' '),1)||   -- pos 2812  P1_22_62
       RPAD(NVL(TO_CHAR(P1_22_63,'YYYYMMDD'),' '), 8)||   -- pos 2813  P1_22_63
       RPAD (' ', 12)||   -- pos 2821 
       RPAD(nvl(P1_22_66, ' '), 2)||   -- pos 2833  P1_22_66
       RPAD(NVL(TO_CHAR(P1_22_67, 'YYYYMMDD'), ' '), 8)||   -- pos 2835  P1_22_67
       RPAD (' ', 3)||   -- pos 2843 
       LPAD(NVL(to_char(P1_22_70), ' '),5,'0')||   -- pos 2846  P1_22_70
       CASE WHEN P1_22_71 is NULL then RPAD(' ', 3) ELSE LPAD(P1_22_71,3,'0') END||   -- pos 2851  P1_22_71
       RPAD(nvl(P1_22_72,' '),2)||   -- pos 2854  P1_22_72
       RPAD (' ', 20)||   -- pos 2856 
       RPAD(nvl(P1_23_1,' '),1)||   -- pos 2876  P1_23_1
       RPAD(nvl(P1_23_2,' '),7)||   -- pos 2877  P1_23_2
       RPAD(nvl(P1_23_3,' '),20)||   -- pos 2884  P1_23_3
       RPAD(nvl(P1_23_4,' '),3)||   -- pos 2904  P1_23_4
       RPAD(nvl(P1_23_5,' '),3)||   -- pos 2907  P1_23_5
       RPAD(nvl(P1_23_6,' '),1)||   -- pos 2910  P1_23_6
       RPAD(NVL(P1_23_7, ' '), 40)||   -- pos 2911  explicita
       RPAD (' ', 10)||   -- pos 2951 
       RPAD (nvl(P1_23_8,' '), 12)||   -- pos 2961  P1_23_8
       RPAD (nvl(P1_23_9,' '), 12)||   -- pos 2973  P1_23_9
       RPAD (nvl(P1_23_10,' '), 12)||   -- pos 2985  P1_23_10
       RPAD (nvl(P1_23_11,' '), 12)||   -- pos 2997  P1_23_11
       RPAD (' ', 2)||   -- pos 3009 
       RPAD(NVL(P1_24_1,' '),1,' ')||   -- pos 3011  P1_24_1
       RPAD (' ', 471)||   -- pos 3012 
       RPAD (' ', 178)||   -- pos 3483 
       RPAD(NVL(P1_26_1,' '),1,' ')||   -- pos 3661  P1_26_1
       RPAD(NVL(P1_22_11, ' '), 1)||   -- pos 3662  P1_22_11
       RPAD(NVL(P1_26_3, ' '), 3)||   -- pos 3663  P1_26_3
       RPAD(NVL(P1_26_4, ' '), 3)||   -- pos 3666  P1_26_4
       RPAD (' ', 44)||   -- pos 3669 
       RPAD (' ', 22)||   -- pos 3713 
       RPAD(P1_27_3, 1)||   -- pos 3735  P1_27_3
       RPAD(NVL(P1_27_4, ' '), 2)||   -- pos 3736  P1_27_4
       RPAD (' ', 23)||   -- pos 3738 
       RPAD (nvl(P1_28_1,' '), 1)||   -- pos 3761  P1_28_1
       RPAD (' ', 1)||   -- pos 3762 
       pack_utilitaire.F_FORMAT_MONTANT_BIS3(P1_29_1)||   -- pos 3763  P1_29_1
       RPAD (nvl(P1_29_2,' '), 3)||   -- pos 3782  P1_29_2
       RPAD(' ',190)||   -- pos 3785 
       RPAD(' ',6)||   -- pos 3975 
       'N'||   -- pos 3981 
       RPAD (' ', 18)     -- pos 3982 
     as lignedetail1,
       RPAD (' ', 7)||   -- pos 4000 
       'N'||   -- pos 4007 
       RPAD (' ', 25)||   -- pos 4008 
       RPAD (' ', 1)||   -- pos 4033 
       RPAD (' ', 5)||   -- pos 4034 
       RPAD(NVL(P1_31_2, ' '), 40)||   -- pos 4039  P1_31_2
       RPAD(NVL(P1_31_3, ' '), 40)||   -- pos 4079  P1_31_3
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_31_4),19)||   -- pos 4119  P1_31_4
       RPAD(NVL(P1_31_5, ' '), 1)||   -- pos 4138  P1_31_5
       RPAD (NVL(P1_31_6,'2'), 1)||   -- pos 4139  P1_31_6
       RPAD (' ', 6)||   -- pos 4140 
       RPAD (' ', 1)||   -- pos 4146 
       RPAD(NVL(P1_31_9, ' '),15,' ')||   -- pos 4147  P1_31_9
       RPAD(NVL(P1_31_10, ' '),2,' ')||   -- pos 4162  P1_31_10
       RPAD (' ', 1)||   -- pos 4164 
       RPAD (' ', 1)||   -- pos 4165 
       RPAD (' ', 1)||   -- pos 4166 
       RPAD (' ', 15)||   -- pos 4167 
       RPAD (' ', 19)||   -- pos 4182 
       RPAD (' ', 3)||   -- pos 4201 
       RPAD ('+', 1)||   -- pos 4204 
       LPAD(P1_31_17, 5, '0')||   -- pos 4205  explicita
       RPAD ('+', 1)||   -- pos 4210 
       LPAD(P1_31_18, 5, '0')||   -- pos 4211  explicita
       RPAD (' ', 6)||   -- pos 4216 
       RPAD (' ', 1)||   -- pos 4222 
       RPAD(NVL(P1_31_21,' '), 2)||   -- pos 4223  P1_31_21
       P1_31_22||   -- pos 4225  P1_31_22
       RPAD (' ', 19)||   -- pos 4227 
       RPAD (' ', 3)||   -- pos 4246 
       RPAD (' ', 15)||   -- pos 4249 
       RPAD (' ', 15)||   -- pos 4264 
       RPAD (' ', 15)||   -- pos 4279 
       RPAD (' ', 15)||   -- pos 4294 
       RPAD (' ', 15)||   -- pos 4309 
       RPAD(NVL(P1_31_37,' '),1)||   -- pos 4324  P1_31_37
       RPAD(' ',1)||   -- pos 4325 
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_29_3),19)||   -- pos 4326  P1_29_3
       RPAD ('EUR', 3)||   -- pos 4345 
       RPAD (' ', 22)||   -- pos 4348 
       RPAD (' ', 19)||   -- pos 4370 
       RPAD (' ', 3)||   -- pos 4389 
       RPAD (' ', 28)||   -- pos 4392 
       RPAD (' ', 7)||   -- pos 4420 
       RPAD (' ', 2)||   -- pos 4427 
       RPAD (' ', 2)||   -- pos 4429 
       RPAD (' ', 2)||   -- pos 4431 
       RPAD (' ', 2)||   -- pos 4433 
       RPAD (' ', 19)||   -- pos 4435 
       RPAD (' ', 3)||   -- pos 4454 
       RPAD (' ', 19)||   -- pos 4457 
       RPAD (' ', 3)||   -- pos 4476 
       RPAD (' ', 19)||   -- pos 4479 
       RPAD (' ', 3)||   -- pos 4498 
       RPAD (' ', 19)||   -- pos 4501 
       RPAD (' ', 3)||   -- pos 4520 
       RPAD (' ', 19)||   -- pos 4523 
       RPAD (' ', 3)||   -- pos 4542 
       RPAD (' ', 19)||   -- pos 4545 
       RPAD (' ', 3)||   -- pos 4564 
       RPAD (' ', 19)||   -- pos 4567 
       RPAD (' ', 3)||   -- pos 4586 
       RPAD (' ', 2)||   -- pos 4589 
       RPAD (' ', 2)||   -- pos 4591 
       RPAD (' ', 2)||   -- pos 4593 
       RPAD (' ', 20)||   -- pos 4595 
       RPAD (' ', 10)||   -- pos 4615 
       RPAD (' ', 15)||   -- pos 4625 
       RPAD (' ', 19)||   -- pos 4640 
       RPAD (' ', 3)||   -- pos 4659 
       RPAD (' ', 19)||   -- pos 4662 
       RPAD (' ', 3)||   -- pos 4681 
       RPAD (' ', 19)||   -- pos 4684 
       RPAD (' ', 3)||   -- pos 4703 
       'EUR'||   -- pos 4706 
       RPAD(NVL(P1_50_2, ' '), 12)||   -- pos 4709  P1_50_2
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_3),19)||   -- pos 4721  P1_50_3
       RPAD(' ',12)||   -- pos 4740 
       RPAD(' ',19)||   -- pos 4752 
       RPAD(NVL(P1_50_8, ' '), 12)||   -- pos 4771  P1_50_8
       RPAD(pack_utilitaire.f_format_montant_bis2(P1_50_9),19)||   -- pos 4783  P1_50_9
       RPAD(' ',12)||   -- pos 4802 
       RPAD(' ',19)||   -- pos 4814 
       RPAD(' ',12)||   -- pos 4833 
       RPAD(' ',19)||   -- pos 4845 
       RPAD(' ',12)||   -- pos 4864 
       RPAD(' ',19)||   -- pos 4876 
       RPAD(NVL(P1_21_22,' '),2)||   -- pos 4895  P1_21_22
       RPAD(NVL(TO_CHAR(P1_21_23, 'YYYYMMDD'), ' '),8)||   -- pos 4897  P1_21_23
       case when P1_21_29 is not null then '+'||LPAD(P1_21_29,5,'0') else RPAD(' ',6) end||   -- pos 4905  P1_21_29
       RPAD(NVL(P1_21_25,' '),2)||   -- pos 4911  P1_21_25
       RPAD(NVL(P1_21_26,' '),1)||   -- pos 4913  P1_21_26
       RPAD(NVL(P1_21_27,' '),1)||   -- pos 4914  P1_21_27
       RPAD(NVL(P1_21_28,' '),2)||   -- pos 4915  P1_21_28
       case when P1_21_30 is not null then RPAD(pack_utilitaire.f_format_montant_bis2(P1_21_30),19) else RPAD(' ',19) end||   -- pos 4917  P1_21_30
       RPAD(NVL(P1_21_31, ' '), 3)||   -- pos 4936  explicita
       RPAD(' ',15)||   -- pos 4939 
       RPAD(' ',3)||   -- pos 4954 
       RPAD(' ',12)||   -- pos 4957 
       RPAD(' ',12)||   -- pos 4969 
       RPAD(' ',12)||   -- pos 4981 
       RPAD(' ',12)||   -- pos 4993 
       RPAD(' ',19)||   -- pos 5005 
       RPAD(' ',1)||   -- pos 5024 
       RPAD(' ',1)||   -- pos 5025 
       RPAD(' ',19)||   -- pos 5026 
       RPAD(' ',3)||   -- pos 5045 
       RPAD(' ',10)||   -- pos 5048 
       RPAD(' ',7)||   -- pos 5058 
       RPAD(' ',19)||   -- pos 5065 
       RPAD(' ',3)||   -- pos 5084 
       RPAD(' ',19)||   -- pos 5087 
       RPAD(' ',3)||   -- pos 5106 
       RPAD(' ',19)||   -- pos 5109 
       RPAD(' ',3)||   -- pos 5128 
       RPAD(NVL(P1_21_44,' '),1)||   -- pos 5131  P1_21_44
       RPAD(NVL(P1_21_45,' '),1)||   -- pos 5132  P1_21_45
       RPAD(NVL(P1_21_46,' '),1)||   -- pos 5133  P1_21_46
       RPAD(NVL(P1_21_38,' '),1)||   -- pos 5134  P1_21_38
       RPAD(NVL(P1_21_39,' '),1)||   -- pos 5135  P1_21_39
       RPAD(NVL(P1_21_40,' '),1)||   -- pos 5136  P1_21_40
       RPAD(' ',1)||   -- pos 5137 
       RPAD(' ',1)||   -- pos 5138 
       RPAD(pack_utilitaire.F_FORMAT_TAUX_15(P1_21_43),15)||   -- pos 5139  P1_21_43
       RPAD(' ',1)||   -- pos 5154 
       RPAD(' ',1)||   -- pos 5155 
       RPAD(' ',1)||   -- pos 5156 
       RPAD(' ',1)||   -- pos 5157 
       RPAD(' ',15)||   -- pos 5158 
       RPAD(' ',10)||   -- pos 5173 
       RPAD(' ',10)||   -- pos 5183 
       RPAD(' ',19)||   -- pos 5193 
       RPAD(' ',3)||   -- pos 5212 
       RPAD(' ',5)||   -- pos 5215 
       RPAD(NVL(P1_21_66,' '),1)||   -- pos 5220  P1_21_66
       RPAD(' ',1)||   -- pos 5221 
       RPAD(NVL(P1_21_68,' '),1)||   -- pos 5222  P1_21_68
       RPAD(NVL(P1_21_55,' '),12)||   -- pos 5223  P1_21_55
       RPAD(NVL(P1_21_69,' '),1)||   -- pos 5235  P1_21_69
       RPAD(' ',20)||   -- pos 5236 
       RPAD(' ',10)||   -- pos 5256 
       RPAD(NVL(P1_8_13,' '),1)||   -- pos 5266  P1_8_13
       RPAD(NVL(P1_21_71,' '),40)||   -- pos 5267  P1_21_71
       RPAD(NVL(P1_21_72,' '),40)||   -- pos 5307  P1_21_72
       RPAD(NVL(P1_21_73,' '),40)||   -- pos 5347  P1_21_73
       RPAD(NVL(P1_21_74,' '),40)||   -- pos 5387  P1_21_74
       RPAD(NVL(P1_21_75,' '),40)||   -- pos 5427  P1_21_75
       RPAD(NVL(P1_21_76,' '),40)||   -- pos 5467  P1_21_76
       RPAD(NVL(P1_21_77,' '),11)||   -- pos 5507  P1_21_77
       RPAD(NVL(P1_21_78,' '),12)||   -- pos 5518  P1_21_78
       RPAD(' ',1)||   -- pos 5530 
       RPAD(' ',2)||   -- pos 5531 
       RPAD(' ',1)||   -- pos 5533 
       RPAD(NVL(P1_21_80,' '),3)||   -- pos 5534  P1_21_80
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_81),10)||   -- pos 5537  P1_21_81
       RPAD(pack_utilitaire.F_FORMAT_TAUX(P1_21_82),10)||   -- pos 5547  P1_21_82
       RPAD(' ',15)||   -- pos 5557 
       RPAD(' ',15)||   -- pos 5572 
       RPAD(' ',15)||   -- pos 5587 
       RPAD(NVL(P1_21_86,' '),1)||   -- pos 5602  P1_21_86
       RPAD(NVL(P1_21_87,' '),1)||   -- pos 5603  P1_21_87
       RPAD(NVL(P1_21_88,' '),1)||   -- pos 5604  P1_21_88
       RPAD(' ',19)||   -- pos 5605 
       RPAD(' ',3)||   -- pos 5624 
       RPAD(' ',5)||   -- pos 5627 
       RPAD(' ',20)||   -- pos 5632 
       RPAD(' ',19)||   -- pos 5652 
       RPAD(' ',3)||   -- pos 5671 
       lPAD(' ', 24)     -- pos 5674 
     as lignedetail2
  from ENG_CORP_P1_BIS
 where CD_PERIMETRE = 'HORS_NAT02'
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
    -- Les champs 1.11 et 1.16 ont pas la mÃªme regle d'alimentation que dans la table  provisions_decotes_p9 
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




