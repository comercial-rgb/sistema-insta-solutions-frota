class SupportTicketsController < ApplicationController
  before_action :set_support_ticket, only: [:show, :update_status, :add_message]

  def index
    authorize SupportTicket

    if params[:support_tickets_grid].nil? || params[:support_tickets_grid].blank?
      @support_tickets = SupportTicketsGrid.new(current_user: @current_user)
      @support_tickets_to_export = SupportTicketsGrid.new(current_user: @current_user)
    else
      @support_tickets = SupportTicketsGrid.new(params[:support_tickets_grid].merge(current_user: @current_user))
      @support_tickets_to_export = SupportTicketsGrid.new(params[:support_tickets_grid].merge(current_user: @current_user))
    end

    # Não-admin vê apenas seus próprios chamados
    if !@current_user.admin?
      @support_tickets.scope { |scope| scope.where(user_id: @current_user.id).page(params[:page]) }
      @support_tickets_to_export.scope { |scope| scope.where(user_id: @current_user.id) }
    else
      @support_tickets.scope { |scope| scope.page(params[:page]) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @support_tickets_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: "Chamados - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize SupportTicket
    @support_ticket = SupportTicket.new
    @support_ticket.attachments.build
  end

  def create
    authorize SupportTicket
    @support_ticket = SupportTicket.new(support_ticket_params)
    @support_ticket.user = @current_user

    if @support_ticket.save
      # Salvar imagens anexadas
      if params[:support_ticket][:images].present?
        params[:support_ticket][:images].each do |image|
          attachment = @support_ticket.attachments.build
          attachment.attachment.attach(image)
          attachment.save
        end
      end
      flash[:success] = t('flash.create')
      redirect_to support_tickets_path
    else
      flash[:error] = @support_ticket.errors.full_messages.join('<br>')
      @support_ticket.attachments.build if @support_ticket.attachments.empty?
      render :new
    end
  end

  def show
    authorize @support_ticket
    @message = SupportTicketMessage.new
    @message.attachments.build
  end

  def add_message
    authorize @support_ticket
    @message = @support_ticket.support_ticket_messages.build(message_params)
    @message.user = @current_user

    if @message.save
      # Salvar imagens anexadas à mensagem
      if params[:support_ticket_message][:images].present?
        params[:support_ticket_message][:images].each do |image|
          attachment = @message.attachments.build
          attachment.attachment.attach(image)
          attachment.save
        end
      end
      # Se admin respondeu e o chamado está aberto, mover para "em andamento"
      if @current_user.admin? && @support_ticket.status == SupportTicket::STATUS_ABERTO
        @support_ticket.update(status: SupportTicket::STATUS_EM_ANDAMENTO)
      end
      flash[:success] = "Mensagem adicionada com sucesso."
    else
      flash[:error] = @message.errors.full_messages.join('<br>')
    end
    redirect_to support_ticket_path(@support_ticket)
  end

  def update_status
    authorize @support_ticket, :update_status?
    new_status = params[:status].to_i

    update_attrs = { status: new_status }

    if new_status == SupportTicket::STATUS_RESOLVIDO
      update_attrs[:resolved_by_id] = @current_user.id
      update_attrs[:resolved_at] = Time.current
    elsif new_status == SupportTicket::STATUS_ABERTO
      update_attrs[:resolved_by_id] = nil
      update_attrs[:resolved_at] = nil
    end

    if @support_ticket.update(update_attrs)
      status_name = SupportTicket::STATUSES.find { |name, val| val == new_status }&.first
      flash[:success] = "Chamado atualizado para: #{status_name}"
    else
      flash[:error] = @support_ticket.errors.full_messages.join('<br>')
    end
    redirect_to support_ticket_path(@support_ticket)
  end

  private

  def set_support_ticket
    @support_ticket = SupportTicket.find(params[:id])
  end

  def support_ticket_params
    params.require(:support_ticket).permit(:title, :description, :ticket_type, :criticality)
  end

  def message_params
    params.require(:support_ticket_message).permit(:message)
  end
end
