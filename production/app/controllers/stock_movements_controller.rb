class StockMovementsController < ApplicationController
  before_action :set_stock_movement, only: [:show]

  def index
    authorize StockMovement
    @stock_movements_grid = StockMovementsGrid.new(params[:stock_movements_grid]) do |scope|
      scope_for_user(scope).page(params[:page])
    end
    @stock_movements_grid.current_user = @current_user
    @stock_movements = @stock_movements_grid.assets

    respond_to do |format|
      format.html
      format.csv { send_data @stock_movements_grid.to_csv, filename: "movimentacoes_estoque_#{Date.today}.csv" }
    end
  end

  def show
    authorize @stock_movement
  end

  private

  def set_stock_movement
    @stock_movement = StockMovement.find(params[:id])
  end

  def scope_for_user(scope)
    if @current_user.admin?
      scope.joins(:stock_item)
    elsif @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id || @current_user.id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = @current_user.associated_sub_units.map(&:id)

      base = scope.joins(:stock_item).where(stock_items: { client_id: client_id })
      if cost_center_ids.any? || sub_unit_ids.any?
        conditions = []
        conditions << "stock_items.cost_center_id IN (#{cost_center_ids.join(',')})" if cost_center_ids.any?
        conditions << "stock_items.sub_unit_id IN (#{sub_unit_ids.join(',')})" if sub_unit_ids.any?
        base.where(conditions.join(' OR '))
      else
        base
      end
    else
      scope.none
    end
  end
end
