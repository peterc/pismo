module Pismo
  module Utils
    class NormalizeHtml
      attr_accessor :html

      UNICODE_CONVERSIONS = {
        "8230" => '...',
        "8194" => ' ',
        "8195" => ' ',
        "8201" => ' ',
        "8211" => '-',
        "8216" => '\'',
        "8217" => '\'',
        "8220" => '"',
        "8221" => '"'
      }
      TRANSLATED_CONVERSIONS =
        UNICODE_CONVERSIONS.map { |k, v| [k.to_i.chr('UTF-8'), v] }

      def initialize(html)
        @html = html
      end

      def normalize_unicode_characters
        TRANSLATED_CONVERSIONS.each { |key, value| @html.gsub!(key, value) }
      end

      # We run across cases where the HTML entities are double escaped.
      # Running this twice helps us handle that sitaution.
      def convert_html_entities
        @html = decoder.decode(@html)
        @html = decoder.decode(@html)
      end

      def decoder
        @decoder ||= HTMLEntities.new
      end

      def call
        normalize_unicode_characters
        convert_html_entities
        @html
      end
    end
  end
end
