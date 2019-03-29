require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Keywords < Base
      def call
        keywords
      end

      def limit
        @limit ||= args.dig(:limit) || 20
      end

      def minimum_score
        @minimum_sccore ||= args.dig(:minimum_score) || "1%"
      end

      def get_parser_options
        default_keyword_options.merge(keyword_options)
      end

      def keywords

      end

      def results
        @results ||= begin
          phrases = extractor.phrases(keyword_text, occur: minimum_score)
                             .map { |phrase, occur, strength| [phrase.downcase, occur] }
          phrases.
            delete_if { |phrase, occur| occur < 2 }.
            sort_by   { |phrase, occur| occur     }.
            reverse.first(limit)
        end
      end

      def keyword_text
        @keyword_text ||= [title, description, body].join(' ')
      end

      def extractor
        @extractor ||= Phrasie::Extractor.new
      end

      def extracted_phrases
        @extracted_phrases ||= results.map { |phrase_array| phrase_array[0] }
      end
    end
  end
end
