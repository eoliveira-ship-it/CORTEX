"""Acrescenta ao ENG_CORP_P1_BIS.sql um COMMENT ON COLUMN por coluna.

Os comentarios "--" do CREATE TABLE ficam so no ficheiro; o COMMENT ON COLUMN
fica no dicionario (ALL_COL_COMMENTS) e aparece no SQL Developer. O nome vem
inteiro da Notice -- no DDL esta cortado a 60 caracteres.

Pode correr-se varias vezes: o bloco anterior e substituido.
"""
import io
import re

import openpyxl

import enc

DDL_FICH = 'ENG_CORP_P1_BIS.sql'
MARCA = '-- ---- Commentaires des colonnes'

TECNICAS = {
    'ID_ENGAGEMENT': 'Reference engagement (ENG_CORP_P1.ID_ENGAGEMENT)',
    'CD_PERIMETRE':  "Perimetre : 'NAT02' / 'HORS_NAT02' (M2 BTR vs post-compta)",
    'NO_VARIANTE':   'Variante 1..8 : lequel des 8 SELECT du spool a produit cette ligne '
                     "(ORDER BY NO_VARIANTE rend l'ordre actuel du fichier)",
    'DT_ARRETE':     "Date d'arrete du traitement",
    'DT_TRAITEMENT': "Horodatage d'alimentation",
}

# Campos que nao estao na folha da Notice, com o nome escrito a mao.
#
# Sem isto o nome sai do proprio comentario do DDL, que leva uma nota nossa a
# seguir ao nome -- '(criado na V45.01 - SIRL-1222)' -- e essa nota ia para o
# dicionario de dados. O P1 621 foi criado na V45.01 e a folha que temos nao o
# tem.
A_MAO = {
    'P1 621': "Intention de gestion de l'operation",
}

wb = openpyxl.load_workbook('Notice PACTV4.5_v1.0.xlsx', read_only=True, data_only=True)
nomes = {}
for r in wb['PACT Corp'].iter_rows(min_row=4, values_only=True):
    if r[0] == 'P1' and r[4] and r[5]:
        nomes[str(r[4]).strip()] = str(r[5]).strip()

# O DDL e cp1252, como todo o .sql do projecto: lido como utf-8 rebenta no
# primeiro acento (0xEA, o 'e' de 'Frequence'). O enc.le detecta.
txt, _cod = enc.le(DDL_FICH)
NL = '\r\n' if '\r\n' in txt else '\n'
txt = txt.split(MARCA)[0].rstrip() + NL

def q(s):
    return s.replace("'", "''")

linhas, sem_nome = [], []
for col, rest in re.findall(r'^\s+([A-Z][A-Z0-9_]*)\s+(?:VARCHAR2|NUMBER|DATE)\b[^\n]*?--\s*([^\r\n]*)', txt, re.M):
    if col in TECNICAS:
        texto = TECNICAS[col]
    else:
        m = re.match(r'(.+?)\s{2,}((?:ALPHA|NUM|DATE)/\d+)', rest)
        ref, fmt = m.group(1).strip(), m.group(2)
        nome = nomes.get(ref) or A_MAO.get(ref)
        if nome is None:
            sem_nome.append(ref)
            nome = rest[m.end():].strip()
        texto = '%s - %s - %s' % (ref, fmt, nome)
    linhas.append("COMMENT ON COLUMN ENG_CORP_P1_BIS.%s IS '%s';" % (col, q(texto)))

bloco = [MARCA + ' (nom complet de la Notice PACT V4.5) ' + '-' * 10] + linhas
io.open(DDL_FICH, 'w', encoding='cp1252', newline='').write(txt + NL + NL.join(bloco) + NL)
print('COMMENT ON COLUMN:', len(linhas), '| sem nome na notice:', sem_nome)
