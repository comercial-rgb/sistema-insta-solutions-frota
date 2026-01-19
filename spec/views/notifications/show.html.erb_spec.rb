require 'rails_helper'

RSpec.describe "notifications/show", type: :view do
  before(:each) do
    assign(:notification, Notification.create!(
      profile: nil,
      send_all: false,
      title: "Title",
      message: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
  end
end
