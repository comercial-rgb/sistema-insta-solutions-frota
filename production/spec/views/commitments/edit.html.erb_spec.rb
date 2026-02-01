require 'rails_helper'

RSpec.describe "commitments/edit", type: :view do
  let(:commitment) {
    Commitment.create!(
      client: nil,
      cost_center: nil,
      contract: nil,
      commitment_number: "MyString",
      commitment_value: "9.99"
    )
  }

  before(:each) do
    assign(:commitment, commitment)
  end

  it "renders the edit commitment form" do
    render

    assert_select "form[action=?][method=?]", commitment_path(commitment), "post" do

      assert_select "input[name=?]", "commitment[client_id]"

      assert_select "input[name=?]", "commitment[cost_center_id]"

      assert_select "input[name=?]", "commitment[contract_id]"

      assert_select "input[name=?]", "commitment[commitment_number]"

      assert_select "input[name=?]", "commitment[commitment_value]"
    end
  end
end
