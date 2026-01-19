function toggleIcon(e) {
	$(e.target)
	.prev('.panel-heading')
	.find(".more-less")
	.toggleClass('fa-plus fa-minus');
}

function hideElement(object, hide){
	if(hide){
		$('#'+object).hide().attr("hidden","true").addClass("invisible").removeClass("visible");
		$('.'+object).hide().attr("hidden","true").addClass("invisible").removeClass("visible");
	} else {
		$('#'+object).show().removeAttr('hidden').addClass("visible").removeClass("invisible");
		$('.'+object).show().removeAttr('hidden').addClass("visible").removeClass("invisible");
	}
	$('select').select2();
}

function disableElement(element, disable){
	$('#'+element).prop("readOnly", disable).prop("disabled", disable);
	$('.'+element).prop("readOnly", disable).prop("disabled", disable);
	if(disable){
		$('#'+element).addClass("disabled");
		$('.'+element).addClass("disabled");
	} else {
		$('#'+element).removeClass("disabled");
		$('.'+element).removeClass("disabled");
	}
}

/* Formatar Dinheiro */
function formatToCurrency(value) {
	if(isNaN(value)){
		val = 0;
	}
	return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

/* Buscar valor em integer recebendo valor em dinheiro formatado */
function getMoney( str )
{
	return parseInt( str.replace(/[\D]+/g,'') );
}

/* Preencher select com as opções enviadas por parâmetro
  values: array de opções
  select_to_populate: id do select que receberá as opções
  attribute: qual será o atributo de texto da opção (name, fantasy_name, etc)
  value_to_select: caso possua um valor a já ser selecionado
  */
function fillSelect(values, select_to_populate, attribute, value_to_select){
	let option_template = '<option :selected value=":id">:text</option>';
	let options = [];
	options.push(option_template.replace(':id', "").replace(':text', '-- Selecione um opção --').replace(':selected', ""));

	$.each(values, function (index, current) {
		selected = ""
		if (current.id == value_to_select) {
			selected = "selected"
		}
		options.push(option_template.replace(':id', current.id).replace(':text', current[attribute]).replace(':selected', selected));
	});
	$(select_to_populate).html(options.join(''));
	$(select_to_populate).select2();
}

/* Preencher select com as opções enviadas por parâmetro
  values: array de opções
  select_to_populate: id do select que receberá as opções
  attribute_parent: label/text do pai do grupo <optgroup>
  attribute_children: label/text da opção <option>
  */
function fillSelectMultiple(values, select_to_populate, attribute_parent, attribute_children){
	let select_options = [];
	for(let i = 0; i < values.length; i++){
		let current_parent = values[i];
		let parent = $("<optgroup>", {"label": current_parent[attribute_parent]});
		for(let j = 0; j < values[i].options.length; j++){
			let current_option = values[i].options[j];
			let option = $("<option>", {"label": current_option[attribute_children], "id": current_option.id, "text": current_option[attribute_children]});
			parent.append(option);
		}
		select_options.push(parent);
	}
	$(select_to_populate).html(select_options);
	$(select_to_populate).select2();
}

let URL_FIND_CEP = '/find_cep';
let URL_FIND_BY_STATE = '/states/:state_id/cities.json';
let URL_FIND_BY_COUNTRY = '/countries/:country_id/states.json';

// Preenchendo os dados corretos nos campos de endereço após a busca pelo CEP
function fill_values_after_cep_find(data, address_id, district_id, selectState, state_id, city_id){
	$('#'+address_id).val(data.address.address);
	$('#'+district_id).val(data.address.neighborhood);

	$("#"+state_id).find("option").filter(function(index) {
		return selectState === $(this).text();
	}).prop("selected", "selected");
	$('#'+state_id).select2();

	let selectCity = data.address.city;
	$("#"+city_id).find("option").filter(function(index) {
		return selectCity === $(this).text();
	}).prop("selected", "selected");
	$('#'+city_id).select2();
}

// Buscar todas as cidades de um Estado
function find_by_state(state_id, select_to_populate){
	let url = URL_FIND_BY_STATE.replace(':state_id', state_id);
	$.ajax({
		url: url,
		dataType: 'json',
		async: false,
		success: function(values) {
			fillSelect(values, select_to_populate, 'name', null);
		}
	});
}

// Buscar todas as cidades de um Estado
function find_by_country(country_id, select_to_populate){
	let url = URL_FIND_BY_COUNTRY.replace(':country_id', country_id);
	$.ajax({
		url: url,
		dataType: 'json',
		async: false,
		success: function(values) {
			fillSelect(values, select_to_populate, 'name', null);
		}
	});
}

// Buscar o endereço completo baseado no cep
function find_by_cep(cep, address_id, district_id, state_id, city_id){
	if(cep != null && cep != ''){
		$.ajax({
			url: URL_FIND_CEP,
			dataType: 'json',
			async: false,
			data: {
				cep: cep
			},
			success: function(data) {
				let selectState = data.address.state
				fill_values_after_cep_find(data, address_id, district_id, selectState, state_id, city_id);
			}
		});
	}
}

// Busca por subcategorias
let URL_FIND_BY_CATEGORY = '/get_subcategories/:category_id';
function find_by_category(category_id, select_to_populate){
	let url = URL_FIND_BY_CATEGORY.replace(':category_id', category_id);
	$.ajax({
		url: url,
		dataType: 'json',
		async: false,
		success: function(data) {
			fillSelect(data.result, select_to_populate, 'name', null);
		}
	});
}

// Copiando texto de um input
function copyInputTextToClipboard(text_id) {
    /* Get the text field */
	var copyText = document.getElementById(text_id);

    /* Select the text field */
	copyText.select();
    copyText.setSelectionRange(0, 99999); /* For mobile devices */

    /* Copy the text inside the text field */
	document.execCommand("copy");

    /* Alert the copied text */
	alert("Copiado com sucesso!");
}

// Getting initial week day by date (today.GetFirstDayOfWeek())
Date.prototype.GetFirstDayOfWeek = function() {
  return (new Date(this.setDate(this.getDate() - this.getDay()+ (this.getDay() == 0 ? -6:1) )));
}

// Getting final week day date (today.GetLastDayOfWeek())
Date.prototype.GetLastDayOfWeek = function() {
  return (new Date(this.setDate(this.getDate() - this.getDay() +7)));
}

function telefoneBrasilValido(telefone) {
    //retira todos os caracteres menos os numeros
    telefone = telefone.replace(/\D/g, '');

    //verifica se tem a qtde de numero correto
    if (!(telefone.length >= 10 && telefone.length <= 11)) return false;

    //Se tiver 11 caracteres, verificar se começa com 9 o celular
    if (telefone.length == 11 && parseInt(telefone.substring(2, 3)) != 9) return false;

    //verifica se não é nenhum numero digitado errado (propositalmente)
    for (var n = 0; n < 10; n++) {
        //um for de 0 a 9.
        //estou utilizando o metodo Array(q+1).join(n) onde "q" é a quantidade e n é o
        //caractere a ser repetido
        if (telefone == new Array(11).join(n) || telefone == new Array(12).join(n)) return false;
    }
    //DDDs validos
    var codigosDDD = [11, 12, 13, 14, 15, 16, 17, 18, 19,
        21, 22, 24, 27, 28, 31, 32, 33, 34,
        35, 37, 38, 41, 42, 43, 44, 45, 46,
        47, 48, 49, 51, 53, 54, 55, 61, 62,
        64, 63, 65, 66, 67, 68, 69, 71, 73,
        74, 75, 77, 79, 81, 82, 83, 84, 85,
        86, 87, 88, 89, 91, 92, 93, 94, 95,
        96, 97, 98, 99];
    //verifica se o DDD é valido (sim, da pra verificar rsrsrs)
    if (codigosDDD.indexOf(parseInt(telefone.substring(0, 2))) == -1) return false;

    //  E por ultimo verificar se o numero é realmente válido. Até 2016 um celular pode
    //ter 8 caracteres, após isso somente numeros de telefone e radios (ex. Nextel)
    //vão poder ter numeros de 8 digitos (fora o DDD), então esta função ficará inativa
    //até o fim de 2016, e se a ANATEL realmente cumprir o combinado, os numeros serão
    //validados corretamente após esse período.
    //NÃO ADICIONEI A VALIDAÇÂO DE QUAIS ESTADOS TEM NONO DIGITO, PQ DEPOIS DE 2016 ISSO NÃO FARÁ DIFERENÇA
    //Não se preocupe, o código irá ativar e desativar esta opção automaticamente.
    //Caso queira, em 2017, é só tirar o if.
    if (new Date().getFullYear() < 2017) return true;
    if (telefone.length == 10 && [2, 3, 4, 5, 7].indexOf(parseInt(telefone.substring(2, 3))) == -1) return false;

    //se passar por todas as validações acima, então está tudo certo
    return true;
}

// Avançando com o focus em inputs dentro de um formulário
function nextFocus(){
	let focussableElements = 'a:not([disabled]), button:not([disabled]), input[type=text]:not([disabled]), [tabindex]:not([disabled]):not([tabindex="-1"])';
	if (document.activeElement && document.activeElement.form) {
		let focussable = Array.prototype.filter.call(document.activeElement.form.querySelectorAll(focussableElements),
			function (element) {
				return element.offsetWidth > 0 || element.offsetHeight > 0 || element === document.activeElement
			});
		let index = focussable.indexOf(document.activeElement);
		if(index > -1) {
			let nextElement = focussable[index + 1] || focussable[0];
			nextElement.focus();
		}
	}
}

function uncheckAllCheckboxesByClass(divClass) {
	// Select the parent div by class
	const parentDivs = document.getElementsByClassName(divClass);

	// Iterate over each div with the specified class
	Array.from(parentDivs).forEach(parentDiv => {
		// Select all input elements within the current div
		const checkboxes = parentDiv.querySelectorAll('input[type="checkbox"]');
		// Iterate over each checkbox and set checked to false
		checkboxes.forEach(checkbox => {
			checkbox.checked = false;
		});
	});
}

function findSubUnitsByCostCenters(cost_center_id, select_sub_unit_id){
	let url = '/get_sub_units_by_cost_center_id';
	$.ajax({
		url: url,
		dataType: 'json',
		async: false,
		data: {
			cost_center_id: cost_center_id
		},
		success: function(data) {
			fillSelect(data.result, select_sub_unit_id, 'name', null);
		}
	});
}