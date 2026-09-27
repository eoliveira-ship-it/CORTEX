# -*- coding: utf-8 -*-
"""Nao-regressao do Adapte: o ficheiro com ';' contra o de antes -- SIRL-1222.

    python comparar_adap.py <CRRADAP.dat com ';'> <o de referencia, sem ';'>

Um diff directo nao serve: com os separadores todos os campos a seguir ao
primeiro estao noutro sitio. Este script desfaz a mudanca -- parte cada linha
nova pelos ';', confere que cada campo tem a largura da notice, e volta a cola-los
sem separador -- e compara o resultado com a referencia. Se der igual, o que
entrou foi o ';' e mais nada.

O que se verifica, por esta ordem:

  1. as quatro linhas do ficheiro (cabecalho, detalhe A1, Z9, rodape) tem o
     numero de ';' que a notice preve: 14, 90, 8 e 2;
  2. em cada linha de detalhe, os 91 campos tem a largura da notice;
  3. reconstruida sem ';' e com o filler antigo (1019 = 929 + 90), a linha tem
     de dar exactamente a da referencia.

A MASYSDATE (o campo 0.5) e mascarada nos dois lados: muda de corrida para
corrida. A linha de cabecalho tambem difere sempre, na data e no numero de envio.
"""
import collections
import hashlib
import sys

import notice_adap

LINHA = 2000


def carrega_regua():
    d = notice_adap.carrega()
    return {r: [(c['ref'], int(c['len'])) for c in cs] for r, cs in d.items()}


def tipo(ln):
    if ln.startswith(b'00;'):
        return 'ENTETE'
    if ln.startswith(b'99;'):
        return 'ENQUEUE'
    c = ln.split(b';')
    if len(c) > 5 and c[5] == b'Z9':
        return 'Z9'
    return 'A1'


def linhas(caminho):
    with open(caminho, 'rb') as f:
        for ln in f:
            yield ln.rstrip(b'\r\n')


def main(novo, ref):
    regua = carrega_regua()
    erros = 0

    # ---------------------------------------------------- 1. os quatro registos
    print('=== 1) separadores por registo')
    censo = collections.Counter()
    pv = collections.defaultdict(collections.Counter)
    det = []
    for ln in linhas(novo):
        t = tipo(ln)
        censo[t] += 1
        pv[t][ln.count(b';')] += 1
        if len(ln) != LINHA:
            print('  X linha de %d octetos (esperado %d)' % (len(ln), LINHA))
            erros += 1
        if t == 'A1':
            det.append(ln)
    for t in ('ENTETE', 'A1', 'Z9', 'ENQUEUE'):
        esperado = len(regua[t]) - 1
        obtido = dict(pv[t])
        ok = list(obtido) == [esperado]
        print('  %-8s %5d linhas   ";" %-12s notice %3d   %s'
              % (t, censo[t], obtido, esperado, 'ok' if ok else 'NAO BATE'))
        if not ok:
            erros += 1

    # ------------------------------------------- 2. as larguras campo a campo
    print()
    print('=== 2) larguras dos 91 campos, nas %d linhas de detalhe' % len(det))
    campos = regua['A1']
    mau = collections.Counter()
    for ln in det:
        c = ln.split(b';')
        if len(c) != len(campos):
            mau[('n campos', len(c))] += 1
            continue
        for (ref_, w), v in zip(campos, c):
            if len(v) != w:
                mau[(ref_, w, len(v))] += 1
    if mau:
        for k, q in mau.most_common(20):
            print('  X %s em %d linhas' % (k, q))
        erros += 1
    else:
        print('  todas as larguras batem com a notice')

    # ------------------------------------------------ 3. a reconstrucao antiga
    print()
    print('=== 3) reconstruido sem ";" contra a referencia')
    # o filler antigo: o da notice mais os separadores que nao existiam
    fil_novo = campos[-1][1]
    sep = len(campos) - 1
    fil_velho = fil_novo + sep

    def masc(b):
        # a MASYSDATE sao os 12 octetos do campo 0.5, no formato posicional
        return b[:26] + b'#' * 12 + b[38:]

    obtido = collections.Counter()
    for ln in det:
        c = ln.split(b';')
        velho = b''.join(c[:-1]) + b' ' * fil_velho
        if len(velho) != LINHA:
            print('  X reconstruida com %d octetos' % len(velho))
            erros += 1
            break
        obtido[hashlib.md5(masc(velho)).digest()] += 1

    esperado, n = collections.Counter(), 0
    for ln in linhas(ref):
        if ln[38:40] != b'A1':
            continue
        n += 1
        esperado[hashlib.md5(masc(ln)).digest()] += 1
    print('  linhas A1: %d no novo, %d na referencia' % (len(det), n))
    print('  filler: %d na notice + %d separadores = %d na referencia'
          % (fil_novo, sep, fil_velho))
    so_n, so_r = obtido - esperado, esperado - obtido
    if so_n or so_r:
        print('  X %d linhas so no novo, %d so na referencia'
              % (sum(so_n.values()), sum(so_r.values())))
        erros += 1
    else:
        print('  IDENTICAS: a unica mudanca e o ";".')

    print()
    print('erros: %d' % erros)
    return 1 if erros else 0


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
