"""Gera 030_spool_Extract_CRRCORP_vPACT.sql : o spool sem regras de negocio.

O spool atual produz o pave P1 com OITO select sobre ENG_CORP_P1, cada um com
as suas regras. Este gerador substitui-os por select sobre ENG_CORP_P1_BIS,
onde as regras ja estao aplicadas: fica so a FORMATACAO (RPAD/LPAD/TO_CHAR e
as funcoes pack_utilitaire.F_FORMAT_*), que e o que um spool deve fazer.

COMO SE CONSTROI CADA CAMPO
---------------------------
Percorre-se a lista de tokens do select de CADA variante emitida (1 para o
NAT02, 4 a 8 para o Hors NAT02). Para cada token:

  * sem coluna de origem (RPAD(' ',n), literais) -> copia-se tal e qual;
  * com coluna de origem -> troca-se a expressao do VALOR pela coluna da
    tabela e mantem-se o invólucro de formatacao. E a mesma reconstrucao que
    o T4 do TESTES.sql verifica campo a campo;
  * dez tokens nao se deixam reconstruir por substituicao textual (o valor
    vem de varias colunas de origem). Estao em EXPLICITAS, escritos a mao.

ORDEM DOS REGISTOS
------------------
Hoje o ficheiro traz as variantes 1-3 antes dos paves P2/M1/P9 e as 4-8
depois. Geram-se SEIS select, nos dois lugares que os blocos originais
ocupavam: um para o NAT02 (as variantes 1-3 partilham o layout) e cinco para
o Hors NAT02, um por variante -- porque as variantes 4 a 8 escrevem campos
diferentes nas mesmas posicoes da linha. Assim o ficheiro sai na mesma ordem
e a nao-regressao e um diff simples.
"""
import collections
import io
import re
import sys

from conv_spool import convert
from layout_variantes import (VARIANTES, DESVIO_A_PARTIR_DE,
                              MAPEAMENTO_VARIANTE_8, VARIANTES_DO_COMPOSTO)

NL = chr(10)
Q = chr(39)
TAB = 'ENG_CORP_P1_BIS'
FONTE = '030_spool_Extract_CRRCORP.sql'
SAIDA = '030_spool_Extract_CRRCORP_vPACT.sql'

# ------------------------------------------------------------------ regua
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


def alimentadas(n):
    """Colunas que o INSERT #n enche. Cada variante enche um conjunto
    diferente -- ler so o do INSERT #1 fazia o spool procurar, nas linhas
    Hors NAT02, colunas que nunca ninguem tinha preenchido."""
    b = proc.split('-- INSERT #%d' % n)[1]
    if n < 8:
        b = b.split('-- INSERT #%d' % (n + 1))[0]
    return set(re.findall(r'AS (P1_[A-Z0-9_]+)', b))


ALIM = {n: alimentadas(n) for n, _, _, _ in VARIANTES}


def guardadas(n):
    """{coluna: expressao} que o INSERT #n guarda."""
    b = proc.split('-- INSERT #%d' % n)[1]
    if n < 8:
        b = b.split('-- INSERT #%d' % (n + 1))[0]
    d = {}
    for m in re.finditer(r'^\s*(\S.*?)\s+AS (P1_[A-Z0-9_]+),?\s*--', b, re.M):
        d.setdefault(m.group(2), m.group(1).strip())
    return d


GUARD = {n: guardadas(n) for n, _, _, _ in VARIANTES}



def col_notice(f):
    r = f['ref']
    if '(P1)' in r:
        return 'P1_H_' + r.replace('(P1)', '').strip().replace('.', '_')
    return 'P1_' + r.split()[1].replace('.', '_')


def resolve(t, off, w, variante):
    if t.get('ref'):
        num = t['ref'].split()[1].replace('.', '_')
        for c in ('P1_' + num, 'P1_H_' + num):
            if c in COLS:
                return c
    if variante == 8 and off in MAPEAMENTO_VARIANTE_8:
        c = MAPEAMENTO_VARIANTE_8[off]
        return c if c in COLS else None
    p = off
    p += 1 if p >= DESVIO_A_PARTIR_DE else 0
    ex = [f for f in v44 if f['start'] == p and f['len'] == w]
    ca = ex if len(ex) == 1 else [f for f in v44
                                  if f['start'] < p + w and f['start'] + f['len'] > p]
    if len(ca) == 1:
        c = col_notice(ca[0])
        return c if c in COLS else None
    return None


# Tokens que escrevem DOIS campos da notice numa so expressao. A procedure
# guarda-os em duas colunas; aqui volta a juntar-se. O NULL de uma marca o
# branco das duas.
COMPOSTAS = {
    'TRE201':
        "CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 22)" + NL
        + "            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4)"
        + "||RPAD(P1_4_5, 3) END",
    'TRE401':
        "CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 22)" + NL
        + "            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14)"
        + "||RPAD(P1_4_15, 3) END",
}

# Tokens cujo valor vem de VARIAS colunas de origem: a substituicao textual
# nao e segura, escreve-se a formatacao a mao sobre a coluna. A chave e o
# offset do campo na linha.
# Tokens cujo valor vem de VARIAS colunas de origem: a substituicao textual
# nao e segura, escreve-se a formatacao a mao sobre a coluna guardada.
# A chave e (variante, offset) -- o mesmo offset noutra variante e outro campo.
EXPLICITAS = {
    # ---- variante 1 (e, por partilharem layout, 2 e 3) -------------------
    (1, 451):  "NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))",
    (1, 581):  "CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19)"
               " ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END",
    (1, 712):  "CASE WHEN P1_3_40 IS NULL THEN RPAD(' ', 19)"
               " ELSE pack_utilitaire.f_format_montant_bis2(P1_3_40) END",
    (1, 731):  "RPAD(NVL(P1_3_41, ' '), 3)",
    (1, 734):  "CASE WHEN P1_3_42 IS NULL THEN RPAD(' ', 19)"
               " ELSE pack_utilitaire.f_format_montant_bis2(P1_3_42) END",
    (1, 753):  "RPAD(NVL(P1_3_43, ' '), 3)",
    (1, 2911): "RPAD(NVL(P1_23_7, ' '), 40)",
    (1, 4205): "LPAD(P1_31_17, 5, '0')",
    (1, 4211): "LPAD(P1_31_18, 5, '0')",
    (1, 4936): "RPAD(NVL(P1_21_31, ' '), 3)",

    # ---- variante 4 ------------------------------------------------------
    (4, 4936): "RPAD(NVL(P1_21_31, ' '), 3)",

    # ---- variante 5 ------------------------------------------------------
    # As datas condicionadas: a procedure ja guarda NULL quando a condicao
    # nao se verifica, por isso aqui basta o NULL -> brancos.
    (5, 440):  "NVL(TO_CHAR(P1_21_2, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 451):  "NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 481):  "CASE WHEN P1_4_4 IS NULL THEN RPAD(' ', 19)"
               " ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END",
    (5, 581):  "CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19)"
               " ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END",
    (5, 600):  "RPAD(NVL(P1_4_7, ' '), 3)",
    (5, 2186): "NVL(TO_CHAR(P1_21_10, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 2194): "NVL(TO_CHAR(P1_21_11, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 2202): "NVL(TO_CHAR(P1_21_12, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 2210): "NVL(TO_CHAR(P1_21_13, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 2218): "NVL(TO_CHAR(P1_21_14, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 2226): "NVL(TO_CHAR(P1_21_15, 'YYYYMMDD'), RPAD(' ', 8))",
    (5, 4205): "LPAD(P1_31_17, 5, '0')",
    (5, 4211): "LPAD(P1_31_18, 5, '0')",
    (5, 4936): "RPAD(NVL(P1_21_31, ' '), 3)",

    # ---- variante 8 ------------------------------------------------------
    # A marge so existe quando a taxa e variavel ou revisavel; a procedure
    # guarda NULL nos outros casos.
    (8, 3922): "CASE WHEN P1_30_17 IS NULL THEN RPAD(' ', 10)"
               " ELSE pack_utilitaire.f_format_taux(P1_30_17) END",
    (8, 3940): "CASE WHEN P1_30_20 IS NULL THEN RPAD(' ', 10)"
               " ELSE pack_utilitaire.f_format_taux(P1_30_20) END",
}


def norm(s):
    return re.sub(r'\s+', '', s).upper()


def expressao(t, off, w, variante):
    """Devolve (expr_vPACT, coluna_ou_None), ou (None, None) se nao souber."""
    raw = re.sub(r'\s+', ' ', t['raw']).strip().rstrip('|').strip()
    for tipo, expr in COMPOSTAS.items():
        if variante not in VARIANTES_DO_COMPOSTO[tipo]:
            continue
        if norm("CD_TYPE_RISQUE='%s'" % tipo) in norm(raw):
            return expr, 'composta'
    if (variante, off) in EXPLICITAS:
        return EXPLICITAS[(variante, off)], 'explicita'
    if not re.search(r'C_ENR\.', raw, re.I) and ':MASYSDATE' not in raw.upper():
        return raw, None                       # filler ou literal: copia
    if ':MASYSDATE' in raw.upper():
        return raw, None                       # a data de extracao vem do shell
    col = resolve(t, off, w, variante)
    if col is None or col not in ALIM[variante]:
        return None, None      # o chamador decide: branco da largura certa
    conv = re.sub(r'\s+', ' ', convert(t['raw'])).strip()
    # So se troca o valor isolado pelo convert quando e EXATAMENTE o que a
    # procedure guarda. O convert nao conhece ABS/TRUNC/MOD como formato: em
    # LPAD(ABS(TRUNC(C_ENR.X)),2,'0') isolava ABS(TRUNC(C_ENR.X)) e o spool
    # ficava LPAD(col,2,'0') -- a maturidade 0.0055 saia '.0.005'.
    if conv and conv in raw and norm(conv) == norm(GUARD[variante].get(col, '')):
        return raw.replace(conv, col), col
    fontes = set(x.upper() for x in re.findall(r'C_ENR\.([A-Za-z0-9_]+)', raw, re.I))
    if len(fontes) == 1:
        return re.sub(r'C_ENR\.' + fontes.pop() + r'\b', col, raw, flags=re.I), col
    return None, None


def percorre(a, b2):
    """Tokens de um SELECT com o seu offset e largura."""
    out = []
    pos = 0
    for t in tokenize(a, b2):
        w = width(t['raw'])
        if w is None:
            nf = next((f for f in v44 if f['start'] == pos), None)
            w = nf['len'] if nf else 0
        out.append((pos, w, t))
        pos += w
    return out


# --------------------------------------------------- validacao e cortes
# So se geram blocos para estas: o NAT02 sai todo do layout da variante 1
# (as 1, 2 e 3 partilham-no) e o Hors NAT02 leva uma por variante.
EMITIDAS = (1, 4, 5, 6, 7, 8)

TOKENS = {n: percorre(a, b2) for n, _, a, b2 in VARIANTES}

# Tokens de dados sem coluna onde guardar o valor. Nao impedem a geracao --
# saem como branco da largura certa, que mantem a linha alinhada -- mas sao
# listados, porque cada um e um campo que o ficheiro novo perde.
SEM_COLUNA = {}
for n in EMITIDAS:
    for off, w, t in TOKENS[n]:
        if expressao(t, off, w, n)[0] is None:
            SEM_COLUNA[(n, off)] = w

if SEM_COLUNA:
    print('campos sem coluna (saem em branco): %d' % len(SEM_COLUNA))
    for n in EMITIDAS:
        q = [o for (v, o) in SEM_COLUNA if v == n]
        if q:
            print('   variante %d: %d campos' % (n, len(q)))

# Verificacao: nenhuma funcao do token original pode desaparecer, a nao ser as
# que a procedure ja aplicou ao guardar. Apanha, sem base de dados, o caso do
# LPAD(ABS(TRUNC(x)),2,'0') que virava LPAD(col,2,'0').
FUNCOES = re.compile(r'\b(ABS|TRUNC|MOD|SUBSTR|LPAD|RPAD|TO_CHAR|UPPER|NVL|CASE|F_FORMAT_[A-Z0-9_]+)\b', re.I)


def funcoes(s):
    return collections.Counter(x.upper() for x in FUNCOES.findall(s))


PERDAS = []
for n in EMITIDAS:
    for off, w, t in TOKENS[n]:
        e, col = expressao(t, off, w, n)
        if not col or col in ('composta', 'explicita') or col not in GUARD[n]:
            continue
        falta = (funcoes(t['raw']) - funcoes(GUARD[n][col])) - funcoes(e)
        if falta:
            PERDAS.append((n, off, col, sorted(falta), e))
if PERDAS:
    for p in PERDAS:
        print('FORMATO PERDIDO variante %d pos %d %s: %s -> %s' % p)
    sys.exit(1)


def corte(n):
    ts = [t for _, _, t in TOKENS[n]]
    return next(k for k in range(len(ts) - 1)
                if ts[k]['s'] == ts[k + 1]['s'] and ts[k]['e'] == ts[k + 1]['e'])


CORTE = {n: corte(n) for n, _, _, _ in VARIANTES}


def bloco(variante, filtro, comentario):
    """Um SELECT sobre a tabela, com a lista de campos DESTA variante."""
    l1, l2 = [], []
    n_col = 0
    for k, (off, w, t) in enumerate(TOKENS[variante]):
        e, col = expressao(t, off, w, variante)
        if e is None:
            e = "RPAD(' ', %d)" % w
            col = None
        elif col:
            n_col += 1
        alvo = l1 if k <= CORTE[variante] else l2
        marca = ('-- pos %-5d %s' % (off, col)) if col else ('-- pos %-5d' % off)
        alvo.append('       %s||   %s' % (e, marca))
    for L_ in (l1, l2):
        L_[-1] = re.sub(r'\|\|(\s+--)', r'  \1', L_[-1])
    print('   %-46s %3d campos com coluna' % (comentario[:46], n_col))
    risca = '-' * 120
    return (risca + NL
            + '-- ' + comentario + NL
            + risca + NL
            + 'select' + NL + NL.join(l1) + NL
            + '     as lignedetail1,' + NL
            + NL.join(l2) + NL
            + '     as lignedetail2' + NL
            + '  from ' + TAB + NL
            + ' where ' + filtro + NL
            + '   and (P1_H_0_2 = :ENTITE or :ENTITE = ' + Q + 'TOTAL' + Q + ')' + NL
            + ' order by NO_VARIANTE;' + NL)

# ------------------------------------------------------------- montagem final
orig = open(FONTE, encoding='latin-1').read().split(NL)

# blocos P1 a substituir (1-based, inclusive) : do 'select' ao ';' do WHERE
BLOCOS = [(590, 1081), (1089, 1586), (1592, 2082),
          (2894, 3456), (3462, 4020), (4026, 4600), (4606, 5056), (5061, 5635)]

def inicio_do_bloco(s):
    """Recua do 'select' ate ao inicio do cabecalho de seccao (as tres linhas
    -- Exx: ...), para nao deixar orfaos a anunciar blocos que ja nao existem."""
    k = s - 1                       # 0-based da linha do select
    while k > 0 and not orig[k - 1].strip():
        k -= 1
    while k > 0 and orig[k - 1].lstrip().startswith('--'):
        k -= 1
    return k + 1                    # 1-based


BLOCOS = [(inicio_do_bloco(a), b) for a, b in BLOCOS]

novo = []
i = 0
while i < len(orig):
    ln = i + 1
    alvo = next((b for b in BLOCOS if b[0] == ln), None)
    if alvo is None:
        novo.append(orig[i])
        i += 1
        continue
    if alvo == BLOCOS[0]:
        # As variantes 1, 2 e 3 partilham o layout -- provado por dados:
        # 113368 registos byte a byte iguais. Um SELECT chega para as tres.
        novo.append(bloco(1, "CD_PERIMETRE = 'NAT02'",
                          'PAVE P1 - perimetre NAT02 (substitui E04a/E04b/E04c)'))
    elif alvo == BLOCOS[3]:
        # As variantes 4 a 8 NAO partilham o layout entre si nem com a 1:
        # cada uma escreve campos diferentes nas mesmas posicoes. Cada uma
        # leva o seu SELECT, com a sua lista de campos, pela mesma ordem em
        # que o spool antigo as escreve.
        for n_var in (4, 5, 6, 7, 8):
            novo.append(bloco(n_var, 'NO_VARIANTE = %d' % n_var,
                              'PAVE P1 - Hors NAT02, variante %d (substitui E05%s)'
                              % (n_var, 'abcde'[n_var - 4])))
    i = alvo[1]          # salta o bloco original

CAB = [
    '-- =====================================================================',
    '-- 030_spool_Extract_CRRCORP_vPACT.sql          (SIRL-1224)',
    '--',
    '-- Versao vPACT do 030_spool_Extract_CRRCORP.sql : o pave P1 deixa de ser',
    '-- calculado aqui. As regras de negocio passaram para a procedure',
    '-- pack_alim_tab_envoi_crrv4.P_ALIM_ENG_CORP_P1_BIS, que alimenta a',
    '-- tabela ENG_CORP_P1_BIS. Aqui fica so a formatacao.',
    '--',
    '-- Os 8 select sobre ENG_CORP_P1 dao lugar a 6 select sobre a tabela:',
    '--   1 para o perimetro NAT02  (variantes 1-3, que partilham o layout,',
    '--     o que esta provado por dados: 113368 registos byte a byte iguais)',
    '--   5 para o Hors NAT02       (variantes 4-8, uma cada, porque cada uma',
    '--     escreve campos DIFERENTES nas mesmas posicoes da linha)',
    '--',
    '-- Ficam nos dois lugares que os blocos originais ocupavam, porque o',
    '-- ficheiro traz as variantes 1-3 antes dos paves P2/M1/P9 e as 4-8',
    '-- depois. Assim o ficheiro sai na mesma ordem.',
    '--',
    '-- Os restantes paves (C1/C5, P2, M1, P9) ficam exatamente como estavam.',
    '--',
    '-- GERADO por gen_spool_vpact.py -- nao editar a mao.',
    '-- =====================================================================',
]
# escreve-se em latin-1, como o original: assim tudo o que nao e o pave P1
# fica byte a byte igual e um diff entre os dois spools mostra so o que mudou.
open(SAIDA, 'w', encoding='latin-1', errors='replace').write(
    NL.join(CAB) + NL + NL.join(novo) + NL)
# O TESTES.sql compara, campo a campo, a expressao ORIGINAL do spool com a
# expressao vPACT. Escreve-se aqui a lista para o gen_testes.py a ler: assim o
# teste verifica exatamente o que o spool novo emite, sem duplicar a logica.
# So a variante 1: e a unica com dados suficientes para o teste (os 200
# engajamentos que o T4 usa vem todos do perimetro NAT02).
import json

pares = []
for off, w, t in TOKENS[1]:
    e, col = expressao(t, off, w, 1)
    if not col:
        continue
    pares.append({'off': off, 'col': col,
                  'orig': re.sub(r'\s+', ' ', t['raw']).strip().rstrip('|').strip(),
                  'vpact': re.sub(r'\s+', ' ', e).strip()})
json.dump(pares, open('pares_vpact.json', 'w', encoding='utf-8'), indent=1)
print('pares para o teste  : %d  -> pares_vpact.json' % len(pares))
print('-> %s' % SAIDA)
