#!/bin/ksh
################################################################################
## Compara o CRRCORP.dat do spool atual com o do spool vPACT.      SIRL-1224  ##
##                                                                            ##
##   ./comparar_ficheiros.sh  CRRCORP.dat  CRRCORP_vPACT.dat                  ##
##                                                                            ##
## Um diff cru nao serve: os dois ficheiros foram gerados em execucoes        ##
## diferentes e ha tres campos que mudam SEMPRE, sem que nada de errado se    ##
## passe. Este script neutraliza-os e compara o resto.                        ##
################################################################################

ANTIGO=$1
NOVO=$2

if [ ! -f "$ANTIGO" ] || [ ! -f "$NOVO" ]; then
  echo "uso: $0 <ficheiro_antigo> <ficheiro_novo>"
  exit 1
fi

# ------------------------------------------------------------------ o ruido
# 1. MASYSDATE, bytes 27..38 de TODAS as linhas. O shell fa-lo com
#       masysdate=`date '+%Y%m%d%H%M'`
#    ou seja, ao minuto. Duas execucoes em minutos diferentes dao dois
#    horodatages diferentes em todas as linhas dos dois ficheiros.
#
# 2. A linha ENTETE (comeca por "00;"). Alem do horodatage ao segundo, traz o
#    numero de envio, que o MERGE em PAR_ENVOI_CRRV43 incrementa a cada
#    execucao. Nunca pode ser igual entre duas corridas.
#
# O cabecalho de cada linha e: arrete 8 + entite 5 + appli 12 + frequencia 1
# = 26 bytes, e so depois vem o horodatage de 12. Dai o .{26} e o .{12}.
normaliza()
{
  grep -v '^00;' "$1" | sed -e 's/^\(.\{26\}\).\{12\}/\1############/'
}

echo "=== 1) tamanho e numero de linhas"
wc -c "$ANTIGO" "$NOVO"
wc -l "$ANTIGO" "$NOVO"

echo
echo "=== 2) censo dos paves (bytes 39-40)"
echo "--- antigo"
cut -c39-40 "$ANTIGO" | sort | uniq -c
echo "--- novo"
cut -c39-40 "$NOVO" | sort | uniq -c

echo
echo "=== 3) diff do conteudo, sem o horodatage e sem a linha ENTETE"
normaliza "$ANTIGO" > /tmp/cmp_antigo.$$
normaliza "$NOVO"   > /tmp/cmp_novo.$$

if diff -q /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ > /dev/null; then
  echo "IDENTICOS. Nao-regressao provada."
else
  echo "HA DIFERENCAS. Primeiras 20 linhas divergentes:"
  echo
  # -y mostra lado a lado; --suppress-common-lines so o que difere
  diff /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ | head -40
  echo
  echo "--- quantas linhas divergem"
  diff /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ | grep -c '^<'

  echo
  echo "--- em que COLUNA comeca a primeira diferenca"
  # o numero da coluna aponta direto para o campo na regua da notice
  paste -d'\n' /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ 2>/dev/null | head -2 > /tmp/cmp_par.$$
  awk 'NR==1{a=$0} NR==2{b=$0;
       for(i=1;i<=length(a);i++)
         if(substr(a,i,1)!=substr(b,i,1)){print "primeira divergencia no byte "i;
            print "  antigo: |"substr(a,i,30)"|";
            print "  novo  : |"substr(b,i,30)"|"; exit}
       print "as duas primeiras linhas sao iguais"}' /tmp/cmp_par.$$
fi

rm -f /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ /tmp/cmp_par.$$
