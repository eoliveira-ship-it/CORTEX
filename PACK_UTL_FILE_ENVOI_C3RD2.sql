create or replace PACKAGE PACK_UTL_FILE_ENVOI_C3RD2
AS

  -- constantes
  v_dt_arrete DATE   := pack_utilitaire.f_calc_dt_arrete;
  g_nb_lignes     NUMBER := 0;
  g_dt_traitement DATE := SYSDATE;

	-- fonctions et procedures
	PROCEDURE P_UTLF_REMOVE_FILE (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_UTLF_PROVISIONS_P7 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_UTLF_TIE_TIERS_C2 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_UTLF_TIE_TIERS_C3 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_UTLF_CREDIT_P3 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_UTLF_SURETE_M3 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_UTLF_LIENS_M3P3 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);
	PROCEDURE P_EXTRACT_FINANCE_SURETE_M3 (p_chemin IN VARCHAR2, p_nom_fichier IN VARCHAR2);-- 02/03/2020 - CDS ATOS (LFD) - US 344 FINREP

END PACK_UTL_FILE_ENVOI_C3RD2 ;
/

create or replace PACKAGE BODY PACK_UTL_FILE_ENVOI_C3RD2
AS

-- -----------------------------------------------------------
-- Procedure  P_UTLF_REMOVE_FILE
--
-- -----------------------------------------------------------
-- Description : Suppression de l'ancien fichier envoi vers CASA.
--
-- Entrees :  -chemin du fichier d'envoi.
--            -nom du fichier d'envoi.
-- Sorties :
-- -----------------------------------------------------------
PROCEDURE P_UTLF_REMOVE_FILE (p_chemin      IN VARCHAR2,
                              p_nom_fichier IN VARCHAR2)
IS

 p_exists          BOOLEAN;
 p_taille_fichier  NUMBER;
 p_taille_bloc     NUMBER;

BEGIN

  dbms_output.enable(100000);

  p_exists         := FALSE;
  p_taille_fichier := 0;
  p_taille_bloc    := 0;

  UTL_FILE.FGETATTR(p_chemin, p_nom_fichier,
                    p_exists, p_taille_fichier, p_taille_bloc);

  IF p_exists = TRUE
  THEN
    UTL_FILE.FREMOVE (p_chemin, p_nom_fichier);
   ELSE
    NULL;

  END IF;

  EXCEPTION
     WHEN OTHERS THEN
       pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur Remove File',50072);

END P_UTLF_REMOVE_FILE;
--------------------------------------------------------------------
--ENVOYER SOCIETE MEME SI ELLE EST ABSENTE DANS P7 ALORS GENERER FICHIER VIDE : MODIF LY le 28-02-2018
--------------------------------------------------------------------
PROCEDURE P_UTLF_PROVISIONS_P7 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
  l_etape    VARCHAR2(30);
  CD_RETOUR  VARCHAR2(30);
  MSG_RETOUR VARCHAR2(250);

  v_crr_descripteur UTL_FILE.FILE_TYPE;
  -- BALE4 AVANT 414. 2000
  v_head     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE.
  --v_ligne     VARCHAR2(245); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(2000); -- 11/02/2019 - CRRV4.2 - correctif
  v_tail     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE.
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;
  type liste_cd_conso is table of varchar2(5); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  cd_cpt liste_cd_conso; -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803


--  CURSOR C_CONSO
--  is select distinct cd_conso_cpt from Eng_Corp_P1;


  ---------------------
  CURSOR C_P7 (p_cd_conso_cpt CHAR)
  IS
   Select
      P.DT_ARRETE			,
		  P.CD_CONSO_CPT		,
		  P.CD_SYS_INT		,
		  P.ID_PROVISION		,
		  P.ID_ENGAGEMENT		,
		  P.CD_NAT_DEPRE		,
		  P.MNT_PROVISION		,
		  P.MNT_PROVISION_TRIM,
		  P.CD_DEVISE
		  -- 04/02/2019 - CDS ATOS (LFD) - CRRV4.2 US 676
		,ORIGINE_CALCUL_PROVISION
		-- FIN LFD
    -- US196
    ,null                    as CdEntSucc
    ,CD_TYPE_PROD_BANCAIRE   as cdTypProd
    ,mtProvBilan             as mtProvBilan
    ,mtProvHB                as mtProvHB
    ,mtProvArrPrecBilan      as mtProvArrPrecBilan
    ,mtProvArrPrecHB         as mtProvArrPrecHB
    ,cdDevEntCmpt            as cdDevEntCmpt
    ,cdPCCOProvDep           as cdPCCOProvDep
    ,mtProvDep               as mtProvDep
    ,null                    as cdPCCOProvSurDec
    ,null                    as mtProvSurDec
    -- US196
	From  PROVISIONS_P7 P
  Where P.cd_conso_cpt=p_cd_conso_cpt
  ;

BEGIN

	cd_cpt := liste_cd_conso('00399','00936','00357','00472','00370','00372'); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803

	SELECT pack_utilitaire.f_calc_dt_arrete INTO v_dt_arrete from DUAL;

	dbms_output.enable(100000);
	DBMS_OUTPUT.PUT_LINE('Debut P_UTLF_PROVISIONS_P7 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

 FOR CD_CONSO in 1 .. cd_cpt.count -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  LOOP
  BEGIN

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier||cd_cpt(CD_CONSO));

  --ouverture du fichier en mode Append.
  --le fichier resultat est supprime avant l'appel de ces procedures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;


  --01/02/2019 - CDS ATOS (SQN) - US 683
  --  v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             '||';'||'P7XX'||';'||'01'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',129);
  --v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             '||';'||'P7XX'||';'||'02'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',129);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
    --v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';BTR                             '||';'||'P7XX'||';'||'03'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',300); -- BALE4
    v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';BTR                             '||';'||'P7XX'||';'||'04'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',1886); -- BALE4

  -- FIN LFD
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);

  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_P7(cd_cpt(CD_CONSO)) -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  LOOP
    BEGIN
    	v_ligne :=
		'01'||';'||
		  RPAD(nvl(C_ENR.ID_PROVISION,' '),40)	||';'||
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)	||';'||
  		  RPAD(nvl(C_ENR.CD_SYS_INT,' '),20)		||';'||
		  RPAD(nvl(C_ENR.ID_PROVISION,' '),40)||';'||
		  RPAD(nvl(C_ENR.CD_NAT_DEPRE,' '),1)	||';'||
		  -- 04/02/2019 - CDS ATOS (LFD) - CRRV4.2 US 676
		  RPAD(nvl(C_ENR.ORIGINE_CALCUL_PROVISION,' '),1)||';'||
		-- FIN LFD
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_PROVISION,0))||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_PROVISION_TRIM,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE,' '),3)			||';'||
		  --RPAD(' ',50)
		  --RPAD(' ', 48) -- 11/02/2019 - CRRV4.2 - correctif
      -- US196
      RPAD(nvl(C_ENR.CdEntSucc          ,' '), 5)                                   ||';'||
      RPAD(nvl(C_ENR.cdTypProd          ,' '), 6)                                   ||';'||
      pack_utilitaire.f_format_montant_BIS2( nvl(C_ENR.mtProvBilan        ,  0) )   ||';'||
      pack_utilitaire.f_format_montant_BIS2( nvl(C_ENR.mtProvHB           ,  0) )   ||';'||
      pack_utilitaire.f_format_montant_BIS2( nvl(C_ENR.mtProvArrPrecBilan ,  0) )   ||';'||
      pack_utilitaire.f_format_montant_BIS2( nvl(C_ENR.mtProvArrPrecHB    ,  0) )   ||';'||
      RPAD(nvl(C_ENR.cdDevEntCmpt       ,' '), 3)                                   ||';'||
      RPAD(nvl(C_ENR.cdPCCOProvDep      ,' '), 12)                                  ||';'||
      pack_utilitaire.f_format_montant_BIS2( nvl(C_ENR.mtProvDep          ,  0) )   ||';'||
      RPAD(nvl(C_ENR.cdPCCOProvSurDec   ,' '), 12)                                  ||';'||
      pack_utilitaire.f_format_montant_BIS2( nvl(C_ENR.mtProvSurDec       ,  0) )   ||';'||
	  RPAD(' ', 12)||';'|| --BALE4 P7 50.22
	  RPAD(' ', 19)||';'|| --BALE4 P7 50.23
      --RPAD(' ', 56)
	  RPAD(' ', 1609) --BALE4
      --US196
		  ;
      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
      v_nb_lignes := C_P7%ROWCOUNT ;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_UTLF_PROVISIONS_P7, ID_ENGAGEMENT='||C_ENR.ID_ENGAGEMENT,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
    v_nb_lignes := v_nb_lignes + 2 ;
   v_tail := '99' ||';'|| LPAD(v_nb_lignes,10,'0') || ';'||RPAD(' ',1986);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);
   DBMS_OUTPUT.PUT_LINE('Nbre P_UTLF_PROVISIONS_P7 : ' || cd_cpt(CD_CONSO) || ' = ' || v_nb_lignes );

   UTL_FILE.FCLOSE(v_crr_descripteur);
   END;
   v_nb_lignes := 0;
   END LOOP;

  DBMS_OUTPUT.PUT_LINE('Fin P_UTLF_PROVISIONS_P7 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur Provisions P7',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_UTLF_PROVISIONS_P7;

PROCEDURE P_UTLF_TIE_TIERS_C2 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
  l_etape    VARCHAR2(30);
  CD_RETOUR  VARCHAR2(30);
  MSG_RETOUR VARCHAR2(250);

  v_crr_descripteur UTL_FILE.FILE_TYPE;
/* 31/01/2018 CDS ATOS (JMP) ANACREDIT Ajouts de champs ANACREDIT US45
 => Accroissement de longueur de la ligne.
  v_head     VARCHAR2(622); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(622); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(622); --  <=== TAILLE DE LA LIGNE.
  */
  /* 09/01/2019 - CDS ATOS (LFD) - US 625
  v_head     VARCHAR2(639); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(639); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(639); --  <=== TAILLE DE LA LIGNE.*/

 -- v_head     VARCHAR2(1203); --  <=== TAILLE DE LA LIGNE. 642
 -- v_ligne     VARCHAR2(1203); --  <=== TAILLE DE LA LIGNE.
 -- v_tail     VARCHAR2(1203); --  <=== TAILLE DE LA LIGNE.

  v_head     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE. BALE4
  v_ligne     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE. BALE4
  v_tail     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE. BALE4
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;

  type liste_cd_conso is table of varchar2(5); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  cd_cpt liste_cd_conso; -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803

  --CURSOR C_CONSO
  --is select distinct cd_conso_cpt from tie_tiers_c2;


  ---------------------
  CURSOR C_C2(p_cd_conso_cpt CHAR)
  IS
   Select
         DT_ARRETE					,
		 CD_CONSO_CPT				,
		 CD_SYS_INT					,
		 ID_TIERS					,
		 REF_EXT_GRPE_CALF			,
		 RAISON_SOCIALE				,
		 REF_IDENT_NATIO			,
		 IDENT_NATIO				,
		 CD_PAYS_NATIONALITE		,
		 CD_PAYS_RESIDENCE			,
		 CD_PAYS_CONTROLE			,
		 ADRESSE					,
		 VILLE						 ,
		 CD_POSTAL					 ,
		 CD_CATEG_CONTREPARTIE		 ,
		 CD_PORTEFEUILLE_BAL_TIERS	 ,
		 CD_SECTEUR_ACTIVITE			,
		 CD_NORME_LOCALE_ACTIVITE	 ,
		 CD_ACTIVITE_LOCALE			 ,
		 CD_APE_INTERNE				 ,
		 CD_TYPE_RELATION			 ,
		 MNT_CA						 ,
		 TOP_CA_CONSO				 ,
		 CD_DEVISE_CA				 ,
		 ANNEE_CA					 ,
		 NB_JOUR_EXERCICE			 ,
		 CD_NATURE_CA				 ,
		 TOT_BILAN_RETRAITE			 ,
		 RESULTAT_NET_RETRAITE		 ,
		 DT_CLOTURE_CPT_NOTE			,
		 NOTE_CALC_FINALE			 ,
		 DT_REVISION_NOTE			 ,
		 DT_ENTREE_DEFAUT			 ,
		 CD_METHODO_NOTE				,
		 CD_MOTIF_NOTE				 ,
		 CD_GRILLE_NOTE				 ,
		 CD_SEGMENT_NOTE				,
		 PD								,
		 ETAT_PROC_JUD 					, -- 30/01/2018 CDS ATOS (JMP) ANACREDIT US 45
		 DT_PROC_JUD 					 -- 30/01/2018 CDS ATOS (JMP) ANACREDIT US 45

		,NB_SALARIE 		  -- 29/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre de salariÃ©s
		,ID_TIERS_CALC -- 27/11/2018 - CDS ATOS (LFD) - ANACREDIT US 593
		,CD_NUTS -- 09/01/2019 - CDS ATOS (LFD) - US 625
    -- US196
    ,CD_AGENT_ECO              as cdAgentEco -- KLx C3RD US297 (GHU)
    ,null                      as cdNatBCE
    ,null                      as idNatBCE
    ,null                      as cdFormJurEtr
    ,null                      as idRegNatAssos
    ,CD_ENTR_INDIVIDUEL        as indGerSoc					-- 08/09/2021 CDS ATOS (EMM) CRRv4.3 US 257
    ,NOM_PATRO                 as descNomIE
    ,PRENOM                    as descPrenomIE
    ,CD_SEXE                   as cdSexeIE
    ,DT_NAISS                  as dtNaisIE
    ,CD_PAYS_NAISS             as cdPaysNaiIE
    ,CD_DPT_NAISS              as cdINSEEComNaiIE
    ,CD_COMM_NAISS             as descComNaiIE
    ,null                      as dtRel
    ,STATUT_DEBITEUR           as cdStatDeb
    ,DT_DEB_PROBATOIRE         as dtDebObs
    ,DT_FIN_PROB_PREVUE        as dtFinPrevObs
    ,DT_FIN_PROB_REELLE        as dtFinObs
    ,PRESENCE_UTP              as tpUTP
    ,PRESENCE_ARRIERES         as tpEvtDef
    ,NBRE_JOURS_ARRIERES       as nbJArr
    ,MNT_ARRIERES              as mtArr
    ,CD_DEVISE                 as cdDevArr
    ,TAUX_ENC_ARR              as txEcnArr
    ,null                      as cdRefIdNat2
    ,null                      as cdIdNat2
    ,null                      as dtSorDef
    -- US196
	,CD_DEVISE_REVENUE_TIERS   as CD_DEVISE_REVENUE_TIERS
	,IND_WL 				   as IND_WL
	,DATE_ENTREE_WL		       as DATE_ENTREE_WL
	,DATE_SORTIE_WL			   as DATE_SORTIE_WL
	,CD_MOTIF_ENTREE_WL		   as CD_MOTIF_ENTREE_WL
	,CD_MOTIF_SORTIE_WL        as CD_MOTIF_SORTIE_WL
	From  TIE_TIERS_C2 where cd_conso_cpt=p_cd_conso_cpt
	--18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise aï¿½ jour de l'utlfile, ajout de la condition A_EXTRAIRE = 'O'
		AND A_EXTRAIRE = 'O'
	-- Fin - CDS AtoS FAD - ANACREDIT US600
	;

BEGIN

	cd_cpt := liste_cd_conso('00399','00936','00357','00472','00370','00372'); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803

	SELECT pack_utilitaire.f_calc_dt_arrete INTO v_dt_arrete from DUAL;

	dbms_output.enable(100000);
	DBMS_OUTPUT.PUT_LINE('Debut P_UTLF_TIE_TIERS_C2 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

 FOR CD_CONSO in 1 .. cd_cpt.count -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  LOOP
  BEGIN

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier||cd_cpt(CD_CONSO));

  --ouverture du fichier en mode Append.
  --le fichier resultat est supprime avant l'appel de ces procedures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  --01/02/2019 - CDS ATOS (SQN) - US 683
  --v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;C2XX;01;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',508);
  --v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;C2XX;02;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',508);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  --v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'||  cd_cpt(CD_CONSO) ||';BTR                             ;C2XX;03;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1089); -- BALE4
  v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'||  cd_cpt(CD_CONSO) ||';BTR                             ;C2XX;04;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1886); -- BALE4
  -- FIN LFD
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);

  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_C2(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
		  --RPAD(nvl(C_ENR.CD_SYS_INT,' '),20)				||
		  --RPAD(' ',7)										||
		  '01'												||';'||
		RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)				||';'||
		RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)				||';'||
		-- Fin - CDS AtoS FAD - ANACREDIT US600
		  --RPAD(' ',20)										||
		  RPAD(' ',10)										||';'||
		  RPAD(nvl(C_ENR.REF_EXT_GRPE_CALF,' '),20)			||';'||
		  RPAD(nvl(C_ENR.REF_IDENT_NATIO,' '),2)			||';'||
		  RPAD(nvl(C_ENR.IDENT_NATIO,' '),20)				||';'||
		  -- 09/01/2019 - CDS ATOS (LFD) - US 625
		   RPAD(NVL(C_ENR.CD_NUTS,' '),5)	||';'||
		   RPAD(nvl(C_ENR.ETAT_PROC_JUD,' '),1)	||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PROC_JUD, 'YYYYMMDD'), ' '), 8)	||';'||
		  -- FIN LFD
/* BloquÃ© en recette retour ancien C3RD
		  RPAD(' ',5)										||';'||  -- CDS ATOS (JMP) ANACREDIT US45 (C2 4.32)
		  RPAD(nvl(C_ENR.ETAT_PROC_JUD,' '),1)				||';'||  -- CDS ATOS (JMP) ANACREDIT US45 (C2 4.33)
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PROC_JUD, 'YYYYMMDD'), ' '), 8)	||';'||  -- CDS ATOS (JMP) ANACREDIT US45 (C2 4.34)
		  RPAD(' ',1)										||';'||  -- Modif MEPHO mai 201018 CDS ATOS (JMP) ANACREDIT US45 (C2 4.32)
		  RPAD(' ',8)										||';'||  -- Modif MEPHO mai 201018 CDS ATOS (JMP) ANACREDIT US45 (C2 4.32)
BloquÃ© en recette retour ancien C3RD */
		  RPAD(nvl(C_ENR.RAISON_SOCIALE,' '),114)			||';'||
		  RPAD(nvl(C_ENR.CD_PAYS_NATIONALITE,' '),2)		||';'||
		  RPAD(nvl(C_ENR.CD_PAYS_RESIDENCE,' '),2)			||';'||
		  RPAD(nvl(C_ENR.CD_PAYS_CONTROLE,' '),2)			||';'||
		  RPAD(nvl(C_ENR.ADRESSE,' '),70)					||';'||
		  RPAD(nvl(C_ENR.VILLE,' '),30	)					||';'||
		  RPAD(nvl(C_ENR.CD_POSTAL,' '),15)					||';'||
		  RPAD(nvl(C_ENR.CD_CATEG_CONTREPARTIE,' '),5)		||';'||
		  RPAD(nvl(C_ENR.CD_PORTEFEUILLE_BAL_TIERS,' '),3)	||';'||
		  RPAD(nvl(C_ENR.CD_SECTEUR_ACTIVITE,' '),6)		||';'||
		  RPAD(nvl(C_ENR.CD_NORME_LOCALE_ACTIVITE,' '),1)	||';'||
		  RPAD(nvl(C_ENR.CD_ACTIVITE_LOCALE,' '),6)			||';'||
		  RPAD(nvl(C_ENR.CD_APE_INTERNE,' '),6)				||';'||
		  RPAD(nvl(C_ENR.CD_TYPE_RELATION,' '),1)			||';'||
                  CASE WHEN C_ENR.MNT_CA IS NULL THEN RPAD(' ',19)
		       WHEN C_ENR.MNT_CA=0 THEN RPAD(' ',19)
		       ELSE pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CA,0)) END ||';'||
		  RPAD(nvl(C_ENR.TOP_CA_CONSO,' '),1)				||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_CA,' '),3)				||';'||
		  RPAD(nvl(to_char(C_ENR.ANNEE_CA),' '),4)					||';'||
		  RPAD(nvl(C_ENR.NB_JOUR_EXERCICE,' '),3)			||';'||
		  RPAD(nvl(C_ENR.CD_NATURE_CA,' '),1)				||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.TOT_BILAN_RETRAITE,0))||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.RESULTAT_NET_RETRAITE,0))||';'||
-- 29/05/2018 CDS Atos (JMP) ANACREDIT  US346
--		  RPAD(' ',6)									||';'||
		  LPAD(NVL(to_char(C_ENR.NB_SALARIE), '      '),6,'0')||';'||
-- Fin 29/05/2018 CDS Atos (JMP) ANACREDIT  US346
		  RPAD(NVL(TO_CHAR(C_ENR.DT_CLOTURE_CPT_NOTE, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(' ',15)									||';'||
		  -- 09/01/2019 - CDS ATOS (LFD) - US 625
		  --RPAD(' ',1)									||';'||
		  --RPAD(' ',8)									||';'||
          CASE WHEN C_ENR.ETAT_PROC_JUD IS NULL THEN RPAD(' ',1)
            WHEN C_ENR.ETAT_PROC_JUD <> 1 THEN RPAD(C_ENR.ETAT_PROC_JUD,1)
            ELSE RPAD(' ',1) END	||';'|| -- C2 6.3 KLx US 298 (GHU)
          CASE WHEN C_ENR.ETAT_PROC_JUD IS NULL THEN RPAD(' ',8)
            WHEN C_ENR.ETAT_PROC_JUD <> 1 THEN RPAD(TO_CHAR(C_ENR.DT_PROC_JUD, 'YYYYMMDD'),8)
            ELSE RPAD(' ',8) END	||';'|| -- C2 6.4 KLx US 298 (GHU)
		  -- FIN LFD
		  RPAD(' ',1)									||';'||
		  RPAD(nvl(C_ENR.NOTE_CALC_FINALE,' '),2)			||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_REVISION_NOTE, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_ENTREE_DEFAUT, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(C_ENR.CD_METHODO_NOTE,'999'),3)					||';'||
-- 06/07/2018 CDS Atos (JMP) ANACREDIT Sprint 12 US382
-- Activation de l'Ã©criture
		  RPAD(NVL(C_ENR.CD_MOTIF_NOTE,' '),3)					||';'||
--                  RPAD(' ',3)                                                                   ||';'||
-- 06/07/2018 CDS Atos (JMP) ANACREDIT Sprint 12 US382
		  RPAD(NVL(C_ENR.CD_GRILLE_NOTE,' '),23)					||	';'||
		  RPAD(NVL(C_ENR.CD_SEGMENT_NOTE,' '),2)					||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.PD,0))		||';'||
		  --RPAD(' ',50)
     ---  US196  >>
		  RPAD(NVL(C_ENR.cdAgentEco        ,' '),  6)                ||';'||
		  RPAD(NVL(C_ENR.cdNatBCE          ,' '),  4)                ||';'||
		  RPAD(NVL(C_ENR.idNatBCE          ,' '), 21)                ||';'||
		  RPAD(NVL(C_ENR.cdFormJurEtr      ,' '),  6)                ||';'||
		  RPAD(NVL(C_ENR.idRegNatAssos     ,' '), 10)                ||';'||
		  RPAD(NVL(C_ENR.indGerSoc         ,'N'),  1)                ||';'|| --M11718 CDS ATOS (VFN) 28/09/2021
		  RPAD(NVL(C_ENR.descNomIE         ,' '), 60)                ||';'||
		  RPAD(NVL(C_ENR.descPrenomIE      ,' '), 60)                ||';'||
		  RPAD(NVL(C_ENR.cdSexeIE          ,' '),  1)                ||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.dtNaisIE  , 'YYYYMMDD'), ' '), 8)   ||';'||
		  RPAD(NVL(C_ENR.cdPaysNaiIE       ,' '),  2)                ||';'||
		  RPAD(NVL(C_ENR.cdINSEEComNaiIE   ,' '),  5)                ||';'||
		  RPAD(NVL(C_ENR.descComNaiIE      ,' '),255)                ||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.dtRel     , 'YYYYMMDD'), ' '), 8)   ||';'||
		  RPAD(NVL(C_ENR.cdStatDeb         ,' '),  1)                ||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.dtDebObs  , 'YYYYMMDD'), ' '), 8)   ||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.dtFinPrevObs, 'YYYYMMDD'), ' '), 8) ||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.dtFinObs  , 'YYYYMMDD'), ' '), 8)   ||';'||
		  RPAD(NVL(C_ENR.tpUTP             ,' '),  1)                ||';'||
		  RPAD(NVL(C_ENR.tpEvtDef          ,' '),  1)                ||';'||
		  CASE WHEN C_ENR.nbJArr IS NULL THEN '      '
		       WHEN C_ENR.nbJArr < 0 THEN '-' || LPAD(ABS(C_ENR.nbJArr),5,'0')
		       ELSE    '+' ||  LPAD(TO_CHAR( C_ENR.nbJArr ),5,'0')
		       END                                                   ||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtArr ,0)) ||';'||
		  RPAD(NVL(C_ENR.cdDevArr          ,'EUR'),  3)                ||';'|| --M11719 CDS ATOS (VFN) 28/09/2021
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.txEcnArr ,0))   ||';'||
		  RPAD(NVL(C_ENR.cdRefIdNat2       ,' '),  2)                ||';'||
		  RPAD(NVL(C_ENR.cdIdNat2          ,' '), 20)                ||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.dtSorDef  , 'YYYYMMDD'), ' '), 8)   ||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_REVENUE_TIERS,' '),3)					||';'|| -- C2 10.8 - BALE4
		  RPAD(' ', 3)													||';'|| --C2 4.50 Agent économique en Norme Française
		  RPAD(NVL(C_ENR.IND_WL, ' '), 1)								||';'||	--C2 4.60 Indicateur Watch List
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)	||';'||	--C2 4.61 Date d'entrée en Watch List
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)	||';'||	--C2 4.62 Date de sortie en Watch List
		  RPAD(NVL(CASE WHEN C_ENR.IND_WL = 'Y' THEN C_ENR.CD_MOTIF_ENTREE_WL WHEN C_ENR.IND_WL = 'N' THEN C_ENR.CD_MOTIF_SORTIE_WL END, ' '), 5)||';'|| --C2 4.63 Motif Watch List 1
		  RPAD(' ', 5)													||';'||	--C2 4.64 Motif Watch List 2
     ---  US196  <<
	--	  RPAD(' ',40) -- 11/02/2019 - CRRV4.2 - correctif
		  --RPAD(' ',833) --BALE4
		  RPAD(' ',797) --BALE4
		  ;

      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
	  --13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
      --v_nb_lignes := C_C2%ROWCOUNT + 2 ;
	  v_nb_lignes := C_C2%ROWCOUNT ;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_UTLF_TIE_TIERS_C2, ID_TIERS='||C_ENR.ID_TIERS,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
	v_nb_lignes := v_nb_lignes +2 ; --13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
   v_tail := '99' || ';'||LPAD(v_nb_lignes,10,'0') || ';'||RPAD(' ',1986);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);

     DBMS_OUTPUT.PUT_LINE('Nbre P_UTLF_TIE_TIERS_C2 : ' || cd_cpt(CD_CONSO) || ' = ' || v_nb_lignes );

   UTL_FILE.FCLOSE(v_crr_descripteur);
   END;
	  v_nb_lignes := 0 ; --13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
   END LOOP;

  DBMS_OUTPUT.PUT_LINE('Fin P_UTLF_TIE_TIERS_C2 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur Tiers C2',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_UTLF_TIE_TIERS_C2;

PROCEDURE P_UTLF_TIE_TIERS_C3 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
  l_etape    VARCHAR2(30);
  CD_RETOUR  VARCHAR2(30);
  MSG_RETOUR VARCHAR2(250);

  v_crr_descripteur UTL_FILE.FILE_TYPE;
  --11/01/2019 CDS Atos (SQN) US 630
  -- incrementation de 2
  -- BALE4 avant 337, apres 1000
  v_head     VARCHAR2(1000); --  <=== TAILLE DE LA LIGNE.
  v_ligne    VARCHAR2(1000); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(1000); --  <=== TAILLE DE LA LIGNE.
  --Fin SQN
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;
  type liste_cd_conso is table of varchar2(5); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  cd_cpt liste_cd_conso; -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803

  --CURSOR C_CONSO
  --is select distinct cd_conso_cpt from tie_tiers_c3;


  ---------------------
  CURSOR C_C3(p_cd_conso_cpt CHAR)
  IS
   Select
       DT_ARRETE					,
	   CD_CONSO_CPT				    ,
	   CD_SYS_INT					,
	   ID_TIERS					    ,
	   DT_NAISSANCE				    ,
	   REF_EXT_GRPE_CALF			,
	   CD_PAYS_RESIDENCE			,
	   CD_POSTAL					,
	   CD_CATEG_CONTREPARTIE		,
	   CD_PORTEFEUILLE_BAL_TIERS	,
	   CD_SECTEUR_ACTIVITE			,
	   NOTE_CALC_FINALE			    ,
	   DT_REVISION_NOTE			    ,
	   DT_ENTREE_DEFAUT			    ,
	   CD_METHODO_NOTE				,
	   CD_MOTIF_NOTE				,
	   CD_GRILLE_NOTE				,
	   CD_SEGMENT_NOTE				,
	   PD
	-- 18/08/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, ajout du champ ID_TIERS_CALC
	   , ID_TIERS_CALC
	-- Fin - CDS AtoS FAD - ANACREDIT US600
	   --11/01/2019 CDS Atos (SQN) US 630
	   , CD_TYPE_RELATION
	   --FIN SQN
     -- US196
     ,STATUT_DEBITEUR           as cdStatDeb
     ,DT_DEB_PROBATOIRE         as dtDebObs
     ,DT_FIN_PROB_PREVUE        as dtFinPrevObs
     ,DT_FIN_PROB_REELLE        as dtFinObs
     ,PRESENCE_UTP              as tpUTP
     ,PRESENCE_ARRIERES         as tpEvtDef
     ,NBRE_JOURS_ARRIERES       as nbJArr
     ,MNT_ARRIERES              as mtArr
     ,CD_DEVISE                 as cdDevArr
     ,TAUX_ENC_ARR              as txEcnArr
     ,CD_AGENT_ECO              AS cdAgentEco -- KLx Risque (VDC) - US 300 - Utilisation du champ CD_AGENT_ECO pour le champ C3 4.44 dans l'extraction
     ,null                      AS dtSorDef
     ,null                      AS dtRel
     -- US196
	 ,CD_DEVISE_REVENUE_TIERS   AS CD_DEVISE_REVENUE_TIERS
	 ,IND_WL 				   as IND_WL
	 ,DATE_ENTREE_WL		       as DATE_ENTREE_WL
	 ,DATE_SORTIE_WL			   as DATE_SORTIE_WL
	 ,CD_MOTIF_ENTREE_WL		   as CD_MOTIF_ENTREE_WL
	 ,CD_MOTIF_SORTIE_WL        as CD_MOTIF_SORTIE_WL
	From  TIE_TIERS_C3 where cd_conso_cpt=p_cd_conso_cpt
	-- 18/08/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, filtre sur A_EXTRAIRE ='O'
		AND A_EXTRAIRE = 'O'
	---- Fin - CDS AtoS FAD - ANACREDIT US600
	;

BEGIN

	--cd_cpt := liste_cd_conso('00399','00936','00357','00472','00370','00372'); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
	cd_cpt := liste_cd_conso('00399','00357','00370','00372'); -- 19/11/2019 - CDS ATOS (GBD) - M49942 pas C3 pour 472 et 936

	SELECT pack_utilitaire.f_calc_dt_arrete INTO v_dt_arrete from DUAL;

	dbms_output.enable(100000);
	DBMS_OUTPUT.PUT_LINE('Debut P_UTLF_TIE_TIERS_C3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

 FOR CD_CONSO in 1 .. cd_cpt.count -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  LOOP
  BEGIN

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier||cd_cpt(CD_CONSO));

  --ouverture du fichier en mode Append.
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  --01/02/2019 - CDS ATOS (SQN) - US 683
  --v_head := '00;00000470;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;C3XX;01;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',116);
  --v_head := '00;00000470;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;C3XX;02;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',116);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  --v_head := '00;00000470;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| cd_cpt(CD_CONSO) ||';BTR                             ;C3XX;03;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',223); -- BALE4
  v_head := '00;00000470;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| cd_cpt(CD_CONSO) ||';BTR                             ;C3XX;04;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',886); -- BALE4
  -- FIN LFD
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);

  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_C3(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
			'01'||';'|| -- C3 0.0
			-- 18/08/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, Modifier l'alimentation du segment C3 dans le fichier
			--  RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)				||';'||
			--  RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)					||';'||
			RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||';'|| -- C3 1.1
			RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||';'|| -- C3 1.0
			-- Fin - CDS AtoS FAD - ANACREDIT US600
			RPAD(NVL(TO_CHAR(C_ENR.DT_NAISSANCE, 'YYYYMMDD'), ' '), 8)||';'|| -- C3 7.1
			RPAD(nvl(C_ENR.REF_EXT_GRPE_CALF,' '),20)			||';'|| -- C3 1.3
			RPAD(nvl(C_ENR.CD_PAYS_RESIDENCE,' '),2)			||';'|| -- C3 3.2
			RPAD(nvl(C_ENR.CD_POSTAL,' '),15)					||';'|| -- C3 3.7
			RPAD(nvl(C_ENR.CD_CATEG_CONTREPARTIE,' '),5)		||';'|| -- C3 4.6
			RPAD(nvl(C_ENR.CD_PORTEFEUILLE_BAL_TIERS,' '),3)	||';'|| -- C3 4.7
			RPAD(nvl(C_ENR.CD_SECTEUR_ACTIVITE,' '),6)		||';'|| -- C3 4.8
			RPAD(' ',2)									||';'|| -- C3 6.9
			RPAD(' ',15)									||';'|| -- C3 6.2
			RPAD(' ',1)									||';'|| -- C3 6.5
			RPAD(nvl(C_ENR.NOTE_CALC_FINALE,' '),2)			||';'|| -- C3 4.1
			RPAD(NVL(TO_CHAR(C_ENR.DT_REVISION_NOTE, 'YYYYMMDD'), ' '), 8)||';'|| -- C3 4.2
			RPAD(NVL(TO_CHAR(C_ENR.DT_ENTREE_DEFAUT, 'YYYYMMDD'), ' '), 8)||';'|| -- C3 4.15
			RPAD(NVL(C_ENR.CD_METHODO_NOTE,'999'),3)					||';'|| -- C3 4.3
			-- 07/06/2018 CDS Atos (JMP) ANACREDIT Sprint 12 US380
			-- Activation de l'Ã©criture
			RPAD(NVL(C_ENR.CD_MOTIF_NOTE,' '),3)					||';'|| -- C3 4.4
			--        RPAD(' ',3)                                                                   ||';'||
			-- Fin 07/06/2018 CDS Atos (JMP) ANACREDIT Sprint 12 US380
			RPAD(NVL(C_ENR.CD_SEGMENT_NOTE,' '),2)					||';'|| -- C3 6.6
			pack_utilitaire.f_format_taux_15(nvl(C_ENR.PD,0))		||';'|| -- C3 6.7
			--11/01/2019 CDS Atos (SQN) US 630
			'C'||';'|| -- C3 5.1
			--Fin SQN
			--RPAD(' ',50)
			-- US196
			RPAD(NVL(C_ENR.cdStatDeb         ,' '),  1)                ||';'|| -- C3 12.1
			RPAD(NVL(TO_CHAR(C_ENR.dtDebObs  , 'YYYYMMDD'), ' '), 8)   ||';'|| -- C3 12.2
			RPAD(NVL(TO_CHAR(C_ENR.dtFinPrevObs, 'YYYYMMDD'), ' '), 8) ||';'|| -- C3 12.3
			RPAD(NVL(TO_CHAR(C_ENR.dtFinObs  , 'YYYYMMDD'), ' '), 8)   ||';'|| -- C3 12.4
			RPAD(NVL(C_ENR.tpUTP             ,' '),  1)                ||';'|| -- C3 14.2
			RPAD(NVL(C_ENR.tpEvtDef          ,' '),  1)                ||';'|| -- C3 14.1
			CASE WHEN C_ENR.nbJArr IS NULL THEN '    '
			     WHEN C_ENR.nbJArr < 0 THEN '-' || LPAD(ABS(C_ENR.nbJArr),3,'0')
			     ELSE    '+' ||  LPAD(TO_CHAR( C_ENR.nbJArr ),3,'0')
			     END                                                   ||';'|| -- C3 13.1
			pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtArr ,0)) ||';'|| -- C3 13.2
			RPAD(NVL(C_ENR.cdDevArr          ,' '),  3)                ||';'|| -- C3 13.3
			pack_utilitaire.f_format_taux_15(nvl(C_ENR.txEcnArr ,0))   ||';'|| -- C3 13.4
			RPAD(NVL(C_ENR.cdAgentEco        ,' '),  6)                ||';'|| -- C3 4.44
			RPAD(NVL(TO_CHAR(C_ENR.dtSorDef  , 'YYYYMMDD'), ' '), 8)   ||';'|| -- C3 4.16
			RPAD(NVL(TO_CHAR(C_ENR.dtRel     , 'YYYYMMDD'), ' '), 8)   ||';'|| -- C3 11.1
			RPAD(nvl(C_ENR.CD_DEVISE_REVENUE_TIERS,' '),3)					||';'|| -- C3 10.8 - BALE4
			RPAD(' ', 3)												||';'|| --C3 4.50 Agent économique en Norme Française
			RPAD(NVL(C_ENR.IND_WL, ' '), 1)								||';'|| --C3 4.60 Indicateur Watch List
			RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTREE_WL, 'YYYYMMDD'), ' '), 8)||';'|| --C3 4.61 Date d'entrée en Watch List
			RPAD(NVL(TO_CHAR(C_ENR.DATE_SORTIE_WL, 'YYYYMMDD'), ' '), 8)||';'|| --C3 4.62 Date de sortie en Watch List
			RPAD(NVL(CASE WHEN C_ENR.IND_WL = 'Y' THEN C_ENR.CD_MOTIF_ENTREE_WL WHEN C_ENR.IND_WL = 'N' THEN C_ENR.CD_MOTIF_SORTIE_WL END, ' '), 5)||';'|| --C3 4.63 Motif Watch List 1
			RPAD(' ', 5)												||';'|| --C3 4.64 Motif Watch List 2
			-- US196
			--RPAD(' ',52) -- 11/02/2019 - CRRV4.2 - correctif
			--RPAD(' ',711) -- BALE4
			RPAD(' ',675) -- BALE4

		  ;

      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
	  --13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
      --v_nb_lignes := C_C3%ROWCOUNT + 2 ;
      v_nb_lignes := C_C3%ROWCOUNT;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_UTLF_TIE_TIERS_C3, ID_TIERS='||C_ENR.ID_TIERS,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
	v_nb_lignes := v_nb_lignes + 2 ;--13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
   --v_tail := '99'||';'||LPAD(v_nb_lignes,10,'0')||';'|| RPAD(' ',323);
   v_tail := '99'||';'||LPAD(v_nb_lignes,10,'0')||';'|| RPAD(' ',986); -- BALE4
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);

     DBMS_OUTPUT.PUT_LINE('Nbre P_UTLF_TIE_TIERS_C3 : ' || cd_cpt(CD_CONSO) || ' = ' || v_nb_lignes );

   UTL_FILE.FCLOSE(v_crr_descripteur);
   END;
   v_nb_lignes := 0 ;--13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
   END LOOP;

  DBMS_OUTPUT.PUT_LINE('Fin P_UTLF_TIE_TIERS_C3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur Tiers C3',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_UTLF_TIE_TIERS_C3;


PROCEDURE P_UTLF_CREDIT_P3 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
	l_etape    VARCHAR2(30);
	CD_RETOUR  VARCHAR2(30);
	MSG_RETOUR VARCHAR2(250);

	v_crr_descripteur UTL_FILE.FILE_TYPE;
	/* 31/01/2018 CDS ATOS (JMP) ANACREDIT Ajouts de champs ANACREDIT US45
	=> Accroissement de longueur de la ligne.
	 v_head     VARCHAR2(1668); --  <=== TAILLE DE LA LIGNE.
	 v_ligne     VARCHAR2(1668); --  <=== TAILLE DE LA LIGNE.
	 v_tail     VARCHAR2(1668); --  <=== TAILLE DE LA LIGNE.
	 */
	 /*31/01/2019 - CDS ATOS (GBD) - US 671
	 v_head     VARCHAR2(1700); --  <=== TAILLE DE LA LIGNE.
	 v_ligne     VARCHAR2(1700); --  <=== TAILLE DE LA LIGNE.
	 v_tail     VARCHAR2(1700); --  <=== TAILLE DE LA LIGNE.
	 */ --- 31/01/2019 - CDS ATOS (GBD) - US 671  : augmente taille
	 --v_head     VARCHAR2(1809); --  <=== TAILLE DE LA LIGNE.
	 --v_head     VARCHAR2(1918); -- 11/02/2019 - CRRV4.2 - correctif
	 --v_ligne     VARCHAR2(1809); --  <=== TAILLE DE LA LIGNE.
	 --v_ligne     VARCHAR2(1918); -- 11/02/2019 - CRRV4.2 - correctif
	 --v_tail     VARCHAR2(1809); --  <=== TAILLE DE LA LIGNE.
	 --v_tail     VARCHAR2(1918);-- 11/02/2019 - CRRV4.2 - correctif
	 --31/01/2019 - CDS ATOS (GBD) - US 671 fin
	-- US196
	v_head     VARCHAR2(4500);
	v_ligne    VARCHAR2(4500);
	v_tail     VARCHAR2(4500);


	v_dt_arrete DATE;
	v_nb_lignes NUMBER := 0;

	type liste_cd_conso is table of varchar2(5); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
	cd_cpt liste_cd_conso; -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803


  --CURSOR C_CONSO
  --is select distinct cd_conso_cpt from credit_p3;


  ---------------------
  CURSOR C_P3(p_cd_conso_cpt CHAR)
  IS
	Select
			DT_ARRETE					,
			CD_CONSO_CPT				,
			CD_SYS_INT					,
			ID_TIERS					,
			ID_ENGAGEMENT				,
			ID_AGREGAT					,
			CD_METHODO_BALE2			,
			ELIGIBILITE_OMP				,
			CD_NATURE_OPE				,
			CD_NATURE_PNU				,
			CD_CLASS_CPT_LOC			,
			CD_CLASS_CPT_REF			,
			CD_CLASS_CPT_IFR			,
			CD_TYPE_RISQUE				,
			CD_PTF_BOOKING				,
			CD_PORTEFEUILLE_BALE2		,
			CD_LIGNE_METIER				,
			CD_CIRCUIT_DISTRIB			,
			IND_POCI					,
			CD_OBJET_FIN				,
			CD_USAGE_BIEN_IMM			,
			TIE_ORIGINE					,
			DT_DEBUT_ENG				,
			DT_DEBUT_ENG_REN			,
			DT_FIN_ENG					,
			DT_DEBUT_ENG_BIL			,
			DT_FIN_ENG_BIL				,
			DT_PREM_DEB_FD				,
			MNT_PREM_DEB_FD				,
			IND_ECH						,
			IND_PAL						,
			CD_TYPE_TAUX				,
			CD_TYPE_AMO					,
			CD_PERIODICITE_K			,
			CD_PERIODICITE_I			,
			CD_MODALITE_RBT				,
			DT_PREM_ECH					,
			TX_PLAFOND					,
			TX_PLANCHER					,
			CD_PERIODICITE_REV_TX		,
			CD_PERIODICITE_REV_TX_NB	,
			TX_CLI_OCTROI				,
			IND_REF_TV					,
			IND_IDX_PAL					,
			TX_MARGE_ADD				,
			TX_MARGE_MUL				,
			BASE_INT					,
			MNT_CRD						,
			MNT_DECOUVERT				,
			CD_DEVISE_CRD				,
			MNT_LOYER					,
			CD_DEVISE_LOY				,
			MNT_IRD						,
			CD_DEVISE_IRD				,
			MNT_PNU						,
			CD_DEVISE_PNU				,
			MNT_CONTRAT_ORIG			,
			CD_DEVISE_ORIG				,
			MNT_VAL_MARCHE				,
			CD_DEVISE_MARCHE			,
			MNT_HYPOTHEQUE				,
			CD_DEVISE_HYPO				,
			CD_ACHAT_FIN_LOC			,
			MNT_VR						,
			CD_DEVISE_VR				,
			MATURITE_RES				,
			PD_ORIGINE					,
			NOTE_ORIGINE				,
			ORGANISME_NOTATION			,
			CD_METHODO_NOTE_ORI			,
			CD_GRILLE_NOTE_ORI			,
			CD_SEGMENT_NOTE_ORI			,
			TOP_ENG_DOUTEUX				,
			CD_IMP_PRUDENT				,
			CD_NEW_DEFAUT				,
			DT_ENG_DOUTEUX				,
			DT_IMP_PRUDENT				,
			CD_ARR_PAIMENT				,
			DT_PREM_ARRIERE				,
			MNT_ENC_ARR_PAIE			,
			CD_DEVISE_ARR_PAIE			,
			MNT_DTCO					,
			CD_DEVISE_DTCO				,
			TOP_EVT_CREDIT				,
			CD_NATURE_EVT				,
			CD_STATUT_CREDIT			,
			CD_TYPE_CREANCE				,
			CD_TYPE_RESTRUCT			,
			DT_RESTRUCTURATION			,
			DT_DER_RESTRUCT_COM			,
			DT_DER_RESTRUCT_RISK		,
			CD_PD_IFRS					,
			CD_LGD_IFRS					,
			CD_CCF_IFRS					,
			CD_TX_REMB_IFRS				,
			CD_CREANCE_TITRI			,
			CLE_COMPTABLE				,
			DATE_PREM_ACT_FORB			, --03/01/2018 CDS ATOS US 29 (EMM)
			DATE_SORT_EFF_FORB			, --03/01/2018 CDS ATOS US 29 (EMM)
			DATE_ENTR_PER_PURG			, --14/04/2018 CDS ATOS (EMM) US 279 Sprint 7
			DATE_SORT_PER_PURG			, --14/04/2018 CDS ATOS (EMM) US 279 Sprint 7
			DATE_ENTR_PER_PROB			, --14/04/2018 CDS ATOS (EMM) US 279 Sprint 7
			DATE_SORT_PER_PROB			, --14/04/2018 CDS ATOS (EMM) US 279 Sprint 7
			DATE_THEO_FIN_FORB 			, --14/04/2018 CDS ATOS (EMM) US 279 Sprint 7
			DT_SIGNATURE				, 		--30/01/2018 CDS ATOS (JMP) ANACREDIT US45
			DT_PL_NPL							--30/01/2018 CDS ATOS (JMP) ANACREDIT US45
			-- 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
			-- DÃ©ja fait P3 21.8				,DT_DER_RESTRUCT_COM
			,IND_RBT_ANTICIPE
			-- DÃ©ja fait P3 22.82				,DT_IMP_PRUDENT
			-- DÃ©ja fait P3 5.5				,CD_ARR_PAIMENT
			,MNT_BIEN_OCTROI
			-- Fin 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
			-- 11/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US418
			,NOTE_EXT_CORP_ORI
			,NOTE_INT_CORP_ORI
			-- Fin 11/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US418
			--31/07/2018 CDS ATOS (PSR) ANACREDIT Sprint 13 Rework US380
			,DT_REVAL_BIEN
			-- Fin 31/07/2018 CDS ATOS (PSR) ANACREDIT Sprint 13 Rework US380
			,ID_TIERS_CALC -- 05/11/2018 - CDS ATOS (LFD) - ANACREDIT US 593
			--31/01/2019 - CDS ATOS (GBD) - US 671   Debut -- >
			, BUCKET_IFRS9
			, DT_DISPO_FONDS
			, CD_MOTIF_SCO_LC0267
			, NB_JOURS_RETARD
			, MNT_IDEMNITE_RES
			, CD_DEV_MNT_INDEMNITE
			, CD_MOTIF_PL_NPL
			, CD_CONF_AUTOR
			, MNT_MTM
			, CD_DEV_MNT_MTM
			, MNT_CAPITAL_ARR
			, CD_DEV_MNT_CAPITAL_ARR
			, MNT_INT_ARR
			, CD_DEV_MNT_INT_ARR
			, IND_REVOLVING
			, IND_HISTO_IMP
			--31/01/2019 - CDS ATOS (GBD) - US 671   Fin   < --
			--18/02/2019 - CDS ATOS (GBD) - US 731   Debut -- >
			,APPLI_SOURCE
			,CD_DEV_PREM_DEB_FD
			,CD_DEV_MNT_BIEN_OCTROI
			,DT_DTCO
			--18/02/2019 - CDS ATOS (GBD) - US 731   Fin   < --
			, DT_FIN_PAL
			-- US 196
			,null                  AS idLocalTiers
			,null                  AS CdEntSucc
			,cdCtOri               AS cdCtOri
			,cdEDCOri              AS cdEDCOri
			,INDRESPSOLI           AS indRespSoli
			,null                  AS indDiffCartePaie
			--DEBUT: KLxRisqLeasing (BA) - Mantis 11758: fichiers P3C vides
			--,RE.CD_INSEE_COMMUNE AS cdCPBienF -- M11700 CDS ATOS (VFN) 24/09/2021
			--,cdCPBienf 			   AS cdCPBienf
			--FIN: KLxRisqLeasing (BA) - Mantis 11758: fichiers P3C vides
			--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
			,cdInseeBienF		   AS cdInseeBienF
			--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
			,cdPayBienF            AS cdPayBienF
			,null                  AS cdEtatBienF
			,null                  AS cdClassNrjBienF
			-- KLx Risque (VDC) - 16/03/2022 - US 295 Leasing, modification de l'alimentation du P3 31.17 et 31.18
			, CEIL( (DT_FIN_ENG - DT_DEBUT_ENG ) / 30 )		AS nbDIOctroi
			, CEIL( (DT_FIN_ENG - DT_DEBUT_ENG ) / 30 )		AS nbDureeTot
			-- FIN (VDC)
			,null                  AS DurReelPeriAnti
			-- KLx Risque (VDC) - 20/01/2022 - US 283 Leasing - Score 6 'Type de garantie principale a date/a l'octroi'
			,CASE
				WHEN cd_conso_cpt = '00472' THEN '01'
				WHEN cd_conso_cpt IN ('00370','00399','00936') THEN '02'
				ELSE '04'
			END AS cdTypeGarPrincOctroi
			,CASE
				WHEN cd_conso_cpt = '00472' THEN '01'
				WHEN cd_conso_cpt IN ('00370','00399','00936') THEN '02'
				ELSE '04'
			END AS cdTypeGarPrincDt
			,null                  AS mtRemis
			,null                  AS cdDevRemis
			,null                  AS txICROctroi
			,null                  AS txLTROctroi
			,null                  AS txLSTIOctroi
			,null                  AS txDSTIOctroi
			,null                  AS txMardeCreditOctroi
			,null                  AS indConPart
			,null                  AS cdTypPartiEnt
			,null                  AS IdEntPil
			,null                  AS MtGloIni
			,null                  AS cdDevAuto
			,null                  AS MtIniTteTran
			,null                  AS MtMajTteTran
			,null                  AS cdDevTteTran
			,null                  AS MtIniTranAuto
			,null                  AS MtMajTranAuto
			,null                  AS cdDevTteTranAuto
			,null                  AS ParRisqSyndTran
			,null                  AS MtRisqSyndTran
			,null                  AS IndPosEntPortRisq
			,mtCtEuroOri           AS mtCtEuroOri
			,null                  AS cdMetRev
			,mtCapHorsArPai        AS mtCapHorsArPai
			,cdDevCapHorsArPai     AS cdDevCapHorsArPai
			,null                  AS mtDecArPai
			,null                  AS cdDevDecArPai
			,null                  AS mtDecHorsArPai
			,null                  AS cdDevDecHorsArPai
			,MTLOYERSARPAI         AS mtLoyersArPai
			,CDDEVLOYERSARPAI      AS cdDevLoyersArPai
			,MTLOYERSHORSARPAI     AS mtLoyersHorsArPai
			,CDDEVLOYERSHORSARPAI  AS cdDevLoyersHorsArPai
			,MTINTHORSARPAI        AS mtIntHorsArPai
			,cdDevIntHorsArPai     AS cdDevIntHorsArPai
			,cdAnaCred             AS cdAnaCred
			,cdMotifExcluAnaCred   AS cdMotifExcluAnaCred
			,null                  AS nbRest
			,null                  AS cdMethRest
			,null                  AS mtSacriRest
			,null                  AS cdDevSacriRest
			,null                  AS cdNatTitri
			,null                  AS cdCreTitSTR
			,mtSubv                AS mtSubv
			,CD_DEVISE_CRD         AS cdDevSubv
			,mtAvCredBail          AS mtAvCredBail
			,CD_DEVISE_CRD         AS cdDevAvCredBail
			,IndMobAct             AS IndMobAct
			,idMobAct              AS idMobAct
			,cdOrgMob              AS cdOrgMob
			,cdDevLiasse           AS cdDevLiasse
			,noPCCO1               AS noPCCO1
			,mtPCCO1               AS mtPCCO1
			,noPCCO2               AS noPCCO2
			,mtPCCO2               AS mtPCCO2
			,noPCCOCreances        AS noPCCOCreances
			,mtPCCOCreances        AS mtPCCOCreances
			,null                  AS noPCCOJV
			,null                  AS mtPCCOJV
			-- US 196
			,CD_TYPE_PROD_BANCAIRE
		--DEBUT: KLxRisqLeasing (BA) - Mantis 11758: fichiers P3C vides
		    ,LTV_RATIO AS LTV_RATIO-- P3C 22.43
		    ,CD_PAYS_JURIDICTION  AS CD_PAYS_JURIDICTION -- P3C 22.66
		    ,MOTIF_MRTR AS MOTIF_MRTR-- P3C 21.22
		    ,DT_DEBUT_MRTR AS DT_DEBUT_MRTR-- P3C 21.23
		    ,DUREE_MRTR AS DUREE_MRTR-- P3C 21.29
		    ,STATUT_MRTR AS STATUT_MRTR-- P3C 21.25
		    ,IND_MRTR_LEGISLATIF AS IND_MRTR_LEGISLATIF-- P3C 21.26
		    ,IND_MRTR_CONTRACTUEL AS IND_MRTR_CONTRACTUEL-- P3C 21.27
		    ,CHAMP_APPL_MRTR AS CHAMP_APPL_MRTR-- P3C 21.28
		    ,MNT_MRTR AS MNT_MRTR-- P3C 21.30
		    ,DEV_MRTR AS DEV_MRTR-- P3C 21.31
		    ,TRT_MTR_BAL AS TRT_MTR_BAL-- P3C 8.15
		    ,NIV_RISQUE_CRR3 AS NIV_RISQUE_CRR3-- P3C 21.68
		    ,IND_UCC AS IND_UCC-- P3C 21.66
		    ,IND_EXPO_TRANSAC AS IND_EXPO_TRANSAC-- P3C 31.44
		    ,IND_PRET_SALARIE_COND_REG AS IND_PRET_SALARIE_COND_REG-- P3C 31.45
		    ,IND_IPRE AS IND_IPRE-- P3C 21.38
		    ,IND_EXPO_ADC AS IND_EXPO_ADC-- P3C 21.39
		    ,IND_REAL_COND_PONDERATION_PREFE AS IND_REAL_COND_PONDERATION_PREFE-- P3C 21.40
		    ,ETV_RATIO AS ETV_RATIO-- P3C 21.43
		    ,IND_QRRE AS IND_QRRE-- P3C 31.46
		    ,IND_NON_APPLI_ASYMETRIE_DEV AS IND_NON_APPLI_ASYMETRIE_DEV-- P3C 31.47
		    ,COMMUNE AS COMMUNE-- P3C 21.71
		    ,NUM_VOIE AS NUM_VOIE-- P3C 21.72
		    ,EXTENSION AS EXTENSION-- P3C 21.73
		    ,TYPE_VOIE AS TYPE_VOIE-- P3C 21.74
		    ,LIB_VOIE AS LIB_VOIE-- P3C 21.75
		    ,LIEU_DIT AS LIEU_DIT-- P3C 21.76
		    ,LATITUDE AS LATITUDE-- P3C 21.77
		    ,LONGITUDE AS LONGITUDE-- P3C 21.78
		    ,CD_TYPE_BIEN_COMM AS CD_TYPE_BIEN_COMM -- P3C 21.86
		    ,CD_EMPLACE_BIEN_COMM AS CD_EMPLACE_BIEN_COMM-- P3C 21.87
		    ,IND_OPE_AVEC_RECOURS AS IND_OPE_AVEC_RECOURS-- P3C 21.88
		    ,TX_DSCR AS TX_DSCR-- P3C 21.81
		    ,TX_DSCR_PREC AS TX_DSCR_PREC-- P3C 21.82
			,CD_METH_IFRS9_PD_ORIG as CD_METH_IFRS9_PD_ORIG -- projet OMP - P3C 2.99
		from CREDIT_P3
		where cd_conso_cpt = p_cd_conso_cpt;

	--FROM CREDIT_P3 CR, RE_COMMUNE RE, BTR_SURETE_REELLE BSR -- M11700 CDS ATOS (VFN) 24/09/2021
	--where cd_conso_cpt=p_cd_conso_cpt and  RE.CD_POSTAL = CR.CDCPBIENF and RE.LIB_COMMUNE = BSR.VILLE; -- FIN VFN
	--FIN: KLxRisqLeasing (BA) - Mantis 11758: fichiers P3C vides
BEGIN

	cd_cpt := liste_cd_conso('00399','00936','00357','00472','00370','00372'); -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803

	SELECT pack_utilitaire.f_calc_dt_arrete INTO v_dt_arrete from DUAL;
    dbms_output.enable(100000);
    DBMS_OUTPUT.PUT_LINE('Debut P_UTLF_CREDIT_P3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

 FOR CD_CONSO in 1 .. cd_cpt.count -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  LOOP
  BEGIN

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier||cd_cpt(CD_CONSO));

  --ouverture du fichier en mode Append.
  --le fichier resultat est supprime avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  --01/02/2019 - CDS ATOS (SQN) - US 683
  --v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;P3CX;01;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1554);
  --v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;P3CX;03;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1554);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
    --v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| cd_cpt(CD_CONSO) ||';BTR                             ;P3CX;05;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',2696); -- BALE4
    v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| cd_cpt(CD_CONSO) ||';BTR                             ;P3CX;06;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',4386); -- BALE4
  -- FIN LFD
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);

  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_P3(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
		'01'||';'||
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'|| -- P3 1.7
		-- 18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, modifier l'alimentation du segment P3 dans le fichier
		  ---- 05/11/2018 - CDS ATOS (LFD) - ANACREDIT US 593
		  --CASE WHEN C_CPT.CD_CONSO_CPT = '00357' THEN RPAD(nvl(to_char(C_ENR.ID_TIERS_CALC),' '),20) ELSE RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)	END		||';'||
		  ----FIN LFD
		  RPAD(nvl(to_char(C_ENR.ID_TIERS_CALC),' '),20) ||';'|| -- P3 1.1
		-- 18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, modifier l'alimentation du segment P3 dans le fichier
		  RPAD(nvl(C_ENR.CD_SYS_INT,' '),20)				||';'|| -- P3 1.20
		  RPAD(' ',7)										||';'|| -- P3 1.29
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'|| -- P3 1.21
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'|| -- P3 1.22
		  RPAD(' ',5)										||';'|| -- P3 1.30
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'|| -- P3 1.31
		  RPAD('R_BTR',12)										||';'|| -- P3 0.9
		  RPAD(nvl(C_ENR.ID_AGREGAT,' '),30)				||';'|| -- P3 1.6
		  RPAD(nvl(C_ENR.ID_AGREGAT,' '),100)				||';'|| -- P3 8.8
		  RPAD(nvl(C_ENR.CD_METHODO_BALE2,' '),7)			||';'|| -- P3 1.1
		  RPAD(nvl(C_ENR.ELIGIBILITE_OMP,' '),1)			||';'|| -- P3 23.1
		  RPAD(nvl(C_ENR.CD_NATURE_OPE,' '),12)				||';'|| -- P3 1.2
		  RPAD(nvl(C_ENR.CD_NATURE_PNU,' '),12)				||';'|| -- P3 8.16
		  RPAD(nvl(C_ENR.CD_CLASS_CPT_LOC,' '),3)			||';'|| -- P3 23.5
		  RPAD(nvl(C_ENR.CD_CLASS_CPT_REF,' '),3)			||';'|| -- P3 19.5
		  RPAD(nvl(C_ENR.CD_CLASS_CPT_IFR,' '),3)			||';'|| -- P3 23.4
		  RPAD(nvl(C_ENR.CD_TYPE_RISQUE,' '),6)				||';'|| -- P3 2.0
		  RPAD(nvl(C_ENR.CD_TYPE_PROD_BANCAIRE,' '),6)		||';'|| -- P3 2.30
		  RPAD(nvl(C_ENR.CD_PTF_BOOKING,' '),1)				||';'|| -- P3 2.4
		  RPAD(nvl(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3)		||';'|| -- P3 8.4
		  RPAD(nvl(C_ENR.CD_LIGNE_METIER,' '),5)			||';'|| -- P3 8.5
		  RPAD(nvl(C_ENR.CD_CIRCUIT_DISTRIB,' '),2)			||';'|| -- P3 8.9
		  RPAD(nvl(C_ENR.BUCKET_IFRS9,' '),2)				||';'||--31/01/2019 - CDS ATOS (GBD) - US 671  P3 22.72
		  RPAD(nvl(C_ENR.IND_POCI,' '),1)					||';'|| -- P3 23.6
		  RPAD(nvl(C_ENR.CD_OBJET_FIN,' '),2)				||';'|| -- P3 8.10
		  RPAD(' ',2)										||';'|| -- P3 22.64
		  RPAD(' ',1)										||';'|| -- P3 22.90
		  RPAD(' ',1)										||';'|| -- P3 22.91
		  RPAD(nvl(C_ENR.CD_USAGE_BIEN_IMM,' '),1)			||';'|| -- P3 8.13
		  RPAD(' ',15)										||';'|| -- P3 22.42
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.LTV_RATIO,0))||';'|| -- P3 22.43 -- bale4
		  RPAD(' ',15)										||';'|| -- P3 22.65
		  RPAD(' ',15)										||';'|| -- P3 22.49
		  RPAD(' ',15)										||';'|| -- P3 22.13
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TIE_ORIGINE,0))||';'|| -- P3 2.11
		  --19/04/18 CDS Atos (EMM) US 279 inhibition du code du C3RD 1.1 pour revenir au C3RD initial
		  RPAD(nvl(C_ENR.CD_CONF_AUTOR,' '),1)					||';'||  -- CDS ATOS (JMP) ANACREDIT US45 (P3 2.11) --31/01/2019 - CDS ATOS (GBD) - US 671 P3 2.11
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS, 'YYYYMMDD'), ' '), 8)||';'|| -- 31/01/2019 - CDS ATOS (GBD) - US 671   P3 4.47
		  RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8)||';'|| -- CDS ATOS (JMP) ANACREDIT US45 (P3 22.67) --31/01/2019 - CDS ATOS (GBD) - US 671 P3 22.67
		  --Fin EMM
   		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 3.2
   		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG_REN, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.63
   		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 3.4
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG_BIL, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.80
		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG_BIL, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.81
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DEB_FD, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.31
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_PREM_DEB_FD,0))||';'||  -- P3 22.32
		  RPAD(nvl(C_ENR.CD_DEV_PREM_DEB_FD,'EUR'),3)       ||';'||   -- P3 22.33 devise 1er deblocage fond    -- 18/02/2019 - CDS ATOS (GBD) - US731
		  RPAD('ECH',3)||';'||   -- P3 22.56 Indicateur produit Ã©chÃ©ancÃ©
		  RPAD(nvl(C_ENR.IND_ECH,' '),1)					||';'|| -- P3 22.12
		  RPAD(nvl(C_ENR.IND_PAL,' '),1)					||';'|| -- P3 22.57
		  RPAD(nvl(C_ENR.CD_TYPE_TAUX,' '),1)				||';'|| -- P3 8.11
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TIE_ORIGINE,0))||';'|| -- P3 22.19
		  RPAD(nvl(C_ENR.CD_TYPE_AMO,' '),1)				||';'|| -- P3 22.16
		  RPAD(nvl(C_ENR.CD_PERIODICITE_K,' '),1)			||';'|| -- P3 22.17
		  RPAD(nvl(C_ENR.CD_PERIODICITE_I,' '),1)			||';'|| -- P3 22.18
		  RPAD(nvl(C_ENR.CD_MODALITE_RBT,' '),1)			||';'|| -- P3 22.20
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_ECH, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.21		---- 06/12/2017 CDS ATOS (EMM) Sprint 2 US 28
		  RPAD(' ',8)										||';'|| -- P3 22.22
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG+1, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.58
	--11/04/2019 - CDS AtoS FAD - MCO Leasing M47350 - US778
		  --RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG-1, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_PAL, 'YYYYMMDD'), ' '), 8)||';'|| --> E0_22_59_DT_FIN_PAL -- P3 22.59
	--Fin - CDS AtoS FAD - MCO Leasing M47350 - US778
		 RPAD(' ',15)                                                                           ||';'|| -- P3 22.23
		 RPAD(' ',15)                                                                           ||';'|| -- P3 22.24
		  --pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_PLAFOND,0))||';'||
		  --pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_PLANCHER,0))||		';'||
		  RPAD(nvl(C_ENR.CD_PERIODICITE_REV_TX,' '),1)		||';'|| -- P3 22.25
		  LPAD(nvl(C_ENR.CD_PERIODICITE_REV_TX_NB,'1'),3)	||';'|| -- P3 22.26
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_CLI_OCTROI,0))||';'|| -- P3 22.27
		  RPAD(nvl(C_ENR.IND_REF_TV,' '),12)				||';'|| -- P3 22.15
		  RPAD(nvl(C_ENR.IND_IDX_PAL,' '),1)				||';'|| -- P3 22.62
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_MARGE_ADD,0))||';'|| -- P3 22.28
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_MARGE_MUL,0))||';'|| -- P3 22.29
		  RPAD(nvl(C_ENR.BASE_INT,' '),7)					||';'|| -- P3 22.30
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CRD,0))||';'|| -- P3 22.34
		  RPAD(' ',19)||	';'|| -- P3 22.60
		  RPAD(' ',3)||	';'|| -- P3 22.61
		  --DEBUT: KLx_Risques(BA) - US 296: Score 6 - Montants DÃ©couvert, Capital et Loyer
		  RPAD(' ', 19)															||';'|| --P3 8.17 - Montant du dÃ©couvert :: AVANT: pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_DECOUVERT,0))
		  RPAD(' ', 3)															||';'|| --P3 8.18 - Devise du dÃ©couvert  :: AVANT: nvl(C_ENR.CD_DEVISE_CRD,' ')
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI103')
		    then pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CRD, 0))
			else RPAD(' ', 19)
		  end																	||';'|| --P3 8.19 * Montant du Capital restant dÃ»
		  RPAD(nvl(C_ENR.CD_DEVISE_CRD, 'EUR'), 3)||';'|| --P3 8.20 - Devise du Capital restant dÃ»	-M12701 Bâle 4
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI105','TRE504')
		    then pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_LOYER, 0))
			else RPAD(' ', 19)
		  end 																	||';'|| --P3 8.21 - Montant des loyers
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI105','TRE504')
		    then RPAD(nvl(C_ENR.CD_DEVISE_LOY, 'EUR'), 3)
			else RPAD(' ', 3)
		  end																	||';'|| --P3 8.22 - Devise des loyers
		  --FIN: KLx_Risques(BA) - US 296: Score 6 - Montants DÃ©couvert, Capital et Loyer
		  pack_utilitaire.f_format_montant_BIS2(0)||';'|| -- P3 6.1
		  RPAD(nvl(C_ENR.CD_DEVISE_IRD,' '),3)				||	';'|| -- P3 6.2
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_PNU,0))||';'|| -- P3 3.5
		  RPAD(nvl(C_ENR.CD_DEVISE_PNU,' '),3)				||	';'|| -- P3 3.6
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CONTRAT_ORIG,0))||';'|| -- P3 3.1
		  RPAD(nvl(C_ENR.CD_DEVISE_ORIG,' '),3)				||	';'|| -- P3 18.18
-- 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
--		  RPAD(' ',19)										||	';'||
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_MTM,0))||';'|| -- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 3.52
		  RPAD(nvl(C_ENR.CD_DEV_MNT_MTM,'EUR'),3)				||';'||-- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 3.53  -- 12/02/2019 - CDS AtoS FAD - CRRV4.2 - Correctif : devise Ã¿ EUR par dÃ©faut.
		pack_utilitaire.f_format_montant_BIS3(C_ENR.MNT_BIEN_OCTROI)||';'||  -- P3 22.44 (84 em champ)
-- Fin 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
-- 31/07/2018 CDS ATOS (PSR) ANACREDIT -
-- 27/07/2018 CDS ATOS (PSR) ANACREDIT - MODIFICATION URGENTE
		 -- RPAD(' ',3)										||	';'||
		 CASE WHEN C_ENR.MNT_BIEN_OCTROI IS NULL THEN RPAD(' ',3)
		 ELSE RPAD(nvl(C_ENR.CD_DEV_MNT_BIEN_OCTROI,'EUR'),3)                    -- 18/02/2019 - CDS ATOS (GBD) - US731
		 END                                                                     -- P3 22.45
		 ||';'||
-- Fin MODIFICATION URGENTE
-- 31/07/2018 CDS ATOS (PSR) ANACREDIT Sprint 13 Rework US380
		  RPAD(NVL(TO_CHAR(C_ENR.DT_REVAL_BIEN, 'YYYYMMDD'), ' '), 8)||';'|| --P3 22.46
-- Fin Rework US380
		pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_VAL_MARCHE,0))||';'|| -- P3 4.6
		  RPAD(nvl(C_ENR.CD_DEVISE_MARCHE,' '),3)			||			  ';'|| -- P3 4.7
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_HYPOTHEQUE,0))||';'|| -- P3 4.8
		  RPAD(nvl(C_ENR.CD_DEVISE_HYPO,' '),3)				||						';'||	-- P3 4.9
		  RPAD(nvl(C_ENR.CD_ACHAT_FIN_LOC,' '),1)			||							';'|| -- P3 4.11
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_VR,0))||';'|| -- P3 4.1
		  RPAD(nvl(C_ENR.CD_DEVISE_VR,' '),3)				||				';'||	 -- P3 4.2
		  LPAD(nvl(to_char(round(CASE WHEN C_ENR.MATURITE_RES BETWEEN 0 AND 1 THEN 1 ELSE C_ENR.MATURITE_RES END)),'000'),3,'0')				||			';'|| -- P3 4.12
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.PD_ORIGINE,0))||';'|| -- P3 40.1
		  RPAD(nvl(C_ENR.NOTE_ORIGINE,' '),2)				||				';'|| -- P3 40.2
		  RPAD(nvl(C_ENR.ORGANISME_NOTATION,' '),2)			||					';'|| -- P3 40.3
-- 11/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US418
--		  RPAD(' ',10)										||';'||
--		  RPAD(' ',2)										||';'||
		  RPAD(nvl(C_ENR.NOTE_EXT_CORP_ORI,' '),10) ||';'||	-- P3 40.4
		  RPAD(nvl(C_ENR.NOTE_INT_CORP_ORI,' '),2) ||';'||	-- P3 40.5
-- Fin 11/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US418
		  RPAD(nvl(C_ENR.CD_METHODO_NOTE_ORI,' '),3)		||';'||	-- P3 40.6
		  RPAD(nvl(C_ENR.CD_GRILLE_NOTE_ORI,' '),23)		||';'|| -- P3 40.7
		  RPAD(nvl(C_ENR.CD_SEGMENT_NOTE_ORI,' '),2)		||';'|| -- P3 40.8
		  RPAD(' ',15)										||';'|| -- P3 40.9
		  RPAD(' ',2)										||';'|| -- P3 40.10
-- 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
--		  RPAD(' ',1)										||';'||
		  RPAD(' ',3)										||';'|| -- P3 40.12     -- US196
		  RPAD(nvl(C_ENR.IND_RBT_ANTICIPE,' '),1)			||';'|| -- P3 22.36
-- Finn 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
		  RPAD(nvl(C_ENR.TOP_ENG_DOUTEUX,' '),1)			||';'||	-- P3 9.14
		  RPAD(nvl(C_ENR.CD_IMP_PRUDENT,' '),1)				||';'||	-- P3 8.25
		  RPAD(nvl(C_ENR.CD_NEW_DEFAUT,' '),1)				||';'||	-- P3 8.29
		  RPAD(NVL(TO_CHAR(C_ENR.DT_ENG_DOUTEUX, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 5.2
		  RPAD(NVL(TO_CHAR(C_ENR.DT_IMP_PRUDENT, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.82
-- 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
--		  RPAD(nvl(C_ENR.CD_NEW_DEFAUT,' '),1)				||';'||
		 -- 12/02/2019 - CDS AtoS FAD - CRRV4.2 - Correctif : CD_MOTIF_SCO_LC0267 : complÃ©ter le code Ã¿ gauche Ã¿ 0.
  		  --LPAD(nvl(C_ENR.CD_MOTIF_SCO_LC0267,' '),3,'0')		||';'||   -- 31/01/2019 - CDS ATOS (GBD) - US 671     P3 22.71     cdPasEngDout
		--15/02/19 CDS ATOS (EMM) Correctif 2 score 7
		CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3)
		ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||';'|| -- P3 22.71
		--Fin EMM
		  RPAD(nvl(C_ENR.CD_ARR_PAIMENT,' '),1)				||';'|| -- P3 5.5
-- Fin 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_ARRIERE, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 22.37
		  RPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '0'), 5)      ||';'||-- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 22.70 < exemple  ;+123;
		  pack_utilitaire.f_format_montant_BIS2( CASE WHEN nvl(C_ENR.MNT_ENC_ARR_PAIE,0) > 0 THEN nvl(C_ENR.MNT_ENC_ARR_PAIE,0) ELSE 0 END)||';'|| -- P3 9.3
		  RPAD(nvl(C_ENR.CD_DEVISE_ARR_PAIE,' '),3)			||';'|| -- P3 9.4
		  --DEBUT: KLx_Risques(BA) - US 296: Score 6 - Montants DÃ©couvert, Capital et Loyer
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI103')
			then pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CAPITAL_ARR, 0))
			else RPAD(' ', 19)
		  end																			||';'|| --P3 9.31 - Montant du capital en arriÃ©rÃ© de paiement :: AVANT: CDS ATOS (GBD) - US 671
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI103')
		    then RPAD(nvl(C_ENR.CD_DEV_MNT_CAPITAL_ARR, 'EUR'), 3)
			else RPAD(' ', 3)
		  end																			||';'|| --P3 9.41 - Devise du capital en arriÃ©rÃ© de paiement  :: AVANT: CDS ATOS (GBD) - US 671
		  --FIN: KLx_Risques(BA) - US 296: Score 6 - Montants DÃ©couvert, Capital et Loyer
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_INT_ARR,0))||';'||   --31/01/2019 - CDS ATOS (GBD) - US 671     p3 9.32
		  RPAD(nvl(C_ENR.CD_DEV_MNT_INT_ARR,'EUR'),3)			||';'||                --31/01/2019 - CDS ATOS (GBD) - US 671     p3 9.42
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DTCO, 'YYYYMMDD'), ' '), 8)   ||';'||          -- 18/02/2019 - CDS ATOS (GBD) - US731     P3 22.38
		  CASE WHEN C_ENR.MNT_DTCO < 0 then pack_utilitaire.f_format_montant_bis2(0) ELSE pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_DTCO,0)) END ||';'||		--M11680 14/09/2021 - CDS ATOS(VFN)       P3 9.13
		  RPAD(nvl(C_ENR.CD_DEVISE_DTCO,' '),3)				||';'|| -- P3 9.6
		  RPAD(' ',19)										||';'|| -- P3 9.7
		  RPAD(' ',3)										||';'|| -- P3 9.10
		  RPAD(' ',8)										||';'|| -- P3 22.41
		  RPAD(' ',19)||  ';'|| -- P3 26.1
                  RPAD(' ',3)||   ';'|| -- P3 26.2
		  RPAD(nvl(C_ENR.TOP_EVT_CREDIT,' '),1)				||';'|| -- P3 21.3
		  RPAD(nvl(C_ENR.CD_NATURE_EVT,' '),1)				||';'|| -- P3 21.4
		  RPAD(nvl(C_ENR.CD_STATUT_CREDIT,' '),1)				||';'||	-- P3 21.5			--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.5)
		  --RPAD(' ', 1)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(nvl(C_ENR.CD_TYPE_CREANCE,' '),2)				||';'|| -- P3 21.6
		  RPAD(nvl(C_ENR.CD_TYPE_RESTRUCT,' '),2)				||';'|| -- P3 8.28
		  RPAD(NVL(TO_CHAR(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 21.2
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DER_RESTRUCT_COM, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 21.8
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DER_RESTRUCT_RISK, 'YYYYMMDD'), ' '), 8)||';'|| -- P3 21.9
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_PREM_ACT_FORB, 'YYYYMMDD'), ' '), 8)	||';'||		--03/01/2018 CDS ATOS (EMM) Sprint 2 US 29 (P3 21.7)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US29
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PURG, 'YYYYMMDD'), ' '), 8) ||';'||	--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.10)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PURG, 'YYYYMMDD'), ' '), 8) ||';'||	--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.11)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_ENTR_PER_PROB, 'YYYYMMDD'), ' '), 8) ||';'||	--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.12)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_PER_PROB, 'YYYYMMDD'), ' '), 8) ||';'||	--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.13)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_THEO_FIN_FORB, 'YYYYMMDD'), ' '), 8) ||';'||	--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.14)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(NVL(TO_CHAR(C_ENR.DATE_SORT_EFF_FORB, 'YYYYMMDD'), ' '), 8)	||';'||		--03/01/2018 CDS ATOS (EMM) Sprint 2 US 29 (P3 21.15)
		  -- RPAD(' ', 8)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US29
		  --19/04/18 CDS Atos (EMM) US 279 inhibition du code du C3RD 1.1 pour revenir au C3RD initial
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PL_NPL, 'YYYYMMDD'), ' '), 8)	||';'||	-- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 21.16
		  RPAD(nvl(C_ENR.CD_MOTIF_PL_NPL,' '),2)				||';'||     -- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 21.17
		  --Fin EMM
		  RPAD(nvl(C_ENR.CD_PD_IFRS,' '),12)				||';'|| -- P3 23.8
		  RPAD(nvl(C_ENR.CD_LGD_IFRS,' '),12)				||';'|| -- P3 23.9
		  RPAD(nvl(C_ENR.CD_CCF_IFRS,' '),12)				||';'|| -- P3 23.10
		  RPAD(nvl(C_ENR.CD_TX_REMB_IFRS,' '),12)			||';'|| -- P3 23.11
		  RPAD(' ',2)										||	';'|| -- P3 8.26
		  RPAD(nvl(C_ENR.CD_CREANCE_TITRI,' '),1)			||';'|| -- P3 8.31
		  RPAD(' ',3)										||	';'|| -- P3 8.40
		  RPAD(' ',1)										||	';'|| -- P3 8.41
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_IDEMNITE_RES,0))  ||';'||  --31/01/2019 - CDS ATOS (GBD) - US 671       P3 29.1
		  -- 13/02/2019 - CDS ATOS (SQN) CRRV4.2 - correctif scores 6 : forcer CD_DEV_MNT_INDEMNITE Ã¿ EUR
		  RPAD(nvl(C_ENR.CD_DEV_MNT_INDEMNITE,'EUR'),3)		||';'||		                 --31/01/2019 - CDS ATOS (GBD) - US 671       P3 29.2
		  RPAD(nvl(C_ENR.CLE_COMPTABLE,' '),40)			||';'|| -- P3 23.7
		  RPAD(' ',5)	||';'|| -- P3 23.12
		  RPAD(' ',5)	||';'|| -- P3 23.13
		  RPAD(' ',1)		||';'|| -- P3 22.10
		  RPAD(nvl(C_ENR.IND_REVOLVING,' '),1)				||';'||     -- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 5.6
		  RPAD(nvl(C_ENR.IND_HISTO_IMP,' '),2)				||';'||     -- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 40.11
		  --RPAD(' ',95);	   												-- 31/01/2019 - CDS ATOS (GBD) - US 671  reduit de 100 Ã¿ 95
		  -- US196
          RPAD(NVL(C_ENR.idLocalTiers                   ,' '), 20)           ||';'|| -- P3 1.3
          RPAD(NVL(C_ENR.CdEntSucc                      ,' '),  5)           ||';'|| -- P3 31.1
          RPAD(NVL(C_ENR.cdCtOri                        ,' '), 40)           ||';'|| -- P3 31.2
          RPAD(NVL(C_ENR.cdEDCOri                       ,' '), 40)           ||';'|| -- P3 31.3
          RPAD(NVL(C_ENR.indRespSoli                    ,' '),  1)           ||';'|| -- P3 31.5
          RPAD(NVL(C_ENR.indDiffCartePaie               ,' '),  1)           ||';'|| -- P3 22.69
		  --DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
          RPAD(NVL(C_ENR.cdInseeBienF                   ,' '), 15)           ||';'|| -- P3 31.9
		  --FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
          RPAD(NVL(C_ENR.cdPayBienF                     ,' '),  2)           ||';'|| -- P3 31.10
          RPAD(NVL(C_ENR.cdEtatBienF                    ,' '),  1)           ||';'|| -- P3 31.12
          RPAD(NVL(C_ENR.cdClassNrjBienF                ,' '),  1)           ||';'|| -- P3 31.13
          CASE WHEN C_ENR.nbDIOctroi IS NULL THEN '      '
               WHEN C_ENR.nbDIOctroi < 0 THEN '-' || LPAD(ABS(C_ENR.nbDIOctroi),5,'0')
               ELSE    '+' ||  LPAD(TO_CHAR( C_ENR.nbDIOctroi ),5,'0')
               END                                                           ||';'|| -- P3 31.17
          CASE WHEN C_ENR.nbDureeTot IS NULL THEN '      '
               WHEN C_ENR.nbDureeTot < 0 THEN '-' || LPAD(ABS(C_ENR.nbDureeTot),5,'0')
               ELSE    '+' ||  LPAD(TO_CHAR( C_ENR.nbDureeTot ),5,'0')
               END                                                           ||';'|| -- P3 31.18
          CASE WHEN C_ENR.DurReelPeriAnti IS NULL THEN '      '
               WHEN C_ENR.DurReelPeriAnti < 0 THEN '-' || LPAD(ABS(C_ENR.DurReelPeriAnti),5,'0')
               ELSE    '+' ||  LPAD(TO_CHAR( C_ENR.DurReelPeriAnti ),5,'0')
               END                                                           ||';'|| -- P3 31.19
          RPAD(NVL(C_ENR.cdTypeGarPrincOctroi           ,' '),  2)           ||';'|| -- P3 31.21
          RPAD(NVL(C_ENR.cdTypeGarPrincDt               ,' '),  2)           ||';'|| -- P3 31.22
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtRemis ,0))       ||';'|| -- P3 31.23
          RPAD(NVL(C_ENR.cdDevRemis                     ,'EUR'),  3)           ||';'|| --P3 31.24 --M11696 - CDS ATOS 16/09/2021
          pack_utilitaire.f_format_taux_15(nvl(C_ENR.txICROctroi        ,0)) ||';'|| -- P3 31.25
          pack_utilitaire.f_format_taux_15(nvl(C_ENR.txLTROctroi        ,0)) ||';'|| -- P3 31.26
          pack_utilitaire.f_format_taux_15(nvl(C_ENR.txLSTIOctroi       ,0)) ||';'|| -- P3 31.27
          pack_utilitaire.f_format_taux_15(nvl(C_ENR.txDSTIOctroi       ,0)) ||';'|| -- P3 31.28
          pack_utilitaire.f_format_taux_15(nvl(C_ENR.txMardeCreditOctroi,0)) ||';'|| -- P3 31.29
          RPAD(NVL(C_ENR.indConPart                     ,'0'),  1)           ||';'|| -- P3 41.1 -- M11703 - CDS ATOS (VFN) 21/09/2021
          RPAD(NVL(C_ENR.cdTypPartiEnt                  ,' '),  1)           ||';'|| -- P3 41.2
          RPAD(NVL(C_ENR.IdEntPil                       ,' '),  5)           ||';'|| -- P3 41.3
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtGloIni ,0))      ||';'|| -- P3 41.4
          RPAD(NVL(C_ENR.cdDevAuto                      ,'EUR'),  3)           ||';'|| -- P3 41.5 -- M11702 CDS ATOS (VFN) 21/09/2021
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtIniTteTran ,0))  ||';'|| -- P3 41.6
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtMajTteTran ,0))  ||';'|| -- P3 41.7
          RPAD(NVL(C_ENR.cdDevTteTran                   ,'EUR'),  3)           ||';'|| -- P3 41.8 -- M11704 CDS ATOS (VFN) 21/09/2021
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtIniTranAuto ,0)) ||';'|| -- P3 41.9
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtMajTranAuto ,0)) ||';'|| -- P3 41.10
          RPAD(NVL(C_ENR.cdDevTteTranAuto               ,'EUR'),  3)           ||';'|| -- P3 41.11 -- M11701 CDS ATOS (VFN) 21/09/2021
          pack_utilitaire.f_format_taux_15(nvl(C_ENR.ParRisqSyndTran ,0))    ||';'|| -- P3 41.12
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtRisqSyndTran ,0))||';'|| -- P3 41.13
          RPAD(NVL(C_ENR.IndPosEntPortRisq              ,' '),  1)           ||';'|| -- P3 41.14
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtCtEuroOri ,0))   ||';'|| -- P3 31.4
          RPAD(NVL(C_ENR.cdMetRev                       ,' '),  1)           ||';'|| -- P3 31.20
		  --DEBUT: KLx_Risques(BA) - US 296: Score 6 - Montants DÃ©couvert, Capital et Loyer
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI103')
		    then pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtCapHorsArPai, 0))
			else RPAD(' ', 19)
		  end																			||';'|| --P3 9.33 - Montant du capital hors arriÃ©rÃ© de paiement
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI103')
			then RPAD(NVL(C_ENR.cdDevCapHorsArPai, 'EUR'), 3)
			else RPAD(' ', 3)
		  end											          						||';'|| --P3 9.43 - Devise du capital hors arriÃ©rÃ© de paiement    :: AVANT: M11705 CDS ATOS
		  RPAD(' ', 19)																	||';'|| --P3 9.35 - Montant du dÃ©couvert en arriÃ©rÃ© de paiement   :: AVANT: pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtDecArPai ,0))
		  RPAD(' ', 3)																	||';'|| --P3 9.45 - Devise du dÃ©couvert en arriÃ©rÃ© de paiement    :: AVANT: RPAD(NVL(C_ENR.cdDevDecArPai,'EUR'),3)
		  RPAD(' ', 19)																	||';'|| --P3 9.36 - Montant du dÃ©couvert hors arriÃ©rÃ© de paiement :: AVANT: pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtDecHorsArPai ,0))
		  RPAD(' ', 3)																	||';'|| --P3 9.46 - Devise du dÃ©couvert hors arriÃ©rÃ© de paiement  :: AVANT: RPAD(NVL(C_ENR.cdDevDecHorsArPai,'EUR'),3)
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI105','TRE504')
		    then pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtLoyersArPai, 0))
			else RPAD(' ', 19)
		  end																			||';'|| --P3 9.37 - Montant des loyers en arriÃ©rÃ© de paiement
		  case when C_ENR.CD_TYPE_RISQUE in ('PRI105','TRE504')
		    then RPAD(NVL(C_ENR.cdDevLoyersArPai, 'EUR'), 3)
			else RPAD(' ', 3)
		  end   				       											 		||';'|| --P3 9.47 - Devise des loyers en arriÃ©rÃ© de paiement      :: AVANT: KLxRisqLeasing (BA) - M11792
          case when C_ENR.CD_TYPE_RISQUE in ('PRI105','TRE504')
		    then pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtLoyersHorsArPai, 0))
			else RPAD(' ', 19)
		  end																			||';'|| --P3 9.38 - Montant des loyers hors arriÃ©rÃ© de paiement
          case when C_ENR.CD_TYPE_RISQUE in ('PRI105','TRE504')
		    then RPAD(NVL(C_ENR.cdDevLoyersHorsArPai, 'EUR'), 3)
			else RPAD(' ', 3)
		  end																			||';'|| --P3 9.48 - Devise des loyers hors arriÃ©rÃ© de paiement    :: AVANT: KLxRisqLeasing (BA) - M11792
		  --FIN: KLx_Risques(BA) - US 296: Score 6 - Montants DÃ©couvert, Capital et Loyer
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtIntHorsArPai ,0))||';'|| -- P3 9.34
          RPAD(NVL(C_ENR.cdDevIntHorsArPai ,'EUR'),  3)||';'|| -- P3 9.44 -- M11706 CDS ATOS (VFN) 21/09/2021 - M12701 Bâle 4s
          RPAD(NVL(C_ENR.cdAnaCred                      ,' '),  1)           ||';'|| -- P3 27.3
          RPAD(NVL(C_ENR.cdMotifExcluAnaCred            ,' '),  2)           ||';'|| -- P3 27.4
          RPAD(NVL(C_ENR.nbRest                         ,' '),  2)           ||';'|| -- P3 21.18
          RPAD(NVL(C_ENR.cdMethRest                     ,' '),  2)           ||';'|| -- P3 21.19
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtSacriRest ,0))   ||';'|| -- P3 21.20
          RPAD(NVL(C_ENR.cdDevSacriRest                 ,'EUR'),  3)         ||';'|| -- P3 21.21 -- M11695 CDS ATOS (VFN) 16/09/2021
          RPAD(NVL(C_ENR.cdNatTitri                     ,' '),  1)           ||';'|| -- P3 16.16
          RPAD(NVL(C_ENR.cdCreTitSTR                    ,' '),  1)           ||';'|| -- P3 4.48
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtSubv ,0))        ||';'|| -- P3 29.3
          RPAD(NVL(C_ENR.cdDevSubv                      ,' '),  3)           ||';'|| -- P3 29.4
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtAvCredBail ,0))  ||';'|| -- P3 29.5
          RPAD(NVL(C_ENR.cdDevAvCredBail                ,' '),  3)           ||';'|| -- P3 29.6
          RPAD(NVL(C_ENR.IndMobAct                      ,' '),  1)           ||';'|| -- P3 22.11
          RPAD(NVL(C_ENR.idMobAct                       ,' '),  3)           ||';'|| -- P3 22.14
          RPAD(NVL(C_ENR.cdOrgMob                       ,' '),  3)           ||';'|| -- P3 22.35
          RPAD(NVL(C_ENR.cdDevLiasse                    ,'EUR'),  3)         ||';'|| -- P3 50.1 --KLxRisqLeasing (BA) - M11793: Devise Liasse
          RPAD(NVL(C_ENR.noPCCO1                        ,' '), 12)           ||';'|| -- P3 50.2
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtPCCO1 ,0))       ||';'|| -- P3 50.3
          RPAD(NVL(C_ENR.noPCCO2                        ,' '), 12)           ||';'|| -- P3 50.4
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtPCCO2 ,0))       ||';'|| -- P3 50.5
          RPAD(NVL(C_ENR.noPCCOCreances                 ,' '), 12)           ||';'|| -- P3 50.8
		  case
		  when C_ENR.mtPCCOCreances is not null
		  then pack_utilitaire.f_format_montant_BIS2(C_ENR.mtPCCOCreances)
		  else RPAD(' ', 19)
		   end 																 ||';'|| -- P3 50.9
          RPAD(NVL(C_ENR.noPCCOJV                       ,' '), 12)           ||';'|| -- P3 50.18
          pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtPCCOJV ,0))      ||';'|| -- P3 50.19
          RPAD(NVL(C_ENR.CD_PAYS_JURIDICTION,' '),2)         ||';'||--P3C 22.66
          RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2)         ||';'||--P3C 21.22
          RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'),' '),8)         ||';'||--P3C 21.23
          case when C_ENR.DUREE_MRTR is not null then '+'||LPAD(C_ENR.DUREE_MRTR,5,'0') else RPAD(' ',6) end ||';'||--P3C 21.29
          RPAD(NVL(C_ENR.STATUT_MRTR,' '),2)         ||';'||--P3C 21.25
          RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1)         ||';'||--P3C 21.26
          RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1)         ||';'||--P3C 21.27
          RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2)         ||';'||--P3C 21.28
          case when C_ENR.MNT_MRTR is not null then pack_utilitaire.f_format_montant_BIS2(C_ENR.MNT_MRTR) else RPAD(' ',19) end ||';'||--P3C 21.30
          case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV_MRTR,' '),3) else RPAD(' ',3) end ||';'||--P3C 21.31
          RPAD(' ',15)         ||';'||--P3C 21.32
          RPAD(' ',3)         ||';'||--P3C 21.33
          RPAD(' ',12)         ||';'||--P3C 15
          RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '),12) ||';'|| --P3C 2.99
          RPAD(' ',12)         ||';'||--P3C 14
          RPAD(' ',1)         ||';'||--P3C 21.34
          RPAD(' ',1)         ||';'||--P3C 21.35
          RPAD(NVL(C_ENR.TRT_MTR_BAL,' '),2)         ||';'||--P3C 8.15
          RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1)         ||';'||--P3C 21.68
          RPAD(' ',2)         ||';'||--P3C 8.33
          RPAD(' ',19)         ||';'||--P3C 8.35
          RPAD(' ',3)         ||';'||--P3C 8.36
          RPAD(' ',1)         ||';'||--P3C 3.16
          RPAD(' ',1)         ||';'||--P3C 3.15
          RPAD(' ',25)         ||';'||--P3C 13.10
          RPAD(' ',8)         ||';'||--P3C 3.3
          RPAD(' ',12)         ||';'||--P3C 12.3
          RPAD(' ',8)         ||';'||--P3C 12.6
          RPAD(' ',1)         ||';'||--P3C 3.36
          RPAD(' ',19)         ||';'||--P3C 31.41
          RPAD(' ',3)         ||';'||--P3C 31.42
          RPAD(' ',25)         ||';'||--P3C 3.17
          RPAD(' ',19)         ||';'||--P3C 13.1
          RPAD(' ',3)         ||';'||--P3C 13.2
          RPAD(' ',19)         ||';'||--P3C 13.4
          RPAD(' ',3)         ||';'||--P3C 13.5
          RPAD(' ',1)         ||';'||--P3C 4.37
          RPAD(' ',1)         ||';'||--P3C 7.24
          RPAD(' ',1)         ||';'||--P3C 7.25
          RPAD(' ',3)         ||';'||--P3C 7.0
          RPAD(' ',2)         ||';'||--P3C 15.1
          RPAD(' ',2)         ||';'||--P3C 15.2
          RPAD(' ',2)         ||';'||--P3C 12.1
          RPAD(NVL(C_ENR.IND_UCC,' '),1)         ||';'||--P3C 21.66
          RPAD(NVL(C_ENR.IND_EXPO_TRANSAC,' '),1)         ||';'||--P3C 31.44
          RPAD(NVL(C_ENR.IND_PRET_SALARIE_COND_REG,' '),1)         ||';'||--P3C 31.45
          RPAD(NVL(C_ENR.IND_IPRE,' '),1)         ||';'||--P3C 21.38
          RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1)         ||';'||--P3C 21.39
          RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1)         ||';'||--P3C 21.40
          RPAD(' ',1)         ||';'||--P3C 21.41
          RPAD(' ',1)         ||';'||--P3C 21.42
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.ETV_RATIO,0))||';'|| -- P3 21.43 -- bale4
          RPAD(NVL(C_ENR.IND_QRRE,' '),1)         ||';'||--P3C 31.46
          RPAD(' ',5)         ||';'||--P3C 21.65
          RPAD(NVL(C_ENR.IND_NON_APPLI_ASYMETRIE_DEV,' '),1)         ||';'||--P3C 31.47
          RPAD(' ',3)         ||';'||--P3C 12.16
          RPAD(' ',1)         ||';'||--P3C 24.8
          RPAD(' ',1)         ||';'||--P3C 3.46
          RPAD(NVL(C_ENR.COMMUNE,' '),40) ||';'||--P3C 21.71
		  RPAD(NVL(C_ENR.NUM_VOIE,' '),40) ||';'||-- P3C 21.72
		  RPAD(NVL(C_ENR.EXTENSION,' '),40) ||';'||-- P3C 21.73
		  RPAD(NVL(C_ENR.TYPE_VOIE,' '),40) ||';'||-- P3C 21.74
		  RPAD(NVL(C_ENR.LIB_VOIE,' '),40) ||';'||-- P3C 21.75
		  RPAD(NVL(C_ENR.LIEU_DIT,' '),40) ||';'||-- P3C 21.76
		  RPAD(NVL(C_ENR.LATITUDE,' '),11) ||';'||-- P3C 21.77
		  RPAD(NVL(C_ENR.LONGITUDE,' '),12) ||';'||-- P3C 21.78
          pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR)||';'||--P3C 21.81 -- GDB
          pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC)||';'||--P3C 21.82 -- GDB
          RPAD(' ',15)         ||';'||--P3C 21.83 -- GDB
          RPAD(' ',15)         ||';'||--P3C 21.84 -- GDB
          RPAD(' ',15)         ||';'||--P3C 21.85
		  RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1) ||';'||-- P3C 21.86
		  RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1) ||';'||-- P3C 21.87
          RPAD(' ',15)         ||';'||--P3C 31.49
		  RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1) ||';'||-- P3C 21.88
          RPAD(' ',19)         ||';'||--P3C 21.91
          RPAD(' ',3)         ||';'||--P3C 21.92
          RPAD(' ',5)         ||';'||--P3C 21.93
          RPAD(' ',20)         ||';'||--P3C 31.51
          RPAD(' ',19)         ||';'||--P3C 31.52
          RPAD(' ',3)         ||';'||--P3C 31.53
          RPAD(' ',4)         ||';'||--0.9 (P3C)
		  RPAD(' ',1132); -- BALE4
      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
      --13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
	  -- v_nb_lignes := C_P3%ROWCOUNT + 2;
	  v_nb_lignes := C_P3%ROWCOUNT;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_UTLF_CREDIT_P3, ID_ENGAGEMENT='||C_ENR.ID_ENGAGEMENT,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
	v_nb_lignes := v_nb_lignes + 2 ;--13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
   v_tail := '99' ||';'|| LPAD(v_nb_lignes,10,'0') ||';'|| RPAD(' ',4486);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);

     DBMS_OUTPUT.PUT_LINE('Nbre P_UTLF_CREDIT_P3 : ' || cd_cpt(CD_CONSO) || ' = ' || v_nb_lignes );

   UTL_FILE.FCLOSE(v_crr_descripteur);
   END;
   v_nb_lignes := 0 ;--13/11/2019 - CDS ATOS (LFD) - Mantis 49880 Correction US 803
   END LOOP;

  DBMS_OUTPUT.PUT_LINE('Fin P_UTLF_CREDIT_P3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur Credit P3',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_UTLF_CREDIT_P3;


-- 18/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
PROCEDURE P_UTLF_SURETE_M3 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
  l_etape    VARCHAR2(30);
  CD_RETOUR  VARCHAR2(30);
  MSG_RETOUR VARCHAR2(250);

  v_crr_descripteur UTL_FILE.FILE_TYPE;
  v_head     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(2000); --  <=== TAILLE DE LA LIGNE.
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;
   type liste_cd_conso is table of varchar2(5); -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
  cd_cpt liste_cd_conso; -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework

  ---------------------
  CURSOR C_M3 (p_cd_conso_cpt CHAR)
  IS
   Select
      M3.ID_ENGAGEMENT
     ,M3.CD_CONSO_CPT
     ,M3.ID_SURETE
     ,M3.TOP_IDTCA_GAR
     ,M3.ID_TIERS_GAR
     ,M3.TOP_IDTCA_DEPO
     ,M3.ID_TIERS_DEPO
     ,M3.SYST_GEST_SOURCE
     ,M3.ID_SURETE_RECUE
     ,M3.REF_IDENT_NATIO_GARANT
     ,M3.IDENT_NATIO_GARANT
     ,M3.REF_IDENT_NATIO_DEPO
     ,M3.IDENT_NATIO_DEPO
     ,M3.DT_DEB_EFFET
     ,M3.DT_FIN_EFFET
     ,M3.CD_NATOP_CPT
     ,M3.CD_TRR
     ,M3.CD_LIEU_DEPOT
     ,M3.CD_NUTS
     ,M3.CD_NATURE_SURETE
     ,M3.MNT_INITIAL
     ,M3.MNT_REVISE
     ,M3.CD_DEVISE
     ,M3.DT_REV_MNT
     ,M3.ELIGIBILITE_SURETE_PERS
     ,M3.CD_RANG_SURETE
     ,M3.CD_PAYS_RECOURS
     ,M3.MNT_HYPOTHEQUE
     ,M3.CD_METHODO_VALORISATION
     ,M3.TOP_COT_BAL_2
     ,M3.CD_INDICE_TITRE
     ,M3.CD_TYPE_TITRE
     ,M3.REF_TITRE
     ,M3.A_EXTRAIRE
      -- 07/02/2019 - CDS ATOS (LFD) - CRRV4.2 --US196
     ,M3.CD_DEV_HYPO
      -- FIN LFD
     ,case
      when nvl(M3.TOP_IDTCA_GAR,'N') = 'N'
      then M3.ID_TIERS_GAR_INITIAL
      else null
       end                     AS idLocalTiersGar
     ,null                     AS idLocalTiersDep
     ,null                     AS CdEntSucc
     ,null                     AS cdSurOri
     ,null                     AS idSurOri
     ,M3.CD_TYPE_PROD_BANCAIRE AS cdTypProd
     ,null                     AS cdInfo2
     ,null                     AS cdInfo3
     ,null                     AS cdInfo4
     ,null                     AS MtIniEuro
     ,null                     AS MtIniNonPrio
     ,null                     AS cdDevSurNonPrio
     ,null                     AS indMobilActif
     ,null                     AS cdUsBien
     ,null                     AS descAdrBien
     ,null                     AS descAdrCompBien
     ,null                     AS descAdrLDBien
     ,null                     AS cdCPBien
     ,null                     AS descComBien
     ,null                     AS descPay
     ,null                     AS cdGPSLat
     ,null                     AS cdGPSLong
     ,null                     AS cdEtatBien
     ,null                     AS cdClassNrjBien
     ,null                     AS cdIndPermisCons
     ,M3.cdDevEntCmpt          AS cdDevEntCmpt
     ,M3.cdPCCOVP1             AS cdPCCOVP1
     ,M3.mtVP1                 AS mtVP1
     ,M3.PERIOD_REVAL_SUR      AS PERIOD_REVAL_SUR   --M3 8.26
     ,M3.METHOD_BALE_GARANT	   AS METHOD_BALE_GARANT --M3 13.13
     ,M3.METHOD_BALE_GARANT_CALC_SIMUL AS METHOD_BALE_GARANT_CALC_SIMUL --M3 13.14
     ,M3.ID_TIERS_GAR_INITIAL          AS ID_TIERS_GAR_INITIAL -- M3 1.18 : afin de gerer les cas des score 7 pour les tiers garants
     From SURETE_M3 M3
    Where M3.cd_conso_cpt = p_cd_conso_cpt
	  AND M3.A_EXTRAIRE   = 'O';

BEGIN
cd_cpt := liste_cd_conso('00399','00936','00357','00472','00370','00372'); -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
	SELECT pack_utilitaire.f_calc_dt_arrete INTO v_dt_arrete from DUAL;

  dbms_output.enable(100000);
  DBMS_OUTPUT.PUT_LINE('Debut P_UTLF_SURETE_M3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

 FOR CD_CONSO in 1 .. cd_cpt.count -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
  LOOP
  BEGIN

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier||cd_cpt(CD_CONSO));

  --ouverture du fichier en mode Append.
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);

  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  --01/02/2019 - CDS ATOS (SQN) - US 683
  --v_head := '00'||';'||'00000474'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';'||RPAD(' ',32)||';'||'M3XX'||';'||'01'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' ;
  --v_head := '00'||';'||'00000474'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';'||RPAD(' ',32)||';'||'M3XX'||';'||'03'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',791); -- BALE4
  v_head := '00'||';'||'00000474'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';'||RPAD(' ',32)||';'||'M3XX'||';'||'04'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',1886); -- BALE4
  --Fin SQN
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);
  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_M3(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
		  '01'                                                               ||';'|| --M3 0.0
		  RPAD(nvl(C_ENR.ID_SURETE,' '),40)                                  ||';'|| --M3 1.17
		  RPAD(nvl(C_ENR.TOP_IDTCA_GAR,' '),1)                               ||';'|| --M3 1.92
          RPAD(nvl(C_ENR.ID_TIERS_GAR,' '),20)                               ||';'|| --M3 1.18 :: RG via la table
		  RPAD(nvl(C_ENR.TOP_IDTCA_DEPO,' '),1)                              ||';'|| --M3 1.93
		  RPAD(nvl(C_ENR.ID_TIERS_DEPO,' '),20)	                             ||';'|| --M3 1.19
		  RPAD(nvl(C_ENR.SYST_GEST_SOURCE,' '),20)	                         ||';'|| --M3 1.40
		  RPAD(nvl(C_ENR.ID_SURETE_RECUE,' '),40)	                         ||';'|| --M3 1.41
		  RPAD(nvl(C_ENR.REF_IDENT_NATIO_GARANT,' '),2)	                     ||';'|| --M3 12.3
		  RPAD(nvl(C_ENR.IDENT_NATIO_GARANT,' '),20)	                     ||';'|| --M3 12.4 :: RG via la table
		  RPAD(nvl(C_ENR.REF_IDENT_NATIO_DEPO,' '),2)	                     ||';'|| --M3 12.5
		  RPAD(nvl(C_ENR.IDENT_NATIO_DEPO,' '),20)	                         ||';'|| --M3 12.6
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEB_EFFET,'YYYYMMDD'), ' '), 8)          ||';'|| --M3 7.1
		  -- 21/10/21 - M3 7.2 - M11734 - coherence des dates
		  CASE
		  WHEN C_ENR.DT_FIN_EFFET < v_dt_arrete
		    or C_ENR.DT_FIN_EFFET <= C_ENR.DT_DEB_EFFET
		  THEN RPAD(NVL(TO_CHAR(v_dt_arrete,'YYYYMMDD'),' '),8)
		  ELSE RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_EFFET,'YYYYMMDD'),' '),8)
		   END	                                                             ||';'|| --M3 7.1
		  -- FIN 11734
		  RPAD(nvl(C_ENR.CD_NATOP_CPT,' '),12)	                             ||';'|| --M3 2.3
		  RPAD(nvl(C_ENR.CD_TRR,' '),1)	                                     ||';'|| --M3 2.4
		  RPAD(nvl(C_ENR.CD_LIEU_DEPOT,' '),1)	                             ||';'|| --M3 3.5
		  RPAD(nvl(C_ENR.CD_NUTS,' '),5)	                                 ||';'|| --M3 7.18
		  RPAD(nvl(C_ENR.CD_NATURE_SURETE,' '),7)                            ||';'|| --M3 4.1
		  RPAD(' ',2)	                                                     ||';'|| --M3 4.2
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_INITIAL,0))    ||';'|| --M3 5.1
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_REVISE,0))     ||';'|| --M3 5.3
		  RPAD(nvl(C_ENR.CD_DEVISE,' '),3)			                         ||';'|| --M3 5.5
		  RPAD(NVL(TO_CHAR(C_ENR.DT_REV_MNT, 'YYYYMMDD'), ' '), 8)	         ||';'|| --M3 6.6
		  RPAD(nvl(C_ENR.ELIGIBILITE_SURETE_PERS,' '),1)	                 ||';'|| --M3 6.5
		  RPAD(nvl(C_ENR.CD_RANG_SURETE,' '),1)	                             ||';'|| --M3 7.7
		  RPAD(nvl(C_ENR.CD_PAYS_RECOURS,' '),2)	                         ||';'|| --M3 7.6
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_HYPOTHEQUE,0)) ||';'|| --M3 5.6
		  -- 12/02/2019 - CDS AtoS FAD - CRRV4.2 - devise a¿EUR par defaut
		  RPAD(nvl(C_ENR.CD_DEV_HYPO,'EUR'),3)                               ||';'|| --M3 6.7
		  -- FIN LFD
		  RPAD(nvl(C_ENR.CD_METHODO_VALORISATION,' '),1)                     ||';'|| --M3 8.27
		  RPAD(nvl(C_ENR.TOP_COT_BAL_2,' '),1)                               ||';'|| --M3 8.32
		  RPAD(nvl(C_ENR.CD_INDICE_TITRE,' '),2)                             ||';'|| --M3 8.1
		  RPAD(nvl(C_ENR.CD_TYPE_TITRE,' '),1)                               ||';'|| --M3 13.1
		  RPAD(nvl(C_ENR.REF_TITRE,' '),12)                                  ||';'|| --M3 8.2
		  RPAD(NVL(C_ENR.idLocalTiersGar                 ,' '), 20)          ||';'|| --M3 1.1 :: RG via le curseur
		  RPAD(NVL(C_ENR.idLocalTiersDep                 ,' '), 20)          ||';'|| --M3 1.2
		  RPAD(NVL(C_ENR.CdEntSucc                       ,' '),  5)          ||';'|| --M3 12.1
		  RPAD(NVL(C_ENR.cdSurOri                        ,' '), 40)          ||';'|| --M3 7.23
		  RPAD(NVL(C_ENR.idSurOri                        ,' '), 40)          ||';'|| --M3 7.25
		  RPAD(NVL(C_ENR.cdTypProd                       ,' '),  6)          ||';'|| --M3 2.7
		  RPAD(NVL(C_ENR.cdInfo2                         ,' '),  2)          ||';'|| --M3 4.3
		  RPAD(NVL(C_ENR.cdInfo3                         ,' '),  2)          ||';'|| --M3 4.4
		  RPAD(NVL(C_ENR.cdInfo4                         ,' '),  2)          ||';'|| --M3 4.5
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtIniEuro    ,0))  ||';'|| --M3 6.8
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MtIniNonPrio ,0))  ||';'|| --M3 6.9
		  RPAD(NVL(C_ENR.cdDevSurNonPrio                 ,'EUR'),  3)        ||';'|| --M3 6.10 :: 21/10/21 - M11733 - EUR si null
		  RPAD(NVL(C_ENR.indMobilActif                   ,' '),  1)          ||';'|| --M3 7.20
		  RPAD(NVL(C_ENR.cdUsBien                        ,' '),  1)          ||';'|| --M3 8.42
		  RPAD(NVL(C_ENR.descAdrBien                     ,' '), 40)          ||';'|| --M3 8.53
		  RPAD(NVL(C_ENR.descAdrCompBien                 ,' '), 40)          ||';'|| --M3 8.54
		  RPAD(NVL(C_ENR.descAdrLDBien                   ,' '), 40)          ||';'|| --M3 8.55
		  RPAD(NVL(C_ENR.cdCPBien                        ,' '), 15)          ||';'|| --M3 8.56
		  RPAD(NVL(C_ENR.descComBien                     ,' '), 40)          ||';'|| --M3 8.57
		  RPAD(NVL(C_ENR.descPay                         ,' '),  2)          ||';'|| --M3 8.58
		  RPAD(NVL(C_ENR.cdGPSLat                        ,' '), 11)          ||';'|| --M3 8.59
		  RPAD(NVL(C_ENR.cdGPSLong                       ,' '), 12)          ||';'|| --M3 8.60
		  RPAD(NVL(C_ENR.cdEtatBien                      ,' '),  1)          ||';'|| --M3 8.49
		  RPAD(NVL(C_ENR.cdClassNrjBien                  ,' '),  1)          ||';'|| --M3 8.50
		  RPAD(NVL(C_ENR.cdIndPermisCons                 ,' '),  1)          ||';'|| --M3 8.51
		  RPAD(NVL(C_ENR.cdDevEntCmpt                    ,' '),  3)          ||';'|| --M3 50.1
		  RPAD(NVL(C_ENR.cdPCCOVP1                       ,' '), 12)          ||';'|| --M3 50.2
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.mtVP1 ,0))         ||';'|| --M3 50.3
		  RPAD(nvl(C_ENR.ID_TIERS_GAR_INITIAL,' '),20)                       ||';'|| --1.1 (M3) :: RG via le curseur > identifiant technique echange du tiers garant
		  RPAD(' ',19)                                                       ||';'|| --M3 8.35
		  RPAD(' ',3)                                                        ||';'|| --M3 8.36
		  RPAD(' ',19)                                                       ||';'|| --M3 8.40
		  RPAD(' ',3)                                                        ||';'|| --M3 8.41
		  RPAD(' ',1)                                                        ||';'|| --M3 8.37
		  RPAD(' ',1)                                                        ||';'|| --M3 8.38
		  RPAD(' ',1)                                                        ||';'|| --M3 8.61
		  RPAD(NVL(C_ENR.PERIOD_REVAL_SUR ,' '),  5)                         ||';'|| --M3 8.26
		  RPAD(' ',2)                                                        ||';'|| --M3 8.31
		  RPAD(' ',1)                                                        ||';'|| --M3 8.3
		  RPAD(' ',8)                                                        ||';'|| --M3 8.5
		  RPAD(' ',1)                                                        ||';'|| --M3 101
		  RPAD(' ',20)                                                       ||';'|| --M3 101.1
		  RPAD(' ',2)                                                        ||';'|| --M3 101.2
		  RPAD(' ',20)                                                       ||';'|| --M3 101.3
		  RPAD(' ',20)                                                       ||';'|| --M3 101.5
		  RPAD(' ',1)                                                        ||';'|| --M3 13.11
		  RPAD(NVL(C_ENR.METHOD_BALE_GARANT ,' '),  7)                       ||';'|| --M3 13.13
		  RPAD(NVL(C_ENR.METHOD_BALE_GARANT_CALC_SIMUL ,' '),  7)            ||';'|| --M3 13.14
		  RPAD(' ',40)                                                       ||';'|| --M3 21.73
		  RPAD(' ',40)                                                       ||';'|| --M3 21.75
		  -- US196
		  RPAD(' ',934) --BALE4
		  ;

      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
      v_nb_lignes := C_M3%ROWCOUNT ;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_UTLF_SURETE_M3, ID_ENGAGEMENT='||C_ENR.ID_ENGAGEMENT,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
    v_nb_lignes := v_nb_lignes + 2 ;
   v_tail := '99' ||';'|| LPAD(v_nb_lignes,10,'0') || ';'||RPAD(' ',1986);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);

     DBMS_OUTPUT.PUT_LINE('Nbre P_UTLF_SURETE_M3 : ' || cd_cpt(CD_CONSO) || ' = ' || v_nb_lignes );
   UTL_FILE.FCLOSE(v_crr_descripteur);
   END;
   v_nb_lignes := 0;
   END LOOP;

  DBMS_OUTPUT.PUT_LINE('Fin P_UTLF_SURETE_M3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur SURETE M3',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_UTLF_SURETE_M3;
-- FIN LFD


-- 19/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
PROCEDURE P_UTLF_LIENS_M3P3 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
  l_etape    VARCHAR2(30);
  CD_RETOUR  VARCHAR2(30);
  MSG_RETOUR VARCHAR2(250);

  v_crr_descripteur UTL_FILE.FILE_TYPE;
  v_head     VARCHAR2(135); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(135); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(135); --  <=== TAILLE DE LA LIGNE.
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;
  type liste_cd_conso is table of varchar2(5); -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
  cd_cpt liste_cd_conso; -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework




  ---------------------
  CURSOR C_M3P3 (p_cd_conso_cpt CHAR)
  IS
   Select
		  M3P3.ID_ENGAGEMENT,
		  M3P3.CD_CONSO_CPT,
		  M3P3.ID_SURETE,
		  M3P3.A_EXTRAIRE
	From  LIENS_M3P3 M3P3
  Where M3P3.cd_conso_cpt=p_cd_conso_cpt AND M3P3.A_EXTRAIRE='O'
  ;

BEGIN
cd_cpt := liste_cd_conso('00399','00936','00357','00472','00370','00372'); -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
	SELECT pack_utilitaire.f_calc_dt_arrete INTO v_dt_arrete from DUAL;

  dbms_output.enable(100000);
  DBMS_OUTPUT.PUT_LINE('Debut P_UTLF_LIENS_M3P3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

 FOR CD_CONSO in 1 .. cd_cpt.count -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
  LOOP
  BEGIN

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier||cd_cpt(CD_CONSO));

  --ouverture du fichier en mode Append.
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);

  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  v_head :=  '00'||';'||'00000478'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';'||RPAD(' ',32)||';'||'M3P3'||';'||'01'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||RPAD(' ',5)||';';
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);
  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_M3P3(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
		'01'||';'||
		  RPAD(nvl(C_ENR.ID_SURETE,' '),40)	||';'||
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)	||';'||
		  RPAD(' ',50)
		  ;

      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
      v_nb_lignes := C_M3P3%ROWCOUNT ;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_UTLF_LIENS_M3P3, ID_ENGAGEMENT='||C_ENR.ID_ENGAGEMENT,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
    v_nb_lignes := v_nb_lignes + 2 ;
   v_tail := '99' ||';'||LPAD(v_nb_lignes,10,'0')|| ';';
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);

     DBMS_OUTPUT.PUT_LINE('Nbre P_UTLF_LIENS_M3P3 : ' || cd_cpt(CD_CONSO) || ' = ' || v_nb_lignes );
   UTL_FILE.FCLOSE(v_crr_descripteur);
   END;
   v_nb_lignes := 0;
   END LOOP;

  DBMS_OUTPUT.PUT_LINE('Fin P_UTLF_LIENS_M3P3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur LIENS M3P3',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_UTLF_LIENS_M3P3;
-- FIN LFD

-- 02/03/2020 - CDS ATOS (LFD) - US 344 FINREP
PROCEDURE P_EXTRACT_FINANCE_SURETE_M3 (   p_chemin                IN VARCHAR2,    p_nom_fichier           IN VARCHAR2)
IS
  l_etape    VARCHAR2(30);
  CD_RETOUR  VARCHAR2(30);
  MSG_RETOUR VARCHAR2(250);

  v_crr_descripteur UTL_FILE.FILE_TYPE;
  v_ligne     VARCHAR2(326); --  <=== TAILLE DE LA LIGNE.
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;

  ---------------------
  CURSOR C_S3
  IS
   Select
		DT_ARRETE
		,CD_CONSO_CPT
		,ID_ENGAGEMENT
		,TYPE_ENREGISTREMENT
		,ID_SURETE
		,TOP_IDTCA_GAR
		,ID_TIERS_GAR -- M_72558 :: impacte par la RG
		,TOP_IDTCA_DEPO
		,ID_TIERS_DEPO
		,SYST_GEST_SOURCE
		,ID_SURETE_RECUE
		,REF_IDENT_NATIO_GARANT
		,IDENT_NATIO_GARANT -- M_72558 :: impacte par la RG
		,REF_IDENT_NATIO_DEPO
		,IDENT_NATIO_DEPO
		,DT_DEB_EFFET
		,DT_FIN_EFFET
		,CD_NATOP_CPT
		,CD_TRR
		,CD_LIEU_DEPOT
		,CD_NUTS
		,CD_NATURE_SURETE
		,MNT_INITIAL
		,MNT_REVISE
		,CD_DEVISE
		,DT_REV_MNT
		,ELIGIBILITE_SURETE_PERS
		,CD_RANG_SURETE
		,CD_PAYS_RECOURS
		,MNT_HYPOTHEQUE
		,CD_METHODO_VALORISATION
		,TOP_COT_BAL_2
		,CD_INDICE_TITRE
		,CD_TYPE_TITRE
		,REF_TITRE
		,A_EXTRAIRE
		,CD_DEV_HYPO
	From  SURETE_M3
 -- Where A_EXTRAIRE='O' -- 15/04/2020 - CDS ATOS (LFD) - US344 FINREP RW EXTRACTION DE TOUTES LES LIGNES
  ;

BEGIN

  dbms_output.enable(100000);
  DBMS_OUTPUT.PUT_LINE('Debut P_EXTRACT_FINANCE_SURETE_M3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

  P_UTLF_REMOVE_FILE(p_chemin, p_nom_fichier);

  --ouverture du fichier en mode Append.
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier, 'A',32767);

  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;


  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_S3
  LOOP
    BEGIN
    	v_ligne :=
		RPAD(NVL(TO_CHAR(C_ENR.DT_ARRETE, 'YYYYMMDD'), ' '), 8)	|| -- position 1
		RPAD(nvl(C_ENR.CD_CONSO_CPT,' '),5)	|| -- 9
		RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),15)	|| -- 14
		RPAD(nvl(C_ENR.TYPE_ENREGISTREMENT,' '),2)	|| -- 29
		RPAD(nvl(C_ENR.ID_SURETE,' '),40)	|| -- 31
		RPAD(nvl(C_ENR.TOP_IDTCA_GAR,' '),1)	|| -- 71
		RPAD(nvl(C_ENR.ID_TIERS_GAR,' '),20)	|| -- 72
		RPAD(nvl(C_ENR.TOP_IDTCA_DEPO,' '),1)	|| -- 92
		RPAD(nvl(C_ENR.ID_TIERS_DEPO,' '),20)	|| -- 93
		RPAD(nvl(C_ENR.SYST_GEST_SOURCE,' '),20)	|| -- 113
		RPAD(nvl(C_ENR.ID_SURETE_RECUE,' '),40)	|| --133
		RPAD(nvl(C_ENR.REF_IDENT_NATIO_GARANT,' '),2)	|| -- 173
		RPAD(nvl(C_ENR.IDENT_NATIO_GARANT,' '),9)	|| -- 175
		RPAD(nvl(C_ENR.REF_IDENT_NATIO_DEPO,' '),2)	|| -- 184
		RPAD(nvl(C_ENR.IDENT_NATIO_DEPO,' '),9)	|| -- 186
		RPAD(NVL(TO_CHAR(C_ENR.DT_DEB_EFFET, 'YYYYMMDD'), ' '), 8)	|| -- 195
		RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_EFFET, 'YYYYMMDD'), ' '), 8)	|| -- 203
		RPAD(nvl(C_ENR.CD_NATOP_CPT,' '),8)	|| -- 211
		RPAD(nvl(C_ENR.CD_TRR,' '),1)	|| -- 219
		RPAD(nvl(C_ENR.CD_LIEU_DEPOT,' '),1)	|| -- 220
		RPAD(nvl(C_ENR.CD_NUTS,' '),5)	|| -- 221
		RPAD(nvl(C_ENR.CD_NATURE_SURETE,' '),7)	|| --226
		pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_INITIAL,0))|| -- 233
		pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_REVISE,0))|| -- 252
		RPAD(nvl(C_ENR.CD_DEVISE,' '),3)			|| -- 271
		RPAD(NVL(TO_CHAR(C_ENR.DT_REV_MNT, 'YYYYMMDD'), ' '), 8)	|| -- 274
		RPAD(nvl(C_ENR.ELIGIBILITE_SURETE_PERS,' '),1)	|| -- 282
		RPAD(nvl(C_ENR.CD_RANG_SURETE,' '),1)	|| -- 283
		RPAD(nvl(C_ENR.CD_PAYS_RECOURS,' '),2)	|| -- 284
		pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_HYPOTHEQUE,0))|| -- 286
		RPAD(nvl(C_ENR.CD_METHODO_VALORISATION,' '),1)	|| -- 305
		RPAD(nvl(C_ENR.TOP_COT_BAL_2,' '),1)	|| -- 306
		RPAD(nvl(C_ENR.CD_INDICE_TITRE,' '),2)	|| -- 307
		RPAD(nvl(C_ENR.CD_TYPE_TITRE,' '),1)	|| -- 309
		RPAD(nvl(C_ENR.REF_TITRE,' '),12)	|| -- 310
		RPAD(nvl(C_ENR.A_EXTRAIRE,' '),1)	|| -- 322
		RPAD(nvl(C_ENR.CD_DEV_HYPO,' '),3)	 -- 323
		  ;

      UTL_FILE.PUT_LINE(v_crr_descripteur, v_ligne);
      v_nb_lignes := C_S3%ROWCOUNT ;

    EXCEPTION
    WHEN OTHERS THEN
      pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Pb P_EXTRACT_FINANCE_SURETE_M3, ID_ENGAGEMENT='||C_ENR.ID_ENGAGEMENT,50059);
      UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
    END;
  END LOOP;
     DBMS_OUTPUT.PUT_LINE('Nbre P_EXTRACT_FINANCE_SURETE_M3 : '  || v_nb_lignes );

   UTL_FILE.FCLOSE(v_crr_descripteur);
   v_nb_lignes := 0;

  DBMS_OUTPUT.PUT_LINE('Fin P_EXTRACT_FINANCE_SURETE_M3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur EXTRACT SURETE M3',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_EXTRACT_FINANCE_SURETE_M3;
-- FIN LFD


END PACK_UTL_FILE_ENVOI_C3RD2 ;
/
