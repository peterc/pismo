module Pismo
  module Parsers
    class SocialNetworks < Base

      def call
        social_networks
      end

      def links
        @links ||= args.dig(:links)
      end

      def allusion_profiles
        @allusion_profiles ||= begin
        end
      end
    end
  end
end
