################################################################################
## CAL-Version : 1.7                                                          ##
################################################################################
################################################################################
## Script        : 030_CREATION_SPOOL_CRRADAP.sh                              ##
## Objet         : Creation fichier spool CRRADAP                             ##
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
## 16/01/2026 MESQUIPE: SIRL-712 - MERCA                                      ##
## 10/01/2024 GOMESHU : BALE4 - entete 43 => 44                               ##
################################################################################
## 04/02/2022 CUNHAVI : Mantis 11841 - Correction Taille Ligne                ##
## 13/07/2021 MIPAMES : Correction US 216 CRRv4.3                             ##
## 13/07/2021 MIPAMES : US 216 CRRv4.3                                        ##
##                                                                            ##
##                                                                            ##
################################################################################
# -- Nom de ce shell
nom_shell=030_CREATION_SPOOL_CRRADAP.sh


# -- Nom du fichier d'envoi
# /!\ sans extension spool creera un .lst  
V30ENVOICRRFIC="CRRADAP.dat"
#export V30ENVOICRRV4FIC

# -- Nom du fichier log
V30ENVOICRRV4LOG=030_CREATION_SPOOL_CRRADAP.log
#export V30ENVOICRRV4LOG
file_log="${LOG}/${V30ENVOICRRV4LOG}"

# -- Nom du fichier log sql
V30ENVOICRRV4ERR=030_CREATION_SPOOL_CRRADAP_sql.log
#export V30ENVOICRRV4ERR

# requete pour les fichiers spool 

spool_sql="${SQL}/030_spool_Extract_CRRADAP.sql"

# entite de depart (cherche suivante) et compteur
entite="00000"
c=1

# requete pour recuperer une entite (cd_conso_cpt) a partir de la liste des entites qui ecriront les fichiers
# SQL2 a 4 : requete pour avoir la liste des entites  qui ecriront les fichiers
# generee a partir de la  
# requete dans P_UTLF_DEGRADE_A1   (SQL2)
# requete dans P_UTLF_AUTO_A1      (SQL4)
SQL1=" SELECT cd_conso_cpt FROM ("
SQL2="SELECT DISTINCT cd_conso_cpt FROM A1_CRRV4_DEGRADE WHERE CD_STATUT_LIGNE = 'V' AND DT_ARRETE = (select max(dt_arrete) from eng_corp_p1)" 
SQLU=" UNION "
SQL4="SELECT DISTINCT cd_conso_cpt FROM A1_DEGRADE_AUTO  WHERE CD_STATUT_LIGNE = 'V' AND DT_ARRETE = (select max(dt_arrete) from eng_corp_p1)"
#SIRL-712
#SQL5="SELECT '00357' AS cd_conso_cpt FROM A1_DEGRADE_GMBH" ## KLx CRRv4.3 - Leasing Germany - US 279 
SQL5="SELECT '00416' AS cd_conso_cpt FROM A1_DEGRADE_GMBH" ## KLx CRRv4.3 - Leasing Germany - US 279 
# pour recuperer une entite parametree (et verifier si c'est bien une entite) 
SQLX=") WHERE cd_conso_cpt = '${param}';"

SQL_entite=${SQL1}${SQL2}${SQLU}${SQL4}${SQLU}${SQL5}${SQLX} ## Fin KLx CRRv4.3 - Leasing Germany - US 279 

# KLx CRRv4.3 - Leasing Germany - US 279 
# Extraire A1_DEGRADE_GMBH uniquement s'il n'y a pas de rejet
rejets=`sqlplus -s $V30LOGIN <<EOF
SET heading off
select TO_CHAR(count(*)) AS REJETS from REJET_DEGRADE_GMBH;
EXIT;
EOF
`

rejets=`echo "${rejets}" | tr -d '\r\n'`

# ------------------------------------------
# Fonction de trace pour les erreurs gerees
# ------------------------------------------
trace_log()
{
  echo "$1-$2 : $3 - $4"
  echo "$1-$2 : $3 - $4" >> "${LOG}/$V30ENVOICRRV4LOG"
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
# Fonction Extraction d'une entite : ecriture du fichier
# CRRADAP pour la partie CRR adapte : tous les A1 qu'ils soient automatiques ou saisis.
# ---------------------------------------------------

extract_entite()
{

trace_log "INFO" 0 "Extraction de l entite : ${entite}"
trace_log "INFO" 0 "Nombre de rejets" "${rejets}"

# KLx CRRv4.3 - Leasing Germany - US 279 - Passage du nombre de rejet au SQL
# ecriture su spool : mis des variable et des parametres 
execution_requete=`sqlplus -s $V30LOGIN << EOF >>${LOG}/$V30ENVOICRRV4ERR 2>>${file_log}
whenever sqlerror exit 1
whenever oserror exit 2
set serveroutput on size 1000000
var ENTITE varchar2(5);
exec :ENTITE := '${entite}';
var REJETNUMBER number ;
exec :REJETNUMBER:= TO_NUMBER( replace('${rejets}','	','') ) ;
var MASYSDATE varchar2(12)
exec :MASYSDATE := '${masysdate}'

@$spool_sql $SORTIE $V30ENVOICRRFIC;
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
             #chmod 777 $LOG/030_CREATION_SPOOL_CRRADAP*
             #chmod 777 $SORTIE/CRRADAP*
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
     #chmod 777 $LOG/030_CREATION_SPOOL_CRRRETA*
     #chmod 777 $SORTIE/CRRRETA*
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
  finlignehead=`printf "%1886s" " " ` ##BALE4

  #echo "00;00000535;001;$masysdateZ;00370;00370;$appemettrice;CRRA;43;$xnumenvoi;M;$dtarrete;00001;$appemettricefin;$finlignehead"  >> $SORTIE/$V30ENVOICRRFIC ## BALE4
  echo "00;00000535;001;$masysdateZ;00370;00370;$appemettrice;CRRA;44;$xnumenvoi;M;$dtarrete;00001;$appemettricefin;$finlignehead"  >> $SORTIE/$V30ENVOICRRFIC ## BALE4

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
#  '' -- 32 blancs	                   -- Application emettrice   
#  ';'                                 -- separateur 7
#  'CRRA'                              -- Code du flux : "CRRC" pour corporate "CRRR" pour retail "CRRA" pour adapte
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
#  '     ' -- 5 lancs             	-- Application ï¿½mettrice Finance
#  ';'                                 -- sï¿½parateur 14
#  ' '									-- filler de fin
}

# ---------------------------------------------------
# Fonction Ecriture de la ligne Z9 du fichier
# ---------------------------------------------------
ecris_Z9()
{
  
  # sysdate au format 'YYYYMMDDHH24MI'   et au format ISO 8601 
  masysdate=`date '+%Y%m%d%H%M' `
  NatureFlux=`printf "%10s" " " `
  Champs2a4="00370C_BTR       M"
  TypeLigne="Z9"
  nbtotligne=`wc -l $SORTIE/$V30ENVOICRRFIC | cut -d' ' -f1`
  # Z9 ne doit pas comtper le header 
  nbtotligne=$(($nbtotligne - 1))
  trace_log "INFO" 0  " Nbre d enregistrement : $nbtotligne"
  # formate en 12 decimal avec des 0 a gauche
  ftotligne=`printf "%012d" $nbtotligne `
  #finlignez9=`printf "%5037s" " " `
  finlignez9=`printf "%1938s" " " ` ##BALE4

  echo "$dtarrete$Champs2a4$masysdate$TypeLigne$NatureFlux$ftotligne$finlignez9" >>  $SORTIE/$V30ENVOICRRFIC

  
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
#  '' -- 32 blancs	                   -- Application emettrice   
#  ';'                                 -- separateur 7
#  'CRRA'                              -- Code du flux : "CRRC" pour corporate "CRRR" pour retail "CRRA" pour adapte
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
#  '     ' -- 5 lancs             	-- Application ï¿½mettrice Finance
#  ';'                                 -- sï¿½parateur 14
#  ' '									-- filler de fin
}
# -------------------------------------------------------------------------------------------------
# T R A I T E M E N T   P R I N C I P A L
# -------------------------------------------------------------------------------------------------


# ---------------------------
# suppression du fichier log
# ---------------------------
if [ -f ${LOG}/$V30ENVOICRRV4LOG ]
 then
  echo "Suppression de l'ancien fichier: ${LOG}/$V30ENVOICRRV4LOG"
   rm -f ${LOG}/$V30ENVOICRRV4LOG
   trace_log "INF" 0 " - Suppression de l'ancien fichier: ${LOG}/$V30ENVOICRRV4LOG" $nom_shell
fi


if [ -f ${LOG}/$V30ENVOICRRV4ERR ]
 then
  echo "Suppression de l'ancien fichier: ${LOG}/$V30ENVOICRRV4ERR"
   trace_log "INF" 0 " - Suppression de l'ancien fichier: ${LOG}/$V30ENVOICRRV4ERR" $nom_shell
   rm -f ${LOG}/$V30ENVOICRRV4ERR
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
SQL_entite=${SQL1}${SQL2}${SQLU}${SQL4}${SQLU}${SQL5}${SQLX} ## KLx CRRv4.3 - Leasing Germany - US 279 

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

# Ecriture du Z9 a la fin de l'extraction du A1
ecris_Z9

# -------------------------------
#   Ecriture de l'enqueue
# -------------------------------
if [[ -f $SORTIE/$V30ENVOICRRFIC ]]; then
  
   #  retrouve le nbre de ligne ds fic sortie
   nbtotligne=`wc -l $SORTIE/$V30ENVOICRRFIC | cut -d' ' -f1`
   # ajoute +1 (enqueue)
   nbtotligne=$(($nbtotligne + 1))

   trace_log "INFO" 0  " Nbre de lignes : $nbtotligne"
   # formate en 12 decimal avec des 0 a gauche
   xtotligne=`printf "%010d" $nbtotligne `
   # ecris un 1 en fin de ligne 
   #finligne=`printf "%884s" 1 `
   # ecris 5085 blancs en fin de ligne  
  # finligne=`printf "%5085s" " " `
   finligne=`printf "%1986s" " " `
	#echo"....;$finligne" >>
   
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
if [ -f ${LOG}/$V30ENVOICRRV4LOG ]
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

if [ -f ${LOG}/$V30ENVOICRRV4ERR ]
 then
  V99015FICLOG=${LOG}/$V30ENVOICRRV4ERR
  export V99015FICLOG
  $EXECRP
  CRP=$?
  if [ $CRP != 0 ]
  then
    echo "Erreur dans $V30ENVOICRRV4ERR"
    exit $CRP
  fi
fi
DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `
trace_log "INF" 0 "-----------------------------------------------------------"
trace_log "INF" 0 "$DATE_TRT - FIN CREATION FICHIER ENVOI POUR CASA" $nom_shell
trace_log "INF" 0 "-----------------------------------------------------------"

# -------------------------------
#  Droits pour tests
# -------------------------------
# chmod 777 $LOG/030_CREATION*CRRADAP*
# chmod 777 $SORTIE/CRRADAP*

