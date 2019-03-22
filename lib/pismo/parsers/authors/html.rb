require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authors
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
          '.profile',
          '.auth a',
          '.auth',
          ['meta[@name="byl"]', lambda { |el| el.attr('content') }],
          '.timestamp a',
          '.fn a',
          '.fn',
          '.byline-author',
          '.ArticleAuthor a',
          '.blog_meta a',
          'cite a',
          'cite',
          '.contributor_details h4 a',
          '.meta a'
        ]

        def call
          authors
        rescue => e
          nil
        end

        def matches
          @matches ||= begin
            doc.match(AUTHOR_MATCHES).map do |nokogiri_shingle|
              handle_shingle(nokogiri_shingle)
            end.compact.uniq
          end
        end

        def match_nodes
          @match_nodes ||= begin
            match_nodes = []
            matches.each do |name|
              contains_text?(name).each do |node|
                match_nodes << { name: name, node: node }
              end
            end
            match_nodes
          end
        end

        def profiles
          @profiles ||= begin
            match_nodes.map { |node| convert_to_profile(node) }
          end
        end

        def convert_to_profile(match_node)
          unless match_node[:node].name == 'script' || match_node[:node].name == 'meta'
            convert_html_to_profile(match_node)
          end
        end

        def convert_html_to_profile(match_node)
          name = match_node[:name]
          node = match_node[:node]
          grandparent_node = node.parent.parent
          profile_link     = profile_links_from_node(grandparent_node)&.first
          return nil if profile_link.nil?
          profile_image    = images_from_node(grandparent_node)&.first
          hsh = {
            name:   name,
            url:    profile_link[:url],
            type:   profile_link[:identifier],
            image:  profile_image,
            source: :html
          }
          hsh[:type] = 'author/profile' if hsh[:type] == 'web/page'
          hsh
        end

        def profile_links_from_node(node)
          node.css('a')
              .map { |x| x['href'] }
              .uniq
              .delete_if(&:nil?)
              .map { |link| Allusion.parse(link) }
              .select do |parsed_link|
                parsed_link[:profile] == true ||
                  author_link_indicators.any? { |indicator| parsed_link[:url].to_s.include?(indicator) }
              end
        end

        def images_from_node(node)
          node.css('img')
              .map { |x| x['src'] }
        end

        def author_link_indicators
          %w[ profile author writer creator contributor ]
        end

        def authors
          @authors ||= profiles
        end

        def handle_shingle(nokogiri_shingle)
          case nokogiri_shingle
          when String
            cleanup_author_name(nokogiri_shingle)
          when Array
            nokogiri_shingle.map! { |a| cleanup_author_name(a) }.uniq!
          else
            puts "%s is a %s" % [nokogiri_shingle, nokogiri_shingle.class]
            nil
          end
        end

        def cleanup_author_name(author)
          author.sub!(/^(post(ed)?\s)?by\W+/i, '')
          author.tr!('^a-zA-Z 0-9\'', '|')
          author = author.split(/\|{2,}/).first.to_s
          author.gsub!(/\s+/, ' ')
          author.gsub!(/\|/, '')
          author.strip!
          author
        end

        # returns innermost nodes containing profile
        def contains_text?(txt)
          doc.xpath("//*[contains(text(), '#{txt}')]")
        end
      end
    end
  end
end
