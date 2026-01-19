require "rails_helper"

RSpec.describe OrderServicesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/order_services").to route_to("order_services#index")
    end

    it "routes to #new" do
      expect(get: "/order_services/new").to route_to("order_services#new")
    end

    it "routes to #show" do
      expect(get: "/order_services/1").to route_to("order_services#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/order_services/1/edit").to route_to("order_services#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/order_services").to route_to("order_services#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/order_services/1").to route_to("order_services#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/order_services/1").to route_to("order_services#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/order_services/1").to route_to("order_services#destroy", id: "1")
    end
  end
end
