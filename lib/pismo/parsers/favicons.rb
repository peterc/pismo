require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Favicons < Base
      def call
        favicons
      end

      def favicon_matches
        [
          ['link[@rel="fluid-icon"]', lambda { |el| el.attr('href') }],      # Get a Fluid icon if possible..
          ['link[@rel="shortcut icon"]', lambda { |el| el.attr('href') }],
          ['link[@rel="icon"]', lambda { |el| el.attr('href') }]
        ]
      end

      # Returns the "description" of the page, usually comes from a meta tag
      # We only return the first match, not all of them. But do it as an
      # array to make the parsers behavior consistent
      def favicons
        @favicons ||= begin
          url = doc.match(favicon_matches).first
          url = URI.join(@url , url).to_s if url and @url and !url.start_with? "http"
          [url]
        end
      end
    end
  end
end
