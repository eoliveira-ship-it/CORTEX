import re, json

def split_args(s):
    d=0; out=[]; cur=''
    for ch in s:
        if ch=='(': d+=1
        elif ch==')': d-=1
        if ch==',' and d==0: out.append(cur); cur=''; continue
        cur+=ch
    out.append(cur); return out

FN=re.compile(r'\b(pack_utilitaire\.[A-Za-z0-9_]+|RPAD|LPAD|TO_CHAR|NVL|SUBSTR|F_FORMAT_[A-Za-z0-9_]+)\s*\(', re.I)
BLANK=re.compile(r"^'\s*'$")
ZERO =re.compile(r"^'[+-]?0+([.,]0+)?'$")

def conv(t):
    out=''; i=0
    while i<len(t):
        m=FN.match(t,i)
        if m:
            fname=m.group(1); op=m.end()-1; d=0; j=op
            while j<len(t):
                if t[j]=='(': d+=1
                elif t[j]==')':
                    d-=1
                    if d==0: break
                j+=1
            inner=t[op+1:j]; args=split_args(inner)
            out+=handle(fname,args); i=j+1; continue
        out+=t[i]; i+=1
    return out

def handle(fname,args):
    f=fname.upper().replace('PACK_UTILITAIRE.','')
    a=[x.strip() for x in args]
    if f == 'SUBSTR':
        # SUBSTR sobre uma funcao de formato faz parte da FORMATACAO: o spool
        # corta a string ja formatada para caber no campo (ex.
        # Substr(F_FORMAT_TAUX(x),4,6) = 2 inteiros + 4 decimais). Retirar so
        # a funcao interna deixava um SUBSTR a fatiar digitos de um numero,
        # o que nao tem sentido: retiram-se os dois.
        if a and re.match(r'^(pack_utilitaire\.)?F_FORMAT_[A-Za-z0-9_]*\s*\(', a[0], re.I):
            interno = a[0][a[0].index('(') + 1:a[0].rindex(')')]
            return conv(interno)
        return 'SUBSTR(' + ', '.join(conv(x) for x in a) + ')'
    if f in ('RPAD','LPAD'):
        if not a: return 'NULL'
        if BLANK.match(a[0]): return 'NULL'
        return conv(a[0])
    if f=='TO_CHAR':
        if len(a)>1 and 'YYYYMMDD' in a[1].upper(): return conv(a[0])
        return 'TO_CHAR('+', '.join(conv(x) for x in a)+')'
    if f=='NVL':
        if len(a)<2: return conv(a[0])
        if BLANK.match(a[1]): return conv(a[0])          # default branco -> NULL
        return 'NVL(%s, %s)'%(conv(a[0]), conv(a[1]))
    if f.startswith('F_FORMAT'):
        return conv(a[0]) if a else 'NULL'
    return fname+'('+', '.join(conv(x) for x in a)+')'

SINAL=re.compile(r"'[+-]'\s*\|\|\s*")

def convert(expr):
    e=re.sub(r'\s+',' ',expr).strip().rstrip('|').strip()
    if not e: return 'NULL'
    r=conv(e).strip()
    r=re.sub(r'\s+',' ',r)
    # o sinal concatenado ('+'||valor) e formatacao, nao dado: quem o guarda
    # e o proprio NUMBER. Sem isto o valor ia para a coluna como texto.
    r=SINAL.sub('', r)
    if ZERO.match(r): return '0'
    # literal montante formatado dentro de CASE
    r=re.sub(r"'([+-]0{6,})'", '0', r)
    return r

if __name__=='__main__':
    tests=["RPAD(' ', 185)",
     "RPAD(NVL(C_ENR.CD_METH_IFRS9_PD_ORIG,' '), 20)",
     "RPAD(nvl(C_enr.NOTE_FIN_RET_ORI, 'ND'),2)",
     "pack_utilitaire.F_FORMAT_MONTANT_BIS2(C_ENR.MNT_CONTRAT_ORIGINE)",
     "RPAD(NVL(TO_CHAR(C_ENR.dt_exigte_prem_impy, 'YYYYMMDD'), ' '), 8)",
     "CASE WHEN C_ENR.CD_TYPE_RISQUE='TRE201' THEN '+0000000000000000' ELSE RPAD (' ', 22) END",
     "CASE WHEN C_ENR.MNT_VTR IS null THEN RPAD (' ', 19) ELSE pack_utilitaire.f_format_montant_bis2(C_ENR.MNT_VTR) END",
     "Case when C_ENR.CD_TYPE_RISQUE = 'TRE502' then pack_utilitaire.f_format_montant_bis2(nvl(C_ENR.MNT_LOYER,0)) else RPAD(' ',19) end",
     "RPAD('EUR', 3)","RPAD ('+', 1)","NVL(C_ENR.TOP_ENG,'B')",
     "to_char(C_ENR.dt_arrete, 'YYYYMMDD')",
     "RPAD(C_ENR.ID_ENGAGEMENT || '_C',40)"]
    for t in tests: print('%-62s => %s'%(t[:60], convert(t)))
