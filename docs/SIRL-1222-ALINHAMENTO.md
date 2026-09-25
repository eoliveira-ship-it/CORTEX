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

## A zona do −1: era o espaço do COLSEP — CORRIGIDO (25/09)

**Esta secção foi reescrita.** A primeira versão dizia que o spool estava 1 byte
desalinhado da Notice a partir do `P1 30.23` **até ao fim da linha**, e que isso
contaminava 110 campos. Está errado. A medição no ficheiro real mostrou outra
coisa, e mais simples.

O que faltava na conta era o **espaço do COLSEP**. O spool antigo escreve a linha
em duas colunas que o SQL*Plus põe lado a lado com um espaço entre elas:
4000 + 1 + 3999 = 8000. Esse espaço é um dos 8000 bytes do registo — cai dentro
do campo `P1 30.24` (bytes 3984–4008), que é todo branco, por isso não se vê.

Quem soma as larguras dos campos do spool está num espaço sem esse byte, e é daí
que vinha o «−1»: a partir do byte 4001 as duas contagens afastam-se uma casa.
Não é desalinhamento — é o COLSEP.

**Com o COLSEP na conta, o layout do P1 é o da Notice, byte a byte, do início ao
fim.** Sobra uma única anomalia real:

| Campo | Tam | Notice | ficheiro de 22/09 |
|---|---|---|---|
| `P1 30.22` Référence du contrat cadre | 25 | 3958–3982 | 24 brancos + **`N`** no 3982 |
| `P1 30.23` Indicateur accord de netting | 1 | 3983 | branco |
| `P1 30.24` Référence du contrat de netting | 25 | 3984–4008 | brancos (o COLSEP é um deles) |
| `P1 30.25` Indicateur accord de netting comptable | 1 | 4009 | **`N`** no 4009 — certo |
| `P1 30.26` | 25 | 4010–4034 | brancos |

Isto é: o **primeiro** indicador de netting é escrito no último byte do campo
anterior, um byte antes do sítio. O segundo está no sítio certo. E isto só
acontece em **cinco das seis variantes**: a variante 8 já escreve o `N` no 3983,
onde a Notice o põe.

Como é invisível (um `N` deslocado um byte num mar de brancos), passou. Com `;`
a ambiguidade desaparece por construção, e os três campos vão escritos à mão no
gerador — `P1 30.22` e `P1 30.24` em branco, `P1 30.23` com o `'N'` — para as
seis variantes ficarem iguais.

## Consequência para a validação

**O ficheiro novo não vai ser "o ficheiro velho mais os `;`".** Há uma correção
de conteúdo: o `N` do primeiro indicador de netting passa do byte 3982 para o
3983.

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

## O spool gerado (24/09)

[`gen_spool_1222.py`](../gen_spool_1222.py) gera o
`030_spool_Extract_CRRCORP_1222.sql`: os 6 blocos do P1 com `;` entre todos os
campos. Para cada um dos 663 campos da Notice, a expressão sai de uma regra:

| Regra | O que é | Variante 1 |
|---|---|---|
| EXATO | um token do spool tem as fronteiras do campo: copia-se a expressão vPACT | 201 |
| BRANCO | o campo cai dentro de um filler: `RPAD(' ', tamanho)` | 402 |
| NOVO | campo criado na V45: lê-se a coluna da tabela, que está a NULL | 51 |
| REGRA | os 6 casos escritos à mão | 6 |
| EMENDA | vários tokens cobrem o campo exatamente: concatenam-se | 2 |
| FILLER | o filler final, o que falta para os 8000 | 1 |

Nas outras variantes muda só a distribuição (mais BRANCO, menos EXATO). **Zero
campos sem regra nas seis.**

Os 6 casos à mão, cada um com a sua razão, estão no dicionário `REGRAS` do
gerador: os quatro dos compostos TRE201/TRE401 (o spool escreve montante e
devise juntos num `CASE` de 22; a tabela guarda-os em duas colunas), o
`P1 21.65` (a régua de hoje tem 5, o vPACT já escreve 50) e o `P1 30.22` (o `N`
do netting passa para o `30.23`).

### Duas colunas, e o espaço do COLSEP

Uma expressão SQL não passa de 4000 caracteres, por isso a linha é montada em
colunas que o SQL*Plus escreve lado a lado. **Duas, não três** — a primeira
tentativa, com três, saiu errada no DEV2 (ver abaixo).

O desenho é o dos outros pavés: **4000 + 1 + 3999 = 8000**, onde o 1 é o espaço
que o SQL*Plus mete entre as colunas (o COLSEP). Nenhuma fronteira de campo cai
no 4000, por isso o corte é **dentro do filler `P1 25.99`** (100 caracteres,
bytes 3962–4061, em branco nas seis variantes): 39 no fim da coluna 1, o espaço
do COLSEP, 60 no início da coluna 2. O espaço do COLSEP é um branco desse
filler, não um caractere a mais.

As duas colunas levam `CAST(... AS VARCHAR2(4000))` e `VARCHAR2(3999)`. Sem
isso o SQL*Plus dá a cada coluna a largura do **tipo declarado**, que é 4000
porque uma função como a `f_format_montant` devolve `VARCHAR2` sem tamanho.

O `;` vai **escrito nas expressões** (`||';'||`), como no ficheiro do P3. Assim
não depende de nenhum parâmetro do SQL*Plus nem cai no meio de um campo, e não
há `;` no fim da linha.

### Verificação sem base de dados

[`valida_1222.py`](../valida_1222.py) lê o spool gerado e, campo a campo, mede a
largura da expressão (`RPAD(x,n)` → n, `'ABC'` → 3, as `F_FORMAT_*` pelo que o
`pack_utilitaire` escreve, as colunas pelo tamanho no DDL) e compara com o
tamanho que a Notice dá ao campo. Confirma também que só o último campo da linha
não leva `;` e soma as larguras por coluna.

```
PAVE P1 - perimetre NAT02 (variantes 1-3)   campos 663  colunas [2669, 2671, 2660]  total 8000
PAVE P1 - Hors NAT02, variante 4            campos 663  colunas [2669, 2671, 2660]  total 8000
...
erros: 0
```

### Mudança no DDL

A tabela ganhou a coluna **`P1_621 VARCHAR2(8)`**, que faltava: o campo foi
criado na V45.01, depois da Notice que gerou o DDL.

### O que isto quebra nas ferramentas

As posições fixas deixam de valer para o P1: o código do pavé já não está nos
bytes 39-40. O `.bat` que divide o ficheiro por pavé e o `comparar_ficheiros.sh`
(que faz o censo por `cut -c39-40`) têm de passar a separar por campo.

## Primeira corrida no DEV2 (24/09, 23:39) — ORA-01847

O spool parou no primeiro bloco do P1, com

```
ERROR at line 635:
ORA-01847: day of month must be between 1 and last day of month
       RPAD(NVL(P1_611,' '), 8)||';'||   -- P1 611       NOVO
                       *
```

Causa: os campos criados na V45 eram todos escritos como `RPAD(NVL(coluna,' '),
n)`, mas 19 dessas colunas não são `VARCHAR2` — são `DATE` (4) ou `NUMBER` (15).
Num `NVL(DATE, ' ')` o Oracle converte o branco para data e estoura; num
`NVL(NUMBER, ' ')` daria ORA-01722. A coluna está a NULL, mas o erro é de
conversão, não de valor: acontece sempre.

Correção no gerador (`expr_novo`), conforme o tipo da coluna no DDL:

| Tipo | Tam | Expressão |
|---|---|---|
| VARCHAR2 | n | `RPAD(NVL(col,' '), n)` |
| DATE | 8 | `RPAD(NVL(TO_CHAR(col,'YYYYMMDD'),' '), 8)` |
| NUMBER | 19 | `CASE WHEN col IS NULL THEN RPAD(' ',19) ELSE pack_utilitaire.f_format_montant(col) END` |
| NUMBER | 15 | `CASE WHEN col IS NULL THEN RPAD(' ',15) ELSE pack_utilitaire.f_format_taux_15(col) END` |
| NUMBER | outro | `LPAD(NVL(TO_CHAR(col),' '), n)` |

O formato do montante e da taxa é o que o ficheiro já usa, e fica em branco
quando não há valor — a mesma convenção dos compostos TRE201/TRE401. As larguras
não mudaram: 663 campos, 8000 caracteres, `valida_1222.py` com 0 erros.

O `.dat` dessa corrida ficou incompleto (tem os pavés até ao F2 e a linha `ORA-`
no fim) e não serve para comparação. É preciso correr outra vez.

## Segunda corrida no DEV2 (25/09) — o P1 saiu em três linhas

O spool correu até ao fim, mas o ficheiro veio com **798 495 linhas** em vez de
554 045: exatamente 2 × 122 225 a mais, ou seja **cada registo do P1 saiu em
três linhas** de 8000, uma por coluna.

Duas coisas, ambas do SQL*Plus:

1. **`SET COLSEP ''` foi ignorado.** A prova está nos outros pavés: eles contam
   com o espaço do COLSEP para fechar os 8000 (4000 + 1 + 3999) e saíram
   **byte a byte iguais** ao ficheiro de referência de 22/09. Se o COLSEP tivesse
   ficado vazio, tinham deslizado um byte.
2. **A largura de cada coluna é a do tipo declarado, não a dos dados.** Uma
   função como a `f_format_montant` devolve `VARCHAR2` sem tamanho, o que dá 4000
   a qualquer coluna que a contenha. Três colunas de 4000 mais dois COLSEP dão
   12 002, muito acima do `linesize` de 8000 — então o SQL*Plus pôs cada coluna
   na sua linha, e o `trimspool off` encheu cada uma até 8000.

Correção: **duas colunas** de 4000 e 3999 com o corte dentro do filler
`P1 25.99`, `CAST` a fixar a largura de cada uma, e o `SET COLSEP ''` retirado
do spool (a linha do P1 passa a usar o mesmo espaço de COLSEP que todos os
outros pavés).

Os dados do P1 dessa corrida servem para validar o conteúdo: as três linhas de
cada registo, cortadas em 4000 / 3999 e juntas com um espaço no meio, dão a
linha de 8000 que se esperava.

## Prova do conteúdo (25/09) — 122 225 registos

Os dados da corrida de 25/09 servem para validar o conteúdo, mesmo tendo saído
em três linhas por registo: colando as três partes (2669 + os bytes 4000–6670 da
primeira linha + 2660 da segunda) obtém-se a linha de 8000 que se esperava. Nos
registos testados, **os 662 `;` caem exatamente nas 662 posições que a Notice
prevê** e nenhum valor de campo contém `;`.

Depois reconstrói-se, a partir dos 611 campos comuns, a linha no formato antigo
— que, como se viu acima, é simplesmente os campos um atrás do outro — e
compara-se com a linha do ficheiro de referência de 22/09, emparelhada pelos
primeiros 3900 bytes. Resultado nos 122 225 registos, todos emparelhados:

```
perfis de diferença (bytes 1-based):
  (3982, 3983)   122180 registos     <- o N do netting, variantes 1,4,5,6,7
  (3983, 3984)       45 registos     <- variante 8, corrigido no gerador
```

**Fora desses dois bytes, os 5720 caracteres de dados são iguais byte a byte.**
Não há mais nenhuma diferença em toda a linha do P1.

Os 45 registos da variante 8 eram um erro do gerador, e não do desenho: como a
variante 8 já escrevia o `N` no sítio certo, a posição lida do spool punha-o no
`P1 30.24`. Resolvido com as regras à mão do bloco 30.x.

### A lista de correções para a DSID

1. **`P1 30.23`** — o `N` do indicador de netting contratual passa do byte 3982
   (último byte do `P1 30.22`) para o 3983, o campo que a Notice define.
   122 180 linhas. A variante 8 não muda.
2. **Os 51 campos criados na V45**, escritos em branco no fim da linha, e o
   filler final reduzido a 1176 (ver [QUESTAO-FILLER-P1.md](QUESTAO-FILLER-P1.md)).

Mais nada.

## O P1 validado (25/09) — ficheiro gerado no DEV2

Terceira corrida, com o spool corrigido (duas colunas, `CAST`, bloco 30.x à
mão). Ferramenta: [`comparar_1222.py`](../comparar_1222.py).

```
linhas: 554045 (referência: 554045)
censo por pavé: F1 122474 | F2 122474 | P1 122225 | P9 76374 | M1 65559
                C1 40856 | P2 4081 | cabeçalho 1 | rodapé 1
P1: campos novos nos bytes 6332..6824, filler final 6825..8000 (1176)
problemas: nenhum

outros pavés: 431820 linhas — só o cabeçalho difere, na data de geração

P1: 122225 linhas, todas emparelhadas
  (3982, 3983)   122180 linhas
  IDENTICO           45 linhas
```

O que isto prova, ponto por ponto:

- **554 045 linhas**, o mesmo número do ficheiro de referência, e todas com 8000
  caracteres. Nenhuma acaba em `;`.
- **O censo por pavé não mudou.** O código do pavé já não está nos bytes 39–40 do
  P1, por isso a contagem passa a ser pelo campo `0.6`.
- **No P1, 662 `;` por linha, todos nas 662 posições que a Notice prevê.** Nenhum
  valor de campo contém `;`.
- **A cauda está em branco nas 122 225 linhas**: os 51 campos criados na V45
  (bytes 6332–6824) e o filler final (6825–8000, 1176 caracteres), com `;` antes
  dele e nenhum depois.
- **Os outros seis pavés não foram tocados**: 431 820 linhas iguais byte a byte.
  A única diferença é a data de geração no cabeçalho, que muda a cada corrida.
- **No P1, uma única diferença de conteúdo**, e é a que o chamado pede.

### A lista de correções, para a DSID

| | O que muda | Linhas |
|---|---|---|
| 1 | O `N` do indicador de netting contratual passa do byte 3982 (último byte do `P1 30.22`, *Référence du contrat cadre*) para o byte 3983, o campo `P1 30.23` que a Notice define | 122 180 |
| 2 | Os 51 campos criados na V45 escritos em branco no fim da linha, e o filler final reduzido de 1185 para 1176 ([QUESTAO-FILLER-P1.md](QUESTAO-FILLER-P1.md)) | todas |

Nas 45 linhas da variante 8 o `N` já estava no `P1 30.23`: essas ficam idênticas.
Fora isto, os 5720 caracteres de dados são iguais byte a byte ao ficheiro de
22/09.

## Os outros seis pavés (25/09)

O P1 foi o piloto porque é o maior e porque o SIRL-1224 já o tinha passado a ler
da `ENG_CORP_P1_BIS`, campo a campo. Os outros seis mantêm os seus SELECT: o `;`
entra por corte dos tokens que lá estão (`gen_spool_paves.py`).

### A conta fecha em todos

| pavé | campos | dados | separadores | filler da Notice | sobra | total |
|---|---|---|---|---|---|---|
| P2 | 398 | 7603 | 397 | 4018 | 3621 | 8000 |
| M1 | 158 | 7843 | 157 | 6037 | 5880 | 8000 |
| C1 | 98 | 7903 | 97 | 6915 | 6818 | 8000 |
| F1 | 73 | 7928 | 72 | 7098 | 7026 | 8000 |
| F2 | 46 | 7955 | 45 | 7412 | 7367 | 8000 |
| P9 | 39 | 7962 | 38 | 7475 | 7437 | 8000 |
| P1 | 663 | 7347 | 662 | 1185 | 523 | **8009** |

O P1 era o único que não fechava — a dúvida do filler 1185/1176
([QUESTAO-FILLER-P1.md](QUESTAO-FILLER-P1.md)) é só dele. Nos outros seis o filler
final absorve os separadores e ainda sobram milhares de brancos.

### Ao contrário do P1, o filler final quase todo não está escrito

Vem do `SET linesize 8000` com `trimspool OFF`, que enche a linha de brancos. Por
isso os separadores não empurram nada: encolhe-se só o `RPAD(' ')` que fecha a
coluna 1, e a coluna 2 fica byte a byte como estava. Os campos com os separadores
dão 588 (F2), 902 (F1), 525 (P9), 1085 (C1), 1963 (M1) e **3982 (P2)** — todos
dentro dos 4000 da coluna 1. O P2 é o apertado, com 18 octetos de margem.

### Como se soube que cada campo cai no lugar certo

Não por sobreposição de posições: basta um campo escrito mais estreito para tudo
o que vem depois ficar fora do sítio, e um emparelhador guloso acusa então todo o
resto (no P2 dava 162 divergências falsas). O `casa_paves.py` faz alinhamento
global por programação dinâmica, minimizando o número de anomalias.

Três medições tiveram de ser corrigidas antes, senão a régua mentia:

- `( CASE ... END)` aberto com um espaço, que o medidor do `align_v44.py` só
  reconhecia como `(CASE` — vale 12 no C1;
- a máscara `'YYYYMMDDHH24MISS'`, 14, do C1;
- a `F_FORMAT_MONTANT_BIS3`, 19, que faltava na lista — era ela sozinha que fazia
  o P2 parecer 19 octetos curto.

Uma quarta medição faltava, e essa custou uma corrida no DEV2: o achatamento do
espaço branco entrava dentro dos literais. Ver *Nenhuma correção de campo* abaixo.
Com ela feita, o C1 mede 988 octetos de dados e o M1 1806, e os onze blocos dos
seis pavés casam com a Notice sem uma anomalia.

### Nenhuma correção de campo, para a DSID — REVISTO (25/09)

Aqui estava uma lista de sete campos — `M1 7.6`, `M1 8.31`, `M1 9.1`, `C1 4.9`,
`C1 4.99`, `C1 8.12` e `C1 8.14` — que o spool parecia escrever mais estreitos do
que a Notice manda, e que se corrigiam à mão.

**Não era verdade.** O erro era meu, no medidor de larguras: o `align_v44.width()`
achatava o espaço branco com `re.sub(r'\s+', ' ')` antes de medir, e isso entrava
dentro dos literais. Um campo escrito como o literal `'  '` — dois brancos — ficava
medido a 1. São exactamente estes sete:

| campo | como está no spool | medido | verdade |
|---|---|---|---|
| `C1 4.9`, `C1 4.99`, `C1 8.14` | `'  '` | 1 | 2 |
| `C1 8.12` | `'     '` | 1 | 5 |
| `M1 7.6`, `M1 8.31`, `M1 9.1` | `NVL(cd_…, '  ')` | 1 | 2 |

Com o `align_v44.achata()` a respeitar o que está entre apóstrofos, os seis pavés
casam com a Notice V45.02 **sem uma única anomalia** — nem um DIVERGE, FALTA,
SOBRA ou PARTE em nenhum dos onze blocos. O spool sempre concordou com a Notice.

Além disto, e como no P1: os campos criados na V45 vão em branco (42 no P2, 12 no
M1, nenhum nos outros quatro), todos no fim da linha.

### O cabeçalho e o rodapé já vinham com `;`

Estão escritos no shell (`030_CREATION_SPOOL_CRRCORP_vPACT.sh`), e já são
separados por `;`: 15 campos no cabeçalho e 3 no rodapé, o que a Notice prevê.
Não há nada a fazer — **fica uma pergunta**: o cabeçalho declara `44` como versão
técnica (`CRRC;44;`). Se o ficheiro passa a ser V45, a DSID confirma se esse
código muda para `45`.

### O que está conferido, e o que não está

Conferido sem base de dados (`valida_paves.py`, 0 erros nos seis pavés): cada
campo emite o tamanho que a Notice manda, o `;` está entre todos, a coluna 1 fecha
exactamente 4000, a cauda (coluna 2, FROM e WHERE) ficou byte a byte, e nenhuma
expressão com valor se perdeu pelo caminho.

Falta a corrida no DEV2 e o `comparar_1222.py` sobre o `.dat`, que é o que dá a
prova por conteúdo. Um dos blocos do P9 guardava o filler antigo na própria linha
do `as lignedetail1` — é o género de armadilha que só o ficheiro apanha.

## Encode dos ficheiros entregues (25/09)

Os `.sql` e os `.sh` são **Windows-1252 (cp1252)**, com fim de linha CRLF, como o
`030_spool_Extract_CRRCORP_vPACT.sql` que geraram o ficheiro de referência. Tudo o
que lê ou escreve estes ficheiros passou a declarar `cp1252` — antes dizia
`latin-1` (que dá os mesmos octetos só enquanto não houver nada entre 0x80 e 0x9F:
o `€`, o `–`, o `’` e as aspas curvas caem exactamente nessa faixa) ou, pior,
`utf-8`.

Dois ficheiros estavam de facto em UTF-8 e foram convertidos, com o texto igual:

| ficheiro | antes | depois |
|---|---|---|
| `ENG_CORP_P1_BIS.sql` | 146 444 octetos, UTF-8 (é×1386, à×155, ê×81, `«»`, `–`) | 144 641, cp1252 |
| `030_CREATION_SPOOL_CRRCORP.sh` | 22 127, UTF-8 | 22 126, cp1252 |

Quatro ficheiros **não** foram tocados porque o que têm não é UTF-8 limpo, é
*mojibake* de origem — a sequência `U+00EF U+00BF U+00BD`, que é o `ï¿½` de um
`U+FFFD` gravado há muito: `PACK_UTL_FILE_ENVOI_C3RD2.sql` (48 ocorrências),
`pack_alim_tab_envoi_crrv4.sql` (157), `030_spool_Extract_CRRADAP.sql` e
`030_CREATION_SPOOL_CRRADAP.sh`. Os acentos originais já não estão lá, e converter
o encode não os traz de volta. Se algum desses comentários fizer falta, tem de vir
do repositório de origem.

A prova de que a troca não mexeu em nada: com `cp1252` em vez de `latin-1`, o
`030_spool_Extract_CRRCORP_1222.sql` sai com o mesmo MD5
(`378028c23bb3a09f5c3e44978978c4e8`, antes de se corrigir o fim de linha para
CRLF).

## O ficheiro entregue passa a ser ASCII puro (25/09)

O encode declarado não chega: o ficheiro continuava a estragar-se de cada vez que
passava por um passo que o lê como UTF-8 — o VS Code a adivinhar, a **vista web do
GitHub** (que mostra `�` em qualquer ficheiro que não seja UTF-8), um copiar-colar
do browser. E o que se estraga não dá erro nenhum, que é o pior: fica a produzir
um ficheiro errado em silêncio.

Foi medido o alcance exato. Em todo o spool, os octetos acentuados em **código**
são 8 linhas, todas a mesma coisa:

```sql
translate(upper(C_ENR.NOM_TIERS), 'ÀÂÇÉÈÊËÎÝÔÖÙÛÜ', 'AACEEEEIIOOUUU')
```

o `translate` que tira os acentos ao **nome, morada, cidade e razão social do
tiers** no C1 (quatro campos × dois blocos). Se aqueles 14 octetos virarem
losangos, o `translate` deixa de casar e **o nome do tiers sai acentuado no
ficheiro entregue**.

Passam a ser escritos assim:

```sql
translate(upper(C_ENR.NOM_TIERS),
          CHR(192)||CHR(194)||CHR(199)||CHR(201)||CHR(200)||CHR(202)||CHR(203)||
          CHR(206)||CHR(221)||CHR(212)||CHR(214)||CHR(217)||CHR(219)||CHR(220),
          'AACEEEEIIOOUUU')
```

**A premissa**, que é a mesma que o ficheiro já faz hoje ao trazer os octetos
`C0..DC` escritos: a base tem um charset ocidental de um octeto. Confirma-se em
dois segundos antes de correr:

```sql
SELECT value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET';
SELECT CHR(192)||CHR(194)||CHR(199)||CHR(201)||CHR(200) FROM dual;   -- ÀÂÇÉÈ
```

Se a primeira devolver `WE8MSWIN1252` ou `WE8ISO8859P15`, está certo.

Os comentários também foram dobrados para ASCII: `Clientèle` → `Clientele`,
`Bâle 4` → `Bale 4`. E as três sequências `ï¿½` — um caractere perdido há muito,
gravado como `EF BF BD` — ficaram com a letra que o francês pede: `limité a 4000`
→ `limite a 4000`, `limite à 4000` → `limite a 4000`, `№01` → `N01`.

O `gen_spool_paves.py` **recusa-se** a dobrar um acento que esteja dentro de um
literal: literal é código, e dobrá-lo mudava o que a consulta faz. Se aparecer um
que o `CHR()` não apanhou, ele pára em vez de estragar em silêncio.

O `valida_paves.py` aplica a mesma troca ao lado do spool antes de comparar: se a
cadeia de `CHR(n)` não der exactamente o literal original, acusa.

Resultado: **0 octetos acima de 0x7F** no `030_spool_Extract_CRRCORP_1222.sql`.
Nenhum editor, browser ou transferência lhe pode tocar.

## As corridas dos seis pavés no DEV2 (25/09) — e o erro que elas apanharam

Duas corridas, `00021` às 16:54 e `00022` às 18:20, ambas com 554 045 linhas e o
censo por pavé certo. É aqui que o `comparar_1222.py` sobre o `.dat` diz o que a
validação estática não pode dizer.

### O que a primeira corrida mostrou

```
problemas: {'M1 ; FORA DE SITIO': 65559}
so no novo: {'C1': 40856, 'M1': 65559}
```

O `;` número 69 do M1 saía no octeto 706 em vez do 707, nas **65 559 linhas**. E o
C1 diferia em todas as 40 856, a partir do octeto 686.

O culpado apontava para o `M1 8.1`:

```sql
CASE WHEN substr(nvl(CD_NATURE_SURETE, '  '), -7, 5) = 'SEC01' THEN '1 ' ELSE '  ' END
```

Lido no spool, os dois ramos têm 2 caracteres e o campo tem largura fixa. Mas o
que eu tinha **gerado** era `ELSE ' '` — um branco. O achatamento comeu-lhe o
segundo, e o campo passou a escrever 1 numa linha e 2 noutra.

### A segunda corrida: o M1 fechou, o C1 ficou em 2 121

Com o campo embrulhado em `RPAD(NVL(..., ' '), 2)`, o `problemas:` passou a
**nenhum** — todos os `;` no lugar nos sete pavés. E a reconstrução:

| pavé | linhas | reconstruídas byte a byte |
|---|---|---|
| P1 | 122 225 | 122 180 com `(3982, 3983)` + 45 idênticas — o esperado |
| P2 | 4 081 | todas |
| M1 | 65 559 | todas |
| F1 | 122 474 | todas |
| F2 | 122 474 | todas |
| P9 | 76 374 | todas |
| C1 | 40 856 | 38 735 — faltavam **2 121** |

As 2 121 do C1 são exactamente as linhas com `NB_SALARIE` a NULL, e diferiam num
único campo:

```sql
-- no spool:   LPAD(NVL(to_char(NB_SALARIE), '      '), 6, '0')   -> '      '
-- gerado:     LPAD(NVL(to_char(NB_SALARIE), ' '),      6, '0')   -> '00000 '
```

Seis brancos achatados a um, e o `LPAD` enche a diferença com zeros. Um campo de
número de empregados que passava a dizer zero.

### A causa única

Os três problemas — o M1, o C1 e as "7 correções" — são o mesmo erro:
`re.sub(r'\s+', ' ')` aplicado a texto SQL que tem literais de brancos. Um literal
de brancos é **valor com largura**, não formatação.

A correção é o `align_v44.achata()`, que parte o texto nos apóstrofos e só achata
o que está fora deles:

```python
return ''.join(x if i % 2 else re.sub(r'\s+', ' ', x)
               for i, x in enumerate(re.split(r"('[^']*')", e)))
```

Usam-no o `width()` (que mede) e o `mapa_paves.tokens()` (que copia para o
ficheiro gerado). Com ele: onze blocos, seis pavés, **zero anomalias** contra a
Notice; o P1 não mexeu um octeto.

### A defesa que fica

Independentemente disto, cada campo dos seis pavés passa a sair embrulhado na
largura que a Notice manda, quando a expressão não a garante por si:

```sql
RPAD(NVL(<expressão>, ' '), <largura>)
```

O `NVL` por dentro não é enfeite: em Oracle `RPAD(NULL, n)` é `NULL`, e um `NULL`
numa concatenação escreve zero octetos — partia a linha pela outra ponta. São 43
campos no P2, 29 no M1, 16 no C1, 17 no F1, 12 no P9 e 7 no F2. Não corrige nada que esteja
errado hoje; fecha a porta a um campo cuja largura dependa dos dados.

### A tabela `ANTIGO` do comparador estava errada

O `comparar_1222.py` reconstruía a linha antiga encolhendo a 1 aqueles sete campos.
Vinha da mesma medição errada, e escondia o resultado: com a tabela vazia — cada
campo com a largura da Notice — o M1 reconstrói nas 65 559 linhas e o C1 em 38 735.
Ficou `ANTIGO = {}`.

### O que falta

Uma terceira corrida no DEV2 com o `C1 4.35` corrigido. O esperado: os seis pavés
sem uma linha de diferença, e o P1 com o `(3982, 3983)` de sempre.
