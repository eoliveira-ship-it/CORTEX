--------------------------------------------------------------------------------
-- CAL-Version : 1.74                                                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Script        : 030_spool_9M.sql                                           --
-- Objet         : Spool d'extraction des donnees                             --
-- Type          : Script SQL et PL/SQL                                       --
--------------------------------------------------------------------------------
-- Domaine       : RINT                                                       --
-- Application   : 030 - Declarations Des Risques                             --
--------------------------------------------------------------------------------
-- Creation      : le 06/10/2015 par PELLETIER NICOLAS                        --
-- Modifications :                                                            --
-- -------------                                                              --
-- 21/07/2025 ALMEIDBR : v1.73 + projet OMP > SIRL-191                        --
-- 03/04/2025 KLx_Risq : LGD - ajout de 2 champs dans PARAM_MULTIDIM_GENER.   --
-- 18/11/2024 KLx_Risq : M69539 - ajout de 2 champs                           --
-- 16/01/2025 KLx_Risq : v1.71 + M_72558 - ajout colonne SIREN afin de gerer  --
--                       des garants                                          --
-- 15/01/2024 KLx_Risq : v1.70 + M67006 - ajout des nouvelles champs          --
-- 10/01/2025 Klx_Risq : M72917 - Ajout 2 caractere pour extraction de OPERATION_ARPSON
-- 21/07/2023 CUNHAVI  : v1.69 + Mantis 67050 - Corrections Linesize 		  --
-- 02/06/2023 CUNHAVI  : V1.68 + Mantis 62593 - Projet LTBCE				  --
-- 27/09/2021 GOMESHU  : v1.67 + US 49 (RL-2022)                              --
-- 23/09/2022 ALMEIDBR : US 50 - SAP NL adaptation NAT01 TRE100               --
-- 13/12/2021 ALMEIDBR : v1.66 + US 269 (CRRv4.3)                             --
-- 10/12/2021 ALMEIDBR : US 269 - Score 7 'Code INSEE de la commune'          --
-- 06/12/2021 CUNHAVI  : 1.65 Corriger                                        --
-- 03/12/2021 GOMESHU  : v1.63 + CRRV4.3 US 265                               --
-- 02/12/2021 CUNHAVI  : CRRV4.3 US 261                                       --
-- 28/09/2021 DUGUETMA : 1.53 + 48431 pour S40                                --
-- 04/08/2021 DUGUETMA : US 231 CRRV4.3 a partir de v1.57                     --
-- 28/07/2021 DUGUETMA : reactive M48431                                      --
-- 21/07/2021 DUGUETMA : reactive US 92 CRR                                   --
-- 15/07/2021 DUGUETMA : US91 + US139 CRRV4.3 								  --
-- 23/06/2021 MIPAMES  : Retrait M48431                                       --
-- 22/06/2021 MIPAMES  : Retrait US 92 CRRV4.3                                --
-- 16/06/2021 DUGUETMA : US 197 Donnee AER NAT 02 - TRICP - Annule et remplac --
--                       e US 88                                              --
-- 12/05/2021 MIPAMES  : US 86 & 88 CRRV4.3                                   --
-- 05/05/2021 DUGUETMA : MEPV21S27 US 92 CORRECTION                           --
-- 05/05/2021 DUGUETMA : MEPV21S27 US 89 et 92 CRRV4.3 a partir v1.46         --
-- 20/04/2021 DUGUETMA : Mantis 48431                                         --
-- 22/03/2021 DUGUETMA : MEPV21S17 US44                                       --
-- 02/03/2021 DUGUETMA : MEPV21S17 US 22 23 25 CRRV4.3                        --
-- 02/12/2020 DUGUETMA : US 17                                                --
-- 24/11/2020 DUGUETMA : US 204 - EQU101 - Leasing Process CORFOU mise en qua --
--                       lite CRR CALEF                                       --
-- 16/04/2020 DUGUETMA : Mantis 51001                                         --
-- 14/10/2019 MIPAMES : M46097 Rework                                         --
-- 05/06/2019 AMIAUDFR : MEPHV19S27 US792                                     --
-- 23/05/2019 DUGUETMA : MEPHV19S27 US 774                                    --
-- 20/03/2019 MIPAMES : MEPHV19S13 correctif                                  --
-- 07/03/2019 DUGUETMA : MEPHV19S13 it2 US 587, 762 et 746                    --
-- 01/03/2019 DUGUETMA : MEPHV19S13 it1                                       --
-- 01/02/2019 DUGUETMA : MEPHV19S09 US570 US606 US609 US610 US620 US621 US651 --
--                        US652 US622 US624 US611 US674                       --
-- 14/12/2018 MIPAMES : Merge v1.27 et v1.28                                  --
-- 10/12/2018 MIPAMES : MEPHV19S02 it2 US557, 578, 541                        --
-- 16/11/2018 DUGUETMA : CDS AToS FAD - AER Palma - Historisation             --
-- 14/11/2018 DUGUETMA : MEPHV18S48 US 546 ET 552                             --
-- 27/09/2018 DUGUETMA : Mantis 42434                                         --
-- 13/09/2018 DUGUETMA : ANACREDIT US 489                                     --
-- 18/07/2018 DUGUETMA : ANACREDIT V18S39 Iteration 1                         --
-- 29/05/2018 DUGUETMA : MEPHO ANACREDIT                                      --
-- 07/02/2018 DUGUETMA : Spool du code NUTS ANACREDIT US 26                   --
-- 23/05/2017 PELLETNI : us180                                                --
-- 22/05/2017 PELLETNI : cd methodo                                           --
-- 02/05/2017 PELLETNI : taille p8                                            --
-- 02/05/2017 PELLETNI : p2 taille                                            --
-- 02/05/2017 PELLETNI : taille p1                                            --
-- 02/05/2017 PELLETNI : p1                                                   --
-- 27/04/2017 PELLETNI : correc                                               --
-- 27/04/2017 PELLETNI : ifrs + merge tof                                     --
-- 22/09/2016 PELLETNI : mephv                                                --
-- 14/01/2016 PELLETNI : nat03                                                --
-- 13/01/2016 PELLETNI : ref_nat03                                            --
--                                                                            --
--------------------------------------------------------------------------------

--
--  Spool de fichiers plats pour transfert Appli DDR (DDREX) -> DDR-HISTO (CRRV3)
--
SET serveroutput on size 1000000;
SET sqlprompt ""
--SET TERM OFF
SET SHOW OFF
SET VERIFY OFF
SET PAGES 0
SET ECHO OFF
SET HEADING OFF
SET FEED OFF
set trimspool on

SET linesize 110
spool $SORTIE/030_FLUX_2M_IDENT_SYNDICATION.txt
select
ID_OPERATION||'~'||
CD_SYS_INT||'~'||
CD_SOC_JURI||'~'||
LIB_SOC_JURI||'~'||
CD_POSITION_ENTITE_RISQUE||'~'||
REF_SYNDICATION||'~'||
-- 17/12/2018 - CDS ATOS (LFD) - ANACREDIT US 570
to_char(DT_ARRETE, 'YYYYMMDD')
-- FIN LFD
from ident_syndication;
spool off;


--SET linesize 292
-- 05/05/2021 - CDS ATOS (EMM) - CRRV4.3 US 86
--SET linesize 392 -- KLx (GHU) - 03/12/2021 _ 392 + SYS_GEST_SRC 20 = 412 _ US265 - Leasing - CRR Corporate - Score 7 'Système de gestion source' 	
--Fin EMM
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
||'~'||SYS_GEST_SRC --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Système de gestion source'||'~'||CD_TYPE_PROD_BANCAIRE
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

--SET linesize 232 -- KLx (GHU) - 03/12/2021 _ 232 + SYS_GEST_SRC 20 = 252 _ US265 - Leasing - CRR Corporate - Score 7 'Système de gestion source' 
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
||'~'||SYS_GEST_SRC --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Système de gestion source'
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
--+1 04/02/2021 - CDS ATOS (LFD) - US 23 CRRV4.3
--SET linesize 2210
--SET linesize 2233
--US 262 - KLx Risque (VDC) - 03/12/2021 - CRRV4.3 - Ajout du champ IND_GAR_SANS_LIMITE format VARCHAR2 de longueur 1 byte , donc +1
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
--07/12/17 CDS ATOS (EMM) Sprint 1 US 27
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
-- 14/04/2018 CDS ATOS (JMP) Sprint 7 US33 Ajout du code motif SCO
CD_MOTIF_SCO_LC0267 ||'~'||
CD_Meth_IFRS9_PD||'~'|| 
CD_Meth_IFRS9_LGD||'~'||
CD_Meth_IFRS9_CCF||'~'|| 
CD_Meth_IFRS9_Tx||'~'||
-- 11/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Donnees premier deblocage de fonds
MNT_PREM_DBLQ_FONDS||'~'||
to_char(DT_PREM_DBLQ_FONDS, 'YYYYMMDD')	||'~'||
DEVISE_PREM_DBLQ_FONDS
-- Fin 11/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 Donnees premier deblocage de fonds 
--09/01/2019 - CDS AtoS FAD - CRRV4.2 US624
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
||'~'||FINALITE_OPERATION -- 04/02/2021 - CDS ATOS (LFD) - US 23 CRR4.3 
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
||'~'||IND_GAR_SANS_LIMITE -- US 262 - KLx Risque (VDC) - 03/12/2021 - CRRV4.3 - Ajout du champ IND_GAR_SANS_LIMITE  
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
--30/11/2021 - KLx Risque (VDC) - US 261 Addition des champs « MNT_FOND_REMIS_DATE » (18+1) et « DEV_FOND_REMIS_DATE » (3)
--SET linesize 1494
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
CD_MOTIF_SCO_LC0267 ||'~'|| 
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
--09/01/2019 - CDS ATOS (SQN) - ANACREDIT US622
||'~'||TX_EL
||'~'||TO_CHAR(DT_PL_NPL, 'YYYYMMDD')
||'~'||CD_MOTIF_PL_NPL
||'~'||CD_PAYS_JURIDICTION
||'~'||TO_CHAR(DT_SIGNATURE, 'YYYYMMDD')
||'~'||EVT_DECL_GAR
-- Suite a l'US670 ne plus creer CD_MOTIF_DTX (SQN)
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
||'~'||MNT_FOND_REMIS_DATE --US 261 CRRV4.3 - Ajout du  champ « MNT_FOND_REMIS_DATE » au format NUMBER(18,2) signé - KLx Risque (VDC) 25/11/2021
||'~'||DEV_FOND_REMIS_DATE --US 261 CRRV4.3 - Ajout du  champ « DEV_FOND_REMIS_DATE » au format VARCHAR(3) - KLx Risque (VDC) 26/11/2021
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

--SET linesize 364
-- 05/05/2021 - CDS ATOS (EMM) - CRRV4.3 US 86
--SET linesize 434 -- KLx (GHU) - 03/12/2021 _ 434 + SYS_GEST_SRC 20 = 454 _ US265 - Leasing - CRR Corporate - Score 7 'Système de gestion source' 	
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
||'~'||SYS_GEST_SRC --KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Système de gestion source'
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
--SET linesize 869
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
DT_STATUT_ACTIVITE_LOCAL   ||'~'||                                      
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

--19/02/2019 - CDS ATOS (SQN) - US 730
--SET linesize 195 + 13
--SET linesize 208
SET linesize 355
  spool $SORTIE/030_FLUX_2M_PROVISIONS_DECOTES_P9.txt
  select
	to_char(DT_ARRETE, 'YYYYMMDD') ||'~'||
	CD_CONSO_CPT                   ||'~'||
	ID_TIERS_CALC                  ||'~'||
	ID_CENTRAL_TIERS               ||'~'||
	ID_AUTORISATION                ||'~'||
	ID_LIGNE_DET                   ||'~'||
	ID_ENGAGEMENT                  ||'~'||
	CD_TYPE_RISQUE                 ||'~'||
	CD_PROVISION                   ||'~'||
	CD_NAT_DEPRE                   ||'~'||
	CD_PERIM_PROV                  ||'~'||    
	CD_DEVISE                      ||'~'||
	FLAG_HN                        ||'~'||
	A_EXTRAIRE                     ||'~'||
	CD_PCCO_CRD                    ||'~'||
	CD_PCCO_SOLD                   ||'~'||
	MNT_PROVISION_CRD              ||'~'||
	MNT_PROVISION_SOLD             ||'~'||
	MNT_PROVISION_TRIM_CRD         ||'~'||
	MNT_PROVISION_TRIM_SOLD        ||'~'||
	ORIGINE_CALCUL_PROVISION       ||'~'|| -- 04/01/2019 - CDS ATOS (LFD) - ANACREDIT US 621
	--19/02/2019 - CDS ATOS (SQN) - US 730
	APPLI_SOURCE                   ||'~'||
	--01/04/2019 - CDS ATOS (LFD) - US 774
	CD_PCCO_PNU                    ||'~'||
	ID_PROVISION                   ||'~'||
	MNT_PROVISION_PNU              ||'~'||
	MNT_PROVISION_TRIM_PNU         ||'~'||
	--CDS_ATOS (MNE) - 08/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
	CD_TYPE_PROD_BANCAIRE          ||'~'||
	-- DEBUT :: M67006 - spec 2.2
    SYSTEME_SOURCE                 ||'~'|| --- P9 1.20 
    CD_DEVISE_LIASSE               ||'~'|| --- P9 50.1 
    PCCO_DEPRECIATION              ||'~'|| --- P9 50.10
    MNT_DEPRECIATION                       --- P9 50.11
    -- FIN :: M67006 - spec 2.2
  from provisions_decotes_p9;
spool off;

SET linesize 506
spool $SORTIE/030_FLUX_9M_NAT01_TRE100.txt
select
  to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
  CD_CONSO_CPT||'~'||
  REF_ENG||'~'||
  NUM_PCEC||'~'||
  LIB_PCEC||'~'||
  NUM_PCCO||'~'||
  LIB_PCCO||'~'||
  NAT_OPE||'~'||
  TYPE_RISQUE||'~'||
  ID_TIERS_CTRPART||'~'||
  NOM_CTRPART||'~'||
  CODE_DEV_SOLDE_BANC||'~'||
  SOLDE_BANC_DEV||'~'||
  SOLDE_BANC_DEV_BU||'~'||
  SOLDE_BANC_DEV_EUR
from NAT01_TRE100 
;
spool off;

-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser le flux consolide NAT01 TRE204 TRE401
-- Operation : Modifier l'export dans le spool d'historisation NAT01_TRE204_TRE401
--SET linesize 774
--05/06/2019 - CDS AtoS FAD - AER / PALMA US792
--SET linesize 811+69
SET linesize 880
--Fin - CDS AtoS FAD - AER / PALMA US792
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534
spool $SORTIE/030_FLUX_9M_NAT01_TRE204_TRE401.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_CONSO_CPT||'~'||
	REF_ENG||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NAT_OPE||'~'||
	TYPE_RISQUE||'~'||
	TYPE_PCCO||'~'||
	NOM_CTRPART||'~'||
	ID_TIERS_CTRPART||'~'||
	CATEG_OPE||'~'||
	NUM_OPE||'~'||
	to_char(DATE_DEBUT, 'YYYYMMDD')||'~'|| 
	to_char(DATE_FIN, 'YYYYMMDD')||'~'||  
	CODE_DEVISE||'~'||
	MT_CRD_DEV||'~'||
	MT_CRD_DEV_BU||'~'||
	MT_CRD_DEV_EUR||'~'||
	MT_CUMUL_IRD_DEV||'~'||
	MT_CUMUL_IRD_DEV_BU||'~'||
	MT_CUMUL_IRD_DEV_EUR||'~'||
	MT_NOMINAL_DEV||'~'||
	MT_NOMINAL_DEV_BU||'~'||
	MT_NOMINAL_DEV_EUR||'~'||
	CODE_DEV||'~'||
	MT_DEV||'~'||
	MT_DEV_BU||'~'||
	MT_DEV_EUR||'~'||
	CODE_DEV_SOLDE_BANC||'~'||
	SOLDE_BANC_DEV||'~'||
	SOLDE_BANC_DEV_BU||'~'||
	SOLDE_BANC_DEV_EUR
-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser le flux consolide NAT01 TRE204 TRE401
-- Operation : Modifier l'export dans le spool d'historisation NAT01_TRE204_TRE401
	||'~'||PCEC_IRD || '~' ||
	PCCO_IRD || '~' ||
	INSTRUMENT
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534
--05/06/2019 - CDS AtoS FAD - AER / PALMA US792
	||'~'||TYPE_TAUX
	||'~'||IND_REF
	||'~'||TYPE_AMOR_CAP
	||'~'||PRD_PMT_INT
	||'~'||BASE_CAL_INT
	||'~'||MNT_TAUX 
	||'~'||TAUX_MOYEN
--Fin - CDS AtoS FAD - AER / PALMA US792
-- 08/02/2021 - CDS ATOS (CPD) -US 22
||'~'||TRANSFERT
-- fin CPD
from NAT01_TRE204_TRE401 
;
spool off;

SET linesize 908
spool $SORTIE/030_FLUX_9M_NAT03_EQU101.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_CONSO_CPT||'~'||
	REF_ENG||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NAT_OPE||'~'||
	TYPE_RISQUE||'~'||
	TYPE_PCCO||'~'||
	NOM_CTRPART||'~'||
	ID_TIERS_CTRPART||'~'||
	NB_TITRES||'~'||
	CODE_DEV||'~'||
	MT_ORIG_DEV||'~'||
	MT_ORIG_DEV_BU||'~'||
	MT_ORIG_DEV_EUR||'~'||
	MT_ACQ||'~'||
	MT_ACQ_DEV_BU||'~'||
	MT_ACQ_DEV_EUR||'~'||
	to_char(DATE_ACQ, 'YYYYMMDD')||'~'|| 
	CODE_DEV_NOMINAL||'~'||
	MT_NOMINAL||'~'||
	MT_NOMINAL_DEV_BU||'~'||
	MT_NOMINAL_DEV_EUR||'~'||
	CODE_DEV_MTM||'~'||
	MT_MTM||'~'||
	MT_MTM_DEV_BU||'~'||
	MT_MTM_DEV_EUR||'~'||
	MT_STOCK_PROV_DEPREC||'~'||
	MT_STOCK_PROV_DEV_BU||'~'||
	MT_STOCK_PROV_DEV_EUR||'~'||
	MT_MTM_NET_DEPREC||'~'||
	MT_MTM_NET_DEV_BU||'~'||
	MT_MTM_NET_DEV_EUR||'~'||
	MT_STOCK_PROV_DEPREC_TRIM||'~'||
	MT_STOCK_PROV_TRIM_DEV_BU||'~'||
	MT_STOCK_PROV_TRIM_DEV_EUR||'~'||
	MT_MTM_NET_TRIM_DEPREC||'~'||
	MT_MTM_NET_TRIM_DEV_BU||'~'||
	MT_MTM_NET_TRIM_DEV_EUR
from NAT03_EQU101 
WHERE DT_ARRETE=pack_utilitaire.f_calc_dt_arrete;
spool off;

SET linesize 723
spool $SORTIE/030_FLUX_9M_NAT06_07_08_SIG201.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_CONSO_CPT||'~'||
	REF_ENG||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NAT_OPE||'~'||
	TYPE_RISQUE||'~'||
	TYPE_PCCO||'~'||
	NOM_CTRPART||'~'||
	ID_TIERS_CTRPART||'~'||
	CATEG_OPE||'~'||
	NUM_OPE||'~'||
	to_char(DATE_DEBUT, 'YYYYMMDD')||'~'||  
	to_char(DATE_FIN, 'YYYYMMDD')||'~'||     
	CODE_DEV_NOMINAL||'~'||
	MT_NOMINAL_DEV||'~'||
	MT_NOMINAL_DEV_BU||'~'||
	MT_NOMINAL_DEV_EUR||'~'||
	CODE_DEV_IRD||'~'||
	MT_IRD_DEV||'~'||
	MT_IRD_DEV_BU||'~'||
	MT_IRD_DEV_EUR||'~'||
	CODE_DEV||'~'||
	MT_DEV||'~'||
	MT_DEV_BU||'~'||
	MT_DEV_EUR||'~'||
	CODE_DEV_SOLDE_BANC||'~'||
	SOLDE_BANC_DEV||'~'||
	SOLDE_BANC_DEV_BU||'~'||
	SOLDE_BANC_DEV_EUR
from NAT06_07_08_SIG201 
;
spool off;
--04/12/2018 - CDS AtoS FAD - AER Palma Leasing US 578 - Swap de taux
-- Mise a jour du spool d'export pour NAT10_VAR104 - Line size + 260
-- SET linesize 1213
SET linesize 1473
-- Fin - CDS AtoS FAD - AER Palma Leasing US 578 - Swap de taux
spool $SORTIE/030_FLUX_9M_NAT10_VAR104.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_CONSO_CPT||'~'||
	REF_ENG||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NAT_OPE||'~'||
	TYPE_RISQUE||'~'||
	TYPE_PCCO||'~'||
	NOM_CTRPART||'~'||
	ID_TIERS_CTRPART||'~'||
	CATEG_OPE||'~'||
	NUM_OPE||'~'||
	to_char(DATE_DEBUT, 'YYYYMMDD')||'~'||   
	to_char(DATE_FIN, 'YYYYMMDD')||'~'||   
	CODE_DEV||'~'||
	MT_DEV||'~'||
	MT_DEV_BU||'~'||
	MT_DEV_EUR||'~'||
	CODE_DEV_SOLDE_BANC||'~'||
	SOLDE_BANC_DEV||'~'||
	SOLDE_BANC_DEV_BU||'~'||
	SOLDE_BANC_DEV_EUR||'~'||
	CODE_DEV_MTM||'~'||
	MT_MTM_DEV||'~'||
	MT_MTM_DEV_BU||'~'||
	MT_MTM_DEV_EUR||'~'||
	NUM_PCCO_MTM||'~'||
	LIB_PCCO_MTM||'~'||
	CODE_DEV_NOMINAL||'~'||
	MT_NOMINAL_DEV||'~'||
	MT_NOMINAL_DEV_BU||'~'||
	MT_NOMINAL_DEV_EUR||'~'||
	NUM_PCCO_NOMINAL||'~'||
	LIB_PCCO_NOMINAL||'~'||
	TYPE_TAUX||'~'||
	TAUX_MARGE
--04/12/2018 - CDS AtoS FAD - AER Palma Leasing US 578 - Swap de taux
-- Mise a jour du spool d'export pour NAT10_VAR104
	||'~'||
	INSTRUMENT||'~'||
	CONTREPARTIE||'~'||
	NUM_HISTO||'~'||
	REF_TAUX_PAYE||'~'||
	TAUX_MARGE_PAYE||'~'||
	REF_TAUX_RECU||'~'||
	TAUX_MARGE_RECU||'~'||
	MT_COUPON_NECH_JMB_VENDU||'~'||
	MT_COUPON_NECH_JMB_ACHETE||'~'||
	REF_CONTRAT_NETTING||'~'||
	REF_ACCORD_COLLAT||'~'||
	NUM_PCEC_MTM||'~'||
	FRQ_PMNT_TX_RECU||'~'||
	BASE_CALC_INT_RECU||'~'||
	FRQ_PMNT_TX_PAYE||'~'||
	BASE_CALC_INT_PAYE
--Fin - CDS AtoS FAD - AER Palma Leasing US 578 - Swap de taux
from NAT10_VAR104 
;
spool off;

-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser  la table de travail sur les donnees en provenance d'ARPSON
-- Operation : Modifier l'export dans le spool d'historisation OPERATION_ARPSON
--SET linesize 317
--05/06/2019 - CDS AtoS FAD - AER : PALMA US792
--SET linesize 426+86
--SET linesize 512
--SET linesize 536 -- US49-RL2022 KLx-GHU
SET linesize 544 -- M72917 - Ajout 8 caractere
--Fin - CDS AtoS FAD - AER : PALMA US792
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534
spool $SORTIE/030_FLUX_9M_OPERATION_ARPSON.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	ID_ENGAGEMENT_ARPSON||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	ID_CONTREPARTIE||'~'||
	NUM_OPE||'~'||
	NUM_HISTO||'~'||
	CAT_OPERATION||'~'||
	to_char(DATE_DEB_ENG, 'YYYYMMDD')||'~'|| 
	to_char(DATE_FIN_ENG, 'YYYYMMDD')||'~'||  
	EMPLOI_RESSOURCE||'~'||
	CODE_DEVISE||'~'||
	MNT_CRD||'~'||
	MNT_NOMINAL||'~'||
	MNT_CUMUL_IRD||'~'||
	MNT_RESCOMPTE_DEB||'~'||
	MNT_RESCOMPTE_FIN||'~'||
	TYPE_TAUX||'~'||
	MNT_TAUX||'~'||
	MNT_REGLEMENT||'~'||
	MNT_VALORISATION||'~'||
	MNT_VALORISATION_CPTA||'~'||
	MNT_VALORISATION_BRUT
-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser  la table de travail sur les donnees en provenance d'ARPSON
-- Operation : Modifier l'export dans le spool d'historisation OPERATION_ARPSON
	|| '~' || INSTRUMENT || '~' ||
	INDICATEUR_CT_LT || '~' ||
	PCEC_MISE_EN_PLACE || '~' ||
	PCEC_INTERET || '~' ||
	CD_CONSO_CPT || '~' ||
	GROUPE || '~' ||
	MNT_CRD_DEV || '~' ||
	MT_REESCOMPTE_FIN_DEV
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534
--05/06/2019 - CDS AtoS FAD - AER : PALMA US792
	||'~'||BASE
	||'~'||CLASSE_TAUX
	||'~'||TAUX_MOYEN
	||'~'||PER_INTERETS
	||'~'||TAUX_MARGE
--Fin - CDS AtoS FAD - AER : PALMA US792
-- 08/02/2021 - CDS ATOS (CPD) -- US 22
||'~'||TRANSFERT
-- fin CPD
	||'~'||PCCO_MISE_EN_PLACE -- US49-RL2022 KLx-GHU
	||'~'||PCCO_INTERET -- US49-RL2022 KLx-GHU
from OPERATION_ARPSON 
;
spool off;

SET linesize 182
spool $SORTIE/030_FLUX_9M_OPERATION_SAP.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	NUM_PCEC||'~'||
	ID_CTRPART||'~'||
	CATEG_OPE||'~'||
	NUM_OPE||'~'||
	CODE_EVT||'~'||
	ID_EVT||'~'||
	to_char(DATE_EVT, 'YYYYMMDD')||'~'|| 
	CODE_DEV||'~'||
	MT_OPE||'~'||
	NOM_DOSSIER||'~'||
	to_char(DATE_CPTA, 'YYYYMMDD')||'~'||   
	CODE_PARTENAIRE
from OPERATION_SAP 
;
spool off;

SET linesize 272
spool $SORTIE/030_FLUX_9M_OPERATION_XRT.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	ID_ENGAGEMENT_XRT||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	to_char(DATE_TRAIT, 'YYYYMMDD')||'~'||  
	to_char(DATE_CPTA, 'YYYYMMDD')||'~'|| 
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	MNT_SOLDE_DEV||'~'||
	CODE_DEVISE_SOLDE_DEV||'~'||
	MNT_SOLDE_CPTA||'~'||
	CODE_DEVISE_CPTA||'~'||
	CODE_TYPE_CPTE||'~'||
	PERIODICITE_XRT||'~'||
	CODE_CPTE_XRT
from OPERATION_XRT 
;
spool off;

SET linesize 765
spool $SORTIE/030_FLUX_9M_REF_CORRESPONDANCE_NAT.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	LIB_SOCIETE_JURIDIQUE||'~'||
	CD_CONSO_DDR||'~'||
	CODE_NAT_OPE||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	RS_GESTION||'~'||
	ID_TIERS||'~'||
	IDENT_TIERS_SYS_SRCE||'~'||
	COMMENTAIRE
from REF_CORRESPONDANCE_NAT 
;
spool off;

SET linesize 97 --US50 :: KLx_Risques :: avant: linesize 70
spool $SORTIE/030_FLUX_9M_REF_CPTBQEXRTM.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD') 	||'~'||
	SOCIETE						   	||'~'||
	NUM_PCEC					   	||'~'||
	CODE_DEV_CPTA				   	||'~'||
	CODE_DEV					   	||'~'||
	CODE_XRT					   	||'~'||
	SIRET						 	||'~'||
	CODE_BANQUE						||'~'|| --US50 :: KLx_Risques
	CODE_BANQUE_ALPHA				||'~'|| --US50 :: KLx_Risques
	NUM_PCEC_XRT							--US50 :: KLx_Risques
from REF_CPTBQEXRTM;
spool off;

SET linesize 359
spool $SORTIE/030_FLUX_9M_REF_NAT03_EQU101.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	NUM_PCCO||'~'||
	NUM_PCEC||'~'||
	ID_CTRPART||'~'||
	RS_GESTION||'~'||
	NB_TITRES||'~'||
	CODE_DEV_ORIG||'~'||
	MT_VALEUR_ORIG||'~'||
	MT_ACQUISITION||'~'||
	to_char(DATE_ACQUISITION, 'YYYYMMDD')||'~'||   
	MT_NOMINAL||'~'||
	MT_MTM||'~'||
	MT_STOCK_PROV_DEPREC||'~'||
	MT_MTM_NET_DEPREC||'~'||
	MT_STOCK_PROV_DEPREC_TRIM||'~'||
	MT_MTM_NET_DEPREC_TRIM
from REF_NAT03_EQU101 
WHERE DT_ARRETE=pack_utilitaire.f_calc_dt_arrete
;
spool off;

SET linesize 334
spool $SORTIE/030_FLUX_9M_REF_PCCO_PCEC_SAP.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	CODE_SENS
from REF_PCCO_PCEC_SAP 
;
spool off;

SET linesize 64
spool $SORTIE/030_FLUX_9M_REF_PCEC_TYPE_RISQUE.txt
select DISTINCT
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CODE_NAT_OPE||'~'||
	NAT_OPE||'~'||
	NUM_PCCO||'~'||
	NUM_PCEC||'~'||
	TYPE_RISQUE||'~'||
	TYPE_PCCO
from REF_PCEC_TYPE_RISQUE 
;
spool off;

SET linesize 46
spool $SORTIE/030_FLUX_9M_REF_PRM_CRR_SOC_JUR.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	SOURCE_CPTA||'~'||
	CD_SAP||'~'||
	CD_CONSO_DDR||'~'||
	CD_SOCIETE_JURIDIQUE
from REF_PRM_CRR_SOC_JUR 
;
spool off;

SET linesize 177
spool $SORTIE/030_FLUX_9M_REF_CORRES_DDR_SAP.txt
select
	to_char(DT_ARRETE, 'YYYYMMDD')||'~'||
	CD_ARGUMENT||'~'||
	CD_SAP||'~'||
	LIBELLE_SAP||'~'||
	CD_CONSO_DDR||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	FLAG_ACTIF
from REF_CORRES_DDR_SAP 
;
spool off;


SET linesize 619
spool $SORTIE/030_FLUX_9M_REJET_DONNEES.txt
select
	to_char(DATE_TRAITEMENT, 'YYYYMMDD HH24:MI:SS')||'~'||    
	CD_SOCIETE_JURIDIQUE||'~'||
	TABLE_SOURCE||'~'||
	TABLE_REFERENTE||'~'||
	CLE_RAPPRO||'~'||
	ID_TIERS||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	MNT_REJET||'~'||
	TYPE_REJET||'~'||
	LIBELLE_REJET
from REJET_DONNEES 
;
spool off;

SET linesize 19
spool $SORTIE/030_FLUX_9M_RS_CORRES_SOC_JURI_UCABAIL.txt
select
	CD_SYS_INT||'~'||
	CD_SOC_JURI_SYS_INT||'~'||
	CD_SOC_JURI
from RS_CORRES_SOC_JURI_UCABAIL 
;
spool off;

SET linesize 619
spool $SORTIE/030_FLUX_9M_RS_CORRESPONDANCE_NAT.txt
select
	CD_SOCIETE_JURIDIQUE||'~'||
	LIB_SOCIETE||'~'||
	CODE_NAT_OPE||'~'||
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	IDENT_TIERS_SYS_ORIG||'~'||
	RS_GESTION||'~'||
	ID_TIERS||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RS_CORRESPONDANCE_NAT 
;
spool off;

SET linesize 103
spool $SORTIE/030_FLUX_9M_RS_PCEC_TYPE_RISQUE.txt
select
	CODE_NAT_OPE||'~'||
	NAT_OPE||'~'||
	NUM_PCCO||'~'||
	NUM_PCEC||'~'||
	TYPE_RISQUE||'~'||
	TYPE_PCCO||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RS_PCEC_TYPE_RISQUE 
;
spool off;

SET linesize 85
spool $SORTIE/030_FLUX_9M_RS_PRM_CRR_SOC_JUR.txt
select
	SOURCE_CPTA||'~'||
	CD_SAP||'~'||
	CD_CONSO_DDR||'~'||
	CD_SOCIETE_JURIDIQUE||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RS_PRM_CRR_SOC_JUR 
;
spool off;

SET linesize 292
spool $SORTIE/030_FLUX_9M_RE_BALCTLXRTM.txt
select
	SOCIETE_SAP||'~'||
	to_char(DATE_TRAITEMENT, 'YYYYMMDD')||'~'||     
	to_char(DATE_CPTA, 'YYYYMMDD')||'~'||    
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	SOLDE_DEV||'~'||
	CODE_DEV||'~'||
	SOLDE_CPTA||'~'||
	CODE_DEV_CPTA||'~'||
	TYPE_CPT||'~'||
	PERIODE||'~'||
	CODE_CPT_XRT||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RE_BALCTLXRTM 
;
spool off;

SET linesize 242
spool $SORTIE/030_FLUX_9M_RE_CPTBQEXRTM.txt
select
	SOCIETE||'~'||
	NUM_PCEC||'~'||
	CODE_DEV_CPTA||'~'||
	CODE_BANQUE_ALPHA||'~'||
	CODE_DEV||'~'||
	CODE_BANQUE||'~'||
	CODE_GUICHET||'~'||
	NUM_COMPTE||'~'||
	CODE_XRT||'~'||
	CODE_CLE||'~'||
	INFO_RIB||'~'||
	SIRET||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RE_CPTBQEXRTM 
;
spool off;

-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser les donnees complementaires en provenances d'ARPSON
-- Operation : Modifier l'export dans le spool d'historisation RE_CUMUL_CPTA_ARP
--SET linesize 575
SET linesize 684
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534
spool $SORTIE/030_FLUX_9M_RE_CUMUL_CPTA_ARP.txt
select
	to_char(DATE_TRAITEMENT, 'YYYYMMDD')||'~'||    
	SOCIETE||'~'||
	REGRPMT_SOCIAL||'~'||
	NUM_OPE||'~'||
	NUM_HISTO||'~'||
	to_char(DATE_VALEUR, 'YYYYMMDD')||'~'||     
	to_char(DATE_FIN, 'YYYYMMDD')||'~'||      
	TAUX_MOYEN||'~'||
	DEVISE||'~'||
	MT_CAPITAL_DEBUT||'~'||
	TYPE_TAUX||'~'||
	TAUX_MARGE||'~'||
	BASE||'~'||
	CLASSE_TAUX||'~'||
	MT_RBT_CAPITAL||'~'||
	EMPLOI_RESSOURCE||'~'||
	CATEG_OPE||'~'||
	INSTRUMENT||'~'||
	CONTREPARTIE||'~'||
	MT_NOMINAL||'~'||
	MT_CRD||'~'||
	MT_CAPITAL_MOYEN||'~'||
	MT_CUMUL_INT||'~'||
	MT_REGLEMENTS||'~'||
	MT_REESCOMPTE_DEBUT||'~'||
	MT_REESCOMPTE_FIN||'~'||
	GROUPE||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser les donnees complementaires en provenances d'ARPSON
-- Operation : Modifier l'export dans le spool d'historisation RE_CUMUL_CPTA_ARP
	|| '~' || MT_CRD_DEV || '~' ||
	CRD_DEV_ARPSON || '~' ||
	MT_REESCOMPTE_FIN_DEV || '~' ||
	TRANSFERT
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534
from RE_CUMUL_CPTA_ARP 
;
spool off;

SET linesize 181
spool $SORTIE/030_FLUX_9M_RE_ECR_SAP.txt
select
	NOM_DOSSIER||'~'||
	to_char(DATE_CPTA, 'YYYYMMDD')||'~'||  
	CODE_PARTENAIRE||'~'||
	NUM_PCEC||'~'||
	TXT_POSTCPTA||'~'||
	DEVISE||'~'||
	MONTANT||'~'||
	SENS_MT||'~'||
	NUM_PIECECPTA||'~'||
	CODE_SAP||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RE_ECR_SAP 
;
spool off;

SET linesize 600
spool $SORTIE/030_FLUX_9M_RE_ENCOURS_ARP.txt
select
	SOCIETE||'~'||
	EMPLOI_RESSOURCE||'~'||
	CLASSE_MARCHE||'~'||
	INSTRUMENT||'~'||
	NUM_OPE||'~'||
	NUM_HISTO||'~'||
	CONTREPARTIE||'~'||
	to_char(DATE_OPE, 'YYYYMMDD')||'~'||  
	to_char(DATE_VALEUR, 'YYYYMMDD')||'~'||  
	to_char(DATE_ECHEANCE, 'YYYYMMDD')||'~'||  
	DEVISE||'~'||
	MT_NOMINAL||'~'||
	MT_CRD||'~'||
	TYPE_TAUX||'~'||
	TAUX_MARGE||'~'||
	PER_INTERETS||'~'||
	BASE||'~'||
	DUREE_INIT||'~'||
	DUREE_REST||'~'||
	TRANSFERT||'~'||
	CATEG_OPE||'~'||
	NOTION_GROUPE||'~'||
	MT_VAL_BILAN||'~'||
	MT_VALO_BRUT||'~'||
	MT_INT_COURUS||'~'||
	MT_VALO_NET||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RE_ENCOURS_ARP 
;
spool off;

SET linesize 376
spool $SORTIE/030_FLUX_9M_RE_NAT03_EQU101.txt
select
	SOCIETE||'~'||
	to_char(DATE_ACQUISITION, 'YYYYMMDD')||'~'||  
	NUM_PCCO||'~'||
	NUM_PCEC||'~'||
	ID_CTRPART||'~'||
	RS_GESTION||'~'||
	IDENT_TIERS_SYS_SRCE||'~'||
	REF_ID_TIERS||'~'||
	CODE_IDENT_TIERS||'~'||
	NB_TITRES||'~'||
	MT_VALEUR_ORIG||'~'||
	CODE_DEV_ORIG||'~'||
	MT_ACQUISITION||'~'||
	MT_NOMINAL||'~'||
	MT_MTM||'~'||
	MT_STOCK_PROV_DEPREC||'~'||
	MT_MTM_NET_DEPREC||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RE_NAT03_EQU101 
;
spool off;

SET linesize 373
spool $SORTIE/030_FLUX_9M_RE_PCCO_PCEC_SAP.txt
select
	NUM_PCCO||'~'||
	LIB_PCCO||'~'||
	NUM_PCEC||'~'||
	LIB_PCEC||'~'||
	CODE_SENS||'~'||
	DATE_CREAT||'~'||
	CODE_UTIL_CREAT
from RE_PCCO_PCEC_SAP 
;
spool off;

SET linesize 40
spool $SORTIE/030_FLUX_9M_RS_DEF_METHODO.txt
select
        to_char(pack_utilitaire.f_calc_dt_arrete, 'YYYYMMDD')||'~'||
        ID_NOTE_RETAIL||'~'||
        CODE_METHODOLOGIQUE||'~'||
        TRANSCO_NOTE_ACTUELLE||'~'||
        ID_NOTE_BALOIS_RETAIL
from RS_DEF_METHODO
;
spool off;

	
SET linesize 70
spool $SORTIE/030_FLUX_9M_RS_NOTATION_MOYENNE.txt
select
        to_char(pack_utilitaire.f_calc_dt_arrete, 'YYYYMMDD')||'~'||
        EXERCICE||'~'||
        LIBELLE_SEGMENT||'~'||
        CODE_SEGMENT||'~'||
        MODELE_NOTATION||'~'||
		GRILLE_NOTATION||'~'||
		NOTE_MOYENNE
from RS_NOTATION_MOYENNE
;
spool off;

-- 13/11/2018 - CDS AtoS (FAD) - AER / PALMA Leasing US534
-- Fonctionnalite : Historiser le Parametrage des comptes lies aux operations de prets d'ARPSON
-- Operation : Ajout de l'export dans le spool d'historisation REF_COMPTA_ARPSON
--SET linesize 64
SET linesize 88  -- US49-RL2022 KLx-GHU _ 64 + 12 + 12

spool $SORTIE/030_FLUX_9M_REF_COMPTA_ARPSON.txt
select
to_char(DT_ARRETE,'YYYYMMDD') ||'~'||
FAMILLE ||'~'||
INSTRUMENT ||'~'||
REGRP_CPTA ||'~'||
INTRAGROUPE ||'~'||
CODE_DEVISE ||'~'||
PCEC_MISE_EN_PLACE ||'~'||
PCEC_INTERET||'~'||
PCCO_MISE_EN_PLACE ||'~'|| -- US49-RL2022 KLx-GHU
PCCO_INTERET -- US49-RL2022 KLx-GHU
from REF_COMPTA_ARPSON
;
spool off;
-- Fin - CDS AtoS (FAD) - AER / PALMA Leasing US534

-- 02/06/2023 - KLx Risque ( VDC ) - Projet LTBCE - Ajout Historisation PARAM_MULTIDIM_GENERIQUE
-- 21/07/2023 - M67050 - 860 + 21 separateur = 881
-- 18/11/2024 - M69539 - 881 + 80 ( 2*40 ) + 2 ( separateur ) = 963
-- 03/04/2025 - LGD    - 963 + 80 ( 2*40 ) + 2 ( separateur ) = 1045
---------------
-- 24 champs * 40 taille = 960
-- 2 champs * 30 taille  = 60
-- 25 separateurs        = 25 ( total: 960 + 60 + 25 = 1045 )
SET LINESIZE 1045
spool $SORTIE/030_FLUX_9M_PARAM_MULTIDIM_GENERIQUE.txt
SELECT	CODE_TYPE_UTILISATION || '~' ||
		VAL_TYPE_UTILISATION  || '~' ||
		CODE_PARAM_1		  || '~' ||
		VAL_PARAM_1			  || '~' ||
		CODE_PARAM_2		  || '~' ||
		VAL_PARAM_2			  || '~' ||
		CODE_PARAM_3		  || '~' ||
		VAL_PARAM_3			  || '~' ||
		CODE_PARAM_4		  || '~' ||
		VAL_PARAM_4			  || '~' ||
		CODE_PARAM_5		  || '~' ||
		VAL_PARAM_5			  || '~' ||
		CODE_RESULTAT1		  || '~' ||
		VAL_RESULTAT1		  || '~' ||
		LIB_RESULTAT1		  || '~' ||
		CODE_RESULTAT2		  || '~' ||
		VAL_RESULTAT2		  || '~' ||
		LIB_RESULTAT2		  || '~' ||
		CODE_PARAM_6		  || '~' ||
		VAL_PARAM_6			  || '~' ||
		CODE_PARAM_7		  || '~' ||
		VAL_PARAM_7	          || '~' ||
		CODE_PARAM_8          || '~' ||
		VAL_PARAM_8           || '~' ||
		CODE_PARAM_9          || '~' ||
		VAL_PARAM_9
FROM PARAM_MULTIDIM_GENERIQUE
;
spool off;
-- FIN SPOOL PARAM_MULTIDIM_GENERIQUE