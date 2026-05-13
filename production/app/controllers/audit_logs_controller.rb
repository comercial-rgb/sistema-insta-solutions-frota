require 'csv'
require 'prawn/table' if defined?(Prawn)

class AuditLogsController < ApplicationController
  before_action :ensure_admin_or_manager

  PER_PAGE    = 50
  ACTION_LABELS = {
    'create'  => 'Criação',
    'update'  => 'Atualização',
    'destroy' => 'Exclusão',
    'login'   => 'Login',
    'logout'  => 'Logout'
  }.freeze
  ENTITY_LABELS = {
    'OrderService'         => 'Ordem de Serviço',
    'OrderServiceProposal' => 'Proposta',
    'ServiceGroup'         => 'Grupo de Serviços',
    'ServiceGroupItem'     => 'Item de Grupo',
    'Session'              => 'Sessão (Login/Logout)'
  }.freeze

  def index
    @audits      = build_query.page(params[:page]).per(PER_PAGE)
    @users       = users_for_filter
    @action_opts = ACTION_LABELS
    @entity_opts = ENTITY_LABELS
  end

  def export
    audits = build_query

    respond_to do |format|
      format.csv do
        send_data render_csv(audits),
          filename: "auditoria_#{Date.today.strftime('%Y%m%d')}.csv",
          type: 'text/csv; charset=utf-8'
      end
      format.pdf do
        pdf_data = render_pdf(audits)
        send_data pdf_data,
          filename: "auditoria_#{Date.today.strftime('%Y%m%d')}.pdf",
          type: 'application/pdf',
          disposition: 'attachment'
      end
    end
  end

  private

  def build_query
    scope = Audited::Audit.includes(:user).order(created_at: :desc)

    scope = scope.where(user_id: params[:user_id])                                    if params[:user_id].present?
    scope = scope.where('created_at >= ?', params[:start_date].to_date.beginning_of_day) if params[:start_date].present?
    scope = scope.where('created_at <= ?', params[:end_date].to_date.end_of_day)         if params[:end_date].present?
    scope = scope.where(action: params[:action_filter])                               if params[:action_filter].present?
    scope = scope.where(auditable_type: params[:auditable_type])                      if params[:auditable_type].present?

    unless @current_user.admin?
      scope = apply_client_scope(scope)
    end

    scope
  rescue ArgumentError
    Audited::Audit.none
  end

  def apply_client_scope(scope)
    client_id    = @current_user.client_id
    os_ids       = OrderService.where(client_id: client_id).pluck(:id).presence || [-1]
    proposal_ids = OrderServiceProposal.joins(:order_service)
                     .where(order_services: { client_id: client_id }).pluck(:id).presence || [-1]
    user_ids     = User.where(client_id: client_id).pluck(:id).presence || [-1]

    scope.where(
      "(auditable_type = 'OrderService'         AND auditable_id IN (:os_ids))   OR " \
      "(auditable_type = 'OrderServiceProposal' AND auditable_id IN (:prop_ids)) OR " \
      "(auditable_type = 'Session'              AND user_id      IN (:u_ids))",
      os_ids: os_ids, prop_ids: proposal_ids, u_ids: user_ids
    )
  end

  def users_for_filter
    if @current_user.admin?
      User.active.order(:name).pluck(:name, :id)
    else
      User.active.where(client_id: @current_user.client_id).order(:name).pluck(:name, :id)
    end
  end

  def format_changes(audit)
    return '—' if audit.audited_changes.blank?

    if audit.audited_changes['order_service_status'].present?
      changes = audit.audited_changes['order_service_status']
      "#{changes[0]} → #{changes[1]}"
    elsif audit.audited_changes['order_service_proposal_status'].present?
      changes = audit.audited_changes['order_service_proposal_status']
      "#{changes[0]} → #{changes[1]}"
    elsif audit.action.in?(%w[login logout])
      "IP: #{audit.remote_address.presence || '—'}"
    else
      count = audit.audited_changes.keys.size
      "#{count} campo(s) alterado(s)"
    end
  end

  def render_csv(audits)
    CSV.generate(col_sep: ';', encoding: 'UTF-8', write_headers: true,
                 headers: ['ID', 'Data/Hora', 'Usuário', 'E-mail', 'IP',
                           'Entidade', 'ID Entidade', 'Ação', 'Mudanças']) do |csv|
      audits.each do |audit|
        csv << [
          audit.id,
          audit.created_at.in_time_zone('Brasilia').strftime('%d/%m/%Y %H:%M:%S'),
          audit.user&.name  || '(sistema)',
          audit.user&.email || '—',
          audit.remote_address.presence || '—',
          ENTITY_LABELS[audit.auditable_type] || audit.auditable_type,
          audit.auditable_id,
          ACTION_LABELS[audit.action] || audit.action,
          format_changes(audit)
        ]
      end
    end
  end

  def render_pdf(audits)
    Prawn::Document.new(page_layout: :landscape, margin: 20) do |pdf|
      pdf.font_size 9

      pdf.text 'Log de Auditoria do Sistema', size: 14, style: :bold
      pdf.text "Gerado em: #{Time.current.in_time_zone('Brasilia').strftime('%d/%m/%Y às %H:%M')}", size: 8
      pdf.move_down 8

      headers = ['Data/Hora', 'Usuário', 'IP', 'Entidade', 'ID', 'Ação', 'Mudanças']
      rows    = audits.map do |audit|
        [
          audit.created_at.in_time_zone('Brasilia').strftime('%d/%m/%Y %H:%M'),
          (audit.user&.name || '(sistema)').truncate(30),
          audit.remote_address.presence || '—',
          (ENTITY_LABELS[audit.auditable_type] || audit.auditable_type).truncate(20),
          audit.auditable_id.to_s,
          ACTION_LABELS[audit.action] || audit.action,
          format_changes(audit).truncate(50)
        ]
      end

      if rows.any?
        pdf.table([headers] + rows,
          header: true,
          cell_style: { size: 8, padding: [3, 4] },
          row_colors: ['FFFFFF', 'F5F5F5'],
          column_widths: [95, 100, 80, 110, 35, 65, 230]) do
          row(0).font_style = :bold
          row(0).background_color = '2C3E50'
          row(0).text_color = 'FFFFFF'
        end
      else
        pdf.text 'Nenhum registro encontrado para os filtros aplicados.', style: :italic
      end
    end.render
  end

  def ensure_admin_or_manager
    unless @current_user.admin? || @current_user.manager? || @current_user.additional?
      flash[:alert] = 'Acesso restrito.'
      redirect_to root_path
    end
  end
end
