"""SIRL-1222: valida o CRRCORP.dat gerado com ';' no pave P1.

Uso:
    python comparar_1222.py <CRRCORP_vPACT.dat novo> <o de referencia, 22/09>

O que faz:

  1. tamanho das linhas (8000), censo por pave, nenhuma linha a acabar em ';';
  2. no P1: 662 ';' por linha, todos nas posicoes que a notice V45.02 preve;
  3. os outros seis paves: compara os MD5 como multiconjunto (a ordem das linhas
     muda de corrida para corrida). So o cabecalho difere, na data de geracao;
  4. o P1: reconstroi a linha no formato ANTIGO -- que e simplesmente os 611
     campos comuns um atras do outro, porque o layout do spool antigo E o da
     notice -- e compara com a de referencia, emparelhada pelos primeiros 3900
     bytes. Imprime em que BYTES difere cada registo.

O resultado esperado, que e o que se entrega no chamado:

    (3982, 3983)   122180 linhas   o N do indicador de netting, que passa do
                                   ultimo byte do P1 30.22 para o P1 30.23
    IDENTICO           45 linhas   a variante 8, que ja o escrevia no sitio

A MASYSDATE (bytes 27-38) e mascarada: muda de corrida para corrida.
"""
import collections, hashlib, io, os, sys
b, o = io.StringIO(), sys.stdout
sys.stdout = b
import gen_spool_1222 as g
import mapa_1222 as M
sys.stdout = o

if len(sys.argv) != 3:
    raise SystemExit(__doc__)
NOVO, REF = sys.argv[1], sys.argv[2]
L, CHAVE = 8001, 3900

NEW, pos, SEPS = {}, 0, []
for c in g.REGUA:
    NEW[c['ref']] = (pos, c['len'])
    pos += c['len']
    if not c['fim']:
        SEPS.append(pos)
    pos += 1
VELHOS = set(c['ref'] for c in M.REGUA)
# a cauda da linha: os 51 campos criados na V45 e o filler final, todos em branco
CAUDA = min(NEW[c['ref']][0] for c in g.REGUA if c['novo_v45'])
FILLER = NEW[g.REGUA[-1]['ref']]
FATIAS = [NEW[c['ref']] for c in g.REGUA if c['ref'] in VELHOS and not c['fim']]
PAVE = NEW['0.6 (P1)'][0]
SEPS_S = set(SEPS)


def e_p1(s):
    """A linha do P1 no formato novo: ';' logo no fim do primeiro campo."""
    return s[8] == ';' and s[PAVE:PAVE + 2] == 'P1'


def masc(s):
    return s[:26] + ' ' * 12 + s[38:]


def passagem1():
    f = open(NOVO, 'rb')
    tot = os.path.getsize(NOVO) // L
    censo, mal = collections.Counter(), collections.Counter()
    for n in range(tot):
        f.seek(n * L)
        s = f.read(8000).decode('latin-1')
        if len(s) != 8000:
            mal['TAMANHO'] += 1
            continue
        if e_p1(s):
            p = 'P1'
            if s.count(';') != len(SEPS):
                mal['N DE ;'] += 1
            elif any(s[i] != ';' for i in SEPS):
                mal['; FORA DE SITIO'] += 1
            if set(s[CAUDA:]) - set(' ;'):
                mal['CAUDA COM DADOS'] += 1
            if s[FILLER[0]:] != ' ' * FILLER[1]:
                mal['FILLER FINAL NAO BRANCO'] += 1
        else:
            p = s[38:40]
        censo[p] += 1
        if s.endswith(';'):
            mal['; NO FIM DA LINHA'] += 1
    return tot, censo, mal


tot, censo, mal = passagem1()
print('linhas: %d (referencia: 554045)' % tot)
print('censo por pave: %s' % dict(censo.most_common()))
print('P1: campos novos nos bytes %d..%d, filler final %d..%d (%d)'
      % (CAUDA + 1, FILLER[0], FILLER[0] + 1, FILLER[0] + FILLER[1], FILLER[1]))
print('problemas: %s' % (dict(mal) if mal else 'nenhum'))
print()


def indice():
    f = open(REF, 'rb')
    d, outros = {}, collections.Counter()
    for n in range(os.path.getsize(REF) // L):
        f.seek(n * L)
        s = f.read(8000).decode('latin-1')
        if s[38:40] == 'P1':
            d.setdefault(hashlib.md5(masc(s)[:CHAVE].encode('latin-1')).digest(),
                         []).append(n)
        else:
            outros[hashlib.md5(masc(s).encode('latin-1')).digest()] += 1
    return d, outros


idx, ref_outros = indice()
fn, fr = open(NOVO, 'rb'), open(REF, 'rb')
novo_outros = collections.Counter()
perfil, sem, ambig, p1 = collections.Counter(), 0, 0, 0
for n in range(tot):
    fn.seek(n * L)
    s = fn.read(8000).decode('latin-1')
    if not e_p1(s):
        novo_outros[hashlib.md5(masc(s).encode('latin-1')).digest()] += 1
        continue
    p1 += 1
    velho_fmt = masc(''.join(s[p:p + w] for p, w in FATIAS).ljust(8000))
    cand = idx.get(hashlib.md5(velho_fmt[:CHAVE].encode('latin-1')).digest())
    if not cand:
        sem += 1
        continue
    if len(cand) > 1:
        ambig += 1
    fr.seek(cand[0] * L)
    v = masc(fr.read(8000).decode('latin-1'))
    perfil[tuple(i + 1 for i in range(8000) if velho_fmt[i] != v[i])] += 1

print('outros paves: %d linhas novas, %d na referencia' %
      (sum(novo_outros.values()), sum(ref_outros.values())))
print('  so no novo: %d   so na referencia: %d'
      % (sum((novo_outros - ref_outros).values()),
         sum((ref_outros - novo_outros).values())))
print()
print('P1: %d linhas, sem par %d, chave ambigua %d' % (p1, sem, ambig))
for d, c in perfil.most_common(8):
    print('  %-24s %7d' % (str(d) if d else 'IDENTICO', c))
