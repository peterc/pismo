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
          json_ld = JSON.parse(json_ld_script.gsub(/\a|\t|\n|\f|\r|\e/, " ")) if json_ld_script
          json_ld = {} if json_ld.nil?
          json_ld
        end
      end

      def json_ld_script
        @json_ld_script ||= doc.xpath('//script[@type="application/ld+json"]')&.first&.text
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
        @type ||= Utils::HashSearch.deep_find(json_ld, '@type')
      end

      def url
        @url ||= Utils::HashSearch.deep_find(json_ld, 'url')
      end

      def headline
        @headline ||= Utils::HashSearch.deep_find(json_ld, 'headline')
      end

      def description
        @description ||= Utils::HashSearch.deep_find(json_ld, 'de')
      end

      def featured_image
        @featured_image ||= begin
          image = Utils::HashSearch.deep_find(json_ld, 'image', 'url')
          image = Utils::HashSearch.deep_find(json_ld, 'image') if image.blank?
          image = image.first if image.is_a?(Array)
          image
        end
      end

      def keywords
        @keywords ||= begin
          keywords = Utils::HashSearch.deep_find(json_ld, 'keywords')

          if keywords.is_a?(String)
            keywords = keywords.downcase.split(',')
                               .map do |keyword|
              keyword.gsub(/\W+/, ' ').squeeze(' ').strip
            end
          end

          keywords
        end
      end

      def published_date
        @published_date ||= Utils::HashSearch.deep_find(json_ld, 'datePublished')
      end

      def person_parser(key)
        hsh = {}
        typed_person_object = Utils::HashSearch.deep_find(json_ld, key)
        if typed_person_object.is_a?(String)
          hsh[:name] = typed_person_object
        else
          name = Utils::HashSearch.deep_find(typed_person_object, 'name')
          if name
            hsh[:name] = name
            %w[jobTitle url email telephone gender image].each do |subkey|
              subkey_value = Utils::HashSearch.deep_find(typed_person_object, subkey)
              hsh[subkey.underscore.to_sym] = subkey_value if subkey_value.present?
            end
          end
        end
        hsh = add_identifier(hsh)
        hsh[:type] = 'site/author' if hsh[:type] && hsh[:type] == 'web/page'
        hsh
      end

      def organization_parser(key)
        hsh = {}
        typed_organization_object = Utils::HashSearch.deep_find(json_ld, key)
        if typed_organization_object.is_a?(String)
          hsh[:name] = typed_organization_object
        else
          name = Utils::HashSearch.deep_find(typed_organization_object, 'name')
          if name
            hsh[:name] = name
            hsh[:image] = Utils::HashSearch.deep_find(typed_organization_object, 'logo', 'url')
            hsh[:image] = Utils::HashSearch.deep_find(typed_organization_object, 'logo') if hsh[:image].blank?
            %w[url description].each do |subkey|
              subkey_value = Utils::HashSearch.deep_find(typed_organization_object, subkey)
              hsh[subkey.to_sym] = subkey_value if subkey_value
            end
          end
        end
        hsh = add_identifier(hsh)
        hsh[:type] = 'company/profile' if hsh[:type] && hsh[:type] == 'web/page'
        hsh[:identifier] = hsh[:type]
        hsh
      end

      def add_identifier(hsh)
        return hsh unless hsh[:url]

        parsed = Allusion.parse(hsh[:url])
        hsh[:type]       = parsed[:identifier]
        hsh[:identifier] = parsed[:identifier]
        hsh[:from]       = 'jsonld' if hsh[:type].present?
        hsh
      end
    end
  end
end
