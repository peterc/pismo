module Pismo
  module Parsers
    module Authorship
      class Entities < Base
        def call
          authors
        end

        # Strategy.. scan text to look for by XX XX where XX is an entity.
        # USe this to find any a links tha are linking to this name
        # run podes to provides
        def authors
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

        def entities
          @entities ||= args.dig(:entities)
        end
      end
    end
  end
end
