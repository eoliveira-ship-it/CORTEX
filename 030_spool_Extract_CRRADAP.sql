--------------------------------------------------------------------------------
-- CAL-Version : 1.9                                                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Script        : 030_spool_Extract_CRRADAP.sql                              --
-- Objet         : spool fichier Export_CRRADAP                               --
--                                                                            --
-- Type          : Script SQL et PL/SQL                                       --
--------------------------------------------------------------------------------
-- Domaine       : RINT                                                       --
-- Application   : 030  - Declarations Des Risques                            --
--------------------------------------------------------------------------------
-- Notice        : Notice CRRAV4.4_Adapté_Adapted_V44.02.xlsx                 --
--------------------------------------------------------------------------------
-- Creation      : le 18/05/2021 par DUGUET MARC                              --
--                                                                            --
-- Modifications                                                              --
-- -------------                                                              --
-- 16/01/2026 MESQUIPE: SIRL-712 - MERCA                                      --
-- 01/04/2025 GOMESHU : Mantis 73798                                          --
-- 10/01/2024 GOMESHU : BALE4                                                 --
--------------------------------------------------------------------------------
-- 18/05/2022 CUNHAVI : Mantis 62434 - Retour en arrière de l'US 302          --
-- 24/03/2022 CUNHAVI : US 302 - Changement alimentation du champs 5.4        --
-- 24/02/2022 GOMESHU : Mantis 11855 - structure fichiers CRR                 --
-- 04/02/2022 CUNHAVI : Mantis 11841 - Taille Ligne                           --
-- 13/07/2021 MIPAMES : US 216 CRRv4.3                                        --
-- 12/07/2021 DUGUETMA : US216 Restitution CRRV4.3 Adapte                     --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- spool fichier Export_CRRADAP

/*
Nom du fichier dâ€™export : en parametre 2 
CrÃ©ation dans le repertoire : en parametre 1
2 bind variable : 
       ENTITE  : entite a extraire (= cd_conso_cpt )
       MASYSDATE : date d'extraction (yyyymmddHHMI): idem sur ttes les lignes et l'entete
Formats  :  char 4201

   /!\    Dans les select : pas de lignes vides , 
  / ! \                     pas de point-virgule dans commentaires
  -----   

select ( champ1 || champ2 ) as lignedetail1 from table : lignedetail1 limitÃ© a 4000 car 
Pour avoir les 4201 car : 
select ( champ1 || champ2 ) as lignedetail1, champ3 as lignedetail2  from table  : 

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
SET COLSEP '' -- KLx M11855 GHU
SET WRAP OFF -- KLx M11855 VDC
--12/07/21 CDS ATOS (VFN) US 216 CRRv4.3
--SET linesize 4201   --4201  mais requete SQL limite Ã  4000 !
SET linesize 2000   --5100  mais lignedetail1 fera 4000 et lignedetail2 fera 1099
--Fin EMM


-- append : ecriture du spool a la suite de la ligne ENTETE ecrite ds shell
spool &1/&2 append;

------------------------------------------------------------------------------------------------------------------------
-- ENTETE : ecrite ds shell
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Â§01: a partir de P_UTLF_DEGRADE_A1
------------------------------------------------------------------------------------------------------------------------
select 
    	RPAD( to_char(C_ENR.DT_ARRETE, 'YYYYMMDD'), 8 )||
      RPAD( NVL(C_ENR.CD_CONSO_CPT,' '), 5 )||
      RPAD( CASE WHEN nvl(C_ENR.CORRECTIF,'N') = 'N' THEN 'A_BTR' ELSE 'ACORE' END, 12 )||
      RPAD( 'M', 1 )||
      RPAD( :MASYSDATE, 12 )||
      RPAD( 'A1', 2 )||
      RPAD( ' ', 10 )||
      RPAD( ' ', 130 )|| --1.98
      RPAD( NVL(C_ENR.ID_ENGAGEMENT, ' '), 40 )||
      RPAD( ' ', 60 )||
      -- Debut 2 - INFORMATIONS CAP
      RPAD( NVL(C_ENR.CD_CAP, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_CONTREPARTIE, ' '), 2 ,'0' )||
      RPAD( NVL(C_ENR.CD_CONSO_PART, ' '), 5,'0' )||
      RPAD( NVL(C_ENR.CD_QUAL_PART, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_ISIN, ' '), 12 )||
      RPAD( NVL(C_ENR.NB_CONTREPARTIE, '0'), 8,'0' )||
      RPAD( ' ', 30 )||
      -- Fin 2 - INFORMATIONS CAP
      -- Debut 3 - INFORMATIONS GENERIQUES 
      RPAD( NVL(C_ENR.CD_METHODO_BALE2, ' '), 7 )||
      RPAD( NVL(C_ENR.CD_MOTEUR, ' '), 2 ) ||
      RPAD( ' ', 5 ) ||
      RPAD( NVL(C_ENR.CD_NATURE_CPT, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_DEVISE, ' '), 3 )||
      RPAD( NVL(C_ENR.CD_PORTEFEUILLE, ' '), 1 )||--04/08/2017 scinder en 2: 5 pour code ligne metier et 25 blans pour zone libre      RPAD(' ', 30)|| 
      RPAD( 'MLE00', 5 ) ||
      --CDS ATOS (VFN) US 216 CRRV4.3 12/07/2021
	RPAD( NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '), 6 )||
	RPAD( ' ', 5 )||
      RPAD( ' ', 14 )||
	--fin CDS ATOS (VFN)
      -- Fin 3 - INFORMATIONS GENERIQUES 
      -- Debut 4 - IFORMATIONS ENGAGEMENTS
      RPAD( NVL(C_ENR.CD_NATURE_SSJ, ' '), 2 )||
      RPAD( NVL(C_ENR.MNT_RWA, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_LFD, ' ') , 1 )||
      RPAD( NVL(C_ENR.MATURITE_RES, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_ENG_DTX, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_PASSAGE_DEF, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_DUREE, ' '), 1 )||
      RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_POND_EXPO), 10 )|| -- A1 4.6 - Taille = 10
      RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_CCF), 10 )||
      RPAD( NVL(C_ENR.CD_PCCO1, ' '), 12 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO1),0)), 19 )||
      RPAD( NVL(C_ENR.CD_PCCO2, ' '), 12 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO2),0)), 19 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_ASSIETTE),0)), 19 )||
      RPAD( NVL(C_ENR.CD_CONSO_ENG, ' '), 5 )||
      RPAD( ' ' , 1 )|| -- Free Zone
      RPAD( NVL(C_ENR.BUCKET_IFRS9, ' '), 2 ) || -- A1 4.17 - Bucket IFRS9 -- M73798
      RPAD( ' ', 27 )||
      -- Fin 4 - INFORMATIONS ENGAGEMENTS
      -- DÃ©but 5 - PrÃªt immobilier et CrÃ©dit-Bail immobilier 
      RPAD( NVL(C_ENR.CD_USAGE_BIEN_IMM, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_RESPECT_COND, ' '), 1 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_VTR_PDR),0)), 19 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_HYPOTHEQUE),0)), 19 )||
      RPAD( NVL(C_ENR.CD_ACHAT_FIN_LOC, ' '), 1 )|| -- Mantis 62434 - Retour en arriere -- RPAD( '0' , 1 )|| -- US 302 Alimentation du champ 5.4 avec un zero '0'
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_VR),0)), 19 )||
      RPAD( ' ', 30 )||
      -- Fin 5 - PrÃªt immobilier et CrÃ©dit-Bail immobilier 
      -- Debut 6 - INFORMATIONS SURETES 
      RPAD( NVL(C_ENR.CD_CAP_SURETE, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_PAYS_SURETE, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_DEPOT_SUR, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_CONSO_SUR, ' '), 5 )||
      RPAD( NVL(C_ENR.CD_NATURE_SUR, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_FOUR_SUR, ' '), 4 )||
      RPAD( NVL(C_ENR.CD_FAMILLE_SUR, ' '), 3 )||
      RPAD( NVL(C_ENR.CD_PCCO3, ' '), 12 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO3),0)), 19 )||
      RPAD( NVL(C_ENR.CD_VALO_BIEN, ' '), 1 )||
      RPAD( ' ', 1 ) ||
      RPAD( ' ', 29 )||
      -- Fin 6 - INFORMATIONS SURETES
      -- Debut 7 - INFORMATIONS Provision spÃ©cifique
      RPAD( NVL(C_ENR.CD_PCCO4, ' '), 12 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO4),0)), 19 )||
      RPAD( NVL(C_ENR.CD_NATURE_PROV, ' '), 12 )|| -- A1 7.3
      -- Fin 7 - INFORMATIONS Provision spÃ©cifique
      -- DÃ©but 8 - INFORMATIONS DÃ©cote
      RPAD( NVL(C_ENR.CD_PCCO5, ' '), 12 )||
      RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO5),0)), 19 )||--04/08/2018      RPAD(NVL(C_ENR.CD_NATURE_DECO, ' '), 12)||
      RPAD( NVL('', ' '), 12 )||        --  CD_NATURE_DECO
      -- Fin 8 - INFORMATIONS DÃ©cote
	--CDS ATOS (VFN) US 216 CRRV4.3 12/07/2021
      LPAD( ' ', 1164) as lignedetail--,  --4000 -836
  --    LPAD( ' ', 3164) as lignedetail,  --4000 -836
	--fin CDS ATOS (VFN)
   --   LPAD( ' ', 1099) as lignedetail2 -- fin de ligne -- Mantis 11841 
FROM  A1_CRRV4_DEGRADE   C_ENR
Where CD_STATUT_LIGNE = 'V'
      and ( cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
      AND DT_ARRETE = (select max(dt_arrete) from eng_corp_p1); 


------------------------------------------------------------------------------------------------------------------------
-- Â§02: a partir de P_UTLF_AUTO_A1 
------------------------------------------------------------------------------------------------------------------------

SELECT
    	RPAD( to_char(C_ENR.DT_ARRETE, 'YYYYMMDD') , 8 )||
      RPAD( NVL(C_ENR.CD_CONSO_CPT,' '), 5 )||
	RPAD( CASE WHEN nvl(C_ENR.CORRECTIF,'N') = 'N' THEN 'A_BTR' ELSE 'ACORE' END, 12 )||
      RPAD( 'M' , 1 )||
      RPAD(:MASYSDATE, 12 )||
      RPAD( 'A1' , 2 )||
      RPAD( ' ', 10 )||
      RPAD( ' ', 130 )||
      RPAD( NVL(C_ENR.ID_ENGAGEMENT, ' '), 40)||
      RPAD( ' ', 60 )||
      -- Debut 2 - INFORMATIONS CAP     
      RPAD( NVL(C_ENR.CD_CAP, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_CONTREPARTIE, ' '), 2,'0' )||
      RPAD( NVL(C_ENR.CD_CONSO_PART, ' '), 5,'0' )||
      RPAD( NVL(C_ENR.CD_QUAL_PART, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_ISIN, ' '), 12 )||
      RPAD( NVL(C_ENR.NB_CONTREPARTIE, '0'), 8,'0' )||
      RPAD( ' ', 30)||
      -- Fin 2 - INFORMATIONS CAP
      -- Debut 3 - INFORMATIONS GENERIQUES       
      RPAD( NVL(C_ENR.CD_METHODO_BALE2, ' '), 7 )||
      RPAD( NVL(C_ENR.CD_MOTEUR, ' '), 7 )||
      RPAD( NVL(C_ENR.CD_NATURE_CPT, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_DEVISE, ' '), 3 )||
      RPAD( NVL(C_ENR.CD_PORTEFEUILLE, ' '), 1 )||
      --04/08/2017 scinder en 2: 5 pour code ligne metier et 25 blans pour zone libre      RPAD(' ', 30)|| 
      RPAD( 'MLE00', 5 ) ||
      --CDS ATOS (VFN) US 216 CRRV4.3 12/07/2021
	RPAD( NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '), 6 )||
	RPAD( ' ', 5 )||
      RPAD( ' ', 14 )||
	--fin CDS ATOS (VFN)
      -- Fin 3 - INFORMATIONS GENERIQUES 
      -- Debut 4 - IFORMATIONS ENGAGEMENTS      
      RPAD( NVL(C_ENR.CD_NATURE_SSJ, ' '), 2 )||
      RPAD( NVL(C_ENR.MNT_RWA, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_LFD, ' '), 1 )||
      RPAD( NVL(C_ENR.MATURITE_RES, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_ENG_DTX, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_PASSAGE_DEF, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_DUREE, ' '), 1 )||
      RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_POND_EXPO), 10 )||
      RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_CCF), 10 )||
      RPAD( NVL(C_ENR.CD_PCCO1, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO1),0)), 19 )||
      RPAD( NVL(C_ENR.CD_PCCO2, ' '), 12)||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO2),0)), 19 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ASSIETTE),0)), 19 )||
      RPAD( NVL(C_ENR.CD_CONSO_ENG, ' '), 5 )||
      --RPAD( ' ', 30 )||
      RPAD( ' ', 1 )||
      RPAD( NVL(C_ENR.BUCKET_IFRS9, ' '), 2 ) || -- A1 4.17 - Bucket IFRS9 -- M73798
      RPAD( ' ', 27 )||         
      -- Fin 4 - INFORMATIONS ENGAGEMENTS
      -- Debut 5 - Pret immobilier et Credit-Bail immobilier       
      RPAD( NVL(C_ENR.CD_USAGE_BIEN_IMM, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_RESPECT_COND, ' '), 1 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR_PDR),0)), 19 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_HYPOTHEQUE),0)), 19 )||
      RPAD( NVL(C_ENR.CD_ACHAT_FIN_LOC, ' '), 1 )|| -- Mantis 62434  -- RPAD( '0' , 1 )|| -- US 302 Alimentation du champ 5.4 avec un zÃ©ro '0'
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)), 19 )||
      RPAD( ' ', 30 )||    
      -- Fin 5 - Pret immobilier et Credit-Bail immobilier 
      -- Debut 6 - INFORMATIONS SURETES       
      RPAD( NVL(C_ENR.CD_CAP_SURETE, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_PAYS_SURETE, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_DEPOT_SUR, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_CONSO_SUR, ' '), 5 )||
      RPAD( NVL(C_ENR.CD_NATURE_SUR, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_FOUR_SUR, ' '), 4 )||
      RPAD( NVL(C_ENR.CD_FAMILLE_SUR, ' '), 3 )||
      RPAD( NVL(C_ENR.CD_PCCO3, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO3),0)), 19 )||
      RPAD( NVL(C_ENR.CD_VALO_BIEN, ' '), 1 )||
      RPAD(' ', 30 )||
      -- Fin 6 - INFORMATIONS SURETES
      -- Debut 7 - INFORMATIONS Provision specifique      
      RPAD( NVL(C_ENR.CD_PCCO4, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO4),0)), 19 )||
      RPAD( NVL(C_ENR.CD_NATURE_PROV, ' '), 12 )|| -- A1 7.3
      -- Fin 7 - INFORMATIONS Provision spÃ©cifique
      -- DÃ©but 8 - INFORMATIONS DÃ©cote      
      RPAD( NVL(C_ENR.CD_PCCO5, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO5),0)),19 )||
      RPAD( NVL(C_ENR.CD_NATURE_DECO, ' '), 12 )||
      -- Fin 8 - INFORMATIONS DÃ©cote      
      --CDS ATOS (VFN) US 216 CRRV4.3 12/07/2021
      LPAD(' ', 1164)  as lignedetail--, --4000 -836
    --  LPAD(' ', 3164)  as lignedetail, --4000 -836
	--fin CDS ATOS (VFN)
  --    LPAD(' ', 1099) as lignedetail2  -- fin de ligne -- Mantis 11841 
FROM  A1_DEGRADE_AUTO    C_ENR
Where CD_STATUT_LIGNE = 'V'
      and ( cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' ) 
	AND DT_ARRETE = (select max(dt_arrete) from eng_corp_p1);

------------------------------------------------------------------------------------------------------------------------
-- Â§03: a partir de P_UTLF_A1_GMBH
------------------------------------------------------------------------------------------------------------------------

SELECT
      RPAD( to_char(C_ENR.DT_ARRETE, 'YYYYMMDD'), 8 )|| 
      --SIRL-712
      --RPAD( '00357', 5 )|| 
      RPAD( '00416', 5 )|| 
      --SIRL-712
      --RPAD( 'A_GMBH', 12 )||
      RPAD( 'A_MERCA', 12 )||
      RPAD( 'M', 1 )|| 
      RPAD( :MASYSDATE, 12 )||
      RPAD( 'A1', 2 )|| 
      RPAD( ' ', 10 )||     
      RPAD( ' ', 130 )||
      RPAD( NVL(C_ENR.ID_ENGAGEMENT, ' '), 40 )||
      RPAD( ' ', 60 )||     
      RPAD( NVL(C_ENR.CD_APE, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_CONTREPARTIE, ' '), 2 , '0' )||
      RPAD( NVL(C_ENR.CD_CONSO_PART, ' '), 5 , '0' )||
      RPAD( NVL(C_ENR.CD_QUAL_PART, ' '), 1 )||
      RPAD( ' ', 12 )||
      RPAD( ' ', 8 )||
      RPAD( ' ', 30 )||      
      RPAD( 'STD', 7 )|| 
      RPAD( '01', 2 )|| 
      RPAD( ' ', 5 )|| 
      RPAD( NVL(C_ENR.CD_NATURE_CPT, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_DEVISE, ' '), 3 )||
      RPAD( 'B', 1 )|| 
      RPAD( NVL(C_ENR.CD_LIGNE_METIER, ' '), 5 )||
      RPAD( NVL(C_ENR.CD_PRD_BANK, ' '), 6 )||	   
      RPAD( ' ', 23 )||
      RPAD( NVL(C_ENR.CD_LFD, ' '), 1 )||
      RPAD( NVL(C_ENR.MATURITE_RES, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_ENG_DTX, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_PASSAGE_DEF, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_DUREE, ' '), 1 )||
      RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_POND_EXPO), 10 )||
      RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_CCF), 10 )||
      RPAD( NVL(C_ENR.CD_PCCO1, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO1),0)), 19 )||
      RPAD( NVL(C_ENR.CD_PCCO2, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO2),0)), 19 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ASSIETTE),0)), 19 )||
      RPAD( NVL(C_ENR.CD_CONSO_ENG, ' '), 5 )||
      RPAD( ' ', 1 )||
      RPAD( NVL(C_ENR.BUCKET_IFRS9, ' '), 2 )|| -- A1 4.17
      RPAD( ' ', 27 )||
      RPAD( NVL(C_ENR.CD_USAGE_BIEN_IMM, ' '), 1)||
      RPAD( NVL(C_ENR.CD_RESPECT_COND, ' '), 1)||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR_PDR),0)),19)||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_HYPOTHEQUE),0)),19)||
      RPAD( NVL(C_ENR.CD_ACHAT_FIN_LOC, ' '), 1 )|| -- Mantis 62434 -- RPAD( '0' , 1 )|| -- US 302 Alimentation du champ 5.4 avec un zÃ©ro '0'
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)),19 )||
      RPAD( ' ', 30 )||
      RPAD( NVL(C_ENR.CD_CAP_SURETE, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_PAYS_SURETE, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_DEPOT_SUR, ' '), 2 )||
      RPAD( NVL(C_ENR.CD_CONSO_SUR, ' '), 5 )||
      RPAD( NVL(C_ENR.CD_NATURE_SUR, ' '), 12 )||
      RPAD( NVL(C_ENR.CD_FOUR_SUR, ' '), 4 )||
      RPAD( NVL(C_ENR.CD_FAMILLE_SUR, ' '), 3 )||
      RPAD( NVL(C_ENR.CD_PCCO3, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO3),0)), 19 )||
      RPAD( NVL(C_ENR.CD_VALO_BIEN, ' '), 1 )||
      RPAD( NVL(C_ENR.CD_ECHELON_CREDIT, ' '), 1 )||
      RPAD( ' ', 29 )||
      RPAD( NVL(C_ENR.CD_PCCO4, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO4),0)), 19 )||
      RPAD( NVL(C_ENR.CD_NATURE_PROV, ' '), 12 )|| -- A1 7.3
      RPAD( NVL(C_ENR.CD_PCCO5, ' '), 12 )||
      RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO5),0)), 19 )||
      RPAD( NVL(C_ENR.CD_NATURE_DECO, ' '), 12 )||
      LPAD( ' ', 1164 )  as lignedetail--,
   --   LPAD( ' ', 3164 )  as lignedetail,
    --  LPAD( ' ', 1099 ) as lignedetail2 -- Mantis 11841 
FROM  A1_DEGRADE_GMBH    C_ENR
      --SIRL-712
      --Where ( '00357' = :ENTITE or :ENTITE = 'TOTAL' ) 
      Where ( '00416' = :ENTITE or :ENTITE = 'TOTAL' ) 
      and ( 0 = :REJETNUMBER )
      and C_ENR.DT_ARRETE = (select max(dt_arrete) from eng_corp_p1);
------------------------------------------------------------------------------------------------------------------------
-- ENQUEUE : ecrite dans shell
------------------------------------------------------------------------------------------------------------------------

spool off;



