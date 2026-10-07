#!/bin/ksh
################################################################################
## CAL-Version : 1.12                                                         ##
################################################################################
##                                                                            ##
## Type          : Traitement Shell                                           ##
################################################################################
## Domaine       : RINT                                                       ##
## Application   : 745 - Historisation mensuelle du Compte rendu des risques(CRR)                            ##
################################################################################
## Creation      : le 07/10/2015 par PELLETIER NICOLAS                        ##
##                                                                            ##
## Modifications                                                              ##
## -------------                                                              ##
## 18/09/2024 CUNHAVI  : Wave HCRR - Nom Composant + Actualisation Variables  ##
## 02/06/2023 CUNHAVI : Mantis 62593 LTBCE - Ajout chargement table PARAM_MULTIDIM_GENERIQUE
## 07/10/2022 CUNHAVI : Mantis 62593 LTBCE  - Modification du nom du shell    ##
## 16/04/2020 DUGUETMA : Mantis 51001                                         ##
## 14/10/2019 MIPAMES : M46097 Rework                                         ##
## 29/04/2019 MIPAMES : Suppression des log                                   ##
## 22/03/2019 MIPAMES : MEPHV19S13 it2                                        ##
## 01/03/2019 DUGUETMA : MEPHV19S13 it1                                       ##
## 16/11/2018 DUGUETMA : CDS AToS FAD - AER Palma - Historisation             ##
## 14/11/2018 DUGUETMA : MEPHV18S48 US552                                     ##
## 24/05/2017 PELLETNI : us180                                                ##
## 22/09/2016 PELLETNI : mephv                                                ##
##                                                                            ##
##                                                                            ##
################################################################################
################################################################################
## CAL-Version : 3.31                                                         ##
################################################################################
#----------------------------------------------------------------------------#
# Script        : 745_CHARGEMENT_HISTO_9M_7ANS.sh                            #
# Objet         : Chargement des fichiers historique                         #
#                                                                            #
# Type          : Traitement Shell                                           #
#----------------------------------------------------------------------------#
# Domaine       : RINT                                                       #
# Application   : 745 - Historisation mensuelle du Compte rendu des risques(CRR)                            #
#----------------------------------------------------------------------------#
# Creation      : 25/08/2008    PBI                                          #
#----------------------------------------------------------------------------#

# -- Nom de ce shell
nom_shell=745_CHARGEMENT_HISTO_9M_7ANS.sh

# -- Nom du fichier log
V745STARTLOG=745_CHARGEMENT_HISTO_9M_7ANS.log
#export V745STARTLOG

# ------------------------------------------
# Fonction de trace pour les erreurs gerees
# ------------------------------------------
trace_log()
{
  echo "$1-$2 : $3 - $4"
  echo "$1-$2 : $3 - $4" >> "$LOG/$V745STARTLOG"
}

# ----------------------------------------
# Fonction de test d'existence de fichier
# $1 : Nom du chemin
# $2 : Nom du fichier a tester
# ----------------------------------------
tester_existence()
{
 # ne pas mettre de / a la fin du nom de chemin a l'appel
 nom_chemin=$1
 nom_fich=$2

 if [ ! -r $nom_chemin/$nom_fich ]
 then
   trace_log "ERR" 50000 " - Fichier $nom_chemin/$nom_fich absent ou illisible"
  # exit 1
 fi
}

# -----------------------------------
# Fonction de suppression de fichier
# $1 : Nom du chemin
# $2 : Nom du fichier a supprimer
# -----------------------------------
supprimer_fichier()
{
 # ne pas mettre de / a la fin du nom de chemin a l'appel
 nom_chemin=$1
 nom_fich=$2

 if [ -s $nom_chemin/$nom_fich ]
 then
   trace_log "INF" 0 " - Suppression de l'ancien fichier: $nom_fich"
   rm $nom_chemin/$nom_fich
 fi
}

# -------------------------------------
# Fonction de suppression des donnees
# $1 : Nom de la table a vider
# -------------------------------------
supprimer_donnees()
{
# typeset fichsql=$1 param1=$2 param2=$3

# sqlplus -s $V30LOGIN @$fichsql $param1 $param2 >> journal_livraison.txt
# sqlplus -s $nomlog/$motpasse@$chaineconnexion @$fichsql $code_univers

trace_log "INF" 0 " - Suppression des donnees $1"

sqlplus -s $V745_CRR <<EOF >>/dev/null 2>> "$LOG/$V745STARTLOG"
set serveroutput on size 1000000;
set sqlprompt ""
truncate table $1;
commit;
spool off;
EXIT;
EOF
}

# ---------------------------------------------------------------------------
# CONTOURNEMENT du gestionnaire des erreurs pour analyse des erreurs loader
# ( qui ne tient pas compte des erreurs uniquement SQLLoader mais aussi ORA- )
# Parametres:
#     $1 : fichier de log genere par le loader
# ---------------------------------------------------------------------------
analyse_erreur_loader ()
{
  ficlog=$1
  LoaderErr=`grep "SQL\*Loader-[0-9][0-9][0-9]:" $ficlog`
  if [ ! -z "$LoaderErr" ]
  then
    trace_log "ERR" 50000 "Erreur SQL-Loader voir le fichier ou le ctl : $ficlog" >> "$LOG/$V745STARTLOG"
    echo "   *** ---------------------------------------------------------------------------------------- ***"
    echo "   *** => ERREUR SQL*LOADER : voir le fichier $ficlog (ou le ctl) ou $LOG/$V745STARTLOG  ***"
    echo "   *** ---------------------------------------------------------------------------------------- ***"
    exit 1
  fi

  LoaderErr=`grep "MAXIMUM ERROR" $ficlog`
  if [ ! -z "$LoaderErr" ]
  then
    trace_log "ERR" 50000 "Erreur SQL-Loader voir le fichier ou le ctl : $ficlog" >> "$LOG/$V745STARTLOG"
    echo "   *** ---------------------------------------------------------------------------------------- ***"
    echo "   *** => ERREUR SQL*LOADER : voir le fichier $ficlog (ou le ctl) ou $LOG/$V745STARTLOG  ***"
    echo "   *** ---------------------------------------------------------------------------------------- ***"
    exit 1
  fi
}

# ---------------------------------------------------
# Fonction de chargement des donnees par SQL*LOADER
# $1 : Nom du fichier CTL  (.ctl)
# $2 : Nom du fichier DATA (.txt)
# ---------------------------------------------------
sql_exec_loader()
{

 echo "dans sql_exec_loader" $CTL/$1

  # Controle de validit? du fichier CTL
  if [ ! -e $CTL/$1 ]
  then
    trace_log "ERR" 50000 "Fichier introuvable ou inexistant: $1"
  else
    # Controle de validit? du fichier DAT ou TXT des donnees a charger
    if [ ! -e $ENTREE/$2 ]
    then
      trace_log "ERR" 50000 "Fichier introuvable ou inexistant: $2"
     else
       # les fichiers .log et .bad ont le meme nom que le .dat
       fn=`basename $2 .txt`
       sqlldr userid=$V745_CRR data=$ENTREE/$2 control=$CTL/$1 log=$LOG/${fn}.log bad=$LOG/${fn}.bad errors=0 direct=FALSE silent=DISCARDS,FEEDBACK
       trace_log "INF" 0 " - Chargement des donnees $1 ok"
     fi
  fi
#  echo >> "$LOG/$V745STARTLOG"
}

# -------------------------------------
# Fonction d'analyse des erreurs
# $1 : Nom de la table a charger
# -------------------------------------
analyse_erreur()
{
  V99015FICLOG="$LOG/$V745STARTLOG"
  export V99015FICLOG
  $EXECRP

  CRP=$?
  echo "affichage CRP: " $CRP
  if [ $CRP != 0 ]
  then
    echo "   *** --------------------------------------------------------------------------------- ***"
    echo "   *** => ERREUR DE CHARGEMENT : voir fichier $LOG/$V745STARTLOG ***"
    echo "   *** --------------------------------------------------------------------------------- ***"
    exit $CRP
  fi
}


# -------------------------------------------------------------
# Fonction principale de chargement des donnees par SQL*LOADER
# $1 : Nom de la table (ex: RS_NOTATION_INTERNE)
# $2 : Nom du fichier associe (ex: 99115648.txt)
# -------------------------------------------------------------
charger_table_start()
{
 DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
 trace_log "INF" 0 "$DATE_TRT => Chargement table: $1" "$nom_shell"

 # desactivation des contraintes liees a la table
 #desactiver_contraintes $1          A VOIR

 # suppression des donnees de la table
 supprimer_donnees $1

 # test de l'existence du fichier start:  inutile car fait dans sql_exec_loader
 #tester_existence "$ENTREE" "$2"

 # suppression de l'ancien fichier bad s'il existe
 supprimer_fichier "$LOG" "030_FLUX_9M_$1.bad"
 supprimer_fichier "$LOG" "030_FLUX_2M_$1.bad"
 # appel de sql*loader (le test de l'existence du ctl se fait dans la fonction)
 sql_exec_loader "745_$1.ctl" "$2"


 # analyse des erreurs
 #analyse_erreur $1
}


#---------------------------
#   DEBUT DU PROGRAMME
#---------------------------

# Suppression du fichier log
#-----------------------------
supprimer_fichier "$LOG" "$V745STARTLOG"

##29/04/19 CDS ATOS (EMM) demande de suppression de tous les fichiers log precedents
#------------------------------------------------------------------------------------
rm $LOG/030_FLUX_*.log

# Suppression de tous les precedents fichiers de rejet
#-----------------------------------------------------
rm $LOG/*.bad

# --------------------
# Debut de traitement
# --------------------
DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "--------------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - DEBUT CHARGEMENT DES DONNEES HISTO DANS DDR-HISTO"
trace_log "INF" 0 "        (script $nom_shell)"
trace_log "INF" 0 "--------------------------------------------------------------"

## tables existant dans start et dans BTR
##---------------------------------------
charger_table_start "AUT_ECHEANCIER"				"030_FLUX_2M_AUT_ECHEANCIER.txt"
charger_table_start "AUTORISATION_DETAIL_F2"		"030_FLUX_2M_AUT_LIGNE_DET.txt"
charger_table_start "AUTORISATION_F1"				"030_FLUX_2M_AUT_CHAPEAU.txt"
charger_table_start "ENG_BALOIS_DETAIL_P6"			"030_FLUX_2M_ENG_BALOIS_DETAIL_P6.txt"
charger_table_start "ENG_CORP_P1"					"030_FLUX_2M_ENG_ENCOURS_CORPORATE.txt"
charger_table_start "ENG_CORP_P2"					"030_FLUX_2M_ENG_ENCOURS_CORP_PNU.txt"
charger_table_start "ENG_RETAIL_AGREG_P5"			"030_FLUX_2M_ENG_ENCOURS_RETAIL_AGREG.txt"
charger_table_start "ENG_RETAIL_DETAIL_P5"			"030_FLUX_2M_ENG_ENCOURS_RETAIL_DET.txt"
charger_table_start "IDENT_SYNDICATION"				"030_FLUX_2M_IDENT_SYNDICATION.txt"
charger_table_start "PROVISIONS_AGREG_P8"			"030_FLUX_2M_provisions_agreg_p8.txt"
charger_table_start "PROVISIONS_DECOTES_P9"			"030_FLUX_2M_PROVISIONS_DECOTES_P9.txt"
charger_table_start "PROVISIONS_DETAIL_P8"			"030_FLUX_2M_provisions_detail_p8.txt"
charger_table_start "SURETE_AGREG_M5"				"030_FLUX_2M_SURETE_AGREG_M5.txt"
charger_table_start "SURETE_DETAIL_M5"				"030_FLUX_2M_SURETE_DETAIL_M5.txt"
charger_table_start "SURETE_M1"						"030_FLUX_2M_SURETE_M1.txt"
charger_table_start "TIE_TIERS_C1_C5"				"030_FLUX_2M_TIE_TIERS.txt"

charger_table_start "JDF_ANA_ASSO_CONTREPARTIES"	"030_FLUX_9M_JDF_ANA_ASSO_CONTREPARTIES.txt"
charger_table_start "JDF_ANA_CONTREPARTIES"			"030_FLUX_9M_JDF_ANA_CONTREPARTIES.txt"
charger_table_start "JDF_ANA_INSTRUMENTS"			"030_FLUX_9M_JDF_ANA_INSTRUMENTS.txt"
charger_table_start "NAT01_TRE100"					"030_FLUX_9M_NAT01_TRE100.txt"
charger_table_start "NAT01_TRE204_TRE401"			"030_FLUX_9M_NAT01_TRE204_TRE401.txt"
charger_table_start "NAT03_EQU101"					"030_FLUX_9M_NAT03_EQU101.txt"
charger_table_start "NAT06_07_08_SIG201"			"030_FLUX_9M_NAT06_07_08_SIG201.txt"
charger_table_start "NAT10_VAR104"					"030_FLUX_9M_NAT10_VAR104.txt"
charger_table_start "OPERATION_ARPSON"				"030_FLUX_9M_OPERATION_ARPSON.txt"
charger_table_start "OPERATION_SAP"					"030_FLUX_9M_OPERATION_SAP.txt"
charger_table_start "OPERATION_XRT"					"030_FLUX_9M_OPERATION_XRT.txt"
charger_table_start "RE_BALCTLXRTM"					"030_FLUX_9M_RE_BALCTLXRTM.txt"
charger_table_start "RE_CPTBQEXRTM"					"030_FLUX_9M_RE_CPTBQEXRTM.txt"
charger_table_start "RE_CUMUL_CPTA_ARP"				"030_FLUX_9M_RE_CUMUL_CPTA_ARP.txt"
charger_table_start "RE_ECR_SAP"					"030_FLUX_9M_RE_ECR_SAP.txt"
charger_table_start "RE_ENCOURS_ARP"				"030_FLUX_9M_RE_ENCOURS_ARP.txt"
charger_table_start "RE_NAT03_EQU101"				"030_FLUX_9M_RE_NAT03_EQU101.txt"
charger_table_start "RE_PCCO_PCEC_SAP"				"030_FLUX_9M_RE_PCCO_PCEC_SAP.txt"
charger_table_start "REF_COMPTA_ARPSON"				"030_FLUX_9M_REF_COMPTA_ARPSON.txt"
charger_table_start "REF_CORRES_DDR_SAP"			"030_FLUX_9M_REF_CORRES_DDR_SAP.txt"
charger_table_start "REF_CORRESPONDANCE_NAT"		"030_FLUX_9M_REF_CORRESPONDANCE_NAT.txt"
charger_table_start "REF_CPTBQEXRTM"				"030_FLUX_9M_REF_CPTBQEXRTM.txt"
charger_table_start "REF_NAT03_EQU101"				"030_FLUX_9M_REF_NAT03_EQU101.txt"
charger_table_start "REF_PCCO_PCEC_SAP"				"030_FLUX_9M_REF_PCCO_PCEC_SAP.txt"
charger_table_start "REF_PCEC_TYPE_RISQUE"			"030_FLUX_9M_REF_PCEC_TYPE_RISQUE.txt"
charger_table_start "REF_PRM_CRR_SOC_JUR"			"030_FLUX_9M_REF_PRM_CRR_SOC_JUR.txt"
charger_table_start "REJET_DONNEES"					"030_FLUX_9M_REJET_DONNEES.txt"
charger_table_start "RS_CORRES_SOC_JURI_UCABAIL"	"030_FLUX_9M_RS_CORRES_SOC_JURI_UCABAIL.txt"
charger_table_start "RS_CORRESPONDANCE_NAT"			"030_FLUX_9M_RS_CORRESPONDANCE_NAT.txt"
charger_table_start "RS_DEF_METHODO"				"030_FLUX_9M_RS_DEF_METHODO.txt"
charger_table_start "RS_NOTATION_MOYENNE"			"030_FLUX_9M_RS_NOTATION_MOYENNE.txt"
charger_table_start "RS_PCEC_TYPE_RISQUE"			"030_FLUX_9M_RS_PCEC_TYPE_RISQUE.txt"
charger_table_start "RS_PRM_CRR_SOC_JUR"			"030_FLUX_9M_RS_PRM_CRR_SOC_JUR.txt"

# 08/10/19 CDS ATOS (EMM) Mantis 46097 - Inhibition du chargement AGREG_P6 dans HCRR
# charger_table_start "ENG_BALOIS_AGREG_P6"			"030_FLUX_2M_ENG_BALOIS_AGREG_P6.txt"
# Fin EMM Mantis 46097

# 25/02/2019 - CDS ATOS (LFD) - ANACREDIT US 485
#charger_table_start "JDF_ANA_PROTECTIONS"			"030_FLUX_9M_JDF_ANA_PROTECTIONS.txt"
#charger_table_start "JDF_ANA_ASSO_PROTECTIONS"		"030_FLUX_9M_JDF_ANA_ASSO_PROTECTIONS.txt"
# FIN LFD

# 02/06/2023 - KLX Risque - M62593 - Projet LTBCE - Ajout table PARAM_MULTIDIM_GENERIQUE
charger_table_start "PARAM_MULTIDIM_GENERIQUE" 		"030_FLUX_9M_PARAM_MULTIDIM_GENERIQUE.txt"

## analyse des erreurs
## -------------------
for fich in $LOG/030_FLUX_*.log
do
  analyse_erreur_loader $fich
done

# 26/09/2018 - CDS ATOS (LFD) - ANACREDIT US 485
#for fich in $LOG/030_JDF*.log
#do
#  analyse_erreur_loader $fich
#done
# FIN LFD


## analyse des fichiers de rejets (.bad)
## si des fichiers bad existent => arret du traitement
## ---------------------------------------------------
if [ -s $LOG/030_FLUX_*.bad ]
then
    echo "   *** --------------------------------------------------------------------------------- ***"
    echo "   *** => EXISTENCE DE FICHIERS DE REJETS (BAD) : voir repertoire $LOG ***"
    echo "   *** --------------------------------------------------------------------------------- ***"
    trace_log "ERR" 50000 " - EXISTENCE DE FICHIERS DE REJETS (BAD) : voir repertoire $LOG"
exit 1
fi



## analyse des erreurs
## -------------------
## passee une fois toutes les tables chargees
## => permet de lister la totalite des tables en erreur pour correction globale
analyse_erreur


DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "--------------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - FIN CHARGEMENT DES DONNEES HISTO DANS DDR-HISTO"
trace_log "INF" 0 "--------------------------------------------------------------"
