# Perguntas em aberto para a DSID

Ficheiro único com o que está à espera de resposta, para levar a uma reunião ou
a um e-mail. Cada ponto diz **o que é**, **por que é preciso decidir** e **o que
acontece com cada resposta**.

Atualizado em 2026-09-27.

**Estado:** respondidas a 1, a 3c e a 4; decididas a 2 e a 5 (fica como está). Em aberto: a **3** (os 661 vs 662 do P1, já datada), a **3b** (o C1 sem linha na tabela) e a **6** (a régua do Adapté, que bloqueia o `CRRADAPT`).

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

### 2. ~~Os campos obsoletos saem ou ficam em branco?~~ — DECIDIDO (27/09)

**Ficam, em branco, com a largura da Notice** — que é como já estão. Nada foi
pedido a este respeito, e o âmbito do chamado é outro: passar os `select` do spool
a `insert` na tabela nova (SIRL-1224) e gerar o spool a partir dela com `;`
(SIRL-1222). Tirar campos nunca esteve no pedido.

São o `P1 22.2` e o `P2 22.2` (*Indicateur niveau de risque*, última aparição
44.09) e o `M1 512` (*Segment de Clientèle au sens de la liquidité*, criado e
retirado na 45).

Fica a nota de uma incoerência, para quando alguém lhes tocar: o `P2 22.2` sai com
o valor da coluna `IND_NIV_RISQUE` e o `P1 22.2` sai em branco, sendo o mesmo
campo.

### 3. A tabela do ticket diz 661 `;` no P1, nós geramos 662 — DATADA (27/09)

A tabela do ticket dá o número de `;` por registo. Bate em tudo menos no P1:

| | ticket | geramos | |
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
(ALPHA/8). E a folha *Suivi des versions* da Notice diz quando ele entrou:

| versão | data | |
|---|---|---|
| 45.00 | 2025-12-23 | introduz os `;` entre campos |
| **45.01** | **2026-05-07** | **"Ajout d'une donnée"** — o `P1 621` |
| 45.02 | 2026-07-17 | "Modification de définitions, règles de gestion et contrôles pour les données **`P1 621` et `P1 622`**" |

As duas contas fecham em 8000, cada uma na sua versão:

```
45.00 :  662 campos + 661 ';' + filler 1185 = 8000   <- a tabela do ticket
45.02 :  663 campos + 662 ';' + filler 1176 = 8000   <- o que geramos
```

O ticket foi criado a **10 de Julho de 2026**, dois meses depois de o campo entrar,
e uma semana antes de a 45.02 lhe afinar as regras de gestão. **Tudo indica que a
tabela ficou na 45.00 e nunca foi refeita** -- o mesmo descuido que deixou o filler
do P1 em 1185 quando a linha passou a dar 8009.

**Pergunta:** confirmam que a tabela do ticket ficou na 45.00, e que o P1 leva
**663 campos, 662 `;` e filler 1176**, como está implementado?

Se a resposta for não -- se o `P1 621` fica mesmo de fora -- é retrabalho no P1:
tudo o que vem depois dele recua 9 octetos, nos 122 225 registos.

### 3b. O C1 não tem linha na tabela do ticket

A tabela lista P1, P2, F1, F2, M1 e P9. **O C1 não aparece.**

O C1 é o pavé da contraparte — o *tiers* — e vem da `tie_tiers_c1_c5`: nome, país,
notação, categoria de contraparte, número de empregados (foi o `C1 4.35`, *Nombre
de salariés*, que deu o problema do `00000`). São **40 856 linhas** do
`CRRCORP.dat`, e geramos **97 `;`** (98 campos pela Notice).

Como não há linha na tabela, não há contra o que confirmar. Confirmar o número, e
que a ausência é esquecimento.

### 3c. ~~Pedido: a Notice filtrada que o ticket anexa~~ — CHEGOU (27/09)

O `Notice PACTV4.5_Grande Clientele_Corporate_V45.02_SIRL_1222.xlsx` é **idêntico,
célula a célula**, ao V45.02 que já tínhamos: 1512 linhas, zero diferenças. Só
traz um filtro gravado. Não responde à 3 nem à 3b -- mas confirma que a Notice
que o ticket anexa **tem** o `P1 621`, o que é o lado dela da questão.

### 4. Cabeçalho (`00;`) e rodapé (`99;`)

O ticket diz "modifications à identifier/valider" para o en-tête e o en-queue,
sem dizer o quê. Hoje as duas linhas **já** têm `;`. Confirmar que ficam como
estão.

### 5. O `N` do netting está um octeto ao lado — FICA ASSIM (27/09)

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

**Não mexemos nisto, e fica assim** (decidido em 27/09). O ficheiro que entregamos
escreve o `N` onde ele está hoje, variante por variante — o chamado pede o
separador, e o separador não obriga a mudar conteúdo. Se estiver errado, é a DSID
que o dirá; a régua está toda mapeada e a correcção são três linhas no gerador.

| Resposta | Consequência |
|---|---|
| Fica como está | o ficheiro é o de 22/09 mais os `;`; a variante 8 continua diferente das outras cinco |
| O `N` passa ao `P1 30.23` | muda o conteúdo de **122 180 registos**; o indicador passa a estar declarado e o contrato-quadro deixa de dizer `N` |

A nossa leitura é que o `N` sempre foi para o indicador e está um octeto ao lado
há muito. Mas é alteração de conteúdo, e por isso confirma-se antes.

**Contexto, da folha de versões da Notice:** a 45.02 (17/07/2026) traz *"Retrait de
l'usage CALCULS PRUDENTIELS des données P1 30.x"*. Os campos do netting são o
`P1 30.22` a `30.26`, e hoje têm `usage = MREL`. A DSID mexeu nesta zona exacta na
última versão, o que torna a pergunta mais oportuna.

Nota, por não ser assunto deste chamado: o `N` é um literal fixo, tanto no spool
como na procedure de alimentação (`'N' AS P1_30_23`). Ou seja, o CORTEX declara
"sem acordo de netting" em todos os registos, por decisão de código. Se há
contratos de netting a declarar, a informação não está a chegar.

### 5b. O registo `Z9` do Adapté

Achado ao medir os dados reais: o `CRRADAPT.dat` tem, entre as linhas de detalhe,
um registo `Z9` que conta os registos.

```
20250531 00370 C_BTR        M 202609221901 Z9          000000001774
```

O layout bate **exactamente** com o pavé `Z9` da Notice do Corporate: cabeçalho
comum 8+5+12+1+12+2, filler de 10, contagem em 12 = 62 octetos. O `CRRCORP.dat`
não o produz; o `CRRADAPT.dat` produz.

Não é pendência — a régua dele já existe, na Notice que temos. Fica registado para
quando o Adapté avançar: o `Z9` também leva `;`, e a tabela do ticket não lhe dá
linha, como não dá ao C1.

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

**E quanto falta, ao certo** — medido com os dados reais do `CRRADAP.7z`, que
estavam no repo: 1777 linhas de 2000 octetos, 1774 do tipo `A1`.

| | |
|---|---|
| campos que o ticket diz | **91** |
| campos com valor no spool, de largura conhecida | 59 |
| filler final | 1 |
| **escondidos dentro de 13 fillers brancos** | **31** |

Um terço dos campos não é identificável. Um `RPAD(' ', 130)` tanto pode ser um
campo de 130 como treze de 10, e os dados reais não distinguem — são brancos nos
dois casos (22 corridas de brancos em todas as 1774 linhas).

Sabe-se ainda: os dados vão até ao octeto **823**, o resto é filler; e os primeiros
6 campos são os mesmos do Corporate (arrêté 8, entidade 5, aplicação 12, frequência
1, data/hora 12, tipo 2), verificado contra os dados.

Testou-se a hipótese de as referências `A1 x.y` corresponderem às do Corporate:
**não correspondem**. O `A1 4.6` é uma taxa de 10, o `P1 4.6` um montante de 19, o
`C1 4.6` uma categoria de 5. Esquema próprio, notice própria.

**Não precisa de ser a notice formal:** basta uma lista dos 91 campos com as
larguras.

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
