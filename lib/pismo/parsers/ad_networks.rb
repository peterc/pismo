require 'pismo/parsers/base'

module Pismo
  module Parsers
    class AdNetworks < Base
      def call
        matched_networks
      end

      def matched_networks
        @matched_networks ||= AdChecker.call(urls: check_links).uniq
      end

      def check_links
        @check_links ||= links.map { |link| link[:href] }
      end
    end
  end
end
