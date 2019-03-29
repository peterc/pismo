require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Feeds < Base
      def call
        feeds
      end

      # Returns URL(s) of Web feed(s)
      def feeds
        @feeds ||= begin
          doc.match(feed_matches).map do |url|
            case url
            when String
              if url.start_with? "http"
                url
              elsif url
                URI.join(url , url).to_s
              end
            when Array
              url.map do |u|
                if u.start_with? "http"
                  u
                elsif url
                  URI.join(url, u).to_s
                end
              end.uniq
            end
          end
        end
      end

      def feed_matches
        [
          ['link[@type="application/rss+xml"][@rel="alternate"]',  lambda { |el| el.attr('href') }],
          ['link[@type="application/atom+xml"][@rel="alternate"]', lambda { |el| el.attr('href') }]
        ]
      end
    end
  end
end
