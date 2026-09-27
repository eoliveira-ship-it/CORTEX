# -*- coding: utf-8 -*-
"""Monta as pastas de entrega a partir dos ficheiros da raiz.

    python montar_entrega.py

Copia os ficheiros de cada chamado para chamados/SIRL-xxxx/ e a versao final de
todos para chamados/final/. Os .md dessas pastas sao escritos a mao e nao se
tocam.

PORQUE E QUE ISTO E UM SCRIPT E NAO UMA COPIA A MAO
---------------------------------------------------
As pastas de entrega sao copias. Uma copia feita a mao diverge do original na
primeira vez que se regenera um spool, e ninguem repara -- entrega-se a versao
velha. Aqui a raiz e a unica fonte de verdade: correr este script poe as pastas
outra vez de acordo, e o --conferir diz se alguma divergiu sem copiar nada.

NA RAIZ E QUE SE TRABALHA
-------------------------
Os geradores (gen_spool_1222.py, gen_spool_adap.py, ...) leem e escrevem na
raiz, pelo nome. Nao correm dentro das pastas de entrega.

O QUE VAI EM CADA PASTA
-----------------------
Um ficheiro pode aparecer em mais do que um chamado quando os dois lhe mexeram:
o 030_spool_Extract_CRRCORP_vPACT.sql nasce no 1224 e leva o alargamento do
1223. Em final/ vai sempre a versao com tudo empilhado.
"""
import filecmp
import io
import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.abspath(__file__))
ENTREGA = os.path.join(RAIZ, 'chamados')

# {pasta: [(ficheiro na raiz, nome na pasta)]}
PLANO = {
    'SIRL-1224': [
        ('ENG_CORP_P1_BIS.sql', None),
        ('pack_alim_tab_envoi_crrv4.sql', None),
        ('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', None),
        ('030_spool_Extract_CRRCORP_vPACT.sql', None),
        ('030_CREATION_SPOOL_CRRCORP_vPACT.sh', None),
        ('run_procedure.sql', None),
        ('TESTES.sql', None),
    ],
    'SIRL-1223': [
        ('030_spool_Extract_CRRCORP_vPACT.sql', None),
        ('PACK_UTL_FILE_ENVOI_C3RD2.sql', None),
        ('VALIDAR_1223_P3.sql', None),
    ],
    'SIRL-1222': [
        ('030_spool_Extract_CRRCORP_1222.sql', None),
        ('030_spool_Extract_CRRADAP_1222.sql', None),
        ('030_CREATION_SPOOL_CRRADAP_1222.sh', None),
        ('comparar_ficheiros.sh', None),
    ],
    # A versao final: o nome de destino e o nome COM QUE O FICHEIRO FICA NO
    # SERVIDOR. E por isso que o _1222 desaparece aqui -- o shell chama o spool
    # pelo nome fixo, e um ficheiro deixado ao lado com outro nome nunca e lido.
    'final': [
        ('ENG_CORP_P1_BIS.sql', None),
        ('pack_alim_tab_envoi_crrv4.sql', None),
        ('030_spool_Extract_CRRCORP_1222.sql', '030_spool_Extract_CRRCORP_vPACT.sql'),
        ('030_CREATION_SPOOL_CRRCORP_vPACT.sh', None),
        ('030_spool_Extract_CRRADAP_1222.sql', '030_spool_Extract_CRRADAP.sql'),
        ('030_CREATION_SPOOL_CRRADAP_1222.sh', '030_CREATION_SPOOL_CRRADAP.sh'),
        ('PACK_UTL_FILE_ENVOI_C3RD2.sql', None),
        ('run_procedure.sql', None),
        ('TESTES.sql', None),
    ],
}


def pares():
    for pasta, fs in PLANO.items():
        for origem, destino in fs:
            yield (pasta, os.path.join(RAIZ, origem),
                   os.path.join(ENTREGA, pasta, destino or origem))


def main(conferir=False):
    faltam, diferentes, copiados = [], [], 0
    for pasta, o, d in pares():
        if not os.path.exists(o):
            faltam.append(o)
            continue
        if conferir:
            if not os.path.exists(d) or not filecmp.cmp(o, d, shallow=False):
                diferentes.append(os.path.relpath(d, RAIZ))
            continue
        os.makedirs(os.path.dirname(d), exist_ok=True)
        shutil.copy2(o, d)
        copiados += 1
    if faltam:
        for f in faltam:
            print('  FALTA na raiz: %s' % os.path.relpath(f, RAIZ))
        return 2
    if conferir:
        if diferentes:
            print('desactualizados (%d):' % len(diferentes))
            for f in diferentes:
                print('   ', f)
            print('corre:  python montar_entrega.py')
            return 1
        print('as pastas de entrega estao iguais a raiz')
        return 0
    for pasta in sorted(PLANO):
        n = len(PLANO[pasta])
        print('  chamados/%-10s %d ficheiros' % (pasta + '/', n))
    print('copiados: %d' % copiados)
    return 0


if __name__ == '__main__':
    sys.exit(main('--conferir' in sys.argv))
