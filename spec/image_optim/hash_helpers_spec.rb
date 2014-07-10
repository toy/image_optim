$:.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/hash_helpers'

describe ImageOptim::HashHelpers do
  HH = ImageOptim::HashHelpers

  it 'should deep stringify hash keys' do
    HH.deep_stringify_keys({
      :a => 1,
      :b => {
        :c => :a,
        :d => {},
      },
    }).should == {
      'a' => 1,
      'b' => {
        'c' => :a,
        'd' => {},
      },
    }
  end

  it 'should deep symbolise hash keys' do
    HH.deep_symbolise_keys({
      'a' => 1,
      'b' => {
        'c' => 'a',
        'd' => {},
      },
    }).should == {
      :a => 1,
      :b => {
        :c => 'a',
        :d => {},
      },
    }
  end

  it 'should deep merge hashes' do
    HH.deep_merge({
      :a => {
        :b => 1,
        :c => {
          :d => 2,
          :e => {
            :f => true
          },
        },
      },
      :y => 10,
    }, {
      :a => {
        :b => 2,
        :c => {
          :d => 3,
          :e => false,
        },
      },
      :z => 20,
    }).should == {
      :a => {
        :b => 2,
        :c => {
          :d => 3,
          :e => false,
        },
      },
      :y => 10,
      :z => 20,
    }
  end

end
