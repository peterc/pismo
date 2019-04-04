module Pismo
  module Parsers
    module Authorship
      class Schema < Base
        def call
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

        def author_url
          @author_url ||= begin
            author_url = nil
            root_node_types.each do |rnt|
              author_url = Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'url')
              author_url = Utils::HashSearch.deep_find(microdata, rnt, 'author', 'url') if author_url.nil?
              author_url = Utils::HashSearch.deep_find(microdata, rnt, 'author', 'properties', 'sameAs') if author_url.nil?
              author_url = Utils::HashSearch.deep_find(microdata, rnt, 'author', 'sameAs')               if author_url.nil?
              break if author_url
            end
            author_url = Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'url')    if author_url.nil?
            author_url = Utils::HashSearch.deep_find(microdata, 'Author', 'properties', 'sameAs') if author_url.nil?
            author_url
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
