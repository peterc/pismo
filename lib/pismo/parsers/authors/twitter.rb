require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authors
      class Twitter < Parsers::Base
        def call
          twitter_profile if profile_url
        end

        def twitter_profile
          {
            name:  twitter_creator,
            type:  identifier,
            url:   profile_url,
            image: nil,
            from:  'meta_twitter'
          }
        end

        def twitter_creator
          @twitter_creator ||= meta.dig('name', 'twitter:creator')&.first
        end

        def filtered_twitter_creator
          @filtered_twitter_creator ||= twitter_creator.to_s.gsub('@', '')
        end

        def profile_url
          @profile_url ||= Allusion::Generator.from_profile_id("twitter/profile:#{filtered_twitter_creator}") if filtered_twitter_creator
        end

        def identifier
          'twitter/profile'
        end
      end
    end
  end
end
