# -*- coding: utf-8 -*-
"""Onde e que o spool e a Notice V45.02 discordam, em cada pave -- SIRL-1222.

O mapa_paves.py mediu quanto falta: F2, F1 e P9 escrevem exatamente o que a
notice manda (diferenca 0, e por isso ja estao gerados); ao M1 faltam 3 octetos,
ao P2 19 e ao C1 33. Este modulo diz QUAIS sao.

COMO
----
Percorre-se o bloco token a token e a notice campo a campo ao mesmo tempo:

  igual     a largura do token e o tamanho do campo -> andam os dois
  junta     o token e um filler que cobre varios campos -> consomem-se campos
            ate somar a largura do token
  DIVERGE   nao fecha -> escreve-se o campo, o token, e de quanto e a diferenca

Os campos criados na V45 (coluna VERSION DE CREATION = 45) estao todos no fim da
linha nos dois paves que os tem (M1 1665..1806, P2 3238..3585) e o spool V44 nao
os escreve: saltam-se, como no P1, e vao escritos em branco.

O que sai daqui e a lista para a DSID: cada DIVERGE e um campo cujo tamanho mudou
na V45 (coluna VERSION DE MODIFICATION = 45.xx) e que o spool ainda escreve com o
tamanho antigo, ou um campo que o spool nunca escreveu.

Uso:  python casa_paves.py [pave ...]
"""
import collections
import io
import sys

import notice

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import mapa_paves as MP               # noqa: E402
sys.stdout = _o


def campos(pave):
    """[(ref, len, novo_v45, modif)] na ordem da notice, sem o filler final."""
    cs = notice.carrega()[pave]
    return [(c['ref'], int(c['len']), c['novo_v45'], c['modif']) for c in cs[:-1]]


def tokens_uteis(pave, a, b):
    """Os tokens do bloco sem o filler grande que fecha a coluna 1."""
    c1 = next(i for i in range(a, b + 1)
              if 'lignedetail1' in MP.A.lines[i - 1].lower())
    ts = MP.tokens(a, c1)      # inclui a linha do 'as lignedetail1'
    return [t for t in ts if not (t[3] and t[1] and t[1] > 300)]


MAX_CAMPOS = 80      # campos que um filler pode cobrir
MAX_TOKENS = 8       # tokens que podem fazer um campo (emenda)


def casa(pave, a, b):
    """[(estado, ref, largura do token, tamanho do campo, nota)].

    Alinhamento global por programacao dinamica, e nao guloso: um passo guloso
    dessincroniza na primeira divergencia e a partir dai acusa tudo (no P2 dava
    162 divergencias falsas). Aqui minimiza-se o numero de anomalias, que e a
    leitura honesta -- cada anomalia custa 1, e casar custa 0:

      igual   um token vale um campo
      junta   um filler cobre varios campos (soma exata)
      emenda  varios tokens fazem um campo (soma exata)
      NOVO    campo criado na V45, que o spool V44 nao escreve
      FALTA   campo da notice sem nada no spool
      SOBRA   token do spool sem campo na notice
      DIVERGE token e campo no mesmo lugar com tamanhos diferentes
    """
    cs, ts = campos(pave), tokens_uteis(pave, a, b)
    n, m = len(ts), len(cs)
    larg = [t[1] if t[1] is not None else -1 for t in ts]
    INF = float('inf')

    # custo[i][j] = anomalias minimas para casar ts[i:] com cs[j:]
    custo = [[INF] * (m + 1) for _ in range(n + 1)]
    mov = [[None] * (m + 1) for _ in range(n + 1)]
    custo[n][m] = 0
    for i in range(n, -1, -1):
        for j in range(m, -1, -1):
            if i == n and j == m:
                continue
            melhor, qual = INF, None
            if i < n and j < m:
                c = custo[i + 1][j + 1]
                if c < INF:
                    igual = larg[i] == cs[j][1] and not cs[j][2]
                    cc = c + (0 if igual else 1)
                    if cc < melhor:
                        melhor, qual = cc, ('igual' if igual else 'DIVERGE', 1, 1)
                # um token cobre varios campos. Se for um filler branco, e de
                # graca -- parte-se o RPAD. Se tiver valor, custa 1: e um valor
                # que a notice separa em varios campos e que so um SUBSTR parte
                # (e o caso do C1), por isso tem de ser escrito a mao.
                if larg[i] > 0:
                    soma = 0
                    for k in range(1, min(MAX_CAMPOS, m - j) + 1):
                        if cs[j + k - 1][2]:
                            break
                        soma += cs[j + k - 1][1]
                        if soma > larg[i]:
                            break
                        if soma == larg[i] and k > 1:
                            estado = 'junta' if ts[i][3] else 'PARTE'
                            c = custo[i + 1][j + k] + (0 if ts[i][3] else 1)
                            if c < melhor:
                                melhor, qual = c, (estado, 1, k)
                # varios tokens fazem um campo
                soma = 0
                for k in range(1, min(MAX_TOKENS, n - i) + 1):
                    if larg[i + k - 1] < 0:
                        break
                    soma += larg[i + k - 1]
                    if soma > cs[j][1]:
                        break
                    if soma == cs[j][1] and k > 1 and custo[i + k][j + 1] < melhor:
                        melhor, qual = custo[i + k][j + 1], ('emenda', k, 1)
            if j < m and custo[i][j + 1] < INF:
                falta = 'NOVO' if cs[j][2] else 'FALTA'
                c = custo[i][j + 1] + (0 if cs[j][2] else 1)
                if c < melhor:
                    melhor, qual = c, (falta, 0, 1)
            if i < n and custo[i + 1][j] < INF:
                c = custo[i + 1][j] + 1
                if c < melhor:
                    melhor, qual = c, ('SOBRA', 1, 0)
            custo[i][j], mov[i][j] = melhor, qual

    out, i, j = [], 0, 0
    while mov[i][j]:
        estado, di, dj = mov[i][j]
        raws = [t[2] for t in ts[i:i + di]]
        if estado == 'SOBRA':
            out.append({'estado': estado, 'ref': '-', 'len': 0, 'w': larg[i],
                        'raw': raws, 'modif': '', 'ordem': 0})
        else:
            for k in range(dj):
                ref, ln, _novo, modif = cs[j + k]
                out.append({'estado': estado, 'ref': ref, 'len': ln,
                            'w': larg[i] if di else 0, 'raw': raws,
                            'modif': modif, 'ordem': k})
        i += di
        j += dj
    return out


if __name__ == '__main__':
    paves = sys.argv[1:] or ['M1', 'P2', 'C1']
    for pave in paves:
        for a, b in MP.BLOCOS[pave]:
            linhas = casa(pave, a, b)
            conta = collections.Counter(l['estado'] for l in linhas)
            mau = [l for l in linhas
                   if l['estado'] in ('DIVERGE', 'FALTA', 'SOBRA', 'PARTE')]
            print('%s bloco %d-%d : %s (%+d octetos)'
                  % (pave, a, b,
                     '  '.join('%s %d' % (k, v) for k, v in sorted(conta.items())),
                     sum((l['w'] or 0) - l['len'] for l in mau)))
            for l in mau:
                print('   %-8s %-11s spool %-5s notice %-4d  %s | %s'
                      % (l['estado'], l['ref'], l['w'], l['len'], l['modif'],
                         (l['raw'][0] if l['raw'] else '')[:60]))
