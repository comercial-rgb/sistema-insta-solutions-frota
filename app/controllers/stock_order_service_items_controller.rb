class StockOrderServiceItemsController < ApplicationController
  def destroy
    @item = StockOrderServiceItem.find(params[:id])
    authorize @item.order_service, :update?, policy_class: OrderServicePolicy

    @item.destroy
    respond_to do |format|
      format.html { redirect_back(fallback_location: order_service_path(@item.order_service), notice: 'Peça removida da OS e devolvida ao estoque.') }
      format.json { head :no_content }
      format.js { head :no_content }
    end
  end
end
