require 'rails_helper'

RSpec.describe "orientation_manuals/show", type: :view do
  before(:each) do
    assign(:orientation_manual, OrientationManual.create!(
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
