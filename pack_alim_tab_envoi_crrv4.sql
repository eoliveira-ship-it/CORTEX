create or replace PACKAGE pack_alim_tab_envoi_crrv4 IS
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

	  END pack_alim_tab_envoi_crrv4;
