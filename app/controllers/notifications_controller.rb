class NotificationsController < ApplicationController
  before_action :set_notification, only: [:show, :edit, :update, :destroy, :get_notification]

  def index
    authorize Notification

    if params[:notifications_grid].nil? || params[:notifications_grid].blank?
      @notifications = NotificationsGrid.new(:current_user => @current_user)
      @notifications_to_export = NotificationsGrid.new(:current_user => @current_user)
    else
      @notifications = NotificationsGrid.new(params[:notifications_grid].merge(current_user: @current_user))
      @notifications_to_export = NotificationsGrid.new(params[:notifications_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @notifications.scope {|scope| scope.page(params[:page]) }
    else
      @notifications.scope {|scope| scope.is_to_me(@current_user.profile_id, @current_user.id).page(params[:page]) }
      @notifications_to_export.scope {|scope| scope.is_to_me(@current_user.profile_id, @current_user.id) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @notifications_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: Notification.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize Notification
    @notification = Notification.new
    build_initial_relations
  end

  def edit
    authorize @notification
    build_initial_relations
  end

  def create
    authorize Notification
    @notification = Notification.new(notification_params)
    if @notification.save
      flash[:success] = t('flash.create')
      redirect_to notifications_path
    else
      flash[:error] = @notification.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @notification
    @notification.update(notification_params)
    if @notification.valid?
      flash[:success] = t('flash.update')
      redirect_to notifications_path
    else
      flash[:error] = @notification.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @notification
    if @notification.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @notification.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @notification.relations.select{ |item| item[:id].nil? }.length == 0
    #  @notification.relations.build
    # end
    # @notification.build_relation if @notification.relation.nil?
  end

  def get_notification
    data = {
      result: @notification
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def check_all_read_notifications
    authorize Notification
    if current_user.key_account?
      notifications = Notification.to_key_account_or_general(current_user.id).unread_by(current_user)
    elsif current_user.auth_key_account? || current_user.by_key_account?
      notifications = Notification.to_key_account_or_general(current_user.key_account_id).unread_by(current_user)
    else
      notifications = Notification.to_general.unread_by(current_user)
    end
    notifications.each do |notification|
      notification.mark_as_read! :for => @current_user
      read_mark = notification.read_marks.select{|item| item.reader_id == @current_user.id}.last
      if read_mark
        read_mark.update_columns(timestamp: DateTime.now)
        read = true
      end
    end
    flash[:success] = Notification.human_attribute_name(:success_read_all)
    redirect_back(fallback_location: :back)
  end

  def manage_read_notification
    result = true
    read = false
    message = ""
    notification = Notification.where(id: params[:id]).first
    if notification
      if notification.read_marks.select{|item| item.reader_id == @current_user.id}.length == 0
        notification.mark_as_read! :for => @current_user
        read_mark = notification.read_marks.select{|item| item.reader_id == @current_user.id}.last
        if read_mark
          read_mark.update_columns(timestamp: DateTime.now)
          read = true
        end
      else
        notification.read_marks.where(reader_id: @current_user.id).destroy_all
        read = false
      end
    else
      message = "Falha ao atualizar. Tente novamente"
    end
    quantity = Notification.getting_current_unread(@current_user)
    data = {
      result: result,
      read: read,
      message: message,
      quantity: quantity
    }
    # Encaminha a resposta
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_notification
    @notification = Notification.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def notification_params
    params.require(:notification).permit(:id,
    :profile_id,
    :send_all,
    :title,
    :message,
    user_ids: []
    )
  end
end
