require "rails_helper"

RSpec.describe "provider_service_types/edit", type: :view do
  let(:provider_service_type) { create(:provider_service_type) }

  before(:each) do
    assign(:provider_service_type, provider_service_type)
  end

  it "renders the edit provider_service_type form" do
    expect { render }.not_to raise_error
  end
end
