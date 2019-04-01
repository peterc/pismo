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
          ['meta[@name="author"]', lambda { |el| el.attr('content') }],     # Traditional meta tag style
          ['meta[@name="Author"]', lambda { |el| el.attr('content') }],     # CNN style
          ['meta[@name="AUTHOR"]', lambda { |el| el.attr('content') }],     # CNN style
          ['meta[@name="pinterestapp:pinner"]', lambda { |el| el.attr('content') }],  # pinterest author
          '.byline a',                                                      # Ruby Inside style
          '.byline',
          '.node-byline',                                                   # FastCompany
          '.post_subheader_left a',                                         # TechCrunch style
          '.byl',                                                           # BBC News style
          '.articledata .author a',
          '#owners a',                                                      # Google Code style
          '.author a',
          '.author',
          ['a[@rel="author"]'],
          '.creator',
          '.writer',
          '.organizer',
          ".info a[@class='name']",
          '[@class*="organizer"]',
          '.profile',
          '.Profile',
          '.auth a',
          '.auth',
          '.author-info',
          '.Post__author',
          ['meta[@name="byline"]',          lambda { |el| el.attr('content') }],
          ['meta[@name="dc.creator"]',      lambda { |el| el.attr('content') }],
          ['meta[@name="byl"]',             lambda { |el| el.attr('content') }],
          ['meta[@rel="author"]',           lambda { |el| el.attr('content') }],
          ['meta[@rel="byline"]',           lambda { |el| el.attr('content') }],
          ['meta[@rel="dc.creator"]',       lambda { |el| el.attr('content') }],
          ['meta[@rel="byl"]',              lambda { |el| el.attr('content') }],
          ['meta[@itemprop="author"]',      lambda { |el| el.attr('content') }],
          ['meta[@itemprop="byline"]',      lambda { |el| el.attr('content') }],
          ['meta[@itemprop="dc.creator"]',  lambda { |el| el.attr('content') }],
          ['meta[@itemprop="byl"]',         lambda { |el| el.attr('content') }],
          '.timestamp a',
          '.fn a',
          '.fn',
          '.byline-author',
          '.userinfo',
          '.byline-item',
          '.poster a',
          '.entry-author',
          '.ArticleAuthor a',
          'a[@class*="username"]',
          '.avatar',
          '.avatarHolder',
          '.blog_meta a',
          'cite a',
          'cite',
          'span[property*="dc:created"] .name',
          '.contributor_details h4 a',
          '.meta a',
          ['link[@rel*="author"]'],
          ['a[@href*="author"]'],
          'p[@class*="author"]',
          'a[@title*="profile"]',
          'a[@title*="author"]',
          '#authorinfo',
          '.authorinfo',
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
