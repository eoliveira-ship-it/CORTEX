# -*- coding: utf-8 -*-
"""Poe os .sql e os .sh em cp1252, que e a codificacao do DDR.

    python para_cp1252.py            # diz o que esta fora da regra
    python para_cp1252.py --aplicar  # converte

PORQUE E QUE ISTO E PRECISO
---------------------------
A regra do projecto e: os .sql e os .sh em cp1252 e CRLF, como no DDR. Mas um
ficheiro que passa por um editor ou pela interface web do GitHub volta muitas
vezes em UTF-8 -- e um ficheiro UTF-8 nao da erro nenhum quando alguem o le como
cp1252. Da o caracter errado e segue:

    cp1252   'A'  ->  C0                 1 octeto
    UTF-8    'A'  ->  C3 80              2 octetos, lidos como 'A' e um controle

O sitio onde isso morde e o translate() do C1, no spool do Corporate: o gerador
do SIRL-1222 dobra esses acentos para CHR(n), e a partir de um ficheiro UTF-8
lido como cp1252 sairiam 28 CHR() em vez de 14. O Oracle, com a cadeia 'de' mais
comprida que a 'para', REMOVE os caracteres a mais -- a linha encolhe e deixa de
fechar nos 8000 octetos. Nao rebenta: espera por um nome com acento.

A CONVERSAO E VERIFICADA
------------------------
So converte se a volta for exacta -- descodificar em cp1252 o que se escreveu
tem de dar o mesmo texto. A excepcao e o U+FFFD, o caracter que marca um
caracter JA perdido antes de chegar aqui: esse passa a '?', que e o que ele e.
Se aparecer noutro sitio que nao um comentario, este script para.
"""
import glob
import io
import os
import sys

import enc

PERDIDO = '�'


def comentario(l):
    s = l.strip()
    return (not s or s.startswith('--') or s.startswith('#')
            or s.startswith('*') or s.startswith('/*'))


def examina(f):
    """(precisa de conversao, texto, quantos U+FFFD, linhas de codigo com U+FFFD)"""
    t, cod = enc.le(f)
    if cod == 'cp1252':
        return False, t, 0, []
    if all(ord(c) < 128 for c in t):
        return False, t, 0, []
    maus = [i for i, l in enumerate(t.replace('\r\n', '\n').split('\n'), 1)
            if PERDIDO in l and not comentario(l)]
    return True, t, t.count(PERDIDO), maus


def main(aplicar=False):
    fora, convertidos = [], 0
    for f in sorted(glob.glob('*.sql') + glob.glob('*.sh')):
        precisa, t, perdidos, maus = examina(f)
        if not precisa:
            continue
        if maus:
            print('  %s: caracter perdido FORA de comentario, nas linhas %s'
                  % (f, maus))
            print('     nao converto: ha que recuperar o ficheiro de origem.')
            fora.append(f)
            continue
        limpo = t.replace(PERDIDO, '?')
        b = limpo.encode('cp1252')
        if b.decode('cp1252') != limpo:
            print('  %s: a volta a cp1252 nao e exacta, nao converto' % f)
            fora.append(f)
            continue
        antes = os.path.getsize(f)
        print('  %-42s UTF-8 -> cp1252  %d -> %d octetos%s'
              % (f, antes, len(b),
                 '  (%d caracter(es) ja perdido(s) -> "?")' % perdidos if perdidos else ''))
        if aplicar:
            with open(f, 'wb') as g:
                g.write(b)
            convertidos += 1
        else:
            fora.append(f)
    if aplicar:
        print('convertidos: %d' % convertidos)
        return 1 if fora else 0
    if fora:
        print('fora da regra: %d ficheiro(s).  corre:  python para_cp1252.py --aplicar'
              % len(fora))
        return 1
    print('todos os .sql e .sh estao em cp1252')
    return 0


if __name__ == '__main__':
    sys.exit(main('--aplicar' in sys.argv))
