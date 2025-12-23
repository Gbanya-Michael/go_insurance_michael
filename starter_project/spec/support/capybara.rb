# frozen_string_literal: true

require 'capybara/rails'
require 'capybara/rspec'

# Configure Capybara for system tests
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Increase wait time for slower operations
Capybara.default_max_wait_time = 5

# Configure Selenium
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end



