# frozen_string_literal: true

DEFAULT_SPEC_PASSWORD = "TestPass123!"

RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    next if example.metadata[:skip_sign_in]

    user = FactoryBot.create(
      :user,
      password: DEFAULT_SPEC_PASSWORD,
      password_confirmation: DEFAULT_SPEC_PASSWORD
    )
    post sessions_url, params: { email: user.email, password: DEFAULT_SPEC_PASSWORD }
  end

  config.before(:each, type: :view) do
    user = FactoryBot.create(
      :user,
      password: DEFAULT_SPEC_PASSWORD,
      password_confirmation: DEFAULT_SPEC_PASSWORD
    )
    assign(:current_user, user)
    assign(:system_configuration, SystemConfiguration.first || SystemConfiguration.create!)

    # View specs have no controller Pundit wiring; templates call policy(record).<predicate>
    view.define_singleton_method(:policy) do |_record|
      @__spec_policy_stub ||= Object.new.tap do |o|
        o.define_singleton_method(:method_missing) { |_name, *_args, &_blk| true }
        o.define_singleton_method(:respond_to_missing?) { |*_args| true }
      end
    end
  end
end
