create or replace PACKAGE PACK_UTL_FILE_ENVOI_C3RD
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

END PACK_UTL_FILE_ENVOI_C3RD ;
/

create or replace PACKAGE BODY PACK_UTL_FILE_ENVOI_C3RD
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
  v_head     VARCHAR2(245); --  <=== TAILLE DE LA LIGNE.
  --v_ligne     VARCHAR2(245); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(243); -- 11/02/2019 - CRRV4.2 - correctif
  v_tail     VARCHAR2(245); --  <=== TAILLE DE LA LIGNE.
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
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;


  --01/02/2019 - CDS ATOS (SQN) - US 683
  --  v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             '||';'||'P7XX'||';'||'01'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',129);
  --v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             '||';'||'P7XX'||';'||'02'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',129);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
    v_head := '00'||';'||'00000475'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';BTR                             '||';'||'P7XX'||';'||'02'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' || RPAD(' ',129);
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
		  RPAD(' ', 48) -- 11/02/2019 - CRRV4.2 - correctif
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
   v_tail := '99' ||';'|| LPAD(v_nb_lignes,10,'0') || ';'||RPAD(' ',229);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);


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

  v_head     VARCHAR2(642); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(642); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(642); --  <=== TAILLE DE LA LIGNE.

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
	From  TIE_TIERS_C2 where cd_conso_cpt=p_cd_conso_cpt
	--18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, ajout de la condition A_EXTRAIRE = 'O'
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
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  --01/02/2019 - CDS ATOS (SQN) - US 683
  --v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;C2XX;01;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',508);
  --v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;C2XX;02;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',508);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
  v_head := '00;00000469;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'||  cd_cpt(CD_CONSO) ||';BTR                             ;C2XX;02;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',508);
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
		  '01'||';'||
		--18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, Modifier l'alimentation du segment C2 dans le fichier
		----- 27/11/2018 - CDS ATOS (LFD) - ANACREDIT US 593
		-- CASE WHEN C_CPT.CD_CONSO_CPT = '00357' THEN RPAD(nvl(to_char(C_ENR.ID_TIERS_CALC),' '),20) ELSE RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)	END				||';'||
		-- CASE WHEN C_CPT.CD_CONSO_CPT = '00357' THEN RPAD(nvl(to_char(C_ENR.ID_TIERS_CALC),' '),20) ELSE RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)	END						||';'||
		-----FIN LFD*/
		RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||';'||
		RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||';'||
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
		   RPAD(nvl(C_ENR.ETAT_PROC_JUD,' '),1)	||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PROC_JUD, 'YYYYMMDD'), ' '), 8)	||';'||
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
		  RPAD(' ',33) -- 11/02/2019 - CRRV4.2 - correctif
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
   v_tail := '99' || ';'||LPAD(v_nb_lignes,10,'0') || ';'||RPAD(' ',608);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);


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
  v_head     VARCHAR2(232); --  <=== TAILLE DE LA LIGNE.
  v_ligne    VARCHAR2(232); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(232); --  <=== TAILLE DE LA LIGNE.
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
  v_head := '00;00000470;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| cd_cpt(CD_CONSO) ||';BTR                             ;C3XX;02;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',116);
  -- FIN LFD
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);

  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_C3(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
		'01'||';'||
		-- 18/08/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, Modifier l'alimentation du segment C3 dans le fichier
		--  RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)				||';'||
		--  RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)					||';'||
		  RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||';'||
		  RPAD(NVL(C_ENR.ID_TIERS_CALC, ' '), 20)||';'||
		-- Fin - CDS AtoS FAD - ANACREDIT US600
  		  RPAD(NVL(TO_CHAR(C_ENR.DT_NAISSANCE, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(nvl(C_ENR.REF_EXT_GRPE_CALF,' '),20)			||';'||
		  RPAD(nvl(C_ENR.CD_PAYS_RESIDENCE,' '),2)			||';'||
		  RPAD(nvl(C_ENR.CD_POSTAL,' '),15)					||';'||
		  RPAD(nvl(C_ENR.CD_CATEG_CONTREPARTIE,' '),5)		||';'||
		  RPAD(nvl(C_ENR.CD_PORTEFEUILLE_BAL_TIERS,' '),3)	||';'||
		  RPAD(nvl(C_ENR.CD_SECTEUR_ACTIVITE,' '),6)		||';'||
		  RPAD(' ',2)									||';'||
		  RPAD(' ',15)									||';'||
		  RPAD(' ',1)									||';'||
		  RPAD(nvl(C_ENR.NOTE_CALC_FINALE,' '),2)			||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_REVISION_NOTE, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_ENTREE_DEFAUT, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(C_ENR.CD_METHODO_NOTE,'999'),3)					||';'||
		  -- 07/06/2018 CDS Atos (JMP) ANACREDIT Sprint 12 US380
		  -- Activation de l'Ã©criture
		  RPAD(NVL(C_ENR.CD_MOTIF_NOTE,' '),3)					||';'||
          --        RPAD(' ',3)                                                                   ||';'||
		  -- Fin 07/06/2018 CDS Atos (JMP) ANACREDIT Sprint 12 US380
		  RPAD(NVL(C_ENR.CD_SEGMENT_NOTE,' '),2)					||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.PD,0))		||';'||
		  --11/01/2019 CDS Atos (SQN) US 630
		  'C'||';'||
		  --Fin SQN
		  --RPAD(' ',50)
		  RPAD(' ',48) -- 11/02/2019 - CRRV4.2 - correctif
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
   v_tail := '99'||';'||LPAD(v_nb_lignes,10,'0')||';'|| RPAD(' ',216);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);


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
  v_head     VARCHAR2(1918); -- 11/02/2019 - CRRV4.2 - correctif
  --v_ligne     VARCHAR2(1809); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(1918); -- 11/02/2019 - CRRV4.2 - correctif
  --v_tail     VARCHAR2(1809); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(1918);-- 11/02/2019 - CRRV4.2 - correctif
  --31/01/2019 - CDS ATOS (GBD) - US 671 fin


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
--11/04/2019 - CDS AtoS FAD - MCO Leasing M47350 - US778
				, DT_FIN_PAL
--11/04/2019 - CDS AtoS FAD - MCO Leasing M47350 - US778
		FROM CREDIT_P3 where cd_conso_cpt=p_cd_conso_cpt;

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
  --le fichier rÃ¿Â¿Â½sultat est supprimÃ¿Â¿Â½ avant l'appel de ces procÃ¿Â¿Â½dures.
  v_crr_descripteur := UTL_FILE.FOPEN (p_chemin, p_nom_fichier||cd_cpt(CD_CONSO), 'A',32767);


  IF UTL_FILE.IS_OPEN (v_crr_descripteur) != TRUE THEN
    pack_utilitaire.DB_TRAITE_ERREUR('O','Probleme a l''ouverture du fichier '||p_nom_fichier,50055);
  END IF;

  --01/02/2019 - CDS ATOS (SQN) - US 683
  --v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;P3CX;01;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1554);
  --v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| C_CPT.CD_CONSO_CPT ||';BTR                             ;P3CX;03;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1554);
  --Fin SQN
  -- 22/07/2019 - CDS ATOS (LFD) - ANACREDIT US 803
    v_head := '00;00000471;001;' || to_char(g_dt_traitement,'YYYYMMDD') || 'T' || to_char(g_dt_traitement,'HHMISS') || ';00357;'|| cd_cpt(CD_CONSO) ||';BTR                             ;P3CX;03;00001;M;'||to_char(v_dt_arrete,'YYYYMMDD')||';00001;     ;' || RPAD(' ',1554);
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
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'||
		-- 18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, modifier l'alimentation du segment P3 dans le fichier
		  ---- 05/11/2018 - CDS ATOS (LFD) - ANACREDIT US 593
		  --CASE WHEN C_CPT.CD_CONSO_CPT = '00357' THEN RPAD(nvl(to_char(C_ENR.ID_TIERS_CALC),' '),20) ELSE RPAD(nvl(to_char(C_ENR.ID_TIERS),' '),20)	END		||';'||
		  ----FIN LFD
		  RPAD(nvl(to_char(C_ENR.ID_TIERS_CALC),' '),20) ||';'||
		-- 18/12/2018 - CDS AtoS FAD - ANACREDIT US600 : Mise Ã¿ jour de lâ¿¿utlfile, modifier l'alimentation du segment P3 dans le fichier
		  RPAD(nvl(C_ENR.CD_SYS_INT,' '),20)				||';'||
		  RPAD(' ',7)										||';'||
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'||
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'||
		  RPAD(' ',5)										||';'||
		  RPAD(nvl(C_ENR.ID_ENGAGEMENT,' '),40)				||';'||
		  RPAD('R_BTR',12)										||';'||
		  RPAD(nvl(C_ENR.ID_AGREGAT,' '),30)				||';'||
		  RPAD(nvl(C_ENR.ID_AGREGAT,' '),100)				||';'||
		  RPAD(nvl(C_ENR.CD_METHODO_BALE2,' '),7)			||';'||
		  RPAD(nvl(C_ENR.ELIGIBILITE_OMP,' '),1)			||';'||
		  RPAD(nvl(C_ENR.CD_NATURE_OPE,' '),12)				||';'||
		  RPAD(nvl(C_ENR.CD_NATURE_PNU,' '),12)				||';'||
		  RPAD(nvl(C_ENR.CD_CLASS_CPT_LOC,' '),3)			||';'||
		  RPAD(nvl(C_ENR.CD_CLASS_CPT_REF,' '),3)			||';'||
		  RPAD(nvl(C_ENR.CD_CLASS_CPT_IFR,' '),3)			||';'||
		  RPAD(nvl(C_ENR.CD_TYPE_RISQUE,' '),6)				||';'||
		  RPAD(' ',6)										||';'||
		  RPAD(nvl(C_ENR.CD_PTF_BOOKING,' '),1)				||';'||
		  RPAD(nvl(C_ENR.CD_PORTEFEUILLE_BALE2,' '),3)		||';'||
		  RPAD(nvl(C_ENR.CD_LIGNE_METIER,' '),5)			||';'||
		  RPAD(nvl(C_ENR.CD_CIRCUIT_DISTRIB,' '),2)			||';'||
		  RPAD(nvl(C_ENR.BUCKET_IFRS9,' '),2)				||';'||--31/01/2019 - CDS ATOS (GBD) - US 671  P3 22.72
		  RPAD(nvl(C_ENR.IND_POCI,' '),1)					||';'||
		  RPAD(nvl(C_ENR.CD_OBJET_FIN,' '),2)				||';'||
		  RPAD(' ',2)										||';'||
		  RPAD(' ',1)										||';'||
		  RPAD(' ',1)										||';'||
		  RPAD(nvl(C_ENR.CD_USAGE_BIEN_IMM,' '),1)			||';'||
		  RPAD(' ',15)										||';'||
		  RPAD(' ',15)										||';'||
		  RPAD(' ',15)										||';'||
		  RPAD(' ',15)										||';'||
		  RPAD(' ',15)										||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TIE_ORIGINE,0))||';'||
		  --19/04/18 CDS Atos (EMM) US 279 inhibition du code du C3RD 1.1 pour revenir au C3RD initial
		  RPAD(nvl(C_ENR.CD_CONF_AUTOR,' '),1)					||';'||  -- CDS ATOS (JMP) ANACREDIT US45 (P3 2.11) --31/01/2019 - CDS ATOS (GBD) - US 671 P3 2.11
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DISPO_FONDS, 'YYYYMMDD'), ' '), 8)||';'|| -- 31/01/2019 - CDS ATOS (GBD) - US 671   P3 4.47
		  RPAD(NVL(TO_CHAR(C_ENR.DT_SIGNATURE, 'YYYYMMDD'), ' '), 8)||';'|| -- CDS ATOS (JMP) ANACREDIT US45 (P3 22.67) --31/01/2019 - CDS ATOS (GBD) - US 671 P3 22.67
		  --Fin EMM
   		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG, 'YYYYMMDD'), ' '), 8)||';'||
   		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG_REN, 'YYYYMMDD'), ' '), 8)||';'||
   		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG_BIL, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG_BIL, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_DEB_FD, 'YYYYMMDD'), ' '), 8)||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_PREM_DEB_FD,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEV_PREM_DEB_FD,'EUR'),3)       ||';'||   -- P3 22.33 devise 1er deblocage fond    -- 18/02/2019 - CDS ATOS (GBD) - US731
		  RPAD('ECH',3)||';'||   -- P3 22.56 Indicateur produit Ã©chÃ©ancÃ©
		  RPAD(nvl(C_ENR.IND_ECH,' '),1)					||';'||
		  RPAD(nvl(C_ENR.IND_PAL,' '),1)					||';'||
		  RPAD(nvl(C_ENR.CD_TYPE_TAUX,' '),1)				||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TIE_ORIGINE,0))||';'||
		  RPAD(nvl(C_ENR.CD_TYPE_AMO,' '),1)				||';'||
		  RPAD(nvl(C_ENR.CD_PERIODICITE_K,' '),1)			||';'||
		  RPAD(nvl(C_ENR.CD_PERIODICITE_I,' '),1)			||';'||
		  RPAD(nvl(C_ENR.CD_MODALITE_RBT,' '),1)			||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_ECH, 'YYYYMMDD'), ' '), 8)||';'||		---- 06/12/2017 CDS ATOS (EMM) Sprint 2 US 28
		  RPAD(' ',8)										||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_ENG+1, 'YYYYMMDD'), ' '), 8)||';'||
--11/04/2019 - CDS AtoS FAD - MCO Leasing M47350 - US778
		  --RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_ENG-1, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_PAL, 'YYYYMMDD'), ' '), 8)||';'|| --> E0_22_59_DT_FIN_PAL
--Fin - CDS AtoS FAD - MCO Leasing M47350 - US778
		 RPAD(' ',15)                                                                           ||';'||
		 RPAD(' ',15)                                                                           ||';'||
		  --pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_PLAFOND,0))||';'||
		  --pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_PLANCHER,0))||		';'||
		  RPAD(nvl(C_ENR.CD_PERIODICITE_REV_TX,' '),1)		||';'||
		  LPAD(nvl(C_ENR.CD_PERIODICITE_REV_TX_NB,'1'),3)	||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_CLI_OCTROI,0))||';'||
		  RPAD(nvl(C_ENR.IND_REF_TV,' '),12)				||';'||
		  RPAD(nvl(C_ENR.IND_IDX_PAL,' '),1)				||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_MARGE_ADD,0))||';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.TX_MARGE_MUL,0))||';'||
		  RPAD(nvl(C_ENR.BASE_INT,' '),7)					||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CRD,0))||';'||
		  RPAD(' ',19)||	';'||
		RPAD(' ',3)||	';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_DECOUVERT,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_CRD,' '),3)				||					';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CRD,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_CRD,' '),3)				||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_LOYER,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_LOY,' '),3)				||					';'||
		  pack_utilitaire.f_format_montant_BIS2(0)||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_IRD,' '),3)				||	';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_PNU,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_PNU,' '),3)				||	';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CONTRAT_ORIG,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_ORIG,' '),3)				||	';'||
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
		pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_VAL_MARCHE,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_MARCHE,' '),3)			||			  ';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_HYPOTHEQUE,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_HYPO,' '),3)				||						';'||
		  RPAD(nvl(C_ENR.CD_ACHAT_FIN_LOC,' '),1)			||							';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_VR,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_VR,' '),3)				||				';'||
		  LPAD(nvl(to_char(round(CASE WHEN C_ENR.MATURITE_RES BETWEEN 0 AND 1 THEN 1 ELSE C_ENR.MATURITE_RES END)),'000'),3,'0')				||			';'||
		  pack_utilitaire.f_format_taux_15(nvl(C_ENR.PD_ORIGINE,0))||';'||
		  RPAD(nvl(C_ENR.NOTE_ORIGINE,' '),2)				||				';'||
		  RPAD(nvl(C_ENR.ORGANISME_NOTATION,' '),2)			||					';'||
-- 11/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US418
--		  RPAD(' ',10)										||';'||
--		  RPAD(' ',2)										||';'||
		  RPAD(nvl(C_ENR.NOTE_EXT_CORP_ORI,' '),10) ||';'||
		  RPAD(nvl(C_ENR.NOTE_INT_CORP_ORI,' '),2) ||';'||
-- Fin 11/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US418
		  RPAD(nvl(C_ENR.CD_METHODO_NOTE_ORI,' '),3)		||								';'||
		  RPAD(nvl(C_ENR.CD_GRILLE_NOTE_ORI,' '),23)		||									';'||
		  RPAD(nvl(C_ENR.CD_SEGMENT_NOTE_ORI,' '),2)		||';'||
		  RPAD(' ',15)										||';'||
		  RPAD(' ',2)										||';'||
-- 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
--		  RPAD(' ',1)										||';'||
		  RPAD(nvl(C_ENR.IND_RBT_ANTICIPE,' '),1)			||';'||
-- Finn 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
		  RPAD(nvl(C_ENR.TOP_ENG_DOUTEUX,' '),1)			||';'||
		  RPAD(nvl(C_ENR.CD_IMP_PRUDENT,' '),1)				||';'||
		  RPAD(nvl(C_ENR.CD_NEW_DEFAUT,' '),1)				||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_ENG_DOUTEUX, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_IMP_PRUDENT, 'YYYYMMDD'), ' '), 8)||';'||
-- 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
--		  RPAD(nvl(C_ENR.CD_NEW_DEFAUT,' '),1)				||';'||
		 -- 12/02/2019 - CDS AtoS FAD - CRRV4.2 - Correctif : CD_MOTIF_SCO_LC0267 : complÃ©ter le code Ã¿ gauche Ã¿ 0.
  		  --LPAD(nvl(C_ENR.CD_MOTIF_SCO_LC0267,' '),3,'0')		||';'||   -- 31/01/2019 - CDS ATOS (GBD) - US 671     P3 22.71     cdPasEngDout
		--15/02/19 CDS ATOS (EMM) Correctif 2 score 7
		CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then RPAD(' ', 3)
		ELSE LPAD(C_ENR.CD_MOTIF_SCO_LC0267,3,'0') END ||';'||
		--Fin EMM
		  RPAD(nvl(C_ENR.CD_ARR_PAIMENT,' '),1)				||';'||
-- Fin 06/07/2018 CDS ATOS (JMP) ANACREDIT Sprint 12 US380
		  RPAD(NVL(TO_CHAR(C_ENR.DT_PREM_ARRIERE, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(to_char(C_ENR.NB_JOURS_RETARD), '0'), 5)      ||';'||-- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 22.70 < exemple  ;+123;
		  pack_utilitaire.f_format_montant_BIS2( CASE WHEN nvl(C_ENR.MNT_ENC_ARR_PAIE,0) > 0 THEN nvl(C_ENR.MNT_ENC_ARR_PAIE,0) ELSE 0 END)||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_ARR_PAIE,' '),3)			||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_CAPITAL_ARR,0))||';'|| --31/01/2019 - CDS ATOS (GBD) - US 671     p3 9.31
		  RPAD(nvl(C_ENR.CD_DEV_MNT_CAPITAL_ARR,' '),3)		||';'||                 --31/01/2019 - CDS ATOS (GBD) - US 671     p3 9.41
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_INT_ARR,0))||';'||   --31/01/2019 - CDS ATOS (GBD) - US 671     p3 9.32
		  RPAD(nvl(C_ENR.CD_DEV_MNT_INT_ARR,' '),3)			||';'||                --31/01/2019 - CDS ATOS (GBD) - US 671     p3 9.42
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DTCO, 'YYYYMMDD'), ' '), 8)   ||';'||          -- 18/02/2019 - CDS ATOS (GBD) - US731     P3 22.38
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_DTCO,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE_DTCO,' '),3)				||';'||
		  RPAD(' ',19)										||';'||
		  RPAD(' ',3)										||';'||
		  RPAD(' ',8)										||';'||
		  RPAD(' ',19)||  ';'||
                  RPAD(' ',3)||   ';'||
		  RPAD(nvl(C_ENR.TOP_EVT_CREDIT,' '),1)				||';'||
		  RPAD(nvl(C_ENR.CD_NATURE_EVT,' '),1)				||';'||
		  RPAD(nvl(C_ENR.CD_STATUT_CREDIT,' '),1)				||';'||					--14/04/2018 CDS ATOS (EMM) Sprint 7 US 279 (P3 21.5)
		  --RPAD(' ', 1)	||';'|| -- 08/06/2018 - CDS AtoS (LFD) - V18S27 ItÃ©ration 2 - Inhibition US279
		  RPAD(nvl(C_ENR.CD_TYPE_CREANCE,' '),2)				||';'||
		  RPAD(nvl(C_ENR.CD_TYPE_RESTRUCT,' '),2)				||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_RESTRUCTURATION, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DER_RESTRUCT_COM, 'YYYYMMDD'), ' '), 8)||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DER_RESTRUCT_RISK, 'YYYYMMDD'), ' '), 8)||';'||
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
		  RPAD(nvl(C_ENR.CD_PD_IFRS,' '),12)				||';'||
		  RPAD(nvl(C_ENR.CD_LGD_IFRS,' '),12)				||';'||
		  RPAD(nvl(C_ENR.CD_CCF_IFRS,' '),12)				||';'||
		  RPAD(nvl(C_ENR.CD_TX_REMB_IFRS,' '),12)			||';'||
		  RPAD(' ',2)										||	';'||
		  RPAD(nvl(C_ENR.CD_CREANCE_TITRI,' '),1)			||';'||
		  RPAD(' ',3)										||	';'||
		  RPAD(' ',1)										||	';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_IDEMNITE_RES,0))  ||';'||  --31/01/2019 - CDS ATOS (GBD) - US 671       P3 29.1
		  -- 13/02/2019 - CDS ATOS (SQN) CRRV4.2 - correctif scores 6 : forcer CD_DEV_MNT_INDEMNITE Ã¿ EUR
		  RPAD(nvl(C_ENR.CD_DEV_MNT_INDEMNITE,'EUR'),3)		||';'||		                 --31/01/2019 - CDS ATOS (GBD) - US 671       P3 29.2
		  RPAD(nvl(C_ENR.CLE_COMPTABLE,' '),40)			||';'||
		  RPAD(' ',5)	||';'||
		  RPAD(' ',5)	||';'||
		  RPAD(' ',1)		||';'||
		  RPAD(nvl(C_ENR.IND_REVOLVING,' '),1)				||';'||     -- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 5.6
		  RPAD(nvl(C_ENR.IND_HISTO_IMP,' '),2)				||';'||     -- 31/01/2019 - CDS ATOS (GBD) - US 671  P3 40.11
		  --RPAD(' ',95);	   												-- 31/01/2019 - CDS ATOS (GBD) - US 671  reduit de 100 Ã¿ 95
		  RPAD(' ',204); -- 11/02/2019 - CRRV4.2 - correctif
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
   v_tail := '99' ||';'|| LPAD(v_nb_lignes,10,'0') ||';'|| RPAD(' ',1654);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);


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
  v_head     VARCHAR2(458); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(458); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(458); --  <=== TAILLE DE LA LIGNE.
  v_dt_arrete DATE;
  v_nb_lignes NUMBER := 0;
   type liste_cd_conso is table of varchar2(5); -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework
  cd_cpt liste_cd_conso; -- 13/11/2018 - CDS ATOS (LFD) - ANACREDIT US 528 rework




  ---------------------
  CURSOR C_M3 (p_cd_conso_cpt CHAR)
  IS
   Select
		  M3.ID_ENGAGEMENT,
		  M3.CD_CONSO_CPT,
		  M3.ID_SURETE,
		  M3.TOP_IDTCA_GAR,
		  M3.ID_TIERS_GAR,
		  M3.TOP_IDTCA_DEPO,
		  M3.ID_TIERS_DEPO,
		  M3.SYST_GEST_SOURCE,
		  M3.ID_SURETE_RECUE,
		  M3.REF_IDENT_NATIO_GARANT,
		  M3.IDENT_NATIO_GARANT,
		  M3.REF_IDENT_NATIO_DEPO,
		  M3.IDENT_NATIO_DEPO,
		  M3.DT_DEB_EFFET,
		  M3.DT_FIN_EFFET,
		  M3.CD_NATOP_CPT,
		  M3.CD_TRR,
		  M3.CD_LIEU_DEPOT,
		  M3.CD_NUTS,
		  M3.CD_NATURE_SURETE,
		  M3.MNT_INITIAL,
		  M3.MNT_REVISE,
		  M3.CD_DEVISE,
		  M3.DT_REV_MNT,
		  M3.ELIGIBILITE_SURETE_PERS,
		  M3.CD_RANG_SURETE,
		  M3.CD_PAYS_RECOURS,
		  M3.MNT_HYPOTHEQUE,
		  M3.CD_METHODO_VALORISATION,
		  M3.TOP_COT_BAL_2,
		  M3.CD_INDICE_TITRE,
		  M3.CD_TYPE_TITRE,
		  M3.REF_TITRE,
		  M3.A_EXTRAIRE,
		  -- 07/02/2019 - CDS ATOS (LFD) - CRRV4.2
		  M3.CD_DEV_HYPO
		  -- FIN LFD
	From  SURETE_M3 M3
  Where M3.cd_conso_cpt=p_cd_conso_cpt AND M3.A_EXTRAIRE='O'
  ;

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
  v_head := '00'||';'||'00000474'||';'||'001' ||';'|| to_char(g_dt_traitement,'YYYYMMDD') ||'T' || to_char(g_dt_traitement,'HHMISS') ||';'|| '00357;'|| cd_cpt(CD_CONSO) ||';'||RPAD(' ',32)||';'||'M3XX'||';'||'02'||';'||'00001'||';'||'M'||';'||to_char(v_dt_arrete,'YYYYMMDD')||';'||'00001'||';'||'     ;' ;
  --Fin SQN
  UTL_FILE.PUT_LINE(v_crr_descripteur, v_head);
  ------------------------------------------------
  -- Debut de la boucle sur les enregistrements --
  ------------------------------------------------
  FOR C_ENR IN C_M3(cd_cpt(CD_CONSO))
  LOOP
    BEGIN
    	v_ligne :=
		'01'||';'||
		  RPAD(nvl(C_ENR.ID_SURETE,' '),40)	||';'||
		  RPAD(nvl(C_ENR.TOP_IDTCA_GAR,' '),1)	||';'||
  		  RPAD(nvl(C_ENR.ID_TIERS_GAR,' '),20)		||';'||
		  RPAD(nvl(C_ENR.TOP_IDTCA_DEPO,' '),1)||';'||
		  RPAD(nvl(C_ENR.ID_TIERS_DEPO,' '),20)	||';'||
		  RPAD(nvl(C_ENR.SYST_GEST_SOURCE,' '),20)	||';'||
		  RPAD(nvl(C_ENR.ID_SURETE_RECUE,' '),40)	||';'||
		  RPAD(nvl(C_ENR.REF_IDENT_NATIO_GARANT,' '),2)	||';'||
		  RPAD(nvl(C_ENR.IDENT_NATIO_GARANT,' '),20)	||';'||
		  RPAD(nvl(C_ENR.REF_IDENT_NATIO_DEPO,' '),2)	||';'||
		  RPAD(nvl(C_ENR.IDENT_NATIO_DEPO,' '),20)	||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_DEB_EFFET, 'YYYYMMDD'), ' '), 8)	||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_FIN_EFFET, 'YYYYMMDD'), ' '), 8)	||';'||
		  RPAD(nvl(C_ENR.CD_NATOP_CPT,' '),12)	||';'||
		  RPAD(nvl(C_ENR.CD_TRR,' '),1)	||';'||
		  RPAD(nvl(C_ENR.CD_LIEU_DEPOT,' '),1)	||';'||
		  RPAD(nvl(C_ENR.CD_NUTS,' '),5)	||';'||
		  RPAD(nvl(C_ENR.CD_NATURE_SURETE,' '),7)	||';'||
		  RPAD(' ',2)	||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_INITIAL,0))||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_REVISE,0))||';'||
		  RPAD(nvl(C_ENR.CD_DEVISE,' '),3)			||';'||
		  RPAD(NVL(TO_CHAR(C_ENR.DT_REV_MNT, 'YYYYMMDD'), ' '), 8)	||';'||
		  RPAD(nvl(C_ENR.ELIGIBILITE_SURETE_PERS,' '),1)	||';'||
		  RPAD(nvl(C_ENR.CD_RANG_SURETE,' '),1)	||';'||
		  RPAD(nvl(C_ENR.CD_PAYS_RECOURS,' '),2)	||';'||
		  pack_utilitaire.f_format_montant_BIS2(nvl(C_ENR.MNT_HYPOTHEQUE,0))||';'||
		  -- 07/02/2019 - CDS ATOS (LFD) - CRRV4.2
		  RPAD(nvl(C_ENR.CD_DEV_HYPO,'EUR'),3)	||';'|| -- 12/02/2019 - CDS AtoS FAD - CRRV4.2 - Correctif : devise Ã¿ EUR par dÃ©faut.
		  -- FIN LFD
		  RPAD(nvl(C_ENR.CD_METHODO_VALORISATION,' '),1)	||';'||
		  RPAD(nvl(C_ENR.TOP_COT_BAL_2,' '),1)	||';'||
		  RPAD(nvl(C_ENR.CD_INDICE_TITRE,' '),2)	||';'||
		  RPAD(nvl(C_ENR.CD_TYPE_TITRE,' '),1)	||';'||
		  RPAD(nvl(C_ENR.REF_TITRE,' '),12)	||';'||
		  --RPAD(' ',100)
		  RPAD(' ',96) -- 11/02/2019 - CRRV4.2 - correctif
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
   v_tail := '99' ||';'|| LPAD(v_nb_lignes,10,'0') || ';'||RPAD(' ',440);
   UTL_FILE.PUT_LINE(v_crr_descripteur, v_tail);


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
  v_head     VARCHAR2(114); --  <=== TAILLE DE LA LIGNE.
  v_ligne     VARCHAR2(135); --  <=== TAILLE DE LA LIGNE.
  v_tail     VARCHAR2(14); --  <=== TAILLE DE LA LIGNE.
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
		,ID_TIERS_GAR
		,TOP_IDTCA_DEPO
		,ID_TIERS_DEPO
		,SYST_GEST_SOURCE
		,ID_SURETE_RECUE
		,REF_IDENT_NATIO_GARANT
		,IDENT_NATIO_GARANT
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


   UTL_FILE.FCLOSE(v_crr_descripteur);
   v_nb_lignes := 0;

  DBMS_OUTPUT.PUT_LINE('Fin P_EXTRACT_FINANCE_SURETE_M3 : ' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));
EXCEPTION
WHEN OTHERS THEN
  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Erreur EXTRACT SURETE M3',50072);
  UTL_FILE.FCLOSE(v_crr_descripteur); --fermeture fichier si pb.
END P_EXTRACT_FINANCE_SURETE_M3;
-- FIN LFD


END PACK_UTL_FILE_ENVOI_C3RD ;
/
