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

# A tabela do FROM identifica o pave. Os blocos acham-se assim, e nao por numero
# de linha, porque o gerador do P1 ja desloca o ficheiro: o mesmo codigo serve
# para medir no spool vPACT e para escrever no ficheiro que ja leva o P1 novo.
TABELAS = {
    'C1': 'tie_tiers_c1_c5',
    'F1': 'AUTORISATION_F1',
    'F2': 'AUTORISATION_DETAIL_F2',
    'P2': 'ENG_CORP_P2',
    'M1': 'SURETE_M1',
    'P9': 'PROVISIONS_DECOTES_P9',
}


def acha_blocos(lines):
    """{pave: [(primeira linha, ultima linha)]}, 1-based, do 'select' ao ';'.

    O P9 tem um subselect sobre a ENG_CORP_P1 dentro do WHERE: por isso sobe-se
    do FROM ate ao 'select' (o de cima) e desce-se ate ao primeiro ';' depois do
    FROM, que e o fim da instrucao."""
    out = {}
    for pave, tab in TABELAS.items():
        for i, ln in enumerate(lines, 1):
            if not re.search(r'\b' + tab + r'\b\s*\w*\s*$', ln, re.I):
                continue
            if not re.search(r'from', lines[i - 2] + ln, re.I):
                continue
            a = max(j for j in range(1, i)
                    if re.match(r'^\s*select\s*$', lines[j - 1], re.I))
            b = next(j for j in range(i, len(lines)) if ';' in lines[j - 1])
            out.setdefault(pave, []).append((a, b))
    return out


def carrega_fonte(caminho=FONTE):
    """Aponta o tokenize do align_v44 a este ficheiro. Devolve (linhas, blocos)."""
    A.lines = open(caminho, encoding='cp1252').read().split(chr(10))
    return A.lines, acha_blocos(A.lines)


LINHAS, BLOCOS = carrega_fonte()

BRANCO = re.compile(r"^[LR]PAD\s*\(\s*'\s*'\s*,\s*\d+\s*\)$", re.I)


def regua(pave):
    """Inicio (1-based) de cada campo da notice, por concatenacao pura."""
    out, p = [], 1
    for c in notice.carrega()[pave]:
        out.append((c['ref'], p, int(c['len'])))
        p += int(c['len'])
    return out


def parte_concat(s):
    """Parte 'a||b||c' nos '||' de fora dos parenteses."""
    out, cur, d = [], '', 0
    i = 0
    while i < len(s):
        if s[i] == '(':
            d += 1
        elif s[i] == ')':
            d -= 1
        if d == 0 and s[i:i + 2] == '||':
            out.append(cur)
            cur = ''
            i += 2
            continue
        cur += s[i]
        i += 1
    out.append(cur)
    return [x for x in (p.strip() for p in out) if x]


def largura(raw):
    """A largura do token. Alem do que o align_v44 mede, sabe:

      - somar uma emenda posta entre parenteses, '(a||b||c)', que e como o
        gen_spool_paves.py escreve os campos que o spool tinha em varios pedacos;
      - desembrulhar um parenteses que so embrulha, '( CASE ... END)' -- o C1
        abre-o com um espaco e o medidor do align_v44 so reconhece '(CASE';
      - a mascara de data longa 'YYYYMMDDHH24MISS', 14, do C1;
      - a F_FORMAT_MONTANT_BIS3, 19, que o P2 usa e nao estava na lista.

    Sem estas quatro, ficavam quatro tokens sem largura e a regua do C1 saia 33
    octetos curta -- o que o ficheiro de referencia desmentiu (mede 981)."""
    w = A.width(raw)
    if w is not None:
        return w
    s = raw.strip()
    if s.startswith('(') and s.endswith(')'):
        partes = parte_concat(s[1:-1])
        if len(partes) > 1:
            ws = [largura(p) for p in partes]
            if all(x is not None for x in ws):
                return sum(ws)
        return largura(s[1:-1])
    if re.search(r"TO_CHAR\s*\(.*'YYYYMMDDHH24MISS'", s, re.I):
        return 14
    if re.search(r'\bF_FORMAT_MONTANT_BIS3\s*\(', s, re.I):
        return 19
    return None


def tokens(a, b):
    """[(inicio 1-based, largura, raw, e_branco)] do bloco."""
    out, pos = [], 1
    for t in A.tokenize(a - 1, b):
        w = largura(t['raw'])
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
