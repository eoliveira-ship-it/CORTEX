# -*- coding: utf-8 -*-
"""Verifica o spool do Adapte gerado, sem base de dados.

    python valida_adap_1222.py

Le o 030_spool_Extract_CRRADAP_1222.sql e, em cada um dos tres blocos:

  1. mede a largura de cada expressao e compara com o que a notice V45.00 do
     Adapte da ao campo;
  2. confirma que todos os campos levam ';' no fim, menos o filler final;
  3. soma: os 91 campos + os 90 ';' tem de dar 2000, e a expressao tem de caber
     nos 4000 de uma coluna SQL;
  4. nao-regressao: descascando o TRANSLATE do sem_pv, cada expressao tem de ser
     identica a que esta no spool de origem -- menos os fillers partidos, os 17
     campos novos da V45 e as 2 REGRAS. Se nao for, mudou-se alguma coisa que
     nao era o ';'.

Sai com erro se alguma coisa nao bater.
"""
import collections
import io
import re
import sys

import notice_adap

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import casa_adap as CA                # noqa: E402  (tokens, blocos, medidor)
import gen_spool_adap as G            # noqa: E402  (REGRAS, SAIDA, FONTE)
sys.stdout = _o

LINHA = 2000
LIMITE_SQL = 4000
CAMPOS = {c['ref']: c for c in notice_adap.carrega()['A1']}


def blocos_gerados(caminho=G.SAIDA):
    """[(tabela, [(expressao, ref, classe, tem_sep), ...])]"""
    lin = io.open(caminho, encoding='cp1252').read().split('\n')
    out, atual, tab = [], None, None
    for l in lin:
        if re.match(r'^\s*select\s*$', l, re.I):
            atual = []
            continue
        if atual is None:
            continue
        m = re.match(r'^\s+(.*?)\s*--\s+(\S+(?: \S+)?)\s+([A-Z-]+)(?:\s|$)', l)
        if m:
            expr, ref, cl = m.group(1), m.group(2), m.group(3)
            sep = False
            for suf in ("||';'||", "||';'"):
                if expr.endswith(suf):
                    expr, sep = expr[:-len(suf)], True
                    break
            expr = re.sub(r'\s+as\s+lignedetail\s*$', '', expr, flags=re.I)
            atual.append((expr.rstrip('|').strip(), ref, cl, sep))
        elif re.match(r'^\s*from\b', l, re.I):
            tab = re.match(r'^\s*from\s+(\S+)', l, re.I).group(1)
            out.append((tab, atual))
            atual = None
    return out


def originais():
    """{tabela: {expressao achatada e sem TRANSLATE}} do spool de origem."""
    bl, lin = CA.blocos(G.FONTE)
    out = {}
    for tab, a, b in bl:
        ts = CA.tokens(a, b, lin)
        out[tab] = collections.Counter(
            re.sub(r'\s+', '', t[2]) for t in ts)
    return out


def main():
    bl = blocos_gerados()
    if len(bl) != 3:
        raise SystemExit('esperava 3 blocos em %s, achei %d' % (G.SAIDA, len(bl)))
    orig = originais()
    erros = 0
    for tab, campos in bl:
        total, n, sep = 0, 0, 0
        censo = collections.Counter()
        for expr, ref, cl, tem_sep in campos:
            n += 1
            censo[cl] += 1
            sep += 1 if tem_sep else 0
            esperado = CAMPOS[ref]['len'] if ref in CAMPOS else None
            w = CA.MP.largura(expr)
            if w is None:
                print('  ? largura desconhecida  %-12s %s' % (ref, expr[:70]))
                erros += 1
                continue
            # o TRANSLATE troca um caractere por outro: nao muda a largura
            nu = CA.A.nu_pv(expr)
            wn = CA.MP.largura(nu)
            if wn != w:
                print('  X %-12s o TRANSLATE mudou a largura: %s -> %s'
                      % (ref, w, wn))
                erros += 1
            if esperado is not None and w != esperado:
                print('  X %-12s notice %-5s spool %-5s  %s'
                      % (ref, esperado, w, expr[:60]))
                erros += 1
            # nao-regressao: o que esta por baixo do TRANSLATE tem de vir do spool
            chato = re.sub(r'\s+', '', nu)
            if cl == 'EXATO' and not orig[tab].get(chato):
                print('  X %-12s EXATO mas nao esta no spool de origem: %s'
                      % (ref, chato[:60]))
                erros += 1
            total += w + (1 if tem_sep else 0)

        ultimo = campos[-1]
        if ultimo[3]:
            print('  X o filler final leva ";" -- nao devia: %s' % ultimo[1])
            erros += 1
        if ultimo[1] != 'A1 99.99':
            print('  X o ultimo campo nao e o filler: %s' % ultimo[1])
            erros += 1
        if n != len(CAMPOS):
            print('  X %d campos escritos, a notice tem %d' % (n, len(CAMPOS)))
            erros += 1
        if sep != len(CAMPOS) - 1:
            print('  X %d separadores, esperava %d' % (sep, len(CAMPOS) - 1))
            erros += 1
        if total != LINHA:
            print('  X total %d, esperado %d' % (total, LINHA))
            erros += 1
        if total > LIMITE_SQL:
            print('  X a expressao passa os %d de uma coluna SQL' % LIMITE_SQL)
            erros += 1
        print('%-20s campos %3d  separadores %3d  total %d   %s'
              % (tab, n, sep, total,
                 '  '.join('%s %d' % (k, censo[k]) for k in sorted(censo))))
    print()
    print('erros: %d' % erros)
    return 1 if erros else 0


if __name__ == '__main__':
    sys.exit(main())
