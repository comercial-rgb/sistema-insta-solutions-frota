require 'rails_helper'

RSpec.describe State, type: :model do
	it 'has a valid factory' do
		expect(create :state).to be_valid
	end

	describe 'Validations' do
		it { should validate_presence_of(:name) }
		it { should validate_presence_of(:acronym) }
	end

	describe 'Relations' do
		it { should belong_to :country }
		it { should have_many :cities }
	end

end
