class Notification < ApplicationRecord
  acts_as_readable on: :created_at
  after_initialize :default_values

  # display_type: 0 = sino (bell), 1 = popup, 2 = ambos (popup + sino)
  DISPLAY_BELL  = 0
  DISPLAY_POPUP = 1
  DISPLAY_BOTH  = 2

  DISPLAY_TYPES = {
    DISPLAY_BELL  => 'Sino de notificações',
    DISPLAY_POPUP => 'Pop-up na tela',
    DISPLAY_BOTH  => 'Pop-up + Sino'
  }.freeze

  default_scope {
    left_outer_joins(:profile)
    .order(created_at: :desc)
  }

  scope :by_id, lambda { |value| where("notifications.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_profile_id, lambda { |value| where("notifications.profile_id = ?", value) if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("notifications.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("notifications.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  scope :is_to_my_profile, lambda {
    |value| where("notifications.profile_id = ? OR notifications.profile_id IS NULL", value) if !value.nil? && !value.blank?
  }

  scope :by_state_id, lambda { |value| where("notifications.state_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_city_id, lambda { |value| where("notifications.city_id = ?", value) if !value.nil? && !value.blank? }
  scope :important, -> { where(is_important: true) }
  scope :popup, -> { where(display_type: [DISPLAY_POPUP, DISPLAY_BOTH]) }
  scope :bell, -> { where(display_type: [DISPLAY_BELL, DISPLAY_BOTH]) }

  scope :is_to_me, lambda { |profile_id, user_id, user_state_id = nil, user_city_id = nil|
    if profile_id.present? && user_id.present?
      to_my_profile_scope = left_outer_joins(:users).is_to_my_profile(profile_id)

      result = to_my_profile_scope.where("users.id IN (?)", user_id)
                        .or(to_my_profile_scope.where(send_all: 1))

      if user_state_id.present?
        result = result.where("notifications.state_id IS NULL OR notifications.state_id = ?", user_state_id)
      else
        result = result.where(state_id: nil)
      end

      if user_city_id.present?
        result = result.where("notifications.city_id IS NULL OR notifications.city_id = ?", user_city_id)
      else
        result = result.where(city_id: nil)
      end

      result
    else
      none
    end
  }

  # scope :is_to_me, lambda {
  #   |profile_id, user_id|
  #     left_outer_joins(:users)
  #     .is_to_my_profile(profile_id)
  #     .where("users.id IN (?)", user_id)
  #     .or(
  #       is_to_my_profile(profile_id)
  #       .where(send_all: 1)
  #       ) if (!user_id.nil? && !user_id.blank? && !profile_id.nil? && !profile_id.blank?)
  # }

  belongs_to :profile, optional: true
  belongs_to :state, optional: true
  belongs_to :city, optional: true

  has_and_belongs_to_many :users, dependent: :destroy, validate: false
  has_many :notification_acknowledgments, dependent: :destroy

  validates_presence_of :title, :message

  def get_text_name
    self.title.to_s
  end

  def getting_profile_text
    result = I18n.t("model.select_all")
    if !self.profile.nil?
      result = self.profile.name
    end
    return result
  end

  def self.getting_current_unread(current_user)
    Notification.is_to_me(current_user.profile_id, current_user.id, current_user.effective_state_id, current_user.effective_city_id)
      .unread_by(current_user)
      .unscope(:limit, :offset)
      .count
  end

  def self.important_unread_for(current_user)
    Notification.is_to_me(current_user.profile_id, current_user.id, current_user.effective_state_id, current_user.effective_city_id)
    .important
    .unread_by(current_user)
    .unscope(:limit, :offset)
  end

  # Notificações popup não reconhecidas pelo usuário
  def self.popup_unread_for(current_user)
    Notification.is_to_me(current_user.profile_id, current_user.id, current_user.effective_state_id, current_user.effective_city_id)
    .popup
    .where.not(id: NotificationAcknowledgment.where(user_id: current_user.id).select(:notification_id))
    .unscope(:limit, :offset)
  end

  def acknowledged_by?(user)
    notification_acknowledgments.exists?(user_id: user.id)
  end

  def acknowledge!(user)
    notification_acknowledgments.find_or_create_by!(user_id: user.id) do |ack|
      ack.acknowledged_at = Time.current
    end
  end

  def get_users
    result = I18n.t("model.select_all")
    if !self.profile.nil? && !self.send_all
      result = self.users.map(&:name).join(", ")
    end
    return result
  end

  def getting_state_text
    self.state.present? ? self.state.name : I18n.t("model.select_all")
  end

  def getting_city_text
    self.city.present? ? self.city.name : I18n.t("model.select_all")
  end

  private

  def default_values
    self.title ||= ""
    self.message ||= ""
  end

end
