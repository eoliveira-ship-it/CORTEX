"""Nao-regressao do SIRL-1223: compara um ficheiro de ANTES com um de DEPOIS.

    python comparar_1223.py crrcorp CRRCORP_antes.dat CRRCORP_depois.dat
    python comparar_1223.py p3      C3RD_antes.dat    C3RD_depois.dat

O 1223 muda o tamanho de campos, por isso um diff direto da diferencas em
todas as linhas. Este script aplica ao ficheiro de ANTES a mudanca que o
chamado pede e compara o resultado com o de DEPOIS. Se forem iguais, a
mudanca foi exatamente a pedida e nada mais mexeu.

crrcorp (posicional, 8000 bytes por linha)
    Nas linhas P1 (bytes 39-40) o P1 21.65 passa de 5 para 50: entram 45
    brancos no byte 5217 e saem os 45 brancos do fim da linha, que fica com
    os mesmos 8000. Os outros paves nao mudam. Como no comparar_ficheiros.sh,
    mascara-se o MASYSDATE (bytes 27-38), ignora-se a linha ENTETE (00;) e a
    comparacao e por conteudo, sem ordem.

p3 (separado por ;)
    Nas linhas de detalhe (01;) o P3C 21.65 passa de 5 para 50 e o filler
    BALE4 do fim de 1132 para 1087: a linha fica com o mesmo tamanho. O
    campo 21.65 descobre-se sozinho: e o unico que cresce 45.
"""
import collections
import hashlib
import sys

P1_BYTE = 5216          # 0-based: o P1 21.65 comeca no byte 5217
DELTA = 45              # 50 - 5


def linhas(caminho):
    with open(caminho, 'rb') as f:
        for ln in f:
            yield ln.rstrip(b'\r\n')


def h(b):
    return hashlib.md5(b).digest()


def crrcorp(antes, depois):
    esperado, obtido = collections.Counter(), collections.Counter()
    exemplo = {}
    censo = collections.Counter()
    for ln in linhas(antes):
        if ln.startswith(b'00;'):
            continue
        ln = ln[:26] + b'#' * 12 + ln[38:]
        if ln[38:40] == b'P1':
            assert ln[P1_BYTE:P1_BYTE + 5] == b' ' * 5, 'P1 21.65 nao vazio'
            assert ln[-DELTA:] == b' ' * DELTA, 'fim da linha P1 nao vazio'
            ln = ln[:P1_BYTE] + b' ' * DELTA + ln[P1_BYTE:-DELTA]
        censo['antes ' + ln[38:40].decode()] += 1
        k = h(ln)
        esperado[k] += 1
        exemplo.setdefault(k, ln)
    for ln in linhas(depois):
        if ln.startswith(b'00;'):
            continue
        ln = ln[:26] + b'#' * 12 + ln[38:]
        censo['depois ' + ln[38:40].decode()] += 1
        k = h(ln)
        obtido[k] += 1
        exemplo.setdefault(k, ln)
    for c in sorted(censo):
        print('  %-10s %8d' % (c, censo[c]))
    return relatorio(esperado, obtido, exemplo, id_=slice(179, 220))


def campos(ln):
    return ln.split(b';')


def p3(antes, depois):
    A = [ln for ln in linhas(antes) if ln.startswith(b'01;')]
    D = [ln for ln in linhas(depois) if ln.startswith(b'01;')]
    print('  linhas 01 : antes %d, depois %d' % (len(A), len(D)))
    wa = [len(x) for x in campos(A[0])]
    wd = [len(x) for x in campos(D[0])]
    if len(wa) != len(wd):
        print('  numero de campos mudou: %d -> %d' % (len(wa), len(wd)))
        return 1
    dif = [(i, wa[i], wd[i]) for i in range(len(wa)) if wa[i] != wd[i]]
    print('  campos que mudaram de tamanho (indice, antes, depois): %s' % dif)
    cresce = [i for i, a, d in dif if d - a == DELTA and a == 5]
    ultimo = len(wa) - 1
    if len(dif) != 2 or len(cresce) != 1 or dif[-1] != (ultimo, 1132, 1087):
        print('  ERRO: esperava-se so o 21.65 5->50 e o filler 1132->1087')
        return 1
    k = cresce[0]
    print('  P3C 21.65 = campo %d; filler BALE4 = campo %d' % (k, ultimo))
    esperado, obtido, exemplo = collections.Counter(), collections.Counter(), {}
    for ln in A:
        c = campos(ln)
        assert c[k] == b' ' * 5 and c[ultimo][-DELTA:] == b' ' * DELTA
        c[k] = b' ' * 50
        c[ultimo] = c[ultimo][:-DELTA]
        ln = b';'.join(c)
        esperado[h(ln)] += 1
        exemplo.setdefault(h(ln), ln)
    for ln in D:
        obtido[h(ln)] += 1
        exemplo.setdefault(h(ln), ln)
    return relatorio(esperado, obtido, exemplo, id_=slice(3, 43))


def relatorio(esperado, obtido, exemplo, id_):
    so_a = esperado - obtido
    so_d = obtido - esperado
    n = sum(so_a.values())
    print('  linhas comparadas: %d' % sum(esperado.values()))
    if not so_a and not so_d:
        print('IDENTICOS: a unica mudanca e a pedida no SIRL-1223.')
        return 0
    print('HA DIFERENCAS: %d linhas esperadas nao aparecem, %d a mais'
          % (n, sum(so_d.values())))
    # pareia pelo identificador do engajamento e mostra o 1o byte divergente
    por_id = {exemplo[k][id_]: exemplo[k] for k in so_d}
    for k in list(so_a)[:5]:
        a = exemplo[k]
        b = por_id.get(a[id_])
        if b is None:
            print('  sem par: %r' % a[id_].strip())
            continue
        i = next((i for i in range(min(len(a), len(b))) if a[i] != b[i]), None)
        print('  %r: byte %s  esperado |%r|  obtido |%r|'
              % (a[id_].strip(), None if i is None else i + 1,
                 a[i:i + 30] if i is not None else '', b[i:i + 30] if i is not None else ''))
    return 1


if __name__ == '__main__':
    if len(sys.argv) != 4 or sys.argv[1] not in ('crrcorp', 'p3'):
        print(__doc__)
        sys.exit(2)
    fn = crrcorp if sys.argv[1] == 'crrcorp' else p3
    sys.exit(fn(sys.argv[2], sys.argv[3]))
