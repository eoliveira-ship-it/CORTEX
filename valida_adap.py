"""Confere a regua do Adapte contra um CRRADAP.dat real.

    python valida_adap.py <CRRADAP.dat>

Prova que a regua da notice e a boa: corta cada linha de detalhe pelas larguras
que a notice da e mostra, campo a campo, o que la esta nas 1774 linhas. Se a
regua estivesse deslocada um so octeto, os montantes apareciam sem o sinal a
frente e as datas partidas -- a leitura e o teste.

Diz tambem, de cada campo, se esta sempre em branco no ficheiro de hoje. Num
ficheiro sem ';' um campo em branco e indistinguivel do filler ao lado: e por
isso que a regua nao se podia adivinhar dos dados e tinha de vir da notice.
"""
import collections
import sys

import notice_adap

PAVE = slice(38, 40)        # o codigo do registo, no formato sem ';'

# Ha nomes de campo com caracteres que a consola em cp1252 nao sabe escrever
# ('Duree initiale <= 3 mois' traz um U+2264). Nao interessa ao teste: escreve-se
# um '?' em vez de estourar a meio da listagem.
sys.stdout.reconfigure(encoding=sys.stdout.encoding, errors='replace')


def linhas(caminho):
    with open(caminho, 'rb') as f:
        for ln in f:
            yield ln.rstrip(b'\r\n')


def sem_separador(caminho):
    """Recusa-se a ler um CRRADAP que ja tem ';' entre os campos (SIRL-1222).

    Este script conta com as posicoes do formato antigo -- o codigo do registo
    nos octetos 39-40, cada campo colado no seguinte. Num ficheiro com ';' o
    l[38:40] nao e o registo, o filtro nao apanha nada e a queixa que saia era
    'nenhuma linha de detalhe A1' num ficheiro com 1774. Para o formato novo
    use o comparar_adap.py, que desfaz os separadores antes de comparar.
    """
    with open(caminho, 'rb') as f:
        f.readline()                       # o cabecalho tem ';' nos dois formatos
        ln = f.readline()
    if ln[8:9] == b';':
        raise SystemExit(
            '%s esta no formato do SIRL-1222, com ";" entre os campos.\n'
            'Este script le a regua por posicao, do formato antigo. Para o\n'
            'novo use:  python comparar_adap.py <novo> <a referencia sem ";">'
            % caminho)


def main(caminho):
    sem_separador(caminho)
    d = notice_adap.carrega()
    lin = list(linhas(caminho))
    print('%s: %d linhas de %d octetos' % (caminho, len(lin), len(lin[0])))
    censo = collections.Counter(l[PAVE].decode('cp1252', 'replace') for l in lin)
    print('registos: %s' % dict(censo))

    campos = d['A1']
    det = [l for l in lin if l[PAVE] == b'A1']
    if not det:
        raise SystemExit('nenhuma linha de detalhe A1')
    print()
    print('%-4s %-12s %-30s %-5s %5s  %-9s %s'
          % ('n', 'ref', 'nome', 'fmt', 'len', 'estado', 'exemplo'))
    p, brancos = 0, 0
    for c in campos:
        vals = {l[p:p + c['len']] for l in det}
        branco = b' ' * c['len']
        if vals == {branco}:
            estado, exemplo = 'BRANCO', ''
            brancos += 1
        else:
            estado = 'valor' if branco not in vals else 'as vezes'
            exemplo = sorted(vals)[-1].decode('cp1252', 'replace')
        print('%-4s %-12s %-30s %-5s %5d  %-9s %s'
              % (c['ordem'], c['ref'], c['nome'][:30], c['fmt'], c['len'],
                 estado, exemplo[:32]))
        p += c['len']
    print()
    print('a regua cobre %d octetos; a linha tem %d' % (p, len(det[0])))
    print('  a diferenca, %d, e o numero de ";" que vao entrar: %d campos - 1'
          % (len(det[0]) - p, len(campos)))
    print('campos sempre em branco: %d de %d' % (brancos, len(campos)))
    return 0 if len(det[0]) - p == len(campos) - 1 else 1


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
