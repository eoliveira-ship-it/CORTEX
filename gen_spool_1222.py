"""Gera o spool do pave P1 com separador ';' -- SIRL-1222.

PARTE DE ONDE
-------------
Do spool vPACT (SIRL-1224 + SIRL-1223), que ja le a tabela ENG_CORP_P1_BIS. Os
outros paves (P2, M1, P9, C1, F1, F2) ficam como estao neste passo: o P1 e o
piloto, para a convencao ser validada antes de se repetir sete vezes.

A LINHA SAI DA NOTICE, NAO DO SPOOL
-----------------------------------
O spool junta campos seguidos num RPAD(' ', soma) so -- 49 campos em 354
caracteres, no maior caso. Para separar por ';' e preciso a lista de campos da
notice. O mapa_1222.py provou que da: em toda a linha do P1 ha um unico desvio
entre o spool e a notice V45.02 (o -1 do bloco 30.x). Com esse desvio aplicado,
cada campo da notice cai sobre o que o spool escreve.

Para cada campo da notice, a expressao sai de uma destas regras:

  EXATO   um token do spool tem exatamente as fronteiras do campo -> copia-se a
          expressao vPACT desse token
  EMENDA  varios tokens cobrem o campo exatamente (RPAD('+',1) seguido de
          LPAD(...,5,'0') formam o P1 31.17, de 6) -> concatenam-se
  BRANCO  o campo cai dentro de um filler -> RPAD(' ', tamanho)
  NOVO    campo criado na V45 -> le-se a coluna da tabela, que esta a NULL e por
          isso sai em branco. Assim, o dia em que a DSID pedir para preencher,
          muda so a procedure
  REGRA   os seis casos escritos a mao em REGRAS, cada um com a sua razao
  FILLER  o filler final, que e o que falta para os 8000

TAMANHO DA LINHA
----------------
663 campos, 6162 caracteres de dados, 662 separadores, filler final de 1176 =
8000. A notice diz 1185 para o filler, o que daria 8009; ver
docs/QUESTAO-FILLER-P1.md. Premissa em vigor: 1176.

TRES COLUNAS, E NAO DUAS
------------------------
Uma expressao SQL nao passa de 4000 caracteres, por isso a linha e montada em
colunas que o SQL*Plus escreve lado a lado. Com DUAS nao da: a linha tem 8000 e
as fronteiras de campo saltam de 3960 para 4061, porque o filler P1 25.99 tem
100 caracteres -- nenhuma fronteira cai no 4000 exato. Com TRES sobra folga
(cerca de 2670 em cada) e o corte cai sempre numa fronteira de campo.

O separador vai ESCRITO nas expressoes (||';'||), como no ficheiro do P3, e o
spool leva SET COLSEP '' para o SQL*Plus nao meter nada entre as colunas. Assim
o ';' nunca depende de um parametro do SQL*Plus nem cai no meio de um campo, e
nao ha ';' no fim da linha.

Uso:  python gen_spool_1222.py
"""
import collections
import io
import re
import sys

import notice

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import gen_spool_vpact as G          # noqa: E402  (expressoes vPACT e TOKENS)
import mapa_1222 as M                # noqa: E402  (regua de hoje e ordem)
sys.stdout = _o

NL = chr(10)
Q = chr(39)
TAB = 'ENG_CORP_P1_BIS'
LINHA = 8000
COLUNAS = 3
VARIANTES = (1, 4, 5, 6, 7, 8)
FONTE = '030_spool_Extract_CRRCORP_vPACT.sql'
SAIDA = '030_spool_Extract_CRRCORP_1222.sql'

CAMPOS = notice.carrega()['P1']
FIM = CAMPOS[-1]                     # o filler final, P1 99.99
COLS = G.COLS                        # colunas que existem na ENG_CORP_P1_BIS

# o desvio de 1 caractere comeca no campo indicador de netting
INICIO_DESVIO = M.ORDEM['P1 30.23']

# Campos que o spool escreve num token so e a notice separa em dois, ou que o
# spool escreve na posicao errada. Um por um, com a razao.
REGRAS = {
    # TRE201: o spool escreve montante e devise juntos num CASE de 22. A tabela
    # guarda os dois em colunas separadas, por isso basta parti-lo em dois.
    'P1 4.4':   "CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 19)"
                " ELSE pack_utilitaire.f_format_montant_bis2(P1_4_4) END",
    'P1 4.5':   "CASE WHEN P1_4_5 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_5, 3) END",
    # TRE401: o mesmo
    'P1 4.14':  "CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 19)"
                " ELSE pack_utilitaire.f_format_montant_bis2(P1_4_14) END",
    'P1 4.15':  "CASE WHEN P1_4_15 IS NULL THEN RPAD(' ', 3) ELSE RPAD(P1_4_15, 3) END",
    # A regua de hoje tem o 21.65 com 5; o vPACT ja o escreve com 50 (SIRL-1223)
    'P1 21.65': "RPAD(' ', 50)",
    # Reference du contrat cadre: o spool punha aqui, no ultimo byte, o 'N' do
    # netting. O 'N' passa para o P1 30.23, que e o campo indicador.
    'P1 30.22': "RPAD(' ', 25)",
}


def regua_1222():
    """Os 663 campos da notice V45.02, na ordem dela. Cada campo leva a posicao
    onde o spool de HOJE o escreve (pos_velho), para se ir buscar a expressao."""
    r = []
    for c in CAMPOS:
        d = {'ref': c['ref'], 'len': c['len'], 'novo_v45': c['novo_v45'],
             'filler': c['filler'], 'fim': c is FIM, 'pos_velho': None}
        if c['ref'] in M.ORDEM:
            j = M.ORDEM[c['ref']]
            d['pos_velho'] = M.REGUA[j]['start'] - (1 if j >= INICIO_DESVIO else 0)
        r.append(d)
    # o filler final e o que falta para os 8000, nao o numero da notice
    dados = sum(x['len'] for x in r[:-1])
    r[-1]['len'] = LINHA - dados - (len(r) - 1)
    return r


REGUA = regua_1222()


def e_filler(raw):
    return re.match(r"^RPAD\(''\s*,\d+\)\|*$", re.sub(r'\s+', '', raw)) is not None


def expressao(c, var):
    """(expressao, regra) para um campo da notice, nesta variante."""
    if c['fim']:
        return "RPAD(' ', %d)" % c['len'], 'FILLER'
    if c['ref'] in REGRAS:
        return REGRAS[c['ref']], 'REGRA'
    if c['novo_v45']:
        col = 'P1_' + c['ref'].split(' ', 1)[1].replace('.', '_')
        if col in COLS:
            return "RPAD(NVL(%s,' '), %d)" % (col, c['len']), 'NOVO'
        return "RPAD(' ', %d)" % c['len'], 'NOVO-SEM-COLUNA'
    a = c['pos_velho']
    if a is None:
        return "RPAD(' ', %d)" % c['len'], 'FORA'
    b = a + c['len']
    cob = [(off, w, t) for off, w, t in G.TOKENS[var] if off < b and off + w > a]
    if not cob:
        return "RPAD(' ', %d)" % c['len'], 'FORA'
    if all(e_filler(t['raw']) for _, _, t in cob):
        return "RPAD(' ', %d)" % c['len'], 'BRANCO'
    if len(cob) == 1 and cob[0][0] == a and cob[0][1] == c['len']:
        e, _ = G.expressao(cob[0][2], a, c['len'], var)
        return (e if e else "RPAD(' ', %d)" % c['len']), 'EXATO'
    if cob[0][0] == a and cob[-1][0] + cob[-1][1] == b:
        partes = []
        for off, w, t in cob:
            e, _ = G.expressao(t, off, w, var)
            partes.append(e if e else "RPAD(' ', %d)" % w)
        return '||'.join(partes), 'EMENDA'
    return None, 'SEM-REGRA'


# --------------------------------------------------------------- as colunas
def cortes(n=COLUNAS):
    """Indice do ULTIMO campo de cada coluna. Corta-se sempre em fronteira de
    campo, a primeira que passa LINHA/n."""
    alvo = LINHA / float(n)
    fim, acc = [], 0
    for k, c in enumerate(REGUA):
        acc += c['len'] + 1
        if len(fim) < n - 1 and acc >= alvo:
            fim.append(k)
            acc = 0
    fim.append(len(REGUA) - 1)
    return fim


def larguras(fim):
    """Largura de cada coluna. O ultimo campo da linha nao leva ';' depois."""
    out, ini = [], 0
    for f in fim:
        w = sum(REGUA[i]['len'] for i in range(ini, f + 1)) + (f - ini + 1)
        if f == len(REGUA) - 1:
            w -= 1
        out.append(w)
        ini = f + 1
    return out


def bloco(var, filtro, comentario, fim):
    """Um SELECT sobre a tabela, com os 663 campos separados por ';'."""
    partes, ini, n_regra = [], 0, collections.Counter()
    for n, f in enumerate(fim):
        corpo = []
        for i in range(ini, f + 1):
            c = REGUA[i]
            e, regra = expressao(c, var)
            n_regra[regra] += 1
            if e is None:
                raise SystemExit('campo sem regra: %s (variante %d)' % (c['ref'], var))
            ultimo = (i == len(REGUA) - 1)
            sep = '' if ultimo else '||' + Q + ';' + Q
            corpo.append('       %s%s||   -- %-12s %s' % (e, sep, c['ref'], regra))
        corpo[-1] = re.sub(r'\|\|(\s+--)', r'  \1', corpo[-1])
        partes.append(NL.join(corpo) + NL + '     as lignedetail%d%s'
                      % (n + 1, ',' if n + 1 < len(fim) else ''))
        ini = f + 1
    risca = '-' * 120
    txt = (risca + NL + '-- ' + comentario + NL + risca + NL
           + 'select' + NL + NL.join(partes) + NL
           + '  from ' + TAB + NL
           + ' where ' + filtro + NL
           + '   and (P1_H_0_2 = :ENTITE or :ENTITE = ' + Q + 'TOTAL' + Q + ')' + NL
           + ' order by NO_VARIANTE;' + NL)
    return txt, n_regra


CAB = [
    '-- =====================================================================',
    '-- 030_spool_Extract_CRRCORP_1222.sql               (SIRL-1222)',
    '--',
    '-- O pave P1 com separador ";" entre todos os campos. Parte do spool vPACT',
    '-- (SIRL-1224 + 1223) e troca a forma de montar a linha: cada campo da',
    '-- notice V45.02 e escrito separado, seguido de ";".',
    '--',
    '-- A LINHA        663 campos: 6162 de dados + 662 separadores + filler',
    '--                final de 1176 = 8000 caracteres. O ultimo campo (o',
    '--                filler) NAO leva ";" depois. Os 51 campos criados na',
    '--                V45 sao escritos, em branco, lendo as colunas da tabela.',
    '--',
    '-- TRES COLUNAS   uma expressao SQL nao passa de 4000. Com duas colunas a',
    '--                linha nao cabe: as fronteiras de campo saltam de 3960',
    '--                para 4061 (o filler P1 25.99 tem 100). Com tres sobra',
    '--                folga e o corte cai em fronteira de campo.',
    '--                SET COLSEP "" : o ";" vai escrito nas expressoes.',
    '--',
    '-- Os restantes paves (P2, M1, P9, C1, F1, F2) ficam como estavam: o P1 e',
    '-- o piloto, para validar a convencao antes de a repetir sete vezes.',
    '--',
    '-- GERADO por gen_spool_1222.py -- nao editar a mao.',
    '-- =====================================================================',
]


def escreve():
    orig = open(FONTE, encoding='latin-1').read().split(NL)
    fim = cortes()
    blocos = []
    for i, ln in enumerate(orig):
        if ln.startswith('-- PAVE P1'):
            j = next(k for k in range(i, len(orig))
                     if orig[k].strip() == 'order by NO_VARIANTE;')
            blocos.append((i - 1, j))
    if len(blocos) != len(VARIANTES):
        raise SystemExit('esperava %d blocos P1, achei %d'
                         % (len(VARIANTES), len(blocos)))
    filtros = {1: "CD_PERIMETRE = 'NAT02'"}
    nomes = {1: 'PAVE P1 - perimetre NAT02 (variantes 1-3) - com separador ;'}
    for v in VARIANTES[1:]:
        filtros[v] = 'NO_VARIANTE = %d' % v
        nomes[v] = 'PAVE P1 - Hors NAT02, variante %d - com separador ;' % v
    novo, i, k, contas = [], 0, 0, {}
    while i < len(orig):
        if k < len(blocos) and i == blocos[k][0]:
            var = VARIANTES[k]
            txt, n = bloco(var, filtros[var], nomes[var], fim)
            contas[var] = n
            novo.append(txt.rstrip(NL))
            i = blocos[k][1] + 1
            k += 1
            continue
        ln = orig[i]
        novo.append(ln)
        if ln.startswith('SET linesize'):
            novo.append("SET COLSEP ''   -- SIRL-1222 : o ';' vai escrito nas expressoes")
        i += 1
    open(SAIDA, 'w', encoding='latin-1', errors='replace').write(
        NL.join(CAB) + NL + NL.join(novo) + NL)
    return fim, contas


if __name__ == '__main__':
    dados = sum(c['len'] for c in REGUA if not c['fim'])
    print('pave P1, formato SIRL-1222')
    print('  campos       : %d (%d criados na V45)'
          % (len(REGUA), sum(1 for c in REGUA if c['novo_v45'])))
    print('  dados        : %d' % dados)
    print('  separadores  : %d' % (len(REGUA) - 1))
    print('  filler final : %d   (a notice diz %d)' % (REGUA[-1]['len'], FIM['len']))
    print('  total        : %d' % (dados + len(REGUA) - 1 + REGUA[-1]['len']))
    fim, contas = escreve()
    print()
    print('  colunas      : %s   (limite 4000 por expressao SQL)' % larguras(fim))
    print('  cortes em    : %s' % ', '.join(REGUA[i]['ref'] for i in fim))
    print()
    for v in VARIANTES:
        print('variante %d: %s'
              % (v, ' | '.join('%s %d' % kv for kv in sorted(contas[v].items()))))
    print()
    print('-> %s' % SAIDA)
