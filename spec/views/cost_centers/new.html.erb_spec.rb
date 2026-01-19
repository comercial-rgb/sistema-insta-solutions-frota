require 'rails_helper'

RSpec.describe "cost_centers/new", type: :view do
  before(:each) do
    assign(:cost_center, CostCenter.new(
      client: nil,
      name: "MyString",
      contract_number: "MyString",
      commitment_number: "MyString",
      initial_consumed_balance: "9.99",
      description: "MyText",
      budget_value: "9.99",
      budget_type: nil,
      has_sub_units: false
    ))
  end

  it "renders new cost_center form" do
    render

    assert_select "form[action=?][method=?]", cost_centers_path, "post" do

      assert_select "input[name=?]", "cost_center[client_id]"

      assert_select "input[name=?]", "cost_center[name]"

      assert_select "input[name=?]", "cost_center[contract_number]"

      assert_select "input[name=?]", "cost_center[commitment_number]"

      assert_select "input[name=?]", "cost_center[initial_consumed_balance]"

      assert_select "textarea[name=?]", "cost_center[description]"

      assert_select "input[name=?]", "cost_center[budget_value]"

      assert_select "input[name=?]", "cost_center[budget_type_id]"

      assert_select "input[name=?]", "cost_center[has_sub_units]"
    end
  end
end
