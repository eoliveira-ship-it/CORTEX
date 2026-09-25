# -*- coding: utf-8 -*-
"""SIRL-1222: valida o CRRCORP.dat gerado com ';' em TODOS os paves.

Uso:
    python comparar_1222.py <CRRCORP_vPACT.dat novo> <o de referencia, 22/09>

O que faz:

  1. tamanho das linhas (8000), censo por pave, nenhuma linha a acabar em ';';
  2. em cada pave: o numero de ';' que a notice preve e todos nas posicoes dela,
     e a cauda (campos criados na V45 e filler final) em branco;
  3. reconstroi cada linha no formato ANTIGO -- os campos um atras do outro, sem
     separador, e os sete campos corrigidos encolhidos ao tamanho que o spool
     escrevia -- e compara com a referencia:
       - nos seis paves a reconstrucao tem de dar a linha da referencia byte a
         byte, e a prova e a igualdade dos MD5 como multiconjunto (a ordem das
         linhas muda de corrida para corrida);
       - no P1 emparelha-se pelos primeiros 3900 bytes e imprime-se em que BYTES
         difere cada registo, porque ha uma diferenca esperada.

O resultado esperado, que e o que se entrega no chamado:

    P1  (3982, 3983)   122180 linhas   o N do indicador de netting, que passa do
                                       ultimo byte do P1 30.22 para o P1 30.23
        IDENTICO           45 linhas   a variante 8, que ja o escrevia no sitio
    os outros seis paves: nenhuma linha so num dos lados

A MASYSDATE (bytes 27-38) e mascarada: muda de corrida para corrida. A linha do
cabecalho tambem difere sempre, na data de geracao.
"""
import collections
import hashlib
import io
import os
import sys

import notice

b, o = io.StringIO(), sys.stdout
sys.stdout = b
import gen_spool_1222 as g           # noqa: E402  (a regua do P1, com o filler 1176)
import gen_spool_paves as GP         # noqa: E402  (as REGRAS dos outros paves)
sys.stdout = o

if len(sys.argv) != 3:
    raise SystemExit(__doc__)
NOVO, REF = sys.argv[1], sys.argv[2]
L, CHAVE, LINHA = 8001, 3900, 8000

# Largura com que o spool ANTIGO escrevia os campos que se corrigiram. Todos
# escreviam 1 -- ver docs/SIRL-1222-ALINHAMENTO.md, "As 7 correcoes".
ANTIGO = {ref: 1 for pave in GP.REGRAS for ref in GP.REGRAS[pave]}

PAVES = ('P1', 'P2', 'M1', 'C1', 'F1', 'F2', 'P9')
CODIGO = (43, 45)          # onde esta o codigo do pave na linha nova (campo 0.6)


def regua(pave):
    """As posicoes 0-based do pave na linha NOVA, e a receita da linha antiga.

    seps    posicoes dos ';'
    fatias  (posicao, largura) de cada campo para reconstruir a linha antiga
    cauda   onde comeca o primeiro campo criado na V45 (ou o filler final)
    filler  (posicao, largura) do filler final
    """
    if pave == 'P1':
        campos = [(c['ref'], c['len'], c['novo_v45'], c['fim']) for c in g.REGUA]
    else:
        cs = notice.carrega()[pave]
        dados = sum(int(c['len']) for c in cs[:-1])
        fim = LINHA - dados - (len(cs) - 1)      # o filler que sobra
        campos = [(c['ref'], int(c['len']), c['novo_v45'], False) for c in cs[:-1]]
        campos.append((cs[-1]['ref'], fim, False, True))

    seps, fatias, pos, cauda = [], [], 0, None
    for ref, ln, novo, fim in campos:
        if novo and cauda is None:
            cauda = pos
        if not fim:
            fatias.append((pos, ANTIGO.get(ref, ln)))
        else:
            filler = (pos, ln)
        pos += ln
        if not fim:
            seps.append(pos)
        pos += 1
    if pos - 1 != LINHA:
        raise SystemExit('%s: a regua da %d, nao %d' % (pave, pos - 1, LINHA))
    return {'seps': seps, 'sset': set(seps), 'fatias': fatias,
            'cauda': cauda if cauda is not None else filler[0],
            'filler': filler, 'n': len(campos)}


R = {p: regua(p) for p in PAVES}


def pave_de(s):
    """O pave da linha nova, ou None se for cabecalho/rodape."""
    if s[:2] in ('00', '99'):
        return None
    return s[CODIGO[0]:CODIGO[1]]


def masc(s):
    return s[:26] + ' ' * 12 + s[38:]


def antiga(s, r):
    """A linha no formato do spool antigo: campos seguidos, sem separador."""
    return masc(''.join(s[p:p + w] for p, w in r['fatias']).ljust(LINHA))


def passagem1():
    f = open(NOVO, 'rb')
    tot = os.path.getsize(NOVO) // L
    censo, mal = collections.Counter(), collections.Counter()
    for n in range(tot):
        f.seek(n * L)
        s = f.read(LINHA).decode('latin-1')
        if len(s) != LINHA:
            mal['TAMANHO'] += 1
            continue
        p = pave_de(s)
        censo[p or s[:2]] += 1
        if s.endswith(';'):
            mal['; NO FIM DA LINHA'] += 1
        if p is None:
            continue
        if p not in R:
            mal['PAVE DESCONHECIDO'] += 1
            continue
        r = R[p]
        if s.count(';') != len(r['seps']):
            mal['%s N DE ;' % p] += 1
        elif any(s[i] != ';' for i in r['seps']):
            mal['%s ; FORA DE SITIO' % p] += 1
        if set(s[r['cauda']:]) - set(' ;'):
            mal['%s CAUDA COM DADOS' % p] += 1
        if s[r['filler'][0]:] != ' ' * r['filler'][1]:
            mal['%s FILLER FINAL NAO BRANCO' % p] += 1
    return tot, censo, mal


tot, censo, mal = passagem1()
print('linhas: %d (referencia: 554045)' % tot)
print('censo por pave: %s' % dict(censo.most_common()))
for p in PAVES:
    r = R[p]
    print('  %-3s %3d campos, %3d separadores, filler final %d..%d (%d)'
          % (p, r['n'], len(r['seps']), r['filler'][0] + 1,
             r['filler'][0] + r['filler'][1], r['filler'][1]))
print('problemas: %s' % (dict(mal) if mal else 'nenhum'))
print()


def indice():
    """A referencia: o P1 por prefixo (para emparelhar), os outros por MD5."""
    f = open(REF, 'rb')
    d, outros = {}, collections.Counter()
    for n in range(os.path.getsize(REF) // L):
        f.seek(n * L)
        s = f.read(LINHA).decode('latin-1')
        if s[38:40] == 'P1':
            d.setdefault(hashlib.md5(masc(s)[:CHAVE].encode('latin-1')).digest(),
                         []).append(n)
        else:
            outros[(s[38:40],
                    hashlib.md5(masc(s).encode('latin-1')).digest())] += 1
    return d, outros


idx, ref_outros = indice()
fn, fr = open(NOVO, 'rb'), open(REF, 'rb')
novo_outros = collections.Counter()
perfil, sem, ambig, p1 = collections.Counter(), 0, 0, 0
for n in range(tot):
    fn.seek(n * L)
    s = fn.read(LINHA).decode('latin-1')
    p = pave_de(s)
    if p is None:
        novo_outros[(s[:2], hashlib.md5(masc(s).encode('latin-1')).digest())] += 1
        continue
    velho = antiga(s, R[p])
    if p != 'P1':
        novo_outros[(p, hashlib.md5(velho.encode('latin-1')).digest())] += 1
        continue
    p1 += 1
    cand = idx.get(hashlib.md5(velho[:CHAVE].encode('latin-1')).digest())
    if not cand:
        sem += 1
        continue
    if len(cand) > 1:
        ambig += 1
    fr.seek(cand[0] * L)
    v = masc(fr.read(LINHA).decode('latin-1'))
    perfil[tuple(i + 1 for i in range(LINHA) if velho[i] != v[i])] += 1

print('outros paves: %d linhas novas, %d na referencia' %
      (sum(novo_outros.values()), sum(ref_outros.values())))
so_novo, so_ref = novo_outros - ref_outros, ref_outros - novo_outros
print('  so no novo: %d   so na referencia: %d'
      % (sum(so_novo.values()), sum(so_ref.values())))
for nome, c in (('so no novo', so_novo), ('so na referencia', so_ref)):
    porpave = collections.Counter()
    for (pv, _h), q in c.items():
        porpave[pv] += q
    if porpave:
        print('  %s: %s' % (nome, dict(porpave)))
print()
print('P1: %d linhas, sem par %d, chave ambigua %d' % (p1, sem, ambig))
for d, c in perfil.most_common(8):
    print('  %-24s %7d' % (str(d) if d else 'IDENTICO', c))
