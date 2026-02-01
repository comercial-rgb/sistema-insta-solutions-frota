$(document).ready(function() {

	$(document).on('change', '#plan_category_id', function(){
		var category_id = $(this).find(":selected").val();
		var select_to_populate = '#plan_sub_category_id';
		find_by_category(category_id, select_to_populate);
	});

	$(document).on('change', '#plans_grid_category_id', function(){
		var category_id = $(this).find(":selected").val();
		var select_to_populate = '#plans_grid_sub_category_id';
		find_by_category(category_id, select_to_populate);
	});

});