# Posicoes do spool ainda por mapear

Geradas por `gen_procedure.py`. Cada linha e uma posicao do spool cuja
coluna de destino ainda nao e conhecida (sem ancora `--P1` no spool).
Ver `docs/ECART-VERSAO.md` para saber porque o mapeamento por posicao
nao pode ser feito automaticamente.

| INSERT | seq | linha spool | expressao (formatacao ja retirada) |
|---|---|---|---|
| #8 | 32 | L5216 | `C_ENR.SENS_TRANSACTION` |
| #8 | 62 | L5359 | `NVL((C_ENR.MT_NOTIONNEL_ACH), 0)` |
| #8 | 63 | L5360 | `C_ENR.DEV_NOTIONNEL_ACH` |
| #8 | 64 | L5361 | `NVL((C_ENR.MT_NOTIONNEL_VENDU), 0)` |
| #8 | 65 | L5362 | `C_ENR.DEV_NOTIONNEL_VENDU` |
| #8 | 73 | L5370 | `NVL((C_ENR.MT_QUANTITE_RECUE), 0)` |
| #8 | 74 | L5371 | `C_ENR.UNITE_QUANTITE_RECUE` |
| #8 | 75 | L5372 | `NVL((C_ENR.MT_QUANTITE_LIVREE), 0)` |
| #8 | 76 | L5373 | `C_ENR.UNITE_QUANTITE_LIVREE` |
| #8 | 79 | L5383 | `C_ENR.REF_UNIQ_CONT` |
| #8 | 80 | L5384 | `C_ENR.REF_UNIQ_ELEM_CONT` |
| #8 | 82 | L5387 | `C_ENR.NOTE_EXT_ORI` |
| #8 | 85 | L5391 | `CASE WHEN C_ENR.GRI_MOD_NOT_ORI IS NULL THEN NULL ELSE C_ENR.GRI_MOD_NOT_ORI\|\|'FR' END` |
| #8 | 86 | L5394 | `upper(C_ENR.METH_NOT_ORI)` |
| #8 | 90 | L5398 | `C_ENR.IND_ECH_FOUR` |
| #8 | 92 | L5404 | `C_ENR.IND_RMB_ANTICIPE` |
| #8 | 94 | L5414 | `CASE WHEN C_ENR.CD_MOTIF_SCO_LC0267 is NULL then NULL ELSE C_ENR.CD_MOTIF_SCO_LC0267 END` |
| #8 | 98 | L5423 | `C_ENR.SYS_GEST_SRC` |
| #8 | 102 | L5427 | `C_ENR.ZONE_APP_COMP` |
| #8 | 103 | L5429 | `C_ENR.CD_METH_IFRS9_PD` |
| #8 | 104 | L5430 | `C_ENR.CD_METH_IFRS9_LGD` |
| #8 | 105 | L5431 | `C_ENR.CD_METH_IFRS9_CCF` |
| #8 | 106 | L5432 | `C_ENR.CD_METH_IFRS9_TX` |
| #8 | 107 | L5434 | `C_ENR.ELIGIB_PRUDENT_VAL` |
| #8 | 118 | L5466 | `C_ENR.TYPE_CTT_CADDRE` |
| #8 | 119 | L5467 | `C_ENR.IND_PROTOCOLE_ISDA_ENTITE` |
| #8 | 120 | L5468 | `C_ENR.IND_PROTOCOLE_ISDA_CPTY` |
| #8 | 121 | L5470 | `NVL(C_ENR.MNT_CCNE_JB_VENDUE, 0)` |
| #8 | 122 | L5471 | `C_ENR.CD_DEV_MNT_CCNE_JB_VENDUE` |
| #8 | 123 | L5472 | `NVL(C_ENR.MNT_CCNE_JB_ACHETEE, 0)` |
| #8 | 124 | L5473 | `C_ENR.CD_DEV_MNT_CCNE_JB_ACHETEE` |
| #8 | 125 | L5474 | `C_ENR.PRD_PAY_TX_RECU` |
| #8 | 126 | L5475 | `CASE WHEN C_ENR.TYPE_TAUX_RECU IN ('V','R') THEN NVL(C_ENR.MRG_TX_RECU, 0) ELSE NULL END` |
| #8 | 127 | L5477 | `C_ENR.CD_BASE_CALCUL_INT_RECU` |
| #8 | 128 | L5478 | `C_ENR.PRD_PAY_TX_PAYE` |
| #8 | 129 | L5479 | `CASE WHEN C_ENR.TYPE_TAUX_PAYE IN ('V','R') THEN NVL(C_ENR.MRG_TX_PAYE, 0) ELSE NULL END` |
| #8 | 134 | L5494 | `C_ENR.REF_UNIQ_CONT` |
| #8 | 135 | L5495 | `C_ENR.REF_UNIQ_ELEM_CONT` |
| #8 | 136 | L5496 | `C_ENR.MNT_ENG_DT_SIGN_CTRT` |
| #8 | 139 | L5501 | `C_ENR.CD_COMMUNE_BIEN_FINAN` |
| #8 | 140 | L5502 | `C_ENR.CD_PAYS_BIEN_FINAN` |
| #8 | 144 | L5520 | `C_ENR.IND_GAR_SANS_LIMITE` |
| #8 | 145 | L5524 | `C_ENR.MNT_SUBV_HT` |
| #8 | 148 | L5532 | `C_ENR.PCEC_MNT_RISQUE` |
| #8 | 149 | L5533 | `C_ENR.MNT_RISQUE` |
| #8 | 150 | L5536 | `C_ENR.PCEC_ICNE` |
| #8 | 151 | L5537 | `C_ENR.MNT_ICNE` |
