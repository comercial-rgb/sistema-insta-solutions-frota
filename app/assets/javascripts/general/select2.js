$(document).ready(function(){

    // Select2
	$("select:not(.checkbox-select)").select2({
		language: "pt-BR",
		allowHtml: true
	});

	$('.select-with-images').select2({
		templateSelection: function(data, container) {
			if (data.element) {
				var imageSrc = $(data.element).data('display-image');
				if (imageSrc) {
					return $('<span><img src="' + imageSrc + '" class="img-flag" /> ' + data.text + '</span>');
				}
			}
			return data.text;
		},
		templateResult: function(data) {
			if (!data.id) {
				return data.text;
			}
			var imageSrc = $(data.element).data('image');
			if (imageSrc) {
				return $('<span><img src="' + imageSrc + '" class="img-flag" /> ' + data.text + '</span>');
			}
			return data.text;
		}
	});


});
