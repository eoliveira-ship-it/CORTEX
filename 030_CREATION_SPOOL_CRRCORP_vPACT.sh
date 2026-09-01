################################################################################
## CAL-Version : 1.41                                                         ##
################################################################################
################################################################################
## Script        : 030_CREATION_SPOOL_CRRCORP_vPACT.sh                        ##
## Objet         : Creation fichier spool CRRCORP                             ##
##                                                                            ##
## Type          : Traitement Shell                                           ##
################################################################################
## Domaine       : RINT                                                       ##
## Application   : 030  - Declarations Des Risques                            ##
################################################################################
## Creation      : le 18/05/2021 par DUGUET MARC                              ##
##                                                                            ##
## Modifications                                                              ##
## -------------                                                              ##
## 10/01/2024 GOMESHU : BALE4 - entete 43 => 44                               ##
################################################################################
## 29/05/2025 MESQUIPE: RSE_LOT3: SIRL-153                                    ## 
## 04/02/2022 CUNHAVI : Mantis 11841 - Correction Taille Ligne                ##
## 13/07/2021 MIPAMES : US 194 CRRv4.3                                        ##
##                                                                            ##
##                                                                            ##
################################################################################
# -- Nom de ce shell
nom_shell=030_CREATION_SPOOL_CRRCORP_vPACT.sh


# -- Nom du fichier d'envoi
# /!\ sans extension spool creera un .lst  
V30ENVOICRRFIC="CRRCORP_vPACT.dat"
#export V30ENVOICRRV4FIC

# -- Nom du fichier log
V30ENVOICRRV4LOG=030_CREATION_SPOOL_CRRCORP_vPACT.log
#export V30ENVOICRRV4LOG
file_log="${V30RACINE}/log/${V30ENVOICRRV4LOG}"

# -- Nom du fichier log sql
V30ENVOICRRV4ERR=030_CREATION_SPOOL_CRRCORP_sql_vPACT.log
#export V30ENVOICRRV4ERR

# requete pour les fichiers spool 

spool_sql="${SQL}/030_spool_Extract_CRRCORP_vPACT.sql"

# entite de depart (cherche suivante) et compteur
entite="00000"
c=1

# requete pour recuperer une entite (cd_conso_cpt) a partir de la liste des entites qui ecriront les fichiers
SQL0=" SELECT cd_conso_cpt FROM ("
# SQL1 a n : requete pour avoir la liste des entites  qui ecriront les fichiers
# requete dans P_UTLF_TIERS_C5                (SQL1)
# requete dans P_UTLF_ENG_CORP_P1             (SQL2)
# requete dans P_UTLF_ENG_CORP_P2             (SQL3)
# requete dans P_UTLF_SURETE_M1               (SQL4)
# requetes dans autres : pas necessaire : les 4 premiers devraient etre suffisantes 
SQL1="SELECT DISTINCT cd_conso_cpt FROM TIE_TIERS_C1_C5 WHERE A_EXTRAIRE ='O' AND CD_TYPE_SEGMENT = 'CORP'" 
SQL2="SELECT DISTINCT cd_conso_cpt FROM ENG_CORP_P1 WHERE A_EXTRAIRE ='O'" 
SQL3="SELECT DISTINCT cd_conso_cpt FROM ENG_CORP_P2 WHERE A_EXTRAIRE ='O'" 
SQL4="SELECT DISTINCT cd_conso_cpt FROM SURETE_M1 WHERE A_EXTRAIRE ='O'" 

SQLU=" UNION "
# pour recuperer une entite parametree (et verifier si c'est bien une entite) 
SQLX=") WHERE cd_conso_cpt = '${param}';"


SQL_entite=${SQL0}${SQL1}${SQLU}${SQL2}${SQLU}${SQL3}${SQLU}${SQL4}${SQLX}
# ------------------------------------------
# Fonction de trace pour les erreurs gerees
# ------------------------------------------
trace_log()
{
  echo "$1-$2 : $3 - $4"
  echo "$1-$2 : $3 - $4" >> "$V30RACINE/log/$V30ENVOICRRV4LOG"
}

# ---------------------------------------------------
# Fonction qui Recupere l'entite a traiter et verifie 
# ---------------------------------------------------
verif_entite()
{
# lance la requete pour recuperer une entite
execution_requete=`sqlplus -s $V30LOGIN << EOF
whenever sqlerror exit 1
whenever oserror exit 2
set heading off
set feedback off
$SQL_entite
exit;
EOF
`
EXECUTION_REQUETE_ERROR=$?

if [[ $EXECUTION_REQUETE_ERROR -ne 0 ]] || [[ $execution_requete == *"ORA-"* ]] || [[ $execution_requete == *"SP2-"* ]]; then
	    trace_log "ERROR" 5000 "Erreur lors de l'execution de la requete " $nom_shell
		echo "<$SQL_entite>" >> ${file_log}
		echo "${execution_requete}" >> ${file_log}
		echo "*****************************************************************************************************" >> ${file_log}
		echo "" >> ${file_log}
		echo "Erreur lors de l'execution d'une requete SQL : voir le fichier log <${V30ENVOICRRV4LOG}>"
		exit 1
fi
# /!\ entite=$execution_requete  renvoi un saut de ligne puis le resultat

# transforme en supprimant return et newligne 
entite=`echo "${execution_requete}" | tr -d '\r\n'`
 echo "entite $c : >${entite}<"

}
# ---------------------------------------------------
# Fonction qui Recupere la date d'arrete
# ---------------------------------------------------
recup_arrete()
{
SQL_arrete="select to_char(nvl((SELECT max(dt_arrete) FROM TIE_TIERS),(SELECT max(dt_arrete) FROM ENG_CORP_P1)),'YYYYMMDD') from dual;"

# lance la requete pour recuperer la date d'arrete
execution_requete=`sqlplus -s $V30LOGIN << EOF
whenever sqlerror exit 1
whenever oserror exit 2
set heading off
set feedback off
$SQL_arrete
exit;
EOF
`
EXECUTION_REQUETE_ERROR=$?

if [[ $EXECUTION_REQUETE_ERROR -ne 0 ]] || [[ $execution_requete == *"ORA-"* ]] || [[ $execution_requete == *"SP2-"* ]]; then
	    trace_log "ERROR" 5000 "Erreur lors de l'execution de la requete " $nom_shell
		echo "<$SQL_arrete>" >> ${file_log}
		echo "${execution_requete}" >> ${file_log}
		echo "*****************************************************************************************************" >> ${file_log}
		echo "" >> ${file_log}
		echo "Erreur lors de l'execution d'une requete SQL : voir le fichier log <${V30ENVOICRRV4LOG}>"
		exit 1
fi
# /!\ entite=$execution_requete  renvoi un saut de ligne puis le resultat

# transforme en supprimant return et newligne 
dtarrete=`echo "${execution_requete}" | tr -d '\r\n'`
 echo "Date arrete : >${dtarrete}<"

}
# ---------------------------------------------------
# Fonction qui Recupere le num envoi 
# ---------------------------------------------------
recup_numenvoi()
{
SQL_numenvoi="SELECT SEQ_ENVOI_CRRV4 FROM PAR_ENVOI_CRRV43 WHERE nom_fichier = '$V30ENVOICRRFIC' AND cd_conso_cpt = 'TOTAL'  AND DT_ARRETE = to_date('${dtarrete}','YYYYMMDD');"
MG1="Merge into PAR_ENVOI_CRRV43 mge"
MG2=" USING (select '$V30ENVOICRRFIC' as nom_fichier, 'TOTAL' as cd_conso_cpt, to_date('${dtarrete}','YYYYMMDD') as dt_arrete from dual) par"
MG3="  ON ( par.nom_fichier = mge.nom_fichier and par.cd_conso_cpt = mge.cd_conso_cpt and par.dt_arrete = mge.dt_arrete)"
MG4="  WHEN MATCHED THEN UPDATE SET mge.seq_envoi_cRRV4 = mge.seq_envoi_cRRV4 + 1, mge.date_traitement = sysdate"
MG5="  WHEN NOT MATCHED THEN INSERT (NOM_FICHIER, CD_CONSO_CPT, DT_ARRETE, SEQ_ENVOI_CRRV4, DATE_TRAITEMENT)"
MG6="  VALUES ('$V30ENVOICRRFIC','TOTAL', (to_date('${dtarrete}','YYYYMMDD')), 1, sysdate);"
SQL_majnum=${MG1}${MG2}${MG3}${MG4}${MG5}${MG6}
# lance la requete pour maj et recuperer le num envoi
execution_requete=`sqlplus -s $V30LOGIN << EOF
whenever sqlerror exit 1
whenever oserror exit 2
set heading off
set feedback off
$SQL_majnum
commit;
$SQL_numenvoi
exit;
EOF
`
EXECUTION_REQUETE_ERROR=$?

if [[ $EXECUTION_REQUETE_ERROR -ne 0 ]] || [[ $execution_requete == *"ORA-"* ]] || [[ $execution_requete == *"SP2-"* ]]; then
	    trace_log "ERROR" 5000 "Erreur lors de l'execution de la requete " $nom_shell
		echo "<$SQL_majnum>" >> ${file_log}
		echo "${execution_requete}" >> ${file_log}
		echo "*****************************************************************************************************" >> ${file_log}
		echo "" >> ${file_log}
		echo "Erreur lors de l'execution d'une requete SQL : voir le fichier log <${V30ENVOICRRV4LOG}>"
		exit 1
fi
# /!\ entite=$execution_requete  renvoi un saut de ligne puis le resultat

# transforme en supprimant return et newligne 
numenvoi=`echo "${execution_requete}" | tr -d '\r\n'`
 echo "Num envoi : >${numenvoi}<"

}
# ---------------------------------------------------
# Fonction Extraction d'une entite : ecriture du fichier CCRCORP
# 
# ---------------------------------------------------

extract_entite()
{

trace_log "INFO" 0 "Extraction de l entite : ${entite}"


# ecriture su spool : mis des variable et des parametres 
execution_requete=`sqlplus -s $V30LOGIN << EOF >>$V30RACINE/log/$V30ENVOICRRV4ERR 2>>${file_log}
whenever sqlerror exit 1
whenever oserror exit 2
set serveroutput on size 1000000
var ENTITE varchar2(5)
exec :ENTITE := '${entite}'
var MASYSDATE varchar2(12)
exec :MASYSDATE := '${masysdate}'
@$spool_sql $SORTIE $V30ENVOICRRFIC ;
exit;
EOF
`

EXECUTION_REQUETE_ERROR=$?
 
if [[ $EXECUTION_REQUETE_ERROR -ne 0 ]] || [[ $execution_requete == *"ORA-"* ]] || [[ $execution_requete == *"SP2-"* ]]; then
	    trace_log "ERROR" 5000 "Erreur lors de l'execution de la requete spool " $nom_shell
		echo "<spool_sql>=$EXECUTION_REQUETE_ERROR" >> ${file_log}
		echo "" >> ${file_log}
		echo "*****************************************************************************************************" >> ${file_log}
		echo "" >> ${file_log}
		echo "Erreur lors de l'execution d'une requete SQL : voir le fichier log <${V30ENVOICRRV4LOG}>"

        if [[ -f $SORTIE/$V30ENVOICRRFIC ]]; then
    	   if grep -q "^ORA-[0-9]" "$SORTIE/$V30ENVOICRRFIC"; then 
           trace_log "ERROR" 4000 "Erreur dans l'ecriture du fichier " $nom_shell
              # copie 50 lignes de fin du fichier sortie ds log
              tail -50 "$SORTIE/$V30ENVOICRRFIC" >> ${file_log}
    		  echo "" >> ${file_log}
    		  echo "*****************************************************************************************************" >> ${file_log}
    		  echo "" >> ${file_log}
 	          #echo "Supprime le fichier sortie car copie ds log"
   		      #rm -f $SORTIE/$V30ENVOICRRFIC    
              # pour test : droit 
              #chmod 777 $LOG/030_CREATION_SPOOL_CRRCORP*
              #chmod 777 $SORTIE/CRRCORP*
       	   fi
       fi 
	  exit 1
fi
# on a pas d'erreur SQL mais on a ecrit SP2-nnnnn ou ORA-nnnnn en debut ligne
if [[ -f $SORTIE/$V30ENVOICRRFIC ]]; then
   if grep -q "^SP2-[0-9]" "$SORTIE/$V30ENVOICRRFIC"; then 
    trace_log "ERROR" 3000 "Erreur SP2 dans l'ecriture du fichier " $nom_shell
      # copie 50 lignes de fin du fichier sortie ds log
      tail -50 "$SORTIE/$V30ENVOICRRFIC" >> ${file_log}
	  echo "" >> ${file_log}
	  echo "*****************************************************************************************************" >> ${file_log}
	  echo "" >> ${file_log}
      #echo "Supprime le fichier sortie car copie ds log"
      #rm -f $SORTIE/$V30ENVOICRRFIC    
      # pour test : droit 
      #chmod 777 $LOG/030_CREATION_SPOOL_CRRCORP*
      #chmod 777 $SORTIE/CRRCORP*
      exit 1
   fi
   # requete SQL ok mais il a ecris erreur dans fichier
   if grep -q "^ORA-[0-9]" "$SORTIE/$V30ENVOICRRFIC"; then 
      trace_log "ERROR" 4000 "Erreur ORA ecrite dans le fichier " $nom_shell
      # copie 50 lignes de fin du fichier sortie ds log
      tail -50 "$SORTIE/$V30ENVOICRRFIC" >> ${file_log}
      echo "" >> ${file_log}
      echo "*****************************************************************************************************" >> ${file_log}
      echo "" >> ${file_log}
      exit 1
   fi
fi 
}

# ---------------------------------------------------
# Fonction Ecriture entete du fichier
# ---------------------------------------------------
ecris_entete()
{
  #masysdate=$(date +"%m/%d/%Y %T")
  # sysdate au format 'YYYYMMDDHH24MI'   et au format ISO 8601 
  masysdate=`date '+%Y%m%d%H%M' `
  masysdateZ=`date '+%Y%m%dT%H%M%S' `
  xnumenvoi=`printf "%05d" $numenvoi `
  appemettrice=`printf "%32s" " " `
  appemettricefin=`printf "%5s" " " `
  #finlignehead=`printf "%4985s" " " `
  finlignehead=`printf "%7886s" " " `
  #echo "00;00000533;001;$masysdateZ;00370;00370;$appemettrice;CRRC;43;$xnumenvoi;M;$dtarrete;00001;$appemettricefin;$finlignehead"  >> $SORTIE/$V30ENVOICRRFIC ## BALE4 
  echo "00;00000533;001;$masysdateZ;00370;00370;$appemettrice;CRRC;44;$xnumenvoi;M;$dtarrete;00001;$appemettricefin;$finlignehead"  >> $SORTIE/$V30ENVOICRRFIC ## BALE4

#  Description dans l'excell : 
#  '00'                                -- Type d'enregistrement
#  ';'                                 -- separateur 1
#  '00000533'                          -- Identifiant du fichier : "00000533" pour corporate  "00000534" pour retail "00000535" pour adapte
#  ';'                                 -- separateur 2
#  '001'                               -- Version technique du fichier
#  ';'                                 -- separateur 3
#   sysdate en 'YYYYMMddThhmmss'       -- Horodatage  Date et heure de production du fichier (norme ISO 8601 : separateur normalise a T a entre la date et l'heure)
#  ';'                                 -- separateur 4
#  '00370'                             -- Entite emettrice      LC.3 Liste des codes consolidation comptable : 00370
#  ';'                                 -- separateur 5
#  '00370'                             -- Entite declarante
#  ';'                                 -- separateur 6
#  '' -- Non alimente	               -- Application emettrice   
#  ';'                                 -- separateur 7
#  'CRRC'                              -- Code du flux : "CRRC" pour corporate "CRRR" pour retail "CRRA" pour adapte
#  ';'                                 -- separateur 8
#  '43'                                -- Version du flux
#  ';'                                 -- separateur 9
#  NUMENVOI en lg 5,  0 a gauche       -- Numero d'envoi du fichier Permet de gerer les reemissions A alimenter a "00001" et a incrementer de +1 a chaque reemission sequence par entite, par mois  a initier
#  ';'                                 -- separateur 10
#  'M'                                 -- Type d'arrete   'M'ensuel  'H'ebdo 'Q'uainzaine
#  ';'                                 -- separateur 11
#  dtarrete en 'YYYYMMDD'              -- Date d'arrete (YYYYMMDD)
#  ';'                                 -- separateur 12
#  '00001'	                           -- Numero de sequence du fichier
#  ';'                                 -- separateur 13
#  '' -- Non alimente                  -- Application emettrice Finance
#  ';'                                 -- separateur 14

}


# -------------------------------------------------------------------------------------------------
# T R A I T E M E N T   P R I N C I P A L
# -------------------------------------------------------------------------------------------------


# ---------------------------
# suppression du fichier log
# ---------------------------
if [ -f $V30RACINE/log/$V30ENVOICRRV4LOG ]
 then
  echo "Suppression de l'ancien fichier: $V30RACINE/log/$V30ENVOICRRV4LOG"
   rm -f $V30RACINE/log/$V30ENVOICRRV4LOG
   trace_log "INF" 0 " - Suppression de l'ancien fichier: $V30RACINE/log/$V30ENVOICRRV4LOG" $nom_shell
fi


if [ -f $V30RACINE/log/$V30ENVOICRRV4ERR ]
 then
  echo "Suppression de l'ancien fichier: $V30RACINE/log/$V30ENVOICRRV4ERR"
   trace_log "INF" 0 " - Suppression de l'ancien fichier: $V30RACINE/log/$V30ENVOICRRV4ERR" $nom_shell
   rm -f $V30RACINE/log/$V30ENVOICRRV4ERR
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

# -------------------------------
# suppression du fichier d'envoi
# -------------------------------
if [[ -f $SORTIE/$V30ENVOICRRFIC ]]; then
    echo "Suppression de l'ancien fichier: $SORTIE/$V30ENVOICRRFIC"
    trace_log "INF" 0 " - Suppression de l'ancien fichier: $SORTIE/$V30ENVOICRRFIC" $nom_shell
    rm -f $SORTIE/$V30ENVOICRRFIC     
fi

# --------------------
# Recup date arrete
# --------------------
recup_arrete

# --------------------
# Recup num envoi
# recuperation et maj du numenvoi
# --------------------
recup_numenvoi

# --------------------
# Si pas de parametres : extraction complete
# --------------------
if [ $# = 0 ]
then

trace_log "INF" 0 "Extraction complete (toutes les entites)"  $nom_shell

# on veut recuperer toutes les entites : 
entite="TOTAL"

# -------------------------------
#   Ecriture de l'entete
# -------------------------------
ecris_entete

# --------------------
# extraction et ecriture fichier
# --------------------
extract_entite

else
# --------------------
# CAS avec n parametres : extraction entite demandee
# --------------------

trace_log "INF" 0 "Traitement des parametres (entite en char 5)"  $nom_shell

# -------------------------------
#   Ecriture de l'entete
# -------------------------------
ecris_entete

# --------------------
# boucle parametre
# --------------------
for param in "$@"
do
 trace_log "INF" 0 "Traitement du parametre  $param "  $nom_shell
 echo -e "	Parametre : $param"

# verifie le parametre en entree est une entite
SQLX=") WHERE cd_conso_cpt = '${param}';"
SQL_entite=${SQL0}${SQL1}${SQLU}${SQL2}${SQLU}${SQL3}${SQLU}${SQL4}${SQLX}

verif_entite

# table vide ou parametre ko 
if [[ $entite == "" ]]; then
   trace_log "WARN" 100 "Aucune ligne retournee lors de l'execution de la requete" $nom_shell
   echo "<$SQL_entite>" >> ${file_log}
   echo "Verifier si l'entite parametree <$param> est ds les tables " >> ${file_log}
   echo "*****************************************************************************************************" >> ${file_log}
   echo "" >> ${file_log}
   echo "Warning lors de l'execution d'une requete SQL : voir le fichier log <${V30ENVOICRRV4LOG}>"
   # exit 1
else

   if [ "$c" -lt 1 ]; then 
      # -------------------------------
      #   Ecriture de l'entete
      # -------------------------------
      ecris_entete
   fi

   extract_entite
   c=$(($c + 1))

fi

done
# fin boucle parametre


fi # fin 1 ou n parametres 

# -------------------------------
#   Ecriture de l'enqueue
# -------------------------------
if [[ -f $SORTIE/$V30ENVOICRRFIC ]]; then
  
   #  retrouve le nbre de ligne ds fic sortie
   nbtotligne=`wc -l $SORTIE/$V30ENVOICRRFIC | cut -d' ' -f1`
   # ajoute +1 (enqueue)
   nbtotligne=$(($nbtotligne + 1))

   trace_log "INFO" 0  " Nbre de lignes : $nbtotligne"
   # formate en 10 decimal avec des 0 a gauche
   xtotligne=`printf "%010d" $nbtotligne `
   # ecris des blancs en fin de ligne 
   #finligne=`printf "%884s" 1 `
   #finligne=`printf "%5085s" " " `
   finligne=`printf "%7986s" " " `
   # ecris ds fichier 
   echo "99;$xtotligne;$finligne"  >> $SORTIE/$V30ENVOICRRFIC
   #echo "99;$xtotligne;"  >> $SORTIE/$V30ENVOICRRFIC

   if [ "$nbtotligne" -le 2 ]; then 
      trace_log "WARN" 100 "Supprime le fichier sortie car Aucune lignes retournees" $nom_shell  
      rm -f $SORTIE/$V30ENVOICRRFIC    
   # else 
   #    # En test : compresse car ENORME 
   #    gzip -f9 $SORTIE/$V30ENVOICRRFIC
   fi

fi 


trace_log "INFO" 0 "Fin de l'extraction"


# -------------------------------
#   Analyse erreur
# -------------------------------
if [ -f $V30RACINE/log/$V30ENVOICRRV4LOG ]
 then
  V99015FICLOG=$V99015LOG/$V30ENVOICRRV4LOG
  export V99015FICLOG
  $EXECRP
  CRP=$?
  if [ $CRP != 0 ]
  then
    echo "Erreur dans $V30ENVOICRRV4LOG"
    exit $CRP
  fi
fi 

if [ -f $V30RACINE/log/$V30ENVOICRRV4ERR ]
 then
  V99015FICLOG=$V30RACINE/log/$V30ENVOICRRV4ERR
  export V99015FICLOG
  $EXECRP
  CRP=$?
  if [ $CRP != 0 ]
  then
    echo "Erreur dans $V30ENVOICRRV4ERR"
    exit $CRP
  fi
fi


## RSE_LOT3: SIRL-153 - 29/05/2025 - Remplissage de la table PERIM_ENVOI_CRR_P1
sqlplus $V30LOGIN <<EOF  >>$V30RACINE/log/$V30ENVOICRRV4ERR
set serveroutput on size 1000000;
whenever oserror exit 9;
whenever sqlerror exit sql.sqlcode;

execute PACK_ALIM_TAB_ENVOI_CRRV4.P_ALIM_PERIM_ENVOI_CRR_P1;

spool off;

EXIT;
EOF

# -------------------------------
#   Analyse erreur
# -------------------------------
if [ -f $V30RACINE/log/$V30ENVOICRRV4ERR ]
then
  V99015FICLOG=$V30RACINE/log//$V30ENVOICRRV4ERR
  export V99015FICLOG
  $EXECRP
  CRP=$?
  if [ $CRP != 0 ]
  then
    echo "Erreur dans 030_CREATION_SPOOL_CRRCORP durant P_ALIM_PERIM_ENVOI_CRR_P1"
    exit 1
  fi
fi

DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - FIN CREATION FICHIER ENVOI POUR CASA" $nom_shell
trace_log "INF" 0 "-----------------------------------------------------------"

# -------------------------------
#  Droits pour tests
# -------------------------------
# chmod 777 $LOG/030_CREATION*CRRCORP*
# chmod 777 $SORTIE/CRRCORP*
