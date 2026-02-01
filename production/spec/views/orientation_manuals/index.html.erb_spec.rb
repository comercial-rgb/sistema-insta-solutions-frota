require 'rails_helper'

RSpec.describe "orientation_manuals/index", type: :view do
  before(:each) do
    assign(:orientation_manuals, [
      OrientationManual.create!(
        name: "Name",
        description: "MyText"
      ),
      OrientationManual.create!(
        name: "Name",
        description: "MyText"
      )
    ])
  end

  it "renders a list of orientation_manuals" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
