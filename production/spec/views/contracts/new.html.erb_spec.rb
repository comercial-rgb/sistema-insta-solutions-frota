require 'rails_helper'

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
    render

    assert_select "form[action=?][method=?]", contracts_path, "post" do

      assert_select "input[name=?]", "contract[client_id]"

      assert_select "input[name=?]", "contract[name]"

      assert_select "input[name=?]", "contract[number]"

      assert_select "input[name=?]", "contract[total_value]"

      assert_select "input[name=?]", "contract[active]"
    end
  end
end
