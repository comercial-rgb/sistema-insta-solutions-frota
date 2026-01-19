require 'rails_helper'

RSpec.describe "commitments/new", type: :view do
  before(:each) do
    assign(:commitment, Commitment.new(
      client: nil,
      cost_center: nil,
      contract: nil,
      commitment_number: "MyString",
      commitment_value: "9.99"
    ))
  end

  it "renders new commitment form" do
    render

    assert_select "form[action=?][method=?]", commitments_path, "post" do

      assert_select "input[name=?]", "commitment[client_id]"

      assert_select "input[name=?]", "commitment[cost_center_id]"

      assert_select "input[name=?]", "commitment[contract_id]"

      assert_select "input[name=?]", "commitment[commitment_number]"

      assert_select "input[name=?]", "commitment[commitment_value]"
    end
  end
end
