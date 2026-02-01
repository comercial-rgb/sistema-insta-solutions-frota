$(document).ready(function() {

	$(document).on('change', '#product_category_id', function(){
		var category_id = $(this).find(":selected").val();
		var select_to_populate = '#product_sub_category_id';
		find_by_category(category_id, select_to_populate);
	});

	$(document).on('change', '#products_grid_category_id', function(){
		var category_id = $(this).find(":selected").val();
		var select_to_populate = '#products_grid_sub_category_id';
		find_by_category(category_id, select_to_populate);
	});

});