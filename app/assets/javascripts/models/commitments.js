$(document).ready(function () {

    let COMMITMENT_CLIENT_ID = 'commitment_client_id';
    let COMMITMENT_COST_CENTER_ID = 'commitment_cost_center_id';
    let COMMITMENT_SUB_UNIT_ID = 'commitment_sub_unit_id';
    let COMMITMENT_CONTRACT_ID = 'commitment_contract_id';

    // Quando mudar o cliente, atualizar centro de custo, subunidade e contrato
    $(document).on('change', '#' + COMMITMENT_CLIENT_ID, function () {
        var client_id = $(this).find(":selected").val();
        var select_cost_center = '#' + COMMITMENT_COST_CENTER_ID;
        var select_sub_unit = '#' + COMMITMENT_SUB_UNIT_ID;
        var select_contract = '#' + COMMITMENT_CONTRACT_ID;
        
        // Limpar campos dependentes
        fillSelect([], select_cost_center, 'name', null);
        fillSelect([], select_sub_unit, 'name', null);
        fillSelect([], select_contract, 'name', null);
        
        if (client_id != null && client_id != '') {
            // Buscar centros de custo
            findCostCentersByClientForCommitment(client_id, select_cost_center);
            // Buscar subunidades
            findSubUnitsByClientForCommitment(client_id, select_sub_unit);
            // Buscar contratos
            findContractsByClientForCommitment(client_id, select_contract);
        }
    });

    // Quando mudar o centro de custo, atualizar subunidades
    $(document).on('change', '#' + COMMITMENT_COST_CENTER_ID, function () {
        var cost_center_id = $(this).find(":selected").val();
		var select_to_populate = '#' + COMMITMENT_SUB_UNIT_ID;
		findSubUnitsByCostCenters(cost_center_id, select_to_populate);
    });

    // Funções de busca
    function findCostCentersByClientForCommitment(client_id, select_to_populate) {
        let url = '/get_cost_centers_by_client_id';
        $.ajax({
            type: 'GET',
            url: url,
            dataType: 'json',
            data: {
                client_id: client_id,
            },
            success: function(data) {
                fillSelect(data.result, select_to_populate, 'name', null);
            }
        });
    }

    function findSubUnitsByClientForCommitment(client_id, select_to_populate) {
        let url = '/get_sub_units_by_client_id';
        $.ajax({
            type: 'GET',
            url: url,
            dataType: 'json',
            data: {
                client_id: client_id,
            },
            success: function(data) {
                fillSelect(data.result, select_to_populate, 'name', null);
            }
        });
    }

    function findContractsByClientForCommitment(client_id, select_to_populate) {
        let url = '/get_contracts_by_client_id';
        $.ajax({
            type: 'GET',
            url: url,
            dataType: 'json',
            data: {
                client_id: client_id,
            },
            success: function(data) {
                fillSelect(data.result, select_to_populate, 'name', null);
            }
        });
    }

    // Grid filters
    let COMMITMENTS_GRID_COST_CENTER_ID = 'commitments_grid_cost_center_id';
    let COMMITMENTS_GRID_SUB_UNIT_ID = 'commitments_grid_sub_unit_id';

    $(document).on('change', '#' + COMMITMENTS_GRID_COST_CENTER_ID, function () {
        var cost_center_id = $(this).find(":selected").val();
		var select_to_populate = '#' + COMMITMENTS_GRID_SUB_UNIT_ID;
		findSubUnitsByCostCenters(cost_center_id, select_to_populate);
    });

});
