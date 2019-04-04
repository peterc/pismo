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
            binding.pry
            nil
          end
        end
      end

      def links
        @links ||= begin
          raw_links = []
          doc.css('a').each do |node|
            if node[:href].present?
              next if skip_starts_with.include?(node[:href].chars[0])

              hsh = {
                href: node[:href],
                url:  Utils::Url.absolutize(url, node[:href])
              }

              link_attributes.each do |attr|
                hsh[attr.to_sym] = node.attr(attr)
              end

              raw_links << hsh
            end
          end
          raw_links
        end
      end

      def link_attributes
        %w[title rel class id alt].freeze
      end

      def skip_starts_with
        %w[#]
      end
    end
  end
end
