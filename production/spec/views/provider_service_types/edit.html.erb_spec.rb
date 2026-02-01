require 'rails_helper'

RSpec.describe "provider_service_types/edit", type: :view do
  let(:provider_service_type) {
    ProviderServiceType.create!(
      name: "MyString",
      description: "MyText"
    )
  }

  before(:each) do
    assign(:provider_service_type, provider_service_type)
  end

  it "renders the edit provider_service_type form" do
    render

    assert_select "form[action=?][method=?]", provider_service_type_path(provider_service_type), "post" do

      assert_select "input[name=?]", "provider_service_type[name]"

      assert_select "textarea[name=?]", "provider_service_type[description]"
    end
  end
end
