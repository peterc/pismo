require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Html < Base
        AUTHOR_MATCHES = [
          '.post-author .fn',
          '.wire_author',
          '.cnnByline b',
          '.editorlink',
          '.authors p',
          '.byline a',
          '.byline',
          '.node-byline',
          '.post_subheader_left a',
          '.byl',
          '.articledata .author a',
          '#owners a',
          '.author a',
          '.author',
          'a[@rel="author"]',
          '.creator',
          '.writer',
          '.profile a',
          '.organizer',
          ".info a[@class='name']",
          '[@class*="organizer"]',
          '.profile',
          '.Profile',
          '.profile_name a',
          '.auth a',
          '.auth',
          '.author-info',
          '.Post__author',
          '.timestamp a',
          '.fn a',
          '.fn',
          '.byline-author',
          '.fs-author-avatar',
          '.speakable-author',
          '.userinfo',
          '.byline-item',
          '.poster a',
          '.entry-author',
          '.ArticleAuthor a',
          'a[@class*="username"]',
          '.avatar',
          '.avatarHolder',
          '.blog_meta a',
          'a[@class*="username"]',
          'cite a',
          'cite',
          '[@data-type="author"]',
          'span[property*="dc:created"] .name',
          '.contributor_details h4 a',
          '.meta a',
          'link[@rel*="author"]',
          'a[@href*="author"]',
          'p[@class*="author"]',
          'a[@title*="profile"]',
          'a[@title*="author"]',
          '#authorinfo',
          '.authorinfo',
          'a.g-profile',
          '.content-calendar-item-poster-linked a',
          'a.author-url',
        ]

        def call
          profiles
        rescue => e
          Pismo.logger.error "status=error message='#{e.message}' location='#{e.backtrace.first}' from=#{self.class.name}"
          nil
        end

        def author_candidates
          @author_candidates ||= begin
            author_candidates = []
            fast_results = get_compound_results
            if fast_results.count > 10
              author_candidates = fast_results
            else
              AUTHOR_MATCHES.each do |match_query|
                nodes = doc.css(match_query)
                if nodes.is_a?(Nokogiri::XML::Element)
                  author_candidates << nodes
                elsif nodes.is_a?(Array) || nodes.is_a?(Nokogiri::XML::NodeSet)
                  nodes.each do |node|
                    author_candidates << node if node.is_a?(Nokogiri::XML::Element)
                  end
                end
              end
            end
            author_candidates = fast_results if author_candidates.count < fast_results.count
            author_candidates
          end
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
                  extract_a_link_node.each { |extracted_node| matches << node }
                else
                  # extracts entities from the text of the node, and tries to
                  # find a matching link that contiains the the name of the
                  # entity
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
            valid_a_nodes = []
            node.css('a').each do |link|
              valid_a_nodes << link if any_a_node_profile_indicator?(link)
            end
            if valid_a_nodes.length.zero? && node.css('a').count == 1
              valid_a_nodes << node.css('a').first
            end
            return valid_a_nodes
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
                result.attr(location).to_s.include?(indicator)
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
