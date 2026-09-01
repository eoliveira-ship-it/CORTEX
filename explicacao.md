# Como a tabela `ENG_CORP_P1_BIS` sai da Notice

Explicação do zero: o que é a especificação, que regras se aplicam a cada
campo, e como a fórmula de Excel que está em [`excel`](excel) as executa.

---

## 1. O que é a Notice

A `Notice PACTV4.5_v1.0.xlsx`, aba **PACT Corp**, é a especificação
regulamentar do ficheiro. **Uma linha por campo.**

O `CRRCORP.dat` é um ficheiro de **largura fixa**: não tem separadores, cada
campo ocupa um número exato de caracteres numa posição exata da linha. A
Notice diz, para cada campo, o nome, o tipo e o comprimento — e é dessa
informação que sai a tabela.

Filtrando a coluna A por `P1`, ficam **662 linhas**: 662 campos do pavé P1.
Cada um dá uma coluna.

## 2. As seis colunas que interessam

| Coluna | Conteúdo | Exemplo |
|---|---|---|
| **A** | Objeto de coleta — serve de filtro | `P1` |
| **E** | Referência do campo | `P1 16.6` ou `0.1 (P1)` |
| **F** | Nome de negócio | `Pondération Bâloise de l'engagement (%)` |
| **T** | Formato | `ALPHA`, `NUM`, `DATE` |
| **U** | Regra de formatação | `10 dont signe et 5 décimales` |
| **W** | Comprimento | `10` |

## 3. Primeira regra — o nome da coluna

A referência vem em dois feitios:

| Na Notice | Significa | Coluna |
|---|---|---|
| `P1 21.30` | campo do corpo | `P1_21_30` |
| `0.1 (P1)` | campo do **cabeçalho** do pavé, repetido no início de cada linha | `P1_H_0_1` |

O `(P1)` no fim é a marca do cabeçalho. Sem essa distinção, `0.1 (P1)` e um
eventual `P1 0.1` dariam o mesmo nome e colidiam. Daí o `_H_`.

O ponto passa a underscore porque, num nome de coluna Oracle, um ponto seria
lido como `esquema.tabela`.

## 4. Segunda regra — o tipo

| Formato (coluna T) | Tipo Oracle |
|---|---|
| `DATE` | `DATE` |
| `ALPHA` | `VARCHAR2(comprimento)` |
| `NUM` | `NUMBER(precisão, escala)` |

Nos 662 campos do P1: **41** datas, **457** alfanuméricos, **164** numéricos.

## 5. A parte subtil — a precisão dos números

Aqui está o que quase toda a gente erra.

O **comprimento da Notice conta caracteres no ficheiro**. O `NUMBER(p,s)` do
Oracle **conta algarismos**. Não é a mesma coisa, porque no ficheiro há
caracteres que não são algarismos:

- o **sinal** (`+` ou `−`) ocupa 1 caractere
- o **separador decimal**, quando existe, ocupa 1

A regra da coluna U diz quais destes existem. Portanto:

```
precisão = comprimento − (1 se a regra diz "signe") − (1 se diz "séparateur")
escala   = o número que aparece antes de "décimales"
```

Três exemplos reais da Notice:

| Regra (coluna U) | W | Cálculo | Tipo gerado |
|---|---|---|---|
| `19 dont signe et 2 décimales` | 19 | 19 − 1 − 0 | `NUMBER(18,2)` |
| `10 dont signe et 5 décimales` | 10 | 10 − 1 − 0 | `NUMBER(9,5)` |
| `11 dont signe, séparateur et 7 décimales` | 11 | 11 − 1 − 1 | `NUMBER(9,7)` |

Declarar `NUMBER(19,2)` no primeiro caso seria aceitar um algarismo a mais do
que o ficheiro consegue escrever. A coluna tem de ter exatamente a capacidade
do campo — nem mais, nem menos.

---

# A fórmula

```excel
=LET(r,ROW(),ref,TRIM(INDEX($E:$E,r)),fmt,UPPER(TRIM(INDEX($T:$T,r))),lng,INDEX($W:$W,r),rule,INDEX($U:$U,r),nm,INDEX($F:$F,r),oc,INDEX($A:$A,r),num,SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(ref,"(P1)",""),"P1","")," ",""),isH,ISNUMBER(SEARCH("(P1)",ref)),col,IF(isH,"P1_H_","P1_")&SUBSTITUTE(num,".","_"),cut,IFERROR(LEFT(rule,SEARCH("cimale",rule)-1),""),cut2,IFERROR(TRIM(LEFT(TRIM(cut),LEN(TRIM(cut))-2)),""),dec,IFERROR(VALUE(TRIM(RIGHT(SUBSTITUTE(cut2," ",REPT(" ",50)),50))),0),sgn,IF(ISNUMBER(SEARCH("signe",rule)),1,0),sep,IF(ISNUMBER(SEARCH("parateur",rule)),1,0),typ,IF(fmt="DATE","DATE",IF(fmt="ALPHA","VARCHAR2("&lng&")",IF(fmt="NUM","NUMBER("&(lng-sgn-sep)&IF(dec>0,","&dec,"")&")","VARCHAR2("&lng&")"))),IF(oc<>"P1","","    "&col&"  "&typ&" ,  -- "&ref&" "&nm))
```

Parece intimidante porque é tudo uma linha. Por dentro são seis passos.

## O `LET`

`LET` serve só para **declarar variáveis e usá-las a seguir**. Escreve-se
`LET(nome1, valor1, nome2, valor2, …, resultado)`. A última expressão é o que a
célula mostra. Sem ele, a fórmula teria de repetir `INDEX($U:$U,ROW())` uma
dúzia de vezes.

## Passo 1 — ler a própria linha

```excel
r,    ROW()
ref,  TRIM(INDEX($E:$E,r))
fmt,  UPPER(TRIM(INDEX($T:$T,r)))
lng,  INDEX($W:$W,r)
rule, INDEX($U:$U,r)
nm,   INDEX($F:$F,r)
oc,   INDEX($A:$A,r)
```

`ROW()` devolve o número da linha onde a fórmula está. `INDEX($E:$E, r)` vai
buscar a célula da coluna E nessa linha.

Isto é deliberado. Em vez de escrever `E5` — que se desloca quando se copia e
desalinha se houver linhas inseridas — a fórmula **pergunta em que linha
está** e vai buscar os dados a essa mesma linha. Podes colá-la em qualquer
coluna, em qualquer sítio da folha, que nunca desalinha.

## Passo 2 — construir o nome

```excel
num,  SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(ref,"(P1)",""),"P1","")," ","")
isH,  ISNUMBER(SEARCH("(P1)",ref))
col,  IF(isH,"P1_H_","P1_") & SUBSTITUTE(num,".","_")
```

Os três `SUBSTITUTE` encaixados limpam a referência: tiram o `(P1)`, tiram o
`P1` e tiram os espaços. De `P1 21.30` sobra `21.30`; de `0.1 (P1)` sobra
`0.1`.

`SEARCH` devolve a posição do texto procurado, ou um erro se não existir.
`ISNUMBER` transforma isso num verdadeiro/falso — é o idioma do Excel para
«contém». Aqui decide o prefixo `P1_` ou `P1_H_`.

## Passo 3 — extrair o número de decimais

Esta é a parte que parece esquisita, e tem uma razão para cada peça:

```excel
cut,  IFERROR(LEFT(rule, SEARCH("cimale",rule)-1), "")
cut2, IFERROR(TRIM(LEFT(TRIM(cut), LEN(TRIM(cut))-2)), "")
dec,  IFERROR(VALUE(TRIM(RIGHT(SUBSTITUTE(cut2," ",REPT(" ",50)),50))), 0)
```

Partindo de `"19 dont signe et 2 décimales"`:

| | Resultado |
|---|---|
| `cut` — corta tudo antes de `cimale` | `19 dont signe et 2 dé` |
| `cut2` — tira os dois últimos caracteres (`dé`) | `19 dont signe et 2` |
| `dec` — fica com a última palavra | `2` |

**Porquê procurar `cimale` e não `décimales`?** Para evitar o acento, que pode
vir codificado de várias maneiras conforme quem gravou o ficheiro. E de
caminho apanha tanto o singular como o plural.

**O truque da última palavra.** `SUBSTITUTE(cut2," ",REPT(" ",50))` substitui
cada espaço por **cinquenta** espaços. O texto fica enorme e esparso.
`RIGHT(...,50)` corta os últimos 50 caracteres — como as palavras estão agora
separadas por 50 espaços, esses 50 caracteres contêm forçosamente só a última
palavra, rodeada de brancos. `TRIM` limpa os brancos e `VALUE` converte em
número. É o idioma clássico do Excel para «dá-me a última palavra».

Os `IFERROR` à volta devolvem `0` quando a regra não fala de decimais — casos
como `NA` ou `6 dont signe`.

## Passo 4 — o sinal e o separador

```excel
sgn, IF(ISNUMBER(SEARCH("signe",rule)),1,0)
sep, IF(ISNUMBER(SEARCH("parateur",rule)),1,0)
```

É a regra da secção 5 traduzida: **1** se a coluna U menciona a palavra, **0**
se não. Outra vez `parateur` sem a primeira sílaba, pelo mesmo motivo do
acento.

## Passo 5 — montar o tipo

```excel
typ, IF(fmt="DATE","DATE",
     IF(fmt="ALPHA","VARCHAR2("&lng&")",
     IF(fmt="NUM","NUMBER("&(lng-sgn-sep)&IF(dec>0,","&dec,"")&")",
     "VARCHAR2("&lng&")")))
```

O `IF(dec>0,","&dec,"")` evita escrever `NUMBER(6,0)` quando não há decimais —
escreve `NUMBER(6)`, que é o mesmo mas mais limpo.

O último ramo é a rede de segurança: um formato desconhecido cai em
`VARCHAR2`, que aceita tudo. Melhor uma coluna larga a mais do que um erro
silencioso.

## Passo 6 — o resultado

```excel
IF(oc<>"P1","", "    "&col&"  "&typ&" ,  -- "&ref&" "&nm)
```

Se a linha não é do pavé P1, devolve vazio. Se é, devolve a linha de DDL
pronta a usar:

```sql
    P1_16_6  NUMBER(9,5) ,  -- P1 16.6 Pondération Bâloise de l'engagement (%)
```

Copia-se a coluna toda, cola-se entre o `CREATE TABLE (` e o `)`, e está a
tabela feita.

---

# Onde a Notice não chega

Duas coisas que a fórmula não pode saber, e que só se descobrem confrontando
com os dados reais.

## Precisão insuficiente

A Notice diz quantos algarismos o **ficheiro** mostra. Se a coluna de origem
tiver mais, o `INSERT` rebenta com `ORA-01438`.

Aconteceu em **15 colunas**. O caso mais claro é o `P1_3_20`: a Notice dava
`NUMBER(12,4)`, mas a função `F_FORMAT_TAUX` lê **5** casas decimais do valor
bruto — a coluna arredondava à quarta e o ficheiro escrevia a quinta. Passou a
`NUMBER(18,10)`.

> A tabela tem de guardar precisão suficiente para **reproduzir** o ficheiro,
> não apenas a que o ficheiro mostra.

## Tipo contrariado pela origem

A Notice diz que a latitude é `NUM` com 7 decimais. Na base, `LATITUDE` é
`VARCHAR2` e o spool limita-se a fazer um `RPAD` de texto. Declarada como
`NUMBER`, dava `ORA-01722` — e, pior, perdia a representação exata. As duas
coordenadas passaram a `VARCHAR2`.

## Por isso os totais não batem certo

| | Notice | DDL final |
|---|---|---|
| `DATE` | 41 | 41 |
| `ALPHA` / `VARCHAR2` | 457 | **459** |
| `NUM` / `NUMBER` | 164 | **162** |

São as duas coordenadas que mudaram de lado.

Mais **cinco colunas técnicas** que não vêm da Notice — servem para saber de
onde veio cada linha e por que ordem a reescrever:

| Coluna | Para quê |
|---|---|
| `ID_ENGAGEMENT` | referência do engajamento na origem |
| `CD_PERIMETRE` | `NAT02` ou `HORS_NAT02` |
| `NO_VARIANTE` | 1..8, qual dos `SELECT` do spool deu esta linha |
| `DT_ARRETE` | data de arrêté do tratamento |
| `DT_TRAITEMENT` | horodatage da alimentação |

---

# A segunda fórmula

```excel
=LET(r,ROW(),oc,INDEX($A:$A,r),cv,TRIM(INDEX($Y:$Y,r)&""),IF(oc<>"P1","",IF(cv="45","V45 - novo, nao alimentado pelo spool atual","V44 - alimentado pelo spool atual")))
```

Muito mais simples. Lê a coluna **Y** (`VERSION DE CREATION`) e marca os campos
criados na V45.

Serve para uma coisa concreta: o spool atual implementa a notice **V44.02** e a
deste repositório é a **V45.00**. Os campos criados na V45 não têm origem no
spool — ficam sempre a `NULL` na tabela até o spool evoluir. Saber quais são
evita perder tempo a procurar de onde os havemos de alimentar.

Ver [docs/ECART-VERSAO.md](docs/ECART-VERSAO.md).
