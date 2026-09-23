# Notice V45.02 contra V45.00

Ficheiros: `Notice PACTV4.5_v1.0.xlsx` (V45.00) e
`Notice PACTV4.5_Grande Clientèle_Corporate_V45.02.xlsx`. O SIRL-1222 cita as
duas; a régua do formato novo sai da **V45.02**.

Atenção ao ler: **as colunas mudaram de letra**. A V45.02 tem uma coluna a
menos antes das DEFINITION, por isso LONGUEUR é V (era W), VERSION DE CREATION
é X (era Y), etc. Localizar sempre pelo cabeçalho da linha 2, não pela letra.

## Diferenças

| Mudança | Detalhe |
|---|---|
| Campo novo | `P1 621` — Intention de gestion de l'opération, ALPHA/8, criado na 45.01 |
| Campos obsoletos | `P1 22.2` e `P2 22.2` (última aparição 44.09), `M1 512` (última aparição 45) |
| LONGUEUR dos fillers | vinha vazia na V45.00, vem preenchida na V45.02 |
| 143 campos | VERSION DE MODIFICATION 45.00 -> 45.01 (quase todos F1 e F2) |
| 18 campos | mudou a lista de USAGE(S) DECLARE(S) |
| 3 campos | mudou o nome (`P1 622`, `P1 625`, `P2 625`) |

**Nenhum campo existente mudou de LONGUEUR**: a régua construída para o
SIRL-1224 continua válida.

## Tamanho da linha, por pavé (V45.02)

| Pavé | Campos | Soma dos campos | Filler `99.99` | Total |
|---|---|---|---|---|
| P1 | 643 | 5882 | 1185 | 7067 |
| P2 | 378 | 3305 | 4018 | 7323 |
| M1 | 138 | 1526 | 6037 | 7563 |
| C1 | 82 | 708 | 6915 | 7623 |
| F1 | 53 | 550 | 7098 | 7648 |
| F2 | 26 | 263 | 7412 | 7675 |
| P9 | 19 | 207 | 7475 | 7682 |

O filler é a última coluna da linha: é nele que o SIRL-1222 diz para **não**
pôr `;` no fim.

## Perguntas para a DSID

1. Os campos obsoletos (`P1 22.2`, `P2 22.2`, `M1 512`) saem do ficheiro ou
   ficam em branco? Hoje o spool escreve o `P1 22.2`.
2. Com o `;`, o cliente passa a ler por número de campo. Os 50 campos criados
   na V45 e o `P1 621` (45.01) não são escritos hoje: ou entram em branco, ou
   a DSID confirma por escrito que lê no formato V44.
