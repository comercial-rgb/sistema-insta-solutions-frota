require "rails_helper"

RSpec.describe "contracts/new", type: :view do
  before(:each) do
    assign(:contract, Contract.new(
      client: nil,
      name: "MyString",
      number: "MyString",
      total_value: "9.99",
      active: false
    ))
  end

  it "renders new contract form" do
    expect { render }.not_to raise_error
  end
end
