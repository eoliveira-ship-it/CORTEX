# -*- coding: utf-8 -*-
"""Onde e que o spool do Adapte e a notice V45.00 do Adapte discordam.

O mesmo trabalho que o casa_paves.py faz no Corporate, no CRRADAP: percorre-se
cada bloco do 030_spool_Extract_CRRADAP.sql token a token e a regua dos 91
campos campo a campo, e diz-se em que e que nao batem. O alinhamento e o do
casa_paves.alinha -- programacao dinamica, minimiza anomalias -- porque um passo
guloso dessincroniza na primeira divergencia e a partir dai acusa tudo.

Duas diferencas em relacao ao Corporate:

  1. o spool do Adapte escreve a linha numa so coluna ('as lignedetail'), porque
     os 2000 octetos cabem nos 4000 de uma expressao SQL. Nao ha o COLSEP nem o
     campo partido entre duas colunas;
  2. sao tres blocos com a mesma regua, um por tabela de origem:
     A1_CRRV4_DEGRADE, A1_DEGRADE_AUTO e A1_DEGRADE_GMBH.

Uso:  python casa_adap.py
"""
import collections
import io
import re
import sys

import notice_adap

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import align_v44 as A                 # noqa: E402
import casa_paves as CP               # noqa: E402  (so pelo alinha)
import mapa_paves as MP               # noqa: E402  (so pelo medidor de largura)
sys.stdout = _o

FONTE = '030_spool_Extract_CRRADAP.sql'
BRANCO = re.compile(r"^[LR]PAD\s*\(\s*'\s*'\s*,\s*\d+\s*\)$", re.I)


def blocos(caminho=FONTE):
    """[(tabela de origem, primeira linha, ultima linha)] 1-based, um por SELECT.

    O bloco vai do 'select' sozinho numa linha ate a linha antes do 'FROM', e
    chama-se pela tabela do FROM. Nao se usa o comentario do cabecalho de cada
    bloco ('-- 01: a partir de ...') porque o ficheiro traz o paragrafo '§' em
    UTF-8 dentro de um ficheiro cp1252, e lido nao e um caractere previsivel.
    """
    lin = io.open(caminho, encoding='cp1252').read().split('\n')
    out, ini = [], None
    for i, l in enumerate(lin, 1):
        if re.match(r'^\s*select\s*$', l, re.I):
            ini = i
        elif ini and re.match(r'^\s*from\b', l, re.I):
            tab = re.match(r'^\s*from\s+(\S+)', l, re.I).group(1)
            out.append((tab, ini, i - 1))
            ini = None
    return out, lin


def tokens(a, b, lin):
    """[(inicio 1-based, largura, raw, e_branco)] do bloco, como o mapa_paves.

    O A.tokenize le do A.lines, que o align_v44 carrega com o spool do
    Corporate. Troca-se pelo do Adapte durante a leitura e repoe-se: e a mesma
    funcao, outro ficheiro.
    """
    guardado = A.lines
    A.lines = lin
    try:
        brutos = A.tokenize(a - 1, b)
    finally:
        A.lines = guardado
    out, pos = [], 1
    for t in brutos:
        raw = A.achata(t['raw']).strip()
        w = MP.largura(raw)
        out.append((pos, w, raw, bool(BRANCO.match(raw))))
        pos += w or 0
    return out


def regua():
    """[(ref, largura, novo_v45, modif)] dos 90 campos, sem o filler final.

    Sem o filler: ele nao se alinha com nada -- e o que sobra da linha, e no
    formato novo encolhe de 1019 para 929 (os 90 ';' que entram).
    """
    cs = notice_adap.carrega()['A1']
    return [(c['ref'], int(c['len']), c['novo_v45'], c['modif']) for c in cs[:-1]]


def main():
    cs = regua()
    bl, lin = blocos()
    if not bl:
        raise SystemExit('nenhum bloco encontrado em %s' % FONTE)
    print('regua: %d campos (%d octetos) + o filler final'
          % (len(cs), sum(c[1] for c in cs)))
    mau_total = 0
    for com, a, b in bl:
        ts = tokens(a, b, lin)
        # o filler que fecha a linha nao entra no alinhamento, como na regua
        uteis = [t for t in ts if not (t[3] and t[1] and t[1] > 300)]
        semlarg = [t for t in uteis if t[1] is None]
        linhas = CP.alinha(cs, uteis)
        conta = collections.Counter(l['estado'] for l in linhas)
        mau = [l for l in linhas
               if l['estado'] in ('DIVERGE', 'FALTA', 'SOBRA', 'PARTE')]
        mau_total += len(mau)
        print()
        print('%-28s linhas %d-%d : %d tokens (%d octetos medidos)%s'
              % (com[:28], a, b, len(uteis), sum(t[1] or 0 for t in uteis),
                 '' if not semlarg else '   %d SEM LARGURA' % len(semlarg)))
        print('   %s' % '  '.join('%s %d' % (k, v) for k, v in sorted(conta.items())))
        for t in semlarg:
            print('   ? sem largura: %s' % t[2][:70])
        for l in mau:
            print('   %-8s %-11s spool %-5s notice %-4d  %s | %s'
                  % (l['estado'], l['ref'], l['w'], l['len'], l['modif'],
                     (l['raw'][0] if l['raw'] else '')[:60]))
    print()
    print('anomalias: %d' % mau_total)
    return 1 if mau_total else 0


if __name__ == '__main__':
    sys.exit(main())
