# -*- coding: utf-8 -*-
"""Gera os outros seis paves do CRRCORP com separador ';' -- SIRL-1222.

O P1 tem gerador proprio (gen_spool_1222.py), porque o SIRL-1224 o passou a ler
da tabela ENG_CORP_P1_BIS, campo a campo. Os outros seis mantem os seus select:
aqui o ';' entra por CORTE dos tokens que la estao.

COMO SE RESOLVE CADA CAMPO DA NOTICE
------------------------------------
  EXATO    o campo tem as fronteiras de um token -> copia-se o token
  EMENDA   varios tokens cobrem o campo exatamente -> concatenam-se
  BRANCO   o campo cai dentro de um filler -> RPAD(' ', tamanho)
  REGRA    escrito a mao em REGRAS, cada um com a sua razao
  FILLER   o filler final, que e o que falta para fechar a coluna 1

O que o mapa_paves.py mediu: F1, F2 e P9 nao levam nenhuma REGRA; o P2 leva 19,
o M1 22 e o C1 cerca de 54 (o C1 escreve num token so o que a notice separa em
tres campos, e por isso vai por ultimo).

O FILLER FINAL E A CAUDA
------------------------
Ao contrario do P1, nestes paves o filler final quase todo nao esta escrito: vem
do 'SET linesize 8000' com 'trimspool OFF', que enche a linha de brancos. Por
isso os separadores nao empurram nada -- encolhe-se so o RPAD(' ') que fecha a
coluna 1, e a coluna 2 fica como estava, byte a byte.

Cabe: os campos com os separadores dao 588 (F2), 902 (F1), 525 (P9), 1085 (C1),
1963 (M1) e 3982 (P2), todos dentro dos 4000 da coluna 1. O P2 e o apertado, com
18 octetos de margem.

ORDEM DE EXECUCAO
-----------------
    python gen_spool_1222.py     # escreve o ficheiro com o P1 novo
    python gen_spool_paves.py    # acrescenta-lhe estes paves

O bloco novo calcula-se sempre sobre o spool vPACT limpo; o que se escreve e o
ficheiro que ja leva o P1. Os blocos acham-se pela tabela do FROM, nao por numero
de linha, porque o P1 novo ja desloca o ficheiro. Antes de trocar, confere-se que
o bloco no alvo e igual ao do vPACT -- se nao for, para, em vez de escrever em
cima de um bloco ja gerado.
"""
import collections
import io
import os
import sys

import notice

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import mapa_paves as MP               # noqa: E402  (tokens, regua, blocos)
sys.stdout = _o

import re                             # noqa: E402

COL1 = 4000
FONTE = MP.FONTE
SAIDA = '030_spool_Extract_CRRCORP_1222.sql'   # o mesmo ficheiro do P1

# Paves gerados nesta corrida. Acrescenta-se um de cada vez, por isso a ordem:
# primeiro os que nao levam REGRA nenhuma.
PAVES = ('F2', 'F1', 'P9')

# Campos escritos a mao, por pave. Um por um, com a razao.
REGRAS = {}


def limites(linhas, a, b):
    """(linha do 'as lignedetail1', linha do 'as lignedetail2'), 1-based."""
    c1 = next(i for i in range(a, b + 1)
              if re.search(r'as\s+lignedetail1', linhas[i - 1], re.I))
    c2 = next(i for i in range(c1, b + 1)
              if re.search(r'as\s+lignedetail2', linhas[i - 1], re.I))
    return c1, c2


def resolve(pave, campos, ts, i):
    """(expressao, classe) para o campo i, ou (None, None) se nao se souber."""
    ref, ini, ln = campos[i]
    fim = ini + ln
    r = REGRAS.get(pave, {}).get(ref)
    if r:
        return r, 'REGRA'
    dentro = [t for t in ts if t[1] and t[0] < fim and t[0] + t[1] > ini]
    if len(dentro) == 1 and dentro[0][0] == ini and dentro[0][1] == ln:
        return dentro[0][2], 'EXATO'
    # Branco antes de emenda: varios fillers seguidos valem um RPAD so, e assim
    # o campo fica num token unico. Uma emenda de tokens com valor vai entre
    # parenteses, senao o medidor torna a parti-la nos '||'.
    if dentro and all(t[3] for t in dentro):
        return "RPAD(' ', %d)" % ln, 'BRANCO'
    if dentro and dentro[0][0] == ini and dentro[-1][0] + dentro[-1][1] == fim:
        return '(%s)' % '||'.join(t[2] for t in dentro), 'EMENDA'
    return None, None


def bloco(linhas, pave, a, b):
    """O texto novo do bloco, e o censo das classes."""
    campos = MP.regua(pave)
    c1, _c2 = limites(linhas, a, b)
    ts = MP.tokens(a, c1 - 1)
    nfim = len(campos) - 1                    # indice do filler final
    if not campos[nfim][0].endswith('99.99'):
        raise SystemExit('%s: o ultimo campo da notice nao e o filler: %s'
                         % (pave, campos[nfim][0]))

    corpo, censo, faltam = [], collections.Counter(), []
    for i in range(nfim):
        e, cl = resolve(pave, campos, ts, i)
        if e is None:
            faltam.append(campos[i])
            continue
        censo[cl] += 1
        corpo.append("       %s||';'||   -- %-12s %s" % (e, campos[i][0], cl))
    if faltam:
        print('%s: %d campos sem regra' % (pave, len(faltam)))
        for ref, ini, ln in faltam[:20]:
            print('   %-12s pos %-5d len %d' % (ref, ini, ln))
        raise SystemExit(1)

    dados = sum(c[2] for c in campos[:nfim])
    sep = nfim                                # um ';' depois de cada campo
    resto = COL1 - dados - sep
    if resto < 0:
        raise SystemExit('%s: a coluna 1 estoura em %d octetos' % (pave, -resto))
    censo['FILLER'] += 1
    corpo.append("       RPAD(' ', %d)     -- %-12s FILLER (%d - %d separadores"
                 " fica em branco por trimspool)"
                 % (resto, campos[nfim][0], campos[nfim][2], sep))

    cauda = linhas[c1 - 1:b]                  # 'as lignedetail1' ate ao ';'
    return ['select'] + corpo + cauda, censo, dados, sep, resto


def escreve():
    # 1. o bloco novo calcula-se sobre o spool vPACT limpo
    fonte, blocos_fonte = MP.carrega_fonte(FONTE)
    novos = {}
    for pave in PAVES:
        for k, (a, b) in enumerate(blocos_fonte[pave]):
            novo, censo, dados, sep, resto = bloco(fonte, pave, a, b)
            novos[(pave, k)] = (fonte[a - 1:b], novo)
            print('%s bloco %d-%d : dados %d + separadores %d + filler %d = %d'
                  % (pave, a, b, dados, sep, resto, dados + sep + resto))
            print('   %s' % '  '.join('%s %d' % (k2, censo[k2])
                                      for k2 in sorted(censo)))

    # 2. escreve-se no ficheiro que ja leva o P1 novo
    alvo = SAIDA if os.path.exists(SAIDA) else FONTE
    linhas, blocos_alvo = MP.carrega_fonte(alvo)
    saida, trocas = list(linhas), []
    for pave in PAVES:
        for k, (a, b) in enumerate(blocos_alvo[pave]):
            orig, novo = novos[(pave, k)]
            if linhas[a - 1:b] != orig:
                raise SystemExit('%s bloco %d-%d de %s nao e o do vPACT'
                                 ' (ja gerado?)' % (pave, a, b, alvo))
            trocas.append((a, b, novo))
    for a, b, novo in sorted(trocas, reverse=True):
        saida[a - 1:b] = novo
    open(SAIDA, 'w', encoding='latin-1', newline='\n').write('\n'.join(saida))
    print('partiu de %s, escreveu %s (%d linhas)' % (alvo, SAIDA, len(saida)))


if __name__ == '__main__':
    escreve()
