#!/bin/ksh
################################################################################
## Compara dois CRRCORP.dat.                            SIRL-1224 / SIRL-1222 ##
## Este ficheiro tem fim de linha LF, e nao CRLF como os .sh do cliente: corre
## no servidor, chamado por sh/ksh, e um  no fim do #!/bin/ksh ou de uma
## atribuicao quebra-o. Nao converter.
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

# --------------------------------------------------------------- os formatos
# O SIRL-1222 poe ';' entre todos os campos, e isso desloca tudo o que vem a
# seguir ao primeiro campo. As posicoes deixam de ser as mesmas:
#
#   campo                       sem ';'    com ';'
#   0.1 Date d'arrete (8)         1-8        1-8
#   0.2 Entite (5)                9-13      10-14
#   0.3 Application (12)         14-25      16-27
#   0.4 Frequence (1)              26         29
#   0.5 Date/Heure (12)          27-38      31-42
#   0.6 Type d'enregistrement     39-40      44-45   <- o codigo do pave
#
# Este script sabia so as da esquerda. Num ficheiro com ';' o censo por pave
# lia dois octetos do meio do horodatage -- dava uma contagem errada sem se
# queixar, que e a pior maneira de estar errado. Por isso o formato de cada
# ficheiro passa a ser DETETADO, e nao assumido.
#
# Como se deteta: no formato novo o octeto 9 e o ';' que fecha a data de
# arrete; no antigo e o primeiro algarismo da entite. Le-se na linha 2, porque
# a linha 1 e o cabecalho, que tem ';' nos dois formatos.
formato()
{
  if [ "$(sed -n '2p' "$1" | cut -c9)" = ";" ]; then
    echo novo
  else
    echo antigo
  fi
}

posicoes()
{
  # $1 = formato -> "<octetos antes do horodatage> <pave de> <pave ate>"
  if [ "$1" = "novo" ]; then
    echo "30 44 45"
  else
    echo "26 39 40"
  fi
}

F_ANTIGO=$(formato "$ANTIGO")
F_NOVO=$(formato "$NOVO")

echo "=== 0) formato"
echo "--- antigo: com ';' entre os campos? $F_ANTIGO"
echo "--- novo  : com ';' entre os campos? $F_NOVO"

if [ "$F_ANTIGO" != "$F_NOVO" ]; then
  echo
  echo "OS DOIS FICHEIROS NAO ESTAO NO MESMO FORMATO."
  echo "Compara-los octeto a octeto nao quer dizer nada: com ';' todos os"
  echo "campos a seguir ao primeiro estao noutro sitio, e o diff acusava as"
  echo "554045 linhas. Para provar que o conteudo e o mesmo use antes:"
  echo "    python comparar_1222.py <ficheiro com ';'> <ficheiro sem ';'>"
  echo "que reconstroi cada linha no formato antigo antes de comparar."
  exit 2
fi

set -- $(posicoes "$F_ANTIGO")
CAB=$1; PAVE_DE=$2; PAVE_ATE=$3

# ------------------------------------------------------------------ o ruido
# 1. MASYSDATE, os 12 octetos logo a seguir aos $CAB do inicio da linha. O
#    shell fa-lo com
#       masysdate=`date '+%Y%m%d%H%M'`
#    ou seja, ao minuto. Duas execucoes em minutos diferentes dao dois
#    horodatages diferentes em todas as linhas dos dois ficheiros.
#
# 2. A linha ENTETE (comeca por "00;"). Alem do horodatage ao segundo, traz o
#    numero de envio, que o MERGE em PAR_ENVOI_CRRV43 incrementa a cada
#    execucao. Nunca pode ser igual entre duas corridas.
#
# 3. A ORDEM das linhas. Nenhum dos dois spools tem ORDER BY, e a procedure
#    faz DELETE + INSERT a cada execucao: a ordem muda sem que o conteudo
#    mude. Por isso as linhas sao ordenadas antes do diff. O teste e por
#    conteudo, nao por posicao (docs/SIRL-1224.md, "A ordem das linhas").
#    LC_ALL=C: ordenacao por byte, igual nos dois ficheiros.
normaliza()
{
  grep -v '^00;' "$1" \
    | sed -e "s/^\(.\{$CAB\}\).\{12\}/\1############/" \
    | LC_ALL=C sort
}

echo
echo "=== 1) tamanho e numero de linhas"
wc -c "$ANTIGO" "$NOVO"
wc -l "$ANTIGO" "$NOVO"

echo
echo "=== 2) censo dos paves (octetos $PAVE_DE-$PAVE_ATE)"
# sem o cabecalho nem o rodape: nessas duas linhas os octetos $PAVE_DE-$PAVE_ATE
# nao sao o codigo do pave, e apareciam no censo como um pave inventado.
censo()
{
  grep -v -e '^00;' -e '^99;' "$1" | cut -c$PAVE_DE-$PAVE_ATE | sort | uniq -c
}
echo "--- antigo"
censo "$ANTIGO"
echo "--- novo"
censo "$NOVO"

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
