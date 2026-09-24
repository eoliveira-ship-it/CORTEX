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

DUAS COLUNAS, COMO NOS OUTROS PAVES
-----------------------------------
Uma expressao SQL nao passa de 4000 caracteres, por isso a linha e montada em
colunas que o SQL*Plus escreve lado a lado, com UM espaco entre elas (o COLSEP).
Esse espaco nao se desliga: na corrida de 25/09 o SET COLSEP com valor vazio foi
ignorado -- os outros paves, que contam com ele, sairam iguais ao ficheiro de
referencia, e as tres colunas do P1 nao couberam nos 8000 (cada uma saiu na sua
linha, porque o SQL*Plus da a cada coluna a largura do TIPO declarado, 4000).

Entao repete-se o desenho dos outros paves: 4000 + 1 (o COLSEP) + 3999 = 8000.
Nenhuma fronteira de campo cai no 4000, por isso o corte e DENTRO do filler
P1 25.99 (100 caracteres, em branco nas seis variantes): 39 no fim da coluna 1,
o espaco do COLSEP, 60 no inicio da coluna 2. O espaco do COLSEP e um branco
desse filler, nao um caractere a mais.

As duas colunas levam CAST para VARCHAR2 do tamanho exato, senao o SQL*Plus
da-lhes 4000 (uma funcao como a f_format_montant devolve VARCHAR2 sem tamanho)
e a linha parte-se em duas.

O ';' vai ESCRITO nas expressoes (||';'||), como no ficheiro do P3. Assim nunca
depende de um parametro do SQL*Plus nem cai no meio de um campo, e nao ha ';' no
fim da linha.

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

# Tipo de cada coluna no DDL. Um NVL(coluna, ' ') numa coluna DATE ou NUMBER faz
# o Oracle converter o branco em data/numero e estoura -- foi o ORA-01847 da
# primeira corrida no DEV2 (campo P1 611, DATE). Os campos NOVO passam a ser
# escritos conforme o tipo da coluna.
TIPOS = dict(re.findall(r'^\s+(P1_[A-Z0-9_]+)\s+(VARCHAR2|DATE|NUMBER)', G.DDL, re.M))

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
    # Reference du contrat cadre: em cinco das seis variantes o spool punha aqui,
    # no ultimo byte (3982), o 'N' do netting. O 'N' passa para o P1 30.23, que e
    # o campo indicador -- e onde a variante 8 ja o escrevia. Os tres campos vao
    # escritos a mao porque e aqui que cai o espaco do COLSEP do spool antigo, e
    # a posicao lida do spool nao serve para os separar.
    'P1 30.22': "RPAD(' ', 25)",
    'P1 30.23': "'N'",
    'P1 30.24': "RPAD(' ', 25)",
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


def expr_novo(col, n):
    """Campo criado na V45, escrito conforme o tipo da coluna. Hoje a coluna esta
    sempre a NULL e o campo sai em branco; o dia em que a DSID pedir para
    preencher, muda so a procedure."""
    t = TIPOS.get(col, 'VARCHAR2')
    if t == 'DATE':
        return "RPAD(NVL(TO_CHAR(%s,'YYYYMMDD'),' '), %d)" % (col, n)
    if t == 'NUMBER':
        # o formato do montante/taxa e o mesmo que o ficheiro ja usa; em branco
        # quando nao ha valor, como nos compostos TRE201/TRE401
        if n == 19:
            return ("CASE WHEN %s IS NULL THEN RPAD(' ', 19)"
                    " ELSE pack_utilitaire.f_format_montant(%s) END" % (col, col))
        if n == 15:
            return ("CASE WHEN %s IS NULL THEN RPAD(' ', 15)"
                    " ELSE pack_utilitaire.f_format_taux_15(%s) END" % (col, col))
        return "LPAD(NVL(TO_CHAR(%s),' '), %d)" % (col, n)
    return "RPAD(NVL(%s,' '), %d)" % (col, n)


def expressao(c, var):
    """(expressao, regra) para um campo da notice, nesta variante."""
    if c['fim']:
        return "RPAD(' ', %d)" % c['len'], 'FILLER'
    if c['ref'] in REGRAS:
        return REGRAS[c['ref']], 'REGRA'
    if c['novo_v45']:
        col = 'P1_' + c['ref'].split(' ', 1)[1].replace('.', '_')
        if col in COLS:
            return expr_novo(col, c['len']), 'NOVO'
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
# A linha e montada em colunas que o SQL*Plus escreve lado a lado, com UM espaco
# entre elas: o COLSEP. Nao se desliga -- na corrida de 25/09 o 'SET COLSEP' com
# valor vazio foi ignorado (os outros paves, que contam com esse espaco, sairam
# iguais ao ficheiro de referencia) e as tres colunas do P1, largas 4000 pelo
# tipo declarado, nao couberam nos 8000: cada uma saiu na sua linha.
#
# Por isso repete-se o desenho dos outros paves: 4000 + 1 (o COLSEP) + 3999.
# O corte cai DENTRO do filler P1 25.99 (100 caracteres, bytes 3962..4061, em
# branco nas seis variantes): 39 no fim da coluna 1, o espaco do COLSEP, 60 no
# inicio da coluna 2. O byte do COLSEP e um branco do filler, nao um a mais.
#
# As duas colunas levam CAST para VARCHAR2 do tamanho exato. Sem isso o SQL*Plus
# da-lhes a largura do tipo declarado -- 4000, porque uma funcao como a
# f_format_montant devolve VARCHAR2 sem tamanho -- e a linha passa dos 8000.
CORTE = 400                  # indice do campo partido
CORTE_REF = 'P1 25.99'
CORTE_A, CORTE_B = 39, 60    # 39 + 1 (COLSEP) + 60 = 100
LARGURAS = (4000, 3999)


def confere_corte():
    """O corte e uma premissa sobre a regua: verifica-se, nao se assume."""
    c = REGUA[CORTE]
    if c['ref'] != CORTE_REF or c['len'] != CORTE_A + 1 + CORTE_B:
        raise SystemExit('o campo %d nao e o %s de %d: e %s de %d'
                         % (CORTE, CORTE_REF, CORTE_A + 1 + CORTE_B,
                            c['ref'], c['len']))
    for v in VARIANTES:
        if expressao(c, v)[1] != 'BRANCO':
            raise SystemExit('%s nao esta em branco na variante %d' % (c['ref'], v))
    ini = sum(REGUA[i]['len'] + 1 for i in range(CORTE))
    if ini + CORTE_A != LARGURAS[0]:
        raise SystemExit('coluna 1 daria %d, esperava %d' % (ini + CORTE_A, LARGURAS[0]))
    resto = CORTE_B + 1 + sum(REGUA[i]['len'] + 1 for i in range(CORTE + 1, len(REGUA))) - 1
    if resto != LARGURAS[1]:
        raise SystemExit('coluna 2 daria %d, esperava %d' % (resto, LARGURAS[1]))


def bloco(var, filtro, comentario):
    """Um SELECT sobre a tabela, com os 663 campos separados por ';'."""
    n_regra = collections.Counter()
    corte = REGUA[CORTE]

    def linha(e, ref, regra, sep=True):
        return ('       %s%s||   -- %-12s %s'
                % (e, ('||' + Q + ';' + Q) if sep else '', ref, regra))

    corpos = []
    for col in (0, 1):
        corpo = []
        if col == 0:
            faixa = range(0, CORTE)
        else:
            # o resto do filler partido, e o ';' que fecha o campo
            corpo.append(linha("RPAD(' ', %d)" % CORTE_B, corte['ref'], 'CORTE-B'))
            faixa = range(CORTE + 1, len(REGUA))
        for i in faixa:
            c = REGUA[i]
            e, regra = expressao(c, var)
            if e is None:
                raise SystemExit('campo sem regra: %s (variante %d)' % (c['ref'], var))
            n_regra[regra] += 1
            corpo.append(linha(e, c['ref'], regra, sep=i != len(REGUA) - 1))
        if col == 0:
            # a primeira parte do filler partido: sem ';', o campo continua na
            # coluna 2. O espaco que o SQL*Plus mete entre as colunas e o byte
            # do meio desse filler.
            n_regra['CORTE'] += 1
            corpo.append(linha("RPAD(' ', %d)" % CORTE_A, corte['ref'],
                               'CORTE-A', sep=False))
        corpo[-1] = corpo[-1].replace('||   --', '     --', 1)
        corpos.append('     CAST(' + NL + NL.join(corpo) + NL
                      + '     AS VARCHAR2(%d)) as lignedetail%d%s'
                      % (LARGURAS[col], col + 1, ',' if col == 0 else ''))
    risca = '-' * 120
    txt = (risca + NL + '-- ' + comentario + NL + risca + NL
           + 'select' + NL + NL.join(corpos) + NL
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
    '-- DUAS COLUNAS  a linha e montada em colunas que o SQL*Plus escreve',
    '--                lado a lado, com um espaco entre elas (o COLSEP, que nao',
    '--                se desliga). 4000 + 1 + 3999 = 8000, como nos outros',
    '--                paves. O corte cai dentro do filler P1 25.99, em branco:',
    '--                39 na coluna 1, o espaco do COLSEP, 60 na coluna 2.',
    '--                O CAST fixa a largura de cada coluna.',
    '--',
    '-- Os restantes paves (P2, M1, P9, C1, F1, F2) ficam como estavam: o P1 e',
    '-- o piloto, para validar a convencao antes de a repetir sete vezes.',
    '--',
    '-- GERADO por gen_spool_1222.py -- nao editar a mao.',
    '-- =====================================================================',
]


def escreve():
    orig = open(FONTE, encoding='latin-1').read().split(NL)
    confere_corte()
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
            txt, n = bloco(var, filtros[var], nomes[var])
            contas[var] = n
            novo.append(txt.rstrip(NL))
            i = blocos[k][1] + 1
            k += 1
            continue
        ln = orig[i]
        novo.append(ln)
        i += 1
    open(SAIDA, 'w', encoding='latin-1', errors='replace').write(
        NL.join(CAB) + NL + NL.join(novo) + NL)
    return contas


if __name__ == '__main__':
    dados = sum(c['len'] for c in REGUA if not c['fim'])
    print('pave P1, formato SIRL-1222')
    print('  campos       : %d (%d criados na V45)'
          % (len(REGUA), sum(1 for c in REGUA if c['novo_v45'])))
    print('  dados        : %d' % dados)
    print('  separadores  : %d' % (len(REGUA) - 1))
    print('  filler final : %d   (a notice diz %d)' % (REGUA[-1]['len'], FIM['len']))
    print('  total        : %d' % (dados + len(REGUA) - 1 + REGUA[-1]['len']))
    contas = escreve()
    print()
    print('  colunas      : %d + 1 (COLSEP) + %d   (limite 4000 por expressao SQL)'
          % LARGURAS)
    print('  corte dentro : %s (%d + 1 + %d)'
          % (REGUA[CORTE]['ref'], CORTE_A, CORTE_B))
    print()
    for v in VARIANTES:
        print('variante %d: %s'
              % (v, ' | '.join('%s %d' % kv for kv in sorted(contas[v].items()))))
    print()
    print('-> %s' % SAIDA)
