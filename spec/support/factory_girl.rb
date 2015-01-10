# FactoryGirl

RSpec.configure do |config|
  # Mix-in methods
  config.include FactoryGirl::Syntax::Methods

  # Validate all factory definitions
  config.before(:suite) do
    begin
      #DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      #DatabaseCleaner.clean
    end
  end

end