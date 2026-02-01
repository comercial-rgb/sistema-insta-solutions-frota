require 'rails_helper'

RSpec.describe "notifications/edit", type: :view do
  let(:notification) {
    Notification.create!(
      profile: nil,
      send_all: false,
      title: "MyString",
      message: "MyText"
    )
  }

  before(:each) do
    assign(:notification, notification)
  end

  it "renders the edit notification form" do
    render

    assert_select "form[action=?][method=?]", notification_path(notification), "post" do

      assert_select "input[name=?]", "notification[profile_id]"

      assert_select "input[name=?]", "notification[send_all]"

      assert_select "input[name=?]", "notification[title]"

      assert_select "textarea[name=?]", "notification[message]"
    end
  end
end
