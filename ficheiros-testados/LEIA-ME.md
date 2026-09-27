# Ficheiros testados

Os ficheiros gerados no DEV2 que serviram de prova aos três chamados. O DEV2
está travado no arrêté **20250531**, por isso os dados são sempre os mesmos e
duas corridas só diferem no horodatage e no número de envio.

---

## O que está aqui

| ficheiro | corrida | o que prova |
|---|---|---|
| `CRRCORP_vPACT.7z.001` + `.002` | **00025**, 27/09 17:12 | o Corporate final: 554 045 linhas, os sete pavés com `;`, e o `TRANSLATE` |
| `CRRADAP.dat` | 28/09 00:20 | o Adapté final: 1 777 linhas, 14/90/8/2 `;` |
| `CRRCORP_P1.7z` | SIRL-1224 | o oráculo da régua V44 — foi contra ele que se validaram as posições de cada campo |

O `.7z.001` e o `.002` são **um arquivo partido em dois**, não dois arquivos.
Para juntar e extrair:

```bash
cat CRRCORP_vPACT.7z.001 CRRCORP_vPACT.7z.002 > junto.7z
python -c "import py7zr; py7zr.SevenZipFile('junto.7z').extractall('.')"
```

---

## Como usar

### O Corporate

```bash
python comparar_1222.py CRRCORP_vPACT.dat <a referencia de 22/09, sem ';'>
```

Reconstrói cada linha no formato antigo — campos colados, cada um na largura da
Notice — e compara. Esperado: `P1 IDENTICO 122225` e nenhuma linha só de um lado
nos outros seis pavés.

### O Adapté

```bash
python comparar_adap.py CRRADAP.dat <a referencia de 22/09, sem ';'>
```

Esperado:

```
ENTETE  ";" {14}   A1  ";" {90}   Z9  ";" {8}   ENQUEUE  ";" {2}
todas as larguras batem com a notice
IDENTICAS: a unica mudanca e o ";".
erros: 0
```

---

## A referência

A referência de 22/09 — o ficheiro **antes** dos separadores — **não está
aqui**. Foi tirada na limpeza de 28/09 para não duplicar centenas de MB. Está
no histórico do git:

```bash
git log --oneline --all -- CRRCORP_vPACT_PT1.7z
git show <commit>:CRRCORP_vPACT_PT1.7z > CRRCORP_vPACT_PT1.7z
```

Ou gera-se outra vez, correndo o spool anterior no DEV2 — os dados não mudam.

---

## Porque é que estes ficheiros ficam guardados

Sem o ficheiro **de antes**, não há prova nenhuma: um ficheiro com o tamanho
certo e os campos no sítio errado passa em qualquer verificação de formato. A
prova dos três chamados é sempre a mesma ideia — **desfazer a mudança e ver se
volta ao original** — e para isso é preciso ter os dois lados.
