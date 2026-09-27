# -*- coding: utf-8 -*-
"""Gera o spool do Adapte com separador ';' entre todos os campos -- SIRL-1222.

    python gen_spool_adap.py

Le o 030_spool_Extract_CRRADAP.sql (que NAO se altera) e escreve o
030_spool_Extract_CRRADAP_1222.sql. No servidor, o ficheiro gerado substitui o
${SQL}/030_spool_Extract_CRRADAP.sql.

COMO SE RESOLVE CADA CAMPO DA REGUA
-----------------------------------
  EXATO    o campo tem as fronteiras de um token do spool -> copia-se o token
  EMENDA   varios tokens cobrem o campo exactamente -> concatenam-se
  BRANCO   o campo cai dentro de um RPAD(' ', n) -> parte-se em n campos
  NOVO     campo criado na V45 que o spool V44 nao escreve -> sai em branco
  REGRA    escrito a mao, com a razao ao lado (ver REGRAS)
  FILLER   o A1 99.99, que fecha a linha

A conta, igual nos tres blocos:

    981 (os 90 campos) + 90 (';') + 929 (filler A1 99.99) = 2000

O filler final NAO leva ';' a seguir, que e a regra da SFG para os fluxos de
formato fixo: «les champs "Filler" en fin d'enregistrement sont a alimenter avec
des blancs et ne doivent pas etre suivis du separateur ";"». Hoje o spool fecha
com LPAD(' ', 1164); passa a 929, que e o que a notice da ao campo -- encolhe
exactamente os 90 octetos dos separadores.

DUAS DIFERENCAS EM RELACAO AO CORPORATE
---------------------------------------
  1. a linha sai numa SO coluna ('as lignedetail'): 2000 octetos cabem nos 4000
     de uma expressao SQL. Nao ha COLSEP nem campo partido entre colunas;
  2. os 17 campos criados na V45 estao todos no fim da regua e saem em branco --
     12 sao 'Ne pas alimenter' na propria notice, 5 esperam a coluna nova da
     tabela A1_DEGRADE_GMBH (ficheiro da MERCA) e 1 espera clarificacao.
     Nenhum deles muda o numero de ';': a regua ja conta com eles.
"""
import collections
import io
import re
import sys

import notice_adap

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import casa_adap as CA                # noqa: E402  (blocos, tokens, regua)
import casa_paves as CP               # noqa: E402  (o alinhamento)
import gen_spool_paves as GP          # noqa: E402  (ascii_seguro, so_ascii, RPAD)
sys.stdout = _o

FONTE = CA.FONTE
SAIDA = '030_spool_Extract_CRRADAP_1222.sql'
LINHA = 2000
VERSAO = '-- VERSAO 2026-09-27a : o Adapte com ";" entre todos os campos.'

# Os campos de texto, onde um ';' nos dados pode aparecer e partir o ficheiro. A
# DSID respondeu que se troca por '.' (respostas.txt), e a SFG poe o mesmo como
# ponto de atencao: «verifier s'il y a des adresses, raisons sociales et des
# donnees contenant des points-virgules». No Adapte nao ha nomes nem moradas --
# os campos de texto sao codigos -- mas a defesa fica igual a do Corporate,
# porque o risco e de todas as corridas e nao desta.
ALPHA = {c['ref'] for c in notice_adap.carrega()['A1']
         if c['fmt'].upper().startswith('ALPHA')}

# Escrito a mao, por bloco (tabela do FROM) e referencia.
#
# O A1_DEGRADE_AUTO escreve o CD_MOTEUR num RPAD de 7, tapando dois campos da
# notice: o A1 3.5 (2) e a zona livre A1 3.98 (5). Os outros dois blocos ja os
# escrevem separados -- o A1_CRRV4_DEGRADE com RPAD(NVL(CD_MOTEUR,' '), 2) e o
# A1_DEGRADE_GMBH com RPAD('01', 2). Partir aqui poe os tres a dizer o mesmo, e
# nao muda o que sai: nas 1774 linhas do CRRADAP.dat o A1 3.5 e '01' em todas e
# o A1 3.98 esta em branco em todas, ou seja o CD_MOTEUR nunca passa de 2
# caracteres -- e o bloco 1 ja o truncaria a 2 se passasse.
REGRAS = {
    'A1_DEGRADE_AUTO': {
        "A1 3.5":  "RPAD( NVL(C_ENR.CD_MOTEUR, ' '), 2 )",
        "A1 3.98": "RPAD( ' ', 5 )",
    },
}


def repara_mojibake(linhas):
    """Repoe as 20 linhas de comentario que estao em UTF-8 dentro de um cp1252.

    O ficheiro de origem e cp1252, mas os comentarios franceses foram gravados
    em UTF-8 por alguem: lidos em cp1252 sai 'CrÃ©ation' por 'Creation' e 'Â§01'
    por '§01'. Dobrar isso para ASCII directamente daria 'CrAeation' e 'AA01' --
    lixo. Decodifica-se primeiro (os octetos sao UTF-8 valido nas 20 linhas) e so
    depois e que o so_ascii lhes tira os acentos.

    Repete-se enquanto der, porque algumas linhas estao codificadas DUAS vezes:
    o '§' do '-- §01' esta la como C3 82 C2 A7, que e o UTF-8 de C2 A7, que e o
    UTF-8 de '§'. Uma passagem so dava 'Â§', e dobrado para ASCII saia 'A01'.
    Outras, como o 'Adapté' da linha da Notice, estao codificadas uma vez. Por
    isso o numero de passagens nao se pode fixar: repete-se ate parar de mudar.

    Se uma linha nao for UTF-8 valido, fica na ultima forma boa: o so_ascii
    dobra-a como conseguir. Nao se mexe em linhas que ja sao ASCII.
    """
    out, reparadas = [], 0
    for l in linhas:
        if all(ord(c) < 128 for c in l):
            out.append(l)
            continue
        n = 0
        while True:
            try:
                r = l.encode('cp1252').decode('utf-8')
            except (UnicodeEncodeError, UnicodeDecodeError):
                break
            if r == l:
                break
            l, n = r, n + 1
        out.append(l)
        reparadas += 1 if n else 0
    return out, reparadas


def regua():
    """[(ref, largura, novo_v45, modif)] dos 91 campos, com o filler final."""
    return [(c['ref'], int(c['len']), c['novo_v45'], c['modif'])
            for c in notice_adap.carrega()['A1']]


def resolve(tab, l):
    r = REGRAS.get(tab, {}).get(l['ref'])
    if r:
        return r, 'REGRA'
    if l['estado'] == 'igual':
        return l['raw'][0], 'EXATO'
    if l['estado'] == 'emenda':
        # entre parenteses, senao o medidor torna a parti-la nos '||'
        return '(%s)' % '||'.join(l['raw']), 'EMENDA'
    if l['estado'] in ('junta', 'NOVO'):
        return "RPAD(' ', %d)" % l['len'], 'BRANCO' if l['estado'] == 'junta' else 'NOVO'
    return None, None


def bloco(lin, tab, a, b):
    """(linhas novas do bloco, censo, dados, separadores, filler)."""
    campos = regua()
    filler = campos[-1]
    if not filler[0].endswith('99.99'):
        raise SystemExit('o ultimo campo da regua nao e o filler: %s' % filler[0])
    ts = CA.tokens(a, b, lin)
    uteis = [t for t in ts if not (t[3] and t[1] and t[1] > 300)]
    semlarg = [t for t in uteis if t[1] is None]
    if semlarg:
        raise SystemExit('%s: %d tokens sem largura medida: %s'
                         % (tab, len(semlarg), semlarg[0][2][:60]))

    corpo, censo, faltam = [], collections.Counter(), []
    for l in CP.alinha(campos[:-1], uteis):
        e, cl = resolve(tab, l)
        if e is None:
            faltam.append(l)
            continue
        censo[cl] += 1
        if any(ord(c) > 127 for c in e):
            e = GP.ascii_seguro(e)
            censo['ASCII'] += 1
        if l['ref'] in ALPHA:
            e, trocado = CA.A.sem_pv(e)
            if trocado:
                censo['SEM-PV'] += 1
        e, forcado = GP.forca_largura(e, l['len'])
        if forcado:
            censo['RPAD'] += 1
        corpo.append("       %s||';'||   -- %-12s %s" % (e, l['ref'], cl))
    if faltam:
        for l in faltam[:20]:
            print('   %-8s %-12s spool %s notice %d  %s'
                  % (l['estado'], l['ref'], l['w'], l['len'],
                     (l['raw'][0] if l['raw'] else '')[:60]))
        raise SystemExit('%s: %d campos sem regra' % (tab, len(faltam)))
    if len(corpo) != len(campos) - 1:
        raise SystemExit('%s: %d campos escritos, a regua tem %d'
                         % (tab, len(corpo), len(campos) - 1))

    dados = sum(c[1] for c in campos[:-1])
    sep = len(campos) - 1                    # um ';' depois de cada campo, menos o filler
    total = dados + sep + filler[1]
    if total != LINHA:
        raise SystemExit('%s: %d + %d + %d = %d, esperado %d'
                         % (tab, dados, sep, filler[1], total, LINHA))

    # A coluna acaba no 'as lignedetail', que no ficheiro esta na MESMA linha do
    # filler que fecha os 2000 ('LPAD( \' \', 1164) as lignedetail'). Cortar a
    # linha anterior deixaria esse filler de pe ao lado do novo.
    c1 = next(i for i in range(a, b + 1)
              if re.search(r'as\s+lignedetail', lin[i - 1], re.I))
    corpo.append("       RPAD(' ', %d) as lignedetail   -- %-12s FILLER"
                 " (%d - %d separadores, sem ';' a seguir)"
                 % (filler[1], filler[0], filler[1] + sep, sep))
    return ['select'] + corpo + lin[c1:b], censo, dados, sep, filler[1]


def escreve():
    bl, lin = CA.blocos(FONTE)
    if not bl:
        raise SystemExit('nenhum bloco encontrado em %s' % FONTE)
    saida, trocas = list(lin), []
    for tab, a, b in bl:
        novo, censo, dados, sep, fil = bloco(lin, tab, a, b)
        trocas.append((a, b, novo))
        print('%-20s linhas %d-%d : dados %d + separadores %d + filler %d = %d'
              % (tab, a, b, dados, sep, fil, dados + sep + fil))
        print('   %s' % '  '.join('%s %d' % (k, censo[k]) for k in sorted(censo)))
    for a, b, novo in sorted(trocas, reverse=True):
        saida[a - 1:b] = novo

    # a marca da versao, logo depois da linha da Notice do cabecalho
    i = next(i for i, l in enumerate(saida) if l.startswith('-- Notice'))
    saida[i + 1:i + 1] = [
        VERSAO,
        '--   Gerado por gen_spool_adap.py a partir de ' + FONTE + '.',
        '--   Regua: Notice PACTV4.5_Adapte_Adapted_V45.00, aba A1.',
        '--   Conferir no servidor com: grep VERSAO 030_spool_Extract_CRRADAP.sql',
    ]
    saida, reparadas = repara_mojibake(saida)
    saida, dobradas = GP.so_ascii(saida)
    print('ASCII puro: %d linhas reparadas de UTF-8, %d dobradas'
          % (reparadas, dobradas))
    # cp1252 e CRLF, como o ficheiro que este vai substituir
    io.open(SAIDA, 'w', encoding='cp1252', newline='\r\n').write('\n'.join(saida))
    print('escreveu %s (%d linhas)' % (SAIDA, len(saida)))


if __name__ == '__main__':
    escreve()
