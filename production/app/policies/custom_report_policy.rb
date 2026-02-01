class CustomReportPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager? || user.additional?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        # Admin vê todos os dados
        scope.all
      elsif user.manager? || user.additional?
        # Gestor e Adicional veem apenas dados do seu cliente
        scope.where(client_id: user.client_id)
      else
        # Outros usuários não têm acesso
        scope.none
      end
    end
  end
end
