class VehicleChecklistPolicy < ApplicationPolicy
  def show?
    !user.nil?
  end

  def acknowledge?
    user.admin? || user.manager? || user.additional?
  end

  def create_os?
    acknowledge?
  end
end
