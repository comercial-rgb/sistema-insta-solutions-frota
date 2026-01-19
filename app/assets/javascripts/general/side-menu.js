$(document).ready(() => {

	$(document).on('click', '.icon-to-manage-menu-close', function(){
		closeMenu();
	});

	function closeMenu(){
		hideElement("custom-display-menu-opened", true);
		hideElement("custom-display-menu-closed", false);
		
		$("#div-with-page-content")
		.removeClass("custom-display-screen-menu-open")
		.addClass("custom-display-screen-menu-closed");
	}

	$(document).on('click', '.icon-to-manage-menu-opened', function(){
		openMenu();
	});

	function openMenu(){
		hideElement("custom-display-menu-opened", false);
		hideElement("custom-display-menu-closed", true);
		
		$("#div-with-page-content")
		.removeClass("custom-display-screen-menu-closed")
		.addClass("custom-display-screen-menu-open");
	}

});