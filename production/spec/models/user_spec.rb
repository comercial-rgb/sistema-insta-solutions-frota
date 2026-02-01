require 'rails_helper'

RSpec.describe User, type: :model do
	it 'has a valid factory' do
		expect(create :user).to be_valid
	end

	describe 'Validations' do
		it { should have_secure_password }
		it { should validate_presence_of :name }
		it { should validate_email_format_of(:email).with_message('inválido') }
	end

	describe 'Relations' do
		it { should belong_to :profile }
		it { should have_many :phones }
		it { should have_one :address }
	end
end
