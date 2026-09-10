# SIRL-1224 — Resumo para a equipe

> Situação em **10/09/2026**. Documento para repassar o trabalho a quem não
> acompanhou. O histórico completo, com todas as investigações, está em
> [SIRL-1224.md](SIRL-1224.md).

---

## 1. O chamado, em poucas palavras

O arquivo regulatório **`CRRCORP.dat`** é gerado por um spool SQL*Plus
(`030_spool_Extract_CRRCORP.sql`). Na parte do **pavé P1** (os engajamentos),
esse spool não só formata os dados: ele também aplica **regras de negócio**
(valores padrão, `CASE`, filtros, conversões).

O objetivo do SIRL-1224 é:

1. criar a tabela **`ENG_CORP_P1_BIS`**, com uma coluna por campo P1 da Notice
   PACT V4.5;
2. criar a procedure **`P_ALIM_ENG_CORP_P1_BIS`**, que aplica as regras de
   negócio e preenche a tabela;
3. criar um spool novo, **`030_spool_Extract_CRRCORP_vPACT.sql`**, que só lê
   a tabela e formata;
4. provar que o arquivo gerado **não muda**.

O spool atual **não foi alterado**. Os dois convivem até a entrega.

---

## 2. Como era e como fica

**Antes**

```
ENG_CORP_P1 ──► spool antigo (regras de negócio + formatação) ──► CRRCORP.dat
```

**Depois**

```
ENG_CORP_P1 ──► procedure (regras de negócio) ──► ENG_CORP_P1_BIS ──► spool vPACT (só formatação) ──► CRRCORP.dat
```

A procedure pode rodar em duas fases, como o chamado pede:

| Fase | Parâmetro `p_perimetre` | Quando |
|---|---|---|
| NAT02 | `'NAT02'` (INSERTs 1 a 3) | durante a M2 BTR |
| Fora do NAT02 | `'HORS_NAT02'` (INSERTs 4 a 8) | depois de receber os dados contábeis |
| Tudo de uma vez | `'TOTAL'` | usado hoje nos testes |

---

## 3. O que foi entregue

| Arquivo | O que é |
|---|---|
| `ENG_CORP_P1_BIS.sql` | Cria a tabela: **667 colunas** (662 campos P1 + 5 técnicas), com `COMMENT ON COLUMN` em todas |
| `pack_alim_tab_envoi_crrv4.sql` | Package completo, já com a procedure nova |
| `pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql` | Só a procedure, para leitura |
| `030_spool_Extract_CRRCORP_vPACT.sql` | Spool novo, que lê a tabela |
| `030_CREATION_SPOOL_CRRCORP_vPACT.sh` | Shell novo: chama a procedure e depois o spool novo |
| `TESTES.sql` | Testes T1 a T4 (estrutura, package, volumetria, round-trip) |
| `run_procedure.sql` | Roda a procedure manualmente |
| `comparar_ficheiros.sh` | Compara dois `CRRCORP.dat` (ver a pendência no item 7) |
| `gen_*.py`, `layout_variantes.py`, `align_v44.py`, `conv_spool.py` | Geradores: a tabela, a procedure, o spool e os testes são **gerados** a partir do spool antigo e da Notice. Não edite os `.sql` gerados à mão |

### As colunas da tabela

- **Nome:** o campo `P1 21.28` da Notice vira `P1_21_28`. O cabeçalho do pavé,
  `1.11 (P1)`, vira `P1_H_1_11`.
- **Tipo:** `ALPHA` vira `VARCHAR2`, `DATE` vira `DATE` e `NUM` vira `NUMBER`.
- **Campo em branco** no spool vira `NULL` na tabela.
- **16 colunas `NUMBER` foram alargadas** em relação à Notice. A Notice limita
  o que vai no arquivo, não o valor gravado. Com a precisão da Notice, alguns
  valores reais davam `ORA-01438` e derrubavam a procedure inteira.
- **Colunas técnicas:**
  - `ID_ENGAGEMENT`;
  - `CD_PERIMETRE` (`NAT02` / `HORS_NAT02`);
  - `NO_VARIANTE` (1 a 8, qual dos 8 SELECTs do spool antigo gerou a linha);
  - `DT_ARRETE`;
  - `DT_TRAITEMENT`.

### Por que o spool novo tem 6 SELECTs e não 1

O plano pedia "une seule requête SELECT". Isso **não é possível sem mudar o
arquivo**.

O spool antigo tem **8 SELECTs** (as "variantes"), e eles não escrevem a mesma
coisa nas mesmas posições da linha:

| Variante | Perímetro | Tipos de risco |
|---|---|---|
| 1, 2, 3 | NAT02 | risco padrão (as três têm o mesmo layout) |
| 4 | Fora do NAT02 | TRE100 |
| 5 | Fora do NAT02 | TRE2 / TRE4 / TRE5 |
| 6 | Fora do NAT02 | EQU101 |
| 7 | Fora do NAT02 | SIG201 / INR101 |
| 8 | Fora do NAT02 | derivados (`%VAR1%`) |

Um exemplo concreto: nos bytes 989 a 2250, a variante 1 escreve brancos e a
variante 8 escreve os campos do derivado (MtM, netting, CVA, spread…).

Por isso, o spool novo tem **1 SELECT para o NAT02 + 5 para o Fora do NAT02**,
cada um no mesmo lugar do arquivo em que os originais estavam.

---

## 4. Como provamos que o arquivo não mudou

### 4.1 Por que um `diff` direto não serve

Dois arquivos gerados em execuções diferentes **sempre** diferem em duas coisas
que não são dado de negócio:

1. **Horário de processamento (`MASYSDATE`)**, bytes 27 a 38 de **todas** as
   linhas. O shell grava ali a data e a hora em que rodou, até o minuto. Nem o
   spool antigo rodado duas vezes gera o mesmo valor.
2. **Ordem das linhas.** Ver o item 4.4.

O método correto: **esconder o `MASYSDATE`, ordenar as linhas e então
comparar**.

### 4.2 As rodadas de comparação

| Rodada | Registros | Diferentes | Causa | Situação |
|---|---|---|---|---|
| 1 | 122138 (só NAT02) | 8770 | O spool **instalado** no DEV2 era anterior ao SIRL-500 nas variantes 2 e 3. Não era erro do código novo | resolvido com a instalação do spool atual |
| 2 | 122225 | 87 | A base ganhou, pela primeira vez, registros Fora do NAT02, e o spool novo usava o layout da variante 1 para todos | corrigido: 6 SELECTs |
| 3 | 122225 | 57 | (a) maturidade `P1 3.20` mal formatada nas variantes 4 e 6; (b) 28 campos da variante 8 saindo em branco | corrigido |
| **4** | **122225** | **0** | — | **conteúdo idêntico** |

Na rodada 4 os dois arquivos têm o mesmo tamanho (977.922.225 bytes), as mesmas
122225 linhas de 8000 bytes e, escondido só o `MASYSDATE`, **as mesmas linhas,
byte a byte**. Isso vale para o NAT02 e para o Fora do NAT02 (VAR104, TRE409,
TRE100, EQU101, SIG201).

A rodada 4 foi repetida com um segundo par de arquivos gerados de forma
independente (`_v2`). Resultado igual.

### 4.3 O que cada correção da rodada 3 resolveu

**(a) Maturidade nas variantes 4 e 6.**

O spool antigo escreve a maturidade em dois pedaços:

```sql
LPAD(ABS(TRUNC(C_ENR.MATURITE_EFF)),2,'0') || LPAD(ABS(MOD(C_ENR.MATURITE_EFF*10000,10000)),4,'0')
```

O gerador perdia o `ABS/TRUNC/MOD` e escrevia `LPAD(P1_3_20,2,'0')`. Uma
maturidade de `0,0055` saía `.0.005` em vez de `000055`.

Além de corrigir, o gerador agora **para com erro** se alguma função do spool
antigo sumir do spool novo. Esse tipo de problema passa a ser pego sem precisar
rodar no banco.

**(b) Variante 8.**

Os bytes 989 a 2250 estavam excluídos do mapeamento automático. A exclusão
existia porque um token de sinal era medido com 10 bytes em vez de 1, o que
deslocava tudo em 9 bytes e gerava falsos acertos.

Corrigida a medida, os campos da faixa batem exatamente com a Notice, e o nome
de cada um confere com a coluna de origem:

- `MNT_MTM` → `P1 3.80` Mark-to-Market;
- `IND_ACCORD_NETTING` → `P1 3.16` netting;
- `NATURE_OPTION` → `P1 10.1` Nature de l'Option.

O INSERT #8 passou de 132 para **160 colunas**. Nenhum campo fica mais sem
coluna.

Um caso especial é o **spread** (`P1 11.2`). O sinal vem num token separado:

```sql
(CASE WHEN C_ENR.MT_SPREAD >= 0 THEN '+' ELSE '-' END) || LPAD(ABS(TRUNC(NVL(C_ENR.MT_SPREAD,0))),4,'0')
```

A procedure grava o `MT_SPREAD` **sem alteração**, para o spool conseguir
remontar o `+`/`-`, inclusive quando o valor é NULL (o spool antigo escreve
`-`). A coluna `P1_11_2` foi alargada para `NUMBER(18,10)`.

### 4.4 A ordem das linhas: decisão de não mexer

Cada spool foi rodado duas vezes sobre a mesma base:

| Comparação | Ordem | Conteúdo |
|---|---|---|
| antigo × antigo | **igual** (122225 de 122225 na mesma posição) | igual |
| novo × novo | **muda a cada execução** (só 87 no mesmo lugar) | igual |
| antigo × novo | diferente | **igual** |

**Por que acontece:**

- **O spool antigo não tem nenhum `ORDER BY`.** A ordem é a da leitura física
  da `ENG_CORP_P1`, que se repete só porque ninguém mexe na tabela entre as
  execuções. O Oracle **não garante** essa ordem, e ela também não segue
  nenhum campo: os IDs são únicos, mas não estão ordenados.
- **O spool novo muda** porque a procedure faz `DELETE` + `INSERT` a cada
  execução, e as linhas vão para blocos diferentes da tabela.

**Decisão:** a ordem das linhas **não é uma propriedade do arquivo**. Não
entra `ORDER BY` em nenhum spool, e o teste de não-regressão é **por
conteúdo**.

---

## 5. Aprendizados do caminho

Estes pontos custaram tempo e vão se repetir nos outros spools.

1. **O byte que some na posição 4000.** O spool divide cada linha em
   `lignedetail1` (4000 caracteres) e `lignedetail2`, porque uma expressão SQL
   não passa de 4000. O SQL*Plus escreve **um espaço entre as duas colunas**.
   Do byte 4000 em diante, a posição real no arquivo é 1 a mais que a soma dos
   campos.
2. **Confira qual spool o shell realmente chama.** O shell antigo tinha uma
   segunda linha `spool_sql=`, sem comentário, apontando para o spool novo.
   Por um tempo, "o antigo" rodava o novo.
3. **O spool instalado não é necessariamente o do repositório.** A primeira
   diferença (8770 registros) era do ambiente, não do código.
4. **Base sem dados não testa nada.** Enquanto não havia registros Fora do
   NAT02, as variantes 4 a 8 estavam "certas" só porque ninguém as
   exercitava.
5. **Quando o mapeamento parecer desalinhado, procure primeiro um campo mal
   medido**, antes de criar exceções. A "zona dos derivados" escondeu 28
   campos por semanas e tinha como causa um único token de 1 byte contado
   como 10.

---

## 6. Resultado dos testes (`TESTES.sql`)

| Teste | O que verifica | Último resultado registrado |
|---|---|---|
| T1 Estrutura | 667 colunas; as alargadas com a precisão certa | OK (a lista agora tem **16** colunas) |
| T2 Package | package `VALID`, procedure com 3 parâmetros, `ALL_ERRORS` vazio | OK |
| T3 Volumetria | linhas na tabela = linhas que os 8 `WHERE` do spool devolvem | écart 0 |
| T4 Round-trip | o valor gravado reproduz o que o spool escreve (196 colunas × 200 engajamentos) | tudo conforme |

> O T4 cobre só a variante 1. As variantes 4 a 8 foram validadas pela
> comparação dos arquivos (item 4) e pela verificação estática do gerador.

---

## 7. O que falta para fechar o chamado

| # | Pendência | Tipo | Como resolver |
|---|---|---|---|
| 1 | Aceite da DSID de que "arquivos idênticos" = **mesmo conteúdo**, ignorando `MASYSDATE` e ordem das linhas | DSID | Mostrar o item 4. Confirmar que ninguém que lê o `CRRCORP.dat` depende da ordem |
| 2 | Aceite do desvio do plano: **6 SELECTs** em vez de 1 | DSID | Mostrar o item 3 |
| 3 | **Carga em duas fases.** O shell vPACT chama `'TOTAL'` de uma vez | entrega | Chamar `'NAT02'` no shell da M2 BTR e `'HORS_NAT02'` depois dos dados contábeis. Falta identificar esses shells na cadeia |
| 4 | **Nome do package.** O shell chama `PACK_ALIM_TAB_ENVOI_CRRV4_NEW` (cópia do DEV2); o plano pede `pack_alim_tab_envoi_crrv4` | entrega | Alinhar na instalação (consulta 8.2) |
| 5 | **`TABLESPACE`.** O DDL está com `DDR_DATA` (DEV2) | entrega | Trocar pelo de produção (consulta 8.1) |
| 6 | **`comparar_ficheiros.sh` não ordena** as linhas antes do `diff` | ajuste | Acrescentar `sort` (ver o item 10). Enquanto isso, usar os comandos do item 10 |
| 7 | **`P1 3.41` / `P1 3.43`.** O antigo faz `RPAD(C_ENR.CD_DEV_VTR,3)` sem `NVL`: um TRE502 sem devise **encurta a linha em 3 bytes** e desalinha o resto. O novo escreve 3 brancos | DSID | Rodar a consulta 8.7-b. Hoje dá 0 casos (se não, os arquivos teriam diferido). Confirmar que o comportamento novo é o desejado |
| 8 | Tipos de risco **sem dados** na base 20250531 (ex.: `INR101`) | teste | Validados só pelo gerador. Testar numa data de arrêté que os tenha (consulta 8.6) |
| 9 | **Estimativa de esforço para os outros spools**, pedida no chamado para as próximas MEPs | entregável | Não iniciado |
| 10 | Histórico no HCRR (`030_spool_data.sql` + `030_spool_9M.sql`) e documento SFD/STD único | não prioritário | Não iniciado |

> **Correção de uma pendência anterior.** Tinha sido listado para a DSID um
> defeito no campo composto `P1 4.4 + 4.5` do **TRE201** (o antigo escreve
> 20 caracteres onde deviam ser 22). Esse ramo **nunca executa**: os `WHERE`
> das variantes 1 e 2 excluem `TRE2%`. É código morto; não precisa de
> confirmação, só de registro. A consulta 8.7-a comprova.

---

## 8. Consultas para buscar as informações

Todas rodam no **SQL Developer**, no esquema do DEV2. Para rodar um bloco
inteiro, use **F5 (Run Script)**; para uma consulta só, **Ctrl+Enter**.

### 8.1 Estrutura da tabela

```sql
-- Quantidade de colunas. Esperado: 667
SELECT COUNT(*) AS qtd_colunas
  FROM ALL_TAB_COLUMNS
 WHERE TABLE_NAME = 'ENG_CORP_P1_BIS';

-- Tipo das colunas que mudaram nesta rodada. Esperado:
--   P1_3_20 = NUMBER(18,10) | P1_11_2 = NUMBER(18,10) | P1_3_7 = VARCHAR2(1)
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE
  FROM ALL_TAB_COLUMNS
 WHERE TABLE_NAME = 'ENG_CORP_P1_BIS'
   AND COLUMN_NAME IN ('P1_3_20', 'P1_11_2', 'P1_3_7');

-- Colunas com comentário. Esperado: 667
SELECT COUNT(*) AS qtd_com_comentario
  FROM ALL_COL_COMMENTS
 WHERE TABLE_NAME = 'ENG_CORP_P1_BIS'
   AND COMMENTS IS NOT NULL;

-- Ler o dicionário de dados (troque o filtro para o campo que procura)
SELECT COLUMN_NAME, COMMENTS
  FROM ALL_COL_COMMENTS
 WHERE TABLE_NAME = 'ENG_CORP_P1_BIS'
   AND COLUMN_NAME LIKE 'P1\_3\_8%' ESCAPE '\'
 ORDER BY COLUMN_NAME;

-- Procurar um campo pelo nome de negócio
SELECT COLUMN_NAME, COMMENTS
  FROM ALL_COL_COMMENTS
 WHERE TABLE_NAME = 'ENG_CORP_P1_BIS'
   AND UPPER(COMMENTS) LIKE '%MARK-TO-MARKET%';

-- Tablespace atual das duas tabelas (pendência 5)
SELECT OWNER, TABLE_NAME, TABLESPACE_NAME
  FROM ALL_TABLES
 WHERE TABLE_NAME IN ('ENG_CORP_P1', 'ENG_CORP_P1_BIS');
```

### 8.2 Package e procedure

```sql
-- Quais packages existem e se estão válidos (pendência 4: _NEW ou não?)
SELECT OWNER, OBJECT_NAME, OBJECT_TYPE, STATUS, LAST_DDL_TIME
  FROM ALL_OBJECTS
 WHERE OBJECT_NAME LIKE 'PACK_ALIM_TAB_ENVOI_CRRV4%'
 ORDER BY OBJECT_NAME, OBJECT_TYPE;

-- Erros de compilação. Esperado: nenhuma linha
SELECT NAME, TYPE, LINE, POSITION, TEXT
  FROM ALL_ERRORS
 WHERE NAME LIKE 'PACK_ALIM_TAB_ENVOI_CRRV4%'
 ORDER BY NAME, TYPE, SEQUENCE;

-- Parâmetros da procedure. Esperado: p_entite, p_masysdate, p_perimetre
SELECT PACKAGE_NAME, ARGUMENT_NAME, POSITION, DATA_TYPE, IN_OUT
  FROM ALL_ARGUMENTS
 WHERE OBJECT_NAME = 'P_ALIM_ENG_CORP_P1_BIS'
 ORDER BY PACKAGE_NAME, POSITION;

-- Quem usa a tabela nova
SELECT OWNER, NAME, TYPE
  FROM ALL_DEPENDENCIES
 WHERE REFERENCED_NAME = 'ENG_CORP_P1_BIS';
```

### 8.3 A base de origem

```sql
-- Data de arrêté disponível (hoje travada em 20250531)
SELECT DT_ARRETE, COUNT(*) AS qtd
  FROM ENG_CORP_P1
 GROUP BY DT_ARRETE
 ORDER BY DT_ARRETE;

-- População que o spool extrai, por perímetro e tipo de risco
SELECT CASE WHEN FLAG_HN = 'O' THEN 'HORS_NAT02' ELSE 'NAT02' END AS perimetro,
       CD_TYPE_RISQUE,
       COUNT(*) AS qtd
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
 GROUP BY CASE WHEN FLAG_HN = 'O' THEN 'HORS_NAT02' ELSE 'NAT02' END, CD_TYPE_RISQUE
 ORDER BY 1, 2;
```

### 8.4 A tabela nova: o que foi carregado

```sql
-- Linhas por perímetro e variante, e quando foram carregadas
SELECT CD_PERIMETRE, NO_VARIANTE, COUNT(*) AS qtd,
       MIN(DT_TRAITEMENT) AS primeira_carga, MAX(DT_TRAITEMENT) AS ultima_carga
  FROM ENG_CORP_P1_BIS
 GROUP BY CD_PERIMETRE, NO_VARIANTE
 ORDER BY NO_VARIANTE;

-- ID repetido. Esperado: nenhuma linha (as variantes não se sobrepõem)
SELECT ID_ENGAGEMENT, COUNT(*) AS qtd
  FROM ENG_CORP_P1_BIS
 GROUP BY ID_ENGAGEMENT
HAVING COUNT(*) > 1;
```

### 8.5 Volumetria: origem × tabela, por variante

A consulta abaixo aplica à `ENG_CORP_P1` os mesmos 8 `WHERE` do spool antigo,
com a entidade `'TOTAL'`. O resultado de cada variante tem de bater com o
`COUNT(*)` da consulta 8.4. É o mesmo que o T3 do `TESTES.sql` faz.

```sql
SELECT 1 AS variante, COUNT(*) AS esperado FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O'
   AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'
   AND NVL(C_ENR.FLAG_HN,'N') = 'N'
   AND (NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1 OR NVL(C_ENR.MNT_VR,0) >= 1)
   AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
   AND C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%'
UNION ALL
SELECT 2, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O'
   AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
   AND NVL(C_ENR.FLAG_HN,'N') = 'N'
   AND NVL(C_ENR.MNT_SOLD_K_A,0) >= 1
   AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
   AND C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%'
UNION ALL
SELECT 3, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O'
   AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
   AND NVL(C_ENR.FLAG_HN,'N') = 'N'
   AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
   AND C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%'
   AND (NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1 OR NVL(C_ENR.MNT_VR,0) >= 1)
UNION ALL
SELECT 4, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O' AND C_ENR.FLAG_HN = 'O'
   AND C_ENR.CD_TYPE_RISQUE IN ('TRE100')
UNION ALL
SELECT 5, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O' AND C_ENR.FLAG_HN = 'O'
   AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5')
UNION ALL
SELECT 6, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O' AND C_ENR.FLAG_HN = 'O'
   AND C_ENR.CD_TYPE_RISQUE IN ('EQU101')
UNION ALL
SELECT 7, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O' AND C_ENR.FLAG_HN = 'O'
   AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101')
UNION ALL
SELECT 8, COUNT(*) FROM ENG_CORP_P1 C_ENR
 WHERE A_EXTRAIRE = 'O' AND C_ENR.FLAG_HN = 'O'
   AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%'
ORDER BY 1;
```

### 8.6 Tipos de risco com e sem dados (pendência 8)

```sql
-- Fora do NAT02: o que existe nesta data de arrêté.
-- Tipo esperado que não aparecer aqui (ex.: INR101) só foi validado pelo gerador.
SELECT CD_TYPE_RISQUE, COUNT(*) AS qtd
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
   AND FLAG_HN = 'O'
 GROUP BY CD_TYPE_RISQUE
 ORDER BY CD_TYPE_RISQUE;
```

### 8.7 Pontos a confirmar

```sql
-- (a) TRE201 no NAT02. Os WHERE das variantes 1, 2 e 3 têm
--     "CD_TYPE_RISQUE NOT LIKE 'TRE2%'": todos os TRE201 contados aqui ficam
--     FORA do SELECT, e o ramo "CASE WHEN CD_TYPE_RISQUE = 'TRE201'" do campo
--     composto P1 4.4+4.5 nunca executa. Qualquer que seja o número, é código morto.
--     (No spool antigo: linhas 1080 e 1585, os WHERE; linha 638, o CASE.)
SELECT CD_TYPE_RISQUE, COUNT(*) AS qtd_excluidos_pelo_where
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
   AND NVL(FLAG_HN,'N') = 'N'
   AND CD_TYPE_RISQUE LIKE 'TRE2%'
 GROUP BY CD_TYPE_RISQUE;

-- (b) Pendência 7: TRE502 sem devise. Qualquer valor > 0 = linha desalinhada
--     no arquivo antigo (3 bytes a menos) e 3 brancos no arquivo novo.
SELECT COUNT(*)                                            AS total_tre502,
       SUM(CASE WHEN CD_DEV_VTR    IS NULL THEN 1 ELSE 0 END) AS sem_devise_vtr,    -- P1 3.41
       SUM(CASE WHEN CD_DEV_HYPOTH IS NULL THEN 1 ELSE 0 END) AS sem_devise_hypoth  -- P1 3.43
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
   AND NVL(FLAG_HN,'N') = 'N'
   AND CD_TYPE_RISQUE = 'TRE502';

-- (c) Spread dos derivados: justifica o alargamento de P1_11_2.
--     O arquivo só tem 4 dígitos inteiros: acima de 9999 o spool antigo já trunca.
--     spread_nulo > 0 = linhas que saem com sinal '-' e valor 0000.
SELECT COUNT(*)                   AS total_derivados,
       COUNT(*) - COUNT(MT_SPREAD) AS spread_nulo,
       MIN(MT_SPREAD)             AS menor,
       MAX(MT_SPREAD)             AS maior,
       MAX(ABS(MT_SPREAD))        AS maior_absoluto
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
   AND FLAG_HN = 'O'
   AND CD_TYPE_RISQUE LIKE '%VAR1%';

-- (d) Maturidade: o arquivo tem 2 dígitos inteiros e 4 decimais.
--     maior_absoluto >= 100 sai truncado nos dois spools.
SELECT CASE WHEN FLAG_HN = 'O' THEN 'HORS_NAT02' ELSE 'NAT02' END AS perimetro,
       MAX(ABS(MATURITE_EFF)) AS maior_absoluto,
       COUNT(*) - COUNT(MATURITE_EFF) AS maturidade_nula
  FROM ENG_CORP_P1
 WHERE A_EXTRAIRE = 'O'
 GROUP BY CASE WHEN FLAG_HN = 'O' THEN 'HORS_NAT02' ELSE 'NAT02' END;
```

### 8.8 Variante 8: os campos novos foram preenchidos?

```sql
-- COUNT(coluna) conta só os não nulos.
-- Os montantes (MtM, CVA, assiettes) são gravados com NVL(...,0), então
-- aparecem sempre preenchidos. Os códigos e indicadores podem vir nulos.
SELECT COUNT(*)         AS linhas_variante_8,
       COUNT(P1_3_80)   AS mtm,
       COUNT(P1_3_81)   AS devise_mtm,
       COUNT(P1_3_15)   AS ind_collateral,
       COUNT(P1_3_16)   AS ind_netting,
       COUNT(P1_3_86)   AS cva,
       COUNT(P1_11_1)   AS type_derive_credit,
       COUNT(P1_11_2)   AS spread,
       COUNT(P1_3_20)   AS maturidade,
       COUNT(P1_10_1)   AS nature_option,
       COUNT(P1_10_20)  AS type_swap
  FROM ENG_CORP_P1_BIS
 WHERE NO_VARIANTE = 8;

-- Olhar alguns registros lado a lado com a origem
SELECT b.ID_ENGAGEMENT,
       b.P1_3_80, p.MNT_MTM,
       b.P1_11_2, p.MT_SPREAD,
       b.P1_3_20, p.MATURITE_EFF
  FROM ENG_CORP_P1_BIS b
  JOIN ENG_CORP_P1     p ON p.ID_ENGAGEMENT = b.ID_ENGAGEMENT
 WHERE b.NO_VARIANTE = 8
   AND ROWNUM <= 20;
```

---

## 9. Como repetir o ciclo de teste

1. **Atualizar os arquivos** a partir do repositório.
2. **Recriar a tabela:** rodar `ENG_CORP_P1_BIS.sql` (F5).
3. **Compilar o package:** rodar `pack_alim_tab_envoi_crrv4.sql` (F5).
4. **Copiar o spool novo** para o diretório `$SQL` do ambiente.
5. **Rodar o `TESTES.sql`** (F5) e conferir T1 a T4.
   Se o T2 acusar `INVALID`, olhar a consulta 8.2.
6. **Rodar o shell antigo** (`030_CREATION_SPOOL_CRRCORP.sh`) e guardar o
   `CRRCORP.dat`.
7. **Rodar o shell novo** (`030_CREATION_SPOOL_CRRCORP_vPACT.sh`) e guardar
   o `CRRCORP.dat`.
8. **Comparar** os dois arquivos, como no item 10.

---

## 10. Como comparar dois arquivos

Rodar no servidor (ksh/bash). O comando:

- tira a linha de cabeçalho (`00;`), que traz um número de envio que muda
  sempre;
- esconde o `MASYSDATE` (bytes 27 a 38);
- ordena as linhas.

```bash
grep -v '^00;' CRRCORP_antigo.dat | sed -e 's/^\(.\{26\}\).\{12\}/\1############/' | sort > antigo.txt
```

```bash
grep -v '^00;' CRRCORP_novo.dat | sed -e 's/^\(.\{26\}\).\{12\}/\1############/' | sort > novo.txt
```

```bash
cmp antigo.txt novo.txt && echo "CONTEUDO IDENTICO"
```

Se aparecer diferença, este comando mostra as primeiras linhas que só existem
num dos lados:

```bash
diff antigo.txt novo.txt | head -20
```

> O `comparar_ficheiros.sh` do repositório faz o mesmo, **mas sem o `sort`**:
> como a ordem das linhas muda, ele sempre vai acusar diferença (pendência 6).

---

## 11. Glossário

| Termo | Significado |
|---|---|
| **Pavé** | Bloco de registros do arquivo. `P1` = engajamentos; também existem P2, M1, P9… |
| **Notice** | Planilha da especificação PACT V4.5 (aba `PACT Corp`), com nome, formato e tamanho de cada campo |
| **Régua V44** | Posição de cada campo na linha, reconstruída a partir da Notice. O spool implementa a versão V44.02 e a Notice do repositório é a V45 |
| **Variante** | Cada um dos 8 SELECTs do pavé P1 no spool antigo |
| **NAT02 / Fora do NAT02** | Os dois perímetros: NAT02 é carregado na M2 BTR; o Fora do NAT02, depois dos dados contábeis (`FLAG_HN = 'O'`) |
| **Arrêté** | Data de referência dos dados. No DEV2, travada em 20250531 |
| **MASYSDATE** | Data e hora do processamento, gravada pelo shell em todas as linhas |
| **lignedetail1/2** | As duas metades de cada linha no SELECT do spool (limite de 4000 caracteres por expressão SQL) |
| **Round-trip** | Teste que confere se gravar na tabela e formatar de volta reproduz o que o spool antigo escreve |
