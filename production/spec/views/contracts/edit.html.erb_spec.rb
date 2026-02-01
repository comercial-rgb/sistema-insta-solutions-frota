require 'rails_helper'

RSpec.describe "contracts/edit", type: :view do
  let(:contract) {
    Contract.create!(
      client: nil,
      name: "MyString",
      number: "MyString",
      total_value: "9.99",
      active: false
    )
  }

  before(:each) do
    assign(:contract, contract)
  end

  it "renders the edit contract form" do
    render

    assert_select "form[action=?][method=?]", contract_path(contract), "post" do

      assert_select "input[name=?]", "contract[client_id]"

      assert_select "input[name=?]", "contract[name]"

      assert_select "input[name=?]", "contract[number]"

      assert_select "input[name=?]", "contract[total_value]"

      assert_select "input[name=?]", "contract[active]"
    end
  end
end
