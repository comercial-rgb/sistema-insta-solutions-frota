/*
* REGRAS:
* - a div a ser clonada deverá ter a classe multi-nome
* - a div deverá ter o hidden multi-nome-cont começando com zero
* - o botão de adicionar terá a classe multi-nome-add
* - o botão de deletar terá a classe multi-nome-del
*/

window.addEventListener('DOMContentLoaded', () => {
    multi('person-contact', true);
    multi('subunit', true);
    multi('orderserviceproposalitempart', true);
    multi('orderserviceproposalitemservice', true);
    multi('providerservicetemp', true);
    multi('orderserviceinvoice', true);
    multi('addendumcontract', true);
    multi('cancelcommitment', true);
    multi('partserviceordeservicepecas', true);
    multi('partserviceordeserviceservicos', true);
    // multi('subcategory', true);
    // multi('attachment', true);
    // multi('card', true);
    // multi('data-bank', true);
    // multi('email', true);
    // multi('phone', true);
    // multi('plan-service', true);
});

function multi(nome, enableDel){
    var item      = '.multi-' + nome;
    var addButton = '.multi-' + nome + '-add';
    var delButton = '.multi-' + nome + '-del';
    var contEl    = '.multi-' + nome + '-cont';

    //ao clicar no botão de adicionar
    $(document).on('click', addButton, function(){
        //incrementa-se o cont
        if (addButton == '.multi-orderserviceproposalitempart-add' || addButton == '.multi-orderserviceproposalitemservice-add'){
            var cont = $('#multi-order_service_proposal_items-cont').val();
            cont++;
            $('#multi-order_service_proposal_items-cont').val(cont);
        } else {
            // usa um identificador longo para evitar colisão de índices em formulários grandes
            var cont = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
            $(contEl).val(cont);
        }

        //clona-se a div
        var clone = $(item).last().clone();

        //pra cada input, select e textarea
        clone.find('input, select, textarea, checkbox, label, hidden, div').each(function(index, el) {
            
            if($(this).is("label")) {
                // Atualizando o atributo for
                if ($(this).attr("for")) {
                    let new_for = $(this).attr("for").replace(/\d+/g, cont);
                    $(this).attr("for", new_for);
                }
            } else if ($(this).is("div")) {
                this.id = this.id.replace(/\d+/g, cont);
            } else {
                //muda-se o id e o nome
                this.name = this.name.replace(/\d+/g, cont);
                this.id = this.id.replace(/\d+/g, cont);
                
                if( $(this).hasClass('complete-phone-ddd') ){
                    $(this).unmask();
                    $(this).inputmask({
                        mask: ["(99) 9999-9999", "(99) 99999-9999" ],
                        keepStatic: true
                    });
                } else if( $(this).hasClass('money') ){
                    $(this).unmask();
                    $(this).mask("000.000.000.000,00", {reverse: true});
                }  else if ($(this).hasClass('chosen') || $(this).hasClass('select2') || $(this).hasClass('select')) {
                    $(this).select2();
                    $(this).val('').trigger('change');
                    $(this).next().next().remove();
                } else if( $(this).hasClass('cep') ){
                    $(this).unmask();
                    $(this).inputmask({
                        mask: "99.999-999",
                        keepStatic: true,
                        positionCaretOnTab: true
                    }); 
                } else if( $(this).hasClass('cpf') ){
                    $(this).inputmask({
                        mask: "999.999.999-99",
                        keepStatic: true,
                        positionCaretOnTab: true
                    }); 
                } else if( $(this).hasClass('datepicker') ){
                    $(this).datepicker({
                        format: 'dd/mm/yyyy',
                        language: 'pt-BR',
                        todayHighlight: true
                    });

                    $(this).inputmask({
                        mask: "99/99/9999",
                        keepStatic: true,
                        positionCaretOnTab: true
                    }); 
                } else if( $(this).hasClass('datetimepicker') ){
                    flatpickr(this, settings.flatpickr);
                }
                if(!$(this).hasClass('hidden')){
                    //limpa o valor
                    this.value = '';
                }
                if ($(this).hasClass('order_service_proposal_item_total_value_part') || $(this).hasClass('order_service_proposal_item_total_value_service') || ($(this).hasClass('order_service_proposal_item_discount_part') || $(this).hasClass('order_service_proposal_item_discount_service'))) {
                    // Limpando os valores de desconto e total da área de proposta de peças/serviços
                    $(this).val(0);
                }
                if ($(this).hasClass('order_service_proposal_item_quantity') || $(this).hasClass('provider_service_temp_quantity')) {
                    $(this).val(1);
                }
                if($(this).is(":checkbox")) {
                    $(this).prop('checked', false);
                }
            }
        });

        //coloca-se no parent
        clone.appendTo( $(item).parent() );
        $('select').select2();
        $(".select2icon").select2({
            escapeMarkup: function (markup) { return markup; }
        });
        
        $(".money").maskMoney({
            prefix: "R$ ",
            showSymbol: true,
            decimal: ",",
            thousands: ".",
            symbolStay: true,
            selectAllOnFocus: true
        });

        // Apenas para o cadastro de notas fiscais (show_order_service_proposal) (para validar o botão de salvar)
        validateInvoiceInputs();
        updateTotalValues();
        
        refreshTooltipFields();
        
        // Filtrar selects de peças/serviços para mostrar apenas itens do grupo selecionado
        if (nome === 'partserviceordeservicepecas' || nome === 'partserviceordeserviceservicos') {
            var serviceGroupId = $('#order_service_service_group_id').val();
            if (serviceGroupId) {
                $.ajax({
                    url: '/service_groups/' + serviceGroupId + '.json',
                    dataType: 'json',
                    async: false,
                    success: function (data) {
                        if (data && data.service_group_items) {
                            var allowedServiceIds = data.service_group_items.map(function(item) {
                                return item.service_id.toString();
                            });
                            // Filtrar o select clonado
                            clone.find('.service-select-1, .service-select-2').each(function() {
                                var $select = $(this);
                                $select.find('option').each(function() {
                                    var $opt = $(this);
                                    var val = $opt.val();
                                    if (val !== '' && allowedServiceIds.indexOf(val) === -1) {
                                        $opt.remove();
                                    }
                                });
                            });
                        }
                    }
                });
            }
        }

        //para não dar submit
        return false;
    });

    //caso o parâmetro de ativação do botão de exclusão do item seja falso, o gatilho de execução
    //deverá ser reescrito. Isso é útil para quando houverem outras operações além de remover o
    //item, como cálculos.
    if(enableDel){
        $(document).on('click', delButton, function() {
            //verificação que impede a exclusão de quando houve apenas um item
            if($(item).length > 1){
                //após o fade, remove o item
                $(this).parent().parent().fadeOut('fast', function(){
                    $(this).remove();
                    // Apenas para o cadastro de notas fiscais (show_order_service_proposal) (para validar o botão de salvar)
                    updateButtonSaveInvoiceDataState();
                    updateTotalValues();
                });
            }
            return false;
        });
    }
}