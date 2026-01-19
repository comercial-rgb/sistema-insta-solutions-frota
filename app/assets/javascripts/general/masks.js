$(document).ready( () => {

  $('.phone-code').mask('99');
  $('.card-number').mask('9999 9999 9999 9999');
  $('.card-validate-date').mask('99/9999');
  $('.card-ccv-code').mask('999');

  $('.datepicker, .date_filter').datepicker({
    format: 'dd/mm/yyyy',
    language: 'pt-BR',
    todayHighlight: true
  }).on('change', function(){
    // $('.datepicker-dropdown').hide();
  });

  $(".datepicker, .date_filter, .birthday").inputmask({
    mask: "99/99/9999",
    keepStatic: true,
    positionCaretOnTab: true,
    clearIncomplete: true
  });

  $(".license_plate").inputmask({
    mask: [
      "AAA-9999",   // Ex: ABC-1234 (formato antigo)
      "AAA-9A99"    // Ex: ABC-1D23 (Mercosul)
    ],
    definitions: {
      'A': {
        validator: "[A-Za-z]",
        casing: "upper"
      },
      '9': {
        validator: "[0-9]",
        casing: null
      }
    },
    keepStatic: false,             // permite alternar entre as máscaras
    showMaskOnHover: false,
    clearIncomplete: true          // evita entrada parcial inválida
  });
  
  // $('.datetimepicker').datetimepicker({
  //     locale: 'pt-BR'
  // });

  // flatpickr
  flatpickr('.datetimepicker, .date_time_filter', settings.flatpickr);
  // Exemplo input: <%= f.input :final_date, as: :string, input_html: {class: 'datetimepicker', :value => CustomHelper.get_text_date(f.object.final_date, 'datetime', :full), autocomplete: :off} %>

  $(".cep").inputmask({
    mask: "99.999-999",
    keepStatic: true,
    positionCaretOnTab: true
  });

  $(".cpf").inputmask({
    mask: "999.999.999-99",
    keepStatic: true,
    positionCaretOnTab: true
  });

  $(".cnpj").inputmask({
    mask: "99.999.999/9999-99",
    keepStatic: true,
    positionCaretOnTab: true
  });

  $(".rg").inputmask({
    mask: "AA 99.999.999",
    keepStatic: true,
    positionCaretOnTab: true
  });

  $(".money").maskMoney({
    prefix: "R$ ",
    showSymbol: true,
    decimal: ",",
    thousands: ".",
    symbolStay: true,
    selectAllOnFocus: true
  });

  $(".complete-phone").inputmask({
    mask: ["9999-9999", "99999-9999", ],
    keepStatic: true,
    positionCaretOnTab: true
  });

  $(".complete-phone-ddd").inputmask({
    mask: ["(99) 9999-9999", "(99) 99999-9999", ],
    keepStatic: true,
    positionCaretOnTab: true
  });

  var cpfMascara = function (val) {
    return val.replace(/\D/g, '').length > 11 ? '00.000.000/0000-00' : '000.000.000-009';
  },
  cpfOptions = {
    onKeyPress: function(val, e, field, options) {
      field.mask(cpfMascara.apply({}, arguments), options);
    }
  };
  $('.cpf-cnpj').mask(cpfMascara, cpfOptions);
  $('.cpf_cnpj').mask(cpfMascara, cpfOptions);

  $(".insert_just_letter").keypress( event => {
    var inputValue = event.which;
    if(!(inputValue >= 65 && inputValue <= 122) && (inputValue != 32 && inputValue != 0)) {
      event.preventDefault();
    }
  });

  $('.change_to_upper_case').keyup(function() {
    this.value = this.value.toLocaleUpperCase();
  });
  
  $('.just_letter_and_number').keypress(function (e) {
    var regex = new RegExp("^[a-zA-Z0-9]+$");
    var str = String.fromCharCode(!e.charCode ? e.which : e.charCode);
    if (regex.test(str)) {
        return true;
    }
    e.preventDefault();
    return false;
  });

  // Converter todo campo de texto para maiúsculo (menos campo de e-mail)
  // $('input[type="text"]').on('input', function() {
  //   $(this).val(function(_, val) {
  //     return val.toUpperCase();
  //   });
  // });

});

// End of file masks.js
// Path: ./app/assets/javascripts/masks.js
