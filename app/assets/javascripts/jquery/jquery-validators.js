$(document).ready(function(){

	// Validação de CPF
	jQuery.validator.addMethod("cpfValidation", function(value, element) {
		value = jQuery.trim(value);

		value = value.replace('.','');
		value = value.replace('.','');
		let cpf = value.replace('-','');

		while(cpf.length < 11) cpf = "0"+ cpf;
		let expReg = /^0+$|^1+$|^2+$|^3+$|^4+$|^5+$|^6+$|^7+$|^8+$|^9+$/;
		let a = [];
		let b = new Number;
		let c = 11;
		let y = null;
		let x = null;
		for (let i=0; i<11; i++){
			a[i] = cpf.charAt(i);
			if (i < 9) b += (a[i] * --c);
		}
		if ((x = b % 11) < 2) { a[9] = 0 } else { a[9] = 11-x }
			b = 0;
		c = 11;
		for (y=0; y<10; y++) b += (a[y] * c--);
			if ((x = b % 11) < 2) { a[10] = 0; } else { a[10] = 11-x; }

		let retorno = true;
		if ((cpf.charAt(9) != a[9]) || (cpf.charAt(10) != a[10]) || cpf.match(expReg)) retorno = false;

		return retorno;

	}, "Informe um CPF válido.")

	// Validação de arquivo
	jQuery.validator.addMethod("hasFile", function(value, element) {
		let old_file = $(element).attr("old_file");
		let current_value = $(element).val();
		return ((old_file != null && old_file != "") || (current_value != null && current_value != ""));
	}, "Insira um arquivo válido.")

	// Validação de data
	jQuery.validator.addMethod("validDate", function(value, element) {
		var dateRegex = /^(?=\d)(?:(?:31(?!.(?:0?[2469]|11))|(?:30|29)(?!.0?2)|29(?=.0?2.(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))(?:\x20|$))|(?:2[0-8]|1\d|0?[1-9]))([-.\/])(?:1[012]|0?[1-9])\1(?:1[6-9]|[2-9]\d)?\d\d(?:(?=\x20\d)\x20|$))?(((0?[1-9]|1[012])(:[0-5]\d){0,2}(\x20[AP]M))|([01]\d|2[0-3])(:[0-5]\d){1,2})?$/;
		return dateRegex.test(value)
	}, "Insira uma data válida.")

	jQuery.validator.addMethod(
		"validate_age",
		function(value, element) {              
            // var from = value.split(" "); // DD MM YYYY
            var from = value.split("/"); // DD/MM/YYYY

            var day = from[0];
            var month = from[1];
            var year = from[2];
            var age = 18;

            var mydate = new Date();
            mydate.setFullYear(year, month-1, day);

            var currdate = new Date();
            var setDate = new Date();

            setDate.setFullYear(mydate.getFullYear() + age, month-1, day);

            if ((currdate - setDate) > 0){
            	return true;
            }else{
            	return false;
            }
        },
        "Deve ser maior de 18 anos"
        );

	$("select").on("select2:close", function (e) {  
		try {
			$(this).valid();
		} catch (e) {
			console.error(`${e.name}: ${e.message}`);
		}
	});

  jQuery.validator.addMethod("correct_phone", function(value, element) {
    return telefoneBrasilValido(value);
  }, "Telefone inválido");

  jQuery.validator.addMethod("phoneValidation", function (value, element) {
		// Removing all non-digit characters
		value = value.replace(/[^\d]/g, '');

		// Brazilian cellphones should have 11 digits, starting with a 9
		const brazilianCellphoneRegex = /^(\d{2})?9\d{8}$/;

		return brazilianCellphoneRegex.test(value);

	}, "Informe um telefone válido.")

});