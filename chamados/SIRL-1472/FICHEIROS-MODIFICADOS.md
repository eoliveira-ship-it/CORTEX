# SIRL-1472 — ficheiros desta pasta

**O chamado:** historizar a `ENG_CORP_P1_BIS` no HCRR, a cada execução mensal,
**sem impacto** na historização do que já existe.

> Detalhe, medições e o que falta: [`documentação/SIRL-1472.md`](../../documentação/SIRL-1472.md)

---

## O encadeamento, que é o que manda no desenho

```
DDR                                           HCRR
---                                           ----
P_ALIM_ENG_CORP_P1_BIS  enche a tabela
030_spool_data.sql      escreve o ficheiro
   $SORTIE/030_FLUX_2M_ENG_CORP_P1_BIS.txt  ->  SQL*Loader  ->  CRR.ENG_CORP_P1_BIS
                                                 pack_histo_crr.p_histo_eng_corp_p1_bis
                                                   -> CRR_2A.HIS_ENG_CORP_P1_BIS
                                                   -> CRR_10A.HIS_ENG_CORP_P1_BIS
```

A procedure de historização **não lê o ficheiro**: lê a tabela já carregada, e
faz `INSERT ... SELECT`. É assim nas 180 procedures que o `pack_histo_crr` já
tem, e é assim nesta.

---

## Os ficheiros

| ficheiro | onde instala | o que é |
|---|---|---|
| `030_spool_data.sql` | **DDR** | o de produção **mais** o nosso bloco de extração, antes do `spool off;` final |
| `745_create_pack_histo_crr.sql` | **HCRR** | o de produção **mais** a `p_histo_eng_corp_p1_bis` (1 linha na spec, 1250 no corpo) |
| `030_create_table_ENG_CORP_P1_BIS_HCRR.sql` | **HCRR** | a tabela de receção `CRR.ENG_CORP_P1_BIS`, onde o loader carrega |
| `745_create_table_HIS_ENG_CORP_P1_BIS.sql` | **HCRR** | as duas tabelas de histórico, 2 anos e 10 anos, com índice por `DT_ARRETE` |
| `*_PROD.sql` | — | as bases de produção, para quem instalar poder fazer o diff |

### ⚠ Não há shell novo

O `030_spool_data.sql` **já é chamado pela cadeia mensal**. O nosso bloco entra
nele e passa a correr sozinho, no sítio certo da sequência. Zero ficheiros novos
no diretório dos shells.

### ⚠ Os quatro saem do mesmo gerador

São 301 campos repetidos em quatro ficheiros (o spool, a tabela de receção, as
duas de histórico, e duas vezes dentro da procedure — lista do `INSERT` e do
`SELECT`). A ordem tem de ser **a mesma nos oito sítios**. Por isso saem todos de
[`gen_hcrr.py`](../../gen_hcrr.py), que lê o `ENG_CORP_P1_BIS.sql`:

```bash
python gen_hcrr.py        # os quatro ficheiros
python valida_hcrr.py     # confere que nao divergiram  -> erros: 0
```

**Porque é que isto importa.** Um campo deslocado entre o spool e a tabela de
receção **não dá erro**: o SQL\*Loader carrega tudo uma coluna ao lado, e a data
vai para o campo do montante. Testado: a trocar **duas colunas seguidas** de
ordem no DDL, o `valida_hcrr.py` aponta logo `o primeiro e o 297 (P1_50_3, nao
P1_50_2)`. A tirar um campo, aponta a contagem.

---

## As decisões, e porquê

### Só 301 das 668 colunas

A tabela tem 668 colunas e a linha daria **8 912** octetos. Uma expressão SQL não
passa de **4 000** — é por isso que o maior ficheiro da cadeia tem `linesize
3215` (`BTR_OPERATION`) e nenhum passa dos 4 000.

Das 668, a `P_ALIM_ENG_CORP_P1_BIS` alimenta **301**; as outras 367 ficam sempre
`NULL` e **nenhum spool do CRR as lê** (medido: 0). Extraindo só as alimentadas a
linha dá **3 231** octetos — cabe, e fica ao lado do maior que já existe.

> O dia em que um campo da V45 ganhar origem, há que o acrescentar aqui. É assim
> que a cadeia faz: o histórico do `030_spool_data.sql` é uma lista de *«ajout
> colonne X»*. O separador vai à **frente** do campo novo — `||'~'||COLUNA` —
> para não mexer na linha anterior.

### O formato é o da cadeia, não o nosso

Medido no `030_spool_data.sql`, não escolhido:

| | |
|---|---|
| separador | `~` — 2 173 vezes no ficheiro; `;` zero |
| datas | `YYYYMMDD` — zero `HH24` em todo o ficheiro |
| comprimento | variável, com `SET linesize` no máximo exato |
| cabeçalho/rodapé | não existem |
| nome | `030_FLUX_2M_<TABELA>.txt` em `$SORTIE` |

### Porque é que não há proteção do separador

Nenhum dos 2 173 campos da cadeia tem `TRANSLATE` nem `REPLACE`. A convenção
assume que o `~` não aparece nos dados. Não a contrariámos num chamado de
historização.

### Impacto nulo no que já existe

O critério de aceitação diz **«aucun impact sur l'historisation des données
existantes»**. O `valida_hcrr.py` prova isso por construção, no ponto 5: o diff
contra os dois ficheiros de produção é **só acrescentos** — nenhuma linha
removida nem alterada, e os 130 acentos do package intactos (uma escrita em
cp1252 convertê-los-ia sem dizer nada, e o gerador por isso escreve na
codificação da origem).

---

## Ordem de instalação

```
No DDR
1. 030_spool_data.sql                        substitui o de producao

No HCRR
2. 030_create_table_ENG_CORP_P1_BIS_HCRR.sql cria a tabela de recepcao
3. 745_create_table_HIS_ENG_CORP_P1_BIS.sql  cria as duas de historico
4. 745_create_pack_histo_crr.sql             substitui o package (F5, nao F9)
```

---

## O que é proposta, e não medida

| o que | porquê | onde se muda |
|---|---|---|
| o **tablespace** das três tabelas | o único modelo que temos (`030_create_table_BTR_OPE_PARTENAIRE_POOL.sql`) é do **DDR**: diz `DDR_DATA`. Não sabemos o do HCRR | vai **comentado** nos dois DDL, com um `-- A CONFIRMAR` |
| os **GRANT** | os roles do modelo são `ROLE_DDR_*`. Um GRANT a um role inexistente dá `ORA-01919` e para o script **com a tabela já criada** | idem, comentados |
| o passo de **SQL\*Loader** | não está no repositório para nenhuma das 180 tabelas — é gerado ou genérico do lado HCRR | a confirmar com a DSID |
| **quem chama** a `p_histo_eng_corp_p1_bis` | o `pack_histo_crr` não tem despachante interno: as 180 procedures são chamadas de fora | a confirmar com a DSID |

Nenhuma delas muda os 301 campos — mudam o invólucro.
