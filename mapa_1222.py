"""SIRL-1222: o layout do pave P1 e o da notice? Medicao por ancoras.

Para pôr ';' entre campos e preciso saber onde cada campo da notice comeca. O
spool nao diz: junta campos seguidos num RPAD(' ', soma) so -- ha 153 pedacos do
SELECT do P1 que cobrem mais de um campo, o maior com 49 campos em 354
caracteres.

COMO SE MEDE
------------
120 tokens do spool trazem o comentario '--P1 x.y', que diz o campo. Para cada
ancora calcula-se

    desvio = posicao no spool - posicao na regua da notice

e olha-se para onde o desvio MUDA. Um desvio constante quer dizer que o spool e
a notice concordam, mesmo que o spool escreva 49 campos num RPAD so. Cada
degrau e uma divergencia real, e e ai que ha trabalho.

Nao se comparam somas entre ancoras: o token da ancora pode ser um filler grande
que cobre o campo da ancora E os seguintes (o '--P1 3.56' esta num RPAD(' ',185)
que vale 20 campos), e isso produzia zonas falsas.

BOLHAS
------
Um degrau que desaparece na ancora seguinte nao e desalinhamento: e o comentario
colado no pedaco errado. Exemplo: o 'P1 4.2' (19 caracteres, posicao 459) esta
escrito como RPAD(' ',1) + RPAD(' ',16) + RPAD(' ',2) e o comentario esta no
ultimo pedaco, 17 caracteres depois do inicio do campo. Estas ancoras marcam-se
como BOLHA e nao contam.

RESULTADO (2026-09-24), com a correcao de 25/09
-----------------------------------------------
Nas seis variantes, um unico degrau: -1 a partir do bloco 30.x. A medicao no
ficheiro real mostrou que esse degrau NAO e desalinhamento: e o espaco do COLSEP,
o byte que o SQL*Plus mete entre as duas colunas e que cai dentro do filler do
P1 30.24. Contado esse byte, o layout do P1 E o da notice do inicio ao fim, e
sobra uma unica anomalia: em cinco das seis variantes o 'N' do primeiro
indicador de netting vai no ultimo byte do P1 30.22, um byte antes do campo
indicador (ver docs/SIRL-1222-ALINHAMENTO.md).

Por isso a regua deste modulo (com o -1) continua a servir para ir buscar a
expressao de cada campo ao spool -- e a regua do espaco SEM o COLSEP -- mas nao
descreve as posicoes no ficheiro. Os campos P1 30.22, 30.23 e 30.24, que e onde o
COLSEP cai, vao escritos a mao no gen_spool_1222.py.

Uso:  python mapa_1222.py
"""
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
    """Os campos que o ficheiro escreve hoje: notice V45.02 menos os criados na
    V45, sem o filler final, e com o P1 21.65 em 5 -- o spool de origem e o de
    antes do SIRL-1223."""
    r, off = [], 0
    for c in CAMPOS:
        if c['novo_v45'] or c is FIM:
            continue
        ln = 5 if c['ref'] == 'P1 21.65' else c['len']
        r.append({'ref': c['ref'], 'len': ln, 'start': off, 'filler': c['filler']})
        off += ln
    return r


REGUA = regua()
POS = {c['ref']: c['start'] for c in REGUA}
ORDEM = {c['ref']: i for i, c in enumerate(REGUA)}


def ancoras(var):
    """[(indice_token, offset, largura, campo, desvio)] das ancoras que casam
    com um campo da regua, em ordem crescente na notice."""
    out, ultimo = [], -1
    for i, (off, w, t) in enumerate(G.TOKENS[var]):
        ref = (t.get('ref') or '').strip()
        j = ORDEM.get(ref)
        if j is None or j <= ultimo:
            continue
        out.append((i, off, w, ref, off - POS[ref]))
        ultimo = j
    return out


def degraus(var):
    """[(campo, desvio_antes, desvio_depois, bolha)] -- onde o desvio muda."""
    anc = ancoras(var)
    out = []
    fecha = -1
    for k in range(1, len(anc)):
        d0, d1 = anc[k - 1][4], anc[k][4]
        if d0 == d1:
            continue
        # bolha: o desvio volta ao valor anterior na ancora seguinte. O degrau
        # de volta faz parte da mesma bolha e tambem nao conta.
        bolha = k == fecha or (k + 1 < len(anc) and anc[k + 1][4] == d0)
        if bolha and k != fecha:
            fecha = k + 1
        out.append((anc[k][3], d0, d1, bolha))
    return anc, out


if __name__ == '__main__':
    print('notice V45.02, pave P1 : %d campos (%d criados na V45)'
          % (len(CAMPOS), sum(1 for c in CAMPOS if c['novo_v45'])))
    print('regua de hoje          : %d campos, %d caracteres'
          % (len(REGUA), sum(c['len'] for c in REGUA)))
    print('filler final           : %d na notice (premissa em vigor: 1176)' % FIM['len'])
    print()
    for v in VARIANTES:
        anc, deg = degraus(v)
        reais = [d for d in deg if not d[3]]
        print('variante %d: %3d ancoras, %d degraus reais, %d bolhas'
              % (v, len(anc), len(reais), len(deg) - len(reais)))
        for ref, d0, d1, bolha in deg:
            print('   %-12s desvio %+d -> %+d   %s'
                  % (ref, d0, d1, 'BOLHA (comentario no pedaco errado)' if bolha else 'DEGRAU REAL'))
