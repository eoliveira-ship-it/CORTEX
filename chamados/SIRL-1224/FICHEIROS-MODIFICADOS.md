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
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | **gerado** | o shell de produção com os nomes trocados **+** o passo que enche a tabela, antes do spool |
| `030_CREATION_SPOOL_CRRCORP.sh` | **gerado** | o shell de produção **+** a chamada ao `_vPACT` no fim. Sem ele o novo nunca corre |
| `run_procedure.sql` | **novo** | a chamada à procedure, sozinha, para carregar a tabela sem abrir o `TESTES.sql` |
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

## O passo do RSE_LOT3 fica no shell de produção, não aqui

O shell de produção tem um passo que não é nosso — o **RSE_LOT3 / SIRL-153**, de
29/05/2025, que enche a tabela `PERIM_ENVOI_CRR_P1`:

```ksh
execute PACK_ALIM_TAB_ENVOI_CRRV4.P_ALIM_PERIM_ENVOI_CRR_P1;
```

Esse passo **não entra** no `030_CREATION_SPOOL_CRRCORP_vPACT.sh`, e é de
propósito: quem o corre é o shell de produção, que é quem chama o `_vPACT`. Numa
corrida normal ele já correu quando o nosso começa.

Repeti-lo aqui não estragava nada — a procedure começa com
`truncate table PERIM_ENVOI_CRR_P1` e reenche a partir da `ENG_CORP_P1` — mas
custava, em cada corrida, **oito varrimentos** da `ENG_CORP_P1` com `UNION` (não
`UNION ALL`, logo mais o *sort* para desduplicar), para reescrever a tabela com o
mesmo conteúdo.

No lugar dele, o gerador deixa **um comentário**, que não corre nada:

```ksh
## SIRL-1224 - le pas RSE_LOT3 / SIRL-153 (P_ALIM_PERIM_ENVOI_CRR_P1) n'est
## PAS ici : il tourne dans le shell de production, qui appelle celui-ci.
## Le jour ou ce shell remplacera celui de la production, il faudra le
## remettre -- sinon la table PERIM_ENVOI_CRR_P1 ne sera plus alimentee, et
## sans erreur : elle gardera le contenu de l'arrete precedent.
```

**Porque é que isto está escrito no ficheiro.** O fim natural deste chamado é o
`_vPACT` substituir o shell de produção. Nesse dia o passo desaparece com ele, e
a `PERIM_ENVOI_CRR_P1` deixa de ser enchida **sem dar erro** — fica com o
conteúdo do arrêté anterior. Nada da nossa cadeia lê essa tabela, por isso não
seríamos nós a dar por isso. Fica decidido nessa altura; o comentário é só para
não haver que o descobrir outra vez.

### A ordem dos passos, na corrida completa

```
./030_CREATION_SPOOL_CRRCORP.sh
   210  @spool antigo                  ->  CRRCORP.dat
   521  P_ALIM_PERIM_ENVOI_CRR_P1      ->  enche a PERIM_ENVOI_CRR_P1
   545  chama o _vPACT:
          201  P_ALIM_ENG_CORP_P1_BIS  ->  enche a ENG_CORP_P1_BIS
          245  @spool novo             ->  CRRCORP_vPACT.dat
```

O nosso passo entra **antes** do `extract_entite()`, e portanto antes do
`@$spool_sql`: o spool lê a tabela, tem de a encontrar cheia.

---

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
