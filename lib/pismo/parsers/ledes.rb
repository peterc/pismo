require 'pismo/parsers/base'

module Pismo
  module Parsers
    # Lede(s) are the lead of teh story, or the first paragraph of the story/page
    class Ledes < Base
      def call
        ledes
      end

      def lede_extractor
        /^(.*?[\.\!\?]\s){1,3}/m
      end

      def ledes
        @ledes ||= begin
          matches = doc.match(lede_matches).map do |lede|
            case lede
            when String
              (lede[lede_extractor] || lede).to_s.strip
            when Array
              lede.map { |l| l.to_s[lede_extrator].strip || l }.uniq
            end
          end

          if matches.empty? && reader_doc && reader_doc.sentences(4).length > 3
            matches.push(reader_doc.sentences(4).join(' '))
          end

          matches.uniq
        end
      end

      def lede_matches
        ['.post-text p', '#blogpost p', '.story-teaser', '.article .body p',
          '//div[@class="entrytext"]//p[string-length()>40]',
          'section p:not(.advertisement,.advertisement_river)',
          '.entry .text p', '.hentry .content p', '.entry-content p',
          '#wikicontent p', '.wikistyle p',
          '//td[@class="storybody"]/p[string-length()>40]',
          '//div[@class="entry"]//p[string-length()>100]',
          ['.entry-content', lambda { |el| el.inner_html[/(#{el.inner_text[0..4].strip}.*?)\<br/, 1] }],
          ['.entry', lambda { |el| el.inner_html[/(#{el.inner_text[0..4].strip}.*?)\<br/, 1] }],
          '.entry',
          '#content p:not(.advertisement,.advertisement_river)',
          '#article p', '.post-body', '.entry-content',
          '.document_description_short p', '.single-post p']
      end
    end
  end
end
