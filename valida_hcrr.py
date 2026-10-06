# -*- coding: utf-8 -*-
"""Confere os quatro ficheiros do SIRL-1472, sem base de dados.

    python valida_hcrr.py

O que se verifica:

  1. os quatro falam das MESMAS 300 colunas, pela MESMA ordem da origem;
  2. os tipos batem entre a ENG_CORP_P1_BIS do DDR, a CRR e as duas HIS_;
  3. no spool: um '~' entre campos e nenhum no fim, e o linesize e a soma exacta;
  4. no package: cada INSERT lista as colunas e o SELECT le-as pela mesma ordem;
  5. nos dois ficheiros de producao nao se removeu nem alterou uma linha.

PORQUE E QUE ISTO E UM VALIDADOR E NAO UMA LEITURA
--------------------------------------------------
Sao 300 campos em quatro ficheiros. Um deslocamento de UM campo entre o spool e
a tabela de recepcao nao da erro: o SQL*Loader carrega tudo uma coluna ao lado,
e a data cai no campo do montante. Nenhuma verificacao de formato apanha isso --
so a comparacao campo a campo.

E A ULTIMA LINHA E A QUE MAIS IMPORTA
-------------------------------------
O 030_spool_data.sql e o pack_histo_crr.sql sao de PRODUCAO. O que entregamos
tem de ser eles mais o nosso bloco, e nada mais: por isso o ponto 5 exige que o
diff contra a origem seja so acrescentos, e falha se uma unica linha deles
desapareceu ou mudou -- incluindo os 130 acentos do package, que uma escrita em
cp1252 converteria sem dizer nada.
"""
import io
import re
import sys

import enc

BIS = 'ENG_CORP_P1_BIS.sql'
SPOOL = '030_spool_data.sql'
PACK = 'pack_histo_crr.sql'

SPOOL_OUT = '030_spool_data_1472.sql'
PACK_OUT = 'pack_histo_crr_1472.sql'
DDL_CRR = '030_create_table_ENG_CORP_P1_BIS_HCRR.sql'
DDL_HIS = '745_create_table_HIS_ENG_CORP_P1_BIS.sql'

TAB = 'ENG_CORP_P1_BIS'
HIS = 'HIS_ENG_CORP_P1_BIS'
PROCEDURE = 'p_histo_eng_corp_p1_bis'
FLUXO = '030_FLUX_2M_ENG_CORP_P1_BIS.txt'

erros = []
TETO = 8          # um deslocamento de um campo da centenas de erros; a seguir
                  # ao primeiro nenhum acrescenta nada


def mal(msg):
    erros.append(msg)
    if len(erros) <= TETO:
        print('  ERRO  %s' % msg)
    elif len(erros) == TETO + 1:
        print('  ERRO  ... (os seguintes nao se imprimem: ver o total no fim)')


def ls(caminho):
    t, _ = enc.le(caminho)
    return t.split('\r\n') if '\r\n' in t else t.split('\n')


def tabelas(caminho):
    """[(nome do CREATE TABLE, [(coluna, tipo)])] por ordem no ficheiro."""
    out = []
    linhas = ls(caminho)
    for i, l in enumerate(linhas):
        m = re.match(r'CREATE TABLE\s+([A-Za-z0-9_.]+)', l.strip(), re.I)
        if not m:
            continue
        cols = []
        for n in range(i + 1, len(linhas)):
            s = linhas[n].strip()
            if s.startswith(')'):
                break
            c = re.match(r'([A-Z][A-Z0-9_]*)\s+'
                         r'(VARCHAR2\(\d+\)|NUMBER\([\d,]+\)|NUMBER|DATE)', s)
            if c:
                cols.append((c.group(1), c.group(2)))
        out.append((m.group(1), cols))
    return out


def do_spool():
    """([campos], separadores, linesize) do nosso bloco, dentro do ficheiro."""
    linhas = ls(SPOOL_OUT)
    i = next(n for n, l in enumerate(linhas) if FLUXO in l)
    lin = int(re.search(r'linesize\s+(\d+)',
                        next(linhas[n] for n in range(i, 0, -1)
                             if 'linesize' in linhas[n])).group(1))
    campos, seps, fim = [], 0, None
    for n in range(i + 1, len(linhas)):
        s = linhas[n].strip()
        if s.startswith('from '):
            fim = s
            break
        seps += s.count("'~'")
        c = re.search(r"([A-Z][A-Z0-9_]*)\s*$", s.replace("||'~'||", ' '))
        if c:
            campos.append(c.group(1))
        elif "to_char(" in s:
            campos.append(re.search(r'to_char\(([A-Z][A-Z0-9_]*)', s).group(1))
    return campos, seps, lin, fim


def do_pack():
    """[(destino, [colunas do INSERT], [colunas do SELECT])] da nossa procedure."""
    linhas = ls(PACK_OUT)
    i = next((n for n, l in enumerate(linhas)
              if l.strip().startswith('PROCEDURE %s IS' % PROCEDURE)), None)
    if i is None:
        mal('nao achei a PROCEDURE %s no corpo de %s' % (PROCEDURE, PACK_OUT))
        return []
    j = next(n for n in range(i, len(linhas))
             if linhas[n].strip() == 'END %s;' % PROCEDURE)
    out, n = [], i
    while n < j:
        m = re.match(r'INSERT INTO\s+([A-Za-z0-9_.]+)', linhas[n].strip())
        if not m:
            n += 1
            continue
        ins, sel, onde = [], [], None
        n += 1
        for k in range(n, j):
            s = linhas[k].strip()
            if s == 'SELECT':
                onde = sel
                continue
            if s.startswith('FROM '):
                n = k
                break
            # a producao alinha a virgula: "DT_ARRETE      ,". Sem o \s* aqui
            # o leitor achava 2 campos de 300 e eu culpava o gerador.
            c = re.match(r'([A-Z][A-Z0-9_]*)\s*,?$', s)
            if c:
                (ins if onde is None else onde).append(c.group(1))
        out.append((m.group(1), ins, sel))
        n += 1
    return out


def so_acrescentos(origem, nosso):
    """Nenhuma linha da origem desapareceu nem mudou, e os acentos mantem-se."""
    a, b = ls(origem), ls(nosso)
    i = 0
    for l in a:
        while i < len(b) and b[i] != l:
            i += 1
        if i >= len(b):
            return None, 'a linha "%s" da origem nao esta no gerado' % l[:60]
        i += 1
    oa = sum(1 for c in io.open(origem, 'rb').read() if c > 127)
    ob = sum(1 for c in io.open(nosso, 'rb').read() if c > 127)
    if oa != ob:
        return None, ('%s tem %d octetos acentuados e o gerado tem %d: '
                      'a codificacao mudou' % (origem, oa, ob))
    return len(b) - len(a), None


def main():
    origem = dict(tabelas(BIS))[TAB]
    print('1) de onde se parte')
    print('   %-44s %d colunas' % (BIS, len(origem)))

    campos, seps, lin, fim = do_spool()
    ref = [c for c, _t in origem if c in set(campos)]
    print('   %-44s %d campos no fluxo' % (SPOOL_OUT, len(campos)))

    print('2) a ordem dos campos')
    tudo = [(SPOOL_OUT, campos)]
    for f in (DDL_CRR, DDL_HIS):
        for nome, cols in tabelas(f):
            tudo.append(('%s (%s)' % (f, nome), [c for c, _t in cols]))
    for dest, ins, sel in do_pack():
        tudo.append(('%s INSERT %s' % (PACK_OUT, dest), ins))
        tudo.append(('%s SELECT %s' % (PACK_OUT, dest), sel))
    for nome, lista in tudo:
        if len(lista) != len(ref):
            mal('%s: %d campos, esperava %d' % (nome, len(lista), len(ref)))
            continue
        fora = [(i, a, b) for i, (a, b) in enumerate(zip(ref, lista), 1) if a != b]
        if fora:
            mal('%s: %d fora de ordem; o primeiro e o %d (%s, nao %s)'
                % (nome, len(fora), fora[0][0], fora[0][2], fora[0][1]))
        else:
            print('   %-54s %d campos, igual a origem' % (nome, len(lista)))
    if len(tudo) != 8:
        mal('esperava 8 listas de campos (1 spool + 3 tabelas + 2x2 no package),'
            ' achei %d' % len(tudo))

    print('3) os tipos, tabela a tabela')
    esp = dict(origem)
    for f in (DDL_CRR, DDL_HIS):
        for nome, cols in tabelas(f):
            dif = [(c, t, esp.get(c)) for c, t in cols if esp.get(c) != t]
            if dif:
                mal('%s.%s: %s e %s e a origem diz %s'
                    % (f, nome, dif[0][0], dif[0][1], dif[0][2]))
            else:
                print('   %-54s tipos iguais a origem' % nome)

    print('4) o fluxo')
    largo = sum(larg(esp[c]) for c in campos) + len(campos) - 1
    print('   separadores %d   (esperado %d)' % (seps, len(campos) - 1))
    if seps != len(campos) - 1:
        mal('%d separadores para %d campos' % (seps, len(campos)))
    print('   linesize %d   (a soma das larguras da %d)' % (lin, largo))
    if lin != largo:
        mal('o linesize diz %d e a linha pode chegar a %d' % (lin, largo))
    if lin > 4000:
        mal('linesize %d: passa o limite de 4000 de uma expressao SQL' % lin)
    if fim != 'from %s;' % TAB:
        mal('o spool acaba em "%s", esperava "from %s;"' % (fim, TAB))
    else:
        print('   le a %s e escreve o %s' % (TAB, FLUXO))

    print('5) os dois ficheiros de producao, intactos')
    for o, n in ((SPOOL, SPOOL_OUT), (PACK, PACK_OUT)):
        mais, erro = so_acrescentos(o, n)
        if erro:
            mal(erro)
        else:
            print('   %-44s +%d linhas, nada removido' % (n, mais))

    print()
    print('erros: %d' % len(erros))
    return 1 if erros else 0


def larg(t):
    """Os mesmos octetos que o gen_hcrr.py conta. Se divergir, o ponto 4 cai."""
    if t.startswith('VARCHAR2'):
        return int(re.search(r'\((\d+)\)', t).group(1))
    if t == 'DATE':
        return 8
    m = re.search(r'\(([\d,]+)\)', t)
    if not m:
        return 40
    p = m.group(1).split(',')
    ints, dec = int(p[0]), (int(p[1]) if len(p) > 1 else 0)
    return 1 + ints + (1 + dec if dec else 0)


if __name__ == '__main__':
    sys.exit(main())
