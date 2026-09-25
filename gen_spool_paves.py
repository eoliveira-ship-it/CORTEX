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
import casa_paves as CP               # noqa: E402  (alinhamento campo a campo)
sys.stdout = _o

import re                             # noqa: E402

COL1 = 4000
FONTE = MP.FONTE
SAIDA = '030_spool_Extract_CRRCORP_1222.sql'   # o mesmo ficheiro do P1

# Paves gerados nesta corrida. Acrescenta-se um de cada vez, por isso a ordem:
# primeiro os que nao levam REGRA nenhuma.
PAVES = ('F2', 'F1', 'P9', 'P2', 'M1', 'C1')

# Campos escritos a mao, por pave. Um por um, com a razao.
#
# Sao as sete unicas divergencias entre o spool e a Notice V45.02 nos seis paves,
# e todas do mesmo genero: o spool escreve o campo mais estreito do que a notice
# manda, e a partir dai tudo o que vem depois fica um octeto fora do sitio. Com o
# ';' pelo meio isso deixa de ser invisivel, por isso corrigem-se aqui -- e vao
# na lista de correcoes para a DSID, como o P1 21.65 do SIRL-1223.
REGRAS = {
    # Codigos de pais e de bolsa: a notice da-lhes 2, o spool escreve o valor da
    # coluna sem RPAD, que da 1. O ficheiro de referencia confirma o 1 (a zona de
    # dados do M1 acaba no octeto 1580 nas 65 559 linhas, e nao no 1583).
    'M1': {
        'M1 7.6':  "RPAD(NVL(C_ENR.cd_pays_recours, ' '), 2)",
        'M1 8.31': "RPAD(NVL(C_ENR.CD_BOURSE_COTATION, ' '), 2)",
        'M1 9.1':  "RPAD(NVL(C_ENR.CD_PAYS_LOCAL_GARANT, ' '), 2)",
    },
    # Quatro campos que o spool escreve como um literal de um branco, ' ', onde a
    # notice pede 2, 2, 5 e 2. Ficam em branco, so com a largura certa.
    'C1': {
        'C1 4.9':  "RPAD(' ', 2)",
        'C1 4.99': "RPAD(' ', 2)",
        'C1 8.12': "RPAD(' ', 5)",
        'C1 8.14': "RPAD(' ', 2)",
    },
}


def limites(linhas, a, b):
    """(linha do 'as lignedetail1', linha do 'as lignedetail2'), 1-based."""
    c1 = next(i for i in range(a, b + 1)
              if re.search(r'as\s+lignedetail1', linhas[i - 1], re.I))
    c2 = next(i for i in range(c1, b + 1)
              if re.search(r'as\s+lignedetail2', linhas[i - 1], re.I))
    return c1, c2


def resolve(pave, l):
    """(expressao, classe) para uma linha do alinhamento do casa_paves.

    O alinhamento vem de programacao dinamica, nao de sobreposicao por posicao:
    e o que permite gerar o M1 e o C1, onde ha campos que o spool escreve mais
    estreitos do que a notice manda e que punham tudo o que vem depois fora do
    sitio."""
    r = REGRAS.get(pave, {}).get(l['ref'])
    if r:
        return r, 'REGRA'
    if l['estado'] == 'igual':
        return l['raw'][0], 'EXATO'
    if l['estado'] == 'emenda':
        # entre parenteses, senao o medidor torna a parti-la nos '||'
        return '(%s)' % '||'.join(l['raw']), 'EMENDA'
    if l['estado'] == 'junta':
        return "RPAD(' ', %d)" % l['len'], 'BRANCO'
    if l['estado'] == 'NOVO':
        return "RPAD(' ', %d)" % l['len'], 'NOVO'
    return None, None


def bloco(linhas, pave, a, b):
    """O texto novo do bloco, e o censo das classes."""
    campos = MP.regua(pave)
    c1, _c2 = limites(linhas, a, b)
    nfim = len(campos) - 1                    # indice do filler final
    if not campos[nfim][0].endswith('99.99'):
        raise SystemExit('%s: o ultimo campo da notice nao e o filler: %s'
                         % (pave, campos[nfim][0]))

    corpo, censo, faltam = [], collections.Counter(), []
    for l in CP.casa(pave, a, b):
        if l['ref'] == campos[nfim][0]:
            continue                          # o filler final vai no fim
        e, cl = resolve(pave, l)
        if e is None:
            faltam.append(l)
            continue
        censo[cl] += 1
        corpo.append("       %s||';'||   -- %-12s %s" % (e, l['ref'], cl))
    if faltam:
        print('%s: %d campos sem regra' % (pave, len(faltam)))
        for l in faltam[:20]:
            print('   %-8s %-12s spool %s notice %d  %s'
                  % (l['estado'], l['ref'], l['w'], l['len'],
                     (l['raw'][0] if l['raw'] else '')[:60]))
        raise SystemExit(1)
    if len(corpo) != nfim:
        raise SystemExit('%s: %d campos escritos, a notice tem %d'
                         % (pave, len(corpo), nfim))

    dados = sum(c[2] for c in campos[:nfim])
    sep = nfim                                # um ';' depois de cada campo
    resto = COL1 - dados - sep
    if resto < 0:
        raise SystemExit('%s: a coluna 1 estoura em %d octetos' % (pave, -resto))
    censo['FILLER'] += 1
    corpo.append("       RPAD(' ', %d)     -- %-12s FILLER (%d - %d separadores"
                 " fica em branco por trimspool)"
                 % (resto, campos[nfim][0], campos[nfim][2], sep))

    # A coluna 1 acaba no 'as lignedetail1', que pode nao estar sozinho na linha:
    # num dos blocos do P9 o filler que fechava os 4000 esta escrito na mesma
    # linha ('LPAD(\' \', 3512) as lignedetail1'). Cortar a linha anterior deixava
    # esse filler de pe ao lado do novo -- 7512 octetos e um erro de sintaxe.
    resto_linha = re.search(r'as\s+lignedetail1.*$', linhas[c1 - 1], re.I)
    cauda = ['     ' + resto_linha.group(0)] + linhas[c1:b]
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
    # cp1252 e fim de linha do Windows, como o ficheiro que este vai substituir:
    # todos os .sql e .sh do repo estao em CRLF, e e assim que o spool vPACT que
    # gerou o ficheiro de referencia esta escrito.
    open(SAIDA, 'w', encoding='cp1252').write('\n'.join(saida))
    print('partiu de %s, escreveu %s (%d linhas)' % (alvo, SAIDA, len(saida)))


if __name__ == '__main__':
    escreve()
