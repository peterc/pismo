module Pismo
  # Stores the utilities that we need, in no particular organization
  class Utilities
    class << self
      def max(a, b)
        a >= b ? a : b
      end

      def sentences_from_node(doc)
        text = Utils::ConvertToPlainText.doc_to_plain_text(doc, tag_headings: true)
        Dewey.new(text: text).cleaned_sentences
                             .select { |sentence| sentence.length > 30 || sentence.include?("__HEADING") }
                             .map    { |sentence| remove_header_tag(sentence) }
      end

      def remove_header_tag(sentence)
        sentence.gsub('__HEADER_START__', '').squeeze(' ').strip
      end

      def extract_text(doc)
        Utils::ConvertToPlainText.doc_to_plain_text(doc, tag_headings: true)
      end

      def sentences(text)
        Dewey.new(text: text).cleaned_sentences.map { |sentence| remove_header_tag(sentence) }
      end

      def looks_like_a_name?(term)
        Dewey::Utils::TextUtils.looks_like_a_name?(term)
      end

      def extract_likely_name(text)
        ConfidentialInfoRedactor::Extractor.new.extract(text)&.join(' ')
      end

      # Return the longest common prefix between two strings.  If max is
      # specified then the longest common prefix cannot exceed it
      def longest_common_prefix(s1, s2, max = nil)
        l1, l2 = s1.size, s2.size
        min = l1 < l2 ? l1 : l2
        min = min < max ? min : max if max
        min.times do |i|
          return s1.slice(0, i) if s1[i] != s2[i]
        end
        return s1.slice(0, min)
      end

      def absolutize_url(current_url, new_url)
        Addressable::URI.join(current_url, new_url).to_s
      end

      def longest_common_substring_in_array(array)
        result = longest_repeated_substring(array.join(' '))
        if array.include?(result)
          result
        else
          nil
        end
      end

      # Returns the longest repeated substring in a given string.
      def longest_repeated_substring(string)

        size = string.length

        # put every possible suffix into an array
        suffixes = Array.new(size)
        size.times do |i|
          suffixes[i] = string.slice(i, size)
        end

        # sort the array of suffixes, so common substrings (i.e., prefixes
        # of suffixes) will be found in neighboring elements of the array
        suffixes.sort!

        best = ""
        at_least_size = 1    # the size to meet or exceed to be the new best
        distance = nil
        neighbors_to_check = 1

        # compare pairs of consecutive suffixes and see how much initial
        # commonality there is
        # (size - 1).times do |i|
        (1...size).each do |i|
          # p [i, neighbors_to_check]
          s1 = suffixes[i]

          # generally we will only need to compare the ith item and the one
          # preceding it; however if we were in a position to reject a long
          # enough common substring due to overlap issues, then we may have
          # to compare an ith item with additional preceding items;
          # neighbors_to_check tracks how many neighbors we need to check
          neighbors_to_check.downto(1) do |neighbor|
            s2 = suffixes[i - neighbor]

            # make sure that these to suffixes further apart than the size
            # of the current best; we don't explicitly track the index of
            # these suffixes, but since all suffixes go to the end of the
            # initial string, the size can be used as a proxy
            distance = (s1.size - s2.size).abs
            if distance < at_least_size
              if s1.size >= at_least_size &&
                  s2.size >= at_least_size &&
                  s1.slice(0, at_least_size) == s2.slice(0, at_least_size)
                neighbors_to_check = max(neighbors_to_check, neighbor + 1)
              else
                neighbors_to_check = neighbor
              end
              next
            end

            # if neighboring suffixes don't at least match as far as the best,
            # no need to check more carefully
            unless s1.slice(0, at_least_size) == s2.slice(0, at_least_size)
              neighbors_to_check = neighbor
              next
            end

            # get the longest common prefix that's no larger than distance,
            # since at that point the substrings overlap
            best = longest_common_prefix(s1, s2, distance)
            at_least_size = best.size + 1
            if best.size == distance
              neighbors_to_check = max(neighbors_to_check, neighbor + 1)
            else
              neighbors_to_check = neighbor
            end
          end
        end

        best.strip
      end
    end
  end
end
