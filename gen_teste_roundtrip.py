"""Gera teste_roundtrip.sql : compara a TABELA com o proprio SPOOL, na mesma data.

Nao precisa de ficheiro de referencia. Para cada coluna, corre lado a lado:

    expressao ORIGINAL do spool  sobre ENG_CORP_P1      (A)
    a MESMA expressao            sobre ENG_CORP_P1_BIS  (B)

Se a conversao esta correta, as duas strings sao identicas: o valor guardado na
tabela, reformatado, reproduz o que o spool escreve hoje. E a nao-regressao ao
nivel do campo — e corre sobre os MESMOS dados, sem o ruido de comparar arretes
diferentes.

So se comparam tokens que referenciam UMA unica coluna de origem: nesses, a
reconstrucao e uma substituicao textual segura (C_ENR.X -> B.COLUNA).
"""
import io
import re
import sys

from conv_spool import convert

NL = chr(10)
Q = chr(39)
N_LINHAS = 200

src = open('align_v44.py', encoding='utf-8').read()
src = src.split('# ------------------------------------------------------- alinhamento')[0]
ns = {}
buf = io.StringIO()
_o = sys.stdout
sys.stdout = buf
exec(src, ns)
sys.stdout = _o
tokenize, width, v44 = ns['tokenize'], ns['width'], ns['v44']

DDL = open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
COLS = set(re.findall(r'^\s+(P1_[A-Z0-9_]+)\s', DDL, re.M))

proc = open('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
bloco1 = proc.split('-- INSERT #1')[1].split('-- INSERT #2')[0]
ALIMENTADAS = set(re.findall(r'AS (P1_[A-Z0-9_]+)', bloco1))


def col_de(ref):
    if '(P1)' in ref:
        return 'P1_H_' + ref.replace('(P1)', '').strip().replace('.', '_')
    return 'P1_' + ref.split()[1].replace('.', '_')


pares = []
pos = 0
vistos = set()
for t in tokenize(589, 1068):
    w = width(t['raw'])
    if w is None:
        nf = next((f for f in v44 if f['start'] == pos), None)
        w = nf['len'] if nf else 0
    ach = [f for f in v44 if f['start'] < pos + w and f['start'] + f['len'] > pos]
    pos += w
    col = None
    if t.get('ref'):                       # ancora do spool: prevalece
        num = t['ref'].split()[1].replace('.', '_')
        for cand in ('P1_' + num, 'P1_H_' + num):
            if cand in COLS:
                col = cand
                break
    if col is None and len(ach) == 1:      # senao, a regua V44
        col = col_de(ach[0]['ref'])
    if col is None:
        continue
    if col not in ALIMENTADAS or col not in COLS or col in vistos:
        continue
    bruto = re.sub(r'\s+', ' ', t['raw']).strip().rstrip('|').strip()
    if ':MASYSDATE' in bruto.upper():
        continue                      # depende da execucao
    # a tabela guarda a expressao JA convertida; reconstruir = trocar essa
    # expressao por B.COLUNA dentro do token original (ex.: o spool faz
    # RPAD(ID_ENGAGEMENT||'_C',40) e a tabela ja guarda ID||'_C').
    conv = re.sub(r'\s+', ' ', convert(t['raw'])).strip()
    if conv and conv in bruto:
        refeito = bruto.replace(conv, 'B.' + col)
    else:
        fontes = set(re.findall(r'C_ENR\.([A-Za-z0-9_]+)', bruto))
        if len(fontes) != 1:
            continue                  # varias origens: reconstrucao insegura
        refeito = re.sub(r'C_ENR\.' + fontes.pop() + r'\b',
                         'B.' + col, bruto, flags=re.I)
    if refeito == bruto:
        continue
    vistos.add(col)
    pares.append((col, bruto, refeito))

print('colunas comparaveis (uma so origem): %d' % len(pares))

casos = []
for col, orig, refeito in pares:
    casos.append("         CASE WHEN NVL(%s,%s@%s) <> NVL(%s,%s@%s)"
                 % (orig, Q, Q, refeito, Q, Q)
                 + NL + "              THEN %s%s %s END ||" % (Q, col, Q))
corpo = NL.join(casos).rstrip('|').rstrip()

sql = [
    "-- =====================================================================",
    "-- NAO-REGRESSAO ao nivel do campo, sem ficheiro de referencia.",
    "--",
    "-- Para cada coluna corre-se, na MESMA linha e na MESMA data:",
    "--    a expressao do spool sobre ENG_CORP_P1      (A)",
    "--    a mesma expressao    sobre ENG_CORP_P1_BIS  (B)",
    "-- Se a conversao esta certa, as duas strings sao iguais.",
    "--",
    "-- Devolve as colunas que NAO reproduzem o spool. Vazio = tudo conforme.",
    "-- Sao %d colunas x %d engajamentos." % (len(pares), N_LINHAS),
    "--",
    "-- Prerequisito: package RECOMPILADO com a versao atual.",
    "-- =====================================================================",
    "SET LINESIZE 32000",
    "COLUMN id_engagement FORMAT A26",
    "COLUMN colunas_que_nao_reproduzem FORMAT A120",
    "",
    "SELECT C_ENR.ID_ENGAGEMENT,",
    corpo,
    "           AS colunas_que_nao_reproduzem",
    "  FROM ENG_CORP_P1 C_ENR",
    "  JOIN ENG_CORP_P1_BIS B ON B.P1_H_1_11 = C_ENR.ID_ENGAGEMENT || " + Q + "_C" + Q,
    "  -- so engajamentos com UMA linha na tabela: evita cruzar variantes",
    "  JOIN (SELECT P1_H_1_11 FROM ENG_CORP_P1_BIS",
    "         GROUP BY P1_H_1_11 HAVING COUNT(*) = 1) U",
    "    ON U.P1_H_1_11 = B.P1_H_1_11",
    " WHERE C_ENR.A_EXTRAIRE = " + Q + "O" + Q,
    "   AND NVL(C_ENR.CD_ARR_PAIEMENT," + Q + "N" + Q + ") = " + Q + "N" + Q,
    "   AND NVL(C_ENR.FLAG_HN," + Q + "N" + Q + ")         = " + Q + "N" + Q,
    "   AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1 OR NVL(C_ENR.MNT_VR,0) >= 1 )",
    "   AND C_ENR.CD_TYPE_RISQUE NOT IN (" + Q + "TRE100" + Q + "," + Q + "SIG201" + Q
    + "," + Q + "EQU101" + Q + "," + Q + "VAR104" + Q + ")",
    "   AND ROWNUM <= %d;" % N_LINHAS,
]
open('teste_roundtrip.sql', 'w', encoding='utf-8').write(NL.join(sql) + NL)
print('-> teste_roundtrip.sql')
