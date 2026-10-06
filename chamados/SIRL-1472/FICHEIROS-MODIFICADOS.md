# SIRL-1472 — ficheiros desta pasta

**O chamado:** historizar a `ENG_CORP_P1_BIS` no HCRR, a cada execução mensal,
**sem impacto** na historização do que já existe.

> Detalhe, medições e o que falta: [`documentação/SIRL-1472.md`](../../documentação/SIRL-1472.md)

> ⚠ **Esta pasta é só o lado DDR** — o ponto 1 das cinco modificações do chamado,
> mais o contrato que o ponto 2 vai usar. Os pontos 2, 3 e 4 são dentro do HCRR,
> e não temos o código dessa aplicação.

---

## Os ficheiros

| ficheiro | onde instala | o que é |
|---|---|---|
| `PACK_HIST_ENG_CORP_P1_BIS.sql` | base **DDR** | package novo: escreve a tabela num ficheiro com `UTL_FILE`, 668 campos separados por `;` |
| `030_CREATION_HIST_CRR_P1BIS.sh` | o diretório dos shells, **DDR** | corre a procedure e nomeia o ficheiro com a data do arrêté |
| `HIST_ENG_CORP_P1_BIS.sql` | base **HCRR** | DDL da tabela de histórico: as mesmas 668 colunas + um índice por `DT_ARRETE` |
| `HIST_ENG_CORP_P1_BIS.ctl` | **HCRR** | o `SQL*Loader` que carrega o ficheiro, com os 668 campos na mesma ordem |

### ⚠ Os três ficheiros SQL saem do mesmo gerador

São 668 campos em três ficheiros, e a ordem tem de ser **a mesma** nos três.
Por isso saem todos de [`gen_hcrr.py`](../../gen_hcrr.py), que lê o
`ENG_CORP_P1_BIS.sql` — a única fonte de verdade:

```bash
python gen_hcrr.py        # os tres ficheiros
python valida_hcrr.py     # confere que nao divergiram  -> erros: 0
```

**Porque é que isto importa.** Um campo a mais ou a menos no loader **não dá
erro**: carrega tudo deslocado uma coluna, e a data vai para o campo do montante.
Nenhuma verificação de formato apanha isso. Testei a tirar um campo do `.ctl` — o
`valida_hcrr.py` aponta logo o primeiro fora de ordem.

---

## Porque é um package novo, e não uma procedure dentro de um existente

O critério de aceitação diz **«aucun impact sur l'historisation des données
existantes»**. Num package novo não se toca em nada que já corre: o impacto é
nulo **por construção**, e não por verificação.

## Porque é `UTL_FILE` e não um spool

A linha tem **9 170** octetos no máximo (8 503 de dados + 667 separadores). Uma
expressão SQL não pode passar de **4 000** — é por isso que o
`030_spool_Extract_CRRCORP.sql` parte a linha em duas colunas e enche tudo com
`RPAD`, que é a única forma de o SQL\*Plus não meter espaços pelo meio. Isso dava
um ficheiro de largura fixa: 9 170 × 122 225 = **1,1 GB por arrêté**.

Com `UTL_FILE` em PL/SQL o limite é 32 767 e não há enchimento: cada campo vai
com o tamanho que tem. É o padrão que o `P_UTLF_CREDIT_P3` já usa neste projeto.

## Como os valores vão para o ficheiro, sem perder nada

| tipo | expressão | porquê |
|---|---|---|
| texto | `TRANSLATE(x, ';', '.')` | um `;` nos dados partia o ficheiro — é a mesma resposta que a DSID deu no SIRL-1222 |
| data | `TO_CHAR(x, 'YYYYMMDDHH24MISS')` | a `DATE` do Oracle tem precisão ao segundo; só `YYYYMMDD` perdia a hora |
| número | `TO_CHAR(x, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')` | o `TM9` dá a representação mínima sem arredondar, e o NLS forçado impede que o separador decimal dependa da sessão |

Um campo `NULL` sai **vazio** — dois `;` seguidos. São 367 das 668 colunas, as
que a V45 criou e ainda não têm origem.

## Ordem de instalação

```
No DDR
1. PACK_HIST_ENG_CORP_P1_BIS.sql     compila o package     (F5, nao F9)
2. 030_CREATION_HIST_CRR_P1BIS.sh    o diretorio dos shells

No HCRR
3. HIST_ENG_CORP_P1_BIS.sql          cria a tabela de historico
4. HIST_ENG_CORP_P1_BIS.ctl          o controle do SQL*Loader
```

### ⚠ Quando correr, na cadeia mensal

A `P_ALIM_ENG_CORP_P1_BIS` começa com `DELETE FROM ENG_CORP_P1_BIS`: a tabela
guarda **só o arrêté corrente**. A extração tem de correr **depois** de a tabela
estar cheia e **antes** do enchimento seguinte — senão o arrêté perde-se, e
perde-se **sem erro**.

```
030_CREATION_SPOOL_CRRCORP.sh      enche a tabela, escreve o ficheiro oficial
  ... e chama o _vPACT no fim
030_CREATION_HIST_CRR_P1BIS.sh     <- AQUI
```

---

## O que é proposta, e não medida

Não temos o `030_spool_data.sql` nem o processo de carga do HCRR, por isso estas
três coisas são escolha nossa e não cópia do que lá está:

| o que | onde se muda |
|---|---|
| o formato do cabeçalho (`00;...`) e do rodapé (`99;...`) | `gen_hcrr.py`, num sítio só |
| o nome do ficheiro (`HCRR_P1BIS_<arrete>.dat`) | `V30HISTFIC`, no shell |
| o diretório e o transporte para o HCRR | `V30HISTDIR`, no shell |

Nenhuma delas muda os 668 campos — mudam o invólucro.
