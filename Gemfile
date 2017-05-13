source 'https://rubygems.org'

gemspec

git 'https://github.com/toy/image_optim_pack.git', :branch => 'guetzli' do
  gem 'image_optim_pack'
end

if ENV['CODECLIMATE']
  group :test do
    gem 'simplecov'

    gem 'codeclimate-test-reporter'
  end
end

if RUBY_VERSION >= '2.0'
  gem 'travis_check_rubies', '~> 0.2'
end
