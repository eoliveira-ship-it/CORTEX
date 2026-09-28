# -*- coding: utf-8 -*-
"""Gera o shell do Adapte com os ';' do Z9 -- SIRL-1222.

    python gen_shell_adap.py

Le o 030_CREATION_SPOOL_CRRADAP.sh e escreve o
030_CREATION_SPOOL_CRRADAP_vPACT.sh.

CORRE EM PARALELO, NAO SUBSTITUI
--------------------------------
O shell antigo continua a correr e a escrever o CRRADAP.dat como sempre; no fim,
chama este. E o mesmo desenho do Corporate (030_CREATION_SPOOL_CRRCORP.sh chama o
_vPACT no fim) e tem duas vantagens sobre substituir o original: as duas versoes
saem da MESMA corrida, com os mesmos dados e o mesmo instante, e a comparacao
antes/depois deixa de depender de duas corridas; e se o novo rebentar, o ficheiro
oficial ja esta escrito.

Por isso o gerado nao escreve nos nomes do original -- tem os seus:

    nom_shell   030_CREATION_SPOOL_CRRADAP_vPACT.sh
    ficheiro    CRRADAP_vPACT.dat
    logs        030_CREATION_SPOOL_CRRADAP_vPACT.log / ..._sql_vPACT.log
    spool       ${SQL}/030_spool_Extract_CRRADAP_vPACT.sql

E o fim do original -- o bloco que chama este script -- nao vem para ca, senao o
shell chamava-se a si mesmo.

PORQUE E QUE O SHELL TEM DE MUDAR
---------------------------------
Das quatro linhas do CRRADAP.dat, o spool so escreve uma:

    cabecalho 00;   ecris_entete, no shell     ja tinha 14 ';'   ok
    detalhe   A1    o spool                    0 -> 90
    Z9              ecris_Z9, no shell         0 ->  8           <- aqui
    rodape    99;   no shell                   ja tinha  2 ';'   ok

O ecris_Z9 escrevia os campos colados, e tres deles numa variavel so
(Champs2a4="00370C_BTR       M": entite 5, application 12, frequence 1). Passa a
nove campos com ';' entre todos, e o filler encolhe de 1938 para 1930 -- os 8
octetos dos separadores. 1992 + 8 = 2000, que e o que a notice do Adapte da ao
Z9.

O cabecalho e o rodape nao se tocam: os ';' deles ja batem com a notice, e os
fillers tambem (1886 e 1986, ao octeto).

A LINHA DE RASTO
----------------
Acrescenta-se um trace_log que escreve, no log de cada corrida, QUAL ficheiro de
spool foi lido e que VERSAO tem. Sem isto a corrida de 27/09 as 23:24 saiu com o
Z9 novo e as 1774 linhas A1 no formato antigo, e nao havia como saber, de dentro
do ficheiro, que o @$spool_sql tinha ido buscar o spool velho: o shell chama-o
pelo nome fixo ${SQL}/030_spool_Extract_CRRADAP.sql, e um spool gerado deixado
ao lado com outro nome nunca e lido -- sem erro nenhum, o que e a pior maneira de
falhar.

O FICHEIRO FICA COMO ESTAVA
---------------------------
cp1252 e CRLF, e com os mesmos 24 octetos acentuados nos comentarios. A alteracao
e cirurgica: quatro sitios, e nenhum outro octeto muda. No .sql o gerador dobra
tudo para ASCII porque reescreve o ficheiro por inteiro; aqui nao ha razao para
mexer no que nao se pediu.
"""
import io
import sys

FONTE = '030_CREATION_SPOOL_CRRADAP.sh'
SAIDA = '030_CREATION_SPOOL_CRRADAP_vPACT.sh'
NL = '\r\n'

# Primeiro os nomes: o gerado corre ao lado do original e nao lhe toca em nada.
RENOMES = [
    (
        '## Script        : 030_CREATION_SPOOL_CRRADAP.sh                              ##',
        '## Script        : 030_CREATION_SPOOL_CRRADAP_vPACT.sh                        ##',
    ),
    (
        '## Creation      : le 18/05/2021 par DUGUET MARC                              ##',
        '## Creation      : le 28/09/2026 par OLIVEIRA ELDERSON                        ##' + NL +
        '##                 a partir do 030_CREATION_SPOOL_CRRADAP.sh                  ##',
    ),
    ('nom_shell=030_CREATION_SPOOL_CRRADAP.sh',
     'nom_shell=030_CREATION_SPOOL_CRRADAP_vPACT.sh'),
    ('V30ENVOICRRFIC="CRRADAP.dat"',
     'V30ENVOICRRFIC="CRRADAP_vPACT.dat"'),
    ('V30ENVOICRRV4LOG=030_CREATION_SPOOL_CRRADAP.log',
     'V30ENVOICRRV4LOG=030_CREATION_SPOOL_CRRADAP_vPACT.log'),
    ('V30ENVOICRRV4ERR=030_CREATION_SPOOL_CRRADAP_sql.log',
     'V30ENVOICRRV4ERR=030_CREATION_SPOOL_CRRADAP_sql_vPACT.log'),
    ('spool_sql="${SQL}/030_spool_Extract_CRRADAP.sql"',
     'spool_sql="${SQL}/030_spool_Extract_CRRADAP_vPACT.sql"'),
]

# O fim do original chama este script. Nao vem para ca, senao o shell chamava-se
# a si mesmo -- e nao se apaga do original, que e onde tem de estar. Corta-se
# pelas duas pontas em vez de por um literal: a linha do ERR tem um acento, e um
# acento num literal deste ficheiro (UTF-8) nao casa com o do shell (cp1252).
CHAMADA_A_SI = ('trace_log "INF" "Lancement du script %s"' % SAIDA,
                'trace_log "INF" "Fin du script %s"' % SAIDA)


def tira_a_chamada(t):
    a = t.find(CHAMADA_A_SI[0])
    b = t.find(CHAMADA_A_SI[1])
    if a < 0 or b < a:
        raise SystemExit('nao achei o bloco que chama o %s no fim do %s'
                         % (SAIDA, FONTE))
    # o corte deixaria as linhas em branco dos dois lados do bloco: fica so o
    # par de linhas em branco que o original tem antes do DATE_TRT
    return t[:a].rstrip(NL) + NL * 3 + t[b + len(CHAMADA_A_SI[1]):].lstrip(NL)

TROCAS = [
    # (o que esta la, o que passa a estar)
    (
        '## 16/01/2026 MESQUIPE: SIRL-712 - MERCA                                      ##',
        '## 28/09/2026 SIRL-1222 : ";" entre os campos do Z9 (o cabecalho e o          ##' + NL +
        '##            rodape ja os tinham; o detalhe vem do spool)                    ##' + NL +
        '## 16/01/2026 MESQUIPE: SIRL-712 - MERCA                                      ##',
    ),
    (
        '  finlignez9=`printf "%1938s" " " ` ##BALE4',
        '  #finlignez9=`printf "%1938s" " " ` ##BALE4' + NL +
        '  # SIRL-1222: o filler do Z9 encolhe os 8 octetos dos separadores.' + NL +
        '  # A notice do Adapte da 1930 ao Z9 99.99; 1992 + 8 ";" = 2000.' + NL +
        '  finlignez9=`printf "%1930s" " " `',
    ),
    (
        '  echo "$dtarrete$Champs2a4$masysdate$TypeLigne$NatureFlux$ftotligne'
        '$finlignez9" >>  $SORTIE/$V30ENVOICRRFIC',
        '  # SIRL-1222: os 9 campos do Z9 com ";" entre todos (8 separadores). O' + NL +
        '  # Champs2a4 tinha os tres campos colados -- entite 5, application 12,' + NL +
        '  # frequence 1 -- e passa a tres variaveis. O filler final nao leva ";"' + NL +
        '  # a seguir, que e a regra da SFG para os fluxos de formato fixo.' + NL +
        '  entiteZ9="00370"' + NL +
        '  appliZ9=`printf "%-12s" "C_BTR" `' + NL +
        '  freqZ9="M"' + NL +
        '  #echo "$dtarrete$Champs2a4$masysdate$TypeLigne$NatureFlux$ftotligne'
        '$finlignez9" >>  $SORTIE/$V30ENVOICRRFIC' + NL +
        '  echo "$dtarrete;$entiteZ9;$appliZ9;$freqZ9;$masysdate;$TypeLigne;'
        '$NatureFlux;$ftotligne;$finlignez9" >>  $SORTIE/$V30ENVOICRRFIC',
    ),
    (
        'spool_sql="${SQL}/030_spool_Extract_CRRADAP_vPACT.sql"',
        'spool_sql="${SQL}/030_spool_Extract_CRRADAP_vPACT.sql"' + NL +
        '# SIRL-1222: deixa no log qual spool foi lido, e que versao tem. O' + NL +
        '# @$spool_sql chama este nome fixo: um spool gerado deixado ao lado com' + NL +
        '# outro nome nunca e lido, e a corrida sai no formato antigo sem erro.' + NL +
        'trace_spool()' + NL +
        '{' + NL +
        '  if [ -f "$spool_sql" ]; then' + NL +
        '    trace_log "INFO" 0 "Spool lido : $spool_sql"' + NL +
        '    versao_spool=`grep -m1 "VERSAO" "$spool_sql"`' + NL +
        '    if [ -n "$versao_spool" ]; then' + NL +
        '      trace_log "INFO" 0 "  $versao_spool"' + NL +
        '    else' + NL +
        '      trace_log "WARN" 100 "  sem linha VERSAO: e o spool anterior ao SIRL-1222"' + NL +
        '    fi' + NL +
        '  else' + NL +
        '    trace_log "ERROR" 5000 "Spool nao encontrado : $spool_sql" $nom_shell' + NL +
        '  fi' + NL +
        '}',
    ),
    # Chama-se a funcao logo a seguir ao recup_numenvoi: e o ultimo ponto do
    # fluxo principal antes de o script se dividir em dois ramos (com e sem
    # parametros), e ja e depois da definicao do trace_log. Tem de ser ANTES da
    # extracao -- se o spool rebentar, o extract_entite faz exit 1, e o rasto
    # que diz qual spool foi lido e justamente o que faz falta nesse caso.
    (
        'recup_numenvoi' + NL +
        '' + NL +
        '# --------------------' + NL +
        '# Si pas de parametres : extraction complete',
        'recup_numenvoi' + NL +
        '' + NL +
        '# SIRL-1222: qual spool vai ser lido nesta corrida' + NL +
        'trace_spool' + NL +
        '' + NL +
        '# --------------------' + NL +
        '# Si pas de parametres : extraction complete',
    ),
]


def main():
    t = tira_a_chamada(io.open(FONTE, encoding='cp1252', newline='').read())
    for velho, novo in RENOMES + TROCAS:
        if t.count(velho) != 1:
            raise SystemExit('nao achei exactamente uma vez em %s:\n  %s'
                             % (FONTE, velho.split(NL)[0][:70]))
        t = t.replace(velho, novo, 1)
    io.open(SAIDA, 'w', encoding='cp1252', newline='').write(t)
    orig = io.open(FONTE, 'rb').read()
    novo = io.open(SAIDA, 'rb').read()
    print('escreveu %s' % SAIDA)
    print('  %d -> %d octetos, CRLF %d -> %d, acentos %d -> %d'
          % (len(orig), len(novo), orig.count(b'\r\n'), novo.count(b'\r\n'),
             sum(1 for b in orig if b > 127), sum(1 for b in novo if b > 127)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
