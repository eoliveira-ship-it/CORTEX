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
-- Notice        : CRRCV4.4_Grande Clientèle_Corporate_V44.02.xlsx            --
--------------------------------------------------------------------------------
-- Creation      : le 18/05/2021 par DUGUET MARC                              --
-- Modifications :                                                            --
--------------------------------------------------------------------------------
-- 18/03/2026 MESQUIPE: SIRL-500 - [QDD Bâle 4] Absence mnt acquisition dans  --
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

select ( champ1 || champ2 ) as lignedetail1 from table : lignedetail1 limitï¿½ a 4000 car 
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
--SET linesize 4201   --4201  mais requete SQL limite ï¿½ 4000 !
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
-- ï¿½01: a partir de P_UTLF_TIERS_C1 
-- 2 select 
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- ï¿½01a: a partir de C_C1 
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
       RPAD(NVL(translate(upper(C_ENR.NOM_TIERS), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 40)||
       --RPAD(NVL(translate(upper(C_ENR.RAISON_SOCLE), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 90)||
       TO_CHAR(nvl(C_ENR.DT_REVISION_NOTE,sysdate),'YYYYMMDDHH24MISS')|| -- a modifier
-- 29/05/2018 CDS Atos (JMP) ANACREDIT  US346 
-- Remplacement de la zone libre de 76 blancs par :
-- * 25 Blancs destinï¿½s ï¿½ C 14.30 ï¿½ C 14.34 dans les US a venir,
-- * Le nombre de salariï¿½s sur 6 chiffres,
-- * Puis 45 Blancs.
       --07/01/2019 CDS Atos (SQN) US 615
--       RPAD(' ',76)||
--       RPAD(' ',25)|| On split le 25 en 10+1+5+1+8 pour C 14.30 ï¿½ C 14.34
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
       RPAD(NVL(translate(upper(C_ENR.ADRESSE), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 70)||
       RPAD(NVL(translate(upper(C_ENR.VILLE), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 30)||
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
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.23	Date d'entrée en Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.24	Date de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_WL_CASA  , ' '), 2)||--C1 4.25	Motif d'entrée en Watch List
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
       RPAD(NVL(translate(upper(NVL(C_ENR.RAIS_SOCL_KBIS,C_ENR.RAISON_SOCLE)), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 114)||
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
-- ï¿½01b: a partir de C_C2 
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
       RPAD(NVL(translate(upper(C_ENR.NOM_TIERS), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 40)||
       --RPAD(NVL(translate(upper(C_ENR.RAISON_SOCLE), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 90)||
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
       RPAD(NVL(translate(upper(C_ENR.ADRESSE), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 70)||
       RPAD(NVL(translate(upper(C_ENR.VILLE), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 30)||
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
       RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.23	Date d'entrée en Watch List
       RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||--C1 4.24	Date de sortie en Watch List
       RPAD(NVL(C_ENR.CD_TYPE_WL_CASA  , ' '), 2)||--C1 4.25	Motif d'entrée en Watch List
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
       RPAD(NVL(translate(upper(NVL(C_ENR.RAIS_SOCL_KBIS,C_ENR.RAISON_SOCLE)), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU'), ' '), 114)||
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
-- ï¿½02: a partir de P_UTLF_AUTORISATION_F1     
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
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20)|| --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'SystÃ¨me de gestion source'
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
-- ï¿½03: a partir de P_UTLF_AUTORISATION_DETAIL_F2
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
       --28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur erronï¿½ pour P2 et F2
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
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20)||--KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'SystÃ¨me de gestion source'
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
-- E04: a partir de P_UTLF_ENG_CORP_P1   
-- 3 select 
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- E04a: a partir de C_ENG_CORP_P1_SANS_IMP 
------------------------------------------------------------------------------------------------------------------------

    select   
       to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD(NVL(C_ENR.APPLI_SOURCE,'C_BTR'), 12)||  -- 18/02/2019 - CDS ATOS (GBD) - US731
       'M'||
       :MASYSDATE||
       'P1'||
       RPAD(' ', 10)||  -- longueur : 1+2+7 | Fin 0
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||   --dans la synthese il est dit a blanc pour les tre5 mais aujourd hui nous la renseignons pour tous
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(' ', 40)||
       RPAD(C_ENR.ID_ENGAGEMENT || '_C',40)||  --pour les TRE2 a TRE4 pas de champ mais c'est une clef de la table -- a revoir si besoin
       RPAD(' ', 40)||
       RPAD(' ', 20)|| -- Fin 1
       RPAD(NVL(C_ENR.CD_METHODO_BALE2, 'STD'),7)||
       RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR, '01'),2)||  -- M56405 change code moteur de 07 a 01
       'Y'||
       RPAD(C_ENR.CD_TYPE_RISQUE,6)||
       NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')||
       RPAD(C_ENR.CD_LIGNE_METIER,5)||
       RPAD(C_ENR.CD_PORTEFEUILLE_BALE2,3)|| -- P1 2.18
       RPAD(nvl(C_ENR.CD_NATURE_OPE, 'NA020'),12)|| -- Fin 2
       RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8)||
       NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'),'99990630')||
       RPAD(' ', 10)||   --1+4+5
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_LGD_PREDICTIF_LOCAL)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_TRC)||
--       
--       RPAD(' ', 10)||    --taux pondï¿½ration baloise
       pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.MNT_EAD_TOT),0) <0 THEN 0 ELSE nvl((C_ENR.MNT_EAD_TOT),0)END ) ||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(' ', 50)|| -- Fin 3.1
       --06/02/2019 - CDS ATOS (SQN) US 654
       --RPAD(' ', 10)|| --2 + 8 | Fin 3.2
       RPAD(' ', 2)|| 
       RPAD(NVL(TO_CHAR(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '), 8)||
       --Fin SQN
       NVL(C_ENR.CD_ARR_PAIEMENT, 'N')||
       NVL(C_ENR.CD_IMP_PRUDENT, 'N')||
       NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')||
       Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then to_char(nvl(C_ENR.DT_ENG_DOUTEUX,C_ENR.dt_arrete), 'YYYYMMDD')
       else RPAD(' ', 8) END||
        RPAD(' ',1)||RPAD(' ',16)||RPAD(' ',2)|| -- P1 4.2
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR'), 3) || --CD_DEVISE_MNT_RISQ
       CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE201' THEN '+0000000000000000'|| --MT_DECOUVERT
           -- US731 RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR'), 3)
         RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, 'EUR'), 3)   -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
       ELSE RPAD (' ', 22) END || -- 1+16+2+3   P1 4.4 + P1 4.5
       --Fin SQN
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_RISQUE),0))|| -- crd brut
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE401' THEN RPAD(' ',22) ELSE
       pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_LOYER,0)) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14
       RPAD(NVL(C_ENR.CD_DEVISE_CRD, 'EUR'), 3)                  -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
       END ||
       RPAD (' ', 22)|| -- 1+16+2+3
       RPAD (nvl(C_ENR.PCCO_MNT_CRD,' '), 12)||
       Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.MNT_SOLD_K_A),0) <0 THEN 0 ELSE nvl((C_ENR.MNT_SOLD_K_A),0)END ) ELSE RPAD (' ', 19) END ||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
       RPAD (' ', 10)|| -- 1+4+5
       CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR),0)) END||
       CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 3) ELSE 'EUR' END||
       RPAD (nvl(C_ENR.CD_CIRCUIT_DISTRIB, 'CL'),2)||-- Fin 3.2BIS
       RPAD (' ', 61)||  --1+20+10+2+1+25+2 | Fin 3.3
       NVL(C_ENR.CD_USAGE_BIEN_IMM,' ')||
       NVL(C_ENR.CD_RESPECT_COND, ' ')|| -- Fin 3.4 
       -- Debut 3.4Bis
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR),0)) else RPAD (' ', 19) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2' and MNT_VTR_PDR
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then RPAD(C_ENR.CD_DEV_VTR,3) else RPAD (' ', 3) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2'
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_HYPOTHEQUE),0)) else RPAD (' ', 19) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2'
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then RPAD(C_ENR.CD_DEV_HYPOTH,3) else RPAD (' ', 3) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2'
       RPAD(nvl(C_ENR.CD_LOC_BIEN, ' '), 2,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 3.44
      --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
       --Nvl(C_ENR.CD_ACHAT_FIN_LOC, '2')||
       C_ENR.CD_ACHAT_FIN_LOC||
       --Fin
       Case when nvl(C_ENR.MNT_VR,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)) else pack_utilitaire.f_format_montant_bis2(0) END ||
         RPAD(nvl(C_ENR.CD_DEVISE_VR,'EUR'),3)|| -- Fin 3.4Bis
         --RPAD (' ', 638)||
       RPAD(nvl(C_ENR.cla_comp_ref_act,' '),3)||
       --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
       -- DEBUT: projet OMP - sous-tache SIRL-237
       RPAD(' ', 185)||                                 -- P1 3.56 jusq'au P1 3.74
       RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP
       RPAD(' ', 354)||                                 -- P1 3.80 jusq'au P1 16.19
       -- FIN: projet OMP - sous-tache SIRL-237
    RPAD(' ', 1) ||
		RPAD(' ', 1) ||
		RPAD(' ', 1) ||
		RPAD(' ', 2) ||
		RPAD(' ', 3) || -- Fin 3.5 a 3.10
		--Fin EMM
        -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.31
       RPAD(C_ENR.IND_PROD_SS_JACENT, 1,' ')||  -- P1 4.31   20/03/19 (EMM)
       --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	    RPAD (' ', 38)||
		RPAD(' ', 1) ||
		RPAD(' ', 4) ||
		RPAD (' ', 24)||
	   --FIN EMM 
     Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(C_ENR.MATURITE_EFF,0))  ,4,6)||  
     NVL(C_ENR.TOP_ENG,'B')|| -- P1 4.8
     RPAD (' ', 5)||
		 RPAD(nvl(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
     RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8)|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
     RPAD (' ', 7)||
     RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS, 'YYYYMMDD'), ' '), 8)||    --DT_DISPO_FONDS
     RPAD (' ', 1)||
     --Fin SQN
     RPAD (' ', 60)||
     RPAD (' ', 74)||
     Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END ||
         --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 3)||
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 45)||
		 RPAD (' ', 10)||
		--Fin EMM
         RPAD (' ', 35)|| 
          RPAD (' ', 466)|| --> Debut 21
         RPAD(nvl(C_ENR.EVENMT_CRDT,' '),1)|| -- P1 21.3
         RPAD(nvl(C_ENR.NAT_CONT_EVENMT_CRDT,' '),1)||
         RPAD(nvl(C_ENR.STA_CRDT,' '),1)||                                            --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.5)
         RPAD(nvl(C_ENR.IND_CRE_PERF,' '),2)||
         RPAD (NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8)||        --04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.7)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_COMM, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_RSQ, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8)  ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.10)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8)  ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.11)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8)  ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.12)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8)  ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.13)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8)  ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.14)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8)  ||                --04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.15)
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 16)||
         RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL, 'YYYYMMDD'), ' '), 8)||    --DT_PL_NPL
         --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 --Fin EMM
         --Fin SQN
         RPAD(nvl(C_ENR.IND_PROD_ECH,' '),3)|| -- P1 22.56
         RPAD(nvl(C_ENR.IND_OBJ_MET_PAL,' '),1)||
         RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
         RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
         RPAD (' ', 45)||
             RPAD(nvl(C_enr.NOTE_FIN_RET_ORI, 'ND'),2)||    -- P1 22.5
         RPAD(nvl(C_ENR.NOTE_EXT_ORI,' '),10)||
         --RPAD(nvl(C_ENR.ORG_NOT_ORI,' '),2)||
         RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||   --RPAD ('I', 2)||  -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
         RPAD(nvl(C_ENR.SEG_NOT_ORI,' '),2)||
         --RPAD(nvl(C_ENR.GRI_MOD_NOT_ORI,' '),46)||
         CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
         ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
     CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999'
     ELSE RPAD(upper(nvl(C_ENR.METH_NOT_ORI,' ')),3) END||
         RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2)|| -- P1 22.7
         --04/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         --RPAD (' ', 22)||
        -- 05/07/2018 - CDS AtoS (FAD) - Mantis 44080 : 
         --  Si le montant du contrat ? l'origine est null alors n'afficher que des blancs pour le montant et la devise associ?e
         --pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
         --RPAD(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 3)||--P1 22.9 : Devise du montant du contrat ? l'origine
         pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
         RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3) ||--P1 22.9 : Devise du montant du contrat ? l'origine
         -- Fin - CDS AtoS (FAD) - Mantis 44080
         --Fin - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         RPAD(nvl(C_ENR.IND_ECH_FOUR,' '),1)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_INT_EFF_ORI)||
         RPAD(nvl(C_ENR.TYPE_TAUX,' '),1)||
         RPAD(nvl(C_ENR.IND_REF,' '),12)||
         RPAD(nvl(C_ENR.TYPE_AMOR_CAP,' '),1)||
         RPAD(nvl(C_ENR.PRD_AMOR_CAP,' '),1)||
         RPAD(nvl(C_ENR.PRD_PMT_INT,' '),1)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_OCT)||
         RPAD(nvl(C_ENR.MOD_REMB_CRE,' '),1)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_PREM_ECH, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_DIFF_AMOR, 'YYYYMMDD'), ' '), 8)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAFOND)||-- P1 22.23
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLANCHER)||
         RPAD(nvl(C_ENR.PRD_REV_TAUX_UNIT_TMP,' '),1)||
         LPAD(nvl((C_ENR.PRD_REV_TAUX_NBR),0),3,0)||
                 pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_PRD_EN_CRS)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_ADD)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_MULT)||
         RPAD(nvl(C_ENR.BASE_CAL_INT,' '),7)||
         -- 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale 
        RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DBLQ_FONDS, 'YYYYMMDD'), ' '), 8)||
-- 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430 => Mettre dans blancs si le montant de premie dï¿½blocage de fond est nul.
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_PREM_DBLQ_FONDS) end || 
-- fin 16/07/2018 CDS ATOS (JMP) 
         RPAD(nvl(C_ENR.DEVISE_PREM_DBLQ_FONDS,'EUR'),3)||        -- bis2 donne 00000 donc il faut la devise
         -- Fin 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale 
         pack_utilitaire.F_FORMAT_MONTANT_BIS2( CASE WHEN C_ENR.CAP_THEO_REST<0 THEN 0 ELSE C_ENR.CAP_THEO_REST END)||
              RPAD(nvl(C_ENR.DEVI_CAP_THEO_REST,' '),3)||
         RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36 
             RPAD(NVL(TO_CHAR(C_ENR.dt_exigte_prem_impy, 'YYYYMMDD'), ' '), 8)||--P1 22.37
         --04/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         --RPAD (' ', 130)||
         RPAD(NVL(TO_CHAR(C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS, 'YYYYMMDD'), ' '), 8)||--P1 22.38 : Date de passage en douteux compromis
         --RPAD(' ', 122)||
         RPAD(' ', 19)|| -- P1 22.39
         RPAD(' ', 3)|| -- P1 22.40
         RPAD(' ', 8)|| -- P1 22.41
         RPAD(' ', 10)|| -- P1 22.42
         RPAD(' ', 10)|| -- P1 22.43
         pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0))||  --P1 22.44 pos 2703 -  Mantis 71368
         RPAD('EUR', 3)|| -- P1 22.45 -- ajout EUR via M_72574
         RPAD(' ', 8)|| -- P1 22.46
         RPAD(' ', 19)|| -- P1 22.47
         RPAD(' ', 3)|| -- P1 22.48
         RPAD(' ', 10)|| -- P1 22.49
         RPAD(' ', 10)|| -- P1 22.50    
         --Fin - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_PALL, 'YYYYMMDD'), ' '), 8)|| -- 22.58
         RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_PALL, 'YYYYMMDD'), ' '), 8)||
         --pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_ECH_EN_COURS)|| --P1 22.60
         pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(C_ENR.MNT_ECH_EN_COURS)|| --P1 22.60
         RPAD(nvl(C_ENR.DEVI_MNT_ECH_EN_COURS,' '),3)||
         RPAD(nvl(C_ENR.IND_PRE_POST_FIX,' '),1)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENVL,'YYYYMMDD'),' '), 8)|| -- P1 22.63 :: projet OMP - sous-tache SIRL-236
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 55)||
         RPAD (' ', 12)||
         RPAD(nvl(C_ENR.CD_PAYS_JURIDICTION, ' '), 2)||    --CD_PAYS_JURIDICTION
         RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8)||    --DT_SIGNATURE
         RPAD (' ', 3)||
         LPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '     '),5,'0')||    --NB_JOURS_RETARD
         CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
         RPAD(nvl(C_ENR.BUCKET_IFRS9,' '),2)||    --BUCKET_IFRS9
         RPAD (' ', 20)||
         --Fin SQN
         RPAD(nvl(C_ENR.ELI_OUT_MUT_PROV,' '),1)|| -- P1 23.1
         RPAD(nvl(C_ENR.CENTRE_RES,' '),7)||
         RPAD(nvl(C_ENR.SYS_GEST_SRC,' '),20)||
         RPAD(nvl(C_ENR.CLA_COMP_ACT_IFRS9,' '),3)||
         RPAD(nvl(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3)||
         RPAD(nvl(C_ENR.IND_ACT_DEP_ORI,' '),1)||
         RPAD(C_ENR.PCCO_MNT_CRD || nvl(C_ENR.ZONE_APP_COMP,' '),40)||
         RPAD (' ', 10)||
              RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)|| -- P1 23.8
              RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
              RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
              RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
         RPAD (' ', 2)||
         RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 1188) 
         --RPAD (' ', 496)||    --Fin P1 24
         RPAD (' ', 471)||    --Fin P1 24 --BALE4 (24.6)+3(24.37)-28=-25
         RPAD (' ', 178)||    --P1 25
         -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
         --RPAD (' ', 52)|| --P1 26
         RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
         --01/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1)||
		 RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3)||
		 RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3)||
		 RPAD (' ', 44)||
         --Fin SQN CRRV4.2 ajout de RG ACODUC
         RPAD (' ', 22)||
		 --07/09/21 CDS_ATOS (EMM) MR 11666
		RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
		--Fin EMM
		RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2) ||
		RPAD (' ', 23)||		 -- Fin P1 27
		--Fin EMM
         -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
         --RPAD (' ', 2)||        --P1 28
         RPAD (nvl(C_ENR.IND_OPE_EFFET_LEVIER,' '), 1)||  --IND_OPE_EFFET_LEVIER
         RPAD (' ', 1)||
         --Fin SQN CRRV4.2 ajout de RG ACODUC
         pack_utilitaire.F_FORMAT_MONTANT_BIS3(C_ENR.MNT_IDEMNITE_RES)||        --MNT_IDEMNITE_RES
         RPAD (nvl(C_ENR.CD_DEV_MNT_INDEMNITE,' '), 3)||        --CD_DEV_MNT_INDEMNITE
         --MANTIS 11611 (VFN) 27/07/2021
	 RPAD(' ',190)|| --Debut P1 30 	|189car sur 250 car dans lignedetail1 
	--Fin MANTIS 11611 
	-- as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	 -- BALE4
	 -- (compter 1 blanc de separation entre les 2 champs dans le spool)
         --MANTIS 11611 (VFN) 27/07/2021
	  RPAD(' ',6)|| -- Fin 30		
	--Fin MANTIS 11611	
		 'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
		 'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 25)||
		 RPAD (' ', 1)||   --fin P1 30 - 60 caracteres sur 250 seront dans lignedetail2
		 RPAD (' ', 5)|| -- dï¿½but P1 31.a
		 RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '), 40)||
		 RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT, ' '), 40)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19) || 
		 RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '), 1)||
		 RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
		 RPAD (' ', 6) ||
		 RPAD (' ', 1)||
     RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
     RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 15)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
     --DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
     RPAD ('+', 1)|| -- P1 31.17a
     case when C_ENR.CD_TYPE_RISQUE like 'TRE%' 
        then LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0') 
        else RPAD('00000',5) 
     end|| -- P1 31.17b
		 RPAD ('+', 1)|| -- P1 31.18a
     case when C_ENR.CD_TYPE_RISQUE like 'TRE%' 
        then LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0') 
        else RPAD('00000',5) 
     end|| -- P1 31.18b
     --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
     RPAD (' ', 6)||
		 RPAD (' ', 1)||
	   RPAD(NVL(C_ENR.CDTYPEGARPRINCOCTROI,' '), 2)|| --Debut P1 31.21 M71371
	  -- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
    CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
    END || -- P1 31.22 Type de garantie principale a date
    -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||--Fin 31b
		 --RPAD(' ', 2)|| --Debut P1 31C
     RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 - P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
     RPAD(' ',1) || -- Fin P1 31c
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
		 RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
		 RPAD (' ', 22)|| -- Fin 31d
		 RPAD (' ', 19)|| --Debut 31 e
		 RPAD (' ', 3)|| -- Fin 31e
		 RPAD (' ', 28)|| --Debut - Fin 31f
		 RPAD (' ', 7)|| --Debut 31 g
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 2)|| --Dï¿½but 31h
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 20)||
		 RPAD (' ', 10)||
		 RPAD (' ', 15)||
		 RPAD (' ', 19)||
         RPAD (' ', 3)||
		 RPAD (' ', 19)||
         RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 'EUR'|| --Dï¿½but P1 50 --M11665 modif VFN
		 RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) ||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) ||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(' ',12)||
		 RPAD(' ',19)||--Fin P1 50 
		RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2)|| --P1 21.22 pos 4897
		RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8)|| --P1 21.23 pos 4899
    case when C_ENR.DUREE_MRTR is not null then '+'||LPAD(C_ENR.DUREE_MRTR,5,'0') else RPAD(' ',6) end ||--P1 21.29 pos 4907
		RPAD(NVL(C_ENR.STATUT_MRTR,' '),2)|| --P1 21.25 pos 4913
		RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1)|| --P1 21.26 pos 4915
		RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1)|| --P1 21.27 pos 4916
		RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2)|| --P1 21.28 pos 4917
		case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_MRTR),19) else RPAD(' ',19) end || --P1 21.30 pos 4919
		case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV_MRTR,' '),3) else RPAD(' ',3) end || --P1 21.31 pos 4938
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE => point fermé
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE => point fermé
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE => point fermé
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE => point fermé
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE => point fermé
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE => point fermé
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE => point fermé
		RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1)|| --P1 21.44 pos 5133
		RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1)|| --P1 21.45 pos 5134
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(NVL(C_ENR.IND_IPRE,' '),1)|| --P1 21.38 pos 5136
		RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)|| --P1 21.39 pos 5137
		RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1)|| --P1 21.40 pos 5138
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE => point fermé
 	  RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15)||--P1 21.43 pos 5141
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.57 pos 5157 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.58 pos 5158 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE => point fermé
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE => point fermé
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE => point fermé
		RPAD(NVL(C_ENR.IND_UCC,' '),1)|| --P1 21.66 pos 5222 => point fermé
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE => point fermé
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224 => point fermé
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225 => point fermé
		RPAD(NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END,' '),1)|| --P1 21.69 pos 5237 => point fermé
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE => point fermé
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
		RPAD(NVL(C_ENR.COMMUNE,' '),40)|| --P1 21.71 pos 5269
		RPAD(NVL(C_ENR.NUM_VOIE,' '),40)|| --P1 21.72 pos 5309 
		RPAD(NVL(C_ENR.EXTENSION,' '),40)|| --P1 21.73 pos 5349
		RPAD(NVL(C_ENR.TYPE_VOIE,' '),40)|| --P1 21.74 pos 5389 
		RPAD(NVL(C_ENR.LIB_VOIE,' '),40)|| --P1 21.75 pos 5429
		RPAD(NVL(C_ENR.LIEU_DIT,' '),40)|| --P1 21.76 pos 5469
		RPAD(NVL(C_ENR.LATITUDE,' '),11)|| --P1 21.77 pos 5509
		RPAD(NVL(C_ENR.LONGITUDE,' '),12)|| --P1 21.78 pos 5520
		RPAD(' ',1)|| --P1 21.94 pos 5532 - A REMPLIR (v1.5)
		RPAD(' ',2)|| --P1 21.95 pos 5533 - A REMPLIR (v1.5)
		RPAD(' ',1)|| --P1 21.79 pos 5535 => point fermé
		RPAD(NVL(C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE,' '),3)|| --P1 21.80 pos 5536
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10)|| --P1 21.81 pos 5539 
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10)|| --P1 21.82 pos 5549
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE  
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 - VIDE
		 lPAD(' ', 24) --MANTIS 11611 (VFN) 27/07/2021	-- Mantis 11841 
     as lignedetail2		-- Fin de ligne(taille lignedetail2 =1117)
		 --Fin EMM
    from 
    ENG_CORP_P1  C_ENR
    WHERE A_EXTRAIRE = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
    AND   NVL(CD_ARR_PAIEMENT, 'N')= 'N'
    AND nvl(FLAG_HN , 'N')       = 'N'
    AND 
      (NVL(MNT_CRD,0)-NVL(MNT_VR,0) >= 1
      OR
      NVL(MNT_VR,0)>=1)
    AND CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
    AND ( CD_TYPE_RISQUE NOT LIKE 'TRE2%'
     );
 
 

------------------------------------------------------------------------------------------------------------------------
-- E04b: a partir de C_ENG_CORP_P1_AVEC_IMP1 
------------------------------------------------------------------------------------------------------------------------

    select
         to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD(NVL(C_ENR.APPLI_SOURCE,'C_BTR'), 12)||  -- 18/02/2019 - CDS ATOS (GBD) - US731
       'M'||
       :MASYSDATE||
       'P1'||
       RPAD(' ', 10)||  -- longueur : 1+2+7	| Fin 0
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||   --dans la synthese il est dit ï¿½ blanc pour les tre5 mais aujourd hui nous la renseignons pour tous
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(' ', 40)||
       RPAD(C_ENR.ID_ENGAGEMENT || '_S',40)||  --pour les TRE2 a TRE4 pas de champ mais c'est une clef de la table -- a revoir si besoin
       RPAD(' ', 40)||
       RPAD(' ', 20)||	-- Fin 1
       RPAD(NVL(C_ENR.CD_METHODO_BALE2, 'STD'),7)||
       RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR, '01'),2)|| -- M56405 change code moteur de 07 ï¿½ 01
       'Y'||
       RPAD(C_ENR.CD_TYPE_RISQUE,6)||
       NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')||
       RPAD(C_ENR.CD_LIGNE_METIER,5)||
       RPAD(C_ENR.CD_PORTEFEUILLE_BALE2,3)||
       RPAD(nvl(C_ENR.CD_NATURE_OPE, 'NA020'),12)||	-- Fin 2
       RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8)||
       --NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'),'99990630')||
       NVL(TO_CHAR(add_months(C_ENR.DT_ARRETE,12), 'YYYYMMDD'),'99990630')||
       RPAD(' ', 10)||   --1+4+5
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_LGD_PREDICTIF_LOCAL)||
       pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_TRC)||
--       
--       RPAD(' ', 10)||    --taux pondï¿½ration baloise
       pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.MNT_EAD_TOT),0) <0 THEN 0 ELSE nvl((C_ENR.MNT_EAD_TOT),0)END ) ||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(' ', 50)||	-- Fin 3.1 
       --06/02/2019 - CDS ATOS (SQN) US 654
       -- Debut 3.2
       --RPAD(' ', 10)|| --2 + 8 
       RPAD(' ', 2)|| 
       RPAD(NVL(TO_CHAR(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '), 8)||
       --Fin SQN - Fin 3.2 | Debut 3.2 Bis
       NVL(C_ENR.CD_ARR_PAIEMENT, 'N')||
       NVL(C_ENR.CD_IMP_PRUDENT, 'N')||
       NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')||
       Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then to_char(nvl(C_ENR.DT_ENG_DOUTEUX,C_ENR.dt_arrete), 'YYYYMMDD')
       else RPAD(' ', 8) END||
       RPAD(' ',1)||RPAD(' ',16)||RPAD(' ',2)|| -- P1 4.2
    --Fin - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR'), 3) ||  -- P1 4.3
       CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE201' THEN '+0000000000000000'|| --MT_DECOUVERT
       -- US731 RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR'), 3)
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, 'EUR'), 3)  -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
       ELSE RPAD (' ', 22) END || -- 1+16+2+3   P1 4.4  + P1 4.5
       --Fin SQN
       pack_utilitaire.f_format_montant_bis2(0)|| -- crd brut
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_SOLD_K_A,0)) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14 
       --Fin SQN
       RPAD(NVL(C_ENR.CD_DEVISE_CRD, 'EUR'), 3)   ||             -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
       RPAD (' ', 22)|| -- 1+16+2+3
       RPAD (nvl(C_ENR.PCCO_MNT_SOLDE,' '), 12)||
       Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN pack_utilitaire.f_format_montant_bis2(CASE WHEN nvl((C_ENR.MNT_SOLD_K_A),0) <0 THEN 0 ELSE nvl((C_ENR.MNT_SOLD_K_A),0)END ) ELSE RPAD (' ', 19) END ||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
       RPAD (' ', 10)|| -- 1+4+5
       --RPAD (' ', 22)|| -- 1+16+2+3
       CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR),0)) END||
       CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 3) ELSE 'EUR' END||
       RPAD (nvl(C_ENR.CD_CIRCUIT_DISTRIB, 'CL'),2)||--
       RPAD (' ', 61)||  --1+20+10+2+1+25+2
       --C_ENR.CD_ACHAT_FIN_LOC||
       NVL(C_ENR.CD_USAGE_BIEN_IMM,' ')||
       NVL(C_ENR.CD_RESPECT_COND, ' ')||
       -- 08/12/2020 - CDS ATOS (CPD) - US 238 - Anacredit Leasing- Revoir la rï¿½gle d'alimentation des montant CBI en cas d'arriï¿½rï¿½
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then pack_utilitaire.f_format_montant_bis2(0) else RPAD (' ', 19) END||
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then RPAD(C_ENR.CD_DEV_VTR,3) else RPAD (' ', 3) END||
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then pack_utilitaire.f_format_montant_bis2(0) else RPAD (' ', 19) END||
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then RPAD(C_ENR.CD_DEV_HYPOTH,3) else RPAD (' ', 3) END||
       -- fin CPD
       --US731 Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then RPAD(nvl(C_ENR.CD_LOC_BIEN, 'FR'), 2) ELSE  RPAD(nvl(C_ENR.CD_LOC_BIEN, ' '), 2) END ||
        RPAD(nvl(C_ENR.CD_LOC_BIEN, ' '), 2,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 3.44
      --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
       --Nvl(C_ENR.CD_ACHAT_FIN_LOC, '2')||
       C_ENR.CD_ACHAT_FIN_LOC||
       --Fin
       Case when nvl(C_ENR.MNT_VR,0) >= 0 then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)) else pack_utilitaire.f_format_montant_bis2(0) END ||
         RPAD(nvl(C_ENR.CD_DEVISE_VR,'EUR'),3)||
         --RPAD (' ', 638)||
       RPAD(nvl(C_ENR.cla_comp_ref_act_s,' '),3)||
	     --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
       -- DEBUT: projet OMP - sous-tache SIRL-237
       RPAD(' ', 185)||                                 -- P1 3.56 jusq'au P1 3.74
       RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP
       RPAD(' ', 354)||                                 -- P1 3.80 jusq'au P1 16.19
       -- FIN: projet OMP - sous-tache SIRL-237
	   RPAD(' ', 1) ||
		RPAD(' ', 1) ||
		RPAD(' ', 1) ||
		RPAD(' ', 2) ||
		RPAD(' ', 3) || -- Fin 3.5 a 3.10
	--FIN EMM
        -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.31
       RPAD(C_ENR.IND_PROD_SS_JACENT, 1,' ')||  -- P1 4.31   20/03/19 (EMM)
       --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD (' ', 38)||
		RPAD(' ', 1) ||
		RPAD(' ', 4) ||
		RPAD (' ', 24)||
	   --FIN EMM
         --Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(C_ENR.MATURITE_EFF,0))  ,4,6)||  
    Substr(pack_utilitaire.F_FORMAT_TAUX (1)  ,4,6)||  
         RPAD(C_ENR.TOP_ENG, 1)||
         RPAD (' ', 5)||
		 RPAD(nvl(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
     RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8)|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
     RPAD (' ', 7)||
     RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS, 'YYYYMMDD'), ' '), 8)||    --DT_DISPO_FONDS
     RPAD (' ', 1)||
     --Fin SQN
     RPAD (' ', 60)||
     RPAD (' ', 74)||
     Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END ||
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 3)||
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 45)||
		 RPAD (' ', 10)||
		 --Fin EMM
         RPAD (' ', 35)||
         RPAD (' ', 466)||
         RPAD(nvl(C_ENR.EVENMT_CRDT,' '),1)||
         RPAD(nvl(C_ENR.NAT_CONT_EVENMT_CRDT,' '),1)||
         RPAD(nvl(C_ENR.STA_CRDT,' '),1)||                                            --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.5)
         RPAD(nvl(C_ENR.IND_CRE_PERF,' '),2)||
         RPAD (NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8)||        --04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.7)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_COMM, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_RSQ, 'YYYYMMDD'), ' '), 8)||
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.10)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.11)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.12)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.13)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.14)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8) END ||                --04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.15)
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 16)||
         RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL, 'YYYYMMDD'), ' '), 8)||    --DT_PL_NPL
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 --Fin EMM
         --Fin SQN
         RPAD(nvl(C_ENR.IND_PROD_ECH,' '),3)||
         RPAD(nvl(C_ENR.IND_OBJ_MET_PAL,' '),1)||
         RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
         RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
         RPAD (' ', 45)||
                 RPAD(nvl(C_enr.NOTE_FIN_RET_ORI, 'ND'),2)||
         RPAD(nvl(C_ENR.NOTE_EXT_ORI,' '),10)||
         --RPAD(nvl(C_ENR.ORG_NOT_ORI,' '),2)||
        RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||    -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
         RPAD(nvl(C_ENR.SEG_NOT_ORI,' '),2)||
         CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
         ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
         --RPAD(upper(nvl(C_ENR.METH_NOT_ORI,' ')),3)||
     CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999'
     ELSE RPAD(upper(nvl(C_ENR.METH_NOT_ORI,' ')),3) END||
         RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2)|| -- P1 22.7
         pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
         RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3) ||--P1 22.9 : Devise du montant du contrat ? l'origine
         -- Fin - CDS AtoS (FAD) - Mantis 44080
         --Fin - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         RPAD(nvl(C_ENR.IND_ECH_FOUR,' '),1)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_INT_EFF_ORI)||
         RPAD(nvl(C_ENR.TYPE_TAUX,' '),1)||
         RPAD(nvl(C_ENR.IND_REF,' '),12)||
         --RPAD(nvl(C_ENR.TYPE_AMOR_CAP,' '),1)||
         'F'||
         RPAD(nvl(C_ENR.PRD_AMOR_CAP,' '),1)||
         RPAD(nvl(C_ENR.PRD_PMT_INT,' '),1)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_OCT)||
         RPAD(nvl(C_ENR.MOD_REMB_CRE,' '),1)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_PREM_ECH, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_DIFF_AMOR, 'YYYYMMDD'), ' '), 8)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAFOND)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLANCHER)||
         RPAD(nvl(C_ENR.PRD_REV_TAUX_UNIT_TMP,' '),1)||
         LPAD(nvl((C_ENR.PRD_REV_TAUX_NBR),0),3,0)||
                 pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_PRD_EN_CRS)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_ADD)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_MULT)||
         RPAD(nvl(C_ENR.BASE_CAL_INT,' '),7)||
          -- 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale 
        RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DBLQ_FONDS, 'YYYYMMDD'), ' '), 8)||
--         RPAD(' ',8)||
-- 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430 => Mettre dans blancs si le montant de premie dï¿½blocage de fond est nul.
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_PREM_DBLQ_FONDS) end || 
-- fin 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430 
         RPAD(nvl(C_ENR.DEVISE_PREM_DBLQ_FONDS,'EUR'),3)||        -- bis2 donne 00000 donc il faut la devise
		 --06/09/21 CDS_ATOS (EMM) MR 11664
         pack_utilitaire.F_FORMAT_MONTANT_BIS2( CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END)||		--P1 22.34
		 --Fin EMM
         RPAD(nvl(C_ENR.DEVI_CAP_THEO_REST,' '),3)||
         RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36 
         RPAD(NVL(TO_CHAR(C_ENR.dt_exigte_prem_impy, 'YYYYMMDD'), ' '), 8)||		--P1 22.37
         --04/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         --RPAD (' ', 130)||
         RPAD(NVL(TO_CHAR(C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS, 'YYYYMMDD'), ' '), 8)||--P1 22.38 : Date de passage en douteux compromis
         --RPAD(' ', 122)||
         --SIRL-500
         RPAD(' ', 19)|| -- P1 22.39
         RPAD(' ', 3)|| -- P1 22.40
         RPAD(' ', 8)|| -- P1 22.41
         RPAD(' ', 10)|| -- P1 22.42
         RPAD(' ', 10)|| -- P1 22.43
         pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0))||  --P1 22.44 pos 2703 -  Mantis 71368
         RPAD('EUR', 3)|| -- P1 22.45
         RPAD(' ', 8)|| -- P1 22.46
         RPAD(' ', 19)|| -- P1 22.47
         RPAD(' ', 3)|| -- P1 22.48
         RPAD(' ', 10)|| -- P1 22.49
         RPAD(' ', 10)|| -- P1 22.50    
         --Fin - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
        RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_PALL, 'YYYYMMDD'), ' '), 8)|| -- 22.58
        RPAD(NVL(TO_CHAR(add_months(C_ENR.DT_ARRETE,12), 'YYYYMMDD'), ' '), 8)||
         --pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_ECH_EN_COURS)||
         pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(C_ENR.MNT_ECH_EN_COURS)||
         RPAD(nvl(C_ENR.DEVI_MNT_ECH_EN_COURS,' '),3)||
         RPAD(nvl(C_ENR.IND_PRE_POST_FIX,' '),1)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENVL,'YYYYMMDD'),' '), 8)|| -- P1 22.63 :: projet OMP - sous-tache SIRL-236
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 55)||
         RPAD (' ', 12)||
         RPAD(nvl(C_ENR.CD_PAYS_JURIDICTION, ' '), 2)||    --CD_PAYS_JURIDICTION
         RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8)||    --DT_SIGNATURE
         RPAD (' ', 3)||
         LPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '     '),5,'0')||    --NB_JOURS_RETARD
         CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
         RPAD(nvl(C_ENR.BUCKET_IFRS9,' '),2)||    --BUCKET_IFRS9
         RPAD (' ', 20)||
         --Fin SQN
         RPAD(nvl(C_ENR.ELI_OUT_MUT_PROV_S,' '),1)||
         RPAD(nvl(C_ENR.CENTRE_RES,' '),7)||
         RPAD(nvl(C_ENR.SYS_GEST_SRC,' '),20)||
         RPAD(nvl(C_ENR.CLA_COMP_ACT_IFRS9_S,' '),3)||
         RPAD(nvl(C_ENR.CLA_COMP_ACT_NATIONALE_S,' '),3)||
         RPAD(nvl(C_ENR.IND_ACT_DEP_ORI,' '),1)||
         RPAD(C_ENR.PCCO_MNT_SOLDE || nvl(C_ENR.ZONE_APP_COMP,' '),40)||
         RPAD (' ', 10)||
         RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
         RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
         RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
         RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
         RPAD (' ', 2)||
         RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 1188)
         --RPAD (' ', 496)||    --Fin P1 24
         		RPAD (' ', 471)||    --Fin P1 24 --BALE4 (24.6)+3(24.37)-28=-25
         RPAD (' ', 178)||    --P1 25
         -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
         --RPAD (' ', 52)|| --P1 26
         RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1)||
		 RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3)||
		 RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3)||
		 RPAD (' ', 44)||
		 --Fin EMM
         --Fin SQN CRRV4.2 ajout de RG ACODUC
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 22)||
		 --07/09/21 CDS_ATOS (EMM) MR 11666
		RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
		--Fin EMM
		RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2) ||
		RPAD (' ', 23)||		 -- Fin P1 27
		--Fin EMM
         -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
         --RPAD (' ', 2)||        --P1 28
         RPAD (nvl(C_ENR.IND_OPE_EFFET_LEVIER,' '), 1)||  --IND_OPE_EFFET_LEVIER
         RPAD (' ', 1)||
         --Fin SQN CRRV4.2 ajout de RG ACODUC
         pack_utilitaire.F_FORMAT_MONTANT_BIS3(C_ENR.MNT_IDEMNITE_RES)||        --MNT_IDEMNITE_RES
         RPAD (nvl(C_ENR.CD_DEV_MNT_INDEMNITE,' '), 3)||        --CD_DEV_MNT_INDEMNITE
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	--MANTIS 11611 (VFN) 27/07/2021
	 RPAD(' ',190)|| --Debut P1 30 	|190car sur 250 car dans lignedetail1 
	--Fin MANTIS 11611 
	-- as lignedetail1,  -- debut ligne (taille lignedetail1 =3982)	 
	 -- (compter 1 blanc de separation entre les 2 champs dans le spool)
         --MANTIS 11611 (VFN) 27/07/2021
	  RPAD(' ',6)|| -- Fin 30		
	--Fin MANTIS 11611		
		  'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
		  'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 25)||
		 RPAD (' ', 1)||   --fin P1 30 - 60 caracteres sur 250 seront dans lignedetail2
		 RPAD (' ', 5)|| -- dï¿½but P1 31.a
		 RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '), 40)||
		 RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT, ' '), 40)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19) || 
		 RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '), 1)||
     RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
		 RPAD (' ', 6) ||
		 RPAD (' ', 1)||
     RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
     RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 15)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
     --DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
		 RPAD ('+', 1)|| -- P1 31.17a
     case when C_ENR.CD_TYPE_RISQUE like 'TRE%' 
        then LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0') 
        else RPAD('00000',5) 
     end|| -- P1 31.17b
		 RPAD ('+', 1)|| -- P1 31.18a
     case when C_ENR.CD_TYPE_RISQUE like 'TRE%' 
        then LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0') 
        else RPAD('00000',5) 
     end|| -- P1 31.18b
     --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
		 RPAD (' ', 6)||
		 RPAD (' ', 1)||
     RPAD(NVL(C_ENR.CDTYPEGARPRINCOCTROI,' '), 2)|| --Debut P1 31.21 M71371
	  -- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
    CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
    END || -- P1 31.22 Type de garantie principale a date
    -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||--Fin 31b
     	--RPAD(' ', 2)|| --DEbut P1 31C
     RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 - P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
     RPAD(' ',1) || -- Fin P1 31c
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
		 RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
		 RPAD (' ', 22)|| -- Fin 31d
		 RPAD (' ', 19)|| --Debut 31 e
		 RPAD (' ', 3)|| -- Fin 31e
		 RPAD (' ', 28)|| --Debut - Fin 31f
		 RPAD (' ', 7)|| -- Debut 31 g
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 2)|| --Debut 31h
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 20)||
		 RPAD (' ', 10)||
		 RPAD (' ', 15)||
		 RPAD (' ', 19)||
         RPAD (' ', 3)||
		 RPAD (' ', 19)||
         RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 'EUR'|| --Debut 50 --M11665 modif VFN
		 RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) ||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) ||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(' ',12)||
		 RPAD(' ',19)||	--Fin 50
		RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2)|| --P1 21.22 pos 4897
		RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8)|| --P1 21.23 pos 4899
    case when C_ENR.DUREE_MRTR is not null then '+'||LPAD(C_ENR.DUREE_MRTR,5,'0') else RPAD(' ',6) end ||--P1 21.29 pos 4907
		RPAD(NVL(C_ENR.STATUT_MRTR,' '),2)|| --P1 21.25 pos 4913
		RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1)|| --P1 21.26 pos 4915
		RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1)|| --P1 21.27 pos 4916
		RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2)|| --P1 21.28 pos 4917
		case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_MRTR),19) else RPAD(' ',19) end || --P1 21.30 pos 4919
		case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV_MRTR,' '),3) else RPAD(' ',3) end || --P1 21.31 pos 4938
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE => point fermé
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE => point fermé
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE => point fermé
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE => point fermé
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE => point fermé
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE => point fermé
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE => point fermé
		RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1)|| --P1 21.44 pos 5133 
		RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1)|| --P1 21.45 pos 5134
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(' ',1)|| --P1 21.38 pos 5136 - A REMPLIR (v1.5)
		RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)|| --P1 21.39 pos 5137
		RPAD(' ',1)|| --P1 21.40 pos 5138 - A REMPLIR (v1.5) créer sur la BD?
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE => point fermé
 	  RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15)||--P1 21.43 pos 5141
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.57 pos 5157 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.58 pos 5158 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE => point fermé
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE => point fermé
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE => point fermé
		RPAD(NVL(C_ENR.IND_UCC,' '),1)|| --P1 21.66 pos 5222 => point fermé
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE => point fermé
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224 => point fermé
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225 => point fermé
		RPAD(NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END,' '),1)|| --P1 21.69 pos 5237 => point fermé
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE => point fermé
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
		RPAD(' ',40)|| --P1 21.71 pos 5269 - A REMPLIR (v1.5)
		RPAD(' ',40)|| --P1 21.72 pos 5309 - A REMPLIR (v1.5)
		RPAD(' ',40)|| --P1 21.73 pos 5349 - A REMPLIR (v1.5)
		RPAD(' ',40)|| --P1 21.74 pos 5389 - A REMPLIR (v1.5)
		RPAD(' ',40)|| --P1 21.75 pos 5429 - A REMPLIR (v1.5)
		RPAD(' ',40)|| --P1 21.76 pos 5469 - A REMPLIR (v1.5)
		RPAD(' ',11)|| --P1 21.77 pos 5509 - A REMPLIR (v1.5)
		RPAD(' ',12)|| --P1 21.78 pos 5520 - A REMPLIR (v1.5)
		RPAD(' ',1)|| --P1 21.94 pos 5532 - A REMPLIR (v1.5)
		RPAD(' ',2)|| --P1 21.95 pos 5533 - A REMPLIR (v1.5)
		RPAD(' ',1)|| --P1 21.79 pos 5535 => point fermé
		RPAD(NVL(C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE,' '),3)|| --P1 21.80 pos 5536
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10)|| --P1 21.81 pos 5539 
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10)|| --P1 21.82 pos 5549
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE  
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 - VIDE
		 LPAD(' ', 24)   -- 5100 - 4922 --MANTIS 11611 (VFN) 27/07/2021 -- Mantis 11841 
     as lignedetail2
	 --Fin EMM
    from 
    ENG_CORP_P1  C_ENR
    WHERE A_EXTRAIRE = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
    AND   NVL(CD_ARR_PAIEMENT, 'N')= 'Y'  
    AND nvl(FLAG_HN , 'N')    = 'N'
    --AND nvl(mnt_solde,0) >= 1
      AND nvl(MNT_SOLD_K_A,0)>=1 -- 17/07/2019 - CDS ATOS (LFD) - Mantis 48678
    AND CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
    AND ( CD_TYPE_RISQUE NOT LIKE 'TRE2%'
    );
  
------------------------------------------------------------------------------------------------------------------------
-- E04c: a partir de C_ENG_CORP_P1_AVEC_IMP2  
------------------------------------------------------------------------------------------------------------------------

    select  
         to_char(C_ENR.dt_arrete, 'YYYYMMDD')||
       RPAD(NVL(C_ENR.CD_CONSO_CPT,' '), 5)||
       RPAD(NVL(C_ENR.APPLI_SOURCE,'C_BTR'), 12)||  -- 18/02/2019 - CDS ATOS (GBD) - US731
       'M'||
       :MASYSDATE||
       'P1'||
       RPAD(' ', 10)||  -- longueur : 1+2+7
       RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||
       --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS, ' '), 10)||   --dans la synthese il est dit a blanc pour les tre5 mais aujourd hui nous la renseignons pour tous
       RPAD(' ', 10)||
       RPAD(NVL(C_ENR.ID_AUTORISATION, ' '), 30)||
       RPAD(NVL(C_ENR.ID_LIGNE_DET, ' '), 30)||
       RPAD(' ', 40)||
       RPAD(C_ENR.ID_ENGAGEMENT || '_C',40)||  --pour les TRE2 a TRE4 pas de champ mais c'est une clef de la table -- a revoir si besoin
       RPAD(' ', 40)||
       RPAD(' ', 20)||
       RPAD(NVL(C_ENR.CD_METHODO_BALE2, 'STD'),7)||
       RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR, '01'),2)||  -- M56405 change code moteur de 07 a 01
       'Y'||
       RPAD(C_ENR.CD_TYPE_RISQUE,6)||
       NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,'B')||
       RPAD(C_ENR.CD_LIGNE_METIER,5)||
       RPAD(C_ENR.CD_PORTEFEUILLE_BALE2,3)||
       RPAD(nvl(C_ENR.CD_NATURE_OPE, 'NA020'),12)||
       RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8)||
       NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'),'99990630')||
       RPAD(' ', 10)||   --1+4+5
       pack_utilitaire.F_FORMAT_TAUX(0)||
       pack_utilitaire.F_FORMAT_TAUX(0)||
--       
--       RPAD(' ', 10)||    --taux ponderation baloise
       pack_utilitaire.f_format_montant_bis2(0) ||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(' ', 50)||	-- Fin 3.1
      --06/02/2019 - CDS ATOS (SQN) US 654
       --RPAD(' ', 10)|| --2 + 8 | Fin 3.2
       RPAD(' ', 2)|| 
       RPAD(NVL(TO_CHAR(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '), 8)||
       --Fin SQN
       -- Debut 3.2Bis
      --NVL(C_ENR.CD_ARR_PAIEMENT, 'N')|| -- US 263 - KLx Risque (VDC) - On met Ã§a pour le moment
      'N'|| -- US 263 A VOIR
       NVL(C_ENR.CD_IMP_PRUDENT, 'N')||
       NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')||
       Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then to_char(nvl(C_ENR.DT_ENG_DOUTEUX,C_ENR.dt_arrete), 'YYYYMMDD')
       else RPAD(' ', 8) END||
       RPAD(' ',1)||RPAD(' ',16)||RPAD(' ',2)|| -- P1 4.2
    --Fin - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR'), 3) ||
       RPAD (' ', 19)|| -- 1+16+2   P1.4.4
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, ' '),3,' ')||  -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_RISQUE),0))|| -- crd brut
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE401' THEN RPAD(' ',22) ELSE
       pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_LOYER,0)) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14
       RPAD(NVL(C_ENR.CD_DEVISE_CRD, 'EUR'), 3)                  -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
    END ||
       RPAD (' ', 22)|| -- 1+16+2+3
       RPAD (nvl(C_ENR.PCCO_MNT_CRD,' '), 12)||
       pack_utilitaire.f_format_montant_bis2(0) ||
       RPAD(NVL(C_ENR.CD_DEVISE_MNT_RISQ, ' '), 3)||
       RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
       RPAD (' ', 10)|| -- 1+4+5
       CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(0) END||
       CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 3) ELSE 'EUR' END||
       RPAD (nvl(C_ENR.CD_CIRCUIT_DISTRIB, 'CL'),2)||--
       RPAD (' ', 61)||  --1+20+10+2+1+25+2
       --C_ENR.CD_ACHAT_FIN_LOC||
       NVL(C_ENR.CD_USAGE_BIEN_IMM,' ')||
       NVL(C_ENR.CD_RESPECT_COND, ' ')||
       -- 08/12/2020 - CDS ATOS (CPD) - US 238 - Anacredit Leasing- Revoir la rï¿½gle d'alimentation des montant CBI en cas d'arriï¿½rï¿½
       -- Debut 3.4Bis
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR),0)) else RPAD (' ', 19) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2' and MNT_VTR_PDR
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then RPAD(C_ENR.CD_DEV_VTR,3) else RPAD (' ', 3) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2'
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_HYPOTHEQUE),0)) else RPAD (' ', 19) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2'
       Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then RPAD(C_ENR.CD_DEV_HYPOTH,3) else RPAD (' ', 3) END|| -- M65476 Removed C_ENR.CD_USAGE_BIEN_IMM = '2'
       -- fin CPD
       --US731 Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then RPAD(nvl(C_ENR.CD_LOC_BIEN, 'FR'), 2) ELSE  RPAD(nvl(C_ENR.CD_LOC_BIEN, ' '), 2) END ||
        RPAD(nvl(C_ENR.CD_LOC_BIEN, ' '), 2,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 3.44
       --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
       --Nvl(C_ENR.CD_ACHAT_FIN_LOC, '2')||
       C_ENR.CD_ACHAT_FIN_LOC||
       --Fin
       pack_utilitaire.f_format_montant_bis2(0)||
         RPAD(nvl(C_ENR.CD_DEVISE_VR,'EUR'),3)||
         --RPAD (' ', 638)||
       RPAD(nvl(C_ENR.cla_comp_ref_act,' '),3)||
       --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
       -- DEBUT: projet OMP - sous-tache SIRL-237
       RPAD(' ', 185)||                                 -- P1 3.56 jusq'au P1 3.74
       RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP
       RPAD(' ', 354)||                                 -- P1 3.80 jusq'au P1 16.19
       -- FIN: projet OMP - sous-tache SIRL-237
		RPAD(' ', 1) ||
		RPAD(' ', 1) ||
		RPAD(' ', 1) ||
		RPAD(' ', 2) ||
		RPAD(' ', 3) || -- Fin 3.5 a 3.10
	--Fin EMM
        -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.31
        RPAD(C_ENR.IND_PROD_SS_JACENT, 1,' ')||  -- P1 4.31   20/03/19 (EMM)
       --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	   RPAD (' ', 38)||
		RPAD(' ', 1) ||
		RPAD(' ', 4) ||
		RPAD (' ', 24)||
		--Fin EMM 
     Substr(pack_utilitaire.F_FORMAT_TAUX (nvl(C_ENR.MATURITE_EFF,0))  ,4,6)||  
     RPAD(C_ENR.TOP_ENG, 1)||	--P1 4.8
     RPAD (' ', 5)||
		 RPAD(nvl(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
     RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8)|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
     RPAD (' ', 7)||
     RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS, 'YYYYMMDD'), ' '), 8)||    --DT_DISPO_FONDS
     RPAD (' ', 1)||
     --Fin SQN
     RPAD (' ', 60)||
     RPAD (' ', 74)||
     Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END ||
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 3)||
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 45)||
		 RPAD (' ', 10)||
		 --Fin EMM
         RPAD (' ', 35)||
         RPAD (' ', 466)||
         RPAD(nvl(C_ENR.EVENMT_CRDT,' '),1)||
         RPAD(nvl(C_ENR.NAT_CONT_EVENMT_CRDT,' '),1)||
         RPAD(nvl(C_ENR.STA_CRDT,' '),1)||                                            --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.5)
         RPAD(nvl(C_ENR.IND_CRE_PERF,' '),2)||
         RPAD (NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8)||        --04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.7)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_COMM, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_RSQ, 'YYYYMMDD'), ' '), 8)||
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.10)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.11)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.12)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.13)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8) END ||                --03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.14)
         CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN RPAD(' ',8)    ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8) END ||                --04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.15)
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 16)||
         RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL, 'YYYYMMDD'), ' '), 8)||    --DT_PL_NPL
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 --Fin EMM
         --Fin SQN
         RPAD(nvl(C_ENR.IND_PROD_ECH,' '),3)||
         RPAD(nvl(C_ENR.IND_OBJ_MET_PAL,' '),1)||
         RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
         RPAD(nvl(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
         RPAD (' ', 45)||
                 RPAD(nvl(C_enr.NOTE_FIN_RET_ORI, 'ND'),2)|| 		--P1 22.5
         RPAD(nvl(C_ENR.NOTE_EXT_ORI,' '),10)||
         --RPAD(nvl(C_ENR.ORG_NOT_ORI,' '),2)||
        RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||    -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
         RPAD(nvl(C_ENR.SEG_NOT_ORI,' '),2)||
         --RPAD(nvl(C_ENR.GRI_MOD_NOT_ORI,' '),46)||
         CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
         ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
         --RPAD(upper(nvl(C_ENR.METH_NOT_ORI,' ')),3)||
     CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999'
     ELSE RPAD(upper(nvl(C_ENR.METH_NOT_ORI,' ')),3) END||
         RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2)||		--P1 22.7
         pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
         RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3) ||--P1 22.9 : Devise du montant du contrat ? l'origine
         RPAD(nvl(C_ENR.IND_ECH_FOUR,' '),1)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_INT_EFF_ORI)||
         RPAD(nvl(C_ENR.TYPE_TAUX,' '),1)||
         RPAD(nvl(C_ENR.IND_REF,' '),12)||
         RPAD(nvl(C_ENR.TYPE_AMOR_CAP,' '),1)||
         RPAD(nvl(C_ENR.PRD_AMOR_CAP,' '),1)||
         RPAD(nvl(C_ENR.PRD_PMT_INT,' '),1)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_OCT)||
         RPAD(nvl(C_ENR.MOD_REMB_CRE,' '),1)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_PREM_ECH, 'YYYYMMDD'), ' '), 8)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_DIFF_AMOR, 'YYYYMMDD'), ' '), 8)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAFOND)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLANCHER)||
         RPAD(nvl(C_ENR.PRD_REV_TAUX_UNIT_TMP,' '),1)||
         LPAD(nvl((C_ENR.PRD_REV_TAUX_NBR),0),3,0)||
                 pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_PRD_EN_CRS)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_ADD)||
         pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_MULT)||
         RPAD(nvl(C_ENR.BASE_CAL_INT,' '),7)||
          -- 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale 
        RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DBLQ_FONDS, 'YYYYMMDD'), ' '), 8)||
-- 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430 => Mettre dans blancs si le montant de premie dï¿½blocage de fond est nul.
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_PREM_DBLQ_FONDS) end || 
-- fin 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430 
         RPAD(nvl(C_ENR.DEVISE_PREM_DBLQ_FONDS,'EUR'),3)||        -- bis2 donne 00000 donc il faut la devise
--         RPAD(' ',3)||
         -- Fin 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale 
         pack_utilitaire.F_FORMAT_MONTANT_BIS2(CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END)||
         RPAD(nvl(C_ENR.DEVI_CAP_THEO_REST,' '),3)||
         RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36 
         RPAD(NVL(TO_CHAR(C_ENR.dt_exigte_prem_impy, 'YYYYMMDD'), ' '), 8)||
         --04/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         --RPAD (' ', 130)||
         RPAD(NVL(TO_CHAR(C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS, 'YYYYMMDD'), ' '), 8)||--P1 22.38 : Date de passage en douteux compromis
         -- SIRL-500
         --RPAD(' ', 122)||
         RPAD(' ', 19)|| -- P1 22.39
         RPAD(' ', 3)|| -- P1 22.40
         RPAD(' ', 8)|| -- P1 22.41
         RPAD(' ', 10)|| -- P1 22.42
         RPAD(' ', 10)|| -- P1 22.43
         pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0))||  --P1 22.44 pos 2703
         RPAD('EUR', 3)|| -- P1 22.45 -- ajout EUR
         RPAD(' ', 8)|| -- P1 22.46
         RPAD(' ', 19)|| -- P1 22.47
         RPAD(' ', 3)|| -- P1 22.48
         RPAD(' ', 10)|| -- P1 22.49
         RPAD(' ', 10)|| -- P1 22.50    
         --Fin - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_PALL, 'YYYYMMDD'), ' '), 8)|| -- P1 22.58
         RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_PALL, 'YYYYMMDD'), ' '), 8)||
         --pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_ECH_EN_COURS)||
         pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(C_ENR.MNT_ECH_EN_COURS)||
         RPAD(nvl(C_ENR.DEVI_MNT_ECH_EN_COURS,' '),3)||
         RPAD(nvl(C_ENR.IND_PRE_POST_FIX,' '),1)||
         RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENVL,'YYYYMMDD'),' '), 8)|| -- P1 22.63 :: projet OMP - sous-tache SIRL-236
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 55)||
         RPAD (' ', 12)||
         RPAD(nvl(C_ENR.CD_PAYS_JURIDICTION, ' '), 2)||    --CD_PAYS_JURIDICTION
         RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8)||    --DT_SIGNATURE
         RPAD (' ', 3)||
         LPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '     '),5,'0')||    --NB_JOURS_RETARD
         CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
         RPAD(nvl(C_ENR.BUCKET_IFRS9,' '),2)||    --BUCKET_IFRS9
         RPAD (' ', 20)||
         --Fin SQN
         RPAD(nvl(C_ENR.ELI_OUT_MUT_PROV,' '),1)||
         RPAD(nvl(C_ENR.CENTRE_RES,' '),7)||
         RPAD(nvl(C_ENR.SYS_GEST_SRC,' '),20)||
         RPAD(nvl(C_ENR.CLA_COMP_ACT_IFRS9,' '),3)||
         RPAD(nvl(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3)||
         RPAD(nvl(C_ENR.IND_ACT_DEP_ORI,' '),1)||
         RPAD(C_ENR.PCCO_MNT_CRD || nvl(C_ENR.ZONE_APP_COMP,' '),40)||
         RPAD (' ', 10)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
         RPAD (' ', 2)||
         RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
         --05/02/2019 - CDS ATOS (SQN) US 662
         --RPAD (' ', 1188) 
         --RPAD (' ', 496)||    --Fin P1 24
         RPAD (' ', 471)||    --Fin P1 24 --BALE4 (24.6)+3(24.37)-28=-25
         RPAD (' ', 178)||    --P1 25
         -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
         --RPAD (' ', 52)|| --P1 26
         RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
		 --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
         RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1)||
		 RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3)||
		 RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3)||
		 RPAD (' ', 44)||
         RPAD (' ', 22)||
		 --07/09/21 CDS_ATOS (EMM) MR 11666
		RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
		--Fin EMM
		RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2) ||
		RPAD (' ', 23)||		 -- Fin P1 27
		--Fin EMM
         -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
         --RPAD (' ', 2)||        --P1 28
         RPAD (nvl(C_ENR.IND_OPE_EFFET_LEVIER,' '), 1)||  --IND_OPE_EFFET_LEVIER
         RPAD (' ', 1)||
         --Fin SQN CRRV4.2 ajout de RG ACODUC
         pack_utilitaire.F_FORMAT_MONTANT_BIS3(C_ENR.MNT_IDEMNITE_RES)||        --MNT_IDEMNITE_RES
         RPAD (nvl(C_ENR.CD_DEV_MNT_INDEMNITE,' '), 3)||        --CD_DEV_MNT_INDEMNITE
         --12/07/21 CDS ATOS (EMM) US 194 CRRv4.3
		 --MANTIS 11611 (VFN) 27/07/2021
	 RPAD(' ',190)|| --Debut P1 30 	|190car sur 250 car dans lignedetail1 
	--Fin MANTIS 11611 
	 --as lignedetail1,  -- debut ligne (taille lignedetail1 =3982)	 
	 -- (compter 1 blanc de separation entre les 2 champs dans le spool)
         --MANTIS 11611 (VFN) 27/07/2021
	  RPAD(' ',6)|| -- Fin 30		
	--Fin MANTIS 11611		
		  'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4		  'N'|| -- M11667 (VFN) 09/09/2021
		  'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 25)||
		 RPAD (' ', 1)||   --fin P1 30 - 78 caracteres sur 250 seront dans lignedetail2 
		 RPAD (' ', 5)|| -- debut P1 31.a
		 RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '), 40)||
		 RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT, ' '), 40)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT), 19) || 
		 RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '), 1)||
     RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
		 RPAD (' ', 6) ||
		 RPAD (' ', 1)||
     RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
     RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 1)||
		 RPAD (' ', 15)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
     --DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
     RPAD ('+', 1)|| -- P1 31.17a
		 case when C_ENR.CD_TYPE_RISQUE like 'TRE%' 
        then LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0') 
        else RPAD('00000',5) 
     end|| -- P1 31.17b
		 RPAD ('+', 1)|| -- P1 31.18a
     case when C_ENR.CD_TYPE_RISQUE like 'TRE%' 
        then LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0') 
        else RPAD('00000',5) 
     end|| -- P1 31.18b
    --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
		 RPAD (' ', 6)||
		 RPAD (' ', 1)||
     RPAD(NVL(C_ENR.CDTYPEGARPRINCOCTROI,' '), 2)|| --Debut P1 31.21 M71371
     -- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
     CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
      END || -- P1 31.22 Type de garantie principale a date
     -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||
		 RPAD (' ', 15)||--Fin 31b 
		 --RPAD(' ', 2)|| --Debut P1 31C
     	 RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 -P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
     	 RPAD(' ',1) || -- Fin P1 31c
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
		 RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
		 RPAD (' ', 22)|| -- Fin 31d		 
     RPAD (' ', 19)|| --Debut 31 e
		 RPAD (' ', 3)|| -- Fin 31e
		 RPAD (' ', 28)|| --Debut - Fin 31f
		 RPAD (' ', 7)|| -- Debut 31 g
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 RPAD (' ', 2)|| --Debut 31h
		 RPAD (' ', 2)||
		 RPAD (' ', 2)||
		 RPAD (' ', 20)||
		 RPAD (' ', 10)||
		 RPAD (' ', 15)||
		 RPAD (' ', 19)||
         RPAD (' ', 3)||
		 RPAD (' ', 19)||
         RPAD (' ', 3)||
		 RPAD (' ', 19)||
		 RPAD (' ', 3)||
		 'EUR'|| --Dï¿½but 50 --M11665 modif VFN
		 RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) ||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
		 RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) ||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(' ',12)||
		 RPAD(' ',19)||
		 RPAD(' ',12)||
		 RPAD(' ',19)||	--Fin 50
		RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2)|| --P1 21.22 pos 4897
		RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8)|| --P1 21.23 pos 4899
    case when C_ENR.DUREE_MRTR is not null then '+'||LPAD(C_ENR.DUREE_MRTR,5,'0') else RPAD(' ',6) end ||--P1 21.29 pos 4907
		RPAD(NVL(C_ENR.STATUT_MRTR,' '),2)|| --P1 21.25 pos 4913
		RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1)|| --P1 21.26 pos 4915
		RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1)|| --P1 21.27 pos 4916
		RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2)|| --P1 21.28 pos 4917
		case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_MRTR),19) else RPAD(' ',19) end || --P1 21.30 pos 4919
		case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV_MRTR,' '),3) else RPAD(' ',3) end || --P1 21.31 pos 4938
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE => point fermé
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE => point fermé
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE => point fermé
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE => point fermé
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE => point fermé
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE => point fermé
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE => point fermé
		RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1)|| --P1 21.44 pos 5133 
		RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1)|| --P1 21.45 pos 5134
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(NVL(C_ENR.IND_IPRE,' '),1)|| --P1 21.38 pos 5136
		RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)|| --P1 21.39 pos 5137
		RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1)|| --P1 21.40 pos 5138
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE => point fermé
 	  RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15)||--P1 21.43 pos 5141
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.57 pos 5157 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.58 pos 5158 - VIDE => point fermé
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE => point fermé
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE => point fermé
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE => point fermé
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE => point fermé
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE => point fermé
		RPAD(NVL(C_ENR.IND_UCC,' '),1)|| --P1 21.66 pos 5222 => point fermé
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE => point fermé
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224 => point fermé
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225 => point fermé
		RPAD(NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END,' '),1)|| --P1 21.69 pos 5237 => point fermé
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE => point fermé
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE => point fermé
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
    RPAD(NVL(C_ENR.COMMUNE,' '),40)|| --P1 21.71 pos 5269
		RPAD(NVL(C_ENR.NUM_VOIE,' '),40)|| --P1 21.72 pos 5309 
		RPAD(NVL(C_ENR.EXTENSION,' '),40)|| --P1 21.73 pos 5349
		RPAD(NVL(C_ENR.TYPE_VOIE,' '),40)|| --P1 21.74 pos 5389 
		RPAD(NVL(C_ENR.LIB_VOIE,' '),40)|| --P1 21.75 pos 5429
		RPAD(NVL(C_ENR.LIEU_DIT,' '),40)|| --P1 21.76 pos 5469
		RPAD(NVL(C_ENR.LATITUDE,' '),11)|| --P1 21.77 pos 5509
		RPAD(NVL(C_ENR.LONGITUDE,' '),12)|| --P1 21.78 pos 5520
		RPAD(' ',1)|| --P1 21.94 pos 5532 - A REMPLIR (v1.5)
		RPAD(' ',2)|| --P1 21.95 pos 5533 - A REMPLIR (v1.5)
		RPAD(' ',1)|| --P1 21.79 pos 5535 => point fermé
		RPAD(NVL(C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE,' '),3)|| --P1 21.80 pos 5536
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10)|| --P1 21.81 pos 5539
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10)|| --P1 21.82 pos 5549 
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE  
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 - VIDE
		 LPAD(' ', 24)   --- 5100 - 4922 --MANTIS 11611 (VFN) 27/07/2021 -- Mantis 11841  
     as lignedetail2
	 --Fin EMM
    from 
    ENG_CORP_P1  C_ENR
    WHERE A_EXTRAIRE = 'O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
    AND   NVL(CD_ARR_PAIEMENT, 'N')= 'Y'   
    AND nvl(FLAG_HN , 'N')  = 'N'
    AND CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
    AND ( CD_TYPE_RISQUE NOT LIKE 'TRE2%')
    AND 
        (NVL(MNT_CRD,0)-NVL(MNT_VR,0) >= 1
        OR
        NVL(MNT_VR,0)>=1)
    ;


    
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
       RPAD(' ', 10)||    --taux pondï¿½ration baloise
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
    -- US 261 - KLx Risque (VDC) [CRRv4.3] Leasing - CRR Corporate - Score 7 'Montant des fonds remis Ã  date '
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
	   pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_INIT_SURETE_SING_CTRT) || --M1 6.8 - Bâle 4 - MR12731 
	   RPAD(' ', 19) || --M1 6.9
	   RPAD(' ', 3) || --M1 6.10
	   RPAD(NVL(C_ENR.SYS_GEST_SRC,' '), 20) ||--KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'SystÃ¨me de gestion source' --M1 1.40
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
    -- Les champs 1.11 et 1.16 ont pas la même regle d'alimentation que dans la table  provisions_decotes_p9 
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
    -- Les champs 1.11 et 1.16 ont pas la même regle d'alimentation que dans la table  provisions_decotes_p9  -- P9 1.16
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
    ELSE RPAD(' ', 40)                                                            -- La regle du spool n'est pas la même que la regle 
  END                                                                          ||    -- d'alimentation de la table provisions_decotes_p9 
  CASE WHEN C_ENR.CD_PERIM_PROV= 'T' THEN RPAD(C_ENR.ID_PROVISION,40)           -- 1.16  :: ID_PROVISION || M72074
    ELSE  RPAD(' ', 40)                                                         -- La regle du spool n'est pas la même que la regle
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
-- E08: a partir de P_UTLF_P1_TRE100            
------------------------------------------------------------------------------------------------------------------------
select
      RPAD(TO_CHAR(C_ENR.DT_ARRETE,'YYYYMMDD'),8,' ')||
      RPAD(TO_CHAR(C_ENR.CD_CONSO_CPT),5,' ')||
      RPAD('C_DDR',12,' ')||
      'M'||
      :MASYSDATE||
      'P1'||
      RPAD(' ',1)||
      RPAD(' ',2)||
      RPAD(' ',7)||    /*?1 - CLE DE REFERENCE */
      RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||--	RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '),10,' ')||
      RPAD(' ', 10)||
      RPAD(NVL(C_ENR.ID_AUTORISATION,' '),30,' ')||
      RPAD(NVL(C_ENR.ID_LIGNE_DET,' '),30,' ')||
      RPAD(' ',40)||
      RPAD(NVL(C_ENR.ID_ENGAGEMENT,' '),40,' ')||
      RPAD(' ',40)||
      RPAD(' ',20)||  /*?2 - INFORMATIONS GENERIQUES */
      RPAD(NVL(C_ENR.CD_METHODO_BALE2,' '),7,' ')||
      RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR,' '),2,' ')||
      RPAD(NVL(C_ENR.CODE_TRAIT_GRR,' '),1,' ')||
      RPAD(NVL(C_ENR.CD_TYPE_RISQUE,' '),6,' ')||
      RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,' '),1,' ')||
      RPAD(NVL(C_ENR.CD_LIGNE_METIER,' '),5,' ')||
      RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3,' ')||
      RPAD(NVL(C_ENR.CD_NATURE_OPE,' '),12,' ')|| /*?3 - DONNEES 3.1 - ELEMENTS COMMUNS */
      RPAD(TO_CHAR(C_ENR.DT_DEBUT_ENG,'YYYYMMDD'),8,' ')||
      RPAD(TO_CHAR(C_ENR.DT_FIN_ENG,'YYYYMMDD'),8,' ')||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(NVL(C_ENR.CD_DEVISE_ORIGINE,' '),3,' ')||   /*?3.2 - PRETS, TITRES DE CREANCE - champs ? blanc car non applicables pour ce type de risque - 10 blancs */
      RPAD(' ',50)||
      RPAD(' ',2)||
      RPAD(' ',8)||    
      /*?3.2BIS- PRETS, CREDIT BAIL ET ENGAGEMENTS PAR SIGNATURE (ss titres de cr?ance)  */
      NVL(C_ENR.CD_ARR_PAIEMENT,'N')|| --P1 5.5 -- 03/12/2021 - KLx Risque (VDC) - US 263 -  CRR Corporate - Score 7 'Indicateur ArriÃ©rÃ© de paiement' 
      RPAD(' ',1)||
      NVL(C_ENR.TOP_ENG_DOUTEUX,'N')|| -- P1 5.2 -- 14/12/2021 - KLx Risque (VDC) - US 260
      RPAD(' ',8)||  --P1 5.3
      /* (CASE
        WHEN C_ENR.MNT_SOLDE >=0
        THEN '+'
        ELSE '-'
      END)||
      LPAD(ABS(TRUNC(C_ENR.MNT_SOLDE)),16,'0')||
      RPAD(' ',2)|| */
       pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_SOLDE),0))|| -- P1 4.2 18/02/2019 - CDS ATOS (GBD) - US731 : deja ok
      RPAD(NVL(C_ENR.CD_DEVISE_SOLDE,' '),3,' ')||
      RPAD(' ',1)||  -- P1 4.4 Montant decouvert
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, ' '),3,' ')||  -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      -- US731 RPAD(' ',1)||    -- P1 4.14
      -- US731 RPAD(' ',16)||
      -- US731 RPAD(' ',2)||
      -- US731 RPAD(' ',3)||    -- P1 4.15
      pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_LOYER) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14
      RPAD(NVL(C_ENR.CD_DEVISE_CRD, ' '), 3,' ')                || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(NVL(C_ENR.PCCO_MNT_SOLDE,' '),12,' ')||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',2)||      /*?3.3 - PRETS, ENGAGEMENTS PAR SIGNATURE - champs ? blanc car non applicables pour ce type de risque - 61 blancs */
      RPAD(' ',1)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',25)||
      RPAD(' ',2)||   /*?3.4 - PR?T immobilier  ET  CREDIT-BAIL immobilier - 2 blancs */
      RPAD(' ',1)||
      RPAD(' ',1)||   /*?3.4Bis - CREDIT-BAIL - champs ? blanc car non applicables pour ce type de risque - 69 blancs */
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||      /* 3.5 - TITRES  - champs ? blanc car non applicables pour ce type de risque - 125 blancs */
      RPAD(nvl(C_ENR.cla_comp_ref_act_s,' '),3)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||     /* 3.6 - TITRES  ET  CREANCES -  champs ? blanc car non applicables pour ce type de risque - 3 blancs */
      RPAD(' ',1)||
      RPAD(' ',2)||     /* 3.6 BIS - TITRES  ET  DERIVES -  champs ? blanc car non applicables pour ce type de risque - 36 blancs */
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',2)||      /* 3.7 - DERIVES - champs ? blanc car non applicables pour ce type de risque - 44 blancs */
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP - sous-tache SIRL-237
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',25)||
      RPAD(' ',1)||
      RPAD(' ',25)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)|| /* 3.9 - CESSIONS TEMPORAIRES DE TITRES - champs ? blanc car non applicables pour ce type de risque - 187 blancs */
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',1)||
      RPAD(' ',1)||      /* 3.10 - DONNEES TITRISATION - champs ? blanc car non applicables pour ce type de risque - 41 blancs */
      RPAD(' ',3)||
      RPAD(' ',5)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',7)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',8)|| /* 4 - DONNEES COMPLEMENTAIRES 4.1 - DONNEES GRANDS RISQUES - champs ? blanc car non applicables pour ce type de risque - 38 blancs */
      RPAD(' ',1)||  --P1 4.31
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',8)||
      RPAD(' ',1)||
      RPAD(' ',29)|| /* 4.2 - COMPLEMENT DE DONNEES CRRV4  (Particularit?s) */
      LPAD(ABS(TRUNC(C_ENR.MATURITE_EFF)),2,'0')||         -- LPAD(NVL(MATURITE_EFF,' ')||2,' ')||
      LPAD(ABS(MOD(C_ENR.MATURITE_EFF *10000,10000)),4,'0')|| --- LPAD(NVL(MATURITE_EFF,' ')||4,' ')
      RPAD(NVL(C_ENR.TOP_ENG, ' '),1,' ')||
      RPAD(' ',3)||
      RPAD(' ',2)||
	    RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '),6,' ')||
      RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8)|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
      RPAD(' ',16)||  
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',30)|| /* 4.2b DONNEES AFFACTURAGE -champs ? blanc car non applicables pour ce type de risque - 74 blancs */
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',30)|| /* 4.2c. DONNEES SUR CREANCES TITRISEES  -champs ? blanc car non applicables pour ce type de risque - 61 blancs */
      RPAD(' ',1)||
      RPAD(' ',50)||
      RPAD(' ',10)|| /* 4.3 - COMPLEMENT DE DONNEES 4.3a? DONNEES CONCERNANT LES TYPES DE RISQUE TRE203  ET  TRE205 (CCP, ..) -champs ? blanc car non applicables pour ce type de risque - 35 blancs */
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',30)||  /* 4.3b DONNEES SOUS-JACENT -champs ? blanc car non applicables pour ce type de risque - 85 blancs */
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',30)|| /* 4.3c- DONNEES CONCERNANT LES DERIVES (y.c. REPOS) --champs ? blanc car non applicables pour ce type de risque - 53 blancs */
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',30)||  /* 4.3d - DONNEES DERIVES -champs ? blanc car non applicables pour ce type de risque - 169 blancs */
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',14)||
      RPAD(' ',1)||
      RPAD(' ',14)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||      /* ZONE LIBRE */
      RPAD(' ',102)||
      RPAD(' ',7)||
      RPAD(' ',137)||
	  --05/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(' ', 2)||
	   RPAD(' ', 2)||
       RPAD(' ', 2)||
	   -- FIN EMM
      RPAD(NVL(C_ENR.IND_PROD_ECH, ' '),3,' ')||
      RPAD(NVL(C_ENR.IND_OBJ_MET_PAL, ' '),1,' ')||
      RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
      RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT, ' '),40,' ')||
      RPAD(' ',45)||
      RPAD(NVL(C_ENR.NOTE_FIN_RET_ORI, 'ND'),2,' ')||
      RPAD(NVL(C_ENR.NOTE_EXT_ORI, ' '),10,' ')||
      --RPAD(NVL(C_ENR.ORG_NOT_ORI, ' '),2,' ')||
      RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||    -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
      RPAD(NVL(C_ENR.SEG_NOT_ORI, ' '),2,' ')||
      --RPAD(NVL(C_ENR.GRI_MOD_NOT_ORI, ' '),46,' ')||
      CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
      ELSE  RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
      RPAD(upper(NVL(C_ENR.METH_NOT_ORI, ' ')),3,' ')||
      RPAD('97',2)||
      --16/01/2018 - CDS ATOS (FAD) - Sprint 4, US 23 - CRRV4.1 Instruments (A)
      --RPAD(' ',22)||
      -- 05/07/2018 - CDS AtoS (FAD) - Mantis 44080 : 
       --  Si le montant du contrat ? l'origine est null alors n'afficher que des blancs pour le montant et la devise associ?e
       --pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat a l'origine
       --RPAD(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 3)||--P1 22.9 : Devise du montant du contrat ? l'origine
       pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat a l'origine
       RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3) ||--P1 22.9 : Devise du montant du contrat a l'origine
       -- Fin - CDS AtoS (FAD) - Mantis 44080
      --Fin - CDS ATOS (FAD) - Sprint 4, US 23 - CRRV4.1 Instruments (A)
      RPAD(NVL(C_ENR.IND_ECH_FOUR, ' '),1,' ')||
                        RPAD(' ',166)||
--08/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - TRE100
      RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36
      -- DEBUT: projet OMP - sous-tache SIRL-236
      -- SIRL-500
      --RPAD(' ', 177)|| -- P1 22.37 jusq'au P1 22.62
      RPAD(' ', 8)|| -- P1 22.37
      RPAD(' ', 8)|| -- P1 22.38
      RPAD(' ', 19)|| -- P1 22.39
      RPAD(' ', 3)|| -- P1 22.40
      RPAD(' ', 8)|| -- P1 22.41
      RPAD(' ', 10)|| -- P1 22.42
      RPAD(' ', 10)|| -- P1 22.43
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0))||  --P1 22.44 pos 2703
      RPAD('EUR', 3)|| -- P1 22.45 -- ajout EUR
      RPAD(' ', 8)|| -- P1 22.46
      RPAD(' ', 19)|| -- P1 22.47
      RPAD(' ', 3)|| -- P1 22.48
      RPAD(' ', 10)|| -- P1 22.49
      RPAD(' ', 10)|| -- P1 22.50
      RPAD(' ', 8)|| -- P1 22.58 
      RPAD(' ', 8)|| -- P1 22.59  
      RPAD(' ', 19)|| -- P1 22.60  
      RPAD(' ', 3)|| -- P1 22.61  
      RPAD(' ', 1)|| -- P1 22.62
      RPAD(' ', 8)||   -- P1 22.63 :: projet OMP - ici doit etre VIDE
      RPAD(' ', 30)||  -- P1 22.64 jusqu'au P1 22.70 
      -- FIN: projet OMP - sous-tache SIRL-236
      --US740  RPAD(NVL(C_ENR.CD_MOTIF_SCO_LC0267, ' '),3,' ')|| -- R?tablissement de CD_MOTIF_SCO_LC0267 --P1_22_71_MOTIF_DU_PASSAGE_EN_ENGAGEMENT_DOUTEUX
      CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ? gauche)
      RPAD(NVL(C_ENR.BUCKET_IFRS9, ' '),2,' ')|| -- Alimentation HN : p_update_origine_p1 --P1_22_72_BUCKET_IFRS9
      RPAD(' ', 20)||
      -- CDS ATOS (JMP) 24/01/2018 ANACREDIT US33 Code motif SCO
                  /*   26/02/2018 CDS ATOS inihibition des ?critures de l'US33         
                        RPAD(' ',215)||
            RPAD(NVL(C_ENR.CD_MOTIF_SCO_LC0267,' '),2,' ')||  -- 2852
                        RPAD(' ',23)||
                                fin   26/02/2018 CDS ATOS inihibition des ?critures de l'US33 */        
        --RPAD(' ',240)||
      -- Fin CDS ATOS (JMP) 24/01/2018 ANACREDIT US33 Code motif SCO
--Fin - CDS AtoS FAD - CRRV4.2 US662 - TRE100
      RPAD(NVL(C_ENR.ELI_OUT_MUT_PROV_S, ' '),1,' ')||
      RPAD(NVL(C_ENR.CENTRE_RES, ' '),7,' ')||
      RPAD(NVL(C_ENR.SYS_GEST_SRC, ' '),20,' ')||
      RPAD(NVL(C_ENR.CLA_COMP_ACT_IFRS9_S, ' '),3,' ')||
      RPAD(NVL(C_ENR.CLA_COMP_ACT_NATIONALE_S, ' '),3,' ')||
      RPAD(NVL(C_ENR.IND_ACT_DEP_ORI, ' '),1,' ')||
      RPAD(NVL(C_ENR.ZONE_APP_COMP, ' '),40,' ')||
     RPAD (' ', 10)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
         RPAD (' ', 2)||
      RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
--     RPAD (' ', 674)|| -- BALE4
     RPAD (' ', 649)|| --BALE4 (24.6)+3(24.37)-28=-25    
      RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
	  --05/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1) ||
	  RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3) ||
	  RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3) ||
	  RPAD(' ',44)|| -- Fin 26
	  RPAD(' ',19)|| --D?but 27
	  RPAD(' ',3)||
	  --07/09/21 CDS_ATOS (EMM) MR 11666
	  RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
	  --Fin EMM
	  RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2)||
	  RPAD(' ',23)|| -- Fin 27	
	  RPAD(' ',2)|| --Debut - Fin 28
	  RPAD(' ',19)|| --Debut 29
	  RPAD(' ',3)|| -- Fin 29
	  --MANTIS 11611 (VFN) 27/07/2021
	 RPAD(' ',190)|| --Debut P1 30 	|189car sur 250 car dans lignedetail1 
	--Fin MANTIS 11611
	-- as lignedetail1,  --  (taille lignedetail1 = 4000) -- BALE4
	 -- (compter 1 blanc de separation entre les 2 champs dans le spool)
	 --MANTIS 11611 (VFN) 27/07/2021
	  RPAD(' ',6)|| 		
	--Fin MANTIS 11611	
	  'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
	  'N'|| -- M11667 (VFN) 09/09/2021
	  RPAD (' ', 25)||
	  RPAD (' ', 1)||   --fin P1 30 - 60 caracteres sur 250 seront dans lignedetail2
	  RPAD(' ',5)|| --Debut 31a
	  RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
	  RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19)  ||
	  RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '),1,' ')||
  	RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
	  RPAD(' ',6)||
	  RPAD(' ',1)|| --Fin 31a
    RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
    RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
	  RPAD(' ', 40)|| -- KLx : Mantis 64749
    --DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
    RPAD('+',1)|| -- P1 31.17a 
    RPAD('00000',5)|| -- P1 31.17b   
    RPAD('+',1)|| -- P1 31.18a 
    RPAD('00000',5)|| -- P1 31.18b
    --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
	  RPAD(' ', 6)|| --Debut P1 31.19 
	  RPAD(' ', 1)|| --Debut P1 31.20
	  RPAD(' ', 2)|| --Debut P1 31.21
	  -- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
    CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
    END || -- P1 31.22 Type de garantie principale a date
	  RPAD(' ', 97)|| --Fin 31b 
    -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
	  --RPAD(' ', 2)|| --Debut P1 31C
    RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 -P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
    RPAD(' ',1) || -- Fin P1 31c
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
	  RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
	  RPAD (' ', 22)|| -- Fin 31d
	  RPAD(' ',22)||-- Debut 31e
	  RPAD(' ',28)||-- Debut 31f
	  RPAD(' ',169)||-- Debut 31g
	  RPAD(' ',117)||-- Debut 31h
	  'EUR'|| --Debut 50 --M11665 modif VFN
	  RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12)||
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) ||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) ||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
      RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)||
	  RPAD(' ',19)||	--Fin 50
		RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2)|| --P1 21.22 pos 4897
		RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8)|| --P1 21.23 pos 4899
    case when C_ENR.DUREE_MRTR is not null then '+'||LPAD(C_ENR.DUREE_MRTR,5,'0') else RPAD(' ',6) end ||--P1 21.29 pos 4907
		RPAD(NVL(C_ENR.STATUT_MRTR,' '),2)|| --P1 21.25 pos 4913
		RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1)|| --P1 21.26 pos 4915
		RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1)|| --P1 21.27 pos 4916
		RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2)|| --P1 21.28 pos 4917
		case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_MRTR),19) else RPAD(' ',19) end || --P1 21.30 pos 4919
		case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV_MRTR,' '),3) else RPAD(' ',3) end || --P1 21.31 pos 4938
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE 
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE  
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE  
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE 
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE 
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE
		RPAD(' ',1)|| --P1 21.44 pos 5133 - VIDE
		RPAD(' ',1)|| --P1 21.45 pos 5134 - VIDE
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(' ',1)|| --P1 21.38 pos 5136 - VIDE
		RPAD(' ',1)|| --P1 21.39 pos 5137 - VIDE
		RPAD(' ',1)|| --P1 21.40 pos 5138 - VIDE
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE
		RPAD(' ',15)|| --P1 21.43 pos 5141 - VIDE
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE
		RPAD(' ',1)|| --P1 21.57 pos 5157 - VIDE
		RPAD(' ',1)|| --P1 21.58 pos 5158 - VIDE
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE 
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE 
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE 
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE 
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE 
		RPAD(' ',1)|| --P1 21.66 pos 5222 - VIDE
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225
		RPAD(' ',1)|| --P1 21.69 pos 5237 - VIDE 
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE 
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE 
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268 - TRE100
		RPAD(' ',40)|| --P1 21.71 pos 5269 - VIDE 
		RPAD(' ',40)|| --P1 21.72 pos 5309 - VIDE 
		RPAD(' ',40)|| --P1 21.73 pos 5349 - VIDE 
		RPAD(' ',40)|| --P1 21.74 pos 5389 - VIDE 
		RPAD(' ',40)|| --P1 21.75 pos 5429 - VIDE 
		RPAD(' ',40)|| --P1 21.76 pos 5469 - VIDE 
		RPAD(' ',11)|| --P1 21.77 pos 5509 - VIDE 
		RPAD(' ',12)|| --P1 21.78 pos 5520 - VIDE 
		RPAD(' ',1)|| --P1 21.94 pos 5532 - VIDE
		RPAD(' ',2)|| --P1 21.95 pos 5533 - VIDE
		RPAD(' ',1)|| --P1 21.79 pos 5535 - VIDE
		RPAD(' ',3)|| --P1 21.80 pos 5536 - VIDE
		RPAD(' ',10)|| --P1 21.81 pos 5539 - VIDE
		RPAD(' ',10)|| --P1 21.82 pos 5549 - VIDE
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 - VIDE    
	  LPAD(' ', 24)   -- 5100 - 4922 --MANTIS 11611 (VFN) 27/07/2021  -- Mantis 11841    
	  as lignedetail2
	 --Fin EMM
   FROM ENG_CORP_P1  C_ENR
    WHERE 1          =1
      AND FLAG_HN      = 'O'
      AND A_EXTRAIRE   ='O'
      and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
      AND CD_TYPE_RISQUE  IN ('TRE100') 
;
 

------------------------------------------------------------------------------------------------------------------------
-- E09: a partir de P_UTLF_P1_TRE2_TRE4          
------------------------------------------------------------------------------------------------------------------------
select
		--EN TETE
		RPAD(TO_CHAR(C_ENR.DT_ARRETE,'YYYYMMDD'),8,' ')||
	  RPAD(TO_CHAR(C_ENR.CD_CONSO_CPT),5,' ')||
	  RPAD('C_DDR',12,' ')||
	  'M'||
	  :MASYSDATE||
	  'P1'||
	  RPAD(' ',1)||
	  RPAD(' ',2)||
	  RPAD(' ',7)||
	  --CLE REFERENCE
	  RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||
	  --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '),10,' ')||
    RPAD(' ', 10)||
	  RPAD(NVL(C_ENR.ID_AUTORISATION,' '),30,' ')||
	  RPAD(NVL(C_ENR.ID_LIGNE_DET,' '),30,' ')||
	  RPAD(' ',40)||
	  RPAD(NVL(C_ENR.ID_ENGAGEMENT,' '),40,' ')||
	  RPAD(' ',40)||
	  RPAD(' ',20)||
	  --INFORMATION GENERIQUES
	  RPAD(NVL(C_ENR.CD_METHODO_BALE2,' '),7,' ')||
	  RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR,' '),2,' ')||
	  RPAD(NVL(C_ENR.CODE_TRAIT_GRR,' '),1,' ')||
	  RPAD(NVL(C_ENR.CD_TYPE_RISQUE,' '),6,' ')||
	  RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,' '),1,' ')||
	  RPAD(NVL(C_ENR.CD_LIGNE_METIER,' '),5,' ')||
	  RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3,' ')||
	  RPAD(NVL(C_ENR.CD_NATURE_OPE,' '),12,' ')||
	  --3
	  --3-1-ELEMENTS COMMUNS
	  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG,'YYYYMMDD'),' '),8,' ') ||
	  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG,'YYYYMMDD'),' '),8,' ') ||
	  RPAD(' ',1)||
	  RPAD(' ',4)||
	  RPAD(' ',5)||
	  RPAD(' ',1)||
	  RPAD(' ',4)||
	  RPAD(' ',5)||
	  RPAD(' ',1)||
	  RPAD(' ',4)||
	  RPAD(' ',5)||
	  RPAD(' ',1)||
	  RPAD(' ',16)||
	  RPAD(' ',2)||
	  RPAD(NVL(C_ENR.DEVISE_EAD,' '),3,' ')||
	  RPAD(NVL(C_ENR.CD_DEVISE_ORIGINE,' '),3,' ')||
	  RPAD(' ',50)||
	  --3-2 PRETS,TITRES DE CREANCE
	  RPAD(NVL(C_ENR.TOP_RESTRUCTURATION,' '),2,' ')||
	  (CASE WHEN NVL(C_ENR.TOP_RESTRUCTURATION,' ') = 'O' THEN
	  RPAD(TO_CHAR(C_ENR.DT_RESTRUCTURATION,'YYYYMMDD'),8,' ')
	  ELSE
	  RPAD(' ',8)
	  END) ||
	  NVL(C_ENR.CD_ARR_PAIEMENT,'N')||  -- US 261 - KLx Risque (VDC) P1 5.5
	  RPAD(NVL(C_ENR.CD_IMP_PRUDENT,' '),1,' ')||
	  RPAD(NVL(C_ENR.TOP_ENG_DOUTEUX,' '),1,' ')||  --P1 5.2
	  (CASE WHEN NVL(C_ENR.TOP_ENG_DOUTEUX,' ') = 'Y' THEN     -- 26/02/2019 - CDS ATOS (GBD) - US740 bonus : corrige le test ( teste 'Y' ald 'O' )
	  RPAD(TO_CHAR(C_ENR.DT_ENG_DOUTEUX,'YYYYMMDD'),8,' ')
	  ELSE
	  RPAD(' ',8)
	  END) ||  -- P1 5.3
    -- 18/02/2019 - CDS ATOS (GBD) - US731   : remplace P1 4.2
	  -- US731 RPAD(' ',1)||
	  -- US731 RPAD(' ',16)||
	  -- US731 RPAD(' ',2)||
	--25/07/2019 - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
	   --pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_SOLDE) || -- 18/02/2019 - CDS ATOS (GBD) - US731  p1 4.2
	   RPAD(' ',1)||RPAD(' ',16)||RPAD(' ',2)|| -- P1 4.2
	--Fin - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
	  RPAD(' ',3)||  --P1 4.3
	  (CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' AND nvl(C_ENR.MNT_SOLDE,0) >=0 THEN
	   	--LPAD(ABS(TRUNC(NVL(C_ENR.MNT_SOLDE,0))),16,'0' )
	   pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_SOLDE),0))
	  	ELSE
	   	RPAD(' ',19)
	   END
	   )||   -- P1 4.4 Montant du decouvert
	   --RPAD(' ',2)||
       -- 18/02/2019 - CDS ATOS (GBD) - US731  :  P1 4.5 remplace
	  -- US731 (CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' AND nvl(C_ENR.MNT_SOLDE,0) >=0 THEN
	  -- US731   	RPAD(NVL(C_ENR.CD_DEVISE_CRD,' '),3,' ') --LPAD(ABS(MOD(NVL(C_ENR.MNT_INT_RD,0) *100,100)),2,'0')
	  -- US731 	ELSE
	  -- US731  	RPAD(' ',3)
	  -- US731  END
	  -- US731  )||
      RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, ' '),3,' ')||  -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
-- 20/03/2019 - CDS AtoS FAD - CRRV4.2 US731 - Complement
	  pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_CRD),0))||  --P1 4.9
	  NVL(C_ENR.CD_DEVISE_CRD,'EUR')|| -- P1 4.13 Devise du capital restant dï¿½
-- Fin - CDS AtoS FAD - CRRV4.2 US731 - Complement
      pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_LOYER) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14
      RPAD(NVL(C_ENR.CD_DEVISE_CRD, ' '), 3,' ')       		 || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
	  RPAD(' ',1)||
	  RPAD(' ',16)||
	  RPAD(' ',2)||
	  RPAD(' ',3)||
	  RPAD(NVL(C_ENR.PCCO_MNT_CRD,' '),12,' ')||
	  (CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN
	    	--LPAD(ABS(TRUNC(NVL(C_ENR.MNT_INT_RD,0))),16,'0' )
		pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_INT_RD),0))
	  	ELSE
	  		RPAD(' ',19)
	   END
	   )||
	  --RPAD(' ',2)||
	  -- 20/03/2019 - CDS AtoS FAD - CRRV4.2 US731 - Complement
	  (
	  	CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN
	    	--RPAD(NVL(C_ENR.CD_DEVISE_CRD,' '),3,' ') --LPAD(ABS(MOD(NVL(C_ENR.MNT_INT_RD,0) *100,100)),2,'0')
			NVL(C_ENR.CD_DEVISE_INT_RD,'EUR')
	  	ELSE
	  		RPAD(' ',3)
	  	END
	   )|| -- P1 4.7 Devise des intï¿½rï¿½ts restant dus
	  -- Fin - CDS AtoS FAD - CRRV4.2 US731 - Complement
	  RPAD(NVL(C_ENR.PCCO_INT_RD,' '),12,' ')||
	  RPAD(' ',1)||
	  RPAD(' ',4)||
	  RPAD(' ',5)||
	  RPAD(' ',1)||
	  RPAD(' ',16)||
	  RPAD(' ',2)||
	  RPAD(' ',3)||
	  RPAD(' ',2)||
	  -- 3.3 PRETS,ENGAGEMENT PAR SIGNATURE
	  RPAD(' ',61)||
	  --3.4 PRET immobilier 
	  RPAD(' ',1)|| -- p1 3.46 ? pos 711 BALE4
	  RPAD(' ',1)|| -- p1 3.47 ? pos 712 BALE4 
	  --3.4Bis-CREDIT-BAIL-camp ï¿½ blanc
	  RPAD(' ',69)||
   	  RPAD(nvl(C_ENR.cla_comp_ref_act,' '),3)||
--08/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
          --RPAD(' ',122)||
	  RPAD(' ', 34)||
	  pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_MTM, 0))|| --P1_3_52_MT_MTM_TITRE
	  --13/02/2019 - CDS ATOS (SQN) - CRRV4.2 - Correctif : devise ï¿½ EUR par dï¿½faut.
	  --RPAD(nvl(C_ENR.CD_DEV_MNT_MTM,' '),3, ' ')|| --P1_3_53_CODE_DEVISE_MTM_TITRE
	  RPAD(nvl(C_ENR.CD_DEV_MNT_MTM,'EUR'),3, ' ')|| --P1_3_53_CODE_DEVISE_MTM_TITRE
	  --Fin Correctif
	  RPAD(' ', 66)||
--Fin - CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  --3.6 TITRES  CREANCE
	  RPAD(' ',1)||
    -- DEBUT: projet OMP - sous-tache SIRL-237
    RPAD(' ', 62)||
    RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP
    RPAD(' ',321)||
    -- FIN: projet OMP - sous-tache SIRL-237
	  --07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  --3.10 DONNES TITRISATION
	  RPAD(' ',33)||
	  RPAD(' ',1)||
	  RPAD(' ',1)||
	  RPAD(' ',1)||
	  RPAD(' ',2)||
	  RPAD(' ',3)||
	  --FIN EMM
	  --4
	  --4.1 DONNEES GRANDS RISQUE
	  RPAD(NVL(C_ENR.IND_PROD_SS_JACENT,' '), 1,' ')||  -- P1 4.31
	  --07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(' ',38)||
	  RPAD(' ',1)||
	  RPAD(' ',4)|| --fin 4.1
	  --Fin EMM 
	  RPAD(' ',24)||
    --modif vfn 
	  LPAD(ABS(TRUNC(NVL(C_ENR.MATURITE_EFF,0))),2,'0')||
	  LPAD(ABS(MOD(NVL(C_ENR.MATURITE_EFF,0) *10000,10000)),4,'0')||
    --fin modif vfn 
	  RPAD(NVL(C_ENR.TOP_ENG,' '),1,' ')||
--08/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  RPAD(' ', 3)||
	  RPAD(' ', 2)||
	  RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
    RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8)|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
	  RPAD(' ', 7)||
	  RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS,'YYYYMMDD'), ' '),8,' ')|| --P1_4_47_DATE_DISPO_FONDS
	  --07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(' ', 1) || --fin 4.2
	  RPAD(' ', 104)||
	  --Fin EMM
	  pack_utilitaire.f_format_taux(C_ENR.TX_ELBE)|| --P1_4_30_EXPECTED_LOSS_BEST_ESTIMATE
	  RPAD(' ', 20)||
--Fin - CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  --DONNEES SUR CREANCES TITRISES
	  RPAD(NVL(C_ENR.IND_CREANCE_TITRI,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.29 
	  --07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(' ',3)||
	  RPAD(' ',1)||
	  RPAD(' ',1)||
	  RPAD(' ',45)||
	  RPAD(' ',10)|| -- 4.2c 
	  RPAD(' ',501)||
	  --FIN EMM
	  RPAD(nvl(C_ENR.EVENMT_CRDT, ' '), 1)||  
	  RPAD(nvl(C_ENR.NAT_CONT_EVENMT_CRDT, ' '), 1)|| 
	  RPAD(nvl(C_ENR.STA_CRDT, ' '), 1)|| 										--03/04/2018 CDS ATOS (EMM) Sprint 7US 218 (P1 21.5)
	  RPAD(NVL(C_ENR.IND_CRE_PERF,' '),2)||
	  RPAD (NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8)||		--05/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.7)
		RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_COMM, 'YYYYMMDD'), ' '), 8)||
		 RPAD(NVL(TO_CHAR(C_ENR.DATE_DER_REST_RSQ, 'YYYYMMDD'), ' '), 8)||
		 CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN RPAD(' ',8)	ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8) END ||				--03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.10)
		 CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN RPAD(' ',8)	ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8) END ||				--03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.11)
		 CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN RPAD(' ',8)	ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8) END ||				--03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.12)
		 CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN RPAD(' ',8)	ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8) END ||				--03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.13)
		 CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN RPAD(' ',8)	ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8) END ||				--03/04/2018 CDS ATOS (EMM) Sprint 7 US 218 (P1 21.14)
		 CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN RPAD(' ',8)	ELSE RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8) END ||				--04/12/2017 CDS ATOS (EMM) Sprint 1 US 27 (P1 21.15)
--08/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	--RPAD (' ', 16)|| 
	RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL,'YYYYMMDD'), ' '),8,' ')|| --P1_21_16_DATE_DEBUT_ETAT_PERFORMANCE_CREANCE
	RPAD(NVL(C_ENR.CD_MOTIF_PL_NPL, ' '), 2, ' ')|| --P1_21_17_MOTIF_ETAT_DE_PERFORMANCE_CREANCE
	--07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	RPAD(' ', 2)||
	RPAD(' ', 2)||
	RPAD(' ', 2)|| --Fin 21
	--Fin EMM
--Fin - CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  RPAD(NVL(C_ENR.IND_PROD_ECH,' '),3)||
	  RPAD(NVL(C_ENR.IND_OBJ_MET_PAL,' '),1)||
    RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
	  RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
	  RPAD(' ',45)||
	  RPAD('ND',2)||
	  RPAD(NVL(C_ENR.NOTE_EXT_ORI,' '),10)||
	  --RPAD(NVL(C_ENR.ORG_NOT_ORI,' '),2)||
	  RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||    -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
	  RPAD(NVL(C_ENR.SEG_NOT_ORI,' '),2)||
	  --RPAD(NVL(C_ENR.GRI_MOD_NOT_ORI,' '),46)|| 
	  CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
          ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
	  RPAD(upper(NVL(C_ENR.METH_NOT_ORI,' ')),3)|| 
	  RPAD('97',2)||
		 pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
		RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3)|| --P1 22.9 : Devise du montant du contrat ? l'origine
		 -- Fin - CDS AtoS (FAD) - Mantis 44080
		--Fin - CDS ATOS (FAD) - Sprint 4, US 23 - CRRV4.1 Instruments (A)
      RPAD(NVL(C_ENR.IND_ECH_FOUR,' '),1)|| 
	  pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_INT_EFF_ORI)||  
--04/06/2019 - CDS AtoS FAD - AER / PALMA US792
	  --RPAD(NVL(C_ENR.TYPE_TAUX,'F'),1)|| --US792
	  RPAD(NVL(C_ENR.TYPE_TAUX,' '),1)||
      RPAD(NVL(C_ENR.IND_REF,' '),12)|| 
      RPAD(NVL(C_ENR.TYPE_AMOR_CAP,' '),1)||   
	  RPAD(NVL(C_ENR.PRD_AMOR_CAP,' '),1)||   
	  RPAD(NVL(C_ENR.PRD_PMT_INT,' '),1)||   
	  pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_OCT)||  
	  RPAD(NVL(C_ENR.MOD_REMB_CRE,' '),1)||   
	  RPAD(NVL(TO_CHAR(C_ENR.DATE_PREM_ECH, 'YYYYMMDD'), ' '), 8)||   
      RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_DIFF_AMOR, 'YYYYMMDD'), ' '), 8)||  
	  pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAFOND)||   
	  pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLANCHER)||  
	  RPAD(NVL(C_ENR.PRD_REV_TAUX_UNIT_TMP,' '),1)||
	  LPAD(nvl((C_ENR.PRD_REV_TAUX_NBR),0),3,0)||
    -- 29/04/2018 CDS Atos (CML) ANACREDIT US785
	  --pack_utilitaire.F_FORMAT_TAUX(0.01)||	
    pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_CLT_PRD_EN_CRS)||
    -- fin US785
	  pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_ADD)||
	  pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_MRG_MULT)||
	  RPAD(NVL(C_ENR.BASE_CAL_INT,' '),7)||
--Fin - CDS AtoS FAD - AER / PALME US792
 		 -- 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale 
		 RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DBLQ_FONDS, 'YYYYMMDD'), ' '), 8)||
-- 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430 => Mettre dans blancs si le montant de premie dï¿½blocage de fond est nul.
		case when C_ENR.MNT_PREM_DBLQ_FONDS is null  then RPAD(' ',19) else pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_PREM_DBLQ_FONDS) end || 
-- fin 16/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US430
		 RPAD(nvl(C_ENR.DEVISE_PREM_DBLQ_FONDS,'EUR'),3)||
		 -- Fin 09/04/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Version finale
	  pack_utilitaire.F_FORMAT_MONTANT_BIS2( CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END)||		--P1 22.34
	  RPAD(NVL(C_ENR.DEVI_CAP_THEO_REST,' '),3)||   --P1 22.35
    RPAD('3',1)||-- P1 22.36
    --SIRL-500      
	  --RPAD(' ',138)||
    RPAD(' ', 8)|| -- P1 22.37
    RPAD(' ', 8)|| -- P1 22.38
    RPAD(' ', 19)|| -- P1 22.39
    RPAD(' ', 3)|| -- P1 22.40
    RPAD(' ', 8)|| -- P1 22.41
    RPAD(' ', 10)|| -- P1 22.42
    RPAD(' ', 10)|| -- P1 22.43
    pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0))||  --P1 22.44 pos 2703
    RPAD('EUR', 3)|| -- P1 22.45 -- ajout EUR
    RPAD(' ', 8)|| -- P1 22.46
    RPAD(' ', 19)|| -- P1 22.47
    RPAD(' ', 3)|| -- P1 22.48
    RPAD(' ', 10)|| -- P1 22.49
    RPAD(' ', 10)|| -- P1 22.50
	  RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_PALL, 'YYYYMMDD'), ' '), 8)|| -- P1 22.58 
	  RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_PALL, 'YYYYMMDD'), ' '), 8)|| -- P1 22.59
	  --pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ECH_EN_COURS)||
	  pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(C_ENR.MNT_ECH_EN_COURS)||  -- P1 22.60 
	  RPAD(NVL(C_ENR.DEVI_MNT_ECH_EN_COURS,' '),3)||                    -- P1 22.61 
	  RPAD(NVL(C_ENR.IND_PRE_POST_FIX,' '),1)||                         -- P1 22.62
    RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENVL,'YYYYMMDD'),' '), 8)||  -- P1 22.63 :: projet OMP - sous-tache SIRL-236
--08/02/2019- CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  --RPAD(' ',55)||
	  RPAD(' ', 2)||--P1 22.64
	  RPAD(' ', 10)||--P1 22.65
	  RPAD(NVL(C_ENR.CD_PAYS_JURIDICTION, ' '), 2, ' ')|| --P1_22_66_PAYS_JURIDICTION_CONTRAT
	  RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE,'YYYYMMDD'), ' '),8,' ')|| --P1_22_67_DATE_SIGNATURE_CONTRAT_INITIAL
	  RPAD(' ', 2)||--P1_22_68_EVENEMENT_DECLENCHEUR_DE_LA_GARANTIE
	  RPAD(' ', 1)||--P1_22_69_INDICATEUR_DIFFERE_CARTE_DE_PAIEMENT
	  LPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '     '),5,'0')|| --P1_22_70_NOMBRE_DE_JOURS_DE_RETARD_DE_PAIEMENT
	  --US740 RPAD(NVL(C_ENR.CD_MOTIF_SCO_LC0267, ' '), 3, ' ')|| -- Rï¿½tablissement de CD_MOTIF_SCO_LC0267 --P1_22_71_MOTIF_DU_PASSAGE_EN_ENGAGEMENT_DOUTEUX
      CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
	  RPAD(NVL(C_ENR.BUCKET_IFRS9, ' '), 2, ' ')|| -- Alimentation HN : p_update_origine_p1 --P1_22_72_BUCKET_IFRS9
	  RPAD(' ', 10)||--P1 22.73
	  RPAD(' ', 10)||--P1 22.74
--Fin- CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  RPAD(NVL(C_ENR.ELI_OUT_MUT_PROV,' '),1)||	  
	  RPAD(NVL(C_ENR.CENTRE_RES,' '),7)||
	  RPAD(NVL(C_ENR.SYS_GEST_SRC,' '),20)||
	  RPAD(NVL(C_ENR.CLA_COMP_ACT_IFRS9,' '),3)||
	  RPAD(NVL(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3)||
	  RPAD(NVL(C_ENR.IND_ACT_DEP_ORI,' '),1)||	
	  RPAD(NVL(C_ENR.ZONE_APP_COMP,' '),40)||	
    RPAD (' ', 10)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
		 RPAD (' ', 2)||
      RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
--08/02/2019- CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
	  --RPAD(' ',1188)
	  --RPAD(' ', 674)||
    RPAD(' ', 649)|| -- BALE4
	  RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
	  --07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1) ||
	  RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3) ||
	  RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3) ||
	  RPAD(' ',44)|| -- Fin 26
	  RPAD(' ',19)|| --Dï¿½but 27
	  RPAD(' ',3)||
	  --07/09/21 CDS_ATOS (EMM) MR 11666
	  RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
	  --Fin EMM
	  RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2)||
	  RPAD(' ',23)|| -- Fin 27	
	  --FIN EMM
	  RPAD (nvl(C_ENR.IND_OPE_EFFET_LEVIER, ' '), 1, ' ')|| --P1_28_1_INDICATEUR_OPERATION_EFFET_DE_LEVIER
	  RPAD (nvl(C_ENR.IND_SPONSOR_FIN, ' '), 1, ' ')|| --P1_28_2_IND_SPONSOR_FINANCIER_MAJOR_AU_CAPITAL
--Fin- CDS AtoS FAD - CRRV4.2 US662 - TRE2_TRE4
     --07/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	 RPAD(' ',19)|| --Dï¿½but 29
	 RPAD(' ',3)|| -- Fin 29
	  --MANTIS 11611 (VFN) 27/07/2021
	 RPAD(' ',190)|| --Debut P1 30 	|189car sur 250 car dans lignedetail1 
	--Fin MANTIS 11611
	-- as lignedetail1,  --  (taille lignedetail1 = 4000)
	 -- (compter 1 blanc de separation entre les 2 champs dans le spool)
	--MANTIS 11611 (VFN) 27/07/2021
	  RPAD(' ',6)|| 		
	--Fin MANTIS 11611	
	  'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
	  'N'|| -- M11667 (VFN) 09/09/2021
	  RPAD (' ', 25)||
	  RPAD (' ', 1)||   --fin P1 30 - 60 caracteres sur 250 seront dans lignedetail2
	 RPAD(' ',5)|| --Dï¿½but 31a
	  RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
	  RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT,' '),40)||
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19) ||
	  RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '),1,' ')||
  	RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
	  RPAD(' ',6)||
	  RPAD(' ',1)|| --Fin 31a
	  RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| --Debut 31b 31.9
	  RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10
	  RPAD(' ', 1)||
	  RPAD(' ', 1)||
	  RPAD(' ', 1)||
	  RPAD(' ', 15)||
	  RPAD(' ', 19)||
	  RPAD(' ', 3)||
	  --DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
    RPAD ('+', 1)|| -- P1 31.17a
		LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0')|| -- P1 31.17b
		RPAD ('+', 1)|| -- P1 31.18a
    LPAD(nvl(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30),'00000'),5, '0')|| -- P1 31.18b
    --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
	  RPAD(' ', 6)||
	  RPAD(' ', 1)||
    RPAD(NVL(C_ENR.CDTYPEGARPRINCOCTROI,' '), 2)|| --Debut P1 31.21 M71371
	  -- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
    CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
    END || -- P1 31.22 Type de garantie principale a date
    -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
	  RPAD(' ', 19)||
	  RPAD(' ', 3)||
	  RPAD(' ', 15)||
	  RPAD(' ', 15)||
	  RPAD(' ', 15)||
	  RPAD(' ', 15)||
	  RPAD(' ', 15)||
	  --RPAD(' ', 2)|| --Debut P1 31C
    RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 - P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
    RPAD(' ',1) || -- Fin P1 31c
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
	  RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
	  RPAD (' ', 22)|| -- Fin 31d	  
    RPAD(' ',19)||-- Debut 31e
	  RPAD(' ',3)||
	  RPAD(' ',1)||-- Debut 31f
    RPAD(' ',1)||
    RPAD(' ',8)||
    RPAD(' ',8)||
    RPAD(' ',1)||
    RPAD(' ',8)||
    RPAD(' ',1)||
	  RPAD(' ',7)||-- Debut 31g
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
	  RPAD(' ',2)||-- Debut 31h
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
	  'EUR'|| --Debut 50 --M11665 modif VFN
	  RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12)||
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) ||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
	  RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) ||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)||
	  RPAD(' ',19)||
	  RPAD(' ',12)||
	  RPAD(' ',19)||	--Fin 50
		RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2)|| --P1 21.22 pos 4897
		RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8)|| --P1 21.23 pos 4899
    case when C_ENR.DUREE_MRTR is not null then '+'||LPAD(C_ENR.DUREE_MRTR,5,'0') else RPAD(' ',6) end ||--P1 21.29 pos 4907
		RPAD(NVL(C_ENR.STATUT_MRTR,' '),2)|| --P1 21.25 pos 4913
		RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1)|| --P1 21.26 pos 4915
		RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1)|| --P1 21.27 pos 4916
		RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2)|| --P1 21.28 pos 4917
		case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_MRTR),19) else RPAD(' ',19) end || --P1 21.30 pos 4919
		case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV_MRTR,' '),3) else RPAD(' ',3) end || --P1 21.31 pos 4938
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE
		RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1)|| --P1 21.44 pos 5133
		RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1)|| --P1 21.45 pos 5134
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(NVL(C_ENR.IND_IPRE,' '),1)|| --P1 21.38 pos 5136
		RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)|| --P1 21.39 pos 5137
		RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1)|| --P1 21.40 pos 5138
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE
 	  RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15)||--P1 21.43 pos 5141
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE
		RPAD(NVL(C_ENR.IND_INVEST_CAPITAL_RISQ,' '),1)|| --P1 21.57 pos 5157 
		RPAD(NVL(C_ENR.IND_INVEST_PROG_LEGISLATIF,' '),1)|| --P1 21.58 pos 5158 
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE
		RPAD(NVL(C_ENR.IND_UCC,' '),1)|| --P1 21.66 pos 5222 
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225
		RPAD(' ',1)|| --P1 21.69 pos 5237 - VIDE
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
		RPAD(NVL(C_ENR.COMMUNE,' '),40)|| --P1 21.71 pos 5269
		RPAD(NVL(C_ENR.NUM_VOIE,' '),40)|| --P1 21.72 pos 5309 
		RPAD(NVL(C_ENR.EXTENSION,' '),40)|| --P1 21.73 pos 5349
		RPAD(NVL(C_ENR.TYPE_VOIE,' '),40)|| --P1 21.74 pos 5389 
		RPAD(NVL(C_ENR.LIB_VOIE,' '),40)|| --P1 21.75 pos 5429
		RPAD(NVL(C_ENR.LIEU_DIT,' '),40)|| --P1 21.76 pos 5469
		RPAD(NVL(C_ENR.LATITUDE,' '),11)|| --P1 21.77 pos 5509
		RPAD(NVL(C_ENR.LONGITUDE,' '),12)|| --P1 21.78 pos 5520
		RPAD(' ',1)|| --P1 21.94 pos 5532 - VIDE
		RPAD(' ',2)|| --P1 21.95 pos 5533 - VIDE
		RPAD(' ',1)|| --P1 21.79 pos 5535 - VIDE
		RPAD(' ',3)|| --P1 21.80 pos 5536 - VIDE
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10)|| --P1 21.81 pos 5539
		RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10)|| --P1 21.82 pos 5549 
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626   - VIDE
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 - VIDE   
      LPAD(' ', 24)   -- 5100 - 4922 --MANTIS 11611 (VFN) 27/07/2021 -- Mantis 11841 
     as lignedetail2
	 --Fin EMM
FROM ENG_CORP_P1 C_ENR
WHERE 1     =1
  AND FLAG_HN = 'O'
  AND A_EXTRAIRE      ='O'
    and (C_ENR.cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
  --CDS_ATOS (MNE) - 20/05/2021 - Mantis 57292 - Eevolution de la rï¿½gle de gestion pour restructuration
  --AND ( CD_TYPE_RISQUE LIKE 'TRE2%' OR CD_TYPE_RISQUE LIKE 'TRE4%' )
  AND SUBSTR(CD_TYPE_RISQUE,1,4) in ('TRE2','TRE4','TRE5')
  --FIN MNE
;


------------------------------------------------------------------------------------------------------------------------
-- E10: a partir de P_UTLF_P1_EQU101             
------------------------------------------------------------------------------------------------------------------------
select
			RPAD(TO_CHAR(C_ENR.DT_ARRETE,'YYYYMMDD'),8,' ')||
			RPAD(TO_CHAR(C_ENR.CD_CONSO_CPT),5,' ')||
			RPAD('C_DDR',12,' ')||
			'M'||
			:MASYSDATE||
			'P1'||
			RPAD(' ',1)||
			RPAD(' ',2)||
			RPAD(' ',7)||
			/*n1 - CLE DE REFERENCE*/
			RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||
			--RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '),10,' ')||
			RPAD(' ', 10)||
			RPAD(NVL(C_ENR.ID_AUTORISATION,' '),30,' ')||
			RPAD(NVL(C_ENR.ID_LIGNE_DET,' '),30,' ')||
			RPAD(' ',40)||
			RPAD(NVL(C_ENR.ID_ENGAGEMENT,' '),40,' ')||
			RPAD(' ',40)||
			RPAD(' ',20)||
			/*n2 - INFORMATIONS GENERIQUES*/
			RPAD(NVL(C_ENR.CD_METHODO_BALE2,' '),7,' ')||
			RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR,' '),2,' ')||
			RPAD(NVL(C_ENR.CODE_TRAIT_GRR,' '),1,' ')||
			RPAD(NVL(C_ENR.CD_TYPE_RISQUE,' '),6,' ')||
			RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,' '),1,' ')||
			RPAD(NVL(C_ENR.CD_LIGNE_METIER,' '),5,' ')||
			RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3,' ')||
			RPAD(NVL(C_ENR.CD_NATURE_OPE,' '),12,' ')||
			/*n3 - DONNEES*/
			/*n3.1 - ELEMENTS COMMUNS*/
			RPAD(TO_CHAR(C_ENR.DT_DEBUT_ENG,'YYYYMMDD'),8,' ')||
			RPAD(TO_CHAR(C_ENR.DT_FIN_ENG,'YYYYMMDD'),8,' ')||
			RPAD(' ',1) ||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(NVL(C_ENR.CD_DEVISE_ORIGINE,' '),3,' ')||
			RPAD(' ',50)||
			RPAD(' ',2)||
			RPAD(' ',8)||
			NVL(C_ENR.CD_ARR_PAIEMENT,'N')|| -- P1 5.5 -- us 263 - KLx Risque (VDC) - CRR Corporate - Score 7 'Indicateur ArriÃ©rÃ© de paiement'
			RPAD(' ',1)|| -- P1 4.1
			--29/04/2018 - CDS ATOS (FCU) - US787 : Top engagement douteux pour type de risque EQU101
			RPAD(NVL(C_ENR.TOP_ENG_DOUTEUX,' '),1, ' ')||  -- P1 5.2  eng douteux
			--Fin - CDS ATOS (FCU) - US787 : Top engagement douteux pour type de risque EQU101
			RPAD(' ',8)||  -- P1 5.3  date eng douteux
			RPAD(' ',1)||  -- P1 4.2 18/02/2019 - CDS ATOS (GBD) - US731  : RAS : pas de MNT_SOLDE dans EQU101
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||  -- P1 4.5 18/02/2019 - CDS ATOS (GBD) - US731  : RAS : pas de CD_DEVISE_MNT_DECOUVERT dans EQU101
			RPAD(' ',1)||  -- P1 4.9
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||  -- P1 4.14 18/02/2019 - CDS ATOS (GBD) - US731  : RAS : pas de montant loyer ds EQU101
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||  -- P1 4.15 
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',12)||  -- P1 4.18
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',12)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',2)||
			RPAD(' ',1)||
			RPAD(' ',20)||
			RPAD(' ',10)||
			RPAD(' ',2)||
			RPAD(' ',1)||
			RPAD(' ',25)||
			RPAD(' ',2)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',2)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(NVL(C_ENR.CD_CPT_ACTIF_IAS,' '),3,' ')||
			RPAD(NVL(C_ENR.PCCO_ACQUISITION,' '),12,' ')||
			pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISITION),0))||	
			RPAD(NVL(C_ENR.CD_DEVISE_ACQUISITION,'EUR'),3)|| -- ajout EUR via M_72574
--07/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - EQU101
			pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_MTM,0))||--P3.52
			RPAD(NVL(C_ENR.CD_DEVISE_MTM,' '),3,' ')||--P3.53
			pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_COUT_AMORTI,0))||--P1_3_54_MNT_COUT_AMORTI
			--13/02/2019 - CDS ATOS (SQN) - CRRV4.2 - Correctif : devise en EUR par defaut.
			--RPAD(NVL(C_ENR.CD_DEV_COUT_AMORTI,' '),3,' ')||--P1_3_55_DEVISE_MT_COUT_AMORTI
			RPAD(NVL(C_ENR.CD_DEV_COUT_AMORTI,'EUR'),3,' ')||--P1_3_55_DEVISE_MT_COUT_AMORTI
			--Fin Correctif
--Fin - CDS AtoS FAD - CRRV4.2 US662 - EQU101
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(C_ENR.CD_IMP_PRUDENT, 1,' ')||
			RPAD(' ',2)||
			pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_NOMINAL),0))||	
			RPAD(NVL(C_ENR.CD_DEVISE_NOMINAL,' '),3,' ')||
			RPAD(NVL(C_ENR.PCCO_NOMINAL,' '),12,' ')||
			RPAD(C_ENR.NATURE_PROD_SS_JACENT, 2,' ')||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
      RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP - sous-tache SIRL-237
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',12)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',25)||
			RPAD(' ',1)||
			RPAD(' ',25)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',12)||
			RPAD(' ',2)||
			RPAD(' ',2)||
			RPAD(' ',2)||
			RPAD(' ',12)||
			RPAD(' ',1)||
			RPAD(' ',8)||
			RPAD(' ',20)||
			RPAD(' ',10)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',12)||
			RPAD(' ',2)||
			RPAD(' ',2)||
			RPAD(' ',2)||
			RPAD(' ',12)||
			RPAD(' ',1)||
			RPAD(' ',8)||
			RPAD(' ',20)||
			RPAD(' ',10)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',3)||
			RPAD(' ',5)||
			RPAD(' ',2)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',7)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',8)||
			RPAD(C_ENR.IND_PROD_SS_JACENT, 1,' ')||  --P1 4.31
			RPAD(' ',1)||
			RPAD(' ',8)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',8)||
			RPAD(' ',1)||
			--09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
			RPAD(' ',1)||
			RPAD(' ',4)||			
			RPAD(' ',24)||
			--Fin EMM
			LPAD(ABS(TRUNC(C_ENR.MATURITE_EFF)),2,'0')||
			LPAD(ABS(MOD(C_ENR.MATURITE_EFF *10000,10000)),4,'0')||
			RPAD(NVL(C_ENR.TOP_ENG,' '),1,' ')||
			RPAD(' ',3)||
			RPAD(NVL(C_ENR.INSTRUMENT_FINANCIER, ' '),2,' ')|| -- 04/11/2020 - CDSATOS (CPD) - US204 P1 3.75 
			RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
      RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8,' ')|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
			RPAD(' ',16)||
			RPAD(' ',20)||
			RPAD(' ',10)||
			RPAD(' ',30)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',30)||
			RPAD(' ',1)||
			RPAD(' ',50)||
			RPAD(' ',10)|| --61
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',30)|| --35 / p 1657
			RPAD(' ',12)||
			RPAD(' ',1)||
			RPAD(' ',8)||
			RPAD(' ',2)|| --p 1713
			RPAD(' ',2)||
			RPAD(' ',20)||
			RPAD(' ',10)|| --p 1737
			RPAD(' ',24)||
			RPAD(' ',30)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',30)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',20)||
			RPAD(' ',10)||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',5)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',1)||
			RPAD(' ',14)||
			RPAD(' ',1)||
			RPAD(' ',14)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',1)||
			RPAD(' ',16)||
			RPAD(' ',2)||
			RPAD(' ',3)||
			RPAD(' ',102)||
--07/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - EQ101
			--RPAD(' ',126)||
			RPAD(' ',36)||
			RPAD(NVL(C_ENR.IND_CRE_PERF,'PE'),2,' ')||--P1_21_6_IND_CREANCE_PERF
			RPAD(' ',72)||
			RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL,'YYYYMMDD'), ' '),8,' ')|| --P1_21_16_DATE_DEBUT_ETAT_PERFORMANCE_CREANCE
			RPAD(NVL(C_ENR.CD_MOTIF_PL_NPL,' '),2,' ')|| --P1_21_17_MOTIF_ETAT_DE_PERFORMANCE_CREANCE
			--09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
			RPAD(' ',2)||
			RPAD(' ',2)||
			RPAD(' ',2)||--21.99
			--Fin EMM
--Fin - CDS AtoS FAD - CRRV4.2 US662 - EQ101
			RPAD(NVL(C_ENR.IND_PROD_ECH,' '),3,' ')||
			RPAD(' ',1)||
			RPAD(NVL(C_ENR.REF_UNIQ_CONT,' '),40,' ')||
			RPAD(NVL(C_ENR.REF_UNIQ_CONT,' '),40,' ')||
			RPAD(' ',1)||
			RPAD(' ',4)||
			RPAD(' ',40)||
			RPAD('ND',2)||
			RPAD(' ',10)||
			RPAD(' ',2)||
			RPAD(' ',2)||
			RPAD(' ',46)||
			RPAD(' ',3)||
			RPAD('97',2)||
			pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
			RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3) ||--P1 22.9 : Devise du montant du contrat ? l'origine|
			 -- Fin - CDS AtoS (FAD) - Mantis 44080
			--Fin - CDS ATOS (FAD) - Sprint 4, US 23 - CRRV4.1 Instruments (A)
			RPAD(NVL(C_ENR.IND_ECH_FOUR,' '),1,' ')||  -- 2469
                        RPAD(' ',166)||
--07/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - EQU101
			RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36
      -- DEBUT: projet OMP - sous-tache SIRL-237
      RPAD(' ', 177)|| -- P1 22.37 jusq'au P1 22.62
      RPAD(' ', 8)||   -- P1 22.63 :: projet OMP - ici doit etre VIDE
      RPAD(' ', 30)||  -- P1 22.64 jusqu'au P1 22.70
      -- FIN: projet OMP - sous-tache SIRL-237
			CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
			RPAD(NVL(C_ENR.BUCKET_IFRS9,' '),2,' ')||--P1_22_72_BUCKET_IFRS9 -- 12/02/2019 - CDS AtoS FAD - CRRV4.2 - Correctif : BUCKET_IFRS9 sur 2 blancs au lieu de 3
			RPAD(' ',20)||
--Fin - CDS AtoS FAD - CRRV4.2 US662 - EQU101
			RPAD(NVL(C_ENR.ELI_OUT_MUT_PROV,' '),1,' ')||
			RPAD(NVL(C_ENR.CENTRE_RES,' '),7,' ')||
			RPAD(NVL(C_ENR.SYS_GEST_SRC,' '),20)|| -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
			RPAD(NVL(C_ENR.CLA_COMP_ACT_IFRS9,' '),3,' ')||
			RPAD(NVL(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3,' ')||
			RPAD(NVL(C_ENR.IND_ACT_DEP_ORI,' '),1,' ')||
			RPAD(NVL(C_ENR.ZONE_APP_COMP,' '),40,' ')||
			 RPAD (' ', 10)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
		 RPAD (' ', 2)||
	 RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
			RPAD(' ',2)|| -- 04/11/2020 - CDSATOS (CPD) - US204 P1 24.2
	 RPAD(NVL(C_ENR.HIERARCHIE_JUSTE_VALEUR,' '),1)|| -- 01/02/2021 - CDSATOS (CPD) - US204 (11317) P1 24.3
	 RPAD(NVL(C_ENR.COMPLEXITE_PRODUIT,' '),1)|| -- 04/11/2020 - CDSATOS (CPD) - US204 P1 24.4
	 RPAD(NVL(C_ENR.IND_ACTIF_COTE,' '),1)|| -- 04/11/2020 - CDSATOS (CPD) - US204 P1 24.5
	-- LPAD(NVL(TO_CHAR(C_ENR.NB_TITRES),' '),10,'0')|| -- 01/02/2021 - CDS ATOS (CPD) - US 204 Mantis de recette 11317 -- 14/12/2020 - CDS ATOS (LFD) - US204 taiga MCO CORRECTION --RPAD(NVL(C_ENR.NB_TITRES,' '),10)|| -- 04/11/2020 - CDSATOS (CPD) - US204 P1 24.6
   		pack_utilitaire.F_FORMAT_MONTANT_13_2(C_ENR.NB_TITRES)||-- BALE 4 P1 24.6
			RPAD(' ',50)|| --P1 24.7
			RPAD(' ',1)||  --P1 24.8
			RPAD(' ',1)||  --P1 24.9
			RPAD(' ',19)|| --P1 24.10
			RPAD(' ',3)||  --P1 24.11
			RPAD(' ',10)|| --P1 24.12
			RPAD(' ',10)|| --P1 24.13
			RPAD(' ',19)|| --P1 24.14
			RPAD(' ',3)||  --P1 24.15
			RPAD(' ',19)|| --P1 24.16
			RPAD(' ',3)||  --P1 24.17
			RPAD(' ',19)|| --P1 24.18
			RPAD(' ',3)||  --P1 24.19
			RPAD(' ',1)||  --P1 24.20
			RPAD(' ',40)|| --P1 24.21
			RPAD(' ',40)|| --P1 24.22
			RPAD(' ',1)||  --P1 24.23
			RPAD(' ',1)||  --P1 24.24
			RPAD(' ',1)||  --P1 24.25
			RPAD(' ',10)|| --P1 24.26
			RPAD(' ',50)|| --P1 24.27 ( POS 3285 )
			RPAD(' ',33)|| -- [ P1 24.28 -> P1 24.97 ]
			RPAD(' ',294)|| -- [ P1 24.31 -> P1 25.99 ] 
      RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
			--09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
			RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1) || -- P1 22.11
			RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3) || -- P1 26.3
			RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3) || -- P1 26.4
			RPAD(' ',44)||
			RPAD(' ',22)||
			--07/09/21 CDS_ATOS (EMM) MR 11666
			RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)|| -- P1 27.3 pos 3736
			--Fin EMM
			RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2)|| -- P1 27.4 pos 3737
			RPAD(' ',23)||		--Fin P1 27
			RPAD(' ',24)||		--fin 29
			--MANTIS 11611 (VFN) 27/07/2021
	 		RPAD(' ',190)|| --Debut P1 30 	|189car sur 250 car dans lignedetail1 
			--Fin MANTIS 11611
	 		--as lignedetail1,  --  (taille lignedetail1 = 4000)
	 		-- (compter 1 blanc de separation entre les 2 champs dans le spool)
			--MANTIS 11611 (VFN) 27/07/2021
			RPAD(' ',6)|| 		
			--Fin MANTIS 11611	
			'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
			'N'|| -- M11667 (VFN) 09/09/2021
			RPAD (' ', 25)||
			RPAD (' ', 1)||   --fin P1 30 - 60 caracteres sur 250 seront dans lignedetail2		
			RPAD(' ',5)|| --  debut 31
			RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '), 40) ||
			RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT, ' '), 40) ||
			RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19) || 	
			RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '), 1) ||
      RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
			RPAD(' ',6)||
			RPAD(' ',1)|| --Fin 31a
      RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
      RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
      RPAD(' ', 40)|| -- KLx : Mantis 64749
      --DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
      RPAD('+',1)|| -- P1 31.17a 
      RPAD('00000',5)|| -- P1 31.17b   
      RPAD('+',1)|| -- P1 31.18a 
      RPAD('00000',5)|| -- P1 31.18b
      --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
      RPAD(' ', 6)|| --Debut P1 31.19 
      RPAD(' ', 1)|| --Debut P1 31.20
	    RPAD(' ', 2)|| --Debut P1 31.21
      -- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
      CASE
        WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
        WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
        ELSE '04'
      END || -- P1 31.22 Type de garantie principale a date
      RPAD(' ', 97)|| --Fin 31b 
      -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22 
			--RPAD(' ', 2)|| --Debut P1 31C
      RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 - P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
      RPAD(' ',1) || -- Fin P1 31c
			RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
			RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
			RPAD (' ', 22)|| -- Fin 31d
			RPAD(' ',22)|| -- Fin 31e
			RPAD(' ',1)|| -- debut 31f
			RPAD(' ',1)||
			RPAD(' ',8)||
			RPAD(' ',8)||
			RPAD(' ',1)||
			RPAD(' ',8)||
			RPAD(' ',1)|| -- fin 31f
			RPAD(' ',169)|| -- Fin 31g
			RPAD(' ',2)|| -- debut 31h
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
			RPAD(' ',3)|| -- fin 31h
			'EUR'||--debut P1 50 --M11665 modif VFN
			RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12) ||
			RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) || 	
			RPAD(' ',12)||
			RPAD(' ',19)||
			RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12) ||
			RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) || 	
			RPAD(' ',12)||
			RPAD(' ',19)||
			RPAD(' ',12)||
			RPAD(' ',19)||
			RPAD(' ',12)||
			RPAD(' ',19)||		--Fin P1 50
		RPAD(' ',2)|| --P1 21.22 pos 4897 - VIDE
		RPAD(' ',8)|| --P1 21.23 pos 4899 - VIDE
		RPAD(' ',6)|| --P1 21.29 pos 4907 - VIDE
		RPAD(' ',2)|| --P1 21.25 pos 4913 - VIDE
		RPAD(' ',1)|| --P1 21.26 pos 4915 - VIDE
		RPAD(' ',1)|| --P1 21.27 pos 4916 - VIDE
		RPAD(' ',2)|| --P1 21.28 pos 4917 - VIDE
		RPAD(' ',19)|| --P1 21.30 pos 4919 - VIDE
		RPAD(' ',3)|| --P1 21.31 pos 4938 - VIDE
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE
		RPAD(' ',1)|| --P1 21.44 pos 5133 - VIDE
		RPAD(' ',1)|| --P1 21.45 pos 5134 - VIDE
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(' ',1)|| --P1 21.38 pos 5136 - VIDE
		RPAD(' ',1)|| --P1 21.39 pos 5137 - VIDE
		RPAD(' ',1)|| --P1 21.40 pos 5138 - VIDE
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE
		RPAD(' ',15)|| --P1 21.43 pos 5141 - VIDE
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE
		RPAD(NVL(C_ENR.IND_INVEST_CAPITAL_RISQ,' '),1)|| --P1 21.57 pos 5157 
		RPAD(NVL(C_ENR.IND_INVEST_PROG_LEGISLATIF,' '),1)|| --P1 21.58 pos 5158 
		RPAD(NVL(C_ENR.IND_PARTICIP_STRATG_SUP_6A,' '),1)|| --P1 21.59 pos 5159
		RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.TX_HIST_POND_PARTICIPATION),15)|| --P1 21.60 pos 5160
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE
		RPAD(' ',1)|| --P1 21.66 pos 5222 - VIDE
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225
		RPAD(' ',1)|| --P1 21.69 pos 5237 - VIDE
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
		RPAD(' ',40)|| --P1 21.71 pos 5269 - VIDE
		RPAD(' ',40)|| --P1 21.72 pos 5309 - VIDE
		RPAD(' ',40)|| --P1 21.73 pos 5349 - VIDE
		RPAD(' ',40)|| --P1 21.74 pos 5389 - VIDE
		RPAD(' ',40)|| --P1 21.75 pos 5429 - VIDE
		RPAD(' ',40)|| --P1 21.76 pos 5469 - VIDE
		RPAD(' ',11)|| --P1 21.77 pos 5509 - VIDE
		RPAD(' ',12)|| --P1 21.78 pos 5520 - VIDE
		RPAD(NVL(C_ENR.IND_HQLA,' '),1)|| --P1 21.94 pos 5532
		RPAD(' ',2)|| --P1 21.95 pos 5533 - EVOLUTION A DEFINIR
		RPAD(NVL(C_ENR.IND_TITRE_PARTICIP,' '),1)|| --P1 21.79 pos 5535
		RPAD(' ',3)|| --P1 21.80 pos 5536 - VIDE
		RPAD(' ',10)|| --P1 21.81 pos 5539 - VIDE
		RPAD(' ',10)|| --P1 21.82 pos 5549 - VIDE
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673      
			LPAD(' ', 24)   -- 5100 - 4922 --MANTIS 11611 (VFN) 27/07/2021 -- Mantis 11841  
			 as lignedetail2		
		--Fin EMM
  FROM ENG_CORP_P1 C_ENR
  WHERE 1     =1
    AND FLAG_HN = 'O'
    AND A_EXTRAIRE ='O'
    and (cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
    AND CD_TYPE_RISQUE IN ('EQU101')
;

 
------------------------------------------------------------------------------------------------------------------------
-- E11: a partir de P_UTLF_P1_SIG201             
------------------------------------------------------------------------------------------------------------------------
select
      RPAD(TO_CHAR(C_ENR.DT_ARRETE,'YYYYMMDD'),8,' ')||
      RPAD(NVL(C_ENR.CD_CONSO_CPT,' '),5,' ')||
      RPAD('C_DDR',12,' ')||
      'M'||
      :MASYSDATE||
      'P1'||
      RPAD(' ',1)||
      RPAD(' ',2)||
      RPAD(' ',7)||
      --1-CLE DE REFERENCE
      RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||
      --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '),10,' ')||
      RPAD(' ', 10)||
      RPAD(NVL(C_ENR.ID_AUTORISATION,' '),30,' ')||
      RPAD(NVL(C_ENR.ID_LIGNE_DET ,' '),30,' ')||
      RPAD(' ',40)||
      RPAD(NVL(C_ENR.ID_ENGAGEMENT,' '),40,' ')||
      RPAD(' ',40)||
      RPAD(' ',20)||
      RPAD(NVL(C_ENR.CD_METHODO_BALE2,' '),7,' ')||
      RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR,' '),2,' ')||
      RPAD(NVL(C_ENR.CODE_TRAIT_GRR,' '),1,' ')||
      RPAD(NVL(C_ENR.CD_TYPE_RISQUE,' '),6,' ')||
      RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,' '),1,' ')||
      RPAD(NVL(C_ENR.CD_LIGNE_METIER,' '),5,' ')||
      RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3,' ')||
      RPAD(NVL(C_ENR.CD_NATURE_OPE,' '),12,' ')||
      RPAD(TO_CHAR(C_ENR.DT_DEBUT_ENG,'YYYYMMDD'),8,' ')||
      RPAD(TO_CHAR(C_ENR.DT_FIN_ENG,'YYYYMMDD'),8,' ')||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(NVL(C_ENR.CD_DEVISE_ORIGINE,' '),3,' ')||
      RPAD(' ',50)||
      RPAD(' ',2)||
      RPAD(' ',8)||
      NVL(C_ENR.CD_ARR_PAIEMENT,'N') ||-- P1 5.5 -- US 263 - KLx Risque (VDC) 
      RPAD(NVL(C_ENR.CD_IMP_PRUDENT,' '),1,' ')||   -- P1 4.1
      NVL(C_ENR.TOP_ENG_DOUTEUX,'N')|| -- P1 5.2 -- US 260 - KLx Risque (VDC) - 14/12/2021
      RPAD(' ',8)|| -- P1 5.3
      -- 18/02/2019 - CDS ATOS (GBD) - US731    P1 4.2 
      -- US731 RPAD(' ',1)||    
      -- US731 RPAD(' ',16)||
      -- US731 RPAD(' ',2)||
      --25/07/2019 - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
       --pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_SOLDE) || -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.2
      RPAD(' ',1)||RPAD(' ',16)||RPAD(' ',2)|| -- P1 4.2
      --Fin - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, ' '),3,' ')||  -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
      RPAD(' ',1)|| --P1 4.9
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      -- US731 RPAD(' ',1)|| -- P1 4.14  
      -- US731 RPAD(' ',16)||
      -- US731 RPAD(' ',2)||
      -- US731 RPAD(' ',3)||
      pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_LOYER) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14
      RPAD(NVL(C_ENR.CD_DEVISE_CRD, ' '), 3,' ')            || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_NOMINAL),0))||
      RPAD(NVL(C_ENR.CD_DEVISE_NOMINAL,' '),3,' ')||
      RPAD(NVL(C_ENR.PCCO_NOMINAL,' '),12,' ')||
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_INT_RD),0))||
      RPAD(NVL(C_ENR.CD_DEVISE_INT_RD,' '),3,' ')||
      RPAD(NVL(C_ENR.PCCO_INT_RD,' '),12,' ')||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||
      RPAD(' ',10)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',25)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',69)||
      --3.5-Classification comptable de ref des actifs
      RPAD(NVL(C_ENR.CLA_COMP_REF_ACT,' '),3,' ')||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      --3.6TITRES  CREANCE
      RPAD(' ',3)||
      --3.6-TITRES  DERVIES
      RPAD(' ',36)||
      --3.7.Derives -champs ï¿½ blanc 
      -- DEBUT: projet OMP - sous-tache SIRL-237
      RPAD(' ',24)||                                   -- P1 3.7 jusqu'au P1 3.74
      RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP
      -- FIN: projet OMP - sous-tache SIRL-237
      --3.8-DERIVES ET CESSIONS TEMPORAIRES
      RPAD(' ',134)||
      --3.9-CESSIONS TEMPORAIRES
      RPAD(' ',187)||
      --3.10 DONNEES TITRISATION
      RPAD(' ',3)||
      RPAD(' ',5)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',7)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
	  --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
      RPAD(' ',10)||
	  RPAD(' ',1)||
		RPAD(' ',1)||
		RPAD(' ',1)||
		RPAD(' ',2)||
		RPAD(' ',3)||
		--Fin EMM
      --4-
      --4.1-DONNEES GRANDS RISQUES
      RPAD(NVL(C_ENR.IND_PROD_SS_JACENT,' '),1,' ')||  --P1 4.31
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',8)||
      RPAD(' ',1)||
	  --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(' ',1)||
	  RPAD(' ',4)||
      --4.2 Complement
      RPAD(' ',24)||
	  --Fin EMM
      LPAD(ABS(TRUNC(NVL(C_ENR.MATURITE_EFF,0))),2,'0')||
      LPAD(ABS(MOD(NVL(C_ENR.MATURITE_EFF,0) *10000,10000)),4,'0')||
      RPAD(NVL(C_ENR.TOP_ENG,' '),1,' ')||
      RPAD(' ',3)||
      RPAD(' ',2)||
	    RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')||
      RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8,' ')|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
      RPAD(' ',16)||
	  --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
      RPAD(' ',783)||
	  RPAD(' ',2)||
	  RPAD(' ',2)||
	  RPAD(' ',2)||
	  --Fin EMM
      RPAD(NVL(C_ENR.IND_PROD_ECH,' '),3,' ')||
      RPAD(NVL(C_ENR.IND_OBJ_MET_PAL,' '),1,' ')|| -- P1 22.57 
      RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
      RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT,' '),40,' ')||
      RPAD(' ',45)||
      RPAD('ND',2)||
      RPAD(NVL(C_ENR.NOTE_EXT_ORI ,' '),10,' ')||
      --RPAD(NVL(C_ENR.ORG_NOT_ORI,' '),2,' ')||
      RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||    -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
      RPAD(NVL(C_ENR.SEG_NOT_ORI,' '),2,' ')||
      --RPAD(NVL(C_ENR.GRI_MOD_NOT_ORI ,' '),46,' ')||
      CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
      ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
      RPAD(upper(NVL(C_ENR.METH_NOT_ORI,' ')),3,' ')||
      RPAD('97',2)|| 
      pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
      RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3)|| --P1 22.9 : Devise du montant du contrat ? l'origine
       -- Fin - CDS AtoS (FAD) - Mantis 44080
      --Fin - CDS ATOS (FAD) - Sprint 4, US 23 - CRRV4.1 Instruments (A)
      RPAD(NVL(C_ENR.IND_ECH_FOUR ,' '),1,' ')||
      RPAD(' ',166)||
--07/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - P1 SIG
                        --RPAD('3',1)|| -- P1 22.36
      RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36 
      -- DEBUT: projet OMP - sous-tache SIRL-236
      RPAD(' ', 177)|| -- P1 22.37 jusq'au P1 22.62
      RPAD(' ', 8)||   -- P1 22.63 :: projet OMP - ici doit etre VIDE
      RPAD(' ', 12)||  -- P1 22.64 jusqu'au P1 22.65 
      -- FIN: projet OMP - sous-tache SIRL-236
      RPAD(NVL(C_ENR.CD_PAYS_JURIDICTION,' '),2,' ')|| --P1_22_66_PAYS_JURIDICTION_CONTRAT
      RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE,'YYYYMMDD'), ' '),8,' ')||--P1_22_67_DATE_SIGNATURE_CONTRAT_INITIAL
      RPAD(NVL(C_ENR.EVT_DECL_GAR,' '),2,' ')||--P1_22_68_EVENEMENT_DECLENCHEUR_DE_LA_GARANTIE
      RPAD(' ', 1)|| --P1 22.69
      LPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '     '),5,'0')||--P1_22_70_NOMBRE_DE_JOURS_DE_RETARD_DE_PAIEMENT
      --US740 RPAD(NVL(C_ENR.CD_MOTIF_SCO_LC0267,' '),3,' ')||--P1_22_71_MOTIF_DU_PASSAGE_EN_ENGAGEMENT_DOUTEUX
      CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
      RPAD(NVL(C_ENR.BUCKET_IFRS9,' '),2,' ')||--P1_22_72_BUCKET_IFRS9
      RPAD(' ', 20)||
            /* 26/02/2018 CDS ATOS inihibition des ecritures de l'US33
      -- CDS ATOS (JMP) 24/01/2018 ANACREDIT US33 Code motif SCO
                        RPAD(' ',215)||
      RPAD(NVL(C_ENR.CD_MOTIF_SCO_LC0267,' '),2,' ')||  -- 2852
                        RPAD(' ',23)||
            fin   26/02/2018 CDS ATOS inihibition des ecritures de l'US33  */
            --RPAD(' ',240)||
      -- Fin CDS ATOS (JMP) 24/01/2018 ANACREDIT US33 Code motif SCO
--Fin - CDS AtoS FAD - CRRV4.2 US662 - P1 SIG
      RPAD(NVL(C_ENR.ELI_OUT_MUT_PROV,' '),1,' ')||
      RPAD(NVL(C_ENR.CENTRE_RES ,' '),7,' ')||
      RPAD(NVL(C_ENR.SYS_GEST_SRC,' '),20,' ')||
      RPAD(NVL(C_ENR.CLA_COMP_ACT_IFRS9 ,' '),3,' ')||
      RPAD(NVL(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3,' ')||
      RPAD(NVL(C_ENR.IND_ACT_DEP_ORI ,' '),1,' ')||
      RPAD(NVL(C_ENR.ZONE_APP_COMP ,' '),40,' ')||
      RPAD (' ', 10)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
     RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
     RPAD (' ', 2)||
     RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
    -- RPAD (' ', 674)|| -- BALE4
    RPAD (' ', 649)|| --BALE4
     RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1
	 --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1) ||
		RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3) ||
		RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3) ||
		RPAD(' ',44) || --Fin 26
		RPAD(' ', 19 ) || --Dï¿½but 27
		RPAD (' ', 3)||
		--07/09/21 CDS_ATOS (EMM) MR 11666
		RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
		--Fin EMM
		RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2)||
		RPAD(' ',23) || --Fin 27
		RPAD(' ', 1 ) || --Dï¿½but 28
		RPAD (' ', 1)||
		RPAD(' ', 22 )||  --Fin 29
		--MANTIS 11611 (VFN) 27/07/2021
	 	RPAD(' ',190)|| --Debut P1 30 	|189car sur 250 car dans lignedetail1 
		--Fin MANTIS 11611
	 --	as lignedetail1,  --  (taille lignedetail1 = 4000)
	 	-- (compter 1 blanc de separation entre les 2 champs dans le spool)
		--MANTIS 11611 (VFN) 27/07/2021
		RPAD(' ',6)|| 		
		--Fin MANTIS 11611	
		'N'|| -- M11667 (VFN) 09/09/2021
		 RPAD (' ', 18)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
		'N'|| -- M11667 (VFN) 09/09/2021
		RPAD (' ', 25)||
		RPAD (' ', 1)||   --fin P1 30 - 60 caracteres sur 250 seront dans lignedetail2		
		RPAD(' ', 5 ) || --Dï¿½but 31a
		RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
		RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT,' '),40,' ')||
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19) ||
	  RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '), 1,' ')||
  	RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
		RPAD (' ', 6) ||
		RPAD (' ', 1)|| --Fin 31a
    RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
    RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
    RPAD(' ', 40)|| -- KLx : Mantis 64749
		--DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
    RPAD('+',1)|| -- P1 31.17a 
    RPAD('00000',5)|| -- P1 31.17b   
    RPAD('+',1)|| -- P1 31.18a 
    RPAD('00000',5)|| -- P1 31.18b
    --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
		-- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
	  RPAD(' ', 6)|| --Debut P1 31.19 
	  RPAD(' ', 1)|| --Debut P1 31.20
	  RPAD(' ', 2)|| --Debut P1 31.21
    CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
    END || -- P1 31.22 Type de garantie principale a date
	  RPAD(' ', 97)|| --Fin 31b 
    -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
		--RPAD(' ', 2)|| --Debut P1 31C
    RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 - P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
    RPAD(' ',1) || -- Fin P1 31c
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
		RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
		RPAD (' ', 22)|| -- Fin 31d
		RPAD(' ', 22 ) || --Debut 31e
		RPAD(' ', 28 ) || --Debut 31f
		RPAD(' ', 7 ) || --Debut 31g
		RPAD(' ', 2 ) ||
		RPAD(' ', 2 ) ||
		RPAD(' ', 2 ) ||
		RPAD(' ', 2 ) ||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)|| --Fin 31g
		RPAD(' ', 2 ) || --Debut 31h
		RPAD(' ', 2 ) ||
		RPAD(' ', 2 ) ||
		RPAD(' ', 20 ) ||
		RPAD(' ', 10 ) ||
		RPAD(' ', 15 ) ||
		RPAD (' ', 19)||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)||
		RPAD(' ', 19 ) ||
		RPAD (' ', 3)|| --Fin 31h
		'EUR'|| --Debut 50 --M11665 modif VFN
	    RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12)||
	    RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) ||
		RPAD(' ',12)||
		RPAD(' ',19)||
		RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12)||
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) ||	  
		RPAD(' ',12)||
		RPAD(' ',19)||
		RPAD(' ',12)||
		RPAD(' ',19)||
		RPAD(' ',12)||
		RPAD(' ',19)||	--Fin 50
		RPAD(' ',2)|| --P1 21.22 pos 4897 - VIDE
		RPAD(' ',8)|| --P1 21.23 pos 4899 - VIDE
		RPAD(' ',6)|| --P1 21.29 pos 4907 - VIDE
		RPAD(' ',2)|| --P1 21.25 pos 4913 - VIDE
		RPAD(' ',1)|| --P1 21.26 pos 4915 - VIDE
		RPAD(' ',1)|| --P1 21.27 pos 4916 - VIDE
		RPAD(' ',2)|| --P1 21.28 pos 4917 - VIDE
		RPAD(' ',19)|| --P1 21.30 pos 4919 - VIDE
		RPAD(' ',3)|| --P1 21.31 pos 4938 - VIDE
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE
		RPAD(' ',12)|| --P1 15 pos 4959 -- SIG* VIDE
		RPAD(' ',12)|| --P1 16 pos 4971 -- SIG* VIDE
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE
		RPAD(' ',1)|| --P1 21.44 pos 5133 - VIDE
		RPAD(' ',1)|| --P1 21.45 pos 5134 - VIDE
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(NVL(C_ENR.IND_IPRE,' '),1)|| --P1 21.38 pos 5136 
		RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)|| --P1 21.39 pos 5137
		RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1)|| --P1 21.40 pos 5138
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE
		RPAD(' ',15)|| --P1 21.43 pos 5141 - VIDE
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE
		RPAD(' ',1)|| --P1 21.57 pos 5157 - VIDE
		RPAD(' ',1)|| --P1 21.58 pos 5158 - VIDE
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE
		RPAD(' ',10)|| --P1 21.61 pos 5175 -- SIG* VIDE
		RPAD(' ',10)|| --P1 21.62 pos 5185 -- SIG* VIDE
		RPAD(' ',19)|| --P1 21.63 pos 5195 -- SIG* VIDE
		RPAD(' ',3)|| --P1 21.64 pos 5214 -- SIG* VIDE
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE
		RPAD(NVL(C_ENR.IND_UCC,' '),1)|| --P1 21.66 pos 5222 -- SIG* BASE
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224 -- SIG* BASE
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225 -- SIG* BASE
		RPAD(' ',1)|| --P1 21.69 pos 5237 - VIDE
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
		RPAD(' ',40)|| --P1 21.71 pos 5269 - VIDE
		RPAD(' ',40)|| --P1 21.72 pos 5309 - VIDE
		RPAD(' ',40)|| --P1 21.73 pos 5349 - VIDE
		RPAD(' ',40)|| --P1 21.74 pos 5389 - VIDE
		RPAD(' ',40)|| --P1 21.75 pos 5429 - VIDE
		RPAD(' ',40)|| --P1 21.76 pos 5469 - VIDE
		RPAD(' ',11)|| --P1 21.77 pos 5509 - VIDE
		RPAD(' ',12)|| --P1 21.78 pos 5520 - VIDE
		RPAD(' ',1)|| --P1 21.94 pos 5532 - VIDE
		RPAD(' ',2)|| --P1 21.95 pos 5533 - VIDE
		RPAD(' ',1)|| --P1 21.79 pos 5535 - VIDE
		RPAD(' ',3)|| --P1 21.80 pos 5536 - VIDE
		RPAD(' ',10)|| --P1 21.81 pos 5539 - VIDE
		RPAD(' ',10)|| --P1 21.82 pos 5549 - VIDE
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 
		LPAD(' ', 24)   -- 5100 - 4922 --MANTIS 11611 (VFN) 27/07/2021 -- Mantis 11841 
	        as lignedetail2
	 --Fin EMM
    FROM ENG_CORP_P1   C_ENR
    WHERE 1     =1
    AND FLAG_HN = 'O'
    AND A_EXTRAIRE ='O'
    and (cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
    AND CD_TYPE_RISQUE IN ('SIG201','INR101') 
;
 
------------------------------------------------------------------------------------------------------------------------
-- E12: a partir de P_UTLF_P1_VAR104             
------------------------------------------------------------------------------------------------------------------------
select
      RPAD(TO_CHAR(C_ENR.DT_ARRETE,'YYYYMMDD'),8,' ')||
      RPAD(NVL(C_ENR.CD_CONSO_CPT,' '),5,' ')||
      RPAD('C_DDR',12,' ')||
      'M'||
      :MASYSDATE||
      'P1'||
      RPAD(' ',1)||
      RPAD(' ',2)||
      RPAD(' ',7)||
      --1.CLE DE REFERENCE
      RPAD(NVL(C_ENR.ID_TIERS_CALC,' '),20,' ')||
      --RPAD(NVL(C_ENR.ID_CENTRAL_TIERS,' '),10,' ')||
      RPAD(' ', 10)||
      RPAD(NVL(C_ENR.ID_AUTORISATION,' '),30,' ')||
      RPAD(NVL(C_ENR.ID_LIGNE_DET ,' '),30,' ')||
      RPAD(' ',40)||
      RPAD(NVL(C_ENR.ID_ENGAGEMENT,' '),40,' ')||
      RPAD(' ',40)||
      RPAD(' ',20)||
      --2. INFORMATIONS GENERIQUES
      RPAD(NVL(C_ENR.CD_METHODO_BALE2,' '),7,' ')||
      RPAD(NVL(C_ENR.CODE_TRAIT_MOTEUR,' '),2,' ')||
      RPAD(NVL(C_ENR.CODE_TRAIT_GRR,' '),1,' ')||
      RPAD(NVL(C_ENR.CD_TYPE_RISQUE,' '),6,' ')||
      RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BOOKING,' '),1,' ')||
      RPAD(NVL(C_ENR.CD_LIGNE_METIER,' '),5,' ')||
      RPAD(NVL(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3,' ')||
      RPAD(NVL(C_ENR.CD_NATURE_OPE,' '),12,' ')||
      --3.
      --3.1 ELEMENTS COMMUNS
      RPAD(TO_CHAR(C_ENR.DT_DEBUT_ENG,'YYYYMMDD'),8,' ')||
      RPAD(TO_CHAR(C_ENR.DT_FIN_ENG,'YYYYMMDD'),8,' ')||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(NVL(C_ENR.CD_DEVISE_ORIGINE, ' '),3,' ')||
      RPAD(' ',50)||
      --3.2-PRETS,TITRES DE CREANCE
      RPAD(' ',2)||
      RPAD(' ',8)||
      --3.2BIS-PRETS CREDIT
      NVL(C_ENR.CD_ARR_PAIEMENT,'N')|| --P1 5.5 -- 03/12/2021 - KLx Risque (VDC) - US 263 -  CRR Corporate - Score 7 'Indicateur ArriÃ©rÃ© de paiement' 
      RPAD(' ',1)||
      --29/04/2018 - CDS ATOS (FCU) - US787 : Top engagement douteux pour type de risque VAR104
      RPAD(NVL(C_ENR.TOP_ENG_DOUTEUX,' '),1, ' ')||  -- P1 5.2  eng douteux
      --Fin - CDS ATOS (FCU) - US787 : Top engagement douteux pour type de risque VAR104
      RPAD(' ',8)||
      -- 18/02/2019 - CDS ATOS (GBD) - US731    P1 4.2 
      -- US731 RPAD(' ',1)||    
      -- US731 RPAD(' ',16)||
      -- US731 RPAD(' ',2)||
  --25/07/2019 - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
      --pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_SOLDE) || -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.2
      RPAD(' ',1)||RPAD(' ',16)||RPAD(' ',2)|| -- P1 4.2
  --Fin - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
      RPAD(' ',3)||   -- P1 4.3
      RPAD(' ',1)||   -- P1 4.4
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT, ' '),3,' ')||  -- 18/02/2019 - CDS ATOS (GBD) - US731  : P1 4.5
      RPAD(' ',1)||  -- P1 4.9
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)|| --P1 4.13
      -- US731 RPAD(' ',1)||  --P1 4.14
      -- US731 RPAD(' ',16)||
      -- US731 RPAD(' ',2)||
      -- US731 RPAD(' ',3)||  --P1 4.15
      pack_utilitaire.f_format_montant_bis3(C_ENR.MNT_LOYER) || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.14
      RPAD(NVL(C_ENR.CD_DEVISE_CRD, ' '), 3,' ')               || -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.15
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)|| -- P1 4.18 POS 570
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',2)||
      --3.3 PRETS ENGAGEMENTS
      RPAD(' ',1)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',25)||
      RPAD(' ',2)||
      --3.4 PRET IMMOBILIER CREDIT 
      RPAD(' ',1)||
      RPAD(' ',1)||
      --3.4bis -CREDIT - bailm
      RPAD(' ',1)||
      RPAD(' ',16)|| 
      RPAD(' ',2)|| 
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      --3.5.Classification comptable de rï¿½fï¿½rence des actifs
      RPAD(nvl(C_ENR.cla_comp_ref_act,' '),3)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      --3.6 TITRES  cREANCE - champs ï¿½ blanc car non applicables pour ce type de risque
      RPAD(' ',1)||
      RPAD(' ',2)||
      --3.6 Bis -TITRES  DERIVES
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_NOMINAL),0))||
      RPAD(NVL(C_ENR.CD_DEVISE_NOMINAL,' '),3,' ')||
      RPAD(NVL(C_ENR.PCCO_NOMINAL,' '),12,' ')||
      RPAD(C_ENR.NATURE_PROD_SS_JACENT, 2,' ')|| 
      RPAD(NVL(C_ENR.SENS_TRANSACTION, ' '),1,' ')||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)|| -- P1 2.99 :: projet OMP - sous-tache SIRL-237
      --3.8-DERIVES ET CESSIONS TEMP
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_MTM),0))||
      RPAD(NVL(C_ENR.CD_DEVISE_MTM,' '),3,' ')||
      RPAD(NVL(C_ENR.PCCO_MTM,' '),12,' ')||
      RPAD(NVL(C_ENR.MODELE_ASSIETE_RISQUE, ' '),1,' ')||
      RPAD(NVL(C_ENR.IND_ACCORD_COLLATERISATION, ' '),1,' ')||
      RPAD(NVL(C_ENR.REF_ACCORD_COLLATERISATION, ' '),25,' ')||
      RPAD(NVL(C_ENR.IND_ACCORD_NETTING, ' '),1,' ')||
      RPAD(NVL(C_ENR.REF_CONTRAT_NETTING, ' '),25,' ')||
      RPAD(NVL(C_ENR.DEV_CONTRAT_NETTING, ' '),3,' ')||
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_ASSIETE_INTERNE),0))||
      RPAD(NVL(C_ENR.DEV_ASSIETE_INTERNE, ' '),3,' ')||
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_ASSIETE_REGLEMENTAIRE),0))||
      RPAD(NVL(C_ENR.DEV_ASSIETE_REGLEMENTAIRE, ' '),3,' ')||
      --3.9-cessions temporaires de titres 
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',12)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',2)||
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      --3.10-Donnes titrisation-champs a blanc car non applicables ...
      RPAD(' ',3)||
      RPAD(' ',5)||
      RPAD(' ',2)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',7)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',8)||
      --4.
      ---4.1.DONNEES GRANDS RISQUEQ 
      RPAD(' ',1)||   -- ou ? RPAD(NVL(C_ENR.IND_PROD_SS_JACENT ' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 4.31
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',1)||
      RPAD(' ',4)||
      RPAD(' ',5)||
      RPAD(' ',8)||
      RPAD(' ',1)||
      --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  RPAD(' ',1)||
	  RPAD(' ',4)||
	  RPAD(' ',24)||
	  --FIN EMM
		LPAD(ABS(TRUNC(NVL(C_ENR.MATURITE_EFF,0))),2,'0')||
		LPAD(ABS(MOD(NVL(C_ENR.MATURITE_EFF,0) *10000,10000)),4,'0')||
      RPAD(NVL(C_ENR.TOP_ENG, ' '),1,' ')||
      RPAD(' ',3)||
      RPAD(NVL(C_ENR.INSTRUMENT_FINANCIER, ' '),2,' ')|| --P1 3.75 position 1430
      RPAD(NVL(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6,' ')|| --P1 4.42 position 1432
      RPAD(nvl(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'),' '),8,' ')|| -- Klx US273 23/12/2021 alimenter le champ P1 3.3 'Date de valeur' avec la date d'arrÃªtÃ© en cours
	  RPAD(' ',16)||
      --4.2a
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',30)||
      --4.2b
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',1)||
      RPAD(' ',16)||
      RPAD(' ',2)||
      RPAD(' ',3)||
      RPAD(' ',30)||
      RPAD(' ',1)||
      RPAD(' ',50)||
      RPAD(' ',10)||
      --4.3a
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(' ',1)||
      RPAD(NVL(C_ENR.IND_CCP, ' '),1,' ')||
      RPAD(' ',30)||
      --4.3b -DONNEES SOUS-JACENT
      RPAD(' ',12)||
      RPAD(' ',1)||
      RPAD(' ',8)||
      RPAD(NVL(C_ENR.CODE_INDICE_BOURSE, ' '),2,' ')||
      RPAD(NVL(C_ENR.CODE_PAYS_BOURSE, ' '),2,' ')||
      RPAD(' ',20)||
      RPAD(' ',10)||
      RPAD(' ',30)||--24+3+3
      --4.3C
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_CVA_COMPTA),0))||
      RPAD(NVL(C_ENR.DEV_CVA_COMPTA, ' '),3,' ')||
      RPAD(NVL(C_ENR.IND_RISQ_COLLAT_SPECIF, ' '),1,' ')||
      --4.3d
      RPAD(' ',30)||--20+10
      RPAD(NVL(C_ENR.TYPE_CREDIT_DERIVE, ' '),3,' ')||
      RPAD(NVL(C_ENR.IND_DENOUEMENT_CDS, ' '),1,' ')||
      RPAD(NVL(C_ENR.IND_ELLIGIBILITE_CVA, ' '),1,' ')||
      RPAD(' ',20)||
      RPAD(' ',10)||
      (CASE
        WHEN C_ENR.MT_SPREAD >=0
        THEN '+'
        ELSE '-'
      END)||
      LPAD(ABS(TRUNC(NVL(C_ENR.MT_SPREAD,0))),4,'0')||
      RPAD(' ',5)||
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_NOTIONNEL_ACH),0))||
      RPAD(NVL(C_ENR.DEV_NOTIONNEL_ACH, ' '),3,' ')||
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_NOTIONNEL_VENDU),0))||
      RPAD(NVL(C_ENR.DEV_NOTIONNEL_VENDU, ' '),3,' ')||
      RPAD(NVL(C_ENR.TYPE_SWAP, ' '),2,' ')||
      RPAD(NVL(C_ENR.NATURE_OPTION, ' '),3,' ')||
      RPAD(NVL(C_ENR.IND_CALL_PUT, ' '),1,' ')||        --P1 10.2
      RPAD(NVL(C_ENR.TYPE_TAUX_PAYE, ' '),1,' ')||      --P1 8.1
      RPAD(NVL(C_ENR.REF_TAUX_PAYE, ' '),14,' ')||      --P1 8.2
      RPAD(NVL(C_ENR.TYPE_TAUX_RECU, ' '),1,' ')||      --P1 8.11
      RPAD(NVL(C_ENR.REF_TAUX_RECU, ' '),14,' ')||      --P1 8.12
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_QUANTITE_RECUE),0))||
      RPAD(NVL(C_ENR.UNITE_QUANTITE_RECUE, ' '),3,' ')||
      pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MT_QUANTITE_LIVREE),0))||
      RPAD(NVL(C_ENR.UNITE_QUANTITE_LIVREE, ' '),3,' ')||
	  --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
      RPAD(' ',244)||
	  RPAD(' ',2)||
		RPAD(' ',2)||
		RPAD(' ',2)||
		RPAD(' ',2)||
		--FIN EMM 
      RPAD(NVL(C_ENR.IND_PROD_ECH,' '),3,' ')|| -- P1 22.56
      RPAD(NVL(C_ENR.IND_OBJ_MET_PAL,' '),1,' ')|| -- P1 22.57 ; POS 932
      RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '),40,' ')||
      RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT,' '),40,' ')||
      RPAD(' ',45)||
      RPAD('ND',2)||
      RPAD(NVL(C_ENR.NOTE_EXT_ORI,' '),10,' ')||
      --RPAD(NVL(C_ENR.ORG_NOT_ORI,' '),2,' ')||
      RPAD(nvl(C_ENR.ORGA_NOTATION_ORIG,' '),2,' ')||    -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.6 
      RPAD(NVL(C_ENR.SEG_NOT_ORI,' '),2,' ')||
      --RPAD(NVL(C_ENR.GRI_MOD_NOT_ORI,' '),46,' ')||
      CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN RPAD(' ',46)
      ELSE RPAD(nvl(rpad(C_ENR.GRI_MOD_NOT_ORI,21)||'FR',' '),46) END ||
      RPAD(upper(NVL(C_ENR.METH_NOT_ORI,' ')),3,' ')||
      RPAD('97',2)||
      pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)||--P1 22.8 : Montant du contrat ? l'origine
      RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3)|| --P1 22.9 : Devise du montant du contrat ? l'origine
      -- Fin - CDS AtoS (FAD) - Mantis 44080
      --Fin - CDS ATOS (FAD) - Sprint 4, US 23 - CRRV4.1 Instruments (A)
      RPAD(NVL(C_ENR.IND_ECH_FOUR,' '),1,' ')||
      RPAD(' ',23)|| --
      RPAD(NVL(C_ENR.TYPE_AMOR_CAP,' '),1)||-- P1 22.16	Type d'amortissement du capital (SIRL-519)
      RPAD(' ',142)|| --
--06/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - VAR104
      --RPAD('3',1)|| --P1 22.36 -> non alimentï¿½ dans la notice
      RPAD(NVL(C_ENR.IND_RMB_ANTICIPE,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 22.36
      -- DEBUT: projet OMP - sous-tache SIRL-236
      RPAD(' ', 177)|| -- P1 22.37 jusq'au P1 22.62
      RPAD(' ', 8)||   -- P1 22.63 :: projet OMP - ici doit etre VIDE
      RPAD(' ', 12)||  -- P1 22.64 jusqu'au P1 22.65 
      -- FIN: projet OMP - sous-tache SIRL-236
      RPAD(NVL(C_ENR.CD_PAYS_JURIDICTION, ' '), 2, ' ')|| -- P1 22.66
      RPAD(' ', 16)||
      --US740 RPAD(NVL(C_ENR.CD_MOTIF_SCO_LC0267,' '), 3, ' ')|| -- P1 22.71
      CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3) ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||  -- 26/02/2019 - CDS ATOS (GBD) - US740  P1 22.71  (col 2852) Motif passage engagemt douteux (0 ï¿½ gauche)
      RPAD(NVL(C_ENR.BUCKET_IFRS9,' '), 2, ' ')|| -- P1 22.72
      RPAD(' ', 20)||
      --RPAD(' ',240)||
-- Fin CDS ATOS (JMP) 24/01/2018 ANACREDIT US33 Code motif SCO
--Fin - CDS AtoS FAD - CRRV4.2 US662 - VAR104
      RPAD(NVL(C_ENR.ELI_OUT_MUT_PROV,' '),1,' ')||
      RPAD(NVL(C_ENR.CENTRE_RES,' '),7,' ')||
      RPAD(NVL(C_ENR.SYS_GEST_SRC,' '),20,' ')||
      RPAD(NVL(C_ENR.CLA_COMP_ACT_IFRS9,' '),3,' ')||
      RPAD(NVL(C_ENR.CLA_COMP_ACT_NATIONALE,' '),3,' ')||
      RPAD(NVL(C_ENR.IND_ACT_DEP_ORI,' '),1,' ')||
      RPAD(NVL(C_ENR.ZONE_APP_COMP,' '),40,' ')||
      RPAD (' ', 10)||
      RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12)||
      RPAD (nvl(C_ENR.CD_METH_IFRS9_LGD,' '), 12)||
      RPAD (nvl(C_ENR.CD_METH_IFRS9_CCF,' '), 12)||
      RPAD (nvl(C_ENR.CD_METH_IFRS9_TX,' '), 12)||
      RPAD (' ', 2)||
      RPAD(NVL(C_ENR.ELIGIB_PRUDENT_VAL,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 24.1 
      --06/02/2019 - CDS AtoS FAD - CRRV4.2 US662 - VAR104
      --RPAD(' ',1188) 
      -- us731 RPAD(' ', 798)|| -- 1188 - 390  -- 674 +1 + 123
      -- 12/11/2020 - CDS ATOS (LFD) - US 206 TAIGA MCO
      --RPAD(' ', 674)||
      RPAD(' ', 2)||
      RPAD(NVL(C_ENR.HIERARCHIE_JUSTE_VALEUR,' '),1,' ')|| -- P1 24.3
     -- RPAD(' ',172)|| --BALE4
      RPAD(' ',175)|| --BALE4 +3
      RPAD(NVL(C_ENR.IND_BCK_TO_BCK,' '),1,' ')|| -- P1 24.20
      RPAD(' ',80)||
      RPAD(NVL(C_ENR.INTENTION_COUVERTURE,' '),1,' ')|| -- P1 24.23
      RPAD(NVL(C_ENR.TYPE_REL_COUVERTURE,' '),1,' ')|| -- P1 24.24
      --RPAD(' ', 416)|| --BALE4
      RPAD(' ', 388)|| --BALE4 -28    
      -- FIN LFD
      RPAD(NVL(C_ENR.IND_MOBIL_ACTIF,' '),1,' ')||   -- 18/02/2019 - CDS ATOS (GBD) - US731 P1 26.1 pos 3662
      --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	RPAD(NVL(C_ENR.ELIG_MOB_BANQUE_CENTRALE, ' '), 1)||
	RPAD(NVL(C_ENR.REF_MOB_ACTIF, ' '), 3)||
	RPAD(NVL(C_ENR.CD_ORGA_MOBIL, ' '), 3)||
	RPAD (' ', 44)|| --fin 26
	RPAD (' ', 19)||
	RPAD (' ', 3)||
	--07/09/21 CDS_ATOS (EMM) MR 11666
	RPAD(NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2'), 1)||
	--Fin EMM
	RPAD(NVL(C_ENR.MOTIF_EXCLU_ANACREDIT, ' '), 2)||
	RPAD (' ', 23)|| --FIN 27	
	--FIN EMM
	RPAD (' ', 24)||	
      RPAD(NVL(C_ENR.TYPE_CTT_CADDRE,' '), 2, ' ')|| --P1_30_1_TYPE_DE_CONTRAT_CADRE
      RPAD(NVL(C_ENR.IND_PROTOCOLE_ISDA_ENTITE,' '), 1, ' ')|| --P1_30_2_IND_PROTOCOLE_ISDA_NIVEAU_ENTITE
      RPAD(NVL(C_ENR.IND_PROTOCOLE_ISDA_CPTY,' '), 1, ' ')|| --P1_30_3_IND_PROTOCOLE_ISDA_NIVEAU_CONTREPARTIE
      RPAD(' ', 88)||
      pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_CCNE_JB_VENDUE,0))|| --P1_30_12_MT_COUPONS_COURUS_NON_ECHUS_JMB_VENDUE
      RPAD(NVL(C_ENR.CD_DEV_MNT_CCNE_JB_VENDUE,' '), 3, ' ')|| --P1_30_13_DEV_COUPONS_COURUS_NON_ECHUS_JMB_VENDUE
      pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_CCNE_JB_ACHETEE,0))|| --P1_30_14_MT_COUPONS_COURUS_NON_ECHUS_JAMBE_ACHETEE
      RPAD(NVL(C_ENR.CD_DEV_MNT_CCNE_JB_ACHETEE,' '), 3, ' ')|| --P1_30_15_DEV_COUPONS_COURUS_NON_ECHUS_JAMBE_ACHETEE
      RPAD(NVL(C_ENR.PRD_PAY_TX_RECU,' '), 1, ' ')|| --P1_30_16_FREQUENCE_PAIEMENT_TX_RECU
      --pack_utilitaire.f_format_taux(nvl(C_ENR.MRG_TX_RECU,0))|| --P1_30_17_MARGE_DU_TAUX_RECU --M73302
      CASE WHEN C_ENR.TYPE_TAUX_RECU IN ('V','R') THEN pack_utilitaire.f_format_taux(nvl(C_ENR.MRG_TX_RECU,0)) ELSE RPAD (' ', 10) END || --P1_30_17_MARGE_DU_TAUX_RECU --M73302
      RPAD(NVL(C_ENR.CD_BASE_CALCUL_INT_RECU,' '), 7, ' ')|| --P1_30_18_BASE_DE_CALCUL_DES_INTERETS_RECUS
      RPAD(NVL(C_ENR.PRD_PAY_TX_PAYE,' '), 1, ' ')|| --P1_30_19_FREQUENCE_PAIEMENT_TX_PAYE
      --pack_utilitaire.f_format_taux(nvl(C_ENR.MRG_TX_PAYE,0))|| --P1_30_20_MARGE_DU_TAUX_PAYE --M73302
      CASE WHEN C_ENR.TYPE_TAUX_PAYE IN ('V','R') THEN pack_utilitaire.f_format_taux(nvl(C_ENR.MRG_TX_PAYE,0)) ELSE RPAD (' ', 10) END || --P1_30_20_MARGE_DU_TAUX_PAYE --M73302
      RPAD(NVL(C_ENR.CD_BASE_CALCUL_INT_PAYE,' '), 7, ' ')|| -- P1_30_21_BASE_DE_CALCUL_DES_INTERETS_PAYES
      -- 04/02/2021 - CDS ATOS (LFD) - US 23 CRRV4.3
      --09/07/21 CDS ATOS (EMM) US 194 CRRv4.3
	  --MANTIS 11611 (VFN) 27/07/2021
      RPAD (' ', 25)|| -- P1 30.22 position 3958
      'N'|| --P1 30.23 position 3983
      RPAD (' ', 17)-- BALE4
	 as lignedetail1,  -- debut ligne (taille lignedetail1 =4000)	  -- BALE4
		 RPAD (' ', 7)|| -- BALE4
	  'N'|| -- M11667 (VFN) 09/09/2021
	  RPAD (' ', 25)||
      RPAD(NVL(C_ENR.FINALITE_OPERATION,' '), 1, ' ')|| --P1_30_27_FINALITE_OPERATION
	  RPAD (' ', 5)|| -- debut P1 31.a
		RPAD(NVL(C_ENR.REF_UNIQ_CONT, ' '), 40)||
		RPAD(NVL(C_ENR.REF_UNIQ_ELEM_CONT, ' '), 40)||
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ENG_DT_SIGN_CTRT),19) || 
		RPAD(NVL(C_ENR.IND_RESPO_SOLIDAIRE, ' '), 1)||
  	RPAD (NVL(C_ENR.IND_ISF,'2'), 1)|| -- KLx (GH) CRRv4.3 141 - P1 31.6 Indicateur dossier infrastructure eligible au facteur de reduction 75%
		RPAD (' ', 6) ||
		RPAD (' ', 1)||	
    RPAD(NVL(C_ENR.CD_COMMUNE_BIEN_FINAN, ' '),15,' ')|| -- Debut 31b 31.9 -- KLx : Mantis 64749
    RPAD(NVL(C_ENR.CD_PAYS_BIEN_FINAN, ' '),2,' ')|| -- 31.10 -- KLx : Mantis 64749
    RPAD(' ', 40)|| -- KLx : Mantis 64749    
		--DEBUT: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
    RPAD('+',1)|| -- P1 31.17a 
    RPAD('00000',5)|| -- P1 31.17b   
    RPAD('+',1)|| -- P1 31.18a 
    RPAD('00000',5)|| -- P1 31.18b
    --FIN: KLx Risques Leasing (BA): US 275 - Score 6 DurÃ©e initiale/totale du prÃªt
		-- Debut Klx US 276 CRRV4.3 - ajout champ P1 31.22
	  RPAD(' ', 6)|| --Debut P1 31.19 
	  RPAD(' ', 1)|| --Debut P1 31.20
	  RPAD(' ', 2)|| --Debut P1 31.21
    CASE
      WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01'
      WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02'
      ELSE '04'
    END || -- P1 31.22 Type de garantie principale a date
	  RPAD(' ', 97)|| --Fin 31b 
    -- Fin Klx US 276 CRRV4.3 - ajout champ P1 31.22
		--RPAD(' ', 2)|| --Debut P1 31C
    RPAD(NVL(C_ENR.IND_GAR_SANS_LIMITE,' '),1) ||-- US 262 CRRV4.3 - P1 31.37 Ajout du champ IND_GAR_SANS_LIMITEÂ format VARCHAR2 de longueur 1 byte - KLx Risque (VDC) - 03/12/2021
    RPAD(' ',1) || -- Fin P1 31c
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_SUBV_HT),19)|| -- Debut 31d US 287 CRRV4.3 - P1 29.3 Montant des subventions  KLx (GH)
		RPAD ('EUR', 3)|| -- P1 29.4 Devise du montant des subventions -- US 287  CRRV4.3 - P1 29.3  KLx (GH)
		RPAD (' ', 22)|| -- Fin 31d
		RPAD(' ',22) || --debut 31e
		RPAD(' ',28) || --debut 31f
		RPAD(' ',169) || --debut 31g
		RPAD(' ',117) || --debut 31h
		'EUR'||--debut P1 50 --M11665 modif VFN
		RPAD(NVL(C_ENR.PCEC_MNT_RISQUE, ' '), 12) ||
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_RISQUE),19) || 	
		RPAD(' ',12)||
		RPAD(' ',19)||
		RPAD(NVL(C_ENR.PCEC_ICNE, ' '), 12) ||
		RPAD(pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_ICNE),19) || 	
		RPAD(' ',12)||
		RPAD(' ',19)||
		RPAD(' ',12)||
		RPAD(' ',19)||
		RPAD(' ',12)||
		RPAD(' ',19)||	--fin P1 50
		RPAD(' ',2)|| --P1 21.22 pos 4897 - VIDE
		RPAD(' ',8)|| --P1 21.23 pos 4899 - VIDE
		RPAD(' ',6)|| --P1 21.29 pos 4907 - VIDE
		RPAD(' ',2)|| --P1 21.25 pos 4913 - VIDE
		RPAD(' ',1)|| --P1 21.26 pos 4915 - VIDE
		RPAD(' ',1)|| --P1 21.27 pos 4916 - VIDE
		RPAD(' ',2)|| --P1 21.28 pos 4917 - VIDE
		RPAD(' ',19)|| --P1 21.30 pos 4919 - VIDE
		RPAD(' ',3)|| --P1 21.31 pos 4938 - VIDE
		RPAD(' ',15)|| --P1 21.32 pos 4941 - VIDE
		RPAD(' ',3)|| --P1 21.33 pos 4956 - VIDE
		RPAD(' ',12)|| --P1 15 pos 4959 - VIDE
		RPAD(' ',12)|| --P1 16 pos 4971 - VIDE
		RPAD(' ',12)|| --P1 14 pos 4983 - VIDE
		RPAD(' ',12)|| --P1 50.20 pos 4995 - VIDE
		RPAD(' ',19)|| --P1 50.21 pos 5007 - VIDE
		RPAD(' ',1)|| --P1 21.34 pos 5026 - VIDE
		RPAD(' ',1)|| --P1 21.35 pos 5027 - VIDE
		RPAD(' ',19)|| --P1 21.36 pos 5028 - VIDE
		RPAD(' ',3)|| --P1 21.37 pos 5047 - VIDE
		RPAD(' ',10)|| --P1 21.47 pos 5050 - VIDE
		RPAD(' ',7)|| --P1 21.48 pos 5060 - VIDE
		RPAD(' ',19)|| --P1 21.49 pos 5067 - VIDE
		RPAD(' ',3)|| --P1 21.50 pos 5086 - VIDE
		RPAD(' ',19)|| --P1 21.51 pos 5089 - VIDE
		RPAD(' ',3)|| --P1 21.52 pos 5108 - VIDE
		RPAD(' ',19)|| --P1 21.53 pos 5111 - VIDE
		RPAD(' ',3)|| --P1 21.54 pos 5130 - VIDE
		RPAD(' ',1)|| --P1 21.44 pos 5133 - VIDE
		RPAD(' ',1)|| --P1 21.45 pos 5134 - VIDE
		RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1)|| --P1 21.46 pos 5135
		RPAD(' ',1)|| --P1 21.38 pos 5136 - VIDE
		RPAD(' ',1)|| --P1 21.39 pos 5137 - VIDE
		RPAD(' ',1)|| --P1 21.40 pos 5138 - VIDE
		RPAD(' ',1)|| --P1 21.41 pos 5139 - VIDE
		RPAD(' ',1)|| --P1 21.42 pos 5140 - VIDE
		RPAD(' ',15)|| --P1 21.43 pos 5141 - VIDE
		RPAD(' ',1)|| --P1 21.56 pos 5156 - VIDE
		RPAD(' ',1)|| --P1 21.57 pos 5157 - VIDE
		RPAD(' ',1)|| --P1 21.58 pos 5158 - VIDE
		RPAD(' ',1)|| --P1 21.59 pos 5159 - VIDE
		RPAD(' ',15)|| --P1 21.60 pos 5160 - VIDE
		RPAD(' ',10)|| --P1 21.61 pos 5175 - VIDE
		RPAD(' ',10)|| --P1 21.62 pos 5185 - VIDE
		RPAD(' ',19)|| --P1 21.63 pos 5195 - VIDE
		RPAD(' ',3)|| --P1 21.64 pos 5214 - VIDE
		RPAD(' ',5)|| --P1 21.65 pos 5217 - VIDE
		RPAD(' ',1)|| --P1 21.66 pos 5222 - VIDE
		RPAD(' ',1)|| --P1 21.67 pos 5223 - VIDE
		RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)|| --P1 21.68 pos 5224 - VAR1%
		RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12)|| --P1 21.55 pos 5225 - VAR1%
		RPAD('N',1)|| --P1 21.69 pos 5237 - VAR1%
		RPAD(' ',20)|| --P1 21.89 pos 5238 - VIDE
		RPAD(' ',10)|| --P1 21.90 pos 5258 - VIDE
		RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1)|| --P1 8.13 pos 5268
		RPAD(' ',40)|| --P1 21.71 pos 5269 - VIDE
		RPAD(' ',40)|| --P1 21.72 pos 5309 - VIDE
		RPAD(' ',40)|| --P1 21.73 pos 5349 - VIDE
		RPAD(' ',40)|| --P1 21.74 pos 5389 - VIDE
		RPAD(' ',40)|| --P1 21.75 pos 5429 - VIDE
		RPAD(' ',40)|| --P1 21.76 pos 5469 - VIDE
		RPAD(' ',11)|| --P1 21.77 pos 5509 - VIDE
		RPAD(' ',12)|| --P1 21.78 pos 5520 - VIDE
		RPAD(' ',1)|| --P1 21.94 pos 5532 - VIDE
		RPAD(' ',2)|| --P1 21.95 pos 5533 - VIDE
		RPAD(' ',1)|| --P1 21.79 pos 5535 - VIDE
		RPAD(NVL(C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE,' '),3)|| --P1 21.80 pos 5536 - VAR1%
		RPAD(' ',10)|| --P1 21.81 pos 5539 - VIDE
		RPAD(' ',10)|| --P1 21.82 pos 5549 - VIDE
		RPAD(' ',15)|| --P1 21.83 pos 5559 - VIDE
		RPAD(' ',15)|| --P1 21.84 pos 5574 - VIDE
		RPAD(' ',15)|| --P1 21.85 pos 5589 - VIDE
		RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1)|| --P1 21.86 pos 5604 
		RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1)|| --P1 21.87 pos 5605
		RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1)|| --P1 21.88 pos 5606
		RPAD(' ',19)|| --P1 21.91 pos 5607 - VIDE
		RPAD(' ',3)|| --P1 21.92 pos 5626 - VIDE
		RPAD(' ',5)|| --P1 21.93 pos 5629 - VIDE
		RPAD(' ',20)|| --P1 31.51 pos 5634 - VIDE
		RPAD(' ',19)|| --P1 31.52 pos 5654 - VIDE
		RPAD(' ',3)|| --P1 31.53 pos 5673 - VIDE
		lPAD(' ', 24)	-- 5100 - 4922 --Mantis 11611 (VFN) -- Mantis 11841 
     as lignedetail2  
	 --Fin EMM
FROM ENG_CORP_P1   C_ENR
WHERE 1     =1
    AND FLAG_HN = 'O'
    AND A_EXTRAIRE   ='O'
    and (cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
    AND CD_TYPE_RISQUE LIKE '%VAR1%'
    ;

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
    -- Les champs 1.11 et 1.16 ont pas la même regle d'alimentation que dans la table  provisions_decotes_p9 
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



