require "rails_helper"

RSpec.describe OrderServiceProposalsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/order_service_proposals").to route_to("order_service_proposals#index")
    end

    it "routes to #new" do
      expect(get: "/order_service_proposals/new").to route_to("order_service_proposals#new")
    end

    it "routes to #show" do
      expect(get: "/order_service_proposals/1").to route_to("order_service_proposals#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/order_service_proposals/1/edit").to route_to("order_service_proposals#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/order_service_proposals").to route_to("order_service_proposals#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/order_service_proposals/1").to route_to("order_service_proposals#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/order_service_proposals/1").to route_to("order_service_proposals#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/order_service_proposals/1").to route_to("order_service_proposals#destroy", id: "1")
    end
  end
end
