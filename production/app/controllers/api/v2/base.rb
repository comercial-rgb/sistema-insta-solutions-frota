module Api
  module V2
    class Base < Grape::API
      prefix 'api'
      version 'v2', using: :path
      format :json

      mount Api::V2::Dashboard
      mount Api::V2::Vehicles
      mount Api::V2::OrderServices
      mount Api::V2::KmRecords
      mount Api::V2::Anomalies
      mount Api::V2::Balances
      mount Api::V2::MaintenanceAlerts
      mount Api::V2::MaintenancePlans
      mount Api::V2::MobileNotifications
      mount Api::V2::QrNfcServices
      mount Api::V2::AdminUsers
      mount Api::V2::Contact
      mount Api::V2::VehicleChecklists
      mount Api::V2::TrafficViolationsEndpoint
      mount Api::V2::MobileBanners
    end
  end
end
