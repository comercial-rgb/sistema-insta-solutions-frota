require "rails_helper"

RSpec.describe OrientationManualsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/orientation_manuals").to route_to("orientation_manuals#index")
    end

    it "routes to #new" do
      expect(get: "/orientation_manuals/new").to route_to("orientation_manuals#new")
    end

    it "routes to #show" do
      expect(get: "/orientation_manuals/1").to route_to("orientation_manuals#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/orientation_manuals/1/edit").to route_to("orientation_manuals#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/orientation_manuals").to route_to("orientation_manuals#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/orientation_manuals/1").to route_to("orientation_manuals#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/orientation_manuals/1").to route_to("orientation_manuals#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/orientation_manuals/1").to route_to("orientation_manuals#destroy", id: "1")
    end
  end
end
