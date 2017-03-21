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
  gem 'rainbow', '!= 2.2.1' # TODO: remove when sickill/rainbow#44 is resolved
end
