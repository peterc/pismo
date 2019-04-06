require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Url < Parsers::Base

        def call
          author if url && profile? && profile_url
        end

        def author
          if profile
            {
              url:   profile_url,
              name:  name,
              image: nil,
              from:  :url,
              type:  type
            }
          end
        end

        def parsed
          @parsed ||= Allusion.parse(url)
        end

        def profile?
          url && parsed&.dig(:profile) == true
        end

        def profile_id
          @profile_id ||= parsed.dig(:profile_id)
        end

        def name
          @name ||= parsed.dig(:username)
        end

        def type
          @type ||= parsed.dig(:identifier)
        end

        def profile_url
          @profile_url ||= Allusion::Generator.from_profile_id(profile_id) if profile_id
        end

        def profile
          @profile ||= Allusion.parse(profile_url) if profile_url
        end
      end
    end
  end
end
