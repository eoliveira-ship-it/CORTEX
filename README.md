# CORTEX — CRR Corporate / PACT V4.5

Trabalho sobre a cadeia de declaração de riscos **CRR Corporate** (Oracle PL/SQL + spool),
cobrindo três tickets SIRL. O objetivo central (SIRL-1224) é **tirar as regras de negócio
de dentro do spool** e passá-las para uma tabela alimentada por uma procedure.

## Estado atual

| Ticket | Assunto | Estado |
|---|---|---|
| **SIRL-1224** | Tabela `ENG_CORP_P1_BIS` + procedure + spool vPACT | 🟢 não-regressão provada em NAT02 |
| **SIRL-1222** | Separador `;` em `CRRCORP.dat` / `CRRADAPT.dat` | ⬜ não iniciado |
| **SIRL-1223** | Tamanhos: `P1 21.65` 5→50, `P3C 21.65`, filler BALE4 1132→1087 | ⬜ não iniciado |
| — | SFD/STD único do projeto | ⬜ não iniciado |

### Resultado da última execução do `TESTES.sql` (2026-09-01)

| Teste | Resultado |
|---|---|
| T1 Estrutura | 667 colunas, as 15 alargadas conformes — **OK** |
| T2 Package | spec e body `VALID`, 3 parâmetros, `ALL_ERRORS` vazio — **OK** |
| T3 Volumetria | `NAT02` 122138 esperado / 122138 inserido, **écart 0** |
| T4 Round-trip | **196 colunas × 200 engajamentos, todas conformes** |

O T4 compara, campo a campo, a expressão original do spool com a expressão que
o **spool vPACT** emite. Todas iguais: o ficheiro sai igual.

O T3 lê agora os 8 `WHERE` do próprio `030_spool_Extract_CRRCORP-antigo.sql`. O total ficou nos mesmos
122138 depois de acrescentar ao INSERT #1 a condição `NOT LIKE 'TRE2%'` que lhe
faltava — nesta fotografia não há registos TRE2% em NAT02, por isso o defeito
era latente. Continua a ser um defeito: noutro arrêté a procedure carregaria
linhas que o ficheiro não leva.

Falta para fechar o ticket: correr os dois spools e comparar os `CRRCORP.dat`;
mapear os 28 campos da variante 8 (derivados, 45 registos em 120789); e repor
o `TABLESPACE HCRR` no DDL antes da entrega.

Detalhe do SIRL-1224: [docs/SIRL-1224.md](docs/SIRL-1224.md)
Mapeamento posicional: [docs/REGUA-V44.md](docs/REGUA-V44.md)

## ⚠️ Achado importante — ecart de versão

O `030_spool_Extract_CRRCORP-antigo.sql` implementa a notice **V44.02**; a notice deste repo é **V45.00**.
Diferença medida: **519 bytes**. Isto invalida o mapeamento automático por posição
e condiciona o SIRL-1224. Ver [docs/ECART-VERSAO.md](docs/ECART-VERSAO.md).

## Os quatro ficheiros do teste

Os nomes trazem `-antigo` e `-novo` para não haver enganos. O par tem de ser
usado sempre inteiro: cada shell só chama o seu spool e escreve o seu `.dat`.

| | Shell | Spool | Lê de | Ficheiro |
|---|---|---|---|---|
| **antigo** | `030_CREATION_SPOOL_CRRCORP-antigo.sh` | `030_spool_Extract_CRRCORP-antigo.sql` | `ENG_CORP_P1` (8 SELECT) | `CRRCORP-antigo.dat` |
| **novo** | `030_CREATION_SPOOL_CRRCORP-novo.sh` | `030_spool_Extract_CRRCORP-novo.sql` | `ENG_CORP_P1_BIS` (2 SELECT) | `CRRCORP-novo.dat` |

Para saber qual é qual sem abrir o ficheiro:

```
grep -c ENG_CORP_P1_BIS 030_spool_Extract_CRRCORP-novo.sql     # 4
grep -c ENG_CORP_P1_BIS 030_spool_Extract_CRRCORP-antigo.sql   # 0
```

> **Corrigido no shell antigo**: tinha uma segunda atribuição de `spool_sql`,
> sem comentário, a apontar para o spool vPACT. Sobrepunha-se à primeira e
> fazia o shell *antigo* correr o spool *novo*.

Na entrega os nomes voltam aos oficiais: `030_spool_Extract_CRRCORP.sql`,
`030_CREATION_SPOOL_CRRCORP.sh` e `CRRCORP.dat`.

## Ordem de execução no Oracle

```
1. ENG_CORP_P1_BIS.sql           cria a tabela (667 colunas)
2. pack_alim_tab_envoi_crrv4.sql compila o package
3. TESTES.sql                    executa a procedure e corre os 4 testes
```

`TESTES.sql` é o ficheiro único de testes. Corre, por esta ordem:

| | Teste | Pergunta a que responde |
|---|---|---|
| T1 | Estrutura | a tabela na base é a que o DDL manda? (666 colunas + as 15 alargadas) |
| T2 | Package | o código compilado é o do repositório? |
| T3 | Volumetria | as linhas inseridas são as que os 8 `WHERE` do spool devolvem? (`ecart` = 0) |
| T4 | Round-trip | o valor guardado reproduz o que o spool escreve hoje? (196 colunas × 200 engajamentos) |

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
| `030_spool_Extract_CRRCORP-novo.sql` | O spool sem regras de negocio: 2 SELECT sobre a tabela |
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | Shell do spool vPACT (identico ao original, muda so os nomes) |
| `comparar_ficheiros.sh` | Compara os dois CRRCORP.dat neutralizando o horodatage e a linha ENTETE |
| `comparar_spools.sql` | Corre os dois spools com os mesmos binds, para o diff de nao-regressao |
| `gen_spool_vpact.py` | Gera o spool vPACT e a lista de campos que o teste usa |
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
| `030_spool_Extract_CRRCORP-antigo.sql` | Cópia do `030_spool_Extract_CRRCORP.sql` (5.662 linhas, notice V44.02) |
| `Notice PACTV4.5_v1.0.xlsx` | Notice PACT V4.5 Corporate — aba `PACT Corp` é a fonte da estrutura |
| `ticket 1224`, `plan 1224`, `1222`, `1223`, `plano` | Tickets e SFG técnicas |
| `1224.png` | Diagrama do fluxo SIRL-1224 |

## Regenerar a procedure

Depois de qualquer alteração ao `030_spool_Extract_CRRCORP-antigo.sql`:

```bash
python gen_procedure.py
```

Requer `openpyxl` (`pip install openpyxl`). O script relê os 8 SELECT do spool,
converte as expressões e reescreve o ficheiro da procedure.
