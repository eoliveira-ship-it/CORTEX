# SIRL-1222 — alinhamento campo a campo do pavé P1

Para pôr `;` entre campos é preciso saber onde cada campo da Notice começa. O
spool não diz: ele junta campos seguidos num `RPAD(' ', soma)` só — há 153
pedaços do SELECT do P1 que cobrem mais de um campo, o maior com 49 campos em
354 caracteres. É o que o ticket avisa: *"modifier simplement le spool et
ajouter un point-virgule entre les colonnes ne suffit pas"*.

Este documento registra como o alinhamento foi feito e o que ele encontrou.
Script: [`mapa_1222.py`](../mapa_1222.py), leitor da Notice:
[`notice.py`](../notice.py).

## O método: âncoras e desvio acumulado

Somar a coluna LONGUEUR da Notice **não funciona sozinho**: a régua dá 5675
caracteres e o spool escreve 5698, e o desvio vai-se acumulando. A coluna
`POSITION` da Notice, que resolveria isto, está vazia nos 1503 campos.

O que funciona são as **âncoras**: 120 pedaços do spool trazem o comentário
`--P1 x.y`, que diz qual campo está a ser escrito. Para cada âncora calcula-se

```
desvio = posição no spool − posição na régua da Notice
```

e olha-se para onde o desvio **muda**. Desvio constante quer dizer que o spool e
a Notice concordam, mesmo que o spool escreva 49 campos num `RPAD` só. Cada
degrau é uma divergência real.

**Duas tentativas que não servem, e porquê:**

1. *Somar as larguras entre duas âncoras.* Foi a primeira versão e dava 6 zonas
   divergentes no P1. Eram falsas: o token da âncora pode ser um filler grande
   que cobre o campo da âncora **e** os seguintes — o `--P1 3.56` está num
   `RPAD(' ',185)` que vale 20 campos. O método por desvio não tem esse problema.
2. *Confiar em todas as âncoras.* O comentário pode estar colado no pedaço
   errado. O `P1 4.2` tem 19 caracteres e começa na posição 459; o spool
   escreve-o como `RPAD(' ',1) || RPAD(' ',16) || RPAD(' ',2)` e o comentário
   está no último pedaço, 17 caracteres depois do início do campo. Isso produz um
   degrau de +17 que desaparece na âncora seguinte. O script marca esses casos
   como **bolha** e não os conta.

## O resultado: um único desvio em toda a linha

| Variante | Âncoras | Degraus reais | Bolhas |
|---|---|---|---|
| 1 | 117 | **1** | 2 |
| 4 | 115 | **1** | 0 |
| 5 | 124 | **1** | 2 |
| 6 | 128 | **1** | 0 |
| 7 | 101 | **1** | 2 |
| 8 | 117 | **1** | 2 |

Nas seis variantes, o degrau é o mesmo: **−1 a partir do bloco 30.x**. Tirando
esse byte, **o layout do P1 é o da Notice**. É isso que permite gerar o formato
com `;` a partir da Notice, em vez de o desenhar à mão campo a campo.

## A zona do −1: o bloco 30.x (derivados / netting) — RESOLVIDO

O −1 era o mais importante, porque contamina 110 campos de uma só vez.

A Notice define, no fim do bloco 30:

| Campo | Tam | Nome |
|---|---|---|
| `P1 30.22` | 25 | Référence du contrat cadre |
| `P1 30.23` | **1** | **Indicateur accord de netting contractuel** |
| `P1 30.24` | 25 | Référence du contrat de netting contractuel |
| `P1 30.25` | **1** | **Indicateur accord de netting comptable** |
| `P1 30.26` | 25 | Référence du contrat de netting comptable |

Isto é: referência, indicador, referência, indicador, referência.

O spool escreve, na mesma faixa:

```
RPAD(' ',190) || RPAD(' ',6) || 'N' || RPAD(' ',18) || RPAD(' ',7) || 'N' || RPAD(' ',25) || RPAD(' ',1)
```

Isto é: indicador, referência, indicador, referência. Os dois `N` estão
confirmados no ficheiro real, nos bytes **3982** (em 122180 das 122225 linhas)
e **4009**.

**O total do bloco bate: 249 caracteres nos dois.** O que não bate é a posição
dos `N`: o spool põe cada `N` no **último byte do campo de referência
anterior**, um byte antes do campo indicador que a Notice define. Como todo o
resto do bloco é branco, isto é invisível hoje — um `N` deslocado um byte dentro
de um mar de brancos não se vê. É esse byte que desalinha os 110 campos
seguintes.

Com `;` a ambiguidade desaparece por construção: cada campo é escrito separado e
o `N` vai para o `30.23` e o `30.25`. Não há decisão de significado a tomar: os
nomes dos campos são explícitos.

## Consequência para a validação

**O ficheiro novo não vai ser "o ficheiro velho mais os `;`".** Nesta zona vai
ter 1 branco a mais, porque a Notice pede 197 caracteres onde o spool escreve
196. As outras zonas ainda em aberto podem trazer correções do mesmo tipo.

Portanto a validação do SIRL-1222 não pode ser *"tirar os `;` e ver se fica
igual ao ficheiro de referência"*. Tem de ser:

> tirar os `;` e ver se fica igual ao ficheiro de referência, **a menos das
> correções conhecidas**, cada uma listada, justificada e contada.

Cada correção é um byte de diferença que a DSID tem de aceitar, porque é uma
mudança de conteúdo do ficheiro — pequena, sempre em zona de brancos, mas
mudança. A lista dessas correções faz parte da entrega do chamado.

## Premissas em vigor (2026-09-23/24)

- **Usar a Notice V45.02** e escrever os 104 campos criados na V45 (P1 51,
  P2 42, M1 12), em branco. Estão todos no fim da linha, antes do filler.
- **`;` em todo o ficheiro:** cabeçalho, fillers do meio e filler final. O
  filler final é o último campo, precedido de `;` e sem `;` depois dele, como já
  se faz no ficheiro do P3 (C3RD).
- **Linha com 8000 caracteres** e filler do P1 em **1176** (a Notice diz 1185,
  que dá 8009; ver [QUESTAO-FILLER-P1.md](QUESTAO-FILLER-P1.md)).
- Em aberto: os campos obsoletos (`P1 22.2`, `P2 22.2`, `M1 512`) e a Notice do
  Adapté.
