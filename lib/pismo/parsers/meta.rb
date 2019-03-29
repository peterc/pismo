require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Meta < Parsers::Base
      def call
        meta
      end

      def meta
        @meta ||= begin
          {
            'name'             => meta_tags_by('name'),
            'http-equiv'       => meta_tags_by('http-equiv'),
            'property'         => meta_tags_by('property'),
            'charset'          => [charset],
            'content_type'     => [content_type],
            'content_language' => content_language
          }
        end
      end

      def charset
        @charset ||= (charset_from_meta_charset || charset_from_meta_content_type)
      end

      def charset_from_meta_charset
        doc.css('meta[charset]')[0].attributes['charset'].value
      rescue
        nil
      end

      def charset_from_meta_content_type
        meta_content_type.split(';')[1].split('=')[1]
      rescue
        nil
      end

      def meta_content_type
        @meta_content_type ||= doc.css("meta[http-equiv='Content-Type']")[0]&.attributes['content'].value
      rescue
        nil
      end

      def content_type
        meta_content_type.split(';')[0]&.strip
      rescue
        nil
      end

      def content_language
        doc.css("meta[http-equiv='Content-Language']")[0]&.attributes['content'].value
      rescue
        nil
      end

      def meta_tags_by(attribute)
        hash = {}
        doc.css("meta[@#{attribute}]").map do |tag|
          name    = tag.attributes[attribute]&.value&.downcase
          content = tag.attributes['content']&.value
          if name && content
            hash[name] ||= []
            hash[name] << content
          end
        end
        hash
      end

      def meta_tag
        convert_each_array_to_first_element_on(meta_tags)
      end

      def convert_each_array_to_first_element_on(hash)
        hash.each_pair do |k, v|
          hash[k] = if v.is_a?(Hash)
                      convert_each_array_to_first_element_on(v)
                    elsif v.is_a?(Array)
                      v.first
                    else
                      v
                    end
        end
      end
    end
  end
end
