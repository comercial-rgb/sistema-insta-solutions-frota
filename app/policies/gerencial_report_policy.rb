class GerencialReportPolicy < ApplicationPolicy
  def index?
    user.admin? || user.gerente?
  end
end
