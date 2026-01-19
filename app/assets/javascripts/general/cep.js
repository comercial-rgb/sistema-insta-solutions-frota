$(document).ready(function() {

	// Exemplo de model (endereço único)
	$(document).on('change', '#user_address_attributes_state_id', function(){
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#user_address_attributes_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('blur', '#user_address_attributes_zipcode', function(){
		let cep = $(this).val();
		find_by_cep(cep, 'user_address_attributes_address', 
			'user_address_attributes_district', 
			'user_address_attributes_state_id', 
			'user_address_attributes_city_id');
	});

	$(document).on('change', '#system_configuration_address_attributes_state_id', function(){
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#system_configuration_address_attributes_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('blur', '#system_configuration_address_attributes_zipcode', function(){
		let cep = $(this).val();
		find_by_cep(cep, 'system_configuration_address_attributes_address', 
			'system_configuration_address_attributes_district', 
			'system_configuration_address_attributes_state_id', 
			'system_configuration_address_attributes_city_id');
	});

	$(document).on('change', '#order_address_attributes_state_id', function(){
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#order_address_attributes_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('blur', '#order_address_attributes_zipcode', function(){
		let cep = $(this).val();
		find_by_cep(cep, 'order_address_attributes_address', 
			'order_address_attributes_district', 
			'order_address_attributes_state_id', 
			'order_address_attributes_city_id');
	});

	$(document).on('change', '#testimony_state_id', function(){
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#testimony_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#testimonies_grid_state_id', function(){
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#testimonies_grid_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#user_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#user_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#managers_grid_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#managers_grid_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#additionals_grid_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#additionals_grid_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#vehicle_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#vehicle_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#vehicles_grid_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#vehicles_grid_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#providers_grid_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#providers_grid_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('change', '#clients_grid_state_id', function () {
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#clients_grid_city_id';
		find_by_state(state_id, select_to_populate);
	});
	
	// Exemplo de model (endereço único)
	$(document).on('change', '#address_state_id', function(){
		var state_id = $(this).find(":selected").val();
		var select_to_populate = '#address_city_id';
		find_by_state(state_id, select_to_populate);
	});

	$(document).on('blur', '#address_zipcode', function(){
		let cep = $(this).val();
		find_by_cep(cep, 'address_address', 
			'address_district', 
			'address_state_id', 
			'address_city_id');
	});
	// Fim model (endereço único)

	// Exemplo de model (endereços múltiplos)
	
	// Classes para múltiplos endereços nos usuários
	var USER_ADDRESS_CHANGE_ZIPCODE = 'user_address_change_zipcode';
	var USER_ADDRESS_CHANGE_STATE = 'user_address_change_state';

	$(document).on('blur', '.'+USER_ADDRESS_CHANGE_ZIPCODE, function(){
		// O valor da posição a ser pego é onde está o valor numérico no ID. Deve se verificar se é a 3ª ou outra posição.
		var position = this.id.split('_')[3];
		var cep = $(this).val();
		find_by_cep(cep, 'user_addresses_attributes_'+position+'_address', 
			'user_addresses_attributes_'+position+'_district', 
			'user_addresses_attributes_'+position+'_state_id', 
			'user_addresses_attributes_'+position+'_city_id');
	});

	$(document).on('change', '.'+USER_ADDRESS_CHANGE_STATE, function(){
		// O valor da posição a ser pego é onde está o valor numérico no ID. Deve se verificar se é a 3ª ou outra posição.
		var position = this.id.split('_')[3];
		var state_id = $(this).find(":selected").val();

		var select_to_populate = '#user_addresses_attributes_'+position+'_city_id';
		find_by_state(state_id, select_to_populate);
	});
	// Fim model (endereços múltiplos)

	
	// Busca de Estados por um País
	$(document).on('change', '#city_country_id', function(){
		var country_id = $(this).find(":selected").val();
		var select_to_populate = '#city_state_id';
		find_by_country(country_id, select_to_populate);
	});

	$(document).on('change', '#cities_grid_country_id', function(){
		var country_id = $(this).find(":selected").val();
		var select_to_populate = '#cities_grid_state_id';
		find_by_country(country_id, select_to_populate);
	});
	// Fim busca de Estados por um País
});
