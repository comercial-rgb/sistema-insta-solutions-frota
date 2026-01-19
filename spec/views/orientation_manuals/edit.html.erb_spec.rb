require 'rails_helper'

RSpec.describe "orientation_manuals/edit", type: :view do
  let(:orientation_manual) {
    OrientationManual.create!(
      name: "MyString",
      description: "MyText"
    )
  }

  before(:each) do
    assign(:orientation_manual, orientation_manual)
  end

  it "renders the edit orientation_manual form" do
    render

    assert_select "form[action=?][method=?]", orientation_manual_path(orientation_manual), "post" do

      assert_select "input[name=?]", "orientation_manual[name]"

      assert_select "textarea[name=?]", "orientation_manual[description]"
    end
  end
end
