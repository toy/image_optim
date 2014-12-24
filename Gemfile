source 'https://rubygems.org'

gemspec

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('1.9')
  gem 'codeclimate-test-reporter', :group => :test, :require => nil
end

gem 'rails', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']
