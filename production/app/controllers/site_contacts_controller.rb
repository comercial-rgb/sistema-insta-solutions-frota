class SiteContactsController < ApplicationController
  before_action :set_site_contact, only: [:show, :edit, :update, :destroy, :get_site_contact]

  def index
    authorize SiteContact

    if params[:site_contacts_grid].nil? || params[:site_contacts_grid].blank?
      @site_contacts = SiteContactsGrid.new(:current_user => @current_user)
      @site_contacts_to_export = SiteContactsGrid.new(:current_user => @current_user)
    else
      @site_contacts = SiteContactsGrid.new(params[:site_contacts_grid].merge(current_user: @current_user))
      @site_contacts_to_export = SiteContactsGrid.new(params[:site_contacts_grid].merge(current_user: @current_user))
    end

    @site_contacts.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @site_contacts_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: SiteContact.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize SiteContact
    @site_contact = SiteContact.new
    build_initial_relations
  end

  def edit
    authorize @site_contact
    build_initial_relations
  end

  def create
    authorize SiteContact
    @site_contact = SiteContact.new(site_contact_params)
    if @site_contact.save
      flash[:success] = t('flash.create')
      redirect_to site_contacts_path
    else
      flash[:error] = @site_contact.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @site_contact
    @site_contact.update(site_contact_params)
    if @site_contact.valid?
      flash[:success] = t('flash.update')
      redirect_to edit_site_contact_path(@site_contact)
    else
      flash[:error] = @site_contact.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @site_contact
    if @site_contact.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @site_contact.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
  end

  def get_site_contact
    data = {
      result: @site_contact
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_site_contact
    @site_contact = SiteContact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def site_contact_params
    params.require(:site_contact).permit(:id, 
    :site_contact_subject_id,
    :name,
    :email,
    :phone,
    :message,
    :user_id,
    )
  end
end
