module Api
  module V2
    class MobileNotifications < Grape::API
      resource :notifications do
        before { authenticate! }

        desc 'Lista notificações do usuário'
        params do
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
          optional :unread_only, type: Boolean, default: false
        end
        get do
          user = current_user

          scope = Notification.is_to_me(
            user.profile_id, user.id, user.state_id, user.city_id
          )

          if params[:unread_only]
            scope = scope.unread_by(user)
          end

          notifications = scope.order(created_at: :desc)
                               .page(params[:page]).per(params[:per_page])

          unread_count = Notification.is_to_me(
            user.profile_id, user.id, user.state_id, user.city_id
          ).unread_by(user).count

          {
            notifications: notifications.map { |n| serialize_notification(n, user) },
            unread_count: unread_count,
            meta: {
              current_page: notifications.current_page,
              total_pages: notifications.total_pages,
              total_count: notifications.total_count
            }
          }
        end

        desc 'Marcar notificação como lida'
        put ':id/read' do
          user = current_user
          notification = Notification.find(params[:id])
          notification.mark_as_read!(for: user)

          { message: 'Notificação marcada como lida' }
        end

        desc 'Marcar todas como lidas'
        put 'read_all' do
          user = current_user
          notifications = Notification.is_to_me(
            user.profile_id, user.id, user.state_id, user.city_id
          ).unread_by(user)

          notifications.each { |n| n.mark_as_read!(for: user) }

          { message: 'Todas notificações marcadas como lidas' }
        end
      end

      helpers do
        def serialize_notification(n, user)
          {
            id: n.id,
            title: n.title,
            message: n.message,
            is_important: n.is_important,
            read: n.read_by?(user),
            created_at: n.created_at
          }
        end
      end
    end
  end
end
