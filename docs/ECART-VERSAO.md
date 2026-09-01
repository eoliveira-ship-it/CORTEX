# Ecart de versão: spool V44.02 vs notice V45.00

## O problema

O `030_spool_Extract_CRRCORP-antigo.sql` deste repo declara no cabeçalho:

```
-- Notice        : CRRCV4.4_Grande Clientèle_Corporate_V44.02.xlsx
```

Mas a notice do repo é a **`Notice PACTV4.5_..._V45.00`**. Ou seja: o código implementa
uma versão da notice, e a especificação disponível é a **seguinte**.

## Como foi medido

Somando a largura de cada campo (a soma dos `RPAD`/`LPAD`/literais do SELECT #1 do spool,
contra a soma dos `LONGUEUR` dos campos P1 da notice, em ordem de ficheiro):

| Fonte | Largura do registo P1 |
|---|---|
| Notice V45.00 | **6154** bytes |
| Spool (V44.02) | **5635** bytes |
| **Diferença** | **519 bytes** |

A diferença é explicada pela própria notice (colunas `VERSION DE CREATION` e
`VERSION DE MODIFICATION`):

- **50 campos criados na V45** → **434 bytes**
  (`P1 600`–`P1 635`, `P1 1001`, `P1 1002`, `P1 22.222`, `P1 24.22.1`…)
- **campos alterados na V45**, sendo o maior o `P1 21.65`: **5 → 50** = **+45 bytes**
  (é exatamente o objeto do SIRL-1223)
- restantes ajustes de tamanho/filler

## A consequência prática

**Não se pode mapear os campos do spool por posição contra a notice V4.5.**

A tentação seria: somar as larguras acumuladas no spool e, para cada offset, ir buscar
o campo que ocupa essa posição na notice. Isso resolveria automaticamente todas as
posições sem comentário `--P1`. **Mas dá resultados errados**, porque as duas réguas
não coincidem — a partir do primeiro campo novo/alterado da V45, tudo desalinha.

Foi testado: o alinhamento acumula desvio e produz atribuições falsas
(ex.: um campo do spool a cair no vizinho seguinte da notice).

Por isso a procedure usa apenas as âncoras `--P1 X.Y` **escritas pelos próprios devs no
spool** (319 posições, fiáveis) e marca as restantes **976** como `COL_A_MAPPER_*`,
em vez de as adivinhar.

## Como resolver

**Opção A — obter a notice V44.02** *(recomendada)*

O ficheiro `CRRCV4.4_Grande Clientèle_Corporate_V44.02.xlsx` é a régua que o spool
realmente segue. Com ela, o alinhamento por posição passa a ser válido e as 976 posições
podem ser mapeadas automaticamente (e depois reconciliadas com a V4.5).

O ticket SIRL-1222 menciona duas notices — `V45.00` e `V45.02` — o que sugere que o
repositório documental da equipa tem as versões anteriores disponíveis.

**Opção B — mapeamento manual com a DSID**

Levar a lista das 976 posições (cada uma com a linha do spool e a expressão) para
mapeamento campo a campo. Mais lento e sujeito a erro humano.

## Ligação com os outros tickets

Este ecart **é** parte do trabalho do projeto, não um acidente:

- **SIRL-1223** trata precisamente de alinhar tamanhos com a nova notice
  (`P1 21.65` 5→50, `P3C 21.65`, filler BALE4 1132→1087).
- **SIRL-1222** muda o formato de saída (separador `;`).

Ou seja: o alvo final é a **V4.5**, mas o SIRL-1224 tem de ser feito **sem regressão**
face ao ficheiro atual (V4.4). Convém decidir explicitamente a ordem:

1. **1224 primeiro, iso-fonctionnel V4.4** — a tabela guarda o que o spool guarda hoje,
   o `CRRCORP.dat` sai idêntico byte a byte, e só depois 1222/1223 evoluem o formato.
   *(É o que os tickets sugerem: "O spool P1 será tratado com prioridade" e o teste de
   não-regressão exige ficheiros idênticos.)*
2. Ou 1224 já na estrutura V4.5 — mas então o teste de não-regressão byte-a-byte deixa
   de poder ser feito diretamente, o que contraria o SFG.

**A tabela `ENG_CORP_P1_BIS` já está criada na estrutura V4.5** (é o que o SFG do 1224
pede: *"la structure du bloc P1 de la notice"*). As colunas novas da V45 ficarão
simplesmente a `NULL` enquanto o spool não as alimentar — o que é compatível com o
cenário 1.
