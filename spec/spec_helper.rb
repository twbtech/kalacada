require 'rubygems'
require 'minitest/autorun'
require 'spork'
require 'shoulda-matchers'
require 'spec_support'
require 'capybara/poltergeist'
require 'simplecov'

ENV['RAILS_ENV'] = 'test'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  unless ENV['DRB']
    SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter]
    SimpleCov.start 'rails'
  end

  require 'factory_girl_rails'
  require File.expand_path('../../config/environment', __FILE__)
  require 'rspec/rails'

  RSpec.configure do |config|
    config.before do |example|
      if example.metadata[:js]
        DatabaseCleaner.strategy = :deletion
        DatabaseCleaner.clean
        page.driver.browser.manage.window.resize_to(1800, 900) if ENV['USE_SELENIUM'] == '1'
        perform_logout
        sleep 3
      else
        DatabaseCleaner.strategy = :transaction
      end

      DatabaseCleaner.start

      I18n.default_locale = :en

      # Stub mysql connection to SOLAS-Match
      solas_match_mysql_client = double(:mysql_client)
      allow(Mysql2::Client).to receive(:new).and_return(solas_match_mysql_client)
      allow_any_instance_of(Solas::Connection).to receive(:solas_config).and_return({})
      allow(solas_match_mysql_client).to receive(:close)
    end

    config.after do
      Timecop.return
      DatabaseCleaner.clean
    end

    config.run_all_when_everything_filtered = true

    config.use_transactional_fixtures = false
    config.infer_spec_type_from_file_location!

    config.before(type: :controller) do
      request.env['HTTP_REFERER'] = '/previous_page'
    end
  end

  Capybara.server = :puma

  if ENV['USE_SELENIUM'] == '1'
    Capybara.register_driver :selenium do |app|
      if ENV['USE_CHROME'] == '1'
        Capybara::Selenium::Driver.new(app, browser: :chrome)
      else
        Capybara::Selenium::Driver.new(app, browser: :firefox)
      end
    end
  else
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new app,
                                        timeout:           60,
                                        phantomjs_options: ['--load-images=yes'],
                                        window_size:       [1800, 900],
                                        js_errors:         false
    end

    Capybara.javascript_driver = :poltergeist
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

  unless ENV['DRB']
    SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter]
    SimpleCov.start 'rails'
  end

  # Reload factories
  FactoryGirl.factories.clear
  ActiveSupport::Dependencies.clear
  Dir[Rails.root.join('spec', 'factories', '**', '*.rb')].each { |f| load f }
  Dir[Rails.root.join('app', 'helpers', '**', '*.rb')].each { |f| load f }
  Dir[Rails.root.join('app', 'support', '**', '*.rb')].sort_by { |p| p.count('/') }.each { |f| load f }
  Dir[Rails.root.join('app', 'controllers', '**', '*.rb')].sort_by { |p| p.count('/') }.each { |f| load f }
  Dir[Rails.root.join('spec', 'spec_support', '**', '*.rb')].each { |f| load f }

  include ApplicationHelper

  include Shoulda::Matchers::ActiveModel
  include Shoulda::Matchers::ActiveRecord

  # Reload Routes
  KatoAnalytics::Application.reload_routes!
  DatabaseCleaner.clean
end
