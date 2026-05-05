require "rails_helper"

RSpec.describe "orientation_manuals/edit", type: :view do
  let(:orientation_manual) { create(:orientation_manual) }

  before(:each) do
    assign(:orientation_manual, orientation_manual)
  end

  it "renders the edit orientation_manual form" do
    expect { render }.not_to raise_error
  end
end
