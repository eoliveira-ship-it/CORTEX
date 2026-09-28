# SIRL-1224 — ficheiros desta pasta

**O chamado:** tirar as regras de negócio de dentro do spool. Passam para uma
procedure, que enche uma tabela nova; o spool só lê a tabela e formata.

**Provado:** o `CRRCORP.dat` gerado é idêntico ao de antes nas 554 045 linhas.

> Detalhe e razão de cada passo: [`documentação/SIRL-1224.md`](../../documentação/SIRL-1224.md)

---

## Os ficheiros

| ficheiro | novo ou alterado | o que é |
|---|---|---|
| `ENG_CORP_P1_BIS.sql` | **novo** | DDL da tabela: 662 colunas do P1 (uma por campo da Notice V45) + 4 técnicas = 666 |
| `pack_alim_tab_envoi_crrv4.sql` | **gerado** | o package de **produção** com a procedure `P_ALIM_ENG_CORP_P1_BIS` inserida |
| `pack_alim_tab_envoi_crrv4_PROD.sql` | — | o package de produção, intacto: a base de que o de cima sai |
| `pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql` | **novo** | a mesma procedure isolada, para rever sem abrir o package inteiro |
| `030_spool_Extract_CRRCORP_vPACT.sql` | **novo** | o spool que lê a tabela. Os 8 `SELECT` do P1 passam a 2 |
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | **novo** | o shell que chama a procedure e depois o spool |
| `030_CREATION_SPOOL_CRRCORP.sh` | **gerado** | o shell de produção **+** a chamada ao `_vPACT` no fim. Sem ele o novo nunca corre |
| `TESTES.sql` | **novo** | os quatro testes de validação |


### ⚠ O package é gerado, não editado

O package de produção tem 13 500 linhas; as nossas são 2 872. Um diff não
distingue «o que acrescentámos» de «o que a produção mudou» — por isso a
alteração vive num gerador, [`gen_pack_1224.py`](../../gen_pack_1224.py), que faz
**duas** inserções no ficheiro de produção e nada mais:

```
na spec    PROCEDURE P_ALIM_ENG_CORP_P1_BIS;       antes do END do package
no corpo   a procedure inteira                     antes do END do package
```

E que **para** se qualquer uma das âncoras não estiver exatamente uma vez. Se a
produção mudar, troca-se o `pack_alim_tab_envoi_crrv4.sql` na raiz e corre-se:

```bash
python gen_pack_1224.py
```

O mesmo vale para o shell: o `030_CREATION_SPOOL_CRRCORP.sh` desta pasta é o de
produção **+** a chamada ao `_vPACT`, posta pelo
[`gen_chamada_vpact.py`](../../gen_chamada_vpact.py).

## O que NÃO foi tocado

O **`030_spool_Extract_CRRCORP.sql`** (o spool antigo) fica como está. Os dois
convivem até à entrega: é o antigo que gera o ficheiro de referência contra o
qual se prova que nada mudou.

---

## Ordem de instalação

```
1. ENG_CORP_P1_BIS.sql                cria a tabela
2. pack_alim_tab_envoi_crrv4.sql      compila o package
3. run_procedure.sql                  carrega a tabela
4. TESTES.sql                         confirma
```

No SQL Developer: **F5 (Run Script)**, não F9.

---

## ⚠ Se for instalar os três chamados

**Não use o `030_spool_Extract_CRRCORP_vPACT.sql` desta pasta.** Esta é a versão
só com o 1224 — sem o alargamento do 1223 e sem os separadores do 1222.

A versão que vai para o servidor está em [`../final/`](../final/), e leva os
três empilhados.

Os outros cinco ficheiros desta pasta são os mesmos em `final/`.
