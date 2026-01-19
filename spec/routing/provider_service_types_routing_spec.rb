require "rails_helper"

RSpec.describe ProviderServiceTypesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/provider_service_types").to route_to("provider_service_types#index")
    end

    it "routes to #new" do
      expect(get: "/provider_service_types/new").to route_to("provider_service_types#new")
    end

    it "routes to #show" do
      expect(get: "/provider_service_types/1").to route_to("provider_service_types#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/provider_service_types/1/edit").to route_to("provider_service_types#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/provider_service_types").to route_to("provider_service_types#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/provider_service_types/1").to route_to("provider_service_types#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/provider_service_types/1").to route_to("provider_service_types#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/provider_service_types/1").to route_to("provider_service_types#destroy", id: "1")
    end
  end
end
