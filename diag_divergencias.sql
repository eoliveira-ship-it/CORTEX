-- Valor da TABELA vs valor do FICHEIRO, para as colunas divergentes.
-- Engajamento analisado: 214530BN0_C
--
-- Como ler:
--   valores parecidos mas diferentes -> os dados mudaram (outra fotografia)
--   valor de um campo COMPLETAMENTE outro -> mapeamento errado
--   mesmo numero com virgula noutro sitio -> escala errada
SET LINESIZE 200
COLUMN coluna      FORMAT A12
COLUMN no_ficheiro FORMAT A22
COLUMN na_tabela   FORMAT A22
COLUMN descricao   FORMAT A40

-- 0) A fotografia e a mesma? (no ficheiro: 20250630)
SELECT TO_CHAR(P1_H_0_1,'YYYYMMDD') AS arrete_na_tabela, COUNT(*) AS linhas
  FROM ENG_CORP_P1_BIS GROUP BY TO_CHAR(P1_H_0_1,'YYYYMMDD') ORDER BY 1;

-- 1) Valores lado a lado
  SELECT 'P1_H_0_1    ' AS coluna, '20250630' AS no_ficheiro,
         TO_CHAR(P1_H_0_1) AS na_tabela, 'Date darrêté' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_1_2      ' AS coluna, '07' AS no_ficheiro,
         TO_CHAR(P1_1_2) AS na_tabela, 'Traitement moteur bâlois' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_4_9      ' AS coluna, '+000000000001840388' AS no_ficheiro,
         TO_CHAR(P1_4_9) AS na_tabela, 'Montant du capital restant dû' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_4_31     ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_4_31) AS na_tabela, 'Indicateur Produit à sous-jacent' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_3_20     ' AS coluna, '029698' AS no_ficheiro,
         TO_CHAR(P1_3_20) AS na_tabela, 'Maturité résiduelle' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_3_3      ' AS coluna, '20250630' AS no_ficheiro,
         TO_CHAR(P1_3_3) AS na_tabela, 'Date de valeur de prise deffet du con' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_4_29     ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_4_29) AS na_tabela, 'Indicateur créance titrisée' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_54    ' AS coluna, '044102018101820230720FR' AS no_ficheiro,
         TO_CHAR(P1_22_54) AS na_tabela, 'Grille Modèle de notation à lorigine' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_23    ' AS coluna, '+000000000' AS no_ficheiro,
         TO_CHAR(P1_22_23) AS na_tabela, 'Taux plafond' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_24    ' AS coluna, '+000000000' AS no_ficheiro,
         TO_CHAR(P1_22_24) AS na_tabela, 'Taux plancher' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_28    ' AS coluna, '+000000000' AS no_ficheiro,
         TO_CHAR(P1_22_28) AS na_tabela, 'Taux de marge additive' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_29    ' AS coluna, '+000000000' AS no_ficheiro,
         TO_CHAR(P1_22_29) AS na_tabela, 'Taux de marge multiplicative' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_34    ' AS coluna, '+000000000001815589' AS no_ficheiro,
         TO_CHAR(P1_22_34) AS na_tabela, 'Montant du capital théorique restant d' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_70    ' AS coluna, '00000' AS no_ficheiro,
         TO_CHAR(P1_22_70) AS na_tabela, 'Nombre de jours de retard de paiement' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_30_22    ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_30_22) AS na_tabela, 'Référence du contrat cadre' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_30_24    ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_30_24) AS na_tabela, 'Référence du contrat de netting contra' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_31_5     ' AS coluna, 'N' AS no_ficheiro,
         TO_CHAR(P1_31_5) AS na_tabela, 'Indicateur responsabilité solidaire' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_31_17    ' AS coluna, '+0006' AS no_ficheiro,
         TO_CHAR(P1_31_17) AS na_tabela, 'Durée initiale du prêt' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_31_18    ' AS coluna, '+0006' AS no_ficheiro,
         TO_CHAR(P1_31_18) AS na_tabela, 'Durée totale du prêt à date' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_21_43    ' AS coluna, '0' AS no_ficheiro,
         TO_CHAR(P1_21_43) AS na_tabela, 'Ratio prudentiel dExposition/valeur (' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_21_55    ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_21_55) AS na_tabela, 'NATure dOpération de lengagement pou' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_26_1     ' AS coluna, '1' AS no_ficheiro,
         TO_CHAR(P1_26_1) AS na_tabela, 'Indicateur mobilisation de lactif' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_11    ' AS coluna, 'N' AS no_ficheiro,
         TO_CHAR(P1_22_11) AS na_tabela, 'Indicateur éligibilité de lactif à un' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_26_3     ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_26_3) AS na_tabela, 'Référence de mobilisation de lactif' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_26_4     ' AS coluna, ' ' AS no_ficheiro,
         TO_CHAR(P1_26_4) AS na_tabela, 'Code organisme de mobilisation' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C'
  UNION ALL
  SELECT 'P1_22_60    ' AS coluna, '+000000000000000000' AS no_ficheiro,
         TO_CHAR(P1_22_60) AS na_tabela, 'Montant de léchéance en cours' AS descricao
    FROM ENG_CORP_P1_BIS WHERE P1_H_1_11 = '214530BN0_C';
