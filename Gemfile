# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'image_optim_pack', platform: 'ruby' if RUBY_VERSION < '3.1'

if RUBY_VERSION >= '4'
  gem 'logger'
end

if ENV['CC_TEST_REPORTER_ID']
  group :test do
    gem 'simplecov'
  end
end
