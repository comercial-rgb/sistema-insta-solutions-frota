require 'rails_helper'

RSpec.describe "commitments/index", type: :view do
  before(:each) do
    assign(:commitments, [
      Commitment.create!(
        client: nil,
        cost_center: nil,
        contract: nil,
        commitment_number: "Commitment Number",
        commitment_value: "9.99"
      ),
      Commitment.create!(
        client: nil,
        cost_center: nil,
        contract: nil,
        commitment_number: "Commitment Number",
        commitment_value: "9.99"
      )
    ])
  end

  it "renders a list of commitments" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Commitment Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
