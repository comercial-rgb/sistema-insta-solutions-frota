# diagnostico.py — Rode PRIMEIRO para validar a estrutura dos PDFs
# Uso: python diagnostico.py

import pdfplumber
import os

CATALOGOS = [
    ("pdf controil-bra.pdf",  "CONTROIL"),
    ("pdf lonaflex-bra.pdf",  "LONAFLEX"),
    ("pdf_frasle-bra.pdf",    "FRASLE"),
    ("pdf fremax-bra.pdf",    "FREMAX"),
    ("pdf nakata-bra.pdf",    "NAKATA"),
]

def diagnosticar(arquivo, fornecedor, paginas_teste=[3, 4, 5, 10, 50]):
    if not os.path.exists(arquivo):
        print(f"\n  ARQUIVO NAO ENCONTRADO: {arquivo}")
        return

    print(f"\n{'='*60}")
    print(f"DIAGNOSTICO: {fornecedor} — {arquivo}")
    print(f"{'='*60}")

    with pdfplumber.open(arquivo) as pdf:
        print(f"Total de paginas: {len(pdf.pages)}")

        for num in paginas_teste:
            if num > len(pdf.pages):
                continue
            pg = pdf.pages[num - 1]
            print(f"\n--- PAGINA {num} ---")
            tabelas = pg.extract_tables()
            if tabelas:
                for t_idx, tabela in enumerate(tabelas):
                    print(f"  Tabela {t_idx+1} — {len(tabela)} linhas")
                    for l_idx, linha in enumerate(tabela[:8]):
                        print(f"    [{l_idx}] {linha}")
            else:
                txt = pg.extract_text()
                print(f"  Sem tabela. Texto: {txt[:400] if txt else 'Vazio'}")


if __name__ == "__main__":
    pasta = os.path.dirname(os.path.abspath(__file__))
    os.chdir(pasta)

    print("="*60)
    print("DIAGNOSTICO DE CATALOGOS PDF")
    print("="*60)

    for arq, nome in CATALOGOS:
        diagnosticar(arq, nome)

    print("\n\nDiagnostico concluido!")
    print("Verifique a estrutura acima e ajuste os parsers em importar_catalogos.py se necessario.")
