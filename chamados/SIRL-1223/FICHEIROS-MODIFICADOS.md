# SIRL-1223 — ficheiros desta pasta

**O chamado:** alargar o campo `21.65` de 5 para 50 octetos, em dois fluxos.

**Provado:** nos dois, a única mudança é a pedida — 554 045 linhas no Corporate,
172 000 no P3.

> Detalhe e razão de cada passo: [`documentação/SIRL-1223.md`](../../documentação/SIRL-1223.md)

---

## Os ficheiros

| ficheiro | o que mudou lá dentro |
|---|---|
| `030_spool_Extract_CRRCORP_vPACT.sql` | `P1 21.65`: `RPAD(' ',5)` → `RPAD(' ',50)`, nos 6 `SELECT` do P1 |
| `PACK_UTL_FILE_ENVOI_C3RD2.sql` | `P3C 21.65`: `RPAD(' ',5)` → `RPAD(' ',50)`<br>filler BALE4: `RPAD(' ',1132)` → `RPAD(' ',1087)` |
| `PACK_UTL_FILE_ENVOI_C3RD2_PROD.sql` | **a versão de produção, sem alterações** — a base de que o de cima sai |
| `VALIDAR_1223_P3.sql` | **novo** — gera o par antes/depois do P3, com nomes próprios |

### ⚠ A base do package é a versão de PRODUÇÃO, e isso não é um detalhe

A cópia do package que veio do DDR estava **atrasada** em relação à produção. As
duas linhas do chamado estavam certas nela, mas o ficheiro inteiro, instalado,
desfazia três alterações que ninguém pediu:

| | em produção | na cópia do DDR |
|---|---|---|
| a entidade `'00372'` | **retirada**, `-- 29/04/2026 -- SIRL-667` | ainda lá → saía um 6.º `UC2_P3`, vazio |
| `v_ligne` do C2 | `VARCHAR2(2002)`, linha com `;` final | `VARCHAR2(2000)`, sem ele |
| `v_ligne` do C3 | `VARCHAR2(1002)`, o mesmo | `VARCHAR2(1000)` |
| `IND_WL` (C2 4.60, C3 4.60) | default `'9'` | default `' '` |

Nada disto aparece num diff do chamado. Só aparece comparando a **base** com a
produção — e o que deu o alerta foi o 6.º ficheiro `UC2_P3` numa corrida do DEV2.

Por isso o ficheiro entregue sai de um gerador,
[`gen_p3_1223.py`](../../gen_p3_1223.py), que parte do `_PROD.sql` e **para** se a
linha que procura não estiver exactamente uma vez:

```bash
python gen_p3_1223.py
```

O resultado difere da produção em **duas linhas**. Mais nada.

As duas linhas do P3 estão marcadas no ficheiro:

```sql
RPAD(' ',50)    ||';'||  --P3C 21.65 -- SIRL-1223 5 -> 50
RPAD(' ',1087);          -- BALE4    -- SIRL-1223 1132 -> 1087
```

## Onde a mudança do P1 vive de facto

Não está escrita à mão no spool. Está num dicionário do
[`gen_spool_vpact.py`](../../gen_spool_vpact.py):

```python
ALARGAMENTOS = {5215: ('P1 21.65', 5, 50)}
```

**Porquê:** o gerador escreve o *offset* de cada campo num comentário ao lado, e
é esse comentário que se lê para conferir. Feito à mão, os comentários ficavam
todos errados do 5215 em diante. O gerador ainda verifica que o campo naquele
offset é mesmo o esperado — se não for, **para**, em vez de alargar o errado.

## O que NÃO foi tocado

- O **`030_spool_Extract_CRRCORP.sql`** (spool antigo) — continua a gerar o
  ficheiro de referência.
- A tabela **`ENG_CORP_P1_BIS`** — a coluna `P1_21_65` já é `VARCHAR2(50)`,
  porque o SIRL-1224 leu a estrutura da Notice V45 e não do spool V44.

---

## Como validar

```bash
python comparar_1223.py crrcorp CRRCORP_vPACT_rodada5.dat CRRCORP_depois.dat
python comparar_1223.py p3      C3RD_antes.dat            C3RD_depois.dat
```

O script aplica ao ficheiro **de antes** a mudança do chamado e compara com o de
depois. `IDENTICOS` = a única mudança é a pedida.

Para o P3 não há referência: gerar o ficheiro **antes** de recompilar o package
e **depois**. Os comandos estão no `VALIDAR_1223_P3.sql`.

---

## ⚠ Se for instalar os três chamados

**Não use o `030_spool_Extract_CRRCORP_vPACT.sql` desta pasta.** Esta é a versão
com o 1224 e o 1223, sem os separadores do 1222. A que vai para o servidor está
em [`../final/`](../final/).

O `PACK_UTL_FILE_ENVOI_C3RD2.sql` desta pasta **é** o final — o SIRL-1222 não
mexe no P3.
