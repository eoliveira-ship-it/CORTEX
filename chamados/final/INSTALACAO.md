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
| `pack_alim_tab_envoi_crrv4.sql` | base de dados | 1224 — é o de produção **+** a procedure |
| `PACK_UTL_FILE_ENVOI_C3RD2.sql` | base de dados | 1223 |
| `030_spool_Extract_CRRCORP_vPACT.sql` | `${SQL}/` | 1224 + 1223 + **1222** |
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | o diretório dos shells | 1224 |
| `030_CREATION_SPOOL_CRRCORP.sh` | o diretório dos shells | 1224 — **é quem chama o de cima** |
| `030_spool_Extract_CRRADAP_vPACT.sql` | `${SQL}/` | **1222** |
| `030_CREATION_SPOOL_CRRADAP_vPACT.sh` | o diretório dos shells | **1222** |
| `030_CREATION_SPOOL_CRRADAP.sh` | o diretório dos shells | **1222** — **é quem chama o de cima** |
| `run_procedure.sql` | correr no SQL Developer | 1224 — a chamada à procedure, sozinha |
| `TESTES.sql` | correr no SQL Developer | 1224 — os quatro testes |

### Todos estes ficheiros saem da versão de PRODUÇÃO

Nenhum foi editado à mão. Cada um sai de um gerador que parte do ficheiro de
produção e lhe aplica só a alteração do chamado — e que **para** se a linha que
procura não estiver exatamente uma vez:

| o que se instala | sai de | a partir de |
|---|---|---|
| `pack_alim_tab_envoi_crrv4.sql` | `gen_pack_1224.py` | o package de produção + a procedure |
| `PACK_UTL_FILE_ENVOI_C3RD2.sql` | `gen_p3_1223.py` | o package de produção + 2 linhas |
| `030_CREATION_SPOOL_CRRCORP.sh` | `gen_chamada_vpact.py` | o shell de produção + a chamada |
| `030_CREATION_SPOOL_CRRADAP.sh` | `gen_chamada_vpact.py` | idem |
| `030_spool_Extract_CRRCORP_vPACT.sql` | `gen_spool_vpact.py` + `gen_spool_1222.py` | o spool de produção |
| `030_spool_Extract_CRRADAP_vPACT.sql` | `gen_spool_adap.py` | o spool de produção |
| `030_CREATION_SPOOL_CRRADAP_vPACT.sh` | `gen_shell_adap.py` | o shell de produção |

**Porque isto importa para quem instala:** se a produção mudar entre hoje e a
MEP, não se re-edita nada — troca-se o ficheiro de produção na raiz do
repositório e corre-se o gerador. Já aconteceu uma vez: o SIRL-1223 esteve
aplicado a uma cópia do package do P3 atrasada, e ia desfazer o SIRL-667 (a
entidade `00372`) sem ninguém ver.

Todos os ficheiros são **cp1252 + CRLF**, como no DDR:

```bash
python para_cp1252.py
```

---

### Os fluxos novos correm ao lado dos antigos, não em vez deles

Nenhum destes ficheiros substitui um spool antigo. Em cada um dos dois fluxos, o
shell de sempre continua a escrever o ficheiro oficial e, **no fim, chama o
`_vPACT`**, que escreve o seu a partir do seu próprio spool:

```
030_CREATION_SPOOL_CRRCORP.sh   ->  CRRCORP.dat         (030_spool_Extract_CRRCORP.sql)
   e no fim chama
030_CREATION_SPOOL_CRRCORP_vPACT.sh  ->  CRRCORP_vPACT.dat  (030_spool_Extract_CRRCORP_vPACT.sql)

030_CREATION_SPOOL_CRRADAP.sh   ->  CRRADAP.dat         (030_spool_Extract_CRRADAP.sql)
   e no fim chama
030_CREATION_SPOOL_CRRADAP_vPACT.sh  ->  CRRADAP_vPACT.dat  (030_spool_Extract_CRRADAP_vPACT.sql)
```

Duas razões, e as duas contam:

1. **os dois ficheiros saem da mesma corrida** — mesmos dados, mesmo instante.
   A comparação antes/depois deixa de depender de duas corridas separadas;
2. **se o novo rebentar, o oficial já está escrito.**

Por isso vão os **dois** shells de cada fluxo: o antigo é que leva a chamada, e
sem ele o novo nunca corre. Os dois spools antigos
(`030_spool_Extract_CRRCORP.sql` e `030_spool_Extract_CRRADAP.sql`) **não se
tocam** e não estão nesta pasta.

### ⚠ O nome do spool do Corporate

Um só ficheiro muda de nome do repositório para cá: no repositório chama-se
`030_spool_Extract_CRRCORP_1222.sql`, e aqui já está com o nome que o shell
chama. Não lhe acrescente o sufixo outra vez:

```ksh
spool_sql="${SQL}/030_spool_Extract_CRRCORP_vPACT.sql"
@$spool_sql $SORTIE $V30ENVOICRRFIC;
```

Deixado ao lado com outro nome, **nunca é lido** e não há erro nenhum: sai um
ficheiro válido, no formato antigo. Aconteceu três vezes, no Adapté.

---

## Ordem

A ordem importa: a procedure precisa da tabela, e o spool precisa da tabela
cheia.

### 1 — Base de dados

> **O nome do package.** Aqui chama-se `pack_alim_tab_envoi_crrv4` — o nome de
> produção, o que ele substitui. No repositório esse nome é o do ficheiro **de
> produção**, intacto, e o que se instala chama-se lá `..._1224.sql`. Quem lhes
> troca o nome é o [`montar_entrega.py`](../../montar_entrega.py) ao montar esta
> pasta. Não edite nomes à mão: o `030_CREATION_SPOOL_CRRCORP_vPACT.sh` também
> chama o package, e instalado com um nome e chamado com outro dá `PLS-00201`.

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
 WHERE object_name IN ('PACK_ALIM_TAB_ENVOI_CRRV4', 'PACK_UTL_FILE_ENVOI_C3RD2')
 ORDER BY 1;
```

`STATUS` tem de ser **VALID** nos dois. Se algum der `INVALID`:

```sql
SELECT line, position, text
  FROM user_errors
 WHERE name = 'PACK_ALIM_TAB_ENVOI_CRRV4'
 ORDER BY sequence;
```

### 2 — Carregar a tabela

```sql
SET SERVEROUTPUT ON
BEGIN
    pack_alim_tab_envoi_crrv4.P_ALIM_ENG_CORP_P1_BIS;
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
4.1  030_spool_Extract_CRRCORP_vPACT.sql     ->  ${SQL}/
4.2  030_CREATION_SPOOL_CRRCORP_vPACT.sh     ->  o diretorio dos shells
4.3  030_CREATION_SPOOL_CRRCORP.sh           ->  o diretorio dos shells
4.4  030_spool_Extract_CRRADAP_vPACT.sql     ->  ${SQL}/
4.5  030_CREATION_SPOOL_CRRADAP_vPACT.sh     ->  o diretorio dos shells
4.6  030_CREATION_SPOOL_CRRADAP.sh           ->  o diretorio dos shells
```

Os `4.3` e `4.6` são os shells antigos, com uma só alteração: a chamada ao
`_vPACT` no fim. **Sem eles o novo não corre.** Confirmar que a chamada está lá:

```bash
grep -n "_vPACT.sh" $SHL/030_CREATION_SPOOL_CRRCORP.sh $SHL/030_CREATION_SPOOL_CRRADAP.sh
```

**E a versão dos dois spools novos:**

```bash
grep VERSAO $SQL/030_spool_Extract_CRRCORP_vPACT.sql
grep VERSAO $SQL/030_spool_Extract_CRRADAP_vPACT.sql
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
INFO  Spool lido : /caminho/030_spool_Extract_CRRADAP_vPACT.sql
INFO    -- VERSAO 2026-09-27a : o Adapte com ";" entre todos os campos.
```

Se aparecer `WARN sem linha VERSAO`, está lá o spool antigo.

### 5 — Correr e comparar

Corre-se **só o shell antigo** de cada fluxo. Ele chama o novo:

```bash
./030_CREATION_SPOOL_CRRCORP.sh
./030_CREATION_SPOOL_CRRADAP.sh
```

Saem dois ficheiros de cada fluxo, da mesma corrida — e é esse par que se
compara:

```bash
python comparar_1222.py CRRCORP_vPACT.dat CRRCORP.dat
python comparar_adap.py  CRRADAP_vPACT.dat CRRADAP.dat
```

Esperado: `IDENTICOS` / `erros: 0`.

---

## O que se espera ver nos ficheiros NOVOS

Os antigos (`CRRCORP.dat` e `CRRADAP.dat`) não mudam — saem como sempre.

### `CRRCORP_vPACT.dat`

| | |
|---|---|
| linhas | 554 045, de 8000 octetos |
| separadores no P1 | 662 |
| P2 / M1 / C1 / F1 / F2 / P9 | 397 / 157 / 97 / 72 / 45 / 38 |
| cabeçalho / rodapé | 14 / 2 |

### `CRRADAP_vPACT.dat`

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
awk -F';' '!/^00;/ && !/^99;/ {print NF-1}' CRRADAP_vPACT.dat | sort -u

# e o Z9, a unica linha que vem do shell: 8
grep -c ";" CRRADAP_vPACT.dat
```

---

## Se precisar de voltar atrás

Não há nada para desfazer nos fluxos: os spools e os ficheiros antigos continuam
a ser escritos como sempre. Para desligar o novo, basta tirar a chamada do fim do
shell antigo — o bloco `Lancement du script ..._vPACT.sh`. O ficheiro oficial não
muda.

Na base de dados, os originais estão no repositório, na raiz.

---

## Como regenerar esta pasta

Os ficheiros daqui são **cópias**. A fonte é a raiz do repositório:

```bash
python montar_entrega.py              # reconstrói chamados/
python montar_entrega.py --conferir   # diz se alguma cópia divergiu
```
