source 'https://rubygems.org'

gemspec

if ENV['CODECLIMATE']
  gem 'codeclimate-test-reporter', :group => :test, :require => nil
end

%w[
  rails
  sprockets
  sprockets-rails
].each do |gem_name|
  version = ENV[gem_name.tr('-', '_').upcase + '_VERSION']
  gem gem_name, version if version
end
