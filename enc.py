# -*- coding: utf-8 -*-
"""Le os ficheiros do DDR sem adivinhar a codificacao.

    import enc
    texto, codificacao = enc.le('030_spool_Extract_CRRCORP.sql')
    enc.escreve('saida.sql', texto, codificacao)

PORQUE E QUE ISTO PRECISOU DE EXISTIR
-------------------------------------
As copias dos ficheiros que tinhamos eram cp1252. As que vieram de producao em
28/09/2026 sao UTF-8. O mesmo codigo, a mesma linha, octetos diferentes:

    cp1252   'A' de 'AACEEEEIYOOUUU'  ->  C0                 1 octeto
    UTF-8    o mesmo caracter         ->  C3 80              2 octetos

Ler um ficheiro UTF-8 como se fosse cp1252 nao da erro: da 'A' em vez de 'A', e
o programa segue. Copiar de um lado para o outro ate funciona, porque cp1252
descodifica e volta a codificar os mesmos octetos. O que NAO funciona e olhar
para os caracteres -- e e exactamente o que o gerador do SIRL-1222 faz, quando
dobra os acentos do translate() do C1 para CHR(n):

    correcto (14 caracteres)   CHR(192)||CHR(194)||...||CHR(220)
    errado   (28 caracteres)   CHR(195)||CHR(128)||CHR(195)||CHR(130)||...

E o segundo caso nao rebenta: escreve um TRANSLATE com 28 caracteres no 'de' e
14 no 'para'. O Oracle, nesse caso, REMOVE os caracteres a mais em vez de os
substituir -- a cadeia encolhe, e a linha de 8000 octetos deixa de fechar. Um
erro que so aparece num nome com acento, no ficheiro final, depois da MEP.

Daqui para a frente le-se com esta funcao, que tenta UTF-8 primeiro: o UTF-8 e
auto-verificavel (uma sequencia invalida rebenta), por isso um ficheiro que se
descodifica em UTF-8 e UTF-8, e o cp1252 fica para o resto.
"""
import io


def le(caminho):
    """(texto, codificacao). Nao traduz os fins de linha (newline='')."""
    with open(caminho, 'rb') as f:
        b = f.read()
    if b.startswith(b'\xef\xbb\xbf'):
        return b.decode('utf-8-sig'), 'utf-8-sig'
    try:
        return b.decode('utf-8'), 'utf-8'
    except UnicodeDecodeError:
        return b.decode('cp1252'), 'cp1252'


def linhas(caminho):
    """(lista de linhas sem o fim de linha, codificacao, fim de linha)."""
    t, cod = le(caminho)
    nl = '\r\n' if '\r\n' in t else '\n'
    return t.split(nl), cod, nl


def escreve(caminho, texto, codificacao='utf-8', nl=''):
    io.open(caminho, 'w', encoding=codificacao, newline=nl).write(texto)


def so_ascii(caminho):
    """True se o ficheiro nao tem um octeto acima de 127."""
    with open(caminho, 'rb') as f:
        return all(c < 128 for c in f.read())
