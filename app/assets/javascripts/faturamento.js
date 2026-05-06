// Faturamento Module - Client-side Tab Management & AJAX Operations
var Faturamento = (function() {
  var _debounceTimer = null;
  var _currentPage = 1;
  var _osAbertosData = []; // cached OS data
  var _selectedOS = {};    // { osId: true/false }
  var _lastOsAbertosClientId = null;
  var _lastOsAbertosCcId = null;
  var _clientDiscount = 0; // client discount percent
  var _clientSphere = 0;   // 0=Municipal, 1=Estadual, 2=Federal
  var _contractsInfo = [];  // contract saldo info
  var _commitmentNumbers = []; // commitment numbers used
  var _osObservacoes = {};  // { osId: 'text' } per-OS observations

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
        (['aberta', 'enviada'].indexOf(f.status) >= 0 ? '<li><a class="dropdown-item text-success" href="#" onclick="Faturamento.marcarPago(' + f.id + '); return false;"><i class="bi bi-check-circle-fill me-2"></i> Marcar como Pago</a></li>' : '') +
        '<li><a class="dropdown-item" href="/faturamento/' + f.id + '/gerar_docx"><i class="bi bi-file-earmark-word me-2"></i> Baixar DOCX</a></li>' +
        '</ul></div>';

      return '<tr>' +
        '<td><strong><a href="/faturamento/' + f.id + '" class="text-primary text-decoration-none">' + escapeHtml(f.numero) + '</a></strong></td>' +
        '<td>' + escapeHtml(f.cliente) + '</td>' +
        '<td>' + escapeHtml(f.centro_custo) + '</td>' +
        '<td>' + (f.data_emissao_fmt || '-') + '</td>' +
        '<td>' + vencTd + '</td>' +
        '<td>' + (f.data_envio_fmt || '-') + '</td>' +
        '<td>' + money(f.valor_bruto) + ' <small class="text-muted">(' + money(f.valor_liquido) + ')</small></td>' +
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
        document.getElementById('editNfNumero').value = f.nota_fiscal_numero || '';
        document.getElementById('editNfSerie').value = f.nota_fiscal_serie || '';
        var setVal = function(id, v) { var el = document.getElementById(id); if (el) el.value = v || ''; };
        setVal('editNfNumeroPecas', f.nota_fiscal_numero_pecas);
        setVal('editNfSeriePecas', f.nota_fiscal_serie_pecas);
        setVal('editNfNumeroServicos', f.nota_fiscal_numero_servicos);
        setVal('editNfSerieServicos', f.nota_fiscal_serie_servicos);

        var pecasInfo = document.getElementById('editNfPecasFileExistente');
        if (pecasInfo) {
          if (f.nota_fiscal_pecas_file_url) {
            pecasInfo.innerHTML = 'Arquivo atual: <a href="' + f.nota_fiscal_pecas_file_url + '" target="_blank">' + (f.nota_fiscal_pecas_file_name || 'baixar') + '</a>';
          } else {
            pecasInfo.textContent = 'Nenhum arquivo anexado.';
          }
        }
        var servInfo = document.getElementById('editNfServicosFileExistente');
        if (servInfo) {
          if (f.nota_fiscal_servicos_file_url) {
            servInfo.innerHTML = 'Arquivo atual: <a href="' + f.nota_fiscal_servicos_file_url + '" target="_blank">' + (f.nota_fiscal_servicos_file_name || 'baixar') + '</a>';
          } else {
            servInfo.textContent = 'Nenhum arquivo anexado.';
          }
        }
        var consInfo = document.getElementById('editNfConsolidadaFileExistente');
        if (consInfo) {
          if (f.nota_fiscal_consolidada_file_url) {
            consInfo.innerHTML = 'Arquivo atual: <a href="' + f.nota_fiscal_consolidada_file_url + '" target="_blank">' + (f.nota_fiscal_consolidada_file_name || 'baixar') + '</a>';
          } else {
            consInfo.textContent = 'Nenhum arquivo anexado.';
          }
        }
        var fileP = document.getElementById('editNfPecasFile'); if (fileP) fileP.value = '';
        var fileS = document.getElementById('editNfServicosFile'); if (fileS) fileS.value = '';
        var fileC = document.getElementById('editNfConsolidadaFile'); if (fileC) fileC.value = '';

        document.getElementById('editDesconto').value = f.desconto || 0;
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
    var fd = new FormData();
    var getVal = function(id) { var el = document.getElementById(id); return el ? el.value : ''; };
    fd.append('fatura[status]', getVal('editStatus'));
    fd.append('fatura[data_envio_empresa]', getVal('editDtEnvio') || '');
    fd.append('fatura[data_recebimento]', getVal('editDtReceb') || '');
    fd.append('fatura[data_vencimento]', getVal('editDtVenc') || '');
    fd.append('fatura[nota_fiscal_numero]', getVal('editNfNumero') || '');
    fd.append('fatura[nota_fiscal_serie]', getVal('editNfSerie') || '');
    fd.append('fatura[nota_fiscal_numero_pecas]', getVal('editNfNumeroPecas') || '');
    fd.append('fatura[nota_fiscal_serie_pecas]', getVal('editNfSeriePecas') || '');
    fd.append('fatura[nota_fiscal_numero_servicos]', getVal('editNfNumeroServicos') || '');
    fd.append('fatura[nota_fiscal_serie_servicos]', getVal('editNfSerieServicos') || '');
    fd.append('fatura[desconto]', getVal('editDesconto') || 0);
    fd.append('fatura[admin_observacoes]', getVal('editObs') || '');

    var pecasFile = document.getElementById('editNfPecasFile');
    if (pecasFile && pecasFile.files && pecasFile.files[0]) {
      fd.append('fatura[nota_fiscal_pecas_file]', pecasFile.files[0]);
    }
    var servFile = document.getElementById('editNfServicosFile');
    if (servFile && servFile.files && servFile.files[0]) {
      fd.append('fatura[nota_fiscal_servicos_file]', servFile.files[0]);
    }
    var consFile = document.getElementById('editNfConsolidadaFile');
    if (consFile && consFile.files && consFile.files[0]) {
      fd.append('fatura[nota_fiscal_consolidada_file]', consFile.files[0]);
    }
    fd.append('_method', 'patch');

    $.ajax({
      url: '/faturamento/' + id,
      method: 'POST',
      data: fd,
      processData: false,
      contentType: false,
      headers: { 'X-CSRF-Token': csrfToken(), 'Accept': 'application/json' },
      dataType: 'json',
      success: function() {
        bootstrap.Modal.getInstance(document.getElementById('modalEditFatura')).hide();
        showAlert('Fatura atualizada com sucesso!');
        setTimeout(function() { window.location.reload(); }, 1000);
      },
      error: function(xhr) {
        var msg = 'Erro ao atualizar fatura';
        try {
          var err = JSON.parse(xhr.responseText).error;
          msg = Array.isArray(err) ? err.join(', ') : (err || msg);
        } catch(e) {}
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

  // ========== EXCLUIR FATURA ==========

  function excluirFatura(id, numero) {
    if (!confirm('Tem certeza que deseja excluir a fatura ' + numero + '?\n\nAs OS vinculadas serão liberadas para faturar novamente.')) return;

    $.ajax({
      url: '/faturamento/' + id,
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrfToken() },
      dataType: 'json',
      success: function(resp) {
        showAlert(resp.message || 'Fatura excluída com sucesso!');
        setTimeout(function() { window.location.reload(); }, 1000);
      },
      error: function(xhr) {
        var msg = 'Erro ao excluir fatura';
        try { msg = JSON.parse(xhr.responseText).error; } catch(e) {}
        showAlert(msg, 'danger');
      }
    });
  }

  // ========== MARCAR PAGO ==========

  function marcarPago(id) {
    if (!confirm('Confirma que esta fatura foi paga?')) return;

    $.ajax({
      url: '/faturamento/' + id + '/marcar_pago',
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken() },
      data: JSON.stringify({ data_pagamento: new Date().toISOString().substring(0, 10) }),
      contentType: 'application/json',
      dataType: 'json',
      success: function() {
        showAlert('Fatura marcada como paga!');
        setTimeout(function() { window.location.reload(); }, 1000);
      },
      error: function(xhr) {
        var msg = 'Erro ao marcar como paga';
        try { msg = JSON.parse(xhr.responseText).error; } catch(e) {}
        showAlert(msg, 'danger');
      }
    });
  }

  // ========== OS EM ABERTO ==========

  function carregarOSAbertos() {
    var clienteId = document.getElementById('fAbertoCliente').value;
    var content = document.getElementById('abertosContent');
    var ccSelect = document.getElementById('fAbertoCentroCusto');
    var suSelect = document.getElementById('fAbertoSubUnidade');
    var empenhoSelect = document.getElementById('fAbertoEmpenho');
    var btnLimpar = document.getElementById('btnLimparAbertos');

    // Preservar seleções atuais dos filtros
    var savedCC = ccSelect.value;
    var savedSU = suSelect.value;
    var savedEmpenho = empenhoSelect ? empenhoSelect.value : '';

    // Reset cost center and subunit filters
    ccSelect.innerHTML = '<option value="">Todos os centros de custo</option>';
    suSelect.innerHTML = '<option value="">Todas as subunidades</option>';
    ccSelect.disabled = true;
    suSelect.disabled = true;
    btnLimpar.disabled = true;
    _osAbertosData = [];
    _selectedOS = {};

    if (!clienteId) {
      _lastOsAbertosClientId = null;
      _lastOsAbertosCcId = null;
      content.innerHTML = '<p class="text-center text-muted py-5">Selecione um cliente para listar as OS autorizadas para faturamento.</p>';
      document.getElementById('previewSection').style.display = 'none';
      document.getElementById('successSection').style.display = 'none';
      return;
    }

    if (clienteId !== _lastOsAbertosClientId) {
      _lastOsAbertosClientId = clienteId;
      _lastOsAbertosCcId = null;
    }

    content.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" role="status"></div><p class="text-muted mt-2">Carregando OS autorizadas...</p></div>';

    // Build URL with date filters + filtros já escolhidos (evita depender só de comparação de texto no browser)
    var params = new URLSearchParams({ client_id: clienteId });
    var dtIni = document.getElementById('fAbertoDtIni');
    var dtFim = document.getElementById('fAbertoDtFim');
    if (dtIni && dtIni.value) params.set('data_inicio', dtIni.value);
    if (dtFim && dtFim.value) params.set('data_fim', dtFim.value);
    if (savedCC) params.set('cost_center_id', savedCC);
    if (savedSU) params.set('sub_unit_id', savedSU);
    if (savedEmpenho) params.set('commitment_id', savedEmpenho);

    $.ajax({
      url: '/faturamento/os_abertos_json?' + params.toString(),
      method: 'GET',
      dataType: 'json',
      success: function(data) {
        _osAbertosData = data.results || [];
        _clientDiscount = data.client_discount || 0;
        _clientSphere = data.client_sphere || 0;
        _contractsInfo = data.contracts_info || [];
        _commitmentNumbers = data.commitment_numbers || [];
        btnLimpar.disabled = false;

        // Populate cost center filter
        var costCenters = data.cost_centers || [];
        if (costCenters.length > 0) {
          ccSelect.disabled = false;
          costCenters.forEach(function(cc) {
            var opt = document.createElement('option');
            opt.value = cc.id;
            opt.textContent = cc.name;
            ccSelect.appendChild(opt);
          });
        }

        // Populate empenho filter
        if (empenhoSelect) {
          empenhoSelect.innerHTML = '<option value="">Todos os empenhos</option>';
          var commitments = data.commitments || [];
          if (commitments.length > 0) {
            empenhoSelect.disabled = false;
            commitments.forEach(function(cm) {
              var opt = document.createElement('option');
              opt.value = cm.id;
              opt.textContent = cm.number + (cm.contract ? ' (Contrato: ' + cm.contract + ')' : '');
              empenhoSelect.appendChild(opt);
            });
          } else {
            empenhoSelect.disabled = true;
          }
        }

        // Restaurar seleções salvas (se as opções ainda existem)
        if (savedCC) { ccSelect.value = savedCC; }
        if (savedSU) { suSelect.value = savedSU; }
        if (savedEmpenho && empenhoSelect) { empenhoSelect.value = savedEmpenho; }

        _lastOsAbertosCcId = savedCC ? savedCC : null;

        renderOSAbertosTable(_osAbertosData);
      },
      error: function() {
        content.innerHTML = '<div class="alert alert-danger">Erro ao carregar OS em aberto.</div>';
      }
    });
  }

  function filtrarOSAbertos() {
    var ccId = document.getElementById('fAbertoCentroCusto').value;
    var empenhoId = document.getElementById('fAbertoEmpenho') ? document.getElementById('fAbertoEmpenho').value : '';
    var suSelect = document.getElementById('fAbertoSubUnidade');
    var clienteId = document.getElementById('fAbertoCliente').value;
    if (!clienteId) return;

    var normCc = ccId ? ccId : null;
    var prevCc = _lastOsAbertosCcId;
    if (normCc !== prevCc) {
      if (normCc || prevCc) suSelect.value = '';
      _lastOsAbertosCcId = normCc;
    }
    var suId = suSelect.value;

    if (ccId) {
      $.ajax({
        url: '/faturamento/sub_units_json?cost_center_id=' + ccId,
        method: 'GET',
        dataType: 'json',
        success: function(data) {
          suSelect.innerHTML = '<option value="">Todas as subunidades</option>';
          var subs = data.sub_units || [];
          if (subs.length > 0) {
            suSelect.disabled = false;
            subs.forEach(function(su) {
              var opt = document.createElement('option');
              opt.value = su.id;
              opt.textContent = su.name;
              suSelect.appendChild(opt);
            });
            if (suId) suSelect.value = suId;
          } else {
            suSelect.disabled = true;
          }
        }
      });
    } else {
      suSelect.innerHTML = '<option value="">Todas as subunidades</option>';
      suSelect.disabled = true;
    }

    var params = new URLSearchParams({ client_id: clienteId });
    var dtIni = document.getElementById('fAbertoDtIni');
    var dtFim = document.getElementById('fAbertoDtFim');
    if (dtIni && dtIni.value) params.set('data_inicio', dtIni.value);
    if (dtFim && dtFim.value) params.set('data_fim', dtFim.value);
    if (ccId) params.set('cost_center_id', ccId);
    if (suId) params.set('sub_unit_id', suId);
    if (empenhoId) params.set('commitment_id', empenhoId);

    var content = document.getElementById('abertosContent');
    content.innerHTML = '<div class="text-center py-3"><div class="spinner-border spinner-border-sm text-primary"></div> Filtrando...</div>';

    $.ajax({
      url: '/faturamento/os_abertos_json?' + params.toString(),
      method: 'GET',
      dataType: 'json',
      success: function(data) {
        _osAbertosData = data.results || [];
        _clientDiscount = data.client_discount || 0;
        _clientSphere = data.client_sphere || 0;
        _contractsInfo = data.contracts_info || [];
        _commitmentNumbers = data.commitment_numbers || [];
        renderOSAbertosTable(_osAbertosData);
      },
      error: function() {
        content.innerHTML = '<div class="alert alert-danger">Erro ao filtrar OS em aberto.</div>';
      }
    });
  }

  function limparFiltrosAbertos() {
    _lastOsAbertosCcId = null;
    document.getElementById('fAbertoCentroCusto').value = '';
    document.getElementById('fAbertoSubUnidade').value = '';
    var empenhoSel = document.getElementById('fAbertoEmpenho');
    if (empenhoSel) empenhoSel.value = '';
    var dtIni = document.getElementById('fAbertoDtIni');
    var dtFim = document.getElementById('fAbertoDtFim');
    if (dtIni) dtIni.value = '';
    if (dtFim) dtFim.value = '';
    _selectedOS = {};
    carregarOSAbertos();
  }

  function renderOSAbertosTable(rows) {
    var content = document.getElementById('abertosContent');

    if (!rows.length) {
      content.innerHTML = '<div class="alert alert-secondary"><i class="bi bi-info-circle me-2"></i>Nenhuma OS autorizada encontrada para este cliente/filtro.</div>';
      return;
    }

    var totalBruto = 0;
    rows.forEach(function(os) { totalBruto += os.total_bruto; });

    var html = '<div class="card border-0 shadow-sm">';

    // Summary bar
    html += '<div class="card-header bg-white d-flex justify-content-between align-items-center">';
    html += '<div><strong>' + rows.length + '</strong> OS autorizadas | Total Bruto: <strong>' + money(totalBruto) + '</strong></div>';
    html += '<div>';
    html += '<button class="btn btn-sm btn-outline-primary me-2" onclick="Faturamento.toggleSelectAll()"><i class="bi bi-check-all"></i> Selecionar Todas</button>';
    html += '<button class="btn btn-sm btn-primary" onclick="Faturamento.gerarPrevia()" id="btnGerarPrevia" disabled><i class="bi bi-eye"></i> Gerar Prévia</button>';
    html += '</div></div>';

    // Table
    html += '<div class="table-responsive"><table class="table table-hover mb-0">';
    html += '<thead class="table-light"><tr>';
    html += '<th width="40"><input type="checkbox" class="form-check-input" id="checkAll" onchange="Faturamento.toggleSelectAll()"></th>';
    html += '<th class="text-uppercase small text-muted">OS</th>';
    html += '<th class="text-uppercase small text-muted">Fornecedor</th>';
    html += '<th class="text-uppercase small text-muted">Veículo</th>';
    html += '<th class="text-uppercase small text-muted">C.Custo</th>';
    html += '<th class="text-uppercase small text-muted">Peças (NF)</th>';
    html += '<th class="text-uppercase small text-muted">Serviços (NF)</th>';
    html += '<th class="text-uppercase small text-muted">Valor Bruto</th>';
    html += '<th class="text-uppercase small text-muted">V. c/ Desc.</th>';
    html += '</tr></thead><tbody>';

    rows.forEach(function(os) {
      var checked = _selectedOS[os.id] ? ' checked' : '';
      // ATENÇÃO: optante_simples=true no DB = NÃO optante (badge invertido)
      var isSimples = !os.provider_optante_simples;
      html += '<tr class="' + (_selectedOS[os.id] ? 'table-primary' : '') + '">';
      html += '<td><input type="checkbox" class="form-check-input os-check" value="' + os.id + '"' + checked + ' onchange="Faturamento.toggleOS(' + os.id + ')"></td>';
      html += '<td><strong>#' + escapeHtml(os.code) + '</strong></td>';
      html += '<td><small>' + escapeHtml(os.provider || '-') + '</small>';
      if (isSimples) html += ' <span class="badge bg-success" style="font-size:0.6em;">Simples</span>';
      else html += ' <span class="badge bg-warning text-dark" style="font-size:0.6em;">Não-Simples</span>';
      html += '</td>';
      html += '<td>' + escapeHtml(os.vehicle_plate) + '</td>';
      html += '<td>' + escapeHtml(os.cost_center || '-') + '</td>';
      html += '<td>' + money(os.bruto_pecas) + (os.nf_pecas ? '<br><small class="text-muted">NF ' + escapeHtml(os.nf_pecas) + '</small>' : '') + '</td>';
      html += '<td>' + money(os.bruto_servicos) + (os.nf_servicos ? '<br><small class="text-muted">NF ' + escapeHtml(os.nf_servicos) + '</small>' : '') + '</td>';
      html += '<td><strong>' + money(os.total_bruto) + '</strong></td>';
      html += '<td class="text-success fw-bold">' + money(os.total_com_desconto) + '</td>';
      html += '</tr>';
    });

    html += '</tbody></table></div></div>';
    content.innerHTML = html;
    updateGerarPreviaBtn();
  }

  function toggleOS(osId) {
    _selectedOS[osId] = !_selectedOS[osId];
    if (!_selectedOS[osId]) delete _selectedOS[osId];
    updateGerarPreviaBtn();
    // Update row style
    var checkboxes = document.querySelectorAll('.os-check');
    checkboxes.forEach(function(cb) {
      var row = cb.closest('tr');
      if (parseInt(cb.value) === osId) {
        row.className = _selectedOS[osId] ? 'table-primary' : '';
      }
    });
  }

  function toggleSelectAll() {
    var visibleCount = _osAbertosData.length;
    var selectedCount = Object.keys(_selectedOS).length;
    var allChecked = visibleCount > 0 && selectedCount === visibleCount;

    _selectedOS = {};
    if (!allChecked) {
      _osAbertosData.forEach(function(os) { _selectedOS[os.id] = true; });
    }

    renderOSAbertosTable(_osAbertosData);
  }

  function updateGerarPreviaBtn() {
    var btn = document.getElementById('btnGerarPrevia');
    var count = Object.keys(_selectedOS).length;
    if (btn) {
      btn.disabled = count === 0;
      btn.innerHTML = '<i class="bi bi-eye"></i> Gerar Prévia' + (count > 0 ? ' (' + count + ')' : '');
    }
  }

  function gerarPrevia() {
    var ids = Object.keys(_selectedOS).map(Number);
    if (ids.length === 0) return;

    // Preservar estados antes de reconstruir o HTML
    var chkEl = document.getElementById('previaAplicarRetencao');
    var aplicarRetencao = chkEl ? chkEl.checked : true;
    var prevObs = document.getElementById('previaObs');
    var savedObs = prevObs ? prevObs.value : '';
    var prevTipo = document.getElementById('previaTipoValor');
    var savedTipo = prevTipo ? prevTipo.value : 'bruto';
    var prevVenc = document.getElementById('previaVencimento');
    var savedVenc = prevVenc ? prevVenc.value : '';

    // Preservar observações por OS já digitadas
    document.querySelectorAll('.os-obs-input').forEach(function(el) {
      var osId = parseInt(el.getAttribute('data-os-id'));
      if (osId) _osObservacoes[osId] = el.value;
    });

    var selectedOSData = _osAbertosData.filter(function(os) { return ids.indexOf(os.id) >= 0; });

    // Totais - usando valores BRUTO da proposta (sem desconto)
    var totalBrutoPecas = 0, totalBrutoServicos = 0, totalBruto = 0;
    var totalDescPecas = 0, totalDescServicos = 0, totalDesconto = 0;
    var totalComDesconto = 0;

    // === REGRA RETENÇÃO (Config Impostos) ===
    // ATENÇÃO: optante_simples=true no DB = NÃO optante (label invertido)
    // !os.provider_optante_simples = IS simples = ISENTO
    // os.provider_optante_simples = NOT simples = APLICAR retenção
    var sphereNames = { 0: 'Municipal', 1: 'Estadual', 2: 'Federal' };
    var sphereName = sphereNames[_clientSphere] || 'Municipal';
    var isFederal = (_clientSphere === 2);

    var retPecasNaoSimples = 0, retServicosNaoSimples = 0;

    selectedOSData.forEach(function(os) {
      totalBrutoPecas += os.bruto_pecas;
      totalBrutoServicos += os.bruto_servicos;
      totalBruto += os.total_bruto;
      totalDescPecas += os.desc_pecas;
      totalDescServicos += os.desc_servicos;
      totalDesconto += os.total_desconto;
      totalComDesconto += os.total_com_desconto;

      // Retenção por tipo de valor selecionado:
      // - bruto: usa base sem desconto por categoria
      // - liquido: usa base com desconto por categoria
      // optante_simples=true = NÃO simples = aplicar retenção
      var isSimples = !os.provider_optante_simples;
      if (isSimples) return; // Simples = ISENTO

      var basePecas = (savedTipo === 'liquido') ? (os.bruto_pecas - os.desc_pecas) : os.bruto_pecas;
      var baseServicos = (savedTipo === 'liquido') ? (os.bruto_servicos - os.desc_servicos) : os.bruto_servicos;

      // Não-simples: retenção sobre a base escolhida
      if (isFederal) {
        retPecasNaoSimples += basePecas * 0.0585;       // 5,85%
        retServicosNaoSimples += baseServicos * 0.0945; // 9,45%
      } else {
        retPecasNaoSimples += basePecas * 0.012;        // 1,20%
        retServicosNaoSimples += baseServicos * 0.048;  // 4,80%
      }
    });

    var totalRetNaoSimples = retPecasNaoSimples + retServicosNaoSimples;
    var totalRetencoes = aplicarRetencao ? totalRetNaoSimples : 0;

    var valorLiquido = totalComDesconto;
    // bruto = total sem desconto; liquido = total com desconto
    // retenções incidem sobre o valor escolhido
    var valorBase = (savedTipo === 'liquido') ? valorLiquido : totalBruto;
    var valorDevido = valorBase - totalRetencoes;

    // Percentual de desconto efetivo (com precisão)
    var pctDesconto = totalBruto > 0 ? ((totalDesconto / totalBruto) * 100) : 0;

    var clienteNome = document.getElementById('fAbertoCliente').selectedOptions[0].textContent;
    var vencDefault = new Date();
    vencDefault.setDate(vencDefault.getDate() + 30);
    var vencStr = savedVenc || vencDefault.toISOString().substring(0, 10);

    // Período apurado
    var dataInicio = document.getElementById('fAbertoDtIni');
    var dataFim = document.getElementById('fAbertoDtFim');
    var periodoInicio = dataInicio && dataInicio.value ? dataInicio.value : '';
    var periodoFim = dataFim && dataFim.value ? dataFim.value : '';
    if (!periodoInicio && selectedOSData.length > 0) {
      var datas = selectedOSData.map(function(os) { return os.created_at; }).filter(Boolean).sort();
      if (datas.length > 0) { periodoInicio = datas[0]; periodoFim = datas[datas.length - 1]; }
    }

    // Contratos e empenhos
    var contractNums = [];
    var commitNums = [];
    selectedOSData.forEach(function(os) {
      if (os.contract_number && contractNums.indexOf(os.contract_number) < 0) contractNums.push(os.contract_number);
      if (os.commitment_number && commitNums.indexOf(os.commitment_number) < 0) commitNums.push(os.commitment_number);
    });

    // ===== BUILD PREVIEW =====
    var html = '';

    // Header
    html += '<div class="mb-3">';
    html += '<h5 class="fw-bold mb-1"><i class="bi bi-building me-2"></i>' + escapeHtml(clienteNome) + '</h5>';
    html += '<span class="badge bg-success me-2">' + escapeHtml(sphereName) + '</span>';
    html += '<span class="badge bg-primary me-2">Desc. Contrato ' + pctDesconto.toFixed(2).replace('.', ',') + '%</span>';
    if (contractNums.length > 0) html += '<span class="badge bg-dark me-2">Contrato: ' + escapeHtml(contractNums.join(', ')) + '</span>';
    if (commitNums.length > 0) html += '<span class="badge bg-secondary me-2">Empenho: ' + escapeHtml(commitNums.join(', ')) + '</span>';
    if (periodoInicio) html += '<span class="badge bg-info text-dark">Período: ' + escapeHtml(periodoInicio) + ' a ' + escapeHtml(periodoFim || periodoInicio) + '</span>';
    html += '</div>';

    // Saldo contrato
    if (_contractsInfo.length > 0) {
      html += '<div class="alert alert-light border py-2 px-3 mb-3 small">';
      html += '<i class="bi bi-wallet2 me-1"></i><strong>Saldo Contrato:</strong> ';
      _contractsInfo.forEach(function(c, i) {
        if (i > 0) html += ' | ';
        var pct = c.total > 0 ? ((c.saldo / c.total) * 100).toFixed(1) : '0.0';
        html += '#' + escapeHtml(c.number) + ': ' + money(c.saldo) + ' (' + pct + '% disponível)';
      });
      html += '</div>';
    }

    // Cards de resumo
    html += '<div class="row g-2 mb-3">';
    html += '<div class="col"><div class="card border shadow-sm h-100"><div class="card-body text-center py-2">';
    html += '<small class="text-muted text-uppercase d-block" style="font-size:0.7em">Valor Bruto</small>';
    html += '<h5 class="fw-bold mb-0 text-primary">' + money(totalBruto) + '</h5>';
    html += '</div></div></div>';

    html += '<div class="col"><div class="card border shadow-sm h-100"><div class="card-body text-center py-2">';
    html += '<small class="text-muted text-uppercase d-block" style="font-size:0.7em">Desconto (' + pctDesconto.toFixed(2).replace('.', ',') + '%)</small>';
    html += '<h5 class="fw-bold mb-0 text-danger">- ' + money(totalDesconto) + '</h5>';
    html += '</div></div></div>';

    html += '<div class="col"><div class="card border shadow-sm h-100"><div class="card-body text-center py-2">';
    html += '<small class="text-muted text-uppercase d-block" style="font-size:0.7em">Retenções</small>';
    html += '<h5 class="fw-bold mb-0" style="color:#c57200">- ' + money(totalRetencoes) + '</h5>';
    html += '</div></div></div>';

    html += '<div class="col"><div class="card border shadow-sm h-100"><div class="card-body text-center py-2">';
    html += '<small class="text-muted text-uppercase d-block" style="font-size:0.7em">Valor c/ Desconto</small>';
    html += '<h5 class="fw-bold mb-0 text-info">' + money(valorLiquido) + '</h5>';
    html += '</div></div></div>';
    html += '</div>';

    // VALOR DEVIDO bar
    var labelValorDevido = savedTipo === 'liquido' ? 'VALOR LÍQUIDO (c/ Desconto e Retenções)' : 'VALOR BRUTO (s/ Desconto, c/ Retenções)';
    html += '<div class="rounded-3 mb-4 p-3 d-flex justify-content-between align-items-center" style="background: linear-gradient(135deg, #251C59, #005BED); color: #fff;">';
    html += '<h5 class="mb-0 fw-bold"><i class="bi bi-cash-stack me-2"></i>' + labelValorDevido + '</h5>';
    html += '<h4 class="mb-0 fw-bold">' + money(valorDevido) + '</h4>';
    html += '</div>';

    // Items table
    html += '<div class="table-responsive mb-3"><table class="table table-sm table-bordered mb-0">';
    html += '<thead class="table-light"><tr>';
    html += '<th>OS</th><th>Fornecedor</th><th>Veículo</th><th>C.Custo</th>';
    html += '<th>Peças<br><small class="fw-normal text-muted">Bruto / Líq.</small></th>';
    html += '<th>Serviços<br><small class="fw-normal text-muted">Bruto / Líq.</small></th>';
    html += '<th>Valor Bruto</th><th>Desc.</th><th>V. c/ Desc.</th>';
    html += '</tr></thead><tbody>';

    selectedOSData.forEach(function(os) {
      var isSimples = !os.provider_optante_simples;
      var osPctDesc = os.total_bruto > 0 ? ((os.total_desconto / os.total_bruto) * 100) : 0;
      var liqPecas = os.bruto_pecas - os.desc_pecas;
      var liqServicos = os.bruto_servicos - os.desc_servicos;
      html += '<tr>';
      html += '<td><strong>#' + escapeHtml(os.code) + '</strong></td>';
      html += '<td><small>' + escapeHtml(os.provider || '-') + '</small>';
      if (isSimples) html += ' <span class="badge bg-success" style="font-size:0.6em;">Simples (Isento)</span>';
      else html += ' <span class="badge bg-warning text-dark" style="font-size:0.6em;">Não-Simples</span>';
      html += '</td>';
      html += '<td>' + escapeHtml(os.vehicle_plate) + '</td>';
      html += '<td>' + escapeHtml(os.cost_center || '-') + '</td>';
      html += '<td>' + money(os.bruto_pecas) + '<br><small class="text-success">' + money(liqPecas) + '</small>';
      if (os.nf_pecas) html += '<br><small class="text-muted">NF ' + escapeHtml(os.nf_pecas) + '</small>';
      html += '</td>';
      html += '<td>' + money(os.bruto_servicos) + '<br><small class="text-success">' + money(liqServicos) + '</small>';
      if (os.nf_servicos) html += '<br><small class="text-muted">NF ' + escapeHtml(os.nf_servicos) + '</small>';
      html += '</td>';
      html += '<td>' + money(os.total_bruto) + '</td>';
      html += '<td class="text-danger">- ' + money(os.total_desconto) + ' <small class="text-muted">(' + osPctDesc.toFixed(2).replace('.', ',') + '%)</small></td>';
      html += '<td class="text-success fw-bold">' + money(os.total_com_desconto) + '</td>';
      html += '</tr>';

      // Supplier detail row
      var savedOsObs = _osObservacoes[os.id] || '';
      html += '<tr style="background:#f8f9fa; font-size:0.8em;">';
      html += '<td colspan="9" class="py-1 ps-4">';
      html += '<span class="text-muted"><i class="bi bi-person-vcard me-1"></i>';
      html += '<strong>CNPJ:</strong> ' + escapeHtml(os.provider_cnpj || '-');
      html += ' &nbsp;|&nbsp; <strong>Regime:</strong> ' + (isSimples ? 'Simples Nacional (Isento de Retenção)' : 'Não-Simples (Retenção Aplicável)');
      html += ' &nbsp;|&nbsp; <strong>Contato:</strong> ' + escapeHtml(os.provider_phone || os.provider_email || '-');
      html += '</span>';
      html += ' &nbsp; <input type="text" class="os-obs-input form-control form-control-sm d-inline-block ms-2"';
      html += ' data-os-id="' + os.id + '" placeholder="Observação..." style="width:calc(100% - 600px); min-width:180px;"';
      html += ' value="' + escapeHtml(savedOsObs) + '">';
      html += '</td></tr>';
    });

    html += '<tr class="table-light fw-bold"><td colspan="4" class="text-end">SUBTOTAIS:</td>';
    html += '<td>' + money(totalBrutoPecas) + '<br><small class="fw-normal text-success">' + money(totalBrutoPecas - totalDescPecas) + '</small></td>';
    html += '<td>' + money(totalBrutoServicos) + '<br><small class="fw-normal text-success">' + money(totalBrutoServicos - totalDescServicos) + '</small></td>';
    html += '<td>' + money(totalBruto) + '</td>';
    html += '<td class="text-danger">- ' + money(totalDesconto) + '</td>';
    html += '<td class="text-success">' + money(totalComDesconto) + '</td></tr>';
    html += '</tbody></table></div>';

    // Resumo Financeiro
    html += '<div class="card border-0 mb-3" style="background:#f0f0f0;">';
    html += '<div class="card-body">';
    html += '<h6 class="fw-bold mb-3"><i class="bi bi-calculator me-1"></i> Resumo Financeiro</h6>';
    html += '<div class="row">';

    // Coluna valores
    html += '<div class="col-md-7">';
    html += '<table class="table table-sm table-borderless mb-0">';

    // Detalhamento peças
    html += '<tr><td colspan="2" class="text-muted small fw-bold"><u>Peças</u></td></tr>';
    html += '<tr><td class="ps-3">Total sem desconto</td><td class="text-end fw-bold">' + money(totalBrutoPecas) + '</td></tr>';
    html += '<tr><td class="ps-3 text-muted">(-) Desconto (' + pctDesconto.toFixed(2).replace('.', ',') + '%)</td><td class="text-end text-danger">- ' + money(totalDescPecas) + '</td></tr>';
    html += '<tr><td class="ps-3 fw-bold">Total peças c/ desconto</td><td class="text-end text-success fw-bold">' + money(totalBrutoPecas - totalDescPecas) + '</td></tr>';

    // Detalhamento serviços
    html += '<tr><td colspan="2" class="text-muted small fw-bold pt-2"><u>Serviços</u></td></tr>';
    html += '<tr><td class="ps-3">Total sem desconto</td><td class="text-end fw-bold">' + money(totalBrutoServicos) + '</td></tr>';
    html += '<tr><td class="ps-3 text-muted">(-) Desconto (' + pctDesconto.toFixed(2).replace('.', ',') + '%)</td><td class="text-end text-danger">- ' + money(totalDescServicos) + '</td></tr>';
    html += '<tr><td class="ps-3 fw-bold">Total serviços c/ desconto</td><td class="text-end text-success fw-bold">' + money(totalBrutoServicos - totalDescServicos) + '</td></tr>';

    // Totais gerais
    html += '<tr class="border-top"><td class="fw-bold pt-2">Valor Bruto Total</td><td class="text-end fw-bold pt-2">' + money(totalBruto) + '</td></tr>';
    html += '<tr><td class="text-muted">(-) Desconto Total (' + pctDesconto.toFixed(2).replace('.', ',') + '%)</td><td class="text-end text-danger">- ' + money(totalDesconto) + '</td></tr>';
    html += '<tr class="border-top"><td class="fw-bold">Valor c/ Desconto</td><td class="text-end fw-bold text-primary">' + money(valorLiquido) + '</td></tr>';

    // Checkbox Aplicar Retenção Fiscal
    var chkChecked = aplicarRetencao ? 'checked' : '';
    var chkStyle = aplicarRetencao ? 'background:#fff3cd; border-color:#ffc107;' : 'background:#343a40; border-color:#343a40; color:#fff;';
    html += '<tr><td colspan="2" class="py-2">';
    html += '<div class="py-2 px-3 mb-0 d-flex align-items-center rounded" style="' + chkStyle + '">';
    html += '<input type="checkbox" class="form-check-input me-2" id="previaAplicarRetencao" ' + chkChecked + ' onchange="Faturamento.recalcularPrevia()">';
    html += '<strong>' + (aplicarRetencao ? 'Aplicar Retenção Fiscal' : 'Retenção Fiscal DESABILITADA') + '</strong>';
    html += '&nbsp; <small class="' + (aplicarRetencao ? 'text-muted' : '') + '">Esfera: ' + escapeHtml(sphereName) + '</small>';
    html += '</div></td></tr>';

    // Retenções detalhadas
    if (aplicarRetencao && totalRetNaoSimples > 0) {
      var pctPecas = isFederal ? '5,85%' : '1,20%';
      var pctServ = isFederal ? '9,45%' : '4,80%';
      var detailPecas = isFederal ? 'IR 1,2% + CSLL 1% + PIS 0,65% + Cofins 3%' : 'somente IR';
      var detailServ = isFederal ? 'IR 4,8% + CSLL 1% + PIS 0,65% + Cofins 3%' : 'somente IR';

      html += '<tr><td class="text-muted ps-3" colspan="2"><small><strong>Não-Simples (' + escapeHtml(sphereName) + '):</strong></small></td></tr>';
      if (retPecasNaoSimples > 0) html += '<tr><td class="text-muted ps-4">(-) Peças (' + pctPecas + ' - ' + detailPecas + ')</td><td class="text-end text-danger">- ' + money(retPecasNaoSimples) + '</td></tr>';
      if (retServicosNaoSimples > 0) html += '<tr><td class="text-muted ps-4">(-) Serviços (' + pctServ + ' - ' + detailServ + ')</td><td class="text-end text-danger">- ' + money(retServicosNaoSimples) + '</td></tr>';
      html += '<tr class="border-top"><td class="text-muted fw-bold">Total Retenções</td><td class="text-end text-danger fw-bold">- ' + money(totalRetencoes) + '</td></tr>';
    } else if (!aplicarRetencao) {
      html += '<tr><td colspan="2" class="py-1"><div class="rounded py-1 px-3" style="background:#343a40; color:#fff;"><i class="bi bi-slash-circle me-1"></i>Retenções desabilitadas pelo usuário</div></td></tr>';
    } else {
      html += '<tr><td class="text-muted" colspan="2"><i class="bi bi-check-circle text-success me-1"></i>Todos os fornecedores são Simples Nacional — isento de retenção</td></tr>';
    }

    html += '<tr class="border-top"><td class="fw-bold fs-6">Valor Devido</td><td class="text-end fw-bold text-success fs-6">' + money(valorDevido) + '</td></tr>';
    html += '</table>';
    html += '</div>';

    // Coluna informativa
    html += '<div class="col-md-5">';
    html += '<div class="alert alert-info py-2 px-3 mb-2 small"><i class="bi bi-info-circle me-1"></i><strong>Simples Nacional:</strong> Fornecedor optante pelo Simples é <u>isento</u> de retenção tributária.</div>';

    var aliqInfo = '<strong>Alíquotas Não-Simples (' + escapeHtml(sphereName) + '):</strong><br>';
    if (isFederal) {
      aliqInfo += 'Peças: <strong>5,85%</strong> (IR 1,2 + CSLL 1 + PIS 0,65 + Cofins 3)<br>';
      aliqInfo += 'Serviços: <strong>9,45%</strong> (IR 4,8 + CSLL 1 + PIS 0,65 + Cofins 3)';
    } else {
      aliqInfo += 'Peças: <strong>1,20%</strong> (somente IR)<br>';
      aliqInfo += 'Serviços: <strong>4,80%</strong> (somente IR)';
    }
    html += '<div class="alert alert-warning py-2 px-3 mb-2 small"><i class="bi bi-info-circle me-1"></i>' + aliqInfo + '</div>';
    html += '</div>';

    html += '</div></div></div>';

    // Campos editáveis: Vencimento, Tipo de valor
    html += '<div class="row mb-3 g-3">';
    html += '<div class="col-md-3">';
    html += '<label class="form-label fw-bold">Data de Vencimento</label>';
    html += '<input type="date" class="form-control" id="previaVencimento" value="' + vencStr + '">';
    html += '</div>';
    html += '<div class="col-md-3">';
    html += '<label class="form-label fw-bold">Tipo de Valor da Fatura</label>';
    html += '<select class="form-select" id="previaTipoValor" onchange="Faturamento.recalcularPrevia()">';
    html += '<option value="bruto"' + (savedTipo === 'bruto' ? ' selected' : '') + '>Valor Bruto (' + money(totalBruto) + ')</option>';
    html += '<option value="liquido"' + (savedTipo === 'liquido' ? ' selected' : '') + '>Valor Líquido (' + money(valorLiquido) + ')</option>';
    html += '</select>';
    html += '<small class="text-muted d-block mt-1"><i class="bi bi-info-circle me-1"></i>Retenções incidem sobre o valor selecionado</small>';
    html += '</div>';
    html += '</div>';

    // Observations input
    html += '<div class="mb-3"><label class="form-label">Observações (opcional)</label>';
    html += '<textarea class="form-control" id="previaObs" rows="2" placeholder="Observações para a fatura...">' + escapeHtml(savedObs) + '</textarea></div>';

    html += '<div class="d-flex justify-content-end gap-2">';
    html += '<button class="btn btn-outline-secondary" onclick="Faturamento.voltarSelecao()"><i class="bi bi-arrow-left"></i> Voltar</button>';
    html += '<button class="btn btn-success btn-lg" onclick="Faturamento.confirmarFatura()"><i class="bi bi-check-circle"></i> Confirmar e Gerar Fatura</button>';
    html += '</div>';

    document.getElementById('previewContent').innerHTML = html;
    document.getElementById('abertosContent').style.display = 'none';
    document.getElementById('previewSection').style.display = '';
    document.getElementById('successSection').style.display = 'none';
  }

  // Recalcular prévia quando checkbox de retenção muda
  function recalcularPrevia() {
    gerarPrevia();
  }

  function confirmarFatura() {
    var ids = Object.keys(_selectedOS).map(Number);
    var clienteId = document.getElementById('fAbertoCliente').value;
    var obs = document.getElementById('previaObs') ? document.getElementById('previaObs').value : '';
    var tipoValor = document.getElementById('previaTipoValor') ? document.getElementById('previaTipoValor').value : 'bruto';
    var chkRetencao = document.getElementById('previaAplicarRetencao');
    var aplicarRetencao = chkRetencao ? chkRetencao.checked : true;
    var vencimento = document.getElementById('previaVencimento') ? document.getElementById('previaVencimento').value : '';

    // Coletar observações por OS antes de confirmar
    document.querySelectorAll('.os-obs-input').forEach(function(el) {
      var osId = parseInt(el.getAttribute('data-os-id'));
      if (osId) _osObservacoes[osId] = el.value;
    });

    if (ids.length === 0 || !clienteId) return;

    // Disable button
    var btns = document.querySelectorAll('#previewSection button');
    btns.forEach(function(b) { b.disabled = true; });

    $.ajax({
      url: '/faturamento',
      method: 'POST',
      data: JSON.stringify({
        client_id: clienteId,
        order_service_ids: ids,
        observacoes: obs,
        os_observacoes: _osObservacoes,
        tipo_valor: tipoValor,
        aplicar_retencao: aplicarRetencao,
        vencimento: vencimento
      }),
      contentType: 'application/json',
      headers: { 'X-CSRF-Token': csrfToken() },
      dataType: 'json',
      success: function(resp) {
        document.getElementById('previewSection').style.display = 'none';
        document.getElementById('successSection').style.display = '';

        var msgHtml = '<strong>Fatura ' + escapeHtml(resp.numero) + ' criada com sucesso!</strong>';
        msgHtml += '<br><span class="text-muted">' + ids.length + ' OS faturadas</span>';
        document.getElementById('successMsg').innerHTML = msgHtml;

        var actionsHtml = '<a href="/faturamento/' + resp.fatura_id + '" class="btn btn-primary me-2"><i class="bi bi-eye"></i> Ver Fatura</a>';
        actionsHtml += '<a href="/faturamento/' + resp.fatura_id + '/gerar_pdf" class="btn btn-outline-danger me-2"><i class="bi bi-file-earmark-pdf"></i> PDF</a>';
        actionsHtml += '<a href="/faturamento/' + resp.fatura_id + '/gerar_docx" class="btn btn-outline-success me-2"><i class="bi bi-file-earmark-word"></i> Word</a>';
        actionsHtml += '<a href="/faturamento/' + resp.fatura_id + '/gerar_excel" class="btn btn-outline-primary me-2"><i class="bi bi-file-earmark-spreadsheet"></i> Excel</a>';
        actionsHtml += '<button class="btn btn-outline-secondary" onclick="Faturamento.resetFatura()"><i class="bi bi-plus-circle"></i> Nova Fatura</button>';
        document.getElementById('successActions').innerHTML = actionsHtml;
      },
      error: function(xhr) {
        btns.forEach(function(b) { b.disabled = false; });
        var msg = 'Erro ao gerar fatura';
        try { msg = JSON.parse(xhr.responseText).error; } catch(e) {}
        showAlert(msg, 'danger');
      }
    });
  }

  function voltarSelecao() {
    document.getElementById('abertosContent').style.display = '';
    document.getElementById('previewSection').style.display = 'none';
  }

  function resetFatura() {
    document.getElementById('successSection').style.display = 'none';
    document.getElementById('abertosContent').style.display = '';
    _selectedOS = {};
    _osObservacoes = {};
    carregarOSAbertos(); // Refresh list
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
    excluirFatura: excluirFatura,
    marcarPago: marcarPago,
    carregarOSAbertos: carregarOSAbertos,
    filtrarOSAbertos: filtrarOSAbertos,
    limparFiltrosAbertos: limparFiltrosAbertos,
    toggleOS: toggleOS,
    toggleSelectAll: toggleSelectAll,
    gerarPrevia: gerarPrevia,
    recalcularPrevia: recalcularPrevia,
    confirmarFatura: confirmarFatura,
    voltarSelecao: voltarSelecao,
    resetFatura: resetFatura
  };
})();
