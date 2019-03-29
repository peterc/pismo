require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Descriptions < Base
      def call
        descriptions
      end

      def description_matches
        [
          ['meta[@name="description"]', lambda { |el| el.attr('content') }],
          ['meta[@name="Description"]', lambda { |el| el.attr('content') }],
          ['meta[@name="DESCRIPTION"]', lambda { |el| el.attr('content') }],
          'rdf:Description[@name="dc:description"]',
          '.description'
        ]
      end

      # Returns the "description" of the page, usually comes from a meta tag
      def descriptions
        doc.match description_matches
      end
    end
  end
end
