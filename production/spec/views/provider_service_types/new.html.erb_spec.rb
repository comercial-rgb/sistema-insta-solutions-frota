require "rails_helper"

RSpec.describe "provider_service_types/new", type: :view do
  before(:each) do
    assign(:provider_service_type, ProviderServiceType.new(name: "Name", description: "MyText"))
  end

  it "renders new provider_service_type form" do
    expect { render }.not_to raise_error
  end
end
