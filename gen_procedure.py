import re, sys
sys.path.insert(0, '.')
from conv_spool import convert

lines = open('spool.sql', encoding='utf-8', errors='replace').read().split('\n')


def strip_line(l, in_block):
    """Retire les commentaires en tenant compte des blocs /* */ qui courent
    sur plusieurs lignes, et des litteraux 'texte' (ou -- et /* ne comptent pas).
    Retourne (code, commentaire_de_ligne, in_block)."""
    code = ''
    cm = ''
    i = 0
    in_str = False
    while i < len(l):
        two = l[i:i+2]
        if in_block:
            if two == '*/':
                in_block = False
                i += 2
                continue
            i += 1
            continue
        if in_str:
            code += l[i]
            if l[i] == "'":
                in_str = False
            i += 1
            continue
        if l[i] == "'":
            in_str = True
            code += l[i]
            i += 1
            continue
        if two == '/*':
            in_block = True
            i += 2
            continue
        if two == '--':
            cm = l[i:]
            break
        code += l[i]
        i += 1
    return code, cm, in_block


def tokenize(a, b):
    seg = lines[a:b]
    buf = []
    anchors = {}
    lnmap = {}
    in_block = False
    for k, l in enumerate(seg):
        code, cm, in_block = strip_line(l, in_block)
        base = sum(len(x) for x in buf)
        m = re.search(r'--\s*P1\s+([\d.]+)', cm)
        # une ancre sur une ligne SANS code appartient a du code commente :
        # elle ne doit pas etre rattachee au token precedent.
        if m and code.strip():
            anchors[base + len(code)] = 'P1 ' + m.group(1)
        lnmap[base] = a + k + 1
        buf.append(code + '\n')
    full = ''.join(buf)
    up = full.upper()
    toks = []
    cur = ''
    pd = cd = 0
    i = 0
    st = 0
    while i < len(full):
        if up[i:i+4] == 'CASE' and (i == 0 or not (up[i-1].isalnum() or up[i-1] == '_')) and not up[i+4:i+5].isalnum():
            cd += 1
            cur += full[i:i+4]
            i += 4
            continue
        if up[i:i+3] == 'END' and (i == 0 or not (up[i-1].isalnum() or up[i-1] == '_')) and not (up[i+3:i+4].isalnum() or up[i+3:i+4] == '_'):
            cd = max(0, cd - 1)
            cur += full[i:i+3]
            i += 3
            continue
        ch = full[i]
        if ch == '(':
            pd += 1
        elif ch == ')':
            pd -= 1
        if ch == '|' and full[i:i+2] == '||' and pd == 0 and cd == 0:
            toks.append((st, i, cur))
            i += 2
            cur = ''
            st = i
            continue
        cur += ch
        i += 1
    if cur.strip():
        toks.append((st, len(full), cur))

    def ln_for(off):
        best = None
        for k in sorted(lnmap):
            if k <= off:
                best = lnmap[k]
        return best

    out = []
    for s, e, t in toks:
        t = re.sub(r'^\s*select\s+', '', t, flags=re.I)
        for part in re.split(r'\bas\s+lignedetail\d\s*,?', t, flags=re.I):
            p = part.strip().rstrip(',').strip()
            if not p:
                continue
            if re.match(r'^(from|where)\b', p, re.I):
                continue
            out.append({'raw': p, 's': s, 'e': e, 'line': ln_for(s)})
    for pos, rf in sorted(anchors.items()):
        cand = [o for o in out if o['e'] <= pos]
        if cand:
            cand[-1]['ref'] = rf
    for o in out:
        o.setdefault('ref', None)
    return out


DDL_COLS = set(re.findall(r'^\s+(P1_[A-Z0-9_]+)\s',
                          open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read(),
                          re.M))


def col_of(ref):
    """Resout l'ancre du spool vers une colonne REELLE de la table.
    Une ancre '--P1 1.11' peut viser le corps (P1_1_11) ou l'en-tete du
    pave (P1_H_1_11, note '1.11 (P1)' dans la notice) : on tranche en
    verifiant l'existence dans le DDL."""
    if not ref:
        return None
    num = ref.split()[1].replace('.', '_')
    for cand in ('P1_' + num, 'P1_H_' + num):
        if cand in DDL_COLS:
            return cand
    return None


HEADER_CONV = [
    (r'DT_ARRETE', 'P1_H_0_1'),
    (r'CD_CONSO_CPT', 'P1_H_0_2'),
    (r"APPLI_SOURCE|'C_DDR'", 'P1_H_0_3'),
    (r"^'M'$", 'P1_H_0_4'),
    (r'^p_masysdate$', 'P1_H_0_5'),
    (r"^'P1'$", 'P1_H_0_6'),
]


def header_col(expr, seq):
    """Les 6 premieres positions de CHAQUE select sont l'en-tete du pave,
    identique partout : arrete / entite / appli / 'M' / horodatage / 'P1'.
    Mapping par convention du spool (a valider DSID)."""
    if seq > 6:
        return None
    pat, col = HEADER_CONV[seq - 1]
    return col if re.search(pat, expr.strip(), re.I) else None


def is_sign(expr):
    """Token qui ne porte QUE le signe d'un montant ('+' / '-', ou un CASE
    dont toutes les branches valent '+' ou '-'). Le signe est porte par le
    NUMBER dans la table : ce token ne devient pas une colonne."""
    e = expr.strip()
    lits = re.findall(r"'([^']*)'", e)
    if not lits:
        return False
    if not all(x.strip() in ('+', '-') for x in lits):
        return False
    return re.fullmatch(r"'[+-]'", e) is not None or re.search(r'\bTHEN\b', e, re.I) is not None


W1 = """      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'N'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 )
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')"""

W2 = """      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND NVL(C_ENR.MNT_SOLD_K_A,0) >= 1
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' )"""

W3 = """      A_EXTRAIRE = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND NVL(C_ENR.CD_ARR_PAIEMENT,'N') = 'Y'
      AND NVL(C_ENR.FLAG_HN,'N')         = 'N'
      AND C_ENR.CD_TYPE_RISQUE NOT IN ('TRE100','SIG201','EQU101','VAR104')
      AND ( C_ENR.CD_TYPE_RISQUE NOT LIKE 'TRE2%' )
      AND ( NVL(C_ENR.MNT_CRD,0) - NVL(C_ENR.MNT_VR,0) >= 1
            OR NVL(C_ENR.MNT_VR,0) >= 1 )"""

W4 = """      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('TRE100')"""

W5 = """      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND SUBSTR(C_ENR.CD_TYPE_RISQUE,1,4) IN ('TRE2','TRE4','TRE5')"""

W6 = """      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('EQU101')"""

W7 = """      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE IN ('SIG201','INR101')"""

W8 = """      A_EXTRAIRE = 'O'
      AND C_ENR.FLAG_HN = 'O'
      AND (C_ENR.CD_CONSO_CPT = p_entite OR p_entite = 'TOTAL')
      AND C_ENR.CD_TYPE_RISQUE LIKE '%VAR1%'"""

VAR = [
    (1, 'NAT02', 589, 1068, 'standard NAT02 - spool L590', W1),
    (2, 'NAT02', 1088, 1575, "NAT02 arriere='Y' solde - spool L1089", W2),
    (3, 'NAT02', 1591, 2069, "NAT02 arriere='Y' CRD/VR - spool L1592", W3),
    (4, 'HORS_NAT02', 2893, 3449, 'Hors-NAT TRE100 - spool L2894', W4),
    (5, 'HORS_NAT02', 3461, 4010, 'Hors-NAT TRE2/TRE4/TRE5 - spool L3462', W5),
    (6, 'HORS_NAT02', 4025, 4593, 'Hors-NAT EQU101 - spool L4026', W6),
    (7, 'HORS_NAT02', 4605, 5049, 'Hors-NAT SIG201/INR101 - spool L4606', W7),
    (8, 'HORS_NAT02', 5060, 5628, 'Hors-NAT VAR1 - spool L5061', W8),
]

stats = []
blocks = []
amapear = []
dupes = []
for num, perim, a, b, desc, where in VAR:
    toks = tokenize(a, b)
    items = []
    seq = 0
    nfill = 0
    nanch = 0
    nsign = 0
    nhdr = 0
    for t in toks:
        expr = convert(t['raw']).replace(':MASYSDATE', 'p_masysdate')
        if expr.strip().upper() == 'NULL':
            nfill += 1
            continue
        if is_sign(expr):
            nsign += 1
            continue
        seq += 1
        col = col_of(t['ref'])
        ref = t['ref']
        if col:
            nanch += 1
        else:
            hc = header_col(expr, seq)
            if hc:
                col = hc
                ref = 'en-tete conv.'
                nhdr += 1
            else:
                col = None
        if col is None:
            amapear.append((num, seq, t['line'], expr))
            continue
        items.append((col, expr, t['line'], ref))
    seen = set()
    ded = []
    for col, expr, ln, ref in items:
        if col in seen:
            dupes.append((num, col, ln, expr))
            continue
        seen.add(col)
        ded.append((col, expr, ln, ref))
    stats.append((num, len(toks), len(ded), nanch + nhdr, nfill, nsign))

    cl = '\n'.join('        %s%s' % (c, ',' if i < len(ded) - 1 else '')
                   for i, (c, _, _, _) in enumerate(ded))
    sl = ["        %-58s AS CD_PERIMETRE," % ("'%s'" % perim)]
    for i, (c, e, ln, ref) in enumerate(ded):
        comma = ',' if i < len(ded) - 1 else ''
        tag = 'L%s' % ln + ((' [%s]' % ref) if ref else ' [a mapper]')
        sl.append("        %-58s AS %s%s  -- %s" % (e, c, comma, tag))
    blocks.append(
        "    ------------------------------------------------------------------\n"
        "    -- INSERT #%d  (%s)\n"
        "    --   colonnes : %d (dont %d ancrees --P1) | %d fillers -> NULL"
        " | %d signes absorbes par le NUMBER\n"
        "    ------------------------------------------------------------------\n"
        "    INSERT INTO ENG_CORP_P1_BIS\n    (\n        CD_PERIMETRE,\n%s\n    )\n"
        "    SELECT\n%s\n    FROM ENG_CORP_P1 C_ENR\n    WHERE\n%s;\n"
        % (num, desc, len(ded), nanch, nfill, nsign, cl, '\n'.join(sl), where))

hdr = open('_hdr.txt', encoding='utf-8').read()

extra = """-- ---------------------------------------------------------------------
-- IMPORTANT - ECART DE VERSION
-- ---------------------------------------------------------------------
-- Le spool implemente la notice V44.02 ; la notice du depot est V45.00.
-- Ecart mesure : 6154 - 5635 = 519 octets (50 champs crees en V45 = 434 o,
-- plus les modifications, ex. P1 21.65 : 5 -> 50).
-- => l'alignement automatique par POSITION spool(V44) vs notice(V45)
--    n'est PAS un oracle valable.
--
-- PERIMETRE DE CETTE VERSION (compilable) :
--   Seules les colonnes dont la cible est CONNUE sont alimentees :
--      - ancre '--P1 X.Y' ecrite dans le spool (source faisant foi) ;
--      - les 6 positions d'en-tete, identiques dans les 8 SELECT.
--   Les positions dont la colonne cible reste a determiner NE SONT PAS
--   inserees : elles restent a NULL dans la table. Leur inventaire complet
--   (INSERT, sequence, ligne du spool, expression deja convertie) est dans
--   docs/posicoes-a-mapear.md -> a completer avec la DSID.
--
--   ATTENTION : tant que ces positions ne sont pas mappees, le fichier
--   CRRCORP.dat regenere depuis la table NE PEUT PAS etre iso au fichier
--   actuel. Le test de non-regression n'est donc pas encore possible.
--
-- PREREQUIS : la table ENG_CORP_P1_BIS doit exister (ENG_CORP_P1_BIS.sql).
-- Les regles de gestion (CASE, NVL par defaut) sont CONSERVEES telles
-- quelles ; seul le formatage (RPAD/LPAD/TO_CHAR/F_FORMAT_*) est retire.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 1) A AJOUTER DANS LA SPEC DU PACKAGE  pack_alim_tab_envoi_crrv4
-- ---------------------------------------------------------------------
--   PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite IN VARCHAR2, p_masysdate IN VARCHAR2);


-- ---------------------------------------------------------------------
-- 2) CORPS DE LA PROCEDURE (a inserer dans le PACKAGE BODY)
-- ---------------------------------------------------------------------
"""

body = "PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite IN VARCHAR2, p_masysdate IN VARCHAR2)\nIS\nBEGIN\n"
body += ("    ------------------------------------------------------------------\n"
         "    -- Etape 1 : vider la table avant de la remplir (SFG SIRL-1224)\n"
         "    ------------------------------------------------------------------\n"
         "    EXECUTE IMMEDIATE 'TRUNCATE TABLE ENG_CORP_P1_BIS';\n\n")
body += '\n'.join(blocks)
body += "\n    COMMIT;\nEND P_ALIM_ENG_CORP_P1_BIS;\n"

open('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', 'w', encoding='utf-8').write(hdr + extra + body)

inv = ['# Posicoes do spool ainda por mapear', '',
       'Geradas por `gen_procedure.py`. Cada linha e uma posicao do spool cuja',
       'coluna de destino ainda nao e conhecida (sem ancora `--P1` no spool).',
       'Ver `docs/ECART-VERSAO.md` para saber porque o mapeamento por posicao',
       'nao pode ser feito automaticamente.', '',
       '| INSERT | seq | linha spool | expressao (formatacao ja retirada) |',
       '|---|---|---|---|']
for n, sq, ln, e in amapear:
    inv.append('| #%d | %d | L%s | `%s` |' % (n, sq, ln, e.replace('|', chr(92)+'|')))
open('docs/posicoes-a-mapear.md', 'w', encoding='utf-8').write(chr(10).join(inv) + chr(10))
print('posicoes por mapear:', len(amapear), '-> docs/posicoes-a-mapear.md')
if dupes:
    print('colunas duplicadas descartadas (2a ocorrencia):', len(dupes))
    for n, c, ln, e in dupes[:10]:
        print('   #%d %s (L%s)' % (n, c, ln))
print('INSERT | tokens | colunas | ancoradas | fillers | sinais')
for n, t, c, anc, f, s in stats:
    print('   #%d   |  %4d  |  %4d   |   %4d    |  %4d   | %4d' % (n, t, c, anc, f, s))
print('duplicados __D restantes:',
      sum(1 for b in blocks for _ in re.finditer(r'__D\d', b)))
