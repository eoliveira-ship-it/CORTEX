
create or replace PACKAGE pack_alim_tab_envoi_crrv4_new IS
	  /******************************************************************************
		Nom :    pack_alim_tab_cibles_envoi_crrv4
		 But :    A partir des tables BTR, alimentations des tables cibles DDR avec
			conversion des donn?es statiques
		 Date :   05/09/2008
		 Auteur : C. SUAUDEAU
		 Reprise du pack_alim...crrv3 pour en faire un v4
		 Modification :
	  ******************************************************************************/

		PROCEDURE p_alim_ident_syndication;
		PROCEDURE p_analyse_tables_btr;
		--20/05/18 CDS ATOS (EMM) Mantis 42171
		PROCEDURE p_alim_tie_tiers_colc;
		--Fin EMM
		PROCEDURE p_alim_tie_tiers_c1_c5;
		PROCEDURE p_alim_Autorisation_F1;
		PROCEDURE p_alim_AUTORISATION_DETAIL_F2;
		PROCEDURE p_alim_eng_encours_corporate;  --P1 + P2
		PROCEDURE p_alim_surete_M1;
		PROCEDURE p_alim_Autorisation_F1_tech;
		PROCEDURE p_alim_AUT_DETAIL_F2_tech;
		PROCEDURE p_alim_aut_echeancier;
		PROCEDURE p_alim_his_provisions;
		PROCEDURE p_alim_provisions_decotes_p9;
		PROCEDURE p_alim_encours_retail_p5;     --P5
		PROCEDURE p_alim_ventilation_baloise_p6;
		PROCEDURE p_alim_aut_cor_ope_num_dec_bis;
		PROCEDURE p_trait_cd_pays_btr;
		PROCEDURE p_alim_PROVISIONS_DETAIL_P8;
		PROCEDURE p_alim_SURETE_RETAIL_M5;
		PROCEDURE Gest_Coherence_IDTCA_inBTR;
		PROCEDURE P_calcul_agregat;
		--17/04/19 CDS ATOS (EMM) Mantis 46097
	   PROCEDURE P_CALCUL_AGREGAT_P5;
	   PROCEDURE P_CALCUL_AGREGAT_P6;
	   PROCEDURE P_CALCUL_AGREGAT_P8;
	   PROCEDURE P_CALCUL_AGREGAT_M5;
	   --Fin EMM
		PROCEDURE P_alim_A1_AUTO;
		function f_cd_motif_sco_lc0267(CD_CATEG_CPT in varchar2, CD_MOTIF_POS_SCO in varchar2, NBRE_IMPY in number, NOTE_BALOISE in varchar2 ) return varchar2;

	   -- Bï¿½le 4
	   PROCEDURE p_alim_ind_isf;
	   PROCEDURE p_alim_ind_conf_crit_ope;

	   -- RSE_LOT3
	   PROCEDURE P_ALIM_PERIM_ENVOI_CRR_P1;

	   PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite    IN VARCHAR2,
	                                     p_masysdate IN VARCHAR2,
	                                     p_perimetre IN VARCHAR2 DEFAULT 'TOTAL');

	  END pack_alim_tab_envoi_crrv4_new;
/

create or replace PACKAGE BODY pack_alim_tab_envoi_crrv4_new IS
	  /******************************************************************************
		 Nom :    pack_alim_tab_cibles_envoi_crrv4 (body)
		 But :    A partir des tables BTR, alimentations des tables cibles DDR avec
			conversion des donn?es statiques
		 Date :   05/09/2008
		 Auteur : C. SUAUDEAU
		 Reprise du pack_alim...crrv3 pour en faire un v4
		 Modification :
	  ******************************************************************************/

		---------------------------------------------------------------
	  -- nom : procedure p_alim_ident_syndication      --
	  -- auteur : CDS ATOS (LFD), le 08/11/2018      --
	  -- ANACREDIT US 552                      --
	  ---------------------------------------------------------------
	  PROCEDURE p_alim_ident_syndication IS

		l_position varchar2(20);
		 BEGIN
         DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		l_position := 'IDENT_SYNDICATION';

		   execute immediate 'truncate table IDENT_SYNDICATION';

	  insert into IDENT_SYNDICATION (
		  ID_OPERATION,
		  CD_SYS_INT,
		  CD_SOC_JURI,
		  LIB_SOC_JURI,
		  CD_POSITION_ENTITE_RISQUE,
		  REF_SYNDICATION
		  , DT_ARRETE -- 17/12/2018 - CDS ATOS (LFD) - ANACREDIT US 570
	  )
	  select
		  o.ID_OPERATION, --ID_OPERATION
		  o.CD_SYS_INT, --CD_SYS_INT
		  o.CD_SOC_JURI, --CD_SOC_JURI
		  rs.LIB_SOC_JURI, --LIB_SOC_JURI
		  DECODE(nvl(o.POSITION_CAL_POOL, 'X'), 'pool CDF', 'C', ' '), --CD_POSITION_ENTITE_RISQUE
		  -- 10/12/2018 - CDS ATOS (LFD) - ANACREDIT US 570
		  /*CASE WHEN DECODE(nvl(o.POSITION_CAL_POOL, 'X'), 'pool CDF', 'C', ' ') = 'C' THEN
			  CASE WHEN o.CD_SOC_JURI = '06' THEN 'LIXBFRP1-'||TO_CHAR(o.DT_SIGNATURE_CLIENT ,'YYYYMMDD')||'-'||o.ID_OPERATION
					WHEN o.CD_SOC_JURI = '11' THEN 'UUFEFRP1-'||TO_CHAR(o.DT_SIGNATURE_CLIENT,'YYYYMMDD')||'-'||o.ID_OPERATION
					WHEN o.CD_SOC_JURI = '14' THEN 'AUXPFR21-'||TO_CHAR(o.DT_SIGNATURE_CLIENT,'YYYYMMDD')||'-'||o.ID_OPERATION
					WHEN o.CD_SOC_JURI = '23' THEN 'FIMUFR21-'||TO_CHAR(o.DT_SIGNATURE_CLIENT,'YYYYMMDD')||'-'||o.ID_OPERATION
					WHEN o.CD_SOC_JURI in ('51','09') THEN 'AGRIFRP1-'||TO_CHAR(o.DT_SIGNATURE_CLIENT,'YYYYMMDD')||'-'||o.ID_OPERATION
			  ELSE NULL END
		  END--REF_SYNDICATION*/
		  RS.BIC_8||'-'||TO_CHAR(O.DT_SIGNATURE_CLIENT,'YYYYMMDD')||'-'||O.ID_OPERATION
		  , O.DT_ARRETE
		  -- FIN LFD
	  FROM
		  BTR_OPERATION                  o,
		  RS_SOCIETE_JURIDIQUE           rs
	  WHERE
		  o.CD_SOC_JURI       = rs.CD_SOC_JURI
		  AND DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', 'Y', 'N') = 'Y';

		COMMIT;


	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE(' proc p_alim_ident_syndication :'||SQLERRM);
			  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_ident_syndication',50072);
	  END p_alim_ident_syndication ;

	  ------------------------------------------------------
	  -- nom : procedure p_analyse_tables_btr             --
	  -- but : analyse statistique des tables BTR         --
	  -- auteur : A. Guilmart, le 05/09/2008              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_analyse_tables_btr IS

      W_TABLE VARCHAR2(30);

	  BEGIN
      DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		DBMS_STATS.GATHER_TABLE_STATS('DDREX','BTR_TIERS',Estimate_Percent => NULL, CASCADE => TRUE);
		DBMS_STATS.GATHER_TABLE_STATS('DDREX','BTR_HORS_BILAN',Estimate_Percent => NULL, CASCADE => TRUE);
		DBMS_STATS.GATHER_TABLE_STATS('DDREX','BTR_ECHEANCIER',Estimate_Percent => NULL, CASCADE => TRUE);
		DBMS_STATS.GATHER_TABLE_STATS('DDREX','BTR_OPERATION',Estimate_Percent => NULL, CASCADE => TRUE);
		DBMS_STATS.GATHER_TABLE_STATS('DDREX','BTR_SURETE_REELLE',Estimate_Percent => NULL, CASCADE => TRUE);
		DBMS_STATS.GATHER_TABLE_STATS('DDREX','BTR_SURETE_PERS',Estimate_Percent => NULL, CASCADE => TRUE);

        W_TABLE := 'BTR_OPERATION';

		UPDATE BTR_OPERATION
		 SET LIB_CHEF_DE_FILE = trim(REPLACE_CAR_SPE(LIB_CHEF_DE_FILE))
		  ;
	  COMMIT ;

        W_TABLE := 'BTR_SURETE_REELLE';

	  UPDATE BTR_SURETE_REELLE
		 SET LIB_MODELE        = trim(REPLACE_CAR_SPE(LIB_MODELE))
		  ,LIG_1_ADR_ACT_CBI = trim(REPLACE_CAR_SPE(LIG_1_ADR_ACT_CBI))
		  ,LIG_2_ADR_ACT_CBI = trim(REPLACE_CAR_SPE(LIG_2_ADR_ACT_CBI))
		  ,LIG_3_ADR_ACT_CBI = trim(REPLACE_CAR_SPE(LIG_3_ADR_ACT_CBI))
		  ,LIG_4_ADR_ACT_CBI = trim(REPLACE_CAR_SPE(LIG_4_ADR_ACT_CBI))
		  ,VILLE             = trim(REPLACE_CAR_SPE(VILLE))
		  ,LIB_ACTIF         = trim(REPLACE_CAR_SPE(LIB_ACTIF))
		  ,IMMATRICULATION   = trim(REPLACE_CAR_SPE(IMMATRICULATION))
		  ;
	  COMMIT ;

      W_TABLE := 'BTR_TIERS';

	  UPDATE BTR_TIERS
		 SET RAISON_SOCLE = trim(REPLACE_CAR_SPE(RAISON_SOCLE))
		  ,NOM_GRPE     = trim(REPLACE_CAR_SPE(NOM_GRPE))
		  ,NOM_PATRO    = trim(REPLACE_CAR_SPE(NOM_PATRO))
		  ,PRENOM       = trim(REPLACE_CAR_SPE(PRENOM))
		  ,LIGNE_1_ADR  = trim(REPLACE_CAR_SPE(LIGNE_1_ADR))
		  ,LIGNE_2_ADR  = trim(REPLACE_CAR_SPE(LIGNE_2_ADR))
		  ,LIGNE_3_ADR  = trim(REPLACE_CAR_SPE(LIGNE_3_ADR))
		  ,LIGNE_4_ADR  = trim(REPLACE_CAR_SPE(LIGNE_4_ADR))
		  ,VILLE        = trim(REPLACE_CAR_SPE(VILLE))
		  ;
	  COMMIT ;

      W_TABLE := 'BTR_TIERS_COLC';

	  --18/04/18 CDS Atos (EMM) Mantis 42171
	  UPDATE BTR_TIERS_COLC
		 SET RAISON_SOCLE = trim(REPLACE_CAR_SPE(RAISON_SOCLE))
		  ,NOM_GRPE     = trim(REPLACE_CAR_SPE(NOM_GRPE))
		  ,NOM_PATRO    = trim(REPLACE_CAR_SPE(NOM_PATRO))
		  ,PRENOM       = trim(REPLACE_CAR_SPE(PRENOM))
		  ,LIGNE_1_ADR  = trim(REPLACE_CAR_SPE(LIGNE_1_ADR))
		  ,LIGNE_2_ADR  = trim(REPLACE_CAR_SPE(LIGNE_2_ADR))
		  ,LIGNE_3_ADR  = trim(REPLACE_CAR_SPE(LIGNE_3_ADR))
		  ,LIGNE_4_ADR  = trim(REPLACE_CAR_SPE(LIGNE_4_ADR))
		  ,VILLE        = trim(REPLACE_CAR_SPE(VILLE))
		  ;
	  COMMIT ;
	  --Fin EMM

      W_TABLE := 'RS_FAMILLE_ACTIF';

	  UPDATE RS_FAMILLE_ACTIF
		 SET LIB_FAMILLE_ACT = trim(REPLACE_CAR_SPE(LIB_FAMILLE_ACT))
		  ;
	  COMMIT ;

      W_TABLE := 'RS_MATERIEL_NAF';

	  UPDATE RS_MATERIEL_NAF
		 SET LIB_MATERIEL_NAF = trim(REPLACE_CAR_SPE(LIB_MATERIEL_NAF))
		  ;
	  COMMIT ;

    W_TABLE := 'HIS_BTR_HORS_BILAN_DE';
	  -- Circuit Cible 06-2018 : MANTIS=42160
	INSERT INTO HIS_BTR_HORS_BILAN_DE
	   (           ID_TIERS                              ,
						NUM_DEC                               ,
						ID_OPERATION                          ,
						CD_SYS_INT                            ,
						DT_ARRETE                             ,
						CD_DEVISE                             ,
						CD_SOC_JURI                           ,
						CD_STATUT_OPE_DT_SOLDE                ,
						CD_STATUT_RISQ_OPE                    ,
						DT_CHG_STATUT_RISQ                    ,
						CD_PRODUIT                            ,
						CD_TYPE_ACCEPTANT                     ,
						MNT_ENGMT_FINANCMT_HB                 ,
						MNT_BRUT_ORIGINE                      ,
						MNT_SYNDIC_FINANC_HB                  ,
						DT_DEB_VALIDITE_AUTO                  ,
						DT_FIN_VALIDITE_AUTO                  ,
						CD_SEGMENT_CASA                       ,
						DT_ENTREE_SGMT                        ,
						NOTE_RETENUE                          ,
						ID_DECISSIONAIRE                      ,
						MNT_IEC                               ,
						CD_SYS_INT_SIG                        ,
						ID_OPERATION_SIG
	   )
	Select B.ID_TIERS                              ,
		   B.NUM_DEC                               ,
		   B.ID_OPERATION                          ,
		   B.CD_SYS_INT                            ,
		   B.DT_ARRETE                             ,
		   B.CD_DEVISE                             ,
		   B.CD_SOC_JURI                           ,
		   B.CD_STATUT_OPE_DT_SOLDE                ,
		   B.CD_STATUT_RISQ_OPE                    ,
		   B.DT_CHG_STATUT_RISQ                    ,
		   B.CD_PRODUIT                            ,
		   B.CD_TYPE_ACCEPTANT                     ,
		   B.MNT_ENGMT_FINANCMT_HB                 ,
		   B.MNT_BRUT_ORIGINE                      ,
		   B.MNT_SYNDIC_FINANC_HB                  ,
		   B.DT_DEB_VALIDITE_AUTO                  ,
		   B.DT_FIN_VALIDITE_AUTO                  ,
		   B.CD_SEGMENT_CASA                       ,
		   B.DT_ENTREE_SGMT                        ,
		   B.NOTE_RETENUE                          ,
		   B.ID_DECISSIONAIRE                      ,
		   B.MNT_IEC                               ,
		   B.CD_SYS_INT_SIG                        ,
		   B.ID_OPERATION_SIG
	From BTR_HORS_BILAN B
	Where B.CD_SYS_INT = 'DE'
	And not exists (Select 1
					From HIS_BTR_HORS_BILAN_DE H1
					Where H1.Num_Dec = B.Num_Dec
					And   H1.Dt_Arrete = B.Dt_Arrete
					)
	;
	--Circuit Cible 06-2018 MAJ DATE DEBUT DATE FIN HB par DATES DE : MANTIS=42160
    W_TABLE := 'BTR_OPERATION';
	UPDATE BTR_OPERATION O
		   Set (O.DT_DEB_OPE, O.DT_FIN_OPE) =
											 (Select H.DT_DEB_VALIDITE_AUTO, H.DT_FIN_VALIDITE_AUTO
											  From  HIS_BTR_HORS_BILAN_DE H
											  Where O.Num_Dec=H.Num_Dec
											  And H.CD_SYS_INT = 'DE'
											  And O.Top_Eng='O'
											  And O.CD_SYS_INT <> 'DE'
											  And H.DT_DEB_VALIDITE_AUTO is not null
											  And H.DT_FIN_VALIDITE_AUTO is not null
											  And H.DT_ARRETE = (Select MAX(DT_ARRETE)
																 From HIS_BTR_HORS_BILAN_DE HB
																 Where HB.Num_Dec=H.Num_Dec
																 And HB.CD_SYS_INT = 'DE'
																)
											 )
	Where O.Top_Eng='O'
	And   O.CD_SYS_INT <> 'DE'
	And exists (Select H.DT_DEB_VALIDITE_AUTO, H.DT_FIN_VALIDITE_AUTO
				From  HIS_BTR_HORS_BILAN_DE H
				Where O.Num_Dec=H.Num_Dec
				And H.CD_SYS_INT = 'DE'
				And O.Top_Eng='O'
				And O.CD_SYS_INT <> 'DE'
				-- M58993 - KLx (VIC) - Retirage du 58993 Pour une deuxieme livraison
				-- US - Remise de la Mantis 58993
				And H.DT_DEB_VALIDITE_AUTO is not null -- M58993 CDS ATOS (VFN) 07/10/2021
                And H.DT_FIN_VALIDITE_AUTO is not null -- Fin VFN
			   )
	;

	Commit;

	  EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Proc p_analyse_tables_btr table:' || W_TABLE || ' -MESS:'||SQLERRM);
            pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'Proc p_analyse_tables_btr table:' || W_TABLE,50072);
	  END p_analyse_tables_btr;




	  ------------------------------------------------------
	-- nom : procedure p_alim_tie_tiers_colc            --
	-- but : Alimentation de la table cible             --
	--       tie_tiers_colc                             --
	--   Date :   11/04/2018              --
	--   Auteur : k. kharroubi              --
	--   Mantis : 42171                 --
	-----------------------------------------------------
	--#### Debut  procedure p_alim_tie_tiers_colc #### --
	PROCEDURE p_alim_tie_tiers_colc IS
		l_position varchar2(20);

	BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		execute immediate 'TRUNCATE TABLE tie_tiers_colc';


		INSERT INTO tie_tiers_colc (
					DT_ARRETE,
					CD_CONSO_CPT,
					ID_TIERS,  -- tier colocataire
					ID_OPERATION, -- operations de tier colc
					CD_SYS_INT,
					CD_ROLE_TIE,  --role colc venant de BTR
					ID_TIERS_CALC,
					ID_CENTRAL_TIERS,
					NOM_TIERS,
					RAISON_SOCLE,
					REF_IDENT_NATIO,
					IDENT_NATIO,
					CD_PAYS_NATIONALITE,
					CD_PAYS_RESIDENCE,
					CD_PAYS_CONTROLE,
					ADRESSE,
					VILLE,
					CD_POSTAL,
					DT_CLOTURE_CPT_NOTE,
					NOTE_INTERNE,
					DT_REVISION_NOTE,
					DT_ENTREE_DEFAUT,
					CD_METHODO_NOTE,
					CD_MOTIF_NOTE,
					CD_ENTITE_RUN,
					CD_ENTITE_RMC,
					CD_GRILLE_NOTE,
					CD_CATEG_CONTREPARTIE,
					CD_PORTEFEUILLE_BAL_TIERS,
					CD_SEGMENT_CAL,
					CD_SECTEUR_ACTIVITE,
					CD_FILIERE,
					CD_NORME_LOCAL_ACT,
					CD_ACTIVITE_LOCALE,
					CD_FORM_JUR,
					CD_STATUT_FILIATION,
					CD_TYPE_ACTEUR,
					CD_TYPE_RELATION,
					MNT_CA,
					TOP_CA_CONSO,
					CD_DEVISE_CA,
					ANNEE_CA,
					TOP_TIERS_DTX,
					CD_TYPE_TIE
				   ,NBRE_JOUR_EXERCICE
				   ,NATURE_CA
				   ,NOTE_NAFA
				   ,TOT_BILAN_RETRAITE
				   ,CA_IFRS
				   ,RES_NET_RETRAITE_SIGN
				   ,RES_NET_RETRAITE_MNT
				   ,NOTE_APR_CORR_GRPE
				   ,AGENCE_NOTATION
				   ,COTATION
				   ,CD_TYPE_COTATION
				   ,DT_COTATION
				   ,STATUT_ACTIVITE_LOC
				   ,DT_STATUT_ACTIVITE_LOC
				   ,IDENT_NATION_2
				   ,RAIS_SOCL_KBIS
				   ,NOTE_CALC_FIN
				   ,CD_SECT_RISQ_SYST
				   ,CD_TYPE_SEGMENT
				   ,ID_AGREGAT
		   ,A_EXTRAIRE)

		SELECT /*+ ORDERED */ DISTINCT T.DT_ARRETE,
				sj.CD_CONSO_CPT_CRRV3 CD_CONSO_CPT,
				T.ID_TIERS,
				T.ID_OPERATION,
				T.CD_SYS_INT,
				T.CD_ROLE_TIE,    --role colc venant de BTR
				CASE WHEN id_entr IS NULL THEN 'ENT'||T.ID_TIERS ELSE 'EN'||T.id_entr END id_tiers_calc,
				T.IDENT_SIRIS ID_CENTRAL_TIERS,
				DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO) NOM_TIERS,
				T.RAISON_SOCLE,
				CASE WHEN T.CD_PAYS_RESIDENCE IN ('FR','RE','MQ','GF','GP','YT','PM','NC','PF','WF') AND pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='O' THEN '01'    WHEN T.CD_PAYS_RESIDENCE = 'US' THEN '02' WHEN nvl(T.CD_PAYS_RESIDENCE,'99') = '99' AND nvl(T.CD_PAYS_NATIONALITE,'99') IN ('FR','RE','MQ','GF','GP','YT','PM','NC','PF','WF', '99') AND pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='O' THEN '01' WHEN nvl(T.CD_PAYS_RESIDENCE,'99') = '99' AND T.CD_PAYS_NATIONALITE = 'US' THEN '02'
					--WHEN pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='N' THEN '99'
					ELSE '99' END ref_ident_natio, -- suite HL43969
				CASE WHEN pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='N' THEN NULL  ELSE T.NUM_SIREN END ident_natio, -- AGU 30/03/2009 Retours homologation 8 CASA
				decode(T.CD_PAYS_NATIONALITE,NULL,'FR','99','FR',T.CD_PAYS_NATIONALITE) CD_PAYS_NATIONALITE,
		  -- HL43969           decode(T.CD_PAYS_RESIDENCE,NULL,'FR','99','FR',T.CD_PAYS_RESIDENCE),
				CASE WHEN nvl(T.CD_PAYS_RESIDENCE,'99') != '99' THEN T.CD_PAYS_RESIDENCE WHEN (nvl(T.CD_PAYS_NATIONALITE,'99') != '99') THEN T.CD_PAYS_NATIONALITE  ELSE 'FR'  END cd_pays_residence ,
				CASE WHEN nvl(T.CD_PAYS_CONTROLE,'99') != '99' THEN T.CD_PAYS_CONTROLE WHEN nvl(T.CD_PAYS_NATIONALITE,'99') != '99' THEN T.CD_PAYS_NATIONALITE ELSE 'FR' END cd_pays_controle,
				T.LIGNE_1_ADR||' '||T.LIGNE_2_ADR ADRESSE,
					  T.VILLE,
					  T.CD_POSTAL,
					  T.DT_CLOTURE_CPT_NOTE,  -- MBO - 20120829 : TaskForce FTCA V2
					  NVL(T.NOTE_BALOISE, 'ND') NOTE_INTERNE,     -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
					  T.DT_NOTE_BAL             DT_REVISION_NOTE, -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
					  NULL DT_ENTREE_DEFAUT, -- case when t.CD_ENTITE_RMC = '00370' and t.DT_DEF_PAIEM_SORT = null then DT_ENTREE_DEFAUT end A REMETTRE LORSQU'ON ENVERRA LES NOTES
					  NVL(T.CD_METHODE_NOTE, '999') CD_METHODO_NOTE, -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
					  NVL(T.CD_MOTIF_NOTE,   '999') CD_MOTIF_NOTE,   -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
					  T.CD_RUN CD_ENTITE_RUN,
					  T.CD_ENTITE_RMC,
					  NVL(T.CD_GRILLE_NOTE, '990001900010120090702FR') CD_GRILLE_NOTE,  -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
					  nvl(T.CD_CATEG_CONTREPARTIE,'ECG12') CD_CATEG_CONTREPARTIE, -- HBO 05/10/2010 LotV5.4: La cat?gorie de contrepartie est r?cup?r?e de BTR
					  T.CD_SEGMENT_CASA CD_PORTEFEUILLE_BAL_TIERS,
					  T.CD_SEGMENT_CAL,
					  nvl(sa.CD_SECTEUR_ACTIVITE,'PP9902') CD_SECTEUR_ACTIVITE,
					  NULL CD_FILIERE,
					  DECODE(T.CD_PAYS_RESIDENCE,'FR','1','RE','1','MQ','1','GF','1','GP','1','YT','1','PM','1','NC','1','PF','1','WF','1','US','2','1') CD_NORME_LOCAL_ACT,
					  T.CD_NAF_REV2 cd_activite_locale,
					  fjc.CD_FORM_JUR_CRRV3 CD_FORM_JUR, --AGU 03/10/2008 Recette
					  DECODE(tlg.FLAG_CONSOLIDATION,'O',2,0) CD_STATUT_FILIATION, -- BTR 6.3 02/08/2012 FHL 50438
					  T.CD_TYPE_ACTEUR,   -- AFR le 15/06/2012 Projet BTR 6.3 L01-C36-2 Passage IRBA provisions dans CRRV3
					  T.CD_ROLE_TIERS CD_TYPE_RELATION,
					  NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) MNT_CA,  -- MBO - 20120829 : TaskForce FTCA V2
					  NVL(T.TOP_CA_CONSO, 'N') TOP_CA_CONSO,                -- MBO - 20120829 : TaskForce FTCA V2
					  (case when NVL(T.MNT_CA_DTG, T.MNT_CA) is not null then 'EUR' else NULL end) CD_DEVISE_CA,  -- MBO - 20120829 : TaskForce FTCA V2
					  (case when T.MNT_CA_DTG is not null then TO_NUMBER(T.ANNEE_CA_DTG) when T.MNT_CA     is not null then T.EXERCICE_CA  else NULL end) ANNEE_CA,  -- MBO - 20120829 : TaskForce FTCA V2
					  top_tiers_dtx,
					  T.CD_TYPE_SGMT CD_TYPE_TIE
					 ,T.NBRE_JOUR_EXERCICE
					 ,T.NATURE_CA
					 ,T.NOTE_NAFA
					 ,T.TOT_BILAN_RETRAITE
					 ,T.CA_IFRS
					 ,T.RES_NET_RETRAITE_SIGN
					 ,T.RES_NET_RETRAITE_MNT
					 ,T.NOTE_APR_CORR_GRPE     -- Fin ajout champs
					 ,T.AGENCE_NOTATION
					 ,T.COTATION
					 ,T.CD_TYPE_COTATION
					 ,T.DT_COTATION
					 ,T.STATUT_ACTIVITE_LOC
					 ,T.DT_STATUT_ACTIVITE_LOC
					 ,T.IDENT_NATION_2
					 ,T.RAIS_SOCL_KBIS
					 ,T.NOTE_CALC_FIN
					 ,nvl(T.CD_SECT_RISQ_SYST,NVL(sa.CD_SECTEUR_ACTIVITE,'PP9902')) CD_SECT_RISQ_SYST
					 ,'CORP'CD_TYPE_SEGMENT
					 ,null ID_AGREGAT
					 ,'O'A_EXTRAIRE
		FROM RS_CORRES_NAF_NORM_LOCAL_ACT sa, --AFR le 09/03/2012 : BTR 6.2 Fiablisation code NAF
			 RS_CORRES_FORM_JUR_CAL_CRRV3 fjc,
			 RS_TYPE_LIENS_GRPE tlg,
			 BTR_TIERS_COLC T,
			 BTR_OPERATION o,
			 RS_SOCIETE_JURIDIQUE sj,
			(  SELECT ti.ID_TIERS ,MIN(CD_INDICATEUR_DOUTEUX) KEEP (DENSE_RANK FIRST ORDER BY priorite) top_tiers_dtx
				FROM BTR_TIERS_COLC ti,BTR_OPERATION oi,RS_CORRES_CATEG_RISQ_INDIC_DTX dtx
				WHERE ti.ID_OPERATION = oi.ID_OPERATION
				AND ti.cd_sys_int = oi.cd_sys_int
				AND DECODE(oi.CD_STATUT_RISQ_OPE,'AJRST',oi.CD_STATUT_RISQ_OPE,ti.CD_CATEG_CPT) = dtx.CD_CATEG_RISQ
				GROUP BY ti.ID_TIERS
			) indic_dtx,
			--Mantis 52841 - CDS_ATOS (MNE) : En cas de doublon sur l'id_entr, pour garder l'unicitÃ¿Â¿Â½ de l'index, on ne garde que le tiers le plus rÃ¿Â¿Â½cent (id_tiers le plus Ã¿Â¿Â½lÃ¿Â¿Â½vÃ¿Â¿Â½)
			(  select max(id_tiers) id_tiers,id_operation,cd_sys_int,id_tiers_calc --Max pour le tiers le plus rÃ¿Â¿Â½cent
				from	(	select id_tiers,id_operation,cd_sys_int,CASE WHEN id_entr IS NULL THEN 'ENT'||ID_TIERS ELSE 'EN'||id_entr END id_tiers_calc
							from BTR_TIERS_COLC
						)
				group by id_operation,cd_sys_int,id_tiers_calc
			) j
			--Mantis 52841 - CDS_ATOS (MNE) : Sous requete de jointure rÃ¿Â¿Â½cupÃ¿Â¿Â½rant les tiers de maniÃ¿Â¿Â½re unique si doublons selon la rÃ¿Â¿Â½gle Ã¿Â¿Â½dictÃ¿Â¿Â½e ci-dessus.
			--Fin MNE
		WHERE T.ID_OPERATION = o.ID_OPERATION --jointure sur les operations et non les tiers
		AND T.cd_sys_int = o.cd_sys_int
		AND o.CD_SOC_JURI = sj.CD_SOC_JURI
		AND T.CD_NAF_REV2 = sa.CD_NAF_REV2 (+)  --AFR le 09/03/2012 : BTR 6.2 Fiablisation code NAF
		AND T.ID_TIERS = indic_dtx.ID_TIERS (+)
		AND T.CD_FORM_JUR = fjc.CD_FORM_JUR (+)
		AND T.CD_TYPE_LIEN=tlg.CD_TYPE_LIEN(+)
		AND T.CD_TYPE_SGMT = 'CORP'
		AND sj.CD_CONSO_CPT_CRRV3 != '99999'
		--Mantis 52841 - CDS_ATOS (MNE) : Jointures de la sous requete J avec le reste de la table. ImpossibilitÃ¿Â¿Â½ de faire un inner join a cause des autres jointures (+)
		AND j.id_operation = t.id_operation
		AND j.cd_sys_int = t.cd_sys_int
		AND j.id_tiers_calc = id_tiers_calc
		AND j.id_tiers = t.id_tiers;
		--Fin MNE
		COMMIT;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_tie_tiers_colc -MESS:'||SQLERRM);
			  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_tie_tiers_colc:'||l_position,50072);
	  END p_alim_tie_tiers_colc;




	  ------------------------------------------------------
	  -- nom : procedure p_alim_tie_tiers                 --
	  -- but : Alimentation de la table cible envoi CRRV4 --
	  --       tie_tiers_c1_c5                            --
	  --   Date :   05/09/2008
	  --   Auteur : C. SUAUDEAU
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
	  ------------------------------------------------------
	  PROCEDURE p_alim_tie_tiers_c1_c5 IS
		l_position varchar2(20);
        W_TABLE    varchar2(20);

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		execute immediate 'TRUNCATE TABLE tie_tiers_c1_c5';
		execute immediate 'TRUNCATE TABLE tie_tiers';

		-- cas des tiers CORPORATE (unitaires)
		l_position := 'tiers CORP';

        W_TABLE :='tie_tiers_c1_c5 (1)';

		INSERT INTO tie_tiers_c1_c5 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  NOM_TIERS,
		  RAISON_SOCLE,
		  REF_IDENT_NATIO,
		  IDENT_NATIO,
		  CD_PAYS_NATIONALITE,
		  CD_PAYS_RESIDENCE,
		  CD_PAYS_CONTROLE,
		  ADRESSE,
		  VILLE,
		  CD_POSTAL,
		  DT_CLOTURE_CPT_NOTE,
		  NOTE_INTERNE,
		  DT_REVISION_NOTE,
		  DT_ENTREE_DEFAUT,
		  CD_METHODO_NOTE,
		  CD_MOTIF_NOTE,
		  CD_ENTITE_RUN,
		  CD_ENTITE_RMC,
		  CD_GRILLE_NOTE,
		  CD_CATEG_CONTREPARTIE,
		  CD_PORTEFEUILLE_BAL_TIERS,
		  CD_SEGMENT_CAL,
		  CD_SECTEUR_ACTIVITE,
		  CD_FILIERE,
		  CD_NORME_LOCAL_ACT,
		  CD_ACTIVITE_LOCALE,
		  CD_FORM_JUR,
		  CD_STATUT_FILIATION,
		  CD_TYPE_ACTEUR,
		  CD_TYPE_RELATION,
		  MNT_CA,
		  TOP_CA_CONSO,
		  CD_DEVISE_CA,
		  ANNEE_CA,
		  TOP_TIERS_DTX,
		  CD_TYPE_TIE
		   ,NBRE_JOUR_EXERCICE
		   ,NATURE_CA
		   ,NOTE_NAFA
		   ,TOT_BILAN_RETRAITE
		   ,CA_IFRS
		   ,RES_NET_RETRAITE_SIGN
		   ,RES_NET_RETRAITE_MNT
		   ,NOTE_APR_CORR_GRPE
		   ,AGENCE_NOTATION
		   ,COTATION
		   ,CD_TYPE_COTATION
		   ,DT_COTATION
		   ,STATUT_ACTIVITE_LOC
		   ,DT_STATUT_ACTIVITE_LOC
		   ,IDENT_NATION_2
		   ,RAIS_SOCL_KBIS
		   ,NOTE_CALC_FIN
		   ,CD_SECT_RISQ_SYST
		   ,CD_TYPE_SEGMENT
		   ,ID_AGREGAT
		   ,A_EXTRAIRE
		   ,NB_SALARIE -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
		  --04/01/2019 CDS Atos (SQN) US 615
		   ,ID_ENT_MERE_IMMEDIAT
		   ,IND_ENT_MERE_IMMEDIAT
		   ,CD_NUTS
		   ,ETAT_AVNCT_PJ
		   ,DT_OUV_PJ
		   --Fin SQN
			   ,REF_IDENT_NAT_2  -- 18/02/2019 - CDS ATOS (GBD) - US731
		   ,ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
		   -- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,IND_CEL
			,NIV_INTG_GROUPE_TIE
			,IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		  )
		SELECT /*+ ORDERED */ DISTINCT T.DT_ARRETE,
			sj.CD_CONSO_CPT_CRRV3,
			T.ID_TIERS,
			CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
			T.IDENT_SIRIS,
			  DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO),
			T.RAISON_SOCLE,
			CASE WHEN T.CD_PAYS_RESIDENCE IN ('FR','RE','MQ','GF','GP','YT','PM','NC','PF','WF') AND pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='O' THEN '01'  -- suite HL43969
			   WHEN T.CD_PAYS_RESIDENCE = 'US' THEN '02'
			   WHEN nvl(T.CD_PAYS_RESIDENCE,'99') = '99' AND nvl(T.CD_PAYS_NATIONALITE,'99') IN ('FR','RE','MQ','GF','GP','YT','PM','NC','PF','WF', '99') AND pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='O' THEN '01'
			   WHEN nvl(T.CD_PAYS_RESIDENCE,'99') = '99' AND T.CD_PAYS_NATIONALITE = 'US' THEN '02'
			   --WHEN pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='N' THEN '99'
			   ELSE '99'
			END ref_ident_natio,
			CASE WHEN pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='N' THEN NULL
			   ELSE T.NUM_SIREN
			END ident_natio, -- AGU 30/03/2009 Retours homologation 8 CASA
			decode(T.CD_PAYS_NATIONALITE,NULL,'FR','99','FR',T.CD_PAYS_NATIONALITE),
	  -- HL43969           decode(T.CD_PAYS_RESIDENCE,NULL,'FR','99','FR',T.CD_PAYS_RESIDENCE),
			CASE WHEN nvl(T.CD_PAYS_RESIDENCE,'99') != '99' THEN T.CD_PAYS_RESIDENCE
			   WHEN (nvl(T.CD_PAYS_NATIONALITE,'99') != '99') THEN T.CD_PAYS_NATIONALITE
			   ELSE 'FR'
			END cd_pays_residence,
			CASE WHEN nvl(T.CD_PAYS_CONTROLE,'99') != '99' THEN T.CD_PAYS_CONTROLE
			   WHEN nvl(T.CD_PAYS_NATIONALITE,'99') != '99' THEN T.CD_PAYS_NATIONALITE
			   ELSE 'FR'
			END cd_pays_controle,
			T.LIGNE_1_ADR||' '||T.LIGNE_2_ADR,
			T.VILLE,
			T.CD_POSTAL,
			T.DT_CLOTURE_CPT_NOTE,  -- MBO - 20120829 : TaskForce FTCA V2
			NVL(T.NOTE_BALOISE, 'ND') NOTE_INTERNE,     -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			--21/01/2019 CDS Atos (SQN) US 649
			--T.DT_NOTE_BAL     DT_REVISION_NOTE, -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			NVL(T.DT_NOTE_BAL, SYSDATE) DT_REVISION_NOTE,
			--Fin SQN
			--10/09/2018 CDS Atos (EMM) US 488
			CASE WHEN T.CD_CATEG_CPT in ('DTCO','DTX')  THEN T.DT_CHG_CATEG_CPT ELSE NULL END dt_entree_defaut,
			--Fin EMM
			NVL(T.CD_METHODE_NOTE, '999') CD_METHODE_NOTE, -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			NVL(T.CD_MOTIF_NOTE,   '999') CD_MOTIF_NOTE,   -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			T.CD_RUN,
			T.CD_ENTITE_RMC,
			NVL(T.CD_GRILLE_NOTE, '990001900010120090702FR') CD_GRILLE_NOTE,  -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			nvl(T.CD_CATEG_CONTREPARTIE,'ECG12'), -- HBO 05/10/2010 LotV5.4: La cat?gorie de contrepartie est r?cup?r?e de BTR
			--T.CD_SEGMENT_CASA,
		  ptf.CD_PTF_BALE_TIERS,
			T.CD_SEGMENT_CAL,
			nvl(sa.CD_SECTEUR_ACTIVITE,'ZZ0000'),
			NULL filiere,
			DECODE(T.CD_PAYS_RESIDENCE,'FR','1','RE','1','MQ','1','GF','1','GP','1','YT','1','PM','1','NC','1','PF','1','WF','1','US','2','1') cd_norm_local_act,
			T.CD_NAF_REV2 cd_activite_locale,
			fjc.CD_FORM_JUR_CRRV3, --AGU 03/10/2008 Recette
			--DECODE(T.CD_TYPE_LIEN,'T','2','F1','2','0'),
			DECODE(tlg.FLAG_CONSOLIDATION,'O',2,0), -- BTR 6.3 02/08/2012 FHL 50438
			T.CD_TYPE_ACTEUR,   -- AFR le 15/06/2012 Projet BTR 6.3 L01-C36-2 Passage IRBA provisions dans CRRV3
			T.CD_ROLE_TIERS,
			--05/02/2019 CDS ATOS (SQN) US 649 - it 2
			--NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA),
			(CASE
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) > 100000000000 THEN NULL
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) < 0 THEN NULL
			  ELSE NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA)
			END) MNT_CA,
			--Fin SQN
			NVL(T.TOP_CA_CONSO, 'N'),                -- MBO - 20120829 : TaskForce FTCA V2
			(case when NVL(T.MNT_CA_DTG, T.MNT_CA) is not null then 'EUR' else NULL end),  -- MBO - 20120829 : TaskForce FTCA V2
			(case when T.MNT_CA_DTG is not null then TO_NUMBER(T.ANNEE_CA_DTG)
				when T.MNT_CA     is not null then T.EXERCICE_CA
				else NULL end),  -- MBO - 20120829 : TaskForce FTCA V2
			top_tiers_dtx,
			T.CD_TYPE_SGMT
			 -- MBO - 20120828 : TaskForce FTCA V2 - Ajout des champs complement notes FNN
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.NBRE_JOUR_EXERCICE
			 ,NVL(T.NBRE_JOUR_EXERCICE, '0')
			 --Fin SQN
			 ,T.NATURE_CA
			 ,T.NOTE_NAFA
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.TOT_BILAN_RETRAITE
			 --,T.CA_IFRS
			 ,NVL(T.TOT_BILAN_RETRAITE, '0')
			 ,NVL(T.CA_IFRS, '0')
			 --Fin SQN
			 ,T.RES_NET_RETRAITE_SIGN
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.RES_NET_RETRAITE_MNT
			 ,NVL(T.RES_NET_RETRAITE_MNT, '0')
			 --Fin SQN
			 ,T.NOTE_APR_CORR_GRPE     -- Fin ajout champs
			 ,T.AGENCE_NOTATION
			 ,T.COTATION
			 ,T.CD_TYPE_COTATION
			 ,T.DT_COTATION
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.STATUT_ACTIVITE_LOC
			 ,NVL(T.STATUT_ACTIVITE_LOC, 'A')
			 --Fin SQN
			 ,T.DT_STATUT_ACTIVITE_LOC
			 ,T.IDENT_NATION_2
			 ,T.RAIS_SOCL_KBIS
			 ,T.NOTE_CALC_FIN
			 ,nvl(T.CD_SECT_RISQ_SYST,NVL(sa.CD_SECTEUR_ACTIVITE,'ZZ0000'))
			 ,'CORP'
			 ,null
			 ,'O' --a extraire
			 , pack_utilitaire.F_CODE_EFFECTIF_NB_SALARIE(T.EFFECTIF) -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
			 --04/01/2019 CDS Atos (SQN) US 615
			 -- 13/05/2019 - CDS ATOS (LFD) - US 791
			 --,null
			 ,T.IDENT_SIRIS ID_ENT_MERE_IMMEDIAT
			   --,null
			 ,CASE WHEN T.IDENT_SIRIS IS NOT NULL THEN '1' END IND_ENT_MERE_IMMEDIAT
			 -- FIN LFD
			 ,PACK_UTILITAIRE.F_GET_CODE_NUTS(t.cd_postal,t.CD_PAYS_RESIDENCE )
			   --30/03/2020 CDS ATOS (SQN) US N3D 509
			 --,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' END
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' ELSE '1' END
			 --Fin SQN
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN T.DT_CHG_STATUT_RISQ END
				   , null  REF_IDENT_NAT_2 -- 18/02/2019 - CDS ATOS (GBD) - US731
			 ,CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
			-- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,'0' IND_CEL
			,'0' NIV_INTG_GROUPE_TIE
			,NULL IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,SBT.CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		FROM RS_CORRES_NAF_NORM_LOCAL_ACT sa, --AFR le 09/03/2012 : BTR 6.2 Fiablisation code NAF
		   RS_CORRES_FORM_JUR_CAL_CRRV3 fjc,
			   RS_TYPE_LIENS_GRPE tlg,
		   BTR_TIERS T,
		RS_CORRES_CATEG_CPY_PTF_BALE ptf,
		   BTR_OPERATION o,
		   RS_SOCIETE_JURIDIQUE sj,
		   (SELECT ti.id_tiers,MIN(CD_INDICATEUR_DOUTEUX) KEEP (DENSE_RANK FIRST ORDER BY priorite) top_tiers_dtx
			FROM BTR_TIERS ti,BTR_OPERATION oi,RS_CORRES_CATEG_RISQ_INDIC_DTX dtx
			WHERE ti.ID_TIERS = oi.ID_TIERS
			AND DECODE(oi.CD_STATUT_RISQ_OPE,'AJRST',oi.CD_STATUT_RISQ_OPE,ti.CD_CATEG_CPT) = dtx.CD_CATEG_RISQ
			GROUP BY ti.id_tiers) indic_dtx
			,RS_CORRES_SGMT_BAL_TYPE_CLI SBT --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		WHERE T.ID_TIERS = o.ID_TIERS
		AND o.CD_SOC_JURI = sj.CD_SOC_JURI
		AND T.CD_NAF_REV2 = sa.CD_NAF_REV2 (+)  --AFR le 09/03/2012 : BTR 6.2 Fiablisation code NAF
		AND T.id_tiers = indic_dtx.id_tiers (+)
		AND T.CD_FORM_JUR = fjc.CD_FORM_JUR (+)
		and nvl(T.CD_CATEG_CONTREPARTIE,'ECG12') = ptf.CD_CATEG_CONTREPARTIE (+)
		AND T.CD_TYPE_LIEN=tlg.CD_TYPE_LIEN(+)
		AND T.CD_TYPE_SGMT = 'CORP'
		AND sj.CD_CONSO_CPT_CRRV3 != '99999'
		AND T.CD_SEGMENT_CAL = SBT.CD_SEGMENT_CAL(+) --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		;
		COMMIT;

		-- Tiers corporates qui ne sont que garants ==> ils ne sont pas dans btr_operation AGU 09/10/2008 Recette
        W_TABLE :='tie_tiers_c1_c5 (2)';
		INSERT INTO tie_tiers_c1_c5 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  NOM_TIERS,
		  RAISON_SOCLE,
		  REF_IDENT_NATIO,
		  IDENT_NATIO,
		  CD_PAYS_NATIONALITE,
		  CD_PAYS_RESIDENCE,
		  CD_PAYS_CONTROLE,
		  ADRESSE,
		  VILLE,
		  CD_POSTAL,
		  DT_CLOTURE_CPT_NOTE,
		  NOTE_INTERNE,
		  DT_REVISION_NOTE,
		  DT_ENTREE_DEFAUT,
		  CD_METHODO_NOTE,
		  CD_MOTIF_NOTE,
		  CD_ENTITE_RUN,
		  CD_ENTITE_RMC,
		  CD_GRILLE_NOTE,
		  CD_CATEG_CONTREPARTIE,
		  CD_PORTEFEUILLE_BAL_TIERS,
		  CD_SEGMENT_CAL,
		  CD_SECTEUR_ACTIVITE,
		  CD_FILIERE,
		  CD_NORME_LOCAL_ACT,
		  CD_ACTIVITE_LOCALE,
		  CD_FORM_JUR,
		  CD_STATUT_FILIATION,
		  CD_TYPE_ACTEUR,
		  CD_TYPE_RELATION,
		  MNT_CA,
		  TOP_CA_CONSO, -- AGU 03/11/2008 Retours homologation CASA
		  CD_DEVISE_CA,
		  ANNEE_CA,
		  TOP_TIERS_DTX,
		  CD_TYPE_TIE
		   -- MBO - 20120828 : TaskForce FTCA V2 - Ajout des champs complement notes FNN
		   ,NBRE_JOUR_EXERCICE
		   ,NATURE_CA
		   ,NOTE_NAFA
		   ,TOT_BILAN_RETRAITE
		   ,CA_IFRS
		   ,RES_NET_RETRAITE_SIGN
		   ,RES_NET_RETRAITE_MNT
		   ,NOTE_APR_CORR_GRPE     -- Fin ajout champs
		   ,AGENCE_NOTATION
		   ,COTATION
		   ,CD_TYPE_COTATION
		   ,DT_COTATION
		   ,STATUT_ACTIVITE_LOC
		   ,DT_STATUT_ACTIVITE_LOC
		   ,IDENT_NATION_2
		   ,RAIS_SOCL_KBIS
		   ,NOTE_CALC_FIN
		   ,CD_SECT_RISQ_SYST
		   ,CD_TYPE_SEGMENT
		   ,ID_AGREGAT
		   ,A_EXTRAIRE
			 ,NB_SALARIE -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
		   --04/01/2019 CDS Atos (SQN) US 615
		   ,ID_ENT_MERE_IMMEDIAT
		   ,IND_ENT_MERE_IMMEDIAT
		   ,CD_NUTS
		   ,ETAT_AVNCT_PJ
		   ,DT_OUV_PJ
		   --Fin SQN
			   ,REF_IDENT_NAT_2  -- 18/02/2019 - CDS ATOS (GBD) - US731
		   ,ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
		   -- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,IND_CEL
			,NIV_INTG_GROUPE_TIE
			,IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		  )
		SELECT   DISTINCT T.DT_ARRETE,
			sj.CD_CONSO_CPT_CRRV3,
			T.ID_TIERS,
			CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
			T.IDENT_SIRIS,
			  DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO),
			T.RAISON_SOCLE,
			CASE WHEN T.CD_PAYS_RESIDENCE IN ('FR','RE','MQ','GF','GP','YT','PM','NC','PF','WF') AND pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='O' THEN '01'
			   WHEN T.CD_PAYS_RESIDENCE = 'US' THEN '02'
			   WHEN nvl(T.CD_PAYS_RESIDENCE,'99') = '99' AND nvl(T.CD_PAYS_NATIONALITE,'99') IN ('FR','RE','MQ','GF','GP','YT','PM','NC','PF','WF', '99') AND pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='O' THEN '01'   -- suite HL 43969
			   WHEN nvl(T.CD_PAYS_RESIDENCE,'99') = '99' AND T.CD_PAYS_NATIONALITE = 'US' THEN '02'
			   --WHEN pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='N' THEN '99'
			   ELSE '99'
			END ref_ident_natio,
			CASE WHEN pack_utilitaire.FONC_VERIFIER_SIRET(T.NUM_SIREN) ='N' THEN NULL
			   ELSE T.NUM_SIREN
			END ident_natio, -- AGU 30/03/2009 Retours homologation 8 CASA,
			decode(T.CD_PAYS_NATIONALITE,NULL,'FR','99','FR',T.CD_PAYS_NATIONALITE),
	  -- HL43969           decode(T.CD_PAYS_RESIDENCE,NULL,'FR','99','FR',T.CD_PAYS_RESIDENCE),
			CASE WHEN nvl(T.CD_PAYS_RESIDENCE,'99') != '99' THEN T.CD_PAYS_RESIDENCE
			   WHEN nvl(T.CD_PAYS_NATIONALITE,'99') != '99' THEN T.CD_PAYS_NATIONALITE
			   ELSE 'FR'
			END cd_pays_residence,
			CASE WHEN nvl(T.CD_PAYS_CONTROLE,'99') != '99' THEN T.CD_PAYS_CONTROLE
			   WHEN nvl(T.CD_PAYS_NATIONALITE,'99') != '99' THEN T.CD_PAYS_NATIONALITE
			   ELSE 'FR'
			END cd_pays_controle,
			T.LIGNE_1_ADR||' '||T.LIGNE_2_ADR,
			T.VILLE,
			T.CD_POSTAL,
			T.DT_CLOTURE_CPT_NOTE,  -- MBO - 20120829 : TaskForce FTCA V2
			NVL(T.NOTE_BALOISE, 'ND') NOTE_INTERNE,     -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			--21/01/2019 CDS Atos (SQN) US 649
			--T.DT_NOTE_BAL     DT_REVISION_NOTE, -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			NVL(T.DT_NOTE_BAL, SYSDATE) DT_REVISION_NOTE,
			--Fin SQN
			--10/10/2018 CDS Atos (LFD) US 488
			--NULL DT_ENTREE_DEFAUT, -- case when t.CD_ENTITE_RMC = '00370' and t.DT_DEF_PAIEM_SORT = null then DT_ENTREE_DEFAUT end A REMETTRE LORSQU'ON ENVERRA LES NOTES
			CASE WHEN T.CD_CATEG_CPT in ('DTCO','DTX')  THEN T.DT_CHG_CATEG_CPT ELSE NULL END dt_entree_defaut,
			--Fin LFD
			NVL(T.CD_METHODE_NOTE, '999') CD_METHODE_NOTE, -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			NVL(T.CD_MOTIF_NOTE,   '999') CD_MOTIF_NOTE,   -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			T.CD_RUN,
			T.CD_ENTITE_RMC,
			NVL(T.CD_GRILLE_NOTE, '990001900010120090702FR') CD_GRILLE_NOTE,  -- MBO - 20121031 - FHL 45879 : supp regle translation notation pour CORP
			nvl(T.CD_CATEG_CONTREPARTIE,'ECG12'), -- HBO 05/10/2010 LotV5.4: La cat?gorie de contrepartie est r?cup?r?e de BTR
			--T.CD_SEGMENT_CASA,
				ptf.CD_PTF_BALE_TIERS,
			T.CD_SEGMENT_CAL,
			nvl(sa.CD_SECTEUR_ACTIVITE,'ZZ0000'),
			NULL filiere,
			DECODE(T.CD_PAYS_RESIDENCE,'FR','1','RE','1','MQ','1','GF','1','GP','1','YT','1','PM','1','NC','1','PF','1','WF','1','1') cd_norm_local_act,
			T.cd_naf_rev2 cd_activite_locale,
			fjc.CD_FORM_JUR_CRRV3, --AGU 03/10/2008 Recette
			--DECODE(T.CD_TYPE_LIEN,'T','2','F1','2','0'),
			DECODE(tlg.FLAG_CONSOLIDATION,'O',2,0), -- BTR 6.3 02/08/2012 FHL 50438
			T.CD_TYPE_ACTEUR,   -- AFR le 15/06/2012 Projet BTR 6.3 L01-C36-2 Passage IRBA provisions dans CRRV3
			T.CD_ROLE_TIERS,
			--05/02/2019 CDS ATOS (SQN) US 649 - it 2
			--NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA),
			(CASE
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) > 100000000000 THEN NULL
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) < 0 THEN NULL
			  ELSE NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA)
			END) MNT_CA,
			--Fin SQN
			NVL(T.TOP_CA_CONSO, 'N'),                -- MBO - 20120829 : TaskForce FTCA V2
			(case when NVL(T.MNT_CA_DTG, T.MNT_CA) is not null then 'EUR' else NULL end),  -- MBO - 20120829 : TaskForce FTCA V2
			(case when T.MNT_CA_DTG is not null then TO_NUMBER(T.ANNEE_CA_DTG)
				when T.MNT_CA     is not null then T.EXERCICE_CA
				else NULL end),  -- MBO - 20120829 : TaskForce FTCA V2
			top_tiers_dtx,
			T.CD_TYPE_SGMT
			 -- MBO - 20120828 : TaskForce FTCA V2 - Ajout des champs complement notes FNN
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.NBRE_JOUR_EXERCICE
			 ,NVL(T.NBRE_JOUR_EXERCICE, '0')
			 --Fin SQN
			 ,T.NATURE_CA
			 ,T.NOTE_NAFA
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.TOT_BILAN_RETRAITE
			 --,T.CA_IFRS
			 ,NVL(T.TOT_BILAN_RETRAITE, '0')
			 ,NVL(T.CA_IFRS, '0')
			 --Fin SQN
			 ,T.RES_NET_RETRAITE_SIGN
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.RES_NET_RETRAITE_MNT
			 ,NVL(T.RES_NET_RETRAITE_MNT, '0')
			 --Fin SQN
			 ,T.NOTE_APR_CORR_GRPE     -- Fin ajout champs
			 ,T.AGENCE_NOTATION
			 ,T.COTATION
			 ,T.CD_TYPE_COTATION
			 ,T.DT_COTATION
			 --21/01/2019 CDS Atos (SQN) US 649
			 --,T.STATUT_ACTIVITE_LOC
			 ,NVL(T.STATUT_ACTIVITE_LOC, 'A')
			 --Fin SQN
			 ,T.DT_STATUT_ACTIVITE_LOC
			 ,T.IDENT_NATION_2
			 ,T.RAIS_SOCL_KBIS
			 ,T.NOTE_CALC_FIN
			 ,nvl(T.CD_SECT_RISQ_SYST,NVL(sa.CD_SECTEUR_ACTIVITE,'ZZ0000'))
			 ,'CORP'
			 ,null
			 ,'O'  --a extraire
			 , pack_utilitaire.F_CODE_EFFECTIF_NB_SALARIE(T.EFFECTIF) -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
			 --04/01/2019 CDS Atos (SQN) US 615
			 -- 13/05/2019 - CDS ATOS (LFD) - US 791
			 --,null
			 ,T.IDENT_SIRIS ID_ENT_MERE_IMMEDIAT
			   --,null
			 ,CASE WHEN T.IDENT_SIRIS IS NOT NULL THEN '1' END IND_ENT_MERE_IMMEDIAT
			 -- FIN LFD
			 ,PACK_UTILITAIRE.F_GET_CODE_NUTS(t.cd_postal,t.CD_PAYS_RESIDENCE )
			   --30/03/2020 CDS ATOS (SQN) US N3D 509
			 --,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' END
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' ELSE '1' END
			 --Fin SQN
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN T.DT_CHG_STATUT_RISQ END
			 --Fin SQN
				   , null  REF_IDENT_NAT_2 -- 18/02/2019 - CDS ATOS (GBD) - US731
			 ,CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
			-- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,'0' IND_CEL
			,'0' NIV_INTG_GROUPE_TIE
			,NULL IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,SBT.CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_CET-- KLX-GOMESHU - BALE4 - 19/12/2023
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		FROM BTR_OPERATION o,
		   BTR_SURETE_PERS sp,
		   RS_SOCIETE_JURIDIQUE sj,
		   RS_CORRES_NAF_NORM_LOCAL_ACT sa, --AFR le 09/03/2012 : BTR 6.2 Fiablisation code NAF
		   RS_CORRES_FORM_JUR_CAL_CRRV3 fjc,
			 RS_CORRES_CATEG_CPY_PTF_BALE ptf,
		   RS_TYPE_LIENS_GRPE tlg,
		   BTR_TIERS T,
		   (SELECT  ti.id_tiers,MIN(CD_INDICATEUR_DOUTEUX) KEEP (DENSE_RANK FIRST ORDER BY priorite) top_tiers_dtx
			FROM BTR_TIERS ti,BTR_OPERATION oi,RS_CORRES_CATEG_RISQ_INDIC_DTX dtx
			WHERE ti.ID_TIERS = oi.ID_TIERS
			AND DECODE(oi.CD_STATUT_RISQ_OPE,'AJRST',oi.CD_STATUT_RISQ_OPE,ti.CD_CATEG_CPT) = dtx.CD_CATEG_RISQ
			GROUP BY ti.id_tiers) indic_dtx
			,RS_CORRES_SGMT_BAL_TYPE_CLI SBT --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		WHERE T.ID_TIERS = sp.ID_TIERS_GARANT
		AND sp.ID_OPERATION = o.ID_OPERATION
		AND sp.CD_SYS_INT = o.CD_SYS_INT
		AND o.CD_SOC_JURI = sj.CD_SOC_JURI
		and nvl(T.CD_CATEG_CONTREPARTIE,'ECG12') = ptf.CD_CATEG_CONTREPARTIE (+)
		AND T.CD_NAF_REV2 = sa.CD_NAF_REV2 (+) --AFR le 09/03/2012 : BTR 6.2 Fiablisation code NAF
		AND T.id_tiers = indic_dtx.id_tiers (+)
		AND T.CD_FORM_JUR = fjc.CD_FORM_JUR (+)
		AND T.CD_TYPE_LIEN=tlg.CD_TYPE_LIEN(+)
		AND T.CD_TYPE_SGMT = 'CORP'
		AND sj.CD_CONSO_CPT_CRRV3 != '99999'
		AND sp.ID_TYPE_GARANTIE_CASA not like 'NOT%'
		AND NOT EXISTS (SELECT 1 FROM tie_tiers_c1_c5 ti
				WHERE ti.ID_TIERS = T.ID_TIERS
			AND   ti.CD_CONSO_CPT = sj.CD_CONSO_CPT_CRRV3
				AND   ti.CD_TYPE_RELATION = T.CD_ROLE_TIERS)
		AND T.CD_SEGMENT_CAL = SBT.CD_SEGMENT_CAL(+) --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		;
		COMMIT;

	-- MBO - 14/11/2018 : Mantis 45535 Debut
	-- MBO - 22/11/2018 : Ajout condition "portefeuille different de 999 dans le DTG
	  l_position := 'CORP : Ajust. DTG';
      W_TABLE :='tie_tiers_c1_c5 (3)';
	  MERGE INTO TIE_TIERS_C1_C5 TT
	  USING ( SELECT D.IDENT_CENTRAL_SI_CIBLE, D.IDENT_NATIONAL
					,D.PTF_BALE_TIERS, D.CATEGORIE_CONTREPARTIE
					,D.NOTATION_INTERNE, D.DT_NOTATION_INTERNE, D.METHOD_NOTATION, D.MOTIF_NOTATION, D.MOD_NOTATION
					,D.RUN
			  FROM SASNOTES.SIRIS_RETOUR_TIERS D
			  WHERE D.PTF_BALE_TIERS != '999'
			  AND D.RUN != '00370'  --KLx 10/12/2021 M59785
			) DTG
	  ON (   NVL(TT.ID_CENTRAL_TIERS, '000') = DTG.IDENT_CENTRAL_SI_CIBLE
		  OR NVL(TT.IDENT_NATIO, 'SIREN_TT') = NVL(DTG.IDENT_NATIONAL, 'SIREN_DTG')
		 )
	  WHEN MATCHED THEN UPDATE
		SET TT.CD_PORTEFEUILLE_BAL_TIERS = DTG.PTF_BALE_TIERS
		   ,TT.CD_CATEG_CONTREPARTIE     = DTG.CATEGORIE_CONTREPARTIE
		   ,TT.NOTE_INTERNE     = CASE WHEN DTG.DT_NOTATION_INTERNE > NVL(TT.DT_REVISION_NOTE, TO_DATE('01011900', 'DDMMYYYY'))
										 THEN DTG.NOTATION_INTERNE
										 ELSE TT.NOTE_INTERNE
								   END
		   ,TT.DT_REVISION_NOTE = CASE WHEN DTG.DT_NOTATION_INTERNE > NVL(TT.DT_REVISION_NOTE, TO_DATE('01011900', 'DDMMYYYY'))
										 THEN DTG.DT_NOTATION_INTERNE
										 ELSE TT.DT_REVISION_NOTE
								   END
		   ,TT.CD_METHODO_NOTE  = CASE WHEN DTG.DT_NOTATION_INTERNE > NVL(TT.DT_REVISION_NOTE, TO_DATE('01011900', 'DDMMYYYY'))
										 THEN NVL(DTG.METHOD_NOTATION, '999')
										 ELSE TT.CD_METHODO_NOTE
								   END
		   ,TT.CD_MOTIF_NOTE    = CASE WHEN DTG.DT_NOTATION_INTERNE > NVL(TT.DT_REVISION_NOTE, TO_DATE('01011900', 'DDMMYYYY'))
										 THEN NVL(DTG.MOTIF_NOTATION, '999')
										 ELSE TT.CD_MOTIF_NOTE
								   END
		   ,TT.CD_GRILLE_NOTE   = CASE WHEN DTG.DT_NOTATION_INTERNE > NVL(TT.DT_REVISION_NOTE, TO_DATE('01011900', 'DDMMYYYY'))
										 THEN NVL(DTG.MOD_NOTATION, '990001900010120090702FR')
										 ELSE TT.CD_GRILLE_NOTE
								   END
		   --,TT.CD_ENTITE_RUN    =
	  ;
	-- MBO - 14/11/2018 : Mantis 45535 Fin


		-- cas des tiers RETAIL (agr?gats)
		l_position := 'tiers RETA clients';
        W_TABLE :='tie_tiers_c1_c5 (4)';
		INSERT INTO tie_tiers_c1_c5 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  NOM_TIERS,
		  RAISON_SOCLE,
		  REF_IDENT_NATIO,
		  IDENT_NATIO,
		  CD_PAYS_NATIONALITE,
		  CD_PAYS_RESIDENCE,
		  CD_PAYS_CONTROLE,
		  ADRESSE,
		  VILLE,
		  CD_POSTAL,
		  DT_CLOTURE_CPT_NOTE,
		  NOTE_INTERNE,
		  DT_REVISION_NOTE,
		  DT_ENTREE_DEFAUT,
		  CD_METHODO_NOTE,
		  CD_MOTIF_NOTE,
		  CD_ENTITE_RUN,
		  CD_ENTITE_RMC,
		  CD_GRILLE_NOTE,
		  CD_CATEG_CONTREPARTIE,
		  CD_PORTEFEUILLE_BAL_TIERS,
		  CD_SEGMENT_CAL,
		  CD_SECTEUR_ACTIVITE,
		  CD_FILIERE,
		  CD_NORME_LOCAL_ACT,
		  CD_ACTIVITE_LOCALE,
		  CD_FORM_JUR,
		  CD_STATUT_FILIATION,
		  CD_TYPE_ACTEUR,
		  CD_TYPE_RELATION,
		  MNT_CA,
		  TOP_CA_CONSO,
		  CD_DEVISE_CA,
		  ANNEE_CA,
		  TOP_TIERS_DTX,
		  CD_TYPE_TIE
		   ,NBRE_JOUR_EXERCICE
		   ,NATURE_CA
		   ,NOTE_NAFA
		   ,TOT_BILAN_RETRAITE
		   ,CA_IFRS
		   ,RES_NET_RETRAITE_SIGN
		   ,RES_NET_RETRAITE_MNT
		   ,NOTE_APR_CORR_GRPE
		   ,AGENCE_NOTATION
		   ,COTATION
		   ,CD_TYPE_COTATION
		   ,DT_COTATION
		   ,STATUT_ACTIVITE_LOC
		   ,DT_STATUT_ACTIVITE_LOC
		   ,IDENT_NATION_2
		   ,RAIS_SOCL_KBIS
		   ,NOTE_CALC_FIN
		   ,CD_SECT_RISQ_SYST
		   ,CD_TYPE_SEGMENT
		   ,ID_AGREGAT
		   ,A_EXTRAIRE
		   ,NB_SALARIE -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
		   --04/01/2019 CDS Atos (SQN) US 615
		   ,ID_ENT_MERE_IMMEDIAT
		   ,IND_ENT_MERE_IMMEDIAT
		   ,CD_NUTS
		   ,ETAT_AVNCT_PJ
		   ,DT_OUV_PJ
		   --Fin SQN
			   ,REF_IDENT_NAT_2  -- 18/02/2019 - CDS ATOS (GBD) - US731
		   ,ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
		   -- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,IND_CEL
			,NIV_INTG_GROUPE_TIE
			,IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		  )
		SELECT   DISTINCT T.DT_ARRETE,
			sj.CD_CONSO_CPT_CRRV3,
			T.ID_TIERS,
			NULL id_tiers_calc,
			T.IDENT_SIRIS,
			DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO),
			DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO) raison_socle,
			'99' ref_ident_natio,
			NULL ident_natio,
			NVL(T.CD_PAYS_RESIDENCE,'FR'),
			NVL(T.CD_PAYS_RESIDENCE,'FR'),
			NVL(T.CD_PAYS_RESIDENCE,'FR'),
			NULL adresse,
			NULL VILLE,
			NULL CD_POSTAL,
			T.DT_CLOTURE_CPT_NOTE,
			nvl(T.NOTE_BALOISE,'ND') NOTE_INTERNE,
			--04/02/2019 CDS Atos (SQN) US 649 - it 2
			--T.DT_NOTE_BAL     DT_REVISION_NOTE,
			NVL(T.DT_NOTE_BAL, SYSDATE) DT_REVISION_NOTE,
			--Fin SQN
			--10/10/2018 CDS Atos (LFD) US 488
			CASE WHEN T.CD_CATEG_CPT in ('DTCO','DTX')  THEN T.DT_CHG_CATEG_CPT ELSE NULL END dt_entree_defaut,
			-- NULL DT_ENTREE_DEFAUT, -- case when t.CD_ENTITE_RMC = '00370' and t.DT_DEF_PAIEM_SORT = null then DT_ENTREE_DEFAUT end A REMETTRE LORSQU'ON ENVERRA LES NOTES
			--  FIN LFD
			nvl2(T.NOTE_BALOISE,T.CD_METHODE_NOTE,NULL) CD_METHODE_NOTE,
			nvl2(T.NOTE_BALOISE,T.CD_MOTIF_NOTE,NULL) CD_MOTIF_NOTE,
			T.CD_RUN,
			T.CD_ENTITE_RMC,
			CASE WHEN T.NOTE_BALOISE IS NOT NULL AND T.CD_GRILLE_NOTE IS NOT NULL THEN T.CD_GRILLE_NOTE
			   WHEN T.NOTE_BALOISE IS NOT NULL AND T.CD_GRILLE_NOTE IS NULL THEN '990001900010120090702FR'
			   ELSE NULL
			   END CD_GRILLE_NOTE,
			nvl(T.CD_CATEG_CONTREPARTIE,'ECG12'), -- HBO 05/10/2010 LotV5.4: La cat?gorie de contrepartie est r?cup?r?e de BTR
			T.CD_SEGMENT_CASA,
			T.cd_segment_cal,
			nvl(sa.CD_SECTEUR_ACTIVITE,'PP9902'), --'PP9900' cd_secteur_activite,
			NULL filiere,
			NULL cd_norm_local_act,
			----hl 45378 T.cd_naf_rev2 cd_activite_locale,
			T.cd_naf_rev2 cd_activite_locale,
			fjc.CD_FORM_JUR_CRRV3, --AGU 03/10/2008 Recette
			'5' cd_statut_filiation,
			T.CD_TYPE_ACTEUR,  -- AFR le 15/06/2012 Projet BTR 6.3 L01-C36-2 Passage IRBA provisions dans CRRV3
			T.CD_ROLE_TIERS,
			-- MBO - 20120829 : TaskForce FTCA V2 : cas des RETA laisser a NULL MNT_CA, TOP_CA_CONSO, DEVISE_CA et ANNEE_CA
			--05/02/2019 CDS Atos (SQN) US 649 - it 2
			--NULL mnt_ca,
			(CASE
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) > 100000000000 THEN NULL
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) < 0 THEN NULL
			  ELSE NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA)
			END) MNT_CA,
			--Fin SQN
			NULL top_ca_conso, -- AGU 03/11/2008 Retours homologation CASA
			NULL devise_ca, -- nvl2(t.MNT_CA,'EUR',NULL), -- AGU 31/03/2009 Retours homologation 8 CASA
			NULL annee_ca, --t.EXERCICE_CA, -- AGU 31/03/2009 Retours homologation 8 CASA
			top_tiers_dtx,
			T.CD_TYPE_SGMT
			 -- MBO - 20120828 : TaskForce FTCA V2 - Ajout des champs complement notes FNN
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.NBRE_JOUR_EXERCICE
			 ,NVL(T.NBRE_JOUR_EXERCICE, '0')
			 --Fin SQN
			 ,T.NATURE_CA
			 ,T.NOTE_NAFA
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.TOT_BILAN_RETRAITE
			 --,T.CA_IFRS
			 ,NVL(T.TOT_BILAN_RETRAITE, '0')
			 ,NVL(T.CA_IFRS, '0')
			 --Fin SQN
			 ,T.RES_NET_RETRAITE_SIGN
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.RES_NET_RETRAITE_MNT
			 ,NVL(T.RES_NET_RETRAITE_MNT, '0')
			 --Fin SQN
			 ,T.NOTE_APR_CORR_GRPE     -- Fin ajout champs
			 ,T.AGENCE_NOTATION
			 ,T.COTATION
			 ,T.CD_TYPE_COTATION
			 ,T.DT_COTATION
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.STATUT_ACTIVITE_LOC
			 ,NVL(T.STATUT_ACTIVITE_LOC, 'A')
			 --Fin SQN
			 ,T.DT_STATUT_ACTIVITE_LOC
			 ,T.IDENT_NATION_2
			 ,T.RAIS_SOCL_KBIS
			 ,T.NOTE_CALC_FIN
			 ,nvl(T.CD_SECT_RISQ_SYST,NVL(sa.CD_SECTEUR_ACTIVITE,'PP9902'))
			 ,'RETA'
			 ,null
			 ,'O'    --a extraire
			 , pack_utilitaire.F_CODE_EFFECTIF_NB_SALARIE(T.EFFECTIF) -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
			 --04/01/2019 CDS Atos (SQN) US 615
			 -- 13/05/2019 - CDS ATOS (LFD) - US 791
			 --,null
			 ,T.IDENT_SIRIS ID_ENT_MERE_IMMEDIAT
			   --,null
			 ,CASE WHEN T.IDENT_SIRIS IS NOT NULL THEN '1' END IND_ENT_MERE_IMMEDIAT
			 -- FIN LFD
			 ,PACK_UTILITAIRE.F_GET_CODE_NUTS(t.cd_postal,t.CD_PAYS_RESIDENCE )
			   --30/03/2020 CDS ATOS (SQN) US N3D 509
			 --,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' END
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' ELSE '1' END
			 --Fin SQN
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN T.DT_CHG_STATUT_RISQ END
			 --Fin SQN
				   , null  REF_IDENT_NAT_2 -- 18/02/2019 - CDS ATOS (GBD) - US731
			 ,CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
			-- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,'0' IND_CEL
			,'0' NIV_INTG_GROUPE_TIE
			,NULL IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,SBT.CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		FROM RS_CORRES_FORM_JUR_CAL_CRRV3 fjc,
		   BTR_TIERS T,
		   BTR_OPERATION o,
		   RS_SOCIETE_JURIDIQUE sj,
		   RS_CORRES_NAF_NORM_LOCAL_ACT sa,
		   (SELECT ti.id_tiers,MIN(CD_INDICATEUR_DOUTEUX) KEEP (DENSE_RANK FIRST ORDER BY priorite) top_tiers_dtx
			FROM BTR_TIERS ti,BTR_OPERATION oi,RS_CORRES_CATEG_RISQ_INDIC_DTX dtx
			WHERE ti.ID_TIERS = oi.ID_TIERS
			AND DECODE(oi.CD_STATUT_RISQ_OPE,'AJRST',oi.CD_STATUT_RISQ_OPE,ti.CD_CATEG_CPT) = dtx.CD_CATEG_RISQ
			GROUP BY ti.id_tiers) indic_dtx
			,RS_CORRES_SGMT_BAL_TYPE_CLI SBT --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		WHERE T.ID_TIERS = o.ID_TIERS
		AND o.CD_SOC_JURI = sj.CD_SOC_JURI
		AND T.id_tiers = indic_dtx.id_tiers (+)
		AND T.CD_FORM_JUR = fjc.CD_FORM_JUR (+)
		and T.CD_NAF_REV2 = sa.CD_NAF_REV2 (+)
		AND T.CD_TYPE_SGMT = 'RETA'
		AND T.CD_ROLE_TIERS = 'C'
		AND sj.CD_CONSO_CPT_CRRV3 != '99999'
		AND T.CD_SEGMENT_CAL = SBT.CD_SEGMENT_CAL(+) --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		;
		COMMIT;

		-- Tiers RETAIL qui ne sont que garants ==> ils ne sont pas dans btr_operation AGU 09/10/2008 Recette
        W_TABLE :='tie_tiers_c1_c5 (5)';
		INSERT INTO tie_tiers_c1_c5 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  NOM_TIERS,
		  RAISON_SOCLE,
		  REF_IDENT_NATIO,
		  IDENT_NATIO,
		  CD_PAYS_NATIONALITE,
		  CD_PAYS_RESIDENCE,
		  CD_PAYS_CONTROLE,
		  ADRESSE,
		  VILLE,
		  CD_POSTAL,
		  DT_CLOTURE_CPT_NOTE,
		  NOTE_INTERNE,
		  DT_REVISION_NOTE,
		  DT_ENTREE_DEFAUT,
		  CD_METHODO_NOTE,
		  CD_MOTIF_NOTE,
		  CD_ENTITE_RUN,
		  CD_ENTITE_RMC,
		  CD_GRILLE_NOTE,
		  CD_CATEG_CONTREPARTIE,
		  CD_PORTEFEUILLE_BAL_TIERS,
		  CD_SEGMENT_CAL,
		  CD_SECTEUR_ACTIVITE,
		  CD_FILIERE,
		  CD_NORME_LOCAL_ACT,
		  CD_ACTIVITE_LOCALE,
		  CD_FORM_JUR,
		  CD_STATUT_FILIATION,
		  CD_TYPE_ACTEUR,
		  CD_TYPE_RELATION,
		  MNT_CA,
		  TOP_CA_CONSO, -- AGU 03/11/2008 Retours homologation CASA
		  CD_DEVISE_CA,
		  ANNEE_CA,
		  TOP_TIERS_DTX,
		  CD_TYPE_TIE
		   -- MBO - 20120828 : TaskForce FTCA V2 - Ajout des champs complement notes FNN
		   ,NBRE_JOUR_EXERCICE
		   ,NATURE_CA
		   ,NOTE_NAFA
		   ,TOT_BILAN_RETRAITE
		   ,CA_IFRS
		   ,RES_NET_RETRAITE_SIGN
		   ,RES_NET_RETRAITE_MNT
		   ,NOTE_APR_CORR_GRPE     -- Fin ajout champs
		   ,AGENCE_NOTATION
		   ,COTATION
		   ,CD_TYPE_COTATION
		   ,DT_COTATION
		   ,STATUT_ACTIVITE_LOC
		   ,DT_STATUT_ACTIVITE_LOC
		   ,IDENT_NATION_2
		   ,RAIS_SOCL_KBIS
		   ,NOTE_CALC_FIN
		   ,CD_SECT_RISQ_SYST
		   ,CD_TYPE_SEGMENT
		   ,ID_AGREGAT
		   ,A_EXTRAIRE
			 ,NB_SALARIE -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
		   --04/01/2019 CDS Atos (SQN) US 615
		   ,ID_ENT_MERE_IMMEDIAT
		   ,IND_ENT_MERE_IMMEDIAT
		   ,CD_NUTS
		   ,ETAT_AVNCT_PJ
		   ,DT_OUV_PJ
		   --Fin SQN
			   ,REF_IDENT_NAT_2  -- 18/02/2019 - CDS ATOS (GBD) - US731
		   ,ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
		   -- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,IND_CEL
			,NIV_INTG_GROUPE_TIE
			,IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		   )
		SELECT  DISTINCT T.DT_ARRETE,
			sj.CD_CONSO_CPT_CRRV3,
			T.ID_TIERS,
			NULL id_tiers_calc,
			T.IDENT_SIRIS,
			DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO),
			DECODE(type_tiers,'M',T.RAISON_SOCLE,'I',T.RAISON_SOCLE,'P',T.NOM_PATRO) raison_socle,
			'99' ref_ident_natio,
			NULL ident_natio,
			NVL(T.CD_PAYS_RESIDENCE,'FR'),
			NVL(T.CD_PAYS_RESIDENCE,'FR'),
			NVL(T.CD_PAYS_RESIDENCE,'FR'),
			NULL adresse,
			NULL VILLE,
			NULL CD_POSTAL,
			T.DT_CLOTURE_CPT_NOTE,
			nvl(T.NOTE_BALOISE,'ND') NOTE_INTERNE, -- AGU 25/08/2010 Lot V5.3
			--04/02/2019 CDS Atos (SQN) US 649 - it 2
			--T.DT_NOTE_BAL,
			NVL(T.DT_NOTE_BAL, SYSDATE) DT_REVISION_NOTE,
			--Fin SQN
			--10/10/2018 CDS Atos (LFD) US 488
			CASE WHEN T.CD_CATEG_CPT in ('DTCO','DTX')  THEN T.DT_CHG_CATEG_CPT ELSE NULL END dt_entree_defaut,
			--NULL DT_ENTREE_DEFAUT,
			--FIN LFD
			DECODE(T.CD_RUN,'00370', T.CD_METHODE_NOTE,'999') CD_METHODE_NOTE,                 -- FHL 9642 : AFR le 13/08/2011
			nvl(T.CD_MOTIF_NOTE,'999') CD_MOTIF_NOTE,                                          -- FHL 9642 : AFR le 13/08/2011
			T.CD_RUN,
			T.CD_ENTITE_RMC,
			CASE WHEN T.NOTE_BALOISE IS NOT NULL AND T.CD_GRILLE_NOTE IS NOT NULL THEN T.CD_GRILLE_NOTE
			   WHEN T.NOTE_BALOISE IS NOT NULL AND T.CD_GRILLE_NOTE IS NULL THEN '990001900010120090702FR'
			   ELSE NULL
			   END CD_GRILLE_NOTE,
			nvl(T.CD_CATEG_CONTREPARTIE,'ECG12'), -- HBO 05/10/2010 LotV5.4: La cat?gorie de contrepartie est r?cup?r?e de BTR
			T.CD_SEGMENT_CASA,
			T.cd_segment_cal,
			nvl(sa.CD_SECTEUR_ACTIVITE,'ZZ0000'), --'PP9900' cd_secteur_activite,
			NULL filiere,
			NULL cd_norm_local_act,
			--HL 45378 T.cd_naf_rev2 cd_activite_locale,
			T.cd_naf_rev2 cd_activite_locale,
			fjc.CD_FORM_JUR_CRRV3, --AGU 03/10/2008 Recette
			'5' cd_statut_filiation,
			--NULL cd_type_acteur, -- AFR le 15/06/2012 Projet BTR 6.3 L01-C36-2 Passage IRBA provisions dans CRRV3
			T.CD_TYPE_ACTEUR, -- AFR le 15/06/2012 Projet BTR 6.3 L01-C36-2 Passage IRBA provisions dans CRRV3
			T.CD_ROLE_TIERS,
			-- MBO - 20120829 : TaskForce FTCA V2 : cas des RETA laisser a NULL MNT_CA, TOP_CA_CONSO, DEVISE_CA et ANNEE_CA
			--05/02/2019 CDS Atos (SQN) US 649 - it 2
			--NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA),
			(CASE
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) > 100000000000 THEN NULL
			  WHEN NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA) < 0 THEN NULL
			  ELSE NVL(TO_NUMBER(T.MNT_CA_DTG), T.MNT_CA)
			END) MNT_CA,
			--Fin SQN
			NULL top_ca_conso, -- AGU 03/11/2008 Retours homologation CASA
			NULL devise_ca, -- nvl2(t.MNT_CA,'EUR',NULL), -- AGU 31/03/2009 Retours homologation 8 CASA
			NULL annee_ca, --t.EXERCICE_CA, -- AGU 31/03/2009 Retours homologation 8 CASA
			top_tiers_dtx,
			T.CD_TYPE_SGMT
			 -- MBO - 20120828 : TaskForce FTCA V2 - Ajout des champs complement notes FNN
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.NBRE_JOUR_EXERCICE
			 ,NVL(T.NBRE_JOUR_EXERCICE, '0')
			 --Fin SQN
			 ,T.NATURE_CA
			 ,T.NOTE_NAFA
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.TOT_BILAN_RETRAITE
			 --,T.CA_IFRS
			 ,NVL(T.TOT_BILAN_RETRAITE, '0')
			 ,NVL(T.CA_IFRS, '0')
			 --Fin SQN
			 ,T.RES_NET_RETRAITE_SIGN
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.RES_NET_RETRAITE_MNT
			 ,NVL(T.RES_NET_RETRAITE_MNT, '0')
			 --Fin SQN
			 ,T.NOTE_APR_CORR_GRPE     -- Fin ajout champs
			 ,T.AGENCE_NOTATION
			 ,T.COTATION
			 ,T.CD_TYPE_COTATION
			 ,T.DT_COTATION
			 --04/02/2019 CDS Atos (SQN) US 649 - it 2
			 --,T.STATUT_ACTIVITE_LOC
			 ,NVL(T.STATUT_ACTIVITE_LOC, 'A')
			 --Fin SQN
			 ,T.DT_STATUT_ACTIVITE_LOC
			 ,T.IDENT_NATION_2
			 ,T.RAIS_SOCL_KBIS
			 ,T.NOTE_CALC_FIN
			 ,nvl(T.CD_SECT_RISQ_SYST,NVL(sa.CD_SECTEUR_ACTIVITE,'ZZ0000'))
			 ,'RETA'
			 ,null
			 ,'O'  --a extraire
			 , pack_utilitaire.F_CODE_EFFECTIF_NB_SALARIE(T.EFFECTIF) -- 28/05/2018 CDS Atos (JMP) ANACREDIT US346 Ajout du nombre basse de la tranche d'effectif NB_SALARIE
			 --04/01/2019 CDS Atos (SQN) US 615
			 -- 13/05/2019 - CDS ATOS (LFD) - US 791
			 --,null
			 ,T.IDENT_SIRIS ID_ENT_MERE_IMMEDIAT
			   --,null
			 ,CASE WHEN T.IDENT_SIRIS IS NOT NULL THEN '1' END IND_ENT_MERE_IMMEDIAT
			 -- FIN LFD
			 ,PACK_UTILITAIRE.F_GET_CODE_NUTS(t.cd_postal,t.CD_PAYS_RESIDENCE )
			   --30/03/2020 CDS ATOS (SQN) US N3D 509
			 --,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' END
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN '3' ELSE '1' END
			 --Fin SQN
			 ,case when (T.CD_STATUT_RISQ = 'PCO')  THEN T.DT_CHG_STATUT_RISQ END
			 --Fin SQN
				   , null  REF_IDENT_NAT_2 -- 18/02/2019 - CDS ATOS (GBD) - US731
			 ,CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC_BIS -- 01/03/2019 - CDS ATOS (LFD) - US 746
			-- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
			,'0' IND_CEL
			,'0' NIV_INTG_GROUPE_TIE
			,NULL IND_OPCVM_EFFET_LEV
			-- FIN LFD
			,SBT.CD_AGENT_ECO -- 29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_CET -- KLX-GOMESHU - BALE4 - 19/12/2023
			,CASE WHEN T.CD_SEGMENT_CASA IN ('040') THEN 'N' ELSE NULL END IND_RATIO_LEVIER -- KLX-GOMESHU - BALE4 - 19/12/2023
		FROM BTR_TIERS T,
		   BTR_OPERATION o,
		   btr_surete_pers sp,
		   RS_SOCIETE_JURIDIQUE sj,
		   RS_CORRES_NAF_NORM_LOCAL_ACT sa,
		   RS_CORRES_FORM_JUR_CAL_CRRV3 fjc,
		   (SELECT ti.id_tiers,MIN(CD_INDICATEUR_DOUTEUX) KEEP (DENSE_RANK FIRST ORDER BY priorite) top_tiers_dtx
			FROM BTR_TIERS ti,BTR_OPERATION oi,RS_CORRES_CATEG_RISQ_INDIC_DTX dtx
			WHERE ti.ID_TIERS = oi.ID_TIERS
			AND DECODE(oi.CD_STATUT_RISQ_OPE,'AJRST',oi.CD_STATUT_RISQ_OPE,ti.CD_CATEG_CPT) = dtx.CD_CATEG_RISQ
			GROUP BY ti.id_tiers) indic_dtx
			,RS_CORRES_SGMT_BAL_TYPE_CLI SBT --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		WHERE T.ID_TIERS = sp.ID_TIERS_GARANT
		AND sp.ID_OPERATION = o.ID_OPERATION
		AND sp.CD_SYS_INT = o.CD_SYS_INT
		AND o.CD_SOC_JURI = sj.CD_SOC_JURI
		AND T.id_tiers = indic_dtx.id_tiers (+)
		AND T.CD_FORM_JUR = fjc.CD_FORM_JUR (+)
		and T.CD_NAF_REV2 = sa.CD_NAF_REV2 (+)
		AND T.CD_TYPE_SGMT = 'RETA'
		  AND T.CD_ROLE_TIERS != 'C'
		AND sj.CD_CONSO_CPT_CRRV3 != '99999'
		AND sp.ID_TYPE_GARANTIE_CASA not like 'NOT%'
		AND NOT EXISTS (SELECT 1 FROM tie_tiers_c1_c5 ti
				WHERE ti.ID_TIERS = ID_TIERS
		  AND   ti.CD_CONSO_CPT = sj.CD_CONSO_CPT_CRRV3
				AND   ti.CD_TYPE_RELATION = T.CD_ROLE_TIERS)
		AND T.CD_SEGMENT_CAL = SBT.CD_SEGMENT_CAL(+) --29/04/2021 - CDS ATOS (LFD) - US 92 CRRV4.3
		;
		COMMIT;

		-- mise ? blanc des identifiant central dans le cas ou un identifiant central est attibu? ? plusieur tiers
		-- AGU 14/09/2009 Retours 12e homologation CASA
        W_TABLE :='tie_tiers_c1_c5 (6)';
		UPDATE tie_tiers_c1_c5
		set id_central_tiers = NULL
		WHERE id_central_tiers IN (SELECT ID_CENTRAL_TIERS FROM tie_tiers_c1_c5
					   WHERE id_central_tiers IS NOT NULL
					   GROUP BY ID_CENTRAL_TIERS
					   HAVING count(DISTINCT ID_TIERS_CALC)>1);
		COMMIT;

		--05/02/2019 CDS Atos (SQN) US 649 - it 2
        W_TABLE :='tie_tiers_c1_c5 (7)';
		UPDATE tie_tiers_c1_c5
		set DT_CLOTURE_CPT_NOTE = null
		WHERE NOTE_INTERNE = 'ND';
		COMMIT;
		--Fin SQN
			-- 18/02/2019 - CDS ATOS (GBD) - US731
			 --UPDATE tie_tiers_c1_c5  set  APPLI_SOURCE =  RPAD('C_DDR', 12) Where nvl(flag_hn,'N') <> 'N';
			 -- 18/02/2019 - CDS ATOS (GBD) - US731
		COMMIT;

		-- 23/04/2021 - CDS ATOS (LFD) - US 89 CRRV4.3
		W_TABLE :='tie_tiers_c1_c5 (8)';
		UPDATE tie_tiers_c1_c5
		set IND_OPCVM_EFFET_LEV = 'N'
		WHERE CD_CATEG_CONTREPARTIE in ('MCG31', 'MCG32', 'MCG41', 'MCG42', 'MCG43', 'MCG44');
		COMMIT;
		-- FIN LFD

	-- Gestion Watchlist
  	MERGE INTO ddrex.tie_tiers_c1_c5 C1_c5
  	USING (SELECT DISTINCT ID_TIERS, IND_WL, DATE_ENTREE_WL, DATE_SORTIE_WL, CD_TYPE_WL_CASA, CD_MOTIF_SORTIE_WL
         FROM BTR_WATCHLIST
        ) WL
     	ON (C1_c5.ID_TIERS = WL.ID_TIERS)
     	WHEN MATCHED THEN
         UPDATE set C1_c5.IND_WL = WL.IND_WL
         ,C1_c5.DATE_ENTREE_WL = WL.DATE_ENTREE_WL
         ,C1_c5.DATE_SORTIE_WL = WL.DATE_SORTIE_WL
         ,C1_c5.CD_TYPE_WL_CASA = WL.CD_TYPE_WL_CASA
         ,C1_c5.CD_MOTIF_SORTIE_WL = WL.CD_MOTIF_SORTIE_WL
         ;
	COMMIT;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_tie_tiers table:' || W_TABLE || ' -MESS:'||SQLERRM);
              pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_tie_tiers table:' || W_TABLE ||'- V4:'||l_position,50072);
	  END p_alim_tie_tiers_c1_c5;

	  ------------------------------------------------------
	  -- nom : procedure p_alim_Autorisation_F1               --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       Autorisation_F1                                --
	  -- auteur : A. Guilmart, le 20/01/2009              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 23/03/2010 : plus de filtre sur le systeme
	  --       de gestion pour constituer l'id_autorisation
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_alim_Autorisation_F1 IS

      W_TABLE VARCHAR2(20);

	BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		execute immediate 'TRUNCATE TABLE Autorisation_F1';

		-- MBO - 09052011 : Perim des autorisation : NUM_DEC de BTR_HORS_BILAN non NULL ou dossier KSP avec statut CDE
		--                  Ce perimetre est constitue dans AUT_COR_OPE_NUM_DEC_BIS (p_alim_aut_cor_ope_num_dec_bis)

        W_TABLE := 'Autorisation_F1 (1)';
		INSERT INTO Autorisation_F1   (
			DT_ARRETE,
			CD_CONSO_CPT,
			ID_TIERS_CALC,
			ID_CENTRAL_TIERS,
			ID_AUTORISATION,
			CD_TYPE_OPE,
			CD_OBJET_CREDIT,
			CD_HIERARCHIE_ACCORD,
			CD_CONFIRMATION_AUTO,
			MNT_GLOBAL_INITIAL,
			MNT_GLOBAL_REVISE,
			CD_DEVISE_AUTO,
			TOP_AUTO_SPECIFIQUE,
			DT_DEB_VALIDITE_AUTO,
			DT_LIM_TIRAGE_AUTO,
			DT_FIN_VALIDITE_AUTO,
			TOP_SYNDICATION,
			CD_POSITION_ENTITE_RISQUE,
			CD_ENTITE_GROUPE_PILOTE,
			TOP_TITRISATION,
			CD_NIV_SENIORITE,
			CD_SEGMENT_CASA,
			A_EXTRAIRE
			,REF_SYNDICATION	-- 08/11/2018 - CDS ATOS (LFD) - ANACREDIT US 552
			,APPLI_SOURCE -- 23/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 652
			,IND_POSITION_ENTITE--23/01/2019 CDS Atos (SQN) US 655
			,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,SYS_GEST_SRC -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
			)
		SELECT  DISTINCT
			hb.DT_ARRETE,
			s.CD_CONSO_CPT_CRRV3,
			CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC,
			T.IDENT_SIRIS	ID_CENTRAL_TIERS,
			'F1'|| nvl(NU.NUM_DEC_BIS, HB.id_operation)	ID_AUTORISATION, -- 07/10/2020 - Mantis 53910 plantage prod - HB.id_operation remplace O.id_operation
			'20'	CD_TYPE_OPE,
			'06'	CD_OBJET_CREDIT,
			nvl(ha.CD_HIERARCHIE_ACCORD,'09')	CD_HIERARCHIE_ACCORD,
			'2'	CD_CONFIRM_AUTO,
			CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE ELSE GREATEST(nvl(o.CRD_BRUT_HT,0), nvl(hb.MNT_ENGMT_FINANCMT_HB,0)) END MNT_GLOBAL_INITIAL,
			CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE ELSE GREATEST(nvl(o.CRD_BRUT_HT,0), nvl(hb.MNT_ENGMT_FINANCMT_HB,0)) END MNT_GLOBAL_REVISE,
			case when
				nvl(CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE ELSE GREATEST(nvl(o.CRD_BRUT_HT,0), nvl(hb.MNT_ENGMT_FINANCMT_HB,0)) END, 0) > 0
				then nvl(hb.CD_DEVISE,'EUR')
				ELSE 'EUR'
			END	CD_DEVISE,
			'N'	TOP_AUTO_SPECIFIQUE,
			CASE WHEN hb.DT_DEB_VALIDITE_AUTO > hb.DT_ARRETE THEN hb.dt_arrete - 1 ELSE hb.DT_DEB_VALIDITE_AUTO END DT_DEB_VALIDITE_AUTO,
			CASE WHEN hb.DT_FIN_VALIDITE_AUTO < hb.DT_ARRETE THEN to_date('30/06/9999','dd/mm/yyyy') ELSE hb.DT_FIN_VALIDITE_AUTO END dt_lim_tirage_auto,
			CASE WHEN hb.DT_FIN_VALIDITE_AUTO < hb.DT_ARRETE THEN to_date('30/06/9999','dd/mm/yyyy') ELSE hb.DT_FIN_VALIDITE_AUTO END dt_fin_validite_auto,
			DECODE(nvl(o.POSITION_CAL_POOL, 'X'), 'pool CDF', 'Y', 'N')	top_syndication,						--'N'   top_syndication, : LOT BTR6.8 MAI2014
			DECODE(nvl(o.POSITION_CAL_POOL, 'X'), 'pool CDF', 'C', ' ')	cd_position_entite_risque,					--NULL  cd_position_entite_risque, : LOT BTR6.8 MAI2014
			DECODE(nvl(o.POSITION_CAL_POOL, 'X'), 'pool CDF', S.CD_CONSO_CPT_CRRV3, ' ')	cd_entite_groupe_pilote,					--NULL  cd_entite_groupe_pilote, : LOT BTR6.8 MAI2014
			'N'   TOP_TITRISATION,
			'SEN' cd_niv_seniorite,
			hb.CD_SEGMENT_CASA,
			'O' A_EXTRAIRE
			,CASE WHEN o.id_operation in (select sy.id_operation from ident_syndication sy) then (select distinct sy.REF_SYNDICATION from ident_syndication sy where sy.id_operation = o.id_operation) END -- 08/11/2018 - CDS ATOS (LFD) - ANACREDIT US 552
			, 'C_BTR'  -- 23/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 652
			,CASE WHEN DECODE(nvl(o.POSITION_CAL_POOL, 'X'), 'pool CDF', 'Y', 'N') = 'Y' THEN 'L' END IND_POSITION_ENTITE--23/01/2019 CDS Atos (SQN) US 655
			,'AUTO01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,hb.CD_SYS_INT SYS_GEST_SRC  -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		FROM
			BTR_HORS_BILAN                 					hb,
			BTR_OPERATION                  					o,   -- MBO 11052011 : Ajout jointure pour gerer MNT_GLOBAL_INITIAL
			RS_SOCIETE_JURIDIQUE          				s,
			BTR_TIERS                      						T,
			RS_CORRES_TYP_ACCEP_HIERA_ACCO 	ha,
			AUT_COR_OPE_NUM_DEC_BIS        		NU
		WHERE
				hb.CD_SOC_JURI  					= s.cd_soc_juri
		  AND 	hb.ID_TIERS     					= T.ID_TIERS

		  --DEBUT: KLxRisqLeasing (BAL) - M63363: Anomalie F1 et F2 Autorisation et Ligne detail autorisation
		  --AND 	hb.CD_SYS_INT   				= NU.CD_SYS_INT (+)
		  --AND 	hb.ID_OPERATION 				= NU.ID_OPERATION (+)

		  AND 	o.CD_SYS_INT   						= NU.CD_SYS_INT (+)
		  AND 	o.ID_OPERATION 						= NU.ID_OPERATION (+)
		  --FIN: KLxRisqLeasing (BAL) - M63363: Anomalie F1 et F2 Autorisation et Ligne detail autorisation

		  AND 	hb.ID_TIERS     					= o.ID_TIERS (+)
		  AND 	hb.CD_SYS_INT   					= o.CD_SYS_INT (+)
		  AND 	hb.ID_OPERATION 					= o.ID_OPERATION (+)
		  AND 	hb.CD_TYPE_ACCEPTANT 				= ha.cd_type_acceptant (+)
		  AND 	T.CD_TYPE_SGMT        				= 'CORP'
		  AND 	s.CD_CONSO_CPT_CRRV3 				!= '99999'
		  ;
	COMMIT;

    W_TABLE := 'Autorisation_F1 (2)';
	MERGE INTO Autorisation_F1   p
		USING
				(
					select
						'F1'|| nvl(nu.NUM_DEC_BIS, Ope.id_operation)	ID_AUTORISATION,
						 nvl(ope.ENC_FINANC_BRUT,0)  						ENC_FINANC_BRUT,
						 ope.QP_POOL   												QPART,
						 ope.cd_devise   												CD_DEVISE
					from
						AUT_COR_OPE_NUM_DEC_BIS 	nu,
						btr_operation 							ope
					where
								ope.cd_sys_int 				= 		nu.cd_sys_int
						and 	ope.id_operation 			= 		nu.id_operation
						and 	nvl(ope.QP_POOL, 0) 	> 		1
				) REQ
		ON ( p.id_autorisation = REQ.ID_AUTORISATION)
		WHEN MATCHED THEN
			UPDATE SET
				P.MNT_INIT_GLOB_BANQ_TT_TRANCHES 		= 		DECODE(P.Top_Syndication, 'Y', ABS(REQ.ENC_FINANC_BRUT/REQ.QPART)*100, 0)
				,P.MNT_MAJ_GLOB_BANQ_TT_TRANCHES  		= 		DECODE(P.Top_Syndication, 'Y', ABS(REQ.ENC_FINANC_BRUT/REQ.QPART)*100, 0)
				--,P.CD_DEVISE_MNT_SYND_TT_TRANCHES 		= 		DECODE(P.Top_Syndication, 'Y', REQ.cd_devise, '')
				,P.CD_DEVISE_MNT_SYND_TT_TRANCHES 		= 		REQ.cd_devise -- M66813
				,P.MNT_INIT_GLOB_BANQ_TRANCHE_AUT 		= 		DECODE(P.Top_Syndication, 'Y', ABS(REQ.ENC_FINANC_BRUT/REQ.QPART)*100, 0)
				,P.MNT_MAJ_GLOB_BANQ_TRANCHE_AUT  		= 		DECODE(P.Top_Syndication, 'Y', ABS(REQ.ENC_FINANC_BRUT/REQ.QPART)*100, 0)
				--,P.CD_DEVISE_MNT_SYND_TRANCHE_AUT 		= 		DECODE(P.Top_Syndication, 'Y', REQ.cd_devise, '')
				,P.CD_DEVISE_MNT_SYND_TRANCHE_AUT 		= 		REQ.cd_devise -- M66813
				,P.TX_PART_RISK_TRANCHE 	        				= 		DECODE(P.Top_Syndication, 'Y',REQ.QPART, '')
	;
	COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
				 ROLLBACK;
                 DBMS_OUTPUT.PUT_LINE('Proc p_alim_Autorisation_F1 table:' || W_TABLE || ' -MESS:'||SQLERRM);
                 pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_Autorisation_F1 table:'|| W_TABLE,50072);

	END p_alim_Autorisation_F1;

	  ------------------------------------------------------
	  -- nom : procedure p_alim_AUT_DETAIL_F2               --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       AUTORISATION_DETAIL_F2                                --
	  -- auteur : A. Guilmart, le 08/09/2008              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 23/03/2010 : plus de filtre sur le systeme
	  --       de gestion pour constituer l'id_autorisation
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_alim_AUTORISATION_DETAIL_F2 IS

        W_TABLE VARCHAR2(30);

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		execute immediate 'TRUNCATE TABLE AUTORISATION_DETAIL_F2';
        W_TABLE := 'AUTORISATION_DETAIL_F2 (1)';
		INSERT INTO AUTORISATION_DETAIL_F2 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  ID_AUTORISATION,
		  ID_LIGNE_DET,
		  CD_TYPE_RISQUE,
		  MNT_AUTORISE_ORIGINE,
		  MNT_AUTORISE_REVISE,
		  MNT_AUTORISE_LIGNE,
		  CD_DEVISE_LIGNE_AUTO,
		  CD_METHODO_BALE2,
		  DT_DEB_VALIDITE_LIGNE,
		  DT_LIM_TIRAGE_LIGNE,
		  DT_FIN_VALIDITE_LIGNE,
		  DUREE_MAX_ENGMT,
		  CD_DEV_RESTRIC_LIGNE,
		  CD_LIQUIDITE_DEFAUT,
		  A_EXTRAIRE,
		  -- 29/11/2018 CDS ATOS (SQN) Mantis 45281 : Code moteur erron? pour P2 et F2
		  CD_MOTEUR
		  --Fin SQN
		  ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,SYS_GEST_SRC -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		  )
		SELECT  DISTINCT hb.DT_ARRETE,
			s.CD_CONSO_CPT_CRRV3,
			CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
			T.IDENT_SIRIS,
			'F1'|| nvl(nu.NUM_DEC_BIS, O.id_operation)   ID_AUTORISATION,
			'F2'|| nvl(nu.NUM_DEC_BIS, O.id_operation)   ID_LIGNE_DET,
			tr.CD_TYP_RISQ_CORP,
			CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE
			   ELSE GREATEST(o.CRD_BRUT_HT, hb.MNT_ENGMT_FINANCMT_HB) END MNT_AUTORIS_BRUT,
			CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE
			   ELSE GREATEST(nvl(o.CRD_BRUT_HT,0), nvl(hb.MNT_ENGMT_FINANCMT_HB,0)) END  MNT_AUTORISE_REVISE,
			-- avant recette IEC rectif sur montant revise qui doit etre egal au montant initial --
			--TRUNC(hb.MNT_ENGMT_FINANCMT_HB)                                                           MNT_AUTORISE_LIGNE,
			CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE
			   ELSE GREATEST(nvl(o.CRD_BRUT_HT,0), nvl(hb.MNT_ENGMT_FINANCMT_HB,0)) END  MNT_AUTORISE_LIGNE,
			-- IEC meme chose que pour Autorisation_F1
			--CASE WHEN TRUNC(nvl(hb.MNT_ENGMT_FINANCMT_HB, 0)) > 0 THEN hb.CD_DEVISE END               CD_DEVISE_LIGNE_AUTO,
			case when nvl(
			CASE WHEN nvl(hb.MNT_BRUT_ORIGINE, 0) > 0 THEN hb.MNT_BRUT_ORIGINE
			   ELSE GREATEST(nvl(o.CRD_BRUT_HT,0), nvl(hb.MNT_ENGMT_FINANCMT_HB,0)) END, 0) > 0 then hb.CD_DEVISE END    CD_DEVISE_LIGNE_AUTO,
			methodo.cd_method CD_METHODO_BALE2, --Mantis re7 5520
			CASE WHEN hb.DT_DEB_VALIDITE_AUTO > hb.DT_FIN_VALIDITE_AUTO THEN hb.DT_ARRETE - 1
										  ELSE hb.DT_DEB_VALIDITE_AUTO END DT_DEB_VALIDITE_LIGNE,
			CASE WHEN hb.DT_FIN_VALIDITE_AUTO < hb.DT_ARRETE THEN to_date('30069999','ddmmyyyy') ELSE hb.DT_FIN_VALIDITE_AUTO END dt_lim_tirage_ligne,
			CASE WHEN hb.DT_FIN_VALIDITE_AUTO < hb.DT_ARRETE THEN to_date('30069999','ddmmyyyy') ELSE hb.DT_FIN_VALIDITE_AUTO END dt_fin_validite_ligne,
			CASE WHEN hb.DT_FIN_VALIDITE_AUTO>hb.DT_DEB_VALIDITE_AUTO THEN hb.DT_FIN_VALIDITE_AUTO - hb.DT_DEB_VALIDITE_AUTO END  duree_max_engmt, -- AGU 02/07/2009 ajout du case
			NULL CD_DEV_RESTRIC_LIGNE,
			'0' cd_liquidite_defaut,
			'O' a_extraire,
			 -- 29/11/2018 CDS ATOS (SQN) Mantis 45281 : Code moteur erron? pour P2 et F2
			 methodo.trt_moteur
			 --Fin SQN
			 ,'AUTO02' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,hb.CD_SYS_INT SYS_GEST_SRC  -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		FROM BTR_HORS_BILAN                 hb,
			 BTR_OPERATION      o,
		   RS_SOCIETE_JURIDIQUE           s,
		   BTR_TIERS                      T,
		   RS_CORRES_PRD_FIN_TYP_RISQ_CRP tr,
		   AUT_COR_OPE_NUM_DEC_BIS        nu,
		   -- 29/11/2018 CDS ATOS (SQN) Mantis 45281 : Code moteur erron? pour P2 et F2
		   (SELECT CD_SOC_JURI, CD_SEGMENT, cd_method, trt_moteur ----Fin SQN (ajout trt_moteur)
			 FROM RS_METHO_BALE_SOC_SEG ) methodo
		WHERE hb.CD_SOC_JURI 		= s.cd_soc_juri
		AND hb.ID_TIERS      		= T.ID_TIERS
		AND hb.CD_PRODUIT    		= tr.CD_PRODUIT

		--DEBUT: KLxRisqLeasing (BAL) - M63363: Anomalie F1 et F2 Autorisation et Ligne detail autorisation
		--AND hb.CD_SYS_INT    		= nu.CD_SYS_INT (+)
		--AND hb.ID_OPERATION  		= nu.ID_OPERATION (+)

		AND o.CD_SYS_INT    		= nu.CD_SYS_INT (+)
		AND o.ID_OPERATION  		= nu.ID_OPERATION (+)
		AND hb.ID_TIERS     		= o.ID_TIERS (+)
		--FIN: KLxRisqLeasing (BAL) - M63363: Anomalie F1 et F2 Autorisation et Ligne detail autorisation

		and hb.CD_SYS_INT    		= o.CD_SYS_INT
		AND hb.ID_OPERATION  		= o.ID_OPERATION
		AND T.CD_TYPE_SGMT        	= 'CORP'
		AND s.CD_CONSO_CPT_CRRV3 	!= '99999'
		And T.CD_SEGMENT_CAL  		= methodo.CD_SEGMENT
		And s.cd_soc_juri     		= methodo.cd_soc_juri
		;

		COMMIT;

		-- AGU 08/06/2010 Rejet lot 00472 par CASA sur arr?te du 31/05/2010
        W_TABLE := 'AUTORISATION_DETAIL_F2 (2)';
		UPDATE AUTORISATION_DETAIL_F2 l
		set (MNT_AUTORISE_REVISE, MNT_AUTORISE_LIGNE, CD_DEVISE_LIGNE_AUTO) = (SELECT MNT_GLOBAL_INITIAL, MNT_GLOBAL_REVISE, CD_DEVISE_AUTO
											 FROM Autorisation_F1   A
											 WHERE A.ID_AUTORISATION = L.ID_AUTORISATION
											 AND A.ID_TIERS_CALC   = L.ID_TIERS_CALC
											 AND A.CD_CONSO_CPT    = L.CD_CONSO_CPT
											)
		WHERE MNT_AUTORISE_LIGNE IS NULL
		AND EXISTS (SELECT 1 FROM  Autorisation_F1 A
			  WHERE A.ID_AUTORISATION = L.ID_AUTORISATION
				AND A.ID_TIERS_CALC   = L.ID_TIERS_CALC
				AND A.CD_CONSO_CPT    = L.CD_CONSO_CPT
				AND A.MNT_GLOBAL_INITIAL IS NOT NULL) ;

		COMMIT;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_AUT_DETAIL_F2 table:' || W_TABLE || ' -MESS:'||SQLERRM);
             pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_AUT_DETAIL_F2 table:'||W_TABLE,50072);

	  END p_alim_AUTORISATION_DETAIL_F2;

	  ------------------------------------------------------
	  -- nom : procedure p_alim_Autorisation_F1_tech          --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       Autorisation_F1 avec les autorisations         --
	  --       techniques                                 --
	  -- auteur : A. Guilmart, le 20/01/2009              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 23/03/2010 : plus de filtre sur le systeme
	  --       de gestion pour constituer l'id_autorisation
	  --       pour KSP, on ne tient pas compte du top_eng
	  --       mais du statut de l'operation
	  ------------------------------------------------------
	  PROCEDURE p_alim_Autorisation_F1_tech IS

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		 DBMS_STATS.GATHER_TABLE_STATS('DDREX','SURETE_PERS',Estimate_Percent => NULL, CASCADE => TRUE);

		-- Autorisation technique ? partir des suretes personnelles
		-- MBO - 09052011 : prendre les SP hors perimetre definit dans AUT_COR_OPE_NUM_DEC_BIS
		INSERT INTO Autorisation_F1 (
		   DT_ARRETE,
		   CD_CONSO_CPT,
		   ID_TIERS_CALC,
		   ID_AUTORISATION,
		   CD_TYPE_OPE,
		   CD_OBJET_CREDIT,
		   CD_HIERARCHIE_ACCORD,
		   CD_CONFIRMATION_AUTO,
		   MNT_GLOBAL_INITIAL,
		   MNT_GLOBAL_REVISE,
		   CD_DEVISE_AUTO,
		   TOP_AUTO_SPECIFIQUE,
		   DT_DEB_VALIDITE_AUTO,
		   DT_LIM_TIRAGE_AUTO,
		   DT_FIN_VALIDITE_AUTO,
		   TOP_SYNDICATION,
		   CD_POSITION_ENTITE_RISQUE,
		   CD_ENTITE_GROUPE_PILOTE,
		   TOP_TITRISATION,
		   CD_NIV_SENIORITE,
		   CD_SEGMENT_CASA,
		   A_EXTRAIRE,
		   MNT_INIT_GLOB_BANQ_TT_TRANCHES,
		   MNT_MAJ_GLOB_BANQ_TT_TRANCHES,
		   CD_DEVISE_MNT_SYND_TT_TRANCHES,
		   MNT_INIT_GLOB_BANQ_TRANCHE_AUT,
		   MNT_MAJ_GLOB_BANQ_TRANCHE_AUT,
		   CD_DEVISE_MNT_SYND_TRANCHE_AUT
		   ,APPLI_SOURCE -- 23/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 652
		  --23/01/2019 CDS Atos (SQN) US 655
		   ,IND_POSITION_ENTITE
		   --Fin SQN
		   ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		   ,SYS_GEST_SRC -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		   )
		SELECT  dt_arrete,
			cd_conso_cpt_crrv3,
			id_tiers_calc,
			id_aut_tech,
			'20' cd_type_ope,
			'06' cd_objet_credit,
			CD_HIERARCHIE_ACCORD,
			'3' cd_confirm_auto,
			mnt_global_intial,
			mnt_global_revise,
			CASE WHEN nvl(mnt_global_intial,0)!=0 THEN nvl(CD_DEVISE,'EUR') ELSE 'EUR' END cd_devise,
			'N' top_auto_specifique,
			DT_DEB_VALIDITE_AUTO,
			DT_FIN_VALIDITE_AUTO,
			DT_FIN_VALIDITE_AUTO,
			DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', 'Y', 'N')   top_syndication,                                                  -- LOTMAI2014 BTR6.8
			DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', 'C', ' ')   cd_position_entite_risque,                                         -- LOTMAI2014 BTR6.8  NULL cd_position_entite_risque,
			DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', CD_CONSO_CPT_CRRV3, ' ')      cd_entite_groupe_pilote,                   --LOTMAI2014 BTR6.8  NULL cd_entite_groupe_pilote,
			'N' TOP_TITRISATION,
			--NULL cd_niv_seniorite, -- AGU 23/04/2010 Retours 1 homologation CASA Lot 5.2
			'SEN' cd_niv_seniorite,
			NULL cd_segment_casa,
			'O' a_extraire,
			0,
			0,
			'EUR', --M66813
			0,
			0,
			'EUR' --M66813
			,'C_BTR' -- 23/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 652
			--23/01/2019 CDS Atos (SQN) US 655
			,CASE WHEN DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', 'Y', 'N') = 'Y' THEN 'L' END IND_POSITION_ENTITE
			--Fin SQN
			,'AUTO01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,CD_SYS_INT SYS_GEST_SRC -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		FROM (SELECT  DISTINCT
					  o.DT_ARRETE,
					o.POSITION_CAL_POOL    ,
				s.CD_CONSO_CPT_CRRV3,
				CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
				'F1'|| o.ID_OPERATION                                                     ID_AUT_TECH, -- EVOL 02/2016 'F1P'||o.ID_OPERATION                                                     ID_AUT_TECH,
				CASE WHEN NU.CD_SYS_INT IS NULL THEN 1 ELSE 0 END                    NON_EXIST_AUTO,
				nvl(ha.CD_HIERARCHIE_ACCORD,'09')                                    CD_HIERARCHIE_ACCORD,
				DECODE(sum(nvl(o.mnt_expo_potent_ht,0)),0,1,sum(nvl(o.mnt_expo_potent_ht,0))) mnt_global_intial,
				DECODE(sum(nvl(o.mnt_expo_potent_ht,0)),0,1,sum(nvl(o.mnt_expo_potent_ht,0))) mnt_global_revise,
				nvl(sp.CD_DEVISE,'EUR')                                              CD_DEVISE,
				CASE WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_FIN_OPE THEN o.DT_ARRETE - 1
				   WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_ARRETE THEN o.DT_ARRETE - 1 -- AGU 23/04/2010 Retour 1 homolagation
				   ELSE nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE)
				END DT_DEB_VALIDITE_AUTO,
				CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE THEN to_date('30/06/9999','dd/mm/yyyy') ELSE o.DT_FIN_OPE END DT_FIN_VALIDITE_AUTO
				,O.CD_SYS_INT -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
			FROM BTR_OPERATION                  o,
			   surete_pers                    sp,
			   RS_SOCIETE_JURIDIQUE           s,
			   BTR_TIERS                      T,
			   RS_CORRES_TYP_ACCEP_HIERA_ACCO ha,
			   AUT_COR_OPE_NUM_DEC_BIS        nu -- Lot5.5: Autorisations techniques
			WHERE o.CD_SOC_JURI  = s.cd_soc_juri
			AND o.ID_TIERS       = T.ID_TIERS
			AND T.cd_role_tiers  = 'C'
			AND sp.ID_ENGAGEMENT = o.ID_OPERATION
			AND sp.CD_CONSO_CPT  = s.CD_CONSO_CPT_CRRV3
			AND o.CD_TYPE_ACCEPTANT = ha.cd_type_acceptant (+)
			AND o.CD_SYS_INT        = nu.CD_SYS_INT   (+)
			AND o.ID_OPERATION      = nu.ID_OPERATION (+)
			AND T.CD_TYPE_SGMT        = 'CORP'
			and s.CD_CONSO_CPT_CRRV3 != '99999'
			GROUP BY o.DT_ARRETE, o.POSITION_CAL_POOL,
				s.CD_CONSO_CPT_CRRV3,
				CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END,
				'F1'|| o.ID_OPERATION ,                                                   --EVOL 02/2016 'F1P'||o.ID_OPERATION,
				CASE WHEN NU.CD_SYS_INT IS NULL THEN 1 ELSE 0 END,
				nvl(ha.CD_HIERARCHIE_ACCORD,'09'),
				nvl(sp.CD_DEVISE,'EUR'),
				CASE WHEN nvl(o.DT_DEB_VALIDITE_AUTO, o.DT_DEB_OPE) > o.DT_FIN_OPE THEN o.DT_ARRETE - 1
				   WHEN nvl(o.DT_DEB_VALIDITE_AUTO, o.DT_DEB_OPE) > o.DT_ARRETE  THEN o.DT_ARRETE - 1 -- AGU 23/04/2010 Retour 1 homolagation
				   ELSE nvl(o.DT_DEB_VALIDITE_AUTO, o.DT_DEB_OPE)
				END,
				CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE THEN to_date('30/06/9999','dd/mm/yyyy') ELSE o.DT_FIN_OPE END
				,O.CD_SYS_INT -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		   ) perim
		WHERE perim.NON_EXIST_AUTO = 1
		  AND not exists (select id_autorisation from autorisation_f1 f1p where f1p.id_autorisation=perim.ID_AUT_TECH);

		COMMIT;

		DBMS_STATS.GATHER_TABLE_STATS('DDREX','SURETE_REELLE',Estimate_Percent => NULL, CASCADE => TRUE);

		-- Autorisation technique ? partir des suretes reelles
		-- Tjrs une autorisation technique pour un SR (avec NUM_DEC_BIS si dans perimetre sinon ID_OPERATION)
	  /** Modif tempo le 03/03/2016
		INSERT INTO Autorisation_F1 (
		   DT_ARRETE,
		   CD_CONSO_CPT,
		   ID_TIERS_CALC,
		   ID_AUTORISATION,
		   CD_TYPE_OPE,
		   CD_OBJET_CREDIT,
		   CD_HIERARCHIE_ACCORD,
		   CD_CONFIRMATION_AUTO,
		   MNT_GLOBAL_INITIAL,
		   MNT_GLOBAL_REVISE,
		   CD_DEVISE_AUTO,
		   TOP_AUTO_SPECIFIQUE,
		   DT_DEB_VALIDITE_AUTO,
		   DT_LIM_TIRAGE_AUTO,
		   DT_FIN_VALIDITE_AUTO,
		   TOP_SYNDICATION,
		   CD_POSITION_ENTITE_RISQUE,
		   CD_ENTITE_GROUPE_PILOTE,
		   TOP_TITRISATION,
		   CD_NIV_SENIORITE,
		   CD_SEGMENT_CASA,
		   A_EXTRAIRE,
		   MNT_INIT_GLOB_BANQ_TT_TRANCHES,
		   MNT_MAJ_GLOB_BANQ_TT_TRANCHES,
		   CD_DEVISE_MNT_SYND_TT_TRANCHES,
		   MNT_INIT_GLOB_BANQ_TRANCHE_AUT,
		   MNT_MAJ_GLOB_BANQ_TRANCHE_AUT,
		   CD_DEVISE_MNT_SYND_TRANCHE_AUT)
		SELECT  dt_arrete,
			cd_conso_cpt_crrv3,
			id_tiers_calc,
			id_aut_tech,
			'20' cd_type_ope,
			'06' cd_objet_credit,
			CD_HIERARCHIE_ACCORD,
			'3' cd_confirm_auto,
			mnt_global_intial,
			mnt_global_revise,
			CASE WHEN nvl(mnt_global_intial,0)!=0 THEN nvl(CD_DEVISE,'EUR') ELSE 'EUR' END CD_DEVISE,
			'N' top_auto_specifique,
			DT_DEB_VALIDITE_AUTO,
			DT_FIN_VALIDITE_AUTO,
			DT_FIN_VALIDITE_AUTO,
			DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', 'Y', 'N')   top_syndication,
			DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', 'C', ' ')   cd_position_entite_risque,
			DECODE(nvl(POSITION_CAL_POOL, 'X'), 'pool CDF', CD_CONSO_CPT_CRRV3, ' ')      cd_entite_groupe_pilote,
			'N' TOP_TITRISATION,
			--NULL cd_niv_seniorite, -- AGU 23/04/2010 Retours 1 homologation CASA Lot 5.2
			'SEN' cd_niv_seniorite,
			NULL cd_segment_casa,
			'O' a_extraire,
			0,
			0,
			'',
			0,
			0,
			''
		FROM (SELECT  DISTINCT o.DT_ARRETE, o.POSITION_CAL_POOL,
				s.CD_CONSO_CPT_CRRV3,
				CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC,
				'F1R'|| NVL(NU.NUM_DEC_BIS, o.ID_OPERATION)               ID_AUT_TECH,    --EVOL 02/2016 'F1R'|| NVL2(NU.CD_SYS_INT, NU.NUM_DEC_BIS, o.ID_OPERATION)               ID_AUT_TECH,
				nvl(ha.CD_HIERARCHIE_ACCORD,'09')                                         CD_HIERARCHIE_ACCORD,
				DECODE(sum(sr.mnt_initial),0,NULL,sum(sr.mnt_initial))      mnt_global_intial,
				DECODE(sum(sr.mnt_initial),0,NULL,sum(sr.mnt_initial))      mnt_global_revise,
				nvl(sr.cd_devise,'EUR')                                                   CD_DEVISE,
				CASE WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_FIN_OPE THEN o.DT_ARRETE - 1
				   WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_ARRETE THEN o.DT_ARRETE - 1 -- AGU 23/04/2010 Retour 1 homolagation
				   ELSE nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE)
				END DT_DEB_VALIDITE_AUTO,
				CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE THEN to_date('30/06/9999','dd/mm/yyyy') ELSE o.DT_FIN_OPE END DT_FIN_VALIDITE_AUTO
			FROM BTR_OPERATION                  o,
			   surete_reelle                  sr,
			   RS_SOCIETE_JURIDIQUE           s,
			   BTR_TIERS                      T,
			   RS_CORRES_TYP_ACCEP_HIERA_ACCO ha,
			   AUT_COR_OPE_NUM_DEC_BIS        NU -- Lot 5.5 : Autorisations techniques
			WHERE o.CD_SOC_JURI    = s.cd_soc_juri
			AND o.ID_TIERS       = T.ID_TIERS
			and T.cd_role_tiers  = 'C'
			AND sr.ID_ENGAGEMENT = o.ID_OPERATION
			AND sr.CD_CONSO_CPT  = s.CD_CONSO_CPT_CRRV3
			AND o.CD_TYPE_ACCEPTANT = ha.cd_type_acceptant (+)
			AND o.CD_SYS_INT        = NU.CD_SYS_INT   (+)
			AND o.ID_OPERATION      = NU.ID_OPERATION (+)
			AND T.CD_TYPE_SGMT        = 'CORP'
			and s.CD_CONSO_CPT_CRRV3 != '99999'
			GROUP BY o.DT_ARRETE, o.POSITION_CAL_POOL ,
				s.CD_CONSO_CPT_CRRV3,
				CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END,
				 'F1R'|| NVL(NU.NUM_DEC_BIS, o.ID_OPERATION),                             --EVOL 02/2016 'F1R'|| NVL2(NU.CD_SYS_INT, NU.NUM_DEC_BIS, o.ID_OPERATION),
				nvl(ha.CD_HIERARCHIE_ACCORD,'09'),
				nvl(sr.cd_devise,'EUR'),
				CASE WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_FIN_OPE THEN o.DT_ARRETE - 1
				   WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_ARRETE THEN o.DT_ARRETE - 1 -- AGU 23/04/2010 Retour 1 homolagation
				   ELSE nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE)
				END,
				CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE THEN to_date('30/06/9999','dd/mm/yyyy') ELSE o.DT_FIN_OPE END
		   ) perim ;
	  ****/
		COMMIT;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_Autorisation_F1_tech -MESS:'||SQLERRM);
			 pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_Autorisation_F1_tech',50072);
	  END p_alim_Autorisation_F1_tech;

	  ------------------------------------------------------
	  -- nom : procedure p_alim_AUT_DETAIL_F2_tech        --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       AUTORISATION_DETAIL_F2 avec les            --
	  --       autorisations techniques                   --
	  -- auteur : A. Guilmart, le 20/01/2009              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 23/03/2010 : plus de filtre sur le systeme
	  --       de gestion pour constituer l'id_autorisation
	  --       pour KSP, on ne tient pas compte du top_eng
	  --       mais du statut de l'operation
	  ------------------------------------------------------
	  PROCEDURE p_alim_AUT_DETAIL_F2_tech IS

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		-- MBO 06052011 : doit etre traiter apres p_alim_Autorisation_F1_tech : a besoin des Auto Tech de Autorisation_F1
		-- Ligne technique ? partir des suretes personnelles (F1P)
		   INSERT INTO AUTORISATION_DETAIL_F2 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS_CALC,
		  ID_AUTORISATION,
		  ID_LIGNE_DET,
		  CD_TYPE_RISQUE,
		  MNT_AUTORISE_ORIGINE,
		  MNT_AUTORISE_REVISE,
		  MNT_AUTORISE_LIGNE,
		  CD_DEVISE_LIGNE_AUTO,
		  CD_METHODO_BALE2,
		  DT_DEB_VALIDITE_LIGNE,
		  DT_LIM_TIRAGE_LIGNE,
		  DT_FIN_VALIDITE_LIGNE,
		  DUREE_MAX_ENGMT,
		  CD_DEV_RESTRIC_LIGNE,
		  CD_LIQUIDITE_DEFAUT,
		  A_EXTRAIRE,
		  -- 25/01/2019 CDS-ATOS (TMN) Mantis 45281 : Code moteur erron? pour P2 et F2
		  CD_MOTEUR
		  --Fin SQN
		  ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,SYS_GEST_SRC -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
          ,ID_ENGAGEMENT -- KLX (VDC) - 22/11/2022 - Mantis 64079 - Ajout alimentation de l id_engagement pour les lignes tech...
		  )
		SELECT DISTINCT o.DT_ARRETE,
			 s.CD_CONSO_CPT_CRRV3,
			 CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
			 'F1'|| O.id_operation id_aut_tech,     --EVOL 02/2016 'F1P'||sp.ID_ENGAGEMENT id_aut_tech,
			'F2'|| O.id_operation      id_ligne_det, -- EVOL 02/2016'F2'||sp.ID_SURETE      id_ligne_det,
			 tr.CD_TYP_RISQ_CORP,
			 ac.MNT_GLOBAL_INITIAL mnt_autorise_origine,
			 ac.MNT_GLOBAL_REVISE  mnt_autorise_revise,
			 ac.MNT_GLOBAL_REVISE mnt_autorise_ligne,
			 CASE WHEN nvl(ac.MNT_GLOBAL_REVISE,0)!=0 THEN o.CD_DEVISE END cd_devise_ligne_auto,
			 methodo.cd_method CD_METHODO_BALE2, --Mantis re7 5520
			 CASE WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_FIN_OPE THEN o.DT_ARRETE - 1
			  ELSE nvl(o.DT_DEB_VALIDITE_AUTO +1 ,o.DT_DEB_OPE +1)
			 END dt_deb_validite_ligne,
			 CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE +1 THEN o.DT_ARRETE ELSE o.DT_FIN_OPE -1 END dt_lim_tirage_ligne,
			 CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE +1 THEN o.DT_ARRETE ELSE o.DT_FIN_OPE -1 END dt_fin_validite_ligne,
			 --NULL duree_max_engmt, -- AGU 23/04/2010 Retours 1 homologation CASA
			 CASE WHEN o.DT_FIN_OPE>nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) THEN o.DT_FIN_OPE - nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) END duree_max_engmt,
			 NULL CD_DEV_RESTRIC_LIGNE,
			 NULL cd_liquidite_defaut,
			 'O' a_extraire,
			 -- 25/01/2019 CDS-ATOS (TMN) Mantis 45281 : Code moteur erron? pour P2 et F2
			 methodo.trt_moteur
			,'AUTO02' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,o.CD_SYS_INT -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
            ,sp.ID_ENGAGEMENT -- KLX (VDC) - 22/11/2022 - Mantis 64079 - Ajout alimentation de l id_engagement pour les lignes tech...
		FROM BTR_OPERATION                  o,
		  -- surete_pers                    sp,
		(select CD_CONSO_CPT,ID_ENGAGEMENT,id_autorisation , sum(MNT_INITIAL) MNT_INITIAL  from surete_pers group by CD_CONSO_CPT,ID_ENGAGEMENT,id_autorisation           ) sp,
		   RS_SOCIETE_JURIDIQUE           s,
		   BTR_TIERS                      T,
		   RS_CORRES_PRD_FIN_TYP_RISQ_CRP tr,
		   (SELECT cd_conso_cpt
			  ,id_autorisation
			  ,MNT_GLOBAL_INITIAL
			  ,MNT_GLOBAL_REVISE
			FROM Autorisation_F1
			where substr(id_autorisation, 1, 2) = 'F1' ) ac,   -- Prendre les Auto Tech F1P (deja dans Autorisation_F1)
			 -- 25/01/2019 CDS-ATOS (TMN) Mantis 45281 : Code moteur erron? pour P2 et F2 -- Ajout trt_moteur
			(SELECT CD_SOC_JURI, CD_SEGMENT, cd_method, trt_moteur FROM RS_METHO_BALE_SOC_SEG) methodo
		WHERE o.CD_SOC_JURI      = s.cd_soc_juri
		  AND o.ID_TIERS         = T.ID_TIERS
		  AND sp.ID_ENGAGEMENT   = o.ID_OPERATION
		  AND sp.CD_CONSO_CPT    = s.CD_CONSO_CPT_CRRV3
		  AND o.CD_PRODUIT       = tr.CD_PRODUIT
		  AND T.CD_TYPE_SGMT     = 'CORP'
		  AND ac.ID_AUTORISATION = REPLACE(sp.ID_AUTORISATION, 'F1P', 'F1')
		  AND ac.cd_conso_cpt    = sp.CD_CONSO_CPT
		  And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
		  And s.cd_soc_juri     = methodo.cd_soc_juri
		and not exists (select CD_CONSO_CPT,    ID_TIERS_CALC,          ID_LIGNE_DET
				  from autorisation_detail_f2 f2 where f2.cd_conso_cpt=sp.CD_CONSO_CPT and f2.id_tiers_calc=CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END
				  and f2.ID_LIGNE_DET='F2'|| O.id_operation      )
		  ;

		COMMIT;

	  /********* Modif tempo 03/03/2016
		-- Ligne technique ? partir des suretes reelles (F1R)
		INSERT INTO AUTORISATION_DETAIL_F2 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS_CALC,
		  ID_AUTORISATION,
		  ID_LIGNE_DET,
		  CD_TYPE_RISQUE,
		  MNT_AUTORISE_ORIGINE,
		  MNT_AUTORISE_REVISE,
		  MNT_AUTORISE_LIGNE,
		  CD_DEVISE_LIGNE_AUTO,
		  CD_METHODO_BALE2,
		  DT_DEB_VALIDITE_LIGNE,
		  DT_LIM_TIRAGE_LIGNE,
		  DT_FIN_VALIDITE_LIGNE,
		  DUREE_MAX_ENGMT,
		  CD_DEV_RESTRIC_LIGNE,
		  CD_LIQUIDITE_DEFAUT,
		  A_EXTRAIRE)
		SELECT DISTINCT o.DT_ARRETE,
			 s.CD_CONSO_CPT_CRRV3,
			 CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END ID_TIERS_CALC,
			 'F1R'||O.ID_OPERATION     ID_AUT_TECH,    --EVOL 02/2016 'F1R'|| sr.ID_ENGAGEMENT ID_AUT_TECH,
			'F2'|| O.ID_OPERATION      ID_LIGNE_DET,     -- EVOL 02/2016 'F2'|| sr.ID_SURETE      ID_LIGNE_DET,
			 tr.CD_TYP_RISQ_CORP,
			 ac.MNT_GLOBAL_INITIAL MNT_AUTORISE_ORIGINE,
			 ac.MNT_GLOBAL_REVISE  MNT_AUTORISE_REVISE,
			 sr.MNT_INITIAL MNT_AUTORISE_LIGNE,
			 CASE WHEN nvl(sr.MNT_INITIAL,0)!=0 THEN o.CD_DEVISE END CD_DEVISE_LIGNE_AUTO,
			 methodo.cd_method CD_METHODO_BALE2, --Mantis re7 5520
			 CASE WHEN nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) > o.DT_FIN_OPE THEN o.DT_ARRETE - 1
			  ELSE nvl(o.DT_DEB_VALIDITE_AUTO +1,o.DT_DEB_OPE +1)
			 END  DT_DEB_VALIDITE_LIGNE,
			 CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE THEN to_date('29/06/9999','dd/mm/yyyy')
							  ELSE o.DT_FIN_OPE END DT_LIM_TIRAGE_LIGNE,
			 CASE WHEN o.DT_FIN_OPE < o.DT_ARRETE THEN to_date('29/06/9999','dd/mm/yyyy')
							  ELSE o.DT_FIN_OPE END                   DT_FIN_VALIDITE_LIGNE,
			--NULL duree_max_engmt, -- AGU 23/04/2010 Retours 1 homologation CASA
			 CASE WHEN o.DT_FIN_OPE>nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE)
				 THEN o.DT_FIN_OPE - nvl(o.DT_DEB_VALIDITE_AUTO,o.DT_DEB_OPE) END     DUREE_MAX_ENGMT,
			 NULL CD_DEV_RESTRIC_LIGNE,
			 NULL CD_LIQUIDITE_DEFAUT,
			 'O'  A_EXTRAIRE
		FROM BTR_OPERATION                  o,
		   surete_reelle                  sr,
		   RS_SOCIETE_JURIDIQUE           s,
		   BTR_TIERS                      T,
		   RS_CORRES_PRD_FIN_TYP_RISQ_CRP tr,
		   (SELECT CD_CONSO_CPT
			  ,id_autorisation
			  ,MNT_GLOBAL_INITIAL
			  ,MNT_GLOBAL_REVISE
			FROM Autorisation_F1
			where substr(id_autorisation, 1, 2) = 'F1' ) ac,   -- Prendre les Auto Tech F1R (deja dans Autorisation_F1)
			(SELECT CD_SOC_JURI,
			CD_SEGMENT,
			cd_method
		   FROM RS_METHO_BALE_SOC_SEG
			) methodo
		WHERE o.CD_SOC_JURI      = s.cd_soc_juri
		  AND o.ID_TIERS         = T.ID_TIERS
		  AND sr.ID_ENGAGEMENT   = o.ID_OPERATION
		  AND sr.CD_CONSO_CPT    = s.CD_CONSO_CPT_CRRV3
		  AND o.CD_PRODUIT       = tr.CD_PRODUIT
		  AND T.CD_TYPE_SGMT     = 'CORP'
		  AND ac.ID_AUTORISATION = REPLACE(sr.ID_AUTORISATION, 'F1R', 'F1')
		  AND ac.CD_CONSO_CPT    = sr.CD_CONSO_CPT
		  And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
		  And s.cd_soc_juri     = methodo.cd_soc_juri
		  ;
	  *********/
		COMMIT;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_AUT_DETAIL_F2_tech -MESS:'||SQLERRM);
			 pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'p_alim_AUT_DETAIL_F2_tech',50072);

	  END p_alim_AUT_DETAIL_F2_tech;

	  ------------------------------------------------------
	  -- nom : procedure p_alim_aut_echeancier            --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       AUT_ECHEANCIER                             --
	  -- auteur : A. Guilmart, le 08/09/2008              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 23/03/2010 : plus de filtre sur le systeme
	  --       de gestion pour constituer l'id_autorisation
	  --       et l'id_ligne_det; pour KSP, on ne tient pas compte
	  --       du top_eng mais du statut de l'operation
	  ------------------------------------------------------
	  PROCEDURE p_alim_aut_echeancier IS

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		execute immediate 'TRUNCATE TABLE AUT_ECHEANCIER';

		-- MBO - 09052011 : Le perimetre est celui des autorisations (AUT_CHAPEAU sans autorisations techniques)
		INSERT INTO AUT_ECHEANCIER (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_AUTORISATION,
		  ID_LIGNE_DET,
		  MNT_CRD,
		  CD_DEVISE,
		  DT_FIN_TRIM, -- DT_DEB_TRIM AGU 06/10/2009 recette
		  A_EXTRAIRE)
		SELECT  DISTINCT E.DT_ARRETE,
			CD_CONSO_CPT_CRRV3,
			'F1'|| nu.NUM_DEC_BIS   id_autorisation,
			'F2'|| nu.NUM_DEC_BIS   id_ligne_det,
			E.MNT_CRD,
			nvl2(E.MNT_CRD, hb.CD_DEVISE, NULL),
			E.DT_FIN_TRIM,
			'O'  --a extraire
		FROM BTR_ECHEANCIER          E,
		   BTR_HORS_BILAN          hb,
		   RS_SOCIETE_JURIDIQUE    s,
		   BTR_TIERS               T,
		   AUT_COR_OPE_NUM_DEC_BIS nu
		WHERE E.CD_SYS_INT    = hb.CD_SYS_INT
		  AND E.ID_OPERATION  = hb.ID_OPERATION
		  AND hb.CD_SOC_JURI  = s.CD_SOC_JURI
		  AND hb.ID_TIERS     = T.ID_TIERS
		  AND hb.CD_SYS_INT   = nu.CD_SYS_INT
		  AND hb.ID_OPERATION = nu.ID_OPERATION
		  AND flag_hb_ope         = 'H' -- flag indiquant que l'operation est en HB (flag a retravaille cote BTR : MBO - 09052011)
		  AND CD_CONSO_CPT_CRRV3 != '99999'
		  AND T.CD_TYPE_SGMT      = 'CORP'
		  AND E.DT_FIN_TRIM      >= E.DT_ARRETE ; -- AGU 17/12/2008 Retours 3 Homologation CASA

		COMMIT;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_aut_echeancier -MESS:'||SQLERRM);
			  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_aut_echeancier',50072);
	  END p_alim_aut_echeancier;



	  ------------------------------------------------------
	  -- nom : procedure p_alim_eng_encours_corporate     --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       ENG_ENCOURS_CORPORATE                      --
	  -- auteur : A. Guilmart, le 08/09/2008              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 24/02/2010 : HL 43378 + suppression filtre
	  --       sur le systeme de gestion pour constituer
	  --        l'id_autorisation pour KSP, on ne tient pas
	  --       compte du top_eng mais du statut de l'operation
	  -- ELAMLKEL - 02/08/2012 : FHL 50439 : ajout nouvelle colonne MNT_EXPO_POTENT pour prendre en compte encours + eng HB
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_alim_eng_encours_corporate IS    --   Domaine p1
        W_TABLE VARCHAR2(150);

		BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
      DBMS_OUTPUT.PUT_LINE( 'p_alim_eng_encours_corporate Debut : ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

          W_TABLE := 'ENG_CORP_P1 (1)';
		  execute immediate 'truncate table ENG_CORP_P1';
		  --30/11/2017 - CDS ATOS (EMM) - Sprint 1 - US 27
		  -- purge de la table d'historisation pour l'arrete en cours
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
          W_TABLE := 'HIS_FORB_BTR_OPERATION';
		  DELETE FROM HIS_FORB_BTR_OPERATION WHERE DT_ARRETE = (SELECT DISTINCT
		  (DT_ARRETE) FROM BTR_OPERATION);
		  COMMIT;
		  --Alimentation de la table d'historisation des forbearance de BTR_OPERATION
		  INSERT INTO HIS_FORB_BTR_OPERATION (ID_OPERATION, CD_SYS_INT, DT_ARRETE,
		  CD_AQR, DT_AQR, CD_AQR_FORCE, DT_AQR_FORCE, DT_FIN_VALID_AQR)
		  SELECT ID_OPERATION, CD_SYS_INT,
		  DT_ARRETE, CD_AQR, DT_AQR, CD_AQR_FORCE, DT_AQR_FORCE, DT_FIN_VALID_AQR
		  FROM BTR_OPERATION;
		  COMMIT;
		  -- Fin EMM
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

          W_TABLE := 'ENG_CORP_P1 (2)';
		  INSERT INTO ENG_CORP_P1   (
					  DT_ARRETE,
					  CD_CONSO_CPT,
					  ID_TIERS_CALC,
					  ID_CENTRAL_TIERS,
					  ID_AUTORISATION,
					  ID_LIGNE_DET,
					  ID_ENGAGEMENT,
					  CD_METHODO_BALE2,
					  CD_TYPE_RISQUE,
					  CD_PORTEFEUILLE_BOOKING,
					  CD_LIGNE_METIER,
					  CD_PORTEFEUILLE_BALE2,
					  CD_NATURE_OPE,
					  DT_DEBUT_ENG,
					  DT_FIN_ENG,
					  MNT_RISQUE,
					  CD_DEVISE_CRD,      ---new
					  MNT_CRD,            ---new
					  PCCO_CRD,           ---new
					  PCCO_MNT_CRD,       ---new
					  PCCO_MNT_SOLDE,
					  PCCO_INT_RD,
					  CD_DEVISE_MNT_RISQ,
					  PCEC_MNT_RISQUE,
					  CD_STATUT_OPE_DT_SOLDE,
					  MNT_ICNE,
					  PCEC_ICNE,
					  CD_DEVISE_ICNE,
					  MNT_VR,
					  CD_DEVISE_VR,
					  TOP_ENG_DOUTEUX,
					  DT_ENG_DOUTEUX,
					  TOP_ACCORD_FUSION,
					  MNT_EXPOSITION,
					  MNT_EXPO_POTENT, -- FHL 50439
					  CD_DEVISE_EXPO,
					  CD_CPT_ACTIF_IAS,
					  MNT_CPT_ACTIF_PCIAS,
					  TOP_RESTRUCTURATION,
					  DT_RESTRUCTURATION,
					  TX_LGD_PREDICTIF,  -- AG 23/01/2008
					  TX_LGD_PREDICTIF_LOCAL, -- AG 23/01/2008
					  A_EXTRAIRE,
					  DT_ACQ_DERN_PART_OPC,
					  TX_CONV_HB,
					  MNT_EAD_TOT,
					  DEVISE_EAD,
					  TOP_ENG,
					  MATURITE_EFF,
					  MNT_LOY_RD,
					  MNT_INT_RD,
					  TX_TRC,
					  CODE_TRAIT_MOTEUR,
					  CODE_TRAIT_GRR,
					  MNT_VTR_PDR,
					  MNT_HYPOTHEQUE,
					  CD_CIRCUIT_DISTRIB,
					  CD_USAGE_BIEN_IMM,
					  CD_DEV_HYPOTH,
					  CD_DEV_VTR,
					  MNT_SOLD_K_A,
					  MNT_SOLDE,
					  CD_DEVISE_SOLDE,
					  CD_IMP_PRUDENT,
					  CD_RESPECT_COND,
					  MNT_FIN_PERIODE,
					  CD_ARR_PAIEMENT,
					  MNT_VTR,
					  CD_ACHAT_FIN_LOC,
					  IND_PROD_ECH,
					  IND_OBJ_MET_PAL,
					  IND_ECH_FOUR,
					  TYPE_AMOR_CAP,
					  PRD_AMOR_CAP,
					  PRD_PMT_INT,
					  MOD_REMB_CRE,
					  DATE_FIN_DIFF_AMOR,
					  PRD_REV_TAUX_UNIT_TMP,
					  PRD_REV_TAUX_NBR,
					  DEVI_CAP_THEO_REST,
					  IND_PRE_POST_FIX,
					  CENTRE_RES,
					  -- Nouveau champs ajout?s
					  EVENMT_CRDT,
					  nat_cont_evenmt_crdt,
					  sta_crdt,
					  ind_cre_perf,
					  date_der_rest_comm,
					  date_der_rest_rsq,
					  REF_UNIQ_CONT,
					  REF_UNIQ_ELEM_CONT,
					  TYPE_TAUX,
					  DATE_PREM_ECH,
					  BASE_CAL_INT,
					  DATE_PREM_DEB_FOND,
					  DEV_MONTANT_DEB,
					  CAP_THEO_REST,
					  DT_EXIGTE_PREM_IMPY,
					  DATE_DEB_PALL,
					  DATE_FIN_PALL,
					  MNT_ECH_EN_COURS,
					  DEVI_MNT_ECH_EN_COURS,
					  DATE_DEB_ENG_RENVL,
					  ELI_OUT_MUT_PROV,
					  SYS_GEST_SRC,
					  ZONE_APP_COMP,
					  IND_REF,
					  TAUX_MRG_ADD,
					  TAUX_CLT_PRD_EN_CRS,
					  taux_clt_oct,
					  taux_int_eff_ori ,
					  ind_act_dep_ori,
					  DATE_PREM_ACT_FORB, --30/11/2017 CDS ATOS (EMM)
					  DATE_SORT_EFF_FORB, --30/11/2017 CDS ATOS (EMM)
					  DATE_ENTR_PER_PURG, --26/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					  DATE_SORT_PER_PURG, --26/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					  DATE_ENTR_PER_PROB, --26/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					  DATE_SORT_PER_PROB, --26/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					  DATE_THEO_FIN_FORB
					  , --26/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					  --01/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
					  MNT_CONTRAT_ORIGINE, -- Montant du contrat  l'origine
					  DEV_MNT_CONTRAT_ORIGINE, -- Devise du montant du contrat  l'origine
					  DT_PASSAGE_DOUTEUX_COMPROMIS -- Date de passage en douteux compromis
					  -- fin FAD
					  -- 24/01/2018 CDS Atos (JMP) ANACRIT US33
					  , CD_MOTIF_SCO_LC0267
					  -- 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					  , MNT_PREM_DBLQ_FONDS
					  , DT_PREM_DBLQ_FONDS
					  , DEVISE_PREM_DBLQ_FONDS
					  -- Fin 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					  --05/02/2019 - CDS ATOS (SQN) US 662
					  , DT_PL_NPL
					  , BUCKET_IFRS9
					  , DT_DISPO_FONDS
					  , CD_PAYS_JURIDICTION
					  , DT_SIGNATURE
					  , NB_JOURS_RETARD
					  , MNT_IDEMNITE_RES
					  , CD_DEV_MNT_INDEMNITE
					  --Fin SQN
					  -- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
					  , IND_OPE_EFFET_LEVIER
					  --Fin SQN
					  -- 18/02/2019 - CDS ATOS (GBD) - US731 -->
					  , ORGA_NOTATION_ORIG
					  , IND_RMB_ANTICIPE
					  , ELIGIB_PRUDENT_VAL
					  --, IND_MOBIL_ACTIF--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
					  -- 18/02/2019 - CDS ATOS (GBD) - US731 <--
					  -- 26/11/2020 - CDS ATOS (CPD) - US17
					  , MNT_SUBV_HT
					  , MNT_AVP_HT
					-- fin CPD
					-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
					,IND_ELIGI_OUTI_CTRAL_ANACRD
					,MOTIF_EXCLU_ANACREDIT
					,MNT_ENG_DT_SIGN_CTRT
					,IND_RESPO_SOLIDAIRE
					-- FIN LFD
					--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
					,IND_MOBIL_ACTIF
					,ELIG_MOB_BANQUE_CENTRALE
					,REF_MOB_ACTIF
					,CD_ORGA_MOBIL
					-- 23/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
					--,IND_ELIGB_ACTIF_IMM_BC
					-- Fin CPD
					-- FIN MNE
					--CDS_ATOS (LFD) - 18/06/2021 - US 91 CRRV4.3
					,CD_COMMUNE_BIEN_FINAN
					,CD_PAYS_BIEN_FINAN
					-- FIN LFD
					--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
					,CD_TYPE_PROD_BANCAIRE
					--FIN MNE
					--,IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
					-- BALE4
					,MOTIF_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.22
					,DT_DEBUT_MRTR-- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.23
					,DUREE_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.29
					,STATUT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.25
					,IND_MRTR_LEGISLATIF -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.26
					,IND_MRTR_CONTRACTUEL -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.27
					,CHAMP_APPL_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.28
					,MNT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.30
					,DEV_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.31
					,IND_EXPO_ADC  -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.39
					,LTV_RATIO -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 22.43
					,ETV_RATIO -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.43
					,IND_INVEST_CAPITAL_RISQ -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.57
					,IND_INVEST_PROG_LEGISLATIF -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.58
					,IND_TITRE_PARTICIP -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.79
					,IND_OPE_AVEC_RECOURS -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.88
					,USAGE_BIEN_FINANCE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 8.13
					,COMMUNE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.71
					,NUM_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.72
					,EXTENSION -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.73
					,TYPE_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.74
					,LIB_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.75
					,LIEU_DIT -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.76
					,LATITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.77
					,LONGITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.78
					,IND_UCC -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.66
					,CLASS_CPT_ELEMENT_COUV_DERIVE -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.80
					,NIV_RISQUE_CRR3 -- KLX-GOMESHU - BALE4 - 22/01/2024 - P1 21.68
					,CD_TYPE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.86
					,CD_EMPLACE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.87
					,TX_DSCR						-- BALE4 - P1 21.81
					,TX_DSCR_PREC					-- BALE4 - P1 21.82
					,IND_ACCORD_NETTING    -- KLX-GOMESHU - BALE4 - 30/04/2024 - P1 30.23
					,MNT_ACQUISITION       -- KLX-BARTOLMI - QDD - Mantis 71368
                    ,CDTYPEGARPRINCOCTROI  -- P1 31.21
					,CD_METH_IFRS9_PD_ORIG -- projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
			  )
			  SELECT  DISTINCT   o.dt_arrete,
					s.CD_CONSO_CPT_CRRV3,
					CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
					T.IDENT_SIRIS,
					CASE WHEN NU.CD_SYS_INT is not null then 'F1'|| nvl(NU.NUM_DEC_BIS, O.id_operation) END  ID_AUTORISATION,
					CASE WHEN NU.CD_SYS_INT is not null then 'F2'|| nvl(NU.NUM_DEC_BIS, O.id_operation) END  ID_LIGNE_DET,
					o.ID_OPERATION,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--methodo.cd_method cd_methodo_bale2,
					NVL(methodo.cd_method, 'STD') CD_METHODO_BALE2,
					--Fin SQN
					pf.CD_TYP_RISQ_CORP,
					'B' cd_portefeuille_booking,
					'MLE00' cd_ligne_metier,
					'900', --DECODE(methodo.cd_method, 'NON IRB', ' ', '900'),         mantis re7 5520
					--pcec.nato_crd cd_nature_ope,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE  WHEN bien.CD_STATUT_ACT='ATNL' THEN 'NAT05'
					--    WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')          THEN 'NA012'
					--       WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
					--       WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
					--       WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
					--       END cd_nature_ope,
					NVL(CASE  WHEN bien.CD_STATUT_ACT='ATNL' THEN 'NAT05'
						  WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')          THEN 'NA012'
						  WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
						  WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
						  WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
					  END, 'NA020') CD_NATURE_OPE,
					--Fin SQN
					CASE WHEN o.DT_DEB_OPE >= o.DT_ARRETE THEN o.DT_ARRETE - 1
									ELSE o.DT_DEB_OPE
					END  DT_DEBUT_ENG,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--o.DT_FIN_OPE ,
					NVL(o.DT_FIN_OPE, to_date('99990630','YYYYMMDD')) DT_FIN_ENG,
					--o.CRD_BRUT_HT,
					NVL(o.CRD_BRUT_HT,0) MNT_RISQUE,
					--Fin SQN
					NVL(o.CD_DEVISE, 'EUR'),      --  CD_DEVISE_CRD,      ---new  -- 18/02/2019 - CDS ATOS (GBD) - US731
					-- 18/01/21 - CDS ATOS (LFD) - Mantis 55571
					--o.CRD_BRUT_HT ,
					CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE401' THEN o.CRD_BRUT_HT + nvl(o.MNT_SOLDE_HT_EXIGIB_K_T,0) + nvl(o.MNT_SOLDE_HT_EXIGIB_I_T,0) + nvl(o.MNT_SOLDE_HT_EXIGIB_AUTRE_T,0)
					ELSE o.CRD_BRUT_HT
					END MNT_CRD,    --    MNT_CRD,            ---new
					-- FIN LFD
					pcec.CD_PCEC_CRD,  --      PCCO_CRD,           ---new
					pcec.CD_PCEC_CRD,   --     PCCO_MNT_CRD,       ---new
					pcec.CD_PCEC_K_A,
					pcec.CD_PCEC_I,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--o.CD_DEVISE,
					NVL((CASE WHEN (NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0)) <> null THEN o.CD_DEVISE END),'EUR') CD_DEVISE_MNT_RISQ,
					--Fin SQN
					pcec.CD_PCEC_CRD,
					o.CD_STATUT_OPE_DT_SOLDE,
					o.MNT_ICNE,
					pcec.CD_PCEC_ICNE,
					o.CD_DEVISE,
					decode(substr(pf.CD_TYP_RISQ_CORP,1,4),'TRE5',o.MNT_VR,NULL) mnt_vr,
					--11/02/2019 - CDS ATOS (SQN) US 654
					--o.cd_devise,
					NVL(o.cd_devise,'EUR'), --CD_DEVISE_VR
					--Fin SQN
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END top_eng_douteux,
					--'N' TOP_ENG_DOUTEUX,  --US41
					-- FIN LFD
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN T.DT_CHG_CATEG_CPT END DT_ENG_DOUTEUX,
					CASE WHEN (CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END = 'Y')
					  THEN NVL((CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN T.DT_CHG_CATEG_CPT END),o.dt_arrete)
					  ELSE null
					END DT_ENG_DOUTEUX,
					--FIN SQN
					--null DT_ENG_DOUTEUX,  --US41
					-- FIN LFD
					' ' top_accord_fusion,
					o.MNT_EXPO_COURANTE_HT- nvl(hb.mnt_iec,0),      -- mont expo
					o.MNT_EXPO_POTENT_HT - nvl(hb.mnt_iec,0),              -- FHL 50439    mnt_expo_potent
					o.CD_DEVISE,
					null cd_cpt_actif_ias, --'L'||'&'||'R' cd_cpt_actif_ias, -- on est oblig? de d?couper la chaine ? cause du '&'
					NULL mnt_cpt_actif_pcias,
					-- CASE WHEN o.CD_AQR IN ('C2', 'C3A') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN 'RF' WHEN o.CD_AQR IN ('C4', 'C3B') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN 'RC' END top_restructuration,
					-- M52619 : TOP_RESTRUCTURATION appliquer la meme regle en vigueur pour le cas RETA (CD_TYPE_RESTRUCT de CREDIT_P3)
					--CDS_ATOS (MNE) - 20/05/2021 - Mantis 57292 - Eevolution de la rÃ¿Â¿Â½gle de gestion pour restructuration
					/*
					CASE WHEN o.cd_aqr in ('C2','C3A') AND T.cd_categ_cpt in ('DTX', 'DTCO')     THEN 'RF'
						 WHEN o.cd_aqr in ('C2','C3A') AND T.cd_categ_cpt not in ('DTX', 'DTCO') THEN 'RC'
						 WHEN o.cd_aqr in ('C4')       AND T.cd_categ_cpt not in ('DTX', 'DTCO') THEN 'AR' */
					CASE 	WHEN O.CD_AQR IN ('C4') 																								THEN 'AR'
							WHEN O.CD_AQR IN ('C3A') AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR 	THEN 'RC'
							WHEN O.CD_AQR IN ('C2')  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')															THEN 'RF' -- M70812
							--WHEN O.CD_AQR IN ('C2') OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')															THEN 'RF' --
					--FIN MNE
						 ELSE NULL
					END AS TOP_RESTRUCTURATION,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN o.CD_AQR IN ('C2', 'C3A','C4', 'C3B') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN o.DT_AQR END dt_restructuration,
					CASE WHEN o.CD_FLAG_RESTRUCTURATION in ('RCOM','RISQ') THEN o.DT_MAJ_FLAG_RESTRUCT ELSE null END DT_RESTRUCTURATION,
					--Fin SQN
					o.TX_LGD_PREDICTIF, -- AGU 23/01/2009
					CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE o.TX_LGD_PREDICTIF_LOCAL END, -- AGU 23/01/2009
					'O' a_extraire,
					''  DT_ACQ_DERN_PART_OPC,
					(Select T1.TX_CONV_HB From RE_TAUX_CONV_HB T1 Where T1.CD_CANAL_APPORT=o.CD_CANAL_APPORT And  T1.CD_SOC_JURI=o.CD_SOC_JURI And  T1.CD_PRODUIT =o.CD_PRODUIT ),
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE (O.MNT_EAD_TOT - nvl(hb.mnt_iec,0)) END,  -- L01-C35-4 CRR Lot BTR 6.8 mantis rec util 2946
					CASE WHEN nvl((CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE (O.MNT_EAD_TOT - nvl(hb.mnt_iec,0)) END),0) <0 THEN 0
						 ELSE nvl((CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE (O.MNT_EAD_TOT - nvl(hb.mnt_iec,0)) END),0)
					END MNT_EAD_TOT,
					--Fin SQN
					Nvl(O.Cd_Devise, 'EUR') ,
					--CASE WHEN methodo.CD_METHOD in ('IRBA','IRB AS')  THEN  -- Mantis recette 5520 obligatoire si IRBA ou IRB AS'
					--11/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN O.TOP_ENG IN ('O','G') THEN 'H' ELSE 'B' END  TOP_ENG,
					--12/06/2019 - CDS_ATOS(CML) - Mantis 48221
					--NVL((CASE WHEN O.TOP_ENG IN ('O','G') THEN 'H' ELSE 'B' END),'B'), --TOP_ENG
					NVL((CASE WHEN O.TOP_ENG IN ('O') THEN 'H' ELSE 'B' END),'B'), --TOP_ENG
					--fin Mantis 48221
					--O.MATURITE_CALC,
					NVL(O.MATURITE_CALC,0), --MATURITE_EFF
					--Fin SQN
					O.MNT_LOY_RD,
					--11/02/2019 - CDS ATOS (SQN) US 654
					--O.MNT_INT_RD,
					NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) , --MNT_INT_RD
					--Fin SQN
					CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE o.TX_TRC END,
					--'01',
					--06/02/2019 - CDS ATOS (SQN) US 654
					--methodo.trt_moteur,
					--'N',
					NVL(methodo.trt_moteur, '01') CODE_TRAIT_MOTEUR, -- M56405 change code moteur de 07 Ã¿Â¿Â½ 01
					'Y' CODE_TRAIT_GRR,
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null), --MNT_VTR_PDR
					CASE
					WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
					THEN nvl((decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null)),0)
					ELSE null
					END MNT_VTR_PDR,
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null), --MNT_HYPOTHEQUE
					CASE
					WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
					THEN nvl((decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null)),0)
					ELSE null
					END MNT_HYPOTHEQUE,
					--Fin SQN
					'CL',
					decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0') CD_USAGE_BIEN_IMM,
					--11/02/2019 - CDS ATOS (SQN) US 654
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ') CD_DEV_HYPOTH,
					CASE
					  WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
					  THEN decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ')
					  ELSE null
					END CD_DEV_HYPOTH,
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ') CD_DEV_VTR,
					CASE
					  WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
					  THEN decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ')
					  ELSE null
					END CD_DEV_VTR,
					--Fin SQN
					NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0),
					NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) ,
					case when o.mnt_solde_ht_cpt_cli = 0 then null else o.CD_DEVISE end CD_DEVISE_SOLDE,
					--MODIF 30/11/2015            nvl((Case when o.dt_arrete - o.dt_exigte_prem_impy > 180 then 'Y' else case when o.dt_arrete - o.dt_exigte_prem_impy > 90 and T.CD_SEGMENT_CAL not in ('08','09','10','11') then 'Y' END end), 'N')   CD_IMP_PRUDENT,
					CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END CD_IMP_PRUDENT,
					'Y', --decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','Y',' ') CD_RESPECT_COND,
					decode(substr(pf.CD_TYP_RISQ_CORP,1,4),'TRE5',o.MNT_VR,NULL) MNT_FIN_PERIODE,
					CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN 'Y' ELSE 'N' END,
					--0, -- MNT_VTR
					-- M65476
                    CASE WHEN substr(pf.CD_TYP_RISQ_CORP,1,6) in ('TRE502','PRI105') AND s.CD_CONSO_CPT_CRRV3='00472' THEN
                        COALESCE( bien.MNT_VV_ACT, bien.MNT_ACQ_HT_ACT * 0.7 , bien.mnt_revise)
					ELSE 0
                    END MNT_VTR,
					-- M65476
					-- --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
					-- --CASE WHEN substr(pf.CD_TYP_RISQ_CORP,1,6)='TRE502' THEN '1' ELSE '2'END,
					-- CASE
					-- WHEN (substr(pf.CD_TYP_RISQ_CORP,1,6) in ('TRE502', 'PRI105')) AND  s.cd_conso_cpt_crrv3 = '00472'
					-- -- WHEN substr(pf.CD_TYP_RISQ_CORP,1,6) in ('TRE501', 'TRE502', 'PRI105') -- M56278 : nouvelle regle Gestion du CD_ACHAT_FIN_LOC
					-- -- pour M56278 mettre partout l'inverse : THEN '2' ELSE '1' END
					-- THEN '1'
					-- --18/03/19 CDS ATOS (EMM) Mantis 47094
					-- --ELSE CASE
					--   --WHEN  substr(pf.CD_TYP_RISQ_CORP,1,6) in ('PRI105', 'TRE501')
					-- --    THEN '2'
					-- --      ELSE '0'
					-- 	  ELSE '2'
					-- --     END
					-- END  CD_ACHAT_FIN_LOC,
					-- --Fin EMM
					-- --Fin
					--'2' as CD_ACHAT_FIN_LOC,   -- M56278 (note 194976): nouvelle regle
					--DEBUT: KLxRisqLeasing (BA) - Mantis 59562: RWA GreenLease - evolution CRRV4 Leasing
					decode(o.cd_type_modele, 'GLES', '1', '2') as CD_ACHAT_FIN_LOC,
					--FIN: KLxRisqLeasing (BA) - Mantis 59562: RWA GreenLease - evolution CRRV4 Leasing
					'ECH',
					'N',
					'N',
					'L',
					'M',
					'M',
					'1',
					NULL,
					'M',
					1,
					'EUR',
					'E',
					'LEASING',
					-- Nouveaux champs
					CASE WHEN (o.cd_flag_restructuration is null OR  o.cd_flag_restructuration = 'SANS') Then '2' ELSE '1' END,
					--- M59263
					CASE
						WHEN o.cd_flag_restructuration = 'RCOM' THEN
						    CASE  -- Mantis 60739 - Changement de note pour les autres quand le CD_FLAG_RESTRUCTURATION = RCOM
						    	WHEN o.CD_AQR in ('C2','C3A') AND  o.TOP_PL_NPL = 'N' THEN '1'  --- M59263
								WHEN o.CD_AQR = 'C4' and o.TOP_PL_NPL = 'P' THEN '4' -- 12/01/2023 - KLX Risque (VDC) - Mantis 65154 - '4' si CD_AQR = 4 et top performant/non performant est P
								ELSE '5' -- 06/04/22 - KLX Risque (VDC) - Mantis 60739 - Tous les cas "autres" sont desormais mis a 5
						    END --- M59263
						WHEN o.cd_flag_restructuration = 'RISQ' THEN DECODE(o.CD_AQR,'C2','1','C3A','1','5')
						ELSE '5'
					END  nat_cont_evenmt_crdt,  -- M59263
					--29/03/2018 CDS ATOS (EMM) Sprint 7 US 218 ANACREDIT
					--DECODE(o.TOP_PL_NPL,'N','1','P','2','4'), --ancienne implementation
                    CASE 	WHEN O.CD_AQR IN ('C4') 																								THEN '4' -- AR
							WHEN O.CD_AQR IN ('C3A') AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR 	THEN '1'
							WHEN O.CD_AQR IN ('C2')  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')															THEN '1'
						 ELSE '4'
					END AS sta_crdt,--M72564  - Modification regle alimentation STA_CRDT
					/*CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN '1'
						ELSE -- 07/09/2020 - CDS ATOS (LFD) - US 89 taiga MCO - ACR/CRR - Si TOP_ENG_DOUTEUX = 'Y' ' et donc si CD_CATEG_CPT IN ('DTX','DTCO') alors STA_CRDT = '1'
							CASE WHEN o.TOP_PL_NPL = 'N' then '1'
							else
					  			CASE WHEN o.TOP_PL_NPL = 'P' AND o.dt_fin_valid_aqr > o.dt_arrete then '2'
					  			else
									CASE WHEN o.TOP_PL_NPL = 'P' AND o.dt_fin_valid_aqr <= o.dt_arrete then '3'
									else '4'
									end
					  			end
					 		end -- 07/09/2020 - CDS ATOS (LFD) - US 89 taiga MCO
					END sta_crdt, */
					--Fin EMM
						CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'NP' ELSE DECODE(o.TOP_PL_NPL,'N','NP','P','PE','PE') END,
					-- 15/04/2019 - CDS ATOS (LFD) - US781
					--DECODE(o.cd_flag_restructuration,'RCOM',o.DT_AQR,null),
					DECODE(o.cd_flag_restructuration,'RCOM',o.DT_MAJ_FLAG_RESTRUCT,null),
					-- FIN LFD
					DECODE(o.cd_flag_restructuration,'RISQ',o.DT_AQR,null),
					o.ID_OPERATION,
					o.ID_OPERATION,
					o.CD_TYPE_TAUX,
					o.DATE_PREM_ECH,
					DECODE(o.cd_sys_int,'KSP','EXA-360','EXB-EXB'),
					o.DT_MEL,
					'EUR',
					--12/02/2019 - CDS ATOS (SQN) US 654
					--o.crd_brut_ht-mnt_vr,
					CASE WHEN o.crd_brut_ht-mnt_vr <0 THEN 0 ELSE o.crd_brut_ht-mnt_vr END CAP_THEO_REST,
					--Fin SQN
					CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN o.DT_EXIGTE_PREM_IMPY END,
					o.DT_DEB_PALL,
					o.DT_FIN_PALL,
					o.MNT_ECH_EN_COURS,
					'EUR',
					CASE WHEN o.DT_DEB_OPE >= o.DT_ARRETE THEN o.DT_ARRETE - 1
														  ELSE o.DT_DEB_OPE
					END  DATE_DEB_ENG_RENVL,
					'1',
					o.CD_SYS_INT,
					'_' || T.cd_segment_casa || '_' || s.CD_CONSO_CPT_CRRV3 || '_' || o.cd_produit,
					RT.code_CASA,
					--o.taux_mrg,   16/05/19 CDS ATOS (EMM) Mantis 47711
					--11/12/2018 CDS ATOS (SQN) Mantis 43416 - IFRS 9 Floorer les taux d'inetret negatifs a 0
					--CASE WHEN o.valeur_taux<0 THEN 0.00001 ELSE o.valeur_taux END,
					--CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))<0 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,
					--CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))<0 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,
					--Fin SQN
					--13/05/19 CDS ATOS (EMM) Mantis 47711
					CASE WHEN nvl(o.taux_mrg,0)< 0.00001 THEN 0.00001 ELSE o.taux_mrg END,                        --TAUX_MRG_ADD
					CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_CLT_PRD_EN_CRS
					CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_CLT_OCT
					CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_INT_EFF_ORI
					--Fin EMM
					'N' ,
					--01/12/2017 - CDS ATOS (EMM) - Sprint 1, US 27
					--ef.dt_aqr,          --- DATE_PREM_ACT_FORB
          -- M58209 : remplace par
				  --- DATE_PREM_ACT_FORB alimentee si TOP_RESTRUCTURATION <> null et <> AR (restructuration commerciale et non en risque)
				  CASE  WHEN O.CD_AQR = 'C4'                                                                                                THEN null      --'AR'
				        WHEN O.CD_AQR = 'C3A' AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR THEN ef.dt_aqr --'RC'
				        WHEN O.CD_AQR = 'C2'  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF' M70812
				       -- WHEN O.CD_AQR = 'C2'   OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF'
				        ELSE NULL
				  END AS DATE_PREM_ACT_FORB,
					--sf.dt_fin_valid_aqr,
					o.DATE_SORT_EFF_FORB,   --08/02/19 VDS ATOS (EMM) ANACREDIT US 497
					-- fin EMM
					--29/03/2018 CDS ATOS (EMM) Sprint 7 US 218 ANACREDIT
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR END DATE_ENTR_PER_PURG,
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12) END DATE_SORT_PER_PURG,
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12)
					  else
						CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR end
					END DATE_ENTR_PER_PROB,
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,36)
					  else
						CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,24) end
					END DATE_SORT_PER_PROB,
          -- DATE_THEO_FIN_FORB  M58209 : regle remplace par
				  CASE WHEN O.CD_AQR = 'C4'                                                                                                THEN null      --'AR'
    			     WHEN o.CD_AQR = 'C3A' AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR then ADD_MONTHS(o.DT_AQR,24)
				       WHEN o.CD_AQR = 'C2'   OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         then ADD_MONTHS(o.DT_AQR,36)
				       ELSE NULL
 					END AS DATE_THEO_FIN_FORB,
					--Fin EMM
					--01/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
					--20/07/2018 - CDS ATOS (LFD) - ANACREDIT US 435
					CASE WHEN o.MNT_BRUT_ORIGINE > 0 THEN o.MNT_BRUT_ORIGINE
					  WHEN o.MNT_BRUT_ORIGINE = 0 OR o.MNT_BRUT_ORIGINE < 0 then 0
					  ELSE null
					END, -- Montant du contrat ? l'origine
					--o.MNT_BRUT_ORIGINE, -- Montant du contrat a l'origine
					--11/02/2019 - CDS ATOS (SQN) US 654
					--Case When o.MNT_BRUT_ORIGINE is not null then o.CD_DEVISE end , --Devise du montant du contrat a l'origine -- Edit du 01/06/2018 : si pas de montant, pas de devise
					CASE WHEN o.MNT_BRUT_ORIGINE IS NULL THEN 'EUR' ELSE (CASE WHEN o.MNT_BRUT_ORIGINE IS NOT NULL THEN o.CD_DEVISE END) END DEV_MNT_CONTRAT_ORIGINE,
					--Fin SQN
					--DECODE( T.CD_CATEG_CPT, 'DTCO', T.DT_CHG_CATEG_CPT , NULL) --, -- Date de passage en douteux compromis
					-- fin FAD
					-- 17/07/2018 - CDS ATOS (LFD) - US 436 - CRRV4.1 P1 22.38
					null DT_PASSAGE_DOUTEUX_COMPROMIS,    -- Date de passage en douteux compromis
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					-- 24/01/2018 CDS Atos (JMP) ANACRIT US33
					pack_alim_tab_envoi_crrv4_new.f_cd_motif_sco_lc0267(
					T.CD_CATEG_CPT,
					t.cd_motif_sco,
					-- On ne tient compte du nombre de jours d'impay?s que si, comme pour le calcul de la date d'exigibilite du premier impaye,
					--    la somme des montants des impayes est strictement poositive.
						CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN o.dt_arrete - o.DT_EXIGTE_PREM_IMPY END,
						t.NOTE_BALOISE)
					-- Fin 24/01/2018 CDS Atos (JMP) ANACRIT US33
					-- null CD_MOTIF_SCO_LC0267  --US41
					-- FIN LFD
					-- 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					, o.MNT_PREM_DBLQ_FONDS
					, o.DT_PREM_DBLQ_FONDS
					--12/02/2019 - CDS ATOS (SQN) US 654
					--, CASE WHEN NVL(o.MNT_PREM_DBLQ_FONDS,0) > 0 THEN 'EUR' END
					, NVL((CASE WHEN NVL(o.MNT_PREM_DBLQ_FONDS,0) > 0 THEN 'EUR' END),o.CD_DEVISE) --DEVISE_PREM_DBLQ_FONDS
					--Fin SQN
					-- Fin 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					--END
					--05/02/2019 - CDS ATOS (SQN) US 662
					, CASE  WHEN (T.CD_CATEG_CPT='DTX' or T.CD_CATEG_CPT ='DTCO')
						THEN T.DT_CHG_CATEG_CPT
						ELSE NVL(o.DT_CHG_PE_NPE, NVL(o.DT_DEB_OPE,o.DT_DEB_VALIDITE_AUTO))
						END               --DT_PL_NPL
					, CASE  WHEN (T.CD_CATEG_CPT = 'DTX' or T.CD_CATEG_CPT = 'DTCO')
						THEN 'B3'
						ELSE 'B1'
						END               --BUCKET_IFRS9
					, CASE  WHEN o.DT_DEB_OPE >= o.DT_ARRETE
						THEN o.DT_ARRETE - 1
					ELSE o.DT_DEB_OPE
					END               --DT_DISPO_FONDS
					--, T.CD_PAYS_RESIDENCE         --CD_PAYS_JURIDICTION
					, T.CD_PAYS_RISQUE --CD_PAYS_JURIDICTION -- BALE4 P1 22.66 pos 2834
					, CASE  WHEN o.DT_DEB_OPE >= o.DT_ARRETE
							THEN o.DT_ARRETE - 1
							ELSE o.DT_DEB_OPE
					END               --DT_SIGNATURE
					--27/02/2019 - CDS ATOS (SQN) - US 747
					, CASE  WHEN (o.dt_arrete - o.dt_exigte_prem_impy) > 0 AND (CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN 'Y' ELSE 'N' END) = 'Y' THEN (o.dt_arrete - o.dt_exigte_prem_impy)
						ELSE 0
						END               --NB_JOURS_RETARD
					, CASE  WHEN o.MNT_SOLDE_HT_EXIGIB_IRE < 0 THEN 0
						ELSE o.MNT_SOLDE_HT_EXIGIB_IRE
						END               --MNT_IDEMNITE_RES
					, CASE  WHEN o.MNT_SOLDE_HT_EXIGIB_IRE is not null
						THEN o.CD_DEVISE
						ELSE null
						END               --CD_DEV_MNT_INDEMNITE
					--Fin SQN
					-- 06/02/2019 - CDS ATOS (SQN) - CRRV4.2 ajout de RG ACODUC
					, '0' --IND_OPE_EFFET_LEVIER
					-- 18/02/2019 - CDS ATOS (GBD) - US731 -->
					, 'I' ORGA_NOTATION_ORIG
					--, CASE  WHEN t.cd_segment_cal not in ('06','07')  THEN '3' ELSE null END IND_RMB_ANTICIPE  -- =3 Pour 'NAT02'
					, '3' IND_RMB_ANTICIPE   -- =3 Pour 'NAT02' cad pour flag_hn=N (flag_hn est /defaut ? N ! ; cest ds le script hors NAT02 qu'on insert flag_hn=O)
					, 'N' ELIGIB_PRUDENT_VAL -- =N Pour 'NAT02'
					-- 27/03/2019 - CDS ATOS (LFD) - US 768
					--, '1' IND_MOBIL_ACTIF
					--,CASE WHEN O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++' OR O.INDIC_PSE IN ('P1','P2') THEN '2' ELSE '1' END IND_MOBIL_ACTIF --CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
					-- FIN LFD
					-- 18/02/2019 - CDS ATOS (GBD) - US731 <--
					-- 26/11/2020 - CDS ATOS (CPD) - US17
					, o.MNT_SUBV_HT
					, o.MNT_AVP_HT
					-- fin CPD
					-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
					,CASE WHEN O.CD_SOC_JURI IN ('09','31') THEN '1' ELSE '2' END IND_ELIGI_OUTI_CTRAL_ANACRD
					,CASE WHEN O.CD_SOC_JURI IN ('09','31') THEN '02' END MOTIF_EXCLU_ANACREDIT
					,CASE WHEN o.MNT_BRUT_ORIGINE > 0 THEN o.MNT_BRUT_ORIGINE
					  WHEN o.MNT_BRUT_ORIGINE = 0 OR o.MNT_BRUT_ORIGINE < 0 then 0
					  ELSE null
					END MNT_ENG_DT_SIGN_CTRT
					,'N' IND_RESPO_SOLIDAIRE
					-- FIN LFD
					--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88

					--Si les 3 caratÃ¿Â¿Â½res Ã¿Â¿Â½ partir de la deuxieme position du champ BTR_OPERATION.COTATION_BDF in ('4+','3','3+','3++') ou si BTR_OPERATION.INDIC_PSE in ('P1','P2') alors renseigner '3' sinon garder l'alimenation actuelle.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '3' 	ELSE '1'	END IND_MOBIL_ACTIF
					--Si les 3 caratÃ¿Â¿Â½res Ã¿Â¿Â½ partir de la deuxieme position du champ BTR_OPERATION.COTATION_BDF in ('4+','3','3+','3++') ou si BTR_OPERATION.INDIC_PSE in ('P1','P2') ET IND_MOBIL_ACTIF='3' Alors 'Y' sinon 'N'
					--IND_MOBIL_ACTIF Ã¿Â¿Â½tant dÃ¿Â¿Â½ja renseignÃ¿Â¿Â½ au dessus et les condition Ã¿Â¿Â½tant les meme pas besoin de le prendre en compte.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN 'Y' 	ELSE 'N' 	END ELIG_MOB_BANQUE_CENTRALE
					--SI IND_MOBIL_ACTIF='3' ET ELIG_MOB_BANQUE_CENTRALE = 'Y' alors 1 sinon laisser vide. Ces deux champs sont renseignÃ¿Â¿Â½s au dessus juste Ã¿Â¿Â½ prendre la condition du 1er champs.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '1' 	ELSE NULL	END REF_MOB_ACTIF
					--SI IND_MOBIL_ACTIF='3' ET ELIG_MOB_BANQUE_CENTRALE = 'Y' ET REF_MOB_ACTIF = '1' alors '404' sinon laisser vide. Ces champs sont renseignÃ¿Â¿Â½s au dessus juste Ã¿Â¿Â½ prendre la condition du 1er champs.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '404' 	ELSE NULL 	END CD_ORGA_MOBIL

					-- 23/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
					--, 'N' IND_ELIGB_ACTIF_IMM_BC
					-- Fin CPD
					-- FIN MNE
					--CDS_ATOS (LFD) - 18/06/2021 - US 91 CRRV4.3
					,CASE WHEN NVL(decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),0) <> 0 AND BSR.CD_PAYS = 'FR' THEN BSR.CD_POSTAL END CD_COMMUNE_BIEN_FINAN
					,CASE WHEN NVL(decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),0) <> 0 THEN NVL(BSR.CD_PAYS,'FR') END CD_PAYS_BIEN_FINAN --Mantis 71367
					-- FIN LFD
					--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
					,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE
					--FIN MNE
					--,o.IND_ISF IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
					--BALE4
					,o.MOTIF_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.22
					,o.DT_DEBUT_MRTR-- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.23
					,o.DUREE_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.29
					,o.STATUT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.25
					,o.IND_MRTR_LEGISLATIF -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.26
					,o.IND_MRTR_CONTRACTUEL -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.27
					,o.CHAMP_APPL_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.28
					,o.MNT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.30
					,o.DEV_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.31
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN
						CASE WHEN HB.MNT_IEC > 0  THEN 'Y' ELSE 'N' END
					 ELSE NULL END IND_EXPO_ADC -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.39
					,bien.MNT_LTV_VV_ACT LTV_RATIO -- KLX-GOMESHU - BALE4 - 15/02/2024 - P1 22.43
					,(bien.MNT_ETV_VV_ACT)*100 ETV_RATIO -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.43
					,CASE WHEN (pf.CD_TYP_RISQ_CORP LIKE 'EQU%' OR pf.CD_TYP_RISQ_CORP IN ('ISS200', 'TRE405', 'TRE406') ) THEN 'N' ELSE NULL END IND_INVEST_CAPITAL_RISQ --P1 21.57
					,CASE WHEN (pf.CD_TYP_RISQ_CORP LIKE 'EQU%' OR pf.CD_TYP_RISQ_CORP IN ('ISS200', 'TRE405', 'TRE406') ) THEN 'N' ELSE NULL END IND_INVEST_PROG_LEGISLATIF --P1 21.58
					,CASE WHEN pf.CD_TYP_RISQ_CORP = 'EQU101' THEN 'Y' ELSE NULL END IND_TITRE_PARTICIP --P1 21.79
					,DECODE(o.CD_TYPE_PRODUIT,'ASR','N','Y') IND_OPE_AVEC_RECOURS -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.88
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502') ) THEN '2' ELSE '0' END USAGE_BIEN_FINANCE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 8.13
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.VILLE ELSE NULL END COMMUNE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.71
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END NUM_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.72
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_2_ADR_ACT_CBI ELSE NULL END EXTENSION -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.73
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END TYPE_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.74
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END LIB_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.75
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN NULL ELSE NULL END LIEU_DIT -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.76
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LATITUDE ELSE NULL END LATITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.77
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LONGITUDE ELSE NULL END LONGITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.78
					,CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN 'Y'
						  WHEN pf.CD_TYP_RISQ_CORP = 'TRE501' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN 'Y'
					ELSE 'N' END IND_UCC --P1 21.66
					,CASE WHEN ( pf.CD_TYP_RISQ_CORP LIKE 'VAR%' AND pf.CD_TYP_RISQ_CORP NOT IN ('VAR105','VAR302'))
						THEN 'JVR' ELSE NULL END CLASS_CPT_ELEMENT_COUV_DERIVE --P1 21.80
					,CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN '1'
						  WHEN pf.CD_TYP_RISQ_CORP = 'TRE501' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN '1'
					ELSE NULL END NIV_RISQUE_CRR3 --P1 21.68
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN immeuble.CD_TYPE_BIEN_COMM ELSE NULL END CD_TYPE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.86
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN emplace_bien.CD_EMPLACE_BIEN_COMM ELSE NULL END CD_EMPLACE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.87
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00936','00399','00472') ) THEN t.DBT_SRVC_RT ELSE NULL END TX_DSCR -- BALE4 - P1 21.81
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00936','00399','00472') ) THEN t.DBT_SRVC_RT_12M ELSE NULL END TX_DSCR_PREC -- BALE4 - P1 21.82
					,CASE WHEN ( PF.CD_TYP_RISQ_CORP IN ('TRE203','TRE207','TRE206') OR PF.CD_TYP_RISQ_CORP LIKE 'VAR%' OR PF.CD_TYP_RISQ_CORP LIKE 'INT%' ) THEN 'N' ELSE NULL END IND_ACCORD_NETTING -- KLX-GOMESHU - BALE4 - 30/04/2024 - P1 30.23
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502') ) THEN bien.MNT_ACQ_HT_ACT ELSE NULL END MNT_ACQUISITION -- KLX-BARTOLMI - QDD - Mantis 71368
					,CASE WHEN TABLE_AUX_31_21.FLAG_ASCR_PARI = 'O' 				THEN '03'
						WHEN PF.CD_TYP_RISQ_CORP in ('PRI105', 'TRE502') and O.dt_mel is not null THEN '01'
						WHEN PF.CD_TYP_RISQ_CORP in ('TRE504', 'TRE501') and O.dt_mel is not null THEN '02'
						ELSE '04' END CDTYPEGARPRINCOCTROI -- P1 31.21 M71371
				,NULL CD_METH_IFRS9_PD_ORIG -- projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
			FROM BTR_OPERATION                  o,
				   RS_SOCIETE_JURIDIQUE           s,
				   REF_TAUX_ARPSON                    RT,
				   BTR_TIERS                      T,
				   RS_CORRES_PRD_FIN_TYP_RISQ_CRP pf,
				   BTR_HORS_BILAN                 hb,
				   RS_FAMILLE_IMMEUBLE			immeuble,--BALE4 P1 21.86
				   RS_CORRES_SIT_GEO_BIEN_COMM emplace_bien,--BALE4 P1 21.87
				   ( select
				   		ope.id_operation,
				   		'O' FLAG_ASCR_PARI
				   		FROM
				   		rs_type_garantie rs,
				   		btr_surete_pers pers,
				   		btr_operation ope
				   		WHERE rs.id_type_garantie =pers.id_type_garantie
				   		AND pers.id_operation = ope.id_operation
				   		AND rs.id_famille_garantie in ('ASCR', 'PARI') ) TABLE_AUX_31_21,
				   -- M65476
				   --(select cd_sys_int, id_operation, sum(MNT_VTR_PDR) MNT_VTR_PDR, sum(MNT_VV_ACT) MNT_VV_ACT,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'ATNL','1','LOUE','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act  from btr_surete_reelle group by cd_sys_int, id_operation) bien,
                   (select cd_sys_int, id_operation, sum(MNT_VTR_PDR) MNT_VTR_PDR, sum(MNT_VV_ACT) MNT_VV_ACT, sum(MNT_ACQ_HT_ACT) MNT_ACQ_HT_ACT, sum(mnt_revise) mnt_revise, sum(MNT_ETV_VV_ACT) MNT_ETV_VV_ACT, sum(MNT_LTV_VV_ACT) MNT_LTV_VV_ACT, min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'ATNL','1','LOUE','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act  from btr_surete_reelle group by cd_sys_int, id_operation) bien,
				   -- M65476
				   (SELECT id_operation, cd_sys_int, id_tiers, cd_pcec_crd, cd_pcec_icne, nato_crd,CD_PCEC_K_A,CD_PCEC_I   -- 33s
					 FROM (SELECT o.CD_SYS_INT, o.ID_OPERATION,
								  CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END CD_STATUT_ACT, --HL 43378
								  so.CD_PHASE, T.ID_TIERS, rs.CD_TYPE_CLI, T.CD_CATEG_CPT, o.CD_PRODUIT                      --HL 466728
						   FROM btr_operation o, -- btr_surete_reelle sr,
								rs_statut_ope so,
								btr_tiers T,
								RS_CORRES_SGMT_BAL_TYPE_CLI rs,
								(SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
								FROM btr_surete_reelle
								GROUP BY cd_sys_int, id_operation
								) sr -- AGU 12/01/2010 passage par un sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
						   WHERE sr.ID_OPERATION  = o.ID_OPERATION
							 AND sr.CD_SYS_INT    = o.CD_SYS_INT
							 AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
							 AND o.ID_TIERS       = T.ID_TIERS
							 AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							 --HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
							 AND so.CD_PHASE      = 'APCDE'
							 --HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
							 AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV')       --HL 43378
						   UNION
							 SELECT o.CD_SYS_INT, o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
							 FROM btr_operation o,
											 rs_statut_ope so,
											 btr_tiers T,
											 RS_CORRES_SGMT_BAL_TYPE_CLI rs
							 WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
							   AND o.ID_TIERS = T.ID_TIERS
							   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							   AND so.CD_PHASE = 'APCDE'
							   and not exists (SELECT 1
												 FROM
																 rs_statut_ope so,
																 btr_tiers T,
																 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
																 (SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
																 FROM btr_surete_reelle
																 GROUP BY cd_sys_int, id_operation
																 ) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
												 WHERE sr.ID_OPERATION  = o.ID_OPERATION
												   AND sr.CD_SYS_INT    = o.CD_SYS_INT
												   AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
												   AND o.ID_TIERS       = T.ID_TIERS
												   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
												   --HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
												   AND so.CD_PHASE      = 'APCDE'
												   --HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
												   AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
												   -- HL 43378 AND o.CD_PRODUIT IN ('CRED','CREN')
								) perim,
						   rs_corres_pcec pc
					WHERE perim.CD_CATEG_CPT  = pc.CD_CATEG_CPT
									AND perim.CD_PHASE      = pc.CD_PHASE
									AND perim.CD_PRODUIT    = pc.CD_PRODUIT
									AND perim.CD_STATUT_ACT = pc.CD_STATUT_ACT
									AND perim.CD_TYPE_CLI   = pc.CD_TYPE_CLI
					 UNION
					   SELECT id_operation, cd_sys_int, o.id_tiers, cd_pcec_crd, cd_pcec_icne, nato_crd,CD_PCEC_K_A,CD_PCEC_I
					   FROM btr_operation  o,
						   btr_tiers t,
						   RS_CORRES_SGMT_BAL_TYPE_CLI rsc,
												   rs_statut_ope  so,
												   rs_corres_pcec pc
					   WHERE o.cd_statut_ope = so.CD_STATUT_OPE
					   and t.id_tiers=o.id_tiers
					   AND   T.cd_segment_cal=rsc.cd_segment_cal
					   and rsc.cd_type_cli=pc.cd_type_cli
					   AND so.CD_PHASE       = 'CDE'
					   AND pc.CD_PHASE       = so.CD_PHASE
					   ) pcec,
				   AUT_COR_OPE_NUM_DEC_BIS                NU,
				   (SELECT CD_SOC_JURI, CD_SEGMENT, cd_method  ,trt_moteur
					  FROM RS_METHO_BALE_SOC_SEG) methodo,
				   --01/12/17 CDS ATOS (EMM) Sprint 1 US 27
				   (select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
				   cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
				   from his_forb_btr_operation hisb
				   where hisb.cd_aqr IN ('C2','C3A')
				   and hisb.dt_arrete between hisb.dt_aqr and hisb.dt_fin_valid_aqr
				   and hisb.dt_aqr = (select min(hist.dt_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation and hist.cd_aqr IN ('C2','C3A'))
				   )ef
				   /*,
				   --14/04/18 CDS ATOS (EMM) Sprint 8 US 319
				   (select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
						 cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
						 from his_forb_btr_operation hisb
						 where hisb.cd_aqr IN ('C2','C3A')
						 and dt_fin_valid_aqr = add_months(dt_arrete, -1)
						 and hisb.dt_fin_valid_aqr = (select max(hist.dt_fin_valid_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation)
						 )sf
				   */

			   --Fin EMM
			   ,(SELECT DISTINCT CD_PAYS, CD_POSTAL, ID_OPERATION, VILLE, LIG_1_ADR_ACT_CBI, LIG_2_ADR_ACT_CBI, LATITUDE, LONGITUDE, CD_FAMILLE_IMM, CD_SIT_GEO_N1, CD_SIT_GEO_N2 FROM BTR_SURETE_REELLE)	BSR 	-- 18/06/2021 - CDS ATOS (LFD) - US 91 CRRV4.3
			   ,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			   WHERE o.CD_SOC_JURI = s.CD_SOC_JURI
				 AND   o.ID_TIERS    = T.ID_TIERS
				 AND   o.CD_PRODUIT  = pf.CD_PRODUIT
				 AND   o.ID_OPERATION = pcec.id_operation (+)
				 and   o.ID_OPERATION = TABLE_AUX_31_21.id_operation (+) -- M7371
				 AND   o.CD_SYS_INT   = pcec.cd_sys_int (+)
				 AND   o.code_index_taux       =             RT.code_index_taux (+)
				 AND   o.ID_OPERATION = hb.id_operation (+)
				 AND   o.CD_SYS_INT   = hb.cd_sys_int (+)
				 AND   o.ID_TIERS     = pcec.id_tiers (+)
				 and   o.CD_SYS_INT   = bien.cd_sys_int (+)
				 AND   o.ID_OPERATION = bien.id_operation (+)
				 AND   BSR.CD_FAMILLE_IMM = immeuble.CD_FAMILLE_IMM(+) --BALE4 P1 21.86
				 AND   BSR.CD_FAMILLE_IMM = emplace_bien.CD_FAMILLE_IMM(+) --BALE4 P1 21.87
				 AND   BSR.CD_SIT_GEO_N1 = emplace_bien.CD_SIT_GEO_N1(+) --BALE4 P1 21.87
				 AND   BSR.CD_SIT_GEO_N2 = emplace_bien.CD_SIT_GEO_N2(+) --BALE4 P1 21.87
				 AND   o.CD_SYS_INT   = NU.CD_SYS_INT   (+)
				 AND   o.ID_OPERATION = NU.ID_OPERATION (+)
				 AND   T.CD_TYPE_SGMT        = 'CORP'
				 AND   s.CD_CONSO_CPT_CRRV3 != '99999'
				 And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
				 and o.id_operation = ef.id_operation(+) --01/12/17 EMM
				 and o.cd_sys_int   = ef.cd_sys_int(+)  --29/03/18 EMM
				 --08/02/19 VDS ATOS (EMM) ANACREDIT US 497 Inhibition de cette partie car de sous-ensembre 'sf' n'existe plus
				 --and o.id_operation = sf.id_operation(+) --01/12/17 EMM
				 --and o.cd_sys_int   = sf.cd_sys_int(+)  --29/03/18 EMM
				 --Fin EMM
				 And s.cd_soc_juri     = methodo.cd_soc_juri
				 And o.CD_SYS_INT     != ('DE')     --Totof a revoir pour le HB
				 AND O.ID_OPERATION = BSR.ID_OPERATION (+) 	-- 18/06/2021 - CDS ATOS (LFD) - US 91 CRRV4.3
				 --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
				AND pf.CD_TYP_RISQ_CORP = PARAM.VAL_PARAM_1 --ENG_CORP_P1.CD_TYPE_RISQUE = PARAM_MULTIDIM_GENERIQUE.VAL_PARAM_1
				--FIN MNE
				;
				COMMIT;

				--   ici pour les iec corp qui font bien partie du bilan
       DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
                W_TABLE := 'ENG_CORP_P1 (3)';
				INSERT INTO ENG_CORP_P1   (
					DT_ARRETE,
					CD_CONSO_CPT,
					ID_TIERS_CALC,
					ID_CENTRAL_TIERS,
					ID_AUTORISATION,
					ID_LIGNE_DET,
					ID_ENGAGEMENT,
					CD_METHODO_BALE2,
					CD_TYPE_RISQUE,
					CD_PORTEFEUILLE_BOOKING,
					CD_LIGNE_METIER,
					CD_PORTEFEUILLE_BALE2,
					CD_NATURE_OPE,
					DT_DEBUT_ENG,
					DT_FIN_ENG,
					MNT_RISQUE,
					CD_DEVISE_CRD,      ---new
					MNT_CRD,            ---new
					PCCO_CRD,           ---new
					PCCO_MNT_CRD,       ---new
					PCCO_MNT_SOLDE,
					PCCO_INT_RD,
					CD_DEVISE_MNT_RISQ,
					PCEC_MNT_RISQUE,
					CD_STATUT_OPE_DT_SOLDE,
					MNT_ICNE,
					PCEC_ICNE,
					CD_DEVISE_ICNE,
					MNT_VR,
					CD_DEVISE_VR,
					TOP_ENG_DOUTEUX,
					DT_ENG_DOUTEUX,
					TOP_ACCORD_FUSION,
					MNT_EXPOSITION,
					MNT_EXPO_POTENT, -- FHL 50439
					CD_DEVISE_EXPO,
					CD_CPT_ACTIF_IAS,
					MNT_CPT_ACTIF_PCIAS,
					TOP_RESTRUCTURATION,
					DT_RESTRUCTURATION,
					TX_LGD_PREDICTIF,  -- AG 23/01/2008
					TX_LGD_PREDICTIF_LOCAL, -- AG 23/01/2008
					A_EXTRAIRE,
					DT_ACQ_DERN_PART_OPC,
					TX_CONV_HB,
					MNT_EAD_TOT,
					DEVISE_EAD,
					TOP_ENG,
					MATURITE_EFF,
					MNT_LOY_RD,
					MNT_INT_RD,
					TX_TRC,
					CODE_TRAIT_MOTEUR,
					CODE_TRAIT_GRR,
					MNT_VTR_PDR,
					MNT_HYPOTHEQUE,
					CD_CIRCUIT_DISTRIB,
					CD_USAGE_BIEN_IMM,
					CD_DEV_HYPOTH,
					CD_DEV_VTR,
					MNT_SOLD_K_A,
					MNT_SOLDE,
					CD_DEVISE_SOLDE,
					CD_IMP_PRUDENT,
					CD_RESPECT_COND,
					MNT_FIN_PERIODE,
					CD_ARR_PAIEMENT,
					MNT_VTR,
					CD_ACHAT_FIN_LOC,
					IND_PROD_ECH,
					IND_OBJ_MET_PAL,
					IND_ECH_FOUR,
					TYPE_AMOR_CAP,
					PRD_AMOR_CAP,
					PRD_PMT_INT,
					MOD_REMB_CRE,
					DATE_FIN_DIFF_AMOR,
					PRD_REV_TAUX_UNIT_TMP,
					PRD_REV_TAUX_NBR,
					DEVI_CAP_THEO_REST,
					IND_PRE_POST_FIX,
					CENTRE_RES,
					-- Nouveau champs ajout?s
					EVENMT_CRDT,
					nat_cont_evenmt_crdt,
					sta_crdt,
					ind_cre_perf,
					date_der_rest_comm,
					date_der_rest_rsq,
					REF_UNIQ_CONT,
					REF_UNIQ_ELEM_CONT,
					TYPE_TAUX,
					DATE_PREM_ECH,
					BASE_CAL_INT,
					DATE_PREM_DEB_FOND,
					DEV_MONTANT_DEB,
					CAP_THEO_REST,
					DT_EXIGTE_PREM_IMPY,
					DATE_DEB_PALL,
					DATE_FIN_PALL,
					MNT_ECH_EN_COURS,
					DEVI_MNT_ECH_EN_COURS,
					DATE_DEB_ENG_RENVL,
					ELI_OUT_MUT_PROV,
					SYS_GEST_SRC,
					ZONE_APP_COMP,
					IND_REF,
					TAUX_MRG_ADD,
					TAUX_CLT_PRD_EN_CRS,
					taux_clt_oct,taux_int_eff_ori,
					ind_act_dep_ori,
					DATE_PREM_ACT_FORB, --30/11/2017 CDS ATOS (EMM)
					DATE_SORT_EFF_FORB, --30/11/2017 CDS ATOS (EMM)
					DATE_ENTR_PER_PURG, --30/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					DATE_SORT_PER_PURG, --30/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					DATE_ENTR_PER_PROB, --30/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					DATE_SORT_PER_PROB, --30/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					DATE_THEO_FIN_FORB, --30/03/2018 CDS ATOS (EMM) US 218 Sprint 7
					--01/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
					MNT_CONTRAT_ORIGINE, -- Montant du contrat  l'origine
					DEV_MNT_CONTRAT_ORIGINE, -- Devise du montant du contrat  l'origine
					DT_PASSAGE_DOUTEUX_COMPROMIS -- Date de passage en douteux compromis
					-- fin FAD
					, CD_MOTIF_SCO_LC0267 -- 24/01/2018 CDS Atos (JMP) ANACREDIT US33
					-- 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					, MNT_PREM_DBLQ_FONDS
					, DT_PREM_DBLQ_FONDS
					, DEVISE_PREM_DBLQ_FONDS
					-- Fin 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					--05/02/2019 - CDS ATOS (SQN) US 662
					, DT_PL_NPL
					, BUCKET_IFRS9
					, DT_DISPO_FONDS
					, CD_PAYS_JURIDICTION
					, DT_SIGNATURE
					, NB_JOURS_RETARD
					, MNT_IDEMNITE_RES
					, CD_DEV_MNT_INDEMNITE
					--Fin SQN
					-- 18/02/2019 - CDS ATOS (GBD) - US731 -->
					, ORGA_NOTATION_ORIG
					, IND_RMB_ANTICIPE
					, ELIGIB_PRUDENT_VAL
					--, IND_MOBIL_ACTIF --CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
					-- 18/02/2019 - CDS ATOS (GBD) - US731 <--
					--11/03/2019 - CDS ATOS (SQN) - US 748
					, IND_OPE_EFFET_LEVIER
					--Fin SQN
					-- 26/11/2020 - CDS ATOS (CPD) - US17
					, MNT_SUBV_HT
					, MNT_AVP_HT
					-- fin CPD
					-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
					,IND_ELIGI_OUTI_CTRAL_ANACRD
					,MOTIF_EXCLU_ANACREDIT
					,MNT_ENG_DT_SIGN_CTRT
					,IND_RESPO_SOLIDAIRE
					-- FIN LFD
					--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88

					,IND_MOBIL_ACTIF
					,ELIG_MOB_BANQUE_CENTRALE
					,REF_MOB_ACTIF
					,CD_ORGA_MOBIL
					-- 23/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
					--,IND_ELIGB_ACTIF_IMM_BC
					-- Fin CPD
					--FIN MNE
					--CDS_ATOS (LFD) - 18/06/2021 - US 91 CRRV4.3
					,CD_COMMUNE_BIEN_FINAN
					,CD_PAYS_BIEN_FINAN
					-- FIN LFD
					--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
					,CD_TYPE_PROD_BANCAIRE
					--FIN MNE
					--,IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
					-- BALE4
					,MOTIF_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.22
					,DT_DEBUT_MRTR-- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.23
					,DUREE_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.29
					,STATUT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.25
					,IND_MRTR_LEGISLATIF -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.26
					,IND_MRTR_CONTRACTUEL -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.27
					,CHAMP_APPL_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.28
					,MNT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.30
					,DEV_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.31
					,IND_EXPO_ADC  -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.39
					,LTV_RATIO -- KLX-GOMESHU - BALE4 - 15/02/2024 - P1 22.43
					,ETV_RATIO -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.43
					,IND_INVEST_CAPITAL_RISQ -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.57
					,IND_INVEST_PROG_LEGISLATIF -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.58
					,IND_TITRE_PARTICIP -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.79
					,IND_OPE_AVEC_RECOURS -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.88
					,USAGE_BIEN_FINANCE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 8.13
					,COMMUNE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.71
					,NUM_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.72
					,EXTENSION -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.73
					,TYPE_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.74
					,LIB_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.75
					,LIEU_DIT -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.76
					,LATITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.77
					,LONGITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.78
					,IND_UCC -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.66
					,CLASS_CPT_ELEMENT_COUV_DERIVE -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.80
					,NIV_RISQUE_CRR3 -- KLX-GOMESHU - BALE4 - 22/01/2024 - P1 21.68
					,CD_TYPE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.86
					,CD_EMPLACE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.87
					,TX_DSCR						-- BALE4 - P1 21.81
					,TX_DSCR_PREC					-- BALE4 - P1 21.82
					,IND_ACCORD_NETTING    -- KLX-GOMESHU - BALE4 - 30/04/2024 - P1 30.23
					,MNT_ACQUISITION       -- KLX-BARTOLMI - QDD - Mantis 71368
					,CDTYPEGARPRINCOCTROI  -- P1 31.21	M71371
					,CD_METH_IFRS9_PD_ORIG -- projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
			)
			SELECT  DISTINCT o.dt_arrete,
					s.CD_CONSO_CPT_CRRV3,
					CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
					T.IDENT_SIRIS,
					CASE WHEN NU.CD_SYS_INT is not null then 'F1'|| nvl(NU.NUM_DEC_BIS, O.id_operation) END  ID_AUTORISATION,
					CASE WHEN NU.CD_SYS_INT is not null then 'F2'|| nvl(NU.NUM_DEC_BIS, O.id_operation) END  ID_LIGNE_DET,
					-- totof IEC o.ID_OPERATION,
					Case when hb.MNT_IEC > 0 then hb.id_operation_sig else o.id_operation end id_operation,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--methodo.cd_method cd_methodo_bale2,
					NVL(methodo.cd_method, 'STD') CD_METHODO_BALE2,
					--Fin SQN
					pf.CD_TYP_RISQ_CORP,
					'B' cd_portefeuille_booking,                                                                    --10
					'MLE00' cd_ligne_metier, -- AFR le 08/11/2012 retour 1 homologation CASA
					'900', --DECODE(methodo.cd_method, 'NON IRB', ' ', '900'),         mantis re7 5520
					--pcec.nato_crd cd_nature_ope,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN bien.CD_STATUT_ACT='ATNL' THEN 'NAT05'
					--   WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')          THEN 'NA012'
					--       WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
					--       WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
					--       WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
					--       END cd_nature_ope,
					NVL(CASE  WHEN bien.CD_STATUT_ACT='ATNL' THEN 'NAT05'
						  WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')          THEN 'NA012'
						  WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
						  WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
						  WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
					  END, 'NA020') CD_NATURE_OPE,
					--Fin SQN
					CASE WHEN o.DT_DEB_OPE >= o.DT_ARRETE THEN o.DT_ARRETE - 1
												   ELSE o.DT_DEB_OPE   END  DT_DEBUT_ENG,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--o.DT_FIN_OPE ,
					NVL(o.DT_FIN_OPE, to_date('99990630','YYYYMMDD')) DT_FIN_ENG,
					--Case when hb.MNT_IEC > 0 then hb.MNT_IEC else o.CRD_BRUT_HT end,
					NVL((Case when hb.MNT_IEC > 0 then hb.MNT_IEC else o.CRD_BRUT_HT end),0) MNT_RISQUE,
					--Fin SQN
					NVL(o.CD_DEVISE,'EUR'),      --  CD_DEVISE_CRD,      ---new   -- 18/02/2019 - CDS ATOS (GBD) - US731
					-- 29/01/2021 - CDS ATOS (LFD) - Mantis 55571
					--Case when hb.MNT_IEC > 0 then hb.MNT_IEC else o.CRD_BRUT_HT end
					CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE401' THEN
						Case when hb.MNT_IEC  > 0 then hb.MNT_IEC + nvl(MNT_SOLDE_HT_EXIGIB_K_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_I_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_AUTRE_T,0)
							else o.CRD_BRUT_HT + nvl(MNT_SOLDE_HT_EXIGIB_K_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_I_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_AUTRE_T,0) end
					ELSE
						Case when hb.MNT_IEC > 0 then hb.MNT_IEC else o.CRD_BRUT_HT end
					END MNT_CRD,    --    MNT_CRD,            ---new
					-- FIN LFD
					pcec.CD_PCEC_CRD,  --      PCCO_CRD,           ---new
					pcec.CD_PCEC_CRD,   --     PCCO_MNT_CRD,       ---new
					pcec.CD_PCEC_K_A,
					pcec.CD_PCEC_I,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--o.CD_DEVISE,
					NVL((CASE WHEN (NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0)) <> null THEN o.CD_DEVISE END),'EUR') CD_DEVISE_MNT_RISQ,
					--Fin SQN
					pcec.CD_PCEC_CRD,
					o.CD_STATUT_OPE_DT_SOLDE,
					o.MNT_ICNE,                --20
					pcec.CD_PCEC_ICNE,
					o.CD_DEVISE,
					decode(substr(pf.CD_TYP_RISQ_CORP,1,4),'TRE5',o.MNT_VR,NULL) mnt_vr,
					--11/02/2019 - CDS ATOS (SQN) US 654
					--o.cd_devise,
					NVL(o.cd_devise,'EUR'), --CD_DEVISE_VR
					--Fin SQN
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END top_eng_douteux,
					--'N' TOP_ENG_DOUTEUX, US41
					-- FIN LFD
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN T.DT_CHG_CATEG_CPT END DT_ENG_DOUTEUX,
					CASE WHEN (CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END = 'Y')
					  THEN NVL((CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN T.DT_CHG_CATEG_CPT END),o.dt_arrete)
					  ELSE null
					END DT_ENG_DOUTEUX,
					--FIN SQN
					--null DT_ENG_DOUTEUX,  --US41
					-- FIN LFD
					' ' top_accord_fusion,
					o.MNT_EXPO_COURANTE_HT,
					Case when hb.MNT_IEC > 0 then MNT_IEC else o.MNT_EXPO_POTENT_HT end MNT_EXPO_POTENT,
					o.CD_DEVISE,                                                   --30
					null cd_cpt_actif_ias, --'L'||'&'||'R' cd_cpt_actif_ias, -- on est oblig? de d?couper la chaine ? cause du '&'
					NULL mnt_cpt_actif_pcias,
					--CASE WHEN o.CD_AQR IN ('C2', 'C3A') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN 'RF' WHEN o.CD_AQR IN ('C4', 'C3B') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN 'RC' END top_restructuration,
					--CDS_ATOS (MNE) - 20/05/2021 - Mantis 57292 - Eevolution de la rÃ¿Â¿Â½gle de gestion pour restructuration
					/*
					-- M52619 : TOP_RESTRUCTURATION appliquer la meme regle en vigueur pour le cas RETA (CD_TYPE_RESTRUCT de CREDIT_P3)
					CASE WHEN o.cd_aqr in ('C2','C3A') AND T.cd_categ_cpt in ('DTX', 'DTCO')     THEN 'RF'
						 WHEN o.cd_aqr in ('C2','C3A') AND T.cd_categ_cpt not in ('DTX', 'DTCO') THEN 'RC'
						 WHEN o.cd_aqr in ('C4')       AND T.cd_categ_cpt not in ('DTX', 'DTCO') THEN 'AR'
					*/
					CASE 	WHEN O.CD_AQR IN ('C4') 																								THEN 'AR' --
							WHEN O.CD_AQR IN ('C3A') AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR 	THEN 'RC' --
							WHEN O.CD_AQR IN ('C2')  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')															THEN 'RF' -- M70812
							--WHEN O.CD_AQR IN ('C2') OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')															THEN 'RF' --
					--FIN MNE
						 ELSE NULL
					END AS TOP_RESTRUCTURATION,
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN o.CD_AQR IN ('C2', 'C3A','C4', 'C3B') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN o.DT_AQR END dt_restructuration,
					CASE WHEN o.CD_FLAG_RESTRUCTURATION in ('RCOM','RISQ') THEN o.DT_MAJ_FLAG_RESTRUCT ELSE null END DT_RESTRUCTURATION,
					--Fin SQN
					o.TX_LGD_PREDICTIF, -- AGU 23/01/2009
					CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE o.TX_LGD_PREDICTIF_LOCAL END, -- AGU 23/01/2009
					'O' a_extraire,
					''  DT_ACQ_DERN_PART_OPC,
					(Select T1.TX_CONV_HB From RE_TAUX_CONV_HB T1 Where T1.CD_CANAL_APPORT=o.CD_CANAL_APPORT And  T1.CD_SOC_JURI=o.CD_SOC_JURI And  T1.CD_PRODUIT =o.CD_PRODUIT ),
					--06/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE Case when hb.MNT_IEC > 0 then MNT_IEC else O.MNT_EAD_TOT end END MNT_EAD_TOT,
					CASE WHEN nvl((CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE Case when hb.MNT_IEC > 0 then MNT_IEC else O.MNT_EAD_TOT end END),0) <0 THEN 0
						 ELSE nvl((CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE Case when hb.MNT_IEC > 0 then MNT_IEC else O.MNT_EAD_TOT end END),0)
					END MNT_EAD_TOT,
					--Fin SQN
					Nvl(O.Cd_Devise, 'EUR') ,
					--CASE WHEN methodo.CD_METHOD in ('IRBA','IRB AS')  THEN  -- Mantis re7 5520
					--11/02/2019 - CDS ATOS (SQN) US 654
					--CASE WHEN O.TOP_ENG IN ('O','G') THEN 'H' ELSE 'B' END  TOP_ENG,
					--12/06/2019 - CDS_ATOS(CML) - Mantis 48221
					--NVL((CASE WHEN O.TOP_ENG IN ('O','G') THEN 'H' ELSE 'B' END),'B'), --TOP_ENG
					NVL((CASE WHEN O.TOP_ENG IN ('O') THEN 'H' ELSE 'B' END),'B'), --TOP_ENG
					--fin Mantis 48221
					--O.MATURITE_CALC,
					NVL(O.MATURITE_CALC,0), --MATURITE_EFF
					--Fin SQN
					O.MNT_LOY_RD,
					--11/02/2019 - CDS ATOS (SQN) US 654
					--O.MNT_INT_RD,
					NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) , --MNT_INT_RD
					--Fin SQN
					CASE WHEN methodo.CD_METHOD in ('STD') THEN 0 ELSE o.TX_TRC END,
					--'01',
					--06/02/2019 - CDS ATOS (SQN) US 654
					--methodo.trt_moteur,
					--'N',
					NVL(methodo.trt_moteur, '01') CODE_TRAIT_MOTEUR, -- M56405 change code moteur de 07 a 01
					'Y' CODE_TRAIT_GRR,
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null), --MNT_VTR_PDR
					CASE
						 WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
						 THEN nvl((decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null)),0)
						 ELSE null
					END MNT_VTR_PDR,
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null), --MNT_HYPOTHEQUE
					CASE
						 WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
						 THEN nvl((decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', bien.MNT_VTR_PDR, null)),0)
						 ELSE null
					END MNT_HYPOTHEQUE,
					--Fin SQN
					'CL',
					decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0') CD_USAGE_BIEN_IMM,
					--11/02/2019 - CDS ATOS (SQN) US 654
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ') CD_DEV_HYPOTH,
					CASE
						 WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
						 THEN decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ')
						 ELSE null
					END CD_DEV_HYPOTH,
					--decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ') CD_DEV_VTR,
					CASE
						 WHEN pf.CD_TYP_RISQ_CORP = 'TRE502' and (decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','2','0')) = '2'
						 THEN decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502',Nvl(O.Cd_Devise, 'EUR'), ' ')
						 ELSE null
					END CD_DEV_VTR,
					--Fin SQN
					NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0),
					NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) ,
					case when o.mnt_solde_ht_cpt_cli = 0 then null else o.CD_DEVISE end CD_DEVISE_SOLDE,
					--MODIF 30/11/2015            nvl((Case when o.dt_arrete - o.dt_exigte_prem_impy > 180 then 'Y' else case when o.dt_arrete - o.dt_exigte_prem_impy > 90 and T.CD_SEGMENT_CAL not in ('08','09','10','11') then 'Y' END end), 'N')   CD_IMP_PRUDENT,
					CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END CD_IMP_PRUDENT,
					'Y' CD_RESPECT_COND, --decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502','Y',' ') CD_RESPECT_COND,
					decode(substr(pf.CD_TYP_RISQ_CORP,1,4),'TRE5',o.MNT_VR,NULL) MNT_FIN_PERIODE,
					CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN 'Y' ELSE 'N' END,
					-- M65476
					--0, -- MNT_VTR
                    CASE WHEN substr(pf.CD_TYP_RISQ_CORP,1,6) in ('TRE502','PRI105') AND s.CD_CONSO_CPT_CRRV3='00472' THEN
                        COALESCE( bien.MNT_VV_ACT, bien.MNT_ACQ_HT_ACT * 0.7 , bien.mnt_revise)
					ELSE 0
                    END MNT_VTR,
					-- M65476
					-- --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
					-- --CASE WHEN substr(pf.CD_TYP_RISQ_CORP,1,6)='TRE502' THEN '1' ELSE '2'END,
					-- CASE
					-- WHEN (substr(pf.CD_TYP_RISQ_CORP,1,6) in ('TRE502', 'PRI105'))
					-- AND  s.cd_conso_cpt_crrv3 = '00472'
					-- --WHEN substr(pf.CD_TYP_RISQ_CORP,1,6) in ('TRE501', 'TRE502', 'PRI105') -- M56278 : nouvelle regle Gestion du CD_ACHAT_FIN_LOC
					-- THEN '1'
					-- --18/03/19 CDS ATOS (EMM) Mantis 47094
					-- --ELSE CASE
					--   --WHEN  substr(pf.CD_TYP_RISQ_CORP,1,6) in ('PRI105', 'TRE501')
					-- --    THEN '2'
					-- --      ELSE '0'
					-- 	  ELSE '2'
					-- --     END
					-- END  CD_ACHAT_FIN_LOC,
					-- --Fin EMM
					-- --Fin
					--'2' as CD_ACHAT_FIN_LOC,   -- M56278 (note 194976): nouvelle regle
					--DEBUT: KLxRisqLeasing (BA) - Mantis 59562: RWA GreenLease - evolution CRRV4 Leasing
					decode(o.cd_type_modele, 'GLES', '1', '2') as CD_ACHAT_FIN_LOC,
					--FIN: KLxRisqLeasing (BA) - Mantis 59562: RWA GreenLease - evolution CRRV4 Leasing
					'ECH',
					'N',
					'N',
					'L',
					'M',
					'M',
					'1',
					NULL,
					'M',
					1,
					'EUR',
					'E',
					'LEASING',
					-- Nouveaux champs
					CASE WHEN (o.cd_flag_restructuration is null OR  o.cd_flag_restructuration = 'SANS') Then '2' ELSE '1' END,
          			--- M59263
					CASE WHEN o.cd_flag_restructuration = 'RCOM' THEN
							CASE
						    	WHEN o.CD_AQR in ('C2','C3A') AND  o.TOP_PL_NPL = 'N' THEN '1'  --- M59263
						    	WHEN o.CD_AQR = 'C4' and o.TOP_PL_NPL = 'P' THEN '4' -- 12/01/2023 - KLX Risque (VDC) - Mantis 65154 - '4' si CD_AQR = 4 et top performant/non performant est P
								ELSE '5' -- 06/04/22 - KLX Risque (VDC) - Mantis 60739 - Tous les cas "autres" sont desormais mis a 5
							END --- M59263
						WHEN o.cd_flag_restructuration = 'RISQ' THEN DECODE(o.CD_AQR,'C2','1','C3A','1','5')
						ELSE '5' -- 06/04/22 - KLX Risqu (VDC) - Mantis 60739 - Tous les cas "autres" sont dÃ©sormais mis Ã¿ 5
					END  nat_cont_evenmt_crdt,  -- M59263
					--30/03/2018 CDS ATOS (EMM) Sprint 7 US 218 ANACREDIT
					--DECODE(o.TOP_PL_NPL,'N','1','P','2','4'), --ancienne implementation
					CASE 	WHEN O.CD_AQR IN ('C4') 																								THEN '4' -- AR
							WHEN O.CD_AQR IN ('C3A') AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR 	THEN '1' -- RC
							WHEN O.CD_AQR IN ('C2')  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')															THEN '1' -- RF
						ELSE '4'
					END AS sta_crdt,--M72564 - Modification regle alimentation STA_CRDT
                    /*
                    CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN '1' ELSE -- 07/09/2020 - CDS ATOS (LFD) - US 89 taiga MCO - ACR/CRR - Si TOP_ENG_DOUTEUX = 'Y' ' et donc si CD_CATEG_CPT IN ('DTX','DTCO') alors STA_CRDT = '1'
                        CASE WHEN o.TOP_PL_NPL = 'N' then '1'
					    else
					      CASE WHEN o.TOP_PL_NPL = 'P' AND o.dt_fin_valid_aqr > o.dt_arrete then '2'
					      else
					    	CASE WHEN o.TOP_PL_NPL = 'P' AND o.dt_fin_valid_aqr <= o.dt_arrete then '3'
					    	else '4'
					    	end
					      end
					    end -- 07/09/2020 - CDS ATOS (LFD) - US 89 taiga MCO
					END sta_crdt,   */
					--Fin EMM
					CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'NP' ELSE DECODE(o.TOP_PL_NPL,'N','NP','P','PE','PE') END,
					-- 15/04/2019 - CDS ATOS (LFD) - US781
					--DECODE(o.cd_flag_restructuration,'RCOM',o.DT_AQR,null),
					DECODE(o.cd_flag_restructuration,'RCOM',o.DT_MAJ_FLAG_RESTRUCT,null),
					-- FIN LFD
					DECODE(o.cd_flag_restructuration,'RISQ',o.DT_AQR,null),

					o.ID_OPERATION,
					o.ID_OPERATION,
					o.CD_TYPE_TAUX,
					o.DATE_PREM_ECH,
					DECODE(o.cd_sys_int,'KSP','EXA-360','EXB-EXB'),
					o.DT_MEL,
					'EUR',
					--12/02/2019 - CDS ATOS (SQN) US 654
					--o.crd_brut_ht-mnt_vr,
					CASE WHEN o.crd_brut_ht-mnt_vr <0 THEN 0 ELSE o.crd_brut_ht-mnt_vr END CAP_THEO_REST,
					--Fin SQN
					CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN o.DT_EXIGTE_PREM_IMPY END,
					o.DT_DEB_PALL,
					o.DT_FIN_PALL,
					o.MNT_ECH_EN_COURS,
					'EUR',
					CASE WHEN o.DT_DEB_OPE >= o.DT_ARRETE THEN o.DT_ARRETE - 1
																   ELSE o.DT_DEB_OPE
					END  DATE_DEB_ENG_RENVL,
					'1',
					o.CD_SYS_INT,
					'_' || T.cd_segment_casa || '_' || s.CD_CONSO_CPT_CRRV3 || '_' || o.cd_produit   ,
					RT.code_CASA,
					--o.taux_mrg,    16/05/19 CDS ATOS (EMM) Mantis 47711
					 --11/12/2018 CDS ATOS (SQN) Mantis 43416 - IFRS 9 Floorer les taux d'inetret negatifs a 0
								   --CASE WHEN o.valeur_taux<0 THEN 0.00001 ELSE o.valeur_taux END,
					--CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))<0 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,
					--CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))<0 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,
					--Fin SQN
					--13/05/19 CDS ATOS (EMM) Mantis 47711
					CASE WHEN nvl(o.taux_mrg,0)< 0.00001 THEN 0.00001 ELSE o.taux_mrg END,                        --TAUX_MRG_ADD
					CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_CLT_PRD_EN_CRS
					CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_CLT_OCT
					CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_INT_EFF_ORI
					--Fin EMM
					'N',
					--01/12/2017 - CDS ATOS (EMM) - Sprint 1, US 27
					--ef.dt_aqr,  ---DATE_PREM_ACT_FORB
          -- M58209 : remplace par
				  --- DATE_PREM_ACT_FORB alimentee si TOP_RESTRUCTURATION <> null et <> AR
				   CASE  WHEN O.CD_AQR = 'C4'                                                                                                THEN null      --'AR'
				         WHEN O.CD_AQR = 'C3A' AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR THEN ef.dt_aqr --'RC'
				         WHEN O.CD_AQR = 'C2'  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF'  M70812
				         --WHEN O.CD_AQR = 'C2'   OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF'
				         ELSE NULL
				   END AS DATE_PREM_ACT_FORB,
					--sf.dt_fin_valid_aqr,
					o.DATE_SORT_EFF_FORB,   --08/02/19 VDS ATOS (EMM) ANACREDIT US 497
					-- fin EMM
					--30/03/2018 CDS ATOS (EMM) Sprint 7 US 218 ANACREDIT
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR END DATE_ENTR_PER_PURG,
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12)  END DATE_SORT_PER_PURG,
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12)
					  else
						CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR end
					END DATE_ENTR_PER_PROB,
					CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,36)
					  else
						CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,24)  end
					END DATE_SORT_PER_PROB,
          -- DATE_THEO_FIN_FORB  M58209 : regle remplace par
				  CASE WHEN O.CD_AQR = 'C4'                                                                                                THEN null      --'AR'
    			     WHEN o.CD_AQR = 'C3A' AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR then ADD_MONTHS(o.DT_AQR,24)
				       WHEN o.CD_AQR = 'C2'   OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         then ADD_MONTHS(o.DT_AQR,36)
				       ELSE NULL
 					END AS DATE_THEO_FIN_FORB,
					--Fin EMM
					--20/07/2018 - CDS ATOS (LFD) - ANACREDIT US 435
					CASE WHEN o.MNT_BRUT_ORIGINE > 0 THEN o.MNT_BRUT_ORIGINE
					  WHEN o.MNT_BRUT_ORIGINE = 0 OR o.MNT_BRUT_ORIGINE < 0 then 0
					  ELSE null
					  END, -- Montant du contrat ? l'origine
					--01/12/2017 - CDS ATOS (FAD) - Sprint 1, US 23 - CRRV4.1 Instruments (A)
					--11/02/2019 - CDS ATOS (SQN) US 654
					--Case When o.MNT_BRUT_ORIGINE is not null then o.CD_DEVISE end , --Devise du montant du contrat a l'origine -- Edit du 01/06/2018 : si pas de montant, pas de devise
					CASE WHEN o.MNT_BRUT_ORIGINE IS NULL THEN 'EUR' ELSE (CASE WHEN o.MNT_BRUT_ORIGINE IS NOT NULL THEN o.CD_DEVISE END) END DEV_MNT_CONTRAT_ORIGINE,
					--Fin SQN
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					DECODE( T.CD_CATEG_CPT, 'DTCO', T.DT_CHG_CATEG_CPT , NULL) -- Date depassage en douteux compromis
					--null DT_PASSAGE_DOUTEUX_COMPROMIS  --US41
					-- FIN LFD
					-- fin FAD
					--05/06/2020 - CDS ATOS (LFD) - US 41 MCO/ANACREDIT
					-- 24/01/2018 CDS Atos (JMP) ANACREDIT US33
					  , pack_alim_tab_envoi_crrv4_new.f_cd_motif_sco_lc0267(
					  T.CD_CATEG_CPT,
					  t.cd_motif_sco,
			  -- On ne tient compte du nombre de jours d'impay?s que si, comme pour le calcul de la date d'exigibilite du premier impaye,
			  --    la somme des montants des impayes est strictement poositive.
					  CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN o.dt_arrete - o.DT_EXIGTE_PREM_IMPY END,
					  t.NOTE_BALOISE)
					  -- Fin 24/01/2018 CDS Atos (JMP) ANACREDIT US33
					  --Fin JMP
					--, null CD_MOTIF_SCO_LC0267   --US41
					-- FIN LFD
					-- 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					, o.MNT_PREM_DBLQ_FONDS
					, o.DT_PREM_DBLQ_FONDS
					--12/02/2019 - CDS ATOS (SQN) US 654
					--, CASE WHEN NVL(o.MNT_PREM_DBLQ_FONDS,0) > 0 THEN 'EUR' END
					, NVL((CASE WHEN NVL(o.MNT_PREM_DBLQ_FONDS,0) > 0 THEN 'EUR' END),o.CD_DEVISE) --DEVISE_PREM_DBLQ_FONDS
					--Fin SQN
					-- Fin 09/05/2018 CDS Atos (JMP) ANACREDIT Sprint 9 US24 donn?es premier deblocage de fonds
					--05/02/2019 - CDS ATOS (SQN) US 662
					, CASE  WHEN (T.CD_CATEG_CPT='DTX' or T.CD_CATEG_CPT ='DTCO')
						THEN T.DT_CHG_CATEG_CPT
						ELSE NVL(o.DT_CHG_PE_NPE, NVL(o.DT_DEB_OPE,o.DT_DEB_VALIDITE_AUTO))
						END               --DT_PL_NPL
					, CASE  WHEN (T.CD_CATEG_CPT = 'DTX' or T.CD_CATEG_CPT = 'DTCO')
						THEN 'B3'
						ELSE 'B1'
						END               --BUCKET_IFRS9
					, CASE  WHEN o.DT_DEB_OPE >= o.DT_ARRETE
						THEN o.DT_ARRETE - 1
									ELSE o.DT_DEB_OPE
						END               --DT_DISPO_FONDS
					--, T.CD_PAYS_RESIDENCE         --CD_PAYS_JURIDICTION
					, T.CD_PAYS_RISQUE --CD_PAYS_JURIDICTION -- BALE4 P1 22.66 pos 2834
					, CASE  WHEN o.DT_DEB_OPE >= o.DT_ARRETE
						THEN o.DT_ARRETE - 1
									ELSE o.DT_DEB_OPE
						END               --DT_SIGNATURE
					--27/02/2019 - CDS ATOS (SQN) - US 747
					, CASE  WHEN (o.dt_arrete - o.dt_exigte_prem_impy) > 0 AND (CASE WHEN NVL(O.MNT_SOLDE_HT_EXIGIB_K,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_I,0) + NVL(O.MNT_SOLDE_HT_EXIGIB_AUTRE,0) > 0 THEN 'Y' ELSE 'N' END) = 'Y' THEN (o.dt_arrete - o.dt_exigte_prem_impy)
						ELSE 0
						END               --NB_JOURS_RETARD
					, CASE  WHEN o.MNT_SOLDE_HT_EXIGIB_IRE < 0 THEN 0
						ELSE o.MNT_SOLDE_HT_EXIGIB_IRE
						END               --MNT_IDEMNITE_RES
					, CASE  WHEN o.MNT_SOLDE_HT_EXIGIB_IRE is not null
						THEN o.CD_DEVISE
						ELSE null
						END               --CD_DEV_MNT_INDEMNITE
					--Fin SQN
					-- 18/02/2019 - CDS ATOS (GBD) - US731 -->
					, 'I' ORGA_NOTATION_ORIG
					, '3' IND_RMB_ANTICIPE   -- =3 Pour 'NAT02' cad pour flag_hn=N (flag_hn est /defaut ? N ! ; cest ds le script hors NAT02 qu'on insert flag_hn=O)
					, 'N' ELIGIB_PRUDENT_VAL -- =N Pour 'NAT02'
					-- 27/03/2019 - CDS ATOS (LFD) - US 768
							--, '1' IND_MOBIL_ACTIF
					--,CASE WHEN O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++' OR O.INDIC_PSE IN ('P1','P2') THEN '2' ELSE '1' END IND_MOBIL_ACTIF --CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
					-- FIN LFD
					-- 18/02/2019 - CDS ATOS (GBD) - US731 <--
					--11/03/2019 - CDS ATOS (SQN) - US 748
					, '0' --IND_OPE_EFFET_LEVIER
					--Fin SQN
					-- 26/11/2020 - CDS ATOS (CPD) - US17
					, o.MNT_SUBV_HT
					, o.MNT_AVP_HT
					--fin CPD
					-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
					,CASE WHEN O.CD_SOC_JURI IN ('09','31') THEN '1' ELSE '2' END IND_ELIGI_OUTI_CTRAL_ANACRD
					,CASE WHEN O.CD_SOC_JURI IN ('09','31') THEN '02' END MOTIF_EXCLU_ANACREDIT
					,CASE WHEN o.MNT_BRUT_ORIGINE > 0 THEN o.MNT_BRUT_ORIGINE
					  WHEN o.MNT_BRUT_ORIGINE = 0 OR o.MNT_BRUT_ORIGINE < 0 then 0
					  ELSE null
					END MNT_ENG_DT_SIGN_CTRT
					,'N' IND_RESPO_SOLIDAIRE
					-- FIN LFD
					--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88

					--Si les 3 caratÃ¿Â¿Â½res Ã¿Â¿Â½ partir de la deuxieme position du champ BTR_OPERATION.COTATION_BDF in ('4+','3','3+','3++') ou si BTR_OPERATION.INDIC_PSE in ('P1','P2') alors renseigner '3' sinon garder l'alimenation actuelle.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '3' 	ELSE '1'	END IND_MOBIL_ACTIF
					--Si les 3 caratÃ¿Â¿Â½res Ã¿Â¿Â½ partir de la deuxieme position du champ BTR_OPERATION.COTATION_BDF in ('4+','3','3+','3++') ou si BTR_OPERATION.INDIC_PSE in ('P1','P2') ET IND_MOBIL_ACTIF='3' Alors 'Y' sinon 'N'
					--IND_MOBIL_ACTIF Ã¿Â¿Â½tant dÃ¿Â¿Â½ja renseignÃ¿Â¿Â½ au dessus et les condition Ã¿Â¿Â½tant les meme pas besoin de le prendre en compte.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN 'Y' 	ELSE 'N' 	END ELIG_MOB_BANQUE_CENTRALE
					--SI IND_MOBIL_ACTIF='3' ET ELIG_MOB_BANQUE_CENTRALE = 'Y' alors 1 sinon laisser vide. Ces deux champs sont renseignÃ¿Â¿Â½s au dessus juste Ã¿Â¿Â½ prendre la condition du 1er champs.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '1' 	ELSE NULL	END REF_MOB_ACTIF
					--SI IND_MOBIL_ACTIF='3' ET ELIG_MOB_BANQUE_CENTRALE = 'Y' ET REF_MOB_ACTIF = '1' alors '404' sinon laisser vide. Ces champs sont renseignÃ¿Â¿Â½s au dessus juste Ã¿Â¿Â½ prendre la condition du 1er champs.
					,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '404' 	ELSE NULL 	END CD_ORGA_MOBIL

					-- 23/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
					--,'N' IND_ELIGB_ACTIF_IMM_BC
					-- Fin CPD
					--FIN MNE
					--CDS_ATOS (LFD) - 18/06/2021 - US 91 CRRV4.3
					,CASE WHEN NVL(decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),0) <> 0 AND BSR.CD_PAYS = 'FR' THEN BSR.CD_POSTAL END CD_COMMUNE_BIEN_FINAN
					,CASE WHEN NVL(decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),0) <> 0 THEN NVL(BSR.CD_PAYS,'FR') END CD_PAYS_BIEN_FINAN --Mantis 71367
					-- FIN LFD
					--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
					,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE
					--FIN MNE
					--,o.IND_ISF IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
					,o.MOTIF_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.22
					,o.DT_DEBUT_MRTR-- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.23
					,o.DUREE_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.29
					,o.STATUT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.25
					,o.IND_MRTR_LEGISLATIF -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.26
					,o.IND_MRTR_CONTRACTUEL -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.27
					,o.CHAMP_APPL_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.28
					,o.MNT_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.30
					,o.DEV_MRTR -- KLX-GOMESHU - BALE4 - 19/01/2024 - P1 21.31
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN
						CASE WHEN HB.MNT_IEC > 0  THEN 'Y' ELSE 'N' END
					 ELSE NULL END IND_EXPO_ADC -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.39
					,bien.MNT_LTV_VV_ACT LTV_RATIO -- KLX-GOMESHU - BALE4 - 15/02/2024 - P1 22.43
					,(bien.MNT_ETV_VV_ACT)*100 ETV_RATIO-- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.43
					,CASE WHEN (pf.CD_TYP_RISQ_CORP LIKE 'EQU%' OR pf.CD_TYP_RISQ_CORP IN ('ISS200', 'TRE405', 'TRE406') ) THEN 'N' ELSE NULL END IND_INVEST_CAPITAL_RISQ --P1 21.57
					,CASE WHEN (pf.CD_TYP_RISQ_CORP LIKE 'EQU%' OR pf.CD_TYP_RISQ_CORP IN ('ISS200', 'TRE405', 'TRE406') ) THEN 'N' ELSE NULL END IND_INVEST_PROG_LEGISLATIF --P1 21.58
					,CASE WHEN pf.CD_TYP_RISQ_CORP = 'EQU101' THEN 'Y' ELSE NULL END IND_TITRE_PARTICIP --P1 21.79
					,DECODE(o.CD_TYPE_PRODUIT,'ASR','N','Y') IND_OPE_AVEC_RECOURS -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.88
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502') ) THEN '2' ELSE '0' END USAGE_BIEN_FINANCE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 8.13
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.VILLE ELSE NULL END COMMUNE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.71
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END NUM_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.72
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_2_ADR_ACT_CBI ELSE NULL END EXTENSION -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.73
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END TYPE_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.74
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END LIB_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.75
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN NULL ELSE NULL END LIEU_DIT -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.76
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LATITUDE ELSE NULL END LATITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.77
					,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LONGITUDE ELSE NULL END LONGITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P1 21.78
					,CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN 'Y'
						  WHEN pf.CD_TYP_RISQ_CORP = 'TRE501' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN 'Y'
					ELSE 'N' END IND_UCC --P1 21.66
					,CASE WHEN ( pf.CD_TYP_RISQ_CORP LIKE 'VAR%' AND pf.CD_TYP_RISQ_CORP NOT IN ('VAR105','VAR302'))
						THEN 'JVR' ELSE NULL END CLASS_CPT_ELEMENT_COUV_DERIVE --P1 21.80
					,CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN '1'
						  WHEN pf.CD_TYP_RISQ_CORP = 'TRE501' AND O.CD_SOC_JURI IN ('06','09') AND O.CD_SYS_INT ='DE' THEN '1'
					ELSE NULL END NIV_RISQUE_CRR3 --P1 21.68
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN immeuble.CD_TYPE_BIEN_COMM ELSE NULL END CD_TYPE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.86
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN emplace_bien.CD_EMPLACE_BIEN_COMM ELSE NULL END CD_EMPLACE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P1 21.87
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00936','00399','00472') ) THEN t.DBT_SRVC_RT ELSE NULL END TX_DSCR -- BALE4 - P1 21.81
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00936','00399','00472') ) THEN t.DBT_SRVC_RT_12M ELSE NULL END TX_DSCR_PREC -- BALE4 - P1 21.82
					,CASE WHEN ( PF.CD_TYP_RISQ_CORP IN ('TRE203','TRE207','TRE206') OR PF.CD_TYP_RISQ_CORP LIKE 'VAR%' OR PF.CD_TYP_RISQ_CORP LIKE 'INT%' ) THEN 'N' ELSE NULL END IND_ACCORD_NETTING -- KLX-GOMESHU - BALE4 - 30/04/2024 - P1 30.23
					,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502') ) THEN bien.MNT_ACQ_HT_ACT ELSE NULL END MNT_ACQUISITION -- KLX-BARTOLMI - QDD - Mantis 71368
					,CASE WHEN TABLE_AUX_31_21.FLAG_ASCR_PARI = 'O' 				THEN '03'
						WHEN PF.CD_TYP_RISQ_CORP in ('PRI105', 'TRE502') and O.dt_mel is not null THEN '01'
						WHEN PF.CD_TYP_RISQ_CORP in ('TRE504', 'TRE501') and O.dt_mel is not null THEN '02'
						ELSE '04' END CDTYPEGARPRINCOCTROI -- P1 31.21 M71371
					,NULL CD_METH_IFRS9_PD_ORIG -- projet OMP - sous-tache SIRL-279 :: ajout du champ P1 2.99
			    FROM BTR_OPERATION                  o,
					RS_SOCIETE_JURIDIQUE           s,
					REF_TAUX_ARPSON                     RT,
					BTR_TIERS                      T,
					BTR_HORS_BILAN hb,
					RS_FAMILLE_IMMEUBLE			immeuble,--BALE4 P1 21.86
					RS_CORRES_SIT_GEO_BIEN_COMM emplace_bien,--BALE4 P1 21.87
				   ( select
				   		ope.id_operation,
				   		'O' FLAG_ASCR_PARI
				   		FROM
				   		rs_type_garantie rs,
				   		btr_surete_pers pers,
				   		btr_operation ope
				   		WHERE rs.id_type_garantie =pers.id_type_garantie
				   		AND pers.id_operation = ope.id_operation
				   		AND rs.id_famille_garantie in ('ASCR', 'PARI') ) TABLE_AUX_31_21,
					--M65476
					--(select cd_sys_int, id_operation, sum(MNT_VTR_PDR) MNT_VTR_PDR, sum(MNT_VV_ACT) MNT_VV_ACT,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'ATNL','1','LOUE','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act  from btr_surete_reelle group by cd_sys_int, id_operation) bien,
					(select cd_sys_int, id_operation, sum(MNT_VTR_PDR) MNT_VTR_PDR, Sum(MNT_VV_ACT) MNT_VV_ACT, sum(MNT_ACQ_HT_ACT) MNT_ACQ_HT_ACT, sum(mnt_revise) mnt_revise, sum(MNT_ETV_VV_ACT) MNT_ETV_VV_ACT, sum(MNT_LTV_VV_ACT) MNT_LTV_VV_ACT, min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'ATNL','1','LOUE','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act  from btr_surete_reelle group by cd_sys_int, id_operation) bien,
					--M65476
					RS_CORRES_PRD_FIN_TYP_RISQ_CRP pf,
					(SELECT id_operation, cd_sys_int, id_tiers, cd_pcec_crd, cd_pcec_icne, nato_crd,CD_PCEC_K_A,CD_PCEC_I
					   FROM btr_hors_bilan o,
												   rs_corres_pcec pc
					   WHERE o.cd_produit = pc.cd_produit
					   AND pc.CD_PHASE       = 'IEC'
					) pcec,
					AUT_COR_OPE_NUM_DEC_BIS                NU,
					(SELECT CD_SOC_JURI,
							CD_SEGMENT,
							cd_method  , trt_moteur
					   FROM RS_METHO_BALE_SOC_SEG
					) methodo,
						 --01/12/17 CDS ATOS (EMM) Sprint 1 US 27
					(select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
					cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
					from his_forb_btr_operation hisb
					where hisb.cd_aqr IN ('C2','C3A')
					and hisb.dt_arrete between hisb.dt_aqr and hisb.dt_fin_valid_aqr
					and hisb.dt_aqr = (select min(hist.dt_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation and hist.cd_aqr IN ('C2','C3A'))
					)ef
					/*,
					--14/04/18 CDS ATOS (EMM) Sprint 8 US 319
					(select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
					cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
					from his_forb_btr_operation hisb
					where hisb.cd_aqr IN ('C2','C3A')
					and dt_fin_valid_aqr = add_months(dt_arrete, -1)
					and hisb.dt_fin_valid_aqr = (select max(hist.dt_fin_valid_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation)
					)sf
					*/
					--Fin EMM
					,(SELECT DISTINCT CD_PAYS, CD_POSTAL, ID_OPERATION, VILLE, LIG_1_ADR_ACT_CBI, LIG_2_ADR_ACT_CBI, LATITUDE, LONGITUDE, CD_SIT_GEO_N1, CD_SIT_GEO_N2, CD_FAMILLE_IMM FROM BTR_SURETE_REELLE)	BSR 	-- 18/06/2021 - CDS ATOS (LFD) - US 91 CRRV4.3
					,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			   WHERE o.CD_SOC_JURI = s.CD_SOC_JURI
					 AND   o.ID_TIERS    = T.ID_TIERS
					 and   o.id_operation = hb.id_operation (+)
					 and   o.ID_OPERATION = TABLE_AUX_31_21.id_operation (+) -- M7371
					 and   o.cd_sys_int   = hb.cd_sys_int (+)
					 and hb.mnt_iec > 0
					 AND   o.CD_PRODUIT  = pf.CD_PRODUIT
					 AND   o.ID_OPERATION = pcec.id_operation (+)
					 AND      o.code_index_taux=RT.code_index_taux (+)
					 AND   o.CD_SYS_INT   = pcec.cd_sys_int (+)
					 AND   o.ID_TIERS     = pcec.id_tiers (+)
					 and   o.CD_SYS_INT   = bien.cd_sys_int (+)
					 AND   o.ID_OPERATION = bien.id_operation (+)
					 AND   o.CD_SYS_INT   = NU.CD_SYS_INT   (+)
					 AND   o.ID_OPERATION = NU.ID_OPERATION (+)
					 AND   BSR.CD_FAMILLE_IMM = immeuble.CD_FAMILLE_IMM(+) --BALE4 P1 21.86
					 AND   BSR.CD_FAMILLE_IMM = emplace_bien.CD_FAMILLE_IMM(+) --BALE4 P1 21.87
					 AND   BSR.CD_SIT_GEO_N1 = emplace_bien.CD_SIT_GEO_N1(+) --BALE4 P1 21.87
					 AND   BSR.CD_SIT_GEO_N2 = emplace_bien.CD_SIT_GEO_N2(+) --BALE4 P1 21.87
					 AND   T.CD_TYPE_SGMT        = 'CORP'
					 AND   s.CD_CONSO_CPT_CRRV3 != '99999'
					 And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
					 and o.id_operation = ef.id_operation (+) --01/12/17 EMM
					 and o.cd_sys_int   = ef.cd_sys_int(+)  --29/03/18 EMM
					 --08/02/19 VDS ATOS (EMM) ANACREDIT US 497  Inhibition de cette partie car le sous-ensemble 'sf' n'existe plus
					 --and o.id_operation = sf.id_operation (+) --01/12/17 EMM
					 --and o.cd_sys_int   = sf.cd_sys_int(+)  --29/03/18 EMM
					 --Fin EMM
					 And s.cd_soc_juri     = methodo.cd_soc_juri
					 AND (Case when hb.MNT_IEC > 0 then hb.id_operation_sig else o.id_operation end) = BSR.ID_OPERATION (+) 	-- 18/06/2021 - CDS ATOS (LFD) - US 91 CRRV4.3
					 AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
					 AND pf.CD_TYP_RISQ_CORP = PARAM.VAL_PARAM_1 --ENG_CORP_P1.CD_TYPE_RISQUE = PARAM_MULTIDIM_GENERIQUE.VAL_PARAM_1
					;

				   COMMIT;

--
		W_TABLE := 'ENG_CORP_P1 (2.18)'; -- KLX-GOMESHU - BALE4 - 08/04/2024 - P1 2.18
		merge
		 into ddrex.eng_corp_p1 P1
		using (SELECT DISTINCT ID_OPERATION
				FROM ENG_FIPUNI_TAXONOMIE
				WHERE IND_FINANCEMENT_PROJETS = 'Y'
		) peri
		   on (peri.ID_OPERATION  = P1.ID_ENGAGEMENT )
		 when matched then
		   update
			  set P1.CD_PORTEFEUILLE_BALE2 = '061';
		   commit;

		   ----------------------------------------------------------------------------------
		   --EVOL CRRV4 - LOT FEVRIER 2016 : DEDUIRE LES MONTANTS DE GARANTIE DE SYNDICATION DU MONTANT DE CRD
		   ----------------------------------------------------------------------------------
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
           W_TABLE := 'ENG_CORP_P1 (4)';
		   Update Eng_Corp_p1   P1
		   Set (p1.mnt_Crd, P1.mnt_solde) =
			   (Select  DECODE(sign(nvl(p1.mnt_Crd,0)-sum(nvl(sp.mnt_garantie,0))),
															  -1,0, nvl(p1.mnt_Crd,0)-sum(nvl(sp.mnt_garantie,0)) ),
											  DECODE(sign(nvl(p1.mnt_Crd,0)-sum(nvl(sp.mnt_garantie,0))),
															  1,p1.mnt_solde, DECODE(SIGN(P1.mnt_solde-ABS(nvl(p1.mnt_Crd,0)-sum(nvl(sp.mnt_garantie,0)))), -1,0, (P1.mnt_solde-ABS(nvl(p1.mnt_Crd,0)-sum(nvl(sp.mnt_garantie,0)))))
															  )
			   From BTR_SURETE_PERS sp, RS_TYPE_GARANTIE tg
			   Where  tg.id_type_garantie = sp.id_type_garantie
			   And   tg.id_type_garantie in ('AUSY', 'CASY', 'CLSY')
			   And sp.id_operation=P1.id_engagement
			   )
		   where exists  (Select 1
			   From BTR_SURETE_PERS sp, RS_TYPE_GARANTIE tg
			   Where  tg.id_type_garantie = sp.id_type_garantie
			   And   tg.id_type_garantie in ('AUSY', 'CASY', 'CLSY')
			   And sp.id_operation=P1.id_engagement
			   )
		   ;
		   COMMIT;

		   --UPDATE si taux inconnu du referential
           W_TABLE := 'ENG_CORP_P1 (5)';
		   UPDATE ENG_CORP_P1 SET TYPE_TAUX='F',taux_mrg_add=null,taux_mrg_mult=null,prd_rev_taux_nbr=null,prd_rev_taux_unit_tmp=null WHERE ind_ref is null;
		   COMMIT;

		   --12/02/2019 - CDS ATOS (SQN) US 654
           W_TABLE := 'ENG_CORP_P1 (6)';
		   UPDATE ENG_CORP_P1 SET prd_rev_taux_nbr=0 WHERE prd_rev_taux_nbr is null;
		   COMMIT;
		   --Fin SQN

           W_TABLE := 'ENG_CORP_P1 (7)';
		   Update Eng_Corp_p1   P1
				 Set (p1.mnt_Crd, P1.mnt_solde) =
				 (Select  DECODE(sign(nvl(p1.mnt_Crd,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0))),
												-1,0, nvl(p1.mnt_Crd,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0)) ),
												DECODE(sign(nvl(p1.mnt_Crd,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0))),
												1,p1.mnt_solde, DECODE(SIGN(P1.mnt_solde-ABS(nvl(p1.mnt_Crd,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0)))), -1,0, (P1.mnt_solde-ABS(nvl(p1.mnt_Crd,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0)))))
												)
				 From BTR_OPERATION o
				 Where o.id_operation=P1.id_engagement
				 )
		   where exists  (Select 1
				 From BTR_OPERATION o
				 Where o.id_operation=P1.id_engagement
				 )
		   ;
		   COMMIT;

		   --25/10/2018 CDS Atos (EMM) US 542
           W_TABLE := 'ENG_CORP_P1 (8)';
		   UPDATE Eng_Corp_p1   P1
		   SET P1.DT_PREM_DBLQ_FONDS = (SELECT CASE WHEN BTR.DT_PREM_DBLQ_FONDS is null AND P1.MNT_CRD is not null THEN P1.DT_DEBUT_ENG
							  else CASE WHEN BTR.DT_PREM_DBLQ_FONDS is not nulL AND BTR.DT_PREM_DBLQ_FONDS < P1.DT_DEBUT_ENG THEN P1.DT_DEBUT_ENG
									else CASE WHEN BTR.DT_PREM_DBLQ_FONDS is not null AND BTR.DT_PREM_DBLQ_FONDS >= P1.DT_DEBUT_ENG THEN BTR.DT_PREM_DBLQ_FONDS
									  END
								END
							END
						FROM BTR_OPERATION BTR
						WHERE BTR.ID_OPERATION=P1.ID_ENGAGEMENT );
		   COMMIT;
		   --Fin EMM

		   -- 29/10/2018 - CDS ATOS (LFD) - ANACREDIT US 542
           W_TABLE := 'ENG_CORP_P1 (9)';
		   UPDATE ENG_CORP_P1 P1
		   SET P1.DT_PREM_DBLQ_FONDS = DT_DEBUT_ENG
		   WHERE MNT_CRD is not null AND DT_PREM_DBLQ_FONDS is null;
		   COMMIT;
		   --FIN LFD

           W_TABLE := 'ENG_CORP_P1 (10)';
		   UPDATE ENG_CORP_P1 set MNT_RISQUE=MNT_CRD WHERE CD_TYPE_RISQUE='TRE401';
		   COMMIT;

           W_TABLE := 'ENG_CORP_P1 (11)';
		   Update Eng_Corp_p1   P1
						   Set OBJ_FINANCIE =
			  (SELECT CASE WHEN (P1.CD_NATURE_OPE like 'NA02%' AND o.CD_produit ='CBI') THEN '04'
			   ELSE '97' END
			  From BTR_OPERATION o
			  Where o.id_operation=P1.id_engagement
			  )
		   where exists  (Select 1
					  From BTR_OPERATION o
					  Where o.id_operation=P1.id_engagement
					  )
		   ;
		   COMMIT;

			  --11/02/2019 - CDS ATOS (SQN) US 654
              W_TABLE := 'ENG_CORP_P1 (12)';
			  UPDATE eng_corp_p1 SET OBJ_FINANCIE = 97 WHERE OBJ_FINANCIE is null;
			  COMMIT;
			  --Fin SQN

        W_TABLE := 'ENG_CORP_P1 (13)';
		  update eng_corp_p1 set ELI_OUT_MUT_PROV ='1';
		 update eng_corp_p1 set ELI_OUT_MUT_PROV_S ='1';

        W_TABLE := 'ENG_CORP_P1 (14)';
		   Update Eng_Corp_p1   P1
				Set (ELI_OUT_MUT_PROV,ELI_OUT_MUT_PROV_S) =
		  (
			 Select distinct '4','4'
			 FROM
			 btr_tiers T,
			 TIE_TIERS_C1_C5 c1
			 where
			 T.id_tiers = c1.id_tiers
			 AND p1.cd_conso_cpt = c1.cd_conso_cpt
			 AND c1.cd_type_relation='C'
			 AND c1.id_tiers_calc=p1.id_tiers_calc
			 AND t.cd_role_tiers='C'
			 AND p1.flag_hn='N'
			 AND c1.flag_hn='N'
			 AND c1.a_extraire='O'
			 AND (P1.CD_NATURE_OPE not like 'NA10%'
							 AND P1.CD_NATURE_OPE <> 'NA311'
							 AND P1.CD_NATURE_OPE <> 'NAT05')
			 AND nvl(c1.top_tiers_dtx,0) = 0
		  )
		 where exists  (Select 1
						 FROM
			 btr_tiers T,
			 TIE_TIERS_C1_C5 c1
						  where
						  T.id_tiers = c1.id_tiers
						  AND p1.cd_conso_cpt = c1.cd_conso_cpt
						  AND c1.cd_type_relation='C'
						  AND c1.id_tiers_calc=p1.id_tiers_calc
						  AND t.cd_role_tiers='C'
						  AND p1.flag_hn='N'
						  AND c1.flag_hn='N'
						  AND c1.a_extraire='O'
		AND (P1.CD_NATURE_OPE not like 'NA10%'
						  AND P1.CD_NATURE_OPE <> 'NA311'
						  AND P1.CD_NATURE_OPE <> 'NAT05')
			   AND nvl(c1.top_tiers_dtx,0) = 0
													 )
			 ;

		 COMMIT;


		--Mantis 42098 CDS_ATOS(CML) 23/02
		--Pour tous les types de risque:Alimenter p1.CLA_COMP_REF_ACT ? l?identique de p1.CLA_COMP_ACT_IFRS9
		--update eng_corp_p1 p1 set (p1.ELI_OUT_MUT_PROV,p1.CLA_COMP_ACT_IFRS9,p1.CLA_COMP_ACT_NATIONALE,P1.CLA_COMP_REF_ACT) =
		--                                                               (select distinct ELIGIBILITE_OMP,CLASS_COMPTABLE_IFRS9,CLASS_COMPTABLE_NORME_LOCALE,CLASS_COMPTABLE_IAS39 from ref_pcco_pcec_sap sap where p1.pcco_crd=sap.num_pcco)
		--                                                               where p1.pcco_crd is not null;     modifier par mantis
        W_TABLE := 'ENG_CORP_P1 (15)';
		update eng_corp_p1 p1 set (p1.ELI_OUT_MUT_PROV,p1.CLA_COMP_ACT_IFRS9,p1.CLA_COMP_ACT_NATIONALE,P1.CLA_COMP_REF_ACT) =
					   (select distinct ELIGIBILITE_OMP,CLASS_COMPTABLE_IFRS9,CLASS_COMPTABLE_NORME_LOCALE,CLASS_COMPTABLE_IFRS9 from ref_pcco_pcec_sap sap where p1.pcco_crd=sap.num_pcco)
					   where p1.pcco_crd is not null;
		commit;

		--Si p1.CLA_COMP_ACT_IFRS9_S est renseign? alors: Alimenter p1.CLA_COMP_REF_ACT_S ? l?identique de p1.CLA_COMP_ACT_IFRS9_S
		--update eng_corp_p1 p1 set (p1.ELI_OUT_MUT_PROV_S,p1.CLA_COMP_ACT_IFRS9_S,p1.CLA_COMP_ACT_NATIONALE_S,P1.CLA_COMP_REF_ACT_S) =
		--                (select distinct ELIGIBILITE_OMP,CLASS_COMPTABLE_IFRS9,CLASS_COMPTABLE_NORME_LOCALE,CLASS_COMPTABLE_IAS39 from ref_pcco_pcec_sap sap where p1.pcco_mnt_solde=sap.num_pcco)
		--                 where p1.pcco_mnt_solde is not null;        modifier par mantis
        W_TABLE := 'ENG_CORP_P1 (16)';
		update eng_corp_p1 p1 set (p1.ELI_OUT_MUT_PROV_S,p1.CLA_COMP_ACT_IFRS9_S,p1.CLA_COMP_ACT_NATIONALE_S,P1.CLA_COMP_REF_ACT_S) =
						(select distinct ELIGIBILITE_OMP,CLASS_COMPTABLE_IFRS9,CLASS_COMPTABLE_NORME_LOCALE,CLASS_COMPTABLE_IFRS9 from ref_pcco_pcec_sap sap where p1.pcco_mnt_solde=sap.num_pcco)
						 where p1.pcco_mnt_solde is not null;
		commit;
		--fin mantis 42098

        W_TABLE := 'ENG_CORP_P1 (17)';
		 UPDATE ENG_CORP_P1 SET date_prem_ech=dt_debut_eng where date_prem_ech is null;
		 COMMIT;

        W_TABLE := 'ENG_CORP_P1 (18)';
		 UPDATE ENG_CORP_P1 P1
										 SET DT_FIN_ENG=dt_arrete+30 where DT_FIN_ENG is null or  P1.DT_FIN_ENG < P1.dt_arrete ;
						 COMMIT;
						 UPDATE ENG_CORP_P1 P1
										 SET MATURITE_EFF= (CASE WHEN P1.DT_FIN_ENG >= P1.dt_arrete THEN (P1.DT_FIN_ENG - P1.dt_arrete)/365
																						  END ) ;
						COMMIT;


        W_TABLE := 'ENG_CORP_P1 (19)';
		update eng_corp_p1 p1 set mnt_ltv = (select DECODE(sum(nvl(MNT_VTR_PDR,0)),0,null,(NVL(P1.MNT_CRD, 0)+NVL(P1.MNT_SOLDE, 0))/sum(nvl(MNT_VTR_PDR,0)))*100 from BTR_SURETE_REELLE where p1.id_engagement=id_operation group by id_operation);
		commit;

		--PRAC
        W_TABLE := 'ENG_CORP_P1 (20)';
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_TX='RACBM0001' WHERE CD_CONSO_CPT IN ('00357','00370','00372');
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_TX='RACBI0001' WHERE CD_CONSO_CPT IN ('00472');
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_TX='RAFIP0001' WHERE CD_CONSO_CPT IN ('00399','00936');
		COMMIT;

		--CCF
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
        W_TABLE := 'ENG_CORP_P1 (21)';
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_CCF='CCCALL0060' WHERE CD_CONSO_CPT IN ('00399','00936');
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_CCF='CCCALL0050' WHERE CD_CONSO_CPT IN ('00472');
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_CCF='CCCALL0020' WHERE CD_CONSO_CPT IN ('00357','00370','00372') AND CD_METH_IFRS9_CCF IS NULL AND EXISTS (SELECT 1 FROM BTR_OPERATION WHERE ID_OPERATION=ID_ENGAGEMENT AND CD_PRODUIT in ('LOCF'));
		UPDATE ENG_CORP_P1 SET CD_METH_IFRS9_CCF='CCCALL0010' WHERE CD_CONSO_CPT IN ('00357','00370','00372') AND CD_METH_IFRS9_CCF IS NULL;
		COMMIT;

-- =======================================================================================================
--  DEBUT :: Maj des rg du perimetre LGD - corporate P1
-- =======================================================================================================
---- RG_08
----    perimetre CORPORATE
---- ET societe est 'FINAMURï¿½
---- ET identifiant du type de garantie est ('CA','CASY','CLSY','FEI1','GPDB','HSBC','LCL','PART')
---- ET avec une quotepart garant strictement superieure a 0
---- ET le perimetre des natures des operations est 'NAT02'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET la garantie est valide
	W_TABLE := 'TABLE: eng_corp_p1 - RG_08 :: LGD';
	update eng_corp_p1 p1
       set p1.cd_meth_ifrs9_lgd  = 'LGCBI_GAR1'
	 where nvl(p1.flag_hn,'N')   = 'N'
 	   and p1.cd_conso_cpt      in ('00472')
	   and p1.cd_meth_ifrs9_lgd is null
	   and
	 exists (select 1
			   from btr_surete_pers sur
			  where sur.id_operation             = p1.id_engagement
			    and nvl(sur.quote_part_garant,0) > 0
			    and sur.id_type_garantie        in ('CA','CASY','CLSY','FEI1','GPDB','HSBC','LCL','PART')
			    and sur.dt_arrete
		    between sur.dt_deb_valid_garant
			    and nvl(sur.dt_fin_valid_garant,to_date('31122099','ddmmyyyy')));

---- RG_09
----    perimetre CORPORATE
---- ET societe est 'FINAMURï¿½
---- ET le perimetre des natures des operations est 'NAT02'
---- ET identifiant du type de garantie n'est pas ('CA','CASY','CLSY','FEI1','GPDB','HSBC','LCL','PART')
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET (pas de garantie dans BTR_SURETE_PERS
---- OR engagement avec une quotepart garant egal a 0
---- OR garantie est invalide)
	W_TABLE := 'TABLE: eng_corp_p1 - RG_09 :: LGD';
    update eng_corp_p1 p1
       set p1.cd_meth_ifrs9_lgd  = 'LGCBI_GAR0'
	 where nvl(p1.flag_hn,'N')   = 'N'
       and p1.cd_conso_cpt      in ('00472')
	   and p1.cd_meth_ifrs9_lgd is null
	   and ( -- pas besoin d'indiquer que le type de garantie ne doit pas etre dans
       not   -- la liste mentionnee car la RG_01 a ete appliquee et donc cela est assure
    exists (select 1
              from btr_surete_pers sur
             where sur.id_operation = p1.id_engagement)
	    or
    exists (select 1
              from btr_surete_pers sur
             where (sur.id_operation            = p1.id_engagement
		       and nvl(sur.quote_part_garant,0) = 0)
                or sur.dt_arrete
               not
           between sur.dt_deb_valid_garant
               and nvl(sur.dt_fin_valid_garant,to_date('31122099','ddmmyyyy'))));

---- RG_10
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif est ('A','R','C','L','T','6')
---- ET le type de delegation est different de 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
	W_TABLE := 'TABLE: eng_corp_p1 - RG_10 :: LGD';
	update eng_corp_p1 p1
       set p1.cd_meth_ifrs9_lgd  = 'LGCBM_COR2'
	 where nvl(p1.flag_hn,'N')   = 'N'
	   and p1.cd_conso_cpt      in ('00370','00357')
	   and p1.cd_meth_ifrs9_lgd is null
	   and
	exists (select 1
			  from btr_operation op
			 where op.id_operation                 = p1.id_engagement
			   and nvl(op.type_delegation,'NULL') != 'CRCAGLES')
	   and
	exists (select 1
              from (select sur.id_operation                             id_operation
                          ,sur.id_actif                                 id_actif
                          ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                          ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                      from btr_surete_reelle sur
                     where sur.id_operation = p1.id_engagement) sr
             where sr.act_vtr_max       = 1 --- actif avec la plus grande valeur de VTR
               and sr.id_operation      = p1.id_engagement
               and sr.cd_famille_actif in ('A','R','C','L','T','6'));

---- RG_11
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif n'est pas ('A','R','C','L','T','6')
---- ET le type de delegation est different de 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
---- OR (pas d'engagement dans BTR_SURETE_REELLE)
	W_TABLE := 'TABLE: eng_corp_p1 - RG_11 :: LGD';
	update eng_corp_p1 p1
       set p1.cd_meth_ifrs9_lgd  = 'LGCBM_COR1'
	 where nvl(p1.flag_hn,'N')   = 'N'
       and p1.cd_conso_cpt      in ('00370','00357')
	   and p1.cd_meth_ifrs9_lgd is null
       and ((
	exists (select 1
              from btr_operation op
             where op.id_operation                 = p1.id_engagement
               and nvl(op.type_delegation,'NULL') != 'CRCAGLES')
       and
	exists (select 1
              from (select sur.id_operation                             id_operation
                          ,sur.id_actif                                 id_actif
                          ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                          ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                      from btr_surete_reelle sur
                     where sur.id_operation = p1.id_engagement) sr
             where sr.act_vtr_max           = 1 --- actif avec la plus grande valeur de VTR
               and sr.id_operation          = p1.id_engagement
               and sr.cd_famille_actif not in ('A','R','C','L','T','6')))
	    or
	   not
	exists (select 1
	          from btr_surete_reelle sur
			 where sur.id_operation = p1.id_engagement));

---- RG_17
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif est ('A','R','C','L','T','6')
---- ET le type de delegation est 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
	W_TABLE := 'TABLE: eng_corp_p1 - RG_17 :: LGD';
	update eng_corp_p1 p1
       set p1.cd_meth_ifrs9_lgd  = 'LGCBM_C2_GL'
	 where nvl(p1.flag_hn,'N')   = 'N'
		and p1.cd_conso_cpt      in ('00370','00357')
		and p1.cd_meth_ifrs9_lgd is null
		and
	 exists (select 1
			   from btr_operation op
			  where op.id_operation                = p1.id_engagement
				and nvl(op.type_delegation,'NULL') = 'CRCAGLES')
		and
	 exists (select 1
               from (select sur.id_operation                             id_operation
                           ,sur.id_actif                                 id_actif
                           ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                           ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                       from btr_surete_reelle sur
                      where sur.id_operation = p1.id_engagement) sr
              where sr.act_vtr_max       = 1 --- actif avec la plus grande valeur de VTR
                and sr.id_operation      = p1.id_engagement
                and sr.cd_famille_actif in ('A','R','C','L','T','6'));

---- RG_18
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif n'est pas ('A','R','C','L','T','6')
---- ET le type de delegation est 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
---- OR (pas d'engagement dans BTR_SURETE_REELLE)
	W_TABLE := 'TABLE: eng_corp_p1 - RG_18 :: LGD';
	update eng_corp_p1 p1
       set p1.cd_meth_ifrs9_lgd  = 'LGCBM_C1_GL'
	 where nvl(p1.flag_hn,'N')   = 'N'
		and p1.cd_conso_cpt      in ('00370','00357')
		and p1.cd_meth_ifrs9_lgd is null
		and ((
	 exists (select 1
			   from btr_operation op
			  where op.id_operation                = p1.id_engagement
				and nvl(op.type_delegation,'NULL') = 'CRCAGLES')
		and
	 exists (select 1
               from (select sur.id_operation                             id_operation
                           ,sur.id_actif                                 id_actif
                           ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                           ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                       from btr_surete_reelle sur
                      where sur.id_operation = p1.id_engagement) sr
              where sr.act_vtr_max           = 1 --- actif avec la plus grande valeur de VTR
                and sr.id_operation          = p1.id_engagement
                and sr.cd_famille_actif not in ('A','R','C','L','T','6')))
		 or
	    not
	 exists (select 1
	           from btr_surete_reelle sur
			  where sur.id_operation = p1.id_engagement));

---- RG_13
----    perimetre CORPORATE
---- ET societe est ('LIXBAIL' ou 'CAL Espagne' ou' Finamur')
---- ET perimetre des natures des operations est le ('HORS NAT02')
	W_TABLE := 'TABLE: eng_corp_p1 - RG_13 :: LGD';
	update eng_corp_p1 p1
	   set p1.cd_meth_ifrs9_lgd  = 'DEFAUTLGD'
	 where p1.flag_hn            = 'O'
	   and p1.cd_conso_cpt      in ('00370','00357','00472')
	   and p1.cd_meth_ifrs9_lgd is null;

---- RG_14
----    perimetre CORPORATE
---- ET societe est ('AUXIFIP' ou 'UNIFERGIE')
	W_TABLE := 'TABLE: eng_corp_p1 - RG_14 :: LGD';
	update eng_corp_p1 p1
	   set p1.cd_meth_ifrs9_lgd  = 'DEFAUTLGD'
	 where p1.cd_conso_cpt      in ('00399','00936')
	   and p1.cd_meth_ifrs9_lgd is null;
    commit;
-- =======================================================================================================
--  FIN :: Maj des rg du perimetre LGD - corporate P1
-- =======================================================================================================

			  ----------------------------------------------------------------------------------
			  --EVOL CRRV4 - LOT FEVRIER 2016 : OPERATIONS SANS NUM DE
			  ----------------------------------------------------------------------------------
              W_TABLE := 'ENG_CORP_P1 (34)';
			  Update Eng_Corp_p1   P1
								SET P1.Id_Autorisation = 'F1' || P1.Id_Engagement,
												P1.Id_Ligne_Det = 'F2' || P1.Id_Engagement
			  Where P1.id_autorisation is null
			  ;
			  Commit;

      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
                    W_TABLE := 'CRR_ORIGINE';
					insert into CRR_ORIGINE (
					ID_ENGAGEMENT,
					DT_DONNEES,
					NOTE_ORIGINE,
					CD_SOURCE_NOTE_ORI,
					CD_SEGMENT_CAL_ORI,
					CD_GRILLE_NOTE_ORI,
					CD_METHODE_NOTE_ORI,
					/*TEG_ORIGINE,*/
					CD_CONSO_CPT)
					select  distinct O.id_operation,O.dt_deb_ope,T.note_baloise,T.cd_source_note,T.cd_segment_cal,T.cd_grille_note,CASE WHEN T.cd_methode_note in ('C13','C12') THEN 'C1' WHEN T.cd_methode_note in ('SRR') THEN 'R2' WHEN T.cd_methode_note in ('999') THEN 'C3' ELSE T.cd_methode_note END,/*T.TEG_ORIGINE,*/sj.CD_CONSO_CPT_CRRV3
					FROM btr_tiers T,
								   btr_operation O,
								   RS_SOCIETE_JURIDIQUE sj
					where T.id_tiers = O.id_tiers
					and sj.cd_soc_juri = O.cd_soc_juri
					and T.cd_role_tiers='C'
					and not exists (select 1 from CRR_ORIGINE where id_engagement =o.id_operation and cd_conso_cpt=sj.CD_CONSO_CPT_CRRV3 );

					commit;

      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
                    W_TABLE := 'ENG_CORP_P1 (35)';
      /* M55563 optimisation
					Update Eng_Corp_p1   p1
								   Set (p1.NOTE_FIN_RET_ORI,p1.org_not_ori,p1.SEG_NOT_ORI,p1.GRI_MOD_NOT_ORI,p1.METH_NOT_ORI) =
								   (select  distinct OCR.NOTE_ORIGINE,'I',OCR.CD_SEGMENT_CAL_ORI,
								  OCR.CD_GRILLE_NOTE_ORI,OCR.CD_METHODE_NOTE_ORI
									From CRR_ORIGINE OCR
									Where p1.id_engagement= OCR.id_engagement
									And p1.CD_CONSO_CPT=OCR.CD_CONSO_CPT
									and  nvl(p1.flag_hn,'N') = 'N')
								   where exists  (Select 1
						 From  CRR_ORIGINE OCR
						 Where p1.id_engagement= OCR.id_engagement
						 And p1.CD_CONSO_CPT=OCR.CD_CONSO_CPT
						 and  nvl(p1.flag_hn,'N') = 'N'
						 );
      */
      -- M55563 optimisation
       MERGE INTO Eng_Corp_p1 p1 USING
       (
         SELECT DISTINCT
           CD_CONSO_CPT,
           id_engagement,
           NOTE_ORIGINE,
           'I' AS ORGANISME_NOTATION,
           CD_SEGMENT_CAL_ORI,
           CD_GRILLE_NOTE_ORI,
           CD_METHODE_NOTE_ORI
         FROM
           CRR_ORIGINE
       )
       OCR ON
       (p1.id_engagement= OCR.id_engagement AND p1.CD_CONSO_CPT=OCR.CD_CONSO_CPT)
       WHEN matched THEN
         UPDATE
         SET
           p1.NOTE_FIN_RET_ORI = OCR.NOTE_ORIGINE,
           p1.ORG_NOT_ORI      = OCR.ORGANISME_NOTATION,
           p1.SEG_NOT_ORI      = OCR.CD_SEGMENT_CAL_ORI,
           p1.GRI_MOD_NOT_ORI  = OCR.CD_GRILLE_NOTE_ORI,
           p1.METH_NOT_ORI     = OCR.CD_METHODE_NOTE_ORI
         WHERE nvl(p1.flag_hn,'N') = 'N';

					commit;

      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
                    W_TABLE := 'ENG_CORP_P1 (36)';
					update ENG_CORP_P1 p1
					set (note_fin_ret_ori,gri_mod_not_ori,meth_not_ori) = (select distinct rs.note_moyenne, rs.grille_notation, rs.modele_notation from rs_notation_moyenne rs, tie_tiers_c1_c5 c1
					  where rs.code_segment=c1.cd_portefeuille_bal_tiers
					  and c1.id_tiers_calc = p1.id_tiers_calc
					  and c1.cd_conso_cpt=p1.cd_conso_cpt
					  and c1.cd_type_relation='C'
					  and c1.cd_type_segment='CORP')
					where p1.note_fin_ret_ori is null ;

					COMMIT;

			--11/02/2019 - CDS ATOS (SQN) US 654
            W_TABLE := 'ENG_CORP_P1 (37)';
			UPDATE eng_corp_p1 SET meth_not_ori='999' WHERE meth_not_ori='C3';
			COMMIT;
			--Fin SQN

            W_TABLE := 'ENG_CORP_P1 (38)';
					update eng_corp_p1 p1 set p1.note_fin_ret_ori=(select id_note_balois_retail from rs_def_methodo rs where p1.note_fin_ret_ori=rs.id_note_retail)
					where p1.note_fin_ret_ori in (select id_note_retail from rs_def_methodo);
					COMMIT;

			--11/02/2019 - CDS ATOS (SQN) US 654
            W_TABLE := 'ENG_CORP_P1 (39)';
			UPDATE eng_corp_p1 SET NOTE_FIN_RET_ORI = 'ND' WHERE NOTE_FIN_RET_ORI is null;
			COMMIT;
			--Fin SQN

            W_TABLE := 'ENG_CORP_P1 (40)';
					UPDATE ENG_CORP_P1 set GRI_MOD_NOT_ORI=null where GRI_MOD_NOT_ORI is null or
					gri_mod_not_ori not in (select code_vers_grille_notation from rs_vers_grille_notation where lib_vers_grille_notation !='Erreur Null');

					commit;

			-- 18/02/2019 - CDS ATOS (GBD) - US731 Deb -->
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
            W_TABLE := 'ENG_CORP_P1 (41)';
			UPDATE ENG_CORP_P1 SET  APPLI_SOURCE = 'C_BTR' where nvl(flag_hn,'N') = 'N';
	  --25/07/2019 - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
			--UPDATE ENG_CORP_P1 SET  MNT_SOLDE = null where CD_TYPE_RISQUE <> 'TRE100';
	  --Fin - CDS AtoS FAD - M48783 - Retour sur modification US731 / MNT_SOLDE
            W_TABLE := 'ENG_CORP_P1 (42)';
			UPDATE ENG_CORP_P1 SET  MNT_SOLDE = 0    Where CD_TYPE_RISQUE = 'TRE100' and (MNT_SOLDE is null or MNT_SOLDE < 0) ;
            W_TABLE := 'ENG_CORP_P1 (43)';
			UPDATE ENG_CORP_P1 p1 SET  CD_DEVISE_MNT_DECOUVERT = nvl(CD_DEVISE_MNT_RISQ, (select o.cd_devise from btr_operation o Where o.id_operation=P1.id_engagement) )  Where MNT_DECOUVERT is not null ;
            W_TABLE := 'ENG_CORP_P1 (44)';
			UPDATE ENG_CORP_P1 p1 set MNT_LOYER = greatest (1 , (nvl(MNT_CRD,0) - nvl(mnt_vr,0)
												+ ( select nvl(o.MNT_SOLDE_HT_EXIGIB_K_T,0) + nvl(o.MNT_SOLDE_HT_EXIGIB_I_T,0) + nvl(o.MNT_SOLDE_HT_EXIGIB_AUTRE_T,0) from btr_operation o where o.cd_sys_int = p1.SYS_GEST_SRC and o.id_operation = p1.REF_UNIQ_CONT)-- 18/01/2021 - CDS ATOS (LFD) - Mantis 55571
												) ) WHERE CD_TYPE_RISQUE <> 'TRE401'  and nvl(flag_hn,'N') = 'N';
            W_TABLE := 'ENG_CORP_P1 (45)';
			UPDATE ENG_CORP_P1 SET  CD_DEVISE_CRD = null   WHERE CD_TYPE_RISQUE = 'TRE401' or MNT_LOYER is null ;
            W_TABLE := 'ENG_CORP_P1 (46)';
		UPDATE ENG_CORP_P1 SET  IND_PROD_SS_JACENT  = CASE WHEN (CD_TYPE_RISQUE LIKE 'TRE2%' OR CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END
								WHERE nvl(flag_hn,'N') = 'N';  --11/03/2019 - CDS ATOS (GBD) - US731 Recette
            W_TABLE := 'ENG_CORP_P1 (47)';
			UPDATE ENG_CORP_P1 SET  IND_CREANCE_TITRI = CASE WHEN (CD_TYPE_RISQUE LIKE 'TRE2%' OR CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END ; --11/03/2019 - CDS ATOS (GBD) - US731 Recette
			--11/03/2019 - CDS ATOS (GBD) - US731 Recette                    WHERE nvl(flag_hn,'N') = 'N';
            W_TABLE := 'ENG_CORP_P1 (48)';
			UPDATE ENG_CORP_P1 SET  CD_LOC_BIEN = 'FR' where CD_TYPE_RISQUE = 'TRE502' AND CD_USAGE_BIEN_IMM = '2'      ;
			COMMIT;
			-- 18/02/2019 - CDS ATOS (GBD) - US731 Fin <---
            W_TABLE := 'ENG_CORP_P1 (49)';
		UPDATE ENG_CORP_P1 SET dt_exigte_prem_impy=DT_ARRETE WHERE CD_ARR_PAIEMENT='Y' AND dt_exigte_prem_impy IS NULL;
		COMMIT;
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

   W_TABLE := 'ENG_CORP_P1 (50)'; --Mantis 66161
		  UPDATE ENG_CORP_P1
		  SET OBJ_FINANCIE  = '04' WHERE CD_CONSO_CPT IN ('00472');

	  execute immediate 'truncate table ENG_CORP_P2';
			-- et maintenat le P2 pour tout ce qui est HB
          W_TABLE := 'ENG_CORP_P2 (1)';
		  Insert into DDREX.ENG_CORP_P2
		   ( DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_CENTRAL_TIERS,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_ENGAGEMENT,
			 CD_METHODO_BALE2,
			 CD_TYPE_RISQUE,
			 CD_PORTEFEUILLE_BALE2,
			 CD_NATURE_OPE,
			 DT_DEBUT_ENG,
			 DT_FIN_ENG,
			 CD_PORTEFEUILLE_BOOKING,
			 CD_LIGNE_METIER,
			 TX_POND_BAL,
			 TX_LGD_PREDICTIF,
			 TX_CCF,
			 TX_EAD,
			CD_DEVISE_EAD,
			CD_DEVISE,
			TOP_RESTRUCTURATION,
			DT_RESTRUCTURATION,
			CD_IMP_PRUDENT,
			CD_ENG_DTX,
			DT_EGT_DTX,
			MNT_PNU,
			CD_DEVISE_PNU,
			CD_CIRCUIT_DISTRIB,
			PCCO_MNT_PNU,
			MNT_VTR_PDR,
			MATURITE_EFF,
			TOP_ENG,
			CD_USAGE_BIEN_IMM,
			A_EXTRAIRE,
			IND_PRD_NON_ECH,
			IND_OBJ_MET_PAL_DAT_FOURNI,
			IND_ECH_FOURNI,
			TYP_AMOR_CAP,
			PER_AMOR_CAP,
			PER_PAI_INTERET,
			MOD_REMB_CREANCE,
			DATE_FIN_DIF_AMOR,
			PER_REV_TAUX_UNITE_TMP,
			PER_REV_TAUX_NBR,
			DEV_CAP_THEO_REST_DU,
			IND_PRE_POST_FIX,
			EVT_CREDIT,
			nat_evn_credit,
			--23/04/2018 - CDS ATOS (EMM) - Sprint 8, US 273 et 274
			statu_credit,
			DATE_PREM_ACT_FORB,
			DATE_SORT_EFF_FORB,
			DATE_ENTR_PER_PURG,
			DATE_SORT_PER_PURG,
			DATE_ENTR_PER_PROB,
			DATE_SORT_PER_PROB,
			DATE_THEO_FIN_FORB,
			--Fin EMM
			ind_creance_per,
			dat_der_rest_com,
			dat_der_rest_ris,
			TYP_TAUX,
			BASE_CALCUL_INTERET,
			DATE_PRE_DEB_FOND,
			CAP_THEO_REST_DU,
			SYS_GEST_SOURCE,
			ZONE_APP_COMPTA,
			ELIG_OUTIL_MUT_PROV,
			dev_montant_deb,
			DATE_PRM_ECHEANCE,
			MNT_IEC,
			IND_REF,
			taux_marg_addtiv,
			TAUX_CLT_PRD_EN_CRS,
			taux_cli_octroi,
			taux_int_ef_org,
			REF_UNI_CONTRAT,
			REF_UNI_ELEM_CONTRAT,
			ind_act_dep_org ,
			-- 26/03/2018 CDS ATOS (JMP) ANACREDIT US33 Sprint 4 Ajout du motif SCO
			CD_MOTIF_SCO_LC0267,
			--01/06/2018 - CDS ATOS (PSR) - US 292 - CRRV4.1 Instruments (A)
			MNT_CONTRAT_ORIGINE,
			DEV_MNT_CONTRAT_ORIGINE,
			--Fin CDS ATOS (PSR) - US 292 - CRRV4.1 Instruments (A)
			--08/11/18 CDS Atos (EMM) US 546
			IND_NIV_RISQUE,
			--Fin EMM
			--28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur erron? pour P2 et F2
			CD_MOTEUR
			--Fin SQN
			--23/01/2019 - CDS Atos (SQN) US 670
			, TX_EL
			, DT_PL_NPL
			, CD_MOTIF_PL_NPL
			, CD_PAYS_JURIDICTION
			, DT_SIGNATURE
			, EVT_DECL_GAR
			, BUCKET_IFRS9
			, IND_OPE_EFFET_LEVIER
			, IND_SPONSOR_FIN
			, MNT_IDEMNITE_RES
			, CD_DEV_MNT_INDEMNITE
			--Fin SQN
			-- 08/02/2019 - CDS ATOS (GBD)- US677   Deb -->
			, MNT_ECHEANCE_EN_COURS
			, DEV_MNT_ECHEANCE_EN_COURS
			, APPLI_SOURCE
			, FREQUENCE
			, CODE_TRAIT_GRR
			, MNT_EAD
			, IND_ACCORD_FUSION
			, TOP_PRODUIT
			, RESPECT_COND_REG
			, ORGA_NOTATION_ORIG
			--, IND_MOBIL_ACTIF    --CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
			-- 08/02/2019 - CDS ATOS (GBD)- US677   Fin  <--
			-- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
			,IND_ELIGI_OUTI_CTRAL_ANACRD
			,MOTIF_EXCLU_ANACREDIT
			,MNT_ENG_DT_SIGN_CTRT
			,IND_RESPO_SOLIDAIRE
			-- FIN LFD
			--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
			,IND_MOBIL_ACTIF
			,ELIG_MOB_BANQUE_CENTRALE
			,REF_MOB_ACTIF
			,CD_ORGA_MOBIL
			-- 23/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
			--,IND_ELIGB_ACTIF_IMM_BC
			-- Fin CPD
			--FIN MNE
			--CDS_ATOS (LFD) - 18/06/2021 - US 91 CRRV4.3
			,CD_COMMUNE_BIEN_FINAN
			,CD_PAYS_BIEN_FINAN
			-- FIN LFD
			--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,CD_TYPE_PROD_BANCAIRE
			--FIN MNE
			--,IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
			-- US 261 - KLx Risque (VDC) - Addition des champs MNT_FOND_REMIS_DATE et DEV_FOND_REMIS_DATE
			, MNT_FOND_REMIS_DATE
			, DEV_FOND_REMIS_DATE
			-- FIN VDC
			,IND_UCC -- KLX-GOMESHU - BALE4 - 06/02/2023 - P2 21.66
			,NIV_RISQUE_CRR3 -- KLX-GOMESHU - BALE4 - 06/02/2023 - P2 21.68
			,CD_NAT_OPE_ENG_CALC_FLOOR  -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.55
			,IND_EXPO_ADC -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.39
			,LTV_RATIO -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 22.43
			,ETV_RATIO -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.43
			,USAGE_BIEN_FINANCE -- KLX-GOMESHU -- 04/01/2022 - P2 8.13
			,IND_OPE_AVEC_RECOURS -- P2 21.88 pos 3195
			,IND_INVEST_CAPITAL_RISQ --P2 21.57 pos 2839
			,IND_INVEST_PROG_LEGISLATIF --P2 21.58 pos 2840
			,COMMUNE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.71
			,NUM_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.72
			,EXTENSION -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.73
			,TYPE_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.74
			,LIB_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.75
			,LIEU_DIT -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.76
			,LATITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.77
			,LONGITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.78
			,CD_TYPE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P2 21.86
			,CD_EMPLACE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P2 21.87
			,TX_DSCR						-- BALE4 - P2 21.81
			,TX_DSCR_PREC					-- BALE4 - P2 21.82
			,MNT_ACQUISITION       --KLx BARTOLMI  Mantis 71368- QDD - P2 22.44
			,CDTYPEGARPRINCOCTROI  -- P2 31.21 M71371
			,DATE_DEB_ENG_RENOUV   -- projet OMP - sous-tache SIRL-279 :: ajout du champ P2 22.63
			,CD_METH_IFRS9_PD_ORIG -- projet OMP - sous-tache SIRL-279 :: ajout du champ P2 6.99
		    )
			SELECT  DISTINCT o.dt_arrete,
							  s.CD_CONSO_CPT_CRRV3,
							  CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
							  T.IDENT_SIRIS,
							  CASE WHEN NU.CD_SYS_INT is not null then 'F1'|| NU.NUM_DEC_BIS END  ID_AUTORISATION,
							  CASE WHEN NU.CD_SYS_INT is not null then 'F2'|| NU.NUM_DEC_BIS END  ID_LIGNE_DET,
							  o.ID_OPERATION,
							  nvl(methodo.cd_method, 'STD') cd_methodo_bale2,  --mantis re7 5520  -- 08/02/2019 - CDS ATOS (GBD)- US677
							  pf.CD_TYP_RISQ_CORP,
							  '900',  --DECODE(methodo.cd_method, 'NON IRB', ' ', '900'), mantis re7 5520
							  'NAT07' cd_nature_ope,
							  CASE WHEN o.DT_DEB_OPE > o.DT_ARRETE THEN o.DT_ARRETE - 1
											 ELSE o.DT_DEB_OPE
							  END  DT_DEBUT_ENG,
							  o.DT_FIN_OPE,
							  'B' cd_portefeuille_booking,
							  'MLE00' cd_ligne_metier,
							  null,
							  trunc(o.TX_LGD_PREDICTIF),
							  (0.5 * 100)   TX_CCF, --o.TX_TRC,    mantis 5549 et 5520, tout est en STD   -- 08/02/2019 - CDS ATOS (GBD)- US677
							  case when o.MNT_EXPO_POTENT_HT = 0 then 100 else (o.mnt_ead_tot/o.MNT_EXPO_POTENT_HT)*100 end,
							  o.CD_DEVISE,   ---CD_DEVISE_EAD     -- 08/02/2019 - CDS ATOS (GBD)- US677   rem: MNT_EAD aliment? ? 0 par defaut
							  o.CD_DEVISE,
							  -- CASE WHEN o.CD_AQR IN ('C2', 'C3A') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN 'RF' WHEN o.CD_AQR IN ('C4', 'C3B') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN 'RC' END top_restructuration,
							  -- M52619 : TOP_RESTRUCTURATION appliquer la meme regle en vigueur pour le cas RETA (CD_TYPE_RESTRUCT de CREDIT_P3)
							  -- M70812
							  /*CASE WHEN o.cd_aqr in ('C2','C3A') AND T.cd_categ_cpt in ('DTX', 'DTCO')     THEN 'RF'
								   WHEN o.cd_aqr in ('C2','C3A') AND T.cd_categ_cpt not in ('DTX', 'DTCO') THEN 'RC'
								   WHEN o.cd_aqr in ('C4')       AND T.cd_categ_cpt not in ('DTX', 'DTCO') THEN 'AR'
								   ELSE NULL
							  END AS TOP_RESTRUCTURATION, */
							  CASE WHEN O.CD_AQR IN ('C4')                                                                                                THEN 'AR'
							  	   WHEN O.CD_AQR IN ('C3A') AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR THEN 'RC'
								   WHEN O.CD_AQR IN ('C2')  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN 'RF'
								   ELSE NULL
							  END AS TOP_RESTRUCTURATION,
							  -- M70812
							  CASE WHEN o.CD_AQR IN ('C2', 'C3A','C4', 'C3B') AND o.DT_ARRETE BETWEEN o.DT_AQR AND o.DT_FIN_VALID_AQR THEN o.DT_AQR END dt_restructuration,
							  --MODIF LY 30/11/2015            decode (nvl(o.nbre_impy, 0), 0, 'N', 'Y'), --CD_IMP_PRUDENT,
							  CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END  CD_IMP_PRUDENT,
							  CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END top_eng_douteux,  -- cd_eng_dtx (top_eng_douteux ds P1)
							  CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN T.DT_CHG_CATEG_CPT END dt_eng_dtx,
							  nvl(o.MNT_EXPO_POTENT_HT,0) - nvl(hb.mnt_iec,0),  -- MNT_PNU  -- 08/02/2019 - CDS ATOS (GBD)- US677
							  o.CD_DEVISE,
							  Decode (o.cd_canal_apport, 'DIRE', 'CC', 'CL'),   -- CD_CIRCUIT_DISTRIB
							  pcec.CD_PCEC_CRD,
							  nvl(surete.vtr,0),
							  O.MATURITE_CALC,
							  --CASE WHEN methodo.CD_METHOD in ('IRBA','IRB AS')  THEN  -- Mantis re7 5520
							  --12/06/2019 - CDS_ATOS(CML) - Mantis 48221
							  --CASE WHEN O.TOP_ENG IN ('O','G') THEN 'H' ELSE 'B'
							  CASE WHEN O.TOP_ENG IN ('O') THEN 'H' ELSE 'B'
							  --fin Mantis 48221
							  --            END
							  END  TOP_ENG,
							  decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),
							  'O',
							decode(substr(pf.CD_TYP_RISQ_CORP,1,3),'TRE', 'ECH', 'NEC'),
							'N',
							'N',
							'L',
							'M',
							'M',
							'1',
							null,
							'M',
							1,     -- PER_REV_TAUX_NBR
							'EUR',
							'E',
							CASE WHEN (o.cd_flag_restructuration is null OR  o.cd_flag_restructuration = 'SANS') Then '2' ELSE '1' END,  -- EVT_CREDIT
							CASE
                				WHEN o.cd_flag_restructuration = 'RCOM' THEN
                				     CASE
                				     WHEN o.CD_AQR in ('C2','C3A') AND  o.TOP_PL_NPL = 'N' THEN '1'  --- M59263
                				     ELSE '4'
                				     END                            --- M59263
								WHEN o.cd_flag_restructuration = 'RISQ' THEN DECODE(o.CD_AQR,'C2','1','C3A','1','5')
								ELSE '5'
							END as NAT_EVN_CREDIT,   ---  M59263
							--23/04/2018 - CDS ATOS (EMM) - Sprint 8, US 273 et 274
							CASE
                				WHEN T.CD_CATEG_CPT IN ('DTX', 'DTCO')  then '1'  --- M59263
                				WHEN o.TOP_PL_NPL = 'N' then '1'
                				WHEN o.TOP_PL_NPL = 'P' AND o.dt_fin_valid_aqr > o.dt_arrete then '2'
                				WHEN o.TOP_PL_NPL = 'P' AND o.dt_fin_valid_aqr <= o.dt_arrete then '3'
								ELSE '4'
							END statu_credit,
							--ef.dt_aqr,   -- DATE_PREM_ACT_FORB
                			-- M58209 : remplace par
				        	--- DATE_PREM_ACT_FORB alimentee si TOP_RESTRUCTURATION <> null et <> AR
				        	CASE  WHEN O.CD_AQR = 'C4'                                                                                                THEN null      --'AR'
				        	      WHEN O.CD_AQR = 'C3A' AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR THEN ef.dt_aqr --'RC'
				        	      WHEN O.CD_AQR = 'C2'  AND T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF' M70812
				        	      --WHEN O.CD_AQR = 'C2'   OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF'
				        	      ELSE NULL
				        	END AS DATE_PREM_ACT_FORB,
							  --sf.dt_fin_valid_aqr,
							o.DATE_SORT_EFF_FORB,   --08/02/19 VDS ATOS (EMM) ANACREDIT US 497
							CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR END DATE_ENTR_PER_PURG,
							CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12) END DATE_SORT_PER_PURG,
							CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12)
								else
								  CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR end
							END DATE_ENTR_PER_PROB,
							CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,36)
								else
								  CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,24) end
							END DATE_SORT_PER_PROB,
               				-- DATE_THEO_FIN_FORB  M58209 : regle remplace par
				        	CASE WHEN O.CD_AQR = 'C4'                                                                                                THEN null      --'AR'
    			        	   WHEN o.CD_AQR = 'C3A' AND T.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR then ADD_MONTHS(o.DT_AQR,24)
				        	     WHEN o.CD_AQR = 'C2'   OR T.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         then ADD_MONTHS(o.DT_AQR,36)
				        	     ELSE NULL
 					    	END AS DATE_THEO_FIN_FORB,
							--Fin EMM
							CASE WHEN T.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'NP' ELSE DECODE(o.TOP_PL_NPL,'N','NP','P','PE','PE') END,
							DECODE(o.cd_flag_restructuration,'RCOM',o.DT_AQR,null),
							DECODE(o.cd_flag_restructuration,'RISQ',o.DT_AQR,null),

							o.CD_TYPE_TAUX,
							(DECODE(o.cd_sys_int,'KSP','EXA-360','EXB-EXB')),
							o.DT_MEL DATE_PRE_DEB_FOND, --BALE4
							nvl(o.crd_brut_ht,0)-nvl(mnt_vr,0),
							o.CD_SYS_INT,
							pcec.CD_PCEC_CRD||'_'||T.cd_segment_casa||'_'|| s.CD_CONSO_CPT_CRRV3||'_'||o.cd_produit,
							'1',
							'EUR',
							o.date_prem_ech,
							hb.MNT_IEC,
							RT.code_CASA,
							--o.taux_mrg,    16/05/19 CDS ATOS (EMM) Mantis 47711
							--11/12/2018 CDS ATOS (SQN) Mantis 43416 - IFRS 9 Floorer les taux d'inetret negatifs a 0
							--CASE WHEN o.valeur_taux<0 THEN 0.00001 ELSE o.valeur_taux END,
							--CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))<0 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,
							--CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))<0 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,
							--Fin SQN
							--13/05/19 CDS ATOS (EMM) Mantis 47711
							CASE WHEN nvl(o.taux_mrg,0)< 0.00001 THEN 0.00001 ELSE o.taux_mrg END,                        --TAUX_MARG_ADDITIV
							CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_CLT_PRD_EN_CRS
							CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_CLI_OCTROI
							CASE WHEN (o.valeur_taux+nvl(o.taux_mrg,0))< 0.00001 THEN 0.00001 ELSE o.valeur_taux+nvl(o.taux_mrg,0) END,     --TAUX_INT_EF_ORG
							--Fin EMM
							o.id_operation,
							o.id_operation,
							'N' ,
							-- 26/03/2018 CDS Atos (JMP) ANACREDIT US33 Sprint 7

							pack_alim_tab_envoi_crrv4_new.f_cd_motif_sco_lc0267(
							  T.CD_CATEG_CPT,
							  t.cd_motif_sco,
							  null, -- Pour le P2 on ne prend pas en compte le nombre de jours d'impay?s
							  t.NOTE_BALOISE),
							--Fin JMP
							--01/06/2018 - CDS ATOS (PSR) - US 292 - CRRV4.1 Instruments (A)
							o.MNT_BRUT_ORIGINE, -- Montant du contrat ? l'origine  MNT_CONTRAT_ORIGINE
							Case When o.MNT_BRUT_ORIGINE is not null then o.CD_DEVISE end, --Devise du montant du contrat a l'origine -- Edit du 01/06/2018 : si pas de montant, pas de devise
							-- fin US 292 - CDS ATOS(PSR)
							--08/11/18 CDS Atos (EMM) US 546
							CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' THEN '1'  -- 08/06/2022 - KLx Risque (VDC) - Risque Leasing 2022 US 11
								WHEN O.CD_SOC_JURI = '06' and O.CD_SYS_INT ='DE' and pf.CD_TYP_RISQ_CORP = 'TRE501' THEN '1'
							END IND_NIV_RISQUE,  --IND_NIV_RISQUE
							--Fin EMM
							--28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur erron? pour P2 et F2
							methodo.trt_moteur
							  --Fin SQN
							  --23/01/2019 - CDS Atos (SQN) US 670
							  , null          --TX_EL
							  , CASE  WHEN (T.CD_CATEG_CPT='DTX' or T.CD_CATEG_CPT ='DTCO')
								  THEN T.DT_CHG_CATEG_CPT
								  ELSE NVL(o.DT_CHG_PE_NPE, NVL(o.DT_DEB_OPE,o.DT_DEB_VALIDITE_AUTO))
								  END       --DT_PL_NPL
							  , null          --CD_MOTIF_PL_NPL
							  --, T.CD_PAYS_RESIDENCE --CD_PAYS_JURIDICTION
							  , T.CD_PAYS_RISQUE --CD_PAYS_JURIDICTION -- BALE4 P2 22.66 pos 1518
							  , CASE  WHEN o.DT_DEB_OPE > o.DT_ARRETE
								  THEN o.DT_ARRETE - 1
													  ELSE o.DT_DEB_OPE
								  END       --DT_SIGNATURE
							  , '04'          --EVT_DECL_GAR
							  , CASE  WHEN (T.CD_CATEG_CPT = 'DTX' or T.CD_CATEG_CPT = 'DTCO')
								  THEN 'B3'
								  ELSE 'B1'
								  END       --BUCKET_IFRS9
							  -- 06/02/19 - CDS ATOS (LFD) - CRRV4.2 US 718
							  -- , null         --IND_OPE_EFFET_LEVIER
							  ,'0' --IND_OPE_EFFET_LEVIER
							  -- FIN LFD
							  , null          --IND_SPONSOR_FIN
							  , null          --MNT_IDEMNITE_RES
							  , null          --CD_DEV_MNT_INDEMNITE
							  --Fin SQN
							  -- 08/02/2019 - CDS ATOS (GBD)- US677  Deb -->
							  , null    -- MNT_ECHEANCE_EN_COURS
							  , null    -- DEV_MNT_ECHEANCE_EN_COURS
							  , 'C_BTR' -- APPLI_SOURCE
							  , CASE When pf.CD_TYP_RISQ_CORP = 'EQU101' THEN 'T' ELSE 'M' END  FREQUENCE     -- FREQUENCE si CD_TYPE_RISQUE='EQU101' : T sinon  M
							  , 'Y'  -- CODE_TRAIT_GRR
							  , 0    -- MNT_EAD
							  , 'N'  -- IND_ACCORD_FUSION
							  , 'N'  -- TOP_PRODUIT
							  , 'Y'  -- RESPECT_COND_REG
							  , 'I'  -- ORGA_NOTATION_ORIG
							  -- 27/03/2019 - CDS ATOS (LFD) - US768
							  --, '1'  -- IND_MOBIL_ACTIF
							  --,CASE WHEN O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++' OR O.INDIC_PSE IN ('P1','P2') THEN '2' ELSE '1' END IND_MOBIL_ACTIF --CDS_ATOS (MNE) - 14/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88
							  -- FIN LFD
							  -- 08/02/2019 - CDS ATOS (GBD)- US677  Fin <--
							  -- 12/03/2020 - CDS ATOS (LFD) - US 44 CRRV4.3
							,CASE WHEN O.CD_SOC_JURI IN ('09','31') THEN '1' ELSE '2' END IND_ELIGI_OUTI_CTRAL_ANACRD
							,CASE WHEN O.CD_SOC_JURI IN ('09','31') THEN '02' END MOTIF_EXCLU_ANACREDIT
							,o.MNT_BRUT_ORIGINE MNT_ENG_DT_SIGN_CTRT
							,'N' IND_RESPO_SOLIDAIRE
							-- FIN LFD
							--CDS_ATOS (MNE) - 11/06/2021 - US 197 CRRV4.3 - DonnÃ¿Â¿Â½e AER NAT 02 - TRICP - Annnule et remplace US88

							--Si les 3 caratÃ¿Â¿Â½res Ã¿Â¿Â½ partir de la deuxieme position du champ BTR_OPERATION.COTATION_BDF in ('4+','3','3+','3++') ou si BTR_OPERATION.INDIC_PSE in ('P1','P2') alors renseigner '3' sinon garder l'alimenation actuelle.
							,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '3' 	ELSE '1'	END IND_MOBIL_ACTIF
							--Si les 3 caratÃ¿Â¿Â½res Ã¿Â¿Â½ partir de la deuxieme position du champ BTR_OPERATION.COTATION_BDF in ('4+','3','3+','3++') ou si BTR_OPERATION.INDIC_PSE in ('P1','P2') ET IND_MOBIL_ACTIF='3' Alors 'Y' sinon 'N'
							--IND_MOBIL_ACTIF Ã¿Â¿Â½tant dÃ¿Â¿Â½ja renseignÃ¿Â¿Â½ au dessus et les condition Ã¿Â¿Â½tant les meme pas besoin de le prendre en compte.
							,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN 'Y' 	ELSE 'N' 	END ELIG_MOB_BANQUE_CENTRALE
							--SI IND_MOBIL_ACTIF='3' ET ELIG_MOB_BANQUE_CENTRALE = 'Y' alors 1 sinon laisser vide. Ces deux champs sont renseignÃ¿Â¿Â½s au dessus juste Ã¿Â¿Â½ prendre la condition du 1er champs.
							,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '1' 	ELSE NULL	END REF_MOB_ACTIF
							--SI IND_MOBIL_ACTIF='3' ET ELIG_MOB_BANQUE_CENTRALE = 'Y' ET REF_MOB_ACTIF = '1' alors '404' sinon laisser vide. Ces champs sont renseignÃ¿Â¿Â½s au dessus juste Ã¿Â¿Â½ prendre la condition du 1er champs.
							,CASE WHEN (O.COTATION_BDF LIKE '_4+' OR O.COTATION_BDF LIKE '_3' OR O.COTATION_BDF LIKE '_3+' OR O.COTATION_BDF LIKE '_3++') OR O.INDIC_PSE IN ('P1','P2') THEN '404' 	ELSE NULL 	END CD_ORGA_MOBIL

							-- 23/04/2021 - CDS ATOS (CPD) - US 88 CRRV4.3
							--,'N' IND_ELIGB_ACTIF_IMM_BC
							-- Fin CPD
							--FIN MNE
							--CDS_ATOS (LFD) - 18/06/2021 - US 91 CRRV4.3
							,CASE WHEN NVL(decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),0) <> 0 AND BSR.CD_PAYS = 'FR' THEN BSR.CD_POSTAL END CD_COMMUNE_BIEN_FINAN
							,CASE WHEN NVL(decode(substr(pf.CD_TYP_RISQ_CORP,1,6),'TRE502', '2', '0'),0) <> 0 THEN NVL(BSR.CD_PAYS,'FR') END CD_PAYS_BIEN_FINAN --Mantis 71367
							-- FIN LFD
							--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
							,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE
							--FIN MNE
							--,hb.IND_ISF IND_ISF -- 10/08/2021 - CDS ATOS (LFD) - US 141 CRRV4.3
							-- US 261 - KLx Risque (VDC) - Addition des champs MNT_FOND_REMIS_DATE et DEV_FOND_REMIS_DATE
							, 0 MNT_FOND_REMIS_DATE
							, 'EUR' DEV_FOND_REMIS_DATE
							-- FIN VDC
							,CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' AND hb.CD_SOC_JURI IN ('06','09') THEN 'Y'
								  WHEN pf.CD_TYP_RISQ_CORP = 'TRE501' AND hb.CD_SOC_JURI IN ('06','09') THEN 'Y'
							ELSE 'N' END IND_UCC --P2 21.66
							,CASE WHEN pf.CD_TYP_RISQ_CORP = 'TRE504' AND hb.CD_SOC_JURI IN ('06','09') THEN '1'
								  WHEN pf.CD_TYP_RISQ_CORP = 'TRE501' AND hb.CD_SOC_JURI IN ('06','09') THEN '1'
							ELSE NULL END NIV_RISQUE_CRR3 --P2 21.68
							,'NAT07' CD_NAT_OPE_ENG_CALC_FLOOR  -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.55
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN
									CASE WHEN HB.MNT_IEC > 0  THEN 'Y' ELSE 'N' END
								ELSE NULL END IND_EXPO_ADC -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.39
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN
								(surete.MNT_ETV_VV_ACT)*100 ELSE NULL END ETV_RATIO -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.43
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN
								surete.MNT_LTV_VV_ACT ELSE NULL END LTV_RATIO -- KLX-GOMESHU - BALE4 - 15/02/2023 - P2 22.43
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502') ) THEN '2' ELSE '0' END USAGE_BIEN_FINANCE -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 8.13
							,DECODE(o.CD_TYPE_PRODUIT,'ASR','N','Y') IND_OPE_AVEC_RECOURS -- P2 21.88 pos 3195
							,'N' IND_INVEST_CAPITAL_RISQ --P2 21.57 pos 2839
							,'N' IND_INVEST_PROG_LEGISLATIF --P2 21.58 pos 2840
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.VILLE ELSE NULL END COMMUNE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.71
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END NUM_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.72
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_2_ADR_ACT_CBI ELSE NULL END EXTENSION -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.73
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END TYPE_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.74
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LIG_1_ADR_ACT_CBI ELSE NULL END LIB_VOIE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.75
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN NULL ELSE NULL END LIEU_DIT -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.76
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LATITUDE ELSE NULL END LATITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.77
							,CASE WHEN S.CD_CONSO_CPT_CRRV3 IN ('00472') THEN BSR.LONGITUDE ELSE NULL END LONGITUDE -- KLX-GOMESHU - BALE4 - 06/02/2024 - P2 21.78
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN immeuble.CD_TYPE_BIEN_COMM ELSE NULL END CD_TYPE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P2 21.86
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502','PRI105') ) THEN emplace_bien.CD_EMPLACE_BIEN_COMM ELSE NULL END CD_EMPLACE_BIEN_COMM -- KLX-GOMESHU - BALE4 - 07/02/2024 - P2 21.87
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00936','00399','00472') ) THEN t.DBT_SRVC_RT ELSE NULL END TX_DSCR -- BALE4 - P2 21.81
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00936','00399','00472') ) THEN t.DBT_SRVC_RT_12M ELSE NULL END TX_DSCR_PREC -- BALE4 - P2 21.82
							,CASE WHEN ( S.CD_CONSO_CPT_CRRV3 IN ('00472') AND PF.CD_TYP_RISQ_CORP IN ('TRE502') ) THEN surete.MNT_ACQ_HT_ACT ELSE NULL END MNT_ACQUISITION -- KLX-BARTOLMI Mantis 71368 - QDD P2 22.44
							,CASE WHEN TABLE_AUX_31_21.FLAG_ASCR_PARI = 'O' 				THEN '03'
								WHEN PF.CD_TYP_RISQ_CORP in ('PRI105', 'TRE502') and O.dt_mel is not null THEN '01'
								WHEN PF.CD_TYP_RISQ_CORP in ('TRE504', 'TRE501') and O.dt_mel is not null THEN '02'
								ELSE '04' END CDTYPEGARPRINCOCTROI -- P1 31.21 M7371
			,NULL DATE_DEB_ENG_RENOUV   -- projet OMP - sous-tache SIRL-279 :: ajout du champ P2 22.63
			,NULL CD_METH_IFRS9_PD_ORIG -- projet OMP - sous-tache SIRL-279 :: ajout du champ P2 6.99
		  FROM
			  --BTR_OPERATION                  o,
			  (select ope.*,rso.cd_phase from BTR_OPERATION ope,rs_statut_ope rso where ope.cd_statut_ope=rso.cd_statut_ope) o,
			  RS_SOCIETE_JURIDIQUE           s,
							  REF_TAUX_ARPSON                     RT,
			  BTR_TIERS                      T,
			  (select id_operation, cd_sys_int, dt_arrete, sum( MNT_VTR_PDR) VTR, sum( MNT_ETV_VV_ACT) MNT_ETV_VV_ACT, sum(MNT_LTV_VV_ACT) MNT_LTV_VV_ACT, sum(MNT_ACQ_HT_ACT) MNT_ACQ_HT_ACT from btr_surete_reelle group by  id_operation, cd_sys_int, dt_arrete) surete,
			  RS_CORRES_PRD_FIN_TYP_RISQ_CRP pf,
			  BTR_HORS_BILAN                 hb,
			  ( select
				   		ope.id_operation,
				   		'O' FLAG_ASCR_PARI
				   		FROM
				   		rs_type_garantie rs,
				   		btr_surete_pers pers,
				   		btr_operation ope
				   		WHERE rs.id_type_garantie =pers.id_type_garantie
				   		AND pers.id_operation = ope.id_operation
				   		AND rs.id_famille_garantie in ('ASCR', 'PARI') ) TABLE_AUX_31_21,
			  RS_FAMILLE_IMMEUBLE			immeuble,--BALE4 P2 21.86
			  RS_CORRES_SIT_GEO_BIEN_COMM emplace_bien,--BALE4 P2 21.87
			  (SELECT distinct rsc.cd_type_cli, rss.cd_segment_cal,rsc.cd_phase,rsc.cd_pcec_crd,t.id_tiers FROM btr_tiers t ,rs_corres_pcec  rsc, RS_CORRES_SGMT_BAL_TYPE_CLI rss
			  where rsc.cd_type_cli=rss.cd_type_cli and rsc.nato_crd='NAT07'
			  and T.cd_segment_cal=rss.cd_segment_cal (+)) pcec,
			  AUT_COR_OPE_NUM_DEC_BIS                NU,
			  --28/11/2018 - CDS ATOS (SQN) - Mantis 45281 : Code moteur erron? pour P2 et F2
			  (SELECT CD_SOC_JURI, CD_SEGMENT, cd_method, trt_moteur --Fin SQN (ajout trt_moteur)
				 FROM RS_METHO_BALE_SOC_SEG) methodo,
			  --23/04/2018 - CDS ATOS (EMM) - Sprint 8, US 273 et 274
			  (select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
			  cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
			  from his_forb_btr_operation hisb
			  where hisb.cd_aqr IN ('C2','C3A')
			  and hisb.dt_arrete between hisb.dt_aqr and hisb.dt_fin_valid_aqr
			  and hisb.dt_aqr = (select min(hist.dt_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation and hist.cd_aqr IN ('C2','C3A'))
			  )ef
			  /*,
			  (select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
			  cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
			  from his_forb_btr_operation hisb
			  where hisb.cd_aqr IN ('C2','C3A')
			  and dt_fin_valid_aqr = add_months(dt_arrete, -1)
			  and hisb.dt_fin_valid_aqr = (select max(hist.dt_fin_valid_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation)
			  )sf
			  */
			  --Fin EMM
			  ,(SELECT DISTINCT CD_PAYS, CD_POSTAL, ID_OPERATION, VILLE, LIG_1_ADR_ACT_CBI, LIG_2_ADR_ACT_CBI, LATITUDE, LONGITUDE, CD_FAMILLE_IMM, CD_SIT_GEO_N1, CD_SIT_GEO_N2 FROM BTR_SURETE_REELLE)	BSR 	-- 18/06/2021 - CDS ATOS (LFD) - US 91 CRRV4.3
			  ,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		   WHERE o.CD_SOC_JURI = s.CD_SOC_JURI
			  AND   o.ID_TIERS    = T.ID_TIERS
			  AND   o.CD_PRODUIT  = pf.CD_PRODUIT
			  AND      o.code_index_taux=RT.code_index_taux (+)
			  and   o.ID_OPERATION = TABLE_AUX_31_21.id_operation (+) -- M7371
			  AND    o.cd_phase=pcec.cd_phase (+)
			  AND   o.id_tiers=pcec.id_tiers (+)
			  AND   o.ID_OPERATION = surete.id_operation (+)
			  AND   o.CD_SYS_INT   = surete.cd_sys_int (+)
			  AND   o.ID_OPERATION = hb.id_operation (+)
			  AND   o.CD_SYS_INT   = hb.cd_sys_int (+)
			  AND   o.CD_SYS_INT   = NU.CD_SYS_INT   (+)
			  AND   o.ID_OPERATION = NU.ID_OPERATION (+)
			  AND   BSR.CD_FAMILLE_IMM = immeuble.CD_FAMILLE_IMM(+) --BALE4 P2 21.86
			  AND   BSR.CD_FAMILLE_IMM = emplace_bien.CD_FAMILLE_IMM(+) --BALE4 P2 21.87
			  AND   BSR.CD_SIT_GEO_N1 = emplace_bien.CD_SIT_GEO_N1(+) --BALE4 P2 21.87
			  AND   BSR.CD_SIT_GEO_N2 = emplace_bien.CD_SIT_GEO_N2(+) --BALE4 P2 21.87
			  AND   T.CD_TYPE_SGMT        = 'CORP'
			  AND   s.CD_CONSO_CPT_CRRV3 != '99999'
			  And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
			  and o.id_operation = ef.id_operation(+) --23/04/18 EMM
			  and o.cd_sys_int   = ef.cd_sys_int(+)  --23/04/18 EMM
			  --and o.id_operation = sf.id_operation(+) --23/04/18 EMM
			  --and o.cd_sys_int   = sf.cd_sys_int(+) --23/04/18 EMM
			  And s.cd_soc_juri     = methodo.cd_soc_juri
			  And ( o.CD_SYS_INT = 'DE'
								or
								( o.cd_sys_int != 'DE'
								and o.top_eng='O'
								and o.cd_statut_ope='MEL'
								)
			  )
			  AND O.ID_OPERATION = BSR.ID_OPERATION (+) 	-- 18/06/2021 - CDS ATOS (LFD) - US 91 CRRV4.3
			  --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			  AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
			  AND pf.CD_TYP_RISQ_CORP = PARAM.VAL_PARAM_1 --ENG_CORP_P2.CD_TYPE_RISQUE = PARAM_MULTIDIM_GENERIQUE.VAL_PARAM_1
			  --FIN MNE
			  ;

							  COMMIT;

      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

		W_TABLE := 'Eng_Corp_p2 (2.18)'; -- KLX-GOMESHU - BALE4 - 08/04/2024 - P1 2.18
		merge
		 into ddrex.Eng_Corp_p2 P2
		using (SELECT DISTINCT ID_OPERATION
				FROM ENG_FIPUNI_TAXONOMIE
				WHERE IND_FINANCEMENT_PROJETS = 'Y'
		) peri
		   on (peri.ID_OPERATION  = P2.ID_ENGAGEMENT )
		 when matched then
		   update
			  set P2.CD_PORTEFEUILLE_BALE2 = '061';
		   commit;

      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
        W_TABLE := 'ENG_CORP_P2 (2)';
			 Update Eng_Corp_p2   P2
				   Set p2.OBJ_FINANCIE =
					 (Select CASE WHEN (P2.CD_NATURE_OPE like 'NA02%' AND o.CD_produit ='CBI') THEN '04' ELSE '97' END
					  From BTR_OPERATION o
					  Where o.id_operation=P2.id_engagement
					  )
			  where exists  (Select 1
							 From BTR_OPERATION o
							 Where o.id_operation=P2.id_engagement
							 ) ;
			 -- 08/02/2019 - CDS ATOS (GBD)- US677   : 97 si null
        W_TABLE := 'ENG_CORP_P2 (3)';
			 Update Eng_Corp_p2   P2  Set p2.OBJ_FINANCIE = '97' where p2.OBJ_FINANCIE is null;
			 COMMIT;

        W_TABLE := 'ENG_CORP_P2 (4)';
		 UPDATE ENG_CORP_P2 P2
										 SET DT_FIN_ENG=dt_arrete+30 where DT_FIN_ENG is null or  P2.DT_FIN_ENG < P2.dt_arrete ;
						 COMMIT;

        W_TABLE := 'ENG_CORP_P2 (5)';
						 UPDATE ENG_CORP_P2 P2
										 SET MATURITE_EFF= (CASE WHEN P2.DT_FIN_ENG >= P2.dt_arrete THEN (P2.DT_FIN_ENG - P2.dt_arrete)/365
																						   END ) ;
						 COMMIT;

        W_TABLE := 'ENG_CORP_P2 (6)';
				--UPDATE si taux inconnu du referential
				--- 08/02/2019 - CDS ATOS (GBD)- US677   :   per_rev_taux_nbr =0  ? la place de null
				UPDATE ENG_CORP_P2 SET typ_taux='F',taux_marg_multp=null,taux_marg_addtiv=null,per_rev_taux_nbr=0,per_rev_taux_unite_tmp=null WHERE ind_ref is null;
					COMMIT;

        W_TABLE := 'ENG_CORP_P2 (7)';
		 update eng_corp_p2 set elig_outil_mut_prov='1';

        W_TABLE := 'ENG_CORP_P2 (8)';
		 Update Eng_Corp_p2   P2
			Set ELIG_OUTIL_MUT_PROV =
				(
					   Select distinct '4'
					   FROM
					   btr_tiers T,
					   TIE_TIERS_C1_C5 c1
					   where
					   T.id_tiers = c1.id_tiers
					   AND P2.cd_conso_cpt = c1.cd_conso_cpt
					   AND c1.cd_type_relation='C'
					   AND c1.id_tiers_calc=P2.id_tiers_calc
					   AND t.cd_role_tiers='C'
					   AND c1.flag_hn='N'
					   AND c1.a_extraire='O'
					   AND (P2.CD_NATURE_OPE not like 'NA10%'
									   AND P2.CD_NATURE_OPE <> 'NA311'
									   AND P2.CD_NATURE_OPE <> 'NAT05')
					   AND nvl(c1.top_tiers_dtx,0) = 0
				)
		  where exists  (Select 1
						   FROM
								btr_tiers T,
							   TIE_TIERS_C1_C5 c1
						  where
							   T.id_tiers = c1.id_tiers
							   AND p2.cd_conso_cpt = c1.cd_conso_cpt
							   AND c1.cd_type_relation='C'
							   AND c1.id_tiers_calc=p2.id_tiers_calc
							   AND t.cd_role_tiers='C'
							   AND c1.flag_hn='N'
							   AND c1.a_extraire='O'
							   AND (P2.CD_NATURE_OPE not like 'NA10%'
							   AND P2.CD_NATURE_OPE <> 'NA311'
							   AND P2.CD_NATURE_OPE <> 'NAT05')
							   AND nvl(c1.top_tiers_dtx,0) = 0
						   )
					;

					commit;

        W_TABLE := 'ENG_CORP_P2 (9)';
					update eng_corp_p2 p2 set mnt_ltv = (select DECODE(sum(nvl(MNT_VTR_PDR,0)),0,null,(NVL(P2.MNT_PNU, 0)+NVL(P2.MNT_IEC, 0))/sum(nvl(MNT_VTR_PDR,0)))*100 from BTR_SURETE_REELLE where p2.id_engagement=id_operation group by id_operation);
					commit;

					--PRAC
        W_TABLE := 'ENG_CORP_P2 (10)';
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_TX='RACBM0001' WHERE CD_CONSO_CPT IN ('00357','00370','00372');
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_TX='RACBI0001' WHERE CD_CONSO_CPT IN ('00472');
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_TX='RAFIP0001' WHERE CD_CONSO_CPT IN ('00399','00936');
					COMMIT;

					--CCF
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
        W_TABLE := 'ENG_CORP_P2 (11)';
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_CCF='CCCALL0060' WHERE CD_CONSO_CPT IN ('00399','00936');
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_CCF='CCCALL0050' WHERE CD_CONSO_CPT IN ('00472');
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_CCF='CCCALL0020' WHERE CD_CONSO_CPT IN ('00357','00370','00372') AND CD_METH_IFRS9_CCF IS NULL AND EXISTS (SELECT 1 FROM BTR_OPERATION WHERE ID_OPERATION=ID_ENGAGEMENT AND CD_PRODUIT in ('LOCF'));
					UPDATE ENG_CORP_P2 SET CD_METH_IFRS9_CCF='CCCALL0010' WHERE CD_CONSO_CPT IN ('00357','00370','00372') AND CD_METH_IFRS9_CCF IS NULL;
					COMMIT;

-- =======================================================================================================
--  DEBUT :: Maj des rg du perimetre LGD - corporate P2
-- =======================================================================================================
---- RG_08
----    perimetre CORPORATE
---- ET societe est 'FINAMURï¿½
---- ET identifiant du type de garantie est ('CA','CASY','CLSY','FEI1','GPDB','HSBC','LCL','PART')
---- ET avec une quotepart garant strictement superieure a 0
---- ET le perimetre des natures des operations est 'NAT02'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET la garantie est valide
	W_TABLE := 'TABLE: eng_corp_p2 - RG_08 :: LGD';
	update eng_corp_p2 p2
       set p2.cd_meth_ifrs9_lgd  = 'LGCBI_GAR1'
	 where p2.cd_conso_cpt      in ('00472')
	   and p2.cd_meth_ifrs9_lgd is null
       and
	exists (select 1
              from btr_surete_pers sur
             where sur.id_operation             = p2.id_engagement
			   and nvl(sur.quote_part_garant,0) > 0
               and sur.id_type_garantie        in ('CA','CASY','CLSY','FEI1','GPDB','HSBC','LCL','PART')
               and sur.dt_arrete
           between sur.dt_deb_valid_garant
               and nvl(sur.dt_fin_valid_garant,to_date('31122099','ddmmyyyy')));

---- RG_09
----    perimetre CORPORATE
---- ET societe est 'FINAMURï¿½
---- ET le perimetre des natures des operations est 'NAT02'
---- ET identifiant du type de garantie n'est pas ('CA','CASY','CLSY','FEI1','GPDB','HSBC','LCL','PART')
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET (pas de garantie dans BTR_SURETE_PERS
---- OR engagement avec une quotepart garant egal a 0
---- OR garantie est invalide)
	W_TABLE := 'TABLE: eng_corp_p2 - RG_09 :: LGD';
	update eng_corp_p2 p2
       set p2.cd_meth_ifrs9_lgd  = 'LGCBI_GAR0'
	 where p2.cd_conso_cpt      in ('00472')
	   and p2.cd_meth_ifrs9_lgd is null
       and ( -- pas besoin d'indiquer que le type de garantie ne doit pas etre dans
       not   -- la liste mentionnee car la RG_01 a ete appliquee et donc cela est assure
    exists (select 1
              from btr_surete_pers sur
             where sur.id_operation = p2.id_engagement)
	    or
    exists (select 1
              from btr_surete_pers sur
             where (sur.id_operation            = p2.id_engagement
		       and nvl(sur.quote_part_garant,0) = 0)
                or sur.dt_arrete
               not
           between sur.dt_deb_valid_garant
               and nvl(sur.dt_fin_valid_garant,to_date('31122099','ddmmyyyy'))));

---- RG_10
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif est ('A','R','C','L','T','6')
---- ET le type de delegation est different de 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
	W_TABLE := 'TABLE: eng_corp_p2 - RG_10 :: LGD';
	update eng_corp_p2 p2
       set p2.cd_meth_ifrs9_lgd  = 'LGCBM_COR2'
	 where p2.cd_conso_cpt      in ('00370','00357')
	   and p2.cd_meth_ifrs9_lgd is null
       and
	exists (select 1
              from btr_operation op
             where op.id_operation                 = p2.id_engagement
               and nvl(op.type_delegation,'NULL') != 'CRCAGLES')
       and
	exists (select 1
              from (select sur.id_operation                             id_operation
                          ,sur.id_actif                                 id_actif
                          ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                          ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                      from btr_surete_reelle sur
                     where sur.id_operation = p2.id_engagement) sr
             where sr.act_vtr_max       = 1
               and sr.id_operation      = p2.id_engagement
               and sr.cd_famille_actif in ('A','R','C','L','T','6'));

---- RG_11
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif n'est pas ('A','R','C','L','T','6')
---- ET le type de delegation est different de 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
---- OR (pas d'engagement dans BTR_SURETE_REELLE)
	W_TABLE := 'TABLE: eng_corp_p2 - RG_11 :: LGD';
	update eng_corp_p2 p2
       set p2.cd_meth_ifrs9_lgd  = 'LGCBM_COR1'
	 where p2.cd_conso_cpt      in ('00370','00357')
	   and p2.cd_meth_ifrs9_lgd is null
       and ((
	exists (select 1
              from btr_operation op
             where op.id_operation                 = p2.id_engagement
               and nvl(op.type_delegation,'NULL') != 'CRCAGLES')
       and
	exists (select 1
              from (select sur.id_operation                             id_operation
                          ,sur.id_actif                                 id_actif
                          ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                          ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                      from btr_surete_reelle sur
                     where sur.id_operation = p2.id_engagement) sr
             where sr.act_vtr_max           = 1
               and sr.id_operation          = p2.id_engagement
               and sr.cd_famille_actif not in ('A','R','C','L','T','6')))
	    or
	   not
	exists (select 1
	           from btr_surete_reelle sur
			  where sur.id_operation = p2.id_engagement));

---- RG_17
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif est ('A','R','C','L','T','6')
---- ET le type de delegation est 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
	W_TABLE := 'TABLE: eng_corp_p2 - RG_17 :: LGD';
	update eng_corp_p2 p2
       set p2.cd_meth_ifrs9_lgd  = 'LGCBM_C2_GL'
	 where p2.cd_conso_cpt      in ('00370','00357')
	   and p2.cd_meth_ifrs9_lgd is null
	   and
	exists (select 1
			  from btr_operation op
			 where op.id_operation                = p2.id_engagement
			   and nvl(op.type_delegation,'NULL') = 'CRCAGLES')
	   and
	exists (select 1
              from (select sur.id_operation                             id_operation
                          ,sur.id_actif                                 id_actif
                          ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                          ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                      from btr_surete_reelle sur
                     where sur.id_operation = p2.id_engagement) sr
             where sr.act_vtr_max       = 1
               and sr.id_operation      = p2.id_engagement
               and sr.cd_famille_actif in ('A','R','C','L','T','6'));

---- RG_18
----    perimetre CORPORATE
---- ET societe est 'LIXBAIL' ou 'CAL Espagne'
---- ET le perimetre des natures des operations est 'NAT02'
---- ET le code famille actif n'est pas ('A','R','C','L','T','6')
---- ET le type de delegation est 'CRCAGLES'
--- ------------------------------------------------------------------------------------------------------
---  les conditions ci-dessous seront desormais utilisees, confirme par le metier/ MOA
--- ------------------------------------------------------------------------------------------------------
---- ET a ete pris l'actif avec la plus grande valeur VTR, si plusieurs biens rattaches au meme contrat
---- OR (pas d'engagement dans BTR_SURETE_REELLE)
	W_TABLE := 'TABLE: eng_corp_p2 - RG_18 :: LGD';
	update eng_corp_p2 p2
       set p2.cd_meth_ifrs9_lgd  = 'LGCBM_C1_GL'
	 where p2.cd_conso_cpt      in ('00370','00357')
	   and p2.cd_meth_ifrs9_lgd is null
	   and ((
	exists (select 1
			  from btr_operation op
			 where op.id_operation                = p2.id_engagement
			   and nvl(op.type_delegation,'NULL') = 'CRCAGLES')
	   and
	exists (select 1
              from (select sur.id_operation                             id_operation
                          ,sur.id_actif                                 id_actif
                          ,nvl(sur.cd_famille_actif,'NULL')             cd_famille_actif
                          ,rank() over(order by nvl(mnt_vv_act,0) desc) act_vtr_max
                      from btr_surete_reelle sur
                     where sur.id_operation = p2.id_engagement) sr
             where sr.act_vtr_max           = 1
               and sr.id_operation          = p2.id_engagement
               and sr.cd_famille_actif not in ('A','R','C','L','T','6')))
		or
	   not
	exists (select 1
	           from btr_surete_reelle sur
			  where sur.id_operation = p2.id_engagement));

--- RG_13
---- perimetre HORS-NAT02 donc rien a faire

---- RG_14
----    perimetre CORPORATE
---- ET societe est ('AUXIFIP' ou 'UNIFERGIE')
	W_TABLE := 'TABLE: eng_corp_p2 - RG_14 :: LGD';
	update eng_corp_p2 p2
	   set p2.cd_meth_ifrs9_lgd  = 'DEFAUTLGD'
	 where p2.cd_conso_cpt      in ('00399','00936')
       and p2.cd_meth_ifrs9_lgd is null;
    commit;
-- =======================================================================================================
--  FIN :: Maj des rg du perimetre LGD - corporate P2
-- =======================================================================================================

    DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

					--Mantis 42098 CDS_ATOS(CML) 23/02
					--Pour tous les types de risque:Alimenter p2.CLASS_CPT_REF_ACT ? l?identique de p2.CLASS_CPT_ACT_NOR_IFRS9
					--update eng_corp_p2 p1 set (p1.ELIG_OUTIL_MUT_PROV,p1.class_cpt_act_nor_ifrs9,p1.class_cpt_act_nor_nat,P1.class_cpt_ref_act) =
					--                 (select distinct ELIGIBILITE_OMP,CLASS_COMPTABLE_IFRS9,CLASS_COMPTABLE_NORME_LOCALE,CLASS_COMPTABLE_IAS39 from ref_pcco_pcec_sap sap where p1.pcco_mnt_pnu=sap.num_pcco)
					--                 where p1.pcco_mnt_pnu is not null;
    W_TABLE := 'ENG_CORP_P2 (16)';
					update eng_corp_p2 p2 set (p2.ELIG_OUTIL_MUT_PROV,p2.class_cpt_act_nor_ifrs9,p2.class_cpt_act_nor_nat,P2.class_cpt_ref_act) =
									 (select distinct ELIGIBILITE_OMP,CLASS_COMPTABLE_IFRS9,CLASS_COMPTABLE_NORME_LOCALE,CLASS_COMPTABLE_IFRS9 from ref_pcco_pcec_sap sap where p2.pcco_mnt_pnu=sap.num_pcco)
									 where p2.pcco_mnt_pnu is not null;
					commit;
					--fin mantis 42098
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

    W_TABLE := 'ENG_CORP_P2 (17)';
     /* M55563 optimisation
					UPDATE ENG_CORP_P2 p2
					set (p2.not_fin_ret_org,p2.ORG_NOTATION_ORG,p2.SEG_NOTATION_ORG,p2.GRI_NOT_ORG,p2.METH_NOTATION_ORG)=
					( select OCR.NOTE_ORIGINE,'I',OCR.CD_SEGMENT_CAL_ORI,OCR.CD_GRILLE_NOTE_ORI, upper(nvl(OCR.CD_METHODE_NOTE_ORI,' ')) -- 08/02/2019 - CDS ATOS (GBD)- US677 : fait upper

						 From CRR_ORIGINE OCR
						 Where p2.id_engagement= OCR.id_engagement
						 And p2.CD_CONSO_CPT=OCR.CD_CONSO_CPT)



								   where exists  (Select 1
													From  CRR_ORIGINE OCR

												  Where p2.id_engagement= OCR.id_engagement
												  And p2.CD_CONSO_CPT=OCR.CD_CONSO_CPT
												  );
     */
      -- M55563 optimisation
       MERGE INTO Eng_Corp_p2 p2 USING
       (
         SELECT DISTINCT
           CD_CONSO_CPT,
           id_engagement,
           NOTE_ORIGINE,
           'I' AS ORGANISME_NOTATION,
           CD_SEGMENT_CAL_ORI,
           CD_GRILLE_NOTE_ORI,
           upper(nvl(CD_METHODE_NOTE_ORI,' ')) as CD_METHODE_NOTE_ORI
         FROM
           CRR_ORIGINE
       )
       OCR ON
       (p2.id_engagement= OCR.id_engagement AND p2.CD_CONSO_CPT=OCR.CD_CONSO_CPT)
       WHEN matched THEN
         UPDATE
         SET
           p2.not_fin_ret_org   = OCR.NOTE_ORIGINE,
           p2.ORG_NOTATION_ORG  = OCR.ORGANISME_NOTATION,
           p2.SEG_NOTATION_ORG  = OCR.CD_SEGMENT_CAL_ORI,
           p2.GRI_NOT_ORG       = OCR.CD_GRILLE_NOTE_ORI,
           p2.METH_NOTATION_ORG = OCR.CD_METHODE_NOTE_ORI
       ;
					commit;
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

    W_TABLE := 'ENG_CORP_P2 (18)';
		update ENG_CORP_P2 p1
		  -- 08/02/2019 - CDS ATOS (GBD)- US677 : fait upper
		set (not_fin_ret_org,gri_not_org,meth_notation_org) = (select distinct rs.note_moyenne, rs.grille_notation, upper(nvl(rs.modele_notation,' ')) from rs_notation_moyenne rs, tie_tiers_c1_c5 c1
		  where rs.code_segment=c1.cd_portefeuille_bal_tiers
		  and c1.id_tiers_calc = p1.id_tiers_calc
		  and c1.cd_conso_cpt=p1.cd_conso_cpt
		  and c1.cd_type_relation='C'
		  and c1.cd_type_segment='CORP')
		where p1.not_fin_ret_org is null ;
    COMMIT;

    W_TABLE := 'ENG_CORP_P2 (19)';
		update eng_corp_p2 p1 set p1.not_fin_ret_org=(select id_note_balois_retail from rs_def_methodo rs where p1.not_fin_ret_org=rs.id_note_retail)
		where p1.not_fin_ret_org in (select id_note_retail from rs_def_methodo);


		COMMIT;
		-- 08/02/2019 - CDS ATOS (GBD)- US677   :  s'il reste des null
    W_TABLE := 'ENG_CORP_P2 (20)';
		update eng_corp_p2 p2 set p2.not_fin_ret_org='ND' where p2.not_fin_ret_org is null ;
		-- 08/02/2019 - CDS ATOS (GBD)- US677   :  C3 -> 999
      DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
    W_TABLE := 'ENG_CORP_P2 (21)';
		update eng_corp_p2 p2 set p2.meth_notation_org = '999'  where Upper(p2.meth_notation_org) = 'C3';
		update eng_corp_p2 p2 set p2.meth_notation_org = '   '  where  p2.meth_notation_org is null;
		commit;

    W_TABLE := 'ENG_CORP_P2 (22)';
		UPDATE ENG_CORP_P2 set GRI_NOT_ORG=null where GRI_NOT_ORG is null or
		GRI_NOT_ORG not in (select code_vers_grille_notation from rs_vers_grille_notation where lib_vers_grille_notation !='Erreur Null');
		commit;

	W_TABLE := 'ENG_CORP_P2 (23)';	 -- Mantis 66161
			UPDATE ENG_CORP_P2
			SET OBJ_FINANCIE  = '04' WHERE CD_CONSO_CPT IN ('00472');  -- M71370

        W_TABLE := 'Autorisation_F1';
		MERGE INTO Autorisation_F1   p
		USING
		    (
		    select id_engagement , ID_AUTORISATION
		    from eng_corp_p1 p1
		    ) REQ
		ON ( p.id_autorisation = REQ.ID_AUTORISATION)
		WHEN MATCHED THEN
			UPDATE SET
			    P.id_engagement = req.id_engagement;
        -- 22/11/2022 - KLX Risque - Mantis 64079 - Alimentation de l'id_engagement selon presence de l'autorisation dans le P2. Facilite l'extraction des doublons
        MERGE INTO Autorisation_F1   p
		USING (
			SELECT id_engagement , ID_AUTORISATION
			FROM eng_corp_p2 p2
			) REQ
        ON ( p.id_autorisation = REQ.ID_AUTORISATION)
        WHEN MATCHED THEN
        	UPDATE SET
                P.id_engagement = req.id_engagement
            WHERE P.ID_ENGAGEMENT IS NULL;
		COMMIT;
        DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

        W_TABLE := 'autorisation_detail_f2';
		MERGE INTO autorisation_detail_f2   p
		USING (
			select id_engagement , id_ligne_det
			from eng_corp_p1 p1
			) REQ
	    ON ( p.id_ligne_det = REQ.id_ligne_det)
	    WHEN MATCHED THEN
	    	UPDATE SET
	    	    P.id_engagement = req.id_engagement;

        -- 22/11/2022 - KLX Risque - Mantis 64079 - Alimentation de l'id_engagement selon presence de l'autorisation dans le P2. Facilite l'extraction des doublons
        MERGE INTO autorisation_detail_f2 p
		USING (
			SELECT id_engagement , ID_AUTORISATION
			FROM eng_corp_p2 p2
			) REQ
        ON ( p.id_autorisation = REQ.ID_AUTORISATION)
        WHEN MATCHED THEN
        	UPDATE SET
                P.id_engagement = req.id_engagement
            WHERE P.ID_ENGAGEMENT IS NULL;
		COMMIT;

		-- 24/10/2018 - CDS ATOS (LFD) - ANACREDIT US 532
      	DBMS_OUTPUT.PUT_LINE( ' - ' || W_TABLE || ' - ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));
        W_TABLE := 'ENG_CORP_P1';
		UPDATE ENG_CORP_P1 SET TOP_ENG='B' WHERE CD_NATURE_OPE LIKE 'NA02%';
		COMMIT;
		--FIN LFD
    	DBMS_OUTPUT.PUT_LINE( 'p_alim_eng_encours_corporate Fin : ' || To_char(SYSTIMESTAMP, 'YY/MM/DD HH24:MI:SS.FF3'));

		--DEBUT :: KLx_Risques :: M68156
		W_TABLE := 'ENG_CORP_P1 - contrats eligibles a ANACREDIT';
		merge
		 into ddrex.eng_corp_p1 p1
		using (select id_tiers_calc
					 ,cd_conso_cpt
					 ,cd_type_risque
				 from ddrex.tiers_location_simple tls
				where tls.objet = 'P1') peri
		   on (peri.id_tiers_calc  = p1.id_tiers_calc
		  and  peri.cd_conso_cpt   = p1.cd_conso_cpt
		  and  peri.cd_type_risque = p1.cd_type_risque)
		 when matched then
		   update
			  set p1.ind_eligi_outi_ctral_anacrd = '1'
			     ,p1.motif_exclu_anacredit       = '02';
		   commit;
		--FIN :: KLx_Risques :: M68156

		-- logique ici malgre que CD_PORTEFEUILLE_BALE2 soit toujours 000, le code est pret pour un changement de remplissage...
		W_TABLE := 'ENG_CORP_P2 (21.44)';	  -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.44
			UPDATE ENG_CORP_P2
			SET IND_EXPO_QUAL_ELEVEE  = CASE WHEN CD_PORTEFEUILLE_BALE2 IN ('062') THEN 'N' ELSE NULL END;

		W_TABLE := 'ENG_CORP_P2 (21.45)';	  -- KLX-GOMESHU - BALE4 - 19/12/2023 - P2 21.45 DATE_PRE_DEB_FOND = DT_MEL
			UPDATE ENG_CORP_P2
			SET IND_PHASE_OPE_PROJ_FIN  = CASE WHEN (CD_PORTEFEUILLE_BALE2 IN ('061') AND DATE_PRE_DEB_FOND IS NOT NULL) THEN 'Y' ELSE 'N' END;

		W_TABLE := 'ENG_CORP_P1 (21.44)';	  -- KLX-GOMESHU - BALE4 - 19/12/2023 - P1 21.44
			UPDATE ENG_CORP_P1
			SET IND_EXPO_QUAL_ELEVEE  = CASE WHEN CD_PORTEFEUILLE_BALE2 IN ('062') THEN 'N' ELSE NULL END;

		W_TABLE := 'ENG_CORP_P1 (21.45)';	  -- KLX-GOMESHU - BALE4 - 19/12/2023 - P1 21.45 DATE_PREM_DEB_FOND = DT_MEL
			UPDATE ENG_CORP_P1
			SET IND_PHASE_OPE_PROJ_FIN  = CASE WHEN (CD_PORTEFEUILLE_BALE2 IN ('061') AND DATE_PREM_DEB_FOND IS NOT NULL) THEN 'Y' ELSE 'N' END;

		W_TABLE := 'ENG_CORP_P1 (21.55)';	  -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.55
			UPDATE ENG_CORP_P1
			SET CD_NAT_OPE_ENG_CALC_FLOOR  = CD_NATURE_OPE ;-- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.55

		W_TABLE := 'ENG_CORP_P1 (21.55)';	  -- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.55
			UPDATE ENG_CORP_P1
			SET CD_NAT_OPE_ENG_CALC_FLOOR  = CD_NATURE_OPE ;-- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.55

		W_TABLE := 'ENG_CORP_P1 (21.40)';	  -- KLX-GOMESHU - BALE4 - 12/02/2024 - P1 21.40
			UPDATE ENG_CORP_P1
			SET IND_REAL_COND_PONDERATION_PREFE = CASE WHEN CD_CONSO_CPT = '00472' AND CD_TYPE_RISQUE IN ('TRE502','PRI105') AND ( IND_EXPO_ADC <> 'Y' OR IND_EXPO_ADC IS NULL ) THEN '1'
			WHEN CD_CONSO_CPT = '00472' AND CD_TYPE_RISQUE IN ('TRE502','PRI105') AND IND_EXPO_ADC = 'Y' THEN '0' ELSE NULL END ;-- KLX-GOMESHU - BALE4 - 26/12/2023 - P1 21.40

		W_TABLE := 'ENG_CORP_P2 (21.40)';	  -- KLX-GOMESHU - BALE4 - 12/02/2024 - P2 21.40
			UPDATE ENG_CORP_P2
			SET IND_REAL_COND_PONDERATION_PREFE = CASE WHEN CD_CONSO_CPT = '00472' AND CD_TYPE_RISQUE IN ('TRE502','PRI105') AND ( IND_EXPO_ADC <> 'Y' OR IND_EXPO_ADC IS NULL ) THEN '1'
			WHEN CD_CONSO_CPT = '00472' AND CD_TYPE_RISQUE IN ('TRE502','PRI105') AND IND_EXPO_ADC = 'Y' THEN '0' ELSE NULL END ;-- KLX-GOMESHU - BALE4 - 26/12/2023 - P2 21.40

		W_TABLE := 'ENG_CORP_P1 (21.38)';	  -- KLX-GOMESHU - BALE4 - 15/02/2024 - P1 21.38
		merge
		 into ddrex.eng_corp_p1 P1
		using (select distinct id_tiers_calc
					 ,cd_conso_cpt
					 ,CD_METHODO_NOTE
					 , CASE WHEN CD_METHODO_NOTE IN ('M2','M43') THEN 'Y' ELSE 'N' END IND_IPRE
				 from ddrex.TIE_TIERS_C1_C5 C1_C5
				where C1_C5.CD_CONSO_CPT = '00472'
				) peri
		   on (peri.id_tiers_calc  = p1.id_tiers_calc
		  and  peri.cd_conso_cpt   = p1.cd_conso_cpt)
		 when matched then
		   update
			  set P1.IND_IPRE = peri.IND_IPRE
			WHERE P1.CD_TYPE_RISQUE IN ('TRE502','PRI105')
			AND ( P1.IND_EXPO_ADC <> 'Y' OR P1.IND_EXPO_ADC IS NULL );
		   commit;

		update ddrex.eng_corp_p1 P1 set P1.IND_IPRE = 'N'
		where P1.CD_CONSO_CPT = '00472'
		and P1.CD_TYPE_RISQUE IN ('TRE502','PRI105')
		and P1.IND_EXPO_ADC = 'Y';

		W_TABLE := 'ENG_CORP_P2 (21.38)';	  -- KLX-GOMESHU - BALE4 - 15/02/2024 - P2 21.38
		merge
		 into ddrex.eng_corp_p2 P2
		using (select distinct id_tiers_calc
					 ,cd_conso_cpt
					 ,CD_METHODO_NOTE
					 , CASE WHEN CD_METHODO_NOTE IN ('M2','M43') THEN 'Y' ELSE 'N' END IND_IPRE
				 from ddrex.TIE_TIERS_C1_C5 C1_C5
				where C1_C5.CD_CONSO_CPT = '00472'
				) peri
		   on (peri.id_tiers_calc  = P2.id_tiers_calc
		  and  peri.cd_conso_cpt   = P2.cd_conso_cpt)
		 when matched then
		   update
			  set P2.IND_IPRE = peri.IND_IPRE
			WHERE P2.CD_TYPE_RISQUE IN ('TRE502','PRI105')
            AND ( P2.IND_EXPO_ADC <> 'Y' OR P2.IND_EXPO_ADC IS NULL );
			commit;

		update ddrex.eng_corp_p2 P2 set P2.IND_IPRE = 'N'
		where P2.CD_CONSO_CPT = '00472'
		and P2.CD_TYPE_RISQUE IN ('TRE502','PRI105')
		and P2.IND_EXPO_ADC = 'Y';

		W_TABLE := 'ENG_CORP_P1 (31.6)'; -- KLX-GOMESHU - BALE4 - 29/04/2024 - P1 31.6

		merge into ddrex.eng_corp_p1 P1
		  using (
			  select fipuni.id_operation, decode(fipuni.ind_qualification_isf,'Y','1','N','2') ind_isf
			  from eng_fipuni_taxonomie fipuni
 		  ) perim
		on ( p1.id_engagement = perim.id_operation )
		when matched then update
		set p1.ind_isf = perim.ind_isf
		where p1.cd_conso_cpt in ('00936','00399')
		and p1.cd_portefeuille_bale2 in ('061');

		W_TABLE := 'ENG_CORP_P2 (31.6)'; -- KLX-GOMESHU - BALE4 - 29/04/2024 - P2 31.6

		merge into ddrex.eng_corp_p2 P2
		  using (
			  select fipuni.id_operation, decode(fipuni.ind_qualification_isf,'Y','1','N','2') ind_isf
			  from eng_fipuni_taxonomie fipuni
 		  ) perim
		on ( p2.id_engagement = perim.id_operation )
		when matched then update
		set p2.ind_isf = perim.ind_isf
		where p2.cd_conso_cpt in ('00936','00399')
		and p2.cd_portefeuille_bale2 in ('061');

		W_TABLE := 'ENG_CORP_P1 (21.46)'; -- BALE4 - P1 21.46

		merge into ddrex.eng_corp_p1 P1
		  using (
			  select o.id_operation, o.ind_conf_crit_ope
			  from btr_operation o
 		  ) perim
		on ( p1.id_engagement = perim.id_operation )
		when matched then update
		set p1.ind_conf_crit_ope = perim.ind_conf_crit_ope
		where p1.cd_conso_cpt in ('00936','00399')
		and p1.cd_portefeuille_bale2 in ('061');

		W_TABLE := 'ENG_CORP_P2 (21.46)'; -- BALE4 - P2 21.46

		merge into ddrex.eng_corp_p2 P2
		  using (
			  select o.id_operation, o.ind_conf_crit_ope
			  from btr_operation o
 		  ) perim
		on ( p2.id_engagement = perim.id_operation )
		when matched then update
		set p2.ind_conf_crit_ope = perim.ind_conf_crit_ope
		where p2.cd_conso_cpt in ('00936','00399')
		and p2.cd_portefeuille_bale2 in ('061');

		W_TABLE := 'ENG_CORP_P1 (21.87)'; -- BALE4 - P1 21.87
        update ddrex.eng_corp_p1 p1
		set p1.cd_emplace_bien_comm = '2' where p1.cd_emplace_bien_comm is null
		and p1.cd_conso_cpt = '00472' and p1.cd_type_risque in ('TRE502','PRI105');

		W_TABLE := 'ENG_CORP_P2 (21.87)'; -- BALE4 - P2 21.87
        update ddrex.eng_corp_p2 p2
		set p2.cd_emplace_bien_comm = '2' where p2.cd_emplace_bien_comm is null
		and p2.cd_conso_cpt = '00472' and p2.cd_type_risque in ('TRE502','PRI105');

		W_TABLE := 'ENG_CORP_P2 (31.17_18)'; -- Mantis 71784
        update ddrex.eng_corp_p2 p2
		set p2.DUREE_INIT_PRET = round(ceil(months_between( DT_FIN_ENG , DT_DEBUT_ENG ))),
		p2.DUREE_TOTALE_PRET_DATE = round(ceil(months_between( DT_FIN_ENG , DT_DEBUT_ENG )))
		where (p2.DUREE_INIT_PRET is null or p2.DUREE_TOTALE_PRET_DATE is null );

        -- =======================================================================================================
        --  DEBUT :: projet OMP - SIRL-195
        -- =======================================================================================================
            /**
			  ----------------------------------------------------------------------------------------------------
		        REMARQUES:
                  - dans les perimetres P1 et P2 (tables ENG_CORP_P1 et ENG_CORP_P2) la segmentation des contrats
                    est toujours CORPORATE
                  - dans le corporate on doit chercher les infos dans les fichiers des granulaires

		        ALGORITHME P1 (bilan):
                  1 - si c'est un ancien contrat et il fait objet d'une RCOM
                  1.1 - cd_meth_ifrs9_pd_orig = derniere valeur calculee (mois M = 31/10/2025)
                  1.2 - cd_meth_ifrs9_pd_orig = valeur recuperee du granulaire (mois M+1 = 30/11/2025)
                  1.3 - cd_meth_ifrs9_pd_orig = derniere valeur calculee (si n'existe pas dans le granulaire)
                  1.4 - date_deb_eng_renvl = date de restructuration du mois en cours (mois M)
                  1.5 - date_deb_eng_renvl = valeur recupere du granulaire (mois M+1)
                  1.6 - date_deb_eng_renvl = dernier date calculee (si n'existe pas dans le granulaire)
                  1.7 - maj des infos dans CRR_OMP
			  ----------------------------------------------------------------------------------------------------
		    **/
            w_table := 'MAJ OMP - anciens contrats p1 avec rcom :: [bilan]';
			merge
			 into crr_omp omp_maj
			using (select distinct
			              p1.dt_arrete                                                                                                                                                           as dt_arrete
                         ,p1.id_engagement                                                                                                                                                       as id_engagement
                         ,p1.id_tiers_calc                                                                                                                                                       as id_tiers_calc
                         ,p1.cd_conso_cpt                                                                                                                                                        as cd_conso_cpt
                         ,bt.note_calc_fin                                                                                                                                                       as note_calc_fin
                         ,bo.cd_flag_restructuration                                                                                                                                             as cd_flag_restructuration
                         ,case --- dans le cas d'une nouvelle restructuration - mois M+1 et suivants
                          when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv  is not null
                           and omp.info_methode_flux is not null
                          then gr.dt_deb_eng_renouv
                          else case --- dans le cas d'une nouvelle restructuration - mois M
                               when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) <> nvl(decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux), to_date('01/01/1999','dd/mm/yyyy'))
                               then bo.dt_maj_flag_restruct
                               else decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux)
                                end
                           end                                                                                                                                                                   as dt_maj_flag_restruct
                         ,case --- dans le cas d'une nouvelle restructuration - mois M+1 et suivants
                          when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv  is not null
                           and omp.info_methode_flux is not null
                          then 'ancien contrat - valeur recuperee du granulaire'
                          else case --- dans le cas d'une nouvelle restructuration - mois M
                               when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) <> nvl(decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux), to_date('01/01/1999','dd/mm/yyyy'))
                               then 'ancien contrat - conserve la derniere valeur calculee + maj la date debut de l''engagement renouvele'
                               else 'ancien contrat - conserve la derniere valeur calculee'
                                end
                           end                                                                                                                                                                   as info_methode_flux
                         ,case --- dans le cas d'une nouvelle restructuration - mois M+1 et suivants
                          when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv  is not null
                           and omp.info_methode_flux is not null
                          then gr.cd_meth_ifrs9_pd_orig
						   --- dans tous les cas - mois M
                          else decode(omp.info_methode_flux, null, omp.cd_meth_ifrs9_pd_orig, omp.cd_meth_ifrs9_pd_orig_flux)
                           end                                                                                                                                                                   as cd_meth_ifrs9_pd_orig_flux
			         from (select distinct
                                  ref_uniq_ctr
                                 ,cd_entite
                                 ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                                 ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                             from tmp_gr05_granulaire
                            group
                               by ref_uniq_ctr, cd_entite) gr
                         ,eng_corp_p1                      p1
					     ,btr_operation                    bo
						 ,btr_tiers                        bt
						 ,crr_omp                          omp
			        where bo.id_tiers       = bt.id_tiers
					  and p1.id_engagement  = bo.id_operation
					  and p1.dt_arrete      = bo.dt_arrete
					  and omp.id_operation  = p1.id_engagement
					  and omp.id_tiers_calc = p1.id_tiers_calc
					  and omp.cd_conso_cpt  = p1.cd_conso_cpt
                      and p1.id_engagement  = gr.ref_uniq_ctr (+)
                      and p1.cd_conso_cpt   = gr.cd_entite    (+)
					  and bt.cd_role_tiers  = 'C'
                      and bo.cd_flag_restructuration = 'RCOM') peri_maj
			   on (peri_maj.id_engagement = omp_maj.id_operation
			  and  peri_maj.id_tiers_calc = omp_maj.id_tiers_calc
			  and  peri_maj.cd_conso_cpt  = omp_maj.cd_conso_cpt)
             when matched then
			     update
				    set omp_maj.note_flux                  = peri_maj.note_calc_fin
					   ,omp_maj.cd_flag_restructuration    = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_maj_flag_restruct       = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_flag_restruct_flux      = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_debut_eng_renouv_flux   = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_meth_ifrs9_pd_orig_flux = peri_maj.cd_meth_ifrs9_pd_orig_flux
					   ,omp_maj.info_methode_flux          = peri_maj.info_methode_flux;
			     commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    2 - si c'est un ancien contrat et il ne fait pas objet d'une RCOM
			    2.1 - code methode ifrs9 pd a l'origine = derniere valeur calculee (mois M = 31/10/2025)
			    2.2 - date de restructuration = derniere valeur calculee (null si le contrat n'a jamais ete RCOM)
			    2.3 - maj des infos dans CRR_OMP
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ OMP - anciens contrats p1 sans rcom :: [bilan]';
            merge
			 into crr_omp omp_maj
			using (select distinct
			              p1.dt_arrete                                                                                   as dt_arrete
                         ,p1.id_engagement                                                                               as id_engagement
                         ,p1.id_tiers_calc                                                                               as id_tiers_calc
						 ,p1.cd_conso_cpt                                                                                as cd_conso_cpt
						 ,bt.note_calc_fin                                                                               as note_calc_fin
						 ,bo.cd_flag_restructuration                                                                     as cd_flag_restructuration
						 ,decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux)    as dt_maj_flag_restruct
                         ,decode(omp.info_methode_flux, null, omp.cd_meth_ifrs9_pd_orig, omp.cd_meth_ifrs9_pd_orig_flux) as cd_meth_ifrs9_pd_orig
			         from eng_corp_p1   p1
					     ,btr_operation bo
						 ,btr_tiers     bt
						 ,crr_omp       omp
			        where bo.id_tiers       = bt.id_tiers
					  and p1.id_engagement  = bo.id_operation
					  and p1.dt_arrete      = bo.dt_arrete
					  and omp.id_operation  = p1.id_engagement
					  and omp.id_tiers_calc = p1.id_tiers_calc
					  and omp.cd_conso_cpt  = p1.cd_conso_cpt
					  and bt.cd_role_tiers  = 'C'
                      and nvl(bo.cd_flag_restructuration,'XX') <> 'RCOM') peri_maj
			   on (peri_maj.id_engagement = omp_maj.id_operation
			  and  peri_maj.id_tiers_calc = omp_maj.id_tiers_calc
			  and  peri_maj.cd_conso_cpt  = omp_maj.cd_conso_cpt)
             when matched then
			     update
				    set omp_maj.note_flux                  = peri_maj.note_calc_fin
					   ,omp_maj.cd_flag_restruct_flux      = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_debut_eng_renouv_flux   = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_meth_ifrs9_pd_orig_flux = peri_maj.cd_meth_ifrs9_pd_orig
					   ,omp_maj.info_methode_flux          = 'ancien contrat - conserve la derniere valeur calculee';
				 commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    3 - maj des donnees dans le perimetre p1 (bilan) - anciens contrats
			    3.1 - code methode ifrs9 pd a l'origine
			    3.2 - date debut de l'engagement renouvele
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ P1 - cd_meth_ifrs9_pd_orig + date_deb_eng_renvl :: [bilan]';
            merge
			 into eng_corp_p1 p1_maj
			using (select distinct
                          omp.id_operation                                         as id_operation
                         ,omp.cd_conso_cpt                                         as cd_conso_cpt
                         ,omp.id_tiers_calc                                        as id_tiers_calc
                         ,omp.cd_flag_restruct_flux                                as cd_flag_restruct_flux
                         ,omp.dt_debut_eng_renouv_flux                             as dt_debut_eng_renouv_flux
                         ,nvl(omp.dt_debut_eng_renouv_flux, p1.date_deb_eng_renvl) as dt_debut_eng_renouvele
                         ,omp.cd_meth_ifrs9_pd_orig_flux                           as cd_meth_ifrs9_pd_orig_flux
                     from crr_omp     omp
                         ,eng_corp_p1 p1
                    where omp.id_operation  = p1.id_engagement
                      and omp.cd_conso_cpt  = p1.cd_conso_cpt
                      and omp.id_tiers_calc = p1.id_tiers_calc
                      and omp.info_methode_flux is not null) peri
			   on (p1_maj.id_engagement = peri.id_operation
			  and  p1_maj.id_tiers_calc = peri.id_tiers_calc
			  and  p1_maj.cd_conso_cpt  = peri.cd_conso_cpt)
             when matched then
			     update
				    set p1_maj.date_deb_eng_renvl    = peri.dt_debut_eng_renouvele
					   ,p1_maj.cd_meth_ifrs9_pd_orig = peri.cd_meth_ifrs9_pd_orig_flux;
				 commit;

            w_table := 'MAJ P1 - date_deb_eng_renvl si jamais RCOM :: [bilan]';
            merge
			 into eng_corp_p1 p1_maj
			using (select distinct
                          omp.id_operation            as id_operation
                         ,omp.cd_conso_cpt            as cd_conso_cpt
                         ,omp.id_tiers_calc           as id_tiers_calc
						 ,omp.cd_flag_restructuration as cd_flag_jamais_rcom
                         ,omp.cd_flag_restruct_flux   as cd_flag_restr_flux
                     from crr_omp     omp
                         ,eng_corp_p1 p1
                    where omp.id_operation  = p1.id_engagement
                      and omp.cd_conso_cpt  = p1.cd_conso_cpt
                      and omp.id_tiers_calc = p1.id_tiers_calc
                      and omp.info_methode_flux is not null) peri
			   on (p1_maj.id_engagement = peri.id_operation
			  and  p1_maj.id_tiers_calc = peri.id_tiers_calc
			  and  p1_maj.cd_conso_cpt  = peri.cd_conso_cpt
			  and  nvl(peri.cd_flag_jamais_rcom,'XX') != 'RCOM'
			  and  nvl(peri.cd_flag_restr_flux,'XX')  != 'RCOM')
             when matched then
			     update
				    set p1_maj.date_deb_eng_renvl = null;
			     commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    4 - si c'est un nouveau contrat et il fait objet d'une RCOM
                4.1 - code methode ifrs9 pd a l'origine = null (mois M = 31/10/2025)
			    4.2 - code methode ifrs9 pd a l'origine = valeur recuperee du granulaire (mois M+1 = 30/11/2025)
                4.3 - determiner la date de restructuration a la date d'arrete du mois en cours (mois M)
			    4.4 - si date recuperee du granulaire = date de restructuration a la date d'arrete du mois en cours
			    4.4.1 - date debut de l'engagement renouvele = date recuperee du granulaire (mois M+1)
			    4.5 - sinon
			    4.5.1 - date debut de l'engagement renouvele = date de restructuration calculee (mois M+1)
                4.6 - maj des infos dans ENG_CORP_P1
             ET
                5 - si c'est un nouveau contrat et il ne fait pas objet d'une RCOM
                5.1 - code methode ifrs9 pd a l'origine = null (mois M = 31/10/2025)
				5.2 - code methode ifrs9 pd a l'origine = valeur recuperee du granulaire (mois M+1 = 30/11/2025)
				5.3 - determiner la date de restructuration a la date d'arrete du mois en cours
				5.4 - date debut de l'engagement renouvele = date de restructuration calculee (normalement null)
                5.5 - si null dans 5.4 alors date debut de l'engagement renouvele = valeur deja calculee dans P1
                5.6 - maj des infos dans ENG_CORP_P1
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ P1 - nouveaux contrats avec et sans rcom :: [bilan]';
            merge
			 into eng_corp_p1 p1_maj
			using (select distinct
                          p1.dt_arrete                                                                                                                          as dt_arrete
                         ,p1.id_engagement                                                                                                                      as id_engagement
                         ,p1.id_tiers_calc                                                                                                                      as id_tiers_calc
                         ,p1.cd_conso_cpt                                                                                                                       as cd_conso_cpt
                         ,bt.note_calc_fin                                                                                                                      as note_calc_fin
                         ,bo.cd_flag_restructuration                                                                                                            as cd_flag_restructuration
                         ,case
						  when bo.cd_flag_restructuration = 'RCOM'
                           and nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv is not null
                          then gr.dt_deb_eng_renouv
                          else decode(bo.cd_flag_restructuration, 'RCOM', nvl(bo.dt_maj_flag_restruct, p1.date_deb_eng_renvl), null)
                           end                                                                                                                                  as dt_debut_eng_renouvele
                         ,coalesce(gr.cd_meth_ifrs9_pd_orig, null)                                                                                              as cd_meth_ifrs9_pd_orig_flux
			         from (select distinct
                                  ref_uniq_ctr
                                 ,cd_entite
                                 ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                                 ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                             from tmp_gr05_granulaire
                            group
                               by ref_uniq_ctr, cd_entite) gr
                         ,eng_corp_p1                      p1
					     ,btr_operation                    bo
						 ,btr_tiers                        bt
			        where bo.id_tiers      = bt.id_tiers
					  and p1.id_engagement = bo.id_operation
					  and p1.dt_arrete     = bo.dt_arrete
                      and p1.id_engagement = gr.ref_uniq_ctr (+)
                      and p1.cd_conso_cpt  = gr.cd_entite    (+)
					  and bt.cd_role_tiers = 'C'
                      and
                      not
                   exists (select 1
                             from crr_omp omp
                            where omp.id_operation  = p1.id_engagement
		                      and omp.cd_conso_cpt  = p1.cd_conso_cpt
		                      and omp.id_tiers_calc = p1.id_tiers_calc)) peri_maj
               on (p1_maj.id_engagement = peri_maj.id_engagement
			  and  p1_maj.id_tiers_calc = peri_maj.id_tiers_calc
			  and  p1_maj.cd_conso_cpt  = peri_maj.cd_conso_cpt)
			 when matched then
                 update
				    set p1_maj.date_deb_eng_renvl    = peri_maj.dt_debut_eng_renouvele
			           ,p1_maj.cd_meth_ifrs9_pd_orig = peri_maj.cd_meth_ifrs9_pd_orig_flux;
                 commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    6 - ajouter les nouveaux contrats dans la table CRR_OMP
			    6.1 - contrats avec RCOM
			    6.2 - contrats sans RCOM
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'INSERT OMP - nouveaux contrats p1 :: [bilan]';
            insert
			  into crr_omp
            select distinct
			       p1.id_engagement                                                                                                                      as id_operation
                  ,p1.id_tiers_calc                                                                                                                      as id_tiers_calc
                  ,p1.cd_conso_cpt                                                                                                                       as cd_conso_cpt
                  ,p1.dt_arrete                                                                                                                          as dt_calc_rcom
                  ,bt.id_tiers                                                                                                                           as id_tiers
                  ,bt.id_entr                                                                                                                            as id_entr
                  ,bt.num_siren                                                                                                                          as num_siren
                  ,'P1'                                                                                                                                  as objet
                  ,p1.dt_debut_eng                                                                                                                       as dt_debut_eng
                  ,bo.cd_flag_restructuration                                                                                                            as cd_flag_restructuration
                  ,case
                   when bo.cd_flag_restructuration = 'RCOM'
                    and nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                    and gr.dt_deb_eng_renouv is not null
                   then gr.dt_deb_eng_renouv
                   else decode(bo.cd_flag_restructuration, 'RCOM', bo.dt_maj_flag_restruct, null)
                    end                                                                                                                                  as dt_maj_flag_restruct
                  ,null                                                                                                                                  as dt_calc_sgmt
                  ,bt.cd_segment_casa                                                                                                                    as cd_segment_casa
                  ,bt.cd_type_sgmt                                                                                                                       as cd_type_sgmt
                  ,bt.cd_pays_risque                                                                                                                     as cd_pays_risque
                  ,null                                                                                                                                  as dt_calc_note
                  ,bt.note_calc_fin                                                                                                                      as note_origine
                  ,null                                                                                                                                  as note_calc
                  ,null                                                                                                                                  as cd_meth_ifrs9_pd_orig
                  ,null                                                                                                                                  as info_methode
                  ,bt.note_calc_fin                                                                                                                      as note_flux
                  ,bo.cd_flag_restructuration                                                                                                            as cd_flag_restruct_flux
				  ,case
                   when bo.cd_flag_restructuration = 'RCOM'
                    and nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                    and gr.dt_deb_eng_renouv is not null
                   then gr.dt_deb_eng_renouv
                   else decode(bo.cd_flag_restructuration, 'RCOM', bo.dt_maj_flag_restruct, null)
                    end                                                                                                                                  as dt_debut_eng_renouv_flux
                  ,coalesce(gr.cd_meth_ifrs9_pd_orig, null)                                                                                              as cd_meth_ifrs9_pd_orig_flux
                  ,case
                   when gr.cd_meth_ifrs9_pd_orig is not null
                   then 'nouveau contrat - valeur recuperee du granulaire'
                   else 'nouveau contrat - valeur renseignee a vide'
                    end                                                                                                                                  as info_methode_flux
              from (select distinct
                           ref_uniq_ctr
                          ,cd_entite
                          ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                          ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                      from tmp_gr05_granulaire
                     group
                        by ref_uniq_ctr, cd_entite) gr
                  ,eng_corp_p1                      p1
                  ,btr_operation                    bo
                  ,btr_tiers                        bt
             where bo.id_tiers      = bt.id_tiers
               and p1.id_engagement = bo.id_operation
               and p1.dt_arrete     = bo.dt_arrete
               and p1.id_engagement = gr.ref_uniq_ctr (+)
               and p1.cd_conso_cpt  = gr.cd_entite    (+)
               and bt.cd_role_tiers = 'C'
               and
               not
            exists (select 1
                      from crr_omp omp
                     where omp.id_operation  = p1.id_engagement
                       and omp.cd_conso_cpt  = p1.cd_conso_cpt
                       and omp.id_tiers_calc = p1.id_tiers_calc);
            commit;

            /**
			  ----------------------------------------------------------------------------------------------------
		        REMARQUES:
				  - le perimetre hors-bilan ne sera jamais RCOM ?? Il n'a pas cette info dans BTR_HORS_BILAN

		        ALGORITHME P1 (hors-bilan):
                  1 - si c'est un ancien contrat et il ne fait pas objet d'une RCOM
                  1.1 - code methode ifrs9 pd a l'origine = derniere valeur calculee (mois M = 31/10/2025)
                  1.2 - date de restructuration = derniere valeur calculee (null si le contrat n'a jamais ete RCOM)
                  1.3 - maj des infos dans CRR_OMP
			  ----------------------------------------------------------------------------------------------------
		    **/
            w_table := 'MAJ OMP - anciens contrats p1 sans rcom :: [hors-bilan]';
            merge
			 into crr_omp omp_maj
			using (select distinct
                          p1.dt_arrete                                                                                   as dt_arrete
                         ,p1.id_engagement                                                                               as id_engagement
                         ,p1.id_tiers_calc                                                                               as id_tiers_calc
                         ,p1.cd_conso_cpt                                                                                as cd_conso_cpt
                         ,bt.note_calc_fin                                                                               as note_calc_fin
                         ,null                                                                                           as cd_flag_restructuration
                         ,decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux)    as dt_maj_flag_restruct
                         ,decode(omp.info_methode_flux, null, omp.cd_meth_ifrs9_pd_orig, omp.cd_meth_ifrs9_pd_orig_flux) as cd_meth_ifrs9_pd_orig
                     from (select distinct
                                  ref_uniq_ctr
                                 ,cd_entite
                                 ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                                 ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                             from tmp_gr05_granulaire
                            group
                               by ref_uniq_ctr, cd_entite) gr
                         ,eng_corp_p1                      p1
                         ,btr_hors_bilan                   hb
                         ,btr_tiers                        bt
                         ,crr_omp                          omp
                    where hb.id_tiers       = bt.id_tiers
                      and p1.id_engagement  = hb.id_operation_sig
                      and p1.dt_arrete      = hb.dt_arrete
                      and p1.id_engagement  = gr.ref_uniq_ctr (+)
                      and p1.cd_conso_cpt   = gr.cd_entite    (+)
                      and hb.mnt_iec        > 0
                      and omp.id_operation  = p1.id_engagement
                      and omp.id_tiers_calc = p1.id_tiers_calc
                      and omp.cd_conso_cpt  = p1.cd_conso_cpt
                      and bt.cd_role_tiers  = 'C') peri_maj
               on (peri_maj.id_engagement = omp_maj.id_operation
			  and  peri_maj.id_tiers_calc = omp_maj.id_tiers_calc
			  and  peri_maj.cd_conso_cpt  = omp_maj.cd_conso_cpt)
             when matched then
                 update
				    set omp_maj.note_flux                  = peri_maj.note_calc_fin
					   ,omp_maj.cd_flag_restruct_flux      = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_debut_eng_renouv_flux   = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_meth_ifrs9_pd_orig_flux = peri_maj.cd_meth_ifrs9_pd_orig
					   ,omp_maj.info_methode_flux          = 'ancien contrat - conserve la derniere valeur calculee';
                 commit;

            /**
              ----------------------------------------------------------------------------------------------------
                2 - maj des donnees dans le perimetre p1 (hors-bilan) - anciens contrats
                2.1 - code methode ifrs9 pd a l'origine
                2.2 - date debut de l'engagement renouvele
              ----------------------------------------------------------------------------------------------------
            **/
            w_table := 'MAJ P1 - cd_meth_ifrs9_pd_orig + date_deb_eng_renvl :: [hors-bilan]';
            merge
			 into eng_corp_p1 p1_maj
            using (select distinct
                          omp.id_operation                                         as id_operation
                         ,omp.cd_conso_cpt                                         as cd_conso_cpt
                         ,omp.id_tiers_calc                                        as id_tiers_calc
                         ,omp.cd_flag_restruct_flux                                as cd_flag_restruct_flux
                         ,omp.dt_debut_eng_renouv_flux                             as dt_debut_eng_renouv_flux
                         ,nvl(omp.dt_debut_eng_renouv_flux, p1.date_deb_eng_renvl) as dt_debut_eng_renouvele
                         ,omp.cd_meth_ifrs9_pd_orig_flux                           as cd_meth_ifrs9_pd_orig_flux
                     from crr_omp     omp
                         ,eng_corp_p1 p1
                    where omp.id_operation  = p1.id_engagement
                      and omp.cd_conso_cpt  = p1.cd_conso_cpt
                      and omp.id_tiers_calc = p1.id_tiers_calc
                      and omp.info_methode_flux is not null) peri
               on (p1_maj.id_engagement = peri.id_operation
              and  p1_maj.id_tiers_calc = peri.id_tiers_calc
              and  p1_maj.cd_conso_cpt  = peri.cd_conso_cpt)
             when matched then
                 update
				    set p1_maj.date_deb_eng_renvl    = peri.dt_debut_eng_renouvele
					   ,p1_maj.cd_meth_ifrs9_pd_orig = peri.cd_meth_ifrs9_pd_orig_flux;
                 commit;

            w_table := 'MAJ P1 - date_deb_eng_renvl si jamais RCOM :: [hors-bilan]';
            merge
			 into eng_corp_p1 p1_maj
            using (select distinct
                          omp.id_operation            as id_operation
                         ,omp.cd_conso_cpt            as cd_conso_cpt
                         ,omp.id_tiers_calc           as id_tiers_calc
                         ,omp.cd_flag_restructuration as cd_flag_jamais_rcom
                         ,omp.cd_flag_restruct_flux   as cd_flag_restr_flux
                     from crr_omp     omp
                         ,eng_corp_p1 p1
                    where omp.id_operation  = p1.id_engagement
                      and omp.cd_conso_cpt  = p1.cd_conso_cpt
                      and omp.id_tiers_calc = p1.id_tiers_calc
                      and omp.info_methode_flux is not null) peri
               on (p1_maj.id_engagement                = peri.id_operation
              and  p1_maj.id_tiers_calc                = peri.id_tiers_calc
              and  p1_maj.cd_conso_cpt                 = peri.cd_conso_cpt
			  and  nvl(peri.cd_flag_jamais_rcom,'XX') != 'RCOM'
			  and  nvl(peri.cd_flag_restr_flux,'XX')  != 'RCOM')
             when matched then
                 update
				    set p1_maj.date_deb_eng_renvl = null;
                 commit;

            /**
			  ----------------------------------------------------------------------------------------------------
                3 - si c'est un nouveau contrat et il ne fait pas objet d'une RCOM
                3.1 - code methode ifrs9 pd a l'origine = null (mois M = 31/10/2025)
				3.2 - date debut de l'engagement renouvele = null (dans hors-bilan on n'a pas cette info)
                3.3 - si null dans 3.2 alors date debut de l'engagement renouvele = valeur deja calculee dans P1
                3.4 - maj des infos dans ENG_CORP_P1
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ P1 - nouveaux contrats sans rcom :: [hors-bilan]';
            merge
			 into eng_corp_p1 p1_maj
			using (select distinct
                          p1.dt_arrete                             as dt_arrete
                         ,p1.id_engagement                         as id_engagement
                         ,p1.id_tiers_calc                         as id_tiers_calc
                         ,p1.cd_conso_cpt                          as cd_conso_cpt
                         ,bt.note_calc_fin                         as note_calc_fin
                         ,null                                     as cd_flag_restructuration
                         ,null                                     as dt_debut_eng_renouvele
                         ,coalesce(gr.cd_meth_ifrs9_pd_orig, null) as cd_meth_ifrs9_pd_orig_flux
                     from (select distinct
                                  ref_uniq_ctr
                                 ,cd_entite
                                 ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                                 ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                             from tmp_gr05_granulaire
                            group
                               by ref_uniq_ctr, cd_entite) gr
                         ,eng_corp_p1                      p1
                         ,btr_hors_bilan                   hb
                         ,btr_tiers                        bt
                    where hb.id_tiers      = bt.id_tiers
                      and p1.id_engagement = hb.id_operation_sig
                      and p1.dt_arrete     = hb.dt_arrete
                      and hb.mnt_iec       > 0
                      and p1.id_engagement = gr.ref_uniq_ctr (+)
                      and p1.cd_conso_cpt  = gr.cd_entite    (+)
                      and bt.cd_role_tiers = 'C'
                      and
                      not
                   exists (select 1
                             from crr_omp omp
                            where omp.id_operation  = p1.id_engagement
                              and omp.cd_conso_cpt  = p1.cd_conso_cpt
                              and omp.id_tiers_calc = p1.id_tiers_calc)) peri_maj
			   on (p1_maj.id_engagement = peri_maj.id_engagement
              and  p1_maj.id_tiers_calc = peri_maj.id_tiers_calc
              and  p1_maj.cd_conso_cpt  = peri_maj.cd_conso_cpt)
             when matched then
                 update
				    set p1_maj.date_deb_eng_renvl    = peri_maj.dt_debut_eng_renouvele
					   ,p1_maj.cd_meth_ifrs9_pd_orig = peri_maj.cd_meth_ifrs9_pd_orig_flux;
                 commit;

            /**
			  ----------------------------------------------------------------------------------------------------
                4 - ajouter les nouveaux contrats dans la table CRR_OMP
                4.1 - contrats sans RCOM
			  ----------------------------------------------------------------------------------------------------
            **/
            w_table := 'INSERT OMP - nouveaux contrats p1 :: [hors-bilan]';
            insert
			  into crr_omp
            select distinct
			       p1.id_engagement                                        as id_operation
                  ,p1.id_tiers_calc                                        as id_tiers_calc
                  ,p1.cd_conso_cpt                                         as cd_conso_cpt
                  ,p1.dt_arrete                                            as dt_calc_rcom
                  ,bt.id_tiers                                             as id_tiers
                  ,bt.id_entr                                              as id_entr
                  ,bt.num_siren                                            as num_siren
                  ,'P1'                                                    as objet
                  ,p1.dt_debut_eng                                         as dt_debut_eng
                  ,null                                                    as cd_flag_restructuration
                  ,null                                                    as dt_maj_flag_restruct
                  ,null                                                    as dt_calc_sgmt
                  ,bt.cd_segment_casa                                      as cd_segment_casa
                  ,bt.cd_type_sgmt                                         as cd_type_sgmt
                  ,bt.cd_pays_risque                                       as cd_pays_risque
                  ,null                                                    as dt_calc_note
                  ,bt.note_calc_fin                                        as note_origine
                  ,null                                                    as note_calc
                  ,null                                                    as cd_meth_ifrs9_pd_orig
                  ,null                                                    as info_methode
                  ,bt.note_calc_fin                                        as note_flux
                  ,null                                                    as cd_flag_restruct_flux
                  ,null                                                    as dt_debut_eng_renouv_flux
                  ,coalesce(gr.cd_meth_ifrs9_pd_orig, null)                as cd_meth_ifrs9_pd_orig_flux
                  ,case
                   when gr.cd_meth_ifrs9_pd_orig is not null
                   then 'nouveau contrat - valeur recuperee du granulaire'
                   else 'nouveau contrat - valeur renseignee a vide'
                    end                                                    as info_methode_flux
              from (select distinct
                           ref_uniq_ctr
                          ,cd_entite
                          ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                          ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                      from tmp_gr05_granulaire
                     group
                        by ref_uniq_ctr, cd_entite) gr
                  ,eng_corp_p1                      p1
                  ,btr_hors_bilan                   hb
                  ,btr_tiers                        bt
             where hb.id_tiers      = bt.id_tiers
               and p1.id_engagement = hb.id_operation_sig
               and p1.dt_arrete     = hb.dt_arrete
               and hb.mnt_iec       > 0
               and p1.id_engagement = gr.ref_uniq_ctr (+)
               and p1.cd_conso_cpt  = gr.cd_entite    (+)
               and bt.cd_role_tiers = 'C'
               and
               not
            exists (select 1
                      from crr_omp omp
                     where omp.id_operation  = p1.id_engagement
                       and omp.cd_conso_cpt  = p1.cd_conso_cpt
                       and omp.id_tiers_calc = p1.id_tiers_calc);
            commit;

            /**
			  ----------------------------------------------------------------------------------------------------
		        ALGORITHME P2:
                  1 - si c'est un ancien contrat et il fait objet d'une RCOM
                  1.1 - cd_meth_ifrs9_pd_orig = derniere valeur calculee (mois M = 31/10/2025)
                  1.2 - cd_meth_ifrs9_pd_orig = valeur recuperee du granulaire (mois M+1 = 30/11/2025)
                  1.3 - cd_meth_ifrs9_pd_orig = derniere valeur calculee (si n'existe pas dans le granulaire)
                  1.4 - date_deb_eng_renvl = date de restructuration du mois en cours (mois M)
                  1.5 - date_deb_eng_renvl = valeur recupere du granulaire (mois M+1)
                  1.6 - date_deb_eng_renvl = dernier date calculee (si n'existe pas dans le granulaire)
                  1.7 - maj des infos dans CRR_OMP
			  ----------------------------------------------------------------------------------------------------
		    **/
            w_table := 'MAJ OMP - anciens contrats p2 avec rcom';
			merge
			 into crr_omp omp_maj
			using (select distinct
			              p2.dt_arrete                                                                                                                                                           as dt_arrete
                         ,p2.id_engagement                                                                                                                                                       as id_engagement
                         ,p2.id_tiers_calc                                                                                                                                                       as id_tiers_calc
                         ,p2.cd_conso_cpt                                                                                                                                                        as cd_conso_cpt
                         ,bt.note_calc_fin                                                                                                                                                       as note_calc_fin
                         ,bo.cd_flag_restructuration                                                                                                                                             as cd_flag_restructuration
                         ,case --- dans le cas d'une nouvelle restructuration - mois M+1 et suivants
                          when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv  is not null
                           and omp.info_methode_flux is not null
                          then gr.dt_deb_eng_renouv
                          else case --- dans le cas d'une nouvelle restructuration - mois M
                               when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) <> nvl(decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux), to_date('01/01/1999','dd/mm/yyyy'))
                               then bo.dt_maj_flag_restruct
                               else decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux)
                                end
                           end                                                                                                                                                                   as dt_maj_flag_restruct
                         ,case --- dans le cas d'une nouvelle restructuration - mois M+1 et suivants
                          when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv  is not null
                           and omp.info_methode_flux is not null
                          then 'ancien contrat - valeur recuperee du granulaire'
                          else case --- dans le cas d'une nouvelle restructuration - mois M
                               when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) <> nvl(decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux), to_date('01/01/1999','dd/mm/yyyy'))
                               then 'ancien contrat - conserve la derniere valeur calculee + maj la date debut de l''engagement renouvele'
                               else 'ancien contrat - conserve la derniere valeur calculee'
                                end
                           end                                                                                                                                                                   as info_methode_flux
                         ,case --- dans le cas d'une nouvelle restructuration - mois M+1 et suivants
                          when nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv  is not null
                           and omp.info_methode_flux is not null
                          then gr.cd_meth_ifrs9_pd_orig
						   --- dans tous les cas - mois M
                          else decode(omp.info_methode_flux, null, omp.cd_meth_ifrs9_pd_orig, omp.cd_meth_ifrs9_pd_orig_flux)
                           end                                                                                                                                                                   as cd_meth_ifrs9_pd_orig_flux
			         from (select distinct
                                  ref_uniq_ctr
                                 ,cd_entite
                                 ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                                 ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                             from tmp_gr05_granulaire
                            group
                               by ref_uniq_ctr, cd_entite) gr
                         ,eng_corp_p2                      p2
					     ,btr_operation                    bo
						 ,btr_tiers                        bt
						 ,crr_omp                          omp
			        where bo.id_tiers       = bt.id_tiers
					  and p2.id_engagement  = bo.id_operation
					  and p2.dt_arrete      = bo.dt_arrete
					  and omp.id_operation  = p2.id_engagement
					  and omp.id_tiers_calc = p2.id_tiers_calc
					  and omp.cd_conso_cpt  = p2.cd_conso_cpt
                      and p2.id_engagement  = gr.ref_uniq_ctr (+)
                      and p2.cd_conso_cpt   = gr.cd_entite    (+)
					  and bt.cd_role_tiers  = 'C'
                      and bo.cd_flag_restructuration = 'RCOM') peri_maj
			   on (peri_maj.id_engagement = omp_maj.id_operation
			  and  peri_maj.id_tiers_calc = omp_maj.id_tiers_calc
			  and  peri_maj.cd_conso_cpt  = omp_maj.cd_conso_cpt)
             when matched then
			     update
				    set omp_maj.note_flux                  = peri_maj.note_calc_fin
					   ,omp_maj.cd_flag_restructuration    = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_maj_flag_restruct       = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_flag_restruct_flux      = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_debut_eng_renouv_flux   = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_meth_ifrs9_pd_orig_flux = peri_maj.cd_meth_ifrs9_pd_orig_flux
					   ,omp_maj.info_methode_flux          = peri_maj.info_methode_flux;
			     commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    2 - si c'est un ancien contrat et il ne fait pas objet d'une RCOM
			    2.1 - code methode ifrs9 pd a l'origine = derniere valeur calculee (mois M = 31/10/2025)
			    2.2 - date de restructuration = derniere valeur calculee (null si le contrat n'a jamais ete RCOM)
			    2.3 - maj des infos dans CRR_OMP
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ OMP - anciens contrats p2 sans rcom';
            merge
			 into crr_omp omp_maj
			using (select distinct
			              p2.dt_arrete                                                                                   as dt_arrete
                         ,p2.id_engagement                                                                               as id_engagement
                         ,p2.id_tiers_calc                                                                               as id_tiers_calc
						 ,p2.cd_conso_cpt                                                                                as cd_conso_cpt
						 ,bt.note_calc_fin                                                                               as note_calc_fin
						 ,bo.cd_flag_restructuration                                                                     as cd_flag_restructuration
						 ,decode(omp.info_methode_flux, null, omp.dt_maj_flag_restruct, omp.dt_debut_eng_renouv_flux)    as dt_maj_flag_restruct
                         ,decode(omp.info_methode_flux, null, omp.cd_meth_ifrs9_pd_orig, omp.cd_meth_ifrs9_pd_orig_flux) as cd_meth_ifrs9_pd_orig
			         from eng_corp_p2   p2
					     ,btr_operation bo
						 ,btr_tiers     bt
						 ,crr_omp       omp
			        where bo.id_tiers       = bt.id_tiers
					  and p2.id_engagement  = bo.id_operation
					  and p2.dt_arrete      = bo.dt_arrete
					  and omp.id_operation  = p2.id_engagement
					  and omp.id_tiers_calc = p2.id_tiers_calc
					  and omp.cd_conso_cpt  = p2.cd_conso_cpt
					  and bt.cd_role_tiers  = 'C'
                      and nvl(bo.cd_flag_restructuration,'XX') <> 'RCOM') peri_maj
			   on (peri_maj.id_engagement = omp_maj.id_operation
			  and  peri_maj.id_tiers_calc = omp_maj.id_tiers_calc
			  and  peri_maj.cd_conso_cpt  = omp_maj.cd_conso_cpt)
             when matched then
			     update
				    set omp_maj.note_flux                  = peri_maj.note_calc_fin
					   ,omp_maj.cd_flag_restruct_flux      = peri_maj.cd_flag_restructuration
					   ,omp_maj.dt_debut_eng_renouv_flux   = peri_maj.dt_maj_flag_restruct
					   ,omp_maj.cd_meth_ifrs9_pd_orig_flux = peri_maj.cd_meth_ifrs9_pd_orig
					   ,omp_maj.info_methode_flux          = 'ancien contrat - conserve la derniere valeur calculee';
				 commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    3 - maj des donnees dans le perimetre p2 - anciens contrats
			    3.1 - code methode ifrs9 pd a l'origine
			    3.2 - date debut de l'engagement renouvele
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ P2 - cd_meth_ifrs9_pd_orig + date_deb_eng_renouv';
            merge
			 into eng_corp_p2 p2_maj
			using (select distinct
                          omp.id_operation                                          as id_operation
                         ,omp.cd_conso_cpt                                          as cd_conso_cpt
                         ,omp.id_tiers_calc                                         as id_tiers_calc
                         ,omp.cd_flag_restruct_flux                                 as cd_flag_restruct_flux
                         ,omp.dt_debut_eng_renouv_flux                              as dt_debut_eng_renouv_flux
                         ,nvl(omp.dt_debut_eng_renouv_flux, p2.date_deb_eng_renouv) as dt_debut_eng_renouvele
                         ,omp.cd_meth_ifrs9_pd_orig_flux                            as cd_meth_ifrs9_pd_orig_flux
                     from crr_omp     omp
                         ,eng_corp_p2 p2
                    where omp.id_operation  = p2.id_engagement
                      and omp.cd_conso_cpt  = p2.cd_conso_cpt
                      and omp.id_tiers_calc = p2.id_tiers_calc
                      and omp.info_methode_flux is not null) peri
			   on (p2_maj.id_engagement = peri.id_operation
			  and  p2_maj.id_tiers_calc = peri.id_tiers_calc
			  and  p2_maj.cd_conso_cpt  = peri.cd_conso_cpt)
             when matched then
			     update
				    set p2_maj.date_deb_eng_renouv   = peri.dt_debut_eng_renouvele
					   ,p2_maj.cd_meth_ifrs9_pd_orig = peri.cd_meth_ifrs9_pd_orig_flux;
				 commit;

            w_table := 'MAJ P2 - date_deb_eng_renouv si jamais RCOM';
            merge
			 into eng_corp_p2 p2_maj
			using (select distinct
                          omp.id_operation            as id_operation
                         ,omp.cd_conso_cpt            as cd_conso_cpt
                         ,omp.id_tiers_calc           as id_tiers_calc
                         ,omp.cd_flag_restructuration as cd_flag_jamais_rcom
                         ,omp.cd_flag_restruct_flux   as cd_flag_restr_flux
                     from crr_omp     omp
                         ,eng_corp_p2 p2
                    where omp.id_operation  = p2.id_engagement
                      and omp.cd_conso_cpt  = p2.cd_conso_cpt
                      and omp.id_tiers_calc = p2.id_tiers_calc
                      and omp.info_methode_flux is not null) peri
			   on (p2_maj.id_engagement = peri.id_operation
			  and  p2_maj.id_tiers_calc = peri.id_tiers_calc
			  and  p2_maj.cd_conso_cpt  = peri.cd_conso_cpt
              and  nvl(peri.cd_flag_jamais_rcom,'XX') != 'RCOM'
              and  nvl(peri.cd_flag_restr_flux,'XX')  != 'RCOM')
             when matched then
			     update
				    set p2_maj.date_deb_eng_renouv = null;
			     commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    4 - si c'est un nouveau contrat et il fait objet d'une RCOM
                4.1 - code methode ifrs9 pd a l'origine = null (mois M = 31/10/2025)
			    4.2 - code methode ifrs9 pd a l'origine = valeur recuperee du granulaire (mois M+1 = 30/11/2025)
                4.3 - determiner la date de restructuration a la date d'arrete du mois en cours (mois M)
			    4.4 - si date recuperee du granulaire = date de restructuration a la date d'arrete du mois en cours
			    4.4.1 - date debut de l'engagement renouvele = date recuperee du granulaire (mois M+1)
			    4.5 - sinon
			    4.5.1 - date debut de l'engagement renouvele = date de restructuration calculee (mois M+1)
                4.6 - maj des infos dans ENG_CORP_P2
             ET
                5 - si c'est un nouveau contrat et il ne fait pas objet d'une RCOM
                5.1 - code methode ifrs9 pd a l'origine = null (mois M = 31/10/2025)
				5.2 - code methode ifrs9 pd a l'origine = valeur recuperee du granulaire (mois M+1 = 30/11/2025)
				5.3 - determiner la date de restructuration a la date d'arrete du mois en cours
				5.4 - date debut de l'engagement renouvele = date de restructuration calculee (normalement null)
                5.5 - si null dans 5.4 alors date debut de l'engagement renouvele = valeur deja calculee dans P2
                5.6 - maj des infos dans ENG_CORP_P2
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'MAJ P2 - nouveaux contrats avec et sans rcom';
            merge
			 into eng_corp_p2 p2_maj
			using (select distinct
			              p2.dt_arrete                                                                                                                          as dt_arrete
                         ,p2.id_engagement                                                                                                                      as id_engagement
                         ,p2.id_tiers_calc                                                                                                                      as id_tiers_calc
                         ,p2.cd_conso_cpt                                                                                                                       as cd_conso_cpt
                         ,bt.note_calc_fin                                                                                                                      as note_calc_fin
                         ,bo.cd_flag_restructuration                                                                                                            as cd_flag_restructuration
                         ,case
						  when bo.cd_flag_restructuration = 'RCOM'
                           and nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                           and gr.dt_deb_eng_renouv is not null
                          then gr.dt_deb_eng_renouv
                          else decode(bo.cd_flag_restructuration, 'RCOM', nvl(bo.dt_maj_flag_restruct, p2.date_deb_eng_renouv), null)
                           end                                                                                                                                  as dt_debut_eng_renouvele
                         ,coalesce(gr.cd_meth_ifrs9_pd_orig, null)                                                                                              as cd_meth_ifrs9_pd_orig_flux
			         from (select distinct
                                  ref_uniq_ctr
                                 ,cd_entite
                                 ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                                 ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                             from tmp_gr05_granulaire
                            group
                               by ref_uniq_ctr, cd_entite) gr
                         ,eng_corp_p2                      p2
					     ,btr_operation                    bo
						 ,btr_tiers                        bt
			        where bo.id_tiers      = bt.id_tiers
					  and p2.id_engagement = bo.id_operation
					  and p2.dt_arrete     = bo.dt_arrete
                      and p2.id_engagement = gr.ref_uniq_ctr (+)
                      and p2.cd_conso_cpt  = gr.cd_entite    (+)
					  and bt.cd_role_tiers = 'C'
                      and
                      not
                   exists (select 1
                             from crr_omp omp
                            where omp.id_operation  = p2.id_engagement
		                      and omp.cd_conso_cpt  = p2.cd_conso_cpt
		                      and omp.id_tiers_calc = p2.id_tiers_calc)) peri_maj
			   on (p2_maj.id_engagement = peri_maj.id_engagement
			  and  p2_maj.id_tiers_calc = peri_maj.id_tiers_calc
			  and  p2_maj.cd_conso_cpt  = peri_maj.cd_conso_cpt)
			 when matched then
                 update
				    set p2_maj.date_deb_eng_renouv   = peri_maj.dt_debut_eng_renouvele
			           ,p2_maj.cd_meth_ifrs9_pd_orig = peri_maj.cd_meth_ifrs9_pd_orig_flux;
                 commit;

            /**
			  ----------------------------------------------------------------------------------------------------
			    6 - ajouter les nouveaux contrats dans la table CRR_OMP
			    6.1 - contrats avec RCOM
			    6.2 - contrats sans RCOM
			  ----------------------------------------------------------------------------------------------------
			**/
            w_table := 'INSERT OMP - nouveaux contrats p2';
            insert
			  into crr_omp
            select distinct
			       p2.id_engagement                                                                                                                      as id_operation
                  ,p2.id_tiers_calc                                                                                                                      as id_tiers_calc
		          ,p2.cd_conso_cpt                                                                                                                       as cd_conso_cpt
                  ,p2.dt_arrete                                                                                                                          as dt_calc_rcom
		          ,bt.id_tiers                                                                                                                           as id_tiers
		          ,bt.id_entr                                                                                                                            as id_entr
		          ,bt.num_siren                                                                                                                          as num_siren
		          ,'P2'                                                                                                                                  as objet
		          ,p2.dt_debut_eng                                                                                                                       as dt_debut_eng
		          ,bo.cd_flag_restructuration                                                                                                            as cd_flag_restructuration
		          ,case
                   when bo.cd_flag_restructuration = 'RCOM'
                    and nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                    and gr.dt_deb_eng_renouv is not null
                   then gr.dt_deb_eng_renouv
                   else decode(bo.cd_flag_restructuration, 'RCOM', bo.dt_maj_flag_restruct, null)
                    end                                                                                                                                  as dt_maj_flag_restruct
		          ,null                                                                                                                                  as dt_calc_sgmt
		          ,bt.cd_segment_casa                                                                                                                    as cd_segment_casa
		          ,bt.cd_type_sgmt                                                                                                                       as cd_type_sgmt
		          ,bt.cd_pays_risque                                                                                                                     as cd_pays_risque
		          ,null                                                                                                                                  as dt_calc_note
		          ,bt.note_calc_fin                                                                                                                      as note_origine
		          ,null                                                                                                                                  as note_calc
                  ,null                                                                                                                                  as cd_meth_ifrs9_pd_orig
		          ,null                                                                                                                                  as info_methode
		          ,bt.note_calc_fin                                                                                                                      as note_flux
		          ,bo.cd_flag_restructuration                                                                                                            as cd_flag_restruct_flux
                  ,case
                   when bo.cd_flag_restructuration = 'RCOM'
                    and nvl(bo.dt_maj_flag_restruct, to_date('01/01/1999','dd/mm/yyyy')) = nvl(gr.dt_deb_eng_renouv, to_date('01/01/1999','dd/mm/yyyy'))
                    and gr.dt_deb_eng_renouv is not null
                   then gr.dt_deb_eng_renouv
                   else decode(bo.cd_flag_restructuration, 'RCOM', bo.dt_maj_flag_restruct, null)
                    end                                                                                                                                  as dt_debut_eng_renouv_flux
		          ,coalesce(gr.cd_meth_ifrs9_pd_orig, null)                                                                                              as cd_meth_ifrs9_pd_orig_flux
                  ,case
                   when gr.cd_meth_ifrs9_pd_orig is not null
                   then 'nouveau contrat - valeur recuperee du granulaire'
                   else 'nouveau contrat - valeur renseignee a vide'
                    end                                                                                                                                  as info_methode_flux
              from (select distinct
                           ref_uniq_ctr
                          ,cd_entite
                          ,min(cd_pd_tiers_principal) keep (dense_rank first order by id_contrat) cd_meth_ifrs9_pd_orig
                          ,min(dt_deb_eng_renouv)     keep (dense_rank first order by id_contrat) dt_deb_eng_renouv
                      from tmp_gr05_granulaire
                     group
                        by ref_uniq_ctr, cd_entite) gr
                  ,eng_corp_p2                      p2
                  ,btr_operation                    bo
                  ,btr_tiers                        bt
             where bo.id_tiers      = bt.id_tiers
               and p2.id_engagement = bo.id_operation
               and p2.dt_arrete     = bo.dt_arrete
               and p2.id_engagement = gr.ref_uniq_ctr (+)
               and p2.cd_conso_cpt  = gr.cd_entite    (+)
               and bt.cd_role_tiers = 'C'
               and
               not
            exists (select 1
                      from crr_omp omp
                     where omp.id_operation  = p2.id_engagement
                       and omp.cd_conso_cpt  = p2.cd_conso_cpt
                       and omp.id_tiers_calc = p2.id_tiers_calc);
            commit;
        -- =======================================================================================================
        --  FIN :: projet OMP - SIRL-195
        -- =======================================================================================================
		EXCEPTION
			WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('Proc p_alim_eng_encours_corporate table:' || W_TABLE || ' -MESS:'||SQLERRM);
                pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_eng_encours_corporate table:' || W_TABLE,50072);
	  END p_alim_eng_encours_corporate ;
	  ------------------------------------------------------
	  -- nom : procedure p_alim_surete_pers               --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       SURETE_PERS                                --
	  -- auteur : A. Guilmart, le 08/09/2008              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
	  -- NRN - 23/03/2010 : plus de filtre sur le systeme
	  --       de gestion pour constituer l'id_autorisation
	  --       et l'id_ligne_det; pour KSP, on ne tient pas compte
	  --       du top_eng mais du statut de l'operation
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------

	  PROCEDURE p_alim_surete_M1 IS
        W_TABLE VARCHAR2(20);

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);

		execute immediate 'TRUNCATE TABLE SURETE_M1';
        W_TABLE := 'SURETE_M1(1)';
		INSERT INTO SURETE_M1 (
		  dt_arrete,
		  cd_conso_cpt,
		  id_tiers_calc,
		  id_central_tiers,
		  id_autorisation,
		  ID_LIGNE_DET,
		  id_engagement,
		  ID_SURETE,
		  CD_NATOP_CPT,
		  CD_TRR,
		  id_tiers_calc_gar,
		  id_central_tiers_gar,
		  cd_etendue_surete,
		  cd_arrosage,
		  cd_nature_surete,
		  MNT_INITIAL,
		  POURCENT_INITIAL,
		  VAL_GARANTIE,
		  CD_DEVISE,
		  DT_DEB_EFFET,
		  DT_FIN_EFFET,
		  eligibilite_surete_pers,
		  cd_methodo_valorisation,
		  CD_PERIODICITE,
		  CD_PAYS_RECOURS,
		  ANNEE_EVT_MIM,
		  ANNEE_CONSTRUIT_BIEN,
		  CD_METHO_VAL_BIEN,
		  CD_QUAL_MONTAGE,
		  CD_QUAL_ACTIF,
		  CD_RANG_SURETE,
		  CD_SORTIE_RISQ_PAYS,
		  CD_BOURSE_COTATION,
		  TOP_COT_BAL_2,
		  CD_INDICE_TITRE,
		  CD_NATIO_EMET,
		  CD_PER_LIQUID,
		  CD_PER_LIQUID2,
		  CD_BORRO_BASE,
		  CD_LIEU_DEPOT,
		  A_EXTRAIRE,
		  --08/01/2018 - CDS ATOS (EMM) - Sprint 3 - US 26
		  CD_NUTS,
		  --Fin EMM
		  --12/09/2018 - CDS ATOS (EMM) -  US 489
		  DT_REV_MNT
		  --Fin EMM
		  -- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
		  ,APPLI_SOURCE
		  ,CD_PAYS_LOCAL_GARANT
		  -- FIN LFD
		  -- 06/02/19 - CDS ATOS (LFD) - CRRV4.2 US 716
		  ,EVT_DECL_GAR
		  -- FIN LFD
		  ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,SYS_GEST_SRC -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		  ,METHOD_BALE_GARANT -- KLX-GOMESHU - BALE4 - 06/02/2024 - M1 13.13
		  ,METHOD_BALE_GARANT_CALC_SIMUL -- KLX-GOMESHU - BALE4 - 06/02/2024 - M1 13.14
		  )
		SELECT  DISTINCT sp.DT_ARRETE,
			s.CD_CONSO_CPT_CRRV3,
			CASE WHEN ta.id_entr IS NULL THEN 'ENT'||ta.id_tiers ELSE 'EN'||ta.id_entr END id_tiers_calc, -- identifiant du tiers client
			ta.ident_siris,
			'F1' || NVL(nu.NUM_DEC_BIS, o.ID_OPERATION)   ID_AUTORISATION,  -- evol 02/2016 NVL2(NU.CD_SYS_INT, 'F1' || nu.NUM_DEC_BIS, 'F1P' || o.ID_OPERATION)   ID_AUTORISATION,
			'F2' || NVL2(NU.CD_SYS_INT, nu.NUM_DEC_BIS, o.ID_OPERATION)               ID_LIGNE_DET, -- EVOL 02/2016 'F2' || NVL2(NU.CD_SYS_INT, nu.NUM_DEC_BIS, sp.ID_SURETE)               ID_LIGNE_DET,
			sp.ID_OPERATION                                                        ID_ENGAGEMENT,
			sp.ID_SURETE                                                           ID_SURETE,
			--'NAT81'                                          CD_NATURE_OPE,
		  tg.cd_natop_cpt,
			CASE WHEN tg.ID_FAMILLE_GARANTIE IN ('PARI', 'GSYN') THEN decode (tg.FLAG_PREM_QUALITE, 'O', 'Y', 'N') ELSE 'N' END CD_TRR,
			CASE WHEN t2.id_entr IS NULL THEN 'ENT'||t2.id_tiers ELSE 'EN'||t2.id_entr END id_tiers_garant, -- identifiant du tiers garant
			t2.ident_siris,
			'S' cd_etende_surete,
			decode(substr(sp.ID_TYPE_GARANTIE_CASA,1,3),'SEC','M',NULL) cd_arrosage,
			sp.ID_TYPE_GARANTIE_CASA cd_nature_surete,
			CASE WHEN sp.MNT_GARANTIE IS NULL THEN O.MNT_EXPO_POTENT_HT * (sp.QUOTE_PART_GARANT/100)
			   ELSE sp.MNT_GARANTIE
			END MNT_INITIAL,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('GUA', 'CDE') THEN sp.QUOTE_PART_GARANT END POURCENT_INITIAL,
			CASE WHEN sp.MNT_GARANTIE IS NULL THEN O.MNT_EXPO_POTENT_HT * (sp.QUOTE_PART_GARANT/100)
			   ELSE sp.MNT_GARANTIE
			END VAL_GARANTIE,
			CASE WHEN nvl(sp.MNT_GARANTIE,0)!=0 THEN o.CD_DEVISE
			   WHEN nvl(sp.QUOTE_PART_GARANT,0)!=0 THEN o.CD_DEVISE
			   ELSE NULL
			END cd_devise,

			--DEBUT: KLxRisqLeasing (BAL) - M63359: Anomalie M1 7.1 Date debut d effet
			case when sp.dt_deb_valid_garant > sp.dt_arrete
				then sp.dt_arrete
				else sp.dt_deb_valid_garant
			end dt_deb_valid_garant,
			--FIN: KLxRisqLeasing (BAL) - M63359: Anomalie M1 7.1 Date debut d effet

			--nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')),
			-- 17/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
			-- CASE WHEN nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) > sp.DT_DEB_VALID_GARANT THEN nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) ELSE o.dt_fin_ope END,
			--CASE WHEN nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) > sp.DT_DEB_VALID_GARANT THEN nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) ELSE nvl(o.dt_fin_ope,to_date('31/12/2099','dd/mm/yyyy')) END,
			--30/11/2021 - KLx - CRRV4.3 US 264
			CASE WHEN nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) >= sp.DT_ARRETE THEN nvl(sp.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) ELSE nvl(o.dt_fin_ope,to_date('31/12/2099','dd/mm/yyyy')) END,
			-- FIN LFD
			sp.ELIGIBILITE_SUR_PERS,
			mv.CD_METHODE_VALORIS_BIEN,
			'30',
			decode(ta.CD_PAYS_NATIONALITE,NULL,'FR','99','FR',ta.CD_PAYS_NATIONALITE),
			 CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('REE', 'TAS') THEN To_char(o.DT_MEL, 'YYYY') ELSE '' END,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('REE', 'TAS') THEN To_char(o.DT_MEL, 'YYYY') ELSE '' END,
			'',--CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('REE', 'TAS') THEN RS_ORIG_VALO_ACT_CBI.CD_METHODO_VALORISATION ELSE '' END,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('REE', 'TAS') THEN '2' ELSE '' END,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('REE', 'TAS') THEN '3' ELSE '' END,
			--06/11/18 CDS Atos (EMM) US 549
			CASE WHEN sp.id_type_garantie ='CAUM' THEN '2' ELSE '1' END cd_rang_surete,
			--Fin EMM
			'0' cd_sortie_risq_pays,
			decode(substr(sp.ID_TYPE_GARANTIE_CASA,1,5),'SEC01','02',NULL) cd_bourse_cotation,
			decode(substr(sp.ID_TYPE_GARANTIE_CASA,1,5),'SEC01','Y',NULL) top_cot_bal_2,
			decode(substr(sp.ID_TYPE_GARANTIE_CASA,1,5),'SEC01','1',NULL) cd_indic_titre,
			'  ',
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('SEC','CAS','COL') THEN 'N' ELSE ' ' END,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('SEC','CAS','COL') THEN 'N' ELSE ' ' END,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('IAS', 'REE', 'TAS') THEN 'Y' ELSE '' END,
			CASE WHEN substr(sp.ID_TYPE_GARANTIE_CASA,1,3) IN ('SEC','CAS') THEN CASE WHEN sp.ID_TYPE_GARANTIE in ('AUSY') THEN '1' WHEN sp.id_type_garantie in ('CLSY','CASY') THEN '2' else '0' END  ELSE null END,
			'O' a_extraire,
			-- 04/04/2018 CDS Atos (JMP) ANACREDIT US26 utilsation TIE_TIERS_C1_C5.CD_PAYS_RESIDENCE pour le code NUTS
			--PACK_UTILITAIRE.F_GET_CODE_NUTS(ta.cd_postal,ta.CD_PAYS_RISQUE)
			  PACK_UTILITAIRE.F_GET_CODE_NUTS(tie.cd_postal,tie.CD_PAYS_RESIDENCE),
			-- Fin (JMP)
			--12/09/2018 - CDS ATOS (EMM) -  US 489
			sp.DT_ARRETE
			--Fin EMM
			-- 15/01/18 - CDS ATOS (LFD) - CRRV4.2 US 651
			,'C_BTR' -- APPLI_SOURCE
			, CASE  WHEN substr(nvl(sp.ID_TYPE_GARANTIE_CASA,'   '),-7,3) in ('GUA', 'CDE')
			THEN 'FR' ELSE '' END -- CD_PAYS_LOCAL_GARANT
			-- FIN LFD
			-- 06/02/19 - CDS ATOS (LFD) - CRRV4.2 US 716
		  ,'04'
		  -- FIN LFD
		  ,'GAAC01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,sp.CD_SYS_INT SYS_GEST_SRC  -- KLx (GHU) - 03/12/2021 - US265 - Leasing - CRR Corporate - Score 7 'Systeme de gestion source'
		  ,'STD' METHOD_BALE_GARANT -- KLX-GOMESHU - BALE4 - 06/02/2024 - M1 13.13
		  ,'STD' METHOD_BALE_GARANT_CALC_SIMUL -- KLX-GOMESHU - BALE4 - 06/02/2024 - M1 13.14
		FROM BTR_SURETE_PERS               sp,
		   BTR_OPERATION                 o,
		   RS_SOCIETE_JURIDIQUE          s,
		   RS_TYPE_GARANTIE              tg,
		   BTR_TIERS                     ta, -- pour le tiers client
		   BTR_TIERS                     t2, -- pour le tiers garant
		   RS_CORRES_SGMT_BAL_METH_VALOR mv,
		   AUT_COR_OPE_NUM_DEC_BIS       nu
		   , TIE_TIERS_C1_C5 tie
		WHERE sp.CD_SYS_INT     = o.CD_SYS_INT
		AND   sp.ID_OPERATION   = o.ID_OPERATION
		AND   o.CD_SOC_JURI     = s.CD_SOC_JURI
		AND   o.ID_TIERS        = ta.ID_TIERS -- pour le tiers client
		AND   Sp.ID_TIERS_Garant  = t2.ID_TIERS -- pour le tiers garant
		AND   ta.CD_SEGMENT_CAL = mv.CD_SEGMENT_CAL
		and   tg.id_type_garantie = sp.id_type_garantie
		AND   o.CD_SYS_INT      = nu.CD_SYS_INT   (+)
		AND   o.ID_OPERATION    = nu.ID_OPERATION (+)
		AND tie.id_tiers = ta.id_tiers
		AND   ta.CD_TYPE_SGMT       = 'CORP'
		AND   s.CD_CONSO_CPT_CRRV3 != '99999'
		--02/08/2018 CDS ATOS (EMM) Mantis 43331
		AND sp.ELIGIBILITE_SUR_PERS not like 'N'
		--Fin EMM
		;

		COMMIT;

		 -------------------------------------------------------
		 --EVOL SYNDICATION LOT FEVRIER 2016
		 -------------------------------------------------------
        W_TABLE := 'SURETE_M1 (2)';
		 Update SURETE_M1 M1
		Set M1.A_extraire='N'
		Where Exists (select 1
			FROM BTR_SURETE_PERS sp, RS_TYPE_GARANTIE tg
			where  tg.id_type_garantie = sp.id_type_garantie
			And   tg.id_type_garantie in ('AUSY', 'CASY', 'CLSY')
			And  M1.cd_nature_surete = tg.id_type_garantie_casa
			and sp.id_operation=M1.id_engagement
			 )
		 ;
		 COMMIT;

		 -- 16/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 651
         W_TABLE := 'SURETE_M1(3)';
		 update SURETE_M1
		 set VAL_GARANTIE = 0
		 where VAL_GARANTIE <= 0 or VAL_GARANTIE is null;
		 -- FIN LFD

		 -- 16/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 651
         W_TABLE := 'SURETE_M1(4)';
		 update SURETE_M1
		 set VAL_GARANTIE = 1
		 where VAL_GARANTIE > 0 and VAL_GARANTIE < 1;
		 -- FIN LFD

		 -- 16/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 651
         W_TABLE := 'SURETE_M1(5)';
		 update SURETE_M1
		 set MNT_INITIAL = 1
		 where MNT_INITIAL > 0 and MNT_INITIAL < 1;
		 -- FIN LFD

		 -- 16/01/2019 - CDS ATOS (LFD) - CRRV4.2 US 651
        W_TABLE := 'SURETE_M1(6)';
		 update SURETE_M1
		 set MNT_INITIAL = 0
		 where MNT_INITIAL is NULL;
		 -- FIN LFD

		 -- 08/05/2024 Bï¿½le4 M1 6.8 Mantis Recette 12731
		 W_TABLE := 'SURETE_M1(7)';
		 update SURETE_M1 M1
		 set M1.MNT_INIT_SURETE_SING_CTRT = M1.MNT_INITIAL
		 where M1.MNT_INIT_SURETE_SING_CTRT is NULL;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc p_alim_surete_pers table:' || W_TABLE || ' -MESS:'||SQLERRM);
              pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_surete_pers table:'||W_TABLE,50072);
	  END p_alim_surete_M1 ;


	  ------------------------------------------------------
	  -- nom : procedure p_alim_his_provisions            --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       ENG_IMPAYES                                --
	  -- auteur : A. Guilmart, le 08/09/2008              --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_alim_his_provisions IS
      W_TABLE VARCHAR2(30);

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);

        W_TABLE := 'HIS_PROVISIONS_DECOTES_P9(1)';
		delete HIS_PROVISIONS_DECOTES_P9 where dt_arrete = (select max(dt_arrete) from BTR_OPERATION); -- execute immediate 'truncate table HIS_PROVISIONS_DECOTES_P9';
		commit;

      W_TABLE := 'HIS_PROVISIONS_DECOTES_P9(2)';
	  insert into HIS_PROVISIONS_DECOTES_P9 (
		  dt_arrete,
		  cd_conso_cpt,
		  id_tiers,
		  id_tiers_calc,
		  id_central_tiers,
		  id_autorisation,
		  ID_LIGNE_DET    ,
		  id_engagement,
		  MNT_PROV_SOLD_LOY_K,
		  MNT_PROV_SOLD_AUT,
		  MNT_PROV_CRD ,
		  MNT_PROV_SOLD_LOY_I,
		  MNT_PROV_SOLD_IRE,
		  MNT_REPRISE_SOLD_LOY_K,
		  MNT_REPRISE_SOLD_AUT,
		  MNT_REPRISE_CRD,
		  MNT_REPRISE_SOLD_LOY_I,
		  MNT_REPRISE_SOLD_IRE)
	  select  o.dt_arrete,
		  s.CD_CONSO_CPT_CRRV3,
		  t.id_tiers,
		  CASE WHEN id_entr IS NULL THEN 'ENT'||T.id_tiers ELSE 'EN'||T.id_entr END id_tiers_calc,
		  T.IDENT_SIRIS,
		  CASE WHEN NU.CD_SYS_INT is not null then 'F1'|| nvl(NU.NUM_DEC_BIS, O.id_operation) END  ID_AUTORISATION,
		  CASE WHEN NU.CD_SYS_INT is not null then 'F2'|| nvl(NU.NUM_DEC_BIS, O.id_operation) END  ID_LIGNE_DET,
		  o.id_operation,
		  MNT_PROV_SOLD_LOY_K,
		  MNT_PROV_SOLD_AUT,
		  MNT_PROV_CRD,
		  MNT_PROV_SOLD_LOY_I,
		  MNT_PROV_SOLD_IRE,
		  MNT_REPRISE_SOLD_LOY_K,
		  MNT_REPRISE_SOLD_AUT,
		  MNT_REPRISE_CRD,
		  MNT_REPRISE_SOLD_LOY_I,
		  MNT_REPRISE_SOLD_IRE
	  FROM    BTR_OPERATION                  o,
		  RS_SOCIETE_JURIDIQUE           s,
		  btr_TIERS                      T,
		  AUT_COR_OPE_NUM_DEC_BIS        nu
	  WHERE       o.CD_SOC_JURI       = s.CD_SOC_JURI
		  AND o.ID_TIERS          = T.ID_TIERS
		  AND o.CD_SYS_INT        = nu.CD_SYS_INT   (+)
		  AND o.ID_OPERATION      = nu.ID_OPERATION (+)
		  and T.CD_ROLE_TIERS     = 'C'
	   --       AND T.CD_TYPE_SGMT        = 'CORP'
		  AND s.CD_CONSO_CPT_CRRV3 != '99999';

		COMMIT;

        W_TABLE := 'HIS_PROVISIONS_DECOTES_P9(3)';
		Update his_provisions_decotes_p9   P1
			 SET P1.Id_Autorisation = 'F1' || P1.Id_Engagement,
			   P1.Id_Ligne_Det = 'F2' || P1.Id_Engagement
		Where P1.id_autorisation is null
		;
		Commit;

	  EXCEPTION
		WHEN OTHERS THEN
			 ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc p_alim_his_provisions table:' || W_TABLE || ' -MESS:'||SQLERRM);
              pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_his_provisions table:'||W_TABLE,50072);
	  END p_alim_his_provisions;

	------------------------------------------------------
	-- Nom : procedure p_alim_provisions_decotes_p9     --
	-- But : Alimentation de la table cible envoi CRRV3 --
	--       ENG_IMPAYES                                --
	-- Auteur : A. Guilmart, le 08/09/2008              --
	-- Entree : /                                       --
	-- Retour : /                                       --
    -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
    --   ajout information de la table en cas d'erreurs --
    ------------------------------------------------------
	PROCEDURE p_alim_provisions_decotes_p9 IS
    	W_TABLE VARCHAR2(100);
	BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
        W_TABLE := 'PROVISIONS_DECOTES_P9 (1)';
		execute immediate 'truncate table PROVISIONS_DECOTES_P9';

		---- DEBUT :: M67006 - spec 2.2
		-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
		-- 02/04/2019 - CDS ATOS (LFD) - US 774
		---- FIN :: M67006 - spec 2.2

	  	---- lignes du bucket 3 - CRD
      	W_TABLE := 'PROVISIONS_DECOTES_P9 (2)';
	  	insert
		  into PROVISIONS_DECOTES_P9 (
		    DT_ARRETE
		  , CD_CONSO_CPT
		  , ID_TIERS_CALC
		  , ID_CENTRAL_TIERS
		  , ID_AUTORISATION
		  , ID_LIGNE_DET
		  , ID_ENGAGEMENT
		  , CD_PROVISION
		  , CD_NAT_DEPRE
		  , CD_PERIM_PROV
		  , MNT_PROVISION_CRD
		  , MNT_PROVISION_TRIM_CRD
		  , CD_DEVISE
		  , CD_PCCO_CRD
		  , A_EXTRAIRE
		  , ORIGINE_CALCUL_PROVISION
		  , APPLI_SOURCE
		  , ID_PROVISION
		  , CD_TYPE_PROD_BANCAIRE -- CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire
		  , SYSTEME_SOURCE    --- P9 1.20  :: M67006 - spec 2.2
		  , CD_DEVISE_LIASSE  --- P9 50.1  :: M67006 - spec 2.2
		  , PCCO_DEPRECIATION --- P9 50.10 :: M67006 - spec 2.2
		  , MNT_DEPRECIATION) --- P9 50.11 :: M67006 - spec 2.2
	  	select
			o.dt_arrete DT_ARRETE
		  , s.CD_CONSO_CPT_CRRV3 CD_CONSO_CPT
		  , CASE
		    WHEN id_entr IS NULL
			THEN 'ENT' || T.id_tiers
			ELSE 'EN'  || T.id_entr
			 END ID_TIERS_CALC
		  , T.IDENT_SIRIS ID_CENTRAL_TIERS
		  , CASE
		    WHEN NU.CD_SYS_INT is not null
			THEN 'F1' || nvl(NU.NUM_DEC_BIS, O.id_operation)
			 END ID_AUTORISATION
		  , CASE
		    WHEN NU.CD_SYS_INT is not null
			THEN 'F2' || nvl(NU.NUM_DEC_BIS, O.id_operation)
			 END  ID_LIGNE_DET
		  , o.id_operation ID_ENGAGEMENT
		  , 'O' CD_PROVISION
		  , 'S' CD_NAT_DEPRE
		  , 'P' CD_PERIM_PROV
		  , nvl(o.MNT_PROV_CRD, 0) MNT_PROVISION_CRD
		  , CASE
		    WHEN nvl(h.MNT_PROV_CRD, 0) < 0
			THEN 0
			ELSE nvl(h.MNT_PROV_CRD, 0)
			 END MNT_PROVISION_TRIM_CRD
		  , o.CD_DEVISE CD_DEVISE
		  , pcec.CD_PCEC_CRD_PROV CD_PCCO_CRD
		  , 'O' A_EXTRAIRE
		  , '2' ORIGINE_CALCUL_PROVISION
		  , 'C_BTR' APPLI_SOURCE
		  , 'P' || o.id_operation || '_C' ID_PROVISION
		  , 'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire
		  , 'C_BTR' SYSTEME_SOURCE                  --- P9 1.20  :: M67006 - spec 2.2
		  , o.CD_DEVISE CD_DEVISE_LIASSE            --- P9 50.1  :: M67006 - spec 2.2
		  , pcec.CD_PCEC_CRD_PROV PCCO_DEPRECIATION --- P9 50.10 :: M67006 - spec 2.2
		  , nvl(o.MNT_PROV_CRD, 0) MNT_DEPRECIATION --- P9 50.11 :: M67006 - spec 2.2
	  	from BTR_OPERATION               o,
		  RS_SOCIETE_JURIDIQUE           s,
		  btr_TIERS                      T,
		  HIS_PROVISIONS_DECOTES_P9      h,
		  AUT_COR_OPE_NUM_DEC_BIS        nu,
		  (SELECT id_operation,cd_sys_int,id_tiers,CD_PCEC_CRD_PROV,cd_pcec_icne,CD_PCEC_K_A_I_PROV FROM -- 33s
			   (SELECT o.CD_SYS_INT,o.ID_OPERATION,
				CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END cd_statut_act,  --43378
				so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
				FROM btr_operation o, --/*btr_surete_reelle sr,
				rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				 (SELECT cd_sys_int,id_operation,
				min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
				FROM btr_surete_reelle
				GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
				WHERE sr.ID_OPERATION = o.ID_OPERATION
				AND sr.CD_SYS_INT  = o.CD_SYS_INT
				AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
				AND o.ID_TIERS = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				AND so.CD_PHASE = 'APCDE'
				AND o.CD_PRODUIT NOT IN ('CRED','CREN')
				UNION
				SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
				WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
				AND o.ID_TIERS = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				AND so.CD_PHASE = 'APCDE'
				AND o.CD_PRODUIT IN ('CRED','CREN')
		  and not exists (SELECT 1
			  FROM
				 rs_statut_ope so,
				 btr_tiers T,
				 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				(SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
				 FROM btr_surete_reelle
				 GROUP BY cd_sys_int, id_operation
				) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
			  WHERE sr.ID_OPERATION  = o.ID_OPERATION
				AND sr.CD_SYS_INT    = o.CD_SYS_INT
				AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
				AND o.ID_TIERS       = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
				AND so.CD_PHASE      = 'APCDE'
				--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
				AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
		  ) perim,
			   rs_corres_pcec pc
			 WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
			 AND perim.CD_PHASE = pc.CD_PHASE
			 AND perim.CD_PRODUIT = pc.CD_PRODUIT
			 AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
			 AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
			UNION
			 SELECT id_operation,cd_sys_int,o.id_tiers,CD_PCEC_CRD_PROV,cd_pcec_icne,CD_PCEC_K_A_I_PROV
			 FROM btr_operation o,
														  btr_tiers t,
														  RS_CORRES_SGMT_BAL_TYPE_CLI rsc,
				  rs_statut_ope so, rs_corres_pcec pc
			 WHERE o.cd_statut_ope = so.CD_STATUT_OPE
													  and t.id_tiers=o.id_tiers
													  AND   T.cd_segment_cal=rsc.cd_segment_cal
													  and rsc.cd_type_cli=pc.cd_type_cli
			 AND so.CD_PHASE = 'CDE'
			 AND pc.CD_PHASE = so.CD_PHASE) pcec
	  WHERE   o.CD_SOC_JURI               = s.CD_SOC_JURI
		  AND o.ID_TIERS              = T.ID_TIERS
		  AND o.CD_SYS_INT            = nu.CD_SYS_INT   (+)
		  AND o.ID_OPERATION          = nu.ID_OPERATION (+)
		  AND o.ID_TIERS              = h.ID_TIERS (+)
		  AND o.ID_OPERATION          = h.ID_ENGAGEMENT(+)
		  AND   o.ID_OPERATION = pcec.id_operation (+)    -- AGU 23/01/2009
		  AND   o.CD_SYS_INT = pcec.cd_sys_int (+)        -- AGU 23/01/2009
		  AND   o.ID_TIERS = pcec.id_tiers (+)            -- AGU 23/01/2009
		  --AND trunc(o.dt_arrete, 'Q') = h.DT_ARRETE(+)
		AND case when to_char(o.dt_arrete,'MM') in ('01','02','03') then add_months(last_day(to_date('01/12/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY')),-12)
		  when to_char(o.dt_arrete,'MM') in ('04','05','06') then last_day(to_date('01/03/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY'))
		  when to_char(o.dt_arrete,'MM') in ('07','08','09') then last_day(to_date('01/06/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY'))
		  when to_char(o.dt_arrete,'MM') in ('10','11','12') then last_day(to_date('01/09/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY'))
		  end  = h.dt_arrete (+)
		  AND T.CD_TYPE_SGMT          = 'CORP'
		  and T.CD_ROLE_TIERS         = 'C' -- en fait le tiers peut etre client ou garant comme la provision est dur l'affaire on pourrait multiplier la prov par deux
		  AND s.CD_CONSO_CPT_CRRV3   != '99999';
		COMMIT;

	  	---- lignes du bucket 3 - SOLDE
      	W_TABLE := 'PROVISIONS_DECOTES_P9 (3)';
	  	insert
		  into PROVISIONS_DECOTES_P9 (
		    DT_ARRETE
		  , CD_CONSO_CPT
		  , ID_TIERS_CALC
		  , ID_CENTRAL_TIERS
		  , ID_AUTORISATION
		  , ID_LIGNE_DET
		  , ID_ENGAGEMENT
		  , CD_PROVISION
		  , CD_NAT_DEPRE
		  , CD_PERIM_PROV
		  , MNT_PROVISION_SOLD
		  , MNT_PROVISION_TRIM_SOLD
		  , CD_DEVISE
		  , CD_PCCO_SOLD
		  , A_EXTRAIRE
		  , ORIGINE_CALCUL_PROVISION
		  , APPLI_SOURCE
		  , ID_PROVISION
		  , CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire
		  , SYSTEME_SOURCE    --- P9 1.20  :: M67006 - spec 2.2
		  , CD_DEVISE_LIASSE  --- P9 50.1  :: M67006 - spec 2.2
		  , PCCO_DEPRECIATION --- P9 50.10 :: M67006 - spec 2.2
		  , MNT_DEPRECIATION) --- P9 50.11 :: M67006 - spec 2.2
	  	select
		    o.dt_arrete DT_ARRETE
		  , s.CD_CONSO_CPT_CRRV3 CD_CONSO_CPT
		  , CASE
		    WHEN id_entr IS NULL
			THEN 'ENT' || T.id_tiers
			ELSE 'EN'  || T.id_entr
			 END ID_TIERS_CALC
		  , T.IDENT_SIRIS ID_CENTRAL_TIERS
		  , CASE
		    WHEN NU.CD_SYS_INT is not null
			THEN 'F1' || nvl(NU.NUM_DEC_BIS, O.id_operation)
			 END ID_AUTORISATION
		  , CASE
		    WHEN NU.CD_SYS_INT is not null
			THEN 'F2' || nvl(NU.NUM_DEC_BIS, O.id_operation)
			 END ID_LIGNE_DET
		  , o.id_operation ID_ENGAGEMENT
		  , 'O' CD_PROVISION
		  , 'S' CD_NAT_DEPRE
		  , 'P' CD_PERIM_PROV
		  , (nvl(o.MNT_PROV_SOLD_LOY_K, 0) +
		     nvl(o.MNT_PROV_SOLD_AUT, 0)   +
			 nvl(o.MNT_PROV_SOLD_LOY_I, 0)) MNT_PROVISION_SOLD
		  , CASE
		    WHEN (nvl(h.MNT_PROV_SOLD_LOY_K, 0) +
			      nvl(h.MNT_PROV_SOLD_AUT, 0)   +
				  nvl(h.MNT_PROV_SOLD_LOY_I, 0)) < 0
		    THEN 0
		    ELSE (nvl(h.MNT_PROV_SOLD_LOY_K, 0) +
			      nvl(h.MNT_PROV_SOLD_AUT, 0)   +
				  nvl(h.MNT_PROV_SOLD_LOY_I, 0))
			 END MNT_PROVISION_TRIM_SOLD
		  , o.CD_DEVISE CD_DEVISE
		  , pcec.CD_PCEC_K_A_I_PROV CD_PCCO_SOLD
		  , 'O' A_EXTRAIRE
		  , '2' ORIGINE_CALCUL_PROVISION
		  , 'C_BTR' APPLI_SOURCE
		  , 'P' || O.ID_OPERATION || '_S' ID_PROVISION
		  , 'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire
		  , 'C_BTR' SYSTEME_SOURCE                  --- P9 1.20  :: M67006 - spec 2.2
		  , o.CD_DEVISE CD_DEVISE_LIASSE            --- P9 50.1  :: M67006 - spec 2.2
		  , pcec.CD_PCEC_CRD_PROV PCCO_DEPRECIATION --- P9 50.10 :: M67006 - spec 2.2
		  , nvl(o.MNT_PROV_CRD, 0) MNT_DEPRECIATION --- P9 50.11 :: M67006 - spec 2.2
	  	from BTR_OPERATION               o,
		  RS_SOCIETE_JURIDIQUE           s,
		  btr_TIERS                      T,
		  HIS_PROVISIONS_DECOTES_P9      h,
		  AUT_COR_OPE_NUM_DEC_BIS        nu,
		  (SELECT id_operation,cd_sys_int,id_tiers,CD_PCEC_CRD_PROV,cd_pcec_icne,CD_PCEC_K_A_I_PROV FROM -- 33s
			   (SELECT o.CD_SYS_INT,o.ID_OPERATION,
				CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END cd_statut_act,  --43378
				so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
				FROM btr_operation o, --/*btr_surete_reelle sr,
				rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				 (SELECT cd_sys_int,id_operation,
				min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
				FROM btr_surete_reelle
				GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
				WHERE sr.ID_OPERATION = o.ID_OPERATION
				AND sr.CD_SYS_INT  = o.CD_SYS_INT
				AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
				AND o.ID_TIERS = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				AND so.CD_PHASE = 'APCDE'
				AND o.CD_PRODUIT NOT IN ('CRED','CREN')
				UNION
				SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
				WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
				AND o.ID_TIERS = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				AND so.CD_PHASE = 'APCDE'
				AND o.CD_PRODUIT IN ('CRED','CREN')
		  and not exists (SELECT 1
			  FROM
				 rs_statut_ope so,
				 btr_tiers T,
				 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				(SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
				 FROM btr_surete_reelle
				 GROUP BY cd_sys_int, id_operation
				) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
			  WHERE sr.ID_OPERATION  = o.ID_OPERATION
				AND sr.CD_SYS_INT    = o.CD_SYS_INT
				AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
				AND o.ID_TIERS       = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
				AND so.CD_PHASE      = 'APCDE'
				--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
				AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
		  ) perim,
			   rs_corres_pcec pc
			 WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
			 AND perim.CD_PHASE = pc.CD_PHASE
			 AND perim.CD_PRODUIT = pc.CD_PRODUIT
			 AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
			 AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
			UNION
			 SELECT id_operation,cd_sys_int,o.id_tiers,CD_PCEC_CRD_PROV,cd_pcec_icne,CD_PCEC_K_A_I_PROV
			 FROM btr_operation o,
														  btr_tiers t,
														  RS_CORRES_SGMT_BAL_TYPE_CLI rsc,
				  rs_statut_ope so, rs_corres_pcec pc
			 WHERE o.cd_statut_ope = so.CD_STATUT_OPE
													  and t.id_tiers=o.id_tiers
													  AND   T.cd_segment_cal=rsc.cd_segment_cal
													  and rsc.cd_type_cli=pc.cd_type_cli
			 AND so.CD_PHASE = 'CDE'
			 AND pc.CD_PHASE = so.CD_PHASE) pcec
	  WHERE   o.CD_SOC_JURI               = s.CD_SOC_JURI
		  AND o.ID_TIERS              = T.ID_TIERS
		  AND o.CD_SYS_INT            = nu.CD_SYS_INT   (+)
		  AND o.ID_OPERATION          = nu.ID_OPERATION (+)
		  AND o.ID_TIERS              = h.ID_TIERS (+)
		  AND o.ID_OPERATION          = h.ID_ENGAGEMENT(+)
		  AND   o.ID_OPERATION = pcec.id_operation (+)    -- AGU 23/01/2009
		  AND   o.CD_SYS_INT = pcec.cd_sys_int (+)        -- AGU 23/01/2009
		  AND   o.ID_TIERS = pcec.id_tiers (+)            -- AGU 23/01/2009
		  --AND trunc(o.dt_arrete, 'Q') = h.DT_ARRETE(+)
		AND case when to_char(o.dt_arrete,'MM') in ('01','02','03') then add_months(last_day(to_date('01/12/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY')),-12)
		  when to_char(o.dt_arrete,'MM') in ('04','05','06') then last_day(to_date('01/03/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY'))
		  when to_char(o.dt_arrete,'MM') in ('07','08','09') then last_day(to_date('01/06/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY'))
		  when to_char(o.dt_arrete,'MM') in ('10','11','12') then last_day(to_date('01/09/'||to_char(o.dt_arrete,'YYYY'),'DD/MM/YYYY'))
		  end  = h.dt_arrete (+)
		  AND T.CD_TYPE_SGMT          = 'CORP'
		  and T.CD_ROLE_TIERS         = 'C' -- en fait le tiers peut etre client ou garant comme la provision est dur l'affaire on pourrait multiplier la prov par deux
		  AND s.CD_CONSO_CPT_CRRV3   != '99999';
		COMMIT;
	  -- FIN LFD

      	W_TABLE := 'PROVISIONS_DECOTES_P9 (4)';
      	Update provisions_decotes_p9   P1
		   SET P1.Id_Autorisation = 'F1' || P1.Id_Engagement,
			   P1.Id_Ligne_Det    = 'F2' || P1.Id_Engagement
		 Where P1.id_autorisation is null;
		Commit;

		--DEBUT :: 19/12/2022 - KLx_Risques(BAL) :: M64483 - P9 alimentation du systeme de gestion source
		w_table := 'Table: provisions_decotes_p9 - maj APPLI_SOURCE';
		update provisions_decotes_p9
		   set appli_source   = 'C_BTR'
		      ,systeme_source = 'C_BTR' --- M67006 - spec 2.2
		where nvl(flag_hn, 'N') = 'N';
		commit;
		--FIN :: 19/12/2022 - KLx_Risques(BAL) :: M64483 - P9 alimentation du systeme de gestion source
	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Proc p_alim_provisions_decotes_p9 table:' || W_TABLE || ' -MESS:'||SQLERRM);
			pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'p_alim_provisions_decotes_p9 table :' || W_TABLE,50072);
	END p_alim_provisions_decotes_p9;

------------------------------------------------------
-- nom : procedure p_alim_encours_retail_p5         --
-- but : Alimentation de la table cible envoi CRRV3 --
--       ENG_ENCOURS_RETAIL_DET et                  --
--       ENG_ENCOURS_RETAIL_AGREG                   --
-- auteur : A. Guilmart, le 08/09/2008              --
-- entr?e : /                                       --
-- retour : /                                       --
-- Modification:                                    --
--   AGU - 15/03/2010 : tiers RETA agregat - ext des--
--           chps ID_ENGAGEMENT et CD_TYPE_RISQUE de--
--           la table rs_corres_conso_typ_risq_ret  --
--                                                  --
--   NRN - 02/11/2010 : HL 44035 le type de risque
--      pour les tiers retail doit d?river du segment balois
--      et non plus du produit financier
------------------------------------------------------
-- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
--   ajout information de la table en cas d'erreurs --
------------------------------------------------------
PROCEDURE p_alim_encours_retail_p5 IS
	l_position    varchar2(20);
	W_TABLE       varchar2(30);

	--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
	pInseeCommune varchar2(5);
	Nb_Lignes     number;
	--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune

BEGIN
	DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
	l_position := 'anal stat tie_tiers';
	DBMS_STATS.GATHER_TABLE_STATS('DDREX','TIE_TIERS_C1_C5',Estimate_Percent => NULL, CASCADE => TRUE);

	--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29
	 -- purge de la table d'historisation pour l'arrete en cours
	W_TABLE := 'HIS_FORB_BTR_OPERATION';
	DELETE FROM HIS_FORB_BTR_OPERATION WHERE DT_ARRETE = (SELECT DISTINCT(DT_ARRETE) FROM BTR_OPERATION);
	COMMIT;
	 --Alimentation de la table d'historisation des forbearance de BTR_OPERATION
	  INSERT INTO HIS_FORB_BTR_OPERATION (ID_OPERATION, CD_SYS_INT, DT_ARRETE, CD_AQR, DT_AQR, CD_AQR_FORCE, DT_AQR_FORCE, DT_FIN_VALID_AQR)
	  SELECT ID_OPERATION, CD_SYS_INT, DT_ARRETE, CD_AQR, DT_AQR, CD_AQR_FORCE, DT_AQR_FORCE, DT_FIN_VALID_AQR
	  FROM BTR_OPERATION;
	COMMIT;
	-- Fin EMM

	-- table de d?tail concernant les encours des tiers RETAIL
	l_position := 'tiers RETA detail';

	execute immediate 'TRUNCATE TABLE ENG_RETAIL_DETAIL_P5';
	execute immediate 'TRUNCATE TABLE ENG_RETAIL_AGREG_P5';

	W_TABLE := 'ENG_RETAIL_DETAIL_P5 (1)';
	INSERT INTO ENG_RETAIL_DETAIL_P5 (
		DT_ARRETE,
		CD_CONSO_CPT,
		ID_TIERS,
		ID_TIERS_CALC,
		ID_CENTRAL_TIERS,
		ID_ENGAGEMENT,
		ID_AUTORISATION,
		CD_METHODO_BALE2,
		CD_TRT_MOTEUR,
		CD_NATURE_OPE,
		CD_NATURE_PNU,
		CD_TYPE_RISQUE,
		CD_PORTEFEUILLE_BALE2,
		CD_LIGNE_METIER,
		CD_OBJET_FIN,
		CD_TYPE_TAUX,
		CD_USAGE_BIEN_IMM,
		CD_RESPECT_COND,
		MNT_ENCOURS,
		MNT_AUTORISATION,
		MNT_CONTRAT,
		CD_DEVISE_CONTRAT,
		CD_STATUT_OPE_DT_SOLDE,
		CD_DEVISE_ENCOURS,
		CD_STATUT_TIERS,
		MNT_LOY_RD_CRD,
		MNT_LOY_RD_SOLD,
		MNT_VTR,
		MNT_VR,
		CD_DEVISE_VR,
		CD_ACHAT_FIN_LOC,
		CD_DEVISE_VTR,
		MATURITE_CALC,
		CD_PCEC_CRD,
		CD_PCEC_SOLD_K_A,
		CD_PCEC_SOLD_I,
		MNT_ENC_ARR_PAIE,
		TOP_ENG_DOUTEUX,
		CD_IMP_PRUDENT,
		MNT_PROVISION,
		MNT_ENC_RISQ_PROPRE,
		POURC_NIVEAU_PROVISION,
		MNT_GAR_ACTIF,
		MNT_GAR_PREM_QUAL,
		TX_LGD_PREDICTIF,
		TX_LGD_PREDICTIF_LOCAL,
		CD_NIVEAU_PROVISION,
		CD_COUV_PROVISION,
		CD_NEW_DEFAUT,
		A_EXTRAIRE,
		MNT_PNU,
		CD_PCEC_PNU,
		--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 279
		DATE_PREM_ACT_FORB,
		DATE_SORT_EFF_FORB,
		DATE_ENTR_PER_PURG,
		DATE_SORT_PER_PURG,
		DATE_ENTR_PER_PROB,
		DATE_SORT_PER_PROB,
		DATE_THEO_FIN_FORB,
		--23/11/18 CDS Atos (EMM) US 579
		IND_NIV_RISQ,
		--Fin EMM
		--13/02/2019 - CDS Atos (GBD) US673 deb ->
		BUCKET_IFRS9,
		MNT_MTM,
		CD_DEV_MNT_MTM,
		--13/02/2019 - CDS Atos (GBD) US673 <- fin
		-- 12/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
		MNT_LOY_AVEC_ARR,
		DEV_LOY_AVEC_ARR,
		MNT_LOY_HORS_ARR,
		DEV_LOY_HORS_ARR,
		MNT_INT_AVEC_ARR,
		DEV_INT_AVEC_ARR,
		MNT_INT_HORS_ARR,
		DEV_INT_HORS_ARR,
		-- fin CPD
		CD_TYPE_PROD_BANCAIRE, --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
		MNT_CAPITAL_HORS_ARR,
		DEV_CAPITAL_HORS_ARR,
		-- FIN LFD

		--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		CD_POSTAL_IMM,
		CD_PAYS_IMM,
		LIB_VILLE_IMM,
		CD_COMMUNE_INSEE
		--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		)
		SELECT  DISTINCT o.DT_ARRETE,
			s.CD_CONSO_CPT_CRRV3  CD_CONSO_CPT,
			o.ID_TIERS,
			T.ID_TIERS_CALC,
			T.ID_CENTRAL_TIERS,
			o.ID_OPERATION ID_ENGAGEMENT,
			substr(T.ID_TIERS_CALC,4,11) || substr(s.CD_CONSO_CPT_CRRV3,3,10) ||
			-- CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
			-- WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
			-- WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
			-- WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END
			-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
			CASE WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')					  THEN 'NA012'
			 	 WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt not in ('DTX', 'DTCO')				  THEN 'NA011'
			 	 WHEN ta.cd_segment_cal not in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')				  THEN 'NA022'
			 	 WHEN ta.cd_segment_cal not in ('06','07') and NVL(Ta.cd_categ_cpt,'SAIN') not in ('DTX', 'DTCO') THEN 'NA021' -- M68356
			END ||
			--'NAT07'|| -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO - retire pour faire de la place pour le bucket
			CASE WHEN Ta.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END||
			pf.CD_TYP_RISQ_RET || o.cd_type_taux || case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
			-- CASE WHEN ((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			-- - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
			-- / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end > 0 THEN '1'
			-- WHEN ((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			-- - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
			-- / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end > 20 THEN '2'
			-- ELSE '0' END as ID_AUTORISATION ,  -- optimisation V21S17 + lisible
			CASE  --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				WHEN
					( -- Quand (Somme(MNT_PROV) - Somme(MNT_REPRISE) * 100 ) / 1 ) > 0 alors '1'
					  (   NVL(o.MNT_PROV_SOLD_LOY_K,0)
					    + NVL(o.MNT_PROV_CRD,0)
					    + NVL(o.MNT_PROV_SOLD_LOY_I,0)
					    + NVL(o.MNT_PROV_SOLD_IRE,0)
					    + NVL(o.MNT_PROV_SOLD_AUT,0)
					    + NVL(o.MNT_PROV_ICNE,0)
					  )
					  -
					  (  NVL(o.MNT_REPRISE_SOLD_LOY_K,0)
					   + NVL(o.MNT_REPRISE_CRD,0)
					   + NVL(o.MNT_REPRISE_SOLD_LOY_I,0)
					   + NVL(o.MNT_REPRISE_SOLD_IRE,0)
					   + NVL(o.MNT_REPRISE_SOLD_AUT,0)
					   + NVL(o.MNT_REPRISE_ICNE,0)
					   )
					  *100
					) / CASE
						  WHEN NVL(o.MNT_ENC_RISQ_PROPRE,1) > 1
						  THEN 1
						END
        				> 0 THEN '1'
				WHEN
					( --Quand (Somme(MNT_PROV) - Somme(MNT_REPRISE) * 100 ) / 1 ) > 20 alors '2'
					  (
					      NVL(o.MNT_PROV_SOLD_LOY_K,0)
					    + NVL(o.MNT_PROV_CRD,0)
					    + NVL(o.MNT_PROV_SOLD_LOY_I,0)
					    + NVL(o.MNT_PROV_SOLD_IRE,0)
					    + NVL(o.MNT_PROV_SOLD_AUT,0)
					    + NVL(o.MNT_PROV_ICNE,0)
					  )
					    -
					  (   NVL(o.MNT_REPRISE_SOLD_LOY_K,0)
					    + NVL(o.MNT_REPRISE_CRD,0)
					    + NVL(o.MNT_REPRISE_SOLD_LOY_I,0)
					    + NVL(o.MNT_REPRISE_SOLD_IRE,0)
					    + NVL(o.MNT_REPRISE_SOLD_AUT,0)
					    + NVL(o.MNT_REPRISE_ICNE,0)
					  )
					  *100
					) /
					CASE
					  WHEN NVL(o.MNT_ENC_RISQ_PROPRE,1) > 1
					  THEN 1
					END
					> 20 THEN '2'
					-- Quand Delta(Sommes) = 0 ou  MNT_ENC_RISQ_PROPRE = 0, null, negatif alors '0'
				ELSE '0'
			END ||

			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			---- DEBUT :: M67006 - spec 2.1.3
			CASE
			WHEN (ta.CD_CATEG_CPT = 'DTX' or ta.CD_CATEG_CPT = 'DTCO')
			THEN 'B3'
			ELSE nvl(ifrs.bucket_ifrs9_new,'B1')
			 END as ID_AUTORISATION,
			---- FIN :: M67006 - spec 2.1.3

			-- optimisation V21S17 + lisible
			methodo.CD_METHOD cd_methodo_bale2, --mantis re7 5520
			--DECODE(s.CD_CONSO_CPT_CRRV3, '00472', '07', '01') CD_TRT_MOTEUR, --'07' CD_TRT_MOTEUR,
			NVL(methodo.trt_moteur, '01') as CD_TRT_MOTEUR,-- M56405 change code moteur de 07 Ã¿Â¿Â½ 01
			--CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
				--  WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
				--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
				--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021'  END
		  	-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
		  	CASE WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')         			  THEN 'NA012'
				 WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt not in ('DTX', 'DTCO')      			  THEN 'NA011'
				 WHEN ta.cd_segment_cal not in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')      			  THEN 'NA022'
				 WHEN ta.cd_segment_cal not in ('06','07') and NVL(Ta.cd_categ_cpt,'SAIN') not in ('DTX', 'DTCO') THEN 'NA021' --Recette M68356
				 END cd_nature_ope,
		  	'NAT07' CD_NATURE_PNU,
			-- CASE WHEN T.cd_segment_cal = '01' THEN pf.CD_TYPE_RISQUE_PART ELSE pf.CD_TYPE_RISQUE_AUTRES  END type_risque,
			pf.CD_TYP_RISQ_RET type_risque,
			-- 17/03/2021 - CDS ATOS (LFD) - Mantis 56406
			--'900', --DECODE(methodo.CD_METHOD, 'NON IRB', ' ', '900') CD_PORTEFEUILLE_BALE2, mantis re7 5520
			CASE WHEN pf.CD_TYP_RISQ_RET = 'PRI105' AND s.CD_CONSO_CPT_CRRV3 = '00472' THEN '014' ELSE '900' END CD_PORTEFEUILLE_BALE2,
			-- FIN LFD
			'MLE00' cd_ligne_metier,
			decode(o.cd_PRODUIT, 'CBI', '04', '97') CD_objet_fin,
			o.cd_type_taux,
			decode(o.cd_PRODUIT, 'CBI', '2', '0') CD_USAGE_BIEN_IMM,
			'Y' CD_RESPECT_COND, --decode(o.cd_PRODUIT, 'CBI', 'Y', ' ') CD_RESPECT_COND,
			case when nvl(hb.mnt_iec,0) <> 0 then hb.MNT_IEC -- Mantis 60744 - VDC - Changement alimentation du P5, le mnt_encours doit Ãªtre Ã©gale au mnt_iec quand celui-ci est diffÃ©rent de 0
				else o.ENC_FINANC_BRUT
			END mnt_encours,    --IEC ?
			CASE 	WHEN nvl(hb.mnt_iec,0) <> 0 then o.MNT_BRUT_ORIGINE -- Mantis 60744 - VDC - Changement alimentation du P5, le mnt_autorisation doit Ãªtre Ã©gale au MNT_BRUT_ORIGINE quand MNT_IEC est diffÃ©rent de 0
					WHEN nvl(o.MNT_EXPO_POTENT_HT,0)>= nvl(o.ENC_FINANC_BRUT,0) THEN (nvl(o.MNT_EXPO_POTENT_HT,0) - nvl(hb.mnt_iec,0))
					WHEN nvl(o.ENC_FINANC_BRUT,0)>= nvl(o.MNT_EXPO_POTENT_HT,0) THEN (nvl(o.ENC_FINANC_BRUT,0) - nvl(hb.mnt_iec,0))
				END  mnt_autorisation,
			CASE 	WHEN nvl(hb.mnt_iec,0) <> 0 then o.MNT_BRUT_ORIGINE -- Mantis 60744 - VDC - Changement alimentation du P5, le mnt_autorisation doit Ãªtre Ã©gale au MNT_BRUT_ORIGINE quand MNT_IEC est diffÃ©rent de 0
					WHEN nvl(o.MNT_EXPO_POTENT_HT,0)>= nvl(o.ENC_FINANC_BRUT,0) THEN (nvl(o.MNT_EXPO_POTENT_HT,0) - nvl(hb.mnt_iec,0))
					WHEN nvl(o.ENC_FINANC_BRUT,0)>= nvl(o.MNT_EXPO_POTENT_HT,0) THEN (nvl(o.ENC_FINANC_BRUT,0) - nvl(hb.mnt_iec,0))
			END mnt_contrat,
			nvl2(o.MNT_EXPO_POTENT_HT,o.CD_DEVISE,NULL) cd_devise_contrat,
			o.CD_STATUT_OPE_DT_SOLDE,
			DECODE(o.ENC_FINANC_BRUT,0,NULL,o.CD_DEVISE) cd_devise_encours,
			'' CD_STATUT_TIERS,
			-- 29/01/2021 - CDS ATOS (LFD) - Mantis 55571
			--o.crd_brut_ht ,
			o.crd_brut_ht + nvl(MNT_SOLDE_HT_EXIGIB_K_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_I_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_AUTRE_T,0) MNT_LOY_RD_CRD,
			-- FIN LFD
			nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0) ,
			--M65476
			--CASE WHEN substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE502','PRI105') THEN sr.mnt_vtr_pdr ELSE null END,
			CASE WHEN substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE502','PRI105') AND s.CD_CONSO_CPT_CRRV3='00472' THEN
                COALESCE( SR.MNT_VV_ACT, SR.MNT_ACQ_HT_ACT * 0.7 , SR.mnt_revise)
            END MNT_VTR,
			--M65476
			mnt_vr,
			nvl2(o.MNT_VR,o.CD_DEVISE,NULL) cd_devise_vr,
			-- 		 --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
			--  --DECODE(substr(pf.CD_TYP_RISQ_ret,1,6), 'TRE502', '1', 'PRI105', '1', '2') CD_ACHAT_FIN_LOC,
			--   CASE
			--   WHEN (substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE502', 'PRI105'))
			--   AND  s.cd_conso_cpt_crrv3 = '00472'
			-- 	--WHEN substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE501', 'TRE502', 'PRI105') -- M56278 : nouvelle regle Gestion du CD_ACHAT_FIN_LOC
			--   THEN '1'
			--   --18/03/19 CDS ATOS (EMM) Mantis 47094
			--   --ELSE CASE
			--   --WHEN  substr(pf.CD_TYP_RISQ_CORP,1,6) in ('PRI105', 'TRE501')
			--   --    THEN '2'
			--   --   ELSE '0'
			-- 	 ELSE '2'
			--   --     END
			--   END  CD_ACHAT_FIN_LOC,
			--   --Fin EMM
			-- --Fin
      		'2' as CD_ACHAT_FIN_LOC,   -- M56278 (note 194976): nouvelle regle
			nvl2(COALESCE( SR.MNT_VV_ACT, SR.MNT_ACQ_HT_ACT, SR.mnt_revise),o.CD_DEVISE,NULL) cd_devise_vtr, --M65476
			o.maturite_calc,
			pcec.cd_pcec_crd cd_pcec_crd,
			pcec.cd_pcec_k_a CD_PCEC_SOLD_K_A,
			pcec.CD_PCEC_I CD_PCEC_SOLD_I,
			--12/02/2019 - CDS ATOS (SQN) - Correctif : scorrer les MNT_SOLDE_HT_EXIGIB_I n?gatifs
			--nvl(o.MNT_SOLDE_HT_EXIGIB_K,0)+nvl(o.MNT_SOLDE_HT_EXIGIB_AUTRE,0)+ nvl(o.MNT_SOLDE_HT_EXIGIB_I,0) MNT_ENC_ARR_PAIE,
			CASE WHEN o.MNT_SOLDE_HT_EXIGIB_I >= 0 THEN nvl(o.MNT_SOLDE_HT_EXIGIB_K,0)+nvl(o.MNT_SOLDE_HT_EXIGIB_AUTRE,0)+ nvl(o.MNT_SOLDE_HT_EXIGIB_I,0)
				 ELSE nvl(o.MNT_SOLDE_HT_EXIGIB_K,0)+nvl(o.MNT_SOLDE_HT_EXIGIB_AUTRE,0)
			END MNT_ENC_ARR_PAIE,
			--SQN
			decode (ta.CD_CATEG_CPT, 'DTX', 'Y', 'DTCO', 'Y', 'N') TOP_ENG_DOUTEUX,
	  		--MODIF LY 30/11/2015            case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end    CD_IMP_PRUDENT,
			CASE WHEN Ta.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END  CD_IMP_PRUDENT,
			(nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))  MNT_PROVISION,
			o.MNT_ENC_RISQ_PROPRE,
			((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
			   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end  POURC_NIVEAU_PROVISION,
			sr.mnt_vtr_pdr  MNT_GAR_ACTIF,
			o.ENC_FINANC_BRUT-o.MNT_ENC_RISQ_PROPRE  MNT_GAR_PREM_QUAL,
			o.TX_LGD_PREDICTIF,
			o.TX_LGD_PREDICTIF_LOCAL,
			null  CD_NIVEAU_PROVISION,
			null,
			case when ta.CD_CATEG_CPT in ( 'DTX', 'DTCO')
			   then (case when ta.dt_chg_categ_cpt between trunc(o.dt_arrete, 'Q') and o.dt_arrete then 'Y' else 'N' end)
			   else 'N' end     CD_NEW_DEFAUT,
			'O',  --a extraire
			CASE	WHEN nvl(hb.MNT_IEC,0) <> 0 THEN nvl(hb.MNT_ENGMT_FINANCMT_HB,0)  -- Mantis 60744 - VDC - Changement alimentation du P5, le MNT_PNU doit Ãªtre Ã©gale au MNT_ENGMT_FINANCMT_HB quand MNT_IEC est diffÃ©rent de 0
					WHEN nvl(o.MNT_EXPO_POTENT_HT,0) - nvl(o.ENC_FINANC_BRUT,0) - nvl(hb.mnt_iec,0) >0 THEN nvl(o.MNT_EXPO_POTENT_HT,0) - nvl(o.ENC_FINANC_BRUT,0) - nvl(hb.mnt_iec,0)
			  	 	ELSE 0
			END MNT_PNU,
			pcec_pnu.cd_pcec_crd,
			--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 279
			--ef.dt_aqr,            --DATE_PREM_ACT_FORB
			-- M58209 : remplace par
			--- DATE_PREM_ACT_FORB alimentee si TOP_RESTRUCTURATION <> null et <> AR
			CASE  WHEN O.CD_AQR = 'C4'                                                                                                 THEN null      --'AR'
			      WHEN O.CD_AQR = 'C3A' AND Ta.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR THEN ef.dt_aqr --'RC'
			      WHEN O.CD_AQR = 'C2'  AND Ta.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF' M70812
			      --WHEN O.CD_AQR = 'C2'   OR Ta.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF'
			      ELSE NULL
			END AS DATE_PREM_ACT_FORB,
			--sf.dt_fin_valid_aqr,      --DATE_SORT_EFF_FORB
			--12/02/19 CDS ATOS (EMM) US 497
			o.DATE_SORT_EFF_FORB,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR END DATE_ENTR_PER_PURG,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12) END DATE_SORT_PER_PURG,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12)
				else CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR end
			END DATE_ENTR_PER_PROB,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,36)
				else CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,24) end
			END DATE_SORT_PER_PROB,
			-- DATE_THEO_FIN_FORB  M58209 : regle remplace par
			CASE WHEN O.CD_AQR = 'C4'                                                                                                 THEN null      --'AR'
			 	 WHEN o.CD_AQR = 'C3A' AND Ta.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR then ADD_MONTHS(o.DT_AQR,24)
			     WHEN o.CD_AQR = 'C2'   OR Ta.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         then ADD_MONTHS(o.DT_AQR,36)
			     ELSE NULL
			END AS DATE_THEO_FIN_FORB,
			--23/11/18 CDS Atos (EMM) US 579
			CASE  -- 08/06/2022 - KLx Risque (VDC) - Risque Leasing 2022 US 11  - Juste ï¿½a car insertion pour les codes natures PNU, DETAIL_P5
				WHEN ( s.CD_CONSO_CPT_CRRV3 = '00370' AND pf.CD_TYP_RISQ_RET ='PRI105' ) OR pf.CD_TYP_RISQ_RET = 'TRE504' THEN 1
				ELSE 2 END IND_NIV_RISQ,
			--Fin EMM

			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			-- 14/06/2021 - CDS ATOS (LFD) - US 43 MCO
			---- DEBUT :: M67006 - spec 2.1.3
			CASE
			WHEN (ta.CD_CATEG_CPT = 'DTX' or ta.CD_CATEG_CPT = 'DTCO')
			THEN 'B3'
			ELSE nvl(ifrs.bucket_ifrs9_new,'B1')
			 END  BUCKET_IFRS9,
			---- FIN :: M67006 - spec 2.1.3

			null MNT_MTM,
			null CD_DEV_MNT_MTM,
			-- 12/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
			0 MNT_LOY_AVEC_ARR,
			'EUR'DEV_LOY_AVEC_ARR ,
			0 MNT_LOY_HORS_ARR,
			'EUR' DEV_LOY_HORS_ARR ,
			CASE WHEN (decode (ta.CD_CATEG_CPT, 'DTX', 'Y', 'DTCO', 'Y', 'N')) = 'Y' then
						CASE WHEN o.MNT_SOLDE_HT_EXIGIB_I is null then 0 else o.MNT_SOLDE_HT_EXIGIB_I END
			ELSE 0 END,
			'EUR' DEV_INT_AVEC_ARR,
			0,
			'EUR' DEV_INT_HORS_ARR
			-- fin CPD
			,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
			,CASE WHEN (pf.CD_TYP_RISQ_RET like 'TRE2%' and pf.CD_TYP_RISQ_RET <> 'TRE201') or pf.CD_TYP_RISQ_RET like 'TRE3%' or pf.CD_TYP_RISQ_RET like 'TRE4%'
							or pf.CD_TYP_RISQ_RET in ('PRI102', 'PRI103', 'PRI104' ,'PRI109')
					THEN
						NVL(o.MNT_SOLDE_HT_EXIGIB_K,0)
				ELSE 0
			END MNT_CAPITAL_HORS_ARR
			,'EUR' DEV_CAPITAL_HORS_ARR
			-- FIN LFD
			--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		    ,case
			   when (decode(o.cd_PRODUIT, 'CBI', '2', '0') <> '0' and sr.cd_pays = 'FR')
			     then sr.cd_postal
			     else null
			 end as CD_POSTAL_IMM
			,case
			   when (decode(o.cd_PRODUIT, 'CBI', '2', '0') <> '0' and sr.cd_pays = 'FR')
			     then sr.cd_pays
				 else null
		     end as CD_PAYS_IMM
			,case
			   when (decode(o.cd_PRODUIT, 'CBI', '2', '0') <> '0' and sr.cd_pays = 'FR')
			     then sr.ville
				 else null
			 end  as LIB_VILLE_IMM
			,null as CD_COMMUNE_INSEE
		    --FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		FROM BTR_OPERATION o,
			btr_hors_bilan hb,
			RS_SOCIETE_JURIDIQUE s,
			TIE_TIERS_C1_C5 T,
			BTR_TIERS ta,
			RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			( 	SELECT BTR_SURETE_PERS.cd_sys_int, BTR_SURETE_PERS.id_operation, SUM(MNT_GARANTIE) mnt_garantie
				FROM BTR_SURETE_PERS
				GROUP BY BTR_SURETE_PERS.cd_sys_int,BTR_SURETE_PERS.id_operation
			) sp,
		   	(	SELECT
			   	  --M65476 added Max(column) and commented the group by
				  --DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
				   MAX(br.cd_postal) cd_postal
				  ,MAX(br.cd_pays) cd_pays
				  ,MAX(br.ville) ville
				  --FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
				  ,br.cd_sys_int
				  ,br.id_operation
				  ,SUM(br.MNT_VTR_PDR) mnt_vtr_pdr
				  ,SUM(br.MNT_VV_ACT) MNT_VV_ACT -- M65476
				  ,SUM(br.MNT_ACQ_HT_ACT) MNT_ACQ_HT_ACT -- M65476
				  ,SUM(br.mnt_revise) mnt_revise -- M65476
				FROM BTR_SURETE_REELLE br
				GROUP BY
				  --DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
				  -- br.cd_postal
				  --,br.cd_pays
				  --,br.ville
				  --FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
				  --,
				  br.cd_sys_int, br.id_operation
			) sr,
			(	SELECT id_operation,cd_sys_int,id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I FROM -- 33s
					(	SELECT o.CD_SYS_INT,o.ID_OPERATION,
								CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE nvl(sr.CD_STATUT_ACT,'NA') END cd_statut_act,  --43378
								so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,nvl(T.CD_CATEG_CPT,T.CD_STATUT_RISQ) CD_CATEG_CPT,o.CD_PRODUIT -- 466728
						FROM btr_operation o, --/*btr_surete_reelle sr,
							rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
					 		( SELECT cd_sys_int,id_operation,
										min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
							FROM btr_surete_reelle
							GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
						WHERE o.ID_OPERATION = sr.ID_OPERATION (+)
							AND o.CD_SYS_INT = sr.CD_SYS_INT  (+)
							AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
							AND o.ID_TIERS = T.ID_TIERS
							AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							AND so.CD_PHASE = 'APCDE'
							AND o.CD_PRODUIT NOT IN ('CRED','CREN')
						UNION ALL -- optimisation V21S17
						SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
						FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
						WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
							AND o.ID_TIERS = T.ID_TIERS
							AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							AND so.CD_PHASE = 'APCDE'
							AND o.CD_PRODUIT IN ('CRED','CREN')
							and not exists ( SELECT 1
											FROM
												rs_statut_ope so,
												btr_tiers T,
												RS_CORRES_SGMT_BAL_TYPE_CLI rs,
												( SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
												 FROM btr_surete_reelle
												 GROUP BY cd_sys_int, id_operation
												) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
											WHERE sr.ID_OPERATION  = o.ID_OPERATION
												AND sr.CD_SYS_INT    = o.CD_SYS_INT
												AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
												AND o.ID_TIERS       = T.ID_TIERS
												AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
												--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
												AND so.CD_PHASE      = 'APCDE'
												--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
												AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV')
											)
					) perim,
			   		rs_corres_pcec pc
				WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
				AND perim.CD_PHASE = pc.CD_PHASE
				AND perim.CD_PRODUIT = pc.CD_PRODUIT
				AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
				AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
			) pcec, -- AGU 23/01/2009
			( SELECT CD_SOC_JURI, CD_SEGMENT, cd_method, trt_moteur   --	 M56405 change code moteur de 07 Ã¿Â¿Â½ 01  ; ajout trt_mmoteur
			  FROM RS_METHO_BALE_SOC_SEG ) methodo,
			( 	SELECT o.id_operation,o.cd_sys_int,o.id_tiers,rsc.cd_pcec_crd
				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs, rs_corres_pcec rsc
				WHERE rsc.nato_crd='NAT07'
					AND so.cd_statut_ope=o.cd_statut_ope
					and o.id_tiers=t.id_tiers
					and t.cd_role_tiers='C'
					and t.cd_segment_cal=rs.cd_segment_cal
					and rs.cd_type_cli=rsc.cd_type_cli
					and so.cd_phase=rsc.cd_phase
			) pcec_pnu,
			--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 319
			(	select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
						cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
				from his_forb_btr_operation hisb
							  where hisb.cd_aqr IN ('C2','C3A')
							  and hisb.dt_arrete between hisb.dt_aqr and hisb.dt_fin_valid_aqr
							  and hisb.dt_aqr = (select min(hist.dt_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation and hist.cd_aqr IN ('C2','C3A'))
			) ef
			/*,
			(select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
							  cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
							  from his_forb_btr_operation hisb
							  where hisb.cd_aqr IN ('C2','C3A')
							  and dt_fin_valid_aqr = add_months(dt_arrete, -1)
							  and hisb.dt_fin_valid_aqr = (select max(hist.dt_fin_valid_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation)
							  )sf*/
			--Fin EMM
			,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			-- 14/06/2021 - CDS ATOS (LFD) - US 43 MCO
			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			---- remplacer annexe_ifrs par tmp_gr05_granulaire
			---- DEBUT :: M67006 - spec 2.1.3
			, (select gr05.ref_uniq_ctr
					, gr05.cd_entite
					, max(case
						  when nvl(gr05.bucket_ecl,'Stage1') = 'Stage1'
						  then 'B1'
						  else 'B2'
						   end) bucket_ifrs9_new
		     	 from tmp_gr05_granulaire gr05
                group
				   by gr05.ref_uniq_ctr, gr05.cd_entite) ifrs
			---- FIN :: M67006 - spec 2.1.3
		WHERE o.CD_SOC_JURI = s.CD_SOC_JURI
			AND   o.ID_TIERS = T.ID_TIERS
			AND   o.ID_TIERS = ta.ID_TIERS
			AND   o.CD_SYS_INT = hb.cd_sys_int (+)
			AND   o.ID_OPERATION = hb.id_operation (+)
			AND   o.CD_PRODUIT    = pf.CD_PRODUIT
			--    AND   s.CD_CONSO_CPT_CRRV3 = pf.CD_CONSO_CPT
			AND   o.CD_SYS_INT = sp.CD_SYS_INT (+)
			AND   o.ID_OPERATION = sp.ID_OPERATION (+)
			AND   o.CD_SYS_INT = sr.CD_SYS_INT (+)
			AND   o.ID_OPERATION = sr.ID_OPERATION (+)
			AND   o.ID_OPERATION = pcec.id_operation (+)    -- AGU 23/01/2009
			AND   o.CD_SYS_INT = pcec.cd_sys_int (+)        -- AGU 23/01/2009
			AND   o.ID_TIERS = pcec.id_tiers (+)            -- AGU 23/01/2009
			AND   o.ID_OPERATION = pcec_pnu.id_operation (+)
			AND   o.CD_SYS_INT = pcec_pnu.cd_sys_int (+)
			AND   o.ID_TIERS = pcec_pnu.id_tiers (+)
			AND   s.CD_CONSO_CPT_CRRV3 != '99999'
			AND   T.CD_TYPE_TIE = 'RETA'
			And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
			And s.cd_soc_juri     = methodo.cd_soc_juri
			--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 319
			and o.id_operation = ef.id_operation(+)
			and o.cd_sys_int   = ef.cd_sys_int(+)
			--and o.id_operation = sf.id_operation(+)
			--and o.cd_sys_int   = sf.cd_sys_int(+)
			--Fin EMM
			--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
			AND pf.CD_TYP_RISQ_RET = PARAM.VAL_PARAM_1 --ENG_RETAIL_P5.CD_TYPE_RISQUE = PARAM_MULTIDIM_GENERIQUE.VAL_PARAM_1
			--FIN MNE

			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			-- 14/06/2021 - CDS ATOS (LFD) - US 43 MCO
			---- DEBUT :: M67006 - spec 2.1.3
			and o.id_operation       = ifrs.ref_uniq_ctr (+)
            and s.cd_conso_cpt_crrv3 = ifrs.cd_entite    (+);
			---- FIN :: M67006 - spec 2.1.3
		COMMIT;

	-- totof IEC pour les IEC on d?clare deux fois une fois le HB fait juste au dessus avec la reference DE en repartissant les garanties
	-- une autre fois les IEC avec la r?f?rence SIG c'est celle qui vient
	--     Dossier DE avec :
	--    Mnt_risque = 0
	--    Mnt_exposition = 0
	--    Mnt_expo_potent = Exposition potentielle ? IEC
	--    Mnt_EAD = EAD ? IEC
	--  Affaire SIG
	--    Mnt_risque = IEC
	--    Mnt_exposition = IEC
	--    Mnt_expo_potent = IEC
	--    Mnt_EAD = IEC

    W_TABLE := 'ENG_RETAIL_DETAIL_P5 (2)';
	INSERT INTO ENG_RETAIL_DETAIL_P5 (
		DT_ARRETE,
		CD_CONSO_CPT,
		ID_TIERS,
		ID_TIERS_CALC,
		ID_CENTRAL_TIERS,
		ID_ENGAGEMENT,
		ID_AUTORISATION,
		CD_METHODO_BALE2,
		CD_TRT_MOTEUR,
		CD_NATURE_OPE,
		CD_NATURE_PNU,
		CD_TYPE_RISQUE,
		CD_PORTEFEUILLE_BALE2,
		CD_LIGNE_METIER,
		CD_OBJET_FIN,
		CD_TYPE_TAUX,
		CD_USAGE_BIEN_IMM,
		CD_RESPECT_COND,
		MNT_ENCOURS,
		MNT_AUTORISATION,
		MNT_CONTRAT,
		CD_DEVISE_CONTRAT,
		CD_STATUT_OPE_DT_SOLDE,
		CD_DEVISE_ENCOURS,
		CD_STATUT_TIERS,
		MNT_LOY_RD_CRD,
		MNT_LOY_RD_SOLD,
		MNT_VTR,
		MNT_VR,
		CD_DEVISE_VR,
		CD_ACHAT_FIN_LOC,
		CD_DEVISE_VTR,
		MATURITE_CALC,
		CD_PCEC_CRD,
		CD_PCEC_SOLD_K_A,
		CD_PCEC_SOLD_I,
		MNT_ENC_ARR_PAIE,
		TOP_ENG_DOUTEUX,
		CD_IMP_PRUDENT,
		MNT_PROVISION,
		MNT_ENC_RISQ_PROPRE,
		POURC_NIVEAU_PROVISION,
		MNT_GAR_ACTIF,
		MNT_GAR_PREM_QUAL,
		TX_LGD_PREDICTIF,
		TX_LGD_PREDICTIF_LOCAL,
		CD_NIVEAU_PROVISION,
		CD_COUV_PROVISION,
		CD_NEW_DEFAUT,
		A_EXTRAIRE,
		MNT_PNU,
		CD_PCEC_PNU,
		--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 279
		DATE_PREM_ACT_FORB,
		DATE_SORT_EFF_FORB,
		DATE_ENTR_PER_PURG,
		DATE_SORT_PER_PURG,
		DATE_ENTR_PER_PROB,
		DATE_SORT_PER_PROB,
		DATE_THEO_FIN_FORB,
		--23/11/18 CDS Atos (EMM) US 579
		IND_NIV_RISQ,
		--Fin EMM
		--13/02/2019 - CDS Atos (GBD) US673 deb ->
		BUCKET_IFRS9,
		MNT_MTM,
		CD_DEV_MNT_MTM,
		--13/02/2019 - CDS Atos (GBD) US673 <- fin
		-- 12/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
		MNT_LOY_AVEC_ARR,
		DEV_LOY_AVEC_ARR,
		MNT_LOY_HORS_ARR,
		DEV_LOY_HORS_ARR,
		MNT_INT_AVEC_ARR,
		DEV_INT_AVEC_ARR,
		MNT_INT_HORS_ARR,
		DEV_INT_HORS_ARR,
		-- fin CPD
		CD_TYPE_PROD_BANCAIRE, --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
		MNT_CAPITAL_HORS_ARR,
		DEV_CAPITAL_HORS_ARR,
		-- FIN LFD

		--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		CD_POSTAL_IMM,
		CD_PAYS_IMM,
		LIB_VILLE_IMM,
		CD_COMMUNE_INSEE
		--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
	)
		SELECT  DISTINCT o.DT_ARRETE,
			s.CD_CONSO_CPT_CRRV3,
			o.ID_TIERS,
			T.ID_TIERS_CALC,
			T.ID_CENTRAL_TIERS,
			hb.ID_OPERATION_SIG,
			substr(T.ID_TIERS_CALC,4,11) || substr(s.CD_CONSO_CPT_CRRV3,3,10) ||
			--  CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
			--  WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
			--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
			--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END
			-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
			CASE WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')         			 THEN 'NA012'
				WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt not in ('DTX', 'DTCO')      			 THEN 'NA011'
				WHEN ta.cd_segment_cal not in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')      			 THEN 'NA022'
				WHEN ta.cd_segment_cal not in ('06','07') and NVL(Ta.cd_categ_cpt,'SAIN') not in ('DTX', 'DTCO') THEN 'NA021' --Recette M68356
			END ||
			--'NAT07'|| -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO - retire pour faire de la place pour le bucket
			CASE WHEN Ta.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y'
				ELSE 'N'
			END ||
			pf.CD_TYP_RISQ_RET || o.cd_type_taux || case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
			-- CASE WHEN ((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			-- - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
			-- / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end > 0 THEN '1'
			-- WHEN ((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			-- - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
			-- / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end > 20 THEN '2'
			-- ELSE '0' END as ID_AUTORISATION ,  -- optimisation V21S17 + lisible
			CASE  --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				WHEN
					( -- Quand (Somme(MNT_PROV) - Somme(MNT_REPRISE) * 100 ) / 1 ) > 0 alors '1'
					  (   NVL(o.MNT_PROV_SOLD_LOY_K,0)
					    + NVL(o.MNT_PROV_CRD,0)
					    + NVL(o.MNT_PROV_SOLD_LOY_I,0)
					    + NVL(o.MNT_PROV_SOLD_IRE,0)
					    + NVL(o.MNT_PROV_SOLD_AUT,0)
					    + NVL(o.MNT_PROV_ICNE,0)
					  )
					  -
					  (  NVL(o.MNT_REPRISE_SOLD_LOY_K,0)
					   + NVL(o.MNT_REPRISE_CRD,0)
					   + NVL(o.MNT_REPRISE_SOLD_LOY_I,0)
					   + NVL(o.MNT_REPRISE_SOLD_IRE,0)
					   + NVL(o.MNT_REPRISE_SOLD_AUT,0)
					   + NVL(o.MNT_REPRISE_ICNE,0)
					   )
					  *100
					) / CASE
							WHEN NVL(o.MNT_ENC_RISQ_PROPRE,1) > 1
							THEN 1
						END
			    	> 0 THEN '1'
        		WHEN
        			( --Quand (Somme(MNT_PROV) - Somme(MNT_REPRISE) * 100 ) / 1 ) > 20 alors '2'
        			  (
        			      NVL(o.MNT_PROV_SOLD_LOY_K,0)
        			    + NVL(o.MNT_PROV_CRD,0)
        			    + NVL(o.MNT_PROV_SOLD_LOY_I,0)
        			    + NVL(o.MNT_PROV_SOLD_IRE,0)
        			    + NVL(o.MNT_PROV_SOLD_AUT,0)
        			    + NVL(o.MNT_PROV_ICNE,0)
        			  )
        			    -
        			  (   NVL(o.MNT_REPRISE_SOLD_LOY_K,0)
        			    + NVL(o.MNT_REPRISE_CRD,0)
        			    + NVL(o.MNT_REPRISE_SOLD_LOY_I,0)
        			    + NVL(o.MNT_REPRISE_SOLD_IRE,0)
        			    + NVL(o.MNT_REPRISE_SOLD_AUT,0)
        			    + NVL(o.MNT_REPRISE_ICNE,0)
        			  )
        			  *100
        			) / CASE
        				  WHEN NVL(o.MNT_ENC_RISQ_PROPRE,1) > 1
        				  THEN 1
        				END
            		> 20 THEN '2'
            		-- Quand Delta(Sommes) = 0 ou  MNT_ENC_RISQ_PROPRE = 0, null, negatif alors '0'
          		ELSE '0'
        	END ||

			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			---- DEBUT :: M67006 - spec 2.1.3
			CASE
			WHEN (ta.CD_CATEG_CPT = 'DTX' or ta.CD_CATEG_CPT = 'DTCO')
			THEN 'B3'
			ELSE nvl(ifrs.bucket_ifrs9_new,'B1')
			 END as ID_AUTORISATION,
			---- FIN :: M67006 - spec 2.1.3

			-- optimisation V21S17 + lisible
			methodo.CD_METHOD cd_methodo_bale2, --mantis re7 5520
			--DECODE(s.CD_CONSO_CPT_CRRV3, '00472', '07', '01') CD_TRT_MOTEUR, --'07',
			NVL(methodo.trt_moteur, '01') as CD_TRT_MOTEUR,-- M56405 change code moteur de 07 Ã¿Â¿Â½ 01
			-- CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
			--  WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
			--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
			--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END
			-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
			CASE WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')         			 THEN 'NA012'
				WHEN ta.cd_segment_cal in ('06','07') and Ta.cd_categ_cpt not in ('DTX', 'DTCO')      			 THEN 'NA011'
				WHEN ta.cd_segment_cal not in ('06','07') and Ta.cd_categ_cpt in ('DTX', 'DTCO')      			 THEN 'NA022'
				WHEN ta.cd_segment_cal not in ('06','07') and NVL(Ta.cd_categ_cpt,'SAIN') not in ('DTX', 'DTCO') THEN 'NA021' --Recette M68356
			END cd_nature_ope,
			'NAT07' CD_NATURE_PNU,
			-- CASE WHEN T.cd_segment_cal = '01' THEN pf.CD_TYPE_RISQUE_PART ELSE pf.CD_TYPE_RISQUE_AUTRES  END type_risque,
			pf.CD_TYP_RISQ_RET type_risque,
			-- 17/03/2021 - CDS ATOS (LFD) - Mantis 56406
			--'900', --DECODE(methodo.CD_METHOD, 'NON IRB', ' ', '900') CD_PORTEFEUILLE_BALE2, mantis re7 5520
			CASE WHEN pf.CD_TYP_RISQ_RET = 'PRI105' AND s.CD_CONSO_CPT_CRRV3 = '00472' THEN '014' ELSE '900' END CD_PORTEFEUILLE_BALE2,
			-- FIN LFD
			'MLE00' cd_ligne_metier,
			decode(o.cd_PRODUIT, 'CBI', '04', '97') CD_objet_fin,
			o.cd_type_taux,
			decode(o.cd_PRODUIT, 'CBI', '2', '0') CD_USAGE_BIEN_IMM,
			'Y' CD_RESPECT_COND, --decode(o.cd_PRODUIT, 'CBI', 'Y', ' ') CD_RESPECT_COND,
			hb.MNT_IEC mnt_encours,
			hb.MNT_IEC  mnt_autorisation,
			hb.MNT_IEC mnt_contrat,
			nvl2(hb.MNT_IEC,o.CD_DEVISE,NULL) cd_devise_contrat,
			o.CD_STATUT_OPE_DT_SOLDE,
			DECODE(hb.MNT_IEC,0,NULL,o.CD_DEVISE) cd_devise_encours,
			'',
			-- 29/01/2021 - CDS ATOS (LFD) - Mantis 55571
			--o.crd_brut_ht ,
			o.crd_brut_ht + nvl(MNT_SOLDE_HT_EXIGIB_K_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_I_T,0) + nvl(MNT_SOLDE_HT_EXIGIB_AUTRE_T,0) MNT_LOY_RD_CRD,
			-- FIN LFD
			nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0) ,
			--M65476
			--CASE WHEN substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE502','PRI105') THEN sr.mnt_vtr_pdr ELSE null END,
			CASE WHEN substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE502','PRI105') AND s.CD_CONSO_CPT_CRRV3='00472' THEN
                COALESCE( SR.MNT_VV_ACT, SR.MNT_ACQ_HT_ACT * 0.7 , SR.mnt_revise)
            END MNT_VTR,
			--M65476
			mnt_vr,
			nvl2(o.MNT_VR,o.CD_DEVISE,NULL) cd_devise_vr,
			-- 		 --21/11/2018 CDS ATOS (SQN) Mantis 45248 (Debut)
			--  --DECODE(substr(pf.CD_TYP_RISQ_ret,1,6), 'TRE502', '1', 'PRI105', '1', '2') CD_ACHAT_FIN_LOC,
			--   CASE
			--   WHEN (substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE502', 'PRI105'))
			--   AND  s.cd_conso_cpt_crrv3 = '00472'
			-- 	--WHEN substr(pf.CD_TYP_RISQ_ret,1,6) in ('TRE501', 'TRE502', 'PRI105') -- M56278 : nouvelle regle Gestion du CD_ACHAT_FIN_LOC
			--   THEN '1'
			--   --18/03/19 CDS ATOS (EMM) Mantis 47094
			--   --ELSE CASE
			--   --WHEN  substr(pf.CD_TYP_RISQ_CORP,1,6) in ('PRI105', 'TRE501')
			--   --    THEN '2'
			--   --  ELSE '0'
			-- 	  ELSE '2'
			--   --     END
			--   END  CD_ACHAT_FIN_LOC,
			--   --Fin EMM
			-- --Fin
			'2' as CD_ACHAT_FIN_LOC,   -- M56278 (note 194976): nouvelle regle
			nvl2(COALESCE( SR.MNT_VV_ACT, SR.MNT_ACQ_HT_ACT , SR.mnt_revise),o.CD_DEVISE,NULL) cd_devise_vtr,--M65476
			o.maturite_calc,
			pcec.cd_pcec_crd cd_pcec_crd,
			pcec.cd_pcec_k_a CD_PCEC_SOLD_K_A,
			pcec.CD_PCEC_I CD_PCEC_SOLD_I,
			nvl(o.MNT_SOLDE_HT_EXIGIB_K,0)+nvl(o.MNT_SOLDE_HT_EXIGIB_AUTRE,0)+ nvl(o.MNT_SOLDE_HT_EXIGIB_I,0) MNT_ENC_ARR_PAIE,
			decode (ta.CD_CATEG_CPT, 'DTX', 'Y', 'DTCO', 'Y', 'N'),
			case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end,
			(nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0)),
			o.MNT_ENC_RISQ_PROPRE,
			(((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
			   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
			   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end),
			sr.mnt_vtr_pdr,
			o.ENC_FINANC_BRUT-o.MNT_ENC_RISQ_PROPRE,
			o.TX_LGD_PREDICTIF,
			o.TX_LGD_PREDICTIF_LOCAL,
			null,
			   null,
			case when ta.CD_CATEG_CPT in ( 'DTX', 'DTCO')
			   then case when ta.dt_chg_categ_cpt between trunc(o.dt_arrete, 'Q') and o.dt_arrete then 'Y' else 'N' end
			   else 'N' end,
			'O',  --a extraire
			CASE WHEN nvl(o.MNT_EXPO_COURANTE_HT,0) - nvl(o.ENC_FINANC_BRUT,0) - nvl(hb.mnt_iec,0) >0 THEN nvl(o.MNT_EXPO_COURANTE_HT,0) - nvl(o.ENC_FINANC_BRUT,0) - nvl(hb.mnt_iec,0) ELSE 0 END, -- pour les IEC, on peut mettre la PNU = 0, je garde la meme regle avec expo courante plutot que expo potent
			pcec_pnu.cd_pcec_crd,
			--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 279
			--ef.dt_aqr,            --DATE_PREM_ACT_FORB
			-- M58209 : remplace par
			--- DATE_PREM_ACT_FORB alimentee si TOP_RESTRUCTURATION <> null et <> AR
			CASE  WHEN O.CD_AQR = 'C4'                                                                                                 THEN null      --'AR'
			      WHEN O.CD_AQR = 'C3A' AND Ta.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR THEN ef.dt_aqr --'RC'
			      WHEN O.CD_AQR = 'C2'  AND Ta.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF' M70812
			      --WHEN O.CD_AQR = 'C2'   OR Ta.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         THEN ef.dt_aqr --'RF'
			      ELSE NULL
			END AS DATE_PREM_ACT_FORB,
			--sf.dt_fin_valid_aqr,      --DATE_SORT_EFF_FORB
			--12/02/19 CDS ATOS (EMM) US 497
			o.DATE_SORT_EFF_FORB,
			--Fin EMM
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR END DATE_ENTR_PER_PURG,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12) END DATE_SORT_PER_PURG,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,12)
				else CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then o.DT_AQR end
			END DATE_ENTR_PER_PROB,
			CASE WHEN o.CD_AQR = 'C2' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,36)
				else CASE WHEN o.CD_AQR = 'C3A' AND o.DT_FIN_VALID_AQR > o.dt_arrete then ADD_MONTHS(o.DT_AQR,24) end
			END DATE_SORT_PER_PROB,
			-- DATE_THEO_FIN_FORB  M58209 : regle remplace par
			CASE WHEN O.CD_AQR = 'C4'                                                                                                 THEN null      --'AR'
			 WHEN o.CD_AQR = 'C3A' AND Ta.CD_CATEG_CPT IN ('DTX', 'DTCO') AND O.DT_ARRETE BETWEEN O.DT_AQR AND O.DT_FIN_VALID_AQR then ADD_MONTHS(o.DT_AQR,24)
			     WHEN o.CD_AQR = 'C2'   OR Ta.CD_CATEG_CPT IN ('DTX', 'DTCO')                                                         then ADD_MONTHS(o.DT_AQR,36)
			     ELSE NULL
			END AS DATE_THEO_FIN_FORB,
			--23/11/18 CDS Atos (EMM) US 579
			CASE -- 08/06/2022 - KLx Risque (VDC) - Risque Leasing 2022 US 11  - Juste ï¿½a car insertion pour les codes natures PNU, DETAIL_P5
				WHEN ( s.CD_CONSO_CPT_CRRV3 = '00370' AND pf.CD_TYP_RISQ_RET ='PRI105' ) OR pf.CD_TYP_RISQ_RET = 'TRE504' THEN 1
				ELSE 2 END IND_NIV_RISQ,
			--Fin EMM

			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			-- 14/06/2021 - CDS ATOS (LFD) - US 43 MCO
			---- DEBUT :: M67006 - spec 2.1.3
			CASE
			WHEN (ta.CD_CATEG_CPT = 'DTX' or ta.CD_CATEG_CPT = 'DTCO')
			THEN 'B3'
			ELSE nvl(ifrs.bucket_ifrs9_new,'B1')
			 END  BUCKET_IFRS9,
			---- FIN :: M67006 - spec 2.1.3

			null MNT_MTM,
			null CD_DEV_MNT_MTM,
			--13/02/2019 - CDS Atos (GBD) US673 <- fin
			-- 12/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
			0,
			'EUR'DEV_LOY_AVEC_ARR ,
			0,
			'EUR' DEV_LOY_HORS_ARR ,
			CASE WHEN (decode (ta.CD_CATEG_CPT, 'DTX', 'Y', 'DTCO', 'Y', 'N')) = 'Y' then
						CASE WHEN o.MNT_SOLDE_HT_EXIGIB_I is null then 0 else o.MNT_SOLDE_HT_EXIGIB_I END
			ELSE 0 END,
			'EUR' DEV_INT_AVEC_ARR,
			0,
			'EUR' DEV_INT_HORS_ARR
			-- fin CPD
			,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
			,CASE WHEN (pf.CD_TYP_RISQ_RET like 'TRE2%' and pf.CD_TYP_RISQ_RET <> 'TRE201') or pf.CD_TYP_RISQ_RET like 'TRE3%' or pf.CD_TYP_RISQ_RET like 'TRE4%'
							or pf.CD_TYP_RISQ_RET in ('PRI102', 'PRI103', 'PRI104' ,'PRI109')
					THEN
						NVL(o.MNT_SOLDE_HT_EXIGIB_K,0)
				ELSE 0
			END MNT_CAPITAL_HORS_ARR
			,'EUR' DEV_CAPITAL_HORS_ARR
			-- FIN LFD
			--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		    ,case
			   when (decode(o.cd_PRODUIT, 'CBI', '2', '0') <> '0' and sr.cd_pays = 'FR')
			     then sr.cd_postal
			     else null
			 end as CD_POSTAL_IMM
			,case
			   when (decode(o.cd_PRODUIT, 'CBI', '2', '0') <> '0' and sr.cd_pays = 'FR')
			     then sr.cd_pays
				 else null
		     end as CD_PAYS_IMM
			,case
			   when (decode(o.cd_PRODUIT, 'CBI', '2', '0') <> '0' and sr.cd_pays = 'FR')
			     then sr.ville
				 else null
			 end  as LIB_VILLE_IMM
			,null as CD_COMMUNE_INSEE
		    --FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
		FROM BTR_OPERATION o,
			btr_hors_bilan hb,
			RS_SOCIETE_JURIDIQUE s,
			TIE_TIERS_C1_C5 T,
			BTR_TIERS ta,
			RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			(	SELECT BTR_SURETE_PERS.cd_sys_int, BTR_SURETE_PERS.id_operation, SUM(MNT_GARANTIE) mnt_garantie
				FROM BTR_SURETE_PERS
				GROUP BY BTR_SURETE_PERS.cd_sys_int,BTR_SURETE_PERS.id_operation) sp,
			(	SELECT
			   	    --M65476 added Max(column) and commented the group by
					--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
					MAX(br.cd_postal) cd_postal
					,MAX(br.cd_pays) cd_pays
					,MAX(br.ville) ville
					--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
					,br.cd_sys_int
					,br.id_operation
					,SUM(br.MNT_VTR_PDR) mnt_vtr_pdr
					,SUM(br.MNT_VV_ACT) MNT_VV_ACT -- M65476
					,SUM(br.MNT_ACQ_HT_ACT) MNT_ACQ_HT_ACT -- M65476
					,SUM(br.mnt_revise) mnt_revise -- M65476
				FROM BTR_SURETE_REELLE br
				GROUP BY
				  --DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
				  --  br.cd_postal
				  --,br.cd_pays
				  --,br.ville
				  --FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
				  --,
				  br.cd_sys_int, br.id_operation
			) sr,
			( 	SELECT id_operation,cd_sys_int,id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I
				FROM -- 33s
			   		(	SELECT o.CD_SYS_INT,o.ID_OPERATION,
								CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE nvl(sr.CD_STATUT_ACT,'NA') END cd_statut_act,  --43378
								so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,nvl(T.CD_CATEG_CPT,T.CD_STATUT_RISQ) CD_CATEG_CPT,o.CD_PRODUIT -- 466728
						FROM btr_operation o, --btr_surete_reelle sr,
							rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				 			( SELECT cd_sys_int,id_operation,
										min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
							 	FROM btr_surete_reelle
								GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
						WHERE  o.ID_OPERATION=sr.ID_OPERATION (+)
							AND o.CD_SYS_INT=sr.CD_SYS_INT  (+)
							AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
							AND o.ID_TIERS = T.ID_TIERS
							AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							AND so.CD_PHASE = 'APCDE'
							AND o.CD_PRODUIT NOT IN ('CRED','CREN')
						UNION ALL -- optimisation V21S17
						SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
						FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
						WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
							AND o.ID_TIERS = T.ID_TIERS
							AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							AND so.CD_PHASE = 'APCDE'
							AND o.CD_PRODUIT IN ('CRED','CREN')
							and not exists (SELECT 1
											FROM
												 rs_statut_ope so,
												 btr_tiers T,
												 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
												(SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
												 FROM btr_surete_reelle
												 GROUP BY cd_sys_int, id_operation
												) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
											WHERE sr.ID_OPERATION  = o.ID_OPERATION
												AND sr.CD_SYS_INT    = o.CD_SYS_INT
												AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
												AND o.ID_TIERS       = T.ID_TIERS
												AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
												--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
												AND so.CD_PHASE      = 'APCDE'
												--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
												AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV')
											)
					) perim,
			   		rs_corres_pcec pc
				WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
					AND perim.CD_PHASE = pc.CD_PHASE
					AND perim.CD_PRODUIT = pc.CD_PRODUIT
					AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
					AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
			) pcec, -- AGU 23/01/2009
			(SELECT CD_SOC_JURI, CD_SEGMENT, cd_method, trt_moteur  -- M56405 change code moteur de 07 Ã¿Â¿Â½ 01 : ajout trt_moteur
			   FROM RS_METHO_BALE_SOC_SEG ) methodo,
			( 	SELECT o.id_operation,o.cd_sys_int,o.id_tiers,rsc.cd_pcec_crd
				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs, rs_corres_pcec rsc
				WHERE rsc.nato_crd='NAT07'
					AND so.cd_statut_ope=o.cd_statut_ope
					and o.id_tiers=t.id_tiers
					and t.cd_role_tiers='C'
					and t.cd_segment_cal=rs.cd_segment_cal
					and rs.cd_type_cli=rsc.cd_type_cli
					and so.cd_phase=rsc.cd_phase
			) pcec_pnu,
			--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 319
			( select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
						cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
				from his_forb_btr_operation hisb
				where hisb.cd_aqr IN ('C2','C3A')
					and hisb.dt_arrete between hisb.dt_aqr and hisb.dt_fin_valid_aqr
					and hisb.dt_aqr = (select min(hist.dt_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation and hist.cd_aqr IN ('C2','C3A'))
			)ef
				/*,
			(select id_operation, cd_sys_int, dt_arrete, cd_aqr, dt_aqr,
							  cd_aqr_force, dt_aqr_force, dt_fin_valid_aqr
							  from his_forb_btr_operation hisb
							  where hisb.cd_aqr IN ('C2','C3A')
							  and dt_fin_valid_aqr = add_months(dt_arrete, -1)
							  and hisb.dt_fin_valid_aqr = (select max(hist.dt_fin_valid_aqr) from his_forb_btr_operation hist where hist.id_operation = hisb.id_operation)
							  )sf */
			--Fin EMM
			,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques

			-- 14/06/2021 - CDS ATOS (LFD) - US 43 MCO
			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			---- remplacer annexe_ifrs par tmp_gr05_granulaire
			---- DEBUT :: M67006 - spec 2.1.3
			, (select gr05.ref_uniq_ctr
					, gr05.cd_entite
					, max(case
						  when nvl(gr05.bucket_ecl,'Stage1') = 'Stage1'
						  then 'B1'
						  else 'B2'
						   end) bucket_ifrs9_new
		     	 from tmp_gr05_granulaire gr05
                group
				   by gr05.ref_uniq_ctr, gr05.cd_entite) ifrs
			---- FIN :: M67006 - spec 2.1.3
		WHERE o.CD_SOC_JURI = s.CD_SOC_JURI
			AND   o.ID_TIERS = T.ID_TIERS
			AND   o.ID_TIERS = ta.ID_TIERS
			AND   o.CD_SYS_INT = hb.cd_sys_int
			AND   o.ID_OPERATION = hb.id_operation
			and   hb.mnt_iec > 0
			AND   o.CD_PRODUIT    = pf.CD_PRODUIT
			--    AND   s.CD_CONSO_CPT_CRRV3 = pf.CD_CONSO_CPT
			AND   o.CD_SYS_INT = sp.CD_SYS_INT (+)
			AND   o.ID_OPERATION = sp.ID_OPERATION (+)
			AND   o.CD_SYS_INT = sr.CD_SYS_INT (+)
			AND   o.ID_OPERATION = sr.ID_OPERATION (+)
			AND   o.ID_OPERATION = pcec.id_operation (+)    -- AGU 23/01/2009
			AND   o.CD_SYS_INT = pcec.cd_sys_int (+)        -- AGU 23/01/2009
			AND   o.ID_TIERS = pcec.id_tiers (+)            -- AGU 23/01/2009  n,
			AND   o.ID_OPERATION = pcec_pnu.id_operation (+)
			AND   o.CD_SYS_INT = pcec_pnu.cd_sys_int (+)
			AND   o.ID_TIERS = pcec_pnu.id_tiers (+)
			AND   s.CD_CONSO_CPT_CRRV3 != '99999'
			AND   T.CD_TYPE_TIE = 'RETA'
			And T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
			And s.cd_soc_juri     = methodo.cd_soc_juri
			--01/08/2018 - CDS ATOS (EMM) - Sprint 13 - US 29 et US 319
			and o.id_operation = ef.id_operation(+)
			and o.cd_sys_int   = ef.cd_sys_int(+)
			--and o.id_operation = sf.id_operation(+)
			--and o.cd_sys_int   = sf.cd_sys_int(+)
			--Fin EMM
			--CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
			AND pf.CD_TYP_RISQ_RET = PARAM.VAL_PARAM_1 --ENG_RETAIL_P5.CD_TYPE_RISQUE = PARAM_MULTIDIM_GENERIQUE.VAL_PARAM_1
			--FIN MNE

			-- KLx_Risques :: M67006 - le code precedent a ete supprime afin de ne pas polluer !!!
			-- 14/06/2021 - CDS ATOS (LFD) - US 43 MCO
			---- DEBUT :: M67006 - spec 2.1.3
			and o.id_operation       = ifrs.ref_uniq_ctr (+)
            and s.cd_conso_cpt_crrv3 = ifrs.cd_entite    (+);
			---- FIN :: M67006 - spec 2.1.3
		COMMIT;

	-- mise a jour codes sur detail retail p5
    --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
	W_TABLE := 'ENG_RETAIL_DETAIL_P5 (3)';
	Update ENG_RETAIL_DETAIL_P5
	set CD_NIVEAU_PROVISION = case when POURC_NIVEAU_PROVISION > 0 then '1'
									when POURC_NIVEAU_PROVISION > 20 then '2'
									else '0' end;
	W_TABLE := 'ENG_RETAIL_DETAIL_P5 (4)';
	Update ENG_RETAIL_DETAIL_P5
	set CD_COUV_PROVISION  = case when CD_COUV_PROVISION > 0 then '1'
									when CD_COUV_PROVISION > 20 then '2'
									else '0' end;

	---------------------------------------------
	-- LOT FEVRIER 2016 EVOL SYNDICATION
	---------------------------------------------
	W_TABLE := 'ENG_RETAIL_DETAIL_P5 (5)';
	Update ENG_RETAIL_DETAIL_P5 P5
	Set (p5.MNT_LOY_RD_CRD, p5.MNT_LOY_RD_SOLD) =
			( SELECT DECODE(sign(nvl(P5.MNT_LOY_RD_CRD,0)-sum(nvl(sp.mnt_garantie,0))),
				  -1,0, nvl(P5.MNT_LOY_RD_CRD,0)-sum(nvl(sp.mnt_garantie,0)) ),
				DECODE(sign(nvl(P5.MNT_LOY_RD_CRD,0)-sum(nvl(sp.mnt_garantie,0))),
				  1,p5.MNT_LOY_RD_SOLD, DECODE(SIGN(p5.MNT_LOY_RD_SOLD-ABS(nvl(P5.MNT_LOY_RD_CRD,0)-sum(nvl(sp.mnt_garantie,0)))), -1,0, (p5.MNT_LOY_RD_SOLD-ABS(nvl(P5.MNT_LOY_RD_CRD,0)-sum(nvl(sp.mnt_garantie,0)))))
				  )
			 From BTR_SURETE_PERS sp, RS_TYPE_GARANTIE tg
			 Where  tg.id_type_garantie = sp.id_type_garantie
			 And   tg.id_type_garantie in ('AUSY', 'CASY', 'CLSY')
			 And sp.id_operation=P5.id_engagement
			)
	Where exists  (Select 1
				 From BTR_SURETE_PERS sp, RS_TYPE_GARANTIE tg
				 Where  tg.id_type_garantie = sp.id_type_garantie
				 And   tg.id_type_garantie in ('AUSY', 'CASY', 'CLSY')
				 And sp.id_operation=P5.id_engagement
				)
	;
	COMMIT;
	W_TABLE := 'ENG_RETAIL_DETAIL_P5 (6)';
	Update ENG_RETAIL_DETAIL_P5 P5
	  Set (p5.MNT_LOY_RD_CRD, p5.MNT_LOY_RD_SOLD) =
			  (Select  DECODE(sign(nvl(p5.MNT_LOY_RD_CRD,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0))),
				  -1,0, nvl(p5.MNT_LOY_RD_CRD,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0)) ),
				  DECODE(sign(nvl(p5.MNT_LOY_RD_CRD,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0))),
				  1,DECODE(sign(p5.MNT_LOY_RD_SOLD),-1,0,p5.MNT_LOY_RD_SOLD), -- CDS Atos MDT Mantis 44788 : si SOLD < 0 alors 0
						 DECODE(SIGN(p5.MNT_LOY_RD_SOLD-ABS(nvl(p5.MNT_LOY_RD_CRD,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0)))), -1,0, (p5.MNT_LOY_RD_SOLD-ABS(nvl(p5.MNT_LOY_RD_CRD,0)-(nvl(o.mnt_subv_ht,0) + nvl(o.mnt_avp_ht,0)))))
				  )
			   From BTR_OPERATION o
			   Where o.id_operation=P5.id_engagement
			  )
	where exists  (Select 1
			   From BTR_OPERATION o
			   Where o.id_operation=P5.id_engagement
			  )
	;
	COMMIT;

	--18/02/2019 - CDS ATOS (SQN) - Sprint 22 US 733
	--20/02/2019 - CDS ATOS (SQN) - Sprint 22 US 733 - Correctif
	--UPDATE ENG_RETAIL_DETAIL_P5 SET cd_pcec_crd = CASE WHEN cd_pcec_crd is null THEN 'A5721100' END;
	--UPDATE ENG_RETAIL_DETAIL_P5 SET CD_PCEC_SOLD_K_A = CASE WHEN CD_PCEC_SOLD_K_A is null THEN 'A5721100' END;
	--UPDATE ENG_RETAIL_DETAIL_P5 SET CD_PCEC_SOLD_I = CASE WHEN CD_PCEC_SOLD_I is null THEN 'A5721100' END;
	--COMMIT;
	--Fin SQN

	--12/02/2021 - CDS ATOS (CPD) - US 25 CRRV3.4
	UPDATE ENG_RETAIL_DETAIL_P5 SET MNT_LOY_AVEC_ARR = CASE WHEN substr(CD_TYPE_RISQUE,1,4)='TRE5' OR substr(CD_TYPE_RISQUE,1,6)='PRI105'
											THEN CASE WHEN MNT_LOY_RD_SOLD is null then 0 else MNT_LOY_RD_SOLD END
											ELSE 0
											END;
	UPDATE ENG_RETAIL_DETAIL_P5 SET MNT_LOY_HORS_ARR = CASE WHEN substr(CD_TYPE_RISQUE,1,4)='TRE5' OR substr(CD_TYPE_RISQUE,1,6)='PRI105'
										--THEN CASE WHEN MNT_LOY_AVEC_ARR <> 0 then nvl(MNT_ENCOURS,0) - nvl(MNT_LOY_RD_SOLD,0) else 0 END
                                        --THEN nvl(MNT_ENCOURS,0) - nvl(MNT_LOY_RD_SOLD,0)
	                                    THEN NVL(MNT_LOY_RD_CRD,0) - NVL(MNT_LOY_RD_SOLD,0)
										ELSE 0
										END;
	commit;
	-- fin CPD

	--DEBUT: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune
	l_position := 'code INSEE commune';

	for cINSEE
	in (select distinct cd_postal_imm, lib_ville_imm
	    from eng_retail_detail_p5 p5
	    where p5.cd_pays_imm       = 'FR'
		  and p5.cd_usage_bien_imm <> '0')
	loop
		--vÃ©rifier le numÃ©ro des lignes
		select count(0) into Nb_Lignes
		from re_commune
		where cd_postal   = cINSEE.cd_postal_imm
		  and lib_commune like replace(replace(cINSEE.lib_ville_imm,'-',' '),'''',' ') || '%';

		--si on a plusieurs lignes il faut prendre la ligne dont les 2 premiers caractÃ¤res du code postal = les 2 premiers caractÃ¤res du code INSEE
		if Nb_Lignes > 1 then
			begin
			  select cd_insee_commune into pInseeCommune
			  from re_commune
			  where cd_postal				= cINSEE.cd_postal_imm
			    and substr(cd_postal, 1, 2) = substr(cd_insee_commune, 1, 2)
				and lib_commune like replace(replace(cINSEE.lib_ville_imm,'-',' '),'''',' ') || '%';
			exception
              when too_many_rows then
                select cd_insee_commune into pInseeCommune
			    from re_commune
			    where cd_postal				  = cINSEE.cd_postal_imm
			      and substr(cd_postal, 1, 2) = substr(cd_insee_commune, 1, 2)
				  and lib_commune             = replace(replace(cINSEE.lib_ville_imm,'-',' '),'''',' ');

              when no_data_found then
			    pInseeCommune := null;
			end;
		else
			begin
			  select cd_insee_commune into pInseeCommune
			  from re_commune
			  where cd_postal = cINSEE.cd_postal_imm
				and lib_commune like replace(replace(cINSEE.lib_ville_imm,'-',' '),'''',' ') || '%';
			exception
              when too_many_rows then
                select cd_insee_commune into pInseeCommune
			    from re_commune
			    where cd_postal   = cINSEE.cd_postal_imm
				  and lib_commune = replace(replace(cINSEE.lib_ville_imm,'-',' '),'''',' ');

              when no_data_found then
			    pInseeCommune := null;
			end;
		end if;

		--maj de la table eng_retail_detail_p5
		update eng_retail_detail_p5
		set cd_commune_insee = pInseeCommune
		where cd_postal_imm     = cINSEE.cd_postal_imm
		  and lib_ville_imm     = cINSEE.lib_ville_imm
		  and cd_pays_imm       = 'FR'
		  and cd_usage_bien_imm <> '0';
		commit;
	end loop;
	--FIN: KLxRisqLeasing (BA) - US 269: Score 7 Code INSEE de la commune

EXCEPTION
	WHEN OTHERS THEN
		 ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('Proc p_alim_encours_retail_p5 table:' || W_TABLE || ' -MESS:'||SQLERRM);
		 pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_encours_retail_p5:'||l_position ||' table:'|| W_TABLE,50072);
END p_alim_encours_retail_p5;

	   ------------------------------------------------------
	   -- nom : procedure p_alim_ventilation_baloise_p6    --
	   -- but : Alimentation de la table cible envoi CRRV3 --
	   --       ENG_ENCOURS_RETA_DET_P6 et                 --
	   --       ENG_ENCOURS_RETA_AGREG_P6                  --
	   -- auteur : A. Francisco, le 25/06/2012             --
	   -- entr?e : /                                       --
	   -- retour : /                                       --
	   -- Modification:                                    --
	   ------------------------------------------------------
       -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
       --   ajout information de la table en cas d'erreurs --
       ------------------------------------------------------
	  PROCEDURE p_alim_ventilation_baloise_p6 IS

		   l_position varchar2(20);
           W_TABLE    VARCHAR(30);

		 BEGIN
            DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		  -- l_position := 'anal stat tie_tiers';
		  -- DBMS_STATS.GATHER_TABLE_STATS('DDREX','TIE_TIERS',Estimate_Percent => NULL, CASCADE => TRUE);

		   -- table de d?tail concernant les encours des tiers du domaine P6
		   l_position := 'tiers detail P6';
           W_TABLE := 'ENG_BALOIS_DETAIL_P6 (1)';
		   execute immediate 'TRUNCATE TABLE ENG_BALOIS_DETAIL_P6';
           W_TABLE := 'ENG_BALOIS_AGREG_P6 (1)';
		   execute immediate 'TRUNCATE TABLE ENG_BALOIS_AGREG_P6';

           W_TABLE := 'ENG_BALOIS_DETAIL_P6 (2)';
		   INSERT INTO ENG_BALOIS_DETAIL_P6
			 (
			   DT_ARRETE                   ,
			   CD_CONSO_CPT                ,
			   ID_TIERS                    ,
			   ID_TIERS_CALC               ,
			   ID_CENTRAL_TIERS            ,
			   ID_AUTORISATION             , --
			   ID_LIGNE_DET                , --
			   ID_ENGAGEMENT               ,
			   CD_CLASSE_PD                ,
			   POURC_TX_PD                 ,
			   CD_CLASSE_LGD               ,
			   TX_LGD_PREDICTIF            ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   MNT_EXPO_POTENT_HT          ,
			   ENCOURS_FINANC_BRUT         ,
			   MNT_ENGT_FINANCMT_HB        ,
			   MNT_IRD                     ,
			   TX_CCF                      ,
			   MNT_EAD_TOT                 ,
			   CD_METHODO_BALE2            ,
			   MNT_RWA                     ,
			   CD_DEVISE                   ,
			   MATURITE_CALC               ,
			   A_EXTRAIRE
		   --      ,TX_LGD_PREDICTIF_HG
			  ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 )
			 (SELECT distinct t.DT_ARRETE,
				s.CD_CONSO_CPT_CRRV3,
				t.ID_TIERS,
				'1', --t.ID_TIERS_CALC, totof recalcul agregat
				ta.ident_siris ID_CENTRAL_TIERS,
				-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			/*substr(T.ID_TIERS_CALC,4,11) || substr(s.CD_CONSO_CPT_CRRV3,3,10) ||
			CASE WHEN t.cd_segment_cal in ('06','07')  THEN 'NAT01'
				   WHEN t.cd_segment_cal not in ('06','07')  THEN 'NAT02'
				  END  ||
				   'NAT07'
				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				  case when
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
				  WHEN
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
				  ELSE '0'
				  END*/
				  P5.ID_AUTORISATION,
				  -- FIN LFD
				null,
				o.ID_OPERATION,
				Decode (ta.NOTE_BALOISE, 'R1', 'R1', 'R2','R2', 'R3','R3','R4','R4', 'R5', 'R5','R6', 'R6','F', 'R6', 'Z', 'R6','RR') CD_CLASSE_PD,
				'', --ta.POURC_TX_PD,
				Decode (ta.NOTE_BALOISE, 'R1', 'R1', 'R2','R2', 'R3','R3','R4','R4', 'R5', 'R5','R6', 'R6','F', 'R6', 'Z', 'R6','RR') CD_CLASSE_LGD,
				o.TX_LGD_PREDICTIF_LOCAL,
				ta.CD_PAYS_RESIDENCE,
				nvl(sa.CD_SECTEUR_ACTIVITE,'ZZ0000') CD_SECTEUR_ACTIVITE,
				ta.CD_SEGMENT_CASA,
				CASE WHEN t.NOTE_INTERNE IN ('F','Z') THEN 'R6'    --AFR le 16/11/2012 retour recette mantis n? 571
					WHEN t.NOTE_INTERNE NOT IN ('R1','R2','R3','R4','R5','R6','RR','F','Z') THEN 'RR' --AFR le 16/11/2012 retour recette mantis n? 571
					ELSE t.NOTE_INTERNE --AFR le 16/11/2012 retour recette mantis n? 571
				END  NOTE_INTERNE_RETAIL,
				T.CD_CATEG_CONTREPARTIE,
				NVL(o.ENC_FINANC_BRUT,0) + case when nvl(o.MNT_EXPO_POTENT_HT,0) - NVL(o.mnt_expo_courante_ht,0) >=0 THEN
					nvl(o.MNT_EXPO_POTENT_HT,0) - NVL(o.mnt_expo_courante_ht,0)
				   Else 0
				End MNT_EXPO_POTENT_HT,
				NVL(o.ENC_FINANC_BRUT,0) ENC_FINANC_BRUT,
				case when nvl(o.MNT_EXPO_POTENT_HT,0) - NVL(o.mnt_expo_courante_ht,0) >=0 THEN
					 nvl(o.MNT_EXPO_POTENT_HT,0) - NVL(o.mnt_expo_courante_ht,0)
				   Else 0
				End MNT_ENGMT_FINANCMT_HB, -- on retire l expo courante pour annuler la prise en compte des soldes autres roles
				0,
				0.5, --Decode (substr(cd_method,1,3), 'NON','',re.TX_CONV_HB), mantis 5550, 5520 tout est en STD
				case when o.MNT_EAD_TOT-nvl(hb.mnt_iec,0) < 0 then 0
				   else o.MNT_EAD_TOT-nvl(hb.mnt_iec,0)
				end  MNT_EAD_TOT,
				methodo.cd_method CD_METHODO_BALE2,--mantis re7 5520
				0 MNT_RWA,
				o.CD_DEVISE,
				trunc (o.maturite_calc),
				'O'   --a extraire
				,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 FROM
			  BTR_TIERS ta,
			  RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			  TIE_TIERS_C1_C5 t,
			  BTR_HORS_BILAN hb,
			  RS_SOCIETE_JURIDIQUE s,
			  (SELECT CD_SOC_JURI, CD_SEGMENT, cd_method
			   FROM RS_METHO_BALE_SOC_SEG ) methodo,
			  RS_CORRES_SGMT_BAL_METH_VALOR mv,
			  RE_TAUX_CONV_HB re,
			  RS_CORRES_NAF_NORM_LOCAL_ACT sa,
			  BTR_OPERATION o
			  ,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			  ,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			WHERE  o.CD_SYS_INT      = hb.CD_SYS_INT   (+)
			 AND   o.ID_OPERATION    = hb.ID_OPERATION (+)
			   AND   o.CD_PRODUIT    = pf.CD_PRODUIT
			 AND   o.CD_SOC_JURI     = s.CD_SOC_JURI
			 AND   o.ID_TIERS = ta.ID_TIERS
			 AND   ta.ID_TIERS = t.ID_TIERS
			 and ta.cd_role_tiers in ('C', 'G')
			 and ta.type_tiers in ('P', 'I', 'M')
			 and t.cd_type_relation  in ('C', 'G')
			 and t.cd_conso_cpt =s.CD_CONSO_CPT_CRRV3
			 and   o.CD_CANAL_APPORT = re.CD_CANAL_APPORT(+)
			 and   o.CD_SOC_JURI = re.cd_soc_juri(+)
			 and   o.CD_PRODUIT = re.CD_PRODUIT(+)
			-- AND   nvl(t.ID_CENTRAL_TIERS,'xxx') = nvl(TA.IDENT_SIRIS,'xxx') -- AFR le 13/09/2012 retour recette mantis 349
			 AND   s.CD_CONSO_CPT_CRRV3 = t.CD_CONSO_CPT
			 AND   ta.CD_SEGMENT_CAL = mv.CD_SEGMENT_CAL
			 AND   t.CD_TYPE_TIE   = ta.CD_TYPE_SGMT
			 AND   ta.CD_TYPE_SGMT       = 'RETA'
			 AND   ta.CD_NAF_REV2    = sa.CD_NAF_REV2 (+)
			 AND   s.CD_CONSO_CPT_CRRV3 != '99999'
			 And    T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
			 And   o.cd_soc_juri     = methodo.cd_soc_juri
			 --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
			 AND pf.CD_TYP_RISQ_RET = PARAM.VAL_PARAM_1
			 --FIN MNE
			 AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			 AND    s.CD_CONSO_CPT_CRRV3  = P5. CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
			 ) ;

			 COMMIT;
	   -- totof IEC
           W_TABLE := 'ENG_BALOIS_DETAIL_P6 (3)';
		   INSERT INTO ENG_BALOIS_DETAIL_P6
			 (
			   DT_ARRETE                   ,
			   CD_CONSO_CPT                ,
			   ID_TIERS                    ,
			   ID_TIERS_CALC               ,
			   ID_CENTRAL_TIERS            ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_ENGAGEMENT               ,
			   CD_CLASSE_PD                ,
			   POURC_TX_PD                 ,
			   CD_CLASSE_LGD               ,
			   TX_LGD_PREDICTIF            ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   MNT_EXPO_POTENT_HT          ,
			   ENCOURS_FINANC_BRUT         ,
			   MNT_ENGT_FINANCMT_HB        ,
			   MNT_IRD                     ,
			   TX_CCF                      ,
			   MNT_EAD_TOT                 ,
			   CD_METHODO_BALE2            ,
			   MNT_RWA                     ,
			   CD_DEVISE                   ,
			   MATURITE_CALC               ,
			   A_EXTRAIRE
		   --      ,TX_LGD_PREDICTIF_HG
			   ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 )
			 (SELECT distinct o.DT_ARRETE,
				s.CD_CONSO_CPT_CRRV3,
				o.ID_TIERS,
				'1', --t.ID_TIERS_CALC, totof recalcul agregat
				ta.ident_siris ID_CENTRAL_TIERS,
				-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
				/*
			substr(T.ID_TIERS_CALC,4,11) || substr(s.CD_CONSO_CPT_CRRV3,3,10) ||
			CASE WHEN t.cd_segment_cal in ('06','07')  THEN 'NAT01'
				   WHEN t.cd_segment_cal not in ('06','07')  THEN 'NAT02'
				  END  ||
				   'NAT07'
				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				  case when
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
				  WHEN
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
				  ELSE '0'
				  END */
				  P5.ID_AUTORISATION,
				  -- FIN LFD
				null,
				hb.ID_OPERATION_SIG,
				Decode (ta.NOTE_BALOISE, 'R1', 'R1', 'R2','R2', 'R3','R3','R4','R4', 'R5', 'R5','R6', 'R6','F', 'R6', 'Z', 'R6','RR') CD_CLASSE_PD,
				'', --ta.POURC_TX_PD,
				Decode (ta.NOTE_BALOISE, 'R1', 'R1', 'R2','R2', 'R3','R3','R4','R4', 'R5', 'R5','R6', 'R6','F', 'R6', 'Z', 'R6','RR') CD_CLASSE_LGD,
				o.TX_LGD_PREDICTIF_LOCAL,
				ta.CD_PAYS_RESIDENCE,
				nvl(sa.CD_SECTEUR_ACTIVITE,'ZZ0000') CD_SECTEUR_ACTIVITE,
				ta.CD_SEGMENT_CASA,
				CASE WHEN t.NOTE_INTERNE IN ('F','Z') THEN 'R6'    --AFR le 16/11/2012 retour recette mantis n? 571
				   WHEN t.NOTE_INTERNE NOT IN ('R1','R2','R3','R4','R5','R6','RR','F','Z') THEN 'RR' --AFR le 16/11/2012 retour recette mantis n? 571
				   ELSE t.NOTE_INTERNE --AFR le 16/11/2012 retour recette mantis n? 571
				END  NOTE_INTERNE_RETAIL,
				T.CD_CATEG_CONTREPARTIE,
				hb.mnt_iec MNT_EXPO_POTENT_HT,
				hb.mnt_iec ENC_FINANC_BRUT,
				0 MNT_ENGMT_FINANCMT_HB, --
				0,
			  0.5, --Decode (substr(cd_method,1,3), 'NON','',re.TX_CONV_HB), mantis 5550, 5520 tout est en STD
				hb.mnt_iec  MNT_EAD_TOT,
				methodo.cd_method CD_METHODO_BALE2, --mantis re7 5520
				0 MNT_RWA,
				o.CD_DEVISE,
				trunc (o.maturite_calc),
				'O'   --a extraire
				,PARAM.VAL_RESULTAT1 --CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques

			 FROM
			  BTR_TIERS ta,
			  TIE_TIERS_C1_C5 t,
			  BTR_HORS_BILAN hb,
					  RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			  RS_SOCIETE_JURIDIQUE s,
			  (SELECT CD_SOC_JURI, CD_SEGMENT, cd_method
			   FROM RS_METHO_BALE_SOC_SEG ) methodo,
			  RS_CORRES_SGMT_BAL_METH_VALOR mv,
			  RE_TAUX_CONV_HB re,
			  RS_CORRES_NAF_NORM_LOCAL_ACT sa,
			  BTR_OPERATION o
			  ,PARAM_MULTIDIM_GENERIQUE PARAM --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			  ,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			WHERE  o.CD_SYS_INT      = hb.CD_SYS_INT
			 AND   o.ID_OPERATION    = hb.ID_OPERATION
					AND   o.CD_PRODUIT    = pf.CD_PRODUIT
			 and   hb.mnt_iec > 0
			 AND   o.CD_SOC_JURI     = s.CD_SOC_JURI
			 AND   o.ID_TIERS = ta.ID_TIERS
			 AND   ta.ID_TIERS = t.ID_TIERS
			 and   ta.cd_role_tiers in ('C', 'G')
			 and   ta.type_tiers in ('P', 'I', 'M')
			 and   t.cd_type_relation  in ('C', 'G')
			 and   t.cd_conso_cpt =s.CD_CONSO_CPT_CRRV3
			 and   o.CD_CANAL_APPORT = re.CD_CANAL_APPORT(+)
			 and   o.CD_SOC_JURI = re.cd_soc_juri(+)
			 and   o.CD_PRODUIT = re.CD_PRODUIT(+)
			-- AND   nvl(t.ID_CENTRAL_TIERS,'xxx') = nvl(TA.IDENT_SIRIS,'xxx') -- AFR le 13/09/2012 retour recette mantis 349
			 AND   s.CD_CONSO_CPT_CRRV3 = t.CD_CONSO_CPT
			 AND   ta.CD_SEGMENT_CAL = mv.CD_SEGMENT_CAL
			 AND   t.CD_TYPE_TIE   = ta.CD_TYPE_SGMT
			 AND   ta.CD_TYPE_SGMT       = 'RETA'
			 AND   ta.CD_NAF_REV2    = sa.CD_NAF_REV2 (+)
			 AND   s.CD_CONSO_CPT_CRRV3 != '99999'
			 And    T.CD_SEGMENT_CAL  = methodo.CD_SEGMENT
			 And   o.cd_soc_juri     = methodo.cd_soc_juri
			 --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 AND PARAM.CODE_TYPE_UTILISATION='PRODUIT_BANCAIRE'
			 AND pf.CD_TYP_RISQ_RET = PARAM.VAL_PARAM_1
			 --FIN MNE
			 AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			 AND    s.CD_CONSO_CPT_CRRV3  = P5. CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
			 ) ;

			 COMMIT;

	  EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc p_alim_ventilation_baloise_p6 table:' || W_TABLE || ' -MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_ventilation_baloise_p6:'||l_position,50072);
	  END p_alim_ventilation_baloise_p6;


	  ------------------------------------------------------
	  -- nom : procedure p_alim_PROVISIONS_DETAIL_P8      --
	  -- but : Alimentation de la table cible envoi CRRV3 --
	  --       PROVISIONS_DETAIL_P8                       --
	  -- auteur : A. Francisco, le 25/06/2012             --
	  -- entr?e : /                                       --
	  -- retour : /                                       --
	  -- Modification:                                    --
	  ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_alim_Provisions_detail_P8 IS

		   l_position VARCHAR2(20);
           W_TABLE    VARCHAR2(150);

		 BEGIN
            DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
				 l_position := 'Prov detail P8';

           W_TABLE := 'PROVISIONS_DETAIL_P8 (1)';
		   execute immediate 'TRUNCATE TABLE PROVISIONS_DETAIL_P8';
           W_TABLE := 'PROVISIONS_AGREG_P8 (1)';
		   execute immediate 'TRUNCATE TABLE PROVISIONS_AGREG_P8';

           W_TABLE := 'PROVISIONS_DETAIL_P8 (2)';
		   INSERT INTO PROVISIONS_DETAIL_P8
		   (   DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS,
			 ID_TIERS_CALC,
			 ID_CENTRAL_TIERS,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_ENGAGEMENT,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 MNT_PROVISION,
			 MNT_PROVISION_TRIM,
			 CD_DEVISE,
			 CD_PCCO,
			 a_extraire
			 ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
			,MTPROVBIL
			,MTPROVHB
			,MTPROVTRIMBIL
			,MTPROVTRIMHB
			--FIN LFD
		   )
			  (
--				(SELECT o.DT_ARRETE,
--			  rs.CD_CONSO_CPT_CRRV3,
--			  t.id_tiers,
--			  tt.id_tiers_calc,
--			  t.ident_siris,
--			  -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--				/*
--		substr(TT.ID_TIERS_CALC,4,11) || substr(rs.CD_CONSO_CPT_CRRV3,3,10) ||
--				--  CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
--				--  WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
--				--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
--				--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END  
--				-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
--				CASE WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')         THEN 'NA012'
--				 WHEN t.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
--				 WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
--				 WHEN t.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
--				END
--				||
--				   'NAT07'||CASE WHEN t.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END
--				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
--          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
--				  case when
--				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
--						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
--						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
--				  WHEN
--				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
--						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
--						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
--				  ELSE '0'
--				  END
--				  */
--				  P5.ID_AUTORISATION,
--				  -- FIN LFD
--			  --o.ID_OPERATION,
--		  null,
--			  o.ID_OPERATION,
--			  'S', --CD_NAT_DEPRE
--			  'P', --CD_PERIM_PROV
--			  (nvl(o.MNT_PROV_CRD,0)+nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)), --MNT_PROVISION --SIRL-576
--			  --(nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)), --+nvl(o.MNT_PROV_CRD,0)+nvl(o.MNT_PROV_SOLD_IRE,0)
--	  --MODIF 16/11/2015                -   (nvl(o.MNT_REPRISE_SOLD_LOY_K,0)+nvl(o.MNT_REPRISE_SOLD_AUT,0)+nvl(o.MNT_REPRISE_SOLD_LOY_I,0)), -- +nvl(o.MNT_REPRISE_CRD,0)+nvl(o.MNT_REPRISE_SOLD_IRE,0)
--			  0,
--			  o.CD_DEVISE,
--			  CD_PCEC_K_A_I_PROV,
--			  'O'
--			  ,'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
--			  --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			,IFRSB.MTPROVBIL MTPROVBIL
--			,null MTPROVHB
--			,IFRSB.MTPROVTRIMBIL MTPROVTRIMBIL
--			,null MTPROVTRIMHB
--			--FIN LFD
--		   FROM BTR_OPERATION o,
--			BTR_TIERS t,
--			TIE_TIERS_C1_C5 tt,
--			RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
--			btr_hors_bilan hb,
--			RS_SOCIETE_JURIDIQUE rs,
--			(SELECT id_operation,cd_sys_int,id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV FROM -- 33s
--			   (SELECT o.CD_SYS_INT,o.ID_OPERATION,
--				CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END cd_statut_act,  --43378
--				so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--				FROM btr_operation o, --btr_surete_reelle sr,
--				rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--				 (SELECT cd_sys_int,id_operation,
--				min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--				FROM btr_surete_reelle
--				GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
--				WHERE sr.ID_OPERATION = o.ID_OPERATION
--				AND sr.CD_SYS_INT  = o.CD_SYS_INT
--				AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
--				AND o.ID_TIERS = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				AND so.CD_PHASE = 'APCDE'
--				AND o.CD_PRODUIT NOT IN ('CRED','CREN')
--				-- AJOUT SIRL-576
--				UNION				
--				SELECT o.CD_SYS_INT, o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--							 FROM btr_operation o,
--											 rs_statut_ope so,
--											 btr_tiers T,
--											 RS_CORRES_SGMT_BAL_TYPE_CLI rs
--							 WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
--							   AND o.ID_TIERS = T.ID_TIERS
--							   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--							   AND so.CD_PHASE = 'APCDE'
--							   and not exists (SELECT 1
--												 FROM
--																 rs_statut_ope so,
--																 btr_tiers T,
--																 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--																 (SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--																 FROM btr_surete_reelle
--																 GROUP BY cd_sys_int, id_operation
--																 ) sr 
--												 WHERE sr.ID_OPERATION  = o.ID_OPERATION
--												   AND sr.CD_SYS_INT    = o.CD_SYS_INT
--												   AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
--												   AND o.ID_TIERS       = T.ID_TIERS
--												   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--												   AND so.CD_PHASE      = 'APCDE'
--												   AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
--				-- AJOUT SIRL-576				
--				UNION
--				SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
--				WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
--				AND o.ID_TIERS = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				AND so.CD_PHASE = 'APCDE'
--				AND o.CD_PRODUIT IN ('CRED','CREN')
--		  and not exists (SELECT 1
--			  FROM
--				 rs_statut_ope so,
--				 btr_tiers T,
--				 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--				(SELECT cd_sys_int, id_operation, min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--				 FROM btr_surete_reelle
--				 GROUP BY cd_sys_int, id_operation
--				) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
--			  WHERE sr.ID_OPERATION  = o.ID_OPERATION
--				AND sr.CD_SYS_INT    = o.CD_SYS_INT
--				AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
--				AND o.ID_TIERS       = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
--				AND so.CD_PHASE      = 'APCDE'
--				--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
--				AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
--		  ) perim,
--			   rs_corres_pcec pc
--			 WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
--			 AND perim.CD_PHASE = pc.CD_PHASE
--			 AND perim.CD_PRODUIT = pc.CD_PRODUIT
--			 AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
--			 AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
--			UNION
--			 SELECT id_operation,cd_sys_int,o.id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV
--			 FROM btr_operation o,
--														  btr_tiers t,
--														  RS_CORRES_SGMT_BAL_TYPE_CLI rsc,rs_statut_ope so, rs_corres_pcec pc
--			 WHERE o.cd_statut_ope = so.CD_STATUT_OPE
--													  and t.id_tiers=o.id_tiers
--													  AND   T.cd_segment_cal=rsc.cd_segment_cal
--													  and rsc.cd_type_cli=pc.cd_type_cli
--			 AND so.CD_PHASE = 'CDE'
--			 AND pc.CD_PHASE = so.CD_PHASE) pcec
--			,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--			--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			, (SELECT SUM(MT_PROV_FIN_PERIOD) MTPROVBIL, SUM(MT_PROV_FIN_TRI_PREC) MTPROVTRIMBIL, ID_ENGAGEMENT 
--				FROM ANNEXE_IFRS WHERE IND_BILAN = 'B' AND BUCK_FIN_PERIOD = 'B3'
--				GROUP BY ID_ENGAGEMENT, IND_BILAN, BUCK_FIN_PERIOD) IFRSB
--			-- FIN LFD
--		   WHERE t.ID_TIERS     = o.ID_TIERS
--		   and   t.id_tiers     = tt.id_tiers
--		   and   o.id_operation = pcec.id_operation
--		   AND   o.CD_PRODUIT    = pf.CD_PRODUIT
--		   and   o.cd_sys_int   = pcec.cd_sys_int
--		   AND   o.CD_SYS_INT = hb.cd_sys_int (+)
--		   AND   o.ID_OPERATION = hb.id_operation (+)
--		   and   o.id_tiers     = pcec.id_tiers
--		   and   t.cd_role_tiers = 'C'
--		   and   tt.cd_type_relation = 'C'
--		   AND   rs.CD_SOC_JURI = o.CD_SOC_JURI
--		   AND   rs.CD_CONSO_CPT_CRRV3 != '99999'
--		   AND T.CD_TYPE_SGMT        = 'RETA'
--		   and (nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)) !=0 
--							   -- - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0)+nvl(o.MNT_REPRISE_SOLD_AUT,0)+nvl(o.MNT_REPRISE_SOLD_LOY_I,0)) !=0
--		   and not exists (select null from HIS_PROVISIONS_DECOTES_P9 h
--				   where o.ID_TIERS       = h.ID_TIERS
--				   AND o.ID_OPERATION   = h.ID_ENGAGEMENT
--				   and rs.CD_CONSO_CPT_CRRV3= h.CD_CONSO_CPT
--				   AND trunc(o.dt_arrete, 'Q')-1 = h.DT_ARRETE) --ok
--			 AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--			 AND 	rs.CD_CONSO_CPT_CRRV3 = P5.CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
--		   AND	o.id_operation = IFRSB.id_engagement (+) --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			 )
--		   union
--		   --
--		   SELECT o.DT_ARRETE,
--			  rs.CD_CONSO_CPT_CRRV3,
--			  t.id_tiers,
--			  tt.id_tiers_calc,
--			  t.ident_siris,
--			-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--				/*
--		  substr(TT.ID_TIERS_CALC,4,11) || substr(rs.CD_CONSO_CPT_CRRV3,3,10) ||
--				--CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
--				--WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
--				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
--				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END  
--				-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
--				CASE WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')         THEN 'NA012'
--				WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
--				WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
--				WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
--				END
--				||
--				   'NAT07'||CASE WHEN t.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END
--				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
--          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
--				  case when
--				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
--						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
--						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
--				  WHEN
--				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
--						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
--						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
--				  ELSE '0'
--				  END
--				  */				
--				P5.ID_AUTORISATION,
--				-- FIN LFD
--			  --o.ID_OPERATION,
--		  null,
--			  o.ID_OPERATION,
--			  'S', --CD_NAT_DEPRE
--			  'P', --CD_PERIM_PROV			  
--			  (nvl(o.MNT_PROV_CRD,0)+nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)), --MNT_PROVISION --SIRL-576
--			  0,
--			  o.CD_DEVISE,
--			  CD_PCEC_CRD_PROV,
--			  'O'
--			  ,'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
--			  --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			,IFRSB.MTPROVBIL MTPROVBIL
--			,null MTPROVHB
--			,IFRSB.MTPROVTRIMBIL MTPROVTRIMBIL
--			,null MTPROVTRIMHB
--			--FIN LFD
--		   FROM BTR_OPERATION o,
--			BTR_TIERS t,
--			TIE_TIERS_C1_C5 tt,
--			RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
--			btr_hors_bilan hb,
--			RS_SOCIETE_JURIDIQUE rs,
--			 (SELECT id_operation,cd_sys_int,id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV FROM -- 33s
--			   (SELECT o.CD_SYS_INT,o.ID_OPERATION,
--				CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END cd_statut_act,  --43378
--				so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--				FROM btr_operation o, --btr_surete_reelle sr,
--				rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--				 (SELECT cd_sys_int,id_operation,
--				min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--				FROM btr_surete_reelle
--				GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
--				WHERE sr.ID_OPERATION = o.ID_OPERATION
--				AND sr.CD_SYS_INT  = o.CD_SYS_INT
--				AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
--				AND o.ID_TIERS = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				AND so.CD_PHASE = 'APCDE'
--				AND o.CD_PRODUIT NOT IN ('CRED','CREN')
--				-- AJOUT SIRL-576
--				UNION
--				SELECT o.CD_SYS_INT, o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT 
--							 FROM btr_operation o,
--											 rs_statut_ope so,
--											 btr_tiers T,
--											 RS_CORRES_SGMT_BAL_TYPE_CLI rs
--							 WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
--							   AND o.ID_TIERS = T.ID_TIERS
--							   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--							   AND so.CD_PHASE = 'APCDE'
--							   and not exists (SELECT 1
--												 FROM
--																 rs_statut_ope so,
--																 btr_tiers T,
--																 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--																 (SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--																 FROM btr_surete_reelle
--																 GROUP BY cd_sys_int, id_operation
--																 ) sr 
--												 WHERE sr.ID_OPERATION  = o.ID_OPERATION
--												   AND sr.CD_SYS_INT    = o.CD_SYS_INT
--												   AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
--												   AND o.ID_TIERS       = T.ID_TIERS
--												   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--												   AND so.CD_PHASE      = 'APCDE'
--												   AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
--				-- AJOUT SIRL-576	
--				UNION
--				SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
--				WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
--				AND o.ID_TIERS = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				AND so.CD_PHASE = 'APCDE'
--				AND o.CD_PRODUIT IN ('CRED','CREN')
--				and not exists (SELECT 1
--			  FROM
--				 rs_statut_ope so,
--				 btr_tiers T,
--				 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--				(SELECT cd_sys_int, id_operation,min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--				 FROM btr_surete_reelle
--				 GROUP BY cd_sys_int, id_operation
--				) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
--			  WHERE sr.ID_OPERATION  = o.ID_OPERATION
--				AND sr.CD_SYS_INT    = o.CD_SYS_INT
--				AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
--				AND o.ID_TIERS       = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
--				AND so.CD_PHASE      = 'APCDE'
--				--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
--				AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))) perim,
--			   rs_corres_pcec pc
--			 WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
--			 AND perim.CD_PHASE = pc.CD_PHASE
--			 AND perim.CD_PRODUIT = pc.CD_PRODUIT
--			 AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
--			 AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
--			UNION
--			 SELECT id_operation,cd_sys_int,o.id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV
--			 FROM btr_operation o,
--														  btr_tiers t,
--														  RS_CORRES_SGMT_BAL_TYPE_CLI rsc,rs_statut_ope so, rs_corres_pcec pc
--			 WHERE o.cd_statut_ope = so.CD_STATUT_OPE
--													  and t.id_tiers=o.id_tiers
--													  AND   T.cd_segment_cal=rsc.cd_segment_cal
--													  and rsc.cd_type_cli=pc.cd_type_cli
--			 AND so.CD_PHASE = 'CDE'
--			 AND pc.CD_PHASE = so.CD_PHASE) pcec
--			,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO 
--			--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			, (SELECT SUM(MT_PROV_FIN_PERIOD) MTPROVBIL, SUM(MT_PROV_FIN_TRI_PREC) MTPROVTRIMBIL, ID_ENGAGEMENT 
--				FROM ANNEXE_IFRS WHERE IND_BILAN = 'B' AND BUCK_FIN_PERIOD = 'B3'
--				GROUP BY ID_ENGAGEMENT, IND_BILAN, BUCK_FIN_PERIOD) IFRSB
--			-- FIN LFD
--		   wHERE t.ID_TIERS     = o.ID_TIERS
--		   and   t.id_tiers     = tt.id_tiers
--		   and   o.id_operation = pcec.id_operation
--		   and   o.cd_sys_int   = pcec.cd_sys_int
--		   and   o.id_tiers     = pcec.id_tiers
--		   AND   o.CD_SYS_INT = hb.cd_sys_int (+)
--		   AND   o.ID_OPERATION = hb.id_operation (+)
--		   AND   o.CD_PRODUIT    = pf.CD_PRODUIT
--		   and   t.cd_role_tiers = 'C'
--		   and   tt.cd_type_relation = 'C'
--		   AND   rs.CD_SOC_JURI = o.CD_SOC_JURI
--		   AND   rs.CD_CONSO_CPT_CRRV3 != '99999'
--		   AND T.CD_TYPE_SGMT        = 'RETA'
--		   and (nvl(o.MNT_PROV_CRD,0) ) !=0     --MODIF 16/11/15 - nvl(o.MNT_REPRISE_CRD,0)
--		   and not exists (select null from HIS_PROVISIONS_DECOTES_P9 h
--				   where o.ID_TIERS       = h.ID_TIERS
--				   AND o.ID_OPERATION   = h.ID_ENGAGEMENT
--				   and rs.CD_CONSO_CPT_CRRV3= h.CD_CONSO_CPT
--				   AND trunc(o.dt_arrete, 'Q')-1 = h.DT_ARRETE)
--		   AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--		   AND 	rs.CD_CONSO_CPT_CRRV3 = P5.CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
--		   AND	o.id_operation = IFRSB.id_engagement (+) --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--		   union
		   --
		   SELECT o.DT_ARRETE,
			  rs.CD_CONSO_CPT_CRRV3,
			  t.id_tiers,
			  tt.id_tiers_calc,
			  t.ident_siris,
			  -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
				/*
		  substr(TT.ID_TIERS_CALC,4,11) || substr(rs.CD_CONSO_CPT_CRRV3,3,10) ||
				--  CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
				--  WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
				--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
				--  WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021'  END  
				-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
				CASE WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')         THEN 'NA012'
				WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
				WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
				WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
				END
				  ||
				   'NAT07'||CASE WHEN t.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END
				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				  case when
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
				  WHEN
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
				  ELSE '0'
				  END
				  */				
				  P5.ID_AUTORISATION,
				  -- FIN LFD
			  --o.ID_OPERATION,
		  null,
			  o.ID_OPERATION,
			  'S', --CD_NAT_DEPRE
			  'P', --CD_PERIM_PROV	
			  (nvl(o.MNT_PROV_CRD,0)+nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)), --MNT_PROVISION --SIRL-576
			  --(nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)),       --MODIF 16/11/15 - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0)+nvl(o.MNT_REPRISE_SOLD_AUT,0)+nvl(o.MNT_REPRISE_SOLD_LOY_I,0)),
			  Case when (nvl(h.MNT_PROV_SOLD_LOY_K,0)+nvl(h.MNT_PROV_SOLD_AUT,0)+nvl(h.MNT_PROV_SOLD_LOY_I,0)) < 0      --MODIF 16/11/15 - (nvl(h.MNT_REPRISE_SOLD_LOY_K,0)+nvl(h.MNT_REPRISE_SOLD_AUT,0)+nvl(h.MNT_REPRISE_SOLD_LOY_I,0)) < 0
			  then 0
			  else
			  (nvl(h.MNT_PROV_SOLD_LOY_K,0)+nvl(h.MNT_PROV_SOLD_AUT,0)+nvl(h.MNT_PROV_SOLD_LOY_I,0))      --MODIF 16/11/15 - (nvl(h.MNT_REPRISE_SOLD_LOY_K,0)+nvl(h.MNT_REPRISE_SOLD_AUT,0)+nvl(h.MNT_REPRISE_SOLD_LOY_I,0))
			  end,
			  o.CD_DEVISE,
			  CD_PCEC_K_A_I_PROV,
			  'O'
			  ,'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			  --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
			,IFRSB.MTPROVBIL MTPROVBIL
			,null MTPROVHB
			,IFRSB.MTPROVTRIMBIL MTPROVTRIMBIL
			,null MTPROVTRIMHB
			--FIN LFD
		   FROM BTR_OPERATION o,
			BTR_TIERS t,
			TIE_TIERS_C1_C5 tt,
				   RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			btr_hors_bilan hb,
			HIS_PROVISIONS_DECOTES_P9 h,
			RS_SOCIETE_JURIDIQUE rs,
			(SELECT id_operation,cd_sys_int,id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV FROM -- 33s
			   (SELECT o.CD_SYS_INT,o.ID_OPERATION,
				CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END cd_statut_act,  --43378
				so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
				FROM btr_operation o, --btr_surete_reelle sr,
				rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				 (SELECT cd_sys_int,id_operation,
				min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
				FROM btr_surete_reelle
				GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
				WHERE sr.ID_OPERATION = o.ID_OPERATION
				AND sr.CD_SYS_INT  = o.CD_SYS_INT
				AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
				AND o.ID_TIERS = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				AND so.CD_PHASE = 'APCDE'
				AND o.CD_PRODUIT NOT IN ('CRED','CREN')
				-- AJOUT SIRL-576
				UNION
				SELECT o.CD_SYS_INT, o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT 
							 FROM btr_operation o,
											 rs_statut_ope so,
											 btr_tiers T,
											 RS_CORRES_SGMT_BAL_TYPE_CLI rs
							 WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
							   AND o.ID_TIERS = T.ID_TIERS
							   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
							   AND so.CD_PHASE = 'APCDE'
							   and not exists (SELECT 1
												 FROM
																 rs_statut_ope so,
																 btr_tiers T,
																 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
																 (SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
																 FROM btr_surete_reelle
																 GROUP BY cd_sys_int, id_operation
																 ) sr 
												 WHERE sr.ID_OPERATION  = o.ID_OPERATION
												   AND sr.CD_SYS_INT    = o.CD_SYS_INT
												   AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
												   AND o.ID_TIERS       = T.ID_TIERS
												   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
												   AND so.CD_PHASE      = 'APCDE'
												   AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
				-- AJOUT SIRL-576	
				UNION
				SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
				WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
				AND o.ID_TIERS = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				AND so.CD_PHASE = 'APCDE'
				AND o.CD_PRODUIT IN ('CRED','CREN')
		  and not exists (SELECT 1
			  FROM
				 rs_statut_ope so,
				 btr_tiers T,
				 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
				(SELECT cd_sys_int, id_operation, min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
				 FROM btr_surete_reelle
				 GROUP BY cd_sys_int, id_operation
				) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
			  WHERE sr.ID_OPERATION  = o.ID_OPERATION
				AND sr.CD_SYS_INT    = o.CD_SYS_INT
				AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
				AND o.ID_TIERS       = T.ID_TIERS
				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
				--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
				AND so.CD_PHASE      = 'APCDE'
				--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
				AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))) perim,
			   rs_corres_pcec pc
			 WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
			 AND perim.CD_PHASE = pc.CD_PHASE
			 AND perim.CD_PRODUIT = pc.CD_PRODUIT
			 AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
			 AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
			UNION
			 SELECT id_operation,cd_sys_int,o.id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV
			 FROM btr_operation o,
														  btr_tiers t,
														  RS_CORRES_SGMT_BAL_TYPE_CLI rsc,rs_statut_ope so, rs_corres_pcec pc
			 WHERE o.cd_statut_ope = so.CD_STATUT_OPE
			  AND so.CD_PHASE = 'CDE'
              and t.id_tiers=o.id_tiers
              AND   T.cd_segment_cal=rsc.cd_segment_cal
              and rsc.cd_type_cli=pc.cd_type_cli
			  AND pc.CD_PHASE = so.CD_PHASE) pcec
			  ,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			  --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
				, (SELECT SUM(MT_PROV_FIN_PERIOD) MTPROVBIL, SUM(MT_PROV_FIN_TRI_PREC) MTPROVTRIMBIL, ID_ENGAGEMENT 
					FROM ANNEXE_IFRS WHERE IND_BILAN = 'B' AND BUCK_FIN_PERIOD = 'B3'
					GROUP BY ID_ENGAGEMENT, IND_BILAN, BUCK_FIN_PERIOD) IFRSB
				-- FIN LFD
		   WHERE t.ID_TIERS     = o.ID_TIERS
		   and   t.id_tiers     = tt.id_tiers
		   and   o.id_operation = pcec.id_operation
		   and   o.cd_sys_int   = pcec.cd_sys_int
		   and   o.id_tiers     = pcec.id_tiers
		   and   t.cd_role_tiers = 'C'
		   and   tt.cd_type_relation = 'C'
           AND   o.CD_SYS_INT = hb.cd_sys_int (+)
		   AND   o.ID_OPERATION = hb.id_operation (+)
		   AND   o.CD_PRODUIT    = pf.CD_PRODUIT
		   AND   rs.CD_SOC_JURI = o.CD_SOC_JURI
		   AND   o.ID_TIERS       = h.ID_TIERS
		   and   rs.CD_CONSO_CPT_CRRV3= h.CD_CONSO_CPT
		   and   h.CD_CONSO_CPT = tt.CD_CONSO_CPT
		   AND   o.ID_OPERATION   = h.ID_ENGAGEMENT
		   AND   trunc(o.dt_arrete, 'Q')-1 = h.DT_ARRETE
		   AND   rs.CD_CONSO_CPT_CRRV3 != '99999'
		   AND   T.CD_TYPE_SGMT        = 'RETA'
		   --AND ((nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0))) !=0
		   AND ((nvl(o.MNT_PROV_CRD,0)+nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0))) !=0
		   --AND (Case when (nvl(h.MNT_PROV_SOLD_LOY_K,0)+nvl(h.MNT_PROV_SOLD_AUT,0)+nvl(h.MNT_PROV_SOLD_LOY_I,0)) < 0
		   AND (Case when (nvl(o.MNT_PROV_CRD,0)+nvl(h.MNT_PROV_SOLD_LOY_K,0)+nvl(h.MNT_PROV_SOLD_AUT,0)+nvl(h.MNT_PROV_SOLD_LOY_I,0)) < 0
			  then 0
			  else
			  --(nvl(h.MNT_PROV_SOLD_LOY_K,0)+nvl(h.MNT_PROV_SOLD_AUT,0)+nvl(h.MNT_PROV_SOLD_LOY_I,0))
			  (nvl(o.MNT_PROV_CRD,0)+nvl(h.MNT_PROV_SOLD_LOY_K,0)+nvl(h.MNT_PROV_SOLD_AUT,0)+nvl(h.MNT_PROV_SOLD_LOY_I,0))
			  end) !=0
		   AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
		   AND 	rs.CD_CONSO_CPT_CRRV3 = P5.CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
		   AND	o.id_operation = IFRSB.id_engagement (+) --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--		  union
--		  --
--		   SELECT o.DT_ARRETE,
--			  rs.CD_CONSO_CPT_CRRV3,
--			  t.id_tiers,
--			  tt.id_tiers_calc,
--			  t.ident_siris,
--		null,
--		null,
--		-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--				/*
--		  substr(TT.ID_TIERS_CALC,4,11) || substr(rs.CD_CONSO_CPT_CRRV3,3,10) ||
--				--CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
--				--WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
--				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
--				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END 
--				-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
--				  CASE WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')         THEN 'NA012'
--				   WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
--				   WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
--				   WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
--				  END 
--				  ||
--				   'NAT07'||CASE WHEN t.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END
--				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
--          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
--				  case when
--				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
--						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
--						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
--				  WHEN
--				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
--						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
--						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
--				  ELSE '0'
--				  END
--				  */				
--			   P5.ID_AUTORISATION,
--			   -- FIN LFD
--		--o.ID_OPERATION,
--		--o.ID_OPERATION, 
--			  'S', --CD_NAT_DEPRE
--			  'P', --CD_PERIM_PROV	
--			  (nvl(o.MNT_PROV_CRD,0)+nvl(o.MNT_PROV_SOLD_LOY_K,0)+nvl(o.MNT_PROV_SOLD_AUT,0)+nvl(o.MNT_PROV_SOLD_LOY_I,0)), --MNT_PROVISION --SIRL-576			  
--			  --(nvl(o.MNT_PROV_CRD,0)) ,       -- MODIF 16/11/15 - nvl(o.MNT_REPRISE_CRD,0)),
--			  Case when (nvl(h.MNT_PROV_CRD,0)) < 0     -- MODIF 16/11/15 -nvl(h.MNT_REPRISE_CRD,0)) < 0
--			  then 0
--			  else
--			  (nvl(h.MNT_PROV_CRD,0))         -- MODIF 16/11/15< 0-nvl(h.MNT_REPRISE_CRD,0))
--			  end,
--			  o.CD_DEVISE,
--			  CD_PCEC_CRD_PROV,
--			  'O'
--			  ,'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
--			  --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			,IFRSB.MTPROVBIL MTPROVBIL
--			,null MTPROVHB
--			,IFRSB.MTPROVTRIMBIL MTPROVTRIMBIL
--			,null MTPROVTRIMHB
--			--FIN LFD
--		   FROM BTR_OPERATION o,
--			BTR_TIERS t,
--			TIE_TIERS_C1_C5 tt,
--			HIS_PROVISIONS_DECOTES_P9 h,
--					RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
--			btr_hors_bilan hb,
--			RS_SOCIETE_JURIDIQUE rs,
--			(SELECT id_operation,cd_sys_int,id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV FROM -- 33s
--			   (SELECT o.CD_SYS_INT,o.ID_OPERATION,
--				CASE WHEN sr.CD_STATUT_ACT !=  'ATNL' THEN 'LOUE' ELSE sr.CD_STATUT_ACT END cd_statut_act,  --43378
--				so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--				FROM btr_operation o, --btr_surete_reelle sr,
--				rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--				 (SELECT cd_sys_int,id_operation,
--				min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--				FROM btr_surete_reelle
--				GROUP BY cd_sys_int,id_operation) sr -- AGU 12/01/2009 passage par une sous requ?te pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diff?rents (recette Lot 5.1), on prend d?j? en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
--				WHERE sr.ID_OPERATION = o.ID_OPERATION
--				AND sr.CD_SYS_INT  = o.CD_SYS_INT
--				AND o.CD_STATUT_OPE = so.CD_STATUT_OPE
--				AND o.ID_TIERS = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				AND so.CD_PHASE = 'APCDE'
--				AND o.CD_PRODUIT NOT IN ('CRED','CREN')
--				-- AJOUT SIRL-576
--				UNION
--				SELECT o.CD_SYS_INT, o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT 
--							 FROM btr_operation o,
--											 rs_statut_ope so,
--											 btr_tiers T,
--											 RS_CORRES_SGMT_BAL_TYPE_CLI rs
--							 WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
--							   AND o.ID_TIERS = T.ID_TIERS
--							   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--							   AND so.CD_PHASE = 'APCDE'
--							   and not exists (SELECT 1
--												 FROM
--																 rs_statut_ope so,
--																 btr_tiers T,
--																 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--																 (SELECT cd_sys_int, id_operation,min(cd_statut_act) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--																 FROM btr_surete_reelle
--																 GROUP BY cd_sys_int, id_operation
--																 ) sr 
--												 WHERE sr.ID_OPERATION  = o.ID_OPERATION
--												   AND sr.CD_SYS_INT    = o.CD_SYS_INT
--												   AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
--												   AND o.ID_TIERS       = T.ID_TIERS
--												   AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--												   AND so.CD_PHASE      = 'APCDE'
--												   AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))
--				-- AJOUT SIRL-576	
--				UNION
--				SELECT o.CD_SYS_INT,o.ID_OPERATION,'NA' cd_statut_act,so.CD_PHASE,T.ID_TIERS,rs.CD_TYPE_CLI,T.CD_CATEG_CPT,o.CD_PRODUIT -- 466728
--				FROM btr_operation o, rs_statut_ope so, btr_tiers T,RS_CORRES_SGMT_BAL_TYPE_CLI rs
--				WHERE o.CD_STATUT_OPE = so.CD_STATUT_OPE
--				AND o.ID_TIERS = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				AND so.CD_PHASE = 'APCDE'
--				AND o.CD_PRODUIT IN ('CRED','CREN')
--		  and not exists (SELECT 1
--			  FROM
--				 rs_statut_ope so,
--				 btr_tiers T,
--				 RS_CORRES_SGMT_BAL_TYPE_CLI rs,
--				(SELECT cd_sys_int, id_operation,min(decode(cd_statut_act,'CDNL','ATNL',cd_statut_act)) KEEP (DENSE_RANK FIRST ORDER BY decode(cd_statut_act,'LOUE','1','ATNL','2','AENC','3','CEDE','4','CDNL','5')) cd_statut_act
--				 FROM btr_surete_reelle
--				 GROUP BY cd_sys_int, id_operation
--				) sr -- AGU 12/01/2010 passage par un sous requhte pour enlever les doublons dans le cas ou les operations on plusieurs actifs avec des statuts diffirents (recette Lot 5.1), on prend dij` en compte les satuts autre qye LOUE et ATNL (evolution pour le lot 5.2)
--			  WHERE sr.ID_OPERATION  = o.ID_OPERATION
--				AND sr.CD_SYS_INT    = o.CD_SYS_INT
--				AND o.CD_STATUT_OPE  = so.CD_STATUT_OPE
--				AND o.ID_TIERS       = T.ID_TIERS
--				AND T.CD_SEGMENT_CAL = rs.CD_SEGMENT_CAL
--				--HL 43378 AND sr.cd_statut_act IN ('LOUE','ATNL')
--				AND so.CD_PHASE      = 'APCDE'
--				--HL 43378 AND o.CD_PRODUIT NOT IN ('CRED','CREN')
--				AND o.CD_PRODUIT NOT IN ('CRED', 'CREN', 'SERV'))) perim,
--			   rs_corres_pcec pc
--			 WHERE perim.CD_CATEG_CPT = pc.CD_CATEG_CPT
--			 AND perim.CD_PHASE = pc.CD_PHASE
--			 AND perim.CD_PRODUIT = pc.CD_PRODUIT
--			 AND perim.CD_STATUT_ACT  = pc.CD_STATUT_ACT
--			 AND perim.CD_TYPE_CLI = pc.CD_TYPE_CLI
--			UNION
--			 SELECT id_operation,cd_sys_int,o.id_tiers,cd_pcec_crd,cd_pcec_icne,CD_PCEC_K_A,CD_PCEC_I, CD_PCEC_CRD_PROV, CD_PCEC_K_A_I_PROV
--			 FROM btr_operation o,
--														  btr_tiers t,
--														  RS_CORRES_SGMT_BAL_TYPE_CLI rsc,rs_statut_ope so, rs_corres_pcec pc
--			 WHERE o.cd_statut_ope = so.CD_STATUT_OPE
--              and t.id_tiers=o.id_tiers
--              AND   T.cd_segment_cal=rsc.cd_segment_cal
--              and rsc.cd_type_cli=pc.cd_type_cli
--              AND so.CD_PHASE = 'CDE'
--              AND pc.CD_PHASE = so.CD_PHASE) pcec
--			  ,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--			  --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
--			, (SELECT SUM(MT_PROV_FIN_PERIOD) MTPROVBIL, SUM(MT_PROV_FIN_TRI_PREC) MTPROVTRIMBIL, ID_ENGAGEMENT 
--				FROM ANNEXE_IFRS WHERE IND_BILAN = 'B' AND BUCK_FIN_PERIOD = 'B3'
--				GROUP BY ID_ENGAGEMENT, IND_BILAN, BUCK_FIN_PERIOD) IFRSB
--			-- FIN LFD
--		   WHERE t.ID_TIERS     = o.ID_TIERS
--		   and   t.id_tiers     = tt.id_tiers
--		   and   o.id_operation = pcec.id_operation
--		   and   o.cd_sys_int   = pcec.cd_sys_int
--		   and   o.id_tiers     = pcec.id_tiers
--		   and   t.cd_role_tiers = 'C'
--		   and   tt.cd_type_relation = 'C'
--		   AND   rs.CD_SOC_JURI = o.CD_SOC_JURI
--		   AND   o.CD_SYS_INT = hb.cd_sys_int (+)
--		   AND   o.ID_OPERATION = hb.id_operation (+)
--		   AND   o.CD_PRODUIT    = pf.CD_PRODUIT
--		   AND   o.ID_TIERS       = h.ID_TIERS
--		   and   rs.CD_CONSO_CPT_CRRV3= h.CD_CONSO_CPT
--		   and   h.CD_CONSO_CPT = tt.CD_CONSO_CPT
--		   AND   o.ID_OPERATION   = h.ID_ENGAGEMENT
--		   AND   trunc(o.dt_arrete, 'Q')-1 = h.DT_ARRETE
--		   AND   rs.CD_CONSO_CPT_CRRV3 != '99999'
--		   AND   T.CD_TYPE_SGMT        = 'RETA'
--		   AND (nvl(o.MNT_PROV_CRD,0)) !=0        --MODIF 16/11/2015 - nvl(o.MNT_REPRISE_CRD,0))
--		   AND (Case when (nvl(h.MNT_PROV_CRD,0)) < 0   --MODIF 16/11/2015 -nvl(h.MNT_REPRISE_CRD,0))
--			  then 0
--			  else
--			  (nvl(h.MNT_PROV_CRD,0))       --MODIF 16/11/2015 -nvl(h.MNT_REPRISE_CRD,0))
--			  end) !=0
--		   AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
--		   AND 	rs.CD_CONSO_CPT_CRRV3 = P5.CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
--		   AND	o.id_operation = IFRSB.id_engagement (+) --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
		   )
		   ;

		   COMMIT;

			-- DEBUT :: M67006 - spec 2.6.1
			---- 15/06/201 - CDS ATOS (LFD) - US 43 MCO
			---- maj des donnees concernant les buckets 1 et 2
			---- perimetre bilan
		    W_TABLE := 'PROVISIONS_DETAIL_P8 (3) - BILAN';
			merge
			 into provisions_detail_p8 p8
			using (select
			          p5.dt_arrete                           DT_ARRETE
					, p5.cd_conso_cpt                        CD_CONSO_CPT
					, p5.id_tiers                            ID_TIERS
					, p5.id_tiers_calc                       ID_TIERS_CALC
					, p5.id_central_tiers                    ID_CENTRAL_TIERS
					, p5.id_autorisation                     ID_AUTORISATION
					, null                                   ID_LIGNE_DET
					, p5.id_engagement                       ID_ENGAGEMENT
					, max(case
					      when upper(gr05.bucket_ecl) = 'STAGE1'
					      then 'A'
					      else 'E'
					       end)                              CD_NAT_DEPRE
					, 'P'                                    CD_PERIM_PROV
					, sum(nvl(gr05.mnt_ecl,0))               MNT_PROVISION
					, 0                                      MNT_PROVISION_TRIM
					, gr05.cd_devise                         CD_DEVISE
					, case
					  when p5.cd_type_risque = 'PRI103'
					  then case
						   when p5.bucket_ifrs9 = 'B1'
						   then 'A5290200'
						   else 'A5290210'
							end
					  when p5.cd_type_risque = 'PRI105'
					  then case
						   when p5.bucket_ifrs9 = 'B1'
						   then 'A5290400'
						   else 'A5290410'
							end
					  when p5.cd_type_risque = 'TRE504'
					  then case
						   when p5.bucket_ifrs9 = 'B1'
						   then 'A5199200'
						   else 'A5199210'
							end
					  else null
					   end                                   CD_PCCO
					, 'O'                                    A_EXTRAIRE
					, 'PROV01'                               CD_TYPE_PROD_BANCAIRE
					, sum(nvl(gr05.mnt_ecl,0))               MTPROVBIL
					, 0                                      MTPROVHB
					, 0                                      MTPROVTRIMBIL
					, 0                                      MTPROVTRIMHB
				     from
					    eng_retail_detail_p5           p5
					  , tmp_gr05_granulaire            gr05
					  , btr_operation                  bo
					  , btr_tiers                      bt
					  , tie_tiers_c1_c5                c1_c5
					  , rs_societe_juridique           rs
					  , rs_corres_prd_fin_typ_risq_ret cor
				    where p5.id_engagement       = gr05.ref_uniq_ctr
				      and p5.cd_conso_cpt        = gr05.cd_entite
				      and p5.cd_type_risque      = gr05.cd_type_risque
				      and p5.bucket_ifrs9       <> 'B3'
				      and bo.id_operation        = gr05.ref_uniq_ctr
				      and bo.id_tiers            = bt.id_tiers
				      and bt.cd_role_tiers       = 'C'
				      and bt.cd_type_sgmt        = 'RETA'
				      and c1_c5.id_tiers         = bt.id_tiers
				      and c1_c5.cd_conso_cpt     = p5.cd_conso_cpt
				      and c1_c5.cd_type_relation = 'C'
				      and c1_c5.flag_hn          = 'N'
				      and bo.cd_produit          = cor.cd_produit
				      and bo.cd_soc_juri         = rs.cd_soc_juri
				      and rs.cd_conso_cpt_crrv3  = p5.cd_conso_cpt
				      and rs.cd_conso_cpt_crrv3 <> '99999'
				      and p5.top_eng_douteux     = 'N'
				      and gr05.type_segment      = 'RETAIL'
				      and gr05.ind_bilan         = 'BILAN'
				      and upper(gr05.bucket_ecl) in ('STAGE1','STAGE2')
				    group
					   by p5.dt_arrete
					    , p5.cd_conso_cpt
						, p5.id_tiers
						, p5.id_tiers_calc
						, p5.id_central_tiers
						, p5.id_autorisation
						, null
						, p5.id_engagement
						, 'P'
						, 0
						, gr05.cd_devise
						, case
						  when p5.cd_type_risque = 'PRI103'
						  then case
						       when p5.bucket_ifrs9 = 'B1'
							   then 'A5290200'
							   else 'A5290210'
							    end
						  when p5.cd_type_risque = 'PRI105'
						  then case
						       when p5.bucket_ifrs9 = 'B1'
							   then 'A5290400'
							   else 'A5290410'
							    end
						  when p5.cd_type_risque = 'TRE504'
						  then case
						       when p5.bucket_ifrs9 = 'B1'
							   then 'A5199200'
							   else 'A5199210'
							    end
						  else null
						   end
						, 'O'
						, 'PROV01'
                   having sum(nvl(gr05.mnt_ecl,0)) >= 0.01) peri
			   on (p8.cd_conso_cpt  = peri.cd_conso_cpt
			  and  p8.id_engagement = peri.id_engagement
			  and  p8.id_tiers      = peri.id_tiers
			  and  p8.cd_pcco       = peri.cd_pcco)
			 when not matched then
			   insert (
				  dt_arrete
				, cd_conso_cpt
				, id_tiers
				, id_tiers_calc
				, id_central_tiers
				, id_autorisation
				, id_ligne_det
				, id_engagement
                , cd_nat_depre
                , cd_perim_prov
                , mnt_provision
                , mnt_provision_trim
				, cd_devise
				, cd_pcco
				, a_extraire
				, cd_type_prod_bancaire
				, mtprovbil
				, mtprovhb
				, mtprovtrimbil
				, mtprovtrimhb)
			   values
				( peri.dt_arrete
				, peri.cd_conso_cpt
				, peri.id_tiers
				, peri.id_tiers_calc
				, peri.id_central_tiers
				, peri.id_autorisation
				, peri.id_ligne_det
				, peri.id_engagement
				, peri.cd_nat_depre
				, peri.cd_perim_prov
				, peri.mnt_provision
				, peri.mnt_provision_trim
				, peri.cd_devise
				, peri.cd_pcco
				, peri.a_extraire
				, peri.cd_type_prod_bancaire
				, peri.mtprovbil
				, peri.mtprovhb
				, peri.mtprovtrimbil
				, peri.mtprovtrimhb);
			   commit;
			-- FIN :: M67006 - spec 2.6.1

			-- DEBUT :: M67006 - spec 2.6.2
			---- maj des donnees concernant les buckets 1 et 2
			---- perimetre hors bilan
			W_TABLE := 'PROVISIONS_DETAIL_P8 (4) - HORS_BILAN';
			merge
			 into provisions_detail_p8 p8
			using (select
			          p5.dt_arrete                           DT_ARRETE
					, p5.cd_conso_cpt                        CD_CONSO_CPT
					, p5.id_tiers                            ID_TIERS
					, p5.id_tiers_calc                       ID_TIERS_CALC
					, p5.id_central_tiers                    ID_CENTRAL_TIERS
					, p5.id_autorisation                     ID_AUTORISATION
					, null                                   ID_LIGNE_DET
					, p5.id_engagement                       ID_ENGAGEMENT
					, max(case
					      when upper(gr05.bucket_ecl) = 'STAGE1'
					      then 'A'
					      else 'E'
					       end)                              CD_NAT_DEPRE
					, 'P'                                    CD_PERIM_PROV
					, sum(nvl(gr05.mnt_ecl,0))               MNT_PROVISION
					, 0                                      MNT_PROVISION_TRIM
					, gr05.cd_devise                         CD_DEVISE
					, case
					  when p5.cd_type_risque
					    in ('PRI103','PRI105','TRE504')
					  then case
						   when p5.bucket_ifrs9 = 'B1'
						   then '90390000'
						   else '90370000'
							end
					  else null
					   end                                   CD_PCCO
					, 'O'                                    A_EXTRAIRE
					, 'PROV01'                               CD_TYPE_PROD_BANCAIRE
					, 0                                      MTPROVBIL
					, sum(nvl(gr05.mnt_ecl,0))               MTPROVHB
					, 0                                      MTPROVTRIMBIL
					, 0                                      MTPROVTRIMHB
				     from
					    eng_retail_detail_p5           p5
					  , tmp_gr05_granulaire            gr05
					  , btr_operation                  bo
					  , btr_tiers                      bt
					  , tie_tiers_c1_c5                c1_c5
					  , rs_societe_juridique           rs
					  , rs_corres_prd_fin_typ_risq_ret cor
				    where p5.id_engagement       = gr05.ref_uniq_ctr
				      and p5.cd_conso_cpt        = gr05.cd_entite
				      and p5.cd_type_risque      = gr05.cd_type_risque
				      and p5.bucket_ifrs9       <> 'B3'
				      and bo.id_operation        = gr05.ref_uniq_ctr
				      and bo.id_tiers            = bt.id_tiers
				      and bt.cd_role_tiers       = 'C'
				      and bt.cd_type_sgmt        = 'RETA'
				      and c1_c5.id_tiers         = bt.id_tiers
				      and c1_c5.cd_conso_cpt     = p5.cd_conso_cpt
				      and c1_c5.cd_type_relation = 'C'
				      and c1_c5.flag_hn          = 'N'
				      and bo.cd_produit          = cor.cd_produit
				      and bo.cd_soc_juri         = rs.cd_soc_juri
				      and rs.cd_conso_cpt_crrv3  = p5.cd_conso_cpt
				      and rs.cd_conso_cpt_crrv3 <> '99999'
				      and p5.top_eng_douteux     = 'N'
				      and gr05.type_segment      = 'RETAIL'
				      and gr05.ind_bilan         = 'HORS_BILAN'
				      and upper(gr05.bucket_ecl) in ('STAGE1','STAGE2')
				    group
					   by p5.dt_arrete
					    , p5.cd_conso_cpt
						, p5.id_tiers
						, p5.id_tiers_calc
						, p5.id_central_tiers
						, p5.id_autorisation
						, null
						, p5.id_engagement
						, 'P'
						, 0
						, gr05.cd_devise
						, case
						  when p5.cd_type_risque
						    in ('PRI103','PRI105','TRE504')
						  then case
						       when p5.bucket_ifrs9 = 'B1'
							   then '90390000'
							   else '90370000'
							    end
						  else null
						   end
						, 'O'
						, 'PROV01'
			       having sum(nvl(gr05.mnt_ecl,0)) >= 0.01) peri_h
			   on (p8.cd_conso_cpt  = peri_h.cd_conso_cpt
			  and  p8.id_engagement = peri_h.id_engagement
			  and  p8.id_tiers      = peri_h.id_tiers
			  and  p8.cd_pcco       = peri_h.cd_pcco)
			 when not matched then
			   insert (
				  dt_arrete
				, cd_conso_cpt
				, id_tiers
				, id_tiers_calc
				, id_central_tiers
				, id_autorisation
				, id_ligne_det
				, id_engagement
                , cd_nat_depre
                , cd_perim_prov
                , mnt_provision
                , mnt_provision_trim
				, cd_devise
				, cd_pcco
				, a_extraire
				, cd_type_prod_bancaire
				, mtprovbil
				, mtprovhb
				, mtprovtrimbil
				, mtprovtrimhb)
			   values
			    ( peri_h.dt_arrete
				, peri_h.cd_conso_cpt
				, peri_h.id_tiers
				, peri_h.id_tiers_calc
				, peri_h.id_central_tiers
				, peri_h.id_autorisation
				, peri_h.id_ligne_det
				, peri_h.id_engagement
				, peri_h.cd_nat_depre
				, peri_h.cd_perim_prov
				, peri_h.mnt_provision
				, peri_h.mnt_provision_trim
				, peri_h.cd_devise
				, peri_h.cd_pcco
				, peri_h.a_extraire
				, peri_h.cd_type_prod_bancaire
				, peri_h.mtprovbil
				, peri_h.mtprovhb
				, peri_h.mtprovtrimbil
				, peri_h.mtprovtrimhb);
			   commit;
			-- FIN :: M67006 - spec 2.6.2

			/* Debut :: partie effacee **/
		   /*MERGE INTO PROVISIONS_DETAIL_P8 P8
		   USING ( SELECT DISTINCT
				O.DT_ARRETE 	DT_ARRETE
				,rs.CD_CONSO_CPT_CRRV3	CD_CONSO_CPT
				,t.id_tiers	ID_TIERS
				,tt.id_tiers_calc	ID_TIERS_CALC
				, t.ident_siris	ID_CENTRAL_TIERS
				, P5.ID_AUTORISATION	ID_AUTORISATION
				,null 	ID_LIGNE_DET
				, O.ID_OPERATION	ID_ENGAGEMENT
				,CASE WHEN IFRS.BUCK_FIN_PERIOD = 'B1'
					THEN 'A' ELSE
						(CASE WHEN IFRS.BUCK_FIN_PERIOD = 'B2' THEN 'E' END)
				END CD_NAT_DEPRE
				, 'P' CD_PERIM_PROV
				,IFRS.MT_PROV_FIN_PERIOD MNT_PROVISION
				,IFRS.MT_PROV_FIN_TRI_PREC MNT_PROVISION_TRIM
				,IFRS.DEVISE_EXPOSITION CD_DEVISE
				,IFRS.PCCO_CRD CD_PCCO
				,'O' A_EXTRAIRE
				,'PROV01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
				,IFRSB.MTPROVBIL MTPROVBIL
				,IFRSH.MTPROVHB MTPROVHB
				,IFRSB.MTPROVTRIMBIL MTPROVTRIMBIL
				,IFRSH.MTPROVTRIMHB MTPROVTRIMHB
				--FIN LFD
		   FROM
				(SELECT * FROM ANNEXE_IFRS WHERE (NVL(MT_PROV_FIN_TRI_PREC,0) > 0 OR  NVL(MT_PROV_FIN_PERIOD,0) > 0) AND BUCK_FIN_PERIOD in ('B1', 'B2')) IFRS
				, (SELECT ID_ENGAGEMENT, ID_TIERS, CD_TYPE_RISQUE, ID_AUTORISATION, CD_CONSO_CPT FROM ENG_RETAIL_DETAIL_P5 WHERE BUCKET_IFRS9 <> 'B3') P5
				, BTR_OPERATION O
				, BTR_TIERS t
				, TIE_TIERS_C1_C5 tt
				, RS_CORRES_PRD_FIN_TYP_RISQ_RET pf
				, RS_SOCIETE_JURIDIQUE rs
				--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
				, (SELECT BUCK_FIN_PERIOD, SUM(MT_PROV_FIN_PERIOD) MTPROVBIL, SUM(MT_PROV_FIN_TRI_PREC) MTPROVTRIMBIL, ID_ENGAGEMENT
				FROM ANNEXE_IFRS WHERE IND_BILAN = 'B'
				GROUP BY ID_ENGAGEMENT, IND_BILAN, BUCK_FIN_PERIOD) IFRSB
				, (SELECT BUCK_FIN_PERIOD, SUM(MT_PROV_FIN_PERIOD) MTPROVHB, SUM(MT_PROV_FIN_TRI_PREC) MTPROVTRIMHB, ID_ENGAGEMENT
				FROM ANNEXE_IFRS WHERE IND_BILAN = 'H'
				GROUP BY ID_ENGAGEMENT, IND_BILAN, BUCK_FIN_PERIOD) IFRSH
				-- FIN LFD
		   WHERE
							P5.ID_ENGAGEMENT 				= IFRS.ID_ENGAGEMENT
				AND 	P5.ID_TIERS 						= IFRS.ID_TIERS
				AND 	P5.CD_TYPE_RISQUE			 	= IFRS.CD_TYPE_RISQUE
				AND 	o.ID_OPERATION 					= IFRS.ID_ENGAGEMENT
				AND 	O.ID_TIERS 							= IFRS.ID_TIERS
				AND 	t.ID_TIERS     						= o.ID_TIERS
				AND 	t.id_tiers    							= tt.id_tiers
				AND   	o.CD_PRODUIT    					= pf.CD_PRODUIT
				AND   	t.cd_role_tiers 						= 'C'
				AND   	tt.cd_type_relation 				= 'C'
				AND   	rs.CD_SOC_JURI 					= o.CD_SOC_JURI
				AND   	rs.CD_CONSO_CPT_CRRV3 	!= '99999'
				AND 	T.CD_TYPE_SGMT        			= 'RETA'
				AND 	IFRSB.ID_ENGAGEMENT = O.ID_OPERATION (+)
				AND		IFRSH.ID_ENGAGEMENT = O.ID_OPERATION (+)
				AND		IFRSB.BUCK_FIN_PERIOD = IFRS.BUCK_FIN_PERIOD
				AND		IFRSH.BUCK_FIN_PERIOD = IFRS.BUCK_FIN_PERIOD
				AND 	rs.CD_CONSO_CPT_CRRV3 = P5.CD_CONSO_CPT -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
		  ) SRC
		 ON ( SRC.CD_CONSO_CPT = P8.CD_CONSO_CPT AND SRC.ID_ENGAGEMENT = P8.ID_ENGAGEMENT AND SRC.ID_TIERS = P8.ID_TIERS AND SRC.CD_PCCO = P8.CD_PCCO)
		 WHEN NOT MATCHED THEN
		   INSERT (
				DT_ARRETE
				,CD_CONSO_CPT
				,ID_TIERS
				,ID_TIERS_CALC
				,ID_CENTRAL_TIERS
				,ID_AUTORISATION
				,ID_LIGNE_DET
				,ID_ENGAGEMENT
				,CD_NAT_DEPRE
				,CD_PERIM_PROV
				,MNT_PROVISION
				,MNT_PROVISION_TRIM
				,CD_DEVISE
				,CD_PCCO
				,A_EXTRAIRE
				,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
				,MTPROVBIL
				,MTPROVHB
				,MTPROVTRIMBIL
				,MTPROVTRIMHB
				--FIN LFD
				)
			VALUES (
				SRC.DT_ARRETE
				,SRC.CD_CONSO_CPT
				,SRC.ID_TIERS
				,SRC.ID_TIERS_CALC
				,SRC.ID_CENTRAL_TIERS
				,SRC.ID_AUTORISATION
				,SRC.ID_LIGNE_DET
				,SRC.ID_ENGAGEMENT
				,SRC.CD_NAT_DEPRE
				,SRC.CD_PERIM_PROV
				,SRC.MNT_PROVISION
				,SRC.MNT_PROVISION_TRIM
				,SRC.CD_DEVISE
				,SRC.CD_PCCO
				,SRC.A_EXTRAIRE
				,SRC.CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				--CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
				,SRC.MTPROVBIL
				,SRC.MTPROVHB
				,SRC.MTPROVTRIMBIL
				,SRC.MTPROVTRIMHB
				--FIN LFD
				);
		   	COMMIT;*/
			/* Fin :: partie effacee **/

		 	-- 27/09/2021 - CDS ATOS (VFN) - M11673 (REWORK US 140)
			W_TABLE := 'PROVISIONS_DETAIL_P8 (5)';
		    UPDATE PROVISIONS_DETAIL_P8
		       SET MTPROVBIL     = MNT_PROVISION
			     , MTPROVHB      = 0
				 , MTPROVTRIMBIL = MNT_PROVISION_TRIM
				 , MTPROVTRIMHB  = 0
		     WHERE CD_NAT_DEPRE ='S';
		    COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				ROLLBACK;
              	DBMS_OUTPUT.PUT_LINE('Proc p_alim_PROVISIONS_DETAIL_P8 table:' || W_TABLE || ' -MESS:'||SQLERRM);
				pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_PROVISIONS_DETAIL_P8:'||l_position|| ' table:'||W_TABLE,50072);
		END p_alim_PROVISIONS_DETAIL_P8;

	  -----------------------------------------------------------
	  -- nom : procedure p_alim_aut_cor_ope_num_dec_bis        --
	  -- but : Alimentation de la table cible envoi CRRV3      --
	  -- auteur : H. BOUCHER, le 22/03/2011                    --
	  -- entr?e : /                                            --
	  -- retour : Alimentation table AUT_COR_OPE_NUM_DEC_BIS   --
	  -- Modification:                                         --
	  ------------------------------------------------------------
	  PROCEDURE p_alim_aut_cor_ope_num_dec_bis IS

		-- MBO - 09052011 : Cette table va definir le perimetre des autorisations Autorisation_F1 (non techniques)
		--  On prend les dossiers tel que NUM_DEC est NON NULL et compter Nbre operation en commun pour chaque NUM_DEC
		-- On ajoute (apres traitement curseur) les dossiers KSP en CDE (avec valeur ID_OPERATION pour NUM_DEC_Bis)

		CURSOR cur_OPE_NUM_DEC IS
		 SELECT translate(replace(ope.NUM_DEC, ' ', '.') , '_ /\<>??|(){}[]*&"''$;','---------------------') AS NUM_DEC -- REPLACE_CAR_SPE(ope.NUM_DEC)     AS NUM_DEC
			 ,num.NB_OPE       AS NB_OPE
			 ,ope.ID_OPERATION AS ID_OPERATION
			 ,CD_SYS_INT       AS CD_SYS_INT
		 FROM ( SELECT CD_SYS_INT, ID_OPERATION, NUM_DEC
			FROM BTR_HORS_BILAN
			WHERE NUM_DEC IS NOT NULL
			AND    num_dec <> '327883-a0'
			GROUP BY CD_SYS_INT, ID_OPERATION, NUM_DEC
			) ope,
			( SELECT NUM_DEC, count(NUM_DEC) NB_OPE
			FROM  (SELECT CD_SYS_INT, ID_OPERATION, NUM_DEC
				 FROM BTR_HORS_BILAN
				 WHERE NUM_DEC IS NOT NULL
				 AND    num_dec   <> '327883-a0'
	  --                   AND CD_SYS_INT <> 'KSP'  -- AFR BTR 6.2 le 19/04/2012 : L12-C03 Outil d'instruction CBI (DE CBI)
				) oc
			GROUP BY NUM_DEC
			) num
		 WHERE  ope.NUM_DEC = num.NUM_DEC
		 ORDER BY ope.NUM_DEC, CD_SYS_INT, ope.ID_OPERATION ;

		l_compteur     NUMBER(4);
		l_i            NUMBER(10);
		l_num_dec_bis  VARCHAR2(5);
		l_num_dec      VARCHAR2(10);

	  BEGIN
		BEGIN
		l_i := 0;
		l_compteur := 0;
		l_num_dec := '';
		-- R?initialiser la table de correspondance entre ID_OPERATION et NUM_DEC_BIS ( de la forme NUM_DEC*Incr?ment )
		execute immediate 'TRUNCATE TABLE AUT_COR_OPE_NUM_DEC_BIS';
		-- Parcourir le curseur class? par NUM_DEC
		FOR c IN cur_OPE_NUM_DEC LOOP
		  l_i := l_i + 1;
		  IF c.NUM_DEC != l_num_dec THEN
		   l_compteur:=0; -- A chaque changement de NUM_DEC, on remet le compteur ? z?ro
		  END IF;
		  l_compteur := l_compteur + 1;
		  IF c.NB_OPE > 1 THEN
		   -- Cas de plusieurs op?rations pour un NUM_DEC
		   l_num_dec_bis := '*'||LPAD(TO_CHAR(l_compteur),4,'0');
		   INSERT INTO DDREX.AUT_COR_OPE_NUM_DEC_BIS (CD_SYS_INT, ID_OPERATION, NUM_DEC_BIS)
		   VALUES (c.CD_SYS_INT, c.ID_OPERATION, c.NUM_DEC||l_num_dec_bis );
		  ELSE
		   -- Cas "normal" : 1 seule op?ration pour un NUM_DEC
		   INSERT INTO DDREX.AUT_COR_OPE_NUM_DEC_BIS (CD_SYS_INT, ID_OPERATION, NUM_DEC_BIS)
		   VALUES (c.CD_SYS_INT, c.ID_OPERATION, c.NUM_DEC );
		  END IF;
		  l_num_dec := c.NUM_DEC;
		END LOOP;

		COMMIT;

		EXCEPTION
		  WHEN OTHERS THEN
		  ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('Proc p_alim_aut_cor_ope_num_dec_bis : '||'Indice i='||TO_CHAR(l_i) || ' -MESS:'||SQLERRM);
		  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_aut_cor_ope_num_dec_bis: '||'Indice i='||TO_CHAR(l_i),50072);
		END;

		BEGIN
		INSERT INTO DDREX.AUT_COR_OPE_NUM_DEC_BIS (CD_SYS_INT, ID_OPERATION, NUM_DEC_BIS)
		SELECT HB.CD_SYS_INT,
			   HB.ID_OPERATION,
			   HB.ID_OPERATION -- AFR BTR 6.2 le 19/04/2012 : L12-C03 Outil d'instruction CBI (DE CBI)
			   --NVL(HB.NUM_DEC, HB.ID_OPERATION) -- AFR BTR 6.2 le 19/04/2012 : L12-C03 Outil d'instruction CBI (DE CBI)
		FROM BTR_HORS_BILAN HB,
		   BTR_OPERATION  OP
		WHERE HB.CD_SYS_INT   = OP.CD_SYS_INT
		  AND HB.ID_OPERATION = OP.ID_OPERATION
		  AND HB.NUM_DEC IS NULL   -- MBO BTR 6.2 le 24/04/2012 : L12-C03 Outil d'instruction CBI (DE CBI)
		  AND OP.CD_STATUT_OPE = 'CDE' ;

		COMMIT;

		DBMS_STATS.GATHER_TABLE_STATS('DDREX','AUT_COR_OPE_NUM_DEC_BIS',Estimate_Percent => NULL, CASCADE => TRUE);

		EXCEPTION
		  WHEN OTHERS THEN
		  ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('Proc p_alim_aut_cor_ope_num_dec_bis -MESS:'||SQLERRM);
		  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_aut_cor_ope_num_dec_bis: Ajout_KSP_CDE',50072);
		END;

	  --  begin
	  --    update DDREX.AUT_COR_OPE_NUM_DEC_BIS ndb
	  --    set (ndb.cd_sys_int, ndb.id_operation ) = (select cd_sys_int_sig, id_operation_sig
	  --                                               from ddrex.BTR_HORS_BILAN hb
	  --                                               where hb.cd_sys_int = 'DE'
	  --                                               and hb.id_operation = ndb.id_operation)
	  --    where exists (select null
	  --                  from ddrex.BTR_HORS_BILAN hb1
	  --                  where hb1.cd_sys_int = 'DE'
	  --                  and hb1.id_operation = ndb.id_operation
	  --                  and nvl(hb1.mnt_iec, 0) > 0 );
	  --    COMMIT;

	  --    EXCEPTION
	  --      WHEN OTHERS THEN
	  --        ROLLBACK;
	  --        pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_aut_cor_ope_num_dec_bis:  update ndb ',50072);
	  --  end;
	  END p_alim_aut_cor_ope_num_dec_bis;

	  -----------------------------------------------------------
	  -- nom : procedure p_trait_cd_pays_btr                   --
	  -- but : Traiter les codes pays XX ou YY dans BTR_TIERS  --
	  -- auteur : MBO - 08/11/2011                             --
	  -- entr?e : /                                            --
	  -- retour : MAJ table BTR_TIERS                          --
	  -- Modification:                                         --
	  ------------------------------------------------------------
	  PROCEDURE p_trait_cd_pays_btr IS

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		update BTR_TIERS
		 set CD_PAYS_CONTROLE    = case when CD_PAYS_CONTROLE    in ('XX', 'YY') then NULL else CD_PAYS_CONTROLE    end
		  ,CD_PAYS_RESIDENCE   = case when CD_PAYS_RESIDENCE   in ('XX', 'YY') then NULL else CD_PAYS_RESIDENCE   end
		  ,CD_PAYS_NATIONALITE = case when CD_PAYS_NATIONALITE in ('XX', 'YY') then NULL else CD_PAYS_NATIONALITE end
		  ,CD_PAYS_RISQUE      = case when CD_PAYS_RISQUE      in ('XX', 'YY') then NULL else CD_PAYS_RISQUE      end
		where CD_PAYS_CONTROLE    in ('XX', 'YY')
		 or CD_PAYS_RESIDENCE   in ('XX', 'YY')
		 or CD_PAYS_NATIONALITE in ('XX', 'YY')
		 or CD_PAYS_RISQUE      in ('XX', 'YY') ;

		COMMIT;

		EXCEPTION
		  WHEN OTHERS THEN
		  ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('Proc p_trait_cd_pays_btr table -MESS:'||SQLERRM);
		  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_trait_cd_pays_btr: ', 50072);

	  END p_trait_cd_pays_btr;

	  -------------------------------------------------------------------------------
	  -- nom : Gest_Coherence_IDTCA_inBTR                                          --
	  --                                                                           --
	  -- but : MAJ de ID_TIERS_INT (IDTCA) dans BTR_TIERS a partir du DTG Global   --
	  --       (cette MAJ doit se faire juste apres le chargement de BTR_TIERS)    --
	  --                                                                           --
	  -- auteur : M. Bouchakour - 20130205                                         --
	  -- entr?e : /                                                                --
	  -- retour : /                                                                --
	  -------------------------------------------------------------------------------
	  -- Modification                                                              --
	  --                                                                           --
	  -------------------------------------------------------------------------------
	  PROCEDURE Gest_Coherence_IDTCA_inBTR
	  IS
	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		-- MBO - 20130205 : L01-C35-3b - Traitement code APE Interne, code pays et Alias (BTR 6.5)
		--                  <A noter que cette BTR_TIERS sera historise, dans HCRR, avec cette MAJ>

		-- 1/ Ecraser IDENT_SIRIS (IDTCA) de BTR_TIERS :
		UPDATE BTR_TIERS set IDENT_SIRIS = NULL ;

		-- 2/ Prendre IDTCA du DTG Global (REF_IDENT_NATIONALE a 01 et IDENT_NATIONAL verifiant la fonction SIREN valide) :
		MERGE INTO BTR_TIERS BTR
		USING (SELECT IDENT_NATIONAL, IDENT_CENTRAL_SI_CIBLE
		   FROM  SASNOTES.SIRIS_RETOUR_TIERS
		   WHERE REF_IDENT_NATIONALE    = '01'
			 AND LENGTH(IDENT_NATIONAL) = 9
			 AND ddrex.pack_utilitaire.FONC_VERIFIER_SIRET(IDENT_NATIONAL) = 'O'
		  ) SRT
		 ON (BTR.NUM_SIREN = SRT.IDENT_NATIONAL)
		 WHEN MATCHED THEN
		   UPDATE set BTR.IDENT_SIRIS = SRT.IDENT_CENTRAL_SI_CIBLE ;

		COMMIT;

	  EXCEPTION
		 WHEN OTHERS THEN
		   BEGIN
			 ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Proc Gest_Coherence_IDTCA_inBTR MESS:'||SQLERRM);
			 pack_utilitaire.DB_TRAITE_ERREUR(sqlerrm, 'Erreur PROC Gest_Coherence_IDTCA_inBTR', 50072);
			 RAISE;
			END;

	  END Gest_Coherence_IDTCA_inBTR;

	  --------------------------------------------------------------------------
	  -- SURETE RETAIL
	  --------------------------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE p_alim_SURETE_RETAIL_M5 IS

		   l_position varchar2(20);
           W_TABLE VARCHAR2(30);

		 BEGIN
            DBMS_OUTPUT.ENABLE(buffer_size=>NULL);

		   l_position := 'SURETE Det M5 reelle';

           W_TABLE := 'SURETE_DETAIL_M5 (1)';
		   execute immediate 'TRUNCATE TABLE SURETE_DETAIL_M5';
           W_TABLE := 'SURETE_AGREG_M5 (1)';
		   execute immediate 'TRUNCATE TABLE SURETE_AGREG_M5';

           W_TABLE := 'SURETE_DETAIL_M5 (2)';
		   INSERT INTO SURETE_DETAIL_M5 -- suretes r?elles
			 (
			   DT_ARRETE,     CD_CONSO_CPT,  ID_TIERS,   ID_TIERS_CALC,   ID_CENTRAL_TIERS,     ID_AUTORISATION,          ID_LIGNE_DET,   ID_ENGAGEMENT,
			   ID_SURETE,     CD_NATOP_CPT,  CD_TRR,     ID_TIERS_GARANT, ID_TIERS_CALC_GARANT, ID_CENTRAL_TIERS_GARANT,  ID_TYPE_GARANTIE_CASA,
			   CD_INFO_COMPL, MNT_GARANTIE,  MNT_REVISE, CD_DEVISE,       CD_ELLIGIBILITE,      MNT_RISQUE, CD_TAUX_COUV, CD_PLAF_UTIL,   A_EXTRAIRE
			   , USAGE_BIEN_GARANTI  -- 18/02/2019 - CDS ATOS (GBD) - US731
			   ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			   ,NUM_SIREN --M_72558
			 )
			 select distinct o.DT_ARRETE,
				s.CD_CONSO_CPT_CRRV3,
				o.ID_TIERS,
				tt.ID_TIERS_CALC,
				t.ident_siris,
				null,
				-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
				/*
		  substr(s.CD_CONSO_CPT_CRRV3,3,10) ||
				--CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
				--WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END
				-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
				CASE WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')          THEN 'NA012'
				 WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
				 WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
				 WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
				END
				||
				   'NAT07'||CASE WHEN t.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END
				  || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				  case when
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
				  WHEN
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
				  ELSE '0'
				  END*/
				  P5.ID_AUTORISATION,
				  -- FIN LFD
				o.ID_OPERATION,
				sur.id_surete,
			  DECODE(o.CD_PRODUIT,'CBI','NAT84','NAT85'),
				'1',
				o.ID_TIERS,
				tt.ID_TIERS_CALC,
				t.ident_siris,
				'TAS9999',
				'02',
				sur.mnt_initial,
				sur.mnt_revise,
				o.cd_devise,
				'N',
				null,
			   null,
				DECODE (s.CD_CONSO_CPT_CRRV3, '00472', '3', '9'), --'9', MANTIS=42433 remplacer 9 par '3' Circuit Cible 06-2018
				'O',
				'0'  USAGE_BIEN_GARANTI  -- 18/02/2019 - CDS ATOS (GBD) - US731
				,'GAAC01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				,t.num_siren NUM_SIREN --M_72558
			 from BTR_operation o,
			  BTR_TIERS t,
			  tie_tiers_c1_c5 tt,
			  BTR_SURETE_REELLE sur,
			  RS_SOCIETE_JURIDIQUE s,
			  RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			  btr_hors_bilan hb
			  ,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			 where o.id_tiers = t.id_tiers
			   AND   o.CD_PRODUIT    = pf.CD_PRODUIT
			   AND   o.CD_SYS_INT = hb.cd_sys_int (+)
			AND   o.ID_OPERATION = hb.id_operation (+)
			 and t.id_tiers = tt.id_tiers
			 and t.cd_type_sgmt = 'RETA'
			 and tt.cd_type_relation = 'C'
			 and t.cd_role_tiers = 'C'
			 and o.cd_sys_int = sur.cd_sys_int
			 and o.id_operation = sur.id_operation
			 and o.CD_SOC_JURI = s.CD_SOC_JURI
			 and s.CD_CONSO_CPT_CRRV3 = tt.CD_CONSO_CPT
			 AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			 AND    s.CD_CONSO_CPT_CRRV3  = P5. CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO

	;

		  commit;
		  -- pour les MNT_RISQUE aller voir dans eng_retail_detail_p5 le MNT_LOY_RD pour l'op?ration a prorater avec toutes les garanties sur l'affaire...
		  -- ne pas oublier que c est pour un cumul a suivre ou alors le mettre sur la premiere surete de l'affaire...  2eme soluce fausse les criteres d agregat sont diff

		   l_position := 'SURETE Det M5 pers';
            W_TABLE := 'SURETE_DETAIL_M5 (3)';
		   INSERT INTO SURETE_DETAIL_M5 -- suretes pers
			 (
			   DT_ARRETE,     CD_CONSO_CPT,  ID_TIERS,   ID_TIERS_CALC,   ID_CENTRAL_TIERS,     ID_AUTORISATION,          ID_LIGNE_DET,   ID_ENGAGEMENT,
			   ID_SURETE,     CD_NATOP_CPT,  CD_TRR,     ID_TIERS_GARANT, ID_TIERS_CALC_GARANT, ID_CENTRAL_TIERS_GARANT,  ID_TYPE_GARANTIE_CASA,
			   CD_INFO_COMPL, MNT_GARANTIE,  MNT_REVISE, CD_DEVISE,       CD_ELLIGIBILITE,      MNT_RISQUE, CD_TAUX_COUV, CD_PLAF_UTIL,   A_EXTRAIRE
			   ,DT_DEB_EFFET, DT_FIN_EFFET, CD_NUTS, CD_NATURE_SURETE, CD_RANG_SURETE, CD_PAYS_RECOURS, CD_METHODO_VALORISATION --16/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
			  ,CD_LIEU_DEPOT -- 29/11/2018 - CDS ATOS (LFD) - ANACREDIT US 573
						,USAGE_BIEN_GARANTI  -- 18/02/2019 - CDS ATOS (GBD) - US731
				,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				,NUM_SIREN --M_72558
			 )
			(SELECT distinct
				o.DT_ARRETE,
				s.CD_CONSO_CPT_CRRV3,
				o.ID_TIERS,
				tt.ID_TIERS_CALC,
				t.ident_siris ID_CENTRAL_TIERS,
				sur.id_type_garantie,
				-- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
				/*
			substr(s.CD_CONSO_CPT_CRRV3,3,10) ||
				--CASE WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA012'
				--WHEN (t.cd_segment_cal in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA011'
				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) >0) THEN 'NA022'
				--WHEN (t.cd_segment_cal not in ('06','07') AND (nvl(o.mnt_solde_ht_exigib_autre,0) + nvl(o.mnt_solde_ht_exigib_k,0) + nvl(o.mnt_solde_ht_exigib_i,0)) <=0) THEN 'NA021' END
				-- Circuit cible Juin 2018 MANTIS 42809 - appliquer la meme regle que le corporate
				CASE WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')         THEN 'NA012'
				WHEN T.cd_segment_cal in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')      THEN 'NA011'
				WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt in ('DTX', 'DTCO')      THEN 'NA022'
				WHEN T.cd_segment_cal not in ('06','07') and T.cd_categ_cpt not in ('DTX', 'DTCO')  THEN 'NA021'
				END
				||
				   'NAT07'||CASE WHEN t.CD_CATEG_CPT IN ('DTX','DTCO') THEN 'Y' ELSE 'N' END
				   || pf.CD_TYP_RISQ_RET || CD_TYPE_TAUX ||             case when nvl (o.nbre_impy, 0) > 0 then 'Y' else 'N' end ||
          --  Attention a l'ordre : il faudrait When > 20 puis When > 0  ici et ailleurs !
				  case when
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 0 THEN '1'
				  WHEN
				  (((nvl(o.MNT_PROV_SOLD_LOY_K,0) + nvl(o.MNT_PROV_CRD,0) + nvl(o.MNT_PROV_SOLD_LOY_I,0) + nvl(o.MNT_PROV_SOLD_IRE,0) + nvl(o.MNT_PROV_SOLD_AUT,0) + nvl(o.MNT_PROV_ICNE,0))
						   - (nvl(o.MNT_REPRISE_SOLD_LOY_K,0) + nvl(o.MNT_REPRISE_CRD,0) + nvl(o.MNT_REPRISE_SOLD_LOY_I,0) + nvl(o.MNT_REPRISE_SOLD_IRE,0) + nvl(o.MNT_REPRISE_SOLD_AUT,0) + nvl(o.MNT_REPRISE_ICNE,0))*100)
						   / case when nvl(o.MNT_ENC_RISQ_PROPRE,1) > 1 then 1 end) > 20 THEN '2'
				  ELSE '0'
				  END*/
				P5.ID_AUTORISATION,
				  -- FIN LFD
				o.ID_OPERATION,
				sur.id_surete,
				--'NAT81',
		  tg.cd_natop_cpt,
				CASE WHEN tg.ID_FAMILLE_GARANTIE IN ('PARI', 'GSYN') THEN decode (tg.FLAG_PREM_QUALITE, 'O', '1', '0') ELSE '0' END CD_TRR,
				sur.id_tiers_garant,
				tt1.ID_TIERS_CALC,
				t1.ident_siris,
				sur.id_type_garantie_casa,
				Decode(substr(sur.ID_TYPE_GARANTIE_CASA,1,5), 'SEC01', '13', ''),
				sur.mnt_garantie,
				sur.mnt_garantie,
				o.cd_devise,
				nvl(sur.eligibilite_sur_pers,'N'), -- M71945
				null,
			   null,
				DECODE (s.CD_CONSO_CPT_CRRV3, '00472', '3', '9'), --'9', MANTIS=42433 remplacer 9 par '3' Circuit Cible 06-2018
				'O' ,
				-- 16/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
				CASE WHEN sur.DT_DEB_VALID_GARANT > SUR.DT_ARRETE THEN SUR.DT_ARRETE ELSE SUR.DT_DEB_VALID_GARANT END,--DT_DEB_EFFET
				CASE WHEN nvl(sur.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) > sur.DT_DEB_VALID_GARANT THEN nvl(sur.DT_FIN_VALID_GARANT,to_date('31/12/2099','dd/mm/yyyy')) ELSE o.dt_fin_ope END,--DT_FIN_EFFET
				PACK_UTILITAIRE.F_GET_CODE_NUTS(t.cd_postal,t.CD_PAYS_RESIDENCE),--CD_NUTS
				sur.ID_TYPE_GARANTIE_CASA,--CD_NATURE_SURETE
				--06/11/18 CDS Atos (EMM) US 549
				CASE WHEN sur.id_type_garantie ='CAUM' THEN '2' ELSE '1' END , --CD_RANG_SURETE
				--Fin EMM
				decode(t.CD_PAYS_RESIDENCE,NULL,'FR','99','FR',t.CD_PAYS_RESIDENCE),--CD_PAYS_RECOURS
				mv.CD_METHODE_VALORIS_BIEN--CD_METHODO_VALORISATION
				--FIN LFD
				-- 29/11/2018 - CDS ATOS (LFD) - ANACREDIT US 573
				,CASE WHEN substr(sur.ID_TYPE_GARANTIE_CASA,1,3) IN ('SEC','CAS') THEN
					  CASE WHEN sur.ID_TYPE_GARANTIE in ('AUSY') THEN '1'
						  WHEN sur.id_type_garantie in ('CLSY','CASY') THEN '2' else '0'
					  END
				ELSE null END
				--FIN LFD
						   ,'0'  USAGE_BIEN_GARANTI  -- 18/02/2019 - CDS ATOS (GBD) - US731
				,'GAAC01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				,NVL(t.num_siren,t1.num_siren) NUM_SIREN --M_72558
			 FROM BTR_operation o,
			  BTR_TIERS t,
			  tie_tiers_c1_c5 tt,
			  BTR_TIERS t1,     --- pour les garants
			  tie_tiers_c1_c5 tt1,     --- pour les garants
			  BTR_SURETE_pers sur,
			  RS_SOCIETE_JURIDIQUE s,
			  RS_TYPE_GARANTIE              tg,
					  RS_CORRES_PRD_FIN_TYP_RISQ_RET pf,
			  btr_hors_bilan hb,
			  RS_CORRES_SGMT_BAL_METH_VALOR mv -- 16/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
			  ,ENG_RETAIL_DETAIL_P5 P5 -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			where o.id_tiers = t.id_tiers
			 and t.id_tiers = tt.id_tiers
			 and t.cd_type_sgmt = 'RETA'
			 and tt.cd_type_relation = 'C'
			 and t.cd_role_tiers = 'C'
			 and t1.cd_role_tiers = 'G'
					AND   o.CD_PRODUIT    = pf.CD_PRODUIT
			   AND   o.CD_SYS_INT = hb.cd_sys_int (+)
			AND   o.ID_OPERATION = hb.id_operation (+)
			 and sur.id_tiers_garant = t1.id_tiers
			 and t1.id_tiers = tt1.id_tiers
			 and o.cd_sys_int = sur.cd_sys_int
			 and o.id_operation = sur.id_operation
			 and o.CD_SOC_JURI = s.CD_SOC_JURI
			 and s.CD_CONSO_CPT_CRRV3 = tt.CD_CONSO_CPT
			 and s.CD_CONSO_CPT_CRRV3 = tt1.CD_CONSO_CPT
			 and tg.id_type_garantie = sur.id_type_garantie
			 and t.CD_SEGMENT_CAL = mv.CD_SEGMENT_CAL -- 16/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
			 AND	o.id_operation = P5.id_engagement (+) -- 01/07/2021 - CDS ATOS (LFD) - US 43 MCO
			 AND    s.CD_CONSO_CPT_CRRV3  = P5. CD_CONSO_CPT (+) -- 02/08/2021 - CDS ATOS (LFD) - US 43 MCO
			 ) ;
			 COMMIT;

		 -------------------------------------------------------
		 --EVOL SYNDICATION LOT FEVRIER 2016
		 -------------------------------------------------------
        W_TABLE := 'SURETE_DETAIL_M5 (4)';
		Update SURETE_DETAIL_M5 M5
		Set M5.A_extraire='N'
		Where Exists (select 1
			FROM BTR_SURETE_PERS sp, RS_TYPE_GARANTIE tg
			where  tg.id_type_garantie = sp.id_type_garantie
			And   tg.id_type_garantie in ('AUSY', 'CASY', 'CLSY')
			And  M5.id_type_garantie_casa = tg.id_type_garantie_casa
			and sp.id_operation=M5.id_engagement
			 )
		 ;
		 COMMIT;

		 -- 17/10/2018 - CDS ATOS (LFD) - ANACREDIT US 528
         W_TABLE := 'SURETE_DETAIL_M5 (5)';
		 UPDATE SURETE_DETAIL_M5
		 SET A_EXTRAIRE='N'
		 WHERE MNT_GARANTIE <=0;

		 COMMIT;
		 --FIN LFD

	  EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
               DBMS_OUTPUT.PUT_LINE('Proc p_alim_surete_retail_M5:'||l_position|| ' table:' || W_TABLE||'-MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_surete_retail_M5:'||l_position|| ' table:' || W_TABLE,50072);
	  END p_alim_SURETE_RETAIL_M5;

      ------------------------------------------------------
	  --Une ligne P1sur CRD et une ligne P1 sur solde
	  --P5 CRD + impaye pour couverture de surete formule B donc encours
      ------------------------------------------------------
      -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
      --   ajout information de la table en cas d'erreurs --
      ------------------------------------------------------
	  PROCEDURE P_calcul_agregat IS
		   l_position varchar2(20);
           W_TABLE VARCHAR2(30);

	  BEGIN
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
	   -- chargement de RE_AGREGAT_TIERS avant mise a jour de tie_tiers_c1_c5
	   -- LOT FEVRIER 2016 : EVOL 05/01/2016 remplacer le GEN par GEN4
	   l_position :=' RE_AGREGAT_TIERS';
           W_TABLE := 're_agregat_tiers';
		   insert into re_agregat_tiers (CD_CONSO_CPT,
				  CD_SECTEUR_ACTIVITE,
						 CD_CATEG_CONTREPARTIE,
						 CD_PAYS_RESIDENCE,
						 CD_PORTEFEUILLE_BAL_TIERS,
						 NOTE_INTERNE,
						 CD_ROLE_TIERS,
						 TOP_ENG_DOUTEUX,
						 CD_IMP_PRUDENT,
						 CD_TYPE_RISQUE,
						 CD_STATUT_AGREGAT,
						 ID_AGREGAT,
						 NOM_AGREGAT,
						 ID_TIERS_CALC)
					  select CD_CONSO_CPT,
						   SECT_ACT,
						 CATEG_CTPT,
						 PAYS,
						 CD_SEGMENT,
						 NOTE,
						 CD_ROLE, eng_dtx, imp_prud, cd_TYPE_RISQUE,
						 '1',
						 'AGREGAT-'||LPAD(TO_CHAR(SEQ_ID_TIE_AGREGAT.NEXTVAL),7,'0'),
						 'AGREGAT-'||CD_CONSO_CPT||'-'||SECT_ACT||'-'||CATEG_CTPT||'-'||PAYS||'-'||CD_SEGMENT||'-'||NOTE||'-'||CD_ROLE||'-'||CD_TYPE_RISQUE||'-'||ENG_DTX||'-'||IMP_PRUD,
						 'GEN4'||LPAD(TO_CHAR(SEQ_ID_TIE_AGREGAT.CURRVAL),6,'0')
					  from   (select /*+ FULL(T) */ distinct T.cd_conso_cpt,
						  nvl(sa.CD_SECTEUR_ACTIVITE,'PP9902') SECT_ACT,
						  T.CD_CATEG_CONTREPARTIE CATEG_CTPT,
						  nvl(T.CD_PAYS_RESIDENCE,'99') PAYS,
						  T.CD_PORTEFEUILLE_BAL_TIERS cd_SEGMENT,
						  NOTE_INTERNE NOTE ,
						  T.CD_TYPE_RELATION cd_ROLE,
						  p5.top_eng_douteux eng_dtx,
						  p5.CD_IMP_PRUDENT  imp_prud,
						  p5.cd_TYPE_RISQUE,
						  '1' STATUT
						  from TIE_TIERS_C1_C5 T, RS_CORRES_NAF_NORM_LOCAL_ACT sa, eng_retail_detail_p5 p5
						  where CD_TYPE_SEGMENT = 'RETA' and T.CD_ACTIVITE_LOCALE = sa.CD_NAF_REV2 (+)
						  and p5.id_tiers = T.id_tiers and p5.cd_conso_cpt = T.cd_conso_cpt
						  minus
						  select cd_CONSO_CPT, CD_SECTEUR_ACTIVITE, CD_CATEG_CONTREPARTIE, CD_PAYS_RESIDENCE, CD_PORTEFEUILLE_BAL_TIERS, NOTE_INTERNE, CD_ROLE_TIERS, TOP_ENG_DOUTEUX, CD_IMP_PRUDENT, CD_TYPE_RISQUE,CD_STATUT_AGREGAT
						  from re_agregat_tiers);

		COMMIT;

		--Mise a jour des tiers retails
		l_position := 'maj Tiers retail';
        W_TABLE := 'TIE_TIERS_C1_C5';
		MERGE INTO TIE_TIERS_C1_C5 ti
		USING (SELECT r.id_tiers, re1.ID_TIERS_CALC, re1.NOM_AGREGAT, re1.ID_AGREGAT
		from re_agregat_tiers re1,
		( select t.id_tiers, max (re.NOM_AGREGAT) NOM_AGREGAT  From re_agregat_tiers re, tie_tiers_c1_c5 t
		  where re.CD_CONSO_CPT = t.CD_CONSO_CPT
		  and re.CD_SECTEUR_ACTIVITE = t.CD_SECTEUR_ACTIVITE
		  and re.CD_CATEG_CONTREPARTIE = t.CD_CATEG_CONTREPARTIE
		  and re.CD_PAYS_RESIDENCE = t.CD_PAYS_RESIDENCE
		  and re.CD_PORTEFEUILLE_BAL_TIERS = t.CD_PORTEFEUILLE_BAL_TIERS
		  and re.NOTE_INTERNE = t.NOTE_INTERNE
		  and re.CD_ROLE_TIERS = t.CD_TYPE_RELATION
		  and re.CD_STATUT_AGREGAT ='1'
		  and t.cd_type_segment = 'RETA'
		  and exists (select null from eng_retail_detail_p5 p5 where p5.id_tiers = t.id_tiers and p5.cd_conso_cpt = t.cd_conso_cpt and re.TOP_ENG_DOUTEUX = p5.top_eng_douteux and re.CD_IMP_PRUDENT = p5.CD_IMP_PRUDENT and re.CD_TYPE_RISQUE = p5.cd_TYPE_RISQUE)
		  group by t.id_tiers   )  r
		  where re1.nom_agregat = r.nom_agregat) ag
		 ON (ti.id_tiers = ag.id_tiers)
		 WHEN MATCHED THEN
		   UPDATE set ti.ID_TIERS_CALC = ag.ID_TIERS_CALC,
				ti.NOM_TIERS = ag.ID_AGREGAT,
				ti.ID_AGREGAT = ag.ID_AGREGAT,
			ti.ID_CENTRAL_TIERS = null ;

		COMMIT;

		   -- Je n ai pas le temps de revenir sur tout alors...
		l_position := 'recopie tiers';

        W_TABLE := 'tie_tiers';
		INSERT INTO tie_tiers (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  NOM_TIERS,
		  RAISON_SOCLE,
		  REF_IDENT_NATIO,
		  IDENT_NATIO,
		  CD_PAYS_NATIONALITE,
		  CD_PAYS_RESIDENCE,
		  CD_PAYS_CONTROLE,
		  ADRESSE,
		  VILLE,
		  CD_POSTAL,
		  DT_CLOTURE_CPT_NOTE,
		  NOTE_INTERNE,
		  DT_REVISION_NOTE,
		  DT_ENTREE_DEFAUT,
		  CD_METHODO_NOTE,
		  CD_MOTIF_NOTE,
		  CD_ENTITE_RUN,
		  CD_ENTITE_RMC,
		  CD_GRILLE_NOTE,
		  CD_CATEG_CONTREPARTIE,
		  CD_PORTEFEUILLE_BAL_TIERS,
		  CD_SEGMENT_CAL,
		  CD_SECTEUR_ACTIVITE,
		  CD_FILIERE,
		  CD_NORME_LOCAL_ACT,
		  CD_ACTIVITE_LOCALE,
		  CD_FORM_JUR,
		  CD_STATUT_FILIATION,
		  CD_TYPE_ACTEUR,
		  CD_TYPE_RELATION,
		  MNT_CA,
		  TOP_CA_CONSO,
		  CD_DEVISE_CA,
		  ANNEE_CA,
		  TOP_TIERS_DTX,
		  CD_TYPE_TIE
		   ,NBRE_JOUR_EXERCICE
		   ,NATURE_CA
		   ,NOTE_NAFA
		   ,TOT_BILAN_RETRAITE
		   ,CA_IFRS
		   ,RES_NET_RETRAITE_SIGN
		   ,RES_NET_RETRAITE_MNT
		   ,NOTE_APR_CORR_GRPE
		   ,A_EXTRAIRE)
		select DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS,
		  ID_TIERS_CALC,
		  ID_CENTRAL_TIERS,
		  substr(NOM_TIERS,40),
		  RAISON_SOCLE,
		  REF_IDENT_NATIO,
		  IDENT_NATIO,
		  CD_PAYS_NATIONALITE,
		  CD_PAYS_RESIDENCE,
		  CD_PAYS_CONTROLE,
		  ADRESSE,
		  VILLE,
		  CD_POSTAL,
		  DT_CLOTURE_CPT_NOTE,
		  NOTE_INTERNE,
		  DT_REVISION_NOTE,
		  DT_ENTREE_DEFAUT,
		  CD_METHODO_NOTE,
		  CD_MOTIF_NOTE,
		  CD_ENTITE_RUN,
		  CD_ENTITE_RMC,
		  CD_GRILLE_NOTE,
		  CD_CATEG_CONTREPARTIE,
		  CD_PORTEFEUILLE_BAL_TIERS,
		  CD_SEGMENT_CAL,
		  CD_SECTEUR_ACTIVITE,
		  CD_FILIERE,
		  CD_NORME_LOCAL_ACT,
		  CD_ACTIVITE_LOCALE,
		  CD_FORM_JUR,
		  CD_STATUT_FILIATION,
		  CD_TYPE_ACTEUR,
		  CD_TYPE_RELATION,
		  MNT_CA,
		  TOP_CA_CONSO,
		  CD_DEVISE_CA,
		  ANNEE_CA,
		  TOP_TIERS_DTX,
		  CD_TYPE_TIE
		   ,NBRE_JOUR_EXERCICE
		   ,NATURE_CA
		   ,NOTE_NAFA
		   ,TOT_BILAN_RETRAITE
		   ,CA_IFRS
		   ,RES_NET_RETRAITE_SIGN
		   ,RES_NET_RETRAITE_MNT
		   ,NOTE_APR_CORR_GRPE
		   ,A_EXTRAIRE
		   FROM TIE_TIERS_C1_C5;

		l_position := 'maj retail P5';

        W_TABLE := 'eng_retail_detail_p5 (1)';
		update eng_retail_detail_p5 p5
		set (id_tiers_calc) = (select id_tiers_calc from tie_tiers_c1_c5 c5 where c5.id_tiers = p5.id_tiers and c5.cd_conso_cpt = p5.cd_conso_cpt);
		commit;

        W_TABLE := 'eng_retail_detail_p5 (2)';
		update eng_retail_detail_p5 p5
		set (ID_AUTORISATION) = (select substr(ID_TIERS_CALC,4,11) || p5.ID_AUTORISATION from tie_tiers_c1_c5 c5 where c5.id_tiers = p5.id_tiers and c5.cd_conso_cpt = p5.cd_conso_cpt and p5.id_tiers_calc like 'GEN%');
		commit;


		--17/04/19 CDS ATOS (EMM) Mantis 46097 - Suppression du deversement des donnees de ENG_RETAIL_DETAIL_P5 vers ENG_RETAIL_AGREG_P5 ---> redirection vers p_calcul_agregat_p5
		/*
		INSERT INTO ENG_RETAIL_AGREG_P5 (
		  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS_CALC,
		  ID_ENGAGEMENT,
		  CD_METHODO_BALE2,
		  CD_TRT_MOTEUR,
		  CD_NATURE_OPE,
		  CD_NATURE_PNU,
		  CD_TYPE_RISQUE,
		  CD_PORTEFEUILLE_BALE2,
		  CD_LIGNE_METIER,
		  CD_OBJET_FIN,
		  CD_TYPE_TAUX,
		  CD_USAGE_BIEN_IMM,
		  CD_RESPECT_COND,
		  MNT_LOY_RD,
		  CD_DEVISE_LOY_RD,
		  MNT_AUTORISATION,
		  MNT_VTR,
		  MNT_HYPOTHEQUE,
		  CD_ACHAT_FIN_LOC,
		  MNT_VR,
		  MATURITE_CALC,
		  TOP_ENG_DOUTEUX,
		  CD_IMP_PRUDENT,
		  MNT_ENC_ARR_PAIE,
		  MNT_DTCO,
		  CD_NIVEAU_PROVISION,
		  CD_COUV_PROVISION,
		  CD_PLAF_SURETE,
		  CD_RESTRUCTUR,
		  CD_NEW_DEFAUT,
		  CD_CREANCE_TITRI,
		  NB_TIERS,
		  A_EXTRAIRE,
		mnt_loy_rd_crd,
		  mnt_loy_rd_sold,
		mnt_pnu,
		-- 24/09/2018 CDS AtoS (KKI) Mantis 42434
		IND_NIV_RISQ,
				--13/02/2019 - CDS Atos (GBD) US673 deb ->
				BUCKET_IFRS9,
				MNT_MTM,
				CD_DEV_MNT_MTM
				--13/02/2019 - CDS Atos (GBD) US673 <- fin
		  )
		SELECT  DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS_CALC,
		  ID_AUTORISATION,
		  CD_METHODO_BALE2,
		  CD_TRT_MOTEUR,
		  CD_NATURE_OPE,
		  CD_NATURE_PNU,
		  CD_TYPE_RISQUE,
		  CD_PORTEFEUILLE_BALE2,
		  CD_LIGNE_METIER,
		  CD_OBJET_FIN,
		  CD_TYPE_TAUX,
		  CD_USAGE_BIEN_IMM,
		  CD_RESPECT_COND,
		  --15/02/2019 - CDS ATOS (SQN) US 728
		  --CASE WHEN CD_TYPE_RISQUE not in ('TRE201','PRI102','PRI103','PRI104','PRI109') and CD_TYPE_RISQUE not like 'TRE2%' and CD_TYPE_RISQUE not like 'TRE4%' and CD_TYPE_RISQUE not like 'TRE3%' THEN sum(nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0)) - sum(nvl(MNT_VR,0)) ELSE 0 END,
		  CASE WHEN CD_TYPE_RISQUE not in ('TRE201','PRI102','PRI103','PRI104','PRI109') and CD_TYPE_RISQUE not like 'TRE2%' and CD_TYPE_RISQUE not like 'TRE4%' and CD_TYPE_RISQUE not like 'TRE3%'
		  THEN (CASE WHEN abs(sum(nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0))) > abs(sum(nvl(MNT_VR,0))) THEN sum(nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0)) - sum(nvl(MNT_VR,0)) ELSE 0 END)
		  ELSE 0 END MNT_LOY_RD,
		  --Fin SQN
		  nvl(CD_DEVISE_CONTRAT,'EUR'),
		  sum(MNT_AUTORISATION),
		  sum(MNT_VTR),
		  decode (CD_USAGE_BIEN_IMM , '2', sum(nvl(MNT_VTR,0)), ''),
		  CD_ACHAT_FIN_LOC,
		  sum(nvl(MNT_VR,0)),
		  sum(MATURITE_CALC)/count(*),
		  TOP_ENG_DOUTEUX,
		  CD_IMP_PRUDENT,
		  sum( CASE WHEN MNT_ENC_ARR_PAIE>0 THEN MNT_ENC_ARR_PAIE ELSE 0 END),
		  case when TOP_ENG_DOUTEUX = 'Y' then sum( nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0)) - sum(nvl(MNT_VR,0) ) end,
		max(CD_NIVEAU_PROVISION),
					  CASE WHEN sum(nvl(MNT_GAR_PREM_QUAL,0))=0 THEN 0
			   WHEN sum(nvl(MNT_LOY_RD_SOLD,0)) + sum(nvl(MNT_LOY_RD_CRD,0))  >= sum(nvl(MNT_GAR_PREM_QUAL,0)) THEN 1
			   WHEN sum(nvl(MNT_LOY_RD_SOLD,0)) + sum(nvl(MNT_LOY_RD_CRD,0)) < sum(nvl(MNT_GAR_PREM_QUAL,0)) THEN 2
			   END,
		  DECODE (CD_CONSO_CPT , '00472', '3', '9'), --'9', MANTIS=42433 replacer 9 par '3' Circuit Cible 06-2018
		  null,
		max(CD_NEW_DEFAUT),
		  'N',
		  count(*),
		  A_EXTRAIRE,
		  CASE WHEN CD_TYPE_RISQUE not in ('TRE201','PRI102','PRI103','PRI104','PRI109') and CD_TYPE_RISQUE not like 'TRE2%' and CD_TYPE_RISQUE not like 'TRE4%' and CD_TYPE_RISQUE not like 'TRE3%' THEN 0 ELSE sum(nvl(MNT_LOY_RD_CRD,0)) END,
		  sum(nvl(MNT_LOY_RD_SOLD,0)),
		sum(nvl(MNT_PNU,0)),
		-- 24/09/2018 CDS AtoS (KKI) Mantis 42434
		--,'2'
		--23/11/18 CDS Atos (EMM) US 579
		  CASE WHEN CD_CONSO_CPT = '00370' AND CD_TYPE_RISQUE ='PRI105' THEN 1 ELSE 2 END IND_NIV_RISQ,
		--Fin EMM
				--13/02/2019 - CDS Atos (GBD) US673 deb ->
				BUCKET_IFRS9,
				MNT_MTM,
				CD_DEV_MNT_MTM
				--13/02/2019 - CDS Atos (GBD) US673 <- fin
		 FROM  ENG_RETAIL_DETAIL_P5
		GROUP BY DT_ARRETE,
		  CD_CONSO_CPT,
		  ID_TIERS_CALC,
		  ID_AUTORISATION,
		  CD_METHODO_BALE2,
		  CD_TRT_MOTEUR,
		  CD_NATURE_OPE,
		  CD_NATURE_PNU,
		  CD_TYPE_RISQUE,
		  CD_PORTEFEUILLE_BALE2,
		  CD_LIGNE_METIER,
		  CD_OBJET_FIN,
		  CD_TYPE_TAUX,
		  CD_USAGE_BIEN_IMM,
		  CD_RESPECT_COND,
		nvl(CD_DEVISE_CONTRAT,'EUR'),
		  CD_ACHAT_FIN_LOC,
		  TOP_ENG_DOUTEUX,
		  CD_IMP_PRUDENT,
		  CD_COUV_PROVISION,
		  DECODE ( CD_CONSO_CPT , '00472', '3', '9'), --'9', MANTIS=42433 remplacer 9 par '3' Circuit Cible 06-2018
		  null,
		  'N',
		  A_EXTRAIRE,
				--13/02/2019 - CDS Atos (GBD) US673 deb ->
				BUCKET_IFRS9,
				MNT_MTM,
				CD_DEV_MNT_MTM
				--13/02/2019 - CDS Atos (GBD) US673 <- fin
				;
		COMMIT;


		update ENG_RETAIL_AGREG_P5 set CD_DEVISE_AUT   =  case when nvl(MNT_AUTORISATION,0) > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
		update ENG_RETAIL_AGREG_P5 set CD_DEVISE_VTR   =  case when nvl(MNT_VTR,0)          > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
		update ENG_RETAIL_AGREG_P5 set CD_DEVISE_HYPO  =  case when nvl(MNT_HYPOTHEQUE,0)   > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
		update ENG_RETAIL_AGREG_P5 set CD_DEVISE_VR    =  case when nvl(MNT_VR,0)           > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
		update ENG_RETAIL_AGREG_P5 set CD_DEVISE_ARR   =  case when nvl(CD_DEVISE_ARR,0)    > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
		update ENG_RETAIL_AGREG_P5 set CD_DEVISE_DTCO  =  case when nvl(CD_DEVISE_DTCO,0)   > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
		commit;
		*/


		l_position := 'maj balois P6';

        W_TABLE := 'eng_balois_detail_p6 (1)';
		update eng_balois_detail_p6 p6
		set (id_tiers_calc) = (select id_tiers_calc from tie_tiers_c1_c5 c5 where c5.id_tiers = p6.id_tiers and c5.cd_conso_cpt = p6.cd_conso_cpt);
		commit;

        W_TABLE := 'eng_balois_detail_p6 (2)';
		update eng_balois_detail_p6 p6
		set (ID_AUTORISATION) = (select substr(ID_TIERS_CALC,4,11) || p6.ID_AUTORISATION from tie_tiers_c1_c5 c5 where c5.id_tiers = p6.id_tiers and c5.cd_conso_cpt = p6.cd_conso_cpt and p6.id_tiers_calc like 'GEN%');
		commit;

		--14/05/19 CDS ATOS (EMM) Mantis 46097 -  ---> redirection vers p_calcul_agregat_p6
		/*
		INSERT INTO ENG_BALOIS_AGREG_P6  (
			   DT_ARRETE                   ,
			   CD_CONSO_CPT                ,
			   ID_TIERS_CALC               ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_ENGAGEMENT               ,
			   CD_CLASSE_PD                ,
			   POURC_TX_PD                 ,
			   CD_CLASSE_LGD               ,
			   TX_LGD_PREDICTIF            ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   MNT_EXPO_POTENT_HT          ,
			   ENCOURS_FINANC_BRUT         ,
			   MNT_ENGT_FINANCMT_HB        ,
			   MNT_IRD                     ,
			   TX_CCF                      ,
			   MNT_EAD_TOT                 ,
			   CD_METHODO_BALE2            ,
			   MNT_RWA                     ,
			   CD_DEVISE                   ,
			   MATURITE_CALC               ,
			   A_EXTRAIRE
		   --      ,TX_LGD_PREDICTIF_HG
			 )
			 SELECT DT_ARRETE                ,
			   CD_CONSO_CPT                ,
			   ID_TIERS_CALC               ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_AUTORISATION               ,
			   CD_CLASSE_PD                ,
			   AVG(POURC_TX_PD)            ,
			   CD_CLASSE_LGD               ,
			   AVG(TX_LGD_PREDICTIF      ) ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   sum(MNT_EXPO_POTENT_HT),
			   sum(ENCOURS_FINANC_BRUT),
			   sum(MNT_ENGT_FINANCMT_HB),
			   sum(MNT_IRD)        ,
			   AVG(TX_CCF)                 ,
			   sum(MNT_EAD_TOT)     ,
			   CD_METHODO_BALE2            ,
			   sum(MNT_RWA)         ,
			   CD_DEVISE                   ,
			   AVG(MATURITE_CALC)          ,
			   A_EXTRAIRE
			FROM ENG_BALOIS_DETAIL_P6
			GROUP BY DT_ARRETE             ,
			   CD_CONSO_CPT                ,
			   ID_TIERS_CALC               ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_AUTORISATION               ,
			   CD_CLASSE_PD                ,
			   CD_CLASSE_LGD               ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   CD_METHODO_BALE2            ,
			   CD_DEVISE                   ,
			   A_EXTRAIRE;

		   COMMIT;
		   */


		l_position := 'maj provision P8';

        W_TABLE := 'provisions_detail_p8 (1)';
		update provisions_detail_p8 p8
		set (id_tiers_calc) = (select id_tiers_calc from tie_tiers_c1_c5 c5 where c5.id_tiers = p8.id_tiers and c5.cd_conso_cpt = p8.cd_conso_cpt);
		commit;

        W_TABLE := 'provisions_detail_p8 (2)';
		update provisions_detail_p8 p8
		set (ID_AUTORISATION) = (select substr(ID_TIERS_CALC,4,11) || p8.ID_AUTORISATION from tie_tiers_c1_c5 c5 where c5.id_tiers = p8.id_tiers and c5.cd_conso_cpt = p8.cd_conso_cpt and p8.id_tiers_calc like 'GEN%');
		commit;

		--14/05/19 CDS ATOS (EMM) Mantis 46097 -  ---> redirection vers p_calcul_agregat_p8
		/* INSERT INTO PROVISIONS_AGREG_P8
		   (   DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_ENGAGEMENT,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 MNT_PROVISION,
			 MNT_PROVISION_TRIM,
			 CD_DEVISE,
			 CD_PCCO,
			 a_extraire
		   )
		   SELECT DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_AUTORISATION,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 sum(MNT_PROVISION),
			 sum(MNT_PROVISION_TRIM),
			 CD_DEVISE,
		   MIN(CD_PCCO) KEEP (DENSE_RANK LAST ORDER BY MNT_PROVISION),
			 a_extraire
		   FROM PROVISIONS_DETAIL_P8
		   GROUP BY DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_AUTORISATION,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 CD_DEVISE,
			 a_extraire;

		   COMMIT;
		   */

		l_position := 'maj surete M5';

        W_TABLE := 'surete_detail_m5 (1)';
		update surete_detail_m5 m5
		set (id_tiers_calc) = (select id_tiers_calc from tie_tiers_c1_c5 c5 where c5.id_tiers = m5.id_tiers and c5.cd_conso_cpt = m5.cd_conso_cpt);
		commit;

        W_TABLE := 'surete_detail_m5 (2)';
		update surete_detail_m5 m5
		set ( ID_LIGNE_DET) = (select substr(ID_TIERS_CALC,4,11) || m5.ID_LIGNE_DET from tie_tiers_c1_c5 c5 where c5.id_tiers = m5.id_tiers and c5.cd_conso_cpt = m5.cd_conso_cpt and m5.id_tiers_calc like 'GEN%');
		commit;

        W_TABLE := 'surete_detail_m5 (3)';
		MERGE INTO surete_detail_m5   p
		USING
			(
			select
		  distinct
			  id_tiers_calc,
			  id_tiers,
		  id_central_tiers
			from
			   tie_tiers_c1_c5 tt

			) REQ
		  ON ( p.id_tiers_garant = REQ.id_tiers)
		  WHEN MATCHED THEN
			UPDATE SET
			P.id_tiers_calc_garant = REQ.id_tiers_calc,
			P.ID_CENTRAL_TIERS_GARANT = REQ.id_central_tiers;

		  COMMIT;

		--14/05/19 CDS ATOS (EMM) Mantis 46097 -  ---> redirection vers p_calcul_agregat_m5
		/*
		INSERT INTO SURETE_AGREG_M5 -- suretes r?elles
			 (   DT_ARRETE,     CD_CONSO_CPT,              ID_TIERS_CALC,   ID_ENGAGEMENT,
			   ID_SURETE,     CD_NATOP_CPT,  CD_TRR,                      ID_TIERS_CALC_GARANT, ID_CENTRAL_TIERS_GARANT,  ID_TYPE_GARANTIE_CASA,
			   CD_INFO_COMPL, MNT_GARANTIE,  MNT_REVISE, CD_DEVISE,       CD_ELLIGIBILITE,      MNT_RISQUE, CD_TAUX_COUV, CD_PLAF_UTIL,   A_EXTRAIRE
					   , USAGE_BIEN_GARANTI   -- 18/02/2019 - CDS ATOS (GBD) - US731
			 )
			SELECT DT_ARRETE,
			  CD_CONSO_CPT,
			  ID_TIERS_CALC,
			  ID_LIGNE_DET,
		  ID_LIGNE_DET||substr(ID_TIERS_CALC_GARANT,4,11)||substr(id_type_garantie_casa,1,1) || substr(id_type_garantie_casa,5,1) || substr(id_type_garantie_casa,7,1),
			  CD_NATOP_CPT,
			  CD_TRR,
			  ID_TIERS_CALC_GARANT,
			  ID_CENTRAL_TIERS_GARANT,
			  ID_TYPE_GARANTIE_CASA,
			  CD_INFO_COMPL,
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --sum(MNT_GARANTIE),
			  CASE WHEN sum(MNT_GARANTIE) is null OR sum(MNT_GARANTIE) <0 then 0 else sum(MNT_GARANTIE) end,
			  -- FIN LFD
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --sum(MNT_REVISE),
			  CASE WHEN sum(MNT_REVISE) is null OR sum(MNT_REVISE) <0 then 0 else sum(MNT_REVISE) end,
			  -- FIN LFD
			  CD_DEVISE,
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --CD_ELLIGIBILITE,
			  nvl(CD_ELLIGIBILITE,1),
			  -- FIN LFD
			  sum(MNT_RISQUE),
			  CD_TAUX_COUV,
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --CD_PLAF_UTIL,
			  nvl(CD_PLAF_UTIL,9),
			  -- FIN LFD
			  'O',
						'0'  USAGE_BIEN_GARANTI  -- 18/02/2019 - CDS ATOS (GBD) - US731
		   FROM (select m5.DT_ARRETE,     m5.CD_CONSO_CPT,  m5.ID_TIERS,   m5.ID_TIERS_CALC,    m5.ID_CENTRAL_TIERS,     m5.ID_AUTORISATION,          m5.ID_LIGNE_DET,  m5.ID_ENGAGEMENT,
			   m5.ID_SURETE,     m5.CD_NATOP_CPT,  m5.CD_TRR,     m5.ID_TIERS_GARANT, m5.ID_TIERS_CALC_GARANT, m5.ID_CENTRAL_TIERS_GARANT,  m5.ID_TYPE_GARANTIE_CASA,
			   m5.CD_INFO_COMPL, m5.MNT_GARANTIE,  m5.MNT_REVISE, m5.CD_DEVISE,       m5.CD_ELLIGIBILITE,      m5.MNT_RISQUE, m5.CD_TAUX_COUV, m5.CD_PLAF_UTIL,   m5.A_EXTRAIRE,
			   DECODE (rs.flag_prem_qualite ,'O', m5.MNT_GARANTIE, 0) mnt_prem_qual
			   from  SURETE_DETAIL_M5 m5,
			   rs_type_garantie rs
			   where nvl(m5.id_autorisation,'1') = nvl(rs.id_type_garantie, '1')
		  AND m5.A_extraire='O')    --- pas propre, j ai planque dans ce champ qui ne sert ? rien le type de garantie, post agregat on peut le virer idem mnt_risque
		   group by
			  DT_ARRETE,
			  CD_CONSO_CPT,
			  ID_TIERS_CALC,
			  ID_LIGNE_DET,
			  ID_TIERS_CALC||ID_TIERS_CALC_GARANT||ID_TYPE_GARANTIE_CASA||cd_info_compl||cd_taux_couv||CD_TRR,
			  CD_NATOP_CPT,
			  CD_TRR,
			  ID_TIERS_CALC_GARANT,
			  ID_CENTRAL_TIERS_GARANT,
			  ID_TYPE_GARANTIE_CASA,
			  CD_INFO_COMPL,
			  CD_DEVISE,
			  CD_ELLIGIBILITE,
			  CD_TAUX_COUV,
			  CD_PLAF_UTIL,
			  'O',
						'0';  -- 18/02/2019 - CDS ATOS (GBD) - US731

		  commit;
		UPDATE SURETE_AGREG_M5 M5 SET CD_TAUX_COUV=(SELECT CD_COUV_PROVISION FROM ENG_RETAIL_AGREG_P5 P5 WHERE P5.ID_ENGAGEMENT= M5.ID_ENGAGEMENT);
		COMMIT;

		-- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
		UPDATE SURETE_AGREG_M5 set CD_TAUX_COUV = 0 where CD_TAUX_COUV is null;
		commit;
		-- FIN LFD
		*/

	  EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc p_calcul_agregat:'||l_position|| ' table:' || W_TABLE||'-MESS:'||SQLERRM);
			  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_calcul_agregat:'||l_position || ' table:'||W_TABLE,50072);
	  end P_calcul_agregat;

--22/04/19 CDS ATOS (EMM) Mantis 46097
------------------------------------------------------
-- nom : procedure P_CALCUL_AGREGAT_P5               --
-- but : d?versement de ENG_RETAIL_DETAIL_P5 vers    --
-- ENG_RETAIL_AGREG_P5 quand le top a_extraire =?O?  --
-- auteur : E.Mipam, le 17/04/2019              --
-- entr?e : /                                       --
-- retour : /                                       --
------------------------------------------------------
-- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
--   ajout information de la table en cas d'erreurs --
------------------------------------------------------
PROCEDURE P_CALCUL_AGREGAT_P5 IS
	   l_position varchar2(30);

BEGIN
	DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
	l_position := 'maj retail agregat P5';
	INSERT INTO ENG_RETAIL_AGREG_P5 (
		DT_ARRETE,
		CD_CONSO_CPT,
		ID_TIERS_CALC,
		ID_ENGAGEMENT,
		CD_METHODO_BALE2,
		CD_TRT_MOTEUR,
		CD_NATURE_OPE,
		CD_NATURE_PNU,
		CD_TYPE_RISQUE,
		CD_PORTEFEUILLE_BALE2,
		CD_LIGNE_METIER,
		CD_OBJET_FIN,
		CD_TYPE_TAUX,
		CD_USAGE_BIEN_IMM,
		CD_RESPECT_COND,
		MNT_LOY_RD,
		CD_DEVISE_LOY_RD,
		MNT_AUTORISATION,
		MNT_VTR,
		MNT_HYPOTHEQUE,
		CD_ACHAT_FIN_LOC,
		MNT_VR,
		MATURITE_CALC,
		TOP_ENG_DOUTEUX,
		CD_IMP_PRUDENT,
		MNT_ENC_ARR_PAIE,
		MNT_DTCO,
		CD_NIVEAU_PROVISION,
		CD_COUV_PROVISION,
		CD_PLAF_SURETE,
		CD_RESTRUCTUR,
		CD_NEW_DEFAUT,
		CD_CREANCE_TITRI,
		NB_TIERS,
		A_EXTRAIRE,
		mnt_loy_rd_crd,
		mnt_loy_rd_sold,
		mnt_pnu,
		-- 24/09/2018 CDS AtoS (KKI) Mantis 42434
		IND_NIV_RISQ,
		--13/02/2019 - CDS Atos (GBD) US673 deb ->
		BUCKET_IFRS9,
		MNT_MTM,
		CD_DEV_MNT_MTM,
		--13/02/2019 - CDS Atos (GBD) US673 <- fin
		-- 12/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
		MNT_LOY_AVEC_ARR,
		DEV_LOY_AVEC_ARR,
		MNT_LOY_HORS_ARR,
		DEV_LOY_HORS_ARR,
		MNT_INT_AVEC_ARR,
		DEV_INT_AVEC_ARR,
		MNT_INT_HORS_ARR,
		DEV_INT_HORS_ARR
		-- fin CPD
		,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
		,MNT_CAPITAL_HORS_ARR
		,DEV_CAPITAL_HORS_ARR
		-- FIN LFD
	)
		SELECT  DT_ARRETE,
				CD_CONSO_CPT,
				ID_TIERS_CALC,
				ID_AUTORISATION,
				CD_METHODO_BALE2,
				CD_TRT_MOTEUR,
				CD_NATURE_OPE,
				CD_NATURE_PNU,
				CD_TYPE_RISQUE,
				CD_PORTEFEUILLE_BALE2,
				CD_LIGNE_METIER,
				CD_OBJET_FIN,
				CD_TYPE_TAUX,
				CD_USAGE_BIEN_IMM,
				CD_RESPECT_COND,
				--15/02/2019 - CDS ATOS (SQN) US 728
				--CASE WHEN CD_TYPE_RISQUE not in ('TRE201','PRI102','PRI103','PRI104','PRI109') and CD_TYPE_RISQUE not like 'TRE2%' and CD_TYPE_RISQUE not like 'TRE4%' and CD_TYPE_RISQUE not like 'TRE3%' THEN sum(nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0)) - sum(nvl(MNT_VR,0)) ELSE 0 END,
				CASE WHEN CD_TYPE_RISQUE not in ('TRE201','PRI102','PRI103','PRI104','PRI109') and CD_TYPE_RISQUE not like 'TRE2%' and CD_TYPE_RISQUE not like 'TRE4%' and CD_TYPE_RISQUE not like 'TRE3%'
				THEN (CASE WHEN abs(sum(nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0))) > abs(sum(nvl(MNT_VR,0))) THEN sum(nvl(MNT_LOY_RD_CRD,0)) + sum(nvl(MNT_LOY_RD_SOLD,0)) - sum(nvl(MNT_VR,0)) ELSE 0 END)
				ELSE 0 END MNT_LOY_RD,
				--Fin SQN
				nvl(CD_DEVISE_CONTRAT,'EUR'),
				sum(MNT_AUTORISATION),
				sum(MNT_VTR),
				decode (CD_USAGE_BIEN_IMM , '2', sum(nvl(MNT_VTR,0)), ''),
				CD_ACHAT_FIN_LOC,
				sum(nvl(MNT_VR,0)),
				sum(MATURITE_CALC)/count(*),
				TOP_ENG_DOUTEUX,
				CD_IMP_PRUDENT,
				sum( CASE WHEN MNT_ENC_ARR_PAIE>0 THEN MNT_ENC_ARR_PAIE ELSE 0 END),
				--M11680 - 15/09/2021 - CDS ATOS (VFN)
				case when TOP_ENG_DOUTEUX = 'Y' then sum( CASE WHEN nvl(MNT_LOY_RD_CRD,0) + nvl(MNT_LOY_RD_SOLD,0) - nvl(MNT_VR,0)  < 0
															then 0 else nvl(MNT_LOY_RD_CRD,0) + nvl(MNT_LOY_RD_SOLD,0) - nvl(MNT_VR,0)
															end)
				end,
				--FIN VFN
				max(CD_NIVEAU_PROVISION),
							  CASE WHEN sum(nvl(MNT_GAR_PREM_QUAL,0))=0 THEN 0
					   WHEN sum(nvl(MNT_LOY_RD_SOLD,0)) + sum(nvl(MNT_LOY_RD_CRD,0))  >= sum(nvl(MNT_GAR_PREM_QUAL,0)) THEN 1
					   WHEN sum(nvl(MNT_LOY_RD_SOLD,0)) + sum(nvl(MNT_LOY_RD_CRD,0)) < sum(nvl(MNT_GAR_PREM_QUAL,0)) THEN 2
					   END,
				DECODE (CD_CONSO_CPT , '00472', '3', '9'), --'9', MANTIS=42433 replacer 9 par '3' Circuit Cible 06-2018
				null,
				max(CD_NEW_DEFAUT),
				'N',
				count(*),
				A_EXTRAIRE,
				CASE WHEN CD_TYPE_RISQUE not in ('TRE201','PRI102','PRI103','PRI104','PRI109') and CD_TYPE_RISQUE not like 'TRE2%' and CD_TYPE_RISQUE not like 'TRE4%' and CD_TYPE_RISQUE not like 'TRE3%' THEN 0 ELSE sum(nvl(MNT_LOY_RD_CRD,0)) END,
				sum(nvl(MNT_LOY_RD_SOLD,0)),
				sum(nvl(MNT_PNU,0)),
				-- 24/09/2018 CDS AtoS (KKI) Mantis 42434
				--,'2'
				--23/11/18 CDS Atos (EMM) US 579
				CASE -- 08/06/2022 - KLx Risque (VDC) - Risque Leasing 2022 US 11  - Juste ï¿½a car insertion pour les codes natures PNU, AGREG_P5
					WHEN ( CD_CONSO_CPT = '00370' AND CD_TYPE_RISQUE ='PRI105' ) OR CD_TYPE_RISQUE = 'TRE504' THEN 1
					ELSE 2 END IND_NIV_RISQ,
				--Fin EMM
				--13/02/2019 - CDS Atos (GBD) US673 deb ->
				BUCKET_IFRS9,
				MNT_MTM,
				CD_DEV_MNT_MTM,
				--13/02/2019 - CDS Atos (GBD) US673 <- fin
				-- 12/02/2021 -- CDS_ATOS (CPD) - US 25 CRRV3.4
				sum(nvl(MNT_LOY_AVEC_ARR,0)),
				'EUR' DEV_LOY_AVEC_ARR ,
				sum(nvl(MNT_LOY_HORS_ARR,0)),
				'EUR' DEV_LOY_HORS_ARR ,
				sum(nvl(MNT_INT_AVEC_ARR,0)),
				'EUR' DEV_INT_AVEC_ARR,
				sum(nvl(MNT_INT_HORS_ARR,0)),
				'EUR' DEV_INT_HORS_ARR
				-- fin CPD
				,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
				-- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
				,SUM(NVL(MNT_CAPITAL_HORS_ARR,0))
				,DEV_CAPITAL_HORS_ARR
				-- FIN LFD
	FROM  ENG_RETAIL_DETAIL_P5
	WHERE A_EXTRAIRE='O'
	GROUP BY DT_ARRETE,
			CD_CONSO_CPT,
			ID_TIERS_CALC,
			ID_AUTORISATION,
			CD_METHODO_BALE2,
			CD_TRT_MOTEUR,
			CD_NATURE_OPE,
			CD_NATURE_PNU,
			CD_TYPE_RISQUE,
			CD_PORTEFEUILLE_BALE2,
			CD_LIGNE_METIER,
			CD_OBJET_FIN,
			CD_TYPE_TAUX,
			CD_USAGE_BIEN_IMM,
			CD_RESPECT_COND,
			nvl(CD_DEVISE_CONTRAT,'EUR'),
			CD_ACHAT_FIN_LOC,
			TOP_ENG_DOUTEUX,
			CD_IMP_PRUDENT,
			CD_COUV_PROVISION,
			DECODE ( CD_CONSO_CPT , '00472', '3', '9'), --'9', MANTIS=42433 remplacer 9 par '3' Circuit Cible 06-2018
			null,
			'N',
			A_EXTRAIRE,
			--13/02/2019 - CDS Atos (GBD) US673 deb ->
			BUCKET_IFRS9,
			MNT_MTM,
			CD_DEV_MNT_MTM
			--13/02/2019 - CDS Atos (GBD) US673 <- fin
			,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			,DEV_CAPITAL_HORS_ARR  -- 02/08/2021 - CDS ATOS (LFD) - US 231 CRRV4.3
	;
	COMMIT;


	update ENG_RETAIL_AGREG_P5 set CD_DEVISE_AUT   =  case when nvl(MNT_AUTORISATION,0) > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
	update ENG_RETAIL_AGREG_P5 set CD_DEVISE_VTR   =  case when nvl(MNT_VTR,0)          > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
	update ENG_RETAIL_AGREG_P5 set CD_DEVISE_HYPO  =  case when nvl(MNT_HYPOTHEQUE,0)   > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
	update ENG_RETAIL_AGREG_P5 set CD_DEVISE_VR    =  case when nvl(MNT_VR,0)           > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
	update ENG_RETAIL_AGREG_P5 set CD_DEVISE_ARR   =  case when nvl(CD_DEVISE_ARR,0)    > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
	update ENG_RETAIL_AGREG_P5 set CD_DEVISE_DTCO  =  case when nvl(CD_DEVISE_DTCO,0)   > 0 then nvl(CD_DEVISE_LOY_RD,'EUR') end;
	commit;

	--BALE4 Mantis Recette 12751
	update ENG_RETAIL_AGREG_P5 agregP5 set agregP5.MNT_LOY_HORS_ARR = agregP5.MNT_LOY_RD - agregP5.MNT_LOY_AVEC_ARR;
	--

	EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc P_CALCUL_AGREGAT_P5:'||l_position||'-MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc P_CALCUL_AGREGAT_P5:'||l_position,50072);
end P_CALCUL_AGREGAT_P5;


	------------------------------------------------------
	-- nom : procedure P_CALCUL_AGREGAT_P6               --
	-- but : d?versement de ENG_BALOIS_DETAIL_P6 vers    --
	-- ENG_BALOIS_AGREG_P6 quand le top a_extraire =?O?  --
	-- auteur : E.Mipam, le 14/05/2019                  --
	-- entr?e : /                                       --
	-- retour : /                                       --
	------------------------------------------------------
	PROCEDURE P_CALCUL_AGREGAT_P6 IS
		   l_position varchar2(30);

	  BEGIN
      DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
	l_position := 'maj retail agregat P6';
	INSERT INTO ENG_BALOIS_AGREG_P6  (
			   DT_ARRETE                   ,
			   CD_CONSO_CPT                ,
			   ID_TIERS_CALC               ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_ENGAGEMENT               ,
			   CD_CLASSE_PD                ,
			   POURC_TX_PD                 ,
			   CD_CLASSE_LGD               ,
			   TX_LGD_PREDICTIF            ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   MNT_EXPO_POTENT_HT          ,
			   ENCOURS_FINANC_BRUT         ,
			   MNT_ENGT_FINANCMT_HB        ,
			   MNT_IRD                     ,
			   TX_CCF                      ,
			   MNT_EAD_TOT                 ,
			   CD_METHODO_BALE2            ,
			   MNT_RWA                     ,
			   CD_DEVISE                   ,
			   MATURITE_CALC               ,
			   A_EXTRAIRE
		   --      ,TX_LGD_PREDICTIF_HG
				,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques

			 )
			 SELECT DT_ARRETE                ,
			   CD_CONSO_CPT                ,
			   ID_TIERS_CALC               ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_AUTORISATION               ,
			   CD_CLASSE_PD                ,
			   AVG(POURC_TX_PD)            ,
			   CD_CLASSE_LGD               ,
			   AVG(TX_LGD_PREDICTIF      ) ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   sum(MNT_EXPO_POTENT_HT),
			   sum(ENCOURS_FINANC_BRUT),
			   sum(MNT_ENGT_FINANCMT_HB),
			   sum(MNT_IRD)        ,
			   AVG(TX_CCF)                 ,
			   sum(MNT_EAD_TOT)     ,
			   CD_METHODO_BALE2            ,
			   sum(MNT_RWA)         ,
			   CD_DEVISE                   ,
			   AVG(MATURITE_CALC)          ,
			   A_EXTRAIRE
			   ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			FROM ENG_BALOIS_DETAIL_P6
			WHERE A_EXTRAIRE='O'
			GROUP BY DT_ARRETE             ,
			   CD_CONSO_CPT                ,
			   ID_TIERS_CALC               ,
			   ID_AUTORISATION             ,
			   ID_LIGNE_DET                ,
			   ID_AUTORISATION               ,
			   CD_CLASSE_PD                ,
			   CD_CLASSE_LGD               ,
			   CD_PAYS_RESIDENCE           ,
			   CD_SECTEUR_ACTIVITE         ,
			   CD_PORTEFEUILLE_BAL_TIERS   ,
			   NOTE_INTERNE                ,
			   CD_CATEG_CONTREPARTIE       ,
			   CD_METHODO_BALE2            ,
			   CD_DEVISE                   ,
			   A_EXTRAIRE				   ,
			   CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			   ;
		   COMMIT;


	EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
               DBMS_OUTPUT.PUT_LINE('Proc P_CALCUL_AGREGAT_P6:'||l_position||'-MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc P_CALCUL_AGREGAT_P6:'||l_position,50072);
	end P_CALCUL_AGREGAT_P6;


	------------------------------------------------------
	-- nom : procedure P_CALCUL_AGREGAT_P8               --
	-- but : d?versement de PROVISIONS_DETAIL_P8 vers    --
	-- PROVISIONS_AGREG_P8 quand le top a_extraire =?O?  --
	-- auteur : E.Mipam, le 14/05/2019                  --
	-- entr?e : /                                       --
	-- retour : /                                       --
	------------------------------------------------------
	PROCEDURE P_CALCUL_AGREGAT_P8 IS
		   l_position varchar2(30);

	  BEGIN
      DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
	l_position := 'Insert provision agregat P8';
	INSERT INTO PROVISIONS_AGREG_P8
		   (   DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_ENGAGEMENT,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 MNT_PROVISION,
			 MNT_PROVISION_TRIM,
			 CD_DEVISE,
			 CD_PCCO,
			 a_extraire
			 ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
			,MTPROVBIL
			,MTPROVHB
			,MTPROVTRIMBIL
			,MTPROVTRIMHB
			--FIN LFD
		   )
		   SELECT DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_AUTORISATION,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 sum(MNT_PROVISION),
			 sum(MNT_PROVISION_TRIM),
			 CD_DEVISE,
		   MIN(CD_PCCO) KEEP (DENSE_RANK LAST ORDER BY MNT_PROVISION),
			 a_extraire
			 ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 --CDS_ATOS (LFD) - 22/07/2021 - US 140 CRRV4.3
			,SUM(MTPROVBIL)
			,SUM(MTPROVHB)
			,SUM(MTPROVTRIMBIL)
			,SUM(MTPROVTRIMHB)
			--FIN LFD
		   FROM PROVISIONS_DETAIL_P8
		   WHERE A_EXTRAIRE='O'
		   GROUP BY DT_ARRETE,
			 CD_CONSO_CPT,
			 ID_TIERS_CALC,
			 ID_AUTORISATION,
			 ID_LIGNE_DET,
			 ID_AUTORISATION,
			 CD_NAT_DEPRE,
			 CD_PERIM_PROV,
			 CD_DEVISE,
			 a_extraire
			 ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 ;
		   COMMIT;

	EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc P_CALCUL_AGREGAT_P8:'||l_position||'-MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc P_CALCUL_AGREGAT_P8:'||l_position,50072);
	end P_CALCUL_AGREGAT_P8;


	------------------------------------------------------
	-- nom : procedure P_CALCUL_AGREGAT_M5               --
	-- but : d?versement de SURETE_DETAIL_M5 vers       --
	-- SURETE_AGREG_M5 quand le top a_extraire =?O?     --
	-- auteur : E.Mipam, le 14/05/2019                  --
	-- entr?e : /                                       --
	-- retour : /                                       --
	------------------------------------------------------
    -- Modification : 13/01/2021 - CDS-ATOS -EBA001     --
    --   ajout information de la table en cas d'erreurs --
    ------------------------------------------------------
	PROCEDURE P_CALCUL_AGREGAT_M5 IS
		   l_position varchar2(30);
           W_TABLE VARCHAR2(30);

	  BEGIN
      DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
	l_position := 'maj surete agregat M5';
    W_TABLE := 'SURETE_AGREG_M5 (1)';
	INSERT INTO SURETE_AGREG_M5 -- suretes r?elles
			(	DT_ARRETE,
				CD_CONSO_CPT,
				ID_TIERS_CALC,
				ID_ENGAGEMENT,
				ID_SURETE,
				CD_NATOP_CPT,
				CD_TRR,
				ID_TIERS_CALC_GARANT,
				ID_CENTRAL_TIERS_GARANT,
				ID_TYPE_GARANTIE_CASA,
				CD_INFO_COMPL, MNT_GARANTIE,
				MNT_REVISE, CD_DEVISE,
				CD_ELLIGIBILITE,
				MNT_RISQUE,
				CD_TAUX_COUV,
				CD_PLAF_UTIL,
				A_EXTRAIRE
				, USAGE_BIEN_GARANTI   -- 18/02/2019 - CDS ATOS (GBD) - US731
				,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 )
			SELECT DT_ARRETE,
				CD_CONSO_CPT,
				ID_TIERS_CALC,
				ID_LIGNE_DET,
				ID_LIGNE_DET||substr(ID_TIERS_CALC_GARANT,4,11)||substr(id_type_garantie_casa,1,1) || substr(id_type_garantie_casa,5,1) || substr(id_type_garantie_casa,7,1),
				CD_NATOP_CPT,
				CD_TRR,
				ID_TIERS_CALC_GARANT,
				ID_CENTRAL_TIERS_GARANT,
				ID_TYPE_GARANTIE_CASA,
				CD_INFO_COMPL,
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --sum(MNT_GARANTIE),
				CASE WHEN sum(MNT_GARANTIE) is null OR sum(MNT_GARANTIE) <0 then 0 else sum(MNT_GARANTIE) end,
			  -- FIN LFD
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --sum(MNT_REVISE),
				CASE WHEN sum(MNT_REVISE) is null OR sum(MNT_REVISE) <0 then 0 else sum(MNT_REVISE) end,
			  -- FIN LFD
				CD_DEVISE,
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --CD_ELLIGIBILITE,
				nvl(CD_ELLIGIBILITE,'N'), --M71945
			  -- FIN LFD
				sum(MNT_RISQUE),
				CD_TAUX_COUV,
			  -- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
			  --CD_PLAF_UTIL,
				nvl(CD_PLAF_UTIL,9),
			  -- FIN LFD
				'O',
				'0'  USAGE_BIEN_GARANTI  -- 18/02/2019 - CDS ATOS (GBD) - US731
				,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		   FROM (select m5.DT_ARRETE,     m5.CD_CONSO_CPT,  m5.ID_TIERS,   m5.ID_TIERS_CALC,    m5.ID_CENTRAL_TIERS,     m5.ID_AUTORISATION,          m5.ID_LIGNE_DET,  m5.ID_ENGAGEMENT,
			   m5.ID_SURETE,     m5.CD_NATOP_CPT,  m5.CD_TRR,     m5.ID_TIERS_GARANT, m5.ID_TIERS_CALC_GARANT, m5.ID_CENTRAL_TIERS_GARANT,  m5.ID_TYPE_GARANTIE_CASA,
			   m5.CD_INFO_COMPL, m5.MNT_GARANTIE,  m5.MNT_REVISE, m5.CD_DEVISE,       m5.CD_ELLIGIBILITE,      m5.MNT_RISQUE, m5.CD_TAUX_COUV, m5.CD_PLAF_UTIL,   m5.A_EXTRAIRE,
			   DECODE (rs.flag_prem_qualite ,'O', m5.MNT_GARANTIE, 0) mnt_prem_qual
			   ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			   from  SURETE_DETAIL_M5 m5,
			   rs_type_garantie rs
			   where nvl(m5.id_autorisation,'1') = nvl(rs.id_type_garantie, '1')
		  AND m5.A_extraire='O')    --- pas propre, j ai planque dans ce champ qui ne sert ? rien le type de garantie, post agregat on peut le virer idem mnt_risque
			WHERE A_EXTRAIRE='O'
		   group by
			  DT_ARRETE,
			  CD_CONSO_CPT,
			  ID_TIERS_CALC,
			  ID_LIGNE_DET,
			  ID_TIERS_CALC||ID_TIERS_CALC_GARANT||ID_TYPE_GARANTIE_CASA||cd_info_compl||cd_taux_couv||CD_TRR,
			  CD_NATOP_CPT,
			  CD_TRR,
			  ID_TIERS_CALC_GARANT,
			  ID_CENTRAL_TIERS_GARANT,
			  ID_TYPE_GARANTIE_CASA,
			  CD_INFO_COMPL,
			  CD_DEVISE,
			  CD_ELLIGIBILITE,
			  CD_TAUX_COUV,
			  CD_PLAF_UTIL,
			  'O',
						'0'  -- 18/02/2019 - CDS ATOS (GBD) - US731
			 ,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
			 ;
		  commit;

        W_TABLE := 'SURETE_AGREG_M5 (2)';
		UPDATE SURETE_AGREG_M5 M5 SET CD_TAUX_COUV=(SELECT CD_COUV_PROVISION FROM ENG_RETAIL_AGREG_P5 P5 WHERE P5.ID_ENGAGEMENT= M5.ID_ENGAGEMENT);
		COMMIT;

		-- 08/02/19 - CDS ATOS (LFD) - CRRV4.2 US 663
        W_TABLE := 'SURETE_AGREG_M5 (3)';
		UPDATE SURETE_AGREG_M5 set CD_TAUX_COUV = 0 where CD_TAUX_COUV is null;
		commit;
		-- FIN LFD

		-- 26/09/2019 - CDS ATOS (ODUT) - Mantis 49227
		-- Le but de cette Mantis 49227 est d'?viter, si possible, les doublons sur la colonne ID_SURETE afin que le fichier transmis ? CASA soit int?grable.
		-- Ainsi, les modifications apport?es sont:
		--    Pour toutes les occurrences de la table, si la longueur de la colonne ID_SURETE < 40 caract?res, on lui concat?ne le contenu de la colonne CD_TRR.
		--    Pour toutes les occurrences de la table, si la longueur de la colonne ID_SURETE < 40 caract?res, on lui concat?ne le contenu de la colonne CD_ELLIGIBILITE.
        W_TABLE := 'SURETE_AGREG_M5 (4)';
		UPDATE SURETE_AGREG_M5
		   SET ID_SURETE = ID_SURETE||CD_TRR
		WHERE LENGTH(ID_SURETE) < 40;
		COMMIT;

        W_TABLE := 'SURETE_AGREG_M5 (5)';
		UPDATE SURETE_AGREG_M5
		   SET ID_SURETE = ID_SURETE||CD_ELLIGIBILITE
		WHERE LENGTH(ID_SURETE) < 40;
		COMMIT;
		-- Fin Mantis 49227.

	EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc P_CALCUL_AGREGAT_M5:'||l_position|| ' table:'||W_TABLE||'-MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc P_CALCUL_AGREGAT_M5:'||l_position|| ' table:'||W_TABLE,50072);
	end P_CALCUL_AGREGAT_M5;
	--Fin EMM
    ---------------------------
	  PROCEDURE P_alim_A1_AUTO IS
		   	l_position 	varchar2(20);
           	W_TABLE 	varchar2(150);
			g_dt_arrete date := pack_utilitaire.f_calc_dt_arrete;

		 BEGIN
         DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		   l_position := 'A1 automatique';

        W_TABLE := 'A1_DEGRADE_AUTO (1)';
        execute immediate 'truncate table A1_DEGRADE_AUTO';

		-- insert P1
		Insert into a1_degrade_auto
	  (
		DT_ARRETE           ,
		CD_CONSO_CPT        ,
		ID_ENGAGEMENT       ,
		CD_CAP              ,
		CD_PAYS_RESIDENCE   ,
		CD_CONTREPARTIE     ,
		CD_CONSO_PART       ,
		CD_QUAL_PART        ,
		CD_ISIN             ,
		NB_CONTREPARTIE     ,
		CD_METHODO_BALE2    ,
		CD_MOTEUR           ,
		CD_NATURE_CPT       ,
		CD_DEVISE           ,
		CD_PORTEFEUILLE     ,
		CD_NATURE_SSJ       ,
		MNT_RWA             ,
		CD_LFD              ,
		MATURITE_RES        ,
		CD_ENG_DTX          ,
		CD_PASSAGE_DEF      ,
		CD_DUREE            ,
		TX_POND_EXPO        ,
		TX_CCF              ,
		CD_PCCO1            ,
		MNT_PCCO1           ,
		CD_PCCO2            ,
		MNT_PCCO2           ,
		 MNT_ASSIETTE        ,
		 CD_CONSO_ENG        ,
		CD_USAGE_BIEN_IMM   ,
		CD_RESPECT_COND     ,
		MNT_VTR_PDR         ,
		MNT_HYPOTHEQUE      ,
		CD_ACHAT_FIN_LOC    ,
		MNT_VR              ,
		CD_CAP_SURETE       ,
		CD_PAYS_SURETE      ,
		CD_DEPOT_SUR        ,
		CD_CONSO_SUR        ,
		CD_NATURE_SUR       ,
		CD_FOUR_SUR         ,
		CD_FAMILLE_SUR      ,
		CD_PCCO3            ,
		MNT_PCCO3           ,
		CD_VALO_BIEN        ,
		CD_PCCO4            ,
		MNT_PCCO4           ,
		CD_NATURE_PROV      ,
		CD_PCCO5            ,
		MNT_PCCO5           ,
		CD_NATURE_DECO      ,
		DT_SAISIE           ,
		CD_USER             ,
		CD_STATUT_LIGNE     ,
		CORRECTIF
		,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		,BUCKET_IFRS9 -- A1 4.17 - M73798
		)
	  Select
		  P1.DT_ARRETE   ,
		  P1.CD_CONSO_CPT,
		  P1.ID_ENGAGEMENT || '_C',
		nvl((select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P1.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P1.Id_Tiers_calc)) And rownum=1),'05'), --CD_CAP
		  'FR'            ,   --CD_PAYS_RESIDENCE
		  '05'            ,   --CD_CONTREPARTIE
		  '99999'         ,   --CD_CONSO_PART
		  '1'             ,   --CD_QUAL_PART
		  ''              ,   --CD_ISIN
		  ''              ,   --NB_CONTREPARTIE
		  'STD'           ,   --CD_METHODO_BALE2
		  --DECODE(p1.CD_CONSO_CPT, '00472', '07', '01') CD_TRT_MOTEUR, --'07'            ,   --CD_MOTEUR
		  '01' as CD_TRT_MOTEUR,-- M56405 change code moteur de 07 Ã¿Â¿Â½ 01
      --24/08/2018 CDS Atos (EMM) Mantis 44629
		  CASE WHEN CD_NATURE_OPE is null THEN 'NA021' ELSE CD_NATURE_OPE END , --CD_NATURE_CPT
		  --Fin EMM
		  'EUR'           ,   --CD_DEVISE
		  cd_portefeuille_booking             ,   --CD_PORTEFEUILLE
		  NATURE_PROD_SS_JACENT               ,  -- CD_NATURE_SSJ 98 ou null ????
		  ''               ,  -- MNT_RWA 01 ou null       ????
		CASE WHEN (select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P1.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P1.Id_Tiers_calc)) And rownum=1)
			IN (12, 13, 23, 25, 41, 40, 26, 42) THEN 2 ELSE NULL END , --CD_LFD
		  null               ,  --MATURITE_EFF     ,
		  TOP_ENG_DOUTEUX              ,  --CD_ENG_DTX
		  TOP_ENG_DOUTEUX             ,  --CD_PASSAGE_DEF
		  (select  CASE WHEN nvl(O.MATURITE_CALC,0) <= 3 THEN 'Y' else 'N' end  MATURITE_CALC  from btr_operation O Where O.id_operation=P1.Id_Engagement) ,  -- CD_DUREE
		  0                ,  -- TX_POND_EXPO
		  --25/09/2018 CDS ATOS (KKI) Mantis 42434
		  '1',  -- TX_CCF
		  --fin (KKI)
		  PCCO_MNT_CRD               ,  -- CD_PCCO1 ?
		  MNT_CRD     ,  -- MNT_PCCO1
		  ''               ,  -- CD_PCCO2
		  ''                ,  -- MNT_PCCO2
		  MT_ASSIETE_INTERNE       ,  -- MNT_ASSIETTE
		  -- SIRL-165 - MESQUIPE
		  --CD_CONSO_CPT     ,  -- CD_CONSO_ENG
		  case when CD_NATURE_OPE in ('NAT06','NAT07') then CD_CONSO_CPT else null end,	-- CD_CONSO_ENG
		  nvl(CD_USAGE_BIEN_IMM,'0')              ,  -- CD_USAGE_BIEN_IMM
		  nvl(CD_RESPECT_COND,'Y')              ,  -- CD_RESPECT_COND
		  nvl(MNT_VTR_PDR,0)                ,  --MNT_VTR_PDR
		  nvl(mnt_hypotheque,0)                ,  --MNT_HYPOTHEQUE
		  (select DECODE(Rm.CD_METIER, 'CBM', '2', 'CBI', '1', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P1.id_Engagement) CD_ACHAT_FIN_LOC,
		  MNT_VR               ,
		  '12'             ,   -- CD_CAP_SURETE
		  'FR'             ,   -- CD_PAYS_SURETE
		  '07'             ,   -- CD_DEPOT_SUR
		  '99999'          ,   --CD_CONSO_SUR
		  'NAT85'          ,   --CD_NATURE_SUR */
		  (select DECODE(Rm.CD_METIER, 'CBM', 'FR04', 'CBI', 'FR02', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P1.id_Engagement) CD_FOUR_SUR,
		  'P00'            ,   --CD_FAMILLE_SUR
		  ''               ,   --CD_PCCO3       ?????
		  ''                ,   -- MNT_PCCO3  ????
		  '1'              ,   -- CD_VALO_BIEN
		  ''               ,   -- CD_PCCO4    ????
		  ''               ,   -- MNT_PCCO4   ????
		  null             ,   --CD_NATURE_PROV      , -- A1 7.3 - Bï¿½le 4 M12702
		  ''               ,   -- CD_PCCO5         ????
		  ''               ,   -- MNT_PCCO5        ????
		  ''          ,   -- CD_NATURE_DECO : correction 04/08/2017 mettre a null au lieu de NAS03
		  sysdate          ,   -- DT_SAISIE           ,
		  'AUTO'           ,   --CD_USER             ,
		  'V'               ,   --CD_STATUT_LIGNE     ,
		  ''                   ---CORRECTIF
		  ,'CPTA01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,CASE WHEN P1.TOP_ENG_DOUTEUX =  'Y' THEN 'B3'
            	WHEN P1.TOP_ENG_DOUTEUX <> 'Y' THEN 'B1' END BUCKET_IFRS9 -- A1 4.17 - M73798
	  From    ENG_CORP_P1   P1
	  Where P1.A_EXTRAIRE = 'N'
	  AND NVL(MNT_CRD,0) - nvl(MNT_VR,0) > 1;

        W_TABLE := 'A1_DEGRADE_AUTO (2)';
		Insert into a1_degrade_auto
	  (
		DT_ARRETE           ,
		CD_CONSO_CPT        ,
		ID_ENGAGEMENT       ,
		CD_CAP              ,
		CD_PAYS_RESIDENCE   ,
		CD_CONTREPARTIE     ,
		CD_CONSO_PART       ,
		CD_QUAL_PART        ,
		CD_ISIN             ,
		NB_CONTREPARTIE     ,
		CD_METHODO_BALE2    ,
		CD_MOTEUR           ,
		CD_NATURE_CPT       ,
		CD_DEVISE           ,
		CD_PORTEFEUILLE     ,
		CD_NATURE_SSJ       ,
		MNT_RWA             ,
		CD_LFD              ,
		MATURITE_RES        ,
		CD_ENG_DTX          ,
		CD_PASSAGE_DEF      ,
		CD_DUREE            ,
		TX_POND_EXPO        ,
		TX_CCF              ,
		CD_PCCO1            ,
		MNT_PCCO1           ,
		CD_PCCO2            ,
		MNT_PCCO2           ,
		 MNT_ASSIETTE        ,
		 CD_CONSO_ENG        ,
		CD_USAGE_BIEN_IMM   ,
		CD_RESPECT_COND     ,
		MNT_VTR_PDR         ,
		MNT_HYPOTHEQUE      ,
		CD_ACHAT_FIN_LOC    ,
		MNT_VR              ,
		CD_CAP_SURETE       ,
		CD_PAYS_SURETE      ,
		CD_DEPOT_SUR        ,
		CD_CONSO_SUR        ,
		CD_NATURE_SUR       ,
		CD_FOUR_SUR         ,
		CD_FAMILLE_SUR      ,
		CD_PCCO3            ,
		MNT_PCCO3           ,
		CD_VALO_BIEN        ,
		CD_PCCO4            ,
		MNT_PCCO4           ,
		CD_NATURE_PROV      ,
		CD_PCCO5            ,
		MNT_PCCO5           ,
		CD_NATURE_DECO      ,
		DT_SAISIE           ,
		CD_USER             ,
		CD_STATUT_LIGNE     ,
		CORRECTIF
		,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
	    ,BUCKET_IFRS9 -- A1 4.17 - M73798
		)
	  Select
		  P1.DT_ARRETE   ,
		  P1.CD_CONSO_CPT,
		  P1.ID_ENGAGEMENT || '_S',
			  nvl((select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P1.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P1.Id_Tiers_calc)) And rownum=1),'05'), --CD_CAP
		  'FR'            ,   --CD_PAYS_RESIDENCE
		  '05'            ,   --CD_CONTREPARTIE
		  '99999'         ,   --CD_CONSO_PART
		  '1'             ,   --CD_QUAL_PART
		  ''              ,   --CD_ISIN
		  ''              ,   --NB_CONTREPARTIE
		  'STD'           ,   --CD_METHODO_BALE2
		  --DECODE(p1.CD_CONSO_CPT, '00472', '07', '01') CD_TRT_MOTEUR, --'07'            ,   --CD_MOTEUR
		  '01' as CD_MOTEUR,-- M56405 change code moteur de 07 Ã¿Â¿Â½ 01
		  --24/08/2018 CDS Atos (EMM) Mantis 44629
		  CASE WHEN CD_NATURE_OPE is null THEN 'NA021' ELSE CD_NATURE_OPE END , --CD_NATURE_CPT
		  --Fin EMM
		  'EUR'           ,   --CD_DEVISE
		  cd_portefeuille_booking             ,   --CD_PORTEFEUILLE
		  NATURE_PROD_SS_JACENT               ,  -- CD_NATURE_SSJ 98 ou null ????
		  ''               ,  -- MNT_RWA 01 ou null       ????
	  CASE WHEN (select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P1.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P1.Id_Tiers_calc)) And rownum=1)
			IN (12, 13, 23, 25, 41, 40, 26, 42) THEN 2 ELSE NULL END , --CD_LFD
		  null               ,  --MATURITE_EFF     ,
		  TOP_ENG_DOUTEUX              ,  --CD_ENG_DTX
		  TOP_ENG_DOUTEUX              ,  --CD_PASSAGE_DEF
		  (select  CASE WHEN nvl(O.MATURITE_CALC,0) <= 3 THEN 'Y' else 'N' end  MATURITE_CALC  from btr_operation O Where O.id_operation=P1.Id_Engagement) ,  -- CD_DUREE
		  0                ,  -- TX_POND_EXPO
		  --25/09/2018 CDS ATOS (KKI) Mantis 42434
		  '1',  -- TX_CCF
		  -- fin (KKI)
		  PCCO_MNT_SOLDE               ,  -- CD_PCCO1 ?
		  MNT_SOLDE    ,  -- MNT_PCCO1
		  ''               ,  -- CD_PCCO2
		  ''                ,  -- MNT_PCCO2
		  MT_ASSIETE_INTERNE       ,  -- MNT_ASSIETTE
		  -- SIRL-165 - MESQUIPE
		  --CD_CONSO_CPT     ,  -- CD_CONSO_ENG
		  case when CD_NATURE_OPE in ('NAT06','NAT07') then CD_CONSO_CPT else null end,	-- CD_CONSO_ENG
		  nvl(CD_USAGE_BIEN_IMM,'0')              ,  -- CD_USAGE_BIEN_IMM
		  nvl(CD_RESPECT_COND,'Y')              ,  -- CD_RESPECT_COND
		  nvl(MNT_VTR_PDR,0)                ,  --MNT_VTR_PDR
		  nvl(mnt_hypotheque,0)                ,  --MNT_HYPOTHEQUE
		  (select DECODE(Rm.CD_METIER, 'CBM', '2', 'CBI', '1', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P1.id_Engagement) CD_ACHAT_FIN_LOC,
		  MNT_VR               ,
		  '12'             ,   -- CD_CAP_SURETE
		  'FR'             ,   -- CD_PAYS_SURETE
		  '07'             ,   -- CD_DEPOT_SUR
		  '99999'          ,   --CD_CONSO_SUR
		  'NAT85'          ,   --CD_NATURE_SUR */
		  (select DECODE(Rm.CD_METIER, 'CBM', 'FR04', 'CBI', 'FR02', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P1.id_Engagement) CD_FOUR_SUR,
		  'P00'            ,   --CD_FAMILLE_SUR
		  ''               ,   --CD_PCCO3       ?????
		  ''                ,   -- MNT_PCCO3  ????
		  '1'              ,   -- CD_VALO_BIEN
		  ''               ,   -- CD_PCCO4    ????
		  ''               ,   -- MNT_PCCO4   ????
		  null             ,   --CD_NATURE_PROV      , -- A1 7.3 - Bï¿½le 4 M12702
		  ''               ,   -- CD_PCCO5         ????
		  ''               ,   -- MNT_PCCO5        ????
		  ''          ,   -- CD_NATURE_DECO : correction 04/08/2017 mettre null a la place de NAS03
		  sysdate          ,   -- DT_SAISIE           ,
		  'AUTO'           ,   --CD_USER             ,
		  'V'               ,   --CD_STATUT_LIGNE     ,
		  ''                   ---CORRECTIF
		  ,'CPTA01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,CASE WHEN P1.TOP_ENG_DOUTEUX =  'Y' THEN 'B3'
            	WHEN P1.TOP_ENG_DOUTEUX <> 'Y' THEN 'B1' END BUCKET_IFRS9 -- A1 4.17 - M73798
	  From    ENG_CORP_P1   P1
	  Where P1.A_EXTRAIRE = 'N'
	  AND NVL(MNT_SOLDE,0) > 1;

	  COMMIT;

	  -- insert P2

      W_TABLE := 'A1_DEGRADE_AUTO (3)';
	  Insert into a1_degrade_auto
	  (
		DT_ARRETE           ,
		CD_CONSO_CPT        ,
		ID_ENGAGEMENT       ,
		CD_CAP              ,
		CD_PAYS_RESIDENCE   ,
		CD_CONTREPARTIE     ,
		CD_CONSO_PART       ,
		CD_QUAL_PART        ,
		CD_ISIN             ,
		NB_CONTREPARTIE     ,
		CD_METHODO_BALE2    ,
		CD_MOTEUR           ,
		CD_NATURE_CPT       ,
		CD_DEVISE           ,
		CD_PORTEFEUILLE     ,
		CD_NATURE_SSJ       ,
		MNT_RWA             ,
		CD_LFD              ,
		MATURITE_RES        ,
		CD_ENG_DTX          ,
		CD_PASSAGE_DEF      ,
		CD_DUREE            ,
		TX_POND_EXPO        ,
		TX_CCF              ,
		CD_PCCO1            ,
		MNT_PCCO1           ,
		CD_PCCO2            ,
		MNT_PCCO2           ,
		 MNT_ASSIETTE        ,
		 CD_CONSO_ENG        ,
		CD_USAGE_BIEN_IMM   ,
		CD_RESPECT_COND     ,
		MNT_VTR_PDR         ,
		MNT_HYPOTHEQUE      ,
		CD_ACHAT_FIN_LOC    ,
		MNT_VR              ,
		CD_CAP_SURETE       ,
		CD_PAYS_SURETE      ,
		CD_DEPOT_SUR        ,
		CD_CONSO_SUR        ,
		CD_NATURE_SUR       ,
		CD_FOUR_SUR         ,
		CD_FAMILLE_SUR      ,
		CD_PCCO3            ,
		MNT_PCCO3           ,
		CD_VALO_BIEN        ,
		CD_PCCO4            ,
		MNT_PCCO4           ,
		CD_NATURE_PROV      ,
		CD_PCCO5            ,
		MNT_PCCO5           ,
		CD_NATURE_DECO      ,
		DT_SAISIE           ,
		CD_USER             ,
		CD_STATUT_LIGNE     ,
		CORRECTIF
		,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		,BUCKET_IFRS9 -- A1 4.17 - M73798
		)
	  Select
		  P2.DT_ARRETE   ,
		  P2.CD_CONSO_CPT,
		  P2.ID_ENGAGEMENT,
		nvl((select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P2.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P2.Id_Tiers_calc)) And rownum=1),'05'), --CD_CAP
		  'FR'            ,   --CD_PAYS_RESIDENCE
		  '05'            ,   --CD_CONTREPARTIE
		  '99999'         ,   --CD_CONSO_PART
		  '1'             ,   --CD_QUAL_PART
		  ''              ,   --CD_ISIN
		  ''              ,   --NB_CONTREPARTIE
		  'STD'           ,   --CD_METHODO_BALE2
		  --DECODE(P2.CD_CONSO_CPT, '00472', '07', '01') CD_TRT_MOTEUR, --'07'            ,   --CD_MOTEUR
		  '01' as CD_MOTEUR,-- M56405 change code moteur de 07 Ã¿Â¿Â½ 01
		  --24/08/2018 CDS Atos (EMM) Mantis 44629
		  CASE WHEN CD_NATURE_OPE is null THEN 'NA021' ELSE CD_NATURE_OPE END , --CD_NATURE_CPT
		  --Fin EMM
		  'EUR'           ,   --CD_DEVISE
		  nvl(cd_portefeuille_booking,'B')             ,   --CD_PORTEFEUILLE
		  ''               ,  -- CD_NATURE_SSJ 98 ou null ????
		  ''               ,  -- MNT_RWA 01 ou null       ????
		  CASE WHEN (select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P2.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P2.Id_Tiers_calc)) And rownum=1)
			IN (12, 13, 23, 25, 41, 40, 26, 42) THEN 2 ELSE NULL END , --CD_LFD
		  null               ,  --MATURITE_EFF     ,
		  CD_ENG_DTX              ,  --CD_ENG_DTX
		  CD_ENG_DTX              ,  --CD_PASSAGE_DEF
		  (select  CASE WHEN nvl(O.MATURITE_CALC,0) <= 3 THEN 'Y' else 'N' end  MATURITE_CALC  from btr_operation O Where O.id_operation=P2.Id_Engagement) ,  -- CD_DUREE
		  0                ,  -- TX_POND_EXPO
		  --25/09/2018 CDS ATOS (KKI) Mantis 42434
		  '0.2',  -- TX_CCF
		  --fin (KKI)
		  PCCO_MNT_PNU               ,  -- CD_PCCO1 ?
		  MNT_PNU     ,  -- MNT_PCCO1
		   ''               ,  -- CD_PCCO2
		  ''                ,  -- MNT_PCCO2
		  0       ,  -- MNT_ASSIETTE
		  -- SIRL-165 - MESQUIPE
		  --''     ,  -- CD_CONSO_ENG
		  case when CD_NATURE_OPE in ('NAT06','NAT07') then CD_CONSO_CPT else null end,	-- CD_CONSO_ENG
		  nvl(CD_USAGE_BIEN_IMM,'0')              ,  -- CD_USAGE_BIEN_IMM
		  'Y'              ,  -- CD_RESPECT_COND
		  MNT_VTR_PDR                ,  --MNT_VTR_PDR
		  0                ,  --MNT_HYPOTHEQUE
		  (select DECODE(Rm.CD_METIER, 'CBM', '2', 'CBI', '1', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P2.id_Engagement) CD_ACHAT_FIN_LOC,
		  MNT_VTR_PDR               ,
		  '12'             ,   -- CD_CAP_SURETE
		  'FR'             ,   -- CD_PAYS_SURETE
		  '07'             ,   -- CD_DEPOT_SUR
		  '99999'          ,   --CD_CONSO_SUR
		  'NAT85'          ,   --CD_NATURE_SUR */
		  (select DECODE(Rm.CD_METIER, 'CBM', 'FR04', 'CBI', 'FR02', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P2.id_Engagement) CD_FOUR_SUR,
		  'P00'            ,   --CD_FAMILLE_SUR
		  ''               ,   --CD_PCCO3       ?????
		  ''                ,   -- MNT_PCCO3  ????
		  '1'              ,   -- CD_VALO_BIEN
		  ''               ,   -- CD_PCCO4    ????
		  ''               ,   -- MNT_PCCO4   ????
		  null             ,   --CD_NATURE_PROV      ,-- A1 7.3 - Bï¿½le 4 M12702
		  ''               ,   -- CD_PCCO5         ????
		  ''               ,   -- MNT_PCCO5        ????
		  ''          ,   -- CD_NATURE_DECO : correction 04/08/2017 mettre null a la place de NAS03
		  sysdate          ,   -- DT_SAISIE           ,
		  'AUTO'           ,   --CD_USER             ,
		  'V'               ,   --CD_STATUT_LIGNE     ,
		  ''                   ---CORRECTIF
			,'CPTA01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,CASE WHEN P2.CD_ENG_DTX =  'Y' THEN 'B3'
            	WHEN P2.CD_ENG_DTX <> 'Y' THEN 'B1' END BUCKET_IFRS9 -- A1 4.17 - M73798
	  From    ENG_CORP_P2   P2
	  Where P2.A_EXTRAIRE = 'N'
	  AND nvl(P2.MNT_PNU,0) >1
	  ;

	  COMMIT;


	  --insert P5
      W_TABLE := 'A1_DEGRADE_AUTO (4)';
	  Insert into a1_degrade_auto
	  (
		DT_ARRETE           ,
		CD_CONSO_CPT        ,
		ID_ENGAGEMENT       ,
		CD_CAP              ,
		CD_PAYS_RESIDENCE   ,
		CD_CONTREPARTIE     ,
		CD_CONSO_PART       ,
		CD_QUAL_PART        ,
		CD_ISIN             ,
		NB_CONTREPARTIE     ,
		CD_METHODO_BALE2    ,
		CD_MOTEUR           ,
		CD_NATURE_CPT       ,
		CD_DEVISE           ,
		CD_PORTEFEUILLE     ,
		CD_NATURE_SSJ       ,
		MNT_RWA             ,
		CD_LFD              ,
		MATURITE_RES        ,
		CD_ENG_DTX          ,
		CD_PASSAGE_DEF      ,
		CD_DUREE            ,
		TX_POND_EXPO        ,
		TX_CCF              ,
		CD_PCCO1            ,
		MNT_PCCO1           ,
		CD_PCCO2            ,
		MNT_PCCO2           ,
		 MNT_ASSIETTE        ,
		 CD_CONSO_ENG        ,
		CD_USAGE_BIEN_IMM   ,
		CD_RESPECT_COND     ,
		MNT_VTR_PDR         ,
		MNT_HYPOTHEQUE      ,
		CD_ACHAT_FIN_LOC    ,
		MNT_VR              ,
		CD_CAP_SURETE       ,
		CD_PAYS_SURETE      ,
		CD_DEPOT_SUR        ,
		CD_CONSO_SUR        ,
		CD_NATURE_SUR       ,
		CD_FOUR_SUR         ,
		CD_FAMILLE_SUR      ,
		CD_PCCO3            ,
		MNT_PCCO3           ,
		CD_VALO_BIEN        ,
		CD_PCCO4            ,
		MNT_PCCO4           ,
		CD_NATURE_PROV      ,
		CD_PCCO5            ,
		MNT_PCCO5           ,
		CD_NATURE_DECO      ,
		DT_SAISIE           ,
		CD_USER             ,
		CD_STATUT_LIGNE     ,
		CORRECTIF
		,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		,BUCKET_IFRS9 -- A1 4.17 - M73798
		)
	  Select
		  P5.DT_ARRETE   ,
		  P5.CD_CONSO_CPT,
		  P5.ID_ENGAGEMENT || '_C',
	  nvl((select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P5.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P5.Id_Tiers_calc)) And rownum=1),'05'), --CD_CAP
		  'FR'            ,   --CD_PAYS_RESIDENCE
		  '05'            ,   --CD_CONTREPARTIE
		  '99999'         ,   --CD_CONSO_PART
		  '1'             ,   --CD_QUAL_PART
		  ''              ,   --CD_ISIN
		  ''              ,   --NB_CONTREPARTIE
		  'STD'           ,   --CD_METHODO_BALE2
		  CD_TRT_MOTEUR            ,   --CD_TRT_MOTEUR
		  --24/08/2018 CDS Atos (EMM) Mantis 44629
		  CASE WHEN CD_NATURE_OPE is null THEN 'NA021' ELSE CD_NATURE_OPE END , --CD_NATURE_CPT
		  --Fin EMM
		  'EUR'           ,   --CD_DEVISE
		  'B'             ,   --CD_PORTEFEUILLE
		  ''               ,  -- CD_NATURE_SSJ 98 ou null ????
		  ''               ,  -- MNT_RWA 01 ou null       ????
		  CASE WHEN (select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P5.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P5.Id_Tiers_calc)) And rownum=1)
			IN (12, 13, 23, 25, 41, 40, 26, 42) THEN 2 ELSE NULL END , --CD_LFD
		  ''               ,  --MATURITE_EFF     ,
		  TOP_ENG_DOUTEUX              ,  --CD_ENG_DTX
		  CD_IMP_PRUDENT              ,  --CD_PASSAGE_DEF
		  (select  CASE WHEN nvl(O.MATURITE_CALC,0) <= 3 THEN 'Y' else 'N' end  MATURITE_CALC  from btr_operation O Where O.id_operation=P5.Id_Engagement) ,  -- CD_DUREE
		  0                ,  -- TX_POND_EXPO
		  ''       ,  -- TX_CCF
		  CD_PCEC_CRD               ,  -- CD_PCCO1 ?
		   mnt_loy_rd_crd     ,  -- MNT_PCCO1
		   ''               ,  -- CD_PCCO2
		  ''                ,  -- MNT_PCCO2
		  MNT_CONTRAT       ,  -- MNT_ASSIETTE
		  -- SIRL-165 - MESQUIPE
		  --CD_CONSO_CPT     ,  -- CD_CONSO_ENG
		  case when CD_NATURE_OPE in ('NAT06','NAT07') then CD_CONSO_CPT else null end,	-- CD_CONSO_ENG
		  cd_usage_bien_imm              ,  -- CD_USAGE_BIEN_IMM
		  cd_respect_cond              ,  -- CD_RESPECT_COND
		  mnt_vtr                ,  --MNT_VTR_PDR
		  0                ,  --MNT_HYPOTHEQUE
		  (select DECODE(Rm.CD_METIER, 'CBM', '2', 'CBI', '1', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P5.id_Engagement) CD_ACHAT_FIN_LOC,
		  MNT_VR               ,
		  '12'             ,   -- CD_CAP_SURETE
		  'FR'             ,   -- CD_PAYS_SURETE
		  '07'             ,   -- CD_DEPOT_SUR
		  '99999'          ,   --CD_CONSO_SUR
		  'NAT85'          ,   --CD_NATURE_SUR */
		  (select DECODE(Rm.CD_METIER, 'CBM', 'FR04', 'CBI', 'FR02', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P5.id_Engagement) CD_FOUR_SUR,
		  'P00'            ,   --CD_FAMILLE_SUR
		  ''               ,   --CD_PCCO3       ?????
		  ''                ,   -- MNT_PCCO3  ????
		  '1'              ,   -- CD_VALO_BIEN
		  ''               ,   -- CD_PCCO4    ????
		  ''               ,   -- MNT_PCCO4   ????
		  null             ,   --CD_NATURE_PROV      ,-- A1 7.3 - Bï¿½le 4 M12702
		  ''               ,   -- CD_PCCO5         ????
		  ''               ,   -- MNT_PCCO5        ????
		  ''          ,   -- CD_NATURE_DECO : 04/08/2017 mettre null a la place de NAS03
		  sysdate          ,   -- DT_SAISIE           ,
		  'AUTO'           ,   --CD_USER             ,
		  'V'               ,   --CD_STATUT_LIGNE     ,
		  ''                   ---CORRECTIF
			,'CPTA01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,CASE WHEN P5.TOP_ENG_DOUTEUX =  'Y' THEN 'B3'
            	WHEN P5.TOP_ENG_DOUTEUX <> 'Y' THEN 'B1' END BUCKET_IFRS9 -- A1 4.17 - M73798
	  From    ENG_RETAIL_DETAIL_P5   P5
	  Where P5.A_EXTRAIRE = 'N'
	  and nvl(mnt_loy_rd_crd,0) >1;
	  COMMIT;

      W_TABLE := 'A1_DEGRADE_AUTO (5)';
	  Insert into a1_degrade_auto
	  (
		DT_ARRETE           ,
		CD_CONSO_CPT        ,
		ID_ENGAGEMENT       ,
		CD_CAP              ,
		CD_PAYS_RESIDENCE   ,
		CD_CONTREPARTIE     ,
		CD_CONSO_PART       ,
		CD_QUAL_PART        ,
		CD_ISIN             ,
		NB_CONTREPARTIE     ,
		CD_METHODO_BALE2    ,
		CD_MOTEUR           ,
		CD_NATURE_CPT       ,
		CD_DEVISE           ,
		CD_PORTEFEUILLE     ,
		CD_NATURE_SSJ       ,
		MNT_RWA             ,
		CD_LFD              ,
		MATURITE_RES        ,
		CD_ENG_DTX          ,
		CD_PASSAGE_DEF      ,
		CD_DUREE            ,
		TX_POND_EXPO        ,
		TX_CCF              ,
		CD_PCCO1            ,
		MNT_PCCO1           ,
		CD_PCCO2            ,
		MNT_PCCO2           ,
		 MNT_ASSIETTE        ,
		 CD_CONSO_ENG        ,
		CD_USAGE_BIEN_IMM   ,
		CD_RESPECT_COND     ,
		MNT_VTR_PDR         ,
		MNT_HYPOTHEQUE      ,
		CD_ACHAT_FIN_LOC    ,
		MNT_VR              ,
		CD_CAP_SURETE       ,
		CD_PAYS_SURETE      ,
		CD_DEPOT_SUR        ,
		CD_CONSO_SUR        ,
		CD_NATURE_SUR       ,
		CD_FOUR_SUR         ,
		CD_FAMILLE_SUR      ,
		CD_PCCO3            ,
		MNT_PCCO3           ,
		CD_VALO_BIEN        ,
		CD_PCCO4            ,
		MNT_PCCO4           ,
		CD_NATURE_PROV      ,
		CD_PCCO5            ,
		MNT_PCCO5           ,
		CD_NATURE_DECO      ,
		DT_SAISIE           ,
		CD_USER             ,
		CD_STATUT_LIGNE     ,
		CORRECTIF
		,CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		,BUCKET_IFRS9 -- A1 4.17 - M73798
		)
	  Select
		  P5.DT_ARRETE   ,
		  P5.CD_CONSO_CPT,
		  P5.ID_ENGAGEMENT || '_S',
	  nvl((select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P5.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From  RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P5.Id_Tiers_calc)) And rownum=1),'05'), --CD_CAP
		  'FR'            ,   --CD_PAYS_RESIDENCE
		  '05'            ,   --CD_CONTREPARTIE
		  '99999'         ,   --CD_CONSO_PART
		  '1'             ,   --CD_QUAL_PART
		  ''              ,   --CD_ISIN
		  ''              ,   --NB_CONTREPARTIE
		  'STD'           ,   --CD_METHODO_BALE2
		  CD_TRT_MOTEUR            ,   --CD_TRT_MOTEUR
		  --24/08/2018 CDS Atos (EMM) Mantis 44629
		  CASE WHEN CD_NATURE_OPE is null THEN 'NA021' ELSE CD_NATURE_OPE END , --CD_NATURE_CPT
		  --Fin EMM
		  'EUR'           ,   --CD_DEVISE
		  'B'             ,   --CD_PORTEFEUILLE
		  ''               ,  -- CD_NATURE_SSJ 98 ou null ????
		  ''               ,  -- MNT_RWA 01 ou null       ????
			CASE WHEN (select Pr.VAL_RESULTAT1 from PARAM_MULTIDIM_GENERIQUE pr Where (pr.CODE_PARAM_1='CD_PORTEFEUIL_OP' And pr.VAL_PARAM_1=P5.CD_PORTEFEUILLE_BALE2) And (Pr.Code_Param_2='CD_PORTEFEUILLE_BAL_TIERS'  and pr.code_param_3='CD_CATEG_CONTREPARTIE' And (Pr.Val_Param_2,pr.val_param_3) in (Select Distinct Tr.CD_PTF_BALE_TIERS,Tr.CD_CATEG_CONTREPARTIE From RS_CORRES_CATEG_CPY_PTF_BALE Tr, tie_tiers_c1_c5 T Where Tr.CD_CATEG_CONTREPARTIE=T.CD_CATEG_CONTREPARTIE And T.Id_Tiers_calc = P5.Id_Tiers_calc)) And rownum=1)
			IN (12, 13, 23, 25, 41, 40, 26, 42) THEN 2 ELSE NULL END , --CD_LFD
		  ''               ,  --MATURITE_EFF     ,
		  TOP_ENG_DOUTEUX              ,  --CD_ENG_DTX
		  CD_IMP_PRUDENT              ,  --CD_PASSAGE_DEF
		  (select  CASE WHEN nvl(O.MATURITE_CALC,0) <= 3 THEN 'Y' else 'N' end  MATURITE_CALC  from btr_operation O Where O.id_operation=P5.Id_Engagement) ,  -- CD_DUREE
		  0                ,  -- TX_POND_EXPO
		  ''       ,  -- TX_CCF
		  cd_pcec_sold_k_a               ,  -- CD_PCCO1 ?
		  mnt_loy_rd_sold     ,  -- MNT_PCCO1
		   ''               ,  -- CD_PCCO2
		  ''                ,  -- MNT_PCCO2
		  MNT_CONTRAT       ,  -- MNT_ASSIETTE
		  -- SIRL-165 - MESQUIPE
		  --CD_CONSO_CPT     ,  -- CD_CONSO_ENG
		  case when CD_NATURE_OPE in ('NAT06','NAT07') then CD_CONSO_CPT else null end,	-- CD_CONSO_ENG
		  cd_usage_bien_imm              ,  -- CD_USAGE_BIEN_IMM
		  cd_respect_cond              ,  -- CD_RESPECT_COND
		  mnt_vtr                ,  --MNT_VTR_PDR
		  0                ,  --MNT_HYPOTHEQUE
		  (select DECODE(Rm.CD_METIER, 'CBM', '2', 'CBI', '1', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P5.id_Engagement) CD_ACHAT_FIN_LOC,
		  MNT_VR               ,
		  '12'             ,   -- CD_CAP_SURETE
		  'FR'             ,   -- CD_PAYS_SURETE
		  '07'             ,   -- CD_DEPOT_SUR
		  '99999'          ,   --CD_CONSO_SUR
		  'NAT85'          ,   --CD_NATURE_SUR */
		  (select DECODE(Rm.CD_METIER, 'CBM', 'FR04', 'CBI', 'FR02', '')  FROM BTR_OPERATION O, rs_corres_soc_juri_metier Rm Where Rm.CD_SOC_JURI = O.CD_SOC_JURI And O.id_operation = P5.id_Engagement) CD_FOUR_SUR,
		  'P00'            ,   --CD_FAMILLE_SUR
		  ''               ,   --CD_PCCO3       ?????
		  ''                ,   -- MNT_PCCO3  ????
		  '1'              ,   -- CD_VALO_BIEN
		  ''               ,   -- CD_PCCO4    ????
		  ''               ,   -- MNT_PCCO4   ????
		  null             ,   --CD_NATURE_PROV      ,-- A1 7.3 - Bï¿½le 4 M12702
		  ''               ,   -- CD_PCCO5         ????
		  ''               ,   -- MNT_PCCO5        ????
		  ''          ,   -- CD_NATURE_DECO : 04/08/2017 mettre null a la place de NAS03
		  sysdate          ,   -- DT_SAISIE           ,
		  'AUTO'           ,   --CD_USER             ,
		  'V'               ,   --CD_STATUT_LIGNE     ,
		  ''                   ---CORRECTIF
		  ,'CPTA01' CD_TYPE_PROD_BANCAIRE --CDS_ATOS (MNE) - 09/07/2021 - US139 - Type Produit bancaire - donnees de convergence finance risques
		  ,CASE WHEN P5.TOP_ENG_DOUTEUX =  'Y' THEN 'B3'
            	WHEN P5.TOP_ENG_DOUTEUX <> 'Y' THEN 'B1' END BUCKET_IFRS9 -- A1 4.17 - M73798
	  From    ENG_RETAIL_DETAIL_P5   P5
	  Where P5.A_EXTRAIRE = 'N'
	  and nvl(mnt_loy_rd_sold,0) >0;
	  COMMIT;

      W_TABLE := 'A1_DEGRADE_AUTO (6)';
	  UPDATE A1_DEGRADE_AUTO set CD_STATUT_LIGNE='A' WHERE CD_PCCO1 is null;
	  COMMIT;

      W_TABLE := 'A1_DEGRADE_AUTO (7)';
	  UPDATE A1_DEGRADE_AUTO set CD_STATUT_LIGNE='A' WHERE CD_NATURE_CPT='NAT05';
	  COMMIT;

	  	-- DEBUT :: KLx_Risques :: M67591 - calculer CD_NATURE_CPT a partir de CD_CAP
		---- perimetre d'alimentation P1 :: sufixes _C et _S
		W_TABLE := 'TABLE: a1_degrade_auto :: maj cd_nature_cpt - perimetre P1';
		merge
		 into a1_degrade_auto a1_maj
		using (select a1.id_engagement as ID_ENGAGEMENT
					, a1.dt_arrete     as DT_ARRETE
					, a1.cd_conso_cpt  as CD_CONSO_CPT
					, a1.cd_cap        as CD_CAP
					, bt.cd_categ_cpt  as CD_CATEG_CPT --juste pour controler
					, case
					  when p1.cd_nature_ope is null
					  then 'NA021'

					  when bien.cd_statut_act = 'ATNL'
					  then 'NAT05'

					  when a1.cd_cap in ('12','23')
					  then case
                           when bt.cd_categ_cpt in ('DTX','DTCO')
                           then 'NA012'
                           else 'NA011'
                            end

					  when a1.cd_cap not in ('12','23')
					  then case
                           when bt.cd_categ_cpt in ('DTX','DTCO')
                           then 'NA022'
                           else 'NA021'
                            end
					  else 'NA020'
					   end CD_NATURE_CPT
				 from ddrex.eng_corp_p1     p1
					, ddrex.btr_tiers       bt
					, ddrex.btr_operation   bo
					, ddrex.a1_degrade_auto a1
					, (select cd_sys_int
							, id_operation
                            , dt_arrete
							, min(cd_statut_act)
							  keep (dense_rank
										 first
										 order
											by decode(cd_statut_act,'ATNL','1'
																   ,'LOUE','2'
																   ,'AENC','3'
																   ,'CEDE','4'
																   ,'CDNL','5')) CD_STATUT_ACT
						 from ddrex.btr_surete_reelle
				        group
				           by cd_sys_int, id_operation, dt_arrete) bien
				where p1.id_engagement = bo.id_operation
				  and p1.dt_arrete     = bo.dt_arrete
                  --- comme le perim. P1 a toujours le sufixe _C ou _S donc on n'aura pas des problemes
				  and p1.dt_arrete     = a1.dt_arrete
				  and p1.cd_conso_cpt  = a1.cd_conso_cpt
				  and p1.id_engagement = substr(a1.id_engagement,1,length(a1.id_engagement)-2)
                  ---
				  and bo.id_tiers      = bt.id_tiers
				  and bo.dt_arrete     = bt.dt_arrete
				  ---
				  and bo.cd_sys_int    = bien.cd_sys_int   (+)
				  and bo.id_operation  = bien.id_operation (+)
                  and bo.dt_arrete     = bien.dt_arrete    (+)
				  --- params default
				  and bt.cd_type_sgmt   = 'CORP'
				  and bt.cd_role_tiers  = 'C'
				  and p1.dt_arrete      = g_dt_arrete) peri
		   on (a1_maj.dt_arrete     = peri.dt_arrete
		  and  a1_maj.cd_conso_cpt  = peri.cd_conso_cpt
		  and  a1_maj.id_engagement = peri.id_engagement
		  and  a1_maj.cd_cap        = peri.cd_cap)
		 when matched then
		 	update
			   set a1_maj.cd_nature_cpt = peri.cd_nature_cpt;
			commit;

		---- perimetre d'alimentation P5 :: sufixes _C et _S
		W_TABLE := 'TABLE: a1_degrade_auto :: maj cd_nature_cpt - perimetre P5';
		merge
		 into a1_degrade_auto a1_maj
		using (select a1.id_engagement as ID_ENGAGEMENT
					, a1.dt_arrete     as DT_ARRETE
					, a1.cd_conso_cpt  as CD_CONSO_CPT
					, a1.cd_cap        as CD_CAP
					, bt.cd_categ_cpt  as CD_CATEG_CPT  --juste pour controler
					, p5.cd_nature_ope as CD_NATURE_OPE --juste pour controler
					, case
					  when p5.cd_nature_ope is null
					  then 'NA021'

					  when a1.cd_cap in ('12','23')
                      then case
                           when bt.cd_categ_cpt in ('DTX','DTCO')
						   then 'NA012'
                           else 'NA011'
							end

					  when a1.cd_cap not in ('12','23')
                      then case
                           --- afin de traiter le probleme trouve le 18/12/2023
                           --- RG apliquee dans la M_68356
                           when bt.cd_categ_cpt in ('DTX','DTCO')
						   then 'NA022'
                           else 'NA021'
                            end
                       end CD_NATURE_CPT
				 from ddrex.eng_retail_detail_p5 p5
                    , ddrex.btr_tiers            bt
                    , ddrex.btr_operation        bo
                    , ddrex.a1_degrade_auto      a1
                    , (select distinct
                              cd_sys_int
							, id_operation
							, dt_arrete
                         from ddrex.btr_surete_reelle) sr
				where p5.id_engagement = bo.id_operation
				  and p5.dt_arrete     = bo.dt_arrete
				  --- comme le perim. P5 a toujours le sufixe _C ou _S donc on n'aura pas des problemes
				  and p5.cd_conso_cpt  = a1.cd_conso_cpt
				  and p5.dt_arrete     = a1.dt_arrete
				  and p5.id_engagement = substr(a1.id_engagement,1,length(a1.id_engagement)-2)
				  ---
				  and bo.id_tiers      = bt.id_tiers
				  and bo.dt_arrete     = bt.dt_arrete
				  ---
				  and bo.cd_sys_int    = sr.cd_sys_int   (+)
				  and bo.id_operation  = sr.id_operation (+)
				  and bo.dt_arrete     = sr.dt_arrete    (+)
				  --- params default
				  and bt.cd_role_tiers = 'C'
				  and p5.dt_arrete     = g_dt_arrete) peri
		   on (a1_maj.dt_arrete     = peri.dt_arrete
		  and  a1_maj.cd_conso_cpt  = peri.cd_conso_cpt
		  and  a1_maj.id_engagement = peri.id_engagement
		  and  a1_maj.cd_cap        = peri.cd_cap)
		 when matched then
		 	update
			   set a1_maj.cd_nature_cpt = peri.cd_nature_cpt;
			commit;
		-- FIN :: KLx_Risques :: M67591 - calculer CD_NATURE_CPT a partir de CD_CAP

	  EXCEPTION
		   WHEN OTHERS THEN
			  ROLLBACK;
              DBMS_OUTPUT.PUT_LINE('Proc P_alim_A1_AUTO:'||l_position ||' table:'||W_TABLE||'-MESS:'||SQLERRM);
			   pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc P_alim_A1_AUTO:'||l_position|| ' table:'||W_TABLE,50072);
	  end P_alim_A1_AUTO;
    /********************************************/
	/* 28/03/2018 CDS ATOS (JMP) US33 ANACREDIT */
	/* Creation de la fonction */

		function f_cd_motif_sco_lc0267(CD_CATEG_CPT in varchar2, CD_MOTIF_POS_SCO in varchar2, NBRE_IMPY in number, NOTE_BALOISE in varchar2 ) return varchar2 is
		v_ret varchar2(3);
		begin
        DBMS_OUTPUT.ENABLE(buffer_size=>NULL);
		v_ret:=null;
		if (CD_CATEG_CPT in ('DTX', 'DTCO') ) then
			   v_ret := CASE NVL(CD_MOTIF_POS_SCO,'x') when 'SCO2' THEN '160'
						WHEN 'SCO3' THEN '160'
						WHEN 'SCO6' THEN '60'
						WHEN  'SCO9' THEN '150'
						else  case when NVL(NBRE_IMPY,0)>90 THEN '90'
						else
						 case NVL(NOTE_BALOISE,'x') WHEN'F' THEN '200'
						 when'Z' THEN '210'
						 ELSE'100'
						 END
						 end
						 end;
		end if;
		return v_ret;
		end f_cd_motif_sco_lc0267;


	  -----------------------------------------------------------
	  -- nom : procedure p_alim_ind_isf                   	   --
	  -- but : Injecter les donnees ISF sur BTR_OPERATION      --
	  -- auteur : GOMESHU - 27/03/2024                         --
	  -- retour : MAJ table BTR_OPERATION                      --
	  -- Modification:                                         --
	  ------------------------------------------------------------
	  PROCEDURE p_alim_ind_isf IS

	  BEGIN

		-- BTR_OPERATION
	  	merge into btr_operation o
		  using (
			  select fipuni.id_operation, decode(fipuni.ind_qualification_isf,'Y','1','N','2') ind_isf
			  from eng_fipuni_taxonomie fipuni
 		  ) perim
		on ( o.id_operation = perim.id_operation )
		when matched then update
		set o.ind_isf = perim.ind_isf;

		COMMIT;

		-- BTR_HORS_BILAN
	  	/*merge into btr_hors_bilan hb
		  using (
			  select distinct o.num_dec, decode(fipuni.ind_qualification_isf,'Y','1','N','2') ind_isf
			  from eng_fipuni_taxonomie fipuni,
                   btr_operation o
			  where fipuni.id_operation = o.id_operation
 		  ) perim
		on ( hb.num_dec = perim.num_dec )
		when matched then update
		set hb.ind_isf = perim.ind_isf;
		*/
	  	merge into btr_hors_bilan hb
		  using (
			  select fipuni.id_operation, decode(fipuni.ind_qualification_isf,'Y','1','N','2') ind_isf
			  from eng_fipuni_taxonomie fipuni
 		  ) perim
		on ( hb.id_operation = perim.id_operation )
		when matched then update
		set hb.ind_isf = perim.ind_isf;

		COMMIT;

		EXCEPTION
		  WHEN OTHERS THEN
		  ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('Proc p_alim_ind_isf table -MESS:'||SQLERRM);
		  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_ind_isf: ', 50072);

	  END p_alim_ind_isf;


	  -----------------------------------------------------------
	  -- nom : procedure p_alim_ind_conf_crit_ope              --
	  -- but : Injecter les donnees sur BTR_OPERATION          --
	  -- auteur : GOMESHU - 10/04/2024                         --
	  -- retour : MAJ table BTR_OPERATION                      --
	  -- Modification:                                         --
	  ------------------------------------------------------------
	  PROCEDURE p_alim_ind_conf_crit_ope IS

	  BEGIN

		-- BTR_OPERATION
	  	merge into btr_operation o
		  using (
			  select fipuni.id_operation, fipuni.ind_conf_crit_ope
			  from eng_fipuni_taxonomie fipuni
 		  ) perim
		on ( o.id_operation = perim.id_operation )
		when matched then update
		set o.ind_conf_crit_ope = perim.ind_conf_crit_ope;

		COMMIT;

		EXCEPTION
		  WHEN OTHERS THEN
		  ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('Proc p_alim_ind_conf_crit_ope table -MESS:'||SQLERRM);
		  pack_utilitaire.DB_TRAITE_ERREUR(SQLERRM,'proc p_alim_ind_conf_crit_ope: ', 50072);

	  END p_alim_ind_conf_crit_ope;

	  ----------------------------------------------------------------------
	  -- nom : procedure P_ALIM_PERIM_ENVOI_CRR_P1                        --
	  -- auteur : MESQUIPE, le 29/05/2025                                 --
	  -- RSE_LOT3 - SIRL-153 - remplissage de la table PERIM_ENVOI_CRR_P1 --
	  ----------------------------------------------------------------------
	  PROCEDURE P_ALIM_PERIM_ENVOI_CRR_P1 IS
	  	l_dt_arrete date := pack_utilitaire.f_calc_dt_arrete;
	  BEGIN
	  	DBMS_OUTPUT.ENABLE(buffer_size=>NULL);

	  	execute immediate 'truncate table PERIM_ENVOI_CRR_P1';

	  	insert into PERIM_ENVOI_CRR_P1( DT_ARRETE
									  , CD_CONSO_CPT
	  	                              , ID_ENGAGEMENT
	  	                              , P1_1_11
									  , P1_0_3
	  	                              )
	  	SELECT l_dt_arrete
		     , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT || '_C'      AS P1_1_11
			 , NVL(APPLI_SOURCE,'C_BTR' ) AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE                 = 'O'
	  		AND NVL(CD_ARR_PAIEMENT,'N') = 'N'
	  		AND NVL(FLAG_HN,'N')         = 'N'
	  		AND ( NVL(MNT_CRD,0) - NVL(MNT_VR,0) >= 1 OR NVL(MNT_VR,0) >= 1 )
	  		AND CD_TYPE_RISQUE           NOT IN ( 'TRE100', 'SIG201', 'EQU101', 'VAR104' )
	  		AND ( CD_TYPE_RISQUE         NOT LIKE 'TRE2%' )
	  	UNION
	  	-- E04b: a partir de C_ENG_CORP_P1_AVEC_IMP1
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT || '_S'     AS P1_1_11
			 , NVL(APPLI_SOURCE,'C_BTR') AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE                 = 'O'
	  		AND NVL(CD_ARR_PAIEMENT,'N') = 'Y'
	  		AND NVL(FLAG_HN,'N')         = 'N'
	  		AND NVL(MNT_SOLD_K_A,0)      >= 1
	  		AND CD_TYPE_RISQUE           NOT IN ( 'TRE100', 'SIG201', 'EQU101', 'VAR104' )
	  		AND ( CD_TYPE_RISQUE         NOT LIKE 'TRE2%' )
	  	UNION
	  	-- E04c: a partir de C_ENG_CORP_P1_AVEC_IMP2
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT || '_C'     AS P1_1_11
			 , NVL(APPLI_SOURCE,'C_BTR') AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE                 = 'O'
	  		AND NVL(CD_ARR_PAIEMENT,'N') = 'Y'
	  		AND NVL(FLAG_HN,'N')         = 'N'
	  		AND CD_TYPE_RISQUE           NOT IN ( 'TRE100', 'SIG201', 'EQU101', 'VAR104' )
	  		AND ( CD_TYPE_RISQUE         NOT LIKE 'TRE2%' )
	  		AND ( NVL(MNT_CRD,0) - NVL(MNT_VR,0) >= 1 OR NVL(MNT_VR,0) >= 1 )
	  	UNION
	  	-- E08: a partir de P_UTLF_P1_TRE100
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT AS P1_1_11
			 , 'C_DDR'       AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE        = 'O'
	  		AND FLAG_HN         = 'O'
	  		AND CD_TYPE_RISQUE IN ( 'TRE100' )
	  	UNION
	  	-- E09: a partir de P_UTLF_P1_TRE2_TRE4
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT AS P1_1_11
			 , 'C_DDR'       AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE                    = 'O'
	  		AND FLAG_HN                     = 'O'
	  		AND SUBSTR(CD_TYPE_RISQUE,1,4) IN ( 'TRE2', 'TRE4', 'TRE5' )
	  	UNION
	  	-- E10: a partir de P_UTLF_P1_EQU101
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT AS P1_1_11
			 , 'C_DDR'       AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE        = 'O'
	  		AND FLAG_HN         = 'O'
	  		AND CD_TYPE_RISQUE IN ( 'EQU101' )
	  	UNION
	  	-- E11: a partir de P_UTLF_P1_SIG201
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT AS P1_1_11
			 , 'C_DDR'       AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE        = 'O'
	  		AND FLAG_HN         = 'O'
	  		AND CD_TYPE_RISQUE IN ( 'SIG201', 'INR101' )
	  	UNION
	  	-- E12: a partir de P_UTLF_P1_VAR104
	  	SELECT l_dt_arrete
			 , CD_CONSO_CPT
	  	     , ID_ENGAGEMENT
	  	     , ID_ENGAGEMENT AS P1_1_11
			 , 'C_DDR'       AS P1_0_3
	  	FROM ENG_CORP_P1
	  	WHERE A_EXTRAIRE          = 'O'
	  		AND FLAG_HN           = 'O'
	  		AND CD_TYPE_RISQUE LIKE '%VAR1%'
	  	;
	  	COMMIT;

	  EXCEPTION
	  	WHEN OTHERS THEN
	  		ROLLBACK;
	  		DBMS_OUTPUT.PUT_LINE( ' proc P_ALIM_PERIM_ENVOI_CRR_P1 :' || SQLERRM );
	  		pack_utilitaire.DB_TRAITE_ERREUR( SQLERRM, 'proc P_ALIM_PERIM_ENVOI_CRR_P1', 50072 );
	  END P_ALIM_PERIM_ENVOI_CRR_P1;

PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite    IN VARCHAR2,
                                       p_masysdate IN VARCHAR2,
                                       p_perimetre IN VARCHAR2 DEFAULT 'TOTAL')
IS
BEGIN
    ------------------------------------------------------------------
    -- Etape 1 : vider UNIQUEMENT le perimetre traite.
    --   Pas de TRUNCATE : c'est du DDL (commit implicite), les donnees
    --   seraient perdues meme si un INSERT echouait ensuite. Le DELETE
    --   reste dans la transaction et permet les DEUX alimentations
    --   successives prevues par le ticket : NAT02 (M2 BTR) puis
    --   HORS_NAT02 (apres reception des donnees comptables).
    ------------------------------------------------------------------
    IF p_perimetre NOT IN ('NAT02', 'HORS_NAT02', 'TOTAL') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'p_perimetre invalide : '||p_perimetre||
            ' (attendu NAT02, HORS_NAT02 ou TOTAL)');
    END IF;

    IF p_perimetre = 'TOTAL' THEN
        DELETE FROM ENG_CORP_P1_BIS;
    ELSE
        DELETE FROM ENG_CORP_P1_BIS WHERE CD_PERIMETRE = p_perimetre;
    END IF;

    IF p_perimetre IN ('NAT02', 'TOTAL') THEN

    ------------------------------------------------------------------
    -- INSERT #1  (standard NAT02 - spool L590)
    --   colonnes : 207 (dont 58 ancrees --P1) | 178 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_1,
        P1_18_10,
        P1_18_5,
        P1_18_17,
        P1_18_18,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_3,
        P1_4_4,
        P1_4_5,
        P1_4_9,
        P1_4_13,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_4_21,
        P1_4_22,
        P1_4_23,
        P1_3_46,
        P1_3_47,
        P1_3_40,
        P1_3_41,
        P1_3_42,
        P1_3_43,
        P1_3_44,
        P1_3_45,
        P1_5_19,
        P1_5_20,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_29_1,
        P1_29_2,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_21,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_22,
        P1_21_23,
        P1_21_29,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_43,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_71,
        P1_21_72,
        P1_21_73,
        P1_21_74,
        P1_21_75,
        P1_21_76,
        P1_21_77,
        P1_21_78,
        P1_21_80,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'NAT02'                                                    AS CD_PERIMETRE,
        1                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.dt_arrete                                            AS P1_H_0_1,  -- L590 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L591 [en-tete conv.]
        NVL(C_ENR.APPLI_SOURCE, 'C_BTR')                           AS P1_H_0_3,  -- L592 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L593 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L594 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L595 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L597 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L600 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L601 [position V44]
        C_ENR.ID_ENGAGEMENT || '_C'                                AS P1_H_1_11,  -- L603 [position V44]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS P1_1_1,  -- L606 [position V44]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS P1_1_2,  -- L607 [position V44]
        'Y'                                                        AS P1_4_34,  -- L608 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L609 [position V44]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS P1_2_4,  -- L610 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L611 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L612 [P1 2.18]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS P1_2_29,  -- L613 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L614 [position V44]
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD'))      AS P1_3_4,  -- L615 [position V44]
        C_ENR.TX_LGD_PREDICTIF_LOCAL                               AS P1_18_1,  -- L617 [position V44]
        C_ENR.TX_TRC                                               AS P1_18_10,  -- L618 [position V44]
        CASE WHEN NVL((C_ENR.MNT_EAD_TOT), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_EAD_TOT), 0)END AS P1_18_5,  -- L619 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_17,  -- L622 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_18,  -- L623 [position V44]
        C_ENR.DT_RESTRUCTURATION                                   AS P1_21_2,  -- L628 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L629 [position V44]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS P1_4_1,  -- L631 [position V44]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L632 [position V44]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS P1_5_3,  -- L633 [position V44]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L636 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' THEN 0 END       AS P1_4_4,  -- L637 [campo composto]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' THEN NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT,'EUR') END AS P1_4_5,  -- L637 [campo composto]
        NVL((C_ENR.MNT_RISQUE), 0)                                 AS P1_4_9,  -- L641 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_13,  -- L643 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE401' THEN NULL ELSE NVL(C_ENR.MNT_LOYER,0) END AS P1_4_14,  -- L644 [campo composto]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE401' THEN NULL ELSE NVL(C_ENR.CD_DEVISE_CRD,'EUR') END AS P1_4_15,  -- L644 [campo composto]
        C_ENR.PCCO_MNT_CRD                                         AS P1_4_18,  -- L649 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN CASE WHEN NVL((C_ENR.MNT_SOLD_K_A), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_SOLD_K_A), 0)END ELSE NULL END AS P1_4_6,  -- L650 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_7,  -- L651 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_4_19,  -- L652 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE NVL((C_ENR.MNT_VTR), 0) END AS P1_4_21,  -- L654 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS P1_4_22,  -- L655 [position V44]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS P1_4_23,  -- L656 [position V44]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS P1_3_46,  -- L658 [position V44]
        C_ENR.CD_RESPECT_COND                                      AS P1_3_47,  -- L659 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_VTR), 0) else NULL END AS P1_3_40,  -- L660 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_VTR else NULL END AS P1_3_41,  -- L662 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_HYPOTHEQUE), 0) else NULL END AS P1_3_42,  -- L663 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_HYPOTH else NULL END AS P1_3_43,  -- L664 [position V44]
        C_ENR.CD_LOC_BIEN                                          AS P1_3_44,  -- L665 [position V44]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS P1_3_45,  -- L666 [position V44]
        Case when NVL(C_ENR.MNT_VR, 0) >= 0 then NVL((C_ENR.MNT_VR), 0) else 0 END AS P1_5_19,  -- L669 [position V44]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS P1_5_20,  -- L671 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L672 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L677 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L685 [P1 4.31]
        NVL(C_ENR.MATURITE_EFF, 0)                                 AS P1_3_20,  -- L693 [position V44]
        NVL(C_ENR.TOP_ENG, 'B')                                    AS P1_4_8,  -- L695 [P1 4.8]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L697 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L698 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L700 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS P1_4_29,  -- L705 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L715 [P1 21.3]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L716 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L717 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L718 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L719 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L720 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L721 [position V44]
        C_ENR.DATE_ENTR_PER_PURG                                   AS P1_21_10,  -- L722 [position V44]
        C_ENR.DATE_SORT_PER_PURG                                   AS P1_21_11,  -- L723 [position V44]
        C_ENR.DATE_ENTR_PER_PROB                                   AS P1_21_12,  -- L724 [position V44]
        C_ENR.DATE_SORT_PER_PROB                                   AS P1_21_13,  -- L725 [position V44]
        C_ENR.DATE_THEO_FIN_FORB                                   AS P1_21_14,  -- L726 [position V44]
        C_ENR.DATE_SORT_EFF_FORB                                   AS P1_21_15,  -- L727 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L728 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L736 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L739 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_1,  -- L740 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L741 [position V44]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L743 [P1 22.5]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L744 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L745 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L747 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L748 [position V44]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS P1_22_55,  -- L751 [position V44]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L753 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L754 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L761 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L762 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L765 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L766 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L767 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L768 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L769 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L770 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L771 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L772 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L773 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L774 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L775 [P1 22.23]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L776 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L777 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L778 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L779 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L780 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L781 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L782 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L783 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L785 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L787 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST<0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L789 [position V44]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L791 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L792 [position V44]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L793 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L803 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L804 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L810 [position V44]
        C_ENR.DATE_FIN_PALL                                        AS P1_22_59,  -- L812 [position V44]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L813 [P1 22.60]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L815 [position V44]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L816 [position V44]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L817 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L821 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L822 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L824 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L825 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L826 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L828 [P1 23.1]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L830 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L831 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L832 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L833 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L834 [position V44]
        C_ENR.PCCO_MNT_CRD || C_ENR.ZONE_APP_COMP                  AS P1_23_7,  -- L835 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L837 [P1 23.8]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L838 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L839 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L840 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L842 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L848 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L851 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L853 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L854 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L858 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L860 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L863 [position V44]
        C_ENR.MNT_IDEMNITE_RES                                     AS P1_29_1,  -- L868 [position V44]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS P1_29_2,  -- L870 [position V44]
        'N'                                                        AS P1_30_22,  -- L878 [position V44]
        'N'                                                        AS P1_30_25,  -- L883 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L887 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L888 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L889 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L890 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L891 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L894 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L895 [position V44]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L904 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L909 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS P1_31_21,  -- L916 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L917 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L931 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L934 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L935 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L971 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L972 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L973 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L976 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L977 [position V44]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L984 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L985 [P1 21.23]
        case when C_ENR.DUREE_MRTR is not null then C_ENR.DUREE_MRTR else NULL end AS P1_21_29,  -- L986 [P1 21.29]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L987 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L988 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L989 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L990 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L991 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L992 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L1012 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L1013 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L1014 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L1015 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L1016 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L1017 [P1 21.40]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L1020 [P1 21.43]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L1031 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L1033 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L1034 [P1 21.55]
        CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END AS P1_21_69,  -- L1035 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L1038 [P1 8.13]
        C_ENR.COMMUNE                                              AS P1_21_71,  -- L1039 [P1 21.71]
        C_ENR.NUM_VOIE                                             AS P1_21_72,  -- L1040 [P1 21.72]
        C_ENR.EXTENSION                                            AS P1_21_73,  -- L1041 [P1 21.73]
        C_ENR.TYPE_VOIE                                            AS P1_21_74,  -- L1042 [P1 21.74]
        C_ENR.LIB_VOIE                                             AS P1_21_75,  -- L1043 [P1 21.75]
        C_ENR.LIEU_DIT                                             AS P1_21_76,  -- L1044 [P1 21.76]
        C_ENR.LATITUDE                                             AS P1_21_77,  -- L1045 [P1 21.77]
        C_ENR.LONGITUDE                                            AS P1_21_78,  -- L1046 [P1 21.78]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L1050 [P1 21.80]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L1051 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L1052 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L1056 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L1057 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L1058 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 )
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' );

    ------------------------------------------------------------------
    -- INSERT #2  (NAT02 arriere='Y' solde - spool L1089)
    --   colonnes : 197 (dont 41 ancrees --P1) | 188 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_1,
        P1_18_10,
        P1_18_5,
        P1_18_17,
        P1_18_18,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_3,
        P1_4_4,
        P1_4_5,
        P1_4_9,
        P1_4_13,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_4_21,
        P1_4_22,
        P1_4_23,
        P1_3_46,
        P1_3_47,
        P1_3_40,
        P1_3_41,
        P1_3_42,
        P1_3_43,
        P1_3_44,
        P1_3_45,
        P1_5_19,
        P1_5_20,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_29_1,
        P1_29_2,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_21,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_22,
        P1_21_23,
        P1_21_29,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_39,
        P1_21_43,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_80,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'NAT02'                                                    AS CD_PERIMETRE,
        2                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.dt_arrete                                            AS P1_H_0_1,  -- L1089 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L1090 [en-tete conv.]
        NVL(C_ENR.APPLI_SOURCE, 'C_BTR')                           AS P1_H_0_3,  -- L1091 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L1092 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L1093 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L1094 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L1096 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L1099 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L1100 [position V44]
        C_ENR.ID_ENGAGEMENT || '_S'                                AS P1_H_1_11,  -- L1102 [position V44]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS P1_1_1,  -- L1105 [position V44]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS P1_1_2,  -- L1106 [position V44]
        'Y'                                                        AS P1_4_34,  -- L1107 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L1108 [position V44]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS P1_2_4,  -- L1109 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L1110 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L1111 [position V44]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS P1_2_29,  -- L1112 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L1113 [position V44]
        NVL(add_months(C_ENR.DT_ARRETE,12), TO_DATE('99990630','YYYYMMDD')) AS P1_3_4,  -- L1114 [position V44]
        C_ENR.TX_LGD_PREDICTIF_LOCAL                               AS P1_18_1,  -- L1117 [position V44]
        C_ENR.TX_TRC                                               AS P1_18_10,  -- L1118 [position V44]
        CASE WHEN NVL((C_ENR.MNT_EAD_TOT), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_EAD_TOT), 0)END AS P1_18_5,  -- L1119 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_17,  -- L1122 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_18,  -- L1123 [position V44]
        C_ENR.DT_RESTRUCTURATION                                   AS P1_21_2,  -- L1129 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L1130 [position V44]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS P1_4_1,  -- L1132 [position V44]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L1133 [position V44]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS P1_5_3,  -- L1134 [position V44]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L1137 [P1 4.3]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' THEN 0 END       AS P1_4_4,  -- L1139 [campo composto]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' THEN NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT,'EUR') END AS P1_4_5,  -- L1139 [campo composto]
        0                                                          AS P1_4_9,  -- L1143 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_13,  -- L1145 [position V44]
        NVL(C_ENR.MNT_SOLD_K_A, 0)                                 AS P1_4_14,  -- L1146 [position V44]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS P1_4_15,  -- L1147 [position V44]
        C_ENR.PCCO_MNT_SOLDE                                       AS P1_4_18,  -- L1150 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE5%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN CASE WHEN NVL((C_ENR.MNT_SOLD_K_A), 0) <0 THEN 0 ELSE NVL((C_ENR.MNT_SOLD_K_A), 0)END ELSE NULL END AS P1_4_6,  -- L1151 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_7,  -- L1152 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_4_19,  -- L1153 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE NVL((C_ENR.MNT_VTR), 0) END AS P1_4_21,  -- L1155 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS P1_4_22,  -- L1157 [position V44]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS P1_4_23,  -- L1158 [position V44]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS P1_3_46,  -- L1160 [position V44]
        C_ENR.CD_RESPECT_COND                                      AS P1_3_47,  -- L1162 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then 0 else NULL END AS P1_3_40,  -- L1163 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then C_ENR.CD_DEV_VTR else NULL END AS P1_3_41,  -- L1165 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then 0 else NULL END AS P1_3_42,  -- L1166 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' and C_ENR.CD_USAGE_BIEN_IMM = '2' then C_ENR.CD_DEV_HYPOTH else NULL END AS P1_3_43,  -- L1167 [position V44]
        C_ENR.CD_LOC_BIEN                                          AS P1_3_44,  -- L1168 [position V44]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS P1_3_45,  -- L1171 [position V44]
        Case when NVL(C_ENR.MNT_VR, 0) >= 0 then NVL((C_ENR.MNT_VR), 0) else 0 END AS P1_5_19,  -- L1174 [position V44]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS P1_5_20,  -- L1176 [position V44]
        C_ENR.cla_comp_ref_act_s                                   AS P1_19_5,  -- L1177 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1182 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1190 [P1 4.31]
        1                                                          AS P1_3_20,  -- L1198 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L1201 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L1203 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L1204 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L1206 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS P1_4_29,  -- L1211 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L1221 [position V44]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L1222 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L1223 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L1224 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L1225 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L1226 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L1227 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS P1_21_10,  -- L1228 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS P1_21_11,  -- L1229 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS P1_21_12,  -- L1230 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS P1_21_13,  -- L1231 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS P1_21_14,  -- L1232 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS P1_21_15,  -- L1233 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L1234 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L1242 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L1245 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_1,  -- L1246 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L1247 [position V44]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L1249 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L1250 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L1251 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L1253 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L1254 [position V44]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS P1_22_55,  -- L1256 [position V44]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1259 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1260 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1261 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L1262 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L1265 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L1266 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L1267 [position V44]
        'F'                                                        AS P1_22_16,  -- L1268 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L1270 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L1271 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L1272 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L1273 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L1274 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L1275 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L1276 [position V44]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L1277 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L1278 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L1279 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L1280 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L1281 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L1282 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L1283 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L1284 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L1286 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L1289 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L1291 [P1 22.34]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L1293 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L1295 [position V44]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L1296 [P1 22.37]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1297 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1307 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1308 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L1314 [position V44]
        add_months(C_ENR.DT_ARRETE,12)                             AS P1_22_59,  -- L1316 [position V44]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L1317 [position V44]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L1319 [position V44]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L1320 [position V44]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1321 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L1325 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L1326 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L1328 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L1329 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L1330 [position V44]
        C_ENR.ELI_OUT_MUT_PROV_S                                   AS P1_23_1,  -- L1332 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L1334 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L1335 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9_S                                 AS P1_23_4,  -- L1336 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE_S                             AS P1_23_5,  -- L1337 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L1338 [position V44]
        C_ENR.PCCO_MNT_SOLDE || C_ENR.ZONE_APP_COMP                AS P1_23_7,  -- L1339 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L1341 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L1342 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L1343 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L1344 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L1346 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L1352 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L1355 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L1357 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L1358 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L1364 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L1366 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L1369 [position V44]
        C_ENR.MNT_IDEMNITE_RES                                     AS P1_29_1,  -- L1374 [position V44]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS P1_29_2,  -- L1376 [position V44]
        'N'                                                        AS P1_30_22,  -- L1385 [position V44]
        'N'                                                        AS P1_30_25,  -- L1390 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L1394 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L1395 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L1396 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L1397 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L1398 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L1401 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L1402 [position V44]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L1411 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L1416 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS P1_31_21,  -- L1423 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1424 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L1438 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L1441 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L1442 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L1478 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L1479 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L1480 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L1483 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L1484 [position V44]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L1491 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L1492 [P1 21.23]
        case when C_ENR.DUREE_MRTR is not null then C_ENR.DUREE_MRTR else NULL end AS P1_21_29,  -- L1493 [P1 21.29]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L1494 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L1495 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L1496 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L1497 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L1498 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L1499 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L1519 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L1520 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L1521 [P1 21.46]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L1523 [P1 21.39]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L1527 [P1 21.43]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L1538 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L1540 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L1541 [P1 21.55]
        CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END AS P1_21_69,  -- L1542 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L1545 [P1 8.13]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L1557 [P1 21.80]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L1558 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L1559 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L1563 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L1564 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L1565 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND NVL(C_ENR.MNT_SOLD_K_A,0) >= 1
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' );

    ------------------------------------------------------------------
    -- INSERT #3  (NAT02 arriere='Y' CRD/VR - spool L1592)
    --   colonnes : 206 (dont 51 ancrees --P1) | 179 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_1,
        P1_18_10,
        P1_18_5,
        P1_18_17,
        P1_18_18,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_3,
        P1_4_5,
        P1_4_9,
        P1_4_13,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_4_21,
        P1_4_22,
        P1_4_23,
        P1_3_46,
        P1_3_47,
        P1_3_40,
        P1_3_41,
        P1_3_42,
        P1_3_43,
        P1_3_44,
        P1_3_45,
        P1_5_19,
        P1_5_20,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_37,
        P1_22_38,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_29_1,
        P1_29_2,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_21,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_22,
        P1_21_23,
        P1_21_29,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_43,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_71,
        P1_21_72,
        P1_21_73,
        P1_21_74,
        P1_21_75,
        P1_21_76,
        P1_21_77,
        P1_21_78,
        P1_21_80,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'NAT02'                                                    AS CD_PERIMETRE,
        3                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.dt_arrete                                            AS P1_H_0_1,  -- L1592 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L1593 [en-tete conv.]
        NVL(C_ENR.APPLI_SOURCE, 'C_BTR')                           AS P1_H_0_3,  -- L1594 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L1595 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L1596 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L1597 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L1599 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L1602 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L1603 [position V44]
        C_ENR.ID_ENGAGEMENT || '_C'                                AS P1_H_1_11,  -- L1605 [position V44]
        NVL(C_ENR.CD_METHODO_BALE2, 'STD')                         AS P1_1_1,  -- L1608 [position V44]
        NVL(C_ENR.CODE_TRAIT_MOTEUR, '01')                         AS P1_1_2,  -- L1609 [position V44]
        'Y'                                                        AS P1_4_34,  -- L1610 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L1611 [position V44]
        NVL(C_ENR.CD_PORTEFEUILLE_BOOKING, 'B')                    AS P1_2_4,  -- L1612 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L1613 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L1614 [position V44]
        NVL(C_ENR.CD_NATURE_OPE, 'NA020')                          AS P1_2_29,  -- L1615 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L1616 [position V44]
        NVL(C_ENR.DT_FIN_ENG, TO_DATE('99990630','YYYYMMDD'))      AS P1_3_4,  -- L1617 [position V44]
        0                                                          AS P1_18_1,  -- L1619 [position V44]
        0                                                          AS P1_18_10,  -- L1620 [position V44]
        0                                                          AS P1_18_5,  -- L1621 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_17,  -- L1624 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_18_18,  -- L1625 [position V44]
        C_ENR.DT_RESTRUCTURATION                                   AS P1_21_2,  -- L1630 [position V44]
        'N'                                                        AS P1_5_5,  -- L1631 [position V44]
        NVL(C_ENR.CD_IMP_PRUDENT, 'N')                             AS P1_4_1,  -- L1635 [position V44]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L1636 [position V44]
        Case When C_ENR.TOP_ENG_DOUTEUX = 'Y' then NVL(C_ENR.DT_ENG_DOUTEUX, C_ENR.dt_arrete) else NULL END AS P1_5_3,  -- L1637 [position V44]
        NVL(C_ENR.CD_DEVISE_MNT_RISQ, 'EUR')                       AS P1_4_3,  -- L1640 [position V44]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L1643 [position V44]
        NVL((C_ENR.MNT_RISQUE), 0)                                 AS P1_4_9,  -- L1644 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_13,  -- L1645 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE401' THEN NULL ELSE NVL(C_ENR.MNT_LOYER,0) END AS P1_4_14,  -- L1646 [campo composto]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE401' THEN NULL ELSE NVL(C_ENR.CD_DEVISE_CRD,'EUR') END AS P1_4_15,  -- L1646 [campo composto]
        C_ENR.PCCO_MNT_CRD                                         AS P1_4_18,  -- L1651 [position V44]
        0                                                          AS P1_4_6,  -- L1652 [position V44]
        C_ENR.CD_DEVISE_MNT_RISQ                                   AS P1_4_7,  -- L1653 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_4_19,  -- L1654 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 0 END       AS P1_4_21,  -- L1656 [position V44]
        CASE WHEN C_ENR.MNT_VTR IS null THEN NULL ELSE 'EUR' END   AS P1_4_22,  -- L1657 [position V44]
        NVL(C_ENR.CD_CIRCUIT_DISTRIB, 'CL')                        AS P1_4_23,  -- L1658 [position V44]
        C_ENR.CD_USAGE_BIEN_IMM                                    AS P1_3_46,  -- L1660 [position V44]
        C_ENR.CD_RESPECT_COND                                      AS P1_3_47,  -- L1662 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_VTR), 0) else NULL END AS P1_3_40,  -- L1663 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_VTR else NULL END AS P1_3_41,  -- L1666 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then NVL((C_ENR.MNT_HYPOTHEQUE), 0) else NULL END AS P1_3_42,  -- L1667 [position V44]
        Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then C_ENR.CD_DEV_HYPOTH else NULL END AS P1_3_43,  -- L1668 [position V44]
        C_ENR.CD_LOC_BIEN                                          AS P1_3_44,  -- L1669 [position V44]
        C_ENR.CD_ACHAT_FIN_LOC                                     AS P1_3_45,  -- L1672 [position V44]
        0                                                          AS P1_5_19,  -- L1675 [position V44]
        NVL(C_ENR.CD_DEVISE_VR, 'EUR')                             AS P1_5_20,  -- L1677 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L1678 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L1683 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L1691 [P1 4.31]
        NVL(C_ENR.MATURITE_EFF, 0)                                 AS P1_3_20,  -- L1699 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L1701 [P1 4.8]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L1703 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L1704 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L1706 [position V44]
        Case when (C_ENR.CD_TYPE_RISQUE LIKE 'TRE2%' OR C_ENR.CD_TYPE_RISQUE LIKE 'TRE4%') THEN 'N' ELSE ' ' END AS P1_4_29,  -- L1711 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L1721 [position V44]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L1722 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L1723 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L1724 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L1725 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L1726 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L1727 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS P1_21_10,  -- L1728 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS P1_21_11,  -- L1729 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS P1_21_12,  -- L1730 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS P1_21_13,  -- L1731 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS P1_21_14,  -- L1732 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS P1_21_15,  -- L1733 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L1734 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L1742 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L1745 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_1,  -- L1746 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L1747 [position V44]
        NVL(C_enr.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L1749 [P1 22.5]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L1750 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L1751 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L1753 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L1754 [position V44]
        CASE WHEN C_ENR.METH_NOT_ORI = 'C3' THEN '999' ELSE upper(C_ENR.METH_NOT_ORI) END AS P1_22_55,  -- L1757 [position V44]
        NVL(C_ENR.OBJ_FINANCIE, '97')                              AS P1_22_7,  -- L1760 [P1 22.7]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L1761 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L1762 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L1763 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L1764 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L1765 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L1766 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L1767 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L1768 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L1769 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L1770 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L1771 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L1772 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L1773 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L1774 [position V44]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L1775 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L1776 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L1777 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L1778 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L1779 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L1780 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L1781 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L1782 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L1784 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L1786 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L1788 [position V44]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L1791 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L1792 [position V44]
        C_ENR.dt_exigte_prem_impy                                  AS P1_22_37,  -- L1793 [position V44]
        C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS                         AS P1_22_38,  -- L1794 [P1 22.38]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L1804 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L1805 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L1811 [P1 22.58]
        C_ENR.DATE_FIN_PALL                                        AS P1_22_59,  -- L1813 [position V44]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L1814 [position V44]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L1816 [position V44]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L1817 [position V44]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L1818 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L1822 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L1823 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L1825 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L1826 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L1827 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L1829 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L1831 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L1832 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L1833 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L1834 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L1835 [position V44]
        C_ENR.PCCO_MNT_CRD || C_ENR.ZONE_APP_COMP                  AS P1_23_7,  -- L1836 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L1838 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L1839 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L1840 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L1841 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L1843 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L1849 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L1852 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L1854 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L1855 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L1858 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L1860 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L1863 [position V44]
        C_ENR.MNT_IDEMNITE_RES                                     AS P1_29_1,  -- L1868 [position V44]
        C_ENR.CD_DEV_MNT_INDEMNITE                                 AS P1_29_2,  -- L1870 [position V44]
        'N'                                                        AS P1_30_22,  -- L1879 [position V44]
        'N'                                                        AS P1_30_25,  -- L1884 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L1888 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L1889 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L1890 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L1891 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L1892 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L1895 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L1896 [position V44]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_17,  -- L1905 [P1 31.17]
        case when C_ENR.CD_TYPE_RISQUE like 'TRE%' then NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) else 0 end AS P1_31_18,  -- L1910 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS P1_31_21,  -- L1917 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L1918 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L1932 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L1935 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L1936 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L1972 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L1973 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L1974 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L1977 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L1978 [position V44]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L1985 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L1986 [P1 21.23]
        case when C_ENR.DUREE_MRTR is not null then C_ENR.DUREE_MRTR else NULL end AS P1_21_29,  -- L1987 [P1 21.29]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L1988 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L1989 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L1990 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L1991 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L1992 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L1993 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L2013 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L2014 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L2015 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L2016 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L2017 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L2018 [P1 21.40]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L2021 [P1 21.43]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L2032 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L2034 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L2035 [P1 21.55]
        CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' ELSE NULL END AS P1_21_69,  -- L2036 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L2039 [P1 8.13]
        C_ENR.COMMUNE                                              AS P1_21_71,  -- L2040 [P1 21.71]
        C_ENR.NUM_VOIE                                             AS P1_21_72,  -- L2041 [P1 21.72]
        C_ENR.EXTENSION                                            AS P1_21_73,  -- L2042 [P1 21.73]
        C_ENR.TYPE_VOIE                                            AS P1_21_74,  -- L2043 [P1 21.74]
        C_ENR.LIB_VOIE                                             AS P1_21_75,  -- L2044 [P1 21.75]
        C_ENR.LIEU_DIT                                             AS P1_21_76,  -- L2045 [P1 21.76]
        C_ENR.LATITUDE                                             AS P1_21_77,  -- L2046 [P1 21.77]
        C_ENR.LONGITUDE                                            AS P1_21_78,  -- L2047 [P1 21.78]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L2051 [P1 21.80]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L2052 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L2053 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L2057 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L2058 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L2059 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' )
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 );

    END IF;

    IF p_perimetre IN ('HORS_NAT02', 'TOTAL') THEN

    ------------------------------------------------------------------
    -- INSERT #4  (Hors-NAT TRE100 - spool L2894)
    --   colonnes : 108 (dont 28 ancrees --P1) | 382 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_5_2,
        P1_4_2,
        P1_4_3,
        P1_4_5,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_19_5,
        P1_2_99,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_36,
        P1_22_44,
        P1_22_45,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_22,
        P1_21_23,
        P1_21_29,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_46,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        4                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L2894 [en-tete conv.]
        TO_CHAR(C_ENR.CD_CONSO_CPT)                                AS P1_H_0_2,  -- L2895 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L2896 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L2897 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L2898 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L2899 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L2903 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L2905 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L2906 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L2908 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L2911 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L2912 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L2913 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L2914 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L2915 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L2916 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L2917 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L2918 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L2919 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L2920 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L2934 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L2938 [P1 5.5]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L2941 [P1 5.2]
        NVL((C_ENR.MNT_SOLDE), 0)                                  AS P1_4_2,  -- L2943 [P1 4.2]
        C_ENR.CD_DEVISE_SOLDE                                      AS P1_4_3,  -- L2951 [position V44]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L2955 [position V44]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L2960 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L2965 [position V44]
        C_ENR.PCCO_MNT_SOLDE                                       AS P1_4_18,  -- L2970 [position V44]
        C_ENR.cla_comp_ref_act_s                                   AS P1_19_5,  -- L3007 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3043 [P1 2.99]
        C_ENR.MATURITE_EFF                                         AS P1_3_20,  -- L3118 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L3120 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L3123 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L3124 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L3199 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L3201 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L3202 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L3203 [position V44]
        NVL(C_ENR.NOTE_FIN_RET_ORI, 'ND')                          AS P1_22_5,  -- L3205 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L3206 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L3207 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L3209 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L3210 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_55,  -- L3213 [position V44]
        '97'                                                       AS P1_22_7,  -- L3214 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3215 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3222 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L3223 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L3227 [position V44]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L3239 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L3240 [P1 22.45]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L3253 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L3256 [position V44]
        C_ENR.ELI_OUT_MUT_PROV_S                                   AS P1_23_1,  -- L3258 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L3268 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L3269 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9_S                                 AS P1_23_4,  -- L3270 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE_S                             AS P1_23_5,  -- L3271 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L3272 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L3273 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L3275 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L3276 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L3277 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L3278 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L3280 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L3283 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L3284 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L3286 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L3287 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L3291 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L3293 [position V44]
        'N'                                                        AS P1_30_22,  -- L3306 [position V44]
        'N'                                                        AS P1_30_25,  -- L3311 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L3315 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L3316 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L3317 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L3318 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L3319 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L3322 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L3323 [position V44]
        0                                                          AS P1_31_17,  -- L3327 [P1 31.17]
        0                                                          AS P1_31_18,  -- L3329 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3334 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L3341 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L3345 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L3346 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L3352 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L3353 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L3354 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L3357 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L3358 [position V44]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L3365 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L3366 [P1 21.23]
        case when C_ENR.DUREE_MRTR is not null then C_ENR.DUREE_MRTR else NULL end AS P1_21_29,  -- L3367 [P1 21.29]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L3368 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L3369 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L3370 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L3371 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L3372 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L3373 [P1 21.31]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L3395 [P1 21.46]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L3414 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L3415 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L3419 [P1 8.13]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L3437 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L3438 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L3439 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('TRE100');

    ------------------------------------------------------------------
    -- INSERT #5  (Hors-NAT TRE2/TRE4/TRE5 - spool L3462)
    --   colonnes : 192 (dont 59 ancrees --P1) | 219 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_17,
        P1_18_18,
        P1_21_1,
        P1_21_2,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_5_3,
        P1_4_4,
        P1_4_5,
        P1_4_9,
        P1_4_13,
        P1_4_14,
        P1_4_15,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_19_5,
        P1_3_52,
        P1_3_53,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_4_47,
        P1_4_30,
        P1_4_29,
        P1_21_3,
        P1_21_4,
        P1_21_5,
        P1_21_6,
        P1_21_7,
        P1_21_8,
        P1_21_9,
        P1_21_10,
        P1_21_11,
        P1_21_12,
        P1_21_13,
        P1_21_14,
        P1_21_15,
        P1_21_16,
        P1_21_17,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_13,
        P1_22_14,
        P1_22_15,
        P1_22_16,
        P1_22_17,
        P1_22_18,
        P1_22_19,
        P1_22_20,
        P1_22_21,
        P1_22_22,
        P1_22_23,
        P1_22_24,
        P1_22_25,
        P1_22_26,
        P1_22_27,
        P1_22_28,
        P1_22_29,
        P1_22_30,
        P1_22_31,
        P1_22_32,
        P1_22_33,
        P1_22_34,
        P1_22_35,
        P1_22_36,
        P1_22_44,
        P1_22_45,
        P1_22_58,
        P1_22_59,
        P1_22_60,
        P1_22_61,
        P1_22_62,
        P1_22_63,
        P1_22_66,
        P1_22_67,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_28_1,
        P1_28_2,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_21,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_22,
        P1_21_23,
        P1_21_29,
        P1_21_25,
        P1_21_26,
        P1_21_27,
        P1_21_28,
        P1_21_30,
        P1_21_31,
        P1_21_44,
        P1_21_45,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_43,
        P1_21_57,
        P1_21_58,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_71,
        P1_21_72,
        P1_21_73,
        P1_21_74,
        P1_21_75,
        P1_21_76,
        P1_21_77,
        P1_21_78,
        P1_21_81,
        P1_21_82,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        5                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L3462 [en-tete conv.]
        TO_CHAR(C_ENR.CD_CONSO_CPT)                                AS P1_H_0_2,  -- L3464 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L3465 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L3466 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L3467 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L3468 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L3472 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L3476 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L3477 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L3479 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L3482 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L3484 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L3485 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L3486 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L3487 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L3488 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L3489 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L3490 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L3491 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L3494 [position V44]
        C_ENR.DEVISE_EAD                                           AS P1_18_17,  -- L3507 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L3508 [position V44]
        C_ENR.TOP_RESTRUCTURATION                                  AS P1_21_1,  -- L3510 [position V44]
        (CASE WHEN C_ENR.TOP_RESTRUCTURATION = 'O' THEN C_ENR.DT_RESTRUCTURATION ELSE NULL END) AS P1_21_2,  -- L3512 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L3517 [position V44]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_4_1,  -- L3518 [position V44]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L3519 [P1 5.2]
        (CASE WHEN C_ENR.TOP_ENG_DOUTEUX = 'Y' THEN C_ENR.DT_ENG_DOUTEUX ELSE NULL END) AS P1_5_3,  -- L3520 [P1 5.3]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' THEN 0 END       AS P1_4_4,  -- L3534 [campo composto]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE201' THEN NVL(C_ENR.CD_DEVISE_MNT_DECOUVERT,'EUR') END AS P1_4_5,  -- L3534 [campo composto]
        NVL((C_ENR.MNT_CRD), 0)                                    AS P1_4_9,  -- L3550 [P1 4.9]
        NVL(C_ENR.CD_DEVISE_CRD, 'EUR')                            AS P1_4_13,  -- L3552 [P1 4.13]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L3553 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L3555 [position V44]
        C_ENR.PCCO_MNT_CRD                                         AS P1_4_18,  -- L3560 [position V44]
        (CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL((C_ENR.MNT_INT_RD), 0) ELSE NULL END ) AS P1_4_6,  -- L3561 [position V44]
        ( CASE WHEN C_ENR.CD_TYPE_RISQUE <> 'TRE201' THEN NVL(C_ENR.CD_DEVISE_INT_RD, 'EUR') ELSE NULL END ) AS P1_4_7,  -- L3568 [P1 4.7]
        C_ENR.PCCO_INT_RD                                          AS P1_4_19,  -- L3578 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L3595 [position V44]
        NVL(C_ENR.MNT_MTM, 0)                                      AS P1_3_52,  -- L3599 [position V44]
        NVL(C_ENR.CD_DEV_MNT_MTM, 'EUR')                           AS P1_3_53,  -- L3600 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L3610 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L3621 [P1 4.31]
        NVL(C_ENR.MATURITE_EFF, 0)                                 AS P1_3_20,  -- L3631 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L3634 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L3639 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L3640 [position V44]
        C_ENR.DT_DISPO_FONDS                                       AS P1_4_47,  -- L3642 [position V44]
        C_ENR.TX_ELBE                                              AS P1_4_30,  -- L3646 [position V44]
        C_ENR.IND_CREANCE_TITRI                                    AS P1_4_29,  -- L3649 [position V44]
        C_ENR.EVENMT_CRDT                                          AS P1_21_3,  -- L3659 [position V44]
        C_ENR.NAT_CONT_EVENMT_CRDT                                 AS P1_21_4,  -- L3661 [position V44]
        C_ENR.STA_CRDT                                             AS P1_21_5,  -- L3662 [position V44]
        C_ENR.IND_CRE_PERF                                         AS P1_21_6,  -- L3663 [position V44]
        C_ENR.DATE_PREM_ACT_FORB                                   AS P1_21_7,  -- L3664 [position V44]
        C_ENR.DATE_DER_REST_COMM                                   AS P1_21_8,  -- L3665 [position V44]
        C_ENR.DATE_DER_REST_RSQ                                    AS P1_21_9,  -- L3666 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PURG END AS P1_21_10,  -- L3667 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1') THEN NULL ELSE C_ENR.DATE_SORT_PER_PURG END AS P1_21_11,  -- L3668 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_ENTR_PER_PROB END AS P1_21_12,  -- L3669 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('2') THEN NULL ELSE C_ENR.DATE_SORT_PER_PROB END AS P1_21_13,  -- L3670 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_THEO_FIN_FORB END AS P1_21_14,  -- L3671 [position V44]
        CASE WHEN C_ENR.STA_CRDT NOT IN ('1','2') THEN NULL ELSE C_ENR.DATE_SORT_EFF_FORB END AS P1_21_15,  -- L3672 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L3673 [position V44]
        C_ENR.CD_MOTIF_PL_NPL                                      AS P1_21_17,  -- L3676 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L3681 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L3684 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L3685 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L3686 [position V44]
        'ND'                                                       AS P1_22_5,  -- L3688 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L3689 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L3690 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L3692 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L3693 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_55,  -- L3696 [position V44]
        '97'                                                       AS P1_22_7,  -- L3697 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L3698 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L3699 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L3700 [position V44]
        C_ENR.TAUX_INT_EFF_ORI                                     AS P1_22_13,  -- L3703 [position V44]
        C_ENR.TYPE_TAUX                                            AS P1_22_14,  -- L3704 [position V44]
        C_ENR.IND_REF                                              AS P1_22_15,  -- L3707 [position V44]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L3708 [position V44]
        C_ENR.PRD_AMOR_CAP                                         AS P1_22_17,  -- L3709 [position V44]
        C_ENR.PRD_PMT_INT                                          AS P1_22_18,  -- L3710 [position V44]
        C_ENR.TAUX_CLT_OCT                                         AS P1_22_19,  -- L3711 [position V44]
        C_ENR.MOD_REMB_CRE                                         AS P1_22_20,  -- L3712 [position V44]
        C_ENR.DATE_PREM_ECH                                        AS P1_22_21,  -- L3713 [position V44]
        C_ENR.DATE_FIN_DIFF_AMOR                                   AS P1_22_22,  -- L3714 [position V44]
        C_ENR.TAUX_PLAFOND                                         AS P1_22_23,  -- L3715 [position V44]
        C_ENR.TAUX_PLANCHER                                        AS P1_22_24,  -- L3716 [position V44]
        C_ENR.PRD_REV_TAUX_UNIT_TMP                                AS P1_22_25,  -- L3717 [position V44]
        NVL((C_ENR.PRD_REV_TAUX_NBR), 0)                           AS P1_22_26,  -- L3718 [position V44]
        C_ENR.TAUX_CLT_PRD_EN_CRS                                  AS P1_22_27,  -- L3719 [position V44]
        C_ENR.TAUX_MRG_ADD                                         AS P1_22_28,  -- L3722 [position V44]
        C_ENR.TAUX_MRG_MULT                                        AS P1_22_29,  -- L3724 [position V44]
        C_ENR.BASE_CAL_INT                                         AS P1_22_30,  -- L3725 [position V44]
        C_ENR.DT_PREM_DBLQ_FONDS                                   AS P1_22_31,  -- L3726 [position V44]
        case when C_ENR.MNT_PREM_DBLQ_FONDS is null then NULL else C_ENR.MNT_PREM_DBLQ_FONDS end AS P1_22_32,  -- L3729 [position V44]
        NVL(C_ENR.DEVISE_PREM_DBLQ_FONDS, 'EUR')                   AS P1_22_33,  -- L3731 [position V44]
        CASE WHEN C_ENR.CAP_THEO_REST <0 THEN 0 ELSE C_ENR.CAP_THEO_REST END AS P1_22_34,  -- L3733 [P1 22.34]
        C_ENR.DEVI_CAP_THEO_REST                                   AS P1_22_35,  -- L3735 [P1 22.35]
        '3'                                                        AS P1_22_36,  -- L3736 [P1 22.36]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_22_44,  -- L3746 [P1 22.44]
        'EUR'                                                      AS P1_22_45,  -- L3747 [P1 22.45]
        C_ENR.DATE_DEB_PALL                                        AS P1_22_58,  -- L3753 [P1 22.58]
        C_ENR.DATE_FIN_PALL                                        AS P1_22_59,  -- L3754 [P1 22.59]
        C_ENR.MNT_ECH_EN_COURS                                     AS P1_22_60,  -- L3755 [P1 22.60]
        C_ENR.DEVI_MNT_ECH_EN_COURS                                AS P1_22_61,  -- L3757 [P1 22.61]
        C_ENR.IND_PRE_POST_FIX                                     AS P1_22_62,  -- L3758 [P1 22.62]
        C_ENR.DATE_DEB_ENG_RENVL                                   AS P1_22_63,  -- L3759 [P1 22.63]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L3764 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L3765 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L3768 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L3769 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L3771 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L3774 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L3776 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L3777 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L3778 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L3779 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L3780 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L3781 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L3783 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L3784 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L3785 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L3786 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L3788 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L3793 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L3794 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L3796 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L3797 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L3801 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L3803 [position V44]
        C_ENR.IND_OPE_EFFET_LEVIER                                 AS P1_28_1,  -- L3806 [position V44]
        C_ENR.IND_SPONSOR_FIN                                      AS P1_28_2,  -- L3808 [position V44]
        'N'                                                        AS P1_30_22,  -- L3820 [position V44]
        'N'                                                        AS P1_30_25,  -- L3825 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L3829 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L3830 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L3831 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L3832 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L3833 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L3836 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L3837 [position V44]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) AS P1_31_17,  -- L3846 [P1 31.17]
        NVL(CEIL((C_ENR.DT_FIN_ENG - C_ENR.DT_DEBUT_ENG) / 30), 0) AS P1_31_18,  -- L3848 [P1 31.18]
        C_ENR.CDTYPEGARPRINCOCTROI                                 AS P1_31_21,  -- L3852 [position V44]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L3853 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L3867 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L3870 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L3871 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L3913 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L3914 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L3915 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L3918 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L3919 [position V44]
        C_ENR.MOTIF_MRTR                                           AS P1_21_22,  -- L3926 [P1 21.22]
        C_ENR.DT_DEBUT_MRTR                                        AS P1_21_23,  -- L3927 [P1 21.23]
        case when C_ENR.DUREE_MRTR is not null then C_ENR.DUREE_MRTR else NULL end AS P1_21_29,  -- L3928 [P1 21.29]
        C_ENR.STATUT_MRTR                                          AS P1_21_25,  -- L3929 [P1 21.25]
        C_ENR.IND_MRTR_LEGISLATIF                                  AS P1_21_26,  -- L3930 [P1 21.26]
        C_ENR.IND_MRTR_CONTRACTUEL                                 AS P1_21_27,  -- L3931 [P1 21.27]
        C_ENR.CHAMP_APPL_MRTR                                      AS P1_21_28,  -- L3932 [P1 21.28]
        case when C_ENR.MNT_MRTR is not null then C_ENR.MNT_MRTR else NULL end AS P1_21_30,  -- L3933 [P1 21.30]
        case when C_ENR.MNT_MRTR is not null then C_ENR.DEV_MRTR else NULL end AS P1_21_31,  -- L3934 [P1 21.31]
        C_ENR.IND_EXPO_QUAL_ELEVEE                                 AS P1_21_44,  -- L3954 [P1 21.44]
        C_ENR.IND_PHASE_OPE_PROJ_FIN                               AS P1_21_45,  -- L3955 [P1 21.45]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L3956 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L3957 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L3958 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L3959 [P1 21.40]
        C_ENR.ETV_RATIO                                            AS P1_21_43,  -- L3962 [P1 21.43]
        C_ENR.IND_INVEST_CAPITAL_RISQ                              AS P1_21_57,  -- L3964 [P1 21.57]
        C_ENR.IND_INVEST_PROG_LEGISLATIF                           AS P1_21_58,  -- L3965 [P1 21.58]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L3973 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L3975 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L3976 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L3980 [P1 8.13]
        C_ENR.COMMUNE                                              AS P1_21_71,  -- L3981 [P1 21.71]
        C_ENR.NUM_VOIE                                             AS P1_21_72,  -- L3982 [P1 21.72]
        C_ENR.EXTENSION                                            AS P1_21_73,  -- L3983 [P1 21.73]
        C_ENR.TYPE_VOIE                                            AS P1_21_74,  -- L3984 [P1 21.74]
        C_ENR.LIB_VOIE                                             AS P1_21_75,  -- L3985 [P1 21.75]
        C_ENR.LIEU_DIT                                             AS P1_21_76,  -- L3986 [P1 21.76]
        C_ENR.LATITUDE                                             AS P1_21_77,  -- L3987 [P1 21.77]
        C_ENR.LONGITUDE                                            AS P1_21_78,  -- L3988 [P1 21.78]
        C_ENR.TX_DSCR                                              AS P1_21_81,  -- L3993 [P1 21.81]
        C_ENR.TX_DSCR_PREC                                         AS P1_21_82,  -- L3994 [P1 21.82]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L3998 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L3999 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L4000 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5');

    ------------------------------------------------------------------
    -- INSERT #6  (Hors-NAT EQU101 - spool L4026)
    --   colonnes : 112 (dont 28 ancrees --P1) | 405 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_5_2,
        P1_19_5,
        P1_3_56,
        P1_3_50,
        P1_3_51,
        P1_3_52,
        P1_3_53,
        P1_3_54,
        P1_3_55,
        P1_3_61,
        P1_3_8,
        P1_3_9,
        P1_3_31,
        P1_12_1,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_3_75,
        P1_4_42,
        P1_3_3,
        P1_21_6,
        P1_21_16,
        P1_21_17,
        P1_22_56,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_36,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_24_3,
        P1_24_4,
        P1_24_5,
        P1_24_6,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_46,
        P1_21_57,
        P1_21_58,
        P1_21_59,
        P1_21_60,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_94,
        P1_21_79,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        6                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L4026 [en-tete conv.]
        TO_CHAR(C_ENR.CD_CONSO_CPT)                                AS P1_H_0_2,  -- L4027 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L4028 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L4029 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L4030 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L4031 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L4035 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L4039 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L4040 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L4042 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L4045 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L4047 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L4048 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L4049 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L4050 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L4051 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L4052 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L4053 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L4054 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L4057 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L4071 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4075 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L4077 [P1 5.2]
        C_ENR.CD_CPT_ACTIF_IAS                                     AS P1_19_5,  -- L4138 [position V44]
        C_ENR.PCCO_ACQUISITION                                     AS P1_3_56,  -- L4139 [position V44]
        NVL((C_ENR.MNT_ACQUISITION), 0)                            AS P1_3_50,  -- L4140 [position V44]
        NVL(C_ENR.CD_DEVISE_ACQUISITION, 'EUR')                    AS P1_3_51,  -- L4141 [position V44]
        NVL(C_ENR.MNT_MTM, 0)                                      AS P1_3_52,  -- L4142 [position V44]
        C_ENR.CD_DEVISE_MTM                                        AS P1_3_53,  -- L4144 [position V44]
        NVL(C_ENR.MNT_COUT_AMORTI, 0)                              AS P1_3_54,  -- L4145 [position V44]
        NVL(C_ENR.CD_DEV_COUT_AMORTI, 'EUR')                       AS P1_3_55,  -- L4146 [position V44]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_3_61,  -- L4159 [position V44]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS P1_3_8,  -- L4161 [position V44]
        C_ENR.CD_DEVISE_NOMINAL                                    AS P1_3_9,  -- L4162 [position V44]
        C_ENR.PCCO_NOMINAL                                         AS P1_3_31,  -- L4163 [position V44]
        C_ENR.NATURE_PROD_SS_JACENT                                AS P1_12_1,  -- L4164 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4171 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4234 [P1 4.31]
        C_ENR.MATURITE_EFF                                         AS P1_3_20,  -- L4249 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L4252 [position V44]
        C_ENR.INSTRUMENT_FINANCIER                                 AS P1_3_75,  -- L4254 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L4255 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L4256 [position V44]
        NVL(C_ENR.IND_CRE_PERF, 'PE')                              AS P1_21_6,  -- L4329 [position V44]
        C_ENR.DT_PL_NPL                                            AS P1_21_16,  -- L4331 [position V44]
        C_ENR.CD_MOTIF_PL_NPL                                      AS P1_21_17,  -- L4332 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L4337 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L4341 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_51,  -- L4342 [position V44]
        'ND'                                                       AS P1_22_5,  -- L4346 [position V44]
        '97'                                                       AS P1_22_7,  -- L4352 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4353 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4354 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L4355 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L4359 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L4365 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L4367 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L4369 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L4371 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L4372 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L4373 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L4374 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L4375 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L4376 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L4378 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L4379 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L4380 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L4381 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L4383 [position V44]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS P1_24_3,  -- L4385 [position V44]
        C_ENR.COMPLEXITE_PRODUIT                                   AS P1_24_4,  -- L4386 [position V44]
        C_ENR.IND_ACTIF_COTE                                       AS P1_24_5,  -- L4387 [position V44]
        C_ENR.NB_TITRES                                            AS P1_24_6,  -- L4388 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L4413 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L4414 [P1 22.11]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L4416 [P1 26.3]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L4417 [P1 26.4]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L4420 [P1 27.3]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L4422 [P1 27.4]
        'N'                                                        AS P1_30_22,  -- L4433 [position V44]
        'N'                                                        AS P1_30_25,  -- L4438 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L4442 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L4443 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L4444 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L4445 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L4446 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L4449 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L4450 [position V44]
        0                                                          AS P1_31_17,  -- L4454 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4456 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4461 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L4468 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L4472 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L4473 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L4496 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L4497 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L4498 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L4501 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L4502 [position V44]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L4539 [P1 21.46]
        C_ENR.IND_INVEST_CAPITAL_RISQ                              AS P1_21_57,  -- L4547 [P1 21.57]
        C_ENR.IND_INVEST_PROG_LEGISLATIF                           AS P1_21_58,  -- L4548 [P1 21.58]
        C_ENR.IND_PARTICIP_STRATG_SUP_6A                           AS P1_21_59,  -- L4549 [P1 21.59]
        C_ENR.TX_HIST_POND_PARTICIPATION                           AS P1_21_60,  -- L4550 [P1 21.60]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L4558 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L4559 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L4563 [P1 8.13]
        C_ENR.IND_HQLA                                             AS P1_21_94,  -- L4572 [P1 21.94]
        C_ENR.IND_TITRE_PARTICIP                                   AS P1_21_79,  -- L4574 [P1 21.79]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L4581 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L4582 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L4583 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('EQU101');

    ------------------------------------------------------------------
    -- INSERT #7  (Hors-NAT SIG201/INR101 - spool L4606)
    --   colonnes : 111 (dont 23 ancrees --P1) | 259 fillers -> NULL | 2 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_4_1,
        P1_5_2,
        P1_4_5,
        P1_4_14,
        P1_4_15,
        P1_4_16,
        P1_4_17,
        P1_4_18,
        P1_4_6,
        P1_4_7,
        P1_4_19,
        P1_5_7,
        P1_19_5,
        P1_2_99,
        P1_4_31,
        P1_3_20,
        P1_4_8,
        P1_4_42,
        P1_3_3,
        P1_22_56,
        P1_22_57,
        P1_22_1,
        P1_22_51,
        P1_22_5,
        P1_22_52,
        P1_22_6,
        P1_22_53,
        P1_22_54,
        P1_22_55,
        P1_22_7,
        P1_22_8,
        P1_22_9,
        P1_22_12,
        P1_22_36,
        P1_22_66,
        P1_22_67,
        P1_22_68,
        P1_22_70,
        P1_22_71,
        P1_22_72,
        P1_23_1,
        P1_23_2,
        P1_23_3,
        P1_23_4,
        P1_23_5,
        P1_23_6,
        P1_23_7,
        P1_23_8,
        P1_23_9,
        P1_23_10,
        P1_23_11,
        P1_24_1,
        P1_26_1,
        P1_22_11,
        P1_26_3,
        P1_26_4,
        P1_27_3,
        P1_27_4,
        P1_30_22,
        P1_30_25,
        P1_31_2,
        P1_31_3,
        P1_31_4,
        P1_31_5,
        P1_31_6,
        P1_31_9,
        P1_31_10,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_31_37,
        P1_29_3,
        P1_29_4,
        P1_50_1,
        P1_50_2,
        P1_50_3,
        P1_50_8,
        P1_50_9,
        P1_21_46,
        P1_21_38,
        P1_21_39,
        P1_21_40,
        P1_21_66,
        P1_21_68,
        P1_21_55,
        P1_8_13,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        7                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L4606 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L4607 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L4608 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L4609 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L4610 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L4611 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L4615 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L4619 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L4620 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L4622 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L4625 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L4626 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L4627 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L4628 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L4629 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L4630 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L4631 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L4632 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L4633 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L4634 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L4648 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L4652 [P1 5.5]
        C_ENR.CD_IMP_PRUDENT                                       AS P1_4_1,  -- L4653 [P1 4.1]
        NVL(C_ENR.TOP_ENG_DOUTEUX, 'N')                            AS P1_5_2,  -- L4654 [P1 5.2]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L4668 [position V44]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L4673 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L4678 [position V44]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS P1_4_16,  -- L4679 [position V44]
        C_ENR.CD_DEVISE_NOMINAL                                    AS P1_4_17,  -- L4680 [position V44]
        C_ENR.PCCO_NOMINAL                                         AS P1_4_18,  -- L4681 [position V44]
        NVL((C_ENR.MNT_INT_RD), 0)                                 AS P1_4_6,  -- L4682 [position V44]
        C_ENR.CD_DEVISE_INT_RD                                     AS P1_4_7,  -- L4683 [position V44]
        C_ENR.PCCO_INT_RD                                          AS P1_4_19,  -- L4684 [position V44]
        C_ENR.ID_TIERS_CALC                                        AS P1_5_7,  -- L4694 [position V44]
        C_ENR.CLA_COMP_REF_ACT                                     AS P1_19_5,  -- L4703 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L4733 [P1 2.99]
        C_ENR.IND_PROD_SS_JACENT                                   AS P1_4_31,  -- L4757 [P1 4.31]
        NVL(C_ENR.MATURITE_EFF, 0)                                 AS P1_3_20,  -- L4776 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L4779 [position V44]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L4782 [position V44]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L4783 [position V44]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L4790 [position V44]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L4792 [P1 22.57]
        C_ENR.REF_UNIQ_CONT                                        AS P1_22_1,  -- L4793 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_22_51,  -- L4794 [position V44]
        'ND'                                                       AS P1_22_5,  -- L4796 [position V44]
        C_ENR.NOTE_EXT_ORI                                         AS P1_22_52,  -- L4797 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_6,  -- L4798 [position V44]
        C_ENR.SEG_NOT_ORI                                          AS P1_22_53,  -- L4800 [position V44]
        CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI||'FR' END AS P1_22_54,  -- L4801 [position V44]
        upper(C_ENR.METH_NOT_ORI)                                  AS P1_22_55,  -- L4804 [position V44]
        '97'                                                       AS P1_22_7,  -- L4805 [position V44]
        C_ENR.MNT_CONTRAT_ORIGINE                                  AS P1_22_8,  -- L4806 [P1 22.8]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L4807 [P1 22.9]
        C_ENR.IND_ECH_FOUR                                         AS P1_22_12,  -- L4808 [position V44]
        C_ENR.IND_RMB_ANTICIPE                                     AS P1_22_36,  -- L4812 [position V44]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L4819 [position V44]
        C_ENR.DT_SIGNATURE                                         AS P1_22_67,  -- L4821 [position V44]
        C_ENR.EVT_DECL_GAR                                         AS P1_22_68,  -- L4822 [position V44]
        TO_CHAR(C_ENR.NB_JOURS_RETARD)                             AS P1_22_70,  -- L4824 [position V44]
        CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END AS P1_22_71,  -- L4825 [position V44]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L4827 [position V44]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_1,  -- L4829 [position V44]
        C_ENR.CENTRE_RES                                           AS P1_23_2,  -- L4839 [position V44]
        C_ENR.SYS_GEST_SRC                                         AS P1_23_3,  -- L4840 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_4,  -- L4841 [position V44]
        C_ENR.CLA_COMP_ACT_NATIONALE                               AS P1_23_5,  -- L4842 [position V44]
        C_ENR.IND_ACT_DEP_ORI                                      AS P1_23_6,  -- L4843 [position V44]
        C_ENR.ZONE_APP_COMP                                        AS P1_23_7,  -- L4844 [position V44]
        C_ENR.CD_METH_IFRS9_PD                                     AS P1_23_8,  -- L4846 [position V44]
        C_ENR.CD_METH_IFRS9_LGD                                    AS P1_23_9,  -- L4847 [position V44]
        C_ENR.CD_METH_IFRS9_CCF                                    AS P1_23_10,  -- L4848 [position V44]
        C_ENR.CD_METH_IFRS9_TX                                     AS P1_23_11,  -- L4849 [position V44]
        C_ENR.ELIGIB_PRUDENT_VAL                                   AS P1_24_1,  -- L4851 [position V44]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_1,  -- L4854 [position V44]
        C_ENR.ELIG_MOB_BANQUE_CENTRALE                             AS P1_22_11,  -- L4855 [position V44]
        C_ENR.REF_MOB_ACTIF                                        AS P1_26_3,  -- L4857 [position V44]
        C_ENR.CD_ORGA_MOBIL                                        AS P1_26_4,  -- L4858 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_3,  -- L4862 [position V44]
        C_ENR.MOTIF_EXCLU_ANACREDIT                                AS P1_27_4,  -- L4864 [position V44]
        'N'                                                        AS P1_30_22,  -- L4877 [position V44]
        'N'                                                        AS P1_30_25,  -- L4882 [position V44]
        C_ENR.REF_UNIQ_CONT                                        AS P1_31_2,  -- L4886 [position V44]
        C_ENR.REF_UNIQ_ELEM_CONT                                   AS P1_31_3,  -- L4887 [position V44]
        C_ENR.MNT_ENG_DT_SIGN_CTRT                                 AS P1_31_4,  -- L4888 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_5,  -- L4889 [position V44]
        NVL(C_ENR.IND_ISF, '2')                                    AS P1_31_6,  -- L4890 [position V44]
        C_ENR.CD_COMMUNE_BIEN_FINAN                                AS P1_31_9,  -- L4893 [position V44]
        C_ENR.CD_PAYS_BIEN_FINAN                                   AS P1_31_10,  -- L4894 [position V44]
        0                                                          AS P1_31_17,  -- L4898 [P1 31.17]
        0                                                          AS P1_31_18,  -- L4900 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L4906 [P1 31.22]
        C_ENR.IND_GAR_SANS_LIMITE                                  AS P1_31_37,  -- L4912 [position V44]
        C_ENR.MNT_SUBV_HT                                          AS P1_29_3,  -- L4916 [position V44]
        'EUR'                                                      AS P1_29_4,  -- L4917 [P1 29.4]
        'EUR'                                                      AS P1_50_1,  -- L4952 [position V44]
        C_ENR.PCEC_MNT_RISQUE                                      AS P1_50_2,  -- L4953 [position V44]
        C_ENR.MNT_RISQUE                                           AS P1_50_3,  -- L4954 [position V44]
        C_ENR.PCEC_ICNE                                            AS P1_50_8,  -- L4957 [position V44]
        C_ENR.MNT_ICNE                                             AS P1_50_9,  -- L4958 [position V44]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L4995 [P1 21.46]
        C_ENR.IND_IPRE                                             AS P1_21_38,  -- L4996 [P1 21.38]
        C_ENR.IND_EXPO_ADC                                         AS P1_21_39,  -- L4997 [P1 21.39]
        C_ENR.IND_REAL_COND_PONDERATION_PREFE                      AS P1_21_40,  -- L4998 [P1 21.40]
        C_ENR.IND_UCC                                              AS P1_21_66,  -- L5012 [P1 21.66]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L5014 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L5015 [P1 21.55]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L5019 [P1 8.13]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L5037 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L5038 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L5039 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101');

    ------------------------------------------------------------------
    -- INSERT #8  (Hors-NAT VAR1 - spool L5061)
    --   colonnes : 101 (dont 35 ancrees --P1) | 318 fillers -> NULL | 3 signes absorbes par le NUMBER
    ------------------------------------------------------------------
    INSERT INTO ENG_CORP_P1_BIS
    (
        CD_PERIMETRE,
        NO_VARIANTE,
        ID_ENGAGEMENT,
        DT_ARRETE,
        P1_H_0_1,
        P1_H_0_2,
        P1_H_0_3,
        P1_H_0_4,
        P1_H_0_5,
        P1_H_0_6,
        P1_H_1_1,
        P1_H_1_4,
        P1_H_1_6,
        P1_H_1_11,
        P1_1_1,
        P1_1_2,
        P1_4_34,
        P1_2_0,
        P1_2_4,
        P1_2_6,
        P1_2_18,
        P1_2_29,
        P1_3_2,
        P1_3_4,
        P1_18_18,
        P1_5_5,
        P1_5_2,
        P1_4_5,
        P1_4_14,
        P1_4_15,
        P1_19_5,
        P1_3_8,
        P1_3_9,
        P1_3_31,
        P1_12_1,
        P1_2_99,
        P1_3_80,
        P1_3_81,
        P1_3_82,
        P1_3_83,
        P1_3_15,
        P1_13_10,
        P1_3_16,
        P1_3_17,
        P1_3_19,
        P1_3_84,
        P1_3_85,
        P1_3_72,
        P1_3_73,
        P1_3_20,
        P1_4_8,
        P1_3_75,
        P1_4_42,
        P1_3_3,
        P1_3_36,
        P1_15_1,
        P1_15_2,
        P1_3_86,
        P1_3_87,
        P1_3_88,
        P1_11_1,
        P1_3_76,
        P1_3_77,
        P1_3_10,
        P1_8_2,
        P1_10_2,
        P1_8_1,
        P1_8_11,
        P1_8_12,
        P1_22_56,
        P1_22_57,
        P1_22_52,
        P1_22_54,
        P1_22_8,
        P1_22_9,
        P1_22_16,
        P1_22_66,
        P1_22_72,
        P1_23_3,
        P1_23_7,
        P1_24_3,
        P1_24_20,
        P1_24_23,
        P1_24_24,
        P1_26_99,
        P1_27_99,
        P1_30_22,
        P1_30_23,
        P1_30_26,
        P1_31_2,
        P1_31_9,
        P1_31_17,
        P1_31_18,
        P1_31_22,
        P1_29_4,
        P1_50_2,
        P1_21_46,
        P1_21_68,
        P1_21_55,
        P1_21_69,
        P1_8_13,
        P1_21_80,
        P1_21_86,
        P1_21_87,
        P1_21_88
    )
    SELECT
        'HORS_NAT02'                                               AS CD_PERIMETRE,
        8                                                          AS NO_VARIANTE,
        C_ENR.ID_ENGAGEMENT                                        AS ID_ENGAGEMENT,
        C_ENR.DT_ARRETE                                            AS DT_ARRETE,
        C_ENR.DT_ARRETE                                            AS P1_H_0_1,  -- L5061 [en-tete conv.]
        C_ENR.CD_CONSO_CPT                                         AS P1_H_0_2,  -- L5062 [en-tete conv.]
        'C_DDR'                                                    AS P1_H_0_3,  -- L5063 [en-tete conv.]
        'M'                                                        AS P1_H_0_4,  -- L5064 [en-tete conv.]
        p_masysdate                                                AS P1_H_0_5,  -- L5065 [en-tete conv.]
        'P1'                                                       AS P1_H_0_6,  -- L5066 [en-tete conv.]
        C_ENR.ID_TIERS_CALC                                        AS P1_H_1_1,  -- L5070 [position V44]
        C_ENR.ID_AUTORISATION                                      AS P1_H_1_4,  -- L5074 [position V44]
        C_ENR.ID_LIGNE_DET                                         AS P1_H_1_6,  -- L5075 [position V44]
        C_ENR.ID_ENGAGEMENT                                        AS P1_H_1_11,  -- L5077 [position V44]
        C_ENR.CD_METHODO_BALE2                                     AS P1_1_1,  -- L5080 [position V44]
        C_ENR.CODE_TRAIT_MOTEUR                                    AS P1_1_2,  -- L5082 [position V44]
        C_ENR.CODE_TRAIT_GRR                                       AS P1_4_34,  -- L5083 [position V44]
        C_ENR.CD_TYPE_RISQUE                                       AS P1_2_0,  -- L5084 [position V44]
        C_ENR.CD_PORTEFEUILLE_BOOKING                              AS P1_2_4,  -- L5085 [position V44]
        C_ENR.CD_LIGNE_METIER                                      AS P1_2_6,  -- L5086 [position V44]
        C_ENR.CD_PORTEFEUILLE_BALE2                                AS P1_2_18,  -- L5087 [position V44]
        C_ENR.CD_NATURE_OPE                                        AS P1_2_29,  -- L5088 [position V44]
        C_ENR.DT_DEBUT_ENG                                         AS P1_3_2,  -- L5089 [position V44]
        C_ENR.DT_FIN_ENG                                           AS P1_3_4,  -- L5092 [position V44]
        C_ENR.CD_DEVISE_ORIGINE                                    AS P1_18_18,  -- L5106 [position V44]
        NVL(C_ENR.CD_ARR_PAIEMENT, 'N')                            AS P1_5_5,  -- L5111 [P1 5.5]
        C_ENR.TOP_ENG_DOUTEUX                                      AS P1_5_2,  -- L5114 [P1 5.2]
        C_ENR.CD_DEVISE_MNT_DECOUVERT                              AS P1_4_5,  -- L5130 [position V44]
        C_ENR.MNT_LOYER                                            AS P1_4_14,  -- L5135 [position V44]
        C_ENR.CD_DEVISE_CRD                                        AS P1_4_15,  -- L5140 [position V44]
        C_ENR.cla_comp_ref_act                                     AS P1_19_5,  -- L5185 [position V44]
        NVL((C_ENR.MNT_NOMINAL), 0)                                AS P1_3_8,  -- L5211 [position V44]
        C_ENR.CD_DEVISE_NOMINAL                                    AS P1_3_9,  -- L5213 [position V44]
        C_ENR.PCCO_NOMINAL                                         AS P1_3_31,  -- L5214 [position V44]
        C_ENR.NATURE_PROD_SS_JACENT                                AS P1_12_1,  -- L5215 [position V44]
        C_ENR.CD_METH_IFRS9_PD_ORIG                                AS P1_2_99,  -- L5222 [P1 2.99]
        NVL((C_ENR.MNT_MTM), 0)                                    AS P1_3_80,  -- L5223 [position V44]
        C_ENR.CD_DEVISE_MTM                                        AS P1_3_81,  -- L5225 [position V44]
        C_ENR.PCCO_MTM                                             AS P1_3_82,  -- L5226 [position V44]
        C_ENR.MODELE_ASSIETE_RISQUE                                AS P1_3_83,  -- L5227 [position V44]
        C_ENR.IND_ACCORD_COLLATERISATION                           AS P1_3_15,  -- L5228 [position V44]
        C_ENR.REF_ACCORD_COLLATERISATION                           AS P1_13_10,  -- L5229 [position V44]
        C_ENR.IND_ACCORD_NETTING                                   AS P1_3_16,  -- L5230 [position V44]
        C_ENR.REF_CONTRAT_NETTING                                  AS P1_3_17,  -- L5231 [position V44]
        C_ENR.DEV_CONTRAT_NETTING                                  AS P1_3_19,  -- L5232 [position V44]
        NVL((C_ENR.MT_ASSIETE_INTERNE), 0)                         AS P1_3_84,  -- L5233 [position V44]
        C_ENR.DEV_ASSIETE_INTERNE                                  AS P1_3_85,  -- L5234 [position V44]
        NVL((C_ENR.MT_ASSIETE_REGLEMENTAIRE), 0)                   AS P1_3_72,  -- L5235 [position V44]
        C_ENR.DEV_ASSIETE_REGLEMENTAIRE                            AS P1_3_73,  -- L5236 [position V44]
        NVL(C_ENR.MATURITE_EFF, 0)                                 AS P1_3_20,  -- L5299 [position V44]
        C_ENR.TOP_ENG                                              AS P1_4_8,  -- L5302 [position V44]
        C_ENR.INSTRUMENT_FINANCIER                                 AS P1_3_75,  -- L5304 [P1 3.75]
        C_ENR.CD_TYPE_PROD_BANCAIRE                                AS P1_4_42,  -- L5305 [P1 4.42]
        C_ENR.DT_ARRETE                                            AS P1_3_3,  -- L5306 [position V44]
        C_ENR.IND_CCP                                              AS P1_3_36,  -- L5330 [position V44]
        C_ENR.CODE_INDICE_BOURSE                                   AS P1_15_1,  -- L5336 [position V44]
        C_ENR.CODE_PAYS_BOURSE                                     AS P1_15_2,  -- L5337 [position V44]
        NVL((C_ENR.MT_CVA_COMPTA), 0)                              AS P1_3_86,  -- L5341 [position V44]
        C_ENR.DEV_CVA_COMPTA                                       AS P1_3_87,  -- L5343 [position V44]
        C_ENR.IND_RISQ_COLLAT_SPECIF                               AS P1_3_88,  -- L5344 [position V44]
        C_ENR.TYPE_CREDIT_DERIVE                                   AS P1_11_1,  -- L5347 [position V44]
        C_ENR.IND_DENOUEMENT_CDS                                   AS P1_3_76,  -- L5348 [position V44]
        C_ENR.IND_ELLIGIBILITE_CVA                                 AS P1_3_77,  -- L5349 [position V44]
        ABS(TRUNC(NVL(C_ENR.MT_SPREAD, 0)))                        AS P1_3_10,  -- L5357 [position V44]
        C_ENR.TYPE_SWAP                                            AS P1_8_2,  -- L5363 [position V44]
        C_ENR.IND_CALL_PUT                                         AS P1_10_2,  -- L5365 [P1 10.2]
        C_ENR.TYPE_TAUX_PAYE                                       AS P1_8_1,  -- L5366 [P1 8.1]
        C_ENR.TYPE_TAUX_RECU                                       AS P1_8_11,  -- L5368 [P1 8.11]
        C_ENR.REF_TAUX_RECU                                        AS P1_8_12,  -- L5369 [P1 8.12]
        C_ENR.IND_PROD_ECH                                         AS P1_22_56,  -- L5380 [P1 22.56]
        C_ENR.IND_OBJ_MET_PAL                                      AS P1_22_57,  -- L5382 [P1 22.57]
        'ND'                                                       AS P1_22_52,  -- L5386 [position V44]
        C_ENR.ORGA_NOTATION_ORIG                                   AS P1_22_54,  -- L5388 [position V44]
        97                                                         AS P1_22_8,  -- L5395 [position V44]
        NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR')                  AS P1_22_9,  -- L5397 [P1 22.9]
        C_ENR.TYPE_AMOR_CAP                                        AS P1_22_16,  -- L5402 [P1 22.16]
        C_ENR.CD_PAYS_JURIDICTION                                  AS P1_22_66,  -- L5411 [P1 22.66]
        C_ENR.BUCKET_IFRS9                                         AS P1_22_72,  -- L5416 [P1 22.72]
        C_ENR.ELI_OUT_MUT_PROV                                     AS P1_23_3,  -- L5418 [position V44]
        C_ENR.CLA_COMP_ACT_IFRS9                                   AS P1_23_7,  -- L5424 [position V44]
        C_ENR.HIERARCHIE_JUSTE_VALEUR                              AS P1_24_3,  -- L5441 [P1 24.3]
        C_ENR.IND_BCK_TO_BCK                                       AS P1_24_20,  -- L5444 [P1 24.20]
        C_ENR.INTENTION_COUVERTURE                                 AS P1_24_23,  -- L5446 [P1 24.23]
        C_ENR.TYPE_REL_COUVERTURE                                  AS P1_24_24,  -- L5447 [P1 24.24]
        C_ENR.IND_MOBIL_ACTIF                                      AS P1_26_99,  -- L5450 [position V44]
        NVL(C_ENR.IND_ELIGI_OUTI_CTRAL_ANACRD, '2')                AS P1_27_99,  -- L5459 [position V44]
        C_ENR.CD_BASE_CALCUL_INT_PAYE                              AS P1_30_22,  -- L5481 [position V44]
        'N'                                                        AS P1_30_23,  -- L5486 [P1 30.23]
        'N'                                                        AS P1_30_26,  -- L5490 [position V44]
        C_ENR.FINALITE_OPERATION                                   AS P1_31_2,  -- L5492 [position V44]
        C_ENR.IND_RESPO_SOLIDAIRE                                  AS P1_31_9,  -- L5497 [position V44]
        0                                                          AS P1_31_17,  -- L5506 [P1 31.17]
        0                                                          AS P1_31_18,  -- L5508 [P1 31.18]
        CASE WHEN C_ENR.CD_TYPE_RISQUE = 'TRE502' THEN '01' WHEN C_ENR.CD_TYPE_RISQUE LIKE 'TRE%' THEN '02' ELSE '04' END AS P1_31_22,  -- L5514 [P1 31.22]
        'EUR'                                                      AS P1_29_4,  -- L5525 [P1 29.4]
        'EUR'                                                      AS P1_50_2,  -- L5531 [position V44]
        C_ENR.IND_CONF_CRIT_OPE                                    AS P1_21_46,  -- L5574 [P1 21.46]
        C_ENR.NIV_RISQUE_CRR3                                      AS P1_21_68,  -- L5593 [P1 21.68]
        C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR                            AS P1_21_55,  -- L5594 [P1 21.55]
        'N'                                                        AS P1_21_69,  -- L5595 [P1 21.69]
        C_ENR.USAGE_BIEN_FINANCE                                   AS P1_8_13,  -- L5598 [P1 8.13]
        C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE                        AS P1_21_80,  -- L5610 [P1 21.80]
        C_ENR.CD_TYPE_BIEN_COMM                                    AS P1_21_86,  -- L5616 [P1 21.86]
        C_ENR.CD_EMPLACE_BIEN_COMM                                 AS P1_21_87,  -- L5617 [P1 21.87]
        C_ENR.IND_OPE_AVEC_RECOURS                                 AS P1_21_88  -- L5618 [P1 21.88]
    FROM ENG_CORP_P1 C_ENR
    WHERE
      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%';

    END IF;

    COMMIT;
END P_ALIM_ENG_CORP_P1_BIS;

	  END pack_alim_tab_envoi_crrv4_new;
/
