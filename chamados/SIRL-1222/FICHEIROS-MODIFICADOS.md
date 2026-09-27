# SIRL-1222 — ficheiros desta pasta

**O chamado:** pôr `;` entre todos os campos do `CRRCORP.dat` e do
`CRRADAP.dat`, os dois últimos fluxos ainda em formato posicional puro.

**Provado nos dois:** 554 045 linhas no Corporate, 1 777 no Adapté, nenhuma
diferente da referência depois de se desfazer os separadores.

> Detalhe e razão de cada passo: [`documentação/SIRL-1222.md`](../../documentação/SIRL-1222.md)

---

## Os ficheiros

| ficheiro | substitui no servidor | marca `VERSAO` |
|---|---|---|
| `030_spool_Extract_CRRCORP_1222.sql` | `${SQL}/030_spool_Extract_CRRCORP_vPACT.sql` | `2026-09-27b` |
| `030_spool_Extract_CRRADAP_1222.sql` | `${SQL}/030_spool_Extract_CRRADAP.sql` | `2026-09-27a` |
| `030_CREATION_SPOOL_CRRADAP_1222.sh` | o shell do Adapté, mesmo nome sem o `_1222` | — |
| `comparar_ficheiros.sh` | ferramenta, corre no servidor | — |

### ⚠ O sufixo `_1222` é nome de repositório, não nome de servidor

O shell chama o spool pelo **nome fixo**:

```ksh
spool_sql="${SQL}/030_spool_Extract_CRRADAP.sql"
@$spool_sql $SORTIE $V30ENVOICRRFIC;
```

Copiado para lá com o nome `_1222`, o ficheiro **nunca é lido** — e o SQL\*Plus
não se queixa, porque o que ele pediu existe. Sai um ficheiro válido, no formato
antigo, sem uma linha de erro. **Isto aconteceu três vezes.**

Confirmar sempre depois de copiar:

```bash
grep VERSAO $SQL/030_spool_Extract_CRRADAP.sql
grep VERSAO $SQL/030_spool_Extract_CRRCORP_vPACT.sql
```

E o shell do Adapté passou a registá-lo no log de cada corrida, antes de correr.

---

## O que mudou em cada um

### `030_spool_Extract_CRRCORP_1222.sql`

- **662 `;`** no P1, e 397 / 157 / 97 / 72 / 45 / 38 nos outros seis pavés;
- **1024 `TRANSLATE(x, ';', '.')`** nos campos de texto — a defesa que a DSID
  pediu para um `;` que apareça nos dados;
- o filler final encolhe o número de separadores, e **não leva `;` a seguir**;
- ficheiro em **ASCII puro**: os acentos do `translate` do C1 passaram a `CHR(n)`.

Leva também o SIRL-1223 (`P1 21.65` com 50) e o SIRL-1224 (lê da
`ENG_CORP_P1_BIS`). É o spool com os três empilhados.

### `030_spool_Extract_CRRADAP_1222.sql`

- **90 `;`** nos três blocos (`A1_CRRV4_DEGRADE`, `A1_DEGRADE_AUTO`,
  `A1_DEGRADE_GMBH`);
- o filler final passa de `LPAD(' ', 1164)` a `RPAD(' ', 929)`;
- os 17 campos criados na V45 saem em branco, na largura da Notice;
- duas expressões escritas à mão: o `CD_MOTEUR` do bloco `AUTO`, que tapava dois
  campos num `RPAD` de 7.

### `030_CREATION_SPOOL_CRRADAP_1222.sh`

Três alterações cirúrgicas — o resto do ficheiro não muda um octeto:

1. o `Z9` passa a ter **8 `;`**. Era a única linha do ficheiro sem separadores,
   e não vem do spool: vem do shell;
2. o filler do `Z9` encolhe de 1938 para **1930**;
3. o shell escreve no log **qual spool vai ler e que versão tem**, antes de o
   correr.

O cabeçalho (`00;`) e o rodapé (`99;`) já tinham os `;` certos — 14 e 2 — e os
fillers deles já batiam ao octeto com a Notice.

## O que NÃO foi tocado

- `030_spool_Extract_CRRADAP.sql` e `030_CREATION_SPOOL_CRRADAP.sh` — os
  originais ficam como estão; são a base de que os geradores partem.
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
python comparar_adap.py  <CRRADAP novo> <a referencia sem ';'>
```
