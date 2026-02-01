require 'rails_helper'

RSpec.describe Address, type: :model do
	it 'has a valid factory' do
		expect(create :address).to be_valid
	end

	describe 'Validations' do 
		it { should validate_presence_of :city_id }
		it { should validate_presence_of :state_id }
		it { should validate_presence_of :zipcode }
		it { should validate_presence_of :address }
		it { should validate_presence_of :district }
		it { should validate_presence_of :number }
	end

	describe 'Relations' do
		it { should belong_to :addresstable }
		it { should belong_to :state }
		it { should belong_to :city }
	end
end
