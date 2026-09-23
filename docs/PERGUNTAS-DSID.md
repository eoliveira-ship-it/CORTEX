# Perguntas em aberto para a DSID

Ficheiro único com o que está à espera de resposta, para levar a uma reunião ou
a um e-mail. Cada ponto diz **o que é**, **por que é preciso decidir** e **o que
acontece com cada resposta**.

Atualizado em 2026-09-23.

---

## SIRL-1222 — separador `;`

### 1. A lista de campos é a da Notice ou a de hoje?

Hoje o `CRRCORP.dat` segue a régua da notice **V44.02**. A notice atual é a
**V45.02**, e há **51 campos que o ficheiro não escreve**: os 50 criados na V45
(434 caracteres) e o `P1 621`, criado na 45.01.

Sem separador isto é um desvio de posições, que já existe hoje. **Com o `;` o
cliente passa a ler por número de campo**, e um campo a menos desloca todos os
seguintes.

| Resposta | Consequência |
|---|---|
| Escrever os 643 campos da Notice | os 51 campos novos saem em branco; o ficheiro fica conforme a V45.02 |
| Manter como hoje | a DSID confirma **por escrito** que lê no formato V44; fica registado que o ficheiro não é o da Notice |

**Decidido em 2026-09-23 (KLx): usar a Notice.** Os 104 campos criados na V45
(P1 51, P2 42, M1 12) passam a ser escritos, em branco. Estão todos no fim da
linha, antes do filler, por isso nada se desloca. Sem o `;` nem sequer mudam um
byte do ficheiro; só existem de facto quando o separador entrar.

**Decidido também: o `;` vale para o ficheiro todo** — cabeçalho, fillers do
meio da linha e filler final. O filler final é o último campo, precedido de `;`
e sem `;` depois dele, como já se faz hoje no ficheiro do P3 (C3RD).

### 2. Os campos obsoletos saem ou ficam em branco?

A V45.02 marca três campos com última aparição:

| Campo | Última aparição | Tamanho |
|---|---|---|
| `P1 22.2` | 44.09 | 1 |
| `P2 22.2` | 44.09 | 1 |
| `M1 512` | 45 | 3 |

Os três estão na régua da notice. Se saem do ficheiro, as linhas P1, P2 e M1
perdem um campo cada; se ficam em branco, o tamanho não muda.

| Resposta | Consequência |
|---|---|
| Sair do ficheiro | menos um campo em cada linha P1 e P2; desloca os seguintes |
| Ficar em branco | a linha não muda de tamanho |

### 3. O filler do P1 não fecha em 8000

Pergunta redigida em pt-BR e em francês, pronta a enviar:
**[QUESTAO-FILLER-P1.md](QUESTAO-FILLER-P1.md)**.

Resumo: os tamanhos de filler da V45.02 já contam os separadores e dão 8000
exatos em todos os registos, menos no P1, que dá 8009. A diferença é o
`P1 621` (8 caracteres + 1 separador), criado na 45.01. O filler do P1 deve
passar de 1185 para 1176 — a confirmar.

### 4. Cabeçalho (`00;`) e rodapé (`99;`)

O ticket diz "modifications à identifier/valider" para o en-tête e o en-queue,
sem dizer o quê. Hoje as duas linhas **já** têm `;`. Confirmar que ficam como
estão.

### 5. Notice do Adapté

O `030_spool_Extract_CRRADAP.sql` implementa a notice
`CRRAV4.4_Adapté_Adapted_V44.02.xlsx`, que **não temos**. Sem ela não dá para
separar por campo o `CRRADAPT.dat`. Pedir o ficheiro.

---

## SIRL-1224 — tabela + procedure

### 5. Aceite dos 6 SELECT em vez de 1

O plano falava em consolidar os 8 SELECT num só. Foram 6: um para o NAT02 (as
variantes 1 a 3 partilham o layout, provado por dados) e cinco para o Hors
NAT02, porque cada variante escreve campos diferentes nas mesmas posições.

### 6. `P1 3.41` / `P1 3.43` — TRE502 sem devise

O spool antigo faz `RPAD(C_ENR.CD_DEV_VTR,3)` sem `NVL`. Um TRE502 sem devise
**encurta a linha em 3 bytes** e desalinha o resto. O spool novo escreve 3
brancos. Na fotografia de 20250531 não há nenhum caso (senão os ficheiros
teriam diferido). Confirmar que o comportamento novo é o desejado.
Consulta pronta: `CONSULTAS_CLIENTE.sql`, C1.3.

### 7. Tipos de risco sem dados em 20250531

Alguns tipos (ex.: `INR101`) não têm linhas nesta data, por isso só foram
validados pelo gerador, não por dados. Pedir uma data de arrêté que os tenha,
ou aceitar a validação como está. Consulta pronta: `CONSULTAS_CLIENTE.sql`, C2.

### 8. Estimativa para os outros spools

O ticket pede uma estimativa de esforço para os restantes spools. Este trabalho
mexe só no P1. Avisar que a estimativa não faz parte desta entrega.

---

## Depois da validação do cliente

O histórico no HCRR (`030_spool_data.sql` e `030_spool_9M.sql`) e o documento
SFD/STD único do projeto só começam depois de o cliente validar os dados.
