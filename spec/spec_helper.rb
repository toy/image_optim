if ENV['CODECLIMATE_REPO_TOKEN']
  begin
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  rescue LoadError => e
    $stderr.puts "Got following while loading codeclimate-test-reporter: #{e}"
  end
end

RSpec.configure do |c|
  c.alias_example_to :they
end
