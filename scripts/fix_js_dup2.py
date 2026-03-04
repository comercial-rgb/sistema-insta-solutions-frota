#!/usr/bin/env python3
"""Remove as 2 linhas duplicadas (comment + code) do change handler"""

FILE = "app/assets/javascripts/models/order_services.js"
with open(FILE, "r") as f:
    content = f.read()

old = """            // Mostra link de download da Requisição
            $('#div-requisicao-download').removeClass('d-none').show();
            // Mostra link de download da Requisição
            $('#div-requisicao-download').removeClass('d-none').show();"""

new = """            // Mostra link de download da Requisição
            $('#div-requisicao-download').removeClass('d-none').show();"""

count = content.count(old)
print(f"Encontrou {count} ocorrências do bloco duplicado")

if count > 0:
    content = content.replace(old, new, 1)
    with open(FILE, "w") as f:
        f.write(content)
    print("OK: Duplicata removida")
else:
    print("Bloco duplicado não encontrado - verificando...")
    idx = content.find("$('#div-requisicao-download').removeClass")
    if idx >= 0:
        print(repr(content[idx-50:idx+200]))
