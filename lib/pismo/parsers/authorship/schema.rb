module Pismo
  module Parsers
    module Authorship
      class Schema < Base
        def call
          authors
        end

        def name
          @name ||= begin
            name = nil
            root_node_types.each do |rnt|
              name = Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'name')
              break if name.present?
            end
            name = Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'name') if name.nil?
            name
          end
        end

        def root_node_types
          %w[BlogPosting Article]
        end

        def authors
          if microdata && name
            author_urls.map do |author_url|
              parsed = Allusion.parse(author_url)
              hsh = {
                url:   author_url,
                name:  name,
                image: image,
                type:  parsed[:identifier],
                from: :schema
              }
              hsh[:type] = 'site/author' if hsh[:type] == 'web/page'
              hsh unless hsh[:type].nil?
            end
          end
        end

        def author_urls
          @author_urls ||= begin
            author_urls = []
            root_node_types.each do |rnt|
              author_urls << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'url')
              author_urls << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'url')
              author_urls << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'sameAs')
              author_urls << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'sameAs')
            end
            author_urls << Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'url')
            author_urls << Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'sameAs')
            author_urls.flatten.compact
          end
        end

        def image
          images&.first
        end

        def images
          @images ||= begin
            images = []
            root_node_types.each do |rnt|
              images << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'image', 'url')
              images << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'image', 'properties', 'url')
              images << Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'image')
            end
            images << Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'image', 'url')
            images << Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'image', 'properties', 'url')
            images << Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'image')
            images.flatten.compact.delete_if { |img| img.is_a?(Hash) || img.nil? }
          end
        end

        def microdata
          @microdata ||= begin
            hsh = {}
            microdata_parser.items.each do |item|
              hsh_item = ::HashWithIndifferentAccess.new(item.to_h)
              if hsh_item.keys.length > 1 && hsh_item.key?(:type)
                hsh[hsh_item[:type].gsub('http://schema.org/', '')] = hsh_item[:properties]
              end
            end
            hsh
          end
        end

        def microdata_parser
          @microdata_parser ||= Mida::Document.new(doc, url)
        end
      end
    end
  end
end
