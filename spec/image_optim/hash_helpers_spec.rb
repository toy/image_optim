$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/hash_helpers'

describe ImageOptim::HashHelpers do
  HH = ImageOptim::HashHelpers

  context 'stringify/simbolyze' do
    WITH_SYMBOL_KEYS = {
      :a => 1,
      :b => {
        :c => [:a, 'a'],
        :d => {},
      },
    }

    WITH_STRING_KEYS = {
      'a' => 1,
      'b' => {
        'c' => [:a, 'a'],
        'd' => {},
      },
    }

    it 'deep stringifies hash keys' do
      expect(HH.deep_stringify_keys(WITH_SYMBOL_KEYS)).to eq(WITH_STRING_KEYS)
      expect(HH.deep_stringify_keys(WITH_STRING_KEYS)).to eq(WITH_STRING_KEYS)
    end

    it 'deep symbolises hash keys' do
      expect(HH.deep_symbolise_keys(WITH_STRING_KEYS)).to eq(WITH_SYMBOL_KEYS)
      expect(HH.deep_symbolise_keys(WITH_SYMBOL_KEYS)).to eq(WITH_SYMBOL_KEYS)
    end
  end

  it 'deep merges hashes' do
    merge_a = {
      :a => {
        :b => 1,
        :c => {
          :d => 2,
          :e => {
            :f => true,
          },
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

    expect(HH.deep_merge(merge_a, merge_b)).to eq(merge_result)
  end

end
