# Questão sobre o filler do pavé P1 — Notice PACT V4.5 Corporate V45.02

Ficheiro para enviar à DSID. Versão em português e em francês.
SIRL-1222 (separador `;`). Levantado em 2026-09-23.

---

## Português (pt-BR)

**Assunto: Notice PACT V4.5 Corporate V45.02 — o filler do P1 não fecha em 8000**

Na Notice V45.02, a coluna LONGUEUR do campo de preenchimento (`99.99`) de cada
pavé aparece preenchida, o que não acontecia na V45.00. Verificámos que esses
valores já contam os separadores `;`: para cada registo, a soma dos campos, mais
um separador entre cada dois campos, mais o filler final, dá exatamente 8000
caracteres.

Isso confirma-se em todos os registos do ficheiro CRRCORP:

| Registo | Campos | Soma dos campos | Separadores | Filler `99.99` | Total |
|---|---|---|---|---|---|
| Cabeçalho (`CRRC H`) | 15 | 100 | 14 | 7886 | **8000** |
| Rodapé (`CRRC F`) | 3 | 12 | 2 | 7986 | **8000** |
| P2 | 398 | 3585 | 397 | 4018 | **8000** |
| M1 | 158 | 1806 | 157 | 6037 | **8000** |
| C1 | 98 | 988 | 97 | 6915 | **8000** |
| F1 | 73 | 830 | 72 | 7098 | **8000** |
| F2 | 46 | 543 | 45 | 7412 | **8000** |
| P9 | 39 | 487 | 38 | 7475 | **8000** |
| **P1** | **663** | **6162** | **662** | **1185** | **8009** |

O P1 é o único que não fecha: dá **8009**, ou seja, 9 caracteres a mais.

A diferença corresponde exatamente ao campo **`P1 621` — Intention de gestion de
l'opération** (ALPHA/8), criado na versão 45.01: são os 8 caracteres do campo
mais o separador que ele acrescenta. Tudo indica que, ao acrescentar esse campo,
o filler do P1 não foi recalculado. Sem o `P1 621`, o P1 dá 8000 exatos.

**Pergunta:** qual das duas é a correta?

1. O filler do P1 (`P1 99.99`) passa de **1185 para 1176**, e a linha do P1
   continua com 8000 caracteres, como todos os outros registos; ou
2. a linha do P1 passa a ter **8009 caracteres**, ficando diferente dos restantes
   registos do mesmo ficheiro.

A nossa leitura é que se trata da primeira: o filler deve passar para 1176.
Pedimos confirmação, porque o valor entra diretamente na construção do ficheiro.

---

## Français

**Objet : Notice PACT V4.5 Corporate V45.02 — le filler du pavé P1 ne totalise
pas 8000**

Dans la notice V45.02, la colonne LONGUEUR du champ de remplissage (`99.99`) de
chaque pavé est renseignée, ce qui n'était pas le cas en V45.00. Nous avons
constaté que ces valeurs tiennent déjà compte des séparateurs `;` : pour chaque
enregistrement, la somme des champs, plus un séparateur entre chaque paire de
champs, plus le filler final, donne exactement 8000 caractères.

Cela se vérifie sur tous les enregistrements du fichier CRRCORP :

| Enregistrement | Champs | Somme des champs | Séparateurs | Filler `99.99` | Total |
|---|---|---|---|---|---|
| En-tête (`CRRC H`) | 15 | 100 | 14 | 7886 | **8000** |
| En-queue (`CRRC F`) | 3 | 12 | 2 | 7986 | **8000** |
| P2 | 398 | 3585 | 397 | 4018 | **8000** |
| M1 | 158 | 1806 | 157 | 6037 | **8000** |
| C1 | 98 | 988 | 97 | 6915 | **8000** |
| F1 | 73 | 830 | 72 | 7098 | **8000** |
| F2 | 46 | 543 | 45 | 7412 | **8000** |
| P9 | 39 | 487 | 38 | 7475 | **8000** |
| **P1** | **663** | **6162** | **662** | **1185** | **8009** |

Le P1 est le seul à ne pas tomber juste : il totalise **8009**, soit 9 caractères
de trop.

L'écart correspond exactement au champ **`P1 621` — Intention de gestion de
l'opération** (ALPHA/8), créé en version 45.01 : les 8 caractères du champ plus
le séparateur qu'il ajoute. Il semble donc que le filler du P1 n'ait pas été
recalculé lors de l'ajout de ce champ. Sans le `P1 621`, le P1 totalise
exactement 8000.

**Question :** laquelle des deux options est la bonne ?

1. Le filler du P1 (`P1 99.99`) passe de **1185 à 1176**, et la ligne P1 conserve
   8000 caractères, comme tous les autres enregistrements ; ou
2. la ligne P1 passe à **8009 caractères**, et diffère donc des autres
   enregistrements du même fichier.

Notre lecture est qu'il s'agit de la première : le filler doit passer à 1176.
Nous vous demandons confirmation, cette valeur étant directement utilisée dans la
construction du fichier.
