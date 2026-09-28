# CORTEX PACT 4.5 — resumo dos três chamados

> Situação em **28/09/2026**. Este documento lê-se em cinco minutos e não exige
> conhecer o código. O detalhe de cada chamado está nos documentos ao lado.

---

## O estado, numa tabela

| chamado | o que é | estado |
|---|---|---|
| **[SIRL-1224](SIRL-1224.md)** | separar regras de negócio da formatação, numa tabela nova | 🟢 **feito e provado** |
| **[SIRL-1223](SIRL-1223.md)** | alargar um campo de 5 para 50 octetos | 🟢 **feito e provado** |
| **[SIRL-1222](SIRL-1222.md)** | pôr `;` entre todos os campos | 🟢 **feito e provado** |

Os três estão corridos no DEV2 sobre o arrêté 20250531 e comparados com o
ficheiro de antes. **Nenhuma linha de dados difere do que se esperava.**

---

## Os três em duas frases cada

### SIRL-1224 — a tabela `ENG_CORP_P1_BIS`

O spool que gera o `CRRCORP.dat` fazia duas coisas ao mesmo tempo: aplicava
regras de negócio e formatava. Agora as regras estão numa **procedure** que
enche uma **tabela nova**, e o spool só lê essa tabela e formata.

**Porquê:** uma regra de negócio escondida dentro de um `RPAD` não se testa, não
se reutiliza e não se vê.

### SIRL-1223 — os tamanhos da V45.00

Um campo passou de 5 para 50 octetos, em dois fluxos: o `P1 21.65` no Corporate
e o `P3C 21.65` no P3. No P3, o filler do fim encolhe os mesmos 45 para a linha
não crescer.

**Porquê é delicado:** alargar um campo empurra tudo o que vem depois. Se os 45
brancos entrarem um campo ao lado, o ficheiro continua com o tamanho certo e
está errado de metade em diante.

### SIRL-1222 — o separador `;`

O Corporate e o Adapté eram os dois últimos fluxos em formato posicional puro.
Passam a ter `;` entre todos os campos.

**Porquê é mais do que procurar e substituir:** num ficheiro posicional, um campo
em branco não se distingue do filler ao lado. Um `RPAD(' ', 130)` tanto pode ser
um campo de 130 como treze de 10. A régua tem de vir da Notice.

---

## Como os três se empilham

Não são independentes. Cada um assenta no anterior:

```
1224   ENG_CORP_P1 ─► procedure ─► ENG_CORP_P1_BIS ─► spool vPACT ─► CRRCORP.dat
                                                          │
1223                                        o P1 21.65 passa a 50
                                                          │
1222                                        entram os 662 ';'
                                                          ▼
                                                    CRRCORP.dat final
```

**O que isto quer dizer na prática:** o spool que vai para o servidor é **um só**
e leva os três chamados dentro. Não há como instalar o 1222 sem o 1224.

Um detalhe que poupou trabalho: o SIRL-1224 leu a estrutura da tabela da Notice
**V45** e não do spool V44. Por isso a coluna `P1_21_65` já nasceu com 50, e o
SIRL-1223 não teve de alterar a tabela.

---

## Os números da prova

### Corporate — `CRRCORP.dat`

| | |
|---|---|
| linhas | **554 045** (8000 octetos cada) |
| tipos de registo | P1, P2, M1, C1, F1, F2, P9 |
| separadores | P1 662, P2 397, M1 157, C1 97, F1 72, F2 45, P9 38 |
| última corrida | `00000533`, 28/09 17:15 — **com os três chamados juntos** |
| resultado | **P1 idêntico nas 122 225 linhas**; os outros seis pavés sem uma linha por emparelhar |

### Adapté — `CRRADAP.dat`

| | |
|---|---|
| linhas | **1 777** (2000 octetos cada) |
| separadores | cabeçalho 14, detalhe 90, `Z9` 8, rodapé 2 |
| última corrida | 28/09 17:25 |
| resultado | **erros: 0** — as 1 774 linhas de detalhe idênticas, e o `Z9` com 8 `;` |

### P3 — `C3RD`

| entidade | linhas | resultado |
|---|---|---|
| 00370 | 170 419 | idêntico |
| 00357, 00472, 00936, 00399 | 1 511 | idênticos |
| **total** | **171 930** | cinco ficheiros, não seis: o 00372 saiu no SIRL-667 |

---

## Como se provou, e porque é que isso importa

A prova **não é** «o ficheiro saiu e tem o tamanho certo». Isso não prova nada:
um campo no sítio errado dá um ficheiro do tamanho certo.

A prova é sempre a mesma ideia, nos três chamados: **desfazer a mudança e ver se
volta ao original**.

| chamado | como |
|---|---|
| 1224 | comparar os dois ficheiros, neutralizando o horodatage, o nº de envio e a ordem das linhas |
| 1223 | aplicar ao ficheiro **de antes** o alargamento que o chamado pede, e comparar |
| 1222 | partir as linhas novas pelos `;`, colá-las sem separador, e comparar |

E os testes foram **testados contra o erro**: no 1223, pôr os 45 brancos um campo
ao lado dá 122 138 diferenças. Um teste que não falha quando devia não prova nada.

---

## O que falta

**Nada bloqueia a entrega.** Ficam cinco confirmações com a DSID, em
[`perguntas/PERGUNTAS-PARA-A-DSID.md`](../perguntas/PERGUNTAS-PARA-A-DSID.md):

| | pergunta | risco se a resposta for outra |
|---|---|---|
| 1 | o P1 leva 662 ou 663 campos? | **retrabalho de um dia** no P1 |
| 2 | o C1 não tem linha na tabela do chamado | meio dia |
| 3 | a versão do fluxo fica em `44` ou passa a `45`? | meia hora |
| 4 | o campo `A1 500` do Adapté | uma linha |
| 5 | a cópia do package do P3 estava atrasada — e talvez os dois spools também | **meio dia**, se os spools também estiverem |

E, fora dos três chamados:

- o **SFD/STD** do projeto — não iniciado, espera a validação dos dados pelo
  cliente;
- o fluxo novo **FPCR** (*Flux Pivot Crédit*), que a SFG anuncia: 2050 octetos,
  148 separadores no detalhe, seis ficheiros. É a exigência E03, outro trabalho.

---

## Onde está cada coisa

| pasta | o que tem |
|---|---|
| [`chamados/final/`](../chamados/final/) | **a versão final de tudo, com o guia de instalação** |
| [`chamados/SIRL-1222/`](../chamados/SIRL-1222/) etc. | os ficheiros de cada chamado, e o que mudou em cada um |
| [`documentação/`](.) | este documento e um por chamado |
| [`perguntas/`](../perguntas/) | as perguntas para a DSID |
| [`ficheiros-testados/`](../ficheiros-testados/) | os ficheiros gerados no DEV2 que serviram de prova |
| [`docs/`](../docs/) | o histórico completo, com todas as investigações |
