$(document).ready(function(){

	let FORM_TO_VALIDATE = "pay_order_form";

	let SUBMIT_WITHOUT_VALIDATION = "submit_without_validation";

	$('.'+FORM_TO_VALIDATE).validate({
		onfocusout: function(element) {
			this.element(element);  
		},
		rules: {
			'user[name]': {
				required: true
			},
			'user[cpf]': {
				required: true,
				cpfValidation: true
			}
		},
		messages: {
			'user[name]': {
				required: 'Insira seu nome completo.'
			},
			'user[cpf]': {
				required: 'Insira seu CPF.',
				cpfValidation: "Insira um CPF válido"
			}
		},
		invalidHandler: function(form, validator) {
			if (!validator.numberOfInvalids())
				return;
			$('html, body').animate({
				scrollTop: $(validator.errorList[0].element).offset().top
			}, 2000);
		}
	});

	// Enviando formulário sem realizar validação dos documentos e imagem de perfil
	$("#"+SUBMIT_WITHOUT_VALIDATION).click(function() {
		var settings = $('.'+FORM_TO_VALIDATE).validate().settings;
		for (var i in settings.rules){
			delete settings.rules[i].required;
			delete settings.rules[i].hasFile;
		}
	});

});