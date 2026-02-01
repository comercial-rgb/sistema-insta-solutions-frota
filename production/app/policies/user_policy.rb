class UserPolicy < ApplicationPolicy

  def users_admin?
    user.admin?
  end

  def users_user?
    user.admin?
  end

  def users_client?
    user.admin?
  end

  def users_manager?
    user.admin?
  end

  def users_additional?
    user.admin? || user.manager?
  end

  def users_provider?
    user.admin? || user.manager? || user.additional?
  end

  def validate_users?
    user.admin? && user.id == 1
  end

  def create?
    user.admin? || user.manager?
  end

  def new?
    create?
  end

  def update?
    !user.nil? && (user.admin? || (user.manager? && record.additional? && user.client_id == record.client_id)) || user.id == record.id
  end

  def edit?
    update?
  end

  def generate_contract?
    user.admin?
  end

  def change_data?
    update? && (record.provider.nil? || record.provider.blank?)
  end

  def reset_user_password?
    (change_data? && (user.admin? || (user.manager? && record.additional? && user.client_id == record.client_id))) && !record.client?
  end

  def update_access_data?
    update?
  end

  def block?
    !user.nil? && (user.admin? || (user.manager? && record.additional? && user.client_id == record.client_id)) && user.id != record.id && record.id != 2
  end

  def destroy?
    !user.nil? && (user.admin? || (user.manager? && record.additional? && user.client_id == record.client_id)) && user.id != record.id && record.id != 2
  end

  def open_chat?(sender_id)
    # return (user.id != record.id && sender_id.to_i == user.id)
    false
  end

  def destroy_profile_image?
    user.admin? || (user.user? && record.id == user.id)
  end

  def send_push_test?
    user.id == 1
  end

  def send_push_to_mobile?
    send_push_test?
  end

  def user_addresses?
    # (user.admin? || user.user?) && record.user?
    false
  end

  def new_user_address?
    create_user_address?
  end

  def create_user_address?
    user.admin? || user.user?
  end

  def update_user_address?(address)
    user.admin? || (user.user? && address.ownertable_type == "User" && address.ownertable_id == user.id)
  end

  def edit_user_address?(address)
    update_user_address?(address)
  end

  def destroy_user_address?(address)
    update_user_address?(address)
  end

  def user_cards?
    # (user.admin? || user.user?) && record.user?
    false
  end

  def create_user_card?
    user.admin? || user.user?
  end

  def update_user_card?
    user.admin? || (user.user? && record.ownertable_type == "User" && record.ownertable_id == user.id)
  end

  def destroy_user_card?
    update_user_card?
  end

  def destroy_attachment?
    !user.nil?
  end

  def can_select_plan?
    !user.nil? && user.admin? && !record.admin?
  end

  def approve_users?
    user.admin?
  end

  def disapprove_users?
    user.admin?
  end

  def sending_new_validation_mail?
    !record.nil? && !record.validated_mail
  end

  def validate_mail?
    sending_new_validation_mail?
  end

  def show_notifications_bell?
    !user.nil? && !user.admin?
  end

end
