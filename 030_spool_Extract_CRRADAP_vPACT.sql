--------------------------------------------------------------------------------
-- CAL-Version : 1.9                                                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Script        : 030_spool_Extract_CRRADAP_vPACT.sql                        --
-- Objet         : spool fichier Export_CRRADAP                               --
--                                                                            --
-- Type          : Script SQL et PL/SQL                                       --
--------------------------------------------------------------------------------
-- Domaine       : RINT                                                       --
-- Application   : 030  - Declarations Des Risques                            --
--------------------------------------------------------------------------------
-- Notice        : Notice CRRAV4.4_Adapte_Adapted_V44.02.xlsx                 --
-- VERSAO 2026-09-27a : o Adapte com ";" entre todos os campos.
--   Gerado por gen_spool_adap.py a partir de 030_spool_Extract_CRRADAP.sql.
--   Regua: Notice PACTV4.5_Adapte_Adapted_V45.00, aba A1.
--   Corre pelo 030_CREATION_SPOOL_CRRADAP_vPACT.sh, que o chama por
--   este nome. Conferir no servidor com:  grep VERSAO 030_spool_Extract_CRRADAP_vPACT.sql
--------------------------------------------------------------------------------
-- Creation      : le 18/05/2021 par DUGUET MARC                              --
--                                                                            --
-- Modifications                                                              --
-- -------------                                                              --
-- 16/01/2026 MESQUIPE: SIRL-712 - MERCA                                      --
-- 01/04/2025 GOMESHU : Mantis 73798                                          --
-- 10/01/2024 GOMESHU : BALE4                                                 --
--------------------------------------------------------------------------------
-- 18/05/2022 CUNHAVI : Mantis 62434 - Retour en arriere de l'US 302          --
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
Nom du fichier dexport : en parametre 2 
Creation dans le repertoire : en parametre 1
2 bind variable : 
       ENTITE  : entite a extraire (= cd_conso_cpt )
       MASYSDATE : date d'extraction (yyyymmddHHMI): idem sur ttes les lignes et l'entete
Formats  :  char 4201

   /!\    Dans les select : pas de lignes vides , 
  / ! \                     pas de point-virgule dans commentaires
  -----   

select ( champ1 || champ2 ) as lignedetail1 from table : lignedetail1 limite a 4000 car 
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
--SET linesize 4201   --4201  mais requete SQL limite a 4000 !
SET linesize 2000   --5100  mais lignedetail1 fera 4000 et lignedetail2 fera 1099
--Fin EMM


-- append : ecriture du spool a la suite de la ligne ENTETE ecrite ds shell
spool &1/&2 append;

------------------------------------------------------------------------------------------------------------------------
-- ENTETE : ecrite ds shell
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- 01: a partir de P_UTLF_DEGRADE_A1
------------------------------------------------------------------------------------------------------------------------
select
       RPAD(TRANSLATE( to_char(C_ENR.DT_ARRETE, 'YYYYMMDD'), ';', '.'), 8 )||';'||   -- 0.1 (A1)     EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CONSO_CPT,' '), ';', '.'), 5 )||';'||   -- 0.2 (A1)     EXATO
       RPAD(TRANSLATE( CASE WHEN nvl(C_ENR.CORRECTIF,'N') = 'N' THEN 'A_BTR' ELSE 'ACORE' END, ';', '.'), 12 )||';'||   -- 0.3 (A1)     EXATO
       RPAD( 'M', 1 )||';'||   -- 0.4 (A1)     EXATO
       RPAD( :MASYSDATE, 12 )||';'||   -- 0.5 (A1)     EXATO
       RPAD( 'A1', 2 )||';'||   -- 0.6 (A1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (A1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (A1)     BRANCO
       RPAD(' ', 7)||';'||   -- 0.99 (A1)    BRANCO
       RPAD( ' ', 130 )||';'||   -- A1 1.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.ID_ENGAGEMENT, ' '), ';', '.'), 40 )||';'||   -- A1 1.11      EXATO
       RPAD( ' ', 60 )||';'||   -- A1 1.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CAP, ' '), ';', '.'), 12 )||';'||   -- A1 2.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), ';', '.'), 2 )||';'||   -- A1 2.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CONTREPARTIE, ' '), ';', '.'), 2 ,'0' )||';'||   -- A1 2.3       EXATO
       RPAD( NVL(C_ENR.CD_CONSO_PART, ' '), 5,'0' )||';'||   -- A1 2.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_QUAL_PART, ' '), ';', '.'), 1 )||';'||   -- A1 2.5       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ISIN, ' '), ';', '.'), 12 )||';'||   -- A1 2.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.NB_CONTREPARTIE, '0'), ';', '.'), 8,'0' )||';'||   -- A1 2.7       EXATO
       RPAD( ' ', 30 )||';'||   -- A1 2.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_METHODO_BALE2, ' '), ';', '.'), 7 )||';'||   -- A1 3.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_MOTEUR, ' '), ';', '.'), 2 )||';'||   -- A1 3.5       EXATO
       RPAD( ' ', 5 )||';'||   -- A1 3.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_CPT, ' '), ';', '.'), 12 )||';'||   -- A1 3.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DEVISE, ' '), ';', '.'), 3 )||';'||   -- A1 3.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PORTEFEUILLE, ' '), ';', '.'), 1 )||';'||   -- A1 3.4       EXATO
       RPAD( 'MLE00', 5 )||';'||   -- A1 3.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '), ';', '.'), 6 )||';'||   -- A1 3.7       EXATO
       RPAD( ' ', 5 )||';'||   -- A1 3.8       EXATO
       RPAD( ' ', 14 )||';'||   -- A1 3.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_SSJ, ' '), ';', '.'), 2 )||';'||   -- A1 4.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.MNT_RWA, ' '), ';', '.'), 2 )||';'||   -- A1 4.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_LFD, ' ') , ';', '.'), 1 )||';'||   -- A1 4.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.MATURITE_RES, ' '), ';', '.'), 1 )||';'||   -- A1 4.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ENG_DTX, ' '), ';', '.'), 1 )||';'||   -- A1 4.14      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PASSAGE_DEF, ' '), ';', '.'), 1 )||';'||   -- A1 4.15      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DUREE, ' '), ';', '.'), 1 )||';'||   -- A1 4.5       EXATO
       RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_POND_EXPO), 10 )||';'||   -- A1 4.6       EXATO
       RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_CCF), 10 )||';'||   -- A1 4.7       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO1, ' '), ';', '.'), 12 )||';'||   -- A1 4.8       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO1),0)), 19 )||';'||   -- A1 4.9       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO2, ' '), ';', '.'), 12 )||';'||   -- A1 4.10      EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO2),0)), 19 )||';'||   -- A1 4.11      EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_ASSIETTE),0)), 19 )||';'||   -- A1 4.12      EXATO
       RPAD( NVL(C_ENR.CD_CONSO_ENG, ' '), 5 )||';'||   -- A1 4.13      EXATO
       RPAD( ' ' , 1 )||';'||   -- A1 4.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.BUCKET_IFRS9, ' '), ';', '.'), 2 )||';'||   -- A1 4.17      EXATO
       RPAD( ' ', 27 )||';'||   -- A1 4.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_USAGE_BIEN_IMM, ' '), ';', '.'), 1 )||';'||   -- A1 5.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_RESPECT_COND, ' '), ';', '.'), 1 )||';'||   -- A1 5.6       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_VTR_PDR),0)), 19 )||';'||   -- A1 5.2       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_HYPOTHEQUE),0)), 19 )||';'||   -- A1 5.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ACHAT_FIN_LOC, ' '), ';', '.'), 1 )||';'||   -- A1 5.4       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_VR),0)), 19 )||';'||   -- A1 5.5       EXATO
       RPAD( ' ', 30 )||';'||   -- A1 5.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CAP_SURETE, ' '), ';', '.'), 12 )||';'||   -- A1 6.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PAYS_SURETE, ' '), ';', '.'), 2 )||';'||   -- A1 6.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DEPOT_SUR, ' '), ';', '.'), 2 )||';'||   -- A1 6.3       EXATO
       RPAD( NVL(C_ENR.CD_CONSO_SUR, ' '), 5 )||';'||   -- A1 6.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_SUR, ' '), ';', '.'), 12 )||';'||   -- A1 6.5       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_FOUR_SUR, ' '), ';', '.'), 4 )||';'||   -- A1 6.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_FAMILLE_SUR, ' '), ';', '.'), 3 )||';'||   -- A1 6.7       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO3, ' '), ';', '.'), 12 )||';'||   -- A1 6.8       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO3),0)), 19 )||';'||   -- A1 6.9       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_VALO_BIEN, ' '), ';', '.'), 1 )||';'||   -- A1 6.10      EXATO
       RPAD( ' ', 1 )||';'||   -- A1 6.11      EXATO
       RPAD( ' ', 29 )||';'||   -- A1 6.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO4, ' '), ';', '.'), 12 )||';'||   -- A1 7.1       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO4),0)), 19 )||';'||   -- A1 7.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_PROV, ' '), ';', '.'), 12 )||';'||   -- A1 7.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO5, ' '), ';', '.'), 12 )||';'||   -- A1 8.1       EXATO
       RPAD( pack_utilitaire.F_FORMAT_MONTANT_BIS2(nvl((C_ENR.MNT_PCCO5),0)), 19 )||';'||   -- A1 8.2       EXATO
       RPAD( NVL('', ' '), 12 )||';'||   -- A1 8.3       EXATO
       RPAD(' ', 1)||';'||   -- A1 523       NOVO
       RPAD(' ', 6)||';'||   -- A1 2.0       NOVO
       RPAD(' ', 1)||';'||   -- A1 86        NOVO
       RPAD(' ', 20)||';'||   -- A1 86.1      NOVO
       RPAD(' ', 2)||';'||   -- A1 86.2      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.3      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.4      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.5      NOVO
       RPAD(' ', 12)||';'||   -- A1 500       NOVO
       RPAD(' ', 8)||';'||   -- A1 29        NOVO
       RPAD(' ', 8)||';'||   -- A1 30        NOVO
       RPAD(' ', 8)||';'||   -- A1 31        NOVO
       RPAD(' ', 3)||';'||   -- A1 22.56     NOVO
       RPAD(' ', 1)||';'||   -- A1 22.16     NOVO
       RPAD(' ', 2)||';'||   -- A1 83        NOVO
       RPAD(' ', 8)||';'||   -- A1 530       NOVO
       RPAD(' ', 6)||';'||   -- A1 531       NOVO
       RPAD(' ', 929) as lignedetail   -- A1 99.99     FILLER (1019 - 90 separadores, sem ';' a seguir)
  --    LPAD( ' ', 3164) as lignedetail,  --4000 -836
	--fin CDS ATOS (VFN)
   --   LPAD( ' ', 1099) as lignedetail2 -- fin de ligne -- Mantis 11841 
FROM  A1_CRRV4_DEGRADE   C_ENR
Where CD_STATUT_LIGNE = 'V'
      and ( cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' )
      AND DT_ARRETE = (select max(dt_arrete) from eng_corp_p1); 


------------------------------------------------------------------------------------------------------------------------
-- 02: a partir de P_UTLF_AUTO_A1 
------------------------------------------------------------------------------------------------------------------------

select
       RPAD(TRANSLATE( to_char(C_ENR.DT_ARRETE, 'YYYYMMDD') , ';', '.'), 8 )||';'||   -- 0.1 (A1)     EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CONSO_CPT,' '), ';', '.'), 5 )||';'||   -- 0.2 (A1)     EXATO
       RPAD(TRANSLATE( CASE WHEN nvl(C_ENR.CORRECTIF,'N') = 'N' THEN 'A_BTR' ELSE 'ACORE' END, ';', '.'), 12 )||';'||   -- 0.3 (A1)     EXATO
       RPAD( 'M' , 1 )||';'||   -- 0.4 (A1)     EXATO
       RPAD(:MASYSDATE, 12 )||';'||   -- 0.5 (A1)     EXATO
       RPAD( 'A1' , 2 )||';'||   -- 0.6 (A1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (A1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (A1)     BRANCO
       RPAD(' ', 7)||';'||   -- 0.99 (A1)    BRANCO
       RPAD( ' ', 130 )||';'||   -- A1 1.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.ID_ENGAGEMENT, ' '), ';', '.'), 40)||';'||   -- A1 1.11      EXATO
       RPAD( ' ', 60 )||';'||   -- A1 1.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CAP, ' '), ';', '.'), 12 )||';'||   -- A1 2.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), ';', '.'), 2 )||';'||   -- A1 2.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CONTREPARTIE, ' '), ';', '.'), 2,'0' )||';'||   -- A1 2.3       EXATO
       RPAD( NVL(C_ENR.CD_CONSO_PART, ' '), 5,'0' )||';'||   -- A1 2.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_QUAL_PART, ' '), ';', '.'), 1 )||';'||   -- A1 2.5       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ISIN, ' '), ';', '.'), 12 )||';'||   -- A1 2.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.NB_CONTREPARTIE, '0'), ';', '.'), 8,'0' )||';'||   -- A1 2.7       EXATO
       RPAD( ' ', 30)||';'||   -- A1 2.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_METHODO_BALE2, ' '), ';', '.'), 7 )||';'||   -- A1 3.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_MOTEUR, ' '), ';', '.'), 2 )||';'||   -- A1 3.5       REGRA
       RPAD( ' ', 5 )||';'||   -- A1 3.98      REGRA
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_CPT, ' '), ';', '.'), 12 )||';'||   -- A1 3.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DEVISE, ' '), ';', '.'), 3 )||';'||   -- A1 3.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PORTEFEUILLE, ' '), ';', '.'), 1 )||';'||   -- A1 3.4       EXATO
       RPAD( 'MLE00', 5 )||';'||   -- A1 3.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_TYPE_PROD_BANCAIRE, ' '), ';', '.'), 6 )||';'||   -- A1 3.7       EXATO
       RPAD( ' ', 5 )||';'||   -- A1 3.8       EXATO
       RPAD( ' ', 14 )||';'||   -- A1 3.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_SSJ, ' '), ';', '.'), 2 )||';'||   -- A1 4.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.MNT_RWA, ' '), ';', '.'), 2 )||';'||   -- A1 4.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_LFD, ' '), ';', '.'), 1 )||';'||   -- A1 4.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.MATURITE_RES, ' '), ';', '.'), 1 )||';'||   -- A1 4.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ENG_DTX, ' '), ';', '.'), 1 )||';'||   -- A1 4.14      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PASSAGE_DEF, ' '), ';', '.'), 1 )||';'||   -- A1 4.15      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DUREE, ' '), ';', '.'), 1 )||';'||   -- A1 4.5       EXATO
       RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_POND_EXPO), 10 )||';'||   -- A1 4.6       EXATO
       RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_CCF), 10 )||';'||   -- A1 4.7       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO1, ' '), ';', '.'), 12 )||';'||   -- A1 4.8       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO1),0)), 19 )||';'||   -- A1 4.9       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO2, ' '), ';', '.'), 12)||';'||   -- A1 4.10      EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO2),0)), 19 )||';'||   -- A1 4.11      EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ASSIETTE),0)), 19 )||';'||   -- A1 4.12      EXATO
       RPAD( NVL(C_ENR.CD_CONSO_ENG, ' '), 5 )||';'||   -- A1 4.13      EXATO
       RPAD( ' ', 1 )||';'||   -- A1 4.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.BUCKET_IFRS9, ' '), ';', '.'), 2 )||';'||   -- A1 4.17      EXATO
       RPAD( ' ', 27 )||';'||   -- A1 4.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_USAGE_BIEN_IMM, ' '), ';', '.'), 1 )||';'||   -- A1 5.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_RESPECT_COND, ' '), ';', '.'), 1 )||';'||   -- A1 5.6       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR_PDR),0)), 19 )||';'||   -- A1 5.2       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_HYPOTHEQUE),0)), 19 )||';'||   -- A1 5.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ACHAT_FIN_LOC, ' '), ';', '.'), 1 )||';'||   -- A1 5.4       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)), 19 )||';'||   -- A1 5.5       EXATO
       RPAD( ' ', 30 )||';'||   -- A1 5.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CAP_SURETE, ' '), ';', '.'), 12 )||';'||   -- A1 6.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PAYS_SURETE, ' '), ';', '.'), 2 )||';'||   -- A1 6.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DEPOT_SUR, ' '), ';', '.'), 2 )||';'||   -- A1 6.3       EXATO
       RPAD( NVL(C_ENR.CD_CONSO_SUR, ' '), 5 )||';'||   -- A1 6.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_SUR, ' '), ';', '.'), 12 )||';'||   -- A1 6.5       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_FOUR_SUR, ' '), ';', '.'), 4 )||';'||   -- A1 6.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_FAMILLE_SUR, ' '), ';', '.'), 3 )||';'||   -- A1 6.7       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO3, ' '), ';', '.'), 12 )||';'||   -- A1 6.8       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO3),0)), 19 )||';'||   -- A1 6.9       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_VALO_BIEN, ' '), ';', '.'), 1 )||';'||   -- A1 6.10      EXATO
       RPAD(' ', 1)||';'||   -- A1 6.11      BRANCO
       RPAD(' ', 29)||';'||   -- A1 6.99      BRANCO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO4, ' '), ';', '.'), 12 )||';'||   -- A1 7.1       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO4),0)), 19 )||';'||   -- A1 7.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_PROV, ' '), ';', '.'), 12 )||';'||   -- A1 7.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO5, ' '), ';', '.'), 12 )||';'||   -- A1 8.1       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO5),0)),19 )||';'||   -- A1 8.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_DECO, ' '), ';', '.'), 12 )||';'||   -- A1 8.3       EXATO
       RPAD(' ', 1)||';'||   -- A1 523       NOVO
       RPAD(' ', 6)||';'||   -- A1 2.0       NOVO
       RPAD(' ', 1)||';'||   -- A1 86        NOVO
       RPAD(' ', 20)||';'||   -- A1 86.1      NOVO
       RPAD(' ', 2)||';'||   -- A1 86.2      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.3      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.4      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.5      NOVO
       RPAD(' ', 12)||';'||   -- A1 500       NOVO
       RPAD(' ', 8)||';'||   -- A1 29        NOVO
       RPAD(' ', 8)||';'||   -- A1 30        NOVO
       RPAD(' ', 8)||';'||   -- A1 31        NOVO
       RPAD(' ', 3)||';'||   -- A1 22.56     NOVO
       RPAD(' ', 1)||';'||   -- A1 22.16     NOVO
       RPAD(' ', 2)||';'||   -- A1 83        NOVO
       RPAD(' ', 8)||';'||   -- A1 530       NOVO
       RPAD(' ', 6)||';'||   -- A1 531       NOVO
       RPAD(' ', 929) as lignedetail   -- A1 99.99     FILLER (1019 - 90 separadores, sem ';' a seguir)
    --  LPAD(' ', 3164)  as lignedetail, --4000 -836
	--fin CDS ATOS (VFN)
  --    LPAD(' ', 1099) as lignedetail2  -- fin de ligne -- Mantis 11841 
FROM  A1_DEGRADE_AUTO    C_ENR
Where CD_STATUT_LIGNE = 'V'
      and ( cd_conso_cpt = :ENTITE or :ENTITE = 'TOTAL' ) 
	AND DT_ARRETE = (select max(dt_arrete) from eng_corp_p1);

------------------------------------------------------------------------------------------------------------------------
-- 03: a partir de P_UTLF_A1_GMBH
------------------------------------------------------------------------------------------------------------------------

select
       RPAD(TRANSLATE( to_char(C_ENR.DT_ARRETE, 'YYYYMMDD'), ';', '.'), 8 )||';'||   -- 0.1 (A1)     EXATO
       RPAD( '00416', 5 )||';'||   -- 0.2 (A1)     EXATO
       RPAD( 'A_MERCA', 12 )||';'||   -- 0.3 (A1)     EXATO
       RPAD( 'M', 1 )||';'||   -- 0.4 (A1)     EXATO
       RPAD( :MASYSDATE, 12 )||';'||   -- 0.5 (A1)     EXATO
       RPAD( 'A1', 2 )||';'||   -- 0.6 (A1)     EXATO
       RPAD(' ', 1)||';'||   -- 0.7 (A1)     BRANCO
       RPAD(' ', 2)||';'||   -- 0.8 (A1)     BRANCO
       RPAD(' ', 7)||';'||   -- 0.99 (A1)    BRANCO
       RPAD( ' ', 130 )||';'||   -- A1 1.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.ID_ENGAGEMENT, ' '), ';', '.'), 40 )||';'||   -- A1 1.11      EXATO
       RPAD( ' ', 60 )||';'||   -- A1 1.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_APE, ' '), ';', '.'), 12 )||';'||   -- A1 2.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PAYS_RESIDENCE, ' '), ';', '.'), 2 )||';'||   -- A1 2.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CONTREPARTIE, ' '), ';', '.'), 2 , '0' )||';'||   -- A1 2.3       EXATO
       RPAD( NVL(C_ENR.CD_CONSO_PART, ' '), 5 , '0' )||';'||   -- A1 2.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_QUAL_PART, ' '), ';', '.'), 1 )||';'||   -- A1 2.5       EXATO
       RPAD( ' ', 12 )||';'||   -- A1 2.6       EXATO
       RPAD( ' ', 8 )||';'||   -- A1 2.7       EXATO
       RPAD( ' ', 30 )||';'||   -- A1 2.99      EXATO
       RPAD( 'STD', 7 )||';'||   -- A1 3.1       EXATO
       RPAD( '01', 2 )||';'||   -- A1 3.5       EXATO
       RPAD( ' ', 5 )||';'||   -- A1 3.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_CPT, ' '), ';', '.'), 12 )||';'||   -- A1 3.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DEVISE, ' '), ';', '.'), 3 )||';'||   -- A1 3.3       EXATO
       RPAD( 'B', 1 )||';'||   -- A1 3.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_LIGNE_METIER, ' '), ';', '.'), 5 )||';'||   -- A1 3.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PRD_BANK, ' '), ';', '.'), 6 )||';'||   -- A1 3.7       EXATO
       RPAD(' ', 5)||';'||   -- A1 3.8       BRANCO
       RPAD(' ', 14)||';'||   -- A1 3.99      BRANCO
       RPAD(' ', 2)||';'||   -- A1 4.1       BRANCO
       RPAD(' ', 2)||';'||   -- A1 4.2       BRANCO
       RPAD(TRANSLATE( NVL(C_ENR.CD_LFD, ' '), ';', '.'), 1 )||';'||   -- A1 4.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.MATURITE_RES, ' '), ';', '.'), 1 )||';'||   -- A1 4.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ENG_DTX, ' '), ';', '.'), 1 )||';'||   -- A1 4.14      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PASSAGE_DEF, ' '), ';', '.'), 1 )||';'||   -- A1 4.15      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DUREE, ' '), ';', '.'), 1 )||';'||   -- A1 4.5       EXATO
       RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_POND_EXPO), 10 )||';'||   -- A1 4.6       EXATO
       RPAD( pack_utilitaire.f_format_taux(C_ENR.TX_CCF), 10 )||';'||   -- A1 4.7       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO1, ' '), ';', '.'), 12 )||';'||   -- A1 4.8       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO1),0)), 19 )||';'||   -- A1 4.9       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO2, ' '), ';', '.'), 12 )||';'||   -- A1 4.10      EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO2),0)), 19 )||';'||   -- A1 4.11      EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ASSIETTE),0)), 19 )||';'||   -- A1 4.12      EXATO
       RPAD( NVL(C_ENR.CD_CONSO_ENG, ' '), 5 )||';'||   -- A1 4.13      EXATO
       RPAD( ' ', 1 )||';'||   -- A1 4.98      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.BUCKET_IFRS9, ' '), ';', '.'), 2 )||';'||   -- A1 4.17      EXATO
       RPAD( ' ', 27 )||';'||   -- A1 4.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_USAGE_BIEN_IMM, ' '), ';', '.'), 1)||';'||   -- A1 5.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_RESPECT_COND, ' '), ';', '.'), 1)||';'||   -- A1 5.6       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VTR_PDR),0)),19)||';'||   -- A1 5.2       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_HYPOTHEQUE),0)),19)||';'||   -- A1 5.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ACHAT_FIN_LOC, ' '), ';', '.'), 1 )||';'||   -- A1 5.4       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_VR),0)),19 )||';'||   -- A1 5.5       EXATO
       RPAD( ' ', 30 )||';'||   -- A1 5.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_CAP_SURETE, ' '), ';', '.'), 12 )||';'||   -- A1 6.1       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PAYS_SURETE, ' '), ';', '.'), 2 )||';'||   -- A1 6.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_DEPOT_SUR, ' '), ';', '.'), 2 )||';'||   -- A1 6.3       EXATO
       RPAD( NVL(C_ENR.CD_CONSO_SUR, ' '), 5 )||';'||   -- A1 6.4       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_SUR, ' '), ';', '.'), 12 )||';'||   -- A1 6.5       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_FOUR_SUR, ' '), ';', '.'), 4 )||';'||   -- A1 6.6       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_FAMILLE_SUR, ' '), ';', '.'), 3 )||';'||   -- A1 6.7       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO3, ' '), ';', '.'), 12 )||';'||   -- A1 6.8       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO3),0)), 19 )||';'||   -- A1 6.9       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_VALO_BIEN, ' '), ';', '.'), 1 )||';'||   -- A1 6.10      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_ECHELON_CREDIT, ' '), ';', '.'), 1 )||';'||   -- A1 6.11      EXATO
       RPAD( ' ', 29 )||';'||   -- A1 6.99      EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO4, ' '), ';', '.'), 12 )||';'||   -- A1 7.1       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO4),0)), 19 )||';'||   -- A1 7.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_PROV, ' '), ';', '.'), 12 )||';'||   -- A1 7.3       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_PCCO5, ' '), ';', '.'), 12 )||';'||   -- A1 8.1       EXATO
       RPAD( pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_PCCO5),0)), 19 )||';'||   -- A1 8.2       EXATO
       RPAD(TRANSLATE( NVL(C_ENR.CD_NATURE_DECO, ' '), ';', '.'), 12 )||';'||   -- A1 8.3       EXATO
       RPAD(' ', 1)||';'||   -- A1 523       NOVO
       RPAD(' ', 6)||';'||   -- A1 2.0       NOVO
       RPAD(' ', 1)||';'||   -- A1 86        NOVO
       RPAD(' ', 20)||';'||   -- A1 86.1      NOVO
       RPAD(' ', 2)||';'||   -- A1 86.2      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.3      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.4      NOVO
       RPAD(' ', 20)||';'||   -- A1 86.5      NOVO
       RPAD(' ', 12)||';'||   -- A1 500       NOVO
       RPAD(' ', 8)||';'||   -- A1 29        NOVO
       RPAD(' ', 8)||';'||   -- A1 30        NOVO
       RPAD(' ', 8)||';'||   -- A1 31        NOVO
       RPAD(' ', 3)||';'||   -- A1 22.56     NOVO
       RPAD(' ', 1)||';'||   -- A1 22.16     NOVO
       RPAD(' ', 2)||';'||   -- A1 83        NOVO
       RPAD(' ', 8)||';'||   -- A1 530       NOVO
       RPAD(' ', 6)||';'||   -- A1 531       NOVO
       RPAD(' ', 929) as lignedetail   -- A1 99.99     FILLER (1019 - 90 separadores, sem ';' a seguir)
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



