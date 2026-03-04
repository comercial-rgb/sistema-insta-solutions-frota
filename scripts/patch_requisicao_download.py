#!/usr/bin/env python3
"""
Patch: Adiciona link de download da Requisição de Serviços quando tipo = Requisição
1. _form_data.html.erb: adiciona div com link (escondido por padrão)
2. order_services.js: toggle show/hide nos handlers de inicialização e change
"""

# ============================================================
# PATCH 1: _form_data.html.erb - Adicionar div com link de download
# ============================================================
print("1. Patching _form_data.html.erb...")

FORM_FILE = "app/views/order_services/forms/_form_data.html.erb"
with open(FORM_FILE, "r") as f:
    content = f.read()

# Inserir o div logo após a row de tipo/grupo/fornecedor (após "</div>\n</div>\n\n<%#")
# Procuramos o padrão: fechamento da row + início da seção de fornecedores direcionados
marker = """</div>
</div>

<%# ===== SEÇÃO: Enviar para Fornecedores Específicos"""

if marker in content:
    download_div = """</div>
</div>

<!-- Link para download da Requisição de Serviços (visível apenas para tipo Requisição) -->
<div class="row mt-2 d-none" id="div-requisicao-download">
    <div class="col-12">
        <div class="alert alert-info d-flex align-items-center py-2 mb-2" role="alert">
            <i class="bi bi-file-earmark-word me-2" style="font-size: 1.3rem; color: #2b579a;"></i>
            <div>
                <strong>Requisição de Serviços:</strong>
                <a href="/Requisicao_Servicos_InstaSolutions.docx" target="_blank" class="ms-2 btn btn-sm btn-outline-primary">
                    <i class="bi bi-download me-1"></i> Baixar Formulário de Requisição (.docx)
                </a>
            </div>
        </div>
    </div>
</div>

<%# ===== SEÇÃO: Enviar para Fornecedores Específicos"""
    
    content = content.replace(marker, download_div, 1)
    with open(FORM_FILE, "w") as f:
        f.write(content)
    print("  OK: Div de download adicionado")
else:
    print("  ERRO: Marcador não encontrado no _form_data.html.erb")
    print("  Procurado: " + repr(marker[:80]))
    exit(1)

# ============================================================
# PATCH 2: order_services.js - Toggle na inicialização
# ============================================================
print("2. Patching order_services.js (inicialização)...")

JS_FILE = "app/assets/javascripts/models/order_services.js"
with open(JS_FILE, "r") as f:
    js = f.read()

# Patch inicialização: Requisição (type == 3)
old_init_req = """$('#div-diagnostico-info').addClass('d-none').hide(); // Esconde informativo
        $('.quantity-field-container').show();
        hideNewServiceButtons(true);
        changeQuantityFieldType('number');"""

new_init_req = """$('#div-diagnostico-info').addClass('d-none').hide(); // Esconde informativo
        $('#div-requisicao-download').removeClass('d-none').show(); // Mostra link de download
        $('.quantity-field-container').show();
        hideNewServiceButtons(true);
        changeQuantityFieldType('number');"""

if old_init_req in js:
    js = js.replace(old_init_req, new_init_req, 1)
    print("  OK: Inicialização - Requisição mostra link")
else:
    print("  WARN: Bloco de inicialização Requisição não encontrado (pode já estar patcheado)")

# Patch inicialização: Diagnóstico (type == 2) - esconder o link
old_init_diag = """$('#div-diagnostico-info').removeClass('d-none').show(); // Mostra informativo
        $('.quantity-field-container').hide();
        setTimeout(fixSelect2Width, 100);
    } else if (initialOrderServiceTypeId == '1') {"""

new_init_diag = """$('#div-diagnostico-info').removeClass('d-none').show(); // Mostra informativo
        $('#div-requisicao-download').addClass('d-none').hide(); // Esconde link Requisição
        $('.quantity-field-container').hide();
        setTimeout(fixSelect2Width, 100);
    } else if (initialOrderServiceTypeId == '1') {"""

if old_init_diag in js:
    js = js.replace(old_init_diag, new_init_diag, 1)
    print("  OK: Inicialização - Diagnóstico esconde link")
else:
    print("  WARN: Bloco de inicialização Diagnóstico não encontrado")

# Patch inicialização: Cotações (type == 1) - esconder o link
old_init_cot = """$('#div-diagnostico-info').addClass('d-none').hide(); // Esconde informativo
        $('.quantity-field-container').show();
        changeQuantityFieldType('text');
    } else {"""

new_init_cot = """$('#div-diagnostico-info').addClass('d-none').hide(); // Esconde informativo
        $('#div-requisicao-download').addClass('d-none').hide(); // Esconde link Requisição
        $('.quantity-field-container').show();
        changeQuantityFieldType('text');
    } else {"""

if old_init_cot in js:
    js = js.replace(old_init_cot, new_init_cot, 1)
    print("  OK: Inicialização - Cotações esconde link")
else:
    print("  WARN: Bloco de inicialização Cotações não encontrado")

# ============================================================
# PATCH 3: order_services.js - Toggle no change handler
# ============================================================
print("3. Patching order_services.js (change handler)...")

# Change handler: Requisição (type == 3)
old_change_req = """// Ocultar botões de cadastrar nova peça/serviço
            hideNewServiceButtons(true);
            // Campo quantidade como number
            changeQuantityFieldType('number');"""

new_change_req = """// Ocultar botões de cadastrar nova peça/serviço
            hideNewServiceButtons(true);
            // Campo quantidade como number
            changeQuantityFieldType('number');
            // Mostra link de download da Requisição
            $('#div-requisicao-download').removeClass('d-none').show();"""

if old_change_req in js:
    js = js.replace(old_change_req, new_change_req, 1)
    print("  OK: Change handler - Requisição mostra link")
else:
    print("  WARN: Change handler Requisição não encontrado")

# Change handler: Diagnóstico (type == 2) - esconder link
old_change_diag = """$('#div-diagnostico-info').removeClass('d-none').show(); // Mostra informativo
            $('.quantity-field-container').hide();
            adjustObservationWidth(false);"""

new_change_diag = """$('#div-diagnostico-info').removeClass('d-none').show(); // Mostra informativo
            $('#div-requisicao-download').addClass('d-none').hide(); // Esconde link Requisição
            $('.quantity-field-container').hide();
            adjustObservationWidth(false);"""

if old_change_diag in js:
    js = js.replace(old_change_diag, new_change_diag, 1)
    print("  OK: Change handler - Diagnóstico esconde link")
else:
    print("  WARN: Change handler Diagnóstico não encontrado")

# Change handler: Cotações/Outro - esconder link 
old_change_cot = """$('#div-diagnostico-info').addClass('d-none').hide(); // Esconde informativo
            $('.quantity-field-container').show();
            adjustObservationWidth(true);
            // Limpar seleções"""

new_change_cot = """$('#div-diagnostico-info').addClass('d-none').hide(); // Esconde informativo
            $('#div-requisicao-download').addClass('d-none').hide(); // Esconde link Requisição
            $('.quantity-field-container').show();
            adjustObservationWidth(true);
            // Limpar seleções"""

if old_change_cot in js:
    js = js.replace(old_change_cot, new_change_cot, 1)
    print("  OK: Change handler - Cotações esconde link")
else:
    print("  WARN: Change handler Cotações não encontrado")

with open(JS_FILE, "w") as f:
    f.write(js)

print("\nPatch concluído!")
