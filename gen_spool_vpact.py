"""Gera 030_spool_Extract_CRRCORP_vPACT.sql : o spool sem regras de negocio.

O spool atual produz o pave P1 com OITO select sobre ENG_CORP_P1, cada um com
as suas regras. Este gerador substitui-os por select sobre ENG_CORP_P1_BIS,
onde as regras ja estao aplicadas: fica so a FORMATACAO (RPAD/LPAD/TO_CHAR e
as funcoes pack_utilitaire.F_FORMAT_*), que e o que um spool deve fazer.

COMO SE CONSTROI CADA CAMPO
---------------------------
Percorre-se a lista de tokens do select da variante 1 -- o layout e comum as
oito variantes; verificou-se no ficheiro real que as 120789 linhas, incluindo
as VAR104 da variante 8, trazem o tipo de risco nos bytes 290..296. Para cada
token:

  * sem coluna de origem (RPAD(' ',n), literais) -> copia-se tal e qual;
  * com coluna de origem -> troca-se a expressao do VALOR pela coluna da
    tabela e mantem-se o invólucro de formatacao. E a mesma reconstrucao que
    o T4 do TESTES.sql verifica campo a campo;
  * dez tokens nao se deixam reconstruir por substituicao textual (o valor
    vem de varias colunas de origem). Estao em EXPLICITAS, escritos a mao.

ORDEM DOS REGISTOS
------------------
Hoje o ficheiro traz as variantes 1-3 antes dos paves P2/M1/P9 e as 4-8
depois. Um unico select mudaria essa ordem. Por isso geram-se DOIS select --
um por perimetro, cada um no lugar que o bloco original ocupava -- ambos com
ORDER BY NO_VARIANTE. Assim o ficheiro sai na mesma ordem e a nao-regressao
pode ser um diff simples.
"""
import io
import re
import sys

from conv_spool import convert

NL = chr(10)
Q = chr(39)
TAB = 'ENG_CORP_P1_BIS'
FONTE = 'spool.sql'
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
ALIM = set(re.findall(r'AS (P1_[A-Z0-9_]+)', proc.split('-- INSERT #1')[1]
                      .split('-- INSERT #2')[0]))

DESVIO_A_PARTIR_DE = 4000   # o separador lignedetail1/2; ver gen_procedure.py


def col_notice(f):
    r = f['ref']
    if '(P1)' in r:
        return 'P1_H_' + r.replace('(P1)', '').strip().replace('.', '_')
    return 'P1_' + r.split()[1].replace('.', '_')


def resolve(t, off, w):
    if t.get('ref'):
        num = t['ref'].split()[1].replace('.', '_')
        for c in ('P1_' + num, 'P1_H_' + num):
            if c in COLS:
                return c
    d = 1 if off >= DESVIO_A_PARTIR_DE else 0
    p = off + d
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
    "CD_TYPE_RISQUE='TRE201'":
        "CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 22)" + NL
        + "            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4)"
        + "||RPAD(P1_4_5, 3) END",
    "CD_TYPE_RISQUE='TRE401'":
        "CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 22)" + NL
        + "            ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14)"
        + "||RPAD(P1_4_15, 3) END",
}

# Tokens cujo valor vem de VARIAS colunas de origem: a substituicao textual
# nao e segura, escreve-se a formatacao a mao sobre a coluna. A chave e o
# offset do campo na linha.
EXPLICITAS = {
    451:  "NVL(TO_CHAR(P1_5_3, 'YYYYMMDD'), RPAD(' ', 8))",
    581:  "CASE WHEN P1_4_6 IS NULL THEN RPAD(' ', 19)"
          " ELSE pack_utilitaire.f_format_montant_bis2(P1_4_6) END",
    712:  "CASE WHEN P1_3_40 IS NULL THEN RPAD(' ', 19)"
          " ELSE pack_utilitaire.f_format_montant_bis2(P1_3_40) END",
    731:  "RPAD(NVL(P1_3_41, ' '), 3)",
    734:  "CASE WHEN P1_3_42 IS NULL THEN RPAD(' ', 19)"
          " ELSE pack_utilitaire.f_format_montant_bis2(P1_3_42) END",
    753:  "RPAD(NVL(P1_3_43, ' '), 3)",
    2911: "RPAD(NVL(P1_23_7, ' '), 40)",
    4205: "LPAD(P1_31_17, 5, '0')",
    4211: "LPAD(P1_31_18, 5, '0')",
    4936: "RPAD(NVL(P1_21_31, ' '), 3)",
}


def norm(s):
    return re.sub(r'\s+', '', s).upper()


def expressao(t, off, w):
    """Devolve (expr_vPACT, coluna_ou_None). Levanta se nao souber."""
    raw = re.sub(r'\s+', ' ', t['raw']).strip().rstrip('|').strip()
    for chave, expr in COMPOSTAS.items():
        if norm(chave) in norm(raw):
            return expr, 'composta'
    if off in EXPLICITAS:
        return EXPLICITAS[off], 'explicita'
    if not re.search(r'C_ENR\.', raw, re.I) and ':MASYSDATE' not in raw.upper():
        return raw, None                       # filler ou literal: copia
    if ':MASYSDATE' in raw.upper():
        return raw, None                       # a data de extracao vem do shell
    col = resolve(t, off, w)
    if col is None or col not in ALIM:
        return None, None
    conv = re.sub(r'\s+', ' ', convert(t['raw'])).strip()
    if conv and conv in raw:
        return raw.replace(conv, col), col
    fontes = set(x.upper() for x in re.findall(r'C_ENR\.([A-Za-z0-9_]+)', raw, re.I))
    if len(fontes) == 1:
        return re.sub(r'C_ENR\.' + fontes.pop() + r'\b', col, raw, flags=re.I), col
    return None, None


# ------------------------------------------------------- construcao da lista
linhas = []
pos = 0
n_col = n_fil = 0
falhas = []
for t in tokenize(589, 1068):
    w = width(t['raw'])
    if w is None:
        nf = next((f for f in v44 if f['start'] == pos), None)
        w = nf['len'] if nf else 0
    off = pos
    pos += w
    e, col = expressao(t, off, w)
    if e is None:
        falhas.append((off, w, re.sub(r'\s+', ' ', t['raw']).strip()[:70]))
        continue
    if col:
        n_col += 1
    else:
        n_fil += 1
    marca = ('-- pos %-5d [%s]' % (off, col)) if col else ('-- pos %-5d' % off)
    linhas.append('       %s||   %s' % (e, marca))

if falhas:
    print('TOKENS NAO RESOLVIDOS: %d' % len(falhas))
    for o, w, r in falhas:
        print('   off=%-5d w=%-3d %s' % (o, w, r))
    raise SystemExit('spool nao gerado: ha campos sem origem')

corpo = NL.join(linhas)
corpo = corpo.rstrip()
corpo = re.sub(r'\|\|(\s*--[^\n]*)$', r'  \1', corpo)   # tira o ultimo ||

# lignedetail1 / lignedetail2 : o spool parte a linha em duas colunas porque
# uma expressao SQL nao passa dos 4000 caracteres. O corte nao se adivinha
# pela soma das larguras -- le-se do proprio spool: o tokenizador parte o
# token onde aparece "as lignedetail1", e as duas metades ficam com o mesmo
# par (s,e). O corte e entre elas. Da 4000, que e o que o spool documenta.
TOKENS = list(tokenize(589, 1068))
CORTE = next(k for k in range(len(TOKENS) - 1)
             if TOKENS[k]['s'] == TOKENS[k + 1]['s']
             and TOKENS[k]['e'] == TOKENS[k + 1]['e'])
print('corte lignedetail1/2 depois do token %d' % CORTE)


def bloco(perimetro, comentario):
    l1, l2 = [], []
    pos = 0
    for k, t in enumerate(TOKENS):
        w = width(t['raw'])
        if w is None:
            nf = next((f for f in v44 if f['start'] == pos), None)
            w = nf['len'] if nf else 0
        off = pos
        pos += w
        e, col = expressao(t, off, w)
        alvo = l1 if k <= CORTE else l2
        marca = ('-- pos %-5d %s' % (off, col)) if col else ('-- pos %-5d' % off)
        alvo.append('       %s||   %s' % (e, marca))
    for L in (l1, l2):
        L[-1] = re.sub(r'\|\|(\s+--)', r'  \1', L[-1])
    return (
        '------------------------------------------------------------------'
        '------------------------------------------------------\n'
        '-- %s\n'
        '------------------------------------------------------------------'
        '------------------------------------------------------\n'
        'select\n%s\n     as lignedetail1,\n%s\n     as lignedetail2\n'
        '  from %s\n'
        " where CD_PERIMETRE = '%s'\n"
        "   and (P1_H_0_2 = :ENTITE or :ENTITE = 'TOTAL')\n"
        ' order by NO_VARIANTE;\n'
        % (comentario, NL.join(l1), NL.join(l2), TAB, perimetro))

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
        novo.append(bloco('NAT02',
                          'PAVE P1 - perimetre NAT02 (substitui os select E04a/E04b/E04c)'))
    elif alvo == BLOCOS[3]:
        novo.append(bloco('HORS_NAT02',
                          'PAVE P1 - perimetre Hors NAT02 (substitui os 5 select E05a..E05e)'))
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
    '-- Os 8 select sobre ENG_CORP_P1 dao lugar a 2 select sobre a tabela, um',
    '-- por perimetro, cada um no lugar do bloco que substitui. Sao dois e nao',
    '-- um porque o ficheiro traz hoje as variantes 1-3 antes dos paves',
    '-- P2/M1/P9 e as 4-8 depois: mantendo os dois lugares, e mantendo o',
    '-- ORDER BY NO_VARIANTE dentro de cada um, o ficheiro sai na mesma ordem',
    '-- e a nao-regressao e um diff simples.',
    '--',
    '-- Os restantes paves (C1/C5, P2, M1, P9) ficam exatamente como estavam.',
    '--',
    '-- GERADO por gen_spool_vpact.py -- nao editar a mao.',
    '-- =====================================================================',
]
open(SAIDA, 'w', encoding='utf-8').write(NL.join(CAB) + NL + NL.join(novo) + NL)
# O TESTES.sql compara, campo a campo, a expressao ORIGINAL do spool com a
# expressao vPACT. Escreve-se aqui a lista para o gen_testes.py a ler: assim o
# teste verifica exatamente o que o spool novo emite, sem duplicar a logica.
import json
pares = []
pos = 0
for t in TOKENS:
    w = width(t['raw'])
    if w is None:
        nf = next((f for f in v44 if f['start'] == pos), None)
        w = nf['len'] if nf else 0
    off = pos
    pos += w
    e, col = expressao(t, off, w)
    if not col:
        continue
    pares.append({'off': off, 'col': col,
                  'orig': re.sub(r'\s+', ' ', t['raw']).strip().rstrip('|').strip(),
                  'vpact': re.sub(r'\s+', ' ', e).strip()})
json.dump(pares, open('pares_vpact.json', 'w', encoding='utf-8'), indent=1)
print('pares para o teste  : %d  -> pares_vpact.json' % len(pares))

print('campos com coluna : %d' % n_col)
print('fillers/literais  : %d' % n_fil)
print('-> %s' % SAIDA)
