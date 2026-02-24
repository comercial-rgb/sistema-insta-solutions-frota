$(document).ready(function () {

    // ==================== DECLARAÇÃO DE FUNÇÕES ====================
    
    // Oculta ou mostra os botões de cadastrar nova peça/serviço
    function hideNewServiceButtons(hide) {
        if (hide) {
            $('button[data-bs-target^="#newServiceModal"]').closest('.mt-2, .btn-outline-primary').hide();
        } else {
            $('button[data-bs-target^="#newServiceModal"]').closest('.mt-2, .btn-outline-primary').show();
        }
    }
    
    // Altera o tipo do campo quantidade (text para cotações, number para requisição)
    function changeQuantityFieldType(type) {
        $('.part-service-quantity').each(function() {
            var $input = $(this);
            var currentValue = $input.val();
            var classes = $input.attr('class');
            var id = $input.attr('id');
            var placeholder = type === 'text' ? 'Ex: 1, 2-3, etc' : '';
            
            // Criar novo input do tipo desejado
            var $newInput = $('<input>')
                .attr('type', type)
                .attr('class', classes)
                .attr('id', id)
                .val(currentValue);
            
            if (type === 'number') {
                $newInput.attr('min', '1').attr('max', '9999');
            } else {
                $newInput.attr('placeholder', placeholder);
            }
            
            // Substituir o input antigo pelo novo
            $input.replaceWith($newInput);
        });
    }

    // ====================INICIALIZAÇÃO ====================
    
    // Verificar tipo de OS ao carregar a página e ajustar campos/botões conforme necessário
    var initialOrderServiceTypeId = $('#order_service_order_service_type_id').val();
    
    console.log('🔍 Inicializando formulário de OS - Tipo selecionado:', initialOrderServiceTypeId);
    
    // Função para corrigir largura do Select2
    function fixSelect2Width() {
        $('#div-with-service-group-selection .select2-container, #div-with-provider-selection .select2-container').css('width', '100%');
    }
    
    // Aplicar configuração inicial baseada no tipo
    // IDs reais do banco: 1=Cotações, 2=Diagnóstico, 3=Requisição
    if (initialOrderServiceTypeId == '3') { 
        // REQUISIÇÃO - Mostra Grupo de Serviços, esconde Fornecedor
        console.log('✓ Configurando para REQUISIÇÃO');
        $('#div-with-service-group-selection').removeClass('d-none').show();
        $('#div-with-provider-selection').addClass('d-none').hide();
        $('#div-with-directed-providers').removeClass('d-none').show(); // Mostra seleção direcionada
        $('.quantity-field-container').show();
        hideNewServiceButtons(true);
        changeQuantityFieldType('number');
        setTimeout(fixSelect2Width, 100);
    } else if (initialOrderServiceTypeId == '2') { 
        // DIAGNÓSTICO - Mostra Fornecedor, esconde Grupo de Serviços
        console.log('✓ Configurando para DIAGNÓSTICO');
        $('#div-with-provider-selection').removeClass('d-none').show();
        $('#div-with-service-group-selection').addClass('d-none').hide();
        // Se Diagnóstico pronto para liberar cotação, mostrar painel de fornecedores direcionados
        if ($('#diagnostico_ready_for_release').val() === 'true') {
            console.log('✓ Diagnóstico pronto para liberar cotação - mostrando painel de fornecedores direcionados');
            $('#div-with-directed-providers').removeClass('d-none').show();
        } else {
            $('#div-with-directed-providers').addClass('d-none').hide(); // Diagnóstico já tem fornecedor único
        }
        $('.quantity-field-container').hide();
        setTimeout(fixSelect2Width, 100);
    } else if (initialOrderServiceTypeId == '1') { 
        // COTAÇÕES - Esconde ambos, mostra seleção direcionada
        console.log('✓ Configurando para COTAÇÕES');
        $('#div-with-provider-selection').addClass('d-none').hide();
        $('#div-with-service-group-selection').addClass('d-none').hide();
        $('#div-with-directed-providers').removeClass('d-none').show(); // Mostra seleção direcionada
        $('.quantity-field-container').show();
        changeQuantityFieldType('text');
    } else {
        // Qualquer outro tipo
        $('#div-with-provider-selection').addClass('d-none').hide();
        $('#div-with-service-group-selection').addClass('d-none').hide();
        $('#div-with-directed-providers').addClass('d-none').hide();
        $('.quantity-field-container').show();
        changeQuantityFieldType('text');
    }

    // ==================== EVENT HANDLERS ====================

    $(document).on('change', '#order_services_grid_client_id', function () {
        var client_id = $(this).find(":selected").val();
        var cost_center_id = '#order_services_grid_cost_center_id';
        var vehicle_id = '#order_services_grid_vehicle_id';
        var select_manager_to_populate = '#order_services_grid_manager_id';
        findCostCentersByClients(client_id, cost_center_id, vehicle_id);
        findManagersByClient(client_id, select_manager_to_populate);
    });

    function findCostCentersByClients(client_id, select_cost_center_id, select_vehicle_id) {
        let url = '/get_cost_centers_by_client_id';
        fillSelect([], select_cost_center_id, 'name', null);
        fillSelect([], select_vehicle_id, 'name', null);
        if (client_id != null && client_id != '') {
            $.ajax({
                url: url,
                dataType: 'json',
                async: false,
                data: {
                    client_id: client_id,
                    only_order_services: 1
                },
                success: function (data) {
                    fillSelect(data.result, select_cost_center_id, 'name', null);
                }
            });
        }
    }

    $(document).on('change', '#order_services_grid_cost_center_id', function () {
        var cost_center_id = $(this).find(":selected").val();
        var select_to_populate = '#order_services_grid_vehicle_id';
        findVehiclesByCostCenter(cost_center_id, select_to_populate);
    });

    function findVehiclesByCostCenter(cost_center_id, select_vehicle_id) {
        let url = '/get_vehicles_by_cost_center_id';
        $.ajax({
            url: url,
            dataType: 'json',
            async: false,
            data: {
                cost_center_id: cost_center_id
            },
            success: function (data) {
                fillSelect(data.result, select_vehicle_id, 'board', null);
            }
        });
    }

    $(document).on('change', '#order_service_client_id', function () {
        var client_id = $(this).find(":selected").val();
        var select_to_populate = '#order_service_vehicle_id';
        var select_manager_to_populate = '#order_service_manager_id';
        findVehiclesByClient(client_id, select_to_populate);
        findManagersByClient(client_id, select_manager_to_populate);
        settingOldOrderServiceText('', '', '');
        fillSelect([], '#order_service_commitment_id', 'name', null);
        
        // Carregar requisitos do cliente (fotos de veículo e KM)
        loadClientRequirements(client_id);
    });

    function findVehiclesByClient(client_id, select_vehicle_id) {
        let url = '/get_vehicles_by_client_id';
        $.ajax({
            url: url,
            dataType: 'json',
            async: false,
            data: {
                client_id: client_id,
                active: 1
            },
            success: function (data) {
                fillSelect(data.result, select_vehicle_id, 'board', null);
            }
        });
    }
    
    function loadClientRequirements(client_id) {
        if (!client_id) {
            // Esconder seções de requisitos quando não há cliente
            $('#vehicle-photos-section').remove();
            $('#order_service_km').attr('required', false);
            $('#km-required-hint').remove();
            return;
        }
        
        let url = '/get_client_requirements';
        $.ajax({
            url: url,
            dataType: 'json',
            data: {
                client_id: client_id
            },
            success: function (data) {
                // Atualizar campo KM
                if (data.needs_km) {
                    $('#order_service_km').attr('required', true);
                    $('#order_service_km').closest('.col-12').find('#km-required-hint').remove();
                    $('#order_service_km').after('<small id="km-required-hint" class="text-danger d-block" style="margin-top: -8px; font-size: 0.75rem;"><i class="bi bi-exclamation-circle-fill"></i> <strong>KM obrigatório</strong> para este cliente</small>');
                } else {
                    $('#order_service_km').attr('required', false);
                    $('#km-required-hint').remove();
                }
                
                // Atualizar seção de fotos do veículo
                if (data.require_vehicle_photos) {
                    // Se a seção já existe, não recriar
                    if ($('#vehicle-photos-section').length === 0) {
                        var photosHtml = buildVehiclePhotosSection();
                        $('#order_service_details').closest('.col-12').parent().after(photosHtml);
                    }
                } else {
                    $('#vehicle-photos-section').remove();
                }
            },
            error: function() {
                console.error('Erro ao carregar requisitos do cliente');
            }
        });
    }
    
    function buildVehiclePhotosSection() {
        return `
            <div id="vehicle-photos-section" class="row mt-3">
                <div class="col-12">
                    <div class="alert alert-info" role="alert">
                        <i class="bi bi-info-circle-fill"></i> <strong>Atenção:</strong> Este cliente exige anexar fotos do veículo (frontal, laterais, traseira e hodômetro).
                    </div>
                    
                    <div class="card mb-3">
                        <div class="card-header bg-light">
                            <i class="bi bi-camera-fill"></i> Fotos do veículo
                        </div>
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-12 col-md-6">
                                    <label class="form-label">Frontal <span class="text-danger">*</span></label>
                                    <input type="file" name="order_service[vehicle_photos][]" class="form-control" data-photo-type="frontal" multiple>
                                    <small class="text-muted">Foto da parte frontal do veículo</small>
                                </div>
                                <div class="col-12 col-md-6">
                                    <label class="form-label">Lateral direita <span class="text-danger">*</span></label>
                                    <input type="file" name="order_service[vehicle_photos][]" class="form-control" data-photo-type="lateral_direita" multiple>
                                    <small class="text-muted">Foto do lado direito do veículo</small>
                                </div>
                                <div class="col-12 col-md-6">
                                    <label class="form-label">Lateral esquerda <span class="text-danger">*</span></label>
                                    <input type="file" name="order_service[vehicle_photos][]" class="form-control" data-photo-type="lateral_esquerda" multiple>
                                    <small class="text-muted">Foto do lado esquerdo do veículo</small>
                                </div>
                                <div class="col-12 col-md-6">
                                    <label class="form-label">Traseira <span class="text-danger">*</span></label>
                                    <input type="file" name="order_service[vehicle_photos][]" class="form-control" data-photo-type="traseira" multiple>
                                    <small class="text-muted">Foto da parte traseira do veículo</small>
                                </div>
                                <div class="col-12 col-md-6">
                                    <label class="form-label">Hodômetro <span class="text-danger">*</span></label>
                                    <input type="file" name="order_service[vehicle_photos][]" class="form-control" data-photo-type="hodometro" multiple>
                                    <small class="text-muted">Foto do painel mostrando a quilometragem</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    $(document).on('change', '#order_service_vehicle_id', function () {
        var vehicle_id = $(this).find(":selected").val();
        var select_commitment_id = '#order_service_commitment_id';
        var client_id = $('#order_service_client_id').val();
        findCommitmentsByVehicle(client_id, vehicle_id, select_commitment_id);
    });

    function findManagersByClient(client_id, select_manager_id) {
        let url = '/get_managers_by_client_id';
        $.ajax({
            url: url,
            dataType: 'json',
            async: false,
            data: {
                client_id: client_id
            },
            success: function (data) {
                fillSelect(data.result, select_manager_id, 'name', null);
            }
        });
    }

    function findCommitmentsByVehicle(client_id, vehicle_id, select_commitment_id) {
        let url = '/get_commitments_by_vehicle_id';
        $.ajax({
            url: url,
            dataType: 'json',
            async: false,
            data: {
                vehicle_id: vehicle_id,
                client_id: client_id
            },
            success: function (data) {
                insertMinKmInVehicleKmInput(data.last_km);
                fillSelect(data.result, select_commitment_id, 'formatted_name', null);
            }
        });
    }

    function insertMinKmInVehicleKmInput(min_km){
        $('#order_service_km').attr('min', min_km);
        if (min_km > 0){
            $('#order_service_km').attr('placeholder', 'Mínimo: ' + min_km);
        } else {
            $('#order_service_km').attr('placeholder', '');
        }
    }

    $(document).on('change', '#order_service_order_service_type_id', function () {
        var order_service_type_id = $(this).find(":selected").val();
        console.log('🔄 Tipo de OS alterado para:', order_service_type_id);
        
        // IDs reais do banco: 1=Cotações, 2=Diagnóstico, 3=Requisição
        if (order_service_type_id == '3') {
            // REQUISIÇÃO - Mostra Grupo de Serviços, esconde Fornecedor
            console.log('→ Mudando para REQUISIÇÃO');
            $('#div-with-service-group-selection').removeClass('d-none').show();
            $('#div-with-provider-selection').addClass('d-none').hide();
            $('#div-with-directed-providers').removeClass('d-none').show(); // Mostra seleção direcionada
            $('.quantity-field-container').show();
            adjustObservationWidth(true);
            // Limpar fornecedor selecionado
            $('#order_service_provider_id').val('').trigger('change');
            // Ocultar botões de cadastrar nova peça/serviço
            hideNewServiceButtons(true);
            // Campo quantidade como number
            changeQuantityFieldType('number');
            // Corrigir largura do Select2
            setTimeout(fixSelect2Width, 100);
            // Recarregar fornecedores direcionados
            loadDirectedProviders();
            
        } else if (order_service_type_id == '2') {
            // DIAGNÓSTICO - Mostra Fornecedor, esconde Grupo de Serviços
            console.log('→ Mudando para DIAGNÓSTICO');
            $('#div-with-provider-selection').removeClass('d-none').show();
            $('#div-with-service-group-selection').addClass('d-none').hide();
            $('#div-with-directed-providers').addClass('d-none').hide(); // Diagnóstico já tem fornecedor único
            clearDirectedProviders();
            $('.quantity-field-container').hide();
            adjustObservationWidth(false);
            // Limpar grupo de serviços selecionado
            $('#order_service_service_group_id').val('').trigger('change');
            resetServiceSelects();
            clearServiceGroupLimits();
            // Mostrar botões de cadastrar nova peça/serviço
            hideNewServiceButtons(false);
            // Corrigir largura do Select2
            setTimeout(fixSelect2Width, 100);
            
        } else {
            // COTAÇÕES ou qualquer outro
            console.log('→ Mudando para COTAÇÕES/OUTRO');
            $('#div-with-provider-selection').addClass('d-none').hide();
            $('#div-with-service-group-selection').addClass('d-none').hide();
            $('#div-with-directed-providers').removeClass('d-none').show(); // Mostra seleção direcionada
            $('.quantity-field-container').show();
            adjustObservationWidth(true);
            // Limpar seleções
            $('#order_service_service_group_id').val('').trigger('change');
            $('#order_service_provider_id').val('').trigger('change');
            resetServiceSelects();
            clearServiceGroupLimits();
            // Mostrar botões de cadastrar nova peça/serviço
            hideNewServiceButtons(false);
            // Campo quantidade como text (aceita texto livre)
            changeQuantityFieldType('text');
            // Recarregar fornecedores direcionados
            loadDirectedProviders();
        }
    });
    
    // Ajusta a largura do campo observação
    function adjustObservationWidth(showQuantity) {
        if (showQuantity) {
            $('.observation-field-container').removeClass('col-md-5').addClass('col-md-3');
        } else {
            $('.observation-field-container').removeClass('col-md-3').addClass('col-md-5');
        }
    }
    
    // Armazena os limites dos itens do grupo de serviços
    var serviceGroupItemLimits = {};
    
    // Limpa os limites armazenados
    function clearServiceGroupLimits() {
        serviceGroupItemLimits = {};
    }

    // Função para carregar limites do grupo de serviços (usado no page load e no change)
    function loadServiceGroupLimits(serviceGroupId) {
        if (!serviceGroupId) return;
        
        $.ajax({
            url: '/service_groups/' + serviceGroupId + '.json',
            dataType: 'json',
            success: function (data) {
                // Remover mensagem de limite anterior
                $('#div-with-service-group-selection small').remove();
                
                // Limpar limites anteriores
                clearServiceGroupLimits();
                
                // Filtrar os selects de peças e serviços
                if (data && data.service_group_items && data.service_group_items.length > 0) {
                    var allowedServiceIds = data.service_group_items.map(function(item) {
                        return item.service_id.toString();
                    });
                    
                    // Armazenar os limites de cada item (quantidade máxima e valor máximo)
                    data.service_group_items.forEach(function(item) {
                        serviceGroupItemLimits[item.service_id] = {
                            max_quantity: item.quantity,
                            max_value: item.max_value
                        };
                        console.log('✓ Limite carregado - Serviço ID:', item.service_id, '| Qtd máx:', item.quantity, '| Valor máx:', item.max_value);
                    });
                    
                    // Filtrar select de peças (category_id = 1)
                    filterServiceSelect('.service-select-1', allowedServiceIds);
                    
                    // Filtrar select de serviços (category_id = 2)  
                    filterServiceSelect('.service-select-2', allowedServiceIds);
                    
                    // Mostrar mensagem com quantidade de itens permitidos
                    var pecasCount = data.service_group_items.filter(function(i) { return i.service && i.service.category_id == 1; }).length;
                    var servicosCount = data.service_group_items.filter(function(i) { return i.service && i.service.category_id == 2; }).length;
                    var msg = '<small class="text-success"><i class="bi bi-check-circle"></i> Grupo com ' + pecasCount + ' peça(s) e ' + servicosCount + ' serviço(s) permitido(s)</small>';
                    $('#div-with-service-group-selection').append(msg);
                    
                    // Aplicar limites aos itens já existentes na lista
                    applyLimitsToExistingItems();
                }
            },
            error: function() {
                $('#div-with-service-group-selection small').remove();
                resetServiceSelects();
                clearServiceGroupLimits();
            }
        });
    }
    
    // Aplicar limites de quantidade aos itens já existentes na lista
    function applyLimitsToExistingItems() {
        console.log('ℹ Aplicando limites aos itens já existentes...');
        var itemsProcessed = 0;
        
        $('.service-select-1, .service-select-2').each(function() {
            var $select = $(this);
            var serviceId = $select.val();
            var serviceName = $select.find('option:selected').text();
            
            if (serviceId && serviceGroupItemLimits[serviceId]) {
                var $row = $select.closest('.row, .nested-fields');
                var $quantityInput = $row.find('.part-service-quantity');
                var maxQty = serviceGroupItemLimits[serviceId].max_quantity;
                
                console.log('  ✓ Aplicando limite ao item: "' + serviceName + '" (ID: ' + serviceId + ') - Máx: ' + maxQty);
                
                $quantityInput.attr('max', maxQty);
                $quantityInput.attr('data-max-qty', maxQty);
                $quantityInput.attr('title', 'Máximo permitido: ' + maxQty);
                
                // Ajustar quantidade se exceder o limite
                var currentQty = parseInt($quantityInput.val()) || 1;
                if (currentQty > maxQty) {
                    console.warn('  ⚠ Ajustando quantidade de ' + currentQty + ' para ' + maxQty);
                    $quantityInput.val(maxQty);
                }
                
                // Remover hint anterior
                $row.find('.quantity-limit-hint').remove();
                
                // Adicionar hint visual do limite
                var $container = $quantityInput.closest('.quantity-field-container');
                if ($container.length === 0) {
                    $container = $quantityInput.closest('.col-md-2, .col-12');
                }
                if ($container.length > 0) {
                    $container.append('<small class="text-muted d-block mt-1 quantity-limit-hint"><i class="bi bi-info-circle"></i> Máx: ' + maxQty + '</small>');
                }
                
                itemsProcessed++;
            }
        });
        
        console.log('✓ Limites aplicados a ' + itemsProcessed + ' item(ns)');
    }
    
    // INICIALIZAÇÃO: Carregar limites automaticamente se já houver um grupo de serviços selecionado
    // Isso é essencial para gestores e adicionais que podem não ter permissão para alterar o campo
    setTimeout(function() {
        var $serviceGroupSelect = $('#order_service_service_group_id');
        if ($serviceGroupSelect.length > 0) {
            var currentGroupId = $serviceGroupSelect.val();
            if (currentGroupId) {
                console.log('Carregando limites do grupo de serviços: ' + currentGroupId);
                loadServiceGroupLimits(currentGroupId);
            }
        }
    }, 500); // Pequeno delay para garantir que a página carregou completamente

    $(document).on('change', '#order_service_service_group_id', function () {
        var service_group_id = $(this).find(":selected").val();
        // Sempre limpar selects antes de carregar novo grupo
        resetServiceSelects();
        clearServiceGroupLimits();
        if (service_group_id) {
            loadServiceGroupLimits(service_group_id);
        } else {
            $('#div-with-service-group-selection small').remove();
        }
    });
    
    // Função para filtrar opções dos selects de serviços
    function filterServiceSelect(selector, allowedIds) {
        console.log('🔍 Filtrando selects: ' + selector + ' | IDs permitidos: ' + allowedIds.join(', '));
        $(selector).each(function() {
            var $select = $(this);
            var currentValue = $select.val();
            
            // Guardar opções ORIGINAIS apenas na primeira vez (antes de qualquer filtragem)
            if (!$select.data('original-options')) {
                $select.data('original-options', $select.find('option').clone());
                console.log('  📋 Salvando opções originais: ' + $select.find('option').length + ' opções');
            }
            
            // Usar sempre as opções ORIGINAIS para filtrar
            var $originalOptions = $select.data('original-options');
            var optionsBefore = $select.find('option').length;
            
            // Limpar todas as opções exceto a primeira (em branco)
            $select.find('option:not(:first)').remove();
            
            var addedCount = 0;
            $originalOptions.each(function() {
                var $opt = $(this);
                var val = $opt.val();
                if (val === '' || allowedIds.indexOf(val) !== -1) {
                    $select.append($opt.clone());
                    if (val !== '') addedCount++;
                }
            });
            
            console.log('  ✓ Select filtrado: ' + optionsBefore + ' opções -> ' + addedCount + ' permitidas');
            
            // Restaurar valor se ainda válido
            if (currentValue && allowedIds.indexOf(currentValue) !== -1) {
                $select.val(currentValue);
            } else {
                $select.val('');
            }
            // Atualizar Select2 se estiver sendo usado
            if ($select.hasClass('select2-hidden-accessible')) {
                $select.trigger('change.select2');
            }
        });
    }
    
    // Função para resetar os selects de serviços (mostrar todas as opções originais)
    function resetServiceSelects() {
        ['.service-select-1', '.service-select-2'].forEach(function(selector) {
            $(selector).each(function() {
                var $select = $(this);
                var $originalOptions = $select.data('original-options');
                if ($originalOptions) {
                    var currentValue = $select.val();
                    $select.find('option:not(:first)').remove();
                    $originalOptions.each(function() {
                        var $opt = $(this);
                        if ($opt.val() !== '') {
                            $select.append($opt.clone());
                        }
                    });
                    $select.val(currentValue);
                    
                    if ($select.hasClass('select2-hidden-accessible')) {
                        $select.trigger('change.select2');
                    }
                }
            });
        });
    }
    
    // Quando um serviço é selecionado, aplicar o limite de quantidade do grupo
    $(document).on('change', '.service-select-1, .service-select-2', function () {
        var serviceId = $(this).val();
        var $row = $(this).closest('.row, .nested-fields');
        var $quantityInput = $row.find('.part-service-quantity');
        var serviceName = $(this).find('option:selected').text();
        
        if (serviceId && serviceGroupItemLimits[serviceId]) {
            var maxQty = serviceGroupItemLimits[serviceId].max_quantity;
            console.log('✓ Aplicando limite ao serviço "' + serviceName + '" (ID: ' + serviceId + ') - Qtd máx: ' + maxQty);
            
            $quantityInput.attr('max', maxQty);
            $quantityInput.attr('data-max-qty', maxQty); // Backup para validação
            $quantityInput.attr('title', 'Máximo permitido: ' + maxQty);
            
            // Se quantidade atual excede o máximo, ajustar
            var currentQty = parseInt($quantityInput.val()) || 1;
            if (currentQty > maxQty) {
                console.warn('⚠ Quantidade atual (' + currentQty + ') excede o máximo. Ajustando para: ' + maxQty);
                $quantityInput.val(maxQty);
            }
            
            // Remover hint anterior
            $row.find('.quantity-limit-hint').remove();
            
            // Adicionar hint visual do limite - buscar container de forma mais flexível
            var $container = $quantityInput.closest('.quantity-field-container');
            if ($container.length === 0) {
                $container = $quantityInput.closest('.col-md-2, .col-12');
            }
            if ($container.length > 0) {
                $container.append('<small class="text-muted d-block mt-1 quantity-limit-hint"><i class="bi bi-info-circle"></i> Máx: ' + maxQty + '</small>');
            }
        } else {
            // Remover limite
            console.log('ℹ Removendo limites do campo (serviço sem restrição)');
            $quantityInput.removeAttr('max');
            $quantityInput.removeAttr('data-max-qty');
            $quantityInput.removeAttr('title');
            $row.find('.quantity-limit-hint').remove();
        }
    });
    
    // Validar quantidade ao digitar - PREVENÇÃO RIGOROSA
    $(document).on('change blur input keyup', '.part-service-quantity', function (e) {
        var $input = $(this);
        
        // Se for campo de texto (Cotações), não validar - permitir texto livre
        if ($input.attr('type') === 'text') {
            return;
        }
        
        var max = parseInt($input.attr('max')) || parseInt($input.attr('data-max-qty'));
        var val = parseInt($input.val());
        var $row = $input.closest('.row, .nested-fields');
        var serviceName = $row.find('.service-select-1, .service-select-2').find('option:selected').text();
        
        // Prevenir valores não numéricos
        if (isNaN(val) || val === '') {
            $input.val(1);
            return;
        }
        
        // Validar mínimo
        if (val < 1) {
            $input.val(1);
            return;
        }
        
        // Validar máximo (grupo de serviços) - FORÇAR LIMITE
        if (max && val > max) {
            console.warn('⚠ LIMITE EXCEDIDO: "' + serviceName + '" - Tentativa: ' + val + ' | Máximo: ' + max);
            $input.val(max);
            $input.addClass('is-invalid');
            
            // Mostrar alerta mais visível
            var $alert = $row.find('.quantity-alert');
            if ($alert.length === 0) {
                var $container = $input.closest('.quantity-field-container, .col-md-2, .col-12');
                $container.append('<div class="text-danger small mt-1 quantity-alert"><i class="bi bi-exclamation-triangle-fill"></i> <strong>Quantidade máxima: ' + max + '</strong></div>');
            }
            
            setTimeout(function() {
                $row.find('.quantity-alert').remove();
                $input.removeClass('is-invalid');
            }, 4000);
        } else {
            $input.removeClass('is-invalid');
            $row.find('.quantity-alert').remove();
        }
    });
    
    // Validar antes de submeter o formulário
    $(document).on('submit', 'form[id*="order_service"]', function(e) {
        var hasError = false;
        var errorMessages = [];
        
        $('.part-service-quantity').each(function() {
            var $input = $(this);
            var max = parseInt($input.attr('max'));
            var val = parseInt($input.val());
            var serviceName = $input.closest('.row, .nested-fields').find('.service-select-1, .service-select-2').find('option:selected').text();
            
            if (max && val > max) {
                hasError = true;
                errorMessages.push('"' + serviceName + '": quantidade ' + val + ' excede o máximo permitido (' + max + ')');
                $input.addClass('is-invalid');
            }
        });
        
        if (hasError) {
            e.preventDefault();
            alert('❌ ERRO: Não é possível salvar a Ordem de Serviço.\n\nOs seguintes itens excedem a quantidade máxima do grupo de serviços:\n\n' + errorMessages.join('\n') + '\n\nAjuste as quantidades para continuar.');
            $('html, body').animate({
                scrollTop: $('.is-invalid').first().offset().top - 100
            }, 500);
            return false;
        }
    });

    $(document).on('change', '#order_service_vehicle_id', function () {
        var vehicle_id = $(this).find(":selected").val();
        findLastOrderServiceByVehicle(vehicle_id);
        loadWarrantyItemsByVehicle(vehicle_id);
        
        // Recarregar empenhos quando veículo muda
        var client_id = $('#order_service_client_id').val();
        if (client_id && vehicle_id) {
            findCommitmentsByVehicle(client_id, vehicle_id, '#order_service_commitment_id');
            // Identificar tipos de empenhos disponíveis
            loadCommitmentTypesByVehicle(client_id, vehicle_id);
        }
    });

    // Carregar tipos de empenhos e mostrar/esconder campos
    function loadCommitmentTypesByVehicle(client_id, vehicle_id) {
        let url = '/get_commitment_types_by_vehicle_id';
        $.ajax({
            url: url,
            dataType: 'json',
            data: {
                vehicle_id: vehicle_id,
                client_id: client_id
            },
            success: function (data) {
                // Mostrar info da subunidade do veículo
                if (data.sub_unit_name) {
                    $('#vehicle-sub-unit-name').text(data.sub_unit_name);
                    $('#vehicle-sub-unit-info').show();
                } else {
                    $('#vehicle-sub-unit-info').hide();
                }
                
                // Separar empenhos por tipo
                // SERVICOS_PECAS_ID = 1, SERVICOS_SERVICOS_ID = 2
                let global_commitments = data.commitments.filter(c => c.category_id === null);
                let parts_commitments = data.commitments.filter(c => c.category_id === 1);
                let services_commitments = data.commitments.filter(c => c.category_id === 2);
                
                // Preencher os selects com os empenhos filtrados
                fillSelect(global_commitments, '#order_service_commitment_id', 'name', null);
                fillSelect(parts_commitments, '#order_service_commitment_parts_id', 'name', null);
                fillSelect(services_commitments, '#order_service_commitment_services_id', 'name', null);
                
                // Mostrar/esconder campos baseado nos tipos disponíveis
                if (data.has_global) {
                    $('#div-with-global-commitment').show();
                    $('#div-with-parts-commitment').hide();
                    $('#div-with-services-commitment').hide();
                } else if (data.has_parts || data.has_services) {
                    $('#div-with-global-commitment').hide();
                    $('#div-with-parts-commitment').show();
                    $('#div-with-services-commitment').show();
                } else {
                    // Se não houver empenhos, esconder todos
                    $('#div-with-global-commitment').hide();
                    $('#div-with-parts-commitment').hide();
                    $('#div-with-services-commitment').hide();
                }
            },
            error: function() {
                // Em caso de erro, mostrar todos os campos e limpar
                fillSelect([], '#order_service_commitment_id', 'name', null);
                fillSelect([], '#order_service_commitment_parts_id', 'name', null);
                fillSelect([], '#order_service_commitment_services_id', 'name', null);
                $('#div-with-global-commitment').show();
                $('#div-with-parts-commitment').show();
                $('#div-with-services-commitment').show();
            }
        });
    }

    let ORDER_SERVICE_CODE = '#order-service-code'
    let ORDER_SERVICE_CREATED_AT = '#order-service-created-at'
    let ORDER_SERVICE_PROVIDER_SERVICE_TYPE = '#order-service-provider-service-type'
    let ORDER_SERVICE_STATUS = '#order-service-status'

    function findLastOrderServiceByVehicle(vehicle_id) {
        let url = '/get_last_order_service_by_vehicle_id';
        $.ajax({
            url: url,
            dataType: 'json',
            async: false,
            data: {
                vehicle_id: vehicle_id
            },
            success: function (data) {
                if(data.result != null){
                    var status_name = data.result.order_service_status ? data.result.order_service_status.name : '-';
                    var provider_service_type_name = data.result.provider_service_type ? data.result.provider_service_type.name : '-';
                    settingOldOrderServiceText(data.result.code, data.result.created_at_formatted, provider_service_type_name, status_name);
                } else {
                    settingOldOrderServiceText('-', '-', '-', '-');
                }
            }
        });
    }

    function settingOldOrderServiceText(code, created_at, provider_service_type, status){
        $(ORDER_SERVICE_CODE).text(code);
        $(ORDER_SERVICE_CREATED_AT).text(created_at);
        $(ORDER_SERVICE_PROVIDER_SERVICE_TYPE).text(provider_service_type);
        $(ORDER_SERVICE_STATUS).text(status);
    }

    function loadWarrantyItemsByVehicle(vehicle_id) {
        if (!vehicle_id) {
            $('#warranty-panel-container').html('');
            return;
        }

        $.ajax({
            url: '/get_warranty_items_by_vehicle_id',
            dataType: 'json',
            data: { vehicle_id: vehicle_id },
            success: function (data) {
                renderWarrantyPanel(data.result);
            },
            error: function() {
                $('#warranty-panel-container').html('');
            }
        });
    }

    function renderWarrantyPanel(items) {
        const container = $('#warranty-panel-container');
        
        if (!items || items.length === 0) {
            container.html('');
            return;
        }

        let html = `
            <div class="card shadow-sm mb-4">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <span><i class="bi bi-shield-check me-2"></i>Itens em garantia deste veículo</span>
                    <span class="text-muted small">Mostrando até 15 registros mais recentes</span>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-sm table-striped align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Tipo</th>
                                    <th>Peça/Serviço</th>
                                    <th>Marca</th>
                                    <th>Código</th>
                                    <th>Valor</th>
                                    <th>Garantia restante</th>
                                    <th>Fornecedor</th>
                                    <th>N° OS</th>
                                </tr>
                            </thead>
                            <tbody>`;

        items.forEach(item => {
            const expiresText = new Date(item.expires_at).toLocaleDateString('pt-BR');
            const value = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.value || 0);
            const typeBadge = item.is_part ? 
                '<span class="badge bg-primary">Peça</span>' : 
                '<span class="badge bg-info">Serviço</span>';
            
            html += `
                <tr>
                    <td>${typeBadge}</td>
                    <td>${item.name || '-'}</td>
                    <td>${item.brand || '-'}</td>
                    <td>${item.code || '-'}</td>
                    <td>${value}</td>
                    <td>
                        <span class="fw-semibold">${item.remaining_days} dias</span>
                        <small class="text-muted">(expira em ${expiresText})</small>
                    </td>
                    <td>${item.provider_name || '-'}</td>
                    <td>
                        ${item.order_service_id ? 
                            `<a href="/order_services/${item.order_service_id}/edit">${item.order_service_code || item.order_service_id}</a>` : 
                            '-'
                        }
                    </td>
                </tr>`;
        });

        html += `
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>`;

        container.html(html);
    }

    let ORDER_SERVICE_FORM_TO_VALIDATE = "form-order-service-to-validate";

    $('.' + ORDER_SERVICE_FORM_TO_VALIDATE).validate({
        onfocusout: function (element) {
            this.element(element);
        },
        rules: {
            'cancel_justification': {
                required: true
            }
        },
        messages: {
            'cancel_justification': {
                required: 'Insira a justificativa.'
            }
        }
    });

    let ACTION_TO_ORDER_SERVICES_LISTING = "action-to-order-services-listing";
    let SELECT_ORDER_SERVICE = "select-order-service";
    let URL_AUTHORIZE_ORDER_SERVICES = "/authorize_order_services";
    let URL_WAITING_PAYMENT_ORDER_SERVICES = "/waiting_payment_order_services";
    let URL_MAKE_PAYMENT_ORDER_SERVICES = "/make_payment_order_services";

    $(document).on('click', '.' + ACTION_TO_ORDER_SERVICES_LISTING, function () {
        actionToOrderServices(this);
    });

    function actionToOrderServices(element) {
        let checkBoxes = $('.' + SELECT_ORDER_SERVICE + ':checkbox:checked').map(function () {
            return this.value;
        }).get();
        let order_service_ids = checkBoxes.join(",");
        if (checkBoxes.length > 0) {
            if (element.id == "authorize-order-services") {
                authorizeSelectedOrderServices(order_service_ids);
            } else if (element.id == "waiting-payment-order-services") {
                waitingPaymentSelectedOrderServices(order_service_ids);
            } else if (element.id == "make-payment-order-services") {
                makePaymentSelectedOrderServices(order_service_ids);
            }
        } else {
            alert("Selecione ao menos uma ordem de serviço");
        }
    }

    function authorizeSelectedOrderServices(order_service_ids) {
        let confirm = window.confirm("Você tem certeza?");
        if (confirm) {
            $.ajax({
                url: URL_AUTHORIZE_ORDER_SERVICES,
                dataType: 'json',
                type: 'post',
                data: {
                    order_service_ids: order_service_ids
                },
                async: false,
                success: function (data) {
                    alert(data.message);
                    if (data.result) {
                        window.location = window.location;
                    }
                }
            });
        }
    }

    function waitingPaymentSelectedOrderServices(order_service_ids) {
        let confirm = window.confirm("Você tem certeza?");
        if (confirm) {
            $.ajax({
                url: URL_WAITING_PAYMENT_ORDER_SERVICES,
                dataType: 'json',
                type: 'post',
                data: {
                    order_service_ids: order_service_ids
                },
                async: false,
                success: function (data) {
                    alert(data.message);
                    if (data.result) {
                        window.location = window.location;
                    }
                }
            });
        }
    }

    function makePaymentSelectedOrderServices(order_service_ids) {
        let confirm = window.confirm("Você tem certeza?");
        if (confirm) {
            $.ajax({
                url: URL_MAKE_PAYMENT_ORDER_SERVICES,
                dataType: 'json',
                type: 'post',
                data: {
                    order_service_ids: order_service_ids
                },
                async: false,
                success: function (data) {
                    alert(data.message);
                    if (data.result) {
                        window.location = window.location;
                    }
                }
            });
        }
    }  

    var form        = document.getElementById('order-service-proposal-form');
    var triggerBtn  = document.getElementById('btn-save-and-submit');
    var confirmBtn  = document.getElementById('btn-confirm-submit');
    var modalEl     = document.getElementById('confirmSubmitModal');
    var confirmText = document.getElementById('confirmSubmitText');

    if (!form || !triggerBtn || !confirmBtn || !modalEl) return;

    // Ao abrir o modal via botão:
    triggerBtn.addEventListener('click', function () {
        // Ajusta o texto do modal (se quiser trocar por botão)
        if (this.dataset.confirmText) {
        confirmText.textContent = this.dataset.confirmText;
        }
        // Passa o name/value desejados para o botão de confirmar
        confirmBtn.dataset.paramName  = this.dataset.paramName || 'save_and_submit';
        confirmBtn.dataset.paramValue = this.dataset.paramValue || '';
    });

    // Ao confirmar no modal:
    confirmBtn.addEventListener('click', function () {
        var paramName  = this.dataset.paramName;
        var paramValue = this.dataset.paramValue;

        // Remove hiddens anteriores (evitar duplicados)
        Array.from(form.querySelectorAll('input[type="hidden"][name="' + paramName + '"]'))
            .forEach(function (el) { el.remove(); });

        // Cria o hidden com o name/value do botão original
        var hidden = document.createElement('input');
        hidden.type  = 'hidden';
        hidden.name  = paramName;
        hidden.value = paramValue;
        form.appendChild(hidden);

        // Evita duplo clique
        confirmBtn.disabled = true;
        triggerBtn.disabled = true;

        // Fecha modal e submete
        var modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();

        console.log('Submitting form with ' + paramName + '=' + paramValue);

        form.submit();
    });

    // Quando uma nova linha de peça/serviço é adicionada, aplicar limites do grupo
    $(document).on('cocoon:after-insert', function(e, insertedItem) {
        // Reforçar filtro dos selects da nova linha para mostrar só itens do grupo
        var serviceGroupId = $('#order_service_service_group_id').val();
        console.log('🆕 Nova linha adicionada. Grupo de serviço selecionado: ' + serviceGroupId);
        
        if (serviceGroupId) {
            $.ajax({
                url: '/service_groups/' + serviceGroupId + '.json',
                dataType: 'json',
                success: function (data) {
                    if (data && data.service_group_items) {
                        var allowedServiceIds = data.service_group_items.map(function(item) {
                            return item.service_id.toString();
                        });
                        console.log('🔒 Filtrando nova linha. IDs permitidos: ' + allowedServiceIds.join(', '));
                        
                        // Filtrar cada select da nova linha individualmente
                        insertedItem.find('.service-select-1, .service-select-2').each(function() {
                            var $select = $(this);
                            var currentValue = $select.val();
                            var optionsBefore = $select.find('option').length;
                            
                            // Remover opções não permitidas
                            $select.find('option').each(function() {
                                var $opt = $(this);
                                var val = $opt.val();
                                if (val !== '' && allowedServiceIds.indexOf(val) === -1) {
                                    $opt.remove();
                                }
                            });
                            
                            var optionsAfter = $select.find('option').length;
                            console.log('  ✓ Select filtrado: ' + optionsBefore + ' -> ' + optionsAfter + ' opções');
                        });
                    }
                }
            });
        }
        // Disparar o evento change nos selects da nova linha para aplicar limites
        insertedItem.find('.service-select-1, .service-select-2').trigger('change');
    });

    // ==================== FORNECEDORES DIRECIONADOS ====================
    
    var directedProvidersData = []; // Cache dos fornecedores carregados
    var selectedProviderIds = []; // IDs dos fornecedores selecionados
    
    // Inicializar IDs pré-selecionados (modo edição)
    $('.directed-provider-hidden').each(function() {
        selectedProviderIds.push(parseInt($(this).val()));
    });

    // Toggle do painel de fornecedores direcionados
    $(document).on('change', '#directed_providers_toggle', function() {
        if ($(this).is(':checked')) {
            $('#directed-providers-panel').removeClass('d-none');
            loadDirectedProviders();
        } else {
            $('#directed-providers-panel').addClass('d-none');
            clearDirectedProviders();
        }
    });

    // Se já estava marcado na inicialização (modo edição), mostrar painel
    if ($('#directed_providers_toggle').is(':checked')) {
        $('#directed-providers-panel').removeClass('d-none');
        // Carregar fornecedores após um pequeno delay para garantir que a página carregou
        setTimeout(function() { loadDirectedProviders(); }, 300);
    }

    // ===== DIAGNÓSTICO: Fluxo de "Enviar para Cotação" em 2 passos =====
    // Passo 1: Clica no botão → abre painel de fornecedores com toggle ativado
    $(document).on('click', '#btn-release-to-quotation-step1', function() {
        // Ativar toggle e expandir painel de fornecedores
        var $toggle = $('#directed_providers_toggle');
        if (!$toggle.is(':checked')) {
            $toggle.prop('checked', true).trigger('change');
        }

        // Garantir que o container está visível
        $('#div-with-directed-providers').removeClass('d-none').show();
        $('#directed-providers-panel').removeClass('d-none');

        // Carregar fornecedores
        loadDirectedProviders();

        // Scroll até o painel de fornecedores
        $('html, body').animate({
            scrollTop: $('#div-with-directed-providers').offset().top - 100
        }, 500);

        // Esconder botão passo 1, mostrar botão de confirmação
        $(this).addClass('d-none');
        $('#btn-release-to-quotation-confirm').removeClass('d-none');

        // Mostrar instrução ao usuário
        if ($('#directed-providers-instruction').length === 0) {
            $('#div-with-directed-providers .card-header').append(
                '<div id="directed-providers-instruction" class="alert alert-info mt-2 mb-0 py-1 small">' +
                '<i class="bi bi-info-circle"></i> <strong>Selecione os fornecedores</strong> que poderão cotar esta OS. ' +
                'Depois clique em <strong>"✓ Confirmar e Enviar para Cotação"</strong> no final da página.</div>'
            );
        }
    });

    // Também recarregar quando mudar o tipo de serviço
    $(document).on('change', '#order_service_provider_service_type_id', function() {
        var osType = $('#order_service_order_service_type_id').val();
        // Cotações, Requisição, ou Diagnóstico pronto para liberar cotação
        if (osType == '1' || osType == '3' || (osType == '2' && $('#diagnostico_ready_for_release').val() === 'true')) {
            loadDirectedProviders();
        }
    });

    // Busca/filtro de fornecedores
    $(document).on('input', '#directed-providers-search', function() {
        var searchText = $(this).val().toLowerCase();
        filterDirectedProvidersList(searchText, $('#directed-providers-state-filter').val());
    });

    // Filtro por estado
    $(document).on('change', '#directed-providers-state-filter', function() {
        var state = $(this).val();
        filterDirectedProvidersList($('#directed-providers-search').val().toLowerCase(), state);
    });

    // Selecionar todos (visíveis)
    $(document).on('click', '#directed-providers-select-all', function() {
        $('#directed-providers-list .directed-provider-checkbox:visible:not(:checked)').each(function() {
            $(this).prop('checked', true).trigger('change');
        });
    });

    // Desselecionar todos
    $(document).on('click', '#directed-providers-deselect-all', function() {
        $('#directed-providers-list .directed-provider-checkbox:checked').each(function() {
            $(this).prop('checked', false).trigger('change');
        });
    });

    // Ao marcar/desmarcar um fornecedor
    $(document).on('change', '.directed-provider-checkbox', function() {
        var providerId = parseInt($(this).val());
        if ($(this).is(':checked')) {
            if (selectedProviderIds.indexOf(providerId) === -1) {
                selectedProviderIds.push(providerId);
            }
        } else {
            selectedProviderIds = selectedProviderIds.filter(function(id) { return id !== providerId; });
        }
        updateDirectedProvidersHiddenFields();
        updateDirectedProvidersCount();
    });

    // Carregar fornecedores via AJAX
    function loadDirectedProviders() {
        if (!$('#directed_providers_toggle').is(':checked')) return;
        
        var clientId = $('#order_service_client_id').val();
        var providerServiceTypeId = $('#order_service_provider_service_type_id').val();
        
        if (!providerServiceTypeId) {
            $('#directed-providers-list').html(
                '<p class="text-muted text-center py-3"><i class="bi bi-info-circle"></i> Selecione o tipo de serviço para carregar os fornecedores disponíveis.</p>'
            );
            return;
        }
        
        $('#directed-providers-loading').removeClass('d-none');
        $('#directed-providers-list').html('');
        $('#directed-providers-empty').addClass('d-none');

        $.ajax({
            url: '/get_providers_for_directed_selection',
            dataType: 'json',
            data: {
                client_id: clientId,
                provider_service_type_id: providerServiceTypeId
            },
            success: function(data) {
                directedProvidersData = data;
                $('#directed-providers-loading').addClass('d-none');
                
                if (data.length === 0) {
                    $('#directed-providers-list').html(
                        '<p class="text-muted text-center py-3"><i class="bi bi-exclamation-circle"></i> Nenhum fornecedor encontrado para o tipo de serviço e estados configurados.</p>'
                    );
                    return;
                }

                // Montar lista de estados para o filtro
                var states = [];
                data.forEach(function(p) {
                    if (states.indexOf(p.state) === -1) states.push(p.state);
                });
                states.sort();
                var stateFilter = $('#directed-providers-state-filter');
                stateFilter.html('<option value="">Todos os estados</option>');
                states.forEach(function(s) {
                    stateFilter.append('<option value="' + s + '">' + s + '</option>');
                });

                renderDirectedProvidersList(data);
                updateDirectedProvidersCount();
            },
            error: function() {
                $('#directed-providers-loading').addClass('d-none');
                $('#directed-providers-list').html(
                    '<p class="text-danger text-center py-3"><i class="bi bi-exclamation-triangle"></i> Erro ao carregar fornecedores. Tente novamente.</p>'
                );
            }
        });
    }

    // Renderizar a lista de fornecedores agrupados por estado
    function renderDirectedProvidersList(providers) {
        // Agrupar por estado
        var grouped = {};
        providers.forEach(function(p) {
            var state = p.state || 'Não informado';
            if (!grouped[state]) grouped[state] = [];
            grouped[state].push(p);
        });

        var html = '';
        var sortedStates = Object.keys(grouped).sort();
        
        sortedStates.forEach(function(state) {
            html += '<div class="directed-providers-state-group mb-2" data-state="' + state + '">';
            html += '<div class="bg-light rounded px-2 py-1 mb-1">';
            html += '<strong><i class="bi bi-geo-alt"></i> ' + state + '</strong>';
            html += '<span class="badge bg-secondary ms-2">' + grouped[state].length + '</span>';
            html += '</div>';
            
            grouped[state].forEach(function(provider) {
                var isChecked = selectedProviderIds.indexOf(provider.id) !== -1;
                html += '<div class="form-check ms-3 directed-provider-item" data-name="' + provider.name.toLowerCase() + '" data-city="' + (provider.city || '').toLowerCase() + '" data-state="' + state + '">';
                html += '<input class="form-check-input directed-provider-checkbox" type="checkbox" value="' + provider.id + '" id="directed_provider_' + provider.id + '"' + (isChecked ? ' checked' : '') + '>';
                html += '<label class="form-check-label" for="directed_provider_' + provider.id + '">';
                html += provider.name;
                if (provider.city) {
                    html += ' <small class="text-muted">(' + provider.city + ')</small>';
                }
                html += '</label>';
                html += '</div>';
            });
            
            html += '</div>';
        });

        $('#directed-providers-list').html(html);
    }

    // Filtrar lista de fornecedores por texto e estado
    function filterDirectedProvidersList(searchText, stateFilter) {
        searchText = searchText || '';
        stateFilter = stateFilter || '';

        $('#directed-providers-list .directed-provider-item').each(function() {
            var name = $(this).data('name') || '';
            var city = $(this).data('city') || '';
            var state = $(this).data('state') || '';
            
            var matchesSearch = !searchText || 
                name.indexOf(searchText) !== -1 || 
                city.indexOf(searchText) !== -1 ||
                state.toLowerCase().indexOf(searchText) !== -1;
            var matchesState = !stateFilter || state === stateFilter;
            
            $(this).toggle(matchesSearch && matchesState);
        });

        // Mostrar/ocultar cabeçalhos de estado sem itens visíveis
        $('#directed-providers-list .directed-providers-state-group').each(function() {
            var hasVisible = $(this).find('.directed-provider-item:visible').length > 0;
            $(this).toggle(hasVisible);
        });
    }

    // Atualizar campos hidden com IDs selecionados
    function updateDirectedProvidersHiddenFields() {
        var container = $('#directed-providers-hidden-fields');
        container.html('');
        selectedProviderIds.forEach(function(id) {
            container.append('<input type="hidden" name="order_service[directed_provider_ids][]" value="' + id + '" class="directed-provider-hidden">');
        });
    }

    // Atualizar contador de selecionados
    function updateDirectedProvidersCount() {
        var count = selectedProviderIds.length;
        var text = count + ' selecionado(s)';
        $('#directed-providers-count').text(text);
        if (count > 0) {
            $('#directed-providers-count').removeClass('bg-primary').addClass('bg-success');
        } else {
            $('#directed-providers-count').removeClass('bg-success').addClass('bg-primary');
        }
    }

    // Limpar seleção de fornecedores direcionados
    function clearDirectedProviders() {
        selectedProviderIds = [];
        updateDirectedProvidersHiddenFields();
        updateDirectedProvidersCount();
        $('#directed-providers-list .directed-provider-checkbox').prop('checked', false);
        // Desmarcar o toggle
        $('#directed_providers_toggle').prop('checked', false);
    }
    
});
