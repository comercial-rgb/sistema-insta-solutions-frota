$(document).ready(function() {

	var USER_PERSON_TYPE = 'user_person_type_id';

	var DIV_WITH_PERSON_TYPE_PHYSICAL = 'div_with_person_type_physical';
	var DIV_WITH_PERSON_TYPE_JURIDICAL = 'div_with_person_type_juridical';
	
	$(document).on('change', '#'+USER_PERSON_TYPE, function(){
		hideElement(DIV_WITH_PERSON_TYPE_PHYSICAL, true);
		hideElement(DIV_WITH_PERSON_TYPE_JURIDICAL, true);
		if(this.value == 1){
			hideElement(DIV_WITH_PERSON_TYPE_PHYSICAL, false);
		} else if(this.value == 2){
			hideElement(DIV_WITH_PERSON_TYPE_JURIDICAL, false);
		} 
	});

	let USER_SET_MANUALLY_PLAN = 'user_set_manually_plan';
	let DIV_WITH_MANUALLY_PLAN = 'div-with-manually-plan';
	
	$(document).on('change', '#'+USER_SET_MANUALLY_PLAN, function(){
		if(this.checked){
			hideElement(DIV_WITH_MANUALLY_PLAN, false);
		} else {
			hideElement(DIV_WITH_MANUALLY_PLAN, false);
		} 
	});

	let URL_RESET_PASSWORD = "/reset_user_password/:id";
	let RESET_PASSWORD = "reset-password";
	let RESET_PASSWORD_MODAL = "#reset_password";
	let NEW_PASSWORD = "#new-password";
	let LINK_TEXT = "#link_text";
	
	$(document).on('click', '.'+RESET_PASSWORD, function(){
		let confirm = window.confirm("Você tem certeza?");
		if(confirm){
			let id = this.id.split("-")[2];
			let url = URL_RESET_PASSWORD.replace(':id', id);
			$.ajax({
				url: url,
				type: 'post',
				dataType: 'json',
				async: false,
				success: function(data) {
					if(data.result){
						$(NEW_PASSWORD).text(data.password);
						$(LINK_TEXT).val(data.password);
						$(RESET_PASSWORD_MODAL).modal('show');
					}
				}
			});
		}
	});

	let ACTION_TO_USERS_LISTING = "action-to-users-listing";
	let SELECT_USER = "select-user";
	let REASON_DISAPPROVE_MODAL = "#reason_disapprove_modal";
	let SEND_DISAPPROVE_REASON = "#send-disapprove-reason";
	let REASON_DISAPPROVE = "#reason-disapprove";

	let URL_APPROVE_USERS = "/approve_users";
	let URL_DISAPPROVE_USERS = "/disapprove_users";

	$(document).on('click', '.'+ACTION_TO_USERS_LISTING, function(){
		actionToUsers(this);
	});

	function actionToUsers(element){
		let checkBoxes = $('.'+SELECT_USER+':checkbox:checked').map(function() {
			return this.value;
		}).get();
		let users_ids = checkBoxes.join(",");
		if(checkBoxes.length > 0){
			if(element.id == "approve-users"){
				approveSelectedUsers(users_ids);
			} else if(element.id == "disapprove-users"){
				disapproveSelectedUsers(users_ids);
			}
		} else {
			alert("Selecione ao menos 1 usuário");
		}
	}

	function approveSelectedUsers(users_ids){
		let confirm = window.confirm("Você tem certeza?");
		if(confirm){
			$.ajax({
				url: URL_APPROVE_USERS,
				dataType: 'json',
				data: {
					users_ids: users_ids
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
	}

	function disapproveSelectedUsers(users_ids){
		$(REASON_DISAPPROVE_MODAL).modal('show');
		$(REASON_DISAPPROVE).focus();
	}

	$(document).on('click', SEND_DISAPPROVE_REASON, function(){
		let disapprove_reason = $(REASON_DISAPPROVE).val();
		if(disapprove_reason != null && disapprove_reason != ""){
			let checkBoxes = $('.'+SELECT_USER+':checkbox:checked').map(function() {
				return this.value;
			}).get();
			let users_ids = checkBoxes.join(",");
			let confirm = window.confirm("Você tem certeza?");
			if(confirm){
				$.ajax({
					url: URL_DISAPPROVE_USERS,
					dataType: 'json',
					data: {
						users_ids: users_ids,
						disapprove_reason: disapprove_reason
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

	let USER_CLIENT = 'user_client_id';

	let COST_CENTERS_CLIENT = 'cost-centers-client';

	$(document).on('change', '#' + USER_CLIENT, function () {
		uncheckAllCheckboxesByClass('linked-filter-cost-center');
		hideElement(COST_CENTERS_CLIENT, true);
		hideElement(COST_CENTERS_CLIENT+'-'+this.value, false);
	});

});
