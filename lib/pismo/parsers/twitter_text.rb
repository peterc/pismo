require 'pismo/parsers/base'

module Pismo
  module Parsers
    class TwitterText < Base
      include Twitter::TwitterText::Extractor

      def twitter_entities
        @twitter_entities ||= extract_entities(text)
      end

      def twitter_mentions
        @twitter_mentions ||= extract_mentioned_screen_names(text)
      end

      def twitter_urls
        @twitter_urls ||= extract_urls(text)
      end

      def twitter_hashtags
        @twitter_hashtags ||= extract_hashtags(text)
      end

      def twitter_cashtags
        @twitter_cashtags ||= extract_cashtags(text)
      end

      def twitter_emoji
        @twitter_emoji ||= extract_emoji(text)
      end
    end
  end
end
