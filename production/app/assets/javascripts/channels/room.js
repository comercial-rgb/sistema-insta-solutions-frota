// (function() {

//   function generate_new_room(){
//     App.room = App.cable.subscriptions.create("RoomChannel", {
//       connected: function() {
//       },
//       disconnected: function() {
//       },
//       received: function(data) {
//         $('#messages').append(data['message']);
//       },
//       speak: function(message) {
//         this.perform('speak', {
//           message: message
//         });
//       }
//     });
//   }

//   $(document).on('keypress', '[data-behavior~=room_speaker]', function(event) {
//     if (event.keyCode === 13) {
//       if(App.room){
//         App.room.speak(event.target.value);
//         event.target.value = '';
//       }
//       return event.preventDefault();
//     }
//   });

// }).call(this);

// // para apagar sala
// // if (App.room) App.cable.subscriptions.remove(App.room);