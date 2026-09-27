# Instalação — os três chamados

Esta pasta tem a **versão final** de cada ficheiro, já com os três chamados
empilhados. Os ficheiros estão com **o nome que têm de ter no servidor** — não
com o nome que têm no repositório.

> Resumo do que cada chamado faz:
> [`documentação/RESUMO-DOS-3-CHAMADOS.md`](../../documentação/RESUMO-DOS-3-CHAMADOS.md)

---

## O que vai para onde

| ficheiro desta pasta | destino | chamados que leva |
|---|---|---|
| `ENG_CORP_P1_BIS.sql` | base de dados | 1224 |
| `pack_alim_tab_envoi_crrv4.sql` | base de dados | 1224 |
| `PACK_UTL_FILE_ENVOI_C3RD2.sql` | base de dados | 1223 |
| `030_spool_Extract_CRRCORP_vPACT.sql` | `${SQL}/` | 1224 + 1223 + **1222** |
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | o diretório dos shells | 1224 |
| `030_spool_Extract_CRRADAP.sql` | `${SQL}/` | **1222** |
| `030_CREATION_SPOOL_CRRADAP.sh` | o diretório dos shells | **1222** |
| `TESTES.sql` | correr no SQL Developer | 1224 |

### ⚠ Os nomes já estão certos — não lhes acrescente sufixos

No repositório estes dois chamam-se `..._1222.sql` e `..._1222.sh`. **Aqui não.**
O shell chama o spool pelo nome fixo:

```ksh
spool_sql="${SQL}/030_spool_Extract_CRRADAP.sql"
@$spool_sql $SORTIE $V30ENVOICRRFIC;
```

Se o ficheiro ficar ao lado com outro nome, **nunca é lido** e não há erro
nenhum: sai um ficheiro válido, no formato antigo. Aconteceu três vezes.

---

## Ordem

A ordem importa: a procedure precisa da tabela, e o spool precisa da tabela
cheia.

### 1 — Base de dados

No SQL Developer, **F5 (Run Script)**, não F9:

```
1.1  ENG_CORP_P1_BIS.sql                cria a tabela (666 colunas)
1.2  pack_alim_tab_envoi_crrv4.sql      compila o package com a procedure
1.3  PACK_UTL_FILE_ENVOI_C3RD2.sql      recompila o package do P3 (SIRL-1223)
```

Confirmar que os dois packages ficaram válidos:

```sql
SELECT object_name, status, TO_CHAR(last_ddl_time,'DD/MM/YYYY HH24:MI') AS compilado
  FROM user_objects
 WHERE object_name IN ('PACK_ALIM_TAB_ENVOI_CRRV4_NEW', 'PACK_UTL_FILE_ENVOI_C3RD2')
 ORDER BY 1;
```

`STATUS` tem de ser **VALID** nos dois. Se algum der `INVALID`:

```sql
SELECT line, position, text
  FROM user_errors
 WHERE name = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW'
 ORDER BY sequence;
```

### 2 — Carregar a tabela

```sql
SET SERVEROUTPUT ON
BEGIN
    pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS;
END;
/

SELECT CD_PERIMETRE, COUNT(*) AS linhas
  FROM ENG_CORP_P1_BIS
 GROUP BY CD_PERIMETRE
 ORDER BY 1;
```

Uma chamada só, sem parâmetros: esvazia a tabela e corre os 8 `INSERT` (NAT02 e
Fora do NAT02 juntos).

### 3 — Confirmar

```
TESTES.sql
```

Quatro testes. O **T4 (round-trip)** é o que conta: confirma que o valor guardado
na tabela reproduz o que o spool escrevia antes. Os outros três são
pré-condições — se a tabela ou o package estiverem errados, o T4 podia dar certo
por acaso.

### 4 — Os ficheiros do servidor

```
4.1  030_spool_Extract_CRRCORP_vPACT.sql   ->  ${SQL}/
4.2  030_CREATION_SPOOL_CRRCORP_vPACT.sh   ->  o diretorio dos shells
4.3  030_spool_Extract_CRRADAP.sql         ->  ${SQL}/
4.4  030_CREATION_SPOOL_CRRADAP.sh         ->  o diretorio dos shells
```

**Confirmar sempre depois de copiar:**

```bash
grep VERSAO $SQL/030_spool_Extract_CRRCORP_vPACT.sql
grep VERSAO $SQL/030_spool_Extract_CRRADAP.sql
```

Tem de sair:

```
-- VERSAO 2026-09-27b : os SETE paves com ";" entre todos os campos.
-- VERSAO 2026-09-27a : o Adapte com ";" entre todos os campos.
```

**São duas marcas diferentes.** O `27b` é o Corporate, o `27a` é o Adapté. Se o
`grep` do Adapté devolver `27b`, foi copiado o ficheiro do Corporate por cima.
Se não devolver nada, o ficheiro não foi substituído.

O shell do Adapté também o escreve no log de cada corrida:

```
INFO  Spool lido : /caminho/030_spool_Extract_CRRADAP.sql
INFO    -- VERSAO 2026-09-27a : o Adapte com ";" entre todos os campos.
```

Se aparecer `WARN sem linha VERSAO`, está lá o spool antigo.

### 5 — Correr e comparar

```bash
./030_CREATION_SPOOL_CRRCORP_vPACT.sh
./030_CREATION_SPOOL_CRRADAP.sh
```

E comparar com a referência:

```bash
python comparar_1222.py <CRRCORP novo> <referencia de 22/09>
python comparar_adap.py  <CRRADAP novo> <referencia sem ';'>
```

Esperado: `IDENTICOS` / `erros: 0`.

---

## O que se espera ver no ficheiro

### `CRRCORP.dat`

| | |
|---|---|
| linhas | 554 045, de 8000 octetos |
| separadores no P1 | 662 |
| P2 / M1 / C1 / F1 / F2 / P9 | 397 / 157 / 97 / 72 / 45 / 38 |
| cabeçalho / rodapé | 14 / 2 |

### `CRRADAP.dat`

| | |
|---|---|
| linhas | 1 777, de 2000 octetos |
| cabeçalho | 14 `;` |
| detalhe `A1` | **90 `;`** (91 campos), 1 774 linhas |
| `Z9` | 8 `;` (9 campos) |
| rodapé | 2 `;` |

Verificação rápida, no servidor:

```bash
# o detalhe do Adapte tem de dar 90 em todas as linhas
awk -F';' '!/^00;/ && !/^99;/ {print NF-1}' CRRADAP.dat | sort -u
```

---

## Se precisar de voltar atrás

Os originais não foram apagados. Estão no repositório, na raiz:

| voltar para | ficheiro |
|---|---|
| antes do 1222 (Corporate) | `030_spool_Extract_CRRCORP_vPACT.sql` da pasta `SIRL-1224/` |
| antes do 1222 (Adapté) | `030_spool_Extract_CRRADAP.sql` e `030_CREATION_SPOOL_CRRADAP.sh` da raiz |
| antes de tudo | `030_spool_Extract_CRRCORP.sql` e `030_CREATION_SPOOL_CRRCORP.sh` da raiz |

---

## Como regenerar esta pasta

Os ficheiros daqui são **cópias**. A fonte é a raiz do repositório:

```bash
python montar_entrega.py              # reconstrói chamados/
python montar_entrega.py --conferir   # diz se alguma cópia divergiu
```
