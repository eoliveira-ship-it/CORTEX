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


DDL_TYPES = dict(re.findall(r'^\s+(P1_[A-Z0-9_]+)\s+([A-Z0-9_]+(?:\([0-9, ]+\))?)',
                            open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read(),
                            re.M))


def _split_args(t):
    d, out, cur = 0, [], ''
    for ch in t:
        if ch == '(':
            d += 1
        elif ch == ')':
            d -= 1
        if ch == ',' and d == 0:
            out.append(cur)
            cur = ''
            continue
        cur += ch
    out.append(cur)
    return out


def _fix_nvl(e, conv_lit):
    """Reescreve APENAS o 2o argumento dos NVL (o valor por defeito).
    Nunca toca nos literais das condicoes: um NOT IN ('1','2') tem de
    ficar intacto, senao a regra de negocio muda."""
    out, i = '', 0
    pat = re.compile(r'\bNVL\s*\(', re.I)
    while i < len(e):
        m = pat.match(e, i)
        if m:
            op = m.end() - 1
            d, j = 0, op
            while j < len(e):
                if e[j] == '(':
                    d += 1
                elif e[j] == ')':
                    d -= 1
                    if d == 0:
                        break
                j += 1
            args = _split_args(e[op + 1:j])
            if len(args) == 2:
                out += ('NVL(' + _fix_nvl(args[0], conv_lit)
                        + ', ' + conv_lit(args[1].strip()) + ')')
            else:
                out += e[i:j + 1]
            i = j + 1
            continue
        out += e[i]
        i += 1
    return out


def fit_type(expr, col):
    """O spool escreve numeros e datas como TEXTO formatado. Retirado o
    formato, esses literais tem de voltar ao tipo da coluna, senao
    ORA-00932. So se tocam posicoes de VALOR (THEN / ELSE / defeito de
    NVL / expressao inteira)."""
    typ = DDL_TYPES.get(col, '')
    if typ.startswith('NUMBER'):
        def cl(v):
            return str(int(v.strip("'"))) if re.fullmatch(r"'[+-]?\d+'", v) else v
    elif typ == 'DATE':
        def cl(v):
            if re.fullmatch(r"'\d{8}'", v):
                return "TO_DATE(%s,'YYYYMMDD')" % v
            return v
    else:
        return expr
    e = _fix_nvl(expr, cl)
    e = re.sub(r"(\bTHEN\s+)('[^']*')", lambda m: m.group(1) + cl(m.group(2)), e, flags=re.I)
    e = re.sub(r"(\bELSE\s+)('[^']*')", lambda m: m.group(1) + cl(m.group(2)), e, flags=re.I)
    if re.fullmatch(r"'[^']*'", e.strip()):
        e = cl(e.strip())
    return e


DDL_COLS = set(re.findall(r'^\s+(P1_[A-Z0-9_]+)\s',
                          open('ENG_CORP_P1_BIS.sql', encoding='utf-8').read(),
                          re.M))


import io as _io
import sys as _sys

_src = open('align_v44.py', encoding='utf-8').read()
_src = _src.split('# ------------------------------------------------------- alinhamento')[0]
_ns = {}
_buf = _io.StringIO()
_o = _sys.stdout
_sys.stdout = _buf
exec(_src, _ns)
_sys.stdout = _o
V44 = _ns['v44']
WIDTH = _ns['width']


ORIG_TIPOS = {}
try:
    for _l in open('tipos', encoding='utf-8', errors='replace'):
        _p = _l.rstrip(chr(10)).split(chr(9))
        if len(_p) >= 2 and _p[0].strip():
            ORIG_TIPOS[_p[0].strip().upper()] = _p[1].strip()
except IOError:
    pass


def fontes_valor(expr):
    """Colunas de origem em posicao de VALOR (as condicoes WHEN..THEN
    nao contam: um CASE pode testar uma coluna de texto e devolver um
    numero)."""
    e = re.sub(r'\bWHEN\b.*?\bTHEN\b', ' THEN ', expr, flags=re.I | re.S)
    return set(x.upper() for x in re.findall(r'C_ENR\.([A-Za-z0-9_]+)', e))


def tipo_compativel(expr, col):
    """Recusa alimentar uma coluna NUMBER/DATE a partir de uma origem de
    texto: daria ORA-01722 em execucao. Sem o ficheiro 'tipos' nao se
    valida nada (devolve True)."""
    if not ORIG_TIPOS:
        return True
    dest = DDL_TYPES.get(col, '')
    if not (dest.startswith('NUMBER') or dest == 'DATE'):
        return True
    for f in fontes_valor(expr):
        if ORIG_TIPOS.get(f) in ('VARCHAR2', 'CHAR', 'NVARCHAR2'):
            return False
    return True


def col_notice(ref):
    """'P1 21.28' -> P1_21_28 ; '1.11 (P1)' -> P1_H_1_11"""
    if '(P1)' in ref:
        return 'P1_H_' + ref.replace('(P1)', '').strip().replace('.', '_')
    return 'P1_' + ref.split()[1].replace('.', '_')


def col_por_posicao(pos, w):
    """Coluna deduzida da regua V44: so aceita quando a posicao cai num
    UNICO campo da notice e esse campo existe na tabela."""
    campos = [f for f in V44 if f['start'] < pos + w and f['start'] + f['len'] > pos]
    if len(campos) != 1:
        return None
    c = col_notice(campos[0]['ref'])
    return c if c in DDL_COLS else None


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

HDR = """-- =====================================================================
-- SIRL-1224 : alimentation de la table ENG_CORP_P1_BIS
-- Package  : pack_alim_tab_envoi_crrv4
-- Procedure: P_ALIM_ENG_CORP_P1_BIS
--
-- But : sortir les regles de gestion du pave P1 hors du spool
--       030_spool_Extract_CRRCORP.sql et les porter dans cette procedure,
--       qui remplit ENG_CORP_P1_BIS a partir de ENG_CORP_P1.
--       Le spool vPACT ne fera plus qu'un SELECT unique sur la table.
--
-- Le pave P1 est aujourd'hui produit par 8 SELECT sur ENG_CORP_P1 C_ENR,
-- qui partitionnent la population (perimetre NAT02 vs Hors-NAT, arriere de
-- paiement, montant, type de risque). Chaque SELECT devient ici un INSERT
-- qui garde SON filtre (clause WHERE) a l'identique.
--
--   #  ligne spool  FLAG_HN  filtre principal
--   1     590         N       risque std,  (CRD-VR)>=1 ou VR>=1
--   2    1089         N       arriere='Y', SOLD_K_A>=1, pas TRE2%
--   3    1592         N       arriere='Y', (CRD-VR)>=1 ou VR>=1, pas TRE2%
--   4    2894         O       CD_TYPE_RISQUE = 'TRE100'
--   5    3462         O       CD_TYPE_RISQUE LIKE 'TRE2/TRE4/TRE5'
--   6    4026         O       CD_TYPE_RISQUE = 'EQU101'
--   7    4606         O       CD_TYPE_RISQUE IN ('SIG201','INR101')
--   8    5061         O       CD_TYPE_RISQUE LIKE '%VAR1%'
--
-- ---------------------------------------------------------------------
-- REGLES DE CONVERSION  format spool  ->  valeur typee dans la table
-- ---------------------------------------------------------------------
--   RPAD(NVL(C_ENR.X,' '),n)              ->  C_ENR.X              (VARCHAR)
--   RPAD(C_ENR.X,n)                       ->  C_ENR.X
--   RPAD(' ',n)  (champ vide dans le spool)->  NULL   (colonne non listee)
--   to_char(C_ENR.DT,'YYYYMMDD')          ->  C_ENR.DT             (DATE, brute)
--   RPAD(NVL(TO_CHAR(C_ENR.DT,'YYYYMMDD'),' '),8) -> C_ENR.DT
--   'M' / 'P1' / 'Y' ... (litteral)       ->  litteral conserve
--   pack_utilitaire.F_FORMAT_TAUX(C_ENR.X)         -> C_ENR.X       (NUMBER)
--   pack_utilitaire.f_format_montant_bis2(<expr>)  -> <expr>        (NUMBER)
--   CASE ... THEN '+' ELSE '-' END (signe)-> supprime (le signe est porte
--                                            par le NUMBER)
--   NVL/CASE metier (ex defaut 'STD', '99990630', EAD<0 -> 0)
--                                         ->  CONSERVE (c'est une regle
--                                            de gestion, pas du formatage)
--
-- FLAG_HN -> CD_PERIMETRE :  'N' => 'NAT02'   ,  'O' => 'HORS_NAT02'
-- =====================================================================
"""

stats = []
blocks = []
amapear = []
dupes = []
incompativeis = []
for num, perim, a, b, desc, where in VAR:
    toks = tokenize(a, b)
    items = []
    seq = 0
    nfill = 0
    nanch = 0
    nsign = 0
    nhdr = 0
    npos = 0
    pos = 0
    for t in toks:
        w = WIDTH(t['raw'])
        if w is None:
            nf = next((f for f in V44 if f['start'] == pos), None)
            w = nf['len'] if nf else 0
        off = pos
        pos += w
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
                col = col_por_posicao(off, w)
                if col:
                    ref = 'position V44'
                    npos += 1
        if col is not None and not tipo_compativel(expr, col):
            incompativeis.append((num, col, DDL_TYPES.get(col, ''), t['line'], expr))
            col = None
        if col is None:
            amapear.append((num, seq, t['line'], expr))
            continue
        expr = fit_type(expr, col)
        items.append((col, expr, t['line'], ref))
    seen = set()
    ded = []
    for col, expr, ln, ref in items:
        if col in seen:
            dupes.append((num, col, ln, expr))
            continue
        seen.add(col)
        ded.append((col, expr, ln, ref))
    stats.append((num, len(toks), len(ded), nanch + nhdr, nfill, nsign, npos))

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

hdr = HDR

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
--   PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite    IN VARCHAR2,
--                                     p_masysdate IN VARCHAR2,
--                                     p_perimetre IN VARCHAR2 DEFAULT 'TOTAL');


-- ---------------------------------------------------------------------
-- 2) CORPS DE LA PROCEDURE (a inserer dans le PACKAGE BODY)
-- ---------------------------------------------------------------------
"""

SIG = ("PROCEDURE P_ALIM_ENG_CORP_P1_BIS (p_entite    IN VARCHAR2,"
       + chr(10) + "                                       p_masysdate IN VARCHAR2,"
       + chr(10) + "                                       p_perimetre IN VARCHAR2 DEFAULT 'TOTAL')")

_vid = [
    "IS",
    "BEGIN",
    "    ------------------------------------------------------------------",
    "    -- Etape 1 : vider UNIQUEMENT le perimetre traite.",
    "    --   Pas de TRUNCATE : c'est du DDL (commit implicite), les donnees",
    "    --   seraient perdues meme si un INSERT echouait ensuite. Le DELETE",
    "    --   reste dans la transaction et permet les DEUX alimentations",
    "    --   successives prevues par le ticket : NAT02 (M2 BTR) puis",
    "    --   HORS_NAT02 (apres reception des donnees comptables).",
    "    ------------------------------------------------------------------",
    "    IF p_perimetre NOT IN ('NAT02', 'HORS_NAT02', 'TOTAL') THEN",
    "        RAISE_APPLICATION_ERROR(-20001,",
    "            'p_perimetre invalide : '||p_perimetre||",
    "            ' (attendu NAT02, HORS_NAT02 ou TOTAL)');",
    "    END IF;",
    "",
    "    IF p_perimetre = 'TOTAL' THEN",
    "        DELETE FROM ENG_CORP_P1_BIS;",
    "    ELSE",
    "        DELETE FROM ENG_CORP_P1_BIS WHERE CD_PERIMETRE = p_perimetre;",
    "    END IF;",
    "",
]

body = SIG + chr(10) + chr(10).join(_vid) + chr(10)
body += "    IF p_perimetre IN ('NAT02', 'TOTAL') THEN" + chr(10) + chr(10)
body += chr(10).join(blocks[:3])
body += chr(10) + "    END IF;" + chr(10) + chr(10)
body += "    IF p_perimetre IN ('HORS_NAT02', 'TOTAL') THEN" + chr(10) + chr(10)
body += chr(10).join(blocks[3:])
body += chr(10) + "    END IF;" + chr(10) + chr(10)
body += "    COMMIT;" + chr(10) + "END P_ALIM_ENG_CORP_P1_BIS;" + chr(10)

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
if incompativeis:
    _u = {}
    for _n, _c, _t, _l, _e in incompativeis:
        _u.setdefault(_c, (_t, _l, _e))
    print('recusadas por tipo (origem texto -> coluna %s): %d posicoes, %d colunas'
          % ('NUMBER/DATE', len(incompativeis), len(_u)))
    for _c, (_t, _l, _e) in sorted(_u.items()):
        print('   %-12s %-13s L%-6s %s' % (_c, _t, _l, _e[:44]))
if dupes:
    print('colunas duplicadas descartadas (2a ocorrencia):', len(dupes))
    for n, c, ln, e in dupes[:10]:
        print('   #%d %s (L%s)' % (n, c, ln))
print('INSERT | tokens | colunas | ancoradas | fillers | sinais | por posicao')
for n, t, c, anc, f, sg, pp in stats:
    print('   #%d   |  %4d  |  %4d   |   %4d    |  %4d   | %4d | %4d' % (n, t, c, anc, f, sg, pp))
print('duplicados __D restantes:',
      sum(1 for b in blocks for _ in re.finditer(r'__D\d', b)))


# ---------------------------------------------------------------------
# Controle de coherence de types : le spool code les nombres en TEXTE.
# Toute valeur litterale 'xxx' affectee a une colonne NUMBER/DATE est
# signalee ici (sinon Oracle rend ORA-00932 a la compilation).
# ---------------------------------------------------------------------
_txt = open('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', encoding='utf-8').read()
_susp = []
for _line in _txt.split(chr(10)):
    _m = re.match(r"\s+(.*?)\s+AS (P1_[A-Z0-9_]+),?\s+--", _line)
    if not _m:
        continue
    _e, _c = _m.group(1).strip(), _m.group(2)
    _t = DDL_TYPES.get(_c, '?')
    _v = (re.findall(r"\bTHEN\s+('[^']*')", _e, re.I)
          + re.findall(r"\bELSE\s+('[^']*')", _e, re.I)
          + re.findall(r"\bNVL\s*\([^()]*,\s*('[^']*')\s*\)", _e, re.I))
    if re.fullmatch(r"'[^']*'", _e):
        _v.append(_e)
    if _v and (_t.startswith('NUMBER') or _t == 'DATE'):
        _susp.append((_c, _t, _v))
if _susp:
    print('AVISO - literais texto em colunas %s:' % 'NUMBER/DATE')
    for _c, _t, _v in _susp[:20]:
        print('   %-12s %-13s %s' % (_c, _t, _v))
else:
    print('coerencia de tipos: OK (nenhum literal texto em coluna NUMBER/DATE)')


# ---------------------------------------------------------------------
# Script de test : les requetes de controle reutilisent LES MEMES clauses
# WHERE que les INSERT, elles ne peuvent donc pas diverger.
# ---------------------------------------------------------------------
NL = chr(10)
_t = []
_t.append('-- Test de P_ALIM_ENG_CORP_P1_BIS  (SIRL-1224)')
_t.append('-- Prerequis : ENG_CORP_P1_BIS.sql execute + package compile.')
_t.append('-- MASYSDATE = date extraction yyyymmddHHMI (cf. spool L66), 12 car.')
_t.append('')
_t.append('SET SERVEROUTPUT ON')
_t.append('SET LINESIZE 200')
_t.append('')
_t.append('-- 0) Diagnostic de la source : quel perimetre existe reellement ?')
_t.append("--    FLAG_HN = 'N' -> NAT02 (INSERT #1-#3)  |  'O' -> HORS_NAT02 (#4-#8)")
_t.append("--    Aucune ligne FLAG_HN='O' => seul NAT02 apparaitra : c'est normal,")
_t.append('--    le perimetre Hors NAT 02 arrive apres reception des donnees comptables.')
_t.append("SELECT NVL(FLAG_HN,'N') AS flag_hn, COUNT(*) AS lignes")
_t.append("  FROM ENG_CORP_P1 WHERE A_EXTRAIRE = 'O'")
_t.append(" GROUP BY NVL(FLAG_HN,'N') ORDER BY 1;")
_t.append('')
_t.append('-- 0b) Detail par type de risque : les INSERT #4-#8 ne retiennent que')
_t.append("--     TRE100, TRE2/TRE4/TRE5, EQU101, SIG201/INR101 et %VAR1%.")
_t.append("SELECT NVL(FLAG_HN,'N') AS flag_hn, CD_TYPE_RISQUE, COUNT(*) AS lignes")
_t.append("  FROM ENG_CORP_P1 WHERE A_EXTRAIRE = 'O'")
_t.append(" GROUP BY NVL(FLAG_HN,'N'), CD_TYPE_RISQUE ORDER BY 1, 2;")
_t.append('')
_t.append('-- 1) Etat avant')
_t.append('SELECT COUNT(*) AS avant FROM ENG_CORP_P1_BIS;')
_t.append('')
_t.append('-- 2) Execution')
_t.append('DECLARE')
_t.append("    v_entite    VARCHAR2(10) := 'TOTAL';   -- ou un CD_CONSO_CPT precis")
_t.append("    v_masysdate VARCHAR2(12) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MI');")
_t.append('    v_t0        TIMESTAMP := SYSTIMESTAMP;')
_t.append('BEGIN')
_t.append("    -- p_perimetre : 'NAT02' (M2 BTR) | 'HORS_NAT02' (apres compta) | 'TOTAL'")
_t.append("    pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS(v_entite, v_masysdate, 'TOTAL');")
_t.append("    DBMS_OUTPUT.PUT_LINE('OK - duree : '||TO_CHAR(SYSTIMESTAMP - v_t0));")
_t.append('END;')
_t.append('/')
_t.append('')
_t.append('-- 3) Volumetrie par perimetre')
_t.append('SELECT CD_PERIMETRE, COUNT(*) AS lignes')
_t.append('  FROM ENG_CORP_P1_BIS GROUP BY CD_PERIMETRE ORDER BY 1;')
_t.append('')
_t.append('-- 4) CONTROLE : attendu (source) vs insere (table)')
_t.append('--    Chaque ligne doit donner ecart = 0.')
_t.append('WITH attendu AS (')
for _i, (_n, _p, _a, _b, _d, _w) in enumerate(VAR):
    _u = '' if _i == 0 else '    UNION ALL'
    if _u:
        _t.append(_u)
    _t.append("    SELECT %d AS variante, '%s' AS perimetre, COUNT(*) AS nb" % (_n, _p))
    _t.append('      FROM ENG_CORP_P1 C_ENR WHERE')
    _t.append(_w.replace('p_entite', "'TOTAL'"))
_t.append(')')
_t.append('SELECT a.variante, a.perimetre, a.nb AS attendu FROM attendu a ORDER BY 1;')
_t.append('')
_t.append('-- Total attendu (somme) doit egaler :')
_t.append('SELECT COUNT(*) AS insere FROM ENG_CORP_P1_BIS;')
_t.append('')
_t.append('-- 5) Taux de remplissage : colonnes alimentees vs restees NULL')
_t.append('--    Les colonnes non mappees (docs/posicoes-a-mapear.md) sont NULL : normal.')
_t.append('SELECT COUNT(*) AS lignes,')
for _c in sorted(set(c for blk in blocks for c in re.findall(r'AS (P1_[A-Z0-9_]+)', blk)))[:8]:
    _t.append('       COUNT(%s) AS %s,' % (_c, _c[:26]))
_t.append('       COUNT(CD_PERIMETRE) AS CD_PERIMETRE')
_t.append('  FROM ENG_CORP_P1_BIS;')
_t.append('')
_t.append('-- 6) Deux alimentations successives (comportement cible du ticket) :')
_t.append('--    chaque appel ne vide QUE son perimetre, l autre est conserve.')
_t.append('-- BEGIN pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS(v_entite, v_masysdate, ''NAT02''); END;')
_t.append('-- BEGIN pack_alim_tab_envoi_crrv4_new.P_ALIM_ENG_CORP_P1_BIS(v_entite, v_masysdate, ''HORS_NAT02''); END;')
_t.append('')
open('test_P_ALIM_ENG_CORP_P1_BIS.sql', 'w', encoding='utf-8').write(NL.join(_t) + NL)
print('script de teste -> test_P_ALIM_ENG_CORP_P1_BIS.sql')
