require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Images < Base
      def call
        images
      end

      # Returns URL(s) of Web feed(s)
      def images
        @images ||= begin
          images = []
          images << meta.dig('name', 'twitter:image')
          images << meta.dig('property', 'og:image')
          images = images.flatten
          images = images.delete_if { |image| image.nil? }.uniq
          images
        end
      end
    end
  end
end
