# Mapa SELECT #1 -> ENG_CORP_P1_BIS (campos anotados --P1)

| Coluna | Ref | Expr spool | Expr tipada proposta | Nota |
|---|---|---|---|---|
| P1_2_18 | P1 2.18 | RPAD(C_ENR.CD_PORTEFEUILLE_BALE2,3) | C_ENR.CD_PORTEFEUILLE_BALE2 | texto |
| P1_4_2 | P1 4.2 | RPAD(' ',1)\|\|RPAD(' ',16)\|\|RPAD(' ',2) | NULL | filler (branco) |
| P1_3_56 | P1 3.56 | RPAD(' ', 185) | NULL | filler (branco) |
| P1_2_99 | P1 2.99 | RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20) | C_ENR.CD_METH_IFRS9_PD_ORIG | texto |
| P1_3_80 | P1 3.80 | RPAD(' ', 354) | NULL | filler (branco) |
| P1_4_31 | P1 4.31 | RPAD(C_ENR.IND_PROD_SS_JACENT, 1,' ') | C_ENR.IND_PROD_SS_JACENT | texto |
| P1_4_8 | P1 4.8 | NVL(C_ENR.TOP_ENG,'B') | NVL(C_ENR.TOP_ENG,'B') | texto |
| P1_21_3 | P1 21.3 | RPAD(nvl(C_ENR.EVENMT_CRDT,' '),1) | C_ENR.EVENMT_CRDT | texto |
| P1_22_56 | P1 22.56 | RPAD(nvl(C_ENR.IND_PROD_ECH,' '),3) | C_ENR.IND_PROD_ECH | texto |
| P1_22_5 | P1 22.5 | RPAD(nvl(C_enr.NOTE_FIN_RET_ORI, 'ND'),2) | NVL(C_enr.NOTE_FIN_RET_ORI,'ND') | texto |
| P1_22_7 | P1 22.7 | RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2) | NVL(C_ENR.OBJ_FINANCIE,'97') | texto |
| P1_22_8 | P1 22.8 | RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2) | NVL(C_ENR.OBJ_FINANCIE,'97') | texto |
| P1_22_9 | P1 22.9 | RPAD(nvl(C_ENR.OBJ_FINANCIE,'97'),2) | NVL(C_ENR.OBJ_FINANCIE,'97') | texto |
| P1_22_8 | P1 22.8 | pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIG | C_ENR.MNT_CONTRAT_ORIGINE | montant/taux -> numero |
| P1_22_9 | P1 22.9 | RPAD(nvl(C_ENR.DEV_MNT_CONTRAT_ORIGINE, 'EUR'), 3) | NVL(C_ENR.DEV_MNT_CONTRAT_ORIGINE,'EUR') | texto |
| P1_22_23 | P1 22.23 | pack_utilitaire.F_FORMAT_TAUX(C_ENR.TAUX_PLAFOND) | C_ENR.TAUX_PLAFOND | montant/taux -> numero |
| P1_22_37 | P1 22.37 | RPAD(NVL(TO_CHAR(C_ENR.dt_exigte_prem_impy, 'YYYYMMDD'), ' ' | C_ENR.dt_exigte_prem_impy | data -> DATE |
| P1_22_38 | P1 22.38 | RPAD(NVL(TO_CHAR(C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS, 'YYYYMM | C_ENR.DT_PASSAGE_DOUTEUX_COMPROMIS | data -> DATE |
| P1_22_39 | P1 22.39 | RPAD(' ', 19) | NULL | filler (branco) |
| P1_22_40 | P1 22.40 | RPAD(' ', 3) | NULL | filler (branco) |
| P1_22_41 | P1 22.41 | RPAD(' ', 8) | NULL | filler (branco) |
| P1_22_42 | P1 22.42 | RPAD(' ', 10) | NULL | filler (branco) |
| P1_22_43 | P1 22.43 | RPAD(' ', 10) | NULL | filler (branco) |
| P1_22_44 | P1 22.44 | pack_utilitaire.f_format_montant_bis2(nvl((C_ENR.MNT_ACQUISI | nvl((C_ENR.MNT_ACQUISITION),0) | montant/taux -> numero |
| P1_22_45 | P1 22.45 | RPAD('EUR', 3) | 'EUR' | literal |
| P1_22_46 | P1 22.46 | RPAD(' ', 8) | NULL | filler (branco) |
| P1_22_47 | P1 22.47 | RPAD(' ', 19) | NULL | filler (branco) |
| P1_22_48 | P1 22.48 | RPAD(' ', 3) | NULL | filler (branco) |
| P1_22_49 | P1 22.49 | RPAD(' ', 10) | NULL | filler (branco) |
| P1_22_50 | P1 22.50 | RPAD(' ', 10) | NULL | filler (branco) |
| P1_22_60 | P1 22.60 | RPAD(NVL(TO_CHAR(C_ENR.DATE_FIN_PALL, 'YYYYMMDD'), ' '), 8) | C_ENR.DATE_FIN_PALL | data -> DATE |
| P1_22_60 | P1 22.60 | pack_utilitaire.F_FORMAT_MONTANT_NEGATIF_19(C_ENR.MNT_ECH_EN | C_ENR.MNT_ECH_EN_COURS | montant/taux -> numero |
| P1_22_63 | P1 22.63 | RPAD(NVL(TO_CHAR(C_ENR.DATE_DEB_ENG_RENVL,'YYYYMMDD'),' '),  | C_ENR.DATE_DEB_ENG_RENVL | data -> DATE |
| P1_23_1 | P1 23.1 | RPAD(nvl(C_ENR.ELI_OUT_MUT_PROV,' '),1) | C_ENR.ELI_OUT_MUT_PROV | texto |
| P1_23_8 | P1 23.8 | RPAD (nvl(C_ENR.CD_METH_IFRS9_PD,' '), 12) | C_ENR.CD_METH_IFRS9_PD | texto |
| P1_25 | P1 25 | RPAD (' ', 178) | NULL | filler (branco) |
| P1_26 | P1 26 | RPAD (' ', 178) | NULL | filler (branco) |
| P1_28 | P1 28 | RPAD (' ', 23) | NULL | filler (branco) |
| P1_31_17 | P1 31.17 | RPAD ('+', 1) | '+' | literal |
| P1_31_17 | P1 31.17 | end | /*?*/ end | revisar |
| P1_31_18 | P1 31.18 | RPAD ('+', 1) | '+' | literal |
| P1_31_18 | P1 31.18 | end | /*?*/ end | revisar |
| P1_31_22 | P1 31.22 | END | /*?*/ END | revisar |
| P1_29_4 | P1 29.4 | RPAD ('EUR', 3) | 'EUR' | literal |
| P1_21_22 | P1 21.22 | RPAD(NVL(C_ENR.MOTIF_MRTR,' '),2) | C_ENR.MOTIF_MRTR | texto |
| P1_21_23 | P1 21.23 | RPAD(NVL(TO_CHAR(C_ENR.DT_DEBUT_MRTR, 'YYYYMMDD'), ' '),8) | C_ENR.DT_DEBUT_MRTR | data -> DATE |
| P1_21_29 | P1 21.29 | case when C_ENR.DUREE_MRTR is not null then '+'\|\|LPAD(C_EN | /*CASE*/ case when C_ENR.DUREE_MRTR is not null t | CASE - revisar |
| P1_21_25 | P1 21.25 | RPAD(NVL(C_ENR.STATUT_MRTR,' '),2) | C_ENR.STATUT_MRTR | texto |
| P1_21_26 | P1 21.26 | RPAD(NVL(C_ENR.IND_MRTR_LEGISLATIF,' '),1) | C_ENR.IND_MRTR_LEGISLATIF | texto |
| P1_21_27 | P1 21.27 | RPAD(NVL(C_ENR.IND_MRTR_CONTRACTUEL,' '),1) | C_ENR.IND_MRTR_CONTRACTUEL | texto |
| P1_21_28 | P1 21.28 | RPAD(NVL(C_ENR.CHAMP_APPL_MRTR,' '),2) | C_ENR.CHAMP_APPL_MRTR | texto |
| P1_21_30 | P1 21.30 | case when C_ENR.MNT_MRTR is not null then RPAD(pack_utilitai | /*CASE*/ case when C_ENR.MNT_MRTR is not null the | CASE - revisar |
| P1_21_31 | P1 21.31 | case when C_ENR.MNT_MRTR is not null then RPAD(NVL(C_ENR.DEV | /*CASE*/ case when C_ENR.MNT_MRTR is not null the | CASE - revisar |
| P1_21_32 | P1 21.32 | RPAD(' ',15) | NULL | filler (branco) |
| P1_21_33 | P1 21.33 | RPAD(' ',3) | NULL | filler (branco) |
| P1_15 | P1 15 | RPAD(' ',12) | NULL | filler (branco) |
| P1_16 | P1 16 | RPAD(' ',12) | NULL | filler (branco) |
| P1_14 | P1 14 | RPAD(' ',12) | NULL | filler (branco) |
| P1_50_20 | P1 50.20 | RPAD(' ',12) | NULL | filler (branco) |
| P1_50_21 | P1 50.21 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_34 | P1 21.34 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_35 | P1 21.35 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_36 | P1 21.36 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_37 | P1 21.37 | RPAD(' ',3) | NULL | filler (branco) |
| P1_21_47 | P1 21.47 | RPAD(' ',10) | NULL | filler (branco) |
| P1_21_48 | P1 21.48 | RPAD(' ',7) | NULL | filler (branco) |
| P1_21_49 | P1 21.49 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_50 | P1 21.50 | RPAD(' ',3) | NULL | filler (branco) |
| P1_21_51 | P1 21.51 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_52 | P1 21.52 | RPAD(' ',3) | NULL | filler (branco) |
| P1_21_53 | P1 21.53 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_54 | P1 21.54 | RPAD(' ',3) | NULL | filler (branco) |
| P1_21_44 | P1 21.44 | RPAD(NVL(C_ENR.IND_EXPO_QUAL_ELEVEE,' '),1) | C_ENR.IND_EXPO_QUAL_ELEVEE | texto |
| P1_21_45 | P1 21.45 | RPAD(NVL(C_ENR.IND_PHASE_OPE_PROJ_FIN,' '),1) | C_ENR.IND_PHASE_OPE_PROJ_FIN | texto |
| P1_21_46 | P1 21.46 | RPAD(NVL(C_ENR.IND_CONF_CRIT_OPE,' '),1) | C_ENR.IND_CONF_CRIT_OPE | texto |
| P1_21_38 | P1 21.38 | RPAD(NVL(C_ENR.IND_IPRE,' '),1) | C_ENR.IND_IPRE | texto |
| P1_21_39 | P1 21.39 | RPAD(NVL(C_ENR.IND_EXPO_ADC,' '),1) | C_ENR.IND_EXPO_ADC | texto |
| P1_21_40 | P1 21.40 | RPAD(NVL(C_ENR.IND_REAL_COND_PONDERATION_PREFE,' '),1) | C_ENR.IND_REAL_COND_PONDERATION_PREFE | texto |
| P1_21_41 | P1 21.41 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_42 | P1 21.42 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_43 | P1 21.43 | RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ENR.ETV_RATIO),15) | /*?*/ RPAD(pack_utilitaire.F_FORMAT_TAUX_15(C_ | revisar |
| P1_21_56 | P1 21.56 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_57 | P1 21.57 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_58 | P1 21.58 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_59 | P1 21.59 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_60 | P1 21.60 | RPAD(' ',15) | NULL | filler (branco) |
| P1_21_61 | P1 21.61 | RPAD(' ',10) | NULL | filler (branco) |
| P1_21_62 | P1 21.62 | RPAD(' ',10) | NULL | filler (branco) |
| P1_21_63 | P1 21.63 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_64 | P1 21.64 | RPAD(' ',3) | NULL | filler (branco) |
| P1_21_65 | P1 21.65 | RPAD(' ',5) | NULL | filler (branco) |
| P1_21_66 | P1 21.66 | RPAD(NVL(C_ENR.IND_UCC,' '),1) | C_ENR.IND_UCC | texto |
| P1_21_67 | P1 21.67 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_68 | P1 21.68 | RPAD(NVL(C_ENR.NIV_RISQUE_CRR3,' '),1) | C_ENR.NIV_RISQUE_CRR3 | texto |
| P1_21_55 | P1 21.55 | RPAD(NVL(C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR,' '),12) | C_ENR.CD_NAT_OPE_ENG_CALC_FLOOR | texto |
| P1_21_69 | P1 21.69 | RPAD(NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE LIKE 'VAR%' THEN 'N' | /*CASE*/ RPAD(NVL(CASE WHEN C_ENR.CD_TYPE_RISQUE  | CASE - revisar |
| P1_21_89 | P1 21.89 | RPAD(' ',20) | NULL | filler (branco) |
| P1_21_90 | P1 21.90 | RPAD(' ',10) | NULL | filler (branco) |
| P1_8_13 | P1 8.13 | RPAD(NVL(C_ENR.USAGE_BIEN_FINANCE,' '),1) | C_ENR.USAGE_BIEN_FINANCE | texto |
| P1_21_71 | P1 21.71 | RPAD(NVL(C_ENR.COMMUNE,' '),40) | C_ENR.COMMUNE | texto |
| P1_21_72 | P1 21.72 | RPAD(NVL(C_ENR.NUM_VOIE,' '),40) | C_ENR.NUM_VOIE | texto |
| P1_21_73 | P1 21.73 | RPAD(NVL(C_ENR.EXTENSION,' '),40) | C_ENR.EXTENSION | texto |
| P1_21_74 | P1 21.74 | RPAD(NVL(C_ENR.TYPE_VOIE,' '),40) | C_ENR.TYPE_VOIE | texto |
| P1_21_75 | P1 21.75 | RPAD(NVL(C_ENR.LIB_VOIE,' '),40) | C_ENR.LIB_VOIE | texto |
| P1_21_76 | P1 21.76 | RPAD(NVL(C_ENR.LIEU_DIT,' '),40) | C_ENR.LIEU_DIT | texto |
| P1_21_77 | P1 21.77 | RPAD(NVL(C_ENR.LATITUDE,' '),11) | C_ENR.LATITUDE | texto |
| P1_21_78 | P1 21.78 | RPAD(NVL(C_ENR.LONGITUDE,' '),12) | C_ENR.LONGITUDE | texto |
| P1_21_94 | P1 21.94 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_95 | P1 21.95 | RPAD(' ',2) | NULL | filler (branco) |
| P1_21_79 | P1 21.79 | RPAD(' ',1) | NULL | filler (branco) |
| P1_21_80 | P1 21.80 | RPAD(NVL(C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE,' '),3) | C_ENR.CLASS_CPT_ELEMENT_COUV_DERIVE | texto |
| P1_21_81 | P1 21.81 | RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR),10) | /*?*/ RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR | revisar |
| P1_21_82 | P1 21.82 | RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR.TX_DSCR_PREC),10) | /*?*/ RPAD(pack_utilitaire.F_FORMAT_TAUX(C_ENR | revisar |
| P1_21_83 | P1 21.83 | RPAD(' ',15) | NULL | filler (branco) |
| P1_21_84 | P1 21.84 | RPAD(' ',15) | NULL | filler (branco) |
| P1_21_85 | P1 21.85 | RPAD(' ',15) | NULL | filler (branco) |
| P1_21_86 | P1 21.86 | RPAD(NVL(C_ENR.CD_TYPE_BIEN_COMM,' '),1) | C_ENR.CD_TYPE_BIEN_COMM | texto |
| P1_21_87 | P1 21.87 | RPAD(NVL(C_ENR.CD_EMPLACE_BIEN_COMM,' '),1) | C_ENR.CD_EMPLACE_BIEN_COMM | texto |
| P1_21_88 | P1 21.88 | RPAD(NVL(C_ENR.IND_OPE_AVEC_RECOURS,' '),1) | C_ENR.IND_OPE_AVEC_RECOURS | texto |
| P1_21_91 | P1 21.91 | RPAD(' ',19) | NULL | filler (branco) |
| P1_21_92 | P1 21.92 | RPAD(' ',3) | NULL | filler (branco) |
| P1_21_93 | P1 21.93 | RPAD(' ',5) | NULL | filler (branco) |
| P1_31_51 | P1 31.51 | RPAD(' ',20) | NULL | filler (branco) |
| P1_31_52 | P1 31.52 | RPAD(' ',19) | NULL | filler (branco) |
| P1_31_53 | P1 31.53 | RPAD(' ',3) | NULL | filler (branco) |