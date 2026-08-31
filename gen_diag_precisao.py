"""Gera diag_precisao.sql : encontra as colunas NUMBER(p,s) pequenas demais.

ORA-01438 acontece quando a parte INTEIRA do valor nao cabe em (p - s)
digitos. A escala nao causa erro (o Oracle arredonda). Este script mede,
com UMA passagem por variante, os digitos inteiros reais na origem e
devolve a lista das colunas que estouram.
"""
import re

NL = chr(10)

DDL = open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
TIPOS = {}
for m in re.finditer(r'^\s+(P1_[A-Z0-9_]+)\s+NUMBER\((\d+)(?:,\s*(\d+))?\)', DDL, re.M):
    TIPOS[m.group(1)] = (int(m.group(2)), int(m.group(3) or 0))

PROC = open('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
blocos = re.split(r'    -- INSERT #(\d)', PROC)

partes = []
ncol = 0
for i in range(1, len(blocos), 2):
    num = int(blocos[i])
    corpo = blocos[i + 1]
    sel = corpo.split('SELECT', 1)[1]
    where = sel.split('WHERE', 1)[1].split(';')[0].strip()
    where = where.replace('p_entite', "'TOTAL'")
    sel = sel.split('FROM ENG_CORP_P1')[0]
    casos = []
    for linha in sel.split(NL):
        m = re.match(r'\s+(.*?)\s+AS (P1_[A-Z0-9_]+),?\s+--', linha)
        if not m:
            continue
        expr, col = m.group(1).strip(), m.group(2)
        if col not in TIPOS:
            continue
        p_, s_ = TIPOS[col]
        casos.append(
            "         CASE WHEN MAX(LENGTH(TO_CHAR(TRUNC(ABS(NVL(%s,0)))))) > %d"
            % (expr, p_ - s_)
            + NL + "              THEN '%s(%d,%d) ' END ||" % (col, p_, s_))
        ncol += 1
    if not casos:
        continue
    corpo_sel = NL.join(casos).rstrip('|').rstrip()
    partes.append(
        "  SELECT %d AS ins," % num + NL + corpo_sel + NL
        + "           AS colunas_que_estouram" + NL
        + "    FROM ENG_CORP_P1 C_ENR" + NL
        + "   WHERE " + where)

sql = [
    "-- Diagnostico ORA-01438 : colunas NUMBER(p,s) pequenas demais.",
    "-- Uma passagem por variante. Devolve as colunas cuja parte INTEIRA real",
    "-- nao cabe em (p - s) digitos. Coluna vazia = variante sem problema.",
    "SET LINESIZE 32000",
    "COLUMN colunas_que_estouram FORMAT A150",
    "",
    (NL + "UNION ALL" + NL).join(partes) + NL + " ORDER BY 1;",
]
open('diag_precisao.sql', 'w', encoding='utf-8').write(NL.join(sql) + NL)
print('variantes: %d | colunas NUMBER verificadas: %d' % (len(partes), ncol))
print('-> diag_precisao.sql')
