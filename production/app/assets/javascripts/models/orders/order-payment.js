$( document ).ready(function() {

  var BUY_BUTTON = 'payment-button';

  // ID dos campos dos dados do cartão
  var CARD_NAME = 'order_card_attributes_name';
  var CARD_NUMBER = 'order_card_attributes_number';
  var CARD_CCV = 'order_card_attributes_ccv_code';
  var CARD_MONTH = 'order_card_attributes_validate_date_month';
  var CARD_YEAR = 'order_card_attributes_validate_date_year';
  var CARD_BANNER = 'order_card_attributes_card_banner_id';
  var ORDER_CARD_ID = 'order_card_id';
  // Fim dados do cartão

  var PRICE = 'price';
  var PAYMENT_DATA = 'payment-datas'
  var FINISH_BUY = 'finish-payment-data';
  var EDIT_PAYMENT = 'edit-payment-data';

  let ORDER_PAYMENT_TYPE_ID = 'order_payment_type_id';

  // Pega o Sender Hash e o Card Token quando o usuário confirma os dados do cartão
  $("#"+BUY_BUTTON).click(function() {
    var cardName = $("#"+CARD_NAME).val();
    var cardNumber = $("#"+CARD_NUMBER).val();
    var expirationMonth = $("#"+CARD_MONTH).val();
    var expirationYear = $("#"+CARD_YEAR).val();
    var ccv = $("#"+CARD_CCV).val();
    var brand = $("#"+CARD_BANNER).val();
    var order_card_id = $("#"+ORDER_CARD_ID).val();

    if(order_card_id == null || order_card_id == ''){
      if(cardName == '' || cardNumber == '' || expirationMonth == '' || expirationYear == '' || ccv == '' || brand == '' || cardNumber.replace(/ /g,'').length != 16 || ccv.length != 3){
        alert('Preencha corretamente os dados do cartão.');
      } else {
        $('.'+PAYMENT_DATA).hide();
        $('#'+FINISH_BUY).fadeIn();
      }
    } else {
      $('.'+PAYMENT_DATA).hide();
      $('#'+FINISH_BUY).fadeIn();
    }
    
  });

  // Muda do step de finalização para o step de edição do meio de pagamento
  $("#"+EDIT_PAYMENT).click(function() {
    $('#'+FINISH_BUY).hide();
    $('.'+PAYMENT_DATA).fadeIn();
  });

  var URL_FIND_BY_CARD = '/get_card_details';

  $('#'+ORDER_CARD_ID).on('change', function(){
    var id = $(this).val();
    if(id != null && id != ''){
      $.getJSON(
        URL_FIND_BY_CARD,
        {id: id},
        function(data){
          if(data != null){
            $('#'+FINISH_BUY).fadeIn();
            $('.'+PAYMENT_DATA).hide();
          } else {
            $('.'+PAYMENT_DATA).hide();
            $('#'+FINISH_BUY).fadeIn();
          }
        });
    } else {
      $('#'+FINISH_BUY).hide();
      $('.'+PAYMENT_DATA).fadeIn();
    }
  });

  $('#'+ORDER_PAYMENT_TYPE_ID).on('change', function(){
    var id = $(this).val();
    if(Number(id) == 2 || Number(id) == 3){
      $('#'+FINISH_BUY).fadeIn();
      $('.'+PAYMENT_DATA).hide();
    } else {
      $('#'+FINISH_BUY).hide();
      $('.'+PAYMENT_DATA).fadeIn();
    }
  });

  let CURRENT_ORDER_TO_PAY_ID = '#current_order_to_pay_id';
  let DISCOUNT_COUPON_AREA_ID = "#discount_coupon_area_id";
  let URL_INSERT_DISCOUNT_COUPON_TO_ORDER = '/insert_discount_coupon';
  let INSERT_DISCOUNT_COUPON = 'insert-discount-coupon';
  let TEXT_DISCOUNT_COUPON = '#text-discount-coupon';
  
  $(document).on('click', '#'+INSERT_DISCOUNT_COUPON, function(){
    insertDiscountCoupon();
  });

  function insertDiscountCoupon(){
    let text_discount_coupon = $(TEXT_DISCOUNT_COUPON).val();
    let current_order_to_pay_id = $(CURRENT_ORDER_TO_PAY_ID).val();
    let discount_coupon_area_id = $(DISCOUNT_COUPON_AREA_ID).val();

    if(text_discount_coupon != null && text_discount_coupon != ""){
      if(current_order_to_pay_id != null && current_order_to_pay_id != ""){
        $.getJSON(
          URL_INSERT_DISCOUNT_COUPON_TO_ORDER,
          {
            current_order_to_pay_id: current_order_to_pay_id,
            discount_coupon_area_id: discount_coupon_area_id,
            text_discount_coupon: text_discount_coupon
          },
          function(data){
            alert(data.message);
            if(data.result){
              window.location = window.location;
            }
          });
      }
    } else {
      alert("Insira o texto do cupom");
    }
  }

})