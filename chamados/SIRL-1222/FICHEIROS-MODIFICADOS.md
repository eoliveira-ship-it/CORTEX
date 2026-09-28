# SIRL-1222 — ficheiros desta pasta

**O chamado:** pôr `;` entre todos os campos do `CRRCORP.dat` e do
`CRRADAP.dat`, os dois últimos fluxos ainda em formato posicional puro.

**Provado nos dois:** 554 045 linhas no Corporate, 1 777 no Adapté, nenhuma
diferente da referência depois de se desfazer os separadores.

> Detalhe e razão de cada passo: [`documentação/SIRL-1222.md`](../../documentação/SIRL-1222.md)

---

## Os ficheiros

| ficheiro | o que é no servidor | marca `VERSAO` |
|---|---|---|
| `030_spool_Extract_CRRCORP_1222.sql` | vai como `${SQL}/030_spool_Extract_CRRCORP_vPACT.sql` | `2026-09-27b` |
| `030_spool_Extract_CRRADAP_vPACT.sql` | ficheiro **novo** em `${SQL}/` | `2026-09-27a` |
| `030_CREATION_SPOOL_CRRADAP_vPACT.sh` | shell **novo** | — |
| `030_CREATION_SPOOL_CRRADAP.sh` | o shell de sempre, com **a chamada ao `_vPACT` no fim** | — |
| `comparar_ficheiros.sh` | ferramenta, corre no servidor | — |

### Corre ao lado do antigo, não em vez dele

O shell antigo do Adapté continua a escrever o `CRRADAP.dat` como sempre e, no
fim, chama o `_vPACT`, que escreve o `CRRADAP_vPACT.dat` a partir do seu próprio
spool. É o desenho que o Corporate já usava, e traz duas coisas: os dois
ficheiros saem da **mesma corrida** — mesmos dados, mesmo instante, e a
comparação deixa de depender de duas corridas — e se o novo rebentar, o oficial
já está escrito.

Por isso vão os **dois** shells: o antigo é quem leva a chamada, e sem ele o novo
nunca corre.

O `030_spool_Extract_CRRADAP.sql` **não se toca**, e não está aqui.

### ⚠ O sufixo `_1222` é nome de repositório, não nome de servidor

Sobra num ficheiro só, o spool do Corporate. O shell chama-o pelo **nome fixo**:

```ksh
spool_sql="${SQL}/030_spool_Extract_CRRCORP_vPACT.sql"
@$spool_sql $SORTIE $V30ENVOICRRFIC;
```

Copiado para lá com o nome `_1222`, o ficheiro **nunca é lido** — e o SQL\*Plus
não se queixa, porque o que ele pediu existe. Sai um ficheiro válido, no formato
antigo, sem uma linha de erro. **Isto aconteceu três vezes**, no Adapté.

Confirmar sempre depois de copiar:

```bash
grep VERSAO $SQL/030_spool_Extract_CRRCORP_vPACT.sql
grep VERSAO $SQL/030_spool_Extract_CRRADAP_vPACT.sql
```

E o shell do Adapté passou a registá-lo no log de cada corrida, antes de correr.

## O que mudou em cada um

### `030_spool_Extract_CRRCORP_1222.sql`

- **662 `;`** no P1, e 397 / 157 / 97 / 72 / 45 / 38 nos outros seis pavés;
- **1024 `TRANSLATE(x, ';', '.')`** nos campos de texto — a defesa que a DSID
  pediu para um `;` que apareça nos dados;
- o filler final encolhe o número de separadores, e **não leva `;` a seguir**;
- ficheiro em **ASCII puro**: os acentos do `translate` do C1 passaram a `CHR(n)`.

Leva também o SIRL-1223 (`P1 21.65` com 50) e o SIRL-1224 (lê da
`ENG_CORP_P1_BIS`). É o spool com os três empilhados.

### `030_spool_Extract_CRRADAP_vPACT.sql`

- **90 `;`** nos três blocos (`A1_CRRV4_DEGRADE`, `A1_DEGRADE_AUTO`,
  `A1_DEGRADE_GMBH`);
- o filler final passa de `LPAD(' ', 1164)` a `RPAD(' ', 929)`;
- os 17 campos criados na V45 saem em branco, na largura da Notice;
- duas expressões escritas à mão: o `CD_MOTEUR` do bloco `AUTO`, que tapava dois
  campos num `RPAD` de 7.

Sai do [`gen_spool_adap.py`](../../gen_spool_adap.py), a partir do spool antigo.

### `030_CREATION_SPOOL_CRRADAP_vPACT.sh`

Sai do [`gen_shell_adap.py`](../../gen_shell_adap.py), a partir do
`030_CREATION_SPOOL_CRRADAP.sh`. Leva os nomes próprios — `CRRADAP_vPACT.dat`,
os seus dois logs e o `030_spool_Extract_CRRADAP_vPACT.sql` — e três alterações
de conteúdo:

1. o `Z9` passa a ter **8 `;`**. Era a única linha do ficheiro sem separadores,
   e não vem do spool: vem do shell;
2. o filler do `Z9` encolhe de 1938 para **1930**;
3. escreve no log **qual spool vai ler e que versão tem**, antes de o correr.

O cabeçalho (`00;`) e o rodapé (`99;`) já tinham os `;` certos — 14 e 2 — e os
fillers deles já batiam ao octeto com a Notice.

### `030_CREATION_SPOOL_CRRADAP.sh`

Uma alteração só, no fim: o bloco que chama o `_vPACT` e propaga o código de
saída. O ficheiro que este shell escreve não muda um octeto.

## O que NÃO foi tocado

- `030_spool_Extract_CRRADAP.sql` — o spool antigo fica como está: é a base de
  que o gerador parte, e continua a escrever o `CRRADAP.dat` oficial.
- `PACK_UTL_FILE_ENVOI_C3RD2.sql` — o P3 já era de formato variável.
- O conteúdo dos dados. **Nenhum valor mudou**, em nenhum dos dois fluxos.

---

## Como validar

Sem base de dados, antes de copiar:

```bash
python valida_1222.py        # o P1 do Corporate
python valida_paves.py       # os outros seis
python valida_adap_1222.py   # os três blocos do Adapté
```

Depois da corrida, contra a referência:

```bash
python comparar_1222.py <CRRCORP novo> <a referencia de 22/09>
python comparar_adap.py  CRRADAP_vPACT.dat CRRADAP.dat
```
