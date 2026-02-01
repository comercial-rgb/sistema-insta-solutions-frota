$(document).ready(function(){

  // para apagar sala
  // if (App.room) App.cable.subscriptions.remove(App.room);

  // para dar unsubscribe
  // window.onbeforeunload = function(event)
  // {
  //     if (App.cable) App.cable.unsubscribe();
  // };
    
  check_chat_screen();

  var CURRENT_LOGGED_USER_ID = 'current_logged_user_id';
  var RECEIVER_ID = 'receiver_id';

  var DIV_MESSAGES = 'div_messages';

  function check_chat_screen(){
    var pathname = window.location.pathname;
    if((pathname.includes('/chat/'))) {
      open_channel_chat();
    }
  }

  function get_array_user(){
    var pathname = window.location.pathname;
    var pathname_split = pathname.split('/');
    var user_id_1 = Number(pathname_split[2]);
    var user_id_2 = Number(pathname_split[3]);

    return [user_id_1, user_id_2].sort(function(a, b){return a - b});
  }

  function open_channel_chat(){

    (function() {
      this.App || (this.App = {});
      App.cable = ActionCable.createConsumer();
    }).call(this);

    var users = get_array_user();

    App.room = App.cable.subscriptions.create(
    {
      channel: ("RoomChannel"),
      first_id: users[0],
      last_id: users[1]
    },
    {
      connected: function() {
      },
      disconnected: function() {
      },
      received: function(data) {
        add_new_message(data);
      },
      speak: function(message) {
        this.perform('speak', {
          message: message,
          receiver_id: $('#'+RECEIVER_ID).val(),
          sender_id: $('#'+CURRENT_LOGGED_USER_ID).val(),
          first_id: users[0],
          last_id: users[1]
        });
      }
    });

  }

  $(document).on('keypress', '[data-behavior~=room_speaker]', function(event) {
    if (event.keyCode === 13) {
      if(App.room && event.target.value != null && event.target.value != ''){
        App.room.speak(event.target.value);
        event.target.value = '';
      }
      return event.preventDefault();
    }
  });

  function add_new_message(data){
    if(data != null && data.message != null){
      if( parseInt($('#'+RECEIVER_ID).val()) == parseInt(data.message.receiver_id)){
        var klass = 'text-end';
      } else {
        var klass = 'text-start';
      }
      var $div_row = $("<div>", {"class": "row "+klass});
      var $div_col = $("<div>", {"class": "col"});
      var $span = $("<span>", {"text": data.message.content});
      var $span_hour = $("<span>", {"text": data.message.created_at_formatted_hour, "style": 'font-size: 10px;', "class": "text-muted ms-2"});
      var $br = $("<br>");

      $div_col.append($span);
      $div_col.append($span_hour);
      $div_row.append($div_col);
      $('#'+DIV_MESSAGES).append($div_row);
      $('#'+DIV_MESSAGES).append($br);
    }
  }


});