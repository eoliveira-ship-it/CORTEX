# -*- coding: utf-8 -*-
"""Gera o package do P3 com o 21.65 alargado -- SIRL-1223.

    python gen_p3_1223.py

Le o PACK_UTL_FILE_ENVOI_C3RD2_PROD.sql, que e a versao QUE ESTA EM PRODUCAO, e
escreve o PACK_UTL_FILE_ENVOI_C3RD2_1223.sql. No servidor o gerado instala-se com
o nome de producao (e o montar_entrega.py que lhe tira o sufixo).

PORQUE E QUE ISTO E UM GERADOR, PARA DUAS LINHAS
------------------------------------------------
Porque o que custa nao e a alteracao, e a BASE.

A copia do package que estava no repositorio vinha do DDR e estava atrasada em
relacao a producao. As duas linhas do chamado tinham sido aplicadas nela, e o
ficheiro que sairia dali, instalado em producao, desfazia tres coisas que ninguem
pediu:

  1. o SIRL-667 (29/04/2026), que RETIROU a entidade '00372' das cinco listas
     liste_cd_conso -- e portanto voltaria a sair um 6o ficheiro UC2_P3, vazio;
  2. o v_ligne do C2, que em producao e VARCHAR2(2002) e na copia era 2000, e o
     ';' final da linha do C2, que a copia nao tinha;
  3. o mesmo no C3 (1002 contra 1000), e o default do IND_WL, que em producao e
     '9' e na copia era ' ' (C2 4.60 e C3 4.60).

Nada disto se ve num diff do chamado: as duas linhas do 21.65 estao certas nos
dois ficheiros. Ve-se so comparando a base com a producao -- e foi o 6o ficheiro
UC2_P3 numa corrida do DEV2 que deu o alerta.

Daqui para a frente a base e a producao, e a alteracao e aplicada por um script
que PARA se a linha que procura nao estiver exactamente uma vez. E se a producao
mudar outra vez, e so trocar o ficheiro PROD e correr isto.
"""
import io
import sys

FONTE = 'PACK_UTL_FILE_ENVOI_C3RD2_PROD.sql'
SAIDA = 'PACK_UTL_FILE_ENVOI_C3RD2_1223.sql'

TROCAS = [
    # (o que esta la, o que passa a estar)   -- P_UTLF_CREDIT_P3
    (
        "RPAD(' ',5)         ||';'||--P3C 21.65",
        "RPAD(' ',50)         ||';'||--P3C 21.65 -- SIRL-1223 5 -> 50",
    ),
    # O filler encolhe os mesmos 45 octetos: a linha fica com 4500, como estava.
    (
        "RPAD(' ',1132); -- BALE4",
        "RPAD(' ',1087); -- BALE4    -- SIRL-1223 1132 -> 1087",
    ),
]


def main():
    t = io.open(FONTE, encoding='cp1252', newline='').read()
    for velho, novo in TROCAS:
        n = t.count(velho)
        if n != 1:
            raise SystemExit(
                'achei %d vezes (esperava 1) em %s:\n  %s\n'
                'A producao mudou? Confirmar antes de mexer.' % (n, FONTE, velho))
        t = t.replace(velho, novo, 1)
    io.open(SAIDA, 'w', encoding='cp1252', newline='').write(t)

    a = io.open(FONTE, 'rb').read()
    b = io.open(SAIDA, 'rb').read()
    print('escreveu %s' % SAIDA)
    print('  %d -> %d octetos, CRLF %d -> %d, acentos %d -> %d'
          % (len(a), len(b), a.count(b'\r\n'), b.count(b'\r\n'),
             sum(1 for c in a if c > 127), sum(1 for c in b if c > 127)))
    # o 00372 nao volta: as listas ficam como a producao as tem
    for f, n in ((FONTE, a), (SAIDA, b)):
        print('  %-40s \'00372\' x%d' % (f, n.count(b"'00372'")))
    return 0


if __name__ == '__main__':
    sys.exit(main())
