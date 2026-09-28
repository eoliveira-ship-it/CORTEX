# Ficheiros testados

Os ficheiros gerados no DEV2 que serviram de prova aos três chamados. O DEV2
está travado no arrêté **20250531**, por isso os dados são sempre os mesmos e
duas corridas só diferem no horodatage e no número de envio.

---

## O que está aqui

| ficheiro | corrida | o que prova |
|---|---|---|
| `CRRCORP_vPACT.7z.001` + `.002` | **00025**, 27/09 17:12 | o Corporate final: 554 045 linhas, os sete pavés com `;`, e o `TRANSLATE` |
| `CRRADAP.dat` | 28/09 00:20 | o Adapté final: 1 777 linhas, 14/90/8/2 `;` |
| `CRRCORP_P1.7z` | SIRL-1224 | o oráculo da régua V44 — foi contra ele que se validaram as posições de cada campo |
| `Ficheiros-1715.7z.001` … `.004` | **28/09 17:15** | **os três chamados juntos**, nos três fluxos: é esta a prova da entrega |

O `.7z.001` e o `.002` são **um arquivo partido em dois**, não dois arquivos.
Para juntar e extrair:

```bash
cat CRRCORP_vPACT.7z.001 CRRCORP_vPACT.7z.002 > junto.7z
python -c "import py7zr; py7zr.SevenZipFile('junto.7z').extractall('.')"
```

---

## A corrida de 28/09 12:11 — `Ficheiros.7z.001` … `.006`

Um arquivo partido em seis, com **três pares OLD/NEW** — o antes e o depois de
cada fluxo, na mesma corrida. Para juntar e extrair:

```bash
cat Ficheiros.7z.00[1-6] > junto.7z
python -c "import py7zr; py7zr.SevenZipFile('junto.7z').extractall('.')"
```

Descompactado dá ~11 GB. O `py7zr` extrai só o que se pedir:

```bash
python -c "import py7zr; py7zr.SevenZipFile('junto.7z').extract(path='x', targets=['UC2_P3/NEW/UC2_P3_APRES00357'])"
```

### O que cada par prova, e o que deu

| par | o que se corre | resultado |
|---|---|---|
| `CRRCORP/OLD/CRRCORP.dat` → `NEW/CRRCORP_vPACT.dat` | `python comparar_1223.py crrcorp <OLD> <NEW>` | **IDENTICOS**, 554 044 linhas |
| `CRRADAP/OLD/CRRADAP.dat` → `NEW/CRRADAP_vPACT.dat` | `python comparar_adap.py <NEW> <OLD>` | detalhe **IDENTICAS**; o `Z9` ficou no formato antigo |
| `UC2_P3/OLD/UC2_P3_AVANT*` → `NEW/UC2_P3_APRES*` | `python comparar_1223.py p3 <AVANT> <APRES>` | **IDENTICOS** nos cinco, 171 930 linhas |

### O par do Corporate é a prova do SIRL-1224

O `CRRCORP_vPACT.dat` sai do spool que lê da **`ENG_CORP_P1_BIS`**. Dar
`IDENTICOS` contra o ficheiro do spool antigo quer dizer que a tabela e a
procedure reproduzem o ficheiro **ao octeto** — é mais forte do que o
round-trip do `TESTES.sql`, que compara valor a valor mas não o ficheiro. E leva
o SIRL-1223 ao mesmo tempo: o único campo que muda é o `P1 21.65`.

Este par **não** tem os `;` do SIRL-1222 — nenhum dos dois lados. A prova do
1222 no Corporate é a outra, a corrida `00025`, no `CRRCORP_vPACT.7z.00*`.

### O `Z9` do Adapté ficou no formato antigo — e porquê

O `CRRADAP_vPACT.dat` desta corrida tem o detalhe `A1` certo — 90 `;`, e as
1774 linhas idênticas à referência — mas a linha `Z9` saiu **sem um único `;`**:

```
2025053100370C_BTR       M202609281211Z9          000000001774 ...
```

Essa linha não vem do spool, vem do **shell**. E a razão apareceu quando o
`030_CREATION_SPOOL_CRRADAP_vPACT.sh` entrou no repositório: era o shell antigo
com os nomes trocados (`CRRADAP_vPACT.dat`, o seu spool, os seus logs) e **sem as
três alterações do SIRL-1222** — o `Z9` com 8 `;`, o filler de 1930 e o rasto do
spool lido.

Está corrigido: o `030_CREATION_SPOOL_CRRADAP_vPACT.sh` passou a sair do
[`gen_shell_adap.py`](../gen_shell_adap.py), que aplica as duas coisas — os nomes
e o 1222 — a partir do shell antigo. **Provado na corrida de 17:15:** o `Z9`
saiu com 8 `;`.

### Os `.bat` de partir por pavé contam 12 caracteres, e passaram a ser 14

Os `.bat` que vêm nos arquivos (`CRRCORP_Split*.bat`) partem o ficheiro por
pavé com `findstr "\<M............C1\>"` — o padrão conta **12** caracteres
entre o `M` e o pavé, que é a distância do formato **sem** `;`. Com os
separadores do 1222 passam a ser 14 (`M;202609281719;C1`) e o `findstr` não acha
nada: saem os sete ficheiros **vazios, e sem erro nenhum**.

Medido numa amostra de 2 000 linhas do ficheiro de 17:15: com 12 pontos o
`C1` sai com **0 octetos**; com 14, as 1 999 linhas.

O corrigido está aqui: [`CRRCORP_Split_vPACT.bat`](CRRCORP_Split_vPACT.bat).
Para o ficheiro antigo, sem `;`, continua a servir o `CRRCORP_Split.bat`.

---

## A corrida de 28/09 17:15 — `Ficheiros-1715.7z.001` … `.004`

É esta a prova da entrega: a primeira corrida com **os três chamados
empilhados**, nos três fluxos, com os pares OLD/NEW da mesma corrida. Juntar e
extrair como acima (`cat Ficheiros-1715.7z.00[1-4] > junto.7z`); descompactado
dá ~10 GB, e o `py7zr` extrai só o que se lhe pedir.

Os dois lados saem do **mesmo arrêté e do mesmo número de envio** — o cabeçalho
do Corporate diz `00000533` nos dois, e só o horodatage difere (`171529` no
oficial, `171958` no novo), porque o shell de produção corre primeiro e chama o
`_vPACT` no fim.

### O que deu

| fluxo | o que se corre | resultado |
|---|---|---|
| Corporate | `python comparar_1222.py <NEW> <OLD> --ref-sem-1223` | **P1 IDÊNTICO** nas 122 225 linhas; os outros seis pavés sem uma linha por emparelhar |
| Adapté | `python comparar_adap.py <NEW> <OLD>` | **erros: 0** — e o `Z9` com **8 `;`**, pela primeira vez |
| P3 | `python comparar_1223.py p3 <AVANT> <APRES>` | **IDÊNTICOS** nos **cinco** pares, 171 930 linhas de detalhe |

### O censo do Corporate, pavé a pavé

554 045 linhas, **todas** com 8 000 octetos, e os separadores nos sítios da
notice:

```
P1  122225 linhas  662 ;      F1  122474 linhas   72 ;
P2    4081 linhas  397 ;      F2  122474 linhas   45 ;
M1   65559 linhas  157 ;      P9   76374 linhas   38 ;
C1   40856 linhas   97 ;      cabecalho 14 ;   rodape 2 ;
```

Rodapé `99;0000554045;` igual nos dois lados.

### O `--ref-sem-1223` não é opcional

A referência é o ficheiro do spool **de produção**, que não tem o SIRL-1223: o
`P1 21.65` sai lá com **5** octetos, e a régua (a da notice V45) tem-no com
**50**. Sem a bandeira, a reconstrução mete 45 brancos a mais e tudo o que vem
depois aparece deslocado 45 octetos — o P1 diverge nas 122 225 linhas a partir do
octeto **5222**, que é o 6.º do campo. Foi exatamente o que apareceu à primeira,
e não era regressão nenhuma.

### Cinco `UC2_P3`, não seis

O arquivo traz cinco pares — 00357, 00370, 00399, 00472, 00936 — e **não** o
00372, que o SIRL-667 tirou da lista em 29/04/2026. É o que se esperava: o sexto
ficheiro das corridas antigas vinha de um package compilado anterior ao 667.
---

## Como usar

### O Corporate

```bash
python comparar_1222.py CRRCORP_vPACT.dat <a referencia, sem ';'> --ref-sem-1223
```

Reconstrói cada linha no formato antigo — campos colados, cada um na largura da
Notice — e compara. Esperado: `P1 IDENTICO 122225` e nenhuma linha só de um lado
nos outros seis pavés.

O `--ref-sem-1223` diz que a referência é anterior ao SIRL-1223, e portanto que o
`P1 21.65` sai lá com 5 octetos e não 50. Com uma referência de **produção** é
sempre preciso.

### O Adapté

```bash
python comparar_adap.py CRRADAP.dat <a referencia de 22/09, sem ';'>
```

Esperado:

```
ENTETE  ";" {14}   A1  ";" {90}   Z9  ";" {8}   ENQUEUE  ";" {2}
todas as larguras batem com a notice
IDENTICAS: a unica mudanca e o ";".
erros: 0
```

---

## A referência

> **Desde a corrida de 17:15 isto deixou de ser um problema.** O par OLD/NEW sai
> da mesma corrida, e o OLD é o ficheiro do spool de produção — a referência vem
> dentro do arquivo, sempre. O que está escrito abaixo é sobre a referência
> antiga, de 22/09, e fica por causa das corridas anteriores.

A referência de 22/09 — o ficheiro **antes** dos separadores — **não está
aqui**. Foi tirada na limpeza de 28/09 para não duplicar centenas de MB. Está
no histórico do git:

```bash
git log --oneline --all -- CRRCORP_vPACT_PT1.7z
git show <commit>:CRRCORP_vPACT_PT1.7z > CRRCORP_vPACT_PT1.7z
```

Ou gera-se outra vez, correndo o spool anterior no DEV2 — os dados não mudam.

---

## Porque é que estes ficheiros ficam guardados

Sem o ficheiro **de antes**, não há prova nenhuma: um ficheiro com o tamanho
certo e os campos no sítio errado passa em qualquer verificação de formato. A
prova dos três chamados é sempre a mesma ideia — **desfazer a mudança e ver se
volta ao original** — e para isso é preciso ter os dois lados.
