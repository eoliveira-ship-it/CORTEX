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

## VALIDACAO EMPIRICA (ficheiro real)

O `CRRCORP_P1.7z` (966 MB descomprimido, 120 789 registos, arrete 20250630)
e o ficheiro **realmente gerado** pelo spool. Serve de oraculo: se as posicoes
calculadas pela regua extrairem os valores certos, a regua esta correta.

Ferramenta: [`../valida_posicoes.py`](../valida_posicoes.py)

### Cabecalho — bate exatamente

| Offset | Extraido | Campo |
|---|---|---|
| 0:8 | `20250630` | data de arrete |
| 8:13 | `00370` | entidade porteuse |
| 13:25 | `C_BTR       ` | aplicacao origem |
| 25 | `M` | frequencia |
| 26:38 | `202608241214` | MASYSDATE (confirma `yyyymmddHHMI`) |
| 38:40 | `P1` | tipo de registo |

### Corpo — as fronteiras caem no sitio certo

| Campo | Offset (larg.) | Valor extraido do ficheiro |
|---|---|---|
| `MNT_CONTRAT_ORIGINE` | 2446 (19) | `+000000000000040419` |
| `DEV_MNT_CONTRAT_ORIGINE` | 2465 (3) | `EUR` |
| `MNT_ACQUISITION` | 2702 (19) | `+000000000021146523` |
| `DATE_DEB_ENG_RENVL` | 2813 (8) | `20170131` |
| `CD_METH_IFRS9_PD_ORIG` | 969 (20) | `LC_MIG_D+` |
| `OBJ_FINANCIE` | 2444 (2) | `04`, `97` |

Montantes com sinal e 18 digitos, datas validas, moedas ISO: nenhuma fronteira
corta um valor ao meio. A regua esta validada contra dados reais.

### Largura do registo

Linhas de 8000 octetos (o `linesize` do spool, com enchimento). Dados ate a
coluna **5606**; a regua calcula **5675** — os ultimos 69 octetos sao fillers
em branco, o que e coerente.

## Impacto

Com a regua validada, as **922 posicoes** deixam de precisar da notice V44.02:
podem ser mapeadas pela posicao e **verificadas** contra o ficheiro real,
campo a campo. As 4 zonas com desvio (offsets ~4204, ~4913, ~5024, ~5131)
podem agora ser resolvidas empiricamente, olhando onde os valores mudam.

## Mapeamento gerado

Ferramenta: [`../gen_mapa.py`](../gen_mapa.py) -> [`mapa-posicoes.csv`](mapa-posicoes.csv)

Percorre as 3439 posicoes dos 8 SELECT, atribui o campo da notice pela regua
V44 e **verifica no ficheiro real** se os valores respeitam o FORMAT declarado.

| Confianca | Posicoes | Criterio |
|---|---|---|
| ALTA | 210 | ancora `--P1` do spool E a posicao concordam |
| MEDIA | 858 | sem ancora, um so campo na posicao, valores reais coerentes |
| BAIXA | 251 | ancora e posicao discordam, ou varios campos, ou incoerente |
| FILLER | 2120 | `RPAD(' ', n)` -> coluna fica a NULL |

**1068 posicoes mapeaveis, 251 colunas distintas** (contra as 107 atuais).

Dos 251 BAIXA, so **12** tem valores realmente incoerentes com o formato; os
restantes sao casos de ancora ambigua ou posicao a cobrir varios campos.

O CSV traz por linha: offset, largura, coluna proposta, ref e nome da notice,
ancora do spool, confianca, resultado do oraculo, exemplos reais e a expressao
do spool — pronto para revisao da DSID.
