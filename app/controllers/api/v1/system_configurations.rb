module Api  
  module V1
    class SystemConfigurations < Grape::API
      include Api::V1::Defaults

      resource :system_configurations do

        #GET /system_configurations
        get "" do
          SystemConfiguration.find_or_create_by(id: 1)
        end

      end  
    end
  end
end