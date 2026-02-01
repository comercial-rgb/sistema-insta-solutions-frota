$(document).ready(function() {

	var CHANGE_QUANTITY_PRODUCT = 'change_quantity_product';
	
	$(document).on('change', '.'+CHANGE_QUANTITY_PRODUCT, function(){
		$(this).closest('form').submit();
	}); 

	var LINK_TEXT_ID = 'link_text';
	var COPY_TEXT = 'copy_text';

	$(document).on('click', '#'+COPY_TEXT, function(){
		copyInputTextToClipboard(LINK_TEXT_ID);
	}); 
	
	var LINK_TEXT_CLASS = 'link-text';
	var COPY_TEXT_CLASS = 'copy-text';

	$(document).on('click', '.'+COPY_TEXT_CLASS, function(){
		let position = this.id.split("-")[2];
		copyInputTextToClipboard(LINK_TEXT_CLASS+"-"+position);
	}); 

});
