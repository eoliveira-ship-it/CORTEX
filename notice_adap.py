"""Leitura da Notice do PACT Adapte (o CRRADAP), a regua dos 2000 octetos.

A aba tem as mesmas colunas da Notice do Corporate -- procuradas pelo texto do
cabecalho, como no notice.py -- mas o agrupamento tem de ser outro: no Adapte
os campos do cabecalho, do detalhe e do rodape levam todos a referencia 'A1',
e o notice.carrega mete-os no mesmo saco (15 + 91 + 3 = 109 campos). Aqui
separam-se em quatro registos:

    ENTETE    15 campos    1986 +  14 ';' = 2000
    A1        91 campos    1910 +  90 ';' = 2000     <- a linha de detalhe
    Z9         9 campos    1992 +   8 ';' = 2000     <- o contador de registos
    ENQUEUE    3 campos    1998 +   2 ';' = 2000

Os 90 separadores do detalhe sao os que a SFG e o ticket SIRL-1222 anunciam
para o PACT Adapte, e as somas foram conferidas contra o CRRADAP.dat real:
todos os campos com valor caem na posicao que a notice lhes da.

O filler final (A1 99.99) vem da notice com 929. No ficheiro de hoje, sem
';', ocupa 1019 = 929 + 90: encolhe exatamente o numero de separadores, como
no Corporate.

Uso:
    from notice_adap import carrega
    r = carrega()
    r['A1'][0]['ref'], r['A1'][0]['len'], r['A1'][0]['fmt']
"""
import glob

import notice

ABA = 'A1 Alimentation Adaptée'
LINHA = 2000

# As colunas de mapeamento, que a notice do Corporate nao tem. So estao
# preenchidas nos 18 campos que a V45 mexe: 12 'Ne pas alimenter', 5 vindos do
# ficheiro da MERCA (tabela A1_DEGRADE_GMBH) e o A1 500, em clarificacao.
MAPEAMENTO = {
    'prov': 'PROVENANCE',
    'tab':  'TABLE DDR',
    'rg':   'RG',
    'com':  'COMMENTAIRE',
}


def ficheiro():
    """A notice do Adapte que esta no repositorio."""
    f = glob.glob('Notice PACTV4.5_Adapt*mapping.xlsx')
    if not f:
        raise SystemExit('notice do Adapte nao encontrada no diretorio atual')
    return f[0]


def _registo(ref):
    if ref.startswith('A1 H.'):
        return 'ENTETE'
    if ref.startswith('A1 F.'):
        return 'ENQUEUE'
    if ref.startswith('Z9 ') or '(Z9)' in ref:
        return 'Z9'
    return 'A1'


def carrega(f=None, aba=ABA):
    """{registo: [campo, ...]} na ordem do N. de ordem tecnico da notice."""
    bruto = notice.carrega(f or ficheiro(), aba)
    out = {}
    for cs in bruto.values():
        for c in cs:
            # a linha 3 da aba e a descricao das colunas, nao um campo: nao
            # tem numero de ordem
            if not isinstance(c['ordem'], (int, float)):
                continue
            out.setdefault(_registo(c['ref']), []).append(c)
    for r in out:
        out[r].sort(key=lambda c: c['ordem'])
    return out


if __name__ == '__main__':
    d = carrega()
    print('%-8s %6s %6s %8s %6s %6s' %
          ('registo', 'campos', 'soma', 'sep', 'total', 'novos'))
    for r in ('ENTETE', 'A1', 'Z9', 'ENQUEUE'):
        L = d[r]
        soma = sum(c['len'] for c in L)
        sep = len(L) - 1
        novos = sum(1 for c in L if c['novo_v45'])
        print('%-8s %6d %6d %8d %6d %6d%s'
              % (r, len(L), soma, sep, soma + sep, novos,
                 '' if soma + sep == LINHA else '   NAO DA 2000!'))
