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
#
# 3. A ORDEM das linhas. Nenhum dos dois spools tem ORDER BY, e a procedure
#    faz DELETE + INSERT a cada execucao: a ordem muda sem que o conteudo
#    mude. Por isso as linhas sao ordenadas antes do diff. O teste e por
#    conteudo, nao por posicao (docs/SIRL-1224.md, "A ordem das linhas").
#    LC_ALL=C: ordenacao por byte, igual nos dois ficheiros.
normaliza()
{
  grep -v '^00;' "$1" | sed -e 's/^\(.\{26\}\).\{12\}/\1############/' | LC_ALL=C sort
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
echo "=== 3) diff do conteudo, sem o horodatage, sem a linha ENTETE e com as linhas ordenadas"
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
  # com as linhas ordenadas, a 1a linha de cada lado ja nao e o mesmo
  # registo: compara-se a 1a linha que so existe no antigo com a 1a que so
  # existe no novo
  { diff /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ | grep '^<' | head -1 | cut -c3-
    diff /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ | grep '^>' | head -1 | cut -c3-
  } > /tmp/cmp_par.$$
  awk 'NR==1{a=$0} NR==2{b=$0;
       for(i=1;i<=length(a);i++)
         if(substr(a,i,1)!=substr(b,i,1)){print "primeira divergencia no byte "i;
            print "  antigo: |"substr(a,i,30)"|";
            print "  novo  : |"substr(b,i,30)"|"; exit}
       print "as duas primeiras linhas sao iguais"}' /tmp/cmp_par.$$
fi

rm -f /tmp/cmp_antigo.$$ /tmp/cmp_novo.$$ /tmp/cmp_par.$$
