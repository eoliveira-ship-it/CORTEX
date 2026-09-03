# Posicoes do spool ainda por mapear

Geradas por `gen_procedure.py`. Cada linha e uma posicao do spool cuja
coluna de destino ainda nao e conhecida (sem ancora `--P1` no spool).
Ver `docs/ECART-VERSAO.md` para saber porque o mapeamento por posicao
nao pode ser feito automaticamente.

| INSERT | seq | linha spool | expressao (formatacao ja retirada) |
|---|---|---|---|
| #8 | 34 | L5223 | `NVL((C_ENR.MNT_MTM), 0)` |
| #8 | 35 | L5225 | `C_ENR.CD_DEVISE_MTM` |
| #8 | 36 | L5226 | `C_ENR.PCCO_MTM` |
| #8 | 37 | L5227 | `C_ENR.MODELE_ASSIETE_RISQUE` |
| #8 | 38 | L5228 | `C_ENR.IND_ACCORD_COLLATERISATION` |
| #8 | 39 | L5229 | `C_ENR.REF_ACCORD_COLLATERISATION` |
| #8 | 40 | L5230 | `C_ENR.IND_ACCORD_NETTING` |
| #8 | 41 | L5231 | `C_ENR.REF_CONTRAT_NETTING` |
| #8 | 42 | L5232 | `C_ENR.DEV_CONTRAT_NETTING` |
| #8 | 43 | L5233 | `NVL((C_ENR.MT_ASSIETE_INTERNE), 0)` |
| #8 | 44 | L5234 | `C_ENR.DEV_ASSIETE_INTERNE` |
| #8 | 45 | L5235 | `NVL((C_ENR.MT_ASSIETE_REGLEMENTAIRE), 0)` |
| #8 | 46 | L5236 | `C_ENR.DEV_ASSIETE_REGLEMENTAIRE` |
| #8 | 47 | L5299 | `NVL(C_ENR.MATURITE_EFF, 0)` |
| #8 | 48 | L5302 | `C_ENR.TOP_ENG` |
| #8 | 51 | L5306 | `C_ENR.DT_ARRETE` |
| #8 | 52 | L5330 | `C_ENR.IND_CCP` |
| #8 | 53 | L5336 | `C_ENR.CODE_INDICE_BOURSE` |
| #8 | 54 | L5337 | `C_ENR.CODE_PAYS_BOURSE` |
| #8 | 55 | L5341 | `NVL((C_ENR.MT_CVA_COMPTA), 0)` |
| #8 | 56 | L5343 | `C_ENR.DEV_CVA_COMPTA` |
| #8 | 57 | L5344 | `C_ENR.IND_RISQ_COLLAT_SPECIF` |
| #8 | 58 | L5347 | `C_ENR.TYPE_CREDIT_DERIVE` |
| #8 | 59 | L5348 | `C_ENR.IND_DENOUEMENT_CDS` |
| #8 | 60 | L5349 | `C_ENR.IND_ELLIGIBILITE_CVA` |
| #8 | 61 | L5357 | `ABS(TRUNC(NVL(C_ENR.MT_SPREAD, 0)))` |
| #8 | 66 | L5363 | `C_ENR.TYPE_SWAP` |
| #8 | 67 | L5364 | `C_ENR.NATURE_OPTION` |
