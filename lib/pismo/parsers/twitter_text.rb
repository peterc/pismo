require 'pismo/parsers/base'

module Pismo
  module Parsers
    class TwitterText < Base
      include Twitter::TwitterText::Extractor

      def entities
        @entities ||= extract_entities_with_indices(text)
      end
    end
  end
end
