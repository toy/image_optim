# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

if ENV['CODECLIMATE']
  group :test do
    gem 'simplecov'

    gem 'codeclimate-test-reporter'
  end
end

if ENV['CHECK_RUBIES']
  gem 'travis_check_rubies', '~> 0.2'
end
