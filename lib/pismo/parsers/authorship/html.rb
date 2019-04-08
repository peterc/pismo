require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Html < Base
        def call
          profiles
        rescue => e
          Pismo.logger.error "status=error message='#{e.message}' location='#{e.backtrace.first}' from=#{self.class.name}"
          nil
        end

        def author_candidates
          @author_candidates ||= get_compound_results
        end

        def matches
          @matches ||= begin
            matches = []
            author_candidates.each do |node|
              extract_a_link_node = get_a_node_profile_indicators(node)
              if extract_a_link_node.is_a?(Nokogiri::XML::Element)
                matches << node
              elsif extract_a_link_node.is_a?(Array)
                if extract_a_link_node.length > 0
                  extract_a_link_node.each { |extracted_node| matches << extracted_node }
                else
                  find_profile_nodes_that_match_entities_in_text(node).each do |match|
                    matches << match
                  end
                end
              end
            end
            matches
          end
        end

        def get_a_node_profile_indicators(node)
          if node.name == 'a'
            return node if any_a_node_profile_indicator?(node)
          else
            node.css('a').each do |link|
              return node if any_a_node_profile_indicator?(link)
            end
          end
        end

        def any_a_node_profile_indicator?(result)
          return false if result.attr('href').nil?  || result.attr('href') == '#'
          parsed = Allusion.parse(result['href'])
          if parsed[:profile] == true
            return true
          else
            Utils::Indicators.author_links.any? do |indicator|
              Utils::Indicators.link_search_locations.any? do |location|
                a_array = result.attr('href').to_s.split(/\//)
                result.attr(location).to_s.include?(indicator) && !a_array.any?{|path| Utils::Indicators.registration_locations.include?(path)}
              end
            end
          end
        end

        def profiles
          @profiles ||= Utils::NodesToProfiles.call(matches: matches, url: url, doc: doc)
        end
      end
    end
  end
end
