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
2. pack_alim_tab_envoi_crrv4.sql compila o package
3. TESTES.sql                    executa a procedure e corre os 4 testes
```

`TESTES.sql` é o ficheiro único de testes. Corre, por esta ordem:

| | Teste | Pergunta a que responde |
|---|---|---|
| T1 | Estrutura | a tabela na base é a que o DDL manda? (666 colunas + as 15 alargadas) |
| T2 | Package | o código compilado é o do repositório? |
| T3 | Volumetria | as linhas inseridas são as que os 8 `WHERE` do spool devolvem? (`ecart` = 0) |
| T4 | Round-trip | o valor guardado reproduz o que o spool escreve hoje? (176 colunas × 200 engajamentos) |

T4 é o teste central: para cada coluna corre a expressão do spool sobre
`ENG_CORP_P1` e a mesma expressão sobre `ENG_CORP_P1_BIS`, na mesma linha e na
mesma data. Se as duas strings são iguais, a conversão está certa. Resultado
vazio = conforme.

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
| `tipos` | Tipos reais das colunas de `ENG_CORP_P1`, lidos do dicionario |
| `excel` | Fórmulas Excel: gera o DDL, e marca a origem V44/V45 de cada campo |
| `run_procedure.sql` | Executa so a procedure (a chamada pronta a correr) |
| `TESTES.sql` | Ficheiro unico de testes: estrutura, package, volumetria, round-trip |
| `testes` | Resultado da 1a execucao dos testes |
| `gen_mapa.py` | Gera o mapeamento posicao -> coluna validado contra o ficheiro real |
| `align_v44.py` | Reconstroi a regua V44 e mede o alinhamento posicional |
| `gen_procedure.py` / `conv_spool.py` | Geradores: regeneram a procedure a partir do spool |
| `gen_testes.py` | Gera o `TESTES.sql` a partir do spool, do DDL e da procedure |

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
