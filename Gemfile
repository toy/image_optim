# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

if RUBY_VERSION >= '4'
  gem 'logger'
end

if ENV['CC_TEST_REPORTER_ID']
  group :test do
    gem 'simplecov'
  end
end
