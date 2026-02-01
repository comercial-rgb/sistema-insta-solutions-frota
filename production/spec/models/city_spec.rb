require 'rails_helper'

RSpec.describe City, type: :model do
	it 'has a valid factory' do
		expect(create :city).to be_valid
	end

	describe 'Validations' do
		it { should validate_presence_of :name }
		it { should validate_presence_of :state_id }
	end

	describe 'Relations' do
		it { should belong_to :state }
	end
end
