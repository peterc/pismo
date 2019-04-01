require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Url < Parsers::Base

        def call
          profile if url && profile
        end

        def parsed
          @parsed ||= Allusion.parse(url)
        end

        def profile_id
          @profile_id ||= parsed.dig(:profile_id)
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
