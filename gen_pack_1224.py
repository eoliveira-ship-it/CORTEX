# -*- coding: utf-8 -*-
"""Poe a procedure do SIRL-1224 no package de producao.

    python gen_pack_1224.py

    pack_alim_tab_envoi_crrv4.sql (producao)
      + pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql (do gen_procedure.py)
      = pack_alim_tab_envoi_crrv4_1224.sql

O sufixo e nome de repositorio: no servidor instala-se com o nome de producao, e
e o montar_entrega.py que lho da ao montar a pasta de entrega.

DUAS INSERCOES, E MAIS NADA
---------------------------
  na spec   'PROCEDURE P_ALIM_ENG_CORP_P1_BIS;'   antes do END do package
  no corpo   a procedure inteira                   antes do END do package

O resto do ficheiro de producao nao muda um octeto. E e o ponto: o package tem
13 500 linhas, das quais 2 872 sao nossas; as outras 10 600 sao de producao e
mudam por razoes que nao as nossas.

PORQUE E QUE ISTO E UM GERADOR
------------------------------
Porque a copia que tinhamos do package do P3 estava atrasada em relacao a
producao, e o SIRL-1223 aplicado a mao nessa copia ia desfazer o SIRL-667 sem
ninguem ver (ver gen_p3_1223.py). Aqui o risco era o mesmo e maior: o package do
1224 tem 2 872 linhas nossas misturadas com o codigo de producao, e um diff nao
distingue "o que nos acrescentamos" de "o que a producao mudou".

Assim, uma versao nova de producao custa isto:

    trocar o pack_alim_tab_envoi_crrv4.sql  ->  python gen_pack_1224.py

e o script para se qualquer uma das ancoras nao estiver exactamente uma vez.
"""
import io
import sys

import enc

FONTE = 'pack_alim_tab_envoi_crrv4.sql'
PROC = 'pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql'
SAIDA = 'pack_alim_tab_envoi_crrv4_1224.sql'
NL = '\r\n'

# O END do package aparece duas vezes: fecha a spec e fecha o corpo. E por isso
# que nao se pode procurar 'a' ancora -- procuram-se as duas, pela ordem.
FIM_PACKAGE = 'END pack_alim_tab_envoi_crrv4;'

DECLARACAO = '\t   PROCEDURE P_ALIM_ENG_CORP_P1_BIS;'


def fins(t):
    """As posicoes dos dois END do package: (fim da spec, fim do corpo)."""
    a = t.find(FIM_PACKAGE)
    b = t.find(FIM_PACKAGE, a + 1)
    if a < 0 or b < 0 or t.find(FIM_PACKAGE, b + 1) >= 0:
        raise SystemExit(
            'esperava o "%s" exactamente duas vezes em %s (a spec e o corpo), '
            'achei %d' % (FIM_PACKAGE, FONTE, t.count(FIM_PACKAGE)))
    # recua ate ao inicio da linha, para a insercao ficar em linhas proprias
    return t.rfind(NL, 0, a) + len(NL), t.rfind(NL, 0, b) + len(NL)


def main():
    t, cod = enc.le(FONTE)
    if 'P_ALIM_ENG_CORP_P1_BIS' in t:
        raise SystemExit('%s ja tem a procedure: e a base a versao de producao?'
                         % FONTE)
    corpo, cod_proc = enc.le(PROC)
    corpo = corpo.replace('\r\n', '\n').replace('\n', NL).rstrip(NL)

    a, b = fins(t)
    # de tras para a frente, senao a primeira insercao estraga o indice da segunda
    t = (t[:b] + corpo + NL + NL + t[b:])
    t = (t[:a] + DECLARACAO + NL + NL + t[a:])

    io.open(SAIDA, 'w', encoding='cp1252', newline='').write(t)

    x, y = io.open(FONTE, 'rb').read(), io.open(SAIDA, 'rb').read()
    print('escreveu %s' % SAIDA)
    print('  %s (%s) %d octetos + %s (%s) -> %d octetos'
          % (FONTE, cod, len(x), PROC, cod_proc, len(y)))
    print('  linhas %d -> %d   (+%d)'
          % (x.count(b'\r\n'), y.count(b'\r\n'),
             y.count(b'\r\n') - x.count(b'\r\n')))
    print('  declaracao x%d, corpo x%d, END do package x%d'
          % (y.count(b'PROCEDURE P_ALIM_ENG_CORP_P1_BIS;'),
             y.count(b'END P_ALIM_ENG_CORP_P1_BIS;'),
             y.count(FIM_PACKAGE.encode())))
    return 0


if __name__ == '__main__':
    sys.exit(main())
