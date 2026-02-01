$(document).ready(function () {

    // Não permitindo a inserção do valor 0 ou negativo no campo de quantidade nas propostas
    $('body').on('change', '.order_service_proposal_item_quantity', function (event) {
        const value = parseFloat(event.target.value);
        if (value <= 0 || isNaN(value)) {
            // Reset the value if it's not valid
            event.target.value = '';
            return;
        }
        let item_id = event.target.id;
        let item_position = item_id.split("_")[8];
        gettingCorrectValueAndDiscount(item_position);
    });

    // Capturando o evento de troca de valor no campo de produto/serviço
    $('body').on('change', '.order_service_proposal_item_service', function (event) {
        let item_id = event.target.id;
        let item_position = item_id.split("_")[8];
        gettingCorrectValueAndDiscount(item_position);
    });

    function gettingCorrectValueAndDiscount(item_position){
        let client_id = $('#order_service_proposal_client_id').val();
        let quantity = $('#order_service_proposal_order_service_proposal_items_attributes_' + item_position +'_quantity').val();
        let service_id = $('#order_service_proposal_order_service_proposal_items_attributes_' + item_position +'_service_id').find(":selected").val();
        if (client_id != '' && quantity != '' && service_id != ''){
            let url = '/getting_service_values';
            $.ajax({
                url: url,
                dataType: 'json',
                async: false,
                data: {
                    client_id: client_id,
                    quantity: quantity,
                    service_id: service_id
                },
                success: function (data) {
                    $('#order_service_proposal_order_service_proposal_items_attributes_' + item_position + '_discount_temp').val(data.discount_formatted);
                    $('#order_service_proposal_order_service_proposal_items_attributes_' + item_position + '_discount').val(data.discount);
                    $('#order_service_proposal_order_service_proposal_items_attributes_' + item_position + '_total_temp').val(data.value_formatted);
                    $('#order_service_proposal_order_service_proposal_items_attributes_' + item_position + '_total_value').val(data.value);
                    updateTotalValues();
                }
            });
        }
    }

    document.addEventListener('keydown', function (event) {
        // Check if the key pressed is "Enter"
        if (event.key === 'Enter' || event.keyCode === 13) {
            // Check if the URL contains "order_service_proposals/new?"
            if (window.location.href.indexOf('order_service_proposals/new?') !== -1) {
                // Ignore the function or action
                // console.log('Enter key press ignored due to specific URL.');
                return; // Exit the function early
            }
            // Place any other logic here if you want to handle Enter key presses differently in other cases
            // console.log('Enter key pressed, executing function.');
        }
    });

    document.addEventListener('keydown', function (event) {
        // Check if the event target has the class 'only-read'
        if (event.target.classList.contains('only-read')) {
            // Prevent any key from being typed
            event.preventDefault();
        }
    });

    $('body').on('change blur input', '.provider_service_temp_price, .provider_service_temp_quantity', function (event) {
        let item_id = event.target.id;
        let item_position = item_id.split("_")[7];
        
        // Verificar valor máximo permitido (para preço e quantidade total)
        if ($(this).hasClass('provider_service_temp_price')) {
            let $priceInput = $(this);
            let $row = $priceInput.closest('.card-body');
            let $quantityInput = $row.find('.provider_service_temp_quantity');
            
            let maxValueTotal = parseFloat($priceInput.data('max_value')) || 0;
            
            if (maxValueTotal > 0) {
                // Converter o valor inserido (pode estar formatado como R$ 1.234,56)
                let currentPrice = parseFloat($priceInput.val().replace(/[^\d,]/g, '').replace(',', '.')) || 0;
                let quantity = parseInt($quantityInput.val()) || 1;
                let totalValue = currentPrice * quantity;
                
                if (totalValue > maxValueTotal) {
                    let maxUnitPrice = maxValueTotal / quantity;
                    $priceInput.addClass('is-invalid');
                    
                    // Mostrar alerta inline
                    let $alert = $row.find('.price-limit-alert');
                    if ($alert.length === 0) {
                        $priceInput.closest('.col-md-2').append(
                            '<div class="text-danger small price-limit-alert mt-1">' +
                            '<i class="bi bi-exclamation-triangle-fill"></i> ' +
                            'Valor máximo total: R$ ' + maxValueTotal.toFixed(2).replace('.', ',') + '<br>' +
                            'Preço unitário máximo: R$ ' + maxUnitPrice.toFixed(2).replace('.', ',') +
                            '</div>'
                        );
                    }
                    
                    // Auto-ajustar para o valor máximo permitido
                    if (event.type === 'change' || event.type === 'blur') {
                        let formattedMax = 'R$ ' + maxUnitPrice.toFixed(2).replace('.', ',').replace(/\B(?=(\d{3})+(?!\d))/g, '.');
                        $priceInput.val(formattedMax);
                        $priceInput.removeClass('is-invalid');
                        $row.find('.price-limit-alert').remove();
                    }
                } else {
                    $priceInput.removeClass('is-invalid');
                    $row.find('.price-limit-alert').remove();
                }
            }
        }
        
        gettingCorrectValueAndDiscountToNewServices(item_position);
    });

    function gettingCorrectValueAndDiscountToNewServices(item_position) {
        let client_id = $('#order_service_proposal_client_id').val();
        let quantity = $('#order_service_proposal_provider_service_temps_attributes_' + item_position + '_quantity').val();
        let price = $('#order_service_proposal_provider_service_temps_attributes_' + item_position + '_price').val();
        
        console.log('Calculando valores - Position:', item_position, 'Client:', client_id, 'Qty:', quantity, 'Price:', price);
        
        // Validar se os campos essenciais existem e têm valor
        if (!client_id || !quantity || !price) {
            console.log('Campos vazios, ignorando cálculo');
            return;
        }
        
        // Verificar se o preço não é zero
        let priceNumeric = parseFloat(price.replace(/[^\d,]/g, '').replace(',', '.')) || 0;
        console.log('Preço numérico:', priceNumeric);
        
        if (priceNumeric <= 0) {
            console.log('Preço zero ou inválido, ignorando cálculo');
            return;
        }
        
        let url = '/getting_service_values_new_product';
        console.log('Chamando API:', url);
        
        $.ajax({
            url: url,
            dataType: 'json',
            async: false,
            data: {
                client_id: client_id,
                quantity: quantity,
                price: price
            },
            success: function (data) {
                console.log('Resposta da API:', data);
                $('#order_service_proposal_provider_service_temps_attributes_' + item_position + '_discount_temp').val(data.discount_formatted);
                $('#order_service_proposal_provider_service_temps_attributes_' + item_position + '_discount').val(data.discount);
                $('#order_service_proposal_provider_service_temps_attributes_' + item_position + '_total_temp').val(data.value_formatted);
                $('#order_service_proposal_provider_service_temps_attributes_' + item_position + '_total_value').val(data.value);
                updateTotalValues();
            },
            error: function(xhr, status, error) {
                console.error('Erro ao calcular valores:', error);
            }
        });
    }

    let ORDER_SERVICE_PROPOSAL_FORM_TO_VALIDATE = "form-order-service-proposal-to-validate";

    $('.' + ORDER_SERVICE_PROPOSAL_FORM_TO_VALIDATE).validate({
        onfocusout: function (element) {
            this.element(element);
        },
        rules: {
            'reason_reproved': {
                required: true
            }
        },
        messages: {
            'reason_reproved': {
                required: 'Insira o motivo da reprovação.'
            }
        }
    });

    let ACTION_TO_ORDER_SERVICE_PROPOSALS_LISTING = "action-to-order-service-proposals-listing";
    let SELECT_ORDER_SERVICE_PROPOSAL = "select-order-service-proposal";
    let REASON_REPROVE_MODAL = "#reason_reproved_modal";
    let REASON_REPROVE = "#reason-reprove";
    let SEND_REPROVE_REASON = "#send-reprove-reason";

    let URL_REPROVE_ORDER_SERVICE_PROPOSALS = "/reprove_order_service_proposals";

    $(document).on('click', '.' + ACTION_TO_ORDER_SERVICE_PROPOSALS_LISTING, function () {
        actionToProposals(this);
    });

    function actionToProposals(element) {
        let checkBoxes = $('.' + SELECT_ORDER_SERVICE_PROPOSAL + ':checkbox:checked').map(function () {
            return this.value;
        }).get();
        let order_service_proposal_ids = checkBoxes.join(",");
        if (checkBoxes.length > 0) {
            if (element.id == "reprove-order-services-proposals") {
                reproveSelectedOrderServiceProposals(order_service_proposal_ids);
            }
        } else {
            alert("Selecione ao menos uma proposta");
        }
    }

    function reproveSelectedOrderServiceProposals(order_service_proposal_ids) {
        $(REASON_REPROVE_MODAL).modal('show');
        $(REASON_REPROVE).focus();
    }

    $(document).on('click', SEND_REPROVE_REASON, function(){
        let reprove_reason = $(REASON_REPROVE).val();
        if(reprove_reason != null && reprove_reason != ""){
            let checkBoxes = $('.' + SELECT_ORDER_SERVICE_PROPOSAL +':checkbox:checked').map(function() {
                return this.value;
            }).get();
            let order_service_proposal_ids = checkBoxes.join(",");
            let confirm = window.confirm("Você tem certeza?");
            if(confirm){
                $.ajax({
                    url: URL_REPROVE_ORDER_SERVICE_PROPOSALS,
                    dataType: 'json',
                    type: 'post',
                    data: {
                        order_service_proposal_ids: order_service_proposal_ids,
                        reprove_reason: reprove_reason
                    },
                    async: false,
                    success: function(data) {
                        alert(data.message);
                        if(data.result){
                            window.location = window.location;
                        }
                    }
                });
            }
        } else {
            alert("É necessário inserir o motivo da reprovação.")
        }
    });

    // ========================================
    // VALIDAÇÃO DE NOTAS FISCAIS - CONSOLIDADO
    // ========================================
    
    // Listeners únicos para todos os campos de nota fiscal
    $('body').on('blur change input', '.order_service_invoice_number, .order_service_invoice_value, .order_service_invoice_emission_date', function () {
        validateInvoiceInputs();
    });

    $('body').on('change', '.order_service_invoice_order_service_invoice_type_id', function () {
        validateInvoiceInputs();
    });
    
    // Listener para mudança de arquivo
    $('body').on('change', '.edit_order_service_proposal input.file', function () {
        validateInvoiceInputs();
    });

    // Validate all file inputs within the form with class 'edit_order_service_proposal'
    $('body').on('change', '.edit_order_service_proposal .file', function () {
        validateInvoiceInputs();
    });

    // Initial check on page load
    validateInvoiceInputs();

    let CHANGE_CATEGORY_TYPE_PROVIDER_SERVICE_TEMP = 'change-category-type-provider-service-temp';
    let DIV_WITH_PARTS_DATA_POSITION = 'div-with-parts-data-';

    $(document).on('change', '.' + CHANGE_CATEGORY_TYPE_PROVIDER_SERVICE_TEMP, function () {
        let value = $(this).find(":selected").val();
        let position = this.id.split('-')[6];
        if (value == 1) {
            hideElement(DIV_WITH_PARTS_DATA_POSITION+position, false);
            $('#order_service_proposal_provider_service_temps_attributes_'+position+'_discount').addClass('order_service_proposal_item_discount_part').removeClass('order_service_proposal_item_discount_service');
            $('#order_service_proposal_provider_service_temps_attributes_'+position+'_total_value').addClass('order_service_proposal_item_total_value_part').removeClass('order_service_proposal_item_total_value_service');
        } else {
            hideElement(DIV_WITH_PARTS_DATA_POSITION+position, true);
            $('#order_service_proposal_provider_service_temps_attributes_'+position+'_discount').removeClass('order_service_proposal_item_discount_part').addClass('order_service_proposal_item_discount_service');
            $('#order_service_proposal_provider_service_temps_attributes_'+position+'_total_value').removeClass('order_service_proposal_item_total_value_part').addClass('order_service_proposal_item_total_value_service');
        }
        updateTotalValues();
    });
    
    // Validação no submit do formulário de proposta para limites de grupo
    $(document).on('submit', 'form[id*="order_service_proposal"]', function(e) {
        let hasError = false;
        let errorMessages = [];
        
        // Validar cada item de provider_service_temps
        $('.provider_service_temp_price').each(function() {
            let $priceInput = $(this);
            let $row = $priceInput.closest('.card-body');
            let $quantityInput = $row.find('.provider_service_temp_quantity');
            let $serviceNameField = $row.find('input[id*="_name"]').first();
            
            let maxValueTotal = parseFloat($priceInput.data('max_value')) || 0;
            
            if (maxValueTotal > 0) {
                let currentPrice = parseFloat($priceInput.val().replace(/[^\d,]/g, '').replace(',', '.')) || 0;
                let quantity = parseInt($quantityInput.val()) || 1;
                let totalValue = currentPrice * quantity;
                let serviceName = $serviceNameField.val() || 'Serviço';
                
                if (totalValue > maxValueTotal) {
                    hasError = true;
                    let maxUnitPrice = maxValueTotal / quantity;
                    errorMessages.push(
                        '• ' + serviceName + ': Valor total R$ ' + totalValue.toFixed(2).replace('.', ',') + 
                        ' excede o máximo permitido (R$ ' + maxValueTotal.toFixed(2).replace('.', ',') + '). ' +
                        'Preço unitário máximo: R$ ' + maxUnitPrice.toFixed(2).replace('.', ',')
                    );
                    $priceInput.addClass('is-invalid');
                }
            }
        });
        
        if (hasError) {
            e.preventDefault();
            alert('❌ ERRO: Não é possível salvar a proposta.\n\n' +
                  'Os seguintes itens excedem o valor máximo permitido pelo grupo de serviços:\n\n' +
                  errorMessages.join('\n') + 
                  '\n\nAjuste os valores para continuar.');
            
            // Scroll para o primeiro campo com erro
            $('html, body').animate({
                scrollTop: $('.is-invalid').first().offset().top - 100
            }, 500);
            return false;
        }
    });
});

updateTotalValues();
function updateTotalValues() {
    let idTotalParts = '#totalParts';
    let idPartsDiscount = '#partsDiscount';
    let idTotalPartsWithDiscount = '#totalPartsWithDiscount';
    let idTotalLabor = '#totalLabor';
    let idLaborDiscount = '#laborDiscount';
    let idTotalLaborWithDiscount = '#totalLaborWithDiscount';
    let idTotalOrder = '#totalOrder';
    let idTotalOrderDiscount = '#totalOrderDiscount';
    let idTotalOrderWithDiscount = '#totalOrderWithDiscount';

    // Total de desconto de peças
    let totalDiscountParts = 0;
    $('.order_service_proposal_item_discount_part').each(function () {
        let value = 0;
        if ($(this).is('input')) {
            value = parseFloat($(this).val()) || 0;
        } else {
            value = parseFloat(this.getAttribute('value')) || 0;
        }
        totalDiscountParts += value;
    });
    let totalDiscountPartsFormatted = formatToCurrency(totalDiscountParts);
    $(idPartsDiscount).val(totalDiscountPartsFormatted).text(totalDiscountPartsFormatted);

    // Total de peças
    let totalValueParts = 0;
    $('.order_service_proposal_item_total_value_part').each(function () {
        let value = 0;
        if ($(this).is('input')) {
            value = parseFloat($(this).val()) || 0;
        } else {
            value = parseFloat(this.getAttribute('value')) || 0;
        }
        totalValueParts += value;
    });
    totalValueParts += totalDiscountParts;
    let totalValuePartsFormatted = formatToCurrency(totalValueParts);
    $(idTotalParts).val(totalValuePartsFormatted).text(totalValuePartsFormatted);

    // Total de desconto de serviços
    let totalDiscountServices = 0;
    $('.order_service_proposal_item_discount_service').each(function () {
        let value = 0;
        if ($(this).is('input')) {
            value = parseFloat($(this).val()) || 0;
        } else {
            value = parseFloat(this.getAttribute('value')) || 0;
        }
        totalDiscountServices += value;
    });
    let totalDiscountServicesFormatted = formatToCurrency(totalDiscountServices);
    $(idLaborDiscount).val(totalDiscountServicesFormatted).text(totalDiscountServicesFormatted);
    
    // Total de serviços
    let totalValueServices = 0;
    $('.order_service_proposal_item_total_value_service').each(function () {
        let value = 0;
        if ($(this).is('input')) {
            value = parseFloat($(this).val()) || 0;
        } else {
            value = parseFloat(this.getAttribute('value')) || 0;
        }
        totalValueServices += value;
    });
    totalValueServices += totalDiscountServices;
    let totalValueServicesFormatted = formatToCurrency(totalValueServices);
    $(idTotalLabor).val(totalValueServicesFormatted).text(totalValueServicesFormatted);

    let totalOrderValue = totalValueParts + totalValueServices;
    let totalOrderValueFormatted = formatToCurrency(totalOrderValue);
    $(idTotalOrder).val(totalOrderValueFormatted).text(totalOrderValueFormatted);

    let totalOrderDiscountFormatted = formatToCurrency(totalDiscountParts + totalDiscountServices);
    $(idTotalOrderDiscount).val(totalOrderDiscountFormatted).text(totalOrderDiscountFormatted);

    let totalPartsWithDiscountFormatted = formatToCurrency(totalValueParts - totalDiscountParts);
    $(idTotalPartsWithDiscount).val(totalPartsWithDiscountFormatted).text(totalPartsWithDiscountFormatted);

    let totalTotalLaborWithDiscountFormatted = formatToCurrency(totalValueServices - totalDiscountServices);
    $(idTotalLaborWithDiscount).val(totalTotalLaborWithDiscountFormatted).text(totalTotalLaborWithDiscountFormatted);

    let totalTotalOrderWithDiscountFormatted = formatToCurrency((totalValueParts + totalValueServices) - (totalDiscountParts + totalDiscountServices));
    $(idTotalOrderWithDiscount).val(totalTotalOrderWithDiscountFormatted).text(totalTotalOrderWithDiscountFormatted);
}

function validateInvoiceInputs() {
    let isValid = true;

    // Validate order_service_invoice_number inputs
    $('.order_service_invoice_number').each(function () {
        if ($(this).val().trim() === '') {
            isValid = false;
            return false; // Exit the loop early
        }
    });

    // Validate order_service_invoice_value inputs
    $('.order_service_invoice_value').each(function () {
        if ($(this).val().trim() === '') {
            isValid = false;
            return false; // Exit the loop early
        }
    });

    // Validate order_service_invoice_order_service_invoice_type_id selects
    $('.order_service_invoice_order_service_invoice_type_id').each(function () {
        if ($(this).val() != null && $(this).val().trim() === '') {
            isValid = false;
            return false; // Exit the loop early
        }
    });

    // Validate all input fields within the form with class 'edit_order_service_proposal'
    $('.order_service_invoice_emission_date').each(function () {
        if ($(this).val().trim() === '') {
            isValid = false;
            return false; // Exit the loop early
        }
    });
    
    // Validate file inputs
    // Regra: arquivo é obrigatório, mas se já existe anexo salvo no registro, não exigir novo upload.
    $('.edit_order_service_proposal input.file').each(function () {
        let hasExistingAttachment = false;
        let wrapper = $(this).closest('.invoice-file-wrapper');
        if (wrapper.length) {
            hasExistingAttachment = wrapper.data('attachment-present') === true;
        }

        if (this.files.length === 0 && !hasExistingAttachment) {
            isValid = false;
            return false; // Exit the loop early
        }
    });

    if (isValid) {
        updateButtonSaveInvoiceDataState();
    } else {
        disableElement('button_insert_invoice', true);
    }
}

function updateButtonSaveInvoiceDataState() {
    // Compare em centavos (inteiro) para não depender de parseFloat e formatação pt-BR.
    let totalValueCents = getMoney($('#total_value_order_service_proposal_items').val() || '0') || 0;
    let sumOfInvoicesCents = 0;

    $('.order_service_invoice_value').each(function () {
        let valueCents = getMoney($(this).val() || '0') || 0;
        sumOfInvoicesCents += valueCents;
    });

    console.log('Validação notas - Total proposta (centavos):', totalValueCents, 'Soma notas (centavos):', sumOfInvoicesCents, 'Diferença:', Math.abs(sumOfInvoicesCents - totalValueCents));

    // Tolerância de 5 centavos para cobrir arredondamentos em propostas com muitos itens
    if (Math.abs(sumOfInvoicesCents - totalValueCents) <= 5) {
        console.log('✓ Validação OK - habilitando botão');
        disableElement('button_insert_invoice', false);
    } else {
        console.log('✗ Validação falhou - diferença maior que 5 centavos');
        disableElement('button_insert_invoice', true);
    }
}

// ========================================
// ADICIONAR/REMOVER PROVIDER SERVICE TEMPS
// ========================================

// Contador global para gerar IDs únicos
let providerServiceTempCounter = 10000;

// Adicionar novo provider_service_temp
$(document).on('click', '.add-provider-service-temp', function(e) {
    e.preventDefault();
    
    let button = $(this);
    let categoryId = button.data('category-id');
    let partServiceName = button.data('part-service-name');
    let container = button.closest('.multi-providerservicetemp-block');
    
    // Incrementar contador
    providerServiceTempCounter++;
    let newIndex = providerServiceTempCounter;
    
    // Determinar se é peça (1) ou serviço (2)
    let isPeca = (categoryId == 1);
    
    // Buscar serviços disponíveis via AJAX
    $.ajax({
        url: '/services/by_category',
        method: 'GET',
        data: { category_id: categoryId },
        dataType: 'json',
        success: function(services) {
            // Gerar options do select
            let optionsHtml = '<option value="">Selecionar do banco...</option>';
            services.forEach(function(service) {
                optionsHtml += `<option value="${service.id}" data-name="${service.name}">${service.name}</option>`;
            });
            optionsHtml += '<option value="novo" data-name="">➕ Criar novo item</option>';
            
            // Template do novo item com SELECT e campo de texto condicional
            let newItemHtml = `
            <div class="provider-service-temp-item position-relative">
                <div class="card mb-2 shadow-sm border-success">
                    <div class="card-body py-2 px-3">
                        <div class="row g-2 align-items-end">
                            
                            <!-- Botão para remover este item -->
                            <div class="col-12 text-end">
                                <button type="button" class="btn btn-sm btn-outline-danger remove-provider-service-temp" title="Remover item">
                                    <i class="bi bi-trash"></i> Remover
                                </button>
                            </div>
                            
                            <input type="hidden" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][id]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_id" />
                            <input type="hidden" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][description]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_description" />
                            <input type="hidden" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][category_id]" value="${categoryId}" class="change-category-type-provider-service-temp" id="change-category-type-provider-service-temp-${newIndex}" />
                            
                            <div class="col-md-12">
                                <label class="form-label required">${partServiceName}</label>
                                <select name="order_service_proposal[provider_service_temps_attributes][${newIndex}][service_id]" 
                                        id="order_service_proposal_provider_service_temps_attributes_${newIndex}_service_id" 
                                        class="form-select form-select-sm provider-service-select" 
                                        data-index="${newIndex}"
                                        data-category="${categoryId}">
                                    ${optionsHtml}
                                </select>
                            </div>
                            
                            <div class="col-md-12" id="new-item-name-container-${newIndex}" style="display:none;">
                                <label class="form-label required">Nome do novo item</label>
                                <input type="text" 
                                       name="order_service_proposal[provider_service_temps_attributes][${newIndex}][name]" 
                                       id="order_service_proposal_provider_service_temps_attributes_${newIndex}_name" 
                                       class="form-control form-control-sm new-item-name-input" 
                                       placeholder="Digite o nome do item"
                                       data-index="${newIndex}" />
                                <small class="text-danger duplicate-warning-${newIndex}" style="display:none;">
                                    <i class="bi bi-exclamation-triangle"></i> Item já existe ou está duplicado
                                </small>
                            </div>
                            
                            ${isPeca ? `
                            <div class="col-md-3">
                                <label class="form-label">Marca</label>
                                <input type="text" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][brand]" class="form-control form-control-sm" />
                            </div>
                            ` : ''}
                            
                            <div class="col-md-2">
                                <label class="form-label">Período de Garantia</label>
                                <input type="text" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][warranty_period]" class="form-control form-control-sm" placeholder="Ex: 90 dias" />
                            </div>
                            
                            <div class="col-md-2">
                                <label class="form-label required">Preço Unitário</label>
                                <input type="tel" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][price]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_price" class="form-control form-control-sm money provider_service_temp_price" placeholder="0,00" data-index="${newIndex}" required />
                            </div>
                            
                            <div class="col-md-1">
                                <label class="form-label required">Qtd</label>
                                <input type="number" min="1" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][quantity]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_quantity" class="form-control form-control-sm provider_service_temp_quantity" value="1" required />
                            </div>
                            
                            <div class="col-md-2">
                                <label class="form-label">Desconto</label>
                                <input type="text" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][discount_temp]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_discount_temp" class="form-control form-control-sm only-read bg-light" value="R$ 0,00" readonly />
                                <input type="hidden" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][discount]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_discount" class="order_service_proposal_item_discount_${isPeca ? 'part' : 'service'}" value="0" />
                            </div>
                            
                            <div class="col-md-2">
                                <label class="form-label">Total</label>
                                <input type="text" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][total_temp]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_total_temp" class="form-control form-control-sm only-read fw-bold text-success bg-light" value="R$ 0,00" readonly />
                                <input type="hidden" name="order_service_proposal[provider_service_temps_attributes][${newIndex}][total_value]" id="order_service_proposal_provider_service_temps_attributes_${newIndex}_total_value" class="order_service_proposal_item_total_value_${isPeca ? 'part' : 'service'}" value="0" />
                            </div>
                            
                        </div>
                    </div>
                </div>
            </div>
            `;
            
            // Adicionar o novo item ao container (antes do botão adicionar)
            button.parent().after(newItemHtml);
            
            // IMPORTANTE: Aguardar o DOM atualizar antes de aplicar máscara e eventos
            setTimeout(function() {
                // Inicializar máscara de MOEDA (maskMoney, não mask) no campo de preço
                let priceInput = $(`#order_service_proposal_provider_service_temps_attributes_${newIndex}_price`);
                
                if (priceInput.length) {
                    // Aplicar maskMoney igual aos campos existentes
                    priceInput.maskMoney({
                        prefix: "R$ ",
                        showSymbol: true,
                        decimal: ",",
                        thousands: ".",
                        symbolStay: true,
                        selectAllOnFocus: true
                    });
                    
                    console.log('Máscara de moeda aplicada ao campo:', priceInput.attr('id'));
                    
                    // Adicionar eventos para recalcular quando preço mudar
                    priceInput.on('blur change', function() {
                        console.log('Preço alterado, recalculando...', $(this).val());
                        gettingCorrectValueAndDiscountToNewServices(newIndex);
                    });
                }
                
                // Adicionar eventos para recalcular quando quantidade mudar
                let quantityInput = $(`#order_service_proposal_provider_service_temps_attributes_${newIndex}_quantity`);
                if (quantityInput.length) {
                    quantityInput.on('blur change', function() {
                        console.log('Quantidade alterada, recalculando...', $(this).val());
                        gettingCorrectValueAndDiscountToNewServices(newIndex);
                    });
                }
            }, 100);
        },
        error: function() {
            alert('Erro ao buscar peças/serviços. Tente novamente.');
        }
    });
});

// Quando selecionar um serviço no dropdown
$(document).on('change', '.provider-service-select', function() {
    let select = $(this);
    let selectedOption = select.find('option:selected');
    let selectedValue = selectedOption.val();
    let serviceName = selectedOption.data('name');
    let index = select.data('index');
    let categoryId = select.data('category');
    
    let nameContainer = $(`#new-item-name-container-${index}`);
    let nameInput = $(`#order_service_proposal_provider_service_temps_attributes_${index}_name`);
    
    if (selectedValue === 'novo') {
        // Mostrar campo de texto para criar novo item
        nameContainer.show();
        nameInput.prop('required', true);
        select.prop('required', false);
    } else if (selectedValue) {
        // Item do banco selecionado
        nameContainer.hide();
        nameInput.prop('required', false).val('');
        select.prop('required', true);
        
        // Verificar duplicados
        if (checkDuplicateService(selectedValue, index)) {
            alert('Este item já foi adicionado!');
            select.val('').trigger('change');
            return;
        }
    } else {
        // Nenhuma opção selecionada
        nameContainer.hide();
        nameInput.prop('required', false).val('');
        select.prop('required', true);
    }
});

// Validar nome ao digitar (verificar duplicados)
$(document).on('blur', '.new-item-name-input', function() {
    let input = $(this);
    let index = input.data('index');
    let itemName = input.val().trim().toLowerCase();
    
    if (!itemName) return;
    
    // Verificar se já existe nos items adicionados ou no banco
    let isDuplicate = false;
    
    // Verificar nos items já adicionados nesta proposta
    $('.provider-service-select').each(function() {
        let otherSelect = $(this);
        let otherIndex = otherSelect.data('index');
        
        if (otherIndex != index) {
            let otherOption = otherSelect.find('option:selected');
            let otherName = otherOption.data('name');
            
            if (otherName && otherName.toLowerCase() === itemName) {
                isDuplicate = true;
                return false;
            }
        }
    });
    
    // Verificar nos novos items criados
    $('.new-item-name-input').each(function() {
        let otherInput = $(this);
        let otherIndex = otherInput.data('index');
        
        if (otherIndex != index) {
            let otherName = otherInput.val().trim().toLowerCase();
            if (otherName === itemName) {
                isDuplicate = true;
                return false;
            }
        }
    });
    
    // Verificar se existe no select (banco)
    let select = $(`#order_service_proposal_provider_service_temps_attributes_${index}_service_id`);
    select.find('option').each(function() {
        let optionName = $(this).data('name');
        if (optionName && optionName.toLowerCase() === itemName) {
            isDuplicate = true;
            return false;
        }
    });
    
    // Mostrar/esconder aviso
    if (isDuplicate) {
        $(`.duplicate-warning-${index}`).show();
        input.addClass('is-invalid');
    } else {
        $(`.duplicate-warning-${index}`).hide();
        input.removeClass('is-invalid');
    }
});

// Função para verificar se um service_id já foi adicionado
function checkDuplicateService(serviceId, currentIndex) {
    let isDuplicate = false;
    
    $('.provider-service-select').each(function() {
        let select = $(this);
        let index = select.data('index');
        
        if (index != currentIndex && select.val() == serviceId) {
            isDuplicate = true;
            return false;
        }
    });
    
    return isDuplicate;
}

// Remover provider_service_temp
$(document).on('click', '.remove-provider-service-temp', function(e) {
    e.preventDefault();
    
    let button = $(this);
    let item = button.closest('.provider-service-temp-item');
    
    // Se o item tem ID (já existe no banco), marcar para destruição
    let idInput = item.find('input[name*="[id]"]').first();
    if (idInput.val()) {
        // Adicionar campo _destroy
        item.append(`<input type="hidden" name="${idInput.attr('name').replace('[id]', '[_destroy]')}" value="1" />`);
        item.hide();
    } else {
        // Item novo, apenas remover do DOM
        item.remove();
    }
    
    updateTotalValues();
});
