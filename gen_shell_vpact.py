# -*- coding: utf-8 -*-
"""Gera o shell do Corporate que corre ao lado do de producao -- SIRL-1224.

    python gen_shell_vpact.py

Le o 030_CREATION_SPOOL_CRRCORP.sh, que e a versao DE PRODUCAO, e escreve o
030_CREATION_SPOOL_CRRCORP_vPACT.sh.

O QUE MUDA
----------
  os nomes      nom_shell, o ficheiro de saida, os dois logs e o spool
  o passo novo  enche a ENG_CORP_P1_BIS antes de o spool a ler

E MAIS NADA. Em particular, o que o shell de producao faz continua todo aqui --
incluindo o passo do RSE_LOT3 que enche a PERIM_ENVOI_CRR_P1.

PORQUE E QUE ISTO E UM GERADOR (E PORQUE NAO ERA)
-------------------------------------------------
Este ficheiro estava no repositorio feito a mao, e tinha um passo de producao a
menos: quem o copiou pos o nosso

    execute PACK_ALIM_TAB_ENVOI_CRRV4.P_ALIM_ENG_CORP_P1_BIS;

NO LUGAR do de producao

    execute PACK_ALIM_TAB_ENVOI_CRRV4.P_ALIM_PERIM_ENVOI_CRR_P1;   -- RSE_LOT3
                                                                   -- SIRL-153
em vez de o por ao lado.

Hoje isso nao se nota: o shell de producao corre primeiro, enche a
PERIM_ENVOI_CRR_P1, e so depois chama este. Nota-se no dia em que este shell
SUBSTITUIR o de producao -- que e o fim do SIRL-1224. Nesse dia a
PERIM_ENVOI_CRR_P1 deixa de ser enchida, e sem erro: fica com o conteudo do
arrete anterior. Nada da nossa cadeia a le, por isso nao seriamos nos a dar por
isso.

Gerado a partir do ficheiro de producao, o passo nao se perde: esta la porque
esta la no original.

O PASSO DO RSE_LOT3 NAO VEM PARA CA
-----------------------------------
O shell de producao tem um passo que nao e nosso -- o RSE_LOT3 / SIRL-153, que
enche a PERIM_ENVOI_CRR_P1. Esse passo NAO entra neste ficheiro: quem o corre e o
shell de producao, que e quem chama este. Repeti-lo aqui custava oito varrimentos
da ENG_CORP_P1 com UNION (nao UNION ALL) em cada corrida, para reescrever a
tabela com o mesmo conteudo.

No lugar dele fica um comentario, que nao corre nada, a dizer que falta e porque.
E para o dia em que este shell substituir o de producao -- que e o fim do
SIRL-1224. Nesse dia ha que o trazer, senao a PERIM_ENVOI_CRR_P1 deixa de ser
enchida sem dar erro: fica com o conteudo do arrete anterior.

A ORDEM DO PASSO NOVO
---------------------
O nosso bloco entra ANTES do extract_entite(), e portanto antes do @$spool_sql:
o spool le a ENG_CORP_P1_BIS, tem de a encontrar cheia. O passo do RSE_LOT3 fica
onde o original o tem, depois da extraccao -- nao depende de nada nosso.
"""
import io
import sys

import enc

FONTE = '030_CREATION_SPOOL_CRRCORP.sh'
SAIDA = '030_CREATION_SPOOL_CRRCORP_vPACT.sh'
NL = '\r\n'

RENOMES = [
    (
        '## Script        : 030_CREATION_SPOOL_CRRCORP.sh                              ##',
        '## Script        : 030_CREATION_SPOOL_CRRCORP_vPACT.sh                        ##',
    ),
    ('nom_shell=030_CREATION_SPOOL_CRRCORP.sh',
     'nom_shell=030_CREATION_SPOOL_CRRCORP_vPACT.sh'),
    ('V30ENVOICRRFIC="CRRCORP.dat"',
     'V30ENVOICRRFIC="CRRCORP_vPACT.dat"'),
    ('V30ENVOICRRV4LOG=030_CREATION_SPOOL_CRRCORP.log',
     'V30ENVOICRRV4LOG=030_CREATION_SPOOL_CRRCORP_vPACT.log'),
    ('V30ENVOICRRV4ERR=030_CREATION_SPOOL_CRRCORP_sql.log',
     'V30ENVOICRRV4ERR=030_CREATION_SPOOL_CRRCORP_sql_vPACT.log'),
    ('spool_sql="${SQL}/030_spool_Extract_CRRCORP.sql"',
     'spool_sql="${SQL}/030_spool_Extract_CRRCORP_vPACT.sql"'),
]

# o bloco entra antes desta linha: a extraccao, que e quem chama o spool
ANCORA = 'extract_entite()'

# o passo de producao que se poe dentro da guarda: do comentario do RSE_LOT3 ate
# ao DATE_TRT que fecha o tratamento
PERIM_INICIO = ('## RSE_LOT3: SIRL-153 - 29/05/2025 - Remplissage de la table '
                'PERIM_ENVOI_CRR_P1')
PERIM_FIM = "DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `"
# No lugar do passo do RSE_LOT3 fica so um aviso. Nao corre nada: e uma linha de
# comentario, para quem vier nao ter de descobrir sozinho que o passo falta.
AVISO = NL.join([
    '## SIRL-1224 - le pas RSE_LOT3 / SIRL-153 (P_ALIM_PERIM_ENVOI_CRR_P1) n\'est',
    '## PAS ici : il tourne dans le shell de production, qui appelle celui-ci.',
    '## Le jour ou ce shell remplacera celui de la production, il faudra le',
    '## remettre -- sinon la table PERIM_ENVOI_CRR_P1 ne sera plus alimentee, et',
    '## sans erreur : elle gardera le contenu de l\'arrete precedent.',
    '',
])

BLOCO = NL.join([
    '## SIRL-1224 - Remplissage de la table ENG_CORP_P1_BIS (toutes les entites, un seul appel)',
    'sqlplus $V30LOGIN <<EOF  >>$V30RACINE/log/$V30ENVOICRRV4ERR',
    'set serveroutput on size 1000000;',
    'whenever oserror exit 9;',
    'whenever sqlerror exit sql.sqlcode;',
    '',
    'execute PACK_ALIM_TAB_ENVOI_CRRV4.P_ALIM_ENG_CORP_P1_BIS;',
    '',
    'spool off;',
    '',
    'EXIT;',
    'EOF',
    '',
    '# -------------------------------',
    '#   Analyse erreur',
    '# -------------------------------',
    'if [ -f $V30RACINE/log/$V30ENVOICRRV4ERR ]',
    'then',
    '  V99015FICLOG=$V30RACINE/log//$V30ENVOICRRV4ERR',
    '  export V99015FICLOG',
    '  $EXECRP',
    '  CRP=$?',
    '  if [ $CRP != 0 ]',
    '  then',
    '    echo "Erreur dans 030_CREATION_SPOOL_CRRCORP durant P_ALIM_ENG_CORP_P1_BIS"',
    '    exit 1',
    '  fi',
    'fi',
    '',
    "DATE_TRT=`date '+%d/%m/%Y  %H:%M:%S' `",
    'trace_log "INF" 0 "-----------------------------------------------------------"',
    'trace_log "INF" 0 "$DATE_TRT - FIN ALIMENTATION ENG_CORP_P1_BIS" $nom_shell',
    'trace_log "INF" 0 "-----------------------------------------------------------"',
    '', '', '',
])


def main():
    t, cod = enc.le(FONTE)
    if 'P_ALIM_ENG_CORP_P1_BIS' in t:
        raise SystemExit('%s ja enche a ENG_CORP_P1_BIS: a base nao e o ficheiro '
                         'de producao' % FONTE)
    for velho, novo in RENOMES:
        n = t.count(velho)
        if n != 1:
            raise SystemExit('achei %d vezes (esperava 1) em %s:\n  %s'
                             % (n, FONTE, velho))
        t = t.replace(velho, novo, 1)

    n = t.count(ANCORA)
    if n != 1:
        raise SystemExit('achei a ancora "%s" %d vezes em %s (esperava 1)'
                         % (ANCORA, n, FONTE))
    i = t.index(ANCORA)
    i = t.rfind(NL, 0, i) + len(NL)          # inicio da linha
    t = t[:i] + BLOCO + t[i:]

    # o passo do RSE_LOT3 sai, e fica o aviso no lugar dele
    a = t.find(PERIM_INICIO)
    if a < 0:
        raise SystemExit('nao achei o passo do RSE_LOT3 em %s:\n  %s'
                         % (FONTE, PERIM_INICIO))
    b = t.find(PERIM_FIM, a)
    if b < 0:
        raise SystemExit('nao achei o fim do passo do RSE_LOT3 (o %s a seguir)'
                         % PERIM_FIM)
    t = t[:a] + AVISO + NL + t[b:]

    io.open(SAIDA, 'w', encoding='cp1252', newline='').write(t)

    a, b = io.open(FONTE, 'rb').read(), io.open(SAIDA, 'rb').read()
    print('escreveu %s' % SAIDA)
    print('  a partir de %s (%s), %d -> %d octetos, +%d linhas'
          % (FONTE, cod, len(a), len(b), b.count(b'\r\n') - a.count(b'\r\n')))
    for alvo in (b'P_ALIM_ENG_CORP_P1_BIS', b'P_ALIM_PERIM_ENVOI_CRR_P1',
                 b'030_spool_Extract_CRRCORP_vPACT.sql', b'CRRCORP_vPACT.dat'):
        print('  %-36s x%d' % (alvo.decode(), b.count(alvo)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
