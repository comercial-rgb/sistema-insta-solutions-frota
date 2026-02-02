class AddendumCommitmentsController < ApplicationController
  before_action :set_commitment
  before_action :set_addendum_commitment, only: [:destroy]
  
  def new
    @addendum_commitment = @commitment.addendum_commitments.build
    
    # Calcular valor disponível no controller
    if @commitment.contract.present?
      @contract_available_value = @commitment.contract.get_disponible_value(@commitment.id)
    end
    
    authorize @commitment, :edit?
  end

  def create
    @addendum_commitment = @commitment.addendum_commitments.build(addendum_commitment_params)
    authorize @commitment, :edit?
    
    if @addendum_commitment.save
      flash[:success] = "Aditivo adicionado com sucesso!"
      redirect_to commitment_path(@commitment)
    else
      render :new
    end
  end

  def destroy
    authorize @commitment, :edit?
    
    if @addendum_commitment.can_delete?
      @addendum_commitment.destroy
      flash[:success] = "Aditivo excluído com sucesso!"
    else
      flash[:error] = @addendum_commitment.reason_cannot_delete
    end
    
    redirect_to commitment_path(@commitment)
  end

  private

  def set_commitment
    @commitment = Commitment.includes(:addendum_commitments, contract: :addendum_contracts).find(params[:commitment_id])
  end

  def set_addendum_commitment
    @addendum_commitment = @commitment.addendum_commitments.find(params[:id])
  end

  def addendum_commitment_params
    params.require(:addendum_commitment).permit(:number, :description, :total_value, :active, :contract_id)
  end
end
