require 'rails_helper'

RSpec.describe Profile, type: :model do
	it 'has a valid factory' do
		expect(create :profile).to be_valid
	end

	describe 'Validations' do
		it { should validate_presence_of :name }
	end

	describe 'Relations' do 
		it { should have_many :users }
	end
end
