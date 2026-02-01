$(document).ready(function () {

    $(document).on('change', '#vehicles_grid_client_id', function () {
        var client_id = $(this).find(":selected").val();
        var cost_center_id = '#vehicles_grid_cost_center_id';
        var sub_unit_id = '#vehicles_grid_sub_unit_id';
        findCostCentersByClients(client_id, cost_center_id, sub_unit_id)
    });

    $(document).on('change', '#vehicle_client_id', function () {
        var client_id = $(this).find(":selected").val();
        var cost_center_id = '#vehicle_cost_center_id';
        var sub_unit_id = '#vehicle_sub_unit_id';
        findCostCentersByClients(client_id, cost_center_id, sub_unit_id)
    });

    function findCostCentersByClients(client_id, select_cost_center_id, select_sub_unit_id){
        let url = '/get_cost_centers_by_client_id';
        fillSelect([], select_cost_center_id, 'name', null);
        fillSelect([], select_sub_unit_id, 'name', null);
        if (client_id != null && client_id != ''){
            $.ajax({
                url: url,
                dataType: 'json',
                async: false,
                data: {
                    client_id: client_id
                },
                success: function(data) {
                    fillSelect(data.result, select_cost_center_id, 'name', null);
                }
            });
        }
    }

    $(document).on('change', '#vehicles_grid_cost_center_id', function () {
        var cost_center_id = $(this).find(":selected").val();
        var select_to_populate = '#vehicles_grid_sub_unit_id';
        findSubUnitsByCostCenters(cost_center_id, select_to_populate)
    });

    $(document).on('change', '#vehicle_cost_center_id', function () {
        var cost_center_id = $(this).find(":selected").val();
        var select_to_populate = '#vehicle_sub_unit_id';
        findSubUnitsByCostCenters(cost_center_id, select_to_populate)
    });
});

document.addEventListener("DOMContentLoaded", function () {
    $(document).on('click', '#btn-fetch-vehicle-data', function () {
        const plate = $('#vehicle_board').val().trim().toUpperCase();
      
        if (!plate) {
          alert('Informe a placa do veículo.');
          return;
        }
      
        const url = `/getting_vehicle_by_plate_integration?plate=${encodeURIComponent(plate)}`;
      
        $.ajax({
          url: url,
          dataType: 'json',
          method: 'GET',
          success: function (result) {
            if (!result.success){
              alert(result.error);
              return;
            } else {
              if (!result || !result.data || !result.data.plate) {
                alert('Não foi possível buscar os dados do veículo.');
                return;
              }
            }
      
            let data = result.data;
      
            // Campos diretos
            if (data.brand != null && data.brand !== '') {
              $('#vehicle_brand').val(data.brand);
            }
            if (data.model != null && data.model !== '') {
              $('#vehicle_model').val(data.model);
            }
            if (data.year_manufacture != null && data.year_manufacture !== '') {
              $('#vehicle_year').val(data.year_manufacture);
            }
            if (data.year_model != null && data.year_model !== '') {
              $('#vehicle_model_year').val(data.year_model);
            }
            if (data.color != null && data.color !== '') {
              $('#vehicle_color').val(data.color);
            }
            if (data.chassi != null && data.chassi !== '') {
              $('#vehicle_chassi').val(data.chassi);
            }
            // if (data.renavam != null && data.renavam !== '') {
            //   $('#vehicle_renavam').val(data.renavam);
            // }
      
            // engine_displacement
            if (data.engine_displacement != null && data.engine_displacement !== '') {
              $('#vehicle_engine_displacement').val(data.engine_displacement);
            }
            // gearbox_type
            if (data.gearbox_type != null && data.gearbox_type !== '') {
              $('#vehicle_gearbox_type').val(data.gearbox_type);
            }
            // fipe_code
            if (data.fipe_code != null && data.fipe_code !== '') {
              $('#vehicle_fipe_code').val(data.fipe_code);
            }
            // model_text
            if (data.model_text != null && data.model_text !== '') {
              $('#vehicle_model_text').val(data.model_text);
            }
            // value_text
            if (data.value_text != null && data.value_text !== '') {
              $('#vehicle_value_text').val(data.value_text);
            }

            // Estado (por name)
            if (data.state && data.state.name) {
              const stateOption = $('#vehicle_state_id option').filter(function () {
                return $(this).text().trim().toUpperCase().includes(data.state.name.toUpperCase());
              }).val();
              if (stateOption) {
                $('#vehicle_state_id').val(stateOption).trigger('change');
              }
            }
      
            // Cidade (por nome)
            if (data.city && data.city.name) {
              const cityOption = $('#vehicle_city_id option').filter(function () {
                return $(this).text().trim().toUpperCase() === data.city.name.toUpperCase();
              }).val();
              if (cityOption) {
                $('#vehicle_city_id').val(cityOption).trigger('change');
              }
            }
      
            // Vehicle Type (adiciona se não existir)
            if (data.vehicle_type && data.vehicle_type.id && data.vehicle_type.name) {
              const vtSelect = $('#vehicle_vehicle_type_id');
              if (vtSelect.find(`option[value="${data.vehicle_type.id}"]`).length === 0) {
                const newOption = new Option(data.vehicle_type.name, data.vehicle_type.id, true, true);
                vtSelect.append(newOption).trigger('change');
              } else {
                vtSelect.val(data.vehicle_type.id).trigger('change');
              }
            }
      
            // Fuel Type (adiciona se não existir)
            if (data.fuel_type && data.fuel_type.id && data.fuel_type.name) {
              const ftSelect = $('#vehicle_fuel_type_id');
              if (ftSelect.find(`option[value="${data.fuel_type.id}"]`).length === 0) {
                const newOption = new Option(data.fuel_type.name, data.fuel_type.id, true, true);
                ftSelect.append(newOption).trigger('change');
              } else {
                ftSelect.val(data.fuel_type.id).trigger('change');
              }
            }
          },
          error: function () {
            alert('Erro ao buscar dados da placa.');
          }
        });
    }); 
    
    var btn = document.getElementById('btn-fetch-vehicle-data');
    if (btn) {
      btn.addEventListener('click', function(e) {
        var confirmMsg = btn.getAttribute('data-confirm');
        if (confirmMsg && !confirm(confirmMsg)) {
          e.preventDefault();
        }
      });
    }
      
});
  