# -*- coding: utf-8 -*-
"""Confere, sem base de dados, os paves gerados pelo gen_spool_paves.py.

Le o ficheiro GERADO, torna a medir cada token com o mesmo motor do mapa_paves e
exige que a sequencia de larguras seja exatamente a que a notice manda:

    len(campo 1), 1, len(campo 2), 1, ... , len(campo n-1), 1, filler

isto e: cada campo com o seu tamanho da notice, um ';' de um octeto depois de
cada um, e o filler a fechar os 4000 da coluna 1. Assim apanha-se um campo
copiado com a largura errada, um ';' a mais ou a menos, e um filler mal contado.

Confere ainda que nenhuma linha do bloco acaba em ';' de separador (o ultimo
campo escrito e o filler) e que a cauda -- coluna 2, FROM e WHERE -- ficou igual
a do spool vPACT, byte a byte.

Uso:  python valida_paves.py
"""
import collections
import io
import sys

buf, _o = io.StringIO(), sys.stdout
sys.stdout = buf
import mapa_paves as MP               # noqa: E402
import gen_spool_paves as GP          # noqa: E402
sys.stdout = _o

import re                             # noqa: E402


def esperado(pave):
    """[(largura, o que e)] que a notice manda, com os separadores."""
    campos = MP.regua(pave)
    out = []
    for ref, _ini, ln in campos[:-1]:
        out.append((ln, ref))
        out.append((1, ';'))
    resto = GP.COL1 - sum(w for w, _ in out)
    out.append((resto, campos[-1][0]))
    return out


def medido(linhas, a, b):
    """[(largura, expressao)] do bloco gerado, ate ao 'as lignedetail1'."""
    c1, _ = GP.limites(linhas, a, b)
    return [(t[1], t[2]) for t in MP.tokens(a, c1)]


def valores(linhas, a, b):
    """As expressoes com valor do bloco (tudo o que nao e filler branco).

    E por aqui que se ve que nenhum campo se perdeu: a lista do bloco gerado tem
    de ser igual a do spool vPACT. Uma emenda vai entre parenteses, por isso
    parte-se antes de comparar."""
    c1, _ = GP.limites(linhas, a, b)
    out = []
    for _p, _w, raw, br in MP.tokens(a, c1):
        if br or raw == "';'":
            continue
        s = raw.strip()
        partes = (MP.parte_concat(s[1:-1])
                  if s.startswith('(') and s.endswith(')') else [s])
        for x in partes:
            y = x.strip()
            # um literal so de brancos -- o ' ' que o C1 usa como filler -- nao e
            # valor: se contasse, a correcao para RPAD(' ', 2) dava campo perdido
            if MP.BRANCO.match(y) or re.fullmatch(r"' *'", y):
                continue
            # O literal acentuado do translate do C1 sai em CHR(n) no ficheiro
            # gerado, para nenhum encode lhe poder tocar. Aplica-se a mesma troca
            # ao lado do spool: se as duas nao derem a mesma coisa, e porque a
            # conversao nao foi fiel, e isso tem de acusar.
            out.append(re.sub(r'\s+', '', GP.ascii_seguro(x)))
    return sorted(out)


def confere(pave):
    erros = []
    fonte, blocos_fonte = MP.carrega_fonte(GP.FONTE)
    caudas, vals = {}, {}
    for k, (a, b) in enumerate(blocos_fonte[pave]):
        c1, _ = GP.limites(fonte, a, b)
        caudas[k] = fonte[c1:b]              # depois da linha do 'as lignedetail1'
        vals[k] = valores(fonte, a, b)

    linhas, blocos = MP.carrega_fonte(GP.SAIDA)
    esp = esperado(pave)
    for k, (a, b) in enumerate(blocos[pave]):
        med = medido(linhas, a, b)
        if len(med) != len(esp):
            erros.append('%s bloco %d: %d tokens, esperados %d'
                         % (pave, k + 1, len(med), len(esp)))
        for i, ((we, qe), (wm, em)) in enumerate(zip(esp, med)):
            if wm != we:
                erros.append('%s bloco %d token %d (%s): largura %s, esperada %d'
                             ' -- %s' % (pave, k + 1, i, qe, wm, we, em[:60]))
            if qe == ';' and em.strip() != "';'":
                erros.append('%s bloco %d token %d: esperava o separador, tem %s'
                             % (pave, k + 1, i, em[:40]))
        total = sum(w or 0 for w, _ in med)
        if total != GP.COL1:
            erros.append('%s bloco %d: coluna 1 da %d, nao %d'
                         % (pave, k + 1, total, GP.COL1))
        c1, _ = GP.limites(linhas, a, b)
        for ln in linhas[a - 1:c1 - 1]:
            if re.sub(r'--.*$', '', ln).rstrip().endswith(";'||"):
                continue
            if re.sub(r'--.*$', '', ln).rstrip().endswith("';'"):
                erros.append('%s bloco %d: linha acaba em separador: %s'
                             % (pave, k + 1, ln.strip()[:50]))
        # A coluna 2, o FROM e o WHERE ficam byte a byte. A linha do
        # 'as lignedetail1' e a fronteira: nao pode sobrar nada antes dele (era
        # onde um bloco do P9 guardava o filler antigo).
        antes = re.split(r'as\s+lignedetail1', linhas[c1 - 1], flags=re.I)[0]
        if antes.strip():
            erros.append('%s bloco %d: sobra expressao antes do lignedetail1: %s'
                         % (pave, k + 1, antes.strip()[:50]))
        if linhas[c1:b] != caudas[k]:
            erros.append('%s bloco %d: a cauda mudou' % (pave, k + 1))
        # Nenhuma expressao com valor se pode perder. Uma que a REGRA embrulhou
        # -- 'NVL(col,\' \')' dentro de 'RPAD(NVL(col,\' \'), 2)' -- continua la,
        # por isso aceita-se quando aparece dentro de uma expressao nova; o que
        # nao se aceita e desaparecer.
        vn = valores(linhas, a, b)
        falta = collections.Counter(vals[k]) - collections.Counter(vn)
        sobra = collections.Counter(vn) - collections.Counter(vals[k])
        perdidos = [x for x in falta.elements()
                    if not any(x in y for y in sobra)]
        if perdidos:
            erros.append('%s bloco %d: %d expressoes perdidas'
                         % (pave, k + 1, len(perdidos)))
            for x in perdidos[:10]:
                erros.append('     %s' % x[:90])
    return esp, erros


if __name__ == '__main__':
    mau = 0
    for pave in GP.PAVES:
        esp, erros = confere(pave)
        campos = len([1 for _, q in esp if q != ';'])
        print('%s : %d tokens esperados (%d campos + %d separadores),'
              ' coluna 1 = %d' % (pave, len(esp), campos,
                                  len(esp) - campos, GP.COL1))
        for e in erros:
            print('   ERRO %s' % e)
        print('   erros: %d' % len(erros))
        mau += len(erros)
    sys.exit(1 if mau else 0)
