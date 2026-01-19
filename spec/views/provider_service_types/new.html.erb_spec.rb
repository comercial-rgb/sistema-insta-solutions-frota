require 'rails_helper'

RSpec.describe "provider_service_types/new", type: :view do
  before(:each) do
    assign(:provider_service_type, ProviderServiceType.new(
      name: "MyString",
      description: "MyText"
    ))
  end

  it "renders new provider_service_type form" do
    render

    assert_select "form[action=?][method=?]", provider_service_types_path, "post" do

      assert_select "input[name=?]", "provider_service_type[name]"

      assert_select "textarea[name=?]", "provider_service_type[description]"
    end
  end
end
