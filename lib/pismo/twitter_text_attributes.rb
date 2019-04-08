module Pismo
  module TwitterTextAttributes
    def twitter_entities
      @twitter_entities ||= twitter_text_helper.twitter_entities
    end

    def hashtags
      @hashtags ||= twitter_text_helper.twitter_hashtags
    end

    def cashtags
      @cashtags ||= twitter_text_helper.twitter_cashtags
    end

    def emoji
      @emoji ||= twitter_text_helper.twitter_emoji
    end

    def mentions
      @mentions ||= twitter_text_helper.twitter_mentions
    end

    def twitter_text_helper
      @twitter_text_helper ||= :Pismo::Parsers::TwitterText.new(text: text)
    end
  end
end
