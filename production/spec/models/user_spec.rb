require "rails_helper"

RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(create(:user)).to be_valid
  end

  describe "Validations" do
    it { should have_secure_password }
    it { should validate_presence_of(:name) }

    it "validates email format when not seed" do
      user = build(:user, email: "not-an-email", seed: false)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end
  end

  describe "Relations" do
    it { should belong_to(:profile).optional }
    it { should have_one(:address) }
  end
end
