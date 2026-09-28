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
import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.abspath(__file__))
ENTREGA = os.path.join(RAIZ, 'chamados')

# {pasta: [(ficheiro na raiz, nome na pasta)]}
#
# O NOME DE DESTINO E O NOME NO SERVIDOR
# Os sufixos _1222, _1223, _1224 sao nomes de repositorio: dizem de que chamado
# vem a alteracao e distinguem o ficheiro gerado da base de PRODUCAO com que
# convive na raiz. No servidor todos eles instalam-se com o nome de producao.
#
# TODO O FICHEIRO COM SUFIXO SAI DE UM GERADOR
#   gen_pack_1224.py       pack_alim_tab_envoi_crrv4_1224.sql
#   gen_chamada_vpact.py   os dois shells que passam a chamar o _vPACT
#   gen_spool_vpact.py     030_spool_Extract_CRRCORP_vPACT.sql
#   gen_spool_1222.py      030_spool_Extract_CRRCORP_1222.sql
#   gen_spool_adap.py      030_spool_Extract_CRRADAP_vPACT.sql
#   gen_shell_adap.py      030_CREATION_SPOOL_CRRADAP_vPACT.sh
#   gen_p3_1223.py         PACK_UTL_FILE_ENVOI_C3RD2_1223.sql
# Cada um parte de um ficheiro de producao e PARA se a ancora que procura nao
# estiver exactamente uma vez. Nenhuma alteracao vive num ficheiro editado a
# mao: e por nao ser assim que o SIRL-1223 esteve aplicado a uma copia do
# package do P3 atrasada em relacao a producao, a desfazer o SIRL-667.
PLANO = {
    'SIRL-1224': [
        ('ENG_CORP_P1_BIS.sql', None),
        ('pack_alim_tab_envoi_crrv4_1224.sql', 'pack_alim_tab_envoi_crrv4.sql'),
        ('pack_alim_tab_envoi_crrv4.sql', 'pack_alim_tab_envoi_crrv4_PROD.sql'),
        ('pack_alim_tab_envoi_crrv4_P_ALIM_ENG_CORP_P1_BIS.sql', None),
        ('030_spool_Extract_CRRCORP_vPACT.sql', None),
        ('030_CREATION_SPOOL_CRRCORP_vPACT.sh', None),
        ('030_CREATION_SPOOL_CRRCORP_1224.sh', '030_CREATION_SPOOL_CRRCORP.sh'),
        ('run_procedure.sql', None),
        ('TESTES.sql', None),
    ],
    'SIRL-1223': [
        ('030_spool_Extract_CRRCORP_vPACT.sql', None),
        # o nome de destino e o de producao: o gerado substitui o package
        ('PACK_UTL_FILE_ENVOI_C3RD2_1223.sql', 'PACK_UTL_FILE_ENVOI_C3RD2.sql'),
        ('PACK_UTL_FILE_ENVOI_C3RD2_PROD.sql', None),
        ('VALIDAR_1223_P3.sql', None),
    ],
    'SIRL-1222': [
        ('030_spool_Extract_CRRCORP_1222.sql', '030_spool_Extract_CRRCORP_vPACT.sql'),
        ('030_spool_Extract_CRRADAP_vPACT.sql', None),
        ('030_CREATION_SPOOL_CRRADAP_vPACT.sh', None),
        ('030_CREATION_SPOOL_CRRADAP_1222.sh', '030_CREATION_SPOOL_CRRADAP.sh'),
        ('comparar_ficheiros.sh', None),
    ],
    # A versao final: o nome de destino e o nome COM QUE O FICHEIRO FICA NO
    # SERVIDOR.
    #
    # OS DOIS FLUXOS NOVOS CORREM AO LADO DOS ANTIGOS
    # Nem o CRRCORP nem o CRRADAP substituem o spool antigo. O shell antigo
    # continua a escrever o ficheiro oficial e, no fim, chama o _vPACT, que
    # escreve o seu (CRRCORP_vPACT.dat / CRRADAP_vPACT.dat) a partir do seu
    # proprio spool. Por isso vao os DOIS shells de cada fluxo: o antigo leva a
    # chamada, e sem ele o novo nunca corre.
    #
    # O unico nome que muda e o do spool do Corporate: o _1222 e nome de
    # repositorio, e o que o 030_CREATION_SPOOL_CRRCORP_vPACT.sh chama e o
    # 030_spool_Extract_CRRCORP_vPACT.sql. Um ficheiro deixado ao lado com outro
    # nome nunca e lido -- e nao da erro.
    'final': [
        ('ENG_CORP_P1_BIS.sql', None),
        ('pack_alim_tab_envoi_crrv4_1224.sql', 'pack_alim_tab_envoi_crrv4.sql'),
        ('030_spool_Extract_CRRCORP_1222.sql', '030_spool_Extract_CRRCORP_vPACT.sql'),
        ('030_CREATION_SPOOL_CRRCORP_vPACT.sh', None),
        ('030_CREATION_SPOOL_CRRCORP_1224.sh', '030_CREATION_SPOOL_CRRCORP.sh'),
        ('030_spool_Extract_CRRADAP_vPACT.sql', None),
        ('030_CREATION_SPOOL_CRRADAP_vPACT.sh', None),
        ('030_CREATION_SPOOL_CRRADAP_1222.sh', '030_CREATION_SPOOL_CRRADAP.sh'),
        ('PACK_UTL_FILE_ENVOI_C3RD2_1223.sql', 'PACK_UTL_FILE_ENVOI_C3RD2.sql'),
        ('run_procedure.sql', None),
        ('TESTES.sql', None),
    ],
}


def pares():
    for pasta, fs in PLANO.items():
        for origem, destino in fs:
            yield (pasta, os.path.join(RAIZ, origem),
                   os.path.join(ENTREGA, pasta, destino or origem))


def orfaos():
    """Ficheiros nas pastas de entrega que o PLANO ja nao preve.

    Um ficheiro entregue com o nome antigo nao da erro nenhum: fica ao lado do
    certo, e quem instalar copia os dois. Foi o que aconteceu ao spool do
    Adapte, que passou a correr em paralelo e deixou la o nome com que
    substituia o original.
    """
    previsto = {}
    for pasta, _, d in pares():
        previsto.setdefault(pasta, set()).add(os.path.basename(d))
    fora = []
    for pasta, nomes in previsto.items():
        dir_ = os.path.join(ENTREGA, pasta)
        if not os.path.isdir(dir_):
            continue
        for f in sorted(os.listdir(dir_)):
            if f not in nomes and not f.endswith('.md'):
                fora.append(os.path.relpath(os.path.join(dir_, f), RAIZ))
    return fora


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
    fora = orfaos()
    if fora:
        print('a mais nas pastas de entrega (%d): o PLANO ja nao os preve' % len(fora))
        for f in fora:
            print('    git rm %s' % f)
        if conferir:
            return 1
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
