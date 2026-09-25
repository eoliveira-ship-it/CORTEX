# -*- coding: utf-8 -*-
"""SIRL-1222: o que custa por pave, medido antes de gerar nada.

O P1 ja esta feito e validado. Para os outros seis a pergunta e a mesma que se
fez ao P1: cada campo da notice cai sobre o que o spool escreve? A diferenca e
que aqui nao ha tabela BIS -- os select ficam como estao e o ';' entra por corte
dos tokens que la estao. Entao o que interessa contar e:

  BRANCO     a fronteira do campo cai dentro de um filler -> parte-se o RPAD,
             que e mecanico
  DENTRO     a fronteira cai dentro de um token que nao e branco (um CASE, uma
             funcao) -> tem de ser escrito a mao, como as REGRAS do P1
  FRONTEIRA  a fronteira do campo e fronteira de token -> basta meter ||';'||

Reaproveita o tokenize/width do align_v44.py, que mede a largura de cada token
sem base de dados, apontado ao spool vPACT.

Uso:  python mapa_paves.py
"""
import io
import re
import sys

import notice

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import align_v44 as A                 # noqa: E402  (tokenize e width)
sys.stdout = _o

FONTE = '030_spool_Extract_CRRCORP_vPACT.sql'
A.lines = open(FONTE, encoding='latin-1').read().split('\n')

# blocos de cada pave no spool vPACT (1-based, do 'select' ao ';' do WHERE).
# O P1 nao esta aqui: tem o seu gerador proprio.
BLOCOS = {
    'C1': [(143, 286), (294, 425)],
    'F1': [(437, 540)],
    'F2': [(549, 601)],
    'P2': [(1015, 1388)],
    'M1': [(1398, 1601)],
    'P9': [(1615, 1667), (1689, 1742), (1767, 1808), (4165, 4213)],
}
BRANCO = re.compile(r"^[LR]PAD\s*\(\s*'\s*'\s*,\s*\d+\s*\)$", re.I)


def regua(pave):
    """Inicio (1-based) de cada campo da notice, por concatenacao pura."""
    out, p = [], 1
    for c in notice.carrega()[pave]:
        out.append((c['ref'], p, int(c['len'])))
        p += int(c['len'])
    return out


def tokens(a, b):
    """[(inicio 1-based, largura, raw, e_branco)] do bloco."""
    out, pos = [], 1
    for t in A.tokenize(a - 1, b):
        w = A.width(t['raw'])
        raw = re.sub(r'\s+', ' ', t['raw']).strip()
        out.append((pos, w, raw, bool(BRANCO.match(raw))))
        pos += w or 0
    return out


def classifica(pave, a, b):
    ts = tokens(a, b)
    semlarg = [t for t in ts if t[1] is None]
    fim = {t[0] for t in ts}                       # inicios = fronteiras
    conta = {'FRONTEIRA': 0, 'BRANCO': 0, 'DENTRO': 0, 'FORA': 0}
    maos = []
    for ref, ini, ln in regua(pave)[1:]:           # o 1o campo nao leva ';'
        if ini in fim:
            conta['FRONTEIRA'] += 1
            continue
        t = next((t for t in ts if t[1] and t[0] < ini < t[0] + t[1]), None)
        if t is None:
            conta['FORA'] += 1
        elif t[3]:
            conta['BRANCO'] += 1
        else:
            conta['DENTRO'] += 1
            maos.append((ref, ini, t[2][:60]))
    dados = sum(t[1] or 0 for t in ts)
    return ts, semlarg, conta, maos, dados


if __name__ == '__main__':
    campos = notice.carrega()
    for pave, bs in BLOCOS.items():
        n = len(campos[pave])
        soma = sum(int(c['len']) for c in campos[pave])
        print('%s : %d campos na notice, %d octetos de dados, %d separadores'
              % (pave, n, soma, n - 1))
        for a, b in bs:
            ts, semlarg, conta, maos, dados = classifica(pave, a, b)
            print('   bloco %4d-%-4d %3d tokens, %4d octetos medidos, %d sem largura'
                  % (a, b, len(ts), dados, len(semlarg)))
            print('      %s' % '  '.join('%s %d' % (k, v) for k, v in conta.items()))
            for ref, ini, raw in maos[:6]:
                print('        a mao: %-12s pos %-5d %s' % (ref, ini, raw))
            if len(maos) > 6:
                print('        ... e mais %d' % (len(maos) - 6))
