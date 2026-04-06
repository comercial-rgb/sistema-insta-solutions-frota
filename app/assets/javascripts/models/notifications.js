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

    // Handler para botões "Ciente" / "Entendido" (popup e grid)
    $(document).on('click', '.acknowledge-notification-btn', function () {
        var btn = $(this);
        var notificationId = btn.data('notification-id');
        btn.prop('disabled', true).html('<i class="bi bi-hourglass-split"></i> Aguarde...');

        $.ajax({
            url: '/acknowledge_notification/' + notificationId,
            type: 'POST',
            dataType: 'json',
            headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
            success: function (data) {
                if (data.result) {
                    // Atualiza badge do sino
                    $(".notifications-icon-number").text(data.quantity);

                    // Se estiver no popup modal
                    var card = $('#popup-notification-' + notificationId);
                    if (card.length) {
                        card.find('.acknowledge-notification-btn')
                            .replaceWith('<span class="badge bg-success"><i class="bi bi-check-circle-fill"></i> Ciente</span>');
                        card.addClass('border-success').removeClass('border-warning');

                        // Verificar se todas as notificações do popup foram reconhecidas
                        var pendingBtns = $('#importantNotificationsModal .acknowledge-notification-btn').length;
                        if (pendingBtns === 0) {
                            $('#closePopupNotifications').prop('disabled', false);
                        }
                    }

                    // Se estiver na grid (marcar ciente inline)
                    btn.replaceWith('<span class="badge bg-success"><i class="bi bi-check-circle-fill"></i> Ciente</span>');

                    // Remove indicador de não lido
                    $('.read-notification-' + notificationId).remove();
                }
            },
            error: function () {
                btn.prop('disabled', false).html('<i class="bi bi-check-circle me-1"></i> Ciente');
                alert('Erro ao registrar ciência. Tente novamente.');
            }
        });
    });

    // Botão fechar popup (só habilitado quando todas foram reconhecidas)
    $(document).on('click', '#closePopupNotifications', function () {
        var modal = bootstrap.Modal.getInstance(document.getElementById('importantNotificationsModal'));
        if (modal) modal.hide();
    });

    // Mostrar detalhes de ciência (para admin)
    window.showAcknowledgments = function(notificationId) {
        var modal = new bootstrap.Modal(document.getElementById('ackModal-' + notificationId));
        modal.show();

        $.getJSON('/show_acknowledgments/' + notificationId, function(data) {
            var body = $('#ackModalBody-' + notificationId);
            var html = '<p class="mb-2"><strong>Total:</strong> ' + data.acknowledged_count + ' de ' + data.total + ' confirmaram ciência</p>';

            if (data.acknowledged.length > 0) {
                html += '<h6 class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Confirmaram ciência:</h6>';
                html += '<ul class="list-group list-group-flush mb-3">';
                data.acknowledged.forEach(function(a) {
                    html += '<li class="list-group-item d-flex justify-content-between"><span>' + a.user + '</span><small class="text-muted">' + a.date + '</small></li>';
                });
                html += '</ul>';
            }

            if (data.pending.length > 0) {
                html += '<h6 class="text-danger"><i class="bi bi-clock me-1"></i>Pendentes:</h6>';
                html += '<ul class="list-group list-group-flush">';
                data.pending.forEach(function(name) {
                    html += '<li class="list-group-item">' + name + '</li>';
                });
                html += '</ul>';
            }

            body.html(html);
        });
    };

    // Popup de notificações ao acessar o sistema
    var importantModal = document.getElementById('importantNotificationsModal');
    if (importantModal) {
        var bsModal = new bootstrap.Modal(importantModal);
        bsModal.show();

        // Se não tem notificações que exigem ciência, habilitar botão de fechar
        var pendingBtns = $('#importantNotificationsModal .acknowledge-notification-btn').length;
        if (pendingBtns === 0) {
            $('#closePopupNotifications').prop('disabled', false);
        }
    }

});