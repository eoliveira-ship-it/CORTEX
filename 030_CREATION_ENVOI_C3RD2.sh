#!/usr/bin/ksh
################################################################################
## CAL-Version : 1.1                                                          ##
################################################################################
################################################################################
## Script        : 030_CREATION_ENVOI_C3RD2.sh                                ##
## Objet         : extraction du C3RD v2                                      ##
##                                                                            ##
## Type          : Traitement Shell                                           ##
################################################################################
## Domaine       : RINT                                                       ##
## Application   : 030  - Declarations Des Risques                            ##
################################################################################
## Creation      : le 28/07/2021 par DUGUET MARC                              ##
##                                                                            ##
## Modifications                                                              ##
## -------------                                                              ##
##                                                                            ##
##                                                                            ##
################################################################################

# ---------------------------------------------------------------------------------------------------------------------- 
# 22/07/2021 - CDS ATOS (GBD) - [ CRRV4.3 - C3RD 2.0] US196 Restitution C3RD
# Script developpe a partir de 030_CREATION_ENVOI_C3RD.sh v1.4 pour l'extraction du C3RD v2
#
#  c'est l'ancien C3RD enrichi avec les nouveaux champs et les nouvelles positions et longueurs 
#   mais qu'il faut gerer a part (en parallele) du C3RD qui est en prod actuellement
# ----------------------------------------------------------------------------------------------------------------------


# -- Nom de ce shell
nom_shell=030_CREATION_ENVOI_C3RD2.sh


# -- Nom du fichier d'envoi
V30ENVOIC3FIC=UC2_C3
V30ENVOIC2FIC=UC2_C2
V30ENVOIP7FIC=UC2_P7
V30ENVOIP3FIC=UC2_P3
V30ENVOIM3FIC=UC2_M3
V30ENVOIM3P3FIC=UC2_M3P3
V30EXTRACTM3=SURETE2_M3.dat

# -- Nom du fichier log
V30ENVOIC3RDLOG=030_CREATION_ENVOI_C3RD2.log
#export V30ENVOIC3RDLOG

# -- Nom du fichier d'erreur
V30ENVOIC3RDERR=030_CREATION_ENVOI_C3RD2.err



# ------------------------------------------
# Fonction de trace pour les erreurs gerees
# ------------------------------------------
trace_log()
{
  echo "$1-$2 : $3 - $4"
  echo "$1-$2 : $3 - $4" >> "$V30RACINE/log/$V30ENVOIC3RDLOG"
}


# ---------------------------
# suppression du fichier log
# ---------------------------
if [ -f $V30RACINE/log/$V30ENVOIC3RDLOG ]
 then
  echo "Suppression de l'ancien fichier: $V30RACINE/log/$V30ENVOIC3RDLOG"
   trace_log "INF" 0 " - Suppression de l'ancien fichier: $V30RACINE/log/$V30ENVOIC3RDLOG" $nom_shell
   rm -f $V30RACINE/log/$V30ENVOIC3RDLOG
fi


# --------------------
# Debut de traitement
# --------------------
DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - DEBUT CREATION FICHIER ENVOI POUR CASA"
trace_log "INF" 0 "      (script $nom_shell)"
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "... traitement en cours sous sqlplus ..."

sqlplus $V30LOGIN <<EOF  >>$V30RACINE/log/$V30ENVOIC3RDLOG
set serveroutput on size 1000000;

--CDS_ATOS (CPD) - 19/10/2020 - Mantis 51349 : US 34: Optimisation technique: Gestion des erreurs DDR
whenever oserror exit 9;
whenever sqlerror exit sql.sqlcode;
-- fin CPD

-- les P_UTLF_REMOVE_FILE  sont fait en debut de chaque P_UTLF_xxx

execute pack_utl_file_envoi_c3RD2.P_UTLF_TIE_TIERS_C2('$V30REPTRANSIT2', '$V30ENVOIC2FIC');
execute pack_utl_file_envoi_c3RD2.P_UTLF_TIE_TIERS_C3('$V30REPTRANSIT2', '$V30ENVOIC3FIC');
execute pack_utl_file_envoi_c3RD2.P_UTLF_PROVISIONS_P7('$V30REPTRANSIT2', '$V30ENVOIP7FIC');
execute pack_utl_file_envoi_c3RD2.P_UTLF_CREDIT_P3('$V30REPTRANSIT2', '$V30ENVOIP3FIC');
execute pack_utl_file_envoi_c3RD2.P_UTLF_SURETE_M3('$V30REPTRANSIT2', '$V30ENVOIM3FIC');
execute pack_utl_file_envoi_c3RD2.P_UTLF_LIENS_M3P3('$V30REPTRANSIT2', '$V30ENVOIM3P3FIC');

execute pack_utl_file_envoi_c3RD2.P_EXTRACT_FINANCE_SURETE_M3('$V30REPTRANSIT2', '$V30EXTRACTM3'); 

spool off;

EXIT;
EOF


# -------------------------------
#   Analyse erreur
# -------------------------------
V99015FICLOG=$V99015LOG/$V30ENVOIC3RDLOG
export V99015FICLOG
$EXECRP
CRP=$?
if [ $CRP != 0 ]
then
  echo "Erreur dans 030_CREATION_ENVOI_C3RD"
  exit 1 # CDS_ATOS (CPD) - 19/10/2020 - Mantis 51349 : US 34: Optimisation technique: Gestion des erreurs DDR
fi

DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - FIN CREATION FICHIER ENVOI POUR CASA" $nom_shell
trace_log "INF" 0 "-----------------------------------------------------------"
