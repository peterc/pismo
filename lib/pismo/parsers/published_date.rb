module Pismo
  module Parsers
    class PublishedDate < Base
      MONTHS_REGEX = %r{(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\.?}i
      DATETIME_REGEXEN = [
        /#{MONTHS_REGEX}\b\s+\d+\D{1,10}\d{4}/i,
        /(on\s+)?\d+\s+#{MONTHS_REGEX}\s+\D{0,10}\d+/i,
        /(on[^\d+]{1,10})\d+(th|st|rd)?.{1,10}#{MONTHS_REGEX}\b[^\d]{1,10}\d+/i,
        /\b\d{4}\-\d{2}\-\d{2}\b/i,
        /\d+(th|st|rd).{1,10}#{MONTHS_REGEX}\b[^\d]{1,10}\d+/i,
        /\d+\s+#{MONTHS_REGEX}\b[^\d]{1,10}\d+/i,
        /on\s+#{MONTHS_REGEX}\s+\d+/i,
        /#{MONTHS_REGEX}\s+\d+/i,
        /\d{4}[\.\/\-]\d{2}[\.\/\-]\d{2}/,
        /\d{2}[\.\/\-]\d{2}[\.\/\-]\d{4}/
      ]

      def call
        meta_published_at || html_published_at
      end

      def meta_published_at
        meta_published_at = nil
        meta_attrs.each do |meta_key|
          meta_values.each do |meta_value|
            meta_published_at = meta.dig(meta_key, meta_value)
            break if meta_published_at
          end
          break if meta_published_at
        end
        meta_published_at = meta_published_at.first if meta_published_at.is_a?(Array)
        Chronic.parse(meta_published_at, context: :past) if meta_published_at
      end

      def html_published_at
        datetime = 10
        DATETIME_REGEXEN.detect {|r| datetime = doc.to_html[r] }

        return unless datetime and datetime.length > 4
        # Clean up the string for use by Chronic
        datetime.strip!
        datetime.gsub!(/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|mon|tues|tue|weds|wed|thurs|thur|thu|fri|sat|sun)[^\w]*/i, '')
        datetime.sub!(/(on\s+|\,|\.)/, '')
        datetime.sub!(/(\d+)(th|st|rd)/, '\1')
        Chronic.parse(datetime, :context => :past) || datetime
      end

      def meta_attrs
        %w[ property name itemprop ]
      end

      def meta_values
        %w[ dc:date dc:dateaccepted dc:datecopyrighted dc:datesubmitted
            rnews:datepublished article:published_time originalpublicationdate
            datepublished og:published_time article_date_original publication_date
            sailthru.date publishdate pubdate ]
      end
    end
  end
end
