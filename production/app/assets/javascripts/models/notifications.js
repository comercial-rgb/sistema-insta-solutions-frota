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

    // Cascade: ao trocar Estado, carregar cidades
    $(document).on('change', '#notification_state_id', function () {
        var state_id = $(this).val();
        var citySelect = $('#notification_city_id');
        citySelect.html('<option value="">' + (citySelect.data('blank') || 'Todos') + '</option>');
        if (state_id != null && state_id != '') {
            find_by_state(state_id, '#notification_city_id');
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

    // Popup de notificações importantes ao acessar o sistema
    var importantModal = document.getElementById('importantNotificationsModal');
    if (importantModal) {
        var bsModal = new bootstrap.Modal(importantModal);
        bsModal.show();
    }

});