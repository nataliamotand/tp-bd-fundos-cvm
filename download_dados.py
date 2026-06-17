"""
download_dados.py
-----------------
Baixa os arquivos de fundos de investimento da CVM e os organiza em data/raw/.

Como usar:
    python download_dados.py

Arquivos baixados:
    - cad_fi.csv              (cadastro de fundos — estrutura legada)
    - registro_fundo_classe.zip  
        - registro_fundo.csv      (todos os fundos)
        - registro_classe.csv     (classes de cotas adaptadas )
        - registro_subclasse.csv  (subclasses de cotas adaptadas)
    - inf_diario_fi_202501.zip ... 202512.zip  (informes diários 2025)
    - Extrai os CSVs de cada .zip automaticamente

Requisitos:
    pip install requests tqdm
"""

import os
import zipfile
import requests
from tqdm import tqdm
from pathlib import Path

# ── Configurações ────────────────────────────────────────────────────────────

RAW_DIR = Path("data/raw")
RAW_DIR.mkdir(parents=True, exist_ok=True)

BASE_INF  = "https://dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS"
BASE_CAD  = "https://dados.cvm.gov.br/dados/FI/CAD/DADOS"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; tp-bd-ufmg/1.0; "
        "+https://github.com/tp-bd-fundos-cvm)"
    )
}

MESES_2025 = [f"2025{m:02d}" for m in range(1, 13)]

# ── Funções auxiliares ───────────────────────────────────────────────────────

def download_arquivo(url: str, destino: Path) -> bool:
    """Baixa um arquivo com barra de progresso. Retorna True se bem-sucedido."""
    if destino.exists():
        print(f"  [ok] já existe: {destino.name} — pulando")
        return True

    try:
        resp = requests.get(url, headers=HEADERS, stream=True, timeout=60)
        resp.raise_for_status()

        tamanho = int(resp.headers.get("content-length", 0))

        with open(destino, "wb") as f, tqdm(
            desc=f"  {destino.name}",
            total=tamanho,
            unit="B",
            unit_scale=True,
            unit_divisor=1024,
            leave=True,
        ) as barra:
            for chunk in resp.iter_content(chunk_size=8192):
                f.write(chunk)
                barra.update(len(chunk))

        return True

    except requests.HTTPError as e:
        print(f"  [erro] {url} → {e}")
        if destino.exists():
            destino.unlink()
        return False

    except Exception as e:
        print(f"  [erro inesperado] {url} → {e}")
        if destino.exists():
            destino.unlink()
        return False


def extrair_zip(zip_path: Path) -> None:
    """Extrai o CSV de dentro do .zip na mesma pasta."""
    csvs_extraidos = list(zip_path.parent.glob(zip_path.stem + "*.csv"))
    if csvs_extraidos:
        print(f"  [ok] já extraído: {csvs_extraidos[0].name} — pulando")
        return

    with zipfile.ZipFile(zip_path, "r") as z:
        for nome in z.namelist():
            if nome.endswith(".csv"):
                z.extract(nome, zip_path.parent)
                print(f"  [extraído] {nome}")


# ── Download principal ───────────────────────────────────────────────────────

def main():
    erros = []

    # 1. Cadastro de fundos
    print("\n=== Cadastro de Fundos ===")
    url_cad  = f"{BASE_CAD}/cad_fi.csv"
    dest_cad = RAW_DIR / "cad_fi.csv"
    if not download_arquivo(url_cad, dest_cad):
        erros.append(url_cad)

    # 2. Cadastro de classes e subclasses
    print("\n=== Cadastro de Classes e Subclasses (Resolução CVM 175) ===")
    url_reg  = f"{BASE_CAD}/registro_fundo_classe.zip"
    dest_reg = RAW_DIR / "registro_fundo_classe.zip"
    ok = download_arquivo(url_reg, dest_reg)
    if ok:
        extrair_zip(dest_reg)
    else:
        erros.append(url_reg)

    # 3. Informes diários 2025
    print("\n=== Informes Diários 2025 ===")
    for mes in MESES_2025:
        nome_zip = f"inf_diario_fi_{mes}.zip"
        url_zip  = f"{BASE_INF}/{nome_zip}"
        dest_zip = RAW_DIR / nome_zip

        ok = download_arquivo(url_zip, dest_zip)
        if ok:
            extrair_zip(dest_zip)
        else:
            erros.append(url_zip)

    # 4. Resumo
    print("\n=== Resumo ===")
    csvs     = list(RAW_DIR.glob("*.csv"))
    zips     = list(RAW_DIR.glob("*.zip"))
    print(f"  Arquivos CSV em data/raw/: {len(csvs)}")
    print(f"  Arquivos ZIP em data/raw/: {len(zips)}")

    if erros:
        print(f"\n  [atenção] {len(erros)} arquivo(s) não baixado(s):")
        for e in erros:
            print(f"    - {e}")
        print("\n  Tente baixá-los manualmente pelo portal dados.cvm.gov.br")
    else:
        print("\n  Todos os arquivos baixados com sucesso.")
        print("  Próximo passo: abrir notebooks/01_exploracao.ipynb")


if __name__ == "__main__":
    main()