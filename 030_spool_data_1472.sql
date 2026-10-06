--------------------------------------------------------------------------------
-- CAL-Version : 8.44                                                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Script        : 030_spool_data.sql                                         --
-- Objet         : Script SQL et PL/SQL                                       --
-- Type          : Spool de fichiers afin de les transfert vers HCRR          --
--------------------------------------------------------------------------------
-- Domaine       : DDREX                                                      --
-- Application   : 030 - Declarations Des Risques                             --
--------------------------------------------------------------------------------
-- Creation      : le 23/11/2009 par BIZOT PATRICE                            --
-- Modifications :                                                            --
--------------------------------------------------------------------------------
-- 06/10/2026 KLx_Risq : SIRL-1472 - historisation ENG_CORP_P1_BIS            --
-- 23/05/2025 CUNHAVI : SIRL-130-131-132-DAFNE - Decomissionnement table flux GCA--
--      Adaptation extraction fichier 030_FLUX_2M_DDR_GRPE.txt sachant que    --
--          DDR_GCA sera toujours vide                                        --
-- 04/12/2025 ALMBR (KLx) - Correction anomalie RSE                           --
-- 21/07/2025 ALMEIDBR : v8.42 + projet OMP > SIRL-191                        --
-- 03/07/2025 MESQUIPE : RSE LOT3 - ajout colonne CD_CATEG_BIEN               --
--                       rename colonne CONSOM_ENERGIE_PRIMAIRE               --
--                       Ajoute de la table  REF_CORRES_FORM_JUR_FIFI243      --
-- 31/07/2025 SIUFIDA  : Projet RSE LOT 3 - extraction donnees DDR vers HCRR  --
-- 16/01/2025 KLx_Risq : v8.41 + M_72558 - ajout colonne SIREN afin de gerer  --
--                       des garants                                          --
-- 03/06/2024 GOMESHU  : N3D Forbearance                                      --
-- 03/02/2024 GOMESHU  : RSE LOT2                                             --
-- 05/02/2024 GOMESHU  : BALE4- OPE_OPERATION DONNEES MORATOIRES              --
-- 12/01/2024 KLx_Risq : v8.39 + M67006 - ajout des nouvelles champs          --
-- 21/07/2023 CUNHAVI  : Mantis 67050 - Correction Linesize                   --
-- 05/07/2023 ALMEIDBR : Ajout de nouvelle colonne MNT_BRUT_ORIGINE           --
-- 24/05/2023 Francico Lopes: PROJET RSE                                      --
-- 18/05/2023 ALMEIDBR : Projet VTR-CBI :: sous-chapitre 4.13.3 du SFG        --
-- 27/04/2023 ALMEIDBR : Projet VTR-CBI :: sous-chapitre 4.11.3 du SFG        --
-- 18/04/2023 ALMEIDBR : Projet VTR-CBI :: sous-chapitre 4.3.3 du SFG         --
-- 06/03/2023 ALMEIDBR : Projet VTR-CBI :: sous-chapitre 4.1.3 du SFG         --
-- 11/01/2023 ALMEIDBR : v8.36 + M65088 - ajout de la colonne MAX_PERIODE     --
-- 29/11/2022 GOMESHU  : v8.35 + Mantis 64347 = v8.36                         --
-- 08/09/2022 ALMEIDBR : v8.35 + M63356 - CRD en date de resil (Report. NME)  --
-- 19/07/2022 CUNHAVI : Mantis 62593 - Ajout des donnees LTBCE dans extractio --
--                      BTR_TIERS et RS_FAMILLE_IMMEUBLE. Ajout extraction de --
--                      BTR_OPE_PARTENAIRE POOL et RS_CORRES_METHODE_NOTATION --
-- 06/05/2022 CUNHAVI  : v8.34 + Mantis 62156 = v8.35                         --
-- 10/03/2022 GOMESHU  : v8.34 Mantis 61386                                   --
-- 24/12/2021 ALMEIDBR : merge v8.29 + M59791                                 --
-- 13/12/2021 ALMEIDBR : v8.30 + US 269 (CRRv4.3)                             --
-- 30/09/2021 DUGUETMA : merge v8.26 8.28                                     --
-- 28/09/2021 DUGUETMA : 8.28 + reactivation 48431 pour S40                   --
-- 23/09/2021 DUGUETMA : v8.19 + 57385 + 58424                                --
-- 04/08/2021 DUGUETMA : US 231 CRRV4.3 a partir de V8.23                     --
-- 28/07/2021 DUGUETMA : reactive M48431                                      --
-- 21/07/2021 DUGUETMA : reactive US 92 CRR                                   --
-- 15/07/2021 DUGUETMA : US91 + US139 CRRV4.3                                 --
-- 23/06/2021 MIPAMES  : Retrait M48431                                       --
-- 22/06/2021 MIPAMES  : Retrait US 92 CRRV4.3                                --
-- 16/06/2021 DUGUETMA : 8.16 + Mantis 57336                                  --
-- 16/06/2021 DUGUETMA : 8.14 + US 197 Donnee AER NAT 02 - TRICP - Annule et  --
--                       remplace US 88                                       --
-- 12/05/2021 MIPAMES  : US 86 & 88 CRRV4.3                                   --
-- 05/05/2021 DUGUETMA : MEPV21S27 US 92 CORRECTION                           --
-- 05/05/2021 DUGUETMA : MEPV21S27 US 89 et 92 CRRV4.3 a partir v8.10         --
-- 20/04/2021 DUGUETMA : Mantis 48431                                         --
-- 22/03/2021 DUGUETMA : MEPV21S17 US44                                       --
-- 02/03/2021 DUGUETMA : MEPV21S17 US 22 23 25 CRRV4.3                        --
-- 02/12/2020 DUGUETMA : US 17                                                --
-- 24/11/2020 DUGUETMA : US 204 - EQU101 - Leasing Process CORFOU mise en qua --
--                       lite CRR CALEF                                       --
-- 23/08/2020 MIPAMES  : Modification M52152                                  --
-- 23/06/2020 MIPAMES  : Inhib Valo CBI depuis v8.0                           --
-- 28/05/2020 MIPAMES  : IFRS Mantis 52152                                    --
-- 14/04/2020 DUGUETMA : M51377 reactive valoCBI                              --
-- 16/01/2020 DUGUETMA : MEPV20S08 RETRAIT US 122 N3D                         --
-- 28/11/2019 DUGUETMA : MEPV20S04 US 88 N3D                                  --
-- 05/11/2019 DUGUETMA : MEPHV19S49 N3D US 122 et 149                         --
-- 23/10/2019 MIPAMES  : M46097 Rework a partir de v7.99                      --
-- 13/09/2019 MAZEROTH : Valo_CBI US53 Archivage HIS_GRILLE_CBRE CRRV3        --
-- 11/09/2019 DUGUETMA : linesize VALO_CBI augmentee                          --
-- 28/08/2019 DUGUETMA : rename TYPE_CALCUL_CBRE_AJUST add DT_VALO_VTR        --
-- 25/07/2019 DUGUETMA : Mantis 9755                                          --
-- 16/07/2019 MIPAMES  : Merge S27_BHL_M48274                                 --
-- 21/06/2019 DUGUETMA : Mantis 48274                                         --
-- 22/05/2019 DUGUETMA : MEPHV19S27 US 774 5 MANTIS 47677                     --
-- 20/05/2019 DUGUETMA : MEPHV19S27 it1                                       --
-- 16/05/2019 DUGUETMA : MEPV19S23                                            --
-- 25/04/2019 MIPAMES  : MEPV19S21 it4                                        --
-- 19/04/2019 MIPAMES  : MEPV19S21 it3                                        --
-- 12/04/2019 MIPAMES  : MEPV19S21 M46918                                     --
-- 08/04/2019 DUGUETMA : MEPHV19S17 V7.81 + MANTIS 47318 US 768               --
-- 20/03/2019 MIPAMES  : MEPHV19S13 Mantis 47094                              --
-- 07/03/2019 DUGUETMA : MEPHV19S13 it2 US 587, 762 et 746                    --
-- 01/03/2019 DUGUETMA : MEPHV19S13 it1                                       --
-- 01/02/2019 DUGUETMA : MEPHV19S09 US570 US609 US610 US620 US621 US651 US652 --
--                       US622 US624 US674                                    --
-- 14/12/2018 MIPAMES  : Merge v7.74 et v7.75                                 --
-- 10/12/2018 MIPAMES  : MEPHV19S02 it2 US 541                                --
-- 29/11/2018 DUGUETMA : Mantis 45281                                         --
-- 28/11/2018 CDS ATOS : Mantis 45281 : Code moteur erron? pour P2 et F2      --
-- 14/11/2018 DUGUETMA : MEPV18S48 US 546                                     --
-- 27/09/2018 DUGUETMA : Mantis 42434                                         --
-- 13/09/2018 DUGUETMA : ANACREDIT US 489                                     --
-- 18/07/2018 DUGUETMA : ANACREDIT V18S39 Iteration 1                         --
-- 07/02/2018 DUGUETMA : spool du code NUTS ANACREDIT US 26                   --
-- 03/01/2018 DUGUETMA : sprint 2 US 27 ANACREDIT                             --
-- 27/09/2017 DUGUETMA : Mantis 38693                                         --
-- 11/07/2017 PELLETNI : merge 38359                                          --
-- 02/05/2017 PELLETNI : taille p8                                            --
-- 02/05/2017 PELLETNI : p2 taille                                            --
-- 02/05/2017 PELLETNI : taille P1                                            --
-- 02/05/2017 PELLETNI : p1                                                   --
-- 27/04/2017 PELLETNI : correctif                                            --
-- 27/04/2017 PELLETNI : ifrs                                                 --
-- 12/04/2017 SUAUDECH : un point virgule qui manque                          --
-- 12/04/2017 SUAUDECH : Totof : je me suis plante                            --
-- 12/04/2017 SUAUDECH : c1 c5 jamais teste                                   --
-- 11/04/2017 SUAUDECH : flag_hn N                                            --
-- 11/04/2017 SUAUDECH : ajout table crrv4 du mois                            --
-- 04/11/2016 LACHASVI : Bale 2 Defaut - Mantis 35095                         --
-- 22/09/2016 PELLETNI : mephv                                                --
-- 13/09/2016 LACHASVI : Projet Bale 2 Defaut et Restructuration              --
-- 23/06/2016 PELLETNI : spool                                                --
-- 07/06/2016 PELLETNI : eng_imp                                              --
-- 06/10/2015 PELLETNI : dexp                                                 --
-- 01/10/2015 BOUCHAMU : adaptation par rapport a au ctl                      --
-- 23/09/2015 PELLETNI : ID_TIE_SYS_EXT                                       --
-- 02/09/2015 BOUCHAMU : crrv4                                                --
-- 28/08/2015 PELLETNI : update                                               --
-- 05/08/2015 PELLETNI : c1                                                   --
-- 21/07/2015 PELLETNI : supp cd_type risque                                  --
-- 07/07/2015 PELLETNI : P9                                                   --
-- 02/07/2015 PELLETNI : pcec                                                 --
-- 02/07/2015 PELLETNI : evolutions p5                                        --
-- 13/06/2015 PELLETNI : linesize rs corres pcec                              --
-- 04/06/2015 FOFANAAD : Modification date sur NAT10                          --
-- 04/06/2015 SUAUDECH : Encore un spol                                       --
-- 04/06/2015 SUAUDECH : spool en place de spool                              --
-- 03/06/2015 SUAUDECH : remise a plat p1                                     --
-- 02/06/2015 SUAUDECH : rs_corres_pcec                                       --
-- 01/06/2015 FOFANAAD : Ajout extraction des donnees lot2                    --
-- 04/05/2015 SUAUDECH : rectifs sur tables start pourries a la 1ere livr.    --
-- 22/04/2015 SUAUDECH : diverses erreurs sur lignes de commandes             --
-- 21/04/2015 SUAUDECH : CRRV4 Leasing REPRISE POUR CRRV4 SUAUDECH            --
--                                                                            --
--------------------------------------------------------------------------------

-- =============================================================================
-- 	spool des fichiers: fichiers plats pour transfert vers HCRR (crrv3,crrv3_2a) 
-- 	fichiers en sortie: $SORTIE/030_FLUX_2M_*.txt
-- =============================================================================
SET serveroutput on size 1000000;
SET sqlprompt ""

SET SHOW OFF
SET VERIFY OFF
SET PAGES 0
SET ECHO OFF
SET HEADING OFF
SET FEED OFF
set trimspool on

--SET linesize 392 -- KLx (GHU) - 03/12/2021 _ 392 + SYS_GEST_SRC 20 = 412 _ US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source' 	
SET linesize 412 
spool $SORTIE/030_FLUX_2M_AUT_CHAPEAU.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS_CALC||'~'||
ID_CENTRAL_TIERS||'~'||
ID_AUTORISATION||'~'||
CD_TYPE_OPE||'~'||
CD_OBJET_CREDIT||'~'||
CD_HIERARCHIE_ACCORD||'~'||
CD_CONFIRMATION_AUTO||'~'||
MNT_GLOBAL_INITIAL||'~'||
MNT_GLOBAL_REVISE||'~'||
CD_DEVISE_AUTO||'~'||
TOP_AUTO_SPECIFIQUE||'~'||
to_char(DT_DEB_VALIDITE_AUTO, 'YYYYMMDD')||'~'||
to_char(DT_LIM_TIRAGE_AUTO, 'YYYYMMDD')||'~'||
to_char(DT_FIN_VALIDITE_AUTO, 'YYYYMMDD')||'~'||
TOP_SYNDICATION||'~'||
CD_POSITION_ENTITE_RISQUE||'~'||
CD_ENTITE_GROUPE_PILOTE||'~'||
TOP_TITRISATION||'~'||
CD_NIV_SENIORITE||'~'||
CD_SEGMENT_CASA||'~'||
MNT_INIT_GLOB_BANQ_TT_TRANCHES||'~'||
MNT_MAJ_GLOB_BANQ_TT_TRANCHES||'~'||
CD_DEVISE_MNT_SYND_TT_TRANCHES||'~'||
MNT_INIT_GLOB_BANQ_TRANCHE_AUT||'~'||
MNT_MAJ_GLOB_BANQ_TRANCHE_AUT||'~'||
CD_DEVISE_MNT_SYND_TRANCHE_AUT||'~'||
TX_PART_RISK_TRANCHE||'~'||
MNT_PART_RISK_TRANCHE||'~'||
A_EXTRAIRE||'~'||
-- 12/11/2018 - CDS ATOS (LFD) - ANACREDIT US 552
REF_SYNDICATION||'~'||
-- FIN LFD
-- 20/12/2018 - CDS ATOS (LFD) - ANACREDIT US 609
IND_POSITION_ENTITE||'~'||
ID_ENGAGEMENT
-- FIN LFD
-- 23/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 652
||'~'||APPLI_SOURCE 
-- FIN LFD
-- 28/04/2021 - CDS ATOS (EMM) - CRRV4.3 US 86
||'~'||IND_CONV_PARTAGE
||'~'||CD_TYPE_PARTICIPATION
-- FIN EMM
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
||'~'||SYS_GEST_SRC --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'||'~'||CD_TYPE_PROD_BANCAIRE
from autorisation_f1;
spool off;

SET linesize 88
spool $SORTIE/030_FLUX_2M_AUT_ECHEANCIER.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
MNT_CRD||'~'||
CD_DEVISE||'~'||
to_char(DT_FIN_TRIM, 'YYYYMMDD')||'~'||
A_EXTRAIRE
from AUT_ECHEANCIER;
spool off;

--05/02/2019 - CDS ATOS (SQN) US 662 - Uniformisation des linesize avec 030_spool_9M_v1.32
--SET linesize 206
--SET linesize 232 -- KLx (GHU) - 03/12/2021 _ 232 + SYS_GEST_SRC 20 = 252 _ US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source' 
SET linesize 252
spool $SORTIE/030_FLUX_2M_AUT_LIGNE_DET.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS_CALC||'~'||
ID_CENTRAL_TIERS||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
CD_TYPE_RISQUE||'~'||
MNT_AUTORISE_ORIGINE||'~'||
MNT_AUTORISE_REVISE||'~'||
MNT_AUTORISE_LIGNE||'~'||
CD_DEVISE_LIGNE_AUTO||'~'||
CD_METHODO_BALE2||'~'||
to_char(DT_DEB_VALIDITE_LIGNE, 'YYYYMMDD')||'~'||
to_char(DT_LIM_TIRAGE_LIGNE, 'YYYYMMDD')||'~'||
to_char(DT_FIN_VALIDITE_LIGNE, 'YYYYMMDD')||'~'||
DUREE_MAX_ENGMT||'~'||
CD_DEV_RESTRIC_LIGNE||'~'||
CD_LIQUIDITE_DEFAUT||'~'||
A_EXTRAIRE||'~'||
--28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur errone pour P2 et F2
CD_MOTEUR||'~'||
--Fin SQN
--08/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 620
APPLI_SOURCE||'~'||
TRAIT_MOTEUR
--Fin LFD
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
||'~'||SYS_GEST_SRC --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
from autorisation_detail_F2;
spool off;

--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3 - + 18x4
--set linesize 158
set linesize 230
-- FIN LFD
spool $SORTIE/030_FLUX_2M_provisions_agreg_p8.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS_CALC||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
ID_ENGAGEMENT||'~'||
CD_NAT_DEPRE||'~'||
CD_PERIM_PROV||'~'||
MNT_PROVISION ||'~'||
MNT_PROVISION_TRIM||'~'||
CD_DEVISE||'~'||
CD_PCCO||'~'||
A_EXTRAIRE
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
||'~'||MTPROVBIL
||'~'||MTPROVHB
||'~'||MTPROVTRIMBIL
||'~'||MTPROVTRIMHB
-- FIN LFD
from provisions_agreg_p8;
spool off;  

--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3 - + 18x4
--set linesize 164
set linesize 236
-- FIN LFD
spool $SORTIE/030_FLUX_2M_provisions_detail_p8.txt
select 
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS||'~'||
ID_TIERS_CALC||'~'||
ID_CENTRAL_TIERS||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
ID_ENGAGEMENT||'~'||
CD_NAT_DEPRE||'~'||
CD_PERIM_PROV||'~'||
MNT_PROVISION ||'~'||
MNT_PROVISION_TRIM||'~'||
CD_DEVISE||'~'||
CD_PCCO||'~'||
A_EXTRAIRE
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
||'~'||MTPROVBIL
||'~'||MTPROVHB
||'~'||MTPROVTRIMBIL
||'~'||MTPROVTRIMHB
-- FIN LFD
from provisions_detail_p8;
Spool off;

--19/02/2019 - CDS ATOS (SQN) - US 730
--SET linesize 2154 + 55
-- +1 04/02/2021 - CDS ATOS (LFD) - US 23 CRRV4.3
--SET linesize 2210
-- US 262 - KLx Risque (VDC) - 03/12/2021 - CRRV4.3 - Ajout du champ IND_GAR_SANS_LIMITEeformat VARCHAR2 de longueur 1 byte , donc +1
--SET linesize 2234+455
--DEBUT: projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
---- linesize actuel      : 2689 
---- taille nouveau champ : 20 
---- taille caracter '~'  : 1 
---- total avec modif.    : 2689 + 20 + 1 = 2710
--FIN: projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
SET linesize 2710
spool $SORTIE/030_FLUX_2M_ENG_ENCOURS_CORPORATE.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS_CALC||'~'||
ID_CENTRAL_TIERS||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
ID_ENGAGEMENT||'~'||
CD_METHODO_BALE2||'~'||
CODE_TRAIT_MOTEUR||'~'||
CODE_TRAIT_GRR||'~'||
CD_TYPE_RISQUE||'~'||
CD_PORTEFEUILLE_BOOKING||'~'||
CD_LIGNE_METIER||'~'||
CD_PORTEFEUILLE_BALE2||'~'||
CD_NATURE_OPE||'~'||
to_char(DT_DEBUT_ENG, 'YYYYMMDD')||'~'||
to_char(DT_FIN_ENG, 'YYYYMMDD')||'~'||
MNT_RISQUE||'~'||
CD_DEVISE_MNT_RISQ||'~'||
PCEC_MNT_RISQUE||'~'||
CD_STATUT_OPE_DT_SOLDE||'~'||
MNT_ICNE ||'~'||
PCEC_ICNE||'~'||
CD_DEVISE_ICNE||'~'||
MNT_VR||'~'||
CD_DEVISE_VR||'~'||
TOP_ENG_DOUTEUX||'~'||
to_char(DT_ENG_DOUTEUX, 'YYYYMMDD')||'~'||
TOP_ACCORD_FUSION||'~'||
MNT_EXPOSITION||'~'||
CD_DEVISE_EXPO||'~'||
CD_CPT_ACTIF_IAS||'~'||
MNT_CPT_ACTIF_PCIAS||'~'||
TOP_RESTRUCTURATION||'~'||
to_char(DT_RESTRUCTURATION, 'YYYYMMDD')||'~'||
TX_LGD_PREDICTIF||'~'||
TX_LGD_PREDICTIF_LOCAL||'~'||
MNT_EXPO_POTENT||'~'||
to_char(DT_ACQ_DERN_PART_OPC, 'YYYYMMDD')||'~'||
TX_CONV_HB||'~'||
MNT_EAD_TOT||'~'||
DEVISE_EAD||'~'||
TOP_ENG||'~'||
MATURITE_EFF||'~'||
MNT_LOY_RD||'~'||
MNT_VTR_PDR||'~'||
MNT_HYPOTHEQUE||'~'||
MNT_SOLD_K_A||'~'||
MNT_FIN_PERIODE||'~'||
PCCO_MNT_LRD ||'~'||
CD_DEV_VTR ||'~'||
CD_DEV_HYPOTH||'~'||
CD_ACHAT_FIN_LOC||'~'||
CD_USAGE_BIEN_IMM||'~'||
CD_RESPECT_COND||'~'||
CD_LOC_BIEN||'~'||
CD_ARR_PAIEMENT||'~'||
CD_IMP_PRUDENT||'~'||
CD_CIRCUIT_DISTRIB||'~'||
TX_TRC||'~'||
MNT_INT_RD||'~'||
PCCO_ACQUISITION||'~'||
MNT_ACQUISITION||'~'||
CD_DEVISE_ACQUISITION||'~'||
MNT_MTM||'~'||
CD_DEVISE_MTM||'~'||
PCCO_MTM ||'~'||
CD_DEVISE_NOMINAL||'~'||
PCCO_NOMINAL||'~'||
PCCO_MNT_RISQUE||'~'||
MNT_EXPO_POTENT_HT||'~'||
CD_DEVISE_ORIGINE||'~'||
PCCO_INT_RD ||'~'||
CD_DEVISE_INT_RD||'~'||
CD_DEVISE_CRD||'~'||
MNT_CRD||'~'||
PCCO_CRD||'~'||
PCCO_MNT_CRD||'~'||
MNT_NOMINAL||'~'||
PCCO_MNT_NOMINAL||'~'||
SENS_TRANSACTION||'~'||
MODELE_ASSIETE_RISQUE||'~'||
IND_ACCORD_COLLATERISATION||'~'||
REF_ACCORD_COLLATERISATION||'~'||
IND_ACCORD_NETTING||'~'||
REF_CONTRAT_NETTING||'~'||
DEV_CONTRAT_NETTING||'~'||
MT_ASSIETE_INTERNE||'~'||
DEV_ASSIETE_INTERNE||'~'||
MT_ASSIETE_REGLEMENTAIRE||'~'||
DEV_ASSIETE_REGLEMENTAIRE||'~'||
INSTRUMENT_FINANCIER||'~'||
IND_CCP||'~'||
CODE_INDICE_BOURSE||'~'||
CODE_PAYS_BOURSE||'~'||
MT_CVA_COMPTA||'~'||
DEV_CVA_COMPTA||'~'||
IND_RISQ_COLLAT_SPECIF||'~'||
IND_DENOUEMENT_CDS||'~'||
IND_ELLIGIBILITE_CVA||'~'||
MT_SPREAD||'~'||
MT_NOTIONNEL_ACH||'~'||
DEV_NOTIONNEL_ACH||'~'||
MT_NOTIONNEL_VENDU||'~'||
DEV_NOTIONNEL_VENDU||'~'||
TYPE_CREDIT_DERIVE||'~'||
TYPE_SWAP||'~'||
NATURE_OPTION||'~'||
IND_CALL_PUT ||'~'||
TYPE_TAUX_PAYE||'~'||
REF_TAUX_PAYE||'~'||
TYPE_TAUX_RECU||'~'||
REF_TAUX_RECU||'~'||
MT_QUANTITE_RECUE||'~'||
UNITE_QUANTITE_RECUE ||'~'||
MT_QUANTITE_LIVREE||'~'||
UNITE_QUANTITE_LIVREE||'~'||
IND_PROD_SS_JACENT||'~'||
CD_DEVISE_SOLDE||'~'||
MNT_SOLDE||'~'||
PCCO_MNT_SOLDE||'~'||
CD_DEVISE_DECOUVERT||'~'||
MNT_DECOUVERT||'~'||
NATURE_PROD_SS_JACENT||'~'||
FLAG_HN||'~'||
A_EXTRAIRE||'~'||
MNT_VTR||'~'||
IND_PROD_ECH||'~'|| 
   REF_UNIQ_CONT||'~'|| 
   IND_ECH_FOUR||'~'|| 
   ELI_OUT_MUT_PROV||'~'|| 
   CENTRE_RES||'~'|| 
   CLA_COMP_ACT_IFRS9||'~'|| 
   CLA_COMP_ACT_NATIONALE||'~'|| 
   IND_ACT_DEP_ORI||'~'|| 
   ZONE_APP_COMP||'~'|| 
   IND_OBJ_MET_PAL||'~'|| 
   REF_UNIQ_ELEM_CONT||'~'|| 
   NOTE_FIN_RET_ORI||'~'|| 
   NOTE_EXT_ORI ||'~'|| 
   ORG_NOT_ORI||'~'|| 
   SEG_NOT_ORI||'~'|| 
   GRI_MOD_NOT_ORI||'~'|| 
   METH_NOT_ORI||'~'|| 
   SYS_GEST_SRC||'~'|| 
   TAUX_INT_EFF_ORI||'~'|| 
   TYPE_TAUX||'~'|| 
   IND_REF||'~'|| 
   TYPE_AMOR_CAP||'~'|| 
   PRD_AMOR_CAP||'~'|| 
   PRD_PMT_INT||'~'|| 
   TAUX_CLT_OCT||'~'|| 
   MOD_REMB_CRE||'~'|| 
   DATE_PREM_ECH||'~'|| 
   DATE_FIN_DIFF_AMOR||'~'|| 
   TAUX_PLAFOND||'~'|| 
   TAUX_PLANCHER||'~'|| 
   PRD_REV_TAUX_UNIT_TMP||'~'|| 
   PRD_REV_TAUX_NBR||'~'|| 
   TAUX_MRG_ADD||'~'|| 
   TAUX_MRG_MULT||'~'|| 
   BASE_CAL_INT||'~'|| 
   CAP_THEO_REST||'~'|| 
   DEVI_CAP_THEO_REST||'~'|| 
   DATE_DEB_PALL||'~'|| 
   DATE_FIN_PALL||'~'|| 
   MNT_ECH_EN_COURS||'~'|| 
   DEVI_MNT_ECH_EN_COURS||'~'|| 
   IND_PRE_POST_FIX||'~'|| 
   DATE_DEB_ENG_RENVL||'~'|| 
   CLA_COMP_REF_ACT||'~'|| 
   EVENMT_CRDT||'~'|| 
   NAT_CONT_EVENMT_CRDT||'~'|| 
   STA_CRDT||'~'|| 
   IND_CRE_PERF||'~'|| 
   DATE_DER_REST_COMM||'~'|| 
   DATE_DER_REST_RSQ||'~'|| 
    DATE_PREM_DEB_FOND||'~'||
-- 15/05/2018 CDS Atos (JMP) ANACREDIT US24 remplace    DATE_PREM_DEB_FOND||'~'||
-- 07/12/17 CDS ATOS (EMM) Sprint 1 US 27
	DATE_PREM_ACT_FORB||'~'||
	DATE_SORT_EFF_FORB||'~'||
	-- Fin EMM
	--03/04/2018 CDS ATOS (EMM) Sprint 7 US 218
	DATE_ENTR_PER_PURG||'~'||
	DATE_SORT_PER_PURG||'~'||
	DATE_ENTR_PER_PROB||'~'||
	DATE_SORT_PER_PROB||'~'||
	DATE_THEO_FIN_FORB||'~'||
	-- Fin EMM
   --22/12/17 CDS ATOS (FAD) Sprint 2 US 23
	MNT_CONTRAT_ORIGINE||'~'||
	DEV_MNT_CONTRAT_ORIGINE||'~'||
	DT_PASSAGE_DOUTEUX_COMPROMIS||'~'||
	-- Fin FAD
	CD_Meth_IFRS9_PD||'~'|| 
	CD_Meth_IFRS9_LGD||'~'||
	CD_Meth_IFRS9_CCF||'~'|| 
	CD_Meth_IFRS9_Tx ||'~'||
	-- 14/04/2018 CDS ATOS (JMP) Sprint 7 US33 Ajout du code motif SCO
	CD_MOTIF_SCO_LC0267 ||'~'||
	-- 11/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Donnees premier deblocage de fonds
	MNT_PREM_DBLQ_FONDS||'~'||
	to_char(DT_PREM_DBLQ_FONDS, 'YYYYMMDD')	||'~'||
	DEVISE_PREM_DBLQ_FONDS
	-- Fin 11/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Donnees premier deblocage de fonds
	--11/01/2019 - CDS AtoS FAD - CRRV4.2 US624
||'~'||MNT_COUT_AMORTI
||'~'||CD_DEV_COUT_AMORTI
||'~'||CD_DEV_MNT_MTM
||'~'||TO_CHAR(DT_PL_NPL, 'YYYYMMDD')
||'~'||CD_MOTIF_PL_NPL
--||'~'||CD_MOTIF_DTX -- 30/01/2019 - RW US624 - colonne superflue
||'~'||BUCKET_IFRS9
||'~'||MNT_COUPONS_NON_ECHUS
||'~'||CD_DEV_COUPONS_NON_ECHUS
||'~'||TO_CHAR(DT_DISPO_FONDS, 'YYYYMMDD')
||'~'||TX_ELBE
||'~'||CD_PAYS_JURIDICTION
||'~'||TO_CHAR(DT_SIGNATURE, 'YYYYMMDD')
||'~'||EVT_DECL_GAR
||'~'||NB_JOURS_RETARD
||'~'||IND_OPE_EFFET_LEVIER
||'~'||IND_SPONSOR_FIN
||'~'||MNT_IDEMNITE_RES
||'~'||CD_DEV_MNT_INDEMNITE
||'~'||TYPE_CTT_CADDRE
||'~'||IND_PROTOCOLE_ISDA_ENTITE
||'~'||IND_PROTOCOLE_ISDA_CPTY
||'~'||MNT_CCNE_JB_VENDUE
||'~'||CD_DEV_MNT_CCNE_JB_VENDUE
||'~'||MNT_CCNE_JB_ACHETEE
||'~'||CD_DEV_MNT_CCNE_JB_ACHETEE
||'~'||PRD_PAY_TX_RECU
||'~'||MRG_TX_RECU
||'~'||CD_BASE_CALCUL_INT_RECU
||'~'||PRD_PAY_TX_PAYE
||'~'||MRG_TX_PAYE
||'~'||CD_BASE_CALCUL_INT_PAYE
||'~'||MNT_CCNE_JB_PRETEUSE
||'~'||CD_DEV_MNT_CCNE_JB_PRETEUSE
||'~'||MNT_CCNE_JB_EMPRUNT
||'~'||CD_DEV_MNT_CCNE_JB_EMPRUNT
||'~'||CD_CAP
||'~'||ELI_OUT_MUT_PROV_S
||'~'||CLA_COMP_ACT_IFRS9_S
||'~'||CLA_COMP_ACT_NATIONALE_S
||'~'||CLA_COMP_REF_ACT_S
||'~'||DEV_MONTANT_DEB
||'~'||OBJ_FINANCIE
||'~'||TO_CHAR(DT_EXIGTE_PREM_IMPY, 'YYYYMMDD')
||'~'||TAUX_CLT_PRD_EN_CRS
||'~'||MNT_LTV
--Fin - CDS AtoS FAD - CRRV4.2 US624
--19/02/2019 - CDS ATOS (SQN) - US 730
||'~'||APPLI_SOURCE
||'~'||CD_DEVISE_MNT_DECOUVERT
||'~'||MNT_LOYER
--||'~'||TOP_PRD_SS_JACENT
||'~'||IND_CREANCE_TITRI
||'~'||ORGA_NOTATION_ORIG
||'~'||IND_RMB_ANTICIPE
||'~'||ELIGIB_PRUDENT_VAL
||'~'||IND_MOBIL_ACTIF
--Fin SQN
-- 10/11/2020 - CDS ATOS (CPD) - US 204
||'~'||HIERARCHIE_JUSTE_VALEUR
||'~'||COMPLEXITE_PRODUIT 
||'~'||IND_ACTIF_COTE 
||'~'||NB_TITRES 
||'~'||IND_BCK_TO_BCK 
||'~'||REF_OPE_BCK_TO_BCK
||'~'||INTENTION_COUVERTURE
||'~'||TYPE_REL_COUVERTURE
-- fin CPD
--30/11/2020 - CDS ATOS (CPD) - US 17
||'~'||MNT_SUBV_HT
||'~'||MNT_AVP_HT 
-- fin CPD
||'~'||FINALITE_OPERATION -- 04/02/2021 - CDS ATOS (LFD) - US 23 CRRV4.3
-- 08/02/2021 - CDS ATOS (CPD) -- US 22
||'~'||ELIG_MOB_BANQUE_CENTRALE
||'~'||REF_MOB_ACTIF
-- fin CPD
-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
||'~'||IND_ELIGI_OUTI_CTRAL_ANACRD
||'~'||MOTIF_EXCLU_ANACREDIT
||'~'||MNT_ENG_DT_SIGN_CTRT
||'~'||IND_RESPO_SOLIDAIRE
-- FIN LFD  
--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - Donnee AER NAT 02 - TRICP - Annnule et remplace US88
||'~'||CD_ORGA_MOBIL
-- 27/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
--||'~'||IND_ELIGB_ACTIF_IMM_BC 
-- fin CPD 
--FIN MNE
--CDS_ATOS (MNE) - 12/07/2021 - US91 - Donnees OMP dans le cadre du projet CRRV4.3 et C3RD 2.0
||'~'||CD_COMMUNE_BIEN_FINAN 
||'~'||CD_PAYS_BIEN_FINAN 
--FIN MNE
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
||'~'||IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
||'~'||IND_GAR_SANS_LIMITE -- US 262 - KLx Risque (VDC) - 03/12/2021 - CRRV4.3 - Ajout du champ IND_GAR_SANS_LIMITEe 
||'~'||MOTIF_MRTR
||'~'||TO_CHAR(DT_DEBUT_MRTR,'YYYYMMDD')
||'~'||DUREE_MRTR
||'~'||STATUT_MRTR
||'~'||IND_MRTR_LEGISLATIF
||'~'||IND_MRTR_CONTRACTUEL
||'~'||CHAMP_APPL_MRTR
||'~'||MNT_MRTR
||'~'||DEV_MRTR
||'~'||IND_EXPO_QUAL_ELEVEE
||'~'||IND_PHASE_OPE_PROJ_FIN
||'~'||IND_CONF_CRIT_OPE
||'~'||IND_IPRE
||'~'||IND_EXPO_ADC
||'~'||IND_REAL_COND_PONDERATION_PREFE
||'~'||LTV_RATIO
||'~'||ETV_RATIO
||'~'||IND_INVEST_CAPITAL_RISQ
||'~'||IND_INVEST_PROG_LEGISLATIF
||'~'||IND_PARTICIP_STRATG_SUP_6A
||'~'||TX_HIST_POND_PARTICIPATION
||'~'||IND_UCC
||'~'||NIV_RISQUE_CRR3
||'~'||CD_NAT_OPE_ENG_CALC_FLOOR
||'~'||USAGE_BIEN_FINANCE
||'~'||COMMUNE
||'~'||NUM_VOIE
||'~'||EXTENSION
||'~'||TYPE_VOIE
||'~'||LIB_VOIE
||'~'||LIEU_DIT
||'~'||LATITUDE
||'~'||LONGITUDE
||'~'||IND_HQLA
||'~'||IND_TITRE_PARTICIP
||'~'||CLASS_CPT_ELEMENT_COUV_DERIVE
||'~'||CD_TYPE_BIEN_COMM
||'~'||CD_EMPLACE_BIEN_COMM
||'~'||IND_OPE_AVEC_RECOURS
||'~'||TX_DSCR
||'~'||TX_DSCR_PREC
||'~'||CD_METH_IFRS9_PD_ORIG --projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
from ENG_CORP_P1;
spool off;

--20/04/2021 - CDS ATOS (LFD) - Mantis 48431
--SET linesize 1475
-- 16/12/2021 - KLx Risque (VDC) - US 261 Addition des champs eeMNT_FOND_REMIS_DATEee (18+1) et e DEV_FOND_REMIS_DATE e (3)
--SET linesize 1494
--SET linesize 1515+377
--DEBUT: projet OMP - sous-tache SIRL-279 :: ajout du champ P2 6.99
---- linesize actuel      : 1892 
---- taille nouveau champ : 20 
---- taille caracter '~'  : 1 
---- total avec modif.    : 1892 + 20 + 1 = 1913
--FIN: projet OMP - sous-tache SIRL-279 :: ajout du champ P2 6.99
SET linesize 1913
spool $SORTIE/030_FLUX_2M_ENG_ENCOURS_CORP_PNU.txt
select
to_char(DT_ARRETE,'YYYYMMDD')||'~'||      
CD_CONSO_CPT||'~'||                                                     
ID_TIERS_CALC||'~'||                                                    
ID_CENTRAL_TIERS||'~'||                                                 
ID_AUTORISATION||'~'||                                                  
ID_LIGNE_DET||'~'||                                                     
ID_ENGAGEMENT||'~'||                                                    
CD_METHODO_BALE2||'~'||                                                 
CD_TYPE_RISQUE||'~'||                                                   
CD_PORTEFEUILLE_BALE2||'~'||                                            
CD_NATURE_OPE||'~'||                                                    
to_char(DT_DEBUT_ENG,'YYYYMMDD')||'~'||                                 
to_char(DT_FIN_ENG,'YYYYMMDD')||'~'||                                   
CD_PORTEFEUILLE_BOOKING||'~'||                                          
CD_LIGNE_METIER||'~'||                                                  
TX_POND_BAL||'~'||                                                      
TX_LGD_PREDICTIF||'~'||                                                 
TX_CCF||'~'||                                                           
TX_EAD||'~'||                                                           
CD_DEVISE_EAD||'~'||                                                    
CD_DEVISE||'~'||                                                        
TOP_RESTRUCTURATION||'~'||                                              
to_char(DT_RESTRUCTURATION,'YYYYMMDD')||'~'||                           
CD_IMP_PRUDENT||'~'||                                                   
CD_ENG_DTX||'~'||                                                       
to_char(DT_EGT_DTX,'YYYYMMDD')||'~'||                                   
MNT_PNU||'~'||                                                          
CD_DEVISE_PNU||'~'||                                                    
CD_CIRCUIT_DISTRIB||'~'||                                               
PCCO_MNT_PNU||'~'||                                                     
MNT_VTR_PDR||'~'||                                                      
MATURITE_EFF||'~'||                                                     
TOP_ENG||'~'||                                                          
CD_USAGE_BIEN_IMM||'~'||                                                
  A_EXTRAIRE||'~'|| 
   CLASS_CPT_REF_ACT||'~'|| 
   EVT_CREDIT||'~'|| 
   NAT_EVN_CREDIT||'~'|| 
   STATU_CREDIT||'~'|| 
   IND_CREANCE_PER||'~'||
	--23/04/2018 CDS ATOS (EMM) Sprint 8 US 273 et 274
   DATE_PREM_ACT_FORB||'~'||
	DATE_ENTR_PER_PURG||'~'||
	DATE_SORT_PER_PURG||'~'||
	DATE_ENTR_PER_PROB||'~'||
	DATE_SORT_PER_PROB||'~'||
	DATE_THEO_FIN_FORB||'~'||
	DATE_SORT_EFF_FORB||'~'||
   --Fin EMM
   DAT_DER_REST_COM||'~'|| 
   DAT_DER_REST_RIS||'~'|| 
   IND_PRD_NON_ECH||'~'|| 
   IND_OBJ_MET_PAL_DAT_FOURNI||'~'|| 
   REF_UNI_CONTRAT||'~'|| 
   REF_UNI_ELEM_CONTRAT||'~'|| 
   NOT_FIN_RET_ORG||'~'|| 
   NOT_EXT_ORG||'~'|| 
   ORG_NOTATION_ORG||'~'|| 
   SEG_NOTATION_ORG||'~'|| 
   GRI_NOT_ORG||'~'|| 
   METH_NOTATION_ORG||'~'|| 
   IND_ECH_FOURNI||'~'|| 
   TAUX_INT_EF_ORG||'~'|| 
   TYP_TAUX||'~'|| 
   IND_REF||'~'|| 
   TYP_AMOR_CAP||'~'|| 
   PER_AMOR_CAP||'~'|| 
   PER_PAI_INTERET||'~'|| 
   TAUX_CLI_OCTROI||'~'|| 
   MOD_REMB_CREANCE||'~'|| 
   DATE_PRM_ECHEANCE||'~'|| 
   DATE_FIN_DIF_AMOR||'~'|| 
   TAUX_PLAF||'~'|| 
   TAUX_PLAN||'~'|| 
   PER_REV_TAUX_UNITE_TMP||'~'|| 
   PER_REV_TAUX_NBR||'~'|| 
   TAUX_MARG_ADDTIV||'~'|| 
   TAUX_MARG_MULTP||'~'|| 
   BASE_CALCUL_INTERET||'~'|| 
   DATE_PRE_DEB_FOND||'~'|| 
   CAP_THEO_REST_DU||'~'|| 
   DEV_CAP_THEO_REST_DU||'~'|| 
   DATE_DEB_PALL||'~'|| 
   DATE_FIN_PALL||'~'|| 
   MNT_ECHEANCE_EN_COURS||'~'|| 
   DEV_MNT_ECHEANCE_EN_COURS||'~'|| 
   IND_PRE_POST_FIX||'~'|| 
   DATE_DEB_ENG_RENOUV||'~'|| 
   ELIG_OUTIL_MUT_PROV||'~'|| 
   CENT_RESULT||'~'|| 
   SYS_GEST_SOURCE||'~'|| 
   CLASS_CPT_ACT_NOR_IFRS9||'~'|| 
   CLASS_CPT_ACT_NOR_NAT||'~'|| 
   IND_ACT_DEP_ORG||'~'|| 
   ZONE_APP_COMPTA||'~'||
-- 11/04/2018 CDS ATOS (JMP) ANACREDIT US33 Sprint 7 Motif passage en douteux
CD_MOTIF_SCO_LC0267||'~'||
-- 25/04/2018 CDS ATOS (JMP) Ajout des champs IFRS pour  assurer la coh?rence avec le fichier de controle sur la base historique
CD_Meth_IFRS9_PD||'~'||
CD_Meth_IFRS9_LGD||'~'||
CD_Meth_IFRS9_CCF||'~'||
CD_Meth_IFRS9_Tx||'~'||
-- 04/06/2018 CDS ATOS (PSR) ANACREDIT US292
MNT_CONTRAT_ORIGINE||'~'||
DEV_MNT_CONTRAT_ORIGINE||'~'||
-- Fin US292
--09/11/18 CDS Atos (EMM) US 546
IND_NIV_RISQUE||'~'||
--Fin EMM
--28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur errone pour P2 et F2
CD_MOTEUR
--Fin SQN
--10/01/2019 - CDS ATOS (SQN) - ANACREDIT US622
||'~'||TX_EL
||'~'||TO_CHAR(DT_PL_NPL, 'YYYYMMDD')
||'~'||CD_MOTIF_PL_NPL
||'~'||CD_PAYS_JURIDICTION
||'~'||TO_CHAR(DT_SIGNATURE, 'YYYYMMDD')
||'~'||EVT_DECL_GAR
-- Suite ? l'US670 ne plus cr?er CD_MOTIF_DTX (SQN)
--||'~'||CD_MOTIF_DTX
||'~'||BUCKET_IFRS9
||'~'||IND_OPE_EFFET_LEVIER
||'~'||IND_SPONSOR_FIN
||'~'||MNT_IDEMNITE_RES
||'~'||CD_DEV_MNT_INDEMNITE
--Fin SQN  
-- 08/02/2019 - CDS ATOS (GBD)- US677   Deb -->
||'~'||APPLI_SOURCE        
||'~'||FREQUENCE           
||'~'||CODE_TRAIT_GRR      
||'~'||MNT_EAD             
||'~'||IND_ACCORD_FUSION   
||'~'||TOP_PRODUIT         
||'~'||RESPECT_COND_REG    
||'~'||ORGA_NOTATION_ORIG  
||'~'||IND_MOBIL_ACTIF    
-- 08/02/2019 - CDS ATOS (GBD)- US677   Fin  <--     
-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
||'~'||IND_ELIGI_OUTI_CTRAL_ANACRD
||'~'||MOTIF_EXCLU_ANACREDIT
||'~'||MNT_ENG_DT_SIGN_CTRT
||'~'||IND_RESPO_SOLIDAIRE
-- FIN LFD  
--20/04/2021 - CDS ATOS (LFD) - Mantis 48431
||'~'||MNT_IEC
--FIN LFD
--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - Donnee AER NAT 02 - TRICP - Annnule et remplace US88
||'~'||ELIG_MOB_BANQUE_CENTRALE
||'~'||REF_MOB_ACTIF
||'~'||CD_ORGA_MOBIL
-- 27/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
--||'~'||IND_ELIGB_ACTIF_IMM_BC 
-- fin CPD
--FIN MNE
--CDS_ATOS (MNE) - 12/07/2021 - US91 - Donnees OMP dans le cadre du projet CRRV4.3 et C3RD 2.0
||'~'||CD_COMMUNE_BIEN_FINAN 
||'~'||CD_PAYS_BIEN_FINAN 
--FIN MNE
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
||'~'||IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
||'~'||MNT_FOND_REMIS_DATE --US 261 CRRV4.3 - Ajout du  champ eeMNT_FOND_REMIS_DATEee au format NUMBER(18,2) signe - KLx Risque (VDC) 25/11/2021
||'~'||DEV_FOND_REMIS_DATE --US 261 CRRV4.3 - Ajout du  champ e DEV_FOND_REMIS_DATE e au format VARCHAR(3) - KLx Risque (VDC) 26/11/2021
||'~'||IND_UCC
||'~'||IND_EXPO_QUAL_ELEVEE
||'~'||IND_PHASE_OPE_PROJ_FIN
||'~'||IND_CONF_CRIT_OPE
||'~'||NIV_RISQUE_CRR3
||'~'||CD_NAT_OPE_ENG_CALC_FLOOR
||'~'||IND_IPRE
||'~'||IND_EXPO_ADC
||'~'||LTV_RATIO
||'~'||ETV_RATIO
||'~'||USAGE_BIEN_FINANCE
||'~'||IND_OPE_AVEC_RECOURS
||'~'||IND_INVEST_CAPITAL_RISQ
||'~'||IND_INVEST_PROG_LEGISLATIF
||'~'||IND_REAL_COND_PONDERATION_PREFE
||'~'||COMMUNE
||'~'||NUM_VOIE
||'~'||EXTENSION
||'~'||TYPE_VOIE
||'~'||LIB_VOIE
||'~'||LIEU_DIT
||'~'||LATITUDE
||'~'||LONGITUDE
||'~'||CD_TYPE_BIEN_COMM
||'~'||CD_EMPLACE_BIEN_COMM
||'~'||TX_DSCR
||'~'||TX_DSCR_PREC
||'~'||CD_METH_IFRS9_PD_ORIG --projet OMP - sous-tache SIRL-279 :: ajout du champ P2 6.99
FROM eng_corp_p2;
Spool off;

SET linesize 561
spool $SORTIE/030_FLUX_2M_ENG_ENCOURS_RETAIL_AGREG.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||                                                     
ID_TIERS_CALC||'~'||                                                    
ID_ENGAGEMENT||'~'||                                                    
CD_METHODO_BALE2||'~'||                                                 
CD_TRT_MOTEUR||'~'||                                                    
CD_NATURE_OPE||'~'||                                                    
CD_NATURE_PNU||'~'||                                                    
CD_TYPE_RISQUE ||'~'||                                                  
CD_PORTEFEUILLE_BALE2||'~'||                                            
CD_LIGNE_METIER||'~'||                                                  
CD_OBJET_FIN||'~'||                                                     
CD_TYPE_TAUX||'~'||                                                     
CD_USAGE_BIEN_IMM||'~'||                                                
CD_RESPECT_COND||'~'||                                                  
MNT_LOY_RD||'~'||                                                       
CD_DEVISE_LOY_RD||'~'||                                                 
MNT_AUTORISATION||'~'||                                                 
CD_DEVISE_AUT||'~'||                                                    
MNT_VTR||'~'||                                                          
CD_DEVISE_VTR||'~'||                                                    
MNT_HYPOTHEQUE||'~'||                                                   
CD_DEVISE_HYPO||'~'||                                                   
CD_ACHAT_FIN_LOC||'~'||                                                 
MNT_VR||'~'||                                                           
CD_DEVISE_VR||'~'||                                                     
MATURITE_CALC||'~'||                                                    
TOP_ENG_DOUTEUX||'~'||                                                  
CD_IMP_PRUDENT||'~'||                                                   
MNT_ENC_ARR_PAIE||'~'||                                                 
CD_DEVISE_ARR||'~'||                                                    
MNT_DTCO ||'~'||                                                        
CD_DEVISE_DTCO||'~'||                                                   
CD_NIVEAU_PROVISION||'~'||                                              
CD_COUV_PROVISION||'~'||                                                
CD_PLAF_SURETE||'~'||                                                   
CD_RESTRUCTUR||'~'||                                                    
CD_NEW_DEFAUT||'~'||                                                    
CD_CREANCE_TITRI||'~'||                                                 
NB_TIERS||'~'||                                                         
A_EXTRAIRE ||'~'||       
MNT_LOY_RD_CRD||'~'||
MNT_LOY_RD_SOLD||'~'||
MNT_PNU||'~'||
--25/09/2018 CDS ATOS (KKI) Mantis 42434
IND_NIV_RISQ    
--29/01/2019 CDS ATOS (SQN) US 674
||'~'||BUCKET_IFRS9
||'~'||MNT_MTM
||'~'||CD_DEV_MNT_MTM
--Fin SQN       
-- 11/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
||'~'||MNT_LOY_AVEC_ARR 
||'~'||DEV_LOY_AVEC_ARR 
||'~'||MNT_LOY_HORS_ARR 
||'~'||DEV_LOY_HORS_ARR 
||'~'||MNT_INT_AVEC_ARR
||'~'||DEV_INT_AVEC_ARR
||'~'||MNT_INT_HORS_ARR
||'~'||DEV_INT_HORS_ARR 
-- fin CPD 
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE      
-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
||'~'||MNT_CAPITAL_HORS_ARR
||'~'||DEV_CAPITAL_HORS_ARR
-- FIN LFD                                        
from eng_retail_agreg_p5;                                               
spool off;                                                              
                                                                        
SET linesize 525 --461
spool $SORTIE/030_FLUX_2M_ENG_ENCOURS_RETAIL_DET.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||                                             
ID_TIERS||'~'||                                                 
ID_TIERS_CALC||'~'||                                            
ID_CENTRAL_TIERS||'~'||                                         
ID_ENGAGEMENT||'~'||                                            
CD_METHODO_BALE2||'~'||                                         
CD_TRT_MOTEUR||'~'||                                            
CD_NATURE_OPE||'~'||                                            
CD_NATURE_PNU||'~'||                                            
CD_TYPE_RISQUE||'~'||                                           
CD_PORTEFEUILLE_BALE2||'~'||                                    
CD_LIGNE_METIER||'~'||                                          
CD_OBJET_FIN ||'~'||                                            
CD_TYPE_TAUX||'~'||                                             
CD_USAGE_BIEN_IMM||'~'||                                        
CD_RESPECT_COND||'~'||                                          
MNT_ENCOURS||'~'||                                              
MNT_AUTORISATION||'~'||                                         
MNT_CONTRAT||'~'||                                              
CD_DEVISE_CONTRAT||'~'||                                        
CD_STATUT_OPE_DT_SOLDE||'~'||                                   
CD_DEVISE_ENCOURS||'~'||                                        
CD_STATUT_TIERS||'~'||                                          
MNT_LOY_RD_CRD||'~'||                                           
MNT_LOY_RD_SOLD||'~'||                                          
MNT_VTR||'~'||                                                  
MNT_VR||'~'||                                                   
CD_DEVISE_VR||'~'||                                             
CD_ACHAT_FIN_LOC||'~'||                                         
CD_DEVISE_VTR||'~'||                                            
MATURITE_CALC||'~'||                                            
CD_PCEC_CRD||'~'||                                              
CD_PCEC_SOLD_K_A||'~'||                                         
CD_PCEC_SOLD_I||'~'||                                           
MNT_ENC_ARR_PAIE||'~'||                                         
TOP_ENG_DOUTEUX||'~'||                                          
CD_IMP_PRUDENT||'~'||                                           
MNT_PROVISION||'~'||                                            
MNT_ENC_RISQ_PROPRE||'~'||                                      
POURC_NIVEAU_PROVISION||'~'||                                   
MNT_GAR_ACTIF||'~'||                                            
MNT_GAR_PREM_QUAL||'~'||                                        
TX_LGD_PREDICTIF||'~'||                                         
TX_LGD_PREDICTIF_LOCAL||'~'||                                   
CD_NIVEAU_PROVISION||'~'||                                      
CD_COUV_PROVISION||'~'||                                        
CD_NEW_DEFAUT||'~'||                                            
A_EXTRAIRE||'~'||                                               
ID_AUTORISATION ||'~'||                                         
MNT_PNU
-- 27/07/2018 CDS ATOS (JMP) ANACREDIT sprint 13 Rework US29 et 279                
||'~'|| DATE_PREM_ACT_FORB                                        
||'~'|| DATE_SORT_EFF_FORB
||'~'|| DATE_ENTR_PER_PURG
||'~'|| DATE_SORT_PER_PURG
||'~'|| DATE_ENTR_PER_PROB
||'~'|| DATE_SORT_PER_PROB
||'~'|| DATE_THEO_FIN_FORB
-- Fin 27/07/2018 CDS ATOS (JMP) ANACREDIT sprint 13 Rework US29 et 279 
--29/01/2019 CDS ATOS (SQN) US 674
||'~'||BUCKET_IFRS9
||'~'||MNT_MTM
||'~'||CD_DEV_MNT_MTM
--Fin SQN 
-- 11/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
||'~'||MNT_LOY_AVEC_ARR 
||'~'||DEV_LOY_AVEC_ARR 
||'~'||MNT_LOY_HORS_ARR 
||'~'||DEV_LOY_HORS_ARR 
||'~'||MNT_INT_AVEC_ARR
||'~'||DEV_INT_AVEC_ARR
||'~'||MNT_INT_HORS_ARR
||'~'||DEV_INT_HORS_ARR 
-- fin CPD
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE   
-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
||'~'||MNT_CAPITAL_HORS_ARR
||'~'||DEV_CAPITAL_HORS_ARR
-- FIN LFD
--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
||'~'||CD_POSTAL_IMM
||'~'||CD_PAYS_IMM
||'~'||LIB_VILLE_IMM
||'~'||CD_COMMUNE_INSEE
--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
from eng_retail_detail_p5;                                      
spool off;

--05/02/2019 - CDS ATOS (SQN) US 662 - Uniformisation des linesize avec 030_spool_9M_v1.32
--SET linesize 311
--SET linesize 364
-- 05/05/2021 - CDS ATOS (EMM) - CRRV4.3 US 86
--SET linesize 434 -- KLx (GHU) - 03/12/2021 _ 434 + SYS_GEST_SRC 20 = 454 _ US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source' 	
--SET linesize 454+1+7+1+7
SET linesize 470
--Fin EMM
spool $SORTIE/030_FLUX_2M_SURETE_M1.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||                                                     
ID_TIERS_CALC||'~'||                                                    
ID_CENTRAL_TIERS||'~'||                                                 
ID_AUTORISATION||'~'||                                                  
ID_LIGNE_DET||'~'||                                                     
ID_ENGAGEMENT||'~'||                                                    
ID_SURETE||'~'||                                                        
CD_NATOP_CPT||'~'||                                                     
CD_TRR||'~'||                                                           
ID_TIERS_CALC_GAR||'~'||                                                
ID_CENTRAL_TIERS_GAR||'~'||                                             
CD_ETENDUE_SURETE||'~'||                                                
CD_ARROSAGE||'~'||                                                      
CD_NATURE_SURETE||'~'||                                                 
MNT_INITIAL||'~'||                                                      
POURCENT_INITIAL||'~'||                                                 
VAL_GARANTIE||'~'||                                                     
CD_DEVISE||'~'||                                                        
to_char(DT_DEB_EFFET,'YYYYMMDD')||'~'||                                 
to_char(DT_FIN_EFFET,'YYYYMMDD')||'~'||                                 
ELIGIBILITE_SURETE_PERS||'~'||                                          
CD_METHODO_VALORISATION||'~'||                                          
CD_PERIODICITE||'~'||                                                   
CD_PAYS_RECOURS||'~'||                                                  
ANNEE_EVT_MIM||'~'||                                                    
ANNEE_CONSTRUIT_BIEN||'~'||                                             
CD_METHO_VAL_BIEN||'~'||                                                
CD_RANG_SURETE||'~'||                                                   
CD_SORTIE_RISQ_PAYS||'~'||                                              
CD_BOURSE_COTATION||'~'||                                               
TOP_COT_BAL_2||'~'||                                                    
CD_INDICE_TITRE||'~'||                                                  
CD_QUAL_MONTAGE||'~'||                                                  
CD_QUAL_ACTIF||'~'||                                                    
CD_NATIO_EMET||'~'||                                                    
CD_PER_LIQUID||'~'||                                                    
CD_PER_LIQUID2||'~'||                                                   
CD_BORRO_BASE||'~'||                                                    
A_EXTRAIRE||'~'||                                                       
CD_LIEU_DEPOT||'~'||                                                    
MNT_HYPOTHEQUE||'~'|| 
--18/01/18 CDS ATOS (EMM) Sprint 4 US 26
CD_NUTS||'~'|| 
-- Fin EMM  
--12/09/2018 - CDS ATOS (EMM) -  US 489
to_char(DT_REV_MNT, 'YYYYMMDD')
--Fin EMM  
--02/01/2019 - CDS ATOS (LFD) -  US 610
||'~'||EVT_DECL_GAR
||'~'||MNT_TITRES_RECUS
||'~'||CD_DEV_MNT_TITRES_RECUS
||'~'||MNT_CCNE_RECUS_GAR
||'~'||CD_DEV_MNT_CCNE_RECUS_GAR
||'~'||CD_DEV_HYPO
--Fin LFD
--17/01/2019 - CDS ATOS (LFD) -  CRRV4.2 US 651
||'~'||APPLI_SOURCE
||'~'||CD_PAYS_LOCAL_GARANT
-- FIN LFD  
-- 28/04/2021 - CDS ATOS (EMM) - CRRV4.3 US 86
||'~'||MNT_INIT_SURETE_SING_CTRT 
||'~'||MNT_SUR_NO_PRIO_CREANCE 
||'~'||CD_DEV_MNT_SUR_NO_PRIO_CREANCE 
||'~'||REF_UNIQ_CONT 
||'~'||REF_UNIQ_ELEM_CONT 
||'~'||ID_SURETE_ORIG 
-- FIN EMM
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE         
||'~'||SYS_GEST_SRC --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
||'~'||METHOD_BALE_GARANT --KLx (GHU) 
||'~'||METHOD_BALE_GARANT_CALC_SIMUL --KLx (GHU)
from SURETE_M1;
spool off;

--19/02/2019 - CDS ATOS (SQN) - US 730
--SET linesize 244 + 3
SET linesize 256
spool $SORTIE/030_FLUX_2M_SURETE_DETAIL_M5.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||                                     
ID_TIERS||'~'||                                         
ID_TIERS_CALC||'~'||                                    
ID_CENTRAL_TIERS||'~'||                                 
ID_AUTORISATION||'~'||                                  
ID_LIGNE_DET||'~'||                                     
ID_ENGAGEMENT||'~'||                                    
ID_SURETE||'~'||                                        
CD_NATOP_CPT||'~'||                                     
CD_TRR||'~'||                                           
ID_TIERS_GARANT||'~'||                                  
ID_TIERS_CALC_GARANT||'~'||                             
ID_CENTRAL_TIERS_GARANT||'~'||                          
ID_TYPE_GARANTIE_CASA||'~'||                            
CD_INFO_COMPL||'~'||                                    
MNT_GARANTIE||'~'||                                     
MNT_REVISE||'~'||                                       
CD_DEVISE||'~'||                                        
CD_ELLIGIBILITE||'~'||                                  
CD_TAUX_COUV||'~'||                                     
CD_PLAF_UTIL||'~'||                                     
A_EXTRAIRE||'~'||                                       
MNT_RISQUE||'~'||
-- 04/12/2018 - CDS ATOS (LFD) - ANACREDIT US 541
to_char(DT_DEB_EFFET,'YYYYMMDD')||'~'||
to_char(DT_FIN_EFFET,'YYYYMMDD')||'~'||
CD_NUTS||'~'||
CD_NATURE_SURETE||'~'||
CD_RANG_SURETE||'~'||
CD_PAYS_RECOURS||'~'||
CD_METHODO_VALORISATION||'~'||
CD_LIEU_DEPOT
-- FIN LFD
--02/01/2019 - CDS AtoS FAD - CRRV4.2 US611
||'~'||CD_DEV_HYPO
--Fin - CDS AtoS FAD - CRRV4.2 US611
--19/02/2019 - CDS ATOS (SQN) - US 730
||'~'||USAGE_BIEN_GARANTI
--Fin SQN
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
||'~'||NUM_SIREN --M_72558
from SURETE_DETAIL_M5;
spool off;

--19/02/2019 - CDS ATOS (SQN) - US 730
--SET linesize 181 + 3
SET linesize 184
spool $SORTIE/030_FLUX_2M_SURETE_AGREG_M5.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||      				
CD_CONSO_CPT||'~'||                        
ID_TIERS_CALC||'~'||                       
ID_CENTRAL_TIERS||'~'||                    
ID_AUTORISATION||'~'||                     
ID_LIGNE_DET||'~'||                        
ID_ENGAGEMENT||'~'||                       
ID_SURETE||'~'||                           
CD_NATOP_CPT||'~'||                        
CD_TRR||'~'||                              
ID_TIERS_GARANT||'~'||                     
ID_TIERS_CALC_GARANT||'~'||                
ID_CENTRAL_TIERS_GARANT||'~'||             
ID_TYPE_GARANTIE_CASA||'~'||               
CD_INFO_COMPL||'~'||                       
MNT_GARANTIE||'~'||                        
MNT_REVISE||'~'||                          
CD_DEVISE||'~'||                           
CD_ELLIGIBILITE||'~'||                     
CD_TAUX_COUV||'~'||                        
CD_PLAF_UTIL||'~'||                        
A_EXTRAIRE||'~'||                          
MNT_RISQUE
--19/02/2019 - CDS ATOS (SQN) - US 730
||'~'||USAGE_BIEN_GARANTI
--Fin SQN 
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE                          
from SURETE_AGREG_M5;
spool off;

-- 23/04/2021 - CDS ATOS (LFD) - US 89 et 92 CRRV4.3
--+3+6
--SET linesize 860
--SET linesize 869+1+1+1+1
SET linesize 920
spool $SORTIE/030_FLUX_2M_TIE_TIERS.txt
select distinct
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||                                                     
ID_TIERS||'~'||                                                         
ID_TIERS_CALC||'~'||                                                    
ID_CENTRAL_TIERS||'~'||                                                 
NOM_TIERS||'~'||                                                        
RAISON_SOCLE||'~'||                                                     
REF_IDENT_NATIO||'~'||                                                  
IDENT_NATIO||'~'||                                                      
CD_PAYS_NATIONALITE||'~'||                                              
CD_PAYS_RESIDENCE||'~'||                                                
CD_PAYS_CONTROLE||'~'||                                                 
ADRESSE||'~'||                                                          
VILLE||'~'||                                                            
CD_POSTAL||'~'||  
-- CDS ATOS (EMM) US 2 ANACREDIT                                                     
to_char(DT_CLOTURE_CPT_NOTE, 'YYYYMMDD')||'~'||     
--Fin EMM                    
NOTE_INTERNE||'~'||                                                     
to_char(DT_REVISION_NOTE, 'YYYYMMDD')||'~'||                            
to_char(DT_ENTREE_DEFAUT, 'YYYYMMDD')||'~'||                            
CD_METHODO_NOTE||'~'||                                                  
CD_MOTIF_NOTE||'~'||                                                    
CD_ENTITE_RUN||'~'||                                                    
CD_ENTITE_RMC||'~'||                                                    
CD_GRILLE_NOTE||'~'||                                                   
CD_CATEG_CONTREPARTIE||'~'||                                            
CD_PORTEFEUILLE_BAL_TIERS||'~'||                                        
CD_SEGMENT_CAL||'~'||                                                   
CD_SECTEUR_ACTIVITE||'~'||                                              
CD_FILIERE||'~'||                                                       
CD_NORME_LOCAL_ACT||'~'||                                               
CD_ACTIVITE_LOCALE||'~'||                                               
CD_FORM_JUR||'~'||                                                      
CD_STATUT_FILIATION||'~'||                                              
CD_TYPE_ACTEUR||'~'||                                                   
CD_TYPE_RELATION||'~'||                                                 
MNT_CA||'~'||                                                           
TOP_CA_CONSO||'~'||                                                     
CD_DEVISE_CA||'~'||                                                     
ANNEE_CA||'~'||                                                         
TOP_TIERS_DTX||'~'||                                                    
CD_TYPE_TIE||'~'||                                                      
A_EXTRAIRE||'~'||                                                       
NBRE_JOUR_EXERCICE||'~'||                                               
NATURE_CA||'~'||                                                        
NOTE_NAFA||'~'||                                                        
TOT_BILAN_RETRAITE||'~'||                                               
CA_IFRS ||'~'||                                                         
RES_NET_RETRAITE_SIGN||'~'||                                            
RES_NET_RETRAITE_MNT||'~'||                                             
NOTE_APR_CORR_GRPE||'~'||                                               
AGENCE_NOTATION||'~'||                                                  
COTATION||'~'||                                                         
CD_TYPE_COTATION||'~'||                                                 
to_char(DT_COTATION, 'YYYYMMDD')||'~'||                                 
STATUT_ACTIVITE_LOC||'~'||                                              
to_char(DT_STATUT_ACTIVITE_LOC,'YYYYMMDD')||'~'||                       
IDENT_NATION_2||'~'||                                                   
RAIS_SOCL_KBIS||'~'||                                                   
NOTE_CALC_FIN||'~'||                                                    
CD_SECT_RISQ_SYST||'~'||                                                
CD_TYPE_SEGMENT||'~'||                                                  
ID_AGREGAT||'~'||                                                       
REF_ID_NATIONALE2||'~'||                                                
STATUT_ACTIVITE_LOCAL   ||'~'||                                         
DT_STATUT_ACTIVITE_LOCAL  ||'~'||                                      
'N'||'~'||
NB_SALARIE||'~'|| -- 31/05/2018 CDS ATOS (LFD) ANACREDIT US346
ID_ENT_MERE_IMMEDIAT||'~'|| -- 20/12/2018 CDS ATOS (LFD) ANACREDIT US606
IND_ENT_MERE_IMMEDIAT||'~'|| -- 20/12/2018 CDS ATOS (LFD) ANACREDIT US606
CD_NUTS||'~'|| -- 20/12/2018 CDS ATOS (LFD) ANACREDIT US606
ETAT_AVNCT_PJ||'~'|| -- 20/12/2018 CDS ATOS (LFD) ANACREDIT US606
to_char(DT_OUV_PJ,'YYYYMMDD') -- 20/12/2018 CDS ATOS (LFD) ANACREDIT US606
--19/02/2019 - CDS ATOS (SQN) - US 730
||'~'||REF_IDENT_NAT_2
--Fin SQN
--01/03/2019 - CDS ATOS (LFD) - US 746
||'~'||ID_TIERS_CALC_BIS
--Fin LFD
-- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
||'~'||IND_CEL
||'~'||NIV_INTG_GROUPE_TIE
||'~'||IND_OPCVM_EFFET_LEV
-- FIN LFD
-- 28/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
||'~'||CD_AGENT_ECO
-- FIN LFD
||'~'||IND_RATIO_CET
||'~'||IND_RATIO_LEVIER
-- FED
||'~'||IND_WL
||'~'||TO_CHAR(DATE_ENTREE_WL, 'YYYYMMDD')
||'~'||TO_CHAR(DATE_SORTIE_WL, 'YYYYMMDD')
||'~'||CD_TYPE_WL_CASA
||'~'||CD_MOTIF_SORTIE_WL
-- FIN FED
from TIE_TIERS_C1_C5 t 
where  'N' = (CASE when a_extraire = 'N' then (select distinct ('O') from TIE_TIERS_C1_C5 t1 where t1.id_tiers = t.id_tiers and t1.a_extraire = 'O')
    else 'N' end );
spool off;

--08/10/19 CDS ATOS (EMM) Mantis 46097 - Inhibition de l envoi AGREG_P6 vers HCRR
/*
SET linesize 230
spool $SORTIE/030_FLUX_2M_ENG_BALOIS_AGREG_P6.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS_CALC||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
ID_ENGAGEMENT||'~'||
CD_CLASSE_PD||'~'||
POURC_TX_PD||'~'||
CD_CLASSE_LGD||'~'||
TX_LGD_PREDICTIF||'~'||
CD_PAYS_RESIDENCE||'~'||
CD_SECTEUR_ACTIVITE||'~'||
CD_PORTEFEUILLE_BAL_TIERS||'~'||
NOTE_INTERNE||'~'||
CD_CATEG_CONTREPARTIE||'~'||
MNT_EXPO_POTENT_HT||'~'||
ENCOURS_FINANC_BRUT||'~'||
MNT_ENGT_FINANCMT_HB||'~'||
MNT_IRD||'~'||
TX_CCF||'~'||
MNT_EAD_TOT||'~'||
CD_METHODO_BALE2||'~'||
MNT_RWA||'~'||
CD_DEVISE ||'~'||
MATURITE_CALC||'~'||
A_EXTRAIRE||'~'||
TX_LGD_PREDICTIF_HG

from ENG_BALOIS_AGREG_P6;
spool off;
*/
--Fin EMM Mantis 46097

SET linesize 294
spool $SORTIE/030_FLUX_2M_ENG_BALOIS_DETAIL_P6.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS||'~'||
ID_TIERS_CALC||'~'||
ID_CENTRAL_TIERS||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
ID_ENGAGEMENT||'~'||
CD_CLASSE_PD||'~'||
POURC_TX_PD||'~'||
CD_CLASSE_LGD||'~'||
TX_LGD_PREDICTIF||'~'||
CD_PAYS_RESIDENCE||'~'||
CD_SECTEUR_ACTIVITE||'~'||
CD_PORTEFEUILLE_BAL_TIERS||'~'||
NOTE_INTERNE||'~'||
CD_CATEG_CONTREPARTIE||'~'||
MNT_EXPO_POTENT_HT||'~'||
ENCOURS_FINANC_BRUT||'~'||
MNT_ENGT_FINANCMT_HB||'~'||
MNT_IRD||'~'||
TX_CCF||'~'||
MNT_EAD_TOT||'~'||
CD_METHODO_BALE2||'~'||
MNT_RWA||'~'||
CD_DEVISE ||'~'||
MATURITE_CALC||'~'||
A_EXTRAIRE||'~'||
TX_LGD_PREDICTIF_HG
--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
from ENG_BALOIS_DETAIL_P6;
spool off;

--05/02/2019 - CDS ATOS (SQN) US 662 - Uniformisation des linesize avec 030_spool_9M_v1.32
--SET linesize 206
--SET linesize 208
SET linesize 355
  spool $SORTIE/030_FLUX_2M_PROVISIONS_DECOTES_P9.txt
  select
    to_char(DT_ARRETE, 'YYYYMMDD')  ||'~'||
    CD_CONSO_CPT                    ||'~'||
    ID_TIERS_CALC                   ||'~'||
    ID_CENTRAL_TIERS                ||'~'||
    ID_AUTORISATION                 ||'~'||
    ID_LIGNE_DET                    ||'~'||
    ID_ENGAGEMENT                   ||'~'||
    CD_TYPE_RISQUE                  ||'~'||
    CD_PROVISION                    ||'~'||
    CD_NAT_DEPRE                    ||'~'||
    CD_PERIM_PROV                   ||'~'||
    CD_DEVISE                       ||'~'||
    FLAG_HN                         ||'~'||
    A_EXTRAIRE                      ||'~'||
    CD_PCCO_CRD                     ||'~'||
    CD_PCCO_SOLD                    ||'~'||
    MNT_PROVISION_CRD               ||'~'||
    MNT_PROVISION_SOLD              ||'~'||
    MNT_PROVISION_TRIM_CRD          ||'~'||
    MNT_PROVISION_TRIM_SOLD         ||'~'|| 
    ORIGINE_CALCUL_PROVISION        ||'~'|| -- 04/01/2019 - CDS ATOS (LFD) - ANACREDIT US 621
    --19/02/2019 - CDS ATOS (SQN) - US 730
    APPLI_SOURCE                    ||'~'||
    --01/04/2019 - CDS ATOS (LFD) - US 774
    CD_PCCO_PNU                     ||'~'||
    ID_PROVISION                    ||'~'||
    MNT_PROVISION_PNU               ||'~'||
    MNT_PROVISION_TRIM_PNU          ||'~'||
    --CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
    CD_TYPE_PROD_BANCAIRE           ||'~'||
    -- DEBUT :: M67006 - spec 2.2
    SYSTEME_SOURCE                  ||'~'|| --- P9 1.20 
    CD_DEVISE_LIASSE                ||'~'|| --- P9 50.1 
    PCCO_DEPRECIATION               ||'~'|| --- P9 50.10
    MNT_DEPRECIATION                        --- P9 50.11
  -- FIN :: M67006 - spec 2.2
  from provisions_decotes_p9;
spool off;

SET linesize 74
spool $SORTIE/030_FLUX_2M_BTR_ECHEANCIER.txt
select
ID_OPERATION||'~'||
CD_SYS_INT||'~'||
to_char(DT_DEB_TRIM, 'YYYYMMDD')||'~'||
to_char(DT_FIN_TRIM, 'YYYYMMDD')||'~'||
MNT_CRD||'~'||
FLAG_HB_OPE||'~'||
to_char(DT_ARRETE, 'YYYYMMDD')
from BTR_ECHEANCIER;
spool off;

SET linesize 239
spool $SORTIE/030_FLUX_2M_BTR_HORS_BILAN.txt
select
ID_TIERS||'~'||
NUM_DEC||'~'||
ID_OPERATION||'~'||
CD_SYS_INT||'~'||
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_DEVISE||'~'||
CD_SOC_JURI||'~'||
CD_STATUT_OPE_DT_SOLDE||'~'||
CD_STATUT_RISQ_OPE||'~'||
to_char(DT_CHG_STATUT_RISQ, 'YYYYMMDD')||'~'||
CD_PRODUIT||'~'||
CD_TYPE_ACCEPTANT||'~'||
MNT_ENGMT_FINANCMT_HB||'~'||
MNT_BRUT_ORIGINE||'~'||
MNT_SYNDIC_FINANC_HB||'~'||
to_char(DT_DEB_VALIDITE_AUTO, 'YYYYMMDD')||'~'||
to_char(DT_FIN_VALIDITE_AUTO, 'YYYYMMDD')||'~'||
CD_SEGMENT_CASA||'~'||
to_char(DT_ENTREE_SGMT, 'YYYYMMDD')||'~'||
NOTE_RETENUE||'~'||
ID_DECISSIONAIRE||'~'||
MNT_IEC  ||'~'||
CD_SYS_INT_SIG  ||'~'||
ID_OPERATION_SIG
||'~'||IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
from BTR_HORS_BILAN;
spool off;

-- CDS ATOS - 20160608 - Ajout colonnes CD_FLAG_DEFAUT, DT_MAJ_FLAG_DEFAUT, NOM_RESPO_FLAG_DEFAUT, 
--                                      CD_FLAG_RESTRUCTURATION, DT_MAJ_FLAG_RESTRUCT, NOM_RESPO_FLAG_RESTRUCT
--                                      TOP_DEUX_REST_RISQ, DT_TOP_DEUX_REST   
-- 						 La linesize passe de 780 ? 921
--SET linesize 921
--SET linesize 930
-- Projet BHL (Partie Engagements) CDS ATOS (ODL)
-- La linesize passe de 921 ? 1500 caracteres pour etre large.
--SET linesize 1500 + 130 pour le projet IRBA Leasing - 08/03/21 CDS_ATOS (EMM)
--  SET linesize 1630  + 8 pour DT_RESI -- KLx Risque (VDC) - 15/12/2021  - M59791 - Ajout DT_RESI
-- SET linesize 1642 + 128 pour les 5 nouvelles colonnes -- KLX RISQUE (VDC) - 06/05/2022 - Mantis 62156 - Ajout de CD_NATURE_PRINC, CD_COMMERCIAL, CD_ACCEPTANT, ID_FOURNISSEUR_PRINC, LIB_FOURNISSEUR_PRINC, SIREN_APPORTEUR_PRINC
--SET linesize 1799
--SET linesize 1770+1+2+1+8+1+8+1+6+1+2+1+1+1+1+1+2+1+19+1+3+1+1+1
--SET linesize 1850 
--SET linesize 1950 -- N3D Forbearance + Bale 4
--SET linesize 1855 --RSE LOT2
--SET linesize 3200 --N3D Forbearance 
-- SIRL-669: 3200 + 19 - 4 = 3215
SET linesize 3215 
spool $SORTIE/030_FLUX_2M_BTR_OPERATION.txt
select
ID_OPERATION||'~'||
CD_SYS_INT||'~'||
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_SOC_JURI||'~'||
TOP_ENG||'~'||
CD_PRODUIT||'~'||
CD_DEVISE||'~'||
ID_TIERS||'~'||
NUM_DEC||'~'||
CD_STATUT_OPE_DT_SOLDE||'~'||
CD_STATUT_RISQ_OPE||'~'||
to_char(DT_CHG_STATUT_RISQ, 'YYYYMMDD')||'~'||
CD_SEGMENT_CAL||'~'||
CD_SEGMENT_CASA||'~'||
to_char(DT_ENTREE_SGMT, 'YYYYMMDD')||'~'||
CD_TYPE_ACCEPTANT||'~'||
to_char(DT_DEB_VALIDITE_AUTO, 'YYYYMMDD')||'~'||
to_char(DT_SIGNATURE_CLIENT, 'YYYYMMDD')||'~'||
to_char(DT_STATUT, 'YYYYMMDD')||'~'||
to_char(DT_DEB_OPE, 'YYYYMMDD')||'~'||
to_char(DT_FIN_OPE, 'YYYYMMDD')||'~'||
to_char(DT_MEL, 'YYYYMMDD')||'~'||
CRD_BRUT_HT||'~'||
MNT_ICNE||'~'||
ENC_FINANC_BRUT||'~'||
MNT_SOLDE_HT_CPT_CLI||'~'||
MNT_SOLDE_HT_EXIGIB_K||'~'||
MNT_SOLDE_HT_EXIGIB_I||'~'||
MNT_SOLDE_HT_EXIGIB_IRE||'~'||
MNT_IDEM_RETARD||'~'||
MNT_SOLDE_HT_EXIGIB_AUTRE||'~'||
MNT_VR||'~'||
MNT_EXPO_COURANTE_HT||'~'||
MNT_EXPO_POTENT_HT||'~'||
FLAG_IMPAYES||'~'||
TX_LGD_PREDICTIF||'~'||
TX_LGD_PREDICTIF_LOCAL||'~'||
CD_CANAL_APPORT||'~'||
QP_POOL||'~'||
CD_STATUT_OPE||'~'||
CD_DRV||'~'||               --lot 5.1
LIB_CHEF_DE_FILE||'~'||     --lot 5.1
POSITION_CAL_POOL||'~'||    --lot 5.1
ID_GEST_OPE||'~'||          --lot 5.1
MNT_PROV_SOLD_LOY_K||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PROV_CRD||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PROV_SOLD_LOY_I||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PROV_SOLD_IRE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PROV_SOLD_AUT||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PROV_ICNE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_SOLD_LOY_K||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_CRD||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_SOLD_LOY_I||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_SOLD_IRE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_SOLD_AUT||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_ICNE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_COUV_SOLD_LOY_K||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_COUV_CRD||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_COUV_SOLD_LOY_I||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_COUV_SOLD_IRE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_COUV_SOLD_AUT||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_COUV_ICNE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_NOCOUV_SOLD_LOY_K||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_NOCOUV_CRD||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_NOCOUV_SOLD_LOY_I||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_NOCOUV_SOLD_IRE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_NOCOUV_SOLD_AUT||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_PERTE_NOCOUV_ICNE||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_ACTU_PROV||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_REPRISE_ACTU_PROV||'~'||      -- AGU 05/07/2010 Lot V5.3
MNT_DEASCTU_PROV||'~'||             -- AGU 05/07/2010 Lot V5.3
MNT_FRAIS_RECOUV||'~'||           -- NRN 02/08/2010
MNT_FRAIS_CESSION||'~'||          -- NRN 02/08/2010
CD_RESEAU||'~'||                  -- HBO 04/11/2010 Lot V5.4
MNT_EAD_TOT||'~'||                   -- NRN 02/08/2010
MNT_BRUT_ORIGINE||'~'||              -- LBL 24/11/2011 Lot 6.1
MNT_ENC_RISQ_PROPRE||'~'||           -- LBL 24/11/2011 Lot 6.1
MNT_EXP_RISQ_PROPRE||'~'||           -- LBL 24/11/2011 Lot 6.1
ENC_FINANC_NET_AVP||'~'||            -- LBL 18/07/2012 lot 6.3 (desactiver car report? pour lot de mai)
MNT_SUBV_HT||'~'||                   -- LBL 18/07/2012 lot 6.3 (desactiver car report? pour lot de mai)
MNT_AVP_HT||'~'||                    -- LBL 18/07/2012 lot 6.3 (desactiver car report? pour lot de mai)
MNT_AVR_HT||'~'||                    -- LBL 18/07/2012 lot 6.3 (desactiver car report? pour lot de mai)
CD_STATUT_OPETHEO||'~'||             -- LBL 15/11/2011 Lot 6.4
CD_STATUT_OPEMOD||'~'||              -- LBL 15/11/2011 Lot 6.4
to_char(DT_DEB_VALID, 'YYYYMMDD')||'~'||  -- LBL 15/11/2011 Lot 6.4
to_char(DT_FIN_VALID, 'YYYYMMDD')||'~'||  -- LBL 15/11/2011 Lot 6.4
CD_CANAL_DISTRIB||'~'||                   -- LBL 06/02/2013 BTR6.5
MATURITE_CALC||'~'||                      -- LBL 06/02/2013 BTR6.5
MATURITE_EFF||'~'||                       -- LBL 06/02/2013 BTR6.5
to_char(DT_CPTABLE_PREM_IMPY, 'YYYYMMDD')||'~'||  -- LBL 06/02/2013 BTR6.5
to_char(DT_EXIGTE_PREM_IMPY, 'YYYYMMDD')||'~'||  -- LBL 06/02/2013 BTR6.5
CD_STATUT_RECOUV||'~'||                   -- LBL 06/02/2013 BTR6.5
FLAG_AFF_RESTR||'~'||                     -- LBL 06/02/2013 BTR6.5
FLAG_REJ_TECH||'~'||                      -- LBL 06/02/2013 BTR6.5
MNT_SEUIL_PROV||'~'||                     -- LBL 06/02/2013 BTR6.5
CD_MOTIF_POS_SRA||'~'||                   -- LBL 06/02/2013 BTR6.5
to_char(DT_POS_SRA, 'YYYYMMDD')||'~'||    -- LBL 06/02/2013 BTR6.5
CD_MOTIF_POS_SCO||'~'||                   -- LBL 06/02/2013 BTR6.5
to_char(DT_POS_SCO, 'YYYYMMDD')||'~'||    -- LBL 06/02/2013 BTR6.5
TOP_CONTAGION||'~'||                      -- LBL 06/02/2013 BTR6.5
MNT_ANN_ACTU_PROV||'~'||                  -- CSU 13/01/2013 BTR 6.8
MNT_ANN_DESACTU_PROV||'~'||               -- CSU 13/01/2013 BTR 6.8
NBRE_IMPY||'~'||
--- BTR 6.9 : Ajout colonnes AQR
CD_AQR||'~'||
to_char(DT_AQR, 'YYYYMMDD')||'~'||  
CD_AQR_FORCE||'~'||
to_char(DT_AQR_FORCE, 'YYYYMMDD')||'~'||  
to_char(DT_FIN_VALID_AQR, 'YYYYMMDD')||'~'||  
TOP_PL_NPL||'~'||
to_char(DT_FIN_VALID_NPL, 'YYYYMMDD')||'~'||
MNT_LOY_RD||'~'||
MNT_INt_RD||'~'||
CD_TYPE_TAUX||'~'||
TX_TRC||'~'||
CD_FLAG_DEFAUT||'~'||								-- CDS ATOS - 20160608
to_char(DT_MAJ_FLAG_DEFAUT, 'YYYYMMDD')||'~'||		-- CDS ATOS - 20160608
NOM_RESPO_FLAG_DEFAUT||'~'||						-- CDS ATOS - 20160608
CD_FLAG_RESTRUCTURATION||'~'||						-- CDS ATOS - 20160608
to_char(DT_MAJ_FLAG_RESTRUCT, 'YYYYMMDD')||'~'||	-- CDS ATOS - 20160608
NOM_RESPO_FLAG_RESTRUCT||'~'||						-- CDS ATOS - 20160608
TOP_DEUX_REST_RISQ||'~'||							-- CDS ATOS - 20160608
to_char(DT_TOP_DEUX_REST, 'YYYYMMDD')||'~'||				-- CDS ATOS - 20160608	
-- 05/04/2018 CDS ATOS (JMP) ANACREDIT US45 Sprint 7
to_char(DT_CHG_PE_NPE, 'YYYYMMDD')	||'~'||
-- 11/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Donnees premier d?blocage de fonds
MNT_PREM_DBLQ_FONDS||'~'||
to_char(DT_PREM_DBLQ_FONDS, 'YYYYMMDD')	
-- Fin 11/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Donnees premier d?blocage de fonds
||'~'||COTATION_BDF -- 26/03/2019 - CDS ATOS (LFD) - US 768
||'~'||INDIC_PSE -- 26/03/2019 - CDS ATOS (LFD) - US 768
--15/05/2019 CDS ATOS (SQN) NDDD US 5
||'~'||MNT_SOLDE_HT_EXIGIB_AUTRE_T
||'~'||MNT_SOLDE_HT_EXIGIB_I_T
||'~'||MNT_SOLDE_HT_EXIGIB_K_T
||'~'||MNT_SOLDE_HT_EXIGIB_IRE_T
--Fin SQN
-- Debut ajouts projet BHL (Partie Engagements) CDS ATOS (ODL).
||'~'||NUM_PALLIER
||'~'||NBRE_ECHEANCE
||'~'||TAUX_NOMINAL
||'~'||TYPE_PALIER
||'~'||CD_PERIODTE_ECHEANCE
||'~'||CD_TERME_ECHEANCE
||'~'||TYPE_DELEGATION
||'~'||DECIDEUR
-- Fin ajouts projet BHL (Partie Engagements).
--CDS_ATOS (MNE) - 16/08/2021 - Mantis 58424 Obselescence ICG - suite de la mise e disposition de donnees dans le referentiel balois (HCRR)
||'~'||CD_TYPE_PRODUIT
||'~'||CD_UNITE_PROD
||'~'||MNT_MARGE_FRONTALE
--FIN MNE
||'~'||IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
||'~'||to_char(DT_RESI, 'YYYYMMDD') -- KLx Risque - 15/12/2021 - Mantis 59791 - Ajout champ DT_RESI
--DEBUT: KLxRisqLeasing (BA) - Mantis 59562: RWA GreenLease - evolution CRRV4 Leasing
||'~'||CD_TYPE_MODELE
--FIN: KLxRisqLeasing (BA) - Mantis 59562: RWA GreenLease - evolution CRRV4 Leasing
--DEBUT: KLX RISQUE (VDC) - Mantis 62156: [Obsolescence ICG] Evolution dans le cas des PP sur marge
||'~'||CD_NATURE_PRINC
||'~'||CD_COMMERCIAL
||'~'||CD_ACCEPTANT
||'~'||ID_FOURNISSEUR_PRINC
||'~'||LIB_FOURNISSEUR_PRINC
||'~'||SIREN_APPORTEUR_PRINC
--FIN: KLX RISQUE (VDC) - Mantis 62156: [Obsolescence ICG] Evolution dans le cas des PP sur marge
||'~'||MOTIF_MRTR                 
||'~'||TO_CHAR(DT_DEBUT_MRTR,'YYYYMMDD')        
||'~'||TO_CHAR(DT_FIN_MRTR,'YYYYMMDD')          
||'~'||DUREE_MRTR          
||'~'||STATUT_MRTR         
||'~'||IND_MRTR_LEGISLATIF 
||'~'||IND_MRTR_CONTRACTUEL
||'~'||CHAMP_APPL_MRTR     
||'~'||MNT_MRTR            
||'~'||DEV_MRTR
||'~'||IND_CONF_CRIT_OPE
||'~'||EMIS_GAS_PRODELEC --RSE LOT2
||'~'||to_char(DT_FIN_DELAI_GRACE, 'YYYYMMDD')
||'~'||FLAG_LOY_MAJORE
||'~'||TX_DECOTE_FORF
||'~'||to_char(DT_CHG_TAUX, 'YYYYMMDD')
-----------------RSE LOT3--------------------
||'~'||PROD_ANUEL_ESTIME_ELEC_INST
from BTR_OPERATION;
spool off;

-- Debut ajouts projet BHL (Partie Engagements) CDS ATOS (ODL).
-- La linesize est determinee a 500 pour etre large.
SET linesize 500
spool $SORTIE/030_FLUX_2M_BTR_OPE_LIEN_LIGNE_UTIL.txt
SELECT
TO_CHAR(DT_ARRETE, 'YYYYMMDD')
||'~'||ID_AUTORISATION
||'~'||NUM_DEC
||'~'||MNT_BRUT_ORIGINE
||'~'||MNT_FACT
||'~'||CD_SYS_INT
||'~'||ID_OPERATION_SIG
||'~'||CD_SYS_INT_SIG
||'~'||CD_ACCEPTANT
FROM BTR_OPE_LIEN_LIGNE_UTIL;
spool off;
-- Fin ajouts projet BHL (Partie Engagements).

--26/05/2021 - CDS ATOS (LFD) - Mantis 57336
--SET linesize 142
-- +12
SET linesize 154
-- FIN LFD
spool $SORTIE/030_FLUX_2M_BTR_SURETE_PERS.txt
select
ID_OPERATION||'~'||
CD_SYS_INT||'~'||
ID_TIERS_GARANT||'~'||
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
ID_TYPE_GARANTIE||'~'||
ID_TYPE_GARANTIE_CASA||'~'||
ID_SURETE||'~'||
MNT_GARANTIE||'~'||
QUOTE_PART_GARANT||'~'||
to_char(DT_DEB_VALID_GARANT, 'YYYYMMDD')||'~'||
to_char(DT_FIN_VALID_GARANT, 'YYYYMMDD')||'~'||
ELIGIBILITE_SUR_PERS	--AFR le 13/07/12 BTR 6.3 provisions dans CRRv3
||'~'||LIB_TYPE_GARANTIE_AUT -- 26/05/21 - CDS ATOS (LFD) - Mantis 57336
from BTR_SURETE_PERS;
spool off;

--DEBUT :: Projet VTR-CBI :: sous-chapitre 4.13.3 du SFG
--set linesize 1235
--set linesize 1225+1+11+1+12
--set linesize 1250
set linesize 1350 --N3D Forbearance + Bale 4
spool $SORTIE/030_FLUX_2M_BTR_SURETE_REELLE.txt
  select
	ID_OPERATION                                   || '~' ||
	CD_SYS_INT                                     || '~' ||
	to_char(DT_ARRETE,'YYYYMMDD')                  || '~' ||
	ID_ACTIF                                       || '~' ||
	replace(LIB_ACTIF,'~',' ')                     || '~' ||
	CD_FAMILLE_ACTIF                               || '~' ||
	CD_STATUT_ACT                                  || '~' ||
	ID_SURETE                                      || '~' ||
	MNT_INITIAL                                    || '~' ||
	MNT_REVISE                                     || '~' ||
	MNT_VTR_PDR                                    || '~' ||
	CD_PROD_FINANC                                 || '~' ||
	to_char(DT_EVT_MIM, 'YYYYMMDD')                || '~' ||
	to_char(DT_DERNIER_EVT_ITN, 'YYYYMMDD')        || '~' ||
	CD_MATERIEL_NAF                                || '~' ||
	CD_FAMILLE_IMM                                 || '~' ||
	CD_TYPE_COPROPRIETE                            || '~' ||
	CD_TYPO_COMMERCE                               || '~' ||
	CD_TYPO_ENTREPOT                               || '~' ||
	CD_CATEG_HOTEL                                 || '~' ||
	N_NB_LIT                                       || '~' ||
	N_NB_CHAMBRE                                   || '~' ||
	to_char(DT_DAT,'YYYYMMDD')                     || '~' ||
	CD_ETAT_ACT                                    || '~' ||
	to_char(DT_FIN_VALID_ETAT_ACT,'YYYYMMDD')      || '~' ||
	CD_ANCIENNETE_ACT                              || '~' ||
	to_char(DT_FIN_VALIDITE,'YYYYMMDD')            || '~' ||
	to_char(DT_MODIF,'YYYYMMDD')                   || '~' ||
	CD_SIT_GEO_N1                                  || '~' ||
	CD_SIT_GEO_N2                                  || '~' ||
	SURFACE_ACT_CBI                                || '~' ||
	TX_CAPITALISATION                              || '~' ||
	N_VALEUR_LOCATIVE                              || '~' ||
	TX_DECOTE_FS                                   || '~' ||
	F_MANUEL                                       || '~' ||
	CD_ORIGINE_VALO_VTR                            || '~' ||
	CD_UTIL                                        || '~' ||
	MNT_VV_ACT                                     || '~' ||
	LIG_1_ADR_ACT_CBI                              || '~' ||
	LIG_2_ADR_ACT_CBI                              || '~' ||
	LIG_3_ADR_ACT_CBI                              || '~' ||
	LIG_4_ADR_ACT_CBI                              || '~' ||
	CD_POSTAL                                      || '~' ||
	VILLE                                          || '~' ||
	CD_PAYS                                        || '~' ||
	CRD_BRUT_ACT                                   || '~' ||
	IMMATRICULATION                                || '~' || --LBL 24/11/2011 Lot 6.1
	to_char(DT_PREM_IMMAT,'YYYYMMDD')              || '~' || --LBL 24/11/2011 Lot 6.1
	CD_MARQUE                                      || '~' || --LBL 24/11/2011 Lot 6.1
	LIB_MODELE                                     || '~' || --LBL 24/11/2011 Lot 6.1
	CD_TYPE_CBI                                    || '~' || --LBL 24/11/2011 Lot 6.2
	CD_INTERV_MEL                                  || '~' || --LBL 24/11/2011 Lot 6.2
	CD_ANC_CONTRAT                                 || '~' || --LBL 24/11/2011 Lot 6.2
	MNT_ACQ_HT_ACT                                 || '~' || --LBL 24/11/2011 Lot 6.2
	CD_METHODO_VALORISATION_CBI                    || '~' || --AFR 08/08/2012 lot 6.3
	MNT_VNF_ACT                                    || '~' || --LBL le 07/02/2013 BTR 6.5
	to_char(DT_VALO_VTR,'YYYYMMDD')                || '~' || --LBL le 07/02/2013 BTR 6.5
	TX_ACTUARIEL                                   || '~' || --LBL le 07/02/2013 BTR 6.5
	MNT_VTR_PDR_ACT                                || '~' || --LBL le 07/02/2013 BTR 6.5
	COEF_DOWNTURN_VTR                              || '~' || --LBL le 07/02/2013 BTR 6.5
	-- Debut ajouts projet BHL (Partie Suretes) CDS ATOS (ODL)
	CD_STATUT_ACT_SUPP                             || '~' ||
	CD_TYPE_AMORT_CPTABLE                          || '~' ||
	DUREE_AMORT_CPTABLE_ACT                        || '~' ||
	MNT_CONSTRUCTION                               || '~' ||
	MNT_FRAIS                                      || '~' ||
	PRIX_ACQ_BATIMENT                              || '~' ||
	PRIX_ACQ_TERRAINS                              || '~' ||
	REGIME_FISCAL                                  || '~' ||
	-- Fin ajouts projet BHL (Partie Suretes)
	-- Debut ajouts projet BHL (Partie Cessions de creances) CDS ATOS (ODL)
	to_char(DT_OPERATION,'YYYYMMDD')               || '~' ||
	to_char(DT_COMPTABLE,'YYYYMMDD')               || '~' ||
	FRAIS_RECOMM                                   || '~' ||
	to_char(DT_FIN_PREVUE,'YYYYMMDD')              || '~' ||
	PRIX_VENTE_EFF_ACT                             || '~' ||
	-- Fin ajouts projet BHL (Partie Cessions de creances) CDS ATOS (ODL)
	-- DEBUT PROJET RSE 
  to_char(DT_PREM_UTIL,'YYYYMMDD')               || '~' ||
  EMIS_CO2_VEHIC                                 || '~' ||
  CATEG_VEHIC                                    || '~' ||
  -- RSE lot 3 - SIRL-177
  --CONSOM_ENERGIE_PRIMAIRE                        || '~' ||
  CONSOM_ENERGIE_PRIMAIRE_OCTROI                 || '~' ||
  CONSOM_ENERGIE_ESTIMEE                         || '~' ||
  to_char(DT_CONSTR_BIEN,'YYYYMMDD')             || '~' ||
  to_char(DT_DELIV_PERMIS_CONSTRUIRE,'YYYYMMDD') || '~' ||
  NORME_THERMIK_BIEN                             || '~' ||
  to_char(DT_REAL_DPE_BIEN_IMM,'YYYYMMDD')       || '~' ||
  EMIS_GAZ_EFFET_SERRE_BIEN	                     || '~' ||
  CLASSE_GAZ_EFFET_SERRE_BIEN                    || '~' ||
  DEMAND_ENRG_PRIM_POSTTRAV	                     || '~' ||
  CD_ENERGIE                                     || '~' ||
  CD_STATUS_ACTIF	                               || '~' ||
  CD_NATURE_INVEST	                             || '~' ||
  CD_TYPE_INVEST                                 || '~' ||
  NUM_ADEME                                      || '~' ||
	-- FIN Ajout Projet RSE
  MNT_VV_ACT_PLAF                                || '~' || --Projet VTR-CBI :: sous-chapitre 4.13.3 du SFG
	MNT_LTV_VV_ACT                                 || '~' || --Projet VTR-CBI :: sous-chapitre 4.13.3 du SFG
	MNT_ETV_VV_ACT                                 || '~' || --Projet VTR-CBI :: sous-chapitre 4.13.3 du SFG
  LATITUDE                                       || '~' || 
	LONGITUDE                                      || '~' || 
  TX_ACTUARIEL_PREC                              || '~' || --N3D Forbearance 
  CATEG_ENERGIE_BIEN_IMM_OCTROI                  || '~' || -- RSE Lot3
	CATEG_ENERGIE_BIEN_IMM_A_DATE                  || '~' || -- RSE Lot3
  CONSO_ENERGIE_PRIM_EFF_A_DATE                            -- RSE Lot3
  from BTR_SURETE_REELLE;
spool off;
--FIN :: Projet VTR-CBI :: sous-chapitre 4.13.3 du SFG

-- Debut ajouts projet BHL (Partie Cessions de creances) CDS ATOS (ODL).
-- La linesize est determinee a 500 pour etre large.
SET linesize 500
spool $SORTIE/030_FLUX_2M_BTR_PLUS_MOINS_VALUE.txt
SELECT
TO_CHAR(DT_ARRETE, 'YYYYMMDD')
||'~'||ID_ACTIF
||'~'||ID_TIE_RISQ
||'~'||CD_SYS_INT
||'~'||TO_CHAR(DT_OPERATION, 'YYYYMMDD')
||'~'||ID_OPERATION
||'~'||TO_CHAR(DT_COMPTABLE, 'YYYYMMDD')
||'~'||PRIX_VENTE_EFF_ACT
||'~'||PLUS_VALUE_FINANC
FROM BTR_PLUS_MOINS_VALUE;
spool off;
-- Fin ajouts projet BHL (Partie Cessions de creances).


-- Debut ajouts projet BHL (Partie Pertes) CDS ATOS (ODL).
-- La linesize est determinee a 500 pour etre large.
SET linesize 500
spool $SORTIE/030_FLUX_2M_BTR_PERT_PROF.txt
SELECT
TO_CHAR(DT_ARRETE, 'YYYYMMDD')
||'~'||ID_TIE_RISQ
||'~'||ID_OPERATION
||'~'||CD_SYS_INT
||'~'||NUM_OD
||'~'||TYPE_OD
||'~'||NATURE_OD
||'~'||TO_CHAR(DT_OPERATION, 'YYYYMMDD')
||'~'||MNT_PERT_PROF
||'~'||ID_GESTRE_RECOUV
||'~'||TO_CHAR(DT_GEST_OD, 'YYYYMMDD')
||'~'||MNT_PERT_PROF_K
||'~'||MNT_PERT_PROF_I
||'~'||MNT_PERT_PROF_A
||'~'||CD_ROLE_TIE
FROM BTR_PERT_PROF;
spool off;
-- Fin ajouts projet BHL (Partie Pertes).


-- Debut ajouts projet BHL (Partie Appels en garantie) CDS ATOS (ODL).
-- La linesize est determinee a 500 pour etre large.
SET linesize 500
spool $SORTIE/030_FLUX_2M_BTR_APPEL_EN_GARA_CBI.txt
SELECT
TO_CHAR(DT_ARRETE, 'YYYYMMDD')
||'~'||ID_OPERATION
--18/07/2019 CDS ATOS (SQN) BHL Mantis recette 9755
--||'~'||ID_TIERS_RISQ
||'~'||ID_TIE_RISQ
--Fin SQN
||'~'||NUM_APPEL
||'~'||CD_SYS_INT
||'~'||TO_CHAR(DT_APPEL, 'YYYYMMDD')
||'~'||MNT_APPEL_CUMULE
||'~'||MNT_REGLE_CUMULE
||'~'||TO_CHAR(DT_DERNIER_REGLEMENT, 'YYYYMMDD')
||'~'||FLAG_REG_TOT
FROM BTR_APPEL_EN_GARA_CBI;
spool off;

SET linesize 500
spool $SORTIE/030_FLUX_2M_BTR_APPEL_EN_GARA_CBM.txt
SELECT
TO_CHAR(DT_ARRETE, 'YYYYMMDD')
||'~'||BANQUE
||'~'||NUM_TIERS_AGENCE
||'~'||TO_CHAR(DT_APPEL, 'YYYYMMDD')
||'~'||NUM_AFFAIRE
||'~'||SEQ_ID_NO_LG_CSV
||'~'||ANNEE
||'~'||MNT_APPEL
||'~'||AVOIR
||'~'||MNT_REGLE
||'~'||SOLDE
||'~'||NOM_CAISSE
||'~'||NOM_CLIENT
||'~'||SIREN
||'~'||TO_CHAR(DT_REGLEMENT, 'YYYYMMDD')
FROM BTR_APPEL_EN_GARA_CBM;
spool off;
-- Fin ajouts projet BHL (Partie Appels en garantie).


-- Debut ajouts projet BHL (Partie Provisions) CDS ATOS (ODL).
SET linesize 500
spool $SORTIE/030_FLUX_2M_BTR_PJ10_RETRAITE.txt
SELECT
--26/05/20 CDS ATOS (EMM) Mantis IFRS9 52152
TO_CHAR(DT_ARRETE, 'YYYYMMDD')
||'~'||ANALYSTE         
||'~'||LIB_SCO                 
||'~'||CD_SOC_JURI    			
||'~'||LIB_SOC_JURI				
||'~'||ID_OPERATION             
||'~'||ID_CLIENT                 
||'~'||ID_CLI_SIG 
||'~'||TO_CHAR(DT_TRT, 'YYYYMMDD')
||'~'||NUM_SIREN					
||'~'||RAISON_SOCLE 				
||'~'||CD_PRODUIT                  
||'~'||ITNL						
||'~'||MNT_CRD				
||'~'||MNT_ICNE					
||'~'||MNT_PROV_SOLD_LOY_K      
||'~'||MNT_PROV_CRD             
||'~'||MNT_PROV_SOLD_LOY_I    
||'~'||MNT_PROV_SOLD_IRE        
||'~'||MNT_PROV_SOLD_AUT      
||'~'||MNT_PROV_ICNE				
||'~'||MNT_ASS_SOLD_LOY_K_TTC	
||'~'||MNT_ASS_SOLD_LOY_I_TTC		
||'~'||MNT_ASS_SOLD_IRE_TTC		
||'~'||MNT_ASS_SOLD_AUT_TTC		
||'~'||MNT_STK_PROV_SOCIAL		
||'~'||MNT_ASS_SOLD_LOY_K_HT		
||'~'||MNT_ASS_SOLD_LOY_I_HT		
||'~'||MNT_ASS_SOLD_IRE_HT		
||'~'||MNT_ASS_SOLD_AUT_HT		
||'~'||STK_ACTU_PER_PROV_FINANC  
||'~'||MNT_ASS_GLOB				
||'~'||MNT_TOT_CRE_HT				
||'~'||MNT_TOT_PROV_CRE			
||'~'||MNT_TOT_PROV_M				
||'~'||COMMENTAIRE_DCCR
FROM BTR_PJ10_RETRAITE;
--Fin EMM Mantis 52152
spool off;
-- Fin ajouts projet BHL (Partie Provisions).

--28/02/2019 - CDS ATOS (SQN) - US 587
--SET linesize 1053 + 68
--SET linesize 1121
-- Projet BHL (Partie Tiers) CDS ATOS (ODL)
-- La linesize passe de 1053 ? 1500 caracteres (pour etre large).
--SET linesize 1500
SET linesize 1504 --KLx 29/11/2022 Mantis 64347 
spool $SORTIE/030_FLUX_2M_BTR_TIERS.txt
select
ID_TIERS||'~'||
TYPE_TIERS||'~'||
CD_ROLE_TIERS||'~'||
IDENT_SIRIS||'~'||
CD_SEGMENT_CAL||'~'||
CD_SEGMENT_CASA||'~'||
to_char(DT_ENTREE_SGMT, 'YYYYMMDD')||'~'||
CD_TYPE_SGMT||'~'||
RAISON_SOCLE||'~'||
NUM_SIRET||'~'||
NUM_SIREN||'~'||
ID_ENTR||'~'||
REF_EXT_GRPE_CALF||'~'||									-- NSC 24/10/2010 BTR 6.1 TiersGrpe lot3
NOM_GRPE||'~'||														-- NSC 24/10/2010 BTR 6.1 TiersGrpe lot3
CD_TYPE_LIEN||'~'||
NOM_PATRO||'~'||
PRENOM||'~'||
CD_PAYS_CONTROLE||'~'||
CD_PAYS_RESIDENCE||'~'||
CD_PAYS_NATIONALITE||'~'||
CD_PAYS_RISQUE||'~'||
LIGNE_1_ADR||'~'||
LIGNE_2_ADR||'~'||
LIGNE_3_ADR||'~'||
LIGNE_4_ADR||'~'||
VILLE||'~'||
CD_POSTAL||'~'||
to_char(DT_CLOTURE_CPT_NOTE, 'YYYYMMDD')||'~'||
NOTE_BALOISE||'~'||
to_char(DT_NOTE_BAL, 'YYYYMMDD')||'~'||
to_char(DT_DEF_PAIEM_ENTR, 'YYYYMMDD')||'~'||
to_char(DT_DEF_PAIEM_SORT, 'YYYYMMDD')||'~'||
CD_METHODE_NOTE||'~'||
CD_MOTIF_NOTE||'~'||
CD_SOURCE_NOTE||'~'||
CD_ORIGINE_NOTE||'~'||
CD_RUN||'~'||
CD_APE||'~'||
CD_NAF_REV2||'~'||
CD_FORM_JUR||'~'||
MNT_CA||'~'||
EXERCICE_CA||'~'||
CD_STATUT_RISQ||'~'||
to_char(DT_CHG_STATUT_RISQ, 'YYYYMMDD')||'~'||
to_char(DT_CHG_CATEG_CPT, 'YYYYMMDD')||'~'||
CD_CATEG_CPT||'~'||
CD_ENTITE_RMC||'~'||
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_GRILLE_NOTE||'~'||	       --lot 5.1
CD_DRV||'~'||      	         --lot 5.1
ID_COTATION_BDF||'~'||       --lot 5.2
to_char(DT_COT_ENTR_BDF, 'YYYYMMDD')||'~'||              --lot 5.2
CD_CATEG_CONTREPARTIE||'~'||            -- AGU 05/07/2010 Lot V5.3
CD_APE_INTERNE||'~'||                     -- AGU 05/07/2010 Lot V5.3
CD_MARCHE_DCO||'~'||                    -- HBO 04/11/2010 Lot V5.4 
EFFECTIF_ENTR||'~'||
TOP_CONTAGION_GRPE||'~'||               -- NSC 24/10/2010 BTR 6.1 TiersGrpe lot3
CD_AGE_ECO||'~'||                                 -- LBL 24/11/2011 Lot 6.1
to_char(DT_CPTABLE_PREM_IMPY, 'YYYYMMDD')||'~'||  -- LBL 24/11/2011 Lot 6.1
to_char(DT_EXIGTE_PREM_IMPY, 'YYYYMMDD')||'~'||         -- LBL 24/11/2011 Lot 6.1
CD_TYPE_ACTEUR||'~'||										 --AFR le 13/07/12 BTR 6.3 ajout provisions dans crrv3
POURC_TX_PD||'~'||    									 --AFR le 08/08/12 BTR 6.3 ajout provisions dans crrv3
CD_STATUT_THEO||'~'||                    -- LBL 15/11/2012 Lot 6.4
CD_STATUT_RISQ_AP||'~'||                 -- LBL 15/11/2012 Lot 6.4
to_char(DT_DEB_VALID, 'YYYYMMDD')||'~'|| -- LBL 15/11/2012 Lot 6.4
to_char(DT_FIN_VALID, 'YYYYMMDD')||'~'|| -- LBL 15/11/2012 Lot 6.4
to_char(DT_DEF_PREM_DEFAUT, 'YYYYMMDD')||'~'||  -- LBL 15/11/2012 Lot 6.4
CD_MOTIF_SCO||'~'||                                ---LBL le 05/02/2013 BTR 6.5
CD_EVT_CONTAGION||'~'||                            ---LBL le 05/02/2013 BTR 6.5
to_char(DT_EVT_CONTAGION, 'YYYYMMDD')||'~'||       ---LBL le 05/02/2013 BTR 6.5
CD_MOTIF_POS_SRT||'~'||                            ---LBL le 05/02/2013 BTR 6.5
to_char(DT_POS_SRT, 'YYYYMMDD')||'~'||       ---LBL le 05/02/2013 BTR 6.5
AGENCE_NOTATION||'~'|| 
COTATION||'~'||       
CD_TYPE_COTATION||'~'|| 
to_char(DT_COTATION, 'YYYYMMDD')||'~'||  
STATUT_ACTIVITE_LOC||'~'|| 
to_char(DT_STATUT_ACTIVITE_LOC, 'YYYYMMDD')||'~'|| 
IDENT_NATION_2 ||'~'||
RAIS_SOCL_KBIS||'~'|| 
NOTE_CALC_FIN||'~'||   
CD_SECT_RISQ_SYST ||'~'||
ID_TIE_SYS_EXT          ||'~'||
TOP_CA_CONSO		||'~'||	    -- CRRV4 Modif 01/10/2015
MNT_CA_DTG		||'~'||	
ANNEE_CA_DTG		||'~'||	
NBRE_JOUR_EXERCICE	||'~'||	
NATURE_CA		||'~'||	
NOTE_NAFA		||'~'||	
TOT_BILAN_RETRAITE	||'~'||	
CA_IFRS			||'~'||	
RES_NET_RETRAITE_SIGN	||'~'||	
RES_NET_RETRAITE_MNT	||'~'||	 	  	  	  	
NOTE_APR_CORR_GRPE	||'~'||
to_char(DT_CHG_SEG_POSSIBLE, 'YYYYMMDD')	||'~'||		-- CDS ATOS - 20161103
CD_SEGMENT_CAL_POSSIBLE	||'~'||							-- CDS ATOS - 20161103
to_char(DT_FIN_VALID_CTG, 'YYYYMMDD')||'~'||			-- CDS ATOS - 20161103
TOP_CHGT_PORTEFEU||'~'||										-- CDS ATOS (VLE) - 12/09/2017 - Mantis 38693
EFFECTIF -- 31/05/2018 CDS ATOS (LFD) ANACREDIT US346
--28/02/2019 - CDS ATOS (SQN) - US 587
||'~'||CD_SEXE
||'~'||to_char(DT_NAISS, 'YYYYMMDD')
||'~'||CD_PAYS_NAISS
||'~'||CD_DPT_NAISS
||'~'||CD_COMM_NAISS
||'~'||LIB_COMM_NAISS
--Fin SQN
-- Debut ajouts projet BHL (Partie Tiers) CDS ATOS (ODL).
||'~'||CD_DIRIGEANT
||'~'||ID_FONCTION
||'~'||to_char(DT_DIRIG_ENTR, 'YYYYMMDD')
||'~'||CLE_BDF_DIRIG
||'~'||NOM_PATRO_DIRIG
||'~'||PRENOM_DIRIG
||'~'||to_char(DT_NAISS_DIRIG, 'YYYYMMDD')
||'~'||CD_COMMUNE_DIRIG
||'~'||to_char(DT_CREAT_ENTR, 'YYYYMMDD')
||'~'||NUM_ORDRE_DIRIG
||'~'||CD_TYP_DIRIG
||'~'||CD_TYPE_ETAB
-- Fin ajouts projet BHL (Partie Tiers).
||'~'||ID_TIE_SYS_INT -- 28/05/2021 - CDS ATOS (LFD) - Mantis 57336
||'~'||NUM_COMPTE -- KLx 10/03/2022 Mantis 61386
||'~'||CD_ETAB -- KLx 10/03/2022 Mantis 61386
||'~'||CD_GUICHET -- KLx 10/03/2022 Mantis 61386
||'~'||PAYS_RISQUE -- KLx 29/11/2022 Mantis 64347
||'~'||NOTE_PAYS_RISQUE -- KLx 29/11/2022 Mantis 64347
-- KLx 01/08/2022 Mantis 62593 - Ajout des colonnes LTBCE vers DDR
||'~'||EBITDA     
||'~'||EBITDA_PRVS      
||'~'||EQTY             
||'~'||EQTY_PRVS        
||'~'||LVRG             
||'~'||LVRG_PRVS        
||'~'||TTL_DBT          
||'~'||TTL_DBT_PRVS     
||'~'||DBT_SRVC_RT      
||'~'||DBT_SRVC_RT_12M  
from BTR_TIERS;
spool off;

--ne sert ? rien
SET linesize 125
spool $SORTIE/030_FLUX_2M_ENG_ECHEANCIER.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_TIERS_CALC||'~'||
ID_CENTRAL_TIERS||'~'||
ID_AUTORISATION||'~'||
ID_LIGNE_DET||'~'||
ID_ENGAGEMENT||'~'||
MNT_RISQUE_CRD||'~'||
CD_DEVISE_MNT_RISQ||'~'||
to_char(DT_MNT_RISQ, 'YYYYMMDD')||'~'||
A_EXTRAIRE
from ENG_ECHEANCIER;
spool off;

SET linesize 490
spool $SORTIE/030_FLUX_2M_A1_CRRV4_DEGRADE.txt
select
to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
CD_CONSO_CPT||'~'||
ID_ENGAGEMENT||'~'||
CD_CAP||'~'||
CD_PAYS_RESIDENCE||'~'||
CD_CONTREPARTIE ||'~'||
CD_CONSO_PART||'~'||
CD_QUAL_PART||'~'||
CD_ISIN||'~'||
NB_CONTREPARTIE||'~'||
CD_METHODO_BALE2||'~'||
CD_MOTEUR||'~'||
CD_NATURE_CPT||'~'||
CD_DEVISE||'~'||
CD_PORTEFEUILLE||'~'||
CD_NATURE_SSJ||'~'||
MNT_RWA||'~'||
CD_LFD||'~'||
MATURITE_RES||'~'|| 
CD_ENG_DTX||'~'||
CD_PASSAGE_DEF||'~'||
CD_DUREE||'~'||
TX_POND_EXPO||'~'||
TX_CCF||'~'||
CD_PCCO1||'~'||
MNT_PCCO1||'~'||
CD_PCCO2||'~'||
MNT_PCCO2||'~'||
MNT_ASSIETTE||'~'||
CD_CONSO_ENG||'~'||
CD_USAGE_BIEN_IMM||'~'||
CD_RESPECT_COND ||'~'||
MNT_VTR_PDR ||'~'||
MNT_HYPOTHEQUE||'~'||
CD_ACHAT_FIN_LOC||'~'||
MNT_VR||'~'||
CD_CAP_SURETE||'~'||
CD_PAYS_SURETE||'~'||
CD_DEPOT_SUR ||'~'||
CD_CONSO_SUR||'~'||
CD_NATURE_SUR||'~'||
CD_FOUR_SUR||'~'||
CD_FAMILLE_SUR||'~'||
CD_PCCO3||'~'||
MNT_PCCO3||'~'||
CD_VALO_BIEN ||'~'||
CD_PCCO4||'~'||
MNT_PCCO4||'~'||
CD_NATURE_PROV||'~'||
CD_PCCO5||'~'||
MNT_PCCO5||'~'||
CD_NATURE_DECO||'~'||
to_char(DT_SAISIE, 'YYYYMMDD')||'~'||       
CD_USER||'~'||
CD_STATUT_LIGNE
--CDS_ATOS (MNE) - 12/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
||'~'||CD_TYPE_PROD_BANCAIRE
--FIN MNE
From A1_CRRV4_DEGRADE
Where CD_STATUT_LIGNE = 'V'
and DT_ARRETE = (select max(dt_arrete) from BTR_OPERATION);
Spool off;



SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_APE_NAF.txt
select
CD_APE||'~'||
LIB_ACTIVITE
from RS_APE_NAF;
spool off;

SET linesize 46
spool $SORTIE/030_FLUX_2M_RS_CANAL_APPORT.txt
select
CD_CANAL_APPORT||'~'||
LIB_CANAL_APPORT
from RS_CANAL_APPORT;
spool off;

SET linesize 57
spool $SORTIE/030_FLUX_2M_RS_CATEG_CONTREPARTIE.txt
select
CD_CATEG_CONTREPARTIE||'~'||
LIB_CATEG_CONTREPARTIE
from RS_CATEG_CONTREPARTIE;
spool off;

SET linesize 104
spool $SORTIE/030_FLUX_2M_RS_CATEG_CPT.txt
select
CD_CATEG_CPT||'~'||
LIBELLE||'~'||
PRIORITE||'~'||
AUTORIS_TRICP||'~'||
N_MOIS_SUP_REVENTE
from RS_CATEG_CPT;
spool off;

SET linesize 67
spool $SORTIE/030_FLUX_2M_RS_CLASSE_CPT_ACT_IAS.txt
select
CD_CLASSE_COMPTABLE_IAS||'~'||
LIB_CLASSE_COMPTABLE_IAS
from RS_CLASSE_CPT_ACT_IAS;
spool off;

SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_CONFIRM_AUTORISATION.txt
select
CD_CONFIRM_AUTORISATION||'~'||
LIB_CONFIRM_AUTORISATION
from RS_CONFIRM_AUTORISATION;
spool off;

SET linesize 67
spool $SORTIE/030_FLUX_2M_RS_CONSOLIDATION_COMPTABLE.txt
select
CD_CONSOLIDATION_COMPTABLE||'~'||
LIB_CONSOLIDATION_COMPTABLE
from RS_CONSOLIDATION_COMPTABLE;
spool off;

SET linesize 8
spool $SORTIE/030_FLUX_2M_RS_CORRES_APE_AGE.txt
select
CD_APE||'~'||
CD_AGE_ECO
from RS_CORRES_APE_AGE;
spool off;

--AFR BTR 6.2 Fiablisation code naf : D?sabonnement de Start
--SET linesize 12
--spool $SORTIE/030_FLUX_2M_RS_CORRES_APE_SECT_ACT.txt
--select
--CD_APE||'~'||
--CD_SECTEUR_ACT
--from RS_CORRES_APE_SECT_ACT;
--spool off;
--

SET linesize 31
spool $SORTIE/030_FLUX_2M_RS_CORRES_CATEG_RISQ_INDIC_DTX.txt
select
CD_CATEG_RISQ||'~'||
CD_INDICATEUR_DOUTEUX||'~'||
PRIORITE
from RS_CORRES_CATEG_RISQ_INDIC_DTX;
spool off;

SET linesize 8
spool $SORTIE/030_FLUX_2M_RS_CORRES_CODE_TYPE_SGMT_BAL.txt
select
CD_SEGMENT||'~'||
CD_TYPE_SGMT
from RS_CORRES_CODE_TYPE_SGMT_BAL;
spool off;

SET linesize 12
spool $SORTIE/030_FLUX_2M_RS_CORRES_FAMILLE_ACT_TYPE_SUR.txt
select
CD_FAMILLE_ACT||'~'||
CD_TYPE_SURETE
from RS_CORRES_FAMILLE_ACT_TYPE_SUR;
spool off;

SET linesize 7
spool $SORTIE/030_FLUX_2M_RS_CORRES_FORM_JUR_CAL_CRRV3.txt
select
CD_FORM_JUR||'~'||
CD_FORM_JUR_CRRV3
from RS_CORRES_FORM_JUR_CAL_CRRV3;
spool off;

SET linesize 30
spool $SORTIE/030_FLUX_2M_RS_CORRES_FORM_JUR_CONTR_PART.txt
select
CD_FORM_JURI||'~'||
CD_CATE_CONTPART_DEF||'~'||
CD_CATE_CONTPART_1||'~'||
CD_CATE_CONTPART_2||'~'||
CD_CATE_CONTPART_3
from RS_CORRES_FORM_JUR_CONTR_PART;
spool off;

SET linesize 12
spool $SORTIE/030_FLUX_2M_RS_CORRES_NAF_CATEG_CONTR_PART.txt
select
CD_NAF_REV2||'~'||
CD_CATEG_CONTREPARTIE
from RS_CORRES_NAF_CATEG_CONTR_PART;
spool off;

SET linesize 13
spool $SORTIE/030_FLUX_2M_RS_CORRES_NAF_NORM_LOCAL_ACT.txt
select
CD_NAF_REV2||'~'||
CD_SECTEUR_ACTIVITE
from RS_CORRES_NAF_NORM_LOCAL_ACT;
spool off;

SET linesize 130 
spool $SORTIE/030_FLUX_2M_RS_CORRES_PCEC.txt
select
CD_PRODUIT||'~'||
CD_CATEG_CPT||'~'||
CD_STATUT_ACT||'~'||
CD_TYPE_CLI||'~'||
CD_PHASE||'~'||
CD_PCEC_CRD||'~'||
CD_PCEC_K_A||'~'||
CD_PCEC_I||'~'||
CD_PCEC_ICNE||'~'||
NATO_CRD||'~'||
NATO_K_A||'~'||
NATO_I||'~'||
NATO_ICNE||'~'||
NATO_CRD_PROV||'~'||
CD_PCEC_CRD_PROV||'~'||
NATO_CREANCE_PROV||'~'||
CD_PCEC_K_A_I_PROV
from RS_CORRES_PCEC;
spool off;

SET linesize 12
spool $SORTIE/030_FLUX_2M_RS_CORRES_PRD_FIN_TYP_RISQ_CRP.txt
select
CD_PRODUIT||'~'||
CD_TYP_RISQ_CORP
from RS_CORRES_PRD_FIN_TYP_RISQ_CRP;
spool off;

SET linesize 12
spool $SORTIE/030_FLUX_2M_RS_CORRES_PRD_FIN_TYP_RISQ_RET.txt
select
CD_PRODUIT||'~'||
CD_TYP_RISQ_RET
from RS_CORRES_PRD_FIN_TYP_RISQ_RET;
spool off;

SET linesize 7
spool $SORTIE/030_FLUX_2M_RS_CORRES_SGMT_BAL_CAL_CASA.txt
select
CD_SEGMENT_CAL||'~'||
CD_SEGMENT_CASA
from RS_CORRES_SGMT_BAL_CAL_CASA;
spool off;

SET linesize 5
spool $SORTIE/030_FLUX_2M_RS_CORRES_SGMT_BAL_METH_VALOR.txt
select
CD_SEGMENT_CAL||'~'||
CD_METHODE_VALORIS_BIEN
from RS_CORRES_SGMT_BAL_METH_VALOR;
spool off;

SET linesize 19
spool $SORTIE/030_FLUX_2M_RS_CORRES_SGMT_BAL_TYPE_CLI.txt
select
CD_SEGMENT_CAL||'~'||
CD_TYPE_CLI
from RS_CORRES_SGMT_BAL_TYPE_CLI;
spool off;

SET linesize 7
spool $SORTIE/030_FLUX_2M_RS_CORRES_TYP_ACCEP_HIERA_ACCO.txt
select
CD_TYPE_ACCEPTANT||'~'||
CD_HIERARCHIE_ACCORD
from RS_CORRES_TYP_ACCEP_HIERA_ACCO;
spool off;

SET linesize 18
spool $SORTIE/030_FLUX_2M_RS_CORRES_TYPE_SUR_GARANT.txt
select
CD_TYPE_SURETE||'~'||
TOP_ASSUREUR||'~'||
TOP_GARANT||'~'||
TOP_DEPOSITAIRE||'~'||
TOP_PROPRIETAIRE||'~'||
TOP_CLIENT
from RS_CORRES_TYPE_SUR_GARANT;
spool off;

SET linesize 60
spool $SORTIE/030_FLUX_2M_RS_DEVISES.txt
select
CD_DEVISE||'~'||
NB_DEC||'~'||
LIB_DEVISE
from RS_DEVISES;
spool off;

SET linesize 36
spool $SORTIE/030_FLUX_2M_RS_FAMILLE_ACTIF.txt
select
CD_FAMILLE_ACT||'~'||
LIB_FAMILLE_ACT
from RS_FAMILLE_ACTIF;
spool off;

SET linesize 64
spool $SORTIE/030_FLUX_2M_RS_FILIERE.txt
select
CD_FILIERE||'~'||
LIB_FILIERE
from RS_FILIERE;
spool off;

SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_FORME_JURIDIQUE.txt
select
CD_FORM_JUR||'~'||
LIB_FORM_JUR
from RS_FORME_JURIDIQUE;
spool off;

SET linesize 143
spool $SORTIE/030_FLUX_2M_RS_FORME_JURIDIQUE_CRRV3.txt
select
CD_FORME_JURI||'~'||
LIB_FORME_JURI
from RS_FORME_JURIDIQUE_CRRV3;
spool off;

SET linesize 64
spool $SORTIE/030_FLUX_2M_RS_HIERARCHIE_ACCORD.txt
select
CD_HIERARCHIE_ACCORD||'~'||
LIB_HIERARCHIE_ACCORD
from RS_HIERARCHIE_ACCORD;
spool off;

SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_INDICATEUR_DOUTEUX.txt
select
CD_INDICATEUR_DOUTEUX||'~'||
LIB_INDICATEUR_DOUTEUX
from RS_INDICATEUR_DOUTEUX;
spool off;

SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_LIQUIDITE_ENGAGEMENT.txt
select
CD_LIQUIDITE_ENGAGEMENT||'~'||
LIB_LIQUIDITE_ENGAGEMENT
from RS_LIQUIDITE_ENGAGEMENT;
spool off;

SET linesize 82
spool $SORTIE/030_FLUX_2M_RS_MATERIEL_NAF.txt
select
CD_MATERIEL_NAF||'~'||
LIB_MATERIEL_NAF||'~'||
CD_FAMILLE_ACT||'~'||
--CD_CLASSE_STAND_RISQ||'~'|| -- AGU 18/11/2010 Lot V5.4 Safire suppression classe standard risque
NOTE_LIXXBAIL
from RS_MATERIEL_NAF;
spool off;

SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_METHODE_BAL2_VALORIS_BIEN.txt
select
CD_METHODE_VALORIS_BIEN||'~'||
LIB_METHODE_VALORIS_BIEN
from RS_METHODE_BAL2_VALORIS_BIEN;
spool off;

SET linesize 67
spool $SORTIE/030_FLUX_2M_RS_METHODE_NOTATION.txt
select
CD_METHODE_NOTATION||'~'||
LIB_METHODE_NOTATION
from RS_METHODE_NOTATION;
spool off;

SET linesize 67
spool $SORTIE/030_FLUX_2M_RS_MOTIF_NOTATION.txt
select
CD_MOTIF_NOTATION||'~'||
LIB_MOTIF_NOTATION
from RS_MOTIF_NOTATION;
spool off;

SET linesize 127
spool $SORTIE/030_FLUX_2M_RS_NAF_REV2.txt
select
CD_NAF_REV2||'~'||
LIB_NAF_REV2
from RS_NAF_REV2;
spool off;

SET linesize 65
spool $SORTIE/030_FLUX_2M_RS_NIVEAU_SENIORITE.txt
select
CD_NIVEAU_SENIORITE||'~'||
LIB_NIVEAU_SENIORITE
from RS_NIVEAU_SENIORITE;
spool off;

SET linesize 74
spool $SORTIE/030_FLUX_2M_RS_NORME_LOCALE_ACTIVITE.txt
select
CD_NORME_LOCALE_ACT||'~'||
LIB_COURT_NORME_LOCALE_ACT||'~'||
LIB_LONG_NORME_LOCALE_ACT
from RS_NORME_LOCALE_ACTIVITE;
spool off;

SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_NOTATION_INTERNE.txt
select
CD_INDX_NOTATION_INTERNE||'~'||
CD_NIV_NOTATION_INTERNE||'~'||
LIB_NIV_NOTATION_INTERNE
from RS_NOTATION_INTERNE;
spool off;

SET linesize 64
spool $SORTIE/030_FLUX_2M_RS_OBJET_CREDIT.txt
select
CD_OBJET_CREDIT||'~'||
LIB_OBJET_CREDIT
from RS_OBJET_CREDIT;
spool off;

SET linesize 64
spool $SORTIE/030_FLUX_2M_RS_PAYS.txt
select
CD_PAYS||'~'||
LIB_PAYS
from RS_PAYS;
spool off;

SET linesize 146
spool $SORTIE/030_FLUX_2M_RS_PROD_FINANC.txt
select
CD_PRODUIT||'~'||
LIB_PRODUIT||'~'||
CD_TYP_PROD_BAFI||'~'||
MATURITE_ENG_HB
from RS_PROD_FINANC;
spool off;

SET linesize 75
spool $SORTIE/030_FLUX_2M_RS_REF_IDENT_NATIONALE.txt
select
CD_REF_IDENT_NATIONALE||'~'||
LIB_COURT_REF_IDENT_NATIONALE||'~'||
LIB_LONG_REF_IDENT_NATIONALE
from RS_REF_IDENT_NATIONALE;
spool off;

SET linesize 58
spool $SORTIE/030_FLUX_2M_RS_SECTEUR_ACTIVITE.txt
select
CD_SECTEUR_ACTIVITE||'~'||
LIB_SECTEUR_ACTIVITE
from RS_SECTEUR_ACTIVITE;
spool off;

SET linesize 104
spool $SORTIE/030_FLUX_2M_RS_SEGMENT_BAL_CAL.txt
select
CD_SEGMENT||'~'||
LIB_SEGMENT
from RS_SEGMENT_BAL_CAL;
spool off;

SET linesize 45
spool $SORTIE/030_FLUX_2M_RS_SEGMENT_BAL_CASA.txt
select
CD_SEGMENT||'~'||
LIB_SEGMENT
from RS_SEGMENT_BAL_CASA;
spool off;

SET linesize 65
spool $SORTIE/030_FLUX_2M_RS_SEGMENT_BAL_CASA_OPERATION.txt
select
CD_SEGMENT_OPERATION||'~'||
LIB_SEGMENT_OPERATION
from RS_SEGMENT_BAL_CASA_OPERATION;
spool off;

SET linesize 60
spool $SORTIE/030_FLUX_2M_RS_SOCIETE_JURIDIQUE.txt
select
CD_SOC_JURI||'~'||
LIB_SOC_JURI||'~'||
CD_CONSO_CPT_CRRV3||'~'||
-- 12/12/2018 - CDS ATOS (LFD) - ANACREDIT US 570
' '||'~'||
' '||'~'||
' '||'~'||
' '||'~'||
' '||'~'||
' '||'~'||
' '||'~'||
BIC_11||'~'||
BIC_8
-- FIN LFD
from RS_SOCIETE_JURIDIQUE;
spool off;

SET linesize 97
spool $SORTIE/030_FLUX_2M_RS_SOC_JURI_CRISQUE.txt
select
CD_START||'~'||
CD_SOC_JURI||'~'||
LIB_SOC_JURI||'~'||
CD_PRODUIT||'~'||
CD_SOC_BDF||'~'||
CD_GUICHET||'~'||
CD_METIER_PORTAIL
from RS_SOC_JURI_CRISQUE;
spool off;

SET linesize 52
spool $SORTIE/030_FLUX_2M_RS_STATUT_OPE.txt
select
CD_STATUT_OPE||'~'||
LIB_STATUT_OPE||'~'||
CD_PHASE
from RS_STATUT_OPE;
spool off;

--DEBUT: KLxRisqLeasing (BAL) - M63356: CRD en date de resiliation (Reporting Risques NME)
--linesize 108 + 1 = 109 + 2 (MAX_PERIODE) = 111
SET linesize 111 
spool $SORTIE/030_FLUX_2M_RS_STATUT_RISQ_OPE.txt
	select
	  LIBELLE 			     ||'~'||
	  CD_STATUT_RISQ_OPE ||'~'||
	  PRIORITE			     ||'~'||
	  CD_SRA_PATRIC		   ||'~'||
    MAX_PERIODE 		   ||'~'||
	  FLAG_OPE_RESIL
	from RS_STATUT_RISQ_OPE;
spool off;
--FIN: KLxRisqLeasing (BAL) - M63356: CRD en date de resiliation (Reporting Risques NME)

SET linesize 80
spool $SORTIE/030_FLUX_2M_RS_STATUT_RISQ_TIE.txt
select
CD_STATUT_RISQ_TIE||'~'||
LIBELLE||'~'||
PRIORITE
from RS_STATUT_RISQ_TIE;
spool off;

SET linesize 57
spool $SORTIE/030_FLUX_2M_RS_TYPE_ACCEPTANT.txt
select
CD_TYPE_ACCEPTANT||'~'||
LIB_TYPE_ACCEPTANT
from RS_TYPE_ACCEPTANT;
spool off;

SET linesize 122
spool $SORTIE/030_FLUX_2M_RS_TYPE_GARANTIE.txt
select
ID_TYPE_GARANTIE||'~'||
LIB_TYPE_GARANTIE||'~'||
CD_QUAL_TYPE_GARANTIE||'~'||
ID_FAMILLE_GARANTIE||'~'||
CD_ENG_SIRIS||'~'||
CD_GARANTIE_PATRICK||'~'||
F_GARANTIE_VR||'~'||
F_FIABILISATION||'~'||
ID_TYPE_GARANTIE_CASA||'~'||
CD_SURFI||'~'||
PRIORITE_SURFI||'~'||
FLAG_PREM_QUALITE||'~'||
COEF_MODERATION||'~'||
CD_TYPE_M1||'~'||
CD_NATOP_CPT
from RS_TYPE_GARANTIE;
spool off;

SET linesize 64
spool $SORTIE/030_FLUX_2M_RS_TYPE_OPERATION.txt
select
CD_TYPE_OPERATION||'~'||
LIB_TYPE_OPERATION
from RS_TYPE_OPERATION;
spool off;

SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_TYPE_RELATION_TIE.txt
select
CD_TYPE_RELATION||'~'||
LIB_TYPE_RELATION
from RS_TYPE_RELATION_TIE;
spool off;

SET linesize 199
spool $SORTIE/030_FLUX_2M_RS_TYPE_RISQUE.txt
select
CD_CATEG_ELEM_RISQUE||'~'||
LIB_CATEG_ELEM_RISQUE||'~'||
CD_CATEG_RISQUE||'~'||
LIB_CATEG_RISQUE||'~'||
CD_FAMILLE_RISQUE||'~'||
LIB_FAMILLE_RISQUE
from RS_TYPE_RISQUE;
spool off;

SET linesize 16
spool $SORTIE/030_FLUX_2M_RS_TYPE_SGMT_BAL.txt
select
CD_TYPE_SGMT||'~'||
LIB_TYPE_SGMT
from RS_TYPE_SGMT_BAL;
spool off;

SET linesize 201
spool $SORTIE/030_FLUX_2M_RS_TYPE_SURETE_JURI.txt
select
CD_CATEG_ELEM_SURETE||'~'||
LIB_CATEG_ELEM_SURETE||'~'||
CD_CATEG_SURETE||'~'||
LIB_CATEG_SURETE||'~'||
CD_FAMILLE_SURETE||'~'||
LIB_FAMILLE_SURETE
from RS_TYPE_SURETE_JURI;
spool off;

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_ANCIENNETE_ACT_CBI.txt
select
CD_ANCIENNETE_ACTIF||'~'||
LIB_ANCIENNETE_ACTIF
from RS_ANCIENNETE_ACT_CBI;
spool off;

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_CATEGORIE_HOTEL.txt
select
CD_CATEG_HOTEL||'~'||
LIB_CATEG_HOTEL
from RS_CATEGORIE_HOTEL;
spool off;

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_COPROPRIETE_ACT_CBI.txt
select
CD_TYPE_COPROPRIETE||'~'||
LIB_TYPE_COPROPRIETE
from RS_COPROPRIETE_ACT_CBI;
spool off;

-- lot 5.1
--SET linesize 66 -> 98 -> 100
-- KLX Risque Mantis 62593 - Ajout donnees LTBCE augmentation taille du linesize 66 + 32 = 98 
-- M67050 : 98 + 2 caracteres ( separateurs )
-- BALE 4 : 98 + 4 caracteres ( separateurs )
SET linesize 102
spool $SORTIE/030_FLUX_2M_RS_FAMILLE_IMMEUBLE.txt
select
  CD_FAMILLE_IMM  ||'~'||
  LIB_FAMILLE_IMM ||'~'||
  LTBCE_MN_PRPS   ||'~'|| 
  LIB_LTBCE_MN_PRPS ||'~'|| 
  CD_TYPE_BIEN_COMM
from RS_FAMILLE_IMMEUBLE;
spool off;

--DEBUT :: KLx_Risques (BAL) :: Projet VTR CBI :: US48 (CDS ATOS - GBD)
set linesize 74
spool $SORTIE/030_FLUX_2M_RS_ORIG_VALO_ACT_CBI.txt
  select
    CD_ORIGINE_VALORISATION   ||'~'||
    LIB_ORIGINE_VALORISATION  ||'~'||
    CD_METHODO_VALORISATION	  ||'~'|| --AFR le 13/807/12 BTR 6.3 ajout provisions dans CRRV3
    FLAG_EXPERT               ||'~'||
    TYPE_CALCUL               
  from RS_ORIG_VALO_ACT_CBI;
spool off;
--FIN :: KLx_Risques (BAL) :: Projet VTR CBI :: US48 (CDS ATOS - GBD)

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_SITUATION_GEO_N1.txt
select
CD_SIT_GEO_N1||'~'||
LIB_SIT_GEO_N1
from RS_SITUATION_GEO_N1;
spool off;

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_SITUATION_GEO_N2.txt
select
CD_SIT_GEO_N2||'~'||
LIB_SIT_GEO_N2
from RS_SITUATION_GEO_N2;
spool off;

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_TYPOLOGIE_COMMERCE.txt
select
CD_TYPOLOGIE_COMMERCE||'~'||
LIB_TYPOLOGIE_COMMERCE
from RS_TYPOLOGIE_COMMERCE;
spool off;

-- lot 5.1
SET linesize 66
spool $SORTIE/030_FLUX_2M_RS_TYPOLOGIE_ENTREPOT.txt
select
CD_TYPO_ENTREPOT||'~'||
LIB_TYPO_ENTREPOT
from RS_TYPOLOGIE_ENTREPOT;
spool off;

-- lot 5.1
SET linesize 88
spool $SORTIE/030_FLUX_2M_RE_COMMUNE.txt
select
CD_POSTAL||'~'||
LIB_COMMUNE||'~'||
CD_INSEE_COMMUNE||'~'||
INDIC_PARTICUL_DISTRIBUTION||'~'||
INDIC_BUREAU_DISTRIBUTEUR||'~'||
LIB_LIG_ACHEMINEMENT
from RE_COMMUNE;
spool off;

-- lot 5.1
SET linesize 13
spool $SORTIE/030_FLUX_2M_REF_CORRES_COMMUNE_N1_N2.txt
select
CD_POSTAL||'~'||
CD_SIT_GEO_N1||'~'||
CD_SIT_GEO_N2
from REF_CORRES_COMMUNE_N1_N2;
spool off;

-- lot 5.1
SET linesize 63
spool $SORTIE/030_FLUX_2M_RS_DRV.txt
select
CD_DRV||'~'||
LIB_DRV
from RS_DRV;
spool off;

SET linesize 19
spool $SORTIE/030_FLUX_2M_RS_CORRES_CONSO_TYP_RISQ_RET.txt
select
CD_CONSO_CPT ||'~'||
CD_TYPE_RISQUE_PART ||'~'||
CD_TYPE_RISQUE_AUTRES
from RS_CORRES_CONSO_TYP_RISQ_RET;
spool off;

-- Lot 5.3
SET linesize 45
spool $SORTIE/030_FLUX_2M_RS_FAMILLE_FRAIS.txt
select
CD_FAMILLE_FRAIS ||'~'||
LIB_FAMILLE_FRAIS
from RS_FAMILLE_FRAIS;
spool off;

-- Lot 5.3
SET linesize 54
spool $SORTIE/030_FLUX_2M_RS_TYPE_FRAIS.txt
select
CD_TYPE_FRAIS||'~'||
LIB_TYPE_FRAIS||'~'||
CD_FAMILLE_FRAIS||'~'||
TOP_INTEG_LGD_CT_CESSION||'~'||
TOP_INTEG_LGD_CT_RECOUV
from RS_TYPE_FRAIS;
spool off;

-- Lot 5.3
SET linesize 140
spool $SORTIE/030_FLUX_2M_PAR_SOC_JURI_CALC_LGD.txt
select
CD_SOC_JURI||'~'||
to_char(DT_DEB_AUDIT, 'YYYYMMDD')||'~'||
to_char(DT_FIN_AUDIT, 'YYYYMMDD')||'~'||
TX_SOC_CT_CESSION||'~'||
MT_SOC_CT_CENTRE_COUT_RECO||'~'||
MT_SOC_CT_MOY_RECO||'~'||
NB_OPERATIONS||'~'||
NB_OPE_DTX_DTCO||'~'||
MT_TOT_FRAIS_CESSION||'~'||
MT_TOT_FRAIS_RECOUV
from PAR_SOC_JURI_CALC_LGD;
spool off;

-- Lot 5.4
SET linesize 53
spool $SORTIE/030_FLUX_2M_RS_MOTIF_SGMT_BAL.txt
select
CD_MOTIF||'~'||
LIB_MOTIF
from RS_MOTIF_SGMT_BAL;
spool off;

-- FHL 7351 : Historisation RE_TRC et RE_TAUX_CONV_HB
SET linesize 24
spool $SORTIE/030_FLUX_2M_RE_TRC.txt
SELECT CD_SOC_JURI
||'~'||CD_STATUT_RISQ_OPE
||'~'||N_MOIS_ANCIENNETE_SRA
||'~'||TX_RECOUV_CLI
FROM RE_TRC;
spool off;

SET linesize 21
spool $SORTIE/030_FLUX_2M_RE_TAUX_CONV_HB.txt
SELECT CD_PRODUIT
||'~'||CD_SOC_JURI
||'~'||CD_CANAL_APPORT
||'~'||TX_CONV_HB     
FROM RE_TAUX_CONV_HB;
spool off;

-- Lot 5.5
SET linesize 9
spool $SORTIE/030_FLUX_2M_RS_CORRES_NOTE_RETA_BAL.txt
select
ID_NOTE_RETAIL||'~'||
ID_NOTE_BALOIS_RETAIL
from RS_CORRES_NOTE_RETA_BAL;
spool off;

-- Lot 6.1
SET linesize 65
spool $SORTIE/030_FLUX_2M_RS_TYPE_LIENS_GRPE.txt
select CD_TYPE_LIEN
||'~'||LIB_TYPE_LIEN 
||'~'||FLAG_ENVOI_CASA 
||'~'||FLAG_CONSOLIDATION
FROM  RS_TYPE_LIENS_GRPE;
spool off;

SET linesize 62
spool $SORTIE/030_FLUX_2M_RS_TYPE_GRPE.txt
select CD_GRPE
||'~'|| LIB_GRPE
FROM RS_TYPE_GRPE;
spool off;

SET linesize 50 -- LBL 24/11/2011 Lot 6.1
spool $SORTIE/030_FLUX_2M_RS_AGE.txt
select CD_AGE_ECO
||'~'|| LIBELLE
FROM RS_AGE;
spool off;

SET linesize 65 -- LBL 24/11/2011 Lot 6.1
spool $SORTIE/030_FLUX_2M_RS_FAMILLE_GARANTIE.txt
select ID_FAMILLE_GARANTIE
||'~'|| LIB_FAMILLE_GARANTIE
FROM RS_FAMILLE_GARANTIE;
spool off;

SET linesize 10 -- LBL 24/11/2011 Lot 6.1
spool $SORTIE/030_FLUX_2M_RS_LIEN_CANAL_DETAIL_APPORT.txt
select CD_RESEAU
||'~'|| CD_CANAL_APPORT
FROM RS_LIEN_CANAL_DETAIL_APPORT;
spool off;

SET linesize 800
spool $SORTIE/030_FLUX_2M_DDR_GRPE.txt
select  
distinct --05/04/19 CDS ATOS (EMM) Mantis 47318
GRP.REF_EXT_GRPE_CASA
||'~'|| GRP.REF_EXT_GRPE_CALF
||'~'|| GRP.NUM_EPHEMERE
||'~'|| GRP.NOM_GRPE
||'~'|| GRP.CD_RUN_GRPE
||'~'|| RBG.CD_CORRESP_RUN_GRPE
||'~'|| GRP.CD_SECT_ACT_GRPE
||'~'|| GRP.CD_CATEGORIE_PRINC
||'~'|| GRP.CD_FAMI_ACT_GRPE
||'~'|| GRP.CD_APE_GRPE
||'~'|| GRP.CD_PAYS_CTRL_GRPE
||'~'|| RBG.CD_METHODO_NOTE
||'~'|| RBG.NOTE_INTERNE_GRPE
||'~'|| TO_CHAR(RBG.DT_NOTE_INTERNE_GRPE, 'DD/MM/YY')
||'~'|| RBG.CD_GRILLE_NOTE
--09/05/2019 - CDS ATOS (SQN) - Mantis 47677
--||'~'|| GCA.MNT_CA
||'~'|| BTR_TIERS.MNT_CA_GRPE
--Fin SQN
||'~'|| '' --TO_CHAR(GCA.DT_ARRETE_COMPTE, 'DD/MM/YY')
||'~'|| DTG.NB_TIERS_ATTACHES
||'~'|| GRP.CD_STATUT_GRPE
||'~'|| TO_CHAR(GRP.DT_STATUT_GRPE, 'DD/MM/YY')
--||'~'|| GRP.FLAG_PRESENCE_ECU
||'~'|| (case when ECU.NUM_SIREN_ECU is not null then 'O' else 'N' end)  -- FLAG_PRESENCE_ECU
||'~'|| ECU.NUM_SIREN_ECU
||'~'|| ECU.NOM_TIERS_ECU
||'~'|| TO_CHAR(GRP.DT_REVISION_ECU, 'DD/MM/YY')
||'~'|| GRP.IDTCA_ECU
||'~'|| DTG.NOM_CERTIF_IMMAT_ECU
||'~'|| DTG.NOTE_INTERNE_ECU
||'~'|| TO_CHAR(DTG.DT_REVISION_NOTE_ECU, 'DD/MM/YY')
||'~'|| DTG.GRILLE_NOTATION_ECU
||'~'|| DTG.METHODO_NOTATION_ECU
||'~'|| DTG.MOTIF_NOTATION_ECU
||'~'|| DTG.CD_RUN_ECU
||'~'|| DTG.CD_STATUT_ACT_ECU
||'~'|| TO_CHAR(DTG.DT_MAJ_STATUT_ACT_ECU, 'DD/MM/YY')
||'~'|| NVL(RBG.TOP_DEFAUT, DTG.TOP_DEFAUT)
||'~'|| ECU.NOTATION_INTERNE
||'~'|| TO_CHAR(ECU.DT_NOTATION_INTERNE, 'DD/MM/YY')
FROM DDR_GROUPE        GRP
    ,DDR_REF_BALE_GRPE RBG
    ,DDR_DTG_GRPE      DTG
    /*,(select G.REF_EXT_GRPE_CALF -- 23/05/2025 SIRL-130-131-132-DAFNE 
            ,A.MNT_CA
            ,A.DT_ARRETE_COMPTE
      from DDR_GROUPE G
          ,DDR_GCA    A
      where (G.NUM_EPHEMERE      = A.ID_EPHEMERE     AND G.NUM_EPHEMERE      is not null)
         OR (G.REF_EXT_GRPE_CASA = A.ID_CENTRAL_GRPE AND G.REF_EXT_GRPE_CASA is not null)
     ) GCA*/
    ,(select MBR.REF_EXT_GRPE_CALF
            ,SRT.IDENT_NATIONAL num_siren_ecu
            ,SRT.NOM_TIERS      nom_tiers_ecu
            ,SRT.NOTATION_INTERNE notation_interne
            ,SRT.DT_NOTATION_INTERNE dt_notation_interne
      from ddr_liens_grpe     MBR
          ,SIRIS_RETOUR_TIERS SRT
      where MBR.CD_TYPE_LIEN_JURI   = 'ECU'
        and MBR.ID_TIERS_NATIONAL   = SRT.IDENT_NATIONAL
        and SRT.REF_IDENT_NATIONALE = '01'
     ) ECU
	 --09/05/2019 - CDS ATOS (SQN) - Mantis 47677
	 ,BTR_TIERS
	 --Fin SQN
WHERE GRP.REF_EXT_GRPE_CALF = RBG.REF_EXT_GRPE_CALF (+)
  --AND GRP.REF_EXT_GRPE_CALF = GCA.REF_EXT_GRPE_CALF (+)
  AND GRP.REF_EXT_GRPE_CALF = ECU.REF_EXT_GRPE_CALF (+)
  AND GRP.REF_EXT_GRPE_CASA = DTG.IDENT_CENTRAL_SI_CIBLE_GRPE (+)
  --09/05/2019 - CDS ATOS (SQN) - Mantis 47677
  AND GRP.REF_EXT_GRPE_CALF = BTR_TIERS.REF_EXT_GRPE_CALF (+)
  --Fin SQN
  AND GRP.CD_STATUT_GRPE    = 'ACT' -- les INAC en temporaire sont gardes pour traiter les mouvements recus par RT
  ;
spool off;
  
--AFR BTR 6.2  : Fiablisation code naf
SET linesize 11
spool $SORTIE/030_FLUX_2M_RS_CORRES_APE_NAF_REV_12.txt
select
CD_APE_REV1||'~'||
CD_APE_REV2
from RS_CORRES_APE_NAF_REV_12;
spool off;  

SET linesize 50 -- LBL 10/04/2012 Lot 6.2
spool $SORTIE/030_FLUX_2M_RS_VALO_INTERV_DTMEL.txt
select CD_INTERV_MEL
||'~'|| LIB_INTERV_MEL
||'~'|| BORNE_INF
||'~'|| BORNE_SUP
FROM RS_VALO_INTERV_DTMEL;
spool off;

SET linesize 50 -- LBL 10/04/2012 Lot 6.2
spool $SORTIE/030_FLUX_2M_RS_VALO_VTR_DEF.txt
select CD_TYPE_CBI
||'~'|| CD_INTERV_MEL
||'~'|| CD_FAMILLE_IMM
||'~'|| CD_SIT_GEO_N1
||'~'|| CD_SIT_GEO_N2
||'~'|| CD_ANC_CONTRAT
||'~'|| COEFF_VALO_R
||'~'|| COEFF_AJUST_MARCHE
||'~'|| CD_CODE_FORMULE
FROM RS_VALO_VTR_DEF;
spool off;

SET linesize 40 -- LBL 10/04/2012 Lot 6.2
spool $SORTIE/030_FLUX_2M_RS_VALO_ANC_CONTRAT.txt
select CD_ANC_CONTRAT
||'~'|| LIB_ANC_CONTRAT
||'~'|| BORNE_INF
||'~'|| BORNE_SUP
FROM RS_VALO_ANC_CONTRAT;
spool off;

SET linesize 150 -- LBL 20/04/2012 Lot 6.2
spool $SORTIE/030_FLUX_2M_RS_VALO_FORMUL_VTR.txt
select CD_CODE_FORMULE
||'~'|| LIB_FORMULE
FROM RS_VALO_FORMUL_VTR;
spool off;


SET linesize 134
spool $SORTIE/030_FLUX_2M_RS_TIE_COTATION.txt
select
ID_TYPE_COTATION||'~'||
NUM_ORDRE_COTATION||'~'||
ID_COTATION||'~'||
LIB_COTATION||'~'||
POURC_TX_PD
from RS_TIE_COTATION;
spool off;

SET linesize 430 -- LBL 29/11/2012 Lot 6.4
spool $SORTIE/030_FLUX_2M_RS_NAF_CATEG_CTPT_NM211.txt
select CD_MAXFOUR1
||'~'|| CD_NUMSEQ
||'~'|| CD_NUMREGL
||'~'|| CD_NUMLIGNE
||'~'|| CD_NUMEXCEP
||'~'|| CD_FILLER
||'~'|| TO_CHAR(DT_DEBVAL, 'YYYYMMDD')
||'~'|| TO_CHAR(DT_FINVAL, 'YYYYMMDD')
||'~'|| CD_INDICRES
||'~'|| CD_NBOCCUR
||'~'|| CD_APE_INF
||'~'|| CD_APE_SUP
||'~'|| CD_CAT_JUR_INF
||'~'|| CD_CAT_JUR_SUP
||'~'|| CD_NIV_CA_INF
||'~'|| CD_NIV_CA_SUP
||'~'|| CD_CATEG_CTPT_INF
||'~'|| CD_CATEG_CTPT_SUP
||'~'|| CD_EXCP_CAT_JUR_INF
||'~'|| CD_EXCP_CAT_JUR_SUP
||'~'|| CD_EXCP_NIV_CA_INF
||'~'|| CD_EXCP_NIV_CA_SUP
FROM RS_NAF_CATEG_CTPT_NM211;
spool off;

SET linesize 310 -- LBL 29/11/2012 Lot 6.4
spool $SORTIE/030_FLUX_2M_RS_CAT_JUR_CATEG_CTPT_NM212.txt
select CD_MAXFOUR1
||'~'|| CD_NUMSEQ
||'~'|| CD_NUMREGL
||'~'|| CD_NUMLIGNE
||'~'|| CD_NUMEXCEP
||'~'|| CD_FILLER
||'~'|| TO_CHAR(DT_DEBVAL, 'YYYYMMDD')
||'~'|| TO_CHAR(DT_FINVAL, 'YYYYMMDD')
||'~'|| CD_INDICRES
||'~'|| CD_NBOCCUR
||'~'|| CD_CAT_JUR_INF
||'~'|| CD_CAT_JUR_SUP
||'~'|| CD_NIV_CA_INF
||'~'|| CD_NIV_CA_SUP
||'~'|| CD_CATEG_CTPT_INF
||'~'|| CD_CATEG_CTPT_SUP
||'~'|| CD_EXCP_NIV_CA_INF
||'~'|| CD_EXCP_NIV_CA_SUP
FROM RS_CAT_JUR_CATEG_CTPT_NM212;
spool off;

SET linesize 45
spool $SORTIE/030_FLUX_2M_RS_CANAL_DISTRIB.txt
select
CD_CANAL_DISTRIB||'~'||
LIB_CANAL_DISTRIB
from RS_CANAL_DISTRIB;
spool off;

-- Release BaleII Defaut et Restructuration
-- Ajout colonne NB_MOIS_RET_SAIN table RS_MOTIF_SRA
-- CDS ATOS - GCN le 01/06/16
SET linesize 165
spool $SORTIE/030_FLUX_2M_RS_MOTIF_SRA.txt
select
CD_MOTIF_SRA||'~'||
LIB_MOTIF_SRA||'~'||
CD_PRIORITE||'~'||
NB_MOIS_RET_SAIN
from RS_MOTIF_SRA;
spool off;
-- CDS ATOS - FIN

SET linesize 160
spool $SORTIE/030_FLUX_2M_RS_MOTIF_SRT.txt
select
CD_MOTIF_SRT||'~'||
LIB_MOTIF_SRT||'~'||
CD_PRIORITE
from RS_MOTIF_SRT;
spool off;

SET linesize 160
spool $SORTIE/030_FLUX_2M_RS_MOTIF_SCO.txt
select
CD_MOTIF_SCO||'~'||
LIB_MOTIF_SCO||'~'||
CD_PRIORITE
from RS_MOTIF_SCO;
spool off;

SET linesize 160
spool $SORTIE/030_FLUX_2M_RE_SRA_DEFAUT.txt
select
SOLD_IMP_DT_EXIG||'~'||
SOLD_IMP_DT_EXIG_SM_RENEG||'~'||
DT_IMP_DT_EXIG||'~'||
RESULTAT||'~'||
RES_SI_MOTIF_RENEG
from RS_SRA_DEFAUT;
spool off;

SET linesize 160
spool $SORTIE/030_FLUX_2M_RS_COEF_VTR_CBI.txt
select
CD_SOC_JURI||'~'||
CD_FAMILLE_IMM||'~'||	
CD_SITU_GEO_1||'~'||
CD_SITU_GEO_2||'~'||
COEF_DOWNTURN_VTR
from RS_COEF_VTR_CBI;
spool off;

SET linesize 160
spool $SORTIE/030_FLUX_2M_RS_COEF_VTR_CBM.txt
select
NOTE_LIXXBAIL||'~'||
COEF_DOWNTURN_VTR
from RS_COEF_VTR_CBM;
spool off;

SET linesize 160
spool $SORTIE/030_FLUX_2M_RS_MOTIF_CATEG_CPT.txt
select
CD_MOTIF_CATEG||'~'||
LIB_MOTIF_CATEG||'~'||
CD_PRIORITE
from RS_MOTIF_CATEG_CPT;
spool off;

SET linesize 30
spool $SORTIE/030_FLUX_2M_RS_CORRES_FORM_JURI_SGMT_BAL.txt
select
CD_SEGMENT_CASA ||'~'||
CD_FORM_JUR ||'~'||
CD_SEGMENT_CAL ||'~'||
F_CAL_RUN
from RS_CORRES_FORM_JURI_SGMT_BAL;
spool off;

SET linesize 60
spool $SORTIE/030_FLUX_2M_RE_COEF_LGD.txt
select
CD_SOC_JURI||'~'||
CD_STATUT_SRA||'~'||
N_MOIS_ANC_SRA||'~'||
COEF_DOWNTURN_TRC||'~'||
COEF_CORR_VTR
FROM RE_COEF_LGD ;
spool off;

SET linesize 90
spool $SORTIE/030_FLUX_2M_RS_CORRES_SOC_JURI_METIER.txt
select
CD_METIER||'~'||
CD_SOC_JURI||'~'||
MNT_SEUIL
FROM RS_CORRES_SOC_JURI_METIER ;
spool off;

-- Le 17/07/2013 : Amelioration CRRV3 - lot 6.6.1 versionning nov 2013
SET linesize 20
spool $SORTIE/030_FLUX_2M_RS_METHO_BALE_SOC_SEG.txt
select
CD_SOC_JURI||'~'||
CD_SEGMENT||'~'||
CD_METHOD
FROM RS_METHO_BALE_SOC_SEG ;
spool off;

SET linesize 21
spool $SORTIE/030_FLUX_2M_RS_TAUX_CONV_HB_EAD.txt
SELECT CD_PRODUIT
||'~'||CD_SOC_JURI
||'~'||CD_CANAL_APPORT
||'~'||TX_CONV_HB     
FROM RS_TAUX_CONV_HB_EAD;
spool off;

-- Lot BTR_6.9 versionning d'octobre 2014 : Projet AQR
SET linesize 203
spool $SORTIE/030_FLUX_2M_RS_CATEG_RESTRUCTURATION.txt
select
CD_AQR||'~'||
LIB_AQR
FROM RS_CATEG_RESTRUCTURATION ;
spool off;

SET linesize 163
spool $SORTIE/030_FLUX_2M_RS_FOURNISSEUR_SURETE.txt
select CD_FOURNISSEUR_SURETE||'~'||
LIB_FOURNISSEUR_SURETE
FROM RS_FOURNISSEUR_SURETE;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_ETEND_SURETES.txt
select CODE_ETENDUE_SURETE||'~'||
LIB_ETENDUE_SURETE
FROM RS_ETEND_SURETES;
SPOOL OFF;

SET linesize 163 
spool $SORTIE/030_FLUX_2M_RS_FOURN_SURETES.txt
select CD_FOURNISSEUR_SURETE||'~'||
LIB_FOURNISSEUR_SURETE
FROM RS_FOURN_SURETES;
SPOOL OFF;

SET linesize 113 
spool $SORTIE/030_FLUX_2M_RS_ACTIF_PONDERATION.txt
select CODE_CAP||'~'||
LIB_CAP
FROM RS_ACTIF_PONDERATION;
SPOOL OFF;

SET linesize 113 
spool $SORTIE/030_FLUX_2M_RS_ACHAT_BIEN_FINLOC.txt
select CODE_ACHAT||'~'||
LIB_ACHAT
FROM RS_ACHAT_BIEN_FINLOC;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_CIRCUIT_DISTRIB.txt
select CODE_CIRCUIT_DISTRIBUTION||'~'||
LIB_CIRCUIT_DISTRIBUTION
FROM RS_CIRCUIT_DISTRIB;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_CALL_PUT.txt
select CODE_IND_CALL_PUT||'~'||
LIB_IND_CALL_PUT
FROM RS_CALL_PUT;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_CRC.txt
select CODE_CRC||'~'||
LIB_CRC
FROM RS_CRC;
SPOOL OFF;

SET linesize 113 
spool $SORTIE/030_FLUX_2M_RS_CLASS_ACTIF_POND_8.txt
select CODE_CAP||'~'||
LIB_CAP
FROM RS_CLASS_ACTIF_POND_8;
SPOOL OFF;

SET linesize 113 
spool $SORTIE/030_FLUX_2M_RS_CLASS_ACTIF_POND_0.txt
select CODE_CAP||'~'||
LIB_CAP
FROM RS_CLASS_ACTIF_POND_0;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_TYPE_SWAP.txt
select CODE_TYPE_SQWAP||'~'||
LIB_TYPE_SWAP
FROM RS_TYPE_SWAP;
SPOOL OFF;

SET linesize 63  
spool $SORTIE/030_FLUX_2M_RS_TYPE_RESTRUCT.txt
select CODE_TYPE_RESTRUCT||'~'||
LIB_TYPE_RESTRUCT
FROM RS_TYPE_RESTRUCT;
SPOOL OFF;


SET linesize 91 
spool $SORTIE/030_FLUX_2M_RS_TYPE_ACTEUR.txt
select CD_TYPE_ACTEUR||'~'||
LIB_TYPE_ACTEUR
FROM RS_TYPE_ACTEUR;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_TAUX_COUV_SURETES.txt
select CODE_IND_TX_COUV_SURETE||'~'||
LIB_INd_TX_COUV_SURETE
FROM RS_TAUX_COUV_SURETES;
SPOOL OFF;

SET linesize 102 
spool $SORTIE/030_FLUX_2M_RS_USAGE_BIEN_IMM.txt
SELECT CODE_USAGE_BIEN||'~'||
LIB_USAGE_BIEN
FROM RS_USAGE_BIEN_IMM;
SPOOL OFF;

SET linesize 62
spool $SORTIE/030_FLUX_2M_RS_TYPE_TAUX.txt
SELECT CODE_TYPE_TAUX||'~'||
LIB_TYPE_TAUX
FROM RS_TYPE_TAUX;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_TRT_PRUDENTIEL_TITRES.txt
SELECT CODE_TRAIT_PRUD_TITRE||'~'||
LIB_TRAIT_PRUD_TITRE
FROM RS_TRT_PRUDENTIEL_TITRES;
SPOOL OFF;

SET linesize 64
spool $SORTIE/030_FLUX_2M_RS_TYPE_DERIVE_CRED.txt
SELECT CODE_TYPE_DERIV_CREDIT||'~'||
LIB_TYPE_DERIV_CREDIT
FROM RS_TYPE_DERIVE_CRED;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_TRT_MOTEUR.txt
SELECT CODE_TRAIT_MOTEUR||'~'||
LIB_TRAIT_MOTEUR
FROM RS_TRT_MOTEUR;
SPOOL OFF;

SET linesize 67 
spool $SORTIE/030_FLUX_2M_RS_SECT_ACTIVITE.txt
SELECT CODE_SECT_ACTIVITE||'~'||
LIB_SECT_ACTIVITE
FROM RS_SECT_ACTIVITE;
SPOOL OFF;

SET linesize 113 
spool $SORTIE/030_FLUX_2M_RS_RUB_STATUTAIRE.txt
SELECT CODE_PCCO||'~'||
LIB_PCCO
FROM RS_RUB_STATUTAIRE;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_RISQ_PAYS_SORTIE.txt
SELECT CODE_SORTIE_RISQUE_PAYS||'~'||
LIB_SORTIE_RISQUE_PAYS
FROM RS_RISQ_PAYS_SORTIE;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_REVOLVING.txt
SELECT CODE_IND_REVOLVING||'~'||
LIB_IND_REVOLVING
FrOM RS_REVOLVING;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_RANG_SURETES.txt
SELECT CODE_ETENDUE_SURETE||'~'||
LIB_ETENDUE_SURETE
FROM RS_RANG_SURETES;
SPOOL OFF;

SET linesize 62
spool $SORTIE/030_FLUX_2M_RS_QUAL_CREDIT.txt
SELECT CODE_ECHELON_CREDIT||'~'||
LIB_ECHELON_CREDIT
FROM RS_QUAL_CREDIT;
SPOOL OFF;

SET linesize 112 
spool $SORTIE/030_FLUX_2M_RS_PORTEF_BALE_TIERS.txt
SELECT CODE_CAT_CTRPART||'~'||
LIB_CAT_CTRPART
FROM RS_PORTEF_BALE_TIERS;
SPOOL OFF;

SET linesize 103 
spool $SORTIE/030_FLUX_2M_RS_PRODUIT_POND_PREF.txt
SELECT CODE_PROD_POND||'~'||
LIB_PROD_POND
FROM RS_PRODUIT_POND_PREF;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_POSITION_TITRI.txt
SELECT CODE_POSITION_BANQUE||'~'||
LIB_POSITION_BANQUE
FROM RS_POSITION_TITRI;
SPOOL OFF;

SET linesize 62
spool $SORTIE/030_FLUX_2M_RS_PLAFOND_UTIL_SURETES.txt
SELECT CODE_IND_PLAF_SURETE||'~'||
LIB_IND_PLAF_SURETE
FROM RS_PLAFOND_UTIL_SURETES;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_PERIM_PROV.txt
SELECT CODE_PERIM_AFFECT_PROVI||'~'||
LIB_PERIM_AFFECT_PROVI
FROM RS_PERIM_PROV;
SPOOL OFF;

SET linesize 106 
spool $SORTIE/030_FLUX_2M_RS_PANIER_DEVISES.txt
SELECT CODE_PANIER_DEV||'~'||
LIB_PANIER_DEV
FROM RS_PANIER_DEVISES;
SPOOL OFF;

SET linesize 102 
spool $SORTIE/030_FLUX_2M_RS_OFFICE_NOTATION.txt
SELECT CODE_ORG_NOTATION||'~'||
LIB_ORG_NOTATION
FROM RS_OFFICE_NOTATION;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_OBJET_FINANC.txt
SELECT CODE_OBJET_FINANCE||'~'||
LIB_OBJET_FINANCE
FROM RS_OBJET_FINANC;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_NIVO_CONSANG.txt
SELECT CODE_NIV_CONSANGUINITE||'~'||
LIB_NIV_CONSANGUINITE
FROM RS_NIVO_CONSANG;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_NATURE_SS_JACENT.txt
SELECT CODE_NAT_SOUS_JACENT||'~'||
LIB_NAT_SOUS_JACENT
FROM RS_NATURE_SS_JACENT;
SPOOL OFF;

SET linesize 73 
spool $SORTIE/030_FLUX_2M_RS_NAT_OPER_LANG_COMM.txt
SELECT CODE_NATO||'~'||
LIB_NATO
FROM RS_NAT_OPER_LANG_COMM;
SPOOL OFF;

SET linesize 64 
spool $SORTIE/030_FLUX_2M_RS_NATURE_OPTION.txt
SELECT CODE_NATURE_OPTION||'~'||
LIB_NATURE_OPTION
FROM RS_NATURE_OPTION;
SPOOL OFF;

SET linesize 62
spool $SORTIE/030_FLUX_2M_RS_INTENT_GESTION.txt
SELECT CODE_INTENTION_GESTION||'~'||
LIB_INTENTION_GESTION
FROM RS_INTENT_GESTION;
SPOOL OFF;

SET linesize 64 
spool $SORTIE/030_FLUX_2M_RS_FAMILLE_SURETES.txt
SELECT CODE_FAMILLE_SURETE||'~'||
LIB_FAMILLE_SURETE
FROM RS_FAMILLE_SURETES;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_INSTRUM_FINANCIER.txt
SELECT CODE_INDICE_BOURSIER||'~'||
LIB_INDICE_BOURSIER
FROM RS_INSTRUM_FINANCIER;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_INDIC_PROVISION.txt
SELECT CODE_IND_PROVISION||'~'||
LIB_IND_PROVISION
FROM RS_INDIC_PROVISION;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_INDIC_MATURITE_RES.txt
SELECT CODE_MATURITE_RESIDUELLE||'~'||
LIB_MATURITE_RESIDUELLE
FROM RS_INDIC_MATURITE_RES;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_INDICE_BOURSIER.txt
SELECT CODE_INDICE_BOURSIER||'~'||
LIB_INDICE_BOURSIER
FROM RS_INDICE_BOURSIER;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_INDIC_LFD.txt
SELECT CODE_IND_LFD||'~'||
LIB_IND_LFD
FROM RS_INDIC_LFD;
SPOOL OFF;

SET linesize 102 
spool $SORTIE/030_FLUX_2M_RS_INDIC_GRANUL.txt
SELECT CODE_IND_GRANULARITE||'~'||
LIB_IND_GRANULARITE
FROM RS_INDIC_GRANUL;
SPOOL OFF;

SET linesize 102
spool $SORTIE/030_FLUX_2M_RS_INDIC_COMPENS_CENTR.txt
SELECT CODE_IND_COMPENSATION||'~'||
LIB_IND_COMPENSATION
FROM RS_INDIC_COMPENS_CENTR;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_INDIC_BILAN_HB.txt
SELECT CODE_IND_BILAN||'~'||
LIB_IND_BILAN
FROM RS_INDIC_BILAN_HB;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_FREQUENCE_VALORISAT.txt
SELECT CODE_FREQ_VALO_BIEN||'~'||
LIB_FREQ_VALO_BIEN
FROM RS_FREQUENCE_VALORISAT;
SPOOL OFF;

SET linesize 63 
spool $SORTIE/030_FLUX_2M_RS_NAT_OPCVM_GARANTI.txt
SELECT CODE_NAT_OPCVM_GAR||'~'||
LIB_NAT_OPCVM_GAR
FROM RS_NAT_OPCVM_GARANTI;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_LIEU_DEPOT_SURETES.txt
SELECT CODE_LIEU_DEPOT_SUR||'~'||
LIB_LIEU_DEPOT_SUR
FROM RS_LIEU_DEPOT_SURETES;
SPOOL OFF;

SET linesize 76 
spool $SORTIE/030_FLUX_2M_RS_MOD_TITRISATION.txt
SELECT CODE_MODE_TITRISATION||'~'||
LIB_MODE_TITRISATION
FROM RS_MOD_TITRISATION;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_MOD_RISQUE_VARIAT.txt
SELECT CODE_MOD_ASSIETTE_RISQUE||'~'||
LIB_MOD_ASSIETTE_RISQUE
FROM RS_MOD_RISQUE_VARIAT;
SPOOL OFF;

SET linesize 158 
spool $SORTIE/030_FLUX_2M_RS_METHODO_VAL_BALE2.txt
SELECT CODE_METH_BALE2_VALO||'~'||
LIB_METH_BALE2_VALO
FROM RS_METHODO_VAL_BALE2;
SPOOL OFF;

SET linesize 158 
spool $SORTIE/030_FLUX_2M_RS_METHOD_CALC_BALE.txt
SELECT CODE_METHOD_CALCUL_BALE||'~'||
LIB_METHOD_CALCUL_BALE
FROM RS_METHOD_CALC_BALE;
SPOOL OFF;

SET linesize 113 
spool $SORTIE/030_FLUX_2M_RS_METHODO_POND_TITRI.txt
SELECT CODE_METH_POND_TITRI||'~'||
LIB_METH_POND_TITRI
FROM RS_METHODO_POND_TITRI;
SPOOL OFF;

SET linesize 103 
spool $SORTIE/030_FLUX_2M_RS_MARCHE_COTATION.txt
SELECT CODE_MARCHE_COTATION||'~'||
LIB_MARCHE_COTATION
FROM RS_MARCHE_COTATION;
SPOOL OFF;

SET linesize 66 
spool $SORTIE/030_FLUX_2M_RS_LIGNE_METIER.txt
SELECT CODE_LIGNE_METIER||'~'||
LIB_LIGNE_METIER
FROM RS_LIGNE_METIER;
SPOOL OFF;

SET linesize 103 
spool $SORTIE/030_FLUX_2M_RS_CONTREP_POND_PREF.txt
SELECT CODE_CONTREPARTIE_PREF||'~'||
LIB_CONTREPARTIE_PREF
FROM RS_CONTREP_POND_PREF;
SPOOL OFF;

SET linesize 104 
spool $SORTIE/030_FLUX_2M_RS_PORTEF_BALE_OPE.txt
SELECT CODE_PTF_BAL_V8||'~'||
LIB_PTF_BAL_V8
FROM RS_PORTEF_BALE_OPE;
SPOOL OFF;

SET linesize 124 
spool $SORTIE/030_FLUX_2M_RS_UNITE_MESURE.txt
SELECT CODE_UNITE_MERSURE||'~'||
LIB_UNITE_MERSURE
FROM RS_UNITE_MESURE;
SPOOL OFF;

SET linesize 122 
spool $SORTIE/030_FLUX_2M_RS_INDIC_TRANSP_STRUCT.txt
SELECT CODE_INDIC_TRANSP||'~'||
LIB_INDIC_TRANSP
FROM RS_INDIC_TRANSP_STRUCT;
SPOOL OFF;

SET linesize 122 
spool $SORTIE/030_FLUX_2M_RS_POSITION_SYND.txt
SELECT CODE_POSIT_SYNDIC||'~'||
LIB_POSIT_SYNDIC
FROM RS_POSITION_SYND;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_NATURE_CA_GRPE.txt
SELECT CODE_NAT_CA_GRPE||'~'||
LIB_NAT_CA_GRPE
FROM RS_NATURE_CA_GRPE;
SPOOL OFF;

SET linesize 62 
spool $SORTIE/030_FLUX_2M_RS_NATURE_CA_TIERS.txt
SELECT CODE_NAT_CA_TIERS||'~'||
LIB_NAT_CA_TIERS
FROM RS_NATURE_CA_TIERS;
SPOOL OFF;

-- Release BaleII Defaut et Restructuration
-- Ajout spools pour tables RS_FLAG_DEFAUT, RS_FLAG_RESTRUCTURATION, RS_SOCIETE_DONNEES, RS_TYPE_EVT_TIE_PM
-- CDS ATOS - GCN le 01/06/16
SET linesize 70
spool $SORTIE/030_FLUX_2M_RS_FLAG_DEFAUT.txt
SELECT
CD_FLAG_DEFAUT||'~'||
LIBELLE_FLAG_DEFAUT
FROM RS_FLAG_DEFAUT;
SPOOL OFF;

SET linesize 70
spool $SORTIE/030_FLUX_2M_RS_FLAG_RESTRUCTURATION.txt
SELECT
CD_FLAG_RESTRUCTURATION ||'~'||
LIBELLE_FLAG_RESTRUCTURATION
FROM RS_FLAG_RESTRUCTURATION;
SPOOL OFF;

SET linesize 50
spool $SORTIE/030_FLUX_2M_RS_SOCIETE_DONNEES.txt
SELECT
CD_SYS_INT ||'~'||
CD_SOC_JURI||'~'||
CD_SOC_JURI_SYS_INT ||'~'|| 
LIB_SOC_GEST ||'~'|| 
NB_MOIS_LIT
FROM RS_SOCIETE_DONNEES;
SPOOL OFF;

SET linesize 65
spool $SORTIE/030_FLUX_2M_RS_TYPE_EVT_TIE_PM.txt
SELECT
CD_EVT_TIE_PM ||'~'||
LIB_EVT_TIE_PM ||'~'||
TOP_EVT_ENTREE_PCO ||'~'|| 
TOP_EVT_SORTIE_PCO 
FROM RS_TYPE_EVT_TIE_PM;
SPOOL OFF;
-- CDS ATOS - Fin

--CDS_ATOS (MNE) - 16/08/2021 - Mantis 58424 Obselescence ICG - suite de la mise e disposition de donnees dans le referentiel balois (HCRR)
 SET linesize 10
spool $SORTIE/030_FLUX_2M_RS_LIEN_CANAL_APPORT_DISTRIB.txt
SELECT
CD_CANAL_APPORT||'~'||
CD_CANAL_DISTRIB
FROM RS_LIEN_CANAL_APPORT_DISTRIB;
SPOOL OFF;

SET linesize 70
spool $SORTIE/030_FLUX_2M_RS_TYPE_PROD_FINANC.txt
SELECT
CD_TYPE_PRODUIT ||'~'||
LIB_TYPE_PRODUIT
FROM RS_TYPE_PROD_FINANC;
SPOOL OFF;

SET linesize 40
spool $SORTIE/030_FLUX_2M_RS_UNITE_PROD.txt
SELECT
CD_TYPE_UNITE_PROD ||'~'||
CD_UNITE_PROD||'~'||
LIB_UNITE_PROD 
FROM RS_UNITE_PROD;
SPOOL OFF;
--FIN MNE




-- Release BaleII Defaut et Restructuration
-- Ajout spool pour table RS_SEUIL_MATERIALITE_BALOIS
-- CDS ATOS - VLE le 22/07/16
SET linesize 70
spool $SORTIE/030_FLUX_2M_RS_SEUIL_MATERIALITE_BALOIS.txt
select
    CD_SOC_JURI||'~'||
    CD_TYPE_SGMT||'~'|| 
    SEUIL_POURCENTAGE ||'~'|| 
    MNT_SEUIL ||'~'|| 
    MAX_JOURS ||'~'|| 
    VAR_CALCUL 
from RS_SEUIL_MATERIALITE_BALOIS;
spool off;

-- Release BaleII Defaut et Restructuration
-- Ajout spool pour table HIS_BTR_SRA_TIE
-- CDS ATOS - VLE le 08/06/16
SET linesize 100 
spool $SORTIE/030_FLUX_2M_HIS_BTR_SRA_TIE.txt
select TO_CHAR(DT_ARRETE, 'YYYYMMDD') 
||'~'|| ID_TIE_RISQ
||'~'|| CD_SYS_INT
||'~'|| ID_OPERATION
||'~'|| CD_ROLE_TIE
||'~'|| SEQ_CD_ROLE_TIE
||'~'|| TO_CHAR(DT_DEBUT_VALID, 'YYYYMMDD')
||'~'|| CD_SRA_TIETHEO
||'~'|| CD_MOTIF_SRA_TIETHEO
||'~'|| TO_CHAR(DT_CHG_SRA_TIETHEO, 'YYYYMMDD')
FROM BTR_SRA_TIE
--25/04/19 CDS ATOS (EMM) Mantis 46918 
--where dt_arrete = (select max(dt_arrete) from DDREX.BTR_SRA_TIE)
;
SPOOL OFF;


--28/07/21 CDSATOS (EMM) Mantis 57385
SET linesize 50
spool $SORTIE/030_FLUX_2M_RS_CORRES_NOTE_PD.txt
select
NOTE||'~'||
PD_AUTRES||'~'||
PD_C1||'~'||
PD_PIM||'~'||
PD_LBO
from RS_CORRES_NOTE_PD;
spool off; 
--Fin EMM  

-- 27/05/2021 - CDS ATOS (LFD) - Mantis 57336
SET linesize 65 
spool $SORTIE/030_FLUX_2M_RS_CANAL_APPORT_DETAIL.txt
select CD_RESEAU  
  ||'~'||LIB_RESEAU
FROM RS_CANAL_APPORT_DETAIL
;
SPOOL OFF;


-- Debut KLx 10/03/2022 Mantis 61386
SET linesize 18 
spool $SORTIE/030_FLUX_2M_SIREN_EXCLUSION.txt
select 
  TO_CHAR(DT_ARRETE, 'YYYYMMDD')   
  ||'~'||SIREN
FROM SIREN_EXCLUSION
;
SPOOL OFF;
-- Fin KLx 10/03/2022 Mantis 61386


-- Debut KLx 19/07/2022 Mantis 62593 LTBCE
-- Linesize = 209 byte + 10 + 11 en plus, a verifier
SET linesize 230
spool $SORTIE/030_FLUX_2M_BTR_OPE_PARTENAIRE_POOL.txt
select 
  TO_CHAR(DT_ARRETE, 'YYYYMMDD') ||'~'||     
  ID_PARTENAIRE_POOL             ||'~'||
  CD_SYS_INT                     ||'~'||
  ID_OPERATION                   ||'~'||
  ID_TYPE_POOL                   ||'~'||
  QUOTE_PART_POOL                ||'~'|| -- De type FLOAT(126)  verifier comment il sort !
  MNT_VIVANT_FINANCMT            ||'~'|| -- De type NUMBER(16,2) verifier comment il sort !
  FLAG_CHEF_POOL                 ||'~'||
  SEQ_ID_PARTENAIRE_POOL         ||'~'|| -- De type NUMBER(10) verifier comment il sort !
  SEQ_ID_TYPE_POOL               ||'~'|| -- De type NUMBER(10) verifier comment il sort !
  TOP_ENG                
FROM BTR_OPE_PARTENAIRE_POOL
;
SPOOL OFF;
-- Linesize = 10 + 4 + 6 en plus
SET linesize 20
spool $SORTIE/030_FLUX_2M_RS_CORRES_METHODE_NOTATION.txt
select 
  CD_METHODE_NOTATION     ||'~'||
  TYPE_DE_METHODOLOGIE    
FROM RS_CORRES_METHODE_NOTATION
;
SPOOL OFF;
-- Fin KLx 19/07/2022 Mantis 62593 LTBCE
--DEBUT :: Projet VTR-CBI :: sous-chapitre 4.1.3 du SFG
set linesize 22
spool $SORTIE/030_FLUX_2M_RS_PARA_DONNEES_CBI.txt
  select
    CD_FAMILLE_IMM      ||'~'||
    SURFACE_ACT_CBI     ||'~'||
    CD_POSTAL           ||'~'||
    CD_TYPE_COPROPRIETE ||'~'||
    DT_DAT              ||'~'||
    CD_CATEG_HOTEL      ||'~'||
    N_NB_CHAMBRE        ||'~'||
    N_NB_LIT            ||'~'||
    CD_TYPO_COMMERCE    ||'~'||
    CD_TYPO_ENTREPOT
  from RS_PARA_DONNEES_CBI;
spool off;	
--FIN :: Projet VTR-CBI :: sous-chapitre 4.1.3 du SFG

-- RSE Taxonomie - Tables Start
SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_NATURE_DURABLE_ACTIF.txt
  SELECT 
    CD_INDNDA     ||'~'||
    LIB_INDDNA_FR	||'~'||
    LIB_INDDNA_EN
  FROM RS_NATURE_DURABLE_ACTIF;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_TYPE_RISQ_CLIMAT_ATTENUE.txt
  SELECT 
    CD_TYPRCA    	||'~'||
    LIB_TYPRCA_FR	||'~'||
    LIB_TYPRCA_EN
  FROM RS_TYPE_RISQ_CLIMAT_ATTENUE;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_IND_OBTENT_SURETE_SAISIE.txt
  SELECT 
    CD_IOBSPS   	  ||'~'||  
    LIB_IOBSPS_FR 	||'~'||
    LIB_IOBSPS_EN
  FROM RS_IND_OBTENT_SURETE_SAISIE;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_ELIGIB_FINANC_TAXO.txt
  SELECT 
    CD_IEFTAX     ||'~'||
    LIB_IEFTAX_FR ||'~'||
    LIB_IEFTAX_EN
  FROM RS_ELIGIB_FINANC_TAXO;
spool off;

SET linesize 150 
spool $SORTIE/030_FLUX_2M_RS_IND_FINANC_DEDIE.txt
  SELECT 
    CD_IFINDD   	||'~'||   
    LIB_IFINDD_FR 	||'~'||
    LIB_IFINDD_EN
  FROM RS_IND_FINANC_DEDIE;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_IND_FINANC_ALIGNE.txt
  SELECT 
    CD_IFINAL 	  ||'~'||	
    LIB_IFINAL_FR ||'~'||
    LIB_IFINAL_EN
  FROM RS_IND_FINANC_ALIGNE;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_OBJ_FINANC_TAXO.txt
  SELECT 
    CD_OBJFIT      ||'~'|| 
    LIB_OBJFIT_FR  ||'~'||
    LIB_OBJFIT_EN
  FROM RS_OBJ_FINANC_TAXO;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_CARBURANT_VEHIC.txt
  SELECT 
    CD_TYPECV     ||'~'|| 
    LIB_TYPECV_FR ||'~'|| 
    LIB_TYPECV_EN 
  FROM RS_CARBURANT_VEHIC;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_CATEG_VEHIC.txt
  SELECT 
    CD_CATVEH     ||'~'||
    LIB_CATVEH_FR ||'~'||
    LIB_CATVEH_EN
  FROM RS_CATEG_VEHIC;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_NORM_EMIS_CO2_VEHIC.txt
  SELECT 
    CD_NCCO2V      ||'~'||
    LIB_NCCO2V_FR  ||'~'||
    LIB_NCCO2V_EN
  FROM RS_NORM_EMIS_CO2_VEHIC;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_NORM_THERM_BIEN.txt
  SELECT 
    CD_NOTHBI      ||'~'||
    LIB_NOTHBI_FR  ||'~'||
    LIB_NOTHBI_EN
  FROM RS_NORM_THERM_BIEN;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_CLAS_GAZ_EFF_SER_BIEN.txt
  SELECT 
    CD_CLASENERG     ||'~'||
    LIB_CLASENERG_FR
  FROM RS_CLAS_GAZ_EFF_SER_BIEN;
spool off;

SET linesize 150
spool $SORTIE/030_FLUX_2M_RS_NAT_SERV_FOURNIS.txt
  SELECT 
    CD_NATDSF     ||'~'||
    LIB_NATDSF_FR ||'~'||
    LIB_NATDSF_EN
  FROM RS_NAT_SERV_FOURNIS;
spool off;

SET linesize 170
spool $SORTIE/030_FLUX_2M_RS_CODE_APPLI_BANK.txt
  SELECT 
    KVAPPBK   ||'~'||
    KVBAPPID  ||'~'||
    KVPLAFON  ||'~'||
    KVFLGFIA  ||'~'||
    KVLBCONS  ||'~'||
    KVLBGEST  ||'~'||
    KVLBCOMP  ||'~'||
    KVTRCRR   ||'~'||
    KVCODAPP  ||'~'||
    KVTCRIST  ||'~'||
    NMLIBFRA  ||'~'||
    KVCRRGLO  ||'~'||
    KVVERCRR
  FROM RS_CODE_APPLI_BANK;
spool off;

SET linesize 30
spool $SORTIE/030_FLUX_2M_REF_ACTIF_CBM.txt
SELECT
CD_MATERIEL_NAF
||'~'|| CD_FAMILLE_MAT
||'~'|| IND_NAT_DURABLE_ACTIF
||'~'|| OBJ_FINANCMT_TAXO
||'~'|| CD_CATEG_VEHICULE
||'~'|| CD_CATEG_BIEN         -- SIRL-177 - RSE LOT 3
FROM REF_ACTIF_CBM;
spool off;

SET linesize 127
spool $SORTIE/030_FLUX_2M_REF_CORRES_CARBUR_VEHIC_TAXO.txt
SELECT
CD_TYPECV_RSE     
||'~'|| CD_LIBECV_RSE
||'~'|| CD_TYPECV_EKIP
||'~'|| CD_LIBECV_EKIP
FROM REF_CORRES_CARBUR_VEHIC_TAXO
;
spool off;

SET linesize 9
spool $SORTIE/030_FLUX_2M_REF_CORRES_NORME_THERMIK.txt
SELECT
CD_NORME_THERM_RSE
||'~'|| CD_NORME_THERM_KSP  
FROM REF_CORRES_NORME_THERMIK;
spool off;

SET linesize 13
spool $SORTIE/030_FLUX_2M_REF_CORRES_NATURE_SOCIALE.txt
SELECT
CD_NATURE_INVEST
||'~'|| CD_NATURE_SOCIALE
FROM  REF_CORRES_NATURE_SOCIALE;
spool off;

SET linesize 71
spool $SORTIE/030_FLUX_2M_REF_CORRES_TYPINVEST_TYPFINANCMT.txt
SELECT
CD_TYPE_INVEST
||'~'|| LIB_TYPE_INVEST
||'~'|| CD_TYPE_FINANCEMENT
FROM  REF_CORRES_TYPINVEST_TYPFINANCMT;
spool off;

--RSE Lot3 - SIRL-177
SET linesize 7
spool $SORTIE/030_FLUX_2M_REF_CORRES_FORM_JUR_FIFI243.txt
SELECT
CD_FORM_JUR 
||'~'|| IND_NATURE_DURABLE
FROM  REF_CORRES_FORM_JUR_FIFI243;
spool off;

--4+1+4+1+4+1+2
SET linesize 17
spool $SORTIE/030_FLUX_2M_RS_CORRES_SIT_GEO_BIEN_COMM.txt
select
CD_FAMILLE_IMM  
 ||'~'||CD_SIT_GEO_N1   
 ||'~'||CD_SIT_GEO_N2 
 ||'~'||CD_EMPLACE_BIEN_COMM 
from RS_CORRES_SIT_GEO_BIEN_COMM;
spool off;

--6+1+5+1+23
SET linesize 36
spool $SORTIE/030_FLUX_2M_RS_NAT_OPE_TYPE_RISQ.txt
select
CD_TYPE_RISQUE  
 ||'~'||CD_NATURE_OPE   
 ||'~'||TX_HIST_POND_PARTICIPATION 
from RS_NAT_OPE_TYPE_RISQ;
spool off;

--DEBUT :: Projet VTR-CBI :: sous-chapitre 4.3.3 du SFG
set linesize 50
spool $SORTIE/030_FLUX_2M_BTR_GRILLE_CBRE.txt
  select
    CD_FAMILLE_IMM      	  ||'~'||
    CD_SIT_GEO_N1     		  ||'~'||
    CD_SIT_GEO_N2       	  ||'~'||
    CD_TYPE_COPROPRIETE 	  ||'~'||
    CD_ANCIENNETE_ACTIF 	  ||'~'||
    CD_CATEG_COMPLEMENTAIRE ||'~'||
    TX_PONDERATION_VTR      ||'~'||
    N_VALEUR_LOCATIVE		    ||'~'||
    TX_CAPITALISATION		    ||'~'||
    TO_CHAR(DT_DEBUT_EFFET
		   ,'YYYYMMDD')
  from BTR_GRILLE_CBRE;
spool off;
--FIN :: Projet VTR-CBI :: sous-chapitre 4.3.3 du SFG

--DEBUT :: Projet VTR-CBI :: sous-chapitre 4.11.3 du SFG
set linesize 630
spool $SORTIE/030_FLUX_2M_BTR_ACT_VALO_CBI.txt
  select
    CD_SYS_INT							             || '~' ||
    ID_ACTIF                             || '~' ||
    TO_CHAR(DT_ARRETE,'YYYYMMDD')        || '~' ||
    TYPE_CALCUL_CBRE_AJUST               || '~' ||
    TO_CHAR(DT_EXPE,'YYYYMMDD')          || '~' ||
    MNT_EXPE                             || '~' ||
    CD_ORIGINE_VALO_EXPE                 || '~' ||
    TO_CHAR(DT_OVNI,'YYYYMMDD')          || '~' ||
    MNT_OVNI                             || '~' ||
    ID_OVNI                              || '~' ||
    NOTE_OVNI                            || '~' ||
    TO_CHAR(DT_STATUT,'YYYYMMDD')        || '~' ||
    TX_DELTA                             || '~' ||
    MNT_CBRE_DT_ARRETE                   || '~' ||
    MNT_CBRE_DT_EXPE                     || '~' ||
    MNT_VV_CBRE_AJUST                    || '~' ||
    NUM_DEC                              || '~' ||
    INFO_MANQUANTES                      || '~' ||
    ID_OPERATION                         || '~' ||
    ID_TIE_RISQ                          || '~' ||
    CD_CATEG_CPT                         || '~' ||
    TO_CHAR(DT_CHG_CATEG_CPT,'YYYYMMDD') || '~' ||
    CRD_BRUT_ACT                         || '~' ||
    CD_FAMILLE_IMM                       || '~' ||
    FLAG_CARA_EXHO                       || '~' ||
    MNT_VV_ACT                           || '~' ||
    TO_CHAR(DT_ARRETE_J,'YYYYMMDD')      || '~' ||
    MNT_VV_ACT_FS                        || '~' ||
    MNT_VV_ACT_ESTIME                    || '~' ||
    MNT_VV_ACT_DCT                       || '~' ||
    VAL_DECOTE_VTR                       || '~' ||
    FLAG_NUM_OVNI                        || '~' ||
    CD_ORIGINE_VALO_VTR                  || '~' ||
    TO_CHAR(DT_VALO_VTR,'YYYYMMDD')      || '~' ||
    MNT_BRUT_ORIGINE
  from BTR_ACT_VALO_CBI;
spool off;
--FIN :: Projet VTR-CBI :: sous-chapitre 4.11.3 du SFG

--Bale4
set linesize 63
spool $SORTIE/030_FLUX_2M_RS_STATUT_MORATOIRE.txt
  select
    STATUT_MRTR      	  ||'~'||
    LIB_STATUT_MRTR     		  
  from RS_STATUT_MORATOIRE;
spool off;

set linesize 63
spool $SORTIE/030_FLUX_2M_RS_MOTIF_MORATOIRE.txt
  select
    MOTIF_MRTR      	  ||'~'||
    LIB_MOTIF_MRTR     		  
  from RS_MOTIF_MORATOIRE;
spool off;

set linesize 62
spool $SORTIE/030_FLUX_2M_RS_NIV_RISQUE_CRR3.txt
  select
    NIV_RISQUE_CRR3      	  ||'~'||
    LIB_NIV_RISQUE_CRR3     		  
  from RS_NIV_RISQUE_CRR3;
spool off;

set linesize 63
spool $SORTIE/030_FLUX_2M_RS_IND_CONF_CRIT_OPE.txt
  select
    IND_CONF_CRIT_OPE      	  ||'~'||
    LIB_IND_CONF_CRIT_OPE     		  
  from RS_IND_CONF_CRIT_OPE;
spool off;

set linesize 63
spool $SORTIE/030_FLUX_2M_RS_APPLICATION_MORATOIRE.txt
  select
    CHAMP_APPL_MRTR      	  ||'~'||
    LIB_CHAMP_APPL_MRTR     		  
  from RS_APPLICATION_MORATOIRE;
spool off;

set linesize 62
spool $SORTIE/030_FLUX_2M_RS_IND_MORATOIRE_CONTRACTUEL.txt
  select
    IND_MRTR_CONTRACTUEL      	  ||'~'||
    LIB_IND_MRTR_CONTRACTUEL     		  
  from RS_IND_MORATOIRE_CONTRACTUEL;
spool off;

set linesize 42
spool $SORTIE/030_FLUX_2M_RS_IND_MORATOIRE_LEGISTALIF.txt
  select
    IND_MRTR_LEGISLATIF      	  ||'~'||
    LIB_IND_MRTR_LEGISLATIF     		  
  from RS_IND_MORATOIRE_LEGISTALIF;
spool off;

set linesize 62
spool $SORTIE/030_FLUX_2M_RS_USAGE_BIEN_IMMOBILIER.txt
  select
    USAGE_BIEN_FINANCE      	  ||'~'||
    LIB_USAGE_BIEN_FINANCE     		  
  from RS_USAGE_BIEN_IMMOBILIER;
spool off;

set linesize 62
spool $SORTIE/030_FLUX_2M_RS_EMPLACEMENT_BIEN_COMMERCIAL.txt
  select
    CD_EMPLACE_BIEN_COMM      	  ||'~'||
    LIB_EMPLACE_BIEN_COMM     		  
  from RS_EMPLACEMENT_BIEN_COMMERCIAL;
spool off;

set linesize 63
spool $SORTIE/030_FLUX_2M_RS_TYPE_BIEN_COMMERCIAL.txt
  select
    CD_TYPE_BIEN_COMM      	  ||'~'||
    LIB_TYPE_BIEN_COMM     		  
  from RS_TYPE_BIEN_COMMERCIAL;
spool off;

set linesize 17
spool $SORTIE/030_FLUX_2M_RS_CORRES_SIT_GEO_BIEN_COMM.txt
  select
    CD_FAMILLE_IMM      	||'~'||
    CD_SIT_GEO_N1      	  ||'~'||
    CD_SIT_GEO_N2      	  ||'~'||
    CD_EMPLACE_BIEN_COMM     		  
  from RS_CORRES_SIT_GEO_BIEN_COMM;
spool off;

set linesize 32
spool $SORTIE/030_FLUX_2M_RS_NAT_OPE_TYPE_RISQ.txt
  select
    CD_TYPE_RISQUE      	||'~'||
    CD_NATURE_OPE      	  ||'~'||
    TX_HIST_POND_PARTICIPATION     		  
  from RS_NAT_OPE_TYPE_RISQ;
spool off;

--REF_CORRES_FORM_JUR_FIFI243
set linesize 20
spool $SORTIE/030_FLUX_2M_REF_CORRES_FORM_JUR_FIFI243.txt
  select
    CD_FORM_JUR      	 ||'~'||
    IND_NATURE_DURABLE
  from REF_CORRES_FORM_JUR_FIFI243;
spool off;

--REF_CATEG_BIEN
set linesize 150
spool $SORTIE/030_FLUX_2M_REF_CATEG_BIEN.txt
  select
    CD_FAMILLE_IMM         ||'~'||
    LIB_FAMILLE_IMM        ||'~'||
    CD_TYPO_COMMERCE       ||'~'||
    LIB_TYPOLOGIE_COMMERCE ||'~'||
    CD_TYPO_ENTREPOT       ||'~'||
    CD_CATEG_BIEN	  
  from REF_CATEG_BIEN;

--RS_IND_WATCH_LIST
set linesize 305
spool $SORTIE/030_FLUX_2M_RS_IND_WATCH_LIST.txt
  select
    CODE         ||'~'||
    LIBELLE_FR   ||'~'||
    LIBELLE_EN       
  from RS_IND_WATCH_LIST;

--RS_WL_MOTIF
set linesize 330
spool $SORTIE/030_FLUX_2M_RS_WL_MOTIF.txt
  select
    CODE         ||'~'||
    LIBELLE_FR   ||'~'||
    LIBELLE_EN   ||'~'|| 
    CD_IND_ENTREE_SORTIE  ||'~'||
    CD_TYPE_WL_CASA
  from RS_WL_MOTIF;

--RS_AGENT_ECO_NORME
set linesize 305
spool $SORTIE/030_FLUX_2M_RS_AGENT_ECO_NORME.txt
  select
    CODE            ||'~'||
    DESCRIPTION_FR  ||'~'||
    DESCRIPTION_EN       
  from RS_AGENT_ECO_NORME;

--RS_METHODE_RESTRUCT
set linesize 305
spool $SORTIE/030_FLUX_2M_RS_METHODE_RESTRUCT.txt
  select
    CODE            ||'~'||
    DESCRIPTION_FR  ||'~'||
    DESCRIPTION_EN       
  from RS_METHODE_RESTRUCT;


--------------------------------------------------------------------------------
-- SIRL-1472 : historisation de la ENG_CORP_P1_BIS dans HCRR
--   La table est remplie par pack_alim_tab_envoi_crrv4.P_ALIM_ENG_CORP_P1_BIS,
--   qui commence par un DELETE : elle ne contient que l arrete courant.
--   301 colonnes des 668 de la table -- les autres sont toujours NULL et
--   ne sont lues par aucun spool.
--   GENERE par gen_hcrr.py -- VERSAO 2026-10-06c
--------------------------------------------------------------------------------
SET linesize 3231
spool $SORTIE/030_FLUX_2M_ENG_CORP_P1_BIS.txt
  select
    ID_ENGAGEMENT
    ||'~'||CD_PERIMETRE
    ||'~'||NO_VARIANTE
    ||'~'||to_char(DT_ARRETE, 'YYYYMMDD')
    ||'~'||to_char(DT_TRAITEMENT, 'YYYYMMDD')
    ||'~'||to_char(P1_H_0_1, 'YYYYMMDD')
    ||'~'||P1_H_0_2
    ||'~'||P1_H_0_3
    ||'~'||P1_H_0_4
    ||'~'||P1_H_0_5
    ||'~'||P1_H_0_6
    ||'~'||P1_H_1_1
    ||'~'||P1_H_1_4
    ||'~'||P1_H_1_6
    ||'~'||P1_H_1_11
    ||'~'||P1_1_1
    ||'~'||P1_1_2
    ||'~'||P1_2_0
    ||'~'||P1_2_4
    ||'~'||P1_2_6
    ||'~'||P1_2_18
    ||'~'||P1_2_29
    ||'~'||P1_2_99
    ||'~'||to_char(P1_3_2, 'YYYYMMDD')
    ||'~'||to_char(P1_3_3, 'YYYYMMDD')
    ||'~'||to_char(P1_3_4, 'YYYYMMDD')
    ||'~'||P1_3_7
    ||'~'||P1_3_8
    ||'~'||P1_3_9
    ||'~'||P1_3_10
    ||'~'||P1_3_11
    ||'~'||P1_3_12
    ||'~'||P1_3_13
    ||'~'||P1_3_15
    ||'~'||P1_3_16
    ||'~'||P1_3_17
    ||'~'||P1_3_19
    ||'~'||P1_3_20
    ||'~'||P1_3_31
    ||'~'||P1_3_36
    ||'~'||P1_3_40
    ||'~'||P1_3_41
    ||'~'||P1_3_42
    ||'~'||P1_3_43
    ||'~'||P1_3_44
    ||'~'||P1_3_45
    ||'~'||P1_3_46
    ||'~'||P1_3_47
    ||'~'||P1_3_50
    ||'~'||P1_3_51
    ||'~'||P1_3_52
    ||'~'||P1_3_53
    ||'~'||P1_3_54
    ||'~'||P1_3_55
    ||'~'||P1_3_56
    ||'~'||P1_3_61
    ||'~'||P1_3_72
    ||'~'||P1_3_73
    ||'~'||P1_3_75
    ||'~'||P1_3_76
    ||'~'||P1_3_77
    ||'~'||P1_3_80
    ||'~'||P1_3_81
    ||'~'||P1_3_82
    ||'~'||P1_3_83
    ||'~'||P1_3_84
    ||'~'||P1_3_85
    ||'~'||P1_3_86
    ||'~'||P1_3_87
    ||'~'||P1_3_88
    ||'~'||P1_4_1
    ||'~'||P1_4_2
    ||'~'||P1_4_3
    ||'~'||P1_4_4
    ||'~'||P1_4_5
    ||'~'||P1_4_6
    ||'~'||P1_4_7
    ||'~'||P1_4_8
    ||'~'||P1_4_9
    ||'~'||P1_4_13
    ||'~'||P1_4_14
    ||'~'||P1_4_15
    ||'~'||P1_4_16
    ||'~'||P1_4_17
    ||'~'||P1_4_18
    ||'~'||P1_4_19
    ||'~'||P1_4_21
    ||'~'||P1_4_22
    ||'~'||P1_4_23
    ||'~'||P1_4_29
    ||'~'||P1_4_30
    ||'~'||P1_4_31
    ||'~'||P1_4_34
    ||'~'||P1_4_42
    ||'~'||to_char(P1_4_47, 'YYYYMMDD')
    ||'~'||P1_5_2
    ||'~'||to_char(P1_5_3, 'YYYYMMDD')
    ||'~'||P1_5_5
    ||'~'||P1_5_7
    ||'~'||P1_5_19
    ||'~'||P1_5_20
    ||'~'||P1_8_1
    ||'~'||P1_8_2
    ||'~'||P1_8_11
    ||'~'||P1_8_12
    ||'~'||P1_8_13
    ||'~'||P1_10_1
    ||'~'||P1_10_2
    ||'~'||P1_10_20
    ||'~'||P1_11_1
    ||'~'||P1_11_2
    ||'~'||P1_12_1
    ||'~'||P1_13_10
    ||'~'||P1_15_1
    ||'~'||P1_15_2
    ||'~'||P1_18_1
    ||'~'||P1_18_5
    ||'~'||P1_18_10
    ||'~'||P1_18_17
    ||'~'||P1_18_18
    ||'~'||P1_19_5
    ||'~'||P1_20_1
    ||'~'||P1_20_2
    ||'~'||P1_20_3
    ||'~'||P1_20_4
    ||'~'||P1_21_1
    ||'~'||to_char(P1_21_2, 'YYYYMMDD')
    ||'~'||P1_21_3
    ||'~'||P1_21_4
    ||'~'||P1_21_5
    ||'~'||P1_21_6
    ||'~'||to_char(P1_21_7, 'YYYYMMDD')
    ||'~'||to_char(P1_21_8, 'YYYYMMDD')
    ||'~'||to_char(P1_21_9, 'YYYYMMDD')
    ||'~'||to_char(P1_21_10, 'YYYYMMDD')
    ||'~'||to_char(P1_21_11, 'YYYYMMDD')
    ||'~'||to_char(P1_21_12, 'YYYYMMDD')
    ||'~'||to_char(P1_21_13, 'YYYYMMDD')
    ||'~'||to_char(P1_21_14, 'YYYYMMDD')
    ||'~'||to_char(P1_21_15, 'YYYYMMDD')
    ||'~'||to_char(P1_21_16, 'YYYYMMDD')
    ||'~'||P1_21_17
    ||'~'||P1_21_22
    ||'~'||to_char(P1_21_23, 'YYYYMMDD')
    ||'~'||P1_21_25
    ||'~'||P1_21_26
    ||'~'||P1_21_27
    ||'~'||P1_21_28
    ||'~'||P1_21_29
    ||'~'||P1_21_30
    ||'~'||P1_21_31
    ||'~'||P1_21_38
    ||'~'||P1_21_39
    ||'~'||P1_21_40
    ||'~'||P1_21_43
    ||'~'||P1_21_44
    ||'~'||P1_21_45
    ||'~'||P1_21_46
    ||'~'||P1_21_55
    ||'~'||P1_21_57
    ||'~'||P1_21_58
    ||'~'||P1_21_59
    ||'~'||P1_21_60
    ||'~'||P1_21_66
    ||'~'||P1_21_68
    ||'~'||P1_21_69
    ||'~'||P1_21_71
    ||'~'||P1_21_72
    ||'~'||P1_21_73
    ||'~'||P1_21_74
    ||'~'||P1_21_75
    ||'~'||P1_21_76
    ||'~'||P1_21_77
    ||'~'||P1_21_78
    ||'~'||P1_21_79
    ||'~'||P1_21_80
    ||'~'||P1_21_81
    ||'~'||P1_21_82
    ||'~'||P1_21_86
    ||'~'||P1_21_87
    ||'~'||P1_21_88
    ||'~'||P1_21_94
    ||'~'||P1_22_1
    ||'~'||P1_22_5
    ||'~'||P1_22_6
    ||'~'||P1_22_7
    ||'~'||P1_22_8
    ||'~'||P1_22_9
    ||'~'||P1_22_11
    ||'~'||P1_22_12
    ||'~'||P1_22_13
    ||'~'||P1_22_14
    ||'~'||P1_22_15
    ||'~'||P1_22_16
    ||'~'||P1_22_17
    ||'~'||P1_22_18
    ||'~'||P1_22_19
    ||'~'||P1_22_20
    ||'~'||to_char(P1_22_21, 'YYYYMMDD')
    ||'~'||to_char(P1_22_22, 'YYYYMMDD')
    ||'~'||P1_22_23
    ||'~'||P1_22_24
    ||'~'||P1_22_25
    ||'~'||P1_22_26
    ||'~'||P1_22_27
    ||'~'||P1_22_28
    ||'~'||P1_22_29
    ||'~'||P1_22_30
    ||'~'||to_char(P1_22_31, 'YYYYMMDD')
    ||'~'||P1_22_32
    ||'~'||P1_22_33
    ||'~'||P1_22_34
    ||'~'||P1_22_35
    ||'~'||P1_22_36
    ||'~'||to_char(P1_22_37, 'YYYYMMDD')
    ||'~'||to_char(P1_22_38, 'YYYYMMDD')
    ||'~'||P1_22_44
    ||'~'||P1_22_45
    ||'~'||P1_22_51
    ||'~'||P1_22_52
    ||'~'||P1_22_53
    ||'~'||P1_22_54
    ||'~'||P1_22_55
    ||'~'||P1_22_56
    ||'~'||P1_22_57
    ||'~'||to_char(P1_22_58, 'YYYYMMDD')
    ||'~'||to_char(P1_22_59, 'YYYYMMDD')
    ||'~'||P1_22_60
    ||'~'||P1_22_61
    ||'~'||P1_22_62
    ||'~'||to_char(P1_22_63, 'YYYYMMDD')
    ||'~'||P1_22_66
    ||'~'||to_char(P1_22_67, 'YYYYMMDD')
    ||'~'||P1_22_68
    ||'~'||P1_22_70
    ||'~'||P1_22_71
    ||'~'||P1_22_72
    ||'~'||P1_23_1
    ||'~'||P1_23_2
    ||'~'||P1_23_3
    ||'~'||P1_23_4
    ||'~'||P1_23_5
    ||'~'||P1_23_6
    ||'~'||P1_23_7
    ||'~'||P1_23_8
    ||'~'||P1_23_9
    ||'~'||P1_23_10
    ||'~'||P1_23_11
    ||'~'||P1_24_1
    ||'~'||P1_24_3
    ||'~'||P1_24_4
    ||'~'||P1_24_5
    ||'~'||P1_24_6
    ||'~'||P1_24_20
    ||'~'||P1_24_23
    ||'~'||P1_24_24
    ||'~'||P1_26_1
    ||'~'||P1_26_3
    ||'~'||P1_26_4
    ||'~'||P1_27_3
    ||'~'||P1_27_4
    ||'~'||P1_28_1
    ||'~'||P1_28_2
    ||'~'||P1_29_1
    ||'~'||P1_29_2
    ||'~'||P1_29_3
    ||'~'||P1_29_4
    ||'~'||P1_30_1
    ||'~'||P1_30_2
    ||'~'||P1_30_3
    ||'~'||P1_30_12
    ||'~'||P1_30_13
    ||'~'||P1_30_14
    ||'~'||P1_30_15
    ||'~'||P1_30_16
    ||'~'||P1_30_17
    ||'~'||P1_30_18
    ||'~'||P1_30_19
    ||'~'||P1_30_20
    ||'~'||P1_30_21
    ||'~'||P1_30_22
    ||'~'||P1_30_23
    ||'~'||P1_30_25
    ||'~'||P1_30_27
    ||'~'||P1_31_2
    ||'~'||P1_31_3
    ||'~'||P1_31_4
    ||'~'||P1_31_5
    ||'~'||P1_31_6
    ||'~'||P1_31_9
    ||'~'||P1_31_10
    ||'~'||P1_31_17
    ||'~'||P1_31_18
    ||'~'||P1_31_21
    ||'~'||P1_31_22
    ||'~'||P1_31_37
    ||'~'||P1_50_1
    ||'~'||P1_50_2
    ||'~'||P1_50_3
    ||'~'||P1_50_8
    ||'~'||P1_50_9
  from ENG_CORP_P1_BIS;

spool off;

