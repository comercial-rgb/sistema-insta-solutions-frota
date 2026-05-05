require "rails_helper"

RSpec.describe "notifications/edit", type: :view do
  let(:notification) { create(:notification, title: "Title", message: "MyText") }

  before(:each) do
    assign(:notification, notification)
  end

  it "renders the edit notification form" do
    expect { render }.not_to raise_error
  end
end
