require "rails_helper"

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
    expect { render }.not_to raise_error
  end
end
