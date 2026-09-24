"""SIRL-1222: alinhamento campo a campo do pave P1, por ancoras.

Para pôr ';' entre campos e preciso saber onde cada campo da notice comeca. O
spool nao diz: junta campos seguidos num RPAD(' ', soma) so. Duas maneiras de
descobrir, e a segunda e a que vale:

  1. soma acumulada da notice. Nao serve sozinha: a largura da notice (5675) e
     a do spool (5698) nao batem, e o desvio acumula-se ao longo da linha.
  2. ANCORAS. 120 tokens do spool trazem o comentario '--P1 x.y', que diz o
     campo. Entre duas ancoras consecutivas, comparo a soma das larguras dos
     tokens com a soma dos tamanhos dos campos da notice. Se der o mesmo
     numero, aquela zona esta alinhada e os campos podem ser cortados sem
     duvida. Se nao der, a zona fica marcada: e ali que ha trabalho a mao.

Resultado: 110 das 116 zonas do P1 fecham exatamente. Sao 6 zonas a resolver,
nao 611 campos.

Uso:  python mapa_1222.py
"""
import collections
import io
import re
import sys

import notice

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import gen_spool_vpact as G          # noqa: E402  (pelos TOKENS por variante)
sys.stdout = _o

VARIANTES = (1, 4, 5, 6, 7, 8)
CAMPOS = notice.carrega()['P1']
FIM = CAMPOS[-1]                     # o filler final, P1 99.99


def regua():
    """Os campos que o ficheiro escreve hoje: notice V45.02 menos os criados
    na V45, sem o filler final, e com o P1 21.65 em 5 -- o spool de origem e o
    de antes do SIRL-1223."""
    r = []
    for c in CAMPOS:
        if c['novo_v45'] or c is FIM:
            continue
        r.append({'ref': c['ref'],
                  'len': 5 if c['ref'] == 'P1 21.65' else c['len'],
                  'filler': c['filler']})
    return r


REGUA = regua()
ORDEM = {c['ref']: i for i, c in enumerate(REGUA)}
TAM = {c['ref']: c['len'] for c in REGUA}


def ancoras(var):
    """Tokens com comentario '--P1 x.y' que casa com um campo da regua, em
    ordem crescente na notice. Uma ancora fora de ordem e descartada: sem isso
    inventam-se zonas que nao existem."""
    out, ultimo = [], -1
    for i, (off, w, t) in enumerate(G.TOKENS[var]):
        ref = (t.get('ref') or '').strip()
        j = ORDEM.get(ref)
        if j is None or j <= ultimo:
            continue
        out.append((i, off, w, ref, j))
        ultimo = j
    return out


def zonas(var):
    """[(campo_ini, campo_fim, n_tokens, n_campos, larg_spool, larg_notice)]
    das zonas cuja largura NAO bate. As que batem ficam de fora."""
    toks = G.TOKENS[var]
    anc = ancoras(var)
    fora = []
    for k in range(len(anc) - 1):
        i1, _, _, r1, j1 = anc[k]
        i2, _, _, r2, j2 = anc[k + 1]
        larg = sum(w for _, w, _ in toks[i1 + 1:i2])
        nsum = sum(TAM[c['ref']] for c in REGUA[j1 + 1:j2])
        if larg != nsum:
            fora.append((r1, r2, i2 - i1 - 1, j2 - j1 - 1, larg, nsum))
    return anc, fora


if __name__ == '__main__':
    print('notice V45.02, pave P1 : %d campos (dos quais %d criados na V45)'
          % (len(CAMPOS), sum(1 for c in CAMPOS if c['novo_v45'])))
    print('regua de hoje          : %d campos, %d caracteres'
          % (len(REGUA), sum(c['len'] for c in REGUA)))
    print('filler final           : %d (a confirmar com a DSID: 1176)' % FIM['len'])
    print()
    print('%-9s %7s %8s %8s %9s' % ('variante', 'tokens', 'ancoras', 'zonas ok', 'zonas fora'))
    guardado = {}
    for v in VARIANTES:
        anc, fora = zonas(v)
        guardado[v] = fora
        print('%-9d %7d %8d %8d %9d'
              % (v, len(G.TOKENS[v]), len(anc), len(anc) - 1 - len(fora), len(fora)))
    print()
    for v in VARIANTES:
        print('--- variante %d: zonas a resolver' % v)
        for r1, r2, nt, nc, ls, ln in guardado[v]:
            print('   entre %-12s e %-12s : %2d tokens (%5d) para %3d campos (%5d)  delta %+d'
                  % (r1, r2, nt, ls, nc, ln, ls - ln))
