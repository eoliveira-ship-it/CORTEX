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
| `pack_alim_tab_envoi_crrv4.sql` | **alterado** | o package existente, agora com a procedure `P_ALIM_ENG_CORP_P1_BIS` lá dentro |
| `pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql` | **novo** | a mesma procedure isolada, para rever sem abrir o package inteiro |
| `030_spool_Extract_CRRCORP_vPACT.sql` | **novo** | o spool que lê a tabela. Os 8 `SELECT` do P1 passam a 2 |
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | **novo** | o shell que chama a procedure e depois o spool |
| `TESTES.sql` | **novo** | os quatro testes de validação |

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
