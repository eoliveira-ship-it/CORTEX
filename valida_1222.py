"""Verifica o spool gerado do SIRL-1222, sem base de dados.

Le o 030_spool_Extract_CRRCORP_1222.sql, e para cada campo de cada bloco:

  1. mede a largura da expressao (RPAD(x,n) -> n, 'ABC' -> 3, as funcoes
     pack_utilitaire.F_FORMAT_* tem largura conhecida) e compara com o tamanho
     que a notice V45.02 da a esse campo;
  2. confirma que todos os campos levam ';' no fim, menos o ultimo da linha;
  3. soma as larguras por coluna (limite 4000 de uma expressao SQL) e no total
     (tem de dar 8000, o tamanho da linha).

Se alguma coisa nao bater, imprime o campo e sai com erro. Uso:

    python valida_1222.py
"""
import io
import re
import sys

import notice

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import gen_spool_vpact as G          # noqa: E402  (pela funcao width)
sys.stdout = _o

SPOOL = '030_spool_Extract_CRRCORP_1222.sql'
LINHA = 8000
LIMITE_SQL = 4000
CAMPOS = {c['ref']: c for c in notice.carrega()['P1']}


def blocos(txt):
    """[(comentario, [(expressao, campo, regra, tem_sep), ...] por coluna)]"""
    out = []
    linhas = txt.split(chr(10))
    i = 0
    while i < len(linhas):
        if linhas[i].startswith('-- PAVE P1'):
            com = linhas[i][3:]
            cols, atual = [], []
            i += 2                                  # salta a risca e o 'select'
            while not linhas[i].strip().startswith('from '):
                ln = linhas[i]
                m = re.match(r'^\s+(.*?)\s*--\s+(\S+(?: \S+)?)\s+([A-Z-]+)\s*$', ln)
                if m:
                    expr, campo, regra = m.group(1), m.group(2), m.group(3)
                    # o ultimo campo de cada coluna fica com ||';' (sem o || do
                    # fim, que o gerador tira); os outros com ||';'||
                    sep = False
                    for suf in ("||';'||", "||';'"):
                        if expr.endswith(suf):
                            expr, sep = expr[:-len(suf)], True
                            break
                    expr = expr.rstrip('|').strip()
                    atual.append((expr, campo, regra, sep))
                elif re.match(r'^\s+as lignedetail\d', ln):
                    cols.append(atual)
                    atual = []
                i += 1
            out.append((com, cols))
        i += 1
    return out


DDL = open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
TAMANHO_COLUNA = {m[0]: int(m[1]) for m in
                  re.findall(r'^\s+(P1_[A-Z0-9_]+)\s+VARCHAR2\((\d+)\)', DDL, re.M)}


def partes(expr):
    """Parte a expressao nos '||' de primeiro nivel (fora de parenteses)."""
    out, nivel, atual = [], 0, ''
    i = 0
    while i < len(expr):
        c = expr[i]
        if c == '(':
            nivel += 1
        elif c == ')':
            nivel -= 1
        if nivel == 0 and expr[i:i + 2] == '||':
            out.append(atual)
            atual = ''
            i += 2
            continue
        atual += c
        i += 1
    out.append(atual)
    return [p.strip() for p in out if p.strip()]


# Largura do que cada funcao de formato escreve, lida do pack_utilitaire:
# sinal + LPAD da parte inteira + RPAD dos decimais.
FUNCOES = {
    'F_FORMAT_MONTANT': 19, 'F_FORMAT_MONTANT_BIS': 19, 'F_FORMAT_MONTANT_BIS2': 19,
    'F_FORMAT_MONTANT_BIS3': 19,        # '+' + 16 + 2
    'F_FORMAT_MONTANT_BIS4': 38,        # '+' + 37
    'F_FORMAT_MONTANT_18': 18,          # '+' + 15 + 2
    'F_FORMAT_MONTANT_13_2': 13,        # '+' + 10 + 2
    'F_FORMAT_MONTANT_NEGATIF_19': 19,
    'F_FORMAT_TAUX': 10, 'F_FORMAT_TAUX_15': 15,  # '+' + 5 + 9
}


def largura(expr):
    """Quantos caracteres esta expressao escreve, sem base de dados."""
    expr = expr.strip()
    if expr == ':MASYSDATE':
        return 12
    if re.match(r'^P1_[A-Z0-9_]+$', expr):
        return TAMANHO_COLUNA.get(expr)          # a coluna ja tem o tamanho certo
    # Um CASE ... END nao se parte pelos '||': o 'x'||y de dentro de um ramo
    # esta ao mesmo nivel de parenteses que o resto e a soma sairia errada.
    if expr.upper().startswith('CASE'):
        w = G.width(expr)
        if w is not None:
            return w
        m = re.search(r"RPAD\s*\(\s*'\s*'\s*,\s*(\d+)\s*\)", expr)
        if m:
            return int(m.group(1))
        for nome, larg in FUNCOES.items():
            if nome.lower() in expr.lower():
                return larg
        return None
    # concatenacao de primeiro nivel: soma das partes. Tem de vir antes do
    # G.width, que mediria so a primeira parte
    p = partes(expr)
    if len(p) > 1:
        t = 0
        for x in p:
            w = largura(x)
            if w is None:
                return None
            t += w
        return t
    m = re.match(r'^(?:pack_utilitaire\.)?(F_FORMAT_[A-Z0-9_]+)\s*\(', expr, re.I)
    if m and m.group(1).upper() in FUNCOES:
        return FUNCOES[m.group(1).upper()]
    w = G.width(expr)
    if w is not None:
        return w
    if expr.upper().lstrip('(').startswith('CASE'):
        # CASE WHEN x IS NULL THEN RPAD(' ',n) ELSE <mesma largura> END
        m = re.search(r"RPAD\s*\(\s*'\s*'\s*,\s*(\d+)\s*\)", expr)
        if m:
            return int(m.group(1))
        for nome, larg in FUNCOES.items():
            if nome.lower() in expr.lower():
                return larg
    return None


def main():
    txt = open(SPOOL, encoding='latin-1').read()
    bl = blocos(txt)
    if not bl:
        raise SystemExit('nenhum bloco P1 encontrado em %s' % SPOOL)
    erros = 0
    for com, cols in bl:
        total, larg_col, n = 0, [], 0
        for k, col in enumerate(cols):
            wc = 0
            for expr, campo, regra, sep in col:
                n += 1
                esperado = CAMPOS[campo]['len'] if campo in CAMPOS else None
                w = largura(expr)
                if w is None:
                    print('  ? largura desconhecida  %-12s %s' % (campo, expr[:70]))
                    erros += 1
                    continue
                if campo == 'P1 99.99':
                    esperado = w          # o filler final e calculado, nao vem da notice
                if campo == 'P1 21.65':
                    esperado = 50         # SIRL-1223
                if esperado is not None and w != esperado:
                    print('  X %-12s notice %-5s spool %-5s  %s'
                          % (campo, esperado, w, expr[:60]))
                    erros += 1
                wc += w + (1 if sep else 0)
            larg_col.append(wc)
            total += wc
        ultimo = cols[-1][-1]
        if ultimo[3]:
            print('  X o ultimo campo da linha leva ";" -- nao devia: %s' % ultimo[1])
            erros += 1
        acima = [w for w in larg_col if w > LIMITE_SQL]
        print('%-62s campos %3d  colunas %s  total %d%s'
              % (com[:62], n, larg_col, total,
                 '   ACIMA DE 4000!' if acima else ''))
        if total != LINHA:
            print('  X total %d, esperado %d' % (total, LINHA))
            erros += 1
        if acima:
            erros += 1
    print()
    print('erros: %d' % erros)
    return 1 if erros else 0


if __name__ == '__main__':
    sys.exit(main())
