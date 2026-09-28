@echo off
rem Parte o CRRCORP_vPACT.dat por pave, um ficheiro por pave.
rem
rem SIRL-1222 - O PADRAO TEM 14 PONTOS, NAO 12
rem O CRRCORP_Split.bat de sempre procura "\<M............C1\>": doze
rem caracteres entre o M e o codigo do pave, que e a distancia do formato
rem POSICIONAL (M202609281715C1). Com os separadores do 1222 passam a ser
rem catorze (M;202609281719;C1), e o findstr nao acha nada: saem os sete
rem ficheiros VAZIOS, e sem erro nenhum. Medido: com doze, 0 octetos; com
rem catorze, as 1999 linhas C1 da amostra.
rem
rem Para o ficheiro antigo, sem ";", use o CRRCORP_Split.bat de sempre.

findstr "\<M..............C1\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_C1.txt
findstr "\<M..............F1\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_F1.txt
findstr "\<M..............F2\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_F2.txt
findstr "\<M..............M1\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_M1.txt
findstr "\<M..............P1\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_P1.txt
findstr "\<M..............P2\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_P2.txt
findstr "\<M..............P9\>" CRRCORP_vPACT.dat > CRRCORP_vPACT_P9.txt

Pause
