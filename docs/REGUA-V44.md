# Reconstrucao da regua V44 e mapeamento posicional

## O problema

O spool implementa a notice **V44.02**; a notice do repo e **V45.00**.
Das posicoes com valor nos 8 SELECT, so 367 tem ancora `--P1 X.Y`.
As outras **922** so podem ser identificadas pela **posicao em octetos** —
mas contra a regua errada isso da resultados falsos (ver `ECART-VERSAO.md`).

## A ideia

Duas colunas da notice permitem reconstruir a regua V44:

| Coluna | Uso |
|---|---|
| `LONGUEUR` (W) | soma acumulada = posicao de cada campo |
| `VERSION DE CREATION` (Y) | campos criados em **45** nao existiam em V44 |
| `USAGE` (AB) | campos `NA` sao os que o spool escreve em branco e **agrupa** num so `RPAD` |

**Regua V44** = notice V45 menos os campos criados em V45, com `P1 21.65`
revertido de 50 para 5 (valor dado pelo SIRL-1223).

## Resultado

| Medida | Antes | Depois |
|---|---|---|
| Largura total: spool vs notice | 5635 vs 6154 (**-519**) | 5678 vs 5675 (**+3**) |
| Ancoras `--P1` no campo certo | 1 / 120 | **92 / 120 (77%)** |

Ferramenta: [`../align_v44.py`](../align_v44.py)

Descobertas pelo caminho:

- `SUBSTR(F_FORMAT_TAUX(...), n)` — o `SUBSTR` e que manda na largura, nao a
  funcao interna. Ignorar isto desalinhava tudo a partir do offset 1419.
- `F_FORMAT_MONTANT_BIS3` devolve **19** caracteres (deduzido do alinhamento;
  a funcao vive no `pack_utilitaire`, fora deste repo).

## O que falta para chegar a 100%

Os 28 desvios restantes sao de **um campo**, concentrados em 4 zonas
(offsets ~4204, ~4913, ~5024, ~5131). Causa provavel: campos cujo
**comprimento mudou em V45** e que nao sabemos reverter — a notice marca
~150 campos como modificados em 45.00, mas so da o comprimento **novo**.
Do `P1 21.65` sabemos o antigo porque o SIRL-1223 o diz; dos outros nao.

## As duas saidas

**A — obter a notice V44.02** (recomendado)
Torna a regua exata, o alinhamento passa a 100% e as 922 posicoes ficam
mapeadas automaticamente, com as 367 ancoras a servirem de prova.

**B — usar o alinhamento atual como proposta**
Gerar o mapeamento com os 77% validados, marcando cada linha com o nivel de
confianca, para revisao da DSID. Nao e prova, mas transforma o trabalho de
"descobrir 176 mapeamentos" em "confirmar uma proposta".
