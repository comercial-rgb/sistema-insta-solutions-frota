class PricingManualsController < ApplicationController

  def index
    authorize :pricing_manual, :index?

    if @current_user.provider?
      default_tab = "precificacao"
    else
      default_tab = "manutencao"
    end

    @active_tab = params[:tab].presence || default_tab
    @is_admin = @current_user.admin?
    @is_provider = @current_user.provider?
  end
end
