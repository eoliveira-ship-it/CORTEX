# Perguntas em aberto para a DSID

Ficheiro único com o que está à espera de resposta, para levar a uma reunião ou
a um e-mail. Cada ponto diz **o que é**, **por que é preciso decidir** e **o que
acontece com cada resposta**.

Atualizado em 2026-09-27.

---

## SIRL-1222 — separador `;`

### 1. ~~A lista de campos é a da Notice ou a de hoje?~~ — RESPONDIDA (27/09)

**A da Notice, com as larguras estritas de cada campo.** Ver `respostas.txt`:
*"respecter strictement les longueurs indiquées dans la notice, pour chaque champ
+ nombre de «;» et la somme doit correspondre à la taille maximale indiquée."*

<details><summary>a pergunta como estava</summary>


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

**Confirmado no ticket** (Yacine AIT MADI, 21/07): *"oui pour les filler situés
à l'intérieur des lignes, il faudrait ajouter un séparateur."*

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

</details>

### 3. O `P1 621` entra no ficheiro? — REFORMULADA (27/09)

Era *"o filler do P1 não fecha em 8000"*. O PDF do ticket mudou-lhe a natureza: há
**duas leituras coerentes**, e ele aponta para a que eu não escolhi.

A tabela do ticket dá o número de `;` por registo. Bate em tudo menos no P1:

| | ticket | o que geramos | |
|---|---|---|---|
| cabeçalho | 14 | 14 | ✓ |
| rodapé | 2 | 2 | ✓ |
| P2 | 397 | 397 | ✓ |
| M1 | 157 | 157 | ✓ |
| F1 | 72 | 72 | ✓ |
| F2 | 45 | 45 | ✓ |
| P9 | 38 | 38 | ✓ |
| **P1** | **661** | **662** | **✗** |

A diferença é um campo: o **`P1 621` — *Intention de gestion de l'opération***
(ALPHA/8), criado na versão 45.01.

```
com ele : 663 campos + 662 ';' + filler 1185 = 8009
sem ele : 662 campos + 661 ';' + filler 1185 = 8000   <- fecha exacto
```

| | campos | `;` | filler | total |
|---|---|---|---|---|
| **A** — o que está implementado | 663 | 662 | **1176** | 8000 |
| **B** — o que o ticket descreve | 662 | **661** | **1185** | 8000 |

O ticket aponta para **B** em três sítios independentes: a tabela diz 661; o texto
diz *"le filler doit impérativement avoir la longueur définie dans la notice"*
(1185, não 1176); e *"la longueur totale d'une ligne d'en-tête, d'enregistrement
de détail et d'en-queue doit être la même"* (8000).

Mas a Notice V45.02 **define** o `P1 621`, e é a Notice que o ticket anexa. Uma
das duas coisas está desactualizada, e não se adivinha qual.

**Pergunta:** o `P1 621` entra no `CRRCORP.dat`?

- **Se não entra** (B): o P1 passa a 662 campos e 661 `;`, o filler fica nos 1185
  da Notice, e tudo o que vem depois do `P1 621` recua 9 octetos. Mexe nos
  122 225 registos P1.
- **Se entra** (A): fica como está, e é a tabela do ticket que precisa de ser
  corrigida para 661 -> 662.

Está implementado **A**, e não se muda sem resposta.

### 3b. O C1 não tem linha na tabela do ticket

A tabela lista P1, P2, F1, F2, M1 e P9. **O C1 não aparece**, e são 40 856 linhas
do ficheiro. Geramos 97 `;` (98 campos). Confirmar o número, e que a ausência é
esquecimento e não outra coisa.

### 3c. Pedido: a Notice filtrada que o ticket anexa

O ticket refere `Notice PACTV4.5_Grande Clientele_Corporate_V45.02_SIRL_1222.xlsx`
-- a Notice filtrada para este chamado, com os exemplos dos fillers. Não a temos.
É capaz de responder sozinha à 3 e à 3b.

### 4. Cabeçalho (`00;`) e rodapé (`99;`)

O ticket diz "modifications à identifier/valider" para o en-tête e o en-queue,
sem dizer o quê. Hoje as duas linhas **já** têm `;`. Confirmar que ficam como
estão.

### 5. O `N` do indicador de netting está um octeto ao lado

Levantado em 27/09, ao gerar o ficheiro com separador.

O `P1 30.23` — *Indicateur accord de netting* (ALPHA/1) — leva `N` em todos os
registos. Mas em **cinco das seis variantes** esse `N` está escrito no último
octeto do campo anterior, o `P1 30.22` *Référence du contrat cadre* (25), e o
`P1 30.23` sai em branco. A variante 8 escreve-o no sítio.

```sql
-- variantes 1, 4, 5, 6, 7        -- variante 8
RPAD(' ', 6)||                    RPAD(' ', 25)||
'N'||        <- 3981              'N'||         <- 3982
RPAD(' ', 18)                     RPAD(' ', 17)
```

Sem separador ninguém vê: é um `N` num campo de texto, num mar de brancos. Com
`;` passa a ler-se, sem ambiguidade, que a referência do contrato-quadro é `N` e
que não há indicador de netting.

**Não mexemos nisto.** O ficheiro que entregamos escreve o `N` onde ele está hoje,
variante por variante — o chamado pede o separador, e o separador não obriga a
mudar conteúdo.

| Resposta | Consequência |
|---|---|
| Fica como está | o ficheiro é o de 22/09 mais os `;`; a variante 8 continua diferente das outras cinco |
| O `N` passa ao `P1 30.23` | muda o conteúdo de **122 180 registos**; o indicador passa a estar declarado e o contrato-quadro deixa de dizer `N` |

A nossa leitura é que o `N` sempre foi para o indicador e está um octeto ao lado
há muito. Mas é alteração de conteúdo, e por isso confirma-se antes.

Nota, por não ser assunto deste chamado: o `N` é um literal fixo, tanto no spool
como na procedure de alimentação (`'N' AS P1_30_23`). Ou seja, o CORTEX declara
"sem acordo de netting" em todos os registos, por decisão de código. Se há
contratos de netting a declarar, a informação não está a chegar.

### 6. Notice do Adapté — **o que bloqueia o resto do chamado**

O chamado inclui o `CRRADAPT.dat`, e o `030_spool_Extract_CRRADAP.sql` declara no
cabeçalho a notice `CRRAV4.4_Adapté_Adapted_V44.02.xlsx`. **Não a temos**, e não
há nenhuma indicação de que esteja a caminho nem de que exista uma versão V45.

Sem ela não dá para separar por campo:

- os dois Excel que temos têm só a aba `PACT Corp`;
- o spool não serve de régua — traz referências de campo em meia dúzia de linhas
  (`A1 4.6`, `A1 7.3`) e fillers como `RPAD(' ', 130)`, que tanto podem tapar um
  campo como quarenta. Sem saber quantos, não se sabe quantos `;` lá vão dentro.

**Pedido:** a notice do Adapté, na versão que o ficheiro deve passar a seguir. Se
não existir V45, dizer qual usar.

**O que o PDF do ticket já deu (27/09):**

| PACT Adapté | tamanho | `;` |
|---|---|---|
| cabeçalho | 2000 | 14 |
| **detalhe** | **2000** | **90** |
| rodapé | 2000 | 2 |

São **91 campos** numa linha de 2000, e bate com o spool: os três blocos fecham em
835 octetos de dados mais `LPAD(' ', 1164)`, e havia 1 token por bloco sem largura
medida -- o octeto que falta para os 2000.

Isto não resolve o problema (continuam a faltar as fronteiras: ~70 tokens para 91
campos, ou seja uns 20 campos escondidos nos fillers brancos) mas dá-lhe um alvo:
qualquer reconstrução passa a ser verificável contra o 90.

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
