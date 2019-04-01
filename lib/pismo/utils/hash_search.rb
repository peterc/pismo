module Pismo
  module Utils
    class HashSearch
      class << self
        def find_in_hash(hsh, *keys)
          keys = keys.dup

          next_key = keys.shift
          return [] unless hsh.key? next_key

          next_val = hsh[next_key]
          return next_val if keys.empty?

          return find_in_hash(next_val, *keys) if next_val.is_a?(::Hash)

          return [] unless next_val.is_a?(Array)
          next_val.each_with_object([]) do |v, result|
            inner = find_in_hash(v, *keys)
            result << inner if inner
          end
        end

        def find_in_array(arr, *keys)
          result = nil
          arr.each do |array_part|
            result = find_in_hash(array_part, *keys)
            break if !result.blank?
          end
          result
        end

        # Convenicene method for find in hash or find in aarray
        def find(item, *keys)
          result = nil
          if item.is_a?(::Hash)
            result = find_in_hash(item, *keys)
          elsif item.is_a?(Array)
            result = find_in_array(item, *keys)
          end
          result = clean_result(result)
          result
        end

        def deep_find(item, *keys)
          result = nil
          search_item = item.dup
          if search_item.is_a?(Hash)
            result = find(search_item, *keys)
          else
            keys.each do |key|
              result = self.find(search_item, key)
              search_item = result if result.present?
              break if result.blank?
            end
          end
          result = clean_result(result)
          result
        end

        def clean_result(result)
          return nil              if result.nil?

          result = nil            if result.is_a?(Array)  && result.length.zero?
          result = nil            if result.is_a?(::Hash) && result.keys.length.zero?
          result = result.flatten if result.is_a?(Array)
          result = result.first   if result.is_a?(Array)  && result.length == 1
          result
        end
      end
    end
  end
end
