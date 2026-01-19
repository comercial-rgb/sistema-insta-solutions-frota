require 'rails_helper'

RSpec.describe "notifications/new", type: :view do
  before(:each) do
    assign(:notification, Notification.new(
      profile: nil,
      send_all: false,
      title: "MyString",
      message: "MyText"
    ))
  end

  it "renders new notification form" do
    render

    assert_select "form[action=?][method=?]", notifications_path, "post" do

      assert_select "input[name=?]", "notification[profile_id]"

      assert_select "input[name=?]", "notification[send_all]"

      assert_select "input[name=?]", "notification[title]"

      assert_select "textarea[name=?]", "notification[message]"
    end
  end
end
