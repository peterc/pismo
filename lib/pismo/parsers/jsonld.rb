require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Jsonld < Base
      def call
        json_ld_meta
      end

      def json_ld_meta
        @json_ld_meta ||= begin
          return {} unless json_ld_script
          {
            author:         author,
            person:         person,
            publisher:      publisher,
            type:           type,
            url:            url,
            headline:       headline,
            description:    description,
            featured_image: featured_image,
            keywords:       keywords,
            published_date: published_date,
            raw_data:       json_ld
          }
        end
      end

      def json_ld
        @json_ld ||= begin
          json_ld = JSON.parse(json_ld_script) if json_ld_script
          json_ld = {} if json_ld.nil?
          json_ld
        end
      end

      def json_ld_script
        @json_ld_script_text ||= doc.xpath('//script[@type="application/ld+json"]')&.first&.text
      end

      def author
        @author ||= person_parser('author')
      end

      def person
        @person ||= person_parser('person')
      end

      def publisher
        @publisher ||= organization_parser('publisher')
      end

      def type
        @type ||= json_ld.dig('@type')
      end

      def url
        @url ||= json_ld.dig('url')
      end

      def headline
        @headline ||= json_ld.dig('headline')
      end

      def description
        @description ||= json_ld.dig('description')
      end

      def featured_image
        @featured_image ||= begin
          image = json_ld.dig('image')
          if image.is_a?(Hash)
            image_url = image.dig('url')
          else
            if image.is_a?(Array)
              image_hsh = image.uniq.first
              image_url = image_hsh.dig('url') if image_hsh
            end
          end
          image_url
        end
      end

      def keywords
        @keywords ||= json_ld.dig('keywords').to_s
                             .downcase.split(',')
                             .map do |keyword|
          keyword.gsub(/\W+/, ' ').squeeze(' ').strip
        end
      end

      def published_date
        @published_date ||= json_ld.dig('datePublished')
      end

      def person_parser(key)
        hsh = {}
        if json_ld[key].is_a?(String)
          hsh[:name] = json_ld[key]
        elsif json_ld.is_a?(Hash)
          hsh[:name] = json_ld.dig(key, 'name')
          unless hsh[:name].nil?
            hsh[:from] = 'jsonld'
            hsh[:title] = json_ld.dig(key, 'jobTitle')
            %w[url email telephone gender image].each do |sub_key|
              hsh[sub_key.to_sym] = json_ld.dig(key, sub_key)
            end
            hsh[:image] = json_ld.dig(key, 'image', 'url') if hsh[:image].is_a?(Hash)
            hsh = hsh.delete_if { |k, v| v.nil? }
            hsh = add_identifier(hsh)
            hsh[:type] = 'site/author' if hsh[:type] && hsh[:type] == 'web/page'
          end
        end
        hsh
      end

      def organization_parser(key)
        hsh = {}
        hsh[:name] = json_ld.dig(key, 'name')
        return {} if hsh[:name].nil?
        hsh[:from] = 'jsonld'
        hsh[:image] = json_ld.dig(key, 'logo')
        hsh[:image] = json_ld.dig(key, 'logo', 'url') if hsh[:image].is_a?(Hash)
        %w[url description].each do |sub_key|
          hsh[sub_key.to_sym] = json_ld.dig(key, sub_key)
        end
        hsh = hsh.delete_if { |k, v| v.nil? }
        hsh = add_identifier(hsh)
        hsh[:type] = 'company/profile' if hsh[:type] && hsh[:type] == 'web/page'
        hsh[:identifier] = hsh[:type]
        hsh
      end

      def add_identifier(hsh)
        return hsh unless hsh[:url]
        parsed = Allusion.parse(hsh[:url])
        hsh[:type] = parsed[:identifier]
        hsh
      end
    end
  end
end
