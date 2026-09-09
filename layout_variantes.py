"""Como o layout da linha difere entre os 8 SELECT do pave P1.

Fonte unica: o gen_procedure.py (que enche a tabela) e o gen_spool_vpact.py
(que a le de volta) importam daqui. Se estas regras divergirem entre os dois,
o ficheiro sai errado sem ninguem dar por isso -- por isso ficam num so sitio.

O QUE SE APRENDEU, E COMO
-------------------------
Durante muito tempo assumiu-se que as oito variantes escrevem a MESMA linha,
mudando so quais os registos que entram. E verdade para as variantes 1, 2 e 3
(NAT02) -- provado por dados: 113368 registos byte a byte iguais. NAO e verdade
para as variantes 4 a 8.

So se descobriu quando a base ganhou, pela primeira vez, registos dos tipos de
risco raros (TRE100, TRE409, EQU101, SIG201). Ate ai o perimetro Hors NAT02
estava vazio e nada disto era testavel.

O metodo para medir: comparar, entre duas variantes, o offset das ancoras
"--P1 x.y" que ambas tem no spool. Onde o offset bate, o layout e o mesmo;
onde diverge, ha campos a mais ou a menos antes desse ponto.
"""

# Os 8 SELECT do pave P1 no 030_spool_Extract_CRRCORP.sql, por (linha, linha).
VARIANTES = [
    (1, 'NAT02',      589, 1068),
    (2, 'NAT02',     1088, 1575),
    (3, 'NAT02',     1591, 2069),
    (4, 'HORS_NAT02', 2893, 3449),
    (5, 'HORS_NAT02', 3461, 4010),
    (6, 'HORS_NAT02', 4025, 4593),
    (7, 'HORS_NAT02', 4605, 5049),
    (8, 'HORS_NAT02', 5060, 5628),
]

# ---------------------------------------------------------------------------
# A regua V44 vs a soma das larguras dos tokens
# ---------------------------------------------------------------------------
# A soma das larguras fica 1 byte atras da posicao real a partir do offset
# 4000. O byte em falta e o SEPARADOR: o spool parte a linha em lignedetail1
# (4000 caracteres) e lignedetail2, e o SQL*Plus escreve um branco entre os
# dois. Conta no ficheiro e nao na soma dos tokens.
DESVIO_A_PARTIR_DE = 4000

# ---------------------------------------------------------------------------
# Variante 8 (derivados, CD_TYPE_RISQUE LIKE '%VAR1%')
# ---------------------------------------------------------------------------
# As oito variantes escrevem uma linha da MESMA largura (5698) e, onde ambas
# tem ancora "--P1 x.y", no MESMO byte. Chegou-se a pensar que a 8 estava 9
# bytes a frente a partir do byte 2251: era um token mal medido -- o
#     (CASE WHEN MT_SPREAD >=0 THEN '+' ELSE '-' END)
# vale 1 byte (e so o sinal) e estava a ser contado a 10. Corrigido em
# align_v44.width(). O ficheiro real confirma: o IND_PROD_ECH esta no byte
# 2250 tanto num TRE501 (variante 1) como num VAR104 (variante 8).
#
# O que a variante 8 tem mesmo de proprio e o CONTEUDO entre os bytes 989 e
# 2250: onde a variante 1 poe branco (RPAD(' ',354) e RPAD(' ',466)), a 8 poe
# os campos do derivado -- MTM, nominal, netting, swap/opcao, taxas. Nessa
# faixa a regua V44 nao vale: e reconstruida do comprimento/uso da notice e
# nunca foi confirmada contra um token real, porque a variante 1 nao
# implementa nada ali. So calha coincidir com posicoes que nada tem a ver --
# o NATURE_OPTION chegou a "acertar" em P1 8.2 por sorte de byte.
ZONA_DERIVADOS_V8 = (989, 2251)

# Nessa faixa, os campos identificados a mao pelo nome de negocio na notice.
MAPEAMENTO_VARIANTE_8 = {
    945:  'P1_3_7',     # Sens de la transaction
    1874: 'P1_3_10',    # Montant notionnel de la jambe achetee des derives
    1893: 'P1_3_11',    # Devise du montant du notionnel de la jambe achetee
    1896: 'P1_3_12',    # Montant du notionnel de la jambe vendue des derives
    1915: 'P1_3_13',    # Devise du montant du notionnel de la jambe vendue
    1954: 'P1_20_1',    # Quantite a recevoir
    1973: 'P1_20_2',    # Unite de mesure de la quantite a recevoir
    1976: 'P1_20_3',    # Quantite a livrer
    1995: 'P1_20_4',    # Unite de mesure de la quantite a livrer
}

# ---------------------------------------------------------------------------
# Campos compostos: um token que escreve DOIS campos da notice
# ---------------------------------------------------------------------------
# So as variantes 1 e 2 tem o token de 22 que junta o montante do decouvert
# (P1 4.4, 19) e a sua devise (P1 4.5, 3) dentro do mesmo CASE.
#
# A variante 5 tem um CASE que TAMBEM comeca por CD_TYPE_RISQUE = 'TRE201',
# mas e outra coisa: 19 de largura, so o montante (MNT_SOLDE), com a devise
# num token separado a seguir. Sem esta lista, o match por substring apanhava
# a variante 5 e guardava 0 em P1_4_4 em vez do MNT_SOLDE.
# Cada composto existe so em algumas variantes, e nao nas mesmas:
#   TRE201 (montante do decouvert + devise) : variantes 1 e 2
#   TRE401 (montante dos loyers   + devise) : variantes 1 e 3
VARIANTES_DO_COMPOSTO = {
    'TRE201': (1, 2),
    'TRE401': (1, 3),
}
