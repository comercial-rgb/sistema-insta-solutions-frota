require "rails_helper"

RSpec.describe "commitments/edit", type: :view do
  let(:commitment) { create(:commitment, commitment_number: "MyString", commitment_value: 9.99) }

  before(:each) do
    assign(:commitment, commitment)
    assign(:total_consumed, 0)
    assign(:remaining_value, 9.99)
    assign(:commitment_breakdown, {})
  end

  it "renders the edit commitment form" do
    expect { render }.not_to raise_error
  end
end
