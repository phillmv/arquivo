source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '~> 2.6.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.0', '>= 6.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.4'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# worries that something shifted in how my stylesheets rendered, so for now
# sticking to this old version of sassc
gem 'sassc', '2.2.1'

# TODO: webpacker is now deprecated. need to switch off
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# downgrade psych until upgrade to rails 7
gem 'rexml'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

gem 'commonmarker', '0.23.10'
# Octicons' have since shifted / removed some icons i use, so:
gem 'octicons', '9.4.0'
gem 'octicons_helper', '9.4.0'
gem 'gemoji'

# html-pipeline has radically changed, so we're stuck now:
gem 'html-pipeline', '2.12.3'
gem 'sanitize', '~> 6.0'

# escape utils has deprecated some methods i use, so:
gem 'escape_utils', '1.2.1'

gem 'deckar01-task_list'

gem 'whenever'

gem 'will_paginate'

gem 'icalendar'
gem 'icalendar-recurrence'

# the git gem behaviour shifted after this version, so:
gem 'git', '1.7.0'

gem 'dotenv-rails'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem "dockerfile-rails", ">= 1.4"
end

gem 'pry-rails'
gem 'simple_calendar'
gem 'front_matter_parser'

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
end
