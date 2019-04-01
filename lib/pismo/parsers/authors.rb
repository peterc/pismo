require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Authors < Base
      def call
        profiles
      end

      def profiles
        @profiles ||= begin
          profiles, helpers = extract_helper_data(author_items)
          profiles << default_publisher_profile(helpers) if profiles.length == 0
          profiles
        end
      end

      # when we get enough data to help, but not enough to build a profile,
      # its passed as help_data type. We extract these into a separate
      # array that we pass to the default publisher profile, to add it there.
      def extract_helper_data(potential_profiles)
        profile_data = []
        helper_data = []
        potential_profiles.each do |result|
          if result[:type] == 'help_data'
            helper_data << result
          else
            profile_data << result
          end
        end
        return profile_data, helper_data
      end

      def default_publisher_profile(helpers = [])
        hsh = {
          service:    'publisher/profile',
          identifier: 'publisher/profile',
          type:       'Company',
          name:       name_from_host,
          source_url:  url,
          username:   host,
          id:         "publisher/profile:#{host}",
          known:      false,
          profile:    true
        }
        helpers.each do |helper|
          hsh = hsh.merge(helper.except(:type))
        end
        hsh = merge_jsonld_publisher_info(hsh)
        hsh
      end

      def jsonld_present?
        jsonld && jsonld.keys.length > 0
      end

      def jsonld_publisher_present?
        jsonld_present? && jsonld.dig(:publisher).present? && jsonld.dig(:publisher).keys.length > 0
      end

      def merge_jsonld_publisher_info(hsh)
        if jsonld_publisher_present?
          jsonld.dig(:publisher).each do |key, value|
            hsh[key] = value if value.present?
          end
        end
        hsh
      end

      def name_from_host
        PublicSuffix.parse(host)&.sld&.titleize
      end

      def author_items
        @author_items ||= begin
          arr = []
          arr << html_author
          arr << meta_author
          arr << twitter_author
          arr << pinterest_author
          arr << reddit_author
          arr << url_author
          arr << jsonld_author
          arr = arr.delete_if { |profile| profile.nil? }
          arr
        end
      end

      def meta_author
        @meta_author ||= Parsers::Authorship::Meta.call(url: url, meta: meta, doc: doc)
      end

      def html_author_helper
        @html_author_helper ||= Parsers::Authorship::Html.call(url: url, doc: doc)
      end

      def html_author
        @html_author ||= html_author_helper&.dup&.shift
      end

      def additional_html_profiles
        @additional_html_profiles ||= begin
          additionals = html_author_helper&.dup
          additionals&.shift
          Array(additionals)
        end
      end

      def host
        @host ||= Utils::Url.host(url)
      end

      def jsonld
        @jsonld ||= args.dig(:jsonld)
      end

      def jsonld_author
        @jsonld_author ||= Parsers::Authorship::JsonldAuthor.call(url: url, doc: doc, jsonld_data: jsonld)
      end

      def twitter_author
        @twitter_author ||= Parsers::Authorship::Twitter.call(url: url, meta: meta)
      end

      def pinterest_author
        @pinterest_author ||= Parsers::Authorship::Pinterest.call(url: url, meta: meta)
      end

      def reddit_author
        @reddit_author ||= Parsers::Authorship::Reddit.call(url: url, meta: meta, doc: doc)
      end

      def url_author
        @url_author ||= Parsers::Authorship::Url.call(url: url)
      end
    end
  end
end
