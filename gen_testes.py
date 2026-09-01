"""Gera TESTES.sql : o ficheiro unico de testes da SIRL-1224.

Quatro testes, por ordem de dependencia. Cada um responde a uma pergunta
diferente e nenhum e redundante:

  T1 ESTRUTURA   a tabela na base e a que o DDL manda?
  T2 PACKAGE     o codigo compilado e o do repositorio? (ja nos mordeu:
                 um package obsoleto deu 520547 em vez de 2,95)
  T3 VOLUMETRIA  o numero de linhas inseridas e o que os 8 WHERE do spool
                 devolvem? (ecart tem de ser 0)
  T4 ROUND-TRIP  o valor guardado, reformatado, reproduz o que o spool
                 escreve hoje? (o teste central: nao-regressao campo a campo)

Os diagnosticos pontuais (precisao, tipos, divergencias) serviram para
resolver problemas ja fechados e nao entram aqui.
"""
import io
import json
import re
import sys

from conv_spool import convert

NL = chr(10)
Q = chr(39)
N_LINHAS = 200
PKG = 'PACK_ALIM_TAB_ENVOI_CRRV4_NEW'

# ---------------------------------------------------------------- regua V44
src = open('align_v44.py', encoding='utf-8').read()
src = src.split('# ------------------------------------------------------- alinhamento')[0]
ns = {}
buf = io.StringIO()
_o = sys.stdout
sys.stdout = buf
exec(src, ns)
sys.stdout = _o
tokenize, width, v44 = ns['tokenize'], ns['width'], ns['v44']

DDL = open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
COLS = set(re.findall(r'^\s+(P1_[A-Z0-9_]+)\s', DDL, re.M))
N_COLS = len(re.findall(r'^\s+([A-Z][A-Z0-9_]*)\s+(?:NUMBER|DATE|VARCHAR2)', DDL, re.M))
ALVO = {'P1_21_30', 'P1_21_43', 'P1_21_60', 'P1_3_20', 'P1_18_1', 'P1_18_10',
        'P1_21_81', 'P1_21_82', 'P1_22_19', 'P1_22_23', 'P1_22_24', 'P1_22_27',
        'P1_22_28', 'P1_22_29', 'P1_4_30'}
ALARGADAS = sorted(
    (m.group(1), m.group(2))
    for m in re.finditer(r'^\s+(P1_[A-Z0-9_]+)\s+(NUMBER\(\d+,\s*\d+\))', DDL, re.M)
    if m.group(1) in ALVO)

proc = open('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
bloco1 = proc.split('-- INSERT #1')[1].split('-- INSERT #2')[0]
ALIMENTADAS = set(re.findall(r'AS (P1_[A-Z0-9_]+)', bloco1))


def col_de(ref):
    if '(P1)' in ref:
        return 'P1_H_' + ref.replace('(P1)', '').strip().replace('.', '_')
    return 'P1_' + ref.split()[1].replace('.', '_')


# --------------------------------------------------- T4 : pares round-trip
# A lista vem do gen_spool_vpact.py: sao exatamente os campos que o spool
# vPACT emite, com a expressao ORIGINAL do spool ao lado da expressao nova.
# O teste compara as duas na mesma linha -- se sao iguais, o ficheiro sai
# igual. Nao se duplica aqui a logica de reconstrucao: usa-se a do gerador.
PARES = json.load(open('pares_vpact.json', encoding='utf-8'))

pares = []
EXCLUIDAS = []
for p in PARES:
    if ':MASYSDATE' in p['orig'].upper():
        continue                       # depende do momento da execucao
    if p['col'] in ('composta', 'explicita'):
        # o valor vem de varias colunas: a expressao vPACT nao referencia uma
        # so coluna, mas compara-se na mesma -- e o que interessa e o resultado
        pares.append((('pos %d' % p['off']), p['orig'],
                      re.sub(r'\b(P1_[A-Z0-9_]+)\b', r'B.\1', p['vpact'])))
        continue
    pares.append((p['col'], p['orig'],
                  re.sub(r'\b(P1_[A-Z0-9_]+)\b', r'B.\1', p['vpact'])))

casos = NL.join(
    "         CASE WHEN NVL(%s,%s@%s) <> NVL(%s,%s@%s)" % (o, Q, Q, r, Q, Q)
    + NL + "              THEN %s%s %s END ||" % (Q, c, Q)
    for c, o, r in pares).rstrip('|').rstrip()

# ------------------------------------------------------- T3 : volumetria
# Os 8 WHERE sao lidos do SPOOL, nao copiados da procedure. E a diferenca que
# torna o teste util: se a procedure perder uma condicao -- aconteceu, o
# INSERT #1 ficou sem o "NOT LIKE 'TRE2%'" -- o ecart deixa de ser zero. Um
# teste que reutilizasse as constantes do gerador nunca daria por isso.
FIM_DOS_BLOCOS = [(1, 1068), (2, 1575), (3, 2069), (4, 3449),
                  (5, 4010), (6, 4593), (7, 5049), (8, 5628)]
LIN = open('030_spool_Extract_CRRCORP.sql', encoding='latin-1').read().split(NL)


def where_do_spool(fim):
    txt, k = [], fim
    while ';' not in LIN[k]:
        txt.append(LIN[k])
        k += 1
    txt.append(LIN[k].split(';')[0])
    b = NL.join(txt)
    b = b[b.upper().index('WHERE') + 5:]
    b = NL.join(l.split('--')[0].rstrip() for l in b.split(NL))
    b = b.replace(':ENTITE', Q + 'TOTAL' + Q)
    return NL.join('      ' + l.strip() for l in b.split(NL) if l.strip())


uni = []
for n, fim in FIM_DOS_BLOCOS:
    per = 'NAT02' if n <= 3 else 'HORS_NAT02'
    uni.append("    SELECT %d AS variante, %s%s%s AS perimetre, COUNT(*) AS nb%s"
               % (n, Q, per, Q, NL)
               + "      FROM ENG_CORP_P1 C_ENR WHERE" + NL + where_do_spool(fim))

# ---------------------------------------------------------------- montagem
S = []
a = S.append
a("-- =====================================================================")
a("-- SIRL-1224 : ENG_CORP_P1_BIS -- ficheiro unico de testes")
a("--")
a("-- Correr no SQL Developer com F5 (Run Script), nao F9.")
a("--")
a("-- Ordem: 1. ENG_CORP_P1_BIS.sql            (cria a tabela)")
a("--        2. pack_alim_tab_envoi_crrv4.sql  (compila o package)")
a("--        3. este ficheiro")
a("--")
a("-- T1 ESTRUTURA   a tabela na base e a que o DDL manda?")
a("-- T2 PACKAGE     o codigo compilado e o do repositorio?")
a("-- T3 VOLUMETRIA  o nr de linhas e o que os 8 WHERE do spool devolvem?")
a("-- T4 ROUND-TRIP  o valor guardado reproduz o que o spool escreve hoje?")
a("-- =====================================================================")
a("SET SERVEROUTPUT ON")
a("SET LINESIZE 32000")
a("SET PAGESIZE 200")
a("")
a("-- ---------------------------------------------------------------------")
a("-- T1  ESTRUTURA DA TABELA")
a("-- ---------------------------------------------------------------------")
a("COLUMN column_name FORMAT A14")
a("COLUMN esperado    FORMAT A14")
a("COLUMN instalado   FORMAT A14")
a("")
a("-- T1.1  contagem : esperado %d colunas" % N_COLS)
a("SELECT %d AS esperado_colunas, COUNT(*) AS instalado_colunas," % N_COLS)
a("       CASE WHEN COUNT(*) = %d THEN 'OK' ELSE 'FALHA' END AS veredicto" % N_COLS)
a("  FROM ALL_TAB_COLUMNS WHERE table_name = 'ENG_CORP_P1_BIS';")
a("")
a("-- T1.2  as colunas alargadas (as que causaram ORA-01438 ou perda de")
a("--       decimais). Um FALHA aqui = tabela criada com um DDL antigo.")
a("SELECT t.column_name, t.esperado,")
a("       'NUMBER('||c.data_precision||','||c.data_scale||')' AS instalado,")
a("       CASE WHEN 'NUMBER('||c.data_precision||','||c.data_scale||')' = t.esperado")
a("            THEN 'OK' ELSE 'FALHA' END AS veredicto")
a("  FROM (")
a((NL + "        UNION ALL" + NL).join(
    # o padding fica FORA das plicas: um espaco dentro do literal partiria
    # o JOIN por column_name e a comparacao com o tipo instalado.
    "        SELECT %-12s AS column_name, %-15s AS esperado FROM DUAL"
    % (Q + c + Q, Q + t + Q)
    for c, t in ALARGADAS))
a("       ) t")
a("  LEFT JOIN ALL_TAB_COLUMNS c ON c.table_name  = 'ENG_CORP_P1_BIS'")
a("                             AND c.column_name = t.column_name")
a(" ORDER BY t.column_name;")
a("")
a("-- ---------------------------------------------------------------------")
a("-- T2  PACKAGE INSTALADO")
a("--     Nao se adivinha o que esta compilado: le-se o dicionario. Um")
a("--     package obsoleto ja produziu P1_3_20 = 520547 em vez de 2,95.")
a("-- ---------------------------------------------------------------------")
a("COLUMN object_name   FORMAT A34")
a("COLUMN argument_name FORMAT A14")
a("")
a("-- T2.1  estado e data de compilacao (STATUS tem de ser VALID)")
a("SELECT object_name, object_type, status,")
a("       TO_CHAR(last_ddl_time,'YYYY-MM-DD HH24:MI') AS compilado_em")
a("  FROM ALL_OBJECTS WHERE object_name = '%s' ORDER BY object_type;" % PKG)
a("")
a("-- T2.2  assinatura : a procedure atual tem 3 parametros")
a("SELECT position, argument_name, data_type")
a("  FROM ALL_ARGUMENTS")
a(" WHERE object_name = 'P_ALIM_ENG_CORP_P1_BIS' AND package_name = '%s'" % PKG)
a(" ORDER BY position;")
a("")
a("-- T2.3  se T2.1 devolveu INVALID, a razao esta aqui. Resultado vazio = sem")
a("--       erros: um INVALID sem erros e so uma dependencia que mudou, e a")
a("--       proxima chamada recompila sozinha.")
a("COLUMN texto FORMAT A96")
a("SELECT type, line, position, TRIM(text) AS texto")
a("  FROM ALL_ERRORS WHERE name = '%s' ORDER BY sequence;" % PKG)
a("")
a("-- ---------------------------------------------------------------------")
a("-- T3  VOLUMETRIA : esperado (fonte) vs inserido (tabela)")
a("--     Os 8 SELECT abaixo sao os 8 WHERE dos 8 INSERT da procedure,")
a("--     copiados do spool. ECART tem de ser 0.")
a("-- ---------------------------------------------------------------------")
a("DECLARE")
a("    v_masysdate VARCHAR2(12) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MI');")
a("    v_t0        TIMESTAMP    := SYSTIMESTAMP;")
a("BEGIN")
a("    -- p_perimetre : 'NAT02' (M2 BTR) | 'HORS_NAT02' (apos compta) | 'TOTAL'")
a("    %s.P_ALIM_ENG_CORP_P1_BIS('TOTAL', v_masysdate, 'TOTAL');" % PKG.lower())
a("    DBMS_OUTPUT.PUT_LINE('procedure OK - duracao : '||TO_CHAR(SYSTIMESTAMP - v_t0));")
a("END;")
a("/")
a("")
a("WITH esperado AS (")
a((NL + "    UNION ALL" + NL).join(uni))
a(")")
a("SELECT e.perimetre,")
a("       SUM(e.nb) AS esperado,")
a("       NVL(MAX(i.nb),0) AS inserido,")
a("       SUM(e.nb) - NVL(MAX(i.nb),0) AS ecart")
a("  FROM esperado e")
a("  -- LEFT JOIN: se um perimetro nao foi alimentado tem de aparecer com ecart")
a("  LEFT JOIN (SELECT CD_PERIMETRE, COUNT(*) AS nb")
a("          FROM ENG_CORP_P1_BIS GROUP BY CD_PERIMETRE) i")
a("    ON i.CD_PERIMETRE = e.perimetre")
a(" GROUP BY e.perimetre ORDER BY 1;")
a("")
a("-- ---------------------------------------------------------------------")
a("-- T4  ROUND-TRIP -- o teste central")
a("--")
a("-- Para cada coluna corre-se, na MESMA linha e na MESMA data:")
a("--    a expressao do spool sobre ENG_CORP_P1      (A)")
a("--    a mesma expressao    sobre ENG_CORP_P1_BIS  (B)")
a("-- Se a conversao esta certa as duas strings sao iguais: o valor guardado,")
a("-- reformatado, reproduz o que o spool escreve hoje.")
a("--")
a("-- Sao %d colunas x %d engajamentos." % (len(pares), N_LINHAS))
if EXCLUIDAS:
    a("--")
    a("-- Fora do teste: %s." % ", ".join(sorted(EXCLUIDAS)))
    a("-- Nestes o spool parte o campo em sinal + valor e o valor vem de")
    a("-- varias colunas de origem: nao ha reconstrucao textual segura.")
    a("-- Sao os campos onde o LPAD(...,5) do spool TRUNCA valores > 99999;")
    a("-- a tabela guarda o valor certo, o ficheiro e que perde. Ver")
    a("-- docs/SIRL-1224.md.")
a("-- Coluna de resultado VAZIA = engajamento totalmente conforme.")
a("-- ---------------------------------------------------------------------")
a("COLUMN id_engagement FORMAT A26")
a("COLUMN colunas_que_nao_reproduzem FORMAT A120")
a("")
a("SELECT C_ENR.ID_ENGAGEMENT,")
a(casos)
a("           AS colunas_que_nao_reproduzem")
a("  FROM ENG_CORP_P1 C_ENR")
a("  JOIN ENG_CORP_P1_BIS B ON B.P1_H_1_11 = C_ENR.ID_ENGAGEMENT || '_C'")
a("  -- so engajamentos com UMA linha na tabela: evita cruzar variantes")
a("  JOIN (SELECT P1_H_1_11 FROM ENG_CORP_P1_BIS")
a("         GROUP BY P1_H_1_11 HAVING COUNT(*) = 1) U")
a("    ON U.P1_H_1_11 = B.P1_H_1_11")
a(" WHERE C_ENR.A_EXTRAIRE = 'O'")
a("   AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'")
a("   AND NVL(C_ENR.FLAG_HN,'N')         = 'N'")
a("   AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1 OR NVL(C_ENR.MNT_VR,0) >= 1 )")
a("   AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')")
a("   AND ROWNUM <= %d;" % N_LINHAS)

open('TESTES.sql', 'w', encoding='utf-8').write(NL.join(S) + NL)
print('colunas na tabela      : %d' % N_COLS)
print('colunas alargadas      : %d' % len(ALARGADAS))
print('colunas no round-trip  : %d' % len(pares))
print('-> TESTES.sql')
