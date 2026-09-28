# -*- coding: utf-8 -*-
"""Poe nos shells de producao a chamada ao shell _vPACT.

    python gen_chamada_vpact.py

    030_CREATION_SPOOL_CRRCORP.sh  ->  030_CREATION_SPOOL_CRRCORP_1224.sh
    030_CREATION_SPOOL_CRRADAP.sh  ->  030_CREATION_SPOOL_CRRADAP_1222.sh

O sufixo e nome de repositorio. No servidor os dois instalam-se com o nome de
producao, sem sufixo -- e o montar_entrega.py que lhes tira o nome ao montar a
pasta de entrega.

PORQUE E QUE ISTO E UM GERADOR
------------------------------
Porque a chamada e a UNICA coisa que os dois chamados mudam nestes shells, e
porque os shells de producao mudam por outras razoes que nao as nossas. Guardada
a alteracao como uma linha de codigo em vez de um ficheiro editado a mao, uma
versao nova de producao custa isto:

    trocar o ficheiro de producao  ->  python gen_chamada_vpact.py

Foi por nao ser assim que o package do P3 levou o SIRL-1223 aplicado a uma base
atrasada, e ia desfazer o SIRL-667 sem ninguem ver (ver gen_p3_1223.py).

O DESENHO: CORRE AO LADO, NAO SUBSTITUI
---------------------------------------
O shell de sempre continua a escrever o ficheiro oficial e, no fim, chama o
_vPACT, que escreve o seu. Os dois ficheiros saem da MESMA corrida -- mesmos
dados, mesmo instante -- e se o novo rebentar, o oficial ja esta escrito.

O QUE ESTE BLOCO TEM DE ERRADO, E PORQUE FICA
---------------------------------------------
Duas coisas, as duas herdadas do bloco que ja estava no shell do Corporate e que
ja correu no DEV2:

  * o ERR nao e uma funcao destes shells (nenhum dos dois o define). Da
    "ERR: command not found" no log; o exit $RC a seguir ainda propaga a falha,
    mas a mensagem de erro perde-se;
  * o trace_log espera tres argumentos -- echo "$1-$2 : $3 - $4" -- e aqui leva
    dois, pelo que a mensagem cai no campo do codigo: sai "INF-Lancement ... : -".

Ficam como estao de proposito: e o bloco que correu, e o que se entrega tem de
ser o que foi testado. A correccao, se a DSID a quiser, e uma linha em cada:

    trace_log "INF" 0 "Lancement du script ..."
    trace_log "ERROR" $RC "Erreur lors de l'execution du script ..." $nom_shell
"""
import io
import sys

import enc

NL = '\r\n'

# (shell de producao, shell gerado, o shell que ele passa a chamar)
PARES = [
    ('030_CREATION_SPOOL_CRRCORP.sh', '030_CREATION_SPOOL_CRRCORP_1224.sh',
     '030_CREATION_SPOOL_CRRCORP_vPACT.sh'),
    ('030_CREATION_SPOOL_CRRADAP.sh', '030_CREATION_SPOOL_CRRADAP_1222.sh',
     '030_CREATION_SPOOL_CRRADAP_vPACT.sh'),
]

# o ponto de insercao: a ultima linha em branco antes do fecho do tratamento
ANCORA = "DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `"


def bloco(chamado):
    """O bloco, exactamente como estava no shell do Corporate."""
    return NL.join([
        'trace_log "INF" "Lancement du script %s"' % chamado,
        '',
        'sh $SHL/%s' % chamado,
        'RC=$?',
        '',
        'if [ $RC -ne 0 ]',
        'then',
        # o 'e' de execution escrito como \xe9, o octeto do cp1252: assim o
        # bloco sai igual ao que correu no DEV2 sem depender da codificacao
        # DESTE ficheiro .py
        '    ERR $RC "Erreur lors de l\'ex\xe9cution du script %s"' % chamado,
        '    exit $RC',
        'fi',
        '',
        'trace_log "INF" "Fin du script %s"' % chamado,
    ])


def main():
    for fonte, saida, chamado in PARES:
        t, cod = enc.le(fonte)
        if chamado in t:
            raise SystemExit('%s ja chama o %s: nada a fazer, ou a base ja foi '
                             'alterada a mao' % (fonte, chamado))
        # a ancora aparece duas vezes (inicio e fim do tratamento): a ultima
        i = t.rfind(ANCORA)
        if i < 0:
            raise SystemExit('nao achei a ancora em %s:\n  %s' % (fonte, ANCORA))
        # recua sobre as linhas em branco que ja estao antes da ancora, para o
        # bloco entrar antes delas e nao somar linhas em branco as que ja ha
        brancas = ''
        while t[:i].endswith(NL):
            i -= len(NL)
            brancas += NL
        novo = t[:i] + NL + bloco(chamado) + brancas + t[i:]
        # em cp1252, que e a regra do projecto para os .sql e os .sh
        io.open(saida, 'w', encoding='cp1252', newline='').write(novo)
        a, b = io.open(fonte, 'rb').read(), io.open(saida, 'rb').read()
        print('escreveu %s' % saida)
        print('  a partir de %s (%s), %d -> %d octetos, +%d linhas, chama o %s'
              % (fonte, cod, len(a), len(b),
                 b.count(b'\r\n') - a.count(b'\r\n'), chamado))
    return 0


if __name__ == '__main__':
    sys.exit(main())
