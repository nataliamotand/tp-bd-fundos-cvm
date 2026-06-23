# TP Banco de Dados — Fundos de Investimento (CVM)

Trabalho Prático da disciplina **DCC011 — Banco de Dados** (UFMG)
Departamento de Ciência da Computação — Prof. Pedro H. Barros

## Tema

Análise da indústria de fundos de investimento brasileira com base nos dados abertos da
Comissão de Valores Mobiliários (CVM). O projeto percorre o ciclo completo de um banco de dados:
Modelo ER → Modelo Relacional → SQL (DDL + carga) → Consultas e EDA.

## Pipeline

```
dados (CVM) → download_dados.py → data/raw/
            → notebooks/01_exploracao.ipynb      (entender os dados brutos)
            → notebooks/02_carga_ddl.ipynb        (DDL + carga no DuckDB)
            → notebooks/03_consultas_eda.ipynb    (consultas SQL + gráficos)
```

## Fontes de dados

| Base | Descrição | Portal |
|------|-----------|--------|
| `cad_fi.csv` | Cadastro de fundos — estrutura legada. Usado apenas na exploração inicial (notebook 01) para identificar a migração à RCVM175; não entra na carga final | dados.cvm.gov.br/dataset/fi-cad |
| `registro_fundo_classe.zip` | Cadastro de fundos, classes e subclasses — Resolução CVM 175 (contém `registro_fundo.csv`, `registro_classe.csv` e `registro_subclasse.csv`). Fonte usada na carga final | dados.cvm.gov.br/dados/FI/CAD/DADOS/ |
| `inf_diario_fi_2025MM.zip` | Informes diários de cada fundo (jan–dez 2025) | dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS/ |

## Estrutura do repositório

```
tp-bd-fundos-cvm/
├── data/
│   ├── raw/          # arquivos originais da CVM (não versionados)
│   └── processed/    # CSVs tratados
├── notebooks/
│   ├── 01_exploracao.ipynb     # exploração inicial dos dados brutos
│   ├── 02_carga_ddl.ipynb      # criação do schema e carga dos dados
│   └── 03_consultas_eda.ipynb  # consultas SQL e análise exploratória
├── sql/
│   ├── schema.sql              # DDL — CREATE TABLE com restrições
│   └── consultas.sql           # queries analíticas comentadas
├── docs/
│   ├── modelo_er.png           # diagrama ER/EER
│   └── modelo_relacional.md    # esquema relacional normalizado
├── download_dados.py   # script de download automático das bases
├── requirements.txt
└── README.md
```

## Como reproduzir

### 1. Clonar o repositório

```bash
git clone https://github.com/SEU_USUARIO/tp-bd-fundos-cvm.git
cd tp-bd-fundos-cvm
```

### 2. Instalar dependências

```bash
pip install -r requirements.txt
```

### 3. Baixar os dados

Execute o script de download automático a partir da raiz do projeto:

```bash
python download_dados.py
```

O script baixa todos os arquivos necessários direto do portal da CVM, extrai os CSVs dos arquivos `.zip` e os organiza em `data/raw/`. Se algum arquivo já existir, ele é pulado automaticamente.

Caso o download automático não funcione, os arquivos podem ser obtidos manualmente em `dados.cvm.gov.br/dados/FI/CAD/DADOS/`:

- `cad_fi.csv` — cadastro de fundos (estrutura legada)
- `registro_fundo_classe.zip` — cadastro de fundos, classes e subclasses (Resolução CVM 175); extrair os três CSVs internos
- `inf_diario_fi_202501.zip` até `inf_diario_fi_202512.zip` — disponíveis em `dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS/`

### 4. Executar os notebooks na ordem

```
notebooks/01_exploracao.ipynb
notebooks/02_carga_ddl.ipynb
notebooks/03_consultas_eda.ipynb
```

## Integrantes

Guilherme Lima
Natalia Mota
Ulisses Aurino
Vinicius Portugal

## Disciplina

DCC011 — Banco de Dados · DCC/UFMG · 2026/1