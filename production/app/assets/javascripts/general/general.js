const settings = {
	flatpickr: {
		locale: 'pt',
		monthSelectorType: 'static',
		enableTime: true,
		disableMobile: true,
		dateFormat: 'd/m/Y H:i'
	}
}

$(document).ready(() => {
	
	// Bloqueando digitar tecla espaço
	$('.no-space').keydown(function(event) {
		if(event.which == 32)
			return false;
	});

	// Mudando o idioma do projeto
	$('.change_locale').on('change', function () {
		let id = $(this).find(":selected").val();
		window.location = '/update_locale/'+id;
	});

	// Avançando no input do formulário se estiver com o focus no campo de CEP para não enviar o formulário
	$(document).keydown(function(event) {
		let keyCode = (event.keyCode ? event.keyCode : event.which);
		if (keyCode == 13) {
			if($(document.activeElement) != null && $(document.activeElement).hasClass('cep')){
				nextFocus();
				return false;
			}
		}
	});

	// Selecionando ou não todos os checkboxes de acordo com a class
	let SELECT_ALL_REGISTERS = "select-all-registers";
	let SELECT_REGISTER = "select-register";
	$(document).on('click', '.'+SELECT_ALL_REGISTERS, function(){
		let checkBoxes = $("."+SELECT_REGISTER);
		checkBoxes.prop("checked", this.checked);
	});

	// Selecionando ou não todos os checkboxes de acordo com a class
	let SELECT_ALL_CHECKBOXES = "select-all-checkboxes";
	let CHECK_BOX_TAG = "check-box-tag-";
	$(document).on('click', '.'+SELECT_ALL_CHECKBOXES, function(){
		let id = this.id.split("-")[3];
		let checkBoxes = $("."+CHECK_BOX_TAG+id);
		checkBoxes.prop("checked", this.checked);
	});

	// Recarrega a página sempre que voltar manualmente ou avançar manualmente pelo navegador
	// $(window).on('pageshow', function (evt) {
	//   if (evt.persisted || window.performance && window.performance.navigation.type == 2) {
	//     location.reload();
	//   }
	// });

	/**
  - Mostrar HTML dentro de options do select
  
  Exemplo no model de PRODUCT
  <%= f.association :category,
  collection: Category.order(:name),
  as: :select, include_blank: t("model.select_option"),
  label_method: :get_html_text,
  input_html: {class: 'select2icon'} %>
  */
	$(".select2icon").select2({
		escapeMarkup: function (markup) { return markup; }
	});

	// Filtragem de radiobutton/checkboxes por texto
	let REGISTER_FILTER_TEXT = 'collection-filter-by-text';
	let LINKED_FILTER = 'linked-filter-';

	$("."+REGISTER_FILTER_TEXT).on("keyup", function() {
		let value = $(this).val().toLowerCase();
		let register_name = this.id.split("#")[1];

		$("."+LINKED_FILTER+register_name).filter(function() {
			let label_text = $(this).children().children("span").first().text();
			if(label_text.toUpperCase().indexOf(value.toUpperCase()) > -1){
				$(this).toggle(true);
			} else {
				$(this).toggle(false);
			}
		});
	});

	// Filtragem de códigos por texto
	let CODES_FILTER_TEXT = 'codes-filter-by-text';
	let LINKED_FILTER_CODE = 'linked-filter-code';

	$("."+CODES_FILTER_TEXT).on("keyup", function() {
		let value = $(this).val().toLowerCase();
		let register_name = this.id.split("#")[1];

		$("."+LINKED_FILTER_CODE).filter(function() {
			let label_text = $(this).text();
			if(label_text.toUpperCase().indexOf(value.toUpperCase()) > -1){
				$(this).toggle(true);
			} else {
				$(this).toggle(false);
			}
		});
	});

	$('.datatable-order-service-historic').DataTable({
		"lengthMenu": [100, 500, 1000, 2000, 30000, 60000, 90000, null],
		"pageLength": 2000,
		"order": [],
		"language": {
			"sEmptyTable": "Nenhum registro encontrado",
			"sInfo": "Mostrando de _START_ até _END_ de _TOTAL_ registros",
			"sInfoEmpty": "Mostrando 0 até 0 de 0 registros",
			"sInfoFiltered": "(Filtrados de _MAX_ registros)",
			"sInfoPostFix": "",
			"sInfoThousands": ".",
			"sLengthMenu": "_MENU_ resultados por página",
			"sLoadingRecords": "Carregando...",
			"sProcessing": "Processando...",
			"sZeroRecords": "Nenhum registro encontrado",
			"sSearch": "Pesquisar",
			"oPaginate": {
				"sNext": "Próximo",
				"sPrevious": "Anterior",
				"sFirst": "Primeiro",
				"sLast": "Último"
			},
			"oAria": {
				"sSortAscending": ": Ordenar colunas de forma ascendente",
				"sSortDescending": ": Ordenar colunas de forma descendente"
			}
		}
	});

});
