require 'rails_helper'

RSpec.describe Attachment, type: :model do
	it 'has a valid factory' do
		expect(create :attachment).to be_valid
	end

	describe 'Relations' do
		it { should belong_to :attachmentable }
	end
end
