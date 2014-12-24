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

def flatten_animation(image)
  if image.format == :gif
    flattened = image.temp_path
    flatten_command = %W[
      convert
      #{image.to_s.shellescape}
      -coalesce
      -append
      #{flattened.to_s.shellescape}
    ].join(' ')
    expect(ImageOptim::Cmd.run(flatten_command)).to be_truthy
    flattened
  else
    image
  end
end

def nrmse(image_a, image_b)
  coalesce_a = flatten_animation(image_a)
  coalesce_b = flatten_animation(image_b)
  nrmse_command = %W[
    compare
    -metric RMSE
    -alpha Background
    #{coalesce_a.to_s.shellescape}
    #{coalesce_b.to_s.shellescape}
    /dev/null
    2>&1
  ].join(' ')
  output = ImageOptim::Cmd.capture(nrmse_command)
  if [0, 1].include?($CHILD_STATUS.exitstatus)
    output[/\((\d+(\.\d+)?)\)/, 1].to_f
  else
    fail "compare #{image_a} with #{image_b} failed with `#{output}`"
  end
end
