require "rails_helper"

RSpec.describe "contracts/edit", type: :view do
  let(:contract) { create(:contract, name: "MyString", number: "NUM", total_value: 9.99, active: false) }

  before(:each) do
    assign(:contract, contract)
  end

  it "renders the edit contract form" do
    expect { render }.not_to raise_error
  end
end
