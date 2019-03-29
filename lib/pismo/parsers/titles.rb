require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Titles < Base
      def call
        titles
      end

      # in order of likely accuracy: og:title, html_title, document matches
      def titles
        @titles ||= [og_title, html_title, @doc.match(title_matches)]
                    .flatten.reject { |s| s.nil? || s == '' }.uniq
      end

      # Returns the title of the page/content
      def title
        @title ||= Utilities.longest_common_substring_in_array(titles) || titles.first
      end

      # title from OG tags, if any
      def og_title
        begin
          meta = doc.css("meta[property~='og:title']")
          meta.each do |item|
            next if item['content'].empty?

            return item['content']
          end
        rescue => e
          Pismo.logger.warn "WARN: getting OG tag: #{$!} #{e.message}"
        end
        nil
      end

      # HTML title
      def html_title
        @html_title ||= begin
          if title = @doc.match('title').first
            strip_site_name_and_separators_from(title)
          end
        end
      end

      def strip_site_name_and_separators_from(title)
        parts = title.split(title_separators_regex)
        longest = parts.max_by(&:length)
        longest
      end

      def entities
        @entities ||= extract_entities_with_indices(text)
      end

      def title_separators_regex
        /\s(\p{Pd}|\:|\p{Pf}|\||\:\:|\.)\s/
      end

      # Google Code style - #pname a
      # Blogger/Blogspot - entry-title a
      # Slashdot - a.datitle
      # COmmon - .entry h2
      # BBC news - .mxb h1
      def title_matches
        [ '#pname a', '.entryheader h1', '.entry-title a', '.post-title a',
          '.post_title a', '.posttitle a', '.post-header h1', '.entry-title',
          '.post-title', '.post h1', '.post h3 a', 'a.datitle', '.posttitle',
          '.post_title', '.pageTitle', '#main h1.title', '.title h1',
          '.post h2', 'h2.title', '.entry h2 a', '.entry h2', '.boite_titre a',
          ['meta[@name="title"]', lambda { |el| el.attr('content') }],
          'h1.headermain', 'h1.title', '.mxb h1', '#content h1', '#content h2',
          '#content h3', 'a[@rel="bookmark"]', '.products h2',  '.caption h3',
          '#main h2', '#body h1', '#wrapper h1', '#page h1','.asset-header h1',
          '#body_content h2'
        ]
      end
    end
  end
end
