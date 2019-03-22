require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Jsonld < Parsers::Base
      def call
        json_ld_meta
      end

      def json_ld_meta
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
          published_date: published_date
        }
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
        @featured_image ||= json_ld.dig('image', 'url')
      end

      def keywords
        @keywords ||= json_ld.dig('keywords').to_s.downcase.split(',').map(&:strip)
      end

      def published_date
        @published_date ||= json_ld.dig('datePublished')
      end

      def person_parser(key)
        hsh = {}
        hsh[:name] = json_ld.dig(key, 'name')
        return {} if hsh[:name].nil?
        hsh[:source] = 'jsonld'
        hsh[:title] = json_ld.dig(key, 'jobTitle')
        %w[url email telephone].each do |sub_key|
          hsh[sub_key.to_sym] = json_ld.dig(key, sub_key)
        end
        hsh = hsh.delete_if { |k, v| v.nil? }
        hsh = add_identifier(hsh)
        hsh[:type] = 'author/profile' if hsh[:type] && hsh[:type] == 'web/page'
        hsh
      end

      def organization_parser(key)
        hsh = {}
        hsh[:name] = json_ld.dig(key, 'name')
        return {} if hsh[:name].nil?
        hsh[:source] = 'jsonld'
        hsh[:logo_image] = json_ld.dig(key, 'logo', 'url')
        %w[url description].each do |sub_key|
          hsh[sub_key.to_sym] = json_ld.dig(key, sub_key)
        end
        hsh = hsh.delete_if { |k, v| v.nil? }
        hsh = add_identifier(hsh)
        hsh[:type] = 'company/profile' if hsh[:type] && hsh[:type] == 'web/page'
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
