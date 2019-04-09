module Pismo
  module Parsers
    class Tags < Base
      def call
        tags
      end

      def tag_selectors
        [
           '.watch-info-tag-list a',  # YouTube
           '.entry .tags a',          # Livejournal
           'a[rel~=tag]',             # Wordpress and many others
           'a.tag',                   # Tumblr
           '.tags a',
           '.labels a',
           '.categories a',
           '.topics a'
        ].freeze
      end

      def tags
        @tags ||= begin
          tags = []
          tag_selectors.each do |css_selector|
            tags += doc.css(css_selector)
            break if tags.any?
          end
          tags.map!(&:inner_text) # get the text of it
          tags
        end
      end
    end
  end
end
