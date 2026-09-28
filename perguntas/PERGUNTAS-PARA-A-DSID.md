# Perguntas para a DSID — CORTEX PACT 4.5

Situação em **28/09/2026**. Os três chamados estão feitos e provados no DEV2.
**Nenhuma destas perguntas impede a entrega** — são confirmações, e uma delas
pode dar retrabalho se a resposta for diferente do que implementámos.

Cada pergunta está escrita para ser lida em voz alta numa reunião: o que é,
por que precisamos de resposta, e o que muda conforme a resposta.

---

## Pergunta 1 — O P1 leva 662 ou 663 campos?

**Perguntar assim:**

> A tabela de separadores do chamado SIRL-1222 dá **661 `;`** ao pavé P1.
> Nós geramos **662**. Confirmam que a tabela ficou na versão 45.00 da Notice
> e que o número certo hoje é 662?

**Por que a diferença existe.** A tabela do chamado foi feita a partir da
Notice **V45.00**. Depois disso:

| versão | data | o que mudou |
|---|---|---|
| 45.00 | 23/12/2025 | introduz o `;`; `P1 21.65` passa de 5 para 50 |
| **45.01** | **07/05/2026** | **«Ajout d'une donnée» — entra o campo `P1 621`** |
| 45.02 | 17/07/2026 | afina as regras do `P1 621` e do `P1 622` |

O chamado foi aberto a **10 de julho de 2026**, dois meses depois de o `P1 621`
entrar. A conta fecha nas duas leituras:

```
45.00:  662 campos + 661 ';' + filler 1185 = 8000     <- a tabela do chamado
45.02:  663 campos + 662 ';' + filler 1176 = 8000     <- o que geramos
```

A Notice filtrada que o próprio chamado anexa **tem** o `P1 621` — conferimos
célula a célula: é idêntica à V45.02 que já tínhamos.

**O que muda com a resposta:**

- **«Sim, 662»** — nada a fazer. É o que está gerado e validado.
- **«Não, é 661»** — retrabalho no P1: tudo o que vem depois do `P1 621` recua
  9 octetos, nas 122 225 linhas. Um dia de trabalho, mais uma corrida no DEV2.

---

## Pergunta 2 — O pavé C1 não tem linha na tabela

**Perguntar assim:**

> A tabela de separadores lista P1, P2, F1, F2, M1 e P9. **O C1 não aparece.**
> Geramos **97 `;`** nele, que são os 98 campos da Notice. Confirmam esse
> número, e que a ausência na tabela é esquecimento?

**O que é o C1.** É o pavé da contraparte — o *tiers*. Vem da tabela
`tie_tiers_c1_c5` e leva o nome, o país, a notação, a categoria de contraparte
e o número de empregados. São **40 856 linhas** do `CRRCORP.dat`, cerca de 7%
do ficheiro.

**Por que precisamos de resposta.** Não há número na tabela contra o qual
confirmar. Geramos pela Notice, e a Notice e o ficheiro real concordam — mas é
o único dos sete pavés sem confirmação do lado do chamado.

**A ausência repete-se.** A SFG V0.4 do projeto traz a mesma tabela, com os
mesmos números, e **também sem linha para o C1**. Já não é um lapso de um
documento: é o mesmo lapso em dois.

**O que muda com a resposta:**

- **«97 está certo»** — nada a fazer.
- **«É outro número»** — refazer o C1. É o pavé mais pequeno dos que mexemos,
  meio dia de trabalho.

---

## Pergunta 3 — A versão técnica do fluxo fica em 44 ou passa a 45?

**Perguntar assim:**

> O cabeçalho do ficheiro traz hoje `CRRC;44;` no Corporate e `CRRA;44;` no
> Adapté. A Notice V45 diz «A alimenter à "45"». Passamos para 45 nesta
> entrega, ou fica 44 até outra ordem?

**Onde está.** É o campo *Version du flux* do cabeçalho, escrito pelo shell:

```ksh
echo "00;00000535;001;$masysdateZ;00370;00370;$appemettrice;CRRA;44;..."
```

**Por que não mexemos.** O chamado SIRL-1222 pede separadores, não a mudança
de versão. Mudar o `44` para `45` é uma linha em cada shell, mas é uma
declaração ao destinatário de que o ficheiro segue a V45 por inteiro — e isso
não é nossa decisão.

**O que muda com a resposta:** uma linha em cada um dos dois shells, e uma
corrida de confirmação. Meia hora.

---

## Pergunta 4 — O campo `A1 500` do Adapté

**Perguntar assim:**

> Na Notice do Adapté, o campo `A1 500` (*Plan Produit Liquidité*, 12 octetos)
> está marcado **«Champ en attente de clarification»**. Sai em branco, como
> hoje. Confirmam, ou já há regra?

**Por que não bloqueia.** O campo tem largura fixa de 12 e sai em branco — o
`;` entra à volta dele do mesmo jeito. O ficheiro está correto com ou sem a
resposta; muda só o conteúdo desses 12 octetos.

**O que muda com a resposta:** se houver regra, é uma linha no gerador do
spool do Adapté e uma corrida.

---

## Pergunta 5 — O P3 passou a gerar 6 ficheiros em vez de 5

**Perguntar assim:**

> A corrida do P3 no DEV2 passou a escrever **seis** ficheiros `UC2_P3`, e antes
> escrevia cinco. O que apareceu é o da entidade **00372**, e vem **vazio** —
> só cabeçalho e rodapé, com `99;0000000002`. A entidade não tem uma linha na
> `CREDIT_P3`. O package `PACK_UTL_FILE_ENVOI_C3RD2` que está no nosso
> repositório tem a lista das seis entidades escrita no código
> (`'00399','00936','00357','00472','00370','00372'`) e gera ficheiro para todas,
> mesmo sem dados. A versão que estava compilada no DEV2 não gerava o da 00372.
> Confirmam que o CASA aceita o ficheiro vazio da 00372, ou a 00372 não deve ser
> enviada?

**Por que isto apareceu agora.** Não é o SIRL-1223. O chamado mexeu em **duas
linhas** do package (o `21.65` de 5 para 50 e o filler BALE4 de 1132 para 1087)
— está no commit, e a lista de entidades é byte a byte a mesma. O que mudou foi
que a recompilação do ficheiro do repositório substituiu no DEV2 uma versão mais
antiga, que escolhia as entidades **pelos dados** e não pela lista:

```sql
-- PACK_UTL_FILE_ENVOI_C3RD2.sql, linhas 794-796, comentadas no nosso ficheiro:
--CURSOR C_CONSO
--is select distinct cd_conso_cpt from credit_p3;
```

Com esse cursor, uma entidade sem linhas nunca aparecia — e portanto não saía
ficheiro. Com a lista no código, aparece e sai um ficheiro de 2 linhas. É a
regra que o próprio package escreve na linha 68: *«ENVOYER SOCIETE MEME SI ELLE
EST ABSENTE … ALORS GENERER FICHIER VIDE»*.

**A corrida não falhou.** Verificado: a entidade `00370`, a que vem antes da
00372 na lista, tem nos dois lados o mesmo rodapé `99;0000170421` e o mesmo
tamanho ao octeto. Nenhuma corrida abortou a meio, nenhum ficheiro ficou
truncado, e os cinco pares antes/depois dão `IDENTICOS`.

**O que muda com a resposta:** se a 00372 não deve ir, é tirar `'00372'` da
lista do package. Se deve, não se toca em nada — mas convém dizê-lo ao CASA,
porque é um ficheiro que eles nunca receberam.

---

## Anexo — o que já foi respondido, e não precisa de voltar à mesa

Registado aqui para não se perguntar duas vezes.

| pergunta | resposta | quando |
|---|---|---|
| A linha continua com 8000 octetos depois dos `;`? | **Sim** | 27/09, e-mail DSID |
| E se houver um `;` dentro de um dado? | «Faire une analyse du stock à chaque fois. Solution la plus simple de remplacer les `;` avec un `.`» | 27/09 |
| As larguras dos campos são para respeitar à risca? | «On doit respecter strictement les longueurs indiquées dans la notice, pour chaque champ + nombre de `;`, et la somme doit correspondre à la taille maximale indiquée.» | 27/09 |
| Os campos obsoletos saem do ficheiro ou ficam em branco? | **Ficam**, em branco, na largura da Notice | decidido 27/09 |
| O `N` do netting está um octeto ao lado do que a Notice diz | **Fica como está** — não foi pedido mexer | decidido 27/09 |
| A Notice do Adapté | **Chegou** — estava no repositório desde 27/09 | 27/09 |
