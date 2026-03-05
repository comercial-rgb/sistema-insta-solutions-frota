class OrderServiceProposalsController < ApplicationController
  before_action :set_order_service_proposal, only: [
    :show, :edit, :update, :destroy, :get_order_service_proposal,
    :show_order_service_proposal,
    :approve_order_service_proposal,
    :reprove_order_service_proposal,
    :refuse_additional_approval,
    :autorize_order_service_proposal,
    :waiting_payment_order_service_proposal,
    :paid_order_service_proposal,
    :cancel_order_service_proposal,
    :get_new_proposals_order_service_proposal
  ]

  def index
    authorize OrderServiceProposal

    if params[:order_service_proposals_grid].nil? || params[:order_service_proposals_grid].blank?
      @order_service_proposals = OrderServiceProposalsGrid.new(:current_user => @current_user)
      @order_service_proposals_to_export = OrderServiceProposalsGrid.new(:current_user => @current_user)
    else
      @order_service_proposals = OrderServiceProposalsGrid.new(params[:order_service_proposals_grid].merge(current_user: @current_user))
      @order_service_proposals_to_export = OrderServiceProposalsGrid.new(params[:order_service_proposals_grid].merge(current_user: @current_user))
    end

    if @current_user.provider?
      @order_service_proposals.scope {|scope| scope.where(provider_id: @current_user.id).page(params[:page]) }
      @order_service_proposals_to_export.scope {|scope| scope.where(provider_id: @current_user.id) }
    else
      @order_service_proposals.scope {|scope| scope.page(params[:page]) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @order_service_proposals_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: OrderServiceProposal.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def show_order_service_proposals
    authorize OrderServiceProposal
    if (params[:order_service_proposal_status_id].nil? || params[:order_service_proposal_status_id].blank? || params[:order_service_proposal_status_id].to_i == OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID)
      user_not_authorized
      return
    end

    @order_service_proposal_status = OrderServiceProposalStatus.where(id: params[:order_service_proposal_status_id]).first
    if params[:order_service_proposals_grid].nil? || params[:order_service_proposals_grid].blank?
      @order_service_proposals = OrderServiceProposalsGrid.new(:current_user => @current_user)
      @order_service_proposals_to_export = OrderServiceProposalsGrid.new(:current_user => @current_user)
    else
      @order_service_proposals = OrderServiceProposalsGrid.new(params[:order_service_proposals_grid].merge(current_user: @current_user))
      @order_service_proposals_to_export = OrderServiceProposalsGrid.new(params[:order_service_proposals_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @order_service_proposals.scope {|scope| scope.by_order_service_proposal_status_id(params[:order_service_proposal_status_id]).page(params[:page]) }
      @order_service_proposals_to_export.scope {|scope| scope.by_order_service_proposal_status_id(params[:order_service_proposal_status_id]) }
    elsif @current_user.manager? || @current_user.additional?
      @order_service_proposals.scope {|scope| scope.by_client_id(@current_user.client_id).by_order_service_proposal_status_id(params[:order_service_proposal_status_id]).page(params[:page]) }
      @order_service_proposals_to_export.scope {|scope| scope.by_client_id(@current_user.client_id).by_order_service_proposal_status_id(params[:order_service_proposal_status_id]) }
    elsif @current_user.provider?
      status_id = params[:order_service_proposal_status_id].to_i

      # Para fornecedor: o status "Aguardando Aprovação de Complemento" deve listar a proposta PAI aprovada
      # (não-complemento) cuja OS tem um complemento pendente.
      if status_id == OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
        pending_order_service_ids = OrderServiceProposal
          .unscoped
          .where(
            is_complement: true,
            provider_id: @current_user.id,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          )
          .select(:order_service_id)

        @order_service_proposals.scope do |scope|
          scope
            .by_provider_id(@current_user.id)
            .by_order_service_proposal_status_id(OrderServiceProposalStatus::APROVADA_ID)
            .where(order_service_id: pending_order_service_ids)
            .page(params[:page])
        end
        @order_service_proposals_to_export.scope do |scope|
          scope
            .by_provider_id(@current_user.id)
            .by_order_service_proposal_status_id(OrderServiceProposalStatus::APROVADA_ID)
            .where(order_service_id: pending_order_service_ids)
        end
      else
        # Evita que OS com complemento pendente apareçam também em "Aprovada"
        pending_order_service_ids = OrderServiceProposal
          .unscoped
          .where(
            is_complement: true,
            provider_id: @current_user.id,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          )
          .select(:order_service_id)

        @order_service_proposals.scope do |scope|
          relation = scope.by_provider_id(@current_user.id)
          if status_id == OrderServiceProposalStatus::APROVADA_ID
            relation = relation.where.not(order_service_id: pending_order_service_ids)
          end
          relation.by_order_service_proposal_status_id(status_id).page(params[:page])
        end
        @order_service_proposals_to_export.scope do |scope|
          relation = scope.by_provider_id(@current_user.id)
          if status_id == OrderServiceProposalStatus::APROVADA_ID
            relation = relation.where.not(order_service_id: pending_order_service_ids)
          end
          relation.by_order_service_proposal_status_id(status_id)
        end
      end
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @order_service_proposals_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: OrderServiceProposal.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def show_order_service_proposals_by_order_service
    @order_service = OrderService.where(id: params[:order_service_id]).first
    if policy(@order_service).show_order_service_proposals_by_order_service?
      define_data_show_and_print
    else
      user_not_authorized
    end
  end

  def print_order_service_proposals_by_order_service
    @order_service = OrderService.where(id: params[:order_service_id]).first
    if policy(@order_service).print_order_service_proposals_by_order_service?
      define_data_show_and_print
    else
      user_not_authorized
    end
  end

  def define_data_show_and_print
    if params[:order_service_proposals_list_grid].nil? || params[:order_service_proposals_list_grid].blank?
      @order_service_proposals = OrderServiceProposalsListGrid.new(:current_user => @current_user)
      @order_service_proposals_to_export = OrderServiceProposalsListGrid.new(:current_user => @current_user)
    else
      @order_service_proposals = OrderServiceProposalsListGrid.new(params[:order_service_proposals_list_grid].merge(current_user: @current_user))
      @order_service_proposals_to_export = OrderServiceProposalsListGrid.new(params[:order_service_proposals_list_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @order_service_proposals.scope {|scope| scope.where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID).by_order_service_id(params[:order_service_id]).page(params[:page]) }
      @order_service_proposals_to_export.scope {|scope| scope.where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID).by_order_service_id(params[:order_service_id]) }
    elsif @current_user.manager?
      client_id = @current_user.client_id
      @order_service_proposals.scope {|scope| scope.where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID).by_client_id(client_id).by_order_service_id(params[:order_service_id]).page(params[:page]) }
      @order_service_proposals_to_export.scope {|scope| scope.where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID).by_client_id(client_id).by_order_service_id(params[:order_service_id]) }
    elsif @current_user.additional?
      client_id = @current_user.client_id
      @order_service_proposals.scope {|scope| scope.where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID).by_client_id(client_id).by_order_service_id(params[:order_service_id]).page(params[:page]) }
      @order_service_proposals_to_export.scope {|scope| scope.where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID).by_client_id(client_id).by_order_service_id(params[:order_service_id]) }
    end
    @order_service_proposals.order_service = @order_service
    @order_service_proposals_to_export.order_service = @order_service

    provider_ids = @order_service_proposals_to_export.assets.map(&:provider_id)
    all_providers = User.provider.where(id: [provider_ids]).map {|c| [c.get_name, c.id] }
    @order_service_proposals.providers = all_providers
    respond_to do |format|
      format.html
      format.csv do
        send_data @order_service_proposals_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: OrderServiceProposal.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize OrderServiceProposal
    
    # Validar order_service_id
    if params[:order_service_id].blank?
      flash[:error] = "ID da Ordem de Serviço não informado."
      redirect_to order_services_path and return
    end
    
    @order_service_proposal = OrderServiceProposal
    .where(order_service_id: params[:order_service_id])
    .where(provider_id: @current_user.id, order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
    .first
    if @order_service_proposal
      redirect_to edit_order_service_proposal_path(id: @order_service_proposal.id)
    else
      # Buscar OS com tratamento de erro
      begin
        os = OrderService.find(params[:order_service_id])
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Ordem de Serviço não encontrada."
        redirect_to order_services_path and return
      end
      
      @order_service_proposal = OrderServiceProposal.new
      @order_service_proposal.order_service_id = params[:order_service_id]
      @order_service_proposal.provider_id = @current_user.id
      
      # 📊 Debug: verificar part_service_order_services da OS
      Rails.logger.info "🔍 [PROPOSTA NEW DEBUG] OS ID: #{os.id}"
      Rails.logger.info "🔍 [PROPOSTA NEW DEBUG] Total part_service_order_services: #{os.part_service_order_services.count}"
      os.part_service_order_services.each_with_index do |ps, idx|
        Rails.logger.info "  [#{idx}] ID=#{ps.id}, service_id=#{ps.service_id}, service_name=#{ps.service&.name}, category_id=#{ps.service&.category_id}"
      end
      
      # Carregar limites do grupo de serviços (para Requisição)
      @service_max_values = {}
      if os.order_service_type_id == OrderServiceType::REQUISICAO_ID && os.service_group_id.present?
        os.service_group.service_group_items.each do |item|
          @service_max_values[item.service_id] = item.max_value
        end
      end
      
      # Carregar sugestões do catálogo de peças para o veículo da OS
      load_catalogo_sugestoes(os.vehicle)
      
      build_initial_relations
    end
  end

  def edit
    authorize @order_service_proposal
    
    # Carregar limites do grupo de serviços (para Requisição)
    @service_max_values = {}
    os = @order_service_proposal.order_service
    if os.order_service_type_id == OrderServiceType::REQUISICAO_ID && os.service_group_id.present?
      os.service_group.service_group_items.each do |item|
        @service_max_values[item.service_id] = item.max_value
      end
    end
    
    # Carregar sugestões do catálogo de peças para o veículo da OS
    load_catalogo_sugestoes(os.vehicle)
    
    build_initial_relations
  end

  def create
    authorize OrderServiceProposal
    
    # Limpar service_id="novo" antes de criar o objeto
    cleaned_params = clean_provider_service_temps_params(order_service_proposal_params)
    @order_service_proposal = OrderServiceProposal.new(cleaned_params)
    @order_service_proposal.provider_id = @current_user.id
    
    if !params[:save_and_submit].present?
      @order_service_proposal.skip_validation = true
    end

    if @order_service_proposal.save
      Rails.logger.info "✅ [CREATE DEBUG] Provider Service Temps após save: #{@order_service_proposal.provider_service_temps.count}"
      
      save_files
      if params[:save_and_submit].present?
        generate_order_service_proposal_items
        @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)
        if @order_service_proposal.order_service.order_service_status_id != OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID
          OrderService.generate_historic(@order_service_proposal.order_service, @current_user, @order_service_proposal.order_service.order_service_status_id, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
          @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID, updated_at: Time.current)
        end
        @order_service_proposal.audit_creation(@current_user)
        flash[:success] = t('flash.create')
      else
        @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
        flash[:success] = OrderServiceProposal.human_attribute_name(:proposal_initialized_with_success)
      end
      OrderServiceProposal.update_total_values(@order_service_proposal)
      if params[:save_and_submit].present?
        redirect_to show_order_service_proposal_path(id: @order_service_proposal.id)
      else
        redirect_to edit_order_service_proposal_path(id: @order_service_proposal.id)
      end
    else
      flash[:error] = @order_service_proposal.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    if @order_service_proposal.order_service_proposal_status_id == OrderServiceProposalStatus::APROVADA_ID
      # Se estive tentando apenas inserir as notas fiscais
      if !policy(@order_service_proposal).can_insert_invoices?
        user_not_authorized
        return
      end
    else
      # Se está atualizando a proposta em si
      authorize @order_service_proposal
    end

    # ⚙️ Define se deve validar ou não (submeter ou apenas salvar rascunho)
    @order_service_proposal.skip_validation = !params[:save_and_submit].present?

    # 🔧 Limpar service_id="novo" antes de atribuir parâmetros
    cleaned_params = clean_provider_service_temps_params(order_service_proposal_params)
    
    # 🧠 Atribui os parâmetros incluindo nested attributes
    @order_service_proposal.assign_attributes(cleaned_params)

    # 🔄 Garante que os filhos tenham a referência correta para acessar `skip_validation`
    @order_service_proposal.provider_service_temps.each do |pst|
      pst.order_service_proposal = @order_service_proposal
    end

    # � Log para debug - quantos provider_service_temps antes do save
    Rails.logger.info "🔍 [DEBUG] Provider Service Temps antes do save: #{@order_service_proposal.provider_service_temps.count}"
    Rails.logger.info "🔍 [DEBUG] Provider Service Temps detalhes: #{@order_service_proposal.provider_service_temps.map { |pst| { id: pst.id, service_id: pst.service_id, name: pst.name, price: pst.price } }}"

    # �🔍 Validação forçada para debug
    proposal_valid = @order_service_proposal.valid? && @order_service_proposal.provider_service_temps.all?(&:valid?)

    if proposal_valid && @order_service_proposal.save      # 📊 Log após save bem-sucedido
      Rails.logger.info "✅ [DEBUG] Provider Service Temps após save: #{@order_service_proposal.provider_service_temps.reload.count}"
            save_files

      if params[:save_and_submit].present?
        # Gerar itens da proposta para submissão
        generate_order_service_proposal_items
        @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)

        if @order_service_proposal.order_service.order_service_status_id != OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID
          OrderService.generate_historic(
            @order_service_proposal.order_service,
            @current_user,
            @order_service_proposal.order_service.order_service_status_id,
            OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID
          )
          @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID, updated_at: Time.current)
        end

        @order_service_proposal.audit_creation(@current_user)
        flash[:success] = t('flash.update')
        OrderServiceProposal.update_total_values(@order_service_proposal)
        redirect_to show_order_service_proposal_path(id: @order_service_proposal.id)
      elsif params[:just_save].present?
        flash[:success] = t('flash.update')
        OrderServiceProposal.update_total_values(@order_service_proposal)
        redirect_to edit_order_service_proposal_path(id: @order_service_proposal.id)
      else
        # Transição de status ao inserir NF: APROVADA → NOTA_FISCAL_INSERIDA
        # Aplica para TODOS os usuários (admin, gestor, fornecedor)
        if @order_service_proposal.order_service.order_service_status_id == OrderServiceStatus::APROVADA_ID
          @order_service_proposal.audits.create!(
            user: @current_user,
            action: 'update',
            audited_changes: {
              "order_service_proposal_status" => ["Aguardando inserção de notas fiscais", 'Notas fiscais inseridas'],
              "order_service_proposal_status_id" => [OrderServiceProposalStatus::APROVADA_ID, OrderServiceProposalStatus::NOTAS_INSERIDAS_ID]
            }
          )
          OrderService.generate_historic(
            @order_service_proposal.order_service,
            @current_user,
            @order_service_proposal.order_service.order_service_status_id,
            OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID
          )
          @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID, updated_at: Time.current)
          # Atualizar também o status da proposta para refletir no menu do fornecedor
          @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::NOTAS_INSERIDAS_ID)
        end
        flash[:success] = t('flash.update')
        redirect_to show_order_service_proposal_path(id: @order_service_proposal.id)
      end

    else
      flash[:error] = (
        @order_service_proposal.errors.full_messages +
        @order_service_proposal.provider_service_temps.flat_map { |pst| pst.errors.full_messages }
      ).uniq.join('<br>')

      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @order_service_proposal
    if @order_service_proposal.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @order_service_proposal.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def save_files
    if !order_service_proposal_params[:files].nil?
      order_service_proposal_params[:files].each do |picture|
        @order_service_proposal.attachments.create(:attachment => picture)
      end
    end
  end

  def generate_order_service_proposal_items
    proposal_id = @order_service_proposal.id
    temps_count = @order_service_proposal.provider_service_temps.count

    Rails.logger.info "[GENERATE_ITEMS] Proposta #{proposal_id}: Iniciando geração de #{temps_count} itens"

    ActiveRecord::Base.transaction do
      @order_service_proposal.order_service_proposal_items.destroy_all

      @order_service_proposal.provider_service_temps.reload.each do |provider_service_temp|
        new_service = provider_service_temp.service

        # Para itens criados manualmente (sem service_id), usa os dados do provider_service_temp
        if new_service.present?
          service_id = new_service.id
          service_name = new_service.name
        else
          service_id = nil
          service_name = provider_service_temp.name
        end

        item = @order_service_proposal.order_service_proposal_items.create!(
          service_id: service_id,
          unity_value: provider_service_temp.price,
          service_name: service_name,
          quantity: provider_service_temp.quantity,
          discount: provider_service_temp.discount,
          total_value: provider_service_temp.total_value,
          total_value_without_discount: (provider_service_temp.quantity * provider_service_temp.price),
          brand: provider_service_temp.brand,
          warranty_period: provider_service_temp.warranty_period,
          referencia_catalogo: provider_service_temp.referencia_catalogo
        )
        Rails.logger.info "[GENERATE_ITEMS] Proposta #{proposal_id}: Item #{item.id} criado (service_id=#{service_id}, valor=#{provider_service_temp.price}, qty=#{provider_service_temp.quantity})"
      end
    end

    # Verificação pós-geração
    items_count = @order_service_proposal.order_service_proposal_items.reload.count
    if items_count != temps_count
      Rails.logger.error "[GENERATE_ITEMS] ⚠️ MISMATCH Proposta #{proposal_id}: #{temps_count} temps vs #{items_count} items criados!"
    else
      Rails.logger.info "[GENERATE_ITEMS] ✅ Proposta #{proposal_id}: #{items_count} itens gerados com sucesso"
    end
  end

  def build_initial_relations
    # if @order_service_proposal.relations.select{ |item| item[:id].nil? }.length == 0
    #  @order_service_proposal.relations.build
    # end
    # @order_service_proposal.build_relation if @order_service_proposal.relation.nil?
    # if @order_service_proposal.order_service_proposal_items.select{ |item| item[:id].nil? }.length == 0
    #   @order_service_proposal.order_service_proposal_items.build
    # end
    # if @order_service_proposal.provider_service_temps.select{ |item| item[:id].nil? }.length == 0
    #   @order_service_proposal.provider_service_temps.build
    # end
  end

  def get_order_service_proposal
    authorize @order_service_proposal, :show_order_service_proposal?
    data = {
      result: @order_service_proposal
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def show_order_service_proposal
    authorize @order_service_proposal
    @order_service = @order_service_proposal.order_service
    
    # Buscar complementos relacionados a esta proposta
    @complement_proposals = OrderServiceProposal
      .where(parent_proposal_id: @order_service_proposal.id, is_complement: true)
      .includes(:order_service_proposal_items, :order_service_proposal_status, :provider)
      .order(created_at: :asc)

    # 🔧 Correção de legado: alguns complementos foram criados com desconto zerado.
    # Ajusta somente complementos ainda pendentes de aprovação (não consumiram saldo ainda).
    @complement_proposals.each do |complement|
      next unless complement.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID

      apply_client_discount_to_complement_provider_temps(complement)

      # Se os itens já foram gerados com desconto errado/zerado, regenere para refletir o desconto.
      if complement.order_service_proposal_items.any? && complement.provider_service_temps.any?
        complement.order_service_proposal_items.destroy_all
        convert_provider_temps_to_items(complement)
      end
    end
  end

  def approve_order_service_proposal
    authorize @order_service_proposal
    reason = params[:reason_approved].to_s.strip
    justification_required = @order_service_proposal.requires_approval_justification?

    if justification_required && reason.blank?
      flash[:error] = "É necessário justificar a aprovação para itens com preços acima da tabela de referência."
      return redirect_back(fallback_location: :back)
    end

    # ✅ Verificar saldo nos empenhos antes de aprovar (validação movida do update)
    order_service = @order_service_proposal.order_service
    
    # Calcula valores totais DA PROPOSTA COM DESCONTO APLICADO
    parts_value = @order_service_proposal.order_service_proposal_items
                    .joins(:service)
                    .where(services: { category_id: Category::SERVICOS_PECAS_ID })
                    .sum(:total_value)
    
    services_value = @order_service_proposal.order_service_proposal_items
                       .joins(:service)
                       .where(services: { category_id: Category::SERVICOS_SERVICOS_ID })
                       .sum(:total_value)
    
    balance_check = order_service.check_commitment_balance(parts_value, services_value)
    
    unless balance_check[:valid]
      flash[:error] = "Não é possível aprovar: #{balance_check[:message]}"
      return redirect_back(fallback_location: :back)
    end

    # Usuário ADICIONAL faz pré-aprovação
    if @current_user.additional?
      order_service = @order_service_proposal.order_service
      
      # Manually create an audit record
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)
      OrderService.generate_historic(order_service, @current_user, order_service.order_service_status_id, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
      
      @order_service_proposal.update_columns(
        order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID,
        approved_by_additional_id: @current_user.id,
        approved_by_additional_at: DateTime.now,
        pending_manager_approval: true,
        reason_approved: reason.presence
      )
      
      # Recarrega a OS diretamente do banco para evitar problemas com cache
      OrderService.where(id: order_service.id).update_all(order_service_status_id: OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
      
      flash[:success] = "Pré-aprovação realizada com sucesso. Aguardando aprovação do gestor."
    # Usuário GESTOR ou ADMIN faz aprovação final
    elsif @current_user.manager? || @current_user.admin?
      order_service = @order_service_proposal.order_service
      
      # 🔒 Aprovação final dentro de transaction com lock pessimista nos empenhos
      # Previne race conditions (duas aprovações simultâneas consumindo o mesmo saldo)
      approval_error = nil
      
      ActiveRecord::Base.transaction do
        # Re-verifica saldo com lock FOR UPDATE nos empenhos (garante atomicidade)
        locked_balance_check = order_service.check_commitment_balance_with_lock!(parts_value, services_value)
        unless locked_balance_check[:valid]
          approval_error = "Não é possível aprovar: #{locked_balance_check[:message]}"
          raise ActiveRecord::Rollback
        end

        # 🔒 Verificar se já existe outra proposta ativa (APROVADA ou posterior) nesta OS
        active_proposal_statuses = [
          OrderServiceProposalStatus::APROVADA_ID,
          OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
          OrderServiceProposalStatus::AUTORIZADA_ID,
          OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
          OrderServiceProposalStatus::PAGA_ID
        ]
        
        existing_active_proposals = order_service.order_service_proposals
          .not_complement
          .where(order_service_proposal_status_id: active_proposal_statuses)
          .where.not(id: @order_service_proposal.id)
        
        if existing_active_proposals.any?
          proposal_codes = existing_active_proposals.map(&:code).join(', ')
          approval_error = "Não é possível aprovar: já existe(m) proposta(s) ativa(s) nesta OS (#{proposal_codes}). Cancele ou reprove a proposta existente antes de aprovar uma nova."
          raise ActiveRecord::Rollback
        end
        
        # Reprovar propostas que estão em AGUARDANDO_AVALIACAO
        order_service_proposals = order_service.order_service_proposals
        .where(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)
        .where.not(id: @order_service_proposal.id)

        order_service_proposals.each do |order_service_proposal|
          OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID)
          order_service_proposal.update_columns(
            reproved: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
            reason_reproved: OrderServiceProposal.human_attribute_name(:another_proposal_approved)
            )
        end

        # Aprovar a proposta
        OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::APROVADA_ID)
        OrderService.generate_historic(order_service, @current_user, order_service.order_service_status_id, OrderServiceStatus::APROVADA_ID)

        @order_service_proposal.update_columns(
          order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID,
          pending_manager_approval: false,
          reason_approved: reason.presence
        )
      
        # Recarrega a OS diretamente do banco para evitar problemas com cache
        OrderService.where(id: order_service.id).update_all(order_service_status_id: OrderServiceStatus::APROVADA_ID)
      end # fim da transaction

      if approval_error
        flash[:error] = approval_error
        return redirect_back(fallback_location: :back)
      end

      flash[:success] = OrderServiceProposal.human_attribute_name(:approved_with_success)
    else
      flash[:error] = OrderServiceProposal.human_attribute_name(:approved_failed)
    end

    redirect_back(fallback_location: :back)
  end

  def reprove_order_service_proposal
    authorize @order_service_proposal
    if !params[:reason_reproved].nil? && !params[:reason_reproved].blank?
      order_service = @order_service_proposal.order_service
      
      # 🔧 CORREÇÃO REAVALIAÇÃO: Mudar status para EM_CADASTRO para permitir reedição
      # Isso permite que o fornecedor edite a proposta e reenvie
      OrderServiceProposal.generate_historic(
        @order_service_proposal, 
        @current_user, 
        @order_service_proposal.order_service_proposal_status_id, 
        OrderServiceProposalStatus::EM_CADASTRO_ID
      )
      
      @order_service_proposal.update_columns(
        order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID,
        reproved: true,
        reason_reproved: params[:reason_reproved]
      )
      
      # Atualizar status da OS apenas se não houver mais propostas aguardando avaliação
      if @order_service_proposal.order_service.order_service_proposals.select{|item| item.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID}.length == 0
        OrderService.generate_historic(@order_service_proposal.order_service, @current_user, @order_service_proposal.order_service.order_service_status_id, OrderServiceStatus::EM_ABERTO_ID)
        @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::EM_ABERTO_ID, updated_at: Time.current)
      end
      
      # Não enviar para outros fornecedores ao reprovar - apenas volta para o fornecedor original reeditar
      # sending_order_service_proposals_to_all_providers(order_service, @order_service_proposal)
      
      flash[:success] = OrderServiceProposal.human_attribute_name(:reproved_with_success)
    else
      flash[:error] = OrderServiceProposal.human_attribute_name(:reproved_failed)
    end
    redirect_back(fallback_location: :back)
  end

  def autorize_order_service_proposal
    authorize @order_service_proposal
    
    # Usuário ADICIONAL faz pré-autorização
    if @current_user.additional?
      # Manually create an audit record
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, @order_service_proposal.order_service_proposal_status_id)
      
      @order_service_proposal.update_columns(
        authorized_by_additional_id: @current_user.id,
        authorized_by_additional_at: DateTime.now,
        pending_manager_authorization: true
      )
      
      flash[:success] = "Pré-autorização realizada com sucesso. Aguardando autorização do gestor."
    # Usuário GESTOR ou ADMIN faz autorização final
    elsif @current_user.manager? || @current_user.admin?
      # Manually create an audit record
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::AUTORIZADA_ID)
      @order_service_proposal.update_columns(
        order_service_proposal_status_id: OrderServiceProposalStatus::AUTORIZADA_ID,
        pending_manager_authorization: false
      )

      # Manually create an audit record
      OrderService.generate_historic(@order_service_proposal.order_service, @current_user, @order_service_proposal.order_service.order_service_status_id, OrderServiceStatus::AUTORIZADA_ID)
      @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID, updated_at: Time.current)
      
      # Envia webhook para sistema financeiro (assíncrono com retry)
      SendAuthorizedOsWebhookJob.perform_later(@order_service_proposal.order_service.id)

      flash[:success] = OrderServiceProposal.human_attribute_name(:authorized_with_success)
    end

    redirect_back(fallback_location: :back)
  end

  def refuse_additional_approval
    authorize @order_service_proposal, :manager_refuse_additional_approval?
    if !params[:reason_refused].nil? && !params[:reason_refused].blank?
      additional_user = @order_service_proposal.approved_by_additional
      
      # Manually create an audit record
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)
      
      @order_service_proposal.update_columns(
        approved_by_additional_id: nil,
        approved_by_additional_at: nil,
        pending_manager_approval: false,
        reason_approved: nil,
        reason_refused_approval: params[:reason_refused],
        refused_by_manager_id: @current_user.id,
        refused_by_manager_at: DateTime.now
      )
      
      # Criar notificação para o usuário adicional
      if additional_user.present?
        notification = Notification.create(
          title: "Pré-aprovação recusada - Proposta #{@order_service_proposal.code}",
          message: "O gestor #{@current_user.name} recusou a pré-aprovação da proposta #{@order_service_proposal.code}. Motivo: #{params[:reason_refused]}",
          send_all: false
        )
        notification.users << additional_user
      end
      
      flash[:success] = "Pré-aprovação recusada com sucesso. O usuário adicional foi notificado."
    else
      flash[:error] = "É necessário informar o motivo da recusa."
    end
    redirect_back(fallback_location: :back)
  end

  def refuse_additional_authorization
    authorize @order_service_proposal, :manager_refuse_additional_authorization?
    if !params[:reason_refused].nil? && !params[:reason_refused].blank?
      # Manually create an audit record
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, @order_service_proposal.order_service_proposal_status_id)
      
      @order_service_proposal.update_columns(
        authorized_by_additional_id: nil,
        authorized_by_additional_at: nil,
        pending_manager_authorization: false
      )
      
      flash[:success] = "Pré-autorização recusada com sucesso."
    else
      flash[:error] = "É necessário informar o motivo da recusa."
    end
    redirect_back(fallback_location: :back)
  end

  def waiting_payment_order_service_proposal
    authorize @order_service_proposal
    # Manually create an audit record
    OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID)
    @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID)

    # Manually create an audit record
    OrderService.generate_historic(@order_service_proposal.order_service, @current_user, @order_service_proposal.order_service.order_service_status_id, OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID)
    @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID, updated_at: Time.current)

    flash[:success] = OrderServiceProposal.human_attribute_name(:waiting_payment_with_success)

    redirect_back(fallback_location: :back)
  end

  def paid_order_service_proposal
    authorize @order_service_proposal
    # Manually create an audit record
    OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, @order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::PAGA_ID)
    @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::PAGA_ID)

    # Manually create an audit record
    OrderService.generate_historic(@order_service_proposal.order_service, @current_user, @order_service_proposal.order_service.order_service_status_id, OrderServiceStatus::PAGA_ID)
    @order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::PAGA_ID, updated_at: Time.current)

    flash[:success] = OrderServiceProposal.human_attribute_name(:make_payment_with_success)

    redirect_back(fallback_location: :back)
  end

  def reprove_order_service_proposals
    authorize OrderServiceProposal
    result = true
    begin
      order_service = nil
      order_service_proposal_ids = params[:order_service_proposal_ids].split(",")
      all_order_service_proposals = OrderServiceProposal.where(id: [order_service_proposal_ids])
      all_order_service_proposals.each do |order_service_proposal|
        order_service = order_service_proposal.order_service if order_service.nil?
        OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID)
        order_service_proposal.update_columns(
          order_service_proposal_status_id: OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
          reproved: true,
          reason_reproved: params[:reprove_reason]
        )
        if order_service_proposal.order_service.order_service_proposals.select{|item| item.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID}.length == 0
          OrderService.generate_historic(order_service_proposal.order_service, @current_user, order_service_proposal.order_service.order_service_status_id, OrderServiceStatus::EM_ABERTO_ID)
          order_service_proposal.order_service.update_columns(order_service_status_id: OrderServiceStatus::EM_ABERTO_ID)
        end
      end
      # 🔧 CORREÇÃO BUG REAVALIAÇÃO: Para reprovar/reavaliar, pegamos a proposta do fornecedor original
      # Busca a proposta mais recente do fornecedor que possui itens salvos
      last_proposal = order_service.order_service_proposals
        .where(provider_id: order_service.provider_id)
        .joins(:order_service_proposal_items)
        .distinct
        .order(updated_at: :desc)
        .first
      
      # Se não encontrou proposta com itens, pega a mais recente independente de itens
      last_proposal ||= order_service.order_service_proposals
        .where(provider_id: order_service.provider_id)
        .order(updated_at: :desc)
        .first
      
      sending_order_service_proposals_to_all_providers(order_service, last_proposal)
      message = OrderServiceProposal.human_attribute_name(:all_reproved_with_success)
    rescue StandardError => e
      result = false
      message = e.message
    end
    data = {
      result: result,
      message: message
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def sending_order_service_proposals_to_all_providers(order_service, source_proposal = nil)
    if !order_service.nil? && order_service.order_service_type_id == OrderServiceType::DIAGNOSTICO_ID && !order_service.provider.nil?
      # ⚠️ CORREÇÃO: Usar a proposta passada como parâmetro (a proposta que está sendo enviada)
      # ao invés de buscar, pois pode haver múltiplas propostas e a busca pode pegar a errada
      current_proposal = source_proposal
      
      # 🔧 CORREÇÃO BUG REAVALIAÇÃO: Fallback aprimorado para buscar proposta mais recente
      # Busca propostas em AGUARDANDO_AVALIACAO ou EM_CADASTRO (reavaliação em andamento)
      # Prioriza propostas que já têm order_service_proposal_items salvos
      if current_proposal.nil?
        current_proposal = order_service.order_service_proposals
          .where(order_service_proposal_status_id: [
            OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID,
            OrderServiceProposalStatus::EM_CADASTRO_ID
          ])
          .where(provider_id: order_service.provider_id) # Apenas do fornecedor original
          .order(updated_at: :desc)
          .first
      end
      
      # Se encontrou a proposta com itens atualizados, copia para os part_service_order_services da OS
      if current_proposal.present?
        # Limpa os itens antigos da OS
        order_service.part_service_order_services.destroy_all
        
        # 🔧 CORREÇÃO BUG REAVALIAÇÃO: Copia os itens da proposta para a OS
        # Inclui itens da primeira proposta + itens adicionados/removidos na reavaliação
        # IMPORTANTE: Usar order_service_proposal_items (itens permanentes salvos após submit)
        # NÃO usar provider_service_temps (itens temporários do formulário)
        if current_proposal.order_service_proposal_items.any?
          current_proposal.order_service_proposal_items.each do |item|
            order_service.part_service_order_services.create!(
              service_id: item.service_id,
              observation: item.observation,
              quantity: item.quantity || 1
            )
          end
          Rails.logger.info "✅ [COTAÇÃO] #{order_service.part_service_order_services.count} itens copiados da proposta ##{current_proposal.id} para OS #{order_service.code} (incluindo reavaliações)"
        else
          Rails.logger.warn "⚠️ [COTAÇÃO] Proposta #{current_proposal.id} não possui order_service_proposal_items para copiar"
        end
      else
        Rails.logger.warn "⚠️ [COTAÇÃO] Nenhuma proposta encontrada para copiar itens para OS #{order_service.code}"
      end
      
      # Marca a origem da OS como vinda de um Diagnóstico para cotação
      # Atualizar apenas campos que existem em produção
      update_attrs = {
        provider_id: nil, 
        order_service_status_id: OrderServiceStatus::EM_ABERTO_ID
      }
      
      # Adicionar origin_type apenas se a coluna existir
      if order_service.class.column_names.include?('origin_type')
        update_attrs[:origin_type] = OrderService::ORIGIN_DIAGNOSTICO_COTACOES
      end
      
      order_service.update_columns(update_attrs)
    end
  end

  def cancel_order_service_proposal
    authorize @order_service_proposal
    old_status_id = @order_service_proposal.order_service_proposal_status_id
    @order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID)
    OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, old_status_id, OrderServiceProposalStatus::CANCELADA_ID)
    flash[:success] = OrderServiceProposal.human_attribute_name(:cancel_proposal_success)
    redirect_back(fallback_location: :back)
  end

  def get_new_proposals_order_service_proposal
    authorize @order_service_proposal
    
    begin
      # Validar que a proposta tem itens antes de enviar
      if @order_service_proposal.order_service_proposal_items.empty?
        flash[:error] = "A proposta não possui itens. Não é possível enviar para cotação."
        redirect_back(fallback_location: :back) and return
      end
      
      # ⚠️ CORREÇÃO: Passar a proposta atual (@order_service_proposal) para garantir que os itens corretos sejam copiados
      sending_order_service_proposals_to_all_providers(@order_service_proposal.order_service, @order_service_proposal)
      flash[:success] = OrderServiceProposal.human_attribute_name(:send_proposal_to_all_providers_success)
      redirect_back(fallback_location: :back)
    rescue => e
      Rails.logger.error "❌ [ENVIAR COTAÇÃO] Erro ao enviar para cotação: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:error] = "Erro ao enviar para cotação: #{e.message}"
      redirect_back(fallback_location: :back)
    end
  end
  
  # ============================================
  # Métodos de Complemento
  # ============================================
  
  # Formulário para criar complemento
  def new_complement
    @order_service = OrderService.find(params[:id])
    authorize @order_service, :add_complement?
    
    @parent_proposal = @order_service.approved_proposal
    @order_service_proposal = OrderServiceProposal.new(
      order_service_id: @order_service.id,
      provider_id: @parent_proposal.provider_id,
      parent_proposal_id: @parent_proposal.id,
      is_complement: true,
      order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID
    )
    
    # Inicializa provider_service_temps vazios para o formulário
    @order_service_proposal.provider_service_temps.build
  end
  
  # Criar complemento
  def create_complement
    @order_service = OrderService.find(params[:id])
    authorize @order_service, :add_complement?
    
    @parent_proposal = @order_service.approved_proposal
    @order_service_proposal = OrderServiceProposal.new(order_service_proposal_params)
    @order_service_proposal.order_service_id = @order_service.id
    @order_service_proposal.provider_id = @parent_proposal.provider_id
    @order_service_proposal.parent_proposal_id = @parent_proposal.id
    @order_service_proposal.is_complement = true
    @order_service_proposal.order_service_proposal_status_id = OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID

    # ✅ Garantir que o desconto do cliente seja aplicado e persistido no complemento
    apply_client_discount_to_complement_provider_temps(@order_service_proposal)
    
    if @order_service_proposal.save
      # Converter provider_service_temps em order_service_proposal_items
      convert_provider_temps_to_items(@order_service_proposal)
      
      # Verificar saldo e definir fluxo de aprovação
      check_complement_balance_and_approval(@order_service_proposal)
      
      # Mudar status da OS para indicar que há complemento pendente
      # (A OS fica "travada" em APROVADA até o complemento ser aprovado)
      # Na verdade, não mudamos o status da OS, apenas filtramos no grid
      
      flash[:success] = "Complemento criado com sucesso e enviado para aprovação."
      redirect_to order_service_path(@order_service)
    else
      flash.now[:error] = @order_service_proposal.errors.full_messages.join('<br>')
      render :new_complement
    end
  end
  
  # Aprovar complemento
  def approve_complement
    @order_service_proposal = OrderServiceProposal.find(params[:id])
    @order_service = @order_service_proposal.order_service
    authorize @order_service, :approve_complement?

    # ✅ Complementos antigos podem ter sido salvos com desconto zerado.
    # Reaplica antes de consumir saldo/mesclar itens.
    apply_client_discount_to_complement_provider_temps(@order_service_proposal)
    
    # Converter provider_service_temps para items se necessário
    if @order_service_proposal.order_service_proposal_items.empty? && @order_service_proposal.provider_service_temps.any?
      convert_provider_temps_to_items(@order_service_proposal)
    end
    
    if @order_service_proposal.is_complement
      # Verificar se precisa aprovação do gerente
      if @order_service_proposal.pending_manager_approval && !@current_user.manager?
        flash[:error] = "Este complemento requer aprovação do gerente."
        redirect_back(fallback_location: order_service_path(@order_service))
        return
      end

      # Validar saldo antes de aprovar/mesclar
      balance_check = consume_complement_balance(@order_service_proposal)
      unless balance_check[:valid]
        flash[:error] = balance_check[:message]
        redirect_back(fallback_location: order_service_path(@order_service))
        return
      end
      
      old_status = @order_service_proposal.order_service_proposal_status_id
      
      # Aprovar o complemento
      @order_service_proposal.update!(
        order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID,
        pending_manager_approval: false
      )
      
      # ✅ IMPORTANTE: Não cria nova OS - apenas copia itens para a proposta principal
      # Copiar itens do complemento para a proposta original (proposta PAI)
      # Os itens ficam todos na mesma OS, marcados com is_complement: true
      parent_proposal = @order_service_proposal.parent_proposal

      # Complementos antigos ou cenários de dados inconsistentes podem estar sem parent_proposal.
      # Neste caso, tentamos resolver pela proposta principal aprovada da OS.
      if parent_proposal.blank?
        parent_proposal = @order_service.approved_proposal
        if parent_proposal.present? && parent_proposal.id != @order_service_proposal.id
          @order_service_proposal.update_columns(parent_proposal_id: parent_proposal.id)
        end
      end

      if parent_proposal.blank? || parent_proposal.id == @order_service_proposal.id
        flash[:error] = "Não foi possível identificar a proposta principal para mesclar o complemento."
        redirect_back(fallback_location: order_service_path(@order_service))
        return
      end

      merge_complement_to_parent(@order_service_proposal, parent_proposal)
      
      # Recalcular totais da proposta pai após merge
      if parent_proposal
        OrderServiceProposal.update_total_values(parent_proposal)
        parent_proposal.reload
      end
      
      # ✅ OS permanece com status APROVADA - não cria nova OS
      # Atualizar status da OS para APROVADA após aprovar complemento
      # (OS volta para o status anterior ao complemento)
      @order_service.update!(order_service_status_id: OrderServiceStatus::APROVADA_ID)
      
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, old_status, OrderServiceProposalStatus::APROVADA_ID)
      flash[:success] = "Complemento aprovado e adicionado à OS. OS voltou para status Aprovada."
    else
      flash[:error] = "Esta proposta não é um complemento."
    end
    
    redirect_to order_service_path(@order_service)
  end
  
  # Reprovar complemento
  def reprove_complement
    @order_service_proposal = OrderServiceProposal.find(params[:id])
    @order_service = @order_service_proposal.order_service
    authorize @order_service, :approve_complement?
    
    if @order_service_proposal.is_complement
      old_status = @order_service_proposal.order_service_proposal_status_id
      @order_service_proposal.update!(
        order_service_proposal_status_id: OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        reason_reproved: params[:reason] || "Complemento reprovado"
      )
      OrderServiceProposal.generate_historic(@order_service_proposal, @current_user, old_status, OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID)
      flash[:success] = "Complemento reprovado."
    else
      flash[:error] = "Esta proposta não é um complemento."
    end
    
    redirect_to order_service_path(@order_service)
  end

  private
  # Aplica desconto do cliente e ajusta categoria_id nos provider_service_temps do complemento.
  # Faz update somente quando:
  # - é complemento
  # - existe desconto do cliente
  # - a proposta ainda está aguardando aprovação do complemento
  def apply_client_discount_to_complement_provider_temps(proposal)
    return unless proposal&.is_complement
    return unless proposal.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID

    discount_percent = proposal.order_service&.client&.discount_percent.to_d
    return if discount_percent <= 0

    proposal.provider_service_temps.each do |pst|
      quantity = pst.quantity.to_i
      unity_value = pst.price.to_d
      total_value_without_discount = (unity_value * quantity)
      next if total_value_without_discount <= 0

      discount_value = (total_value_without_discount * (discount_percent / 100)).round(2)
      total_value = (total_value_without_discount - discount_value).round(2)

      resolved_category_id = pst.service&.category_id || pst.category_id

      pst.discount = discount_value
      pst.total_value = total_value
      pst.category_id = resolved_category_id
    end
  end


  # Use callbacks to share common setup or constraints between actions.
  def set_order_service_proposal
    @order_service_proposal = OrderServiceProposal.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def order_service_proposal_params
    params.require(:order_service_proposal).permit(:id,
    :order_service_id,
    :details,
    :total_value,
    :total_discount,
    :total_value_without_discount,
    :justification,
    order_service_proposal_items_attributes: [
      :id, :order_service_proposal_id,
      :service_id,
      :quantity,
      :discount,
      :total_value,
      :discount_temp,
      :total_temp,
      :brand,
      :warranty_period,
      :is_complement
    ],
    provider_service_temps_attributes: [
      :id, :order_service_proposal_id,
      :name,
      :category_id,
      :description,
      :price,
      :code,
      :quantity,
      :discount,
      :total_value,
      :discount_temp,
      :total_temp,
      :category_id,
      :brand,
      :warranty_period,
      :service_id,
      :referencia_catalogo,
      :_destroy
    ],
    order_service_invoices_attributes: [
      :id, :order_service_proposal_id,
      :order_service_invoice_type_id,
      :number,
      :value,
      :emission_date,
      :file
    ],
    files: []
    )
  end
  
  # Limpa service_id="novo" dos parâmetros de provider_service_temps
  # Normaliza nomes usando o catálogo de peças quando disponível
  def clean_provider_service_temps_params(params)
    return params unless params[:provider_service_temps_attributes].present?
    
    cleaned_params = params.deep_dup
    cleaned_params[:provider_service_temps_attributes].each do |key, temp_attrs|
      if temp_attrs[:service_id].to_s == "novo"
        # 🔧 Criar Service para itens novos (modal "Criar novo item")
        # Isso garante que o item exista no banco e possa ser copiado para a OS na cotação
        service_name = temp_attrs[:name].to_s.strip
        category_id = temp_attrs[:category_id]

        # Tenta normalizar nome usando o catálogo de peças
        if category_id.to_i == Category::SERVICOS_PECAS_ID && service_name.present?
          service_name = normalizar_nome_pelo_catalogo(service_name)
        end

        # Padroniza capitalização (Title Case inteligente)
        service_name = Service.padronizar_nome_peca(service_name) if service_name.present?

        if service_name.present? && category_id.present?
          # Busca existente: case-insensitive + ignora acentos (após padronização, nomes são consistentes)
          existing_service = Service.where("LOWER(name) = ? AND category_id = ?", service_name.downcase, category_id).first
          # Se não encontrou exato, tenta sem acentos (dados legados podem não ter sido padronizados ainda)
          if existing_service.nil?
            nome_sem_acento = I18n.transliterate(service_name.downcase.strip)
            existing_service = Service.where(category_id: category_id)
              .where("LOWER(name) LIKE ?", nome_sem_acento)
              .first
          end
          service = existing_service || Service.create!(
            name: service_name,
            category_id: category_id,
            price: temp_attrs[:price],
            provider_id: @current_user&.id
          )
          temp_attrs[:service_id] = service.id
          temp_attrs[:name] = service.name

          # Auto-popular referência do catálogo se disponível
          if category_id.to_i == Category::SERVICOS_PECAS_ID && temp_attrs[:referencia_catalogo].blank?
            begin
              os = OrderServiceProposal.find_by(id: temp_attrs[:order_service_proposal_id])&.order_service ||
                   OrderService.find_by(id: params[:order_service_id])
              vehicle = os&.vehicle
              refs = CatalogoPeca.formatar_referencias(service_name, vehicle: vehicle)
              temp_attrs[:referencia_catalogo] = refs if refs.present?
            rescue => e
              Rails.logger.warn "[CATALOGO] Erro ao buscar referência: #{e.message}"
            end
          end
        else
          temp_attrs[:service_id] = nil
        end
      end
    end
    cleaned_params
  end

  # Normaliza nome da peça usando o catálogo PDF
  # Usa algoritmo inteligente com scoring por sobreposição de palavras
  def normalizar_nome_pelo_catalogo(nome)
    return nome if nome.blank?
    CatalogoPeca.normalizar_nome_inteligente(nome)
  rescue => e
    Rails.logger.warn "[CATALOGO] Erro ao normalizar nome '#{nome}': #{e.message}"
    nome
  end

  # Carrega sugestões do catálogo de peças para o veículo da OS
  def load_catalogo_sugestoes(vehicle)
    @catalogo_sugestoes = []
    @catalogo_fornecedores = []
    @catalogo_grupos = []
    @catalogo_referencias = {} # Hash: nome_peca => "FRASLE: PD/1234 | FREMAX: BD-5560"

    return unless vehicle.present?
    return unless CatalogoPeca.table_exists?

    begin
      @catalogo_sugestoes = CatalogoPeca.buscar_por_veiculo(vehicle).limit(200)
      @catalogo_fornecedores = CatalogoPeca.fornecedores_disponiveis
      @catalogo_grupos = CatalogoPeca.grupos_produto_disponiveis

      # Agrupa referências por grupo_produto para exibir no formulário
      @catalogo_sugestoes.each do |sug|
        grupo = sug.grupo_produto.to_s.strip
        next if grupo.blank?
        @catalogo_referencias[grupo] ||= []
        ref = { fornecedor: sug.fornecedor, produto: sug.produto }
        @catalogo_referencias[grupo] << ref unless @catalogo_referencias[grupo].include?(ref)
      end

      # Formata como strings "FORNECEDOR: CODIGO | ..."
      @catalogo_referencias.transform_values! do |refs|
        refs.map { |r| "#{r[:fornecedor]}: #{r[:produto]}" }.uniq.join(' | ')
      end
    rescue => e
      Rails.logger.warn "[CATALOGO] Erro ao carregar sugestões: #{e.message}"
    end
  end

  # Verifica saldo e define fluxo de aprovação para complemento
  def check_complement_balance_and_approval(complement_proposal)
    order_service = complement_proposal.order_service

    parts_total, services_total = get_complement_totals_by_category(complement_proposal)
    balance_check = order_service.check_commitment_balance(parts_total, services_total)

    if balance_check[:valid]
      complement_proposal.update!(pending_manager_approval: false) if complement_proposal.pending_manager_approval
      Rails.logger.info "[COMPLEMENTO] Saldo suficiente. Peças: #{parts_total}, Serviços: #{services_total}."
    else
      complement_proposal.update!(pending_manager_approval: true)
      Rails.logger.info "[COMPLEMENTO] Saldo insuficiente. Peças: #{parts_total}, Serviços: #{services_total}. Motivo: #{balance_check[:message]}"
    end
  end
  
  # Consome saldo do empenho para os itens do complemento
  def consume_complement_balance(complement_proposal)
    order_service = complement_proposal.order_service

    parts_total, services_total = get_complement_totals_by_category(complement_proposal)

    # Valida saldo com lock pessimista para evitar race conditions na aprovação de complementos
    order_service.check_commitment_balance_with_lock!(parts_total, services_total)
  end

  # Retorna [parts_total, services_total] do complemento.
  # Preferência:
  # 1) provider_service_temps (quando ainda existem)
  # 2) order_service_proposal_items (quando temps já foram convertidos/limpos)
  def get_complement_totals_by_category(complement_proposal)
    parts_total = 0.0
    services_total = 0.0

    if complement_proposal.provider_service_temps.any?
      parts_total = complement_proposal.provider_service_temps
        .select { |pst| pst.category_id == Category::SERVICOS_PECAS_ID }
        .sum { |pst| pst.total_value.to_f }

      services_total = complement_proposal.provider_service_temps
        .select { |pst| pst.category_id == Category::SERVICOS_SERVICOS_ID }
        .sum { |pst| pst.total_value.to_f }

      return [parts_total, services_total]
    end

    if complement_proposal.order_service_proposal_items.any?
      # Usa total_value (já com desconto) para bater com o que será incorporado na proposta pai
      parts_total = complement_proposal.order_service_proposal_items
        .joins(:service)
        .where(services: { category_id: Category::SERVICOS_PECAS_ID })
        .sum(:total_value)
        .to_f

      services_total = complement_proposal.order_service_proposal_items
        .joins(:service)
        .where(services: { category_id: Category::SERVICOS_SERVICOS_ID })
        .sum(:total_value)
        .to_f

      # Se não conseguiu classificar por categoria, mas existe valor, ainda assim não pode "passar" sem validar.
      total = complement_proposal.order_service_proposal_items.sum(:total_value).to_f
      if (parts_total + services_total) == 0.0 && total > 0
        if complement_proposal.order_service&.commitment_id.present?
          # Empenho global: valida pelo total (como serviços)
          services_total = total
        else
          # Empenhos separados: sem categoria, não dá para consumir corretamente
          return [0.0, 0.0]
        end
      end

      return [parts_total, services_total]
    end

    [0.0, 0.0]
  end
  
  # Mescla itens do complemento para a proposta original
  def merge_complement_to_parent(complement_proposal, parent_proposal = nil)
    parent_proposal ||= complement_proposal.parent_proposal
    return unless parent_proposal.present?
    
    # Copiar order_service_proposal_items do complemento para a proposta original
    # marcando as is_complement = true
    complement_proposal.order_service_proposal_items.each do |item|
      parent_proposal.order_service_proposal_items.create!(
        service_id: item.service_id,
        service_name: item.service_name,
        service_description: item.service_description,
        quantity: item.quantity,
        unity_value: item.unity_value,
        discount: item.discount,
        total_value: item.total_value,
        total_value_without_discount: item.total_value_without_discount,
        brand: item.brand,
        guarantee: item.guarantee,
        warranty_period: item.warranty_period,
        warranty_start_date: item.warranty_start_date,
        observation: item.observation,
        is_complement: true
      )
    end
    
    # Atualizar totais da proposta original
    OrderServiceProposal.update_total_values(parent_proposal)
    parent_proposal.reload
  end
  
  # Converter provider_service_temps em order_service_proposal_items
  def convert_provider_temps_to_items(proposal)
    client_discount_percent = proposal.order_service&.client&.discount_percent.to_d

    proposal.provider_service_temps.each do |pst|
      quantity = pst.quantity.to_i
      unity_value = pst.price.to_d
      total_value_without_discount = (unity_value * quantity)

      discount_value = (total_value_without_discount * (client_discount_percent / 100)).round(2)
      total_value = (total_value_without_discount - discount_value).round(2)

      # Garante que a categoria fique coerente com o Service selecionado.
      # Isso é essencial para consumir saldo corretamente (peças vs serviços).
      resolved_category_id = pst.service&.category_id || pst.category_id

      pst.update_columns(
        discount: discount_value,
        total_value: total_value,
        category_id: resolved_category_id
      )

      proposal.order_service_proposal_items.create!(
        service_id: pst.service_id,
        service_name: pst.service&.name || pst.name,
        service_description: pst.service&.description,
        quantity: quantity,
        unity_value: unity_value,
        discount: discount_value,
        total_value: total_value,
        total_value_without_discount: total_value_without_discount,
        brand: pst.brand,
        warranty_period: pst.warranty_period,
        guarantee: pst.warranty_period.to_s,
        observation: pst.description,
        is_complement: proposal.is_complement || false,
        referencia_catalogo: pst.referencia_catalogo
      )
    end
    
    # Atualizar totais
    OrderServiceProposal.update_total_values(proposal)
    proposal.reload
  end
end
