#!/bin/ksh
################################################################################
## Script        : 030_CREATION_HIST_CRR_P1BIS.sh                             ##
## Objet         : SIRL-1472 - extraction de la ENG_CORP_P1_BIS pour HCRR     ##
## VERSAO 2026-10-06a                                                         ##
################################################################################
##
## CE SCRIPT EST NOUVEAU : il ne remplace rien.
##   Le critere d'acceptation du ticket dit "aucun impact sur l'historisation
##   des donnees existantes". Un script a part, et un package a part, donnent
##   un impact nul par construction -- pas par verification.
##
## QUAND LE LANCER : APRES le spool, AVANT l'arrete suivant.
##   La P_ALIM_ENG_CORP_P1_BIS commence par un DELETE : la table ne contient
##   que l'arrete courant. Si cette extraction ne tourne pas avant le prochain
##   remplissage, l'arrete est perdu -- et perdu SANS ERREUR.
##
##   Dans la chaine mensuelle :
##       030_CREATION_SPOOL_CRRCORP.sh      remplit la table, ecrit le fichier
##         ... et appelle le _vPACT a la fin
##       030_CREATION_HIST_CRR_P1BIS.sh     <- ICI
##
## A CONFIRMER AVEC LA DSID (voir documentacao/SIRL-1472.md) :
##   le repertoire d'envoi, le nom du fichier et le transfert vers HCRR. Les
##   trois sont en haut, dans des variables, pour n'etre qu'une modification.
##
################################################################################

nom_shell=030_CREATION_HIST_CRR_P1BIS.sh

# -- Le directory Oracle ou UTL_FILE ecrit (SELECT * FROM all_directories)
V30HISTDIR=DIR_ENVOI_CRR

# -- Nom du fichier : le nom de base + la date d'arrete, ajoutee plus bas
V30HISTFIC=HCRR_P1BIS

# -- Logs
V30HISTLOG=030_CREATION_HIST_CRR_P1BIS.log
V30HISTERR=030_CREATION_HIST_CRR_P1BIS_sql.log

DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - DEBUT $nom_shell" $nom_shell
trace_log "INF" 0 "-----------------------------------------------------------"

# -------------------------------
#   La date d'arrete, pour le nom du fichier
# -------------------------------
DT_ARRETE=`sqlplus -s $V30LOGIN <<EOF
set heading off feedback off pagesize 0 trimspool on
select to_char(max(DT_ARRETE), 'YYYYMMDD') from ENG_CORP_P1_BIS;
exit;
EOF`
DT_ARRETE=`echo $DT_ARRETE | tr -d ' '`

if [ -z "$DT_ARRETE" ]
then
  trace_log "ERR" 1 "ENG_CORP_P1_BIS est vide : rien a historiser" $nom_shell
  exit 1
fi

FICHIER=${V30HISTFIC}_${DT_ARRETE}.dat
trace_log "INF" 0 "Arrete $DT_ARRETE - fichier $FICHIER" $nom_shell

# -------------------------------
#   L'extraction
# -------------------------------
sqlplus $V30LOGIN <<EOF  >>$V30RACINE/log/$V30HISTERR
set serveroutput on size 1000000;
whenever oserror exit 9;
whenever sqlerror exit sql.sqlcode;

execute PACK_HIST_ENG_CORP_P1_BIS.P_HIST_ENG_CORP_P1_BIS('$V30HISTDIR', '$FICHIER');

exit;
EOF

RC=$?
if [ $RC -ne 0 ]
then
  trace_log "ERR" $RC "Erreur dans P_HIST_ENG_CORP_P1_BIS" $nom_shell
  exit $RC
fi

# -------------------------------
#   Analyse erreur
# -------------------------------
if [ -f $V30RACINE/log/$V30HISTERR ]
then
  V99015FICLOG=$V30RACINE/log//$V30HISTERR
  export V99015FICLOG
  $EXECRP
  CRP=$?
  if [ $CRP != 0 ]
  then
    trace_log "ERR" $CRP "Erreur SQL durant l extraction" $nom_shell
    exit 1
  fi
fi

DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - FIN $nom_shell" $nom_shell
trace_log "INF" 0 "-----------------------------------------------------------"

exit 0
