# SIRL-1222 — alinhamento campo a campo do pavé P1

Para pôr `;` entre campos é preciso saber onde cada campo da Notice começa. O
spool não diz: ele junta campos seguidos num `RPAD(' ', soma)` só — há 153
pedaços do SELECT do P1 que cobrem mais de um campo, o maior com 49 campos em
354 caracteres. É o que o ticket avisa: *"modifier simplement le spool et
ajouter un point-virgule entre les colonnes ne suffit pas"*.

Este documento registra como o alinhamento foi feito e o que ele encontrou.
Script: [`mapa_1222.py`](../mapa_1222.py), leitor da Notice:
[`notice.py`](../notice.py).

## O método: âncoras, não soma acumulada

Somar a coluna LONGUEUR da Notice **não funciona sozinho**: a régua dá 5675
caracteres e o spool escreve 5698, e o desvio vai-se acumulando ao longo da
linha. A coluna `POSITION` da Notice, que resolveria isto, está vazia nos 1503
campos.

O que funciona são as **âncoras**: 120 pedaços do spool trazem o comentário
`--P1 x.y`, que diz qual campo está a ser escrito. Entre duas âncoras
consecutivas, compara-se a soma das larguras do spool com a soma dos tamanhos
da Notice. Se der o mesmo número, a zona está alinhada e os campos podem ser
cortados sem dúvida; se não der, a zona fica marcada.

| Variante | Tokens | Âncoras | Zonas alinhadas | Zonas a resolver |
|---|---|---|---|---|
| 1 | 385 | 117 | 110 | 6 |
| 4 | 493 | 115 | 110 | 4 |
| 5 | 414 | 124 | 119 | 4 |
| 6 | 520 | 128 | 119 | 8 |
| 7 | 373 | 101 | 92 | 8 |
| 8 | 482 | 117 | 108 | 8 |

**O problema não são 611 campos, são 6 zonas**, e elas repetem-se entre as
variantes.

| Zona | Delta | Diagnóstico |
|---|---|---|
| `P1 4.x` / `5.x` (TRE201, TRE401) | +17 ou +18 | o spool escreve 22 num token onde a Notice tem dois campos: montante 19 + devise 3 |
| `P1 22.37` → `P1 22.63` | −169 | 18 campos que a Notice põe aqui e o spool escreve noutro ponto da linha |
| zona longa até `P1 31.17` | **−1** | resolvido — ver abaixo |
| `P1 31.17` / `31.18` / `31.22` | +5 | os `LPAD(...,5,'0')` e o `RPAD('+',1)`: o spool escreve 6 onde a Notice diz 5 |

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
