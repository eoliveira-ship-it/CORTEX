# CORTEX — CRR Corporate / PACT V4.5

Trabalho sobre a cadeia de declaração de riscos **CRR Corporate** (Oracle PL/SQL + spool),
cobrindo três tickets SIRL. O objetivo central (SIRL-1224) é **tirar as regras de negócio
de dentro do spool** e passá-las para uma tabela alimentada por uma procedure.

## Estado atual

| Ticket | Assunto | Estado |
|---|---|---|
| **SIRL-1224** | Tabela `ENG_CORP_P1_BIS` + procedure de alimentação | 🟡 em curso |
| **SIRL-1222** | Separador `;` em `CRRCORP.dat` / `CRRADAPT.dat` | ⬜ não iniciado |
| **SIRL-1223** | Tamanhos: `P1 21.65` 5→50, `P3C 21.65`, filler BALE4 1132→1087 | ⬜ não iniciado |
| — | SFD/STD único do projeto | ⬜ não iniciado |

Detalhe do SIRL-1224: [docs/SIRL-1224.md](docs/SIRL-1224.md)

## ⚠️ Achado importante — ecart de versão

O `spool.sql` implementa a notice **V44.02**; a notice deste repo é **V45.00**.
Diferença medida: **519 bytes**. Isto invalida o mapeamento automático por posição
e condiciona o SIRL-1224. Ver [docs/ECART-VERSAO.md](docs/ECART-VERSAO.md).

## Ficheiros

### Entregáveis (produzidos)

| Ficheiro | Conteúdo |
|---|---|
| `ENG_CORP_P1_BIS.sql` | DDL da tabela: 662 colunas P1 + 4 técnicas |
| `pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql` | Procedure isolada: `TRUNCATE` + 8 `INSERT` |
| `pack_alim_tab_envoi_crrv4.sql` | Package completo (spec + body) com a procedure integrada |
| `erro` | Log de compilação Oracle — erros já corrigidos |
| `excel` | Fórmula Excel que gera o DDL a partir da notice |
| `test_P_ALIM_ENG_CORP_P1_BIS.sql` | Script de teste da procedure (volumetria + controlo esperado/inserido) |
| `gen_procedure.py` / `conv_spool.py` | Geradores (regeneram a procedure e o teste a partir do spool) |

### Fonte (entrada)

| Ficheiro | Conteúdo |
|---|---|
| `spool.sql` | Cópia do `030_spool_Extract_CRRCORP.sql` (5.662 linhas, notice V44.02) |
| `Notice PACTV4.5_v1.0.xlsx` | Notice PACT V4.5 Corporate — aba `PACT Corp` é a fonte da estrutura |
| `ticket 1224`, `plan 1224`, `1222`, `1223`, `plano` | Tickets e SFG técnicas |
| `1224.png` | Diagrama do fluxo SIRL-1224 |

## Regenerar a procedure

Depois de qualquer alteração ao `spool.sql`:

```bash
python gen_procedure.py
```

Requer `openpyxl` (`pip install openpyxl`). O script relê os 8 SELECT do spool,
converte as expressões e reescreve o ficheiro da procedure.
