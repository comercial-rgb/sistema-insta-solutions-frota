// Faturamento Module - Client-side Tab Management & AJAX Operations
var Faturamento = (function() {
  var _debounceTimer = null;
  var _currentPage = 1;

  // ========== UTILITY FUNCTIONS ==========

  function money(val) {
    var n = parseFloat(val) || 0;
    return 'R$ ' + n.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  function fmtDate(dateStr) {
    if (!dateStr) return '-';
    var d = new Date(dateStr + 'T00:00:00');
    if (isNaN(d)) return '-';
    return d.toLocaleDateString('pt-BR');
  }

  function statusBadgeHtml(status) {
    var colors = { aberta: 'warning', enviada: 'primary', paga: 'success', cancelada: 'secondary' };
    var color = colors[status] || 'secondary';
    var label = status ? status.charAt(0).toUpperCase() + status.slice(1) : '-';
    return '<span class="badge bg-' + color + '">' + label + '</span>';
  }

  function escapeHtml(str) {
    if (!str) return '';
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  function showAlert(message, type) {
    type = type || 'success';
    var alertDiv = document.createElement('div');
    alertDiv.className = 'alert alert-' + type + ' alert-dismissible fade show position-fixed';
    alertDiv.style.cssText = 'top:20px;right:20px;z-index:9999;max-width:400px;';
    alertDiv.innerHTML = message + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>';
    document.body.appendChild(alertDiv);
    setTimeout(function() { alertDiv.remove(); }, 5000);
  }

  function csrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  }

  // ========== FATURAS TAB (AJAX) ==========

  function debouncedLoadFaturas() {
    clearTimeout(_debounceTimer);
    _debounceTimer = setTimeout(loadFaturas, 400);
  }

  function loadFaturas() {
    var params = new URLSearchParams({ page: _currentPage });
    var search = document.getElementById('fSearch');
    var status = document.getElementById('fStatus');
    var client = document.getElementById('fClient');
    var costCenter = document.getElementById('fCostCenter');
    var dtIni = document.getElementById('fDtIni');
    var dtFim = document.getElementById('fDtFim');

    if (search && search.value) params.set('search', search.value);
    if (status && status.value) params.set('status', status.value);
    if (client && client.value) params.set('client_id', client.value);
    if (costCenter && costCenter.value) params.set('cost_center_id', costCenter.value);
    if (dtIni && dtIni.value) params.set('data_inicio', dtIni.value);
    if (dtFim && dtFim.value) params.set('data_fim', dtFim.value);

    $.ajax({
      url: '/faturamento/faturas_json?' + params.toString(),
      method: 'GET',
      dataType: 'json',
      success: function(data) {
        renderFaturasTable(data.results || [], data.pagination || {});
      },
      error: function() {
        showAlert('Erro ao carregar faturas', 'danger');
      }
    });
  }

  function renderFaturasTable(rows, pagination) {
    var tbody = document.getElementById('faturasBody');
    if (!tbody) return;

    if (!rows.length) {
      tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted py-4">Nenhuma fatura encontrada</td></tr>';
      return;
    }

    var html = rows.map(function(f) {
      var isOverdue = f.data_vencimento && ['aberta', 'enviada'].indexOf(f.status) >= 0 &&
                      new Date(f.data_vencimento) < new Date(new Date().toDateString());
      var vencTd = f.data_vencimento_fmt || '-';
      if (isOverdue) {
        vencTd = '<span class="text-danger fw-bold" title="Vencida!"><i class="bi bi-exclamation-triangle-fill"></i> ' + vencTd + '</span>';
      }

      var actionsHtml = '<div class="dropdown">' +
        '<button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown"><i class="bi bi-three-dots-vertical"></i></button>' +
        '<ul class="dropdown-menu dropdown-menu-end">' +
        '<li><a class="dropdown-item" href="/faturamento/' + f.id + '"><i class="bi bi-eye-fill me-2"></i> Ver Detalhes</a></li>' +
        '<li><a class="dropdown-item" href="#" onclick="Faturamento.editarFatura(' + f.id + '); return false;"><i class="bi bi-pencil-fill me-2"></i> Editar</a></li>' +
        (f.status === 'aberta' ? '<li><a class="dropdown-item" href="#" onclick="Faturamento.enviarCobranca(' + f.id + '); return false;"><i class="bi bi-send-fill me-2"></i> Enviar Cobrança</a></li>' : '') +
        '</ul></div>';

      return '<tr>' +
        '<td><strong><a href="/faturamento/' + f.id + '" class="text-primary text-decoration-none">' + escapeHtml(f.numero) + '</a></strong></td>' +
        '<td>' + escapeHtml(f.cliente) + '</td>' +
        '<td>' + escapeHtml(f.centro_custo) + '</td>' +
        '<td>' + (f.data_emissao_fmt || '-') + '</td>' +
        '<td>' + vencTd + '</td>' +
        '<td>' + (f.data_envio_fmt || '-') + '</td>' +
        '<td>' + money(f.valor_bruto) + '</td>' +
        '<td>' + money(f.valor_liquido) + '</td>' +
        '<td>' + statusBadgeHtml(f.status) + '</td>' +
        '<td>' + actionsHtml + '</td>' +
        '</tr>';
    }).join('');

    tbody.innerHTML = html;
  }

  function limparFiltros() {
    ['fSearch', 'fStatus', 'fClient', 'fCostCenter', 'fDtIni', 'fDtFim'].forEach(function(id) {
      var el = document.getElementById(id);
      if (el) el.value = '';
    });
    _currentPage = 1;
    loadFaturas();
  }

  function goPage(page) {
    _currentPage = page;
    loadFaturas();
  }

  // ========== DETALHE ==========

  function verDetalhe(id) {
    window.location.href = '/faturamento/' + id;
  }

  function voltarFaturas() {
    document.getElementById('panelDetalhe').style.display = 'none';
    document.getElementById('faturamentoTabContent').style.display = '';
    document.querySelector('.faturamento-tabs').style.display = '';
  }

  // ========== EDIT FATURA ==========

  function editarFatura(id) {
    $.ajax({
      url: '/faturamento/' + id + '.json',
      method: 'GET',
      dataType: 'json',
      success: function(f) {
        document.getElementById('editFaturaId').value = f.id;
        document.getElementById('editStatus').value = f.status || 'aberta';
        document.getElementById('editDtEnvio').value = f.data_envio_empresa ? f.data_envio_empresa.substring(0, 10) : '';
        document.getElementById('editDtReceb').value = f.data_recebimento ? f.data_recebimento.substring(0, 10) : '';
        document.getElementById('editDtVenc').value = f.data_vencimento ? f.data_vencimento.substring(0, 10) : '';
        document.getElementById('editObs').value = f.admin_observacoes || '';
        var modal = new bootstrap.Modal(document.getElementById('modalEditFatura'));
        modal.show();
      },
      error: function() {
        showAlert('Erro ao carregar dados da fatura', 'danger');
      }
    });
  }

  function salvarEdicao() {
    var id = document.getElementById('editFaturaId').value;
    var data = {
      fatura: {
        status: document.getElementById('editStatus').value,
        data_envio_empresa: document.getElementById('editDtEnvio').value || null,
        data_recebimento: document.getElementById('editDtReceb').value || null,
        data_vencimento: document.getElementById('editDtVenc').value || null,
        admin_observacoes: document.getElementById('editObs').value
      }
    };

    $.ajax({
      url: '/faturamento/' + id,
      method: 'PATCH',
      data: JSON.stringify(data),
      contentType: 'application/json',
      headers: { 'X-CSRF-Token': csrfToken() },
      dataType: 'json',
      success: function() {
        bootstrap.Modal.getInstance(document.getElementById('modalEditFatura')).hide();
        showAlert('Fatura atualizada com sucesso!');
        setTimeout(function() { window.location.reload(); }, 1000);
      },
      error: function(xhr) {
        var msg = 'Erro ao atualizar fatura';
        try { msg = JSON.parse(xhr.responseText).error.join(', '); } catch(e) {}
        showAlert(msg, 'danger');
      }
    });
  }

  // ========== COBRAR ==========

  function enviarCobranca(id) {
    if (!confirm('Gerar cobrança e marcar como "Enviada"?')) return;

    $.ajax({
      url: '/faturamento/' + id + '/cobrar',
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken() },
      dataType: 'json',
      success: function() {
        showAlert('Cobrança gerada! Status: Enviada.');
        setTimeout(function() { window.location.reload(); }, 1000);
      },
      error: function(xhr) {
        var msg = 'Erro ao gerar cobrança';
        try { msg = JSON.parse(xhr.responseText).error; } catch(e) {}
        showAlert(msg, 'danger');
      }
    });
  }

  // ========== OS EM ABERTO ==========

  function carregarOSAbertos() {
    var clienteId = document.getElementById('fAbertoCliente').value;
    var content = document.getElementById('abertosContent');

    if (!clienteId) {
      content.innerHTML = '<p class="text-center text-muted py-5">Selecione um cliente para listar as OS em aberto.</p>';
      return;
    }

    content.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" role="status"></div><p class="text-muted mt-2">Carregando...</p></div>';

    // Placeholder: In a real implementation, this would load unfatured OS for this provider
    content.innerHTML = '<div class="alert alert-secondary">Funcionalidade de seleção de OS para faturamento será implementada na próxima fase.</div>';
  }

  function voltarSelecao() {
    document.getElementById('abertosContent').style.display = '';
    document.getElementById('previewSection').style.display = 'none';
  }

  function resetFatura() {
    document.getElementById('successSection').style.display = 'none';
    document.getElementById('abertosContent').style.display = '';
  }

  // ========== PUBLIC API ==========

  return {
    loadFaturas: loadFaturas,
    debouncedLoadFaturas: debouncedLoadFaturas,
    limparFiltros: limparFiltros,
    goPage: goPage,
    verDetalhe: verDetalhe,
    voltarFaturas: voltarFaturas,
    editarFatura: editarFatura,
    salvarEdicao: salvarEdicao,
    enviarCobranca: enviarCobranca,
    carregarOSAbertos: carregarOSAbertos,
    voltarSelecao: voltarSelecao,
    resetFatura: resetFatura
  };
})();
