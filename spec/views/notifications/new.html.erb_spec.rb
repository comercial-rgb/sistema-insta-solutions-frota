require "rails_helper"

RSpec.describe "notifications/new", type: :view do
  before(:each) do
    assign(:notification, Notification.new(send_all: false, title: "Title", message: "MyText"))
  end

  it "renders new notification form" do
    expect { render }.not_to raise_error
  end
end
