$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/runner/glob_helpers'

describe ImageOptim::Runner::GlobHelpers do
  GH = ImageOptim::Runner::GlobHelpers

  describe :expand_braces do
    {
      'hello.world' => %w[hello.world],
      '{hello,.world}' => %w[hello .world],
      'hello{.,!}world' => %w[hello.world hello!world],
      '{a,b},{c,d}' => %w[a,c b,c a,d b,d],
      '{{a,b},{c,d}}' => %w[a b c d],
      '{a,b,{c,d}}' => %w[a b c d],
      '{\{a,b\},\{c,d\}}' => %w[\\{a b\\} \\{c d\\}],
      'test{ing,}' => %w[testing test],
    }.each do |glob, expected|
      it "expands #{glob}" do
        expect(GH.expand_braces(glob)).to match_array(expected)
      end
    end
  end
end
