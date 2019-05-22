# frozen_string_literal: true

class ImageOptim
  # Helper methods to manipulate Hash, mainly used in config
  module HashHelpers
    class << self
      # Returns a new hash with all keys of root and nested hashes converted to
      # strings
      def deep_stringify_keys(hash)
        deep_transform_keys(hash, &:to_s)
      end

      # Returns a new hash with all keys of root and nested hashes converted to
      # symbols
      def deep_symbolise_keys(hash)
        deep_transform_keys(hash, &:to_sym)
      end

      # Returns a new hash with recursive merge of all keys
      def deep_merge(hash_a, hash_b)
        hash_a.merge(hash_b) do |_key, value_a, value_b|
          if value_a.is_a?(Hash) && value_b.is_a?(Hash)
            deep_merge(value_a, value_b)
          else
            value_b
          end
        end
      end

    private

      # Returns a new hash with all keys of root and nested hashes converted by
      # provided block
      def deep_transform_keys(hash, &block)
        new_hash = {}
        hash.each do |key, value|
          new_hash[yield key] = if value.is_a?(Hash)
            deep_transform_keys(value, &block)
          else
            value
          end
        end
        new_hash
      end
    end
  end
end
