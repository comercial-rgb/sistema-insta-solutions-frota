require 'rails_helper'

RSpec.describe "provider_service_types/show", type: :view do
  before(:each) do
    assign(:provider_service_type, ProviderServiceType.create!(
      name: "Name",
      description: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end
