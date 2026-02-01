require 'rails_helper'

RSpec.describe "orientation_manuals/new", type: :view do
  before(:each) do
    assign(:orientation_manual, OrientationManual.new(
      name: "MyString",
      description: "MyText"
    ))
  end

  it "renders new orientation_manual form" do
    render

    assert_select "form[action=?][method=?]", orientation_manuals_path, "post" do

      assert_select "input[name=?]", "orientation_manual[name]"

      assert_select "textarea[name=?]", "orientation_manual[description]"
    end
  end
end
