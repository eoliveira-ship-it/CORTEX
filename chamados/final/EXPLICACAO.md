# O que foi feito — os três chamados

Resumo para explicar. O detalhe de cada um está em
[`documentação/`](../../documentação/); a instalação, em
[`INSTALACAO.md`](INSTALACAO.md).

---

## Em uma linha cada

| chamado | o que faz |
|---|---|
| **SIRL-1224** | tira as regras de negócio de dentro do spool: passam para uma procedure, que enche uma tabela nova. O spool só lê a tabela e formata |
| **SIRL-1223** | alarga um campo de 5 para 50 octetos |
| **SIRL-1222** | põe `;` entre todos os campos, nos dois fluxos (Corporate e Adapté) |

Os três mexem no mesmo ficheiro do Corporate, por isso entregam-se empilhados.

---

## SIRL-1224 — as regras saem do spool

O pavé P1 era calculado dentro do spool, em 8 `SELECT` com toda a lógica de
negócio misturada com a formatação. Agora:

```
P_ALIM_ENG_CORP_P1_BIS   calcula  ->  enche a ENG_CORP_P1_BIS
030_spool_..._vPACT.sql  lê       ->  formata e escreve o ficheiro
```

* tabela nova **`ENG_CORP_P1_BIS`**, com **668** colunas — 663 campos da Notice
  V45 do P1 e 5 técnicas;
* procedure nova **`P_ALIM_ENG_CORP_P1_BIS`** dentro do
  `pack_alim_tab_envoi_crrv4`: uma chamada, sem parâmetros, 8 `INSERT`;
* no spool, os **8 `SELECT`** do P1 passam a **6** (as três variantes do NAT02
  juntam-se numa só).

**Prova:** o ficheiro sai igual ao de antes, nas **554 045** linhas, octeto a
octeto. É mais forte do que comparar valor a valor, porque compara o produto
final.

---

## SIRL-1223 — um campo de 5 para 50

| onde | o que muda |
|---|---|
| Corporate, `P1 21.65` (octeto 5217) | `RPAD(' ',5)` → `RPAD(' ',50)` |
| P3, `P3C 21.65` | o mesmo |
| P3, filler `BALE4` | `RPAD(' ',1132)` → `RPAD(' ',1087)` |

A linha **não muda de tamanho**: os 45 octetos que entram saem do filler do fim.

---

## SIRL-1222 — `;` entre todos os campos

Separadores por tipo de registo, todos nas posições que a Notice prevê:

```
Corporate   P1 662   P2 397   M1 157   C1  97
            F1  72   F2  45   P9  38   cabeçalho 14   rodapé 2
Adapté      cabeçalho 14   A1 90   Z9 8   rodapé 2
```

A linha continua com **8000** octetos no Corporate e **2000** no Adapté: o
filler final encolhe para dar lugar aos `;`.

Nos campos de texto entra `TRANSLATE(x, ';', '.')`, para um `;` nos dados não
partir o ficheiro (resposta da DSID de 27/09).

---

## A prova — corrida de 28/09, 17:15 no DEV2

Os dois lados saem da **mesma corrida**: mesmo arrêté e mesmo número de envio
(`00000533`). Só o horodatage difere, porque o shell de produção corre primeiro
e chama o novo no fim.

| fluxo | resultado |
|---|---|
| Corporate | **P1 idêntico** nas 122 225 linhas; os outros seis pavés sem uma linha por emparelhar |
| Adapté | **0 erros**; as 1 774 linhas de detalhe idênticas |
| P3 | **idênticos** nos cinco pares, 171 930 linhas de detalhe |

---

## Decisões

**1. Corre ao lado, não substitui.** O shell de sempre continua a escrever o
ficheiro oficial e, no fim, chama o `_vPACT`, que escreve o seu. Os dois saem da
mesma corrida — e se o novo rebentar, o oficial já está escrito.

**2. Nada é editado à mão.** Cada ficheiro entregue sai de um gerador que parte
da versão **de produção** e para se a âncora que procura não estiver lá. Foi por
não ser assim que o 1223 esteve aplicado a uma cópia atrasada do package do P3 e
ia desfazer o SIRL-667 sem ninguém ver.

**3. `DELETE`, não `TRUNCATE`.** O `TRUNCATE` é DDL e faz commit implícito: os
dados perdiam-se mesmo se um `INSERT` seguinte falhasse. Com `DELETE` a procedure
pode correr duas vezes sem duplicar nada.

**4. A coluna `NO_VARIANTE`.** Guarda qual dos 8 `SELECT` produziu a linha. A
ordem das linhas do ficheiro **é** a ordem em que esses 8 corriam; ao passar para
uma tabela essa informação desaparecia, e sem ela não havia como provar que o
ficheiro não mudou. O `order by NO_VARIANTE` reconstitui-a.

**5. Latitude e longitude ficam `VARCHAR2`.** A Notice diz `NUM`, mas a base
guarda texto. Tipá-las como `NUMBER` dava `ORA-01722` e, pior, perdia a
representação exata.

**6. O passo do RSE_LOT3 não se repete.** Quem o corre é o shell de produção,
que é quem chama o `_vPACT`. Repeti-lo custava oito varrimentos da
`ENG_CORP_P1` com `UNION` para reescrever a tabela com o mesmo conteúdo. Fica um
comentário a dizer que tem de voltar no dia em que o `_vPACT` substituir o de
produção — senão a `PERIM_ENVOI_CRR_P1` deixa de ser enchida **sem dar erro**.

**7. Só o que o chamado pede.** Nenhum campo retirado, nenhum conteúdo
corrigido. O `N` do indicador de netting fica onde o spool o punha, mesmo
parecendo estar no campo errado — é a pergunta 5 à DSID.

**8. Sem PRIMARY KEY** na tabela nova. A chave, para juntar, é
`ID_ENGAGEMENT + CD_PERIMETRE + NO_VARIANTE`: a `ID_ENGAGEMENT` sozinha pode dar
mais do que uma linha.

---

## Em aberto

* as **cinco perguntas à DSID**, em
  [`perguntas/PERGUNTAS-PARA-A-DSID.md`](../../perguntas/PERGUNTAS-PARA-A-DSID.md);
* dois defeitos **herdados** no bloco que já correu no DEV2, e que ficam como
  estão porque o que se entrega tem de ser o que foi testado: o `ERR` não é
  função destes shells, e o `trace_log` leva 2 argumentos onde espera 3. A
  correção é uma linha em cada, se a DSID a quiser.
