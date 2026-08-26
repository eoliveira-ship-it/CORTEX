"""Valida a regua V44 contra o ficheiro CRRCORP_P1 realmente gerado."""
import io
import re
import sys

S = (r'C:/Users/elder/AppData/Local/Temp/claude/'
     r'C--Users-elder-Documents/c833d650-7531-40f4-951e-02752213f565/'
     r'scratchpad/CRRCORP_P1.txt')

src = open('align_v44.py', encoding='utf-8').read()
src = src.split('# ------------------------------------------------------- alinhamento')[0]
ns = {}
buf = io.StringIO()
old = sys.stdout
sys.stdout = buf
exec(src, ns)
sys.stdout = old
v44, toks, width = ns['v44'], ns['toks'], ns['width']

# posicoes previstas
pos = 0
prev = []
for t in toks:
    w = width(t['raw'])
    if w is None:
        nf = next((f for f in v44 if f['start'] == pos), None)
        w = nf['len'] if nf else 0
    prev.append({'off': pos, 'w': w, 'ref': t.get('ref'), 'raw': t['raw']})
    pos += w

# amostras reais
linhas = []
with open(S, 'r', encoding='latin-1') as f:
    for i, l in enumerate(f):
        linhas.append(l.rstrip('\r\n'))
        if i >= 400:
            break

print('=' * 78)
print('VALIDACAO DAS POSICOES ANCORADAS CONTRA O FICHEIRO REAL')
print('=' * 78)
n = 0
for p in prev:
    if not p['ref'] or p['w'] == 0:
        continue
    vals = {l[p['off']:p['off'] + p['w']] for l in linhas}
    amostra = [v for v in sorted(vals) if v.strip()][:3]
    fonte = re.search(r'C_ENR\.([A-Za-z0-9_]+)', p['raw'])
    fonte = fonte.group(1) if fonte else p['raw'][:22]
    print('%-10s off=%-5d w=%-3d %-28s -> %s'
          % (p['ref'], p['off'], p['w'], fonte[:28],
             ' | '.join(repr(a) for a in amostra) or '(tudo branco)'))
    n += 1
    if n >= 30:
        break
