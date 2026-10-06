# -*- coding: utf-8 -*-
"""Gera o lado DDR da historizacao da ENG_CORP_P1_BIS -- SIRL-1472.

    python gen_hcrr.py

Uma fonte de verdade, tres ficheiros:

    ENG_CORP_P1_BIS.sql  ->  PACK_HIST_ENG_CORP_P1_BIS.sql   extrai para ficheiro
                             HIST_ENG_CORP_P1_BIS.sql        a tabela do HCRR
                             HIST_ENG_CORP_P1_BIS.ctl        o SQL*Loader

PORQUE E QUE OS TRES SAEM DO MESMO GERADOR
------------------------------------------
Sao 668 campos, e a ordem tem de ser a MESMA nos tres. Um deslocamento de um
campo entre a extraccao e o loader nao da erro nenhum: carrega tudo trocado uma
coluna para o lado, e a data vai para o campo do montante. Gerados juntos, a
ordem nao pode divergir -- e o valida_hcrr.py confere.

PORQUE NAO E UM SPOOL
---------------------
A linha tem 9170 octetos no maximo. Uma expressao SQL nao pode passar de 4000, e
e por isso que o 030_spool_Extract_CRRCORP.sql parte a linha em duas colunas e
enche tudo com RPAD -- so assim o SQL*Plus nao mete espacos pelo meio. Isso dava
um ficheiro de largura fixa: 9170 x 122 225 = 1,1 GB por arrete.

Com UTL_FILE em PL/SQL o limite e 32767 e nao ha enchimento: os campos vao com o
tamanho que tem, separados por ';'. E o padrao que o P_UTLF_CREDIT_P3 ja usa
neste mesmo projecto.

PORQUE E UM PACKAGE NOVO
------------------------
O criterio de aceitacao do chamado diz "aucun impact sur l'historisation des
donnees existantes". Num package novo nao se toca em nada que ja corre, por isso
o impacto e zero por construcao -- e nao por verificacao.

O QUE E PROPOSTA, E NAO MEDIDA
------------------------------
O formato do cabecalho e do rodape, e o nome do ficheiro. Nao temos o
030_spool_data.sql nem o processo de carga do HCRR, por isso nao da para copiar
o que la esta. Estao os tres no CABECALHO/RODAPE/FICHEIRO aqui abaixo, num sitio
so, para serem uma alteracao pequena quando soubermos.
"""
import io
import re
import sys

import enc

FONTE = 'ENG_CORP_P1_BIS.sql'
PACK = 'PACK_HIST_ENG_CORP_P1_BIS.sql'
DDL = 'HIST_ENG_CORP_P1_BIS.sql'
CTL = 'HIST_ENG_CORP_P1_BIS.ctl'
NL = '\r\n'
VERSAO = '2026-10-06a'

TABELA = 'ENG_CORP_P1_BIS'
HIST = 'HIST_ENG_CORP_P1_BIS'
FICHEIRO = 'HCRR_P1BIS'          # + a data do arrete, posta pelo shell
SEP = ';'
POR_BLOCO = 60                   # campos por instrucao, para nao fazer uma gigante


def colunas(texto):
    """[(nome, tipo, largura no ficheiro)] pela ordem do CREATE TABLE."""
    ls = texto.split(NL) if NL in texto else texto.split('\n')
    i = next(n for n, l in enumerate(ls) if 'CREATE TABLE' in l.upper())
    j = next(n for n in range(i, len(ls)) if ls[n].strip().startswith(')'))
    out = []
    for n in range(i + 1, j):
        s = ls[n].strip()
        m = re.match(r'([A-Z][A-Z0-9_]*)\s+'
                     r'(VARCHAR2\(\d+\)|NUMBER\([\d,]+\)|NUMBER|DATE)', s)
        if m:
            out.append((m.group(1), m.group(2), larg(m.group(2))))
    if not out:
        raise SystemExit('nao achei coluna nenhuma em %s' % FONTE)
    return out


def larg(t):
    """Quantos octetos o campo ocupa no ficheiro, no maximo."""
    if t.startswith('VARCHAR2'):
        return int(re.search(r'\((\d+)\)', t).group(1))
    if t == 'DATE':
        return 14                                   # YYYYMMDDHH24MISS
    m = re.search(r'\(([\d,]+)\)', t)
    if not m:
        return 40
    p = m.group(1).split(',')
    ints, dec = int(p[0]), (int(p[1]) if len(p) > 1 else 0)
    return 1 + ints + (1 + dec if dec else 0)       # sinal + inteiros + . + dec


def expr(nome, tipo):
    """A expressao que poe o campo na linha, sem perder nada.

    texto    TRANSLATE(x, ';', '.') -- um ';' nos dados partia o ficheiro, e e a
             mesma resposta que a DSID deu no SIRL-1222 (27/09)
    data     YYYYMMDDHH24MISS -- a DATE do Oracle tem precisao ao segundo
    numero   TM9 com o NLS forcado: o ponto decimal nao pode depender da sessao
    """
    if tipo.startswith('VARCHAR2'):
        return "TRANSLATE(C.%s, ';', '.')" % nome
    if tipo == 'DATE':
        return "TO_CHAR(C.%s, 'YYYYMMDDHH24MISS')" % nome
    return "TO_CHAR(C.%s, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')" % nome


def cab(nome, n, extra=()):
    """O cabecalho de versao que todo o ficheiro do projecto leva."""
    L = ['-- ' + '=' * 70,
         '-- %s' % nome,
         '-- VERSAO %s -- SIRL-1472, historizacao da %s no HCRR.' % (VERSAO, TABELA),
         '--   GERADO por gen_hcrr.py a partir de %s -- nao editar a mao.' % FONTE,
         '--   %d colunas, na ordem do CREATE TABLE da tabela de origem.' % n]
    L += ['--   %s' % e for e in extra]
    L += ['--   Conferir no servidor com:  grep VERSAO %s' % nome,
          '-- ' + '=' * 70, '']
    return L


def escreve_package(cols):
    tot = sum(w for _, _, w in cols) + len(cols) - 1
    L = cab(PACK, len(cols), (
        'Escreve um ficheiro com UTL_FILE: uma linha por registo, os campos',
        'separados por "%s". No maximo %d octetos por linha.' % (SEP, tot),
    ))
    P = 'P_HIST_%s' % TABELA
    L += [
        'CREATE OR REPLACE PACKAGE PACK_HIST_%s' % TABELA,
        'AS',
        '',
        '    -- Escreve a %s inteira num ficheiro, para o HCRR carregar.' % TABELA,
        '    --   p_chemin        o directory do Oracle (UTL_FILE)',
        '    --   p_nom_fichier   o nome do ficheiro, ja com a data do arrete',
        '    PROCEDURE %s (p_chemin      IN VARCHAR2,' % P,
        '%sp_nom_fichier IN VARCHAR2);' % (' ' * (16 + len(P))),
        '',
        'END PACK_HIST_%s;' % TABELA,
        '/',
        '',
        'CREATE OR REPLACE PACKAGE BODY PACK_HIST_%s' % TABELA,
        'AS',
        '',
        'PROCEDURE %s (p_chemin      IN VARCHAR2,' % P,
        '%sp_nom_fichier IN VARCHAR2)' % (' ' * (12 + len(P))),
        'IS',
        '    v_fic     UTL_FILE.FILE_TYPE;',
        '    v_ligne   VARCHAR2(32767);',
        '    v_nb      NUMBER := 0;',
        '    v_arrete  DATE;',
        'BEGIN',
        '    SELECT MAX(DT_ARRETE) INTO v_arrete FROM %s;' % TABELA,
        '',
        "    -- 'w' e nao 'a': o ficheiro e reescrito de cada vez. Com 'a' uma",
        '    -- segunda corrida no mesmo mes duplicava as linhas, sem dar erro.',
        "    v_fic := UTL_FILE.FOPEN(p_chemin, p_nom_fichier, 'w', 32767);",
        '',
        '    -- Cabecalho. O formato e PROPOSTA: nao temos o do HCRR.',
        "    UTL_FILE.PUT_LINE(v_fic, '00' || '%s' || '%s' || '%s'"
        % (SEP, TABELA, SEP),
        "        || TO_CHAR(v_arrete, 'YYYYMMDD') || '%s'" % SEP,
        "        || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || '%s'" % SEP,
        "        || TO_CHAR(%d));" % len(cols),
        '',
        '    FOR C IN (SELECT * FROM %s' % TABELA,
        '               ORDER BY DT_ARRETE, ID_ENGAGEMENT, CD_PERIMETRE,'
        ' NO_VARIANTE)',
        '    LOOP',
    ]
    # A linha vai por blocos de POR_BLOCO campos, cada bloco numa instrucao.
    # Numa so instrucao com 668 operandos o compilador do Oracle rebenta com
    # PLS-00123 (program too large) ou fica minutos a analisar.
    #
    # O SEPARADOR vai DEPOIS de cada campo menos o ultimo de todos. Por isso
    # cada linha acaba de uma de tres maneiras:
    #    meio do bloco      expr || ';' ||      continua na linha seguinte
    #    fim do bloco       expr || ';';        fecha a instrucao
    #    ultimo de todos    expr;               sem separador a seguir
    for k in range(0, len(cols), POR_BLOCO):
        bloco = cols[k:k + POR_BLOCO]
        L.append('        v_ligne := %s' % ('' if k == 0 else 'v_ligne ||'))
        for n, (nome, tipo, _w) in enumerate(bloco):
            i = k + n
            if i == len(cols) - 1:
                fim = ';'
            elif n == len(bloco) - 1:
                fim = "|| '%s';" % SEP
            else:
                fim = "|| '%s' ||" % SEP
            L.append('            %-62s %s' % (expr(nome, tipo), fim))
        L.append('')
    L += [
        '        UTL_FILE.PUT_LINE(v_fic, v_ligne);',
        '        v_nb := v_nb + 1;',
        '    END LOOP;',
        '',
        '    -- Rodape: o numero de linhas de detalhe, em 12 digitos.',
        "    UTL_FILE.PUT_LINE(v_fic, '99' || '%s'" % SEP,
        "        || TO_CHAR(v_nb, 'FM000000000000'));",
        '',
        '    UTL_FILE.FCLOSE(v_fic);',
        "    DBMS_OUTPUT.PUT_LINE('%s : ' || v_nb || ' lignes, arrete '" % P,
        "        || TO_CHAR(v_arrete, 'DD/MM/YYYY'));",
        '',
        'EXCEPTION',
        '    WHEN OTHERS THEN',
        '        -- fecha o ficheiro antes de propagar, senao o descritor'
        ' fica preso',
        '        IF UTL_FILE.IS_OPEN(v_fic) THEN',
        '            UTL_FILE.FCLOSE(v_fic);',
        '        END IF;',
        '        RAISE;',
        'END %s;' % P,
        '',
        'END PACK_HIST_%s;' % TABELA,
        '/',
        '',
    ]
    io.open(PACK, 'w', encoding='cp1252', newline='').write(NL.join(L))
    return len(L)


def escreve_ddl(cols):
    L = cab(DDL, len(cols), (
        'A tabela do lado do HCRR. Mesma estrutura da origem: a DT_ARRETE ja la',
        'esta, por isso o historico nao leva coluna nenhuma a mais.',
    ))
    L += ['CREATE TABLE %s' % HIST, '(']
    n = max(len(c) for c, _t, _w in cols)
    for i, (nome, tipo, _w) in enumerate(cols):
        L.append('    %-*s %-14s%s'
                 % (n, nome, tipo, '' if i == len(cols) - 1 else ','))
    L += [');', '']
    L += ['-- O historico consulta-se por arrete. Sem isto, contar as linhas de',
          '-- um mes le a tabela toda.',
          'CREATE INDEX IX_HIST_P1BIS_ARRETE ON %s (DT_ARRETE);' % HIST,
          '']
    io.open(DDL, 'w', encoding='cp1252', newline='').write(NL.join(L))
    return len(L)


def escreve_ctl(cols):
    L = ['-- ' + '=' * 70,
         '-- %s' % CTL,
         '-- VERSAO %s -- SIRL-1472. GERADO por gen_hcrr.py.' % VERSAO,
         '--   Os %d campos na MESMA ordem da extraccao. Um campo a mais ou a'
         % len(cols),
         '--   menos aqui carrega tudo deslocado, e sem dar erro.',
         '-- ' + '=' * 70,
         'LOAD DATA',
         'CHARACTERSET WE8MSWIN1252',
         "INFILE '%s.dat'" % FICHEIRO,
         "BADFILE '%s.bad'" % FICHEIRO,
         "DISCARDFILE '%s.dsc'" % FICHEIRO,
         'APPEND',
         'INTO TABLE %s' % HIST,
         "WHEN (01:02) != '00' AND (01:02) != '99'",
         "FIELDS TERMINATED BY '%s'" % SEP,
         'TRAILING NULLCOLS',
         '(']
    n = max(len(c) for c, _t, _w in cols)
    for i, (nome, tipo, w) in enumerate(cols):
        if tipo.startswith('VARCHAR2'):
            d = 'CHAR(%d)' % w
        elif tipo == 'DATE':
            d = 'DATE "YYYYMMDDHH24MISS"'
        else:
            d = 'DECIMAL EXTERNAL'
        L.append('    %-*s %-26s%s'
                 % (n, nome, d, '' if i == len(cols) - 1 else ','))
    L += [')', '']
    io.open(CTL, 'w', encoding='cp1252', newline='').write(NL.join(L))
    return len(L)


def main():
    texto, cod = enc.le(FONTE)
    cols = colunas(texto)
    tot = sum(w for _, _, w in cols) + len(cols) - 1
    if tot > 32767:
        raise SystemExit('a linha daria %d octetos: passa o VARCHAR2 do PL/SQL'
                         % tot)
    print('%s (%s): %d colunas' % (FONTE, cod, len(cols)))
    print('  linha no maximo %d octetos (%d de dados + %d separadores)'
          % (tot, tot - len(cols) + 1, len(cols) - 1))
    print('  %-34s %5d linhas' % (PACK, escreve_package(cols)))
    print('  %-34s %5d linhas' % (DDL, escreve_ddl(cols)))
    print('  %-34s %5d linhas' % (CTL, escreve_ctl(cols)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
