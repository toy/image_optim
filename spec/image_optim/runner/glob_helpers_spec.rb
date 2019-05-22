# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/runner/glob_helpers'

describe ImageOptim::Runner::GlobHelpers do
  describe '.expand_braces' do
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
        expect(described_class.expand_braces(glob)).to match_array(expected)
      end
    end
  end
end
