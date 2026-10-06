# -*- coding: utf-8 -*-
"""Confere os tres ficheiros do SIRL-1472, sem base de dados.

    python valida_hcrr.py

O que se verifica, por esta ordem:

  1. os tres tem as MESMAS 668 colunas, pela MESMA ordem da ENG_CORP_P1_BIS;
  2. os tipos batem entre a origem, a tabela do historico e o loader;
  3. no package, cada campo leva um ';' a seguir menos o ultimo -- 667;
  4. as instrucoes v_ligne := ... abrem e fecham todas;
  5. a largura declarada no loader e a da origem, campo a campo.

PORQUE E QUE ISTO E UM VALIDADOR E NAO UMA LEITURA
--------------------------------------------------
Sao 668 campos em tres ficheiros. Um deslocamento de UM campo entre a extraccao
e o loader nao da erro: carrega tudo uma coluna ao lado, e a data cai no campo
do montante. Nenhuma verificacao de formato apanha isso -- so a comparacao campo
a campo.
"""
import io
import re
import sys

import enc

FONTE = 'ENG_CORP_P1_BIS.sql'
PACK = 'PACK_HIST_ENG_CORP_P1_BIS.sql'
DDL = 'HIST_ENG_CORP_P1_BIS.sql'
CTL = 'HIST_ENG_CORP_P1_BIS.ctl'

erros = []
TETO = 8          # quantos erros se imprimem; um deslocamento de um campo da
                  # centenas, e a seguir ao primeiro nenhum acrescenta nada


def mal(msg):
    erros.append(msg)
    if len(erros) <= TETO:
        print('  ERRO  %s' % msg)
    elif len(erros) == TETO + 1:
        print('  ERRO  ... (os seguintes nao se imprimem: ver o total no fim)')


def tabela(caminho):
    """[(nome, tipo)] pela ordem do CREATE TABLE."""
    t, _ = enc.le(caminho)
    ls = t.split('\r\n') if '\r\n' in t else t.split('\n')
    i = next(n for n, l in enumerate(ls) if 'CREATE TABLE' in l.upper())
    j = next(n for n in range(i, len(ls)) if ls[n].strip().startswith(')'))
    out = []
    for n in range(i + 1, j):
        m = re.match(r'([A-Z][A-Z0-9_]*)\s+'
                     r'(VARCHAR2\(\d+\)|NUMBER\([\d,]+\)|NUMBER|DATE)',
                     ls[n].strip())
        if m:
            out.append((m.group(1), m.group(2)))
    return out


def do_package():
    """[(nome, como foi formatado)] pela ordem em que entram na linha."""
    t, _ = enc.le(PACK)
    ls = t.split('\r\n') if '\r\n' in t else t.split('\n')
    out, seps, abertas, fechadas = [], 0, 0, 0
    for l in ls:
        s = l.strip()
        if s.startswith('--'):
            continue
        if s.startswith('v_ligne :='):
            abertas += 1
        m = re.search(r'(TRANSLATE|TO_CHAR)\(C\.([A-Z][A-Z0-9_]*)[,)]', s)
        if m:
            if 'TRANSLATE' in m.group(1):
                como = 'texto'
            elif 'YYYYMMDDHH24MISS' in s:
                como = 'data'
            else:
                como = 'numero'
            out.append((m.group(2), como))
            # So os separadores a SERIO: os que vem a seguir ao campo, com "||"
            # a frente. O TRANSLATE(C.X, ';', '.') tem um ';' dentro que e
            # argumento, nao separador -- contar tudo dava 667 + 463 = 1130.
            seps += len(re.findall(r"\|\|\s*';'", s))
            if s.rstrip().endswith(';') and not s.rstrip().endswith("||"):
                if not s.rstrip().endswith("';'"):
                    fechadas += 1
    return out, seps, abertas, fechadas


def do_ctl():
    """[(nome, descritor)] pela ordem do loader."""
    t, _ = enc.le(CTL)
    ls = t.split('\r\n') if '\r\n' in t else t.split('\n')
    i = next(n for n, l in enumerate(ls) if l.strip() == '(')
    out = []
    for l in ls[i + 1:]:
        s = l.strip().rstrip(',')
        if s == ')':
            break
        m = re.match(r'([A-Z][A-Z0-9_]*)\s+(.+)$', s)
        if m:
            out.append((m.group(1), m.group(2).strip()))
    return out


def main():
    origem = tabela(FONTE)
    hist = tabela(DDL)
    pack, seps, abertas, fechadas = do_package()
    ctl = do_ctl()

    print('1) contagens')
    print('   %-34s %d colunas' % (FONTE, len(origem)))
    for nome, n in ((DDL, len(hist)), (PACK, len(pack)), (CTL, len(ctl))):
        print('   %-34s %d campos' % (nome, n))
    for nome, lista in ((DDL, hist), (PACK, pack), (CTL, ctl)):
        if len(lista) != len(origem):
            mal('%s tem %d campos, a origem tem %d'
                % (nome, len(lista), len(origem)))

    print('2) a ordem dos campos')
    for nome, lista in ((DDL, hist), (PACK, pack), (CTL, ctl)):
        fora = [(i, a[0], b[0]) for i, (a, b) in enumerate(zip(origem, lista), 1)
                if a[0] != b[0]]
        if fora:
            mal('%s: %d campos fora de ordem; o primeiro e o %d (%s, nao %s)'
                % (nome, len(fora), fora[0][0], fora[0][2], fora[0][1]))
        else:
            print('   %-34s igual a origem' % nome)

    print('3) os tipos')
    for (nome, tipo), (h, th) in zip(origem, hist):
        if tipo != th:
            mal('%s: a origem diz %s e o historico diz %s' % (nome, tipo, th))
    esperado = {'VARCHAR2': 'texto', 'NUMBER': 'numero', 'DATE': 'data'}
    for (nome, tipo), (p, como) in zip(origem, pack):
        k = 'VARCHAR2' if tipo.startswith('VARCHAR2') else (
            'DATE' if tipo == 'DATE' else 'NUMBER')
        if esperado[k] != como:
            mal('%s e %s na origem e esta formatado como %s' % (nome, tipo, como))
    for (nome, tipo), (c, d) in zip(origem, ctl):
        if tipo.startswith('VARCHAR2'):
            w = int(re.search(r'\((\d+)\)', tipo).group(1))
            if d != 'CHAR(%d)' % w:
                mal('%s e %s e o loader diz %s' % (nome, tipo, d))
        elif tipo == 'DATE':
            if not d.startswith('DATE "'):
                mal('%s e DATE e o loader diz %s' % (nome, d))
        elif d != 'DECIMAL EXTERNAL':
            mal('%s e %s e o loader diz %s' % (nome, tipo, d))
    if not erros:
        print('   todos os tipos batem nos tres')

    print('4) os separadores e as instrucoes, no package')
    print('   separadores: %d   (esperado %d)' % (seps, len(origem) - 1))
    if seps != len(origem) - 1:
        mal('o package poe %d separadores, a linha precisa de %d'
            % (seps, len(origem) - 1))
    print('   v_ligne := abertas %d, instrucoes fechadas %d' % (abertas, fechadas))
    if abertas != fechadas:
        mal('%d instrucoes abertas e %d fechadas: alguma nao acaba em ";"'
            % (abertas, fechadas))

    print()
    print('erros: %d' % len(erros))
    return 1 if erros else 0


if __name__ == '__main__':
    sys.exit(main())
