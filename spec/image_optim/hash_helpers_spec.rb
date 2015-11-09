require 'spec_helper'
require 'image_optim/hash_helpers'

describe ImageOptim::HashHelpers do
  before do
    stub_const('HashHelpers', ImageOptim::HashHelpers)
  end

  context 'stringify/simbolyze' do
    symbol_keys = {
      :a => 1,
      :b => {
        :c => [:a, 'a'],
        :d => {},
      },
    }

    string_keys = {
      'a' => 1,
      'b' => {
        'c' => [:a, 'a'],
        'd' => {},
      },
    }

    it 'deep stringifies hash keys' do
      expect(HashHelpers.deep_stringify_keys(symbol_keys)).to eq(string_keys)
      expect(HashHelpers.deep_stringify_keys(string_keys)).to eq(string_keys)
    end

    it 'deep symbolises hash keys' do
      expect(HashHelpers.deep_symbolise_keys(string_keys)).to eq(symbol_keys)
      expect(HashHelpers.deep_symbolise_keys(symbol_keys)).to eq(symbol_keys)
    end
  end

  it 'deep merges hashes' do
    merge_a = {
      :a => {
        :b => 1,
        :c => {
          :d => 2,
          :e => {:f => true},
        },
      },
      :y => 10,
    }

    merge_b = {
      :a => {
        :b => 2,
        :c => {
          :d => 3,
          :e => false,
        },
      },
      'z' => 20,
    }

    merge_result = {
      :a => {
        :b => 2,
        :c => {
          :d => 3,
          :e => false,
        },
      },
      :y => 10,
      'z' => 20,
    }

    expect(HashHelpers.deep_merge(merge_a, merge_b)).to eq(merge_result)
  end
end
