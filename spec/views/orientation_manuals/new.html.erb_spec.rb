require "rails_helper"

RSpec.describe "orientation_manuals/new", type: :view do
  before(:each) do
    assign(:orientation_manual, OrientationManual.new(name: "MyString", description: "MyText"))
  end

  it "renders new orientation_manual form" do
    expect { render }.not_to raise_error
  end
end
