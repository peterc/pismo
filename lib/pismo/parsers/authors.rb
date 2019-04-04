require 'pismo/parsers/base'

module Pismo
  module Parsers
    class Authors < Base
      def call
        log_profiles(profiles)
        profiles
      end

      def profiles
        @profiles ||= Utils::SearchForAdditionalProfiles.call(profiles: found_profiles, url: url, doc: doc, sentences: sentences, social_profiles: social_profiles)
      end

      def log_profiles(profiles)
        profile_counts = profiles.each_with_object(Hash.new(0)) { |hsh, track| track[hsh[:type].downcase.gsub('/', '_')] += 1 }
        profile_counts.each do |key, value|
          Pismo.tracker.count "parsers.authors.results.#{key}", value
        end
      end

      def found_profiles
        @found_profiles ||= begin
          found_profiles, helpers = extract_helper_data(author_items)
          if found_profiles.length == 0
            Pismo.tracker.count('parsers.authors.no_authors_found')
            found_profiles << default_publisher_profile(helpers)
          end
          found_profiles
        end
      end

      # When we get enough data to help, but not enough to build a profile,
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
          type:       'publisher/profile',
          name:        name_from_host,
          source_url:  url,
          username:    host,
          id:          "publisher/profile:#{host}",
          from:        :default
        }
        hsh = merge_jsonld_publisher_info(hsh)
        helpers.each do |helper|
          hsh = hsh.merge(helper.except(:type))
        end
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
          arr << schema_author
          arr = arr.flatten.compact.uniq
          arr
        end
      end

      def meta_author
        @meta_author ||= Parsers::Authorship::Meta.call(url: url, meta: meta, doc: doc)
      end

      def html_author_helper
        @html_author_helper ||= Parsers::Authorship::Html.call(url: url, doc: doc, use_slow: args[:use_slow], use_fast: args[:use_fast])
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

      def schema_author
        @schema_author ||= Parsers::Authorship::Schema.call(url: url, doc: doc)
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
