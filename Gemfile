source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.6'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'
gem 'mysql2'

# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

gem 'bootstrap-sass'
gem 'font-awesome-rails', git: 'https://github.com/bokmann/font-awesome-rails'
gem 'simple_form', git: 'https://github.com/plataformatec/simple_form'
gem 'exception_notification_rails3', require: 'exception_notifier'
gem 'haml'
gem 'jwt'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

gem 'jquery-rails'
gem 'jquery-ui-rails', git: 'https://github.com/joliss/jquery-ui-rails.git'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'ruby-saml'

# Deploy with Capistrano
gem 'capistrano',        '2.14.2'
gem 'capistrano-ext'
gem 'capistrano_colors', require: false

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'rails-controller-testing'
  gem 'spork'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'database_cleaner'

  gem 'rubocop',   require: false
  gem 'haml-lint', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'simplecov'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'timecop'
  gem 'poltergeist'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'chartkick'
gem 'ed25519'
gem 'bcrypt_pbkdf'
gem 'net-ssh'
gem 'whenever', require: false
