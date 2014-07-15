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
      def deep_merge(a, b)
        a.merge(b) do |_k, v_a, v_b|
          if v_a.is_a?(Hash) && v_b.is_a?(Hash)
            deep_merge(v_a, v_b)
          else
            v_b
          end
        end
      end

    private

      # Returns a new hash with all keys of root and nested hashes converted by
      # provided block
      def deep_transform_keys(hash, &block)
        new_hash = {}
        hash.each do |k, v|
          new_hash[block.call(k)] = if v.is_a?(Hash)
            deep_transform_keys(v, &block)
          else
            v
          end
        end
        new_hash
      end
    end
  end
end
