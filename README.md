# CORTEX — CRR Corporate / PACT V4.5

Trabalho sobre a cadeia de declaração de riscos **CRR Corporate** (Oracle PL/SQL + spool),
cobrindo três tickets SIRL. O objetivo central (SIRL-1224) é **tirar as regras de negócio
de dentro do spool** e passá-las para uma tabela alimentada por uma procedure.

## Estado atual

| Ticket | Assunto | Estado |
|---|---|---|
| **SIRL-1224** | Tabela `ENG_CORP_P1_BIS` + procedure de alimentação | 🟡 em curso |
| **SIRL-1222** | Separador `;` em `CRRCORP.dat` / `CRRADAPT.dat` | ⬜ não iniciado |
| **SIRL-1223** | Tamanhos: `P1 21.65` 5→50, `P3C 21.65`, filler BALE4 1132→1087 | ⬜ não iniciado |
| — | SFD/STD único do projeto | ⬜ não iniciado |

Detalhe do SIRL-1224: [docs/SIRL-1224.md](docs/SIRL-1224.md)
Mapeamento posicional: [docs/REGUA-V44.md](docs/REGUA-V44.md)

## ⚠️ Achado importante — ecart de versão

O `spool.sql` implementa a notice **V44.02**; a notice deste repo é **V45.00**.
Diferença medida: **519 bytes**. Isto invalida o mapeamento automático por posição
e condiciona o SIRL-1224. Ver [docs/ECART-VERSAO.md](docs/ECART-VERSAO.md).

## Ordem de execução no Oracle

```
1. ENG_CORP_P1_BIS.sql           cria a tabela (666 colunas)
2. verifica_tabela.sql           confirma que ficou certa
3. pack_alim_tab_envoi_crrv4.sql compila o package
4. run_procedure.sql             executa a alimentação
5. test_P_ALIM_ENG_CORP_P1_BIS.sql   volumetria e controlo esperado/inserido
6. teste_roundtrip.sql           nao-regressao por campo, contra o proprio spool
```

No SQL Developer usar **F5** (Run Script), não F9.

## Ficheiros

### Entregáveis (produzidos)

| Ficheiro | Conteúdo |
|---|---|
| `ENG_CORP_P1_BIS.sql` | DDL da tabela: 662 colunas P1 + 4 técnicas |
| `pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql` | Procedure isolada: `DELETE` por perímetro + 8 `INSERT` |
| `pack_alim_tab_envoi_crrv4.sql` | Package completo (spec + body) com a procedure integrada |
| `erro` | Log de compilação/execução Oracle — erros já corrigidos |
| `pack_utilitaire` | Package com as funcoes de formato (`F_FORMAT_*`) |
| `tipos` | Tipos reais das colunas de `ENG_CORP_P1` (saída do `diag_tipos.sql`) |
| `excel` | Fórmulas Excel: gera o DDL, e marca a origem V44/V45 de cada campo |
| `run_procedure.sql` | Executa a procedure (a chamada pronta a correr) |
| `verifica_tabela.sql` | Confirma que a tabela criada bate com o DDL |
| `diag_tipos.sql` | Tipos reais das colunas de origem (dicionario) |
| `diag_precisao.sql` | Diagnostico ORA-01438: colunas NUMBER pequenas demais |
| `diag_perguntas.sql` | Escala das taxas, mapeamentos suspeitos, arrete da origem |
| `diag_divergencias.sql` | Valor da tabela vs valor do ficheiro, lado a lado |
| `testes` | Resultado da 1a execucao dos testes |
| `teste_roundtrip.sql` | Nao-regressao por campo: tabela reformatada vs spool, mesma data |
| `teste_conteudo.sql` | Compara a tabela com o ficheiro CRRCORP_P1 real, campo a campo |
| `test_P_ALIM_ENG_CORP_P1_BIS.sql` | Script de teste da procedure (volumetria + controlo esperado/inserido) |
| `gen_mapa.py` | Gera o mapeamento posicao -> coluna validado contra o ficheiro real |
| `align_v44.py` | Reconstroi a regua V44 e mede o alinhamento posicional |
| `gen_procedure.py` / `conv_spool.py` | Geradores (regeneram a procedure e o teste a partir do spool) |

### Fonte (entrada)

| Ficheiro | Conteúdo |
|---|---|
| `spool.sql` | Cópia do `030_spool_Extract_CRRCORP.sql` (5.662 linhas, notice V44.02) |
| `Notice PACTV4.5_v1.0.xlsx` | Notice PACT V4.5 Corporate — aba `PACT Corp` é a fonte da estrutura |
| `ticket 1224`, `plan 1224`, `1222`, `1223`, `plano` | Tickets e SFG técnicas |
| `1224.png` | Diagrama do fluxo SIRL-1224 |

## Regenerar a procedure

Depois de qualquer alteração ao `spool.sql`:

```bash
python gen_procedure.py
```

Requer `openpyxl` (`pip install openpyxl`). O script relê os 8 SELECT do spool,
converte as expressões e reescreve o ficheiro da procedure.
