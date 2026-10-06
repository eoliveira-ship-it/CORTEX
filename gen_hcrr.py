# -*- coding: utf-8 -*-
"""Gera a historizacao da ENG_CORP_P1_BIS -- SIRL-1472.

    python gen_hcrr.py

    030_spool_data.sql   ->  030_spool_data_1472.sql       o bloco de extraccao
    pack_histo_crr.sql   ->  pack_histo_crr_1472.sql       a procedure de histo
    ENG_CORP_P1_BIS.sql  ->  030_create_table_ENG_CORP_P1_BIS_HCRR.sql
                             745_create_table_HIS_ENG_CORP_P1_BIS.sql

Os sufixos _1472 sao nomes de repositorio: no servidor os dois instalam-se com o
nome de producao. E o montar_entrega.py que lhes tira o sufixo.

A PRIMEIRA VERSAO DISTO ESTAVA ERRADA, E PORQUE
-----------------------------------------------
Antes de termos o 030_spool_data.sql e o pack_histo_crr.sql, isto gerava um
package com UTL_FILE, um ficheiro separado por ';' e um controle de SQL*Loader.
Nada disso e a convencao da cadeia:

    separador     '~', nunca ';'   (2037 vezes no 030_spool_data.sql)
    datas         YYYYMMDD         (nunca com hora: 0 HH24 no ficheiro todo)
    comprimento   variavel, com SET linesize no maximo da linha
    ficheiro      $SORTIE/030_FLUX_2M_<TABELA>.txt
    sem cabecalho nem rodape
    numeros       sem TO_CHAR, concatenados directamente
    o HCRR NAO LE O FICHEIRO: le a tabela ja carregada, e faz INSERT ... SELECT
                  para CRR_2A.HIS_<tabela> e CRR_10A.HIS_<tabela>

SO AS COLUNAS ALIMENTADAS, E PORQUE
-----------------------------------
A tabela tem 668 colunas e a linha daria 8912 octetos. Uma expressao SQL nao
passa de 4000 -- e por isso que o maior ficheiro da cadeia tem linesize 3215
(BTR_OPERATION) e nenhum passa dos 4000.

Das 668, a procedure alimenta ~300; as outras ficam NULL e o spool do CRR nao le
nenhuma (medido: 0). Extraindo so as alimentadas a linha da 3222 -- cabe, e fica
ao lado do maior ficheiro que ja existe.

O dia em que um dos campos da V45 ganhar origem, ha que o acrescentar aqui. Na
cadeia faz-se assim mesmo: o historico de alteracoes do 030_spool_data.sql e uma
lista de "ajout colonne X". A convencao para acrescentar e por o separador a
FRENTE do campo novo -- ||'~'||COLUNA -- para nao mexer na linha anterior.
"""
import io
import re
import sys

import enc

BIS = 'ENG_CORP_P1_BIS.sql'
PROC = 'pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql'
SPOOL = '030_spool_data.sql'
PACK = 'pack_histo_crr.sql'

SPOOL_OUT = '030_spool_data_1472.sql'
PACK_OUT = 'pack_histo_crr_1472.sql'
DDL_CRR = '030_create_table_ENG_CORP_P1_BIS_HCRR.sql'
DDL_HIS = '745_create_table_HIS_ENG_CORP_P1_BIS.sql'

NL = '\r\n'
VERSAO = '2026-10-06c'
DATA = '06/10/2026'
TAB = 'ENG_CORP_P1_BIS'
HIS = 'HIS_ENG_CORP_P1_BIS'
PROCEDURE = 'p_histo_eng_corp_p1_bis'
FLUXO = '030_FLUX_2M_ENG_CORP_P1_BIS.txt'
SEP = "'~'"


# ---------------------------------------------------------------- as colunas

def colunas():
    """[(nome, tipo, largura)] das colunas ALIMENTADAS, pela ordem do DDL."""
    t, _ = enc.le(BIS)
    ls = t.split(NL) if NL in t else t.split('\n')
    i = next(n for n, l in enumerate(ls) if 'CREATE TABLE' in l.upper())
    j = next(n for n in range(i, len(ls)) if ls[n].strip().startswith(')'))
    todas = []
    for n in range(i + 1, j):
        m = re.match(r'([A-Z][A-Z0-9_]*)\s+'
                     r'(VARCHAR2\(\d+\)|NUMBER\([\d,]+\)|NUMBER|DATE)',
                     ls[n].strip())
        if m:
            todas.append((m.group(1), m.group(2)))

    p, _ = enc.le(PROC)
    alim = set(re.findall(r'AS\s+([A-Z][A-Z0-9_]*)', p))
    # A DT_TRAITEMENT nao aparece no SELECT da procedure: e DEFAULT SYSDATE, o
    # Oracle poe-na. Mas e a unica pista de QUANDO o DDR gerou a linha, e no
    # historico isso perde-se para sempre -- custa 8 octetos e junta-se a mao.
    #
    # VAI AO DIA, NAO AO SEGUNDO, e e de proposito. A coluna e um horodatage,
    # mas a cadeia escreve as datas em YYYYMMDD -- zero HH24 nos 4476 linhas do
    # 030_spool_data.sql. Meter HH24MISS so neste campo quebrava a convencao e,
    # muito provavelmente, o formato de data do loader do HCRR. Fica o dia da
    # corrida, que e o que responde "de que execucao veio esta linha"; a hora
    # perde-se.
    alim.add('DT_TRAITEMENT')
    fora = [c for c, _t in todas if c not in alim]
    cols = [(c, t, larg(t)) for c, t in todas if c in alim]
    if not cols:
        raise SystemExit('nao achei coluna alimentada nenhuma em %s' % PROC)
    return cols, len(todas), fora


def larg(t):
    """Octetos que o campo ocupa no ficheiro, no maximo."""
    if t.startswith('VARCHAR2'):
        return int(re.search(r'\((\d+)\)', t).group(1))
    if t == 'DATE':
        return 8                                    # YYYYMMDD, como a cadeia
    m = re.search(r'\(([\d,]+)\)', t)
    if not m:
        return 40
    p = m.group(1).split(',')
    ints, dec = int(p[0]), (int(p[1]) if len(p) > 1 else 0)
    return 1 + ints + (1 + dec if dec else 0)       # sinal + inteiros + . + dec


def campo(nome, tipo):
    """Como o campo vai para o ficheiro. Datas em YYYYMMDD, o resto directo."""
    if tipo == 'DATE':
        return "to_char(%s, 'YYYYMMDD')" % nome
    return nome


# ------------------------------------------------------------------ o spool

def bloco_spool(cols, linha):
    L = ['', '-' * 80,
         '-- SIRL-1472 : historisation de la %s dans HCRR' % TAB,
         '--   La table est remplie par pack_alim_tab_envoi_crrv4.P_ALIM_%s,' % TAB,
         '--   qui commence par un DELETE : elle ne contient que l arrete courant.',
         '--   %d colonnes des %s de la table -- les autres sont toujours NULL et'
         % (len(cols), 'xxx'),
         '--   ne sont lues par aucun spool.',
         '--   GENERE par gen_hcrr.py -- VERSAO %s' % VERSAO,
         '-' * 80,
         'SET linesize %d' % linha,
         'spool $SORTIE/%s' % FLUXO,
         '  select']
    for i, (nome, tipo, _w) in enumerate(cols):
        if i == 0:
            L.append('    %s' % campo(nome, tipo))
        else:
            L.append("    ||%s||%s" % (SEP, campo(nome, tipo)))
    L.append('  from %s;' % TAB)
    L.append('')
    return L


HISTORICO = 'SIRL-1472 - historisation ENG_CORP_P1_BIS'
REGUA = '-' * 80


def marca(t):
    """Acrescenta a linha de historico no cabecalho, como a cadeia faz.

    A ancora e a regua logo a seguir a "-- Modifications :". As entradas estao
    por data decrescente, por isso a nossa vai em primeiro. Um ficheiro de
    producao alterado sem entrada no cabecalho e uma alteracao que ninguem
    consegue datar depois.
    """
    alvo = '-- Modifications :'
    i = t.find(alvo)
    if i < 0:
        raise SystemExit('nao achei "%s" no cabecalho' % alvo)
    j = t.find(REGUA, i)
    if j < 0:
        raise SystemExit('nao achei a regua a seguir as Modifications')
    j = t.find(NL, j) + len(NL)
    l = '-- %s KLx_Risq : %s' % (DATA, HISTORICO)
    l = l + ' ' * max(1, 78 - len(l)) + '--'
    return t[:j] + l + NL + t[j:]


def escreve_spool(cols, linha, n_todas):
    t, cod = enc.le(SPOOL)
    if FLUXO in t:
        raise SystemExit('%s ja extrai a %s' % (SPOOL, TAB))
    # a ancora: o ultimo "spool off;" do ficheiro
    alvo = 'spool off;'
    i = t.rfind(alvo)
    if i < 0:
        raise SystemExit('nao achei "%s" em %s' % (alvo, SPOOL))
    b = [l.replace('%d colonnes des xxx' % len(cols),
                   '%d colonnes des %d' % (len(cols), n_todas))
         for l in bloco_spool(cols, linha)]
    novo = marca(t[:i] + NL.join(b) + NL + t[i:])
    # NA CODIFICACAO DA ORIGEM, nao na nossa.
    # O 030_spool_data.sql e o pack_histo_crr.sql vem de producao. Escrever em
    # cp1252 convertia os 130 acentuados do package e punha 130 octetos de
    # diferenca num ficheiro de 1 MB que nao e nosso -- um diff que ninguem
    # consegue rever. Os .sql que NASCEM aqui (os dois DDL) ficam cp1252, como
    # todo o resto do projecto.
    io.open(SPOOL_OUT, 'w', encoding=cod, newline='').write(novo)
    return cod, len(b)


# -------------------------------------------------------------- as tabelas

def cabecalho(nome, objet, dominio, apl):
    r = '-' * 80
    return [r,
            '-- CAL-Version : 1.0' + ' ' * 58 + '--',
            r, r,
            '-- Script        : %-60s--' % nome,
            '-- Objet         : %-60s--' % objet,
            '-- Type          : Script de creation de table Oracle' + ' ' * 10 + '--',
            r,
            '-- Domaine       : %-60s--' % dominio,
            '-- Application   : %-60s--' % apl,
            r,
            '-- Creation      : SIRL-1472' + ' ' * 46 + '--',
            '-- Modifications' + ' ' * 48 + '--',
            '-- -------------' + ' ' * 48 + '--',
            '-- GENERE por gen_hcrr.py a partir de %-24s--' % BIS,
            '--   VERSAO %-66s--' % VERSAO,
            r]


def corpo_tabela(cols, nome, tablespace):
    """O CREATE TABLE. O tablespace vai COMENTADO, e porque:

    O unico modelo de criacao de tabela que temos -- o
    030_create_table_BTR_OPE_PARTENAIRE_POOL.sql -- e do DDR: diz
    TABLESPACE DDR_DATA e da GRANT a ROLE_DDR_CS, ROLE_DDR_BAT, ROLE_DDR_DEBUG.
    Estas tres tabelas sao do lado HCRR, onde nao sabemos como se chamam nem o
    tablespace nem os roles. Inventar um nome faz o script falhar na instalacao
    com ORA-00959; deixar comentado faz a tabela nascer no tablespace por
    omissao do esquema, que e o comportamento certo enquanto nao soubermos.
    """
    n = max(len(c) for c, _t, _w in cols)
    L = ['CREATE TABLE %s' % nome, '(']
    for i, (c, t, _w) in enumerate(cols):
        L.append('    %-*s %-14s%s'
                 % (n, c, t, '' if i == len(cols) - 1 else ','))
    L += [')',
          'LOGGING',
          'NOCACHE',
          'NOPARALLEL;',
          '',
          '-- A CONFIRMAR COM A DSID: o tablespace do esquema no HCRR.',
          '--   Descomentar e por o nome certo, ANTES do ponto e virgula acima.',
          '--   TABLESPACE %s' % tablespace,
          '']
    return L


def grants(nome):
    """Os GRANT, comentados pela mesma razao que o tablespace.

    Os roles que o modelo mostra sao do DDR. Um GRANT a um role que nao existe
    da ORA-01919 e para o script a meio -- com a tabela ja criada. Vai
    comentado, com os nomes do DDR como ponto de partida.
    """
    return ['-- A CONFIRMAR COM A DSID: os roles do HCRR.',
            '--   Os nomes abaixo sao os do DDR, do modelo que temos. Um GRANT a',
            '--   um role inexistente da ORA-01919 e para o script COM A TABELA',
            '--   JA CRIADA -- por isso nao se deixa activo as cegas.',
            '-- CREATE OR REPLACE PUBLIC SYNONYM %s FOR %s;' % (nome, nome),
            '-- GRANT SELECT ON %s TO public;' % nome,
            '-- GRANT SELECT ON %s TO ROLE_DDR_CS;' % nome,
            '-- GRANT SELECT, INSERT, UPDATE, DELETE ON %s TO ROLE_DDR_BAT;' % nome,
            '-- GRANT DEBUG ON %s TO ROLE_DDR_DEBUG;' % nome,
            'COMMIT;', '']


def escreve_ddl_crr(cols):
    L = cabecalho(DDL_CRR, 'SIRL-1472 - table de reception du flux DDR',
                  'HCRR', '745 - Historisation mensuelle du CRR')
    L += ['-- A table de RECEPCAO, no esquema CRR do HCRR: e nela que o',
          '-- SQL*Loader carrega o %s, e e dela que a' % FLUXO,
          '-- %s le. Mesmos nomes e tipos da origem no DDR.' % PROCEDURE,
          '']
    L += corpo_tabela(cols, TAB, 'CRR_DATA') + grants(TAB)
    io.open(DDL_CRR, 'w', encoding='cp1252', newline='').write(NL.join(L))
    return len(L)


def escreve_ddl_his(cols):
    L = cabecalho(DDL_HIS, 'SIRL-1472 - tables d historique 2 ans et 10 ans',
                  'HCRR', '745 - Historisation mensuelle du CRR')
    L += ['-- Duas tabelas, como todas as outras da cadeia: a de 2 anos, onde a',
          '-- %s insere, e a de 10 anos, que ela purga.' % PROCEDURE,
          '-- A DT_ARRETE ja vem da origem, por isso nao ha coluna a mais.',
          '']
    for esq, ts in (('CRR_2A', 'CRR_2A_DATA'), ('CRR_10A', 'CRR_10A_DATA')):
        L += corpo_tabela(cols, '%s.%s' % (esq, HIS), ts)
        L += ['-- O historico consulta-se por arrete.',
              'CREATE INDEX %s.IX_%s_ARR ON %s.%s (DT_ARRETE);'
              % (esq, HIS[:22], esq, HIS), '']
    L.append('COMMIT;')
    L.append('')
    io.open(DDL_HIS, 'w', encoding='cp1252', newline='').write(NL.join(L))
    return len(L)


# ------------------------------------------------------------- a procedure

def bloco_procedure(cols):
    r = '-' * 54
    L = ['', r,
         '-- nom : procedure %-34s--' % PROCEDURE,
         '-- but : historisation de la table %-19s--' % TAB.lower(),
         '-- auteur : SIRL-1472' + ' ' * 33 + '--',
         '-- entree : /' + ' ' * 40 + '--',
         '-- retour : /' + ' ' * 40 + '--',
         '--   GENERE par gen_hcrr.py -- ne pas editer a la main   --',
         r,
         'PROCEDURE %s IS' % PROCEDURE,
         '    l_position varchar2(20);',
         '',
         'BEGIN',
         '    -- rejeu : une deuxieme passe dans le mois ne doit pas doubler',
         "    l_position := 'SI REJEU';",
         '    DELETE CRR_2A.%s WHERE DT_ARRETE = g_dt_arrete;' % HIS,
         '    COMMIT;',
         '    DELETE CRR_10A.%s WHERE DT_ARRETE = g_dt_arrete;' % HIS,
         '    COMMIT;',
         '',
         '    -- purge de la table d historique',
         "    l_position := 'PURGE';",
         '    DELETE FROM CRR_10A.%s' % HIS,
         '     WHERE DT_ARRETE < add_months(g_dt_arrete, -g_nb_mois_purge_7ans);',
         '    COMMIT;',
         '',
         "    l_position := 'INSERT MOIS M';"]
    n = max(len(c) for c, _t, _w in cols)
    for esq in ('CRR_2A', 'CRR_10A'):
        L.append('')
        L.append('    INSERT INTO %s.%s' % (esq, HIS))
        L.append('    (')
        for i, (c, _t, _w) in enumerate(cols):
            L.append('        %-*s%s' % (n, c, '' if i == len(cols) - 1 else ','))
        L.append('    )')
        L.append('    SELECT')
        for i, (c, _t, _w) in enumerate(cols):
            L.append('        %-*s%s' % (n, c, '' if i == len(cols) - 1 else ','))
        L.append('    FROM CRR.%s;' % TAB)
        L.append('    COMMIT;')
    L += ['',
          'EXCEPTION',
          '    WHEN OTHERS THEN',
          '        ROLLBACK;',
          '        pack_utilitaire_7ans.DB_TRAITE_ERREUR(SQLERRM,',
          "            'proc %s:'||l_position, 50074);" % PROCEDURE,
          'END %s;' % PROCEDURE,
          '']
    return L


FIM = 'END pack_histo_crr;'


def escreve_pack(cols):
    t, cod = enc.le(PACK)
    if PROCEDURE in t:
        raise SystemExit('%s ja tem a %s' % (PACK, PROCEDURE))
    a = t.find(FIM)
    b = t.find(FIM, a + 1)
    if a < 0 or b < 0 or t.find(FIM, b + 1) >= 0:
        raise SystemExit('esperava o "%s" exactamente 2 vezes em %s' % (FIM, PACK))
    # na spec, a declaracao; no corpo, a procedure. De tras para a frente, para
    # o primeiro indice nao se mexer.
    corpo = NL.join(bloco_procedure(cols)) + NL
    decl = ('    PROCEDURE %s; -- SIRL-1472' % PROCEDURE) + NL
    ib = t.rfind(NL, 0, b) + len(NL)
    t = t[:ib] + corpo + t[ib:]
    ia = t.rfind(NL, 0, a) + len(NL)
    t = t[:ia] + decl + t[ia:]
    io.open(PACK_OUT, 'w', encoding=cod, newline='').write(marca(t))
    return cod, t.count(PROCEDURE)


# ------------------------------------------------------------------- main

def main():
    cols, n_todas, fora = colunas()
    linha = sum(w for _, _, w in cols) + len(cols) - 1
    print('%s: %d colunas, %d alimentadas, %d sempre NULL'
          % (BIS, n_todas, len(cols), len(fora)))
    print('  linha do fluxo: %d octetos  (o maior da cadeia tem 3215)' % linha)
    if linha > 4000:
        raise SystemExit('a linha daria %d: passa o limite de 4000 do SQL' % linha)
    cod, n = escreve_spool(cols, linha, n_todas)
    print('  %-44s +%d linhas (de %s, %s)' % (SPOOL_OUT, n, SPOOL, cod))
    cod, n = escreve_pack(cols)
    print('  %-44s %s x%d  (de %s, %s)' % (PACK_OUT, PROCEDURE, n, PACK, cod))
    print('  %-44s %d linhas' % (DDL_CRR, escreve_ddl_crr(cols)))
    print('  %-44s %d linhas' % (DDL_HIS, escreve_ddl_his(cols)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
