require "rails_helper"

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
    expect { render }.not_to raise_error
  end
end
