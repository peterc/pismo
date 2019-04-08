module Pismo
  module Parsers
    class Links < Base
      def call
        parsed_links
      end

      def parsed_links
        @parsed_links ||= links.map do |link|
          begin
            parsed = Allusion.parse(link[:url], link.except(:url))
            link = link.merge(parsed)
            link
          rescue => e
            nil
          end
        end
      end

      def raw_links
        @raw_links ||= doc.xpath("//a | //script | //img | //link")
      end

      def links
        @links ||= begin
          links = []
          raw_links.each do |node|
            value = get_node_link_value(node)
            next if value.to_s.length == 0 || skip_starts_with.include?(value.chars[0])

            hsh = {
              href: value,
              url:  Utils::Url.absolutize(url, value)
            }

            link_attributes = node.attributes.slice(*link_attributes)
            link_attributes.each do |key, attr|
              hsh[key.to_sym] = attr.value
            end

            links << hsh
          end
          links
        end
      end

      def get_node_link_value(node)
        if href_names.include?(node.name)
          node[:href]
        elsif src_names.include?(node.name)
          node[:src]
        end
      end

      def href_names
        @href_names ||= %w[a link].freeze
      end

      def src_names
        @src_names ||= %w[script image].freeze
      end

      def link_attributes
        @link_attributes ||= %w[title rel class id alt].freeze
      end

      def skip_starts_with
        %w[#]
      end
    end
  end
end
