"""Leitura da Notice PACT, por pave, com as colunas achadas pelo cabecalho.

Porque nao se le pela letra da coluna: da V45.00 para a V45.02 as colunas
andaram uma casa (LONGUEUR passou de W para V). Quem filtra pela letra le a
coluna errada e nao da erro -- le outra coisa. Aqui procura-se sempre pelo
texto do cabecalho, que esta na linha 2.

Uso:
    from notice import carrega
    campos = carrega()['P1']        # lista, na ordem do N. de ordem tecnico
    campos[0]['ref'], campos[0]['len'], campos[0]['crea'], campos[0]['ult']

A V45.02 e a notice de referencia do SIRL-1222. Para ler outra, passar o nome:
    carrega('Notice PACTV4.5_v1.0.xlsx')
"""
import re

import openpyxl

V4502 = 'Notice PACTV4.5_Grande Clientèle_Corporate_V45.02.xlsx'

COLUNAS = {
    'ref':   'REFERENCE DE COLLECTE',
    'nome':  'NOM DE LA DONNEE',
    'len':   'LONGUEUR',
    'pos':   'POSITION',
    'crea':  'VERSION DE CREATION',
    'ult':   'VERSION DE DERNIERE APPARITION',
    'modif': 'VERSION DE MODIFICATION',
    'fmt':   'FORMAT',
    'ordem': "N° D'ORDRE",
    'usage': 'USAGE(S) DECLARE(S)',
}


def _pave(ref):
    """O pave a que o campo pertence. As referencias vem em tres formatos:
    'P1 21.65', '0.1 (P1)' (campos do inicio da linha) e 'CRRC H.ENREG'."""
    if ref.startswith('CRRC H'):
        return 'CABECALHO'
    if ref.startswith('CRRC F'):
        return 'RODAPE'
    m = re.match(r'([A-Z]\d+)\s', ref) or re.search(r'\(([A-Z]\d+)\)', ref)
    return m.group(1) if m else '?'


def carrega(ficheiro=V4502, aba='PACT Corp'):
    """{pave: [campo, ...]} na ordem do N. de ordem tecnico da notice."""
    ws = openpyxl.load_workbook(ficheiro, read_only=True, data_only=True)[aba]
    rows = list(ws.iter_rows(min_row=2, max_col=40, values_only=True))
    cab = [str(h).split('/')[0].strip().replace('\n', ' ').upper() if h else ''
           for h in rows[0]]
    ix = {}
    for nome, titulo in COLUNAS.items():
        achou = [i for i, h in enumerate(cab) if h.startswith(titulo)]
        if not achou:
            raise SystemExit('coluna nao encontrada na notice: %s' % titulo)
        ix[nome] = achou[0]
    out = {}
    for r in rows[1:]:
        ref = r[ix['ref']]
        if not ref:
            continue
        c = {k: r[i] for k, i in ix.items()}
        c['ref'] = str(ref).strip()
        c['nome'] = str(c['nome'] or '').strip()
        c['len'] = c['len'] if isinstance(c['len'], (int, float)) else 0
        for k in ('crea', 'ult', 'modif', 'fmt'):
            c[k] = str(c[k] or '').strip()
        c['filler'] = c['nome'].upper() == 'FILLER'
        c['novo_v45'] = c['crea'].startswith('45')
        c['obsoleto'] = c['ult'].upper() not in ('NA', '')
        out.setdefault(_pave(c['ref']), []).append(c)
    for pave in out:
        out[pave].sort(key=lambda c: c['ordem'] if isinstance(c['ordem'], (int, float)) else 1e9)
    return out


if __name__ == '__main__':
    d = carrega()
    print('%-10s %6s %6s %8s %8s %6s %6s' %
          ('pave', 'campos', 'soma', 'filler', 'sep', 'total', 'novos'))
    for p in ('CABECALHO', 'RODAPE', 'P1', 'P2', 'M1', 'C1', 'F1', 'F2', 'P9'):
        L = d.get(p, [])
        if not L:
            continue
        fim = L[-1]
        soma = sum(c['len'] for c in L if c is not fim)
        sep = len(L) - 1
        novos = sum(1 for c in L if c['novo_v45'])
        print('%-10s %6d %6d %8d %8d %6d %6d'
              % (p, len(L), soma, fim['len'], sep, soma + sep + fim['len'], novos))
