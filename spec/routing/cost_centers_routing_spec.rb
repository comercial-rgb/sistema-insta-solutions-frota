require "rails_helper"

RSpec.describe CostCentersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/cost_centers").to route_to("cost_centers#index")
    end

    it "routes to #new" do
      expect(get: "/cost_centers/new").to route_to("cost_centers#new")
    end

    it "routes to #show" do
      expect(get: "/cost_centers/1").to route_to("cost_centers#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/cost_centers/1/edit").to route_to("cost_centers#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/cost_centers").to route_to("cost_centers#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/cost_centers/1").to route_to("cost_centers#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/cost_centers/1").to route_to("cost_centers#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/cost_centers/1").to route_to("cost_centers#destroy", id: "1")
    end
  end
end
