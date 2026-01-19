$(document).ready(function () {

    $(document).on('change', '#notification_profile_id', function () {
        uncheckAllCheckboxesByClass('users-notification');
        hideElement('users-notification', true);
        $('#notification_send_all').val('true');
        if(this.value != null && this.value != ''){
            hideElement('div-with-send-all', false);
        } else {
            hideElement('div-with-send-all', true);
        }
    });
    
    $(document).on('change', '#notification_send_all', function () {
        let profile_id = $('#notification_profile_id').val();
        hideElement('users-notification', true);
        uncheckAllCheckboxesByClass('users-notification');
        if (this.value == 'false') {
            hideElement('users-notification-'+profile_id, false);
        }
    });

    let MANAGE_READ_NOTIFICATION = 'read-notification';
    let URL_MANAGE_LIKED_MESSAGE = '/manage_read_notification';

    $(document).on('click', '.' + MANAGE_READ_NOTIFICATION, function () {
        var notification_id = this.id.split("-")[2];
        $.getJSON(
            URL_MANAGE_LIKED_MESSAGE,
            {
                id: notification_id
            },
            function (data) {
                if (data.result == true) {
                    if (data.read == true) {
                        $('.read-notification-' + notification_id).remove();
                    }
                    $(".notifications-icon-number").text(data.quantity);
                } else {
                    alert(data.message);
                }
            });
    });

});