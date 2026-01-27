# DatabaseCleaner configuration - DISABLED
# The database_cleaner gem is not included in the Gemfile.
# Uncomment the gem in Gemfile and this code when needed for testing.
#
# RSpec.configure do |config|
#   config.before(:suite) do
#     DatabaseCleaner.clean_with(:truncation)
#   end
#
#   config.before(:each) do
#     DatabaseCleaner.strategy = :transaction
#   end
#
#   config.before(:each, :js => true) do
#     DatabaseCleaner.strategy = :truncation
#   end
#
#   config.before(:each) do
#     DatabaseCleaner.start
#   end
#
#   config.append_after(:each) do
#     DatabaseCleaner.clean
#   end
# end
