source 'https://rubygems.org'

gemspec

if ENV['CODECLIMATE']
  group :test do
    gem 'simplecov'

    gem 'codeclimate-test-reporter'
  end
end

if RUBY_VERSION >= '2.0'
  gem 'travis_check_rubies', '~> 0.2'
end
