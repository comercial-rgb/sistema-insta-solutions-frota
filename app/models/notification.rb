class Notification < ApplicationRecord
  acts_as_readable on: :created_at
  after_initialize :default_values

  default_scope {
    left_outer_joins(:profile)
    .order(created_at: :desc)
  }

  scope :by_id, lambda { |value| where("notifications.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_profile_id, lambda { |value| where("notifications.profile_id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(notifications.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("notifications.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("notifications.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  scope :is_to_my_profile, lambda {
    |value| where("notifications.profile_id = ? OR notifications.profile_id IS NULL", value) if !value.nil? && !value.blank?
  }

  scope :is_to_me, lambda { |profile_id, user_id|
    if profile_id.present? && user_id.present?
      to_my_profile_scope = left_outer_joins(:users).is_to_my_profile(profile_id)

      to_my_profile_scope.where("users.id IN (?)", user_id)
                        .or(to_my_profile_scope.where(send_all: 1))
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

  has_and_belongs_to_many :users, dependent: :destroy, validate: false

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
    result = Notification.is_to_me(current_user.profile_id, current_user.id)
    .unread_by(current_user)
    .unscope(:limit, :offset)
    .length
    return result
  end

  def get_users
    result = I18n.t("model.select_all")
    if !self.profile.nil? && !self.send_all
      result = self.users.map(&:name).join(", ")
    end
    return result
  end

  private

  def default_values
    self.title ||= ""
    self.message ||= ""
  end

end
