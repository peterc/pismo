module Pismo
  module Utils
    class SearchForAdditionalProfiles
      attr_reader :args

      class << self
        def call(*args)
          new(*args).call
        end
      end

      def initialize(args = {})
        @args = args
      end

      def call
        profiles
      end

      def matching_name
        @matching_name ||= begin
          candidate_names = original_profiles.map do |profile|
            get_url_candidate(profile)
          end
          select_most_common_candidate(candidate_names)
        end
      end

      def profiles
        @profiles ||= begin
          profiles = original_profiles.dup
          return profiles if only_publisher_profile?(profiles)
          return profiles if matching_name.blank?

          converted_selected_social_profiles.each do |profile|
            next if profile.nil?
            next if profiles_include_url?(profiles, profile[:url])
            next if profile_type_present?(profiles, profile[:type])

            profiles << profile
          end
          profiles
        end
      end

      def only_publisher_profile?(check_profiles)
        profile_types = check_profiles.map { |profile| profile[:type] }.uniq
        profile_types.length == 1 && profile_types.first == 'publisher/profile'
      end

      def profiles_include_url?(check_profiles, url)
        check_profiles.any? { |candidate| candidate[:url] == url }
      end

      def profile_type_present?(check_profiles, type)
        check_profiles.any? { |candidate| candidate[:type] == type }
      end

      def original_profiles
        @original_profiles ||= args.dig(:profiles)
      end

      def url
        @url ||= args.dig(:url)
      end

      def doc
        @doc ||= args.dig(:doc)
      end

      def social_profiles
        @social_profiles ||= args.dig(:social_profiles)
      end

      def converted_selected_social_profiles
        @converted_selected_social_profiles ||= begin
          titleized_name = matching_name.titleize
          selected_social_profiles.map do |profile|
            profile[:url] = profile[:url].gsub(/\/$/, '')
            {
              name:  titleized_name,
              url:   profile[:url],
              type:  profile[:identifier],
              image: nil,
              from:  :on_page
            }
          end
        end
      end

      def selected_social_profiles
        @selected_social_profiles ||= begin
          return [] if matching_name.blank?

          social_profiles.select do |profile|
            profile[:url].include?(matching_name)
          end
        end
      end

      def get_url_candidate(profile_link)
        return nil if profile_link[:url].nil?

        url_candidate = profile_link[:url].gsub(/\/$/, '')
        candidate = url_candidate.split('/').last
        candidate = candidate.gsub(/^@/, '')
        candidate
      end

      def select_most_common_candidate(candidates)
        candidates = candidates.delete_if { |candidate| candidate.nil? }
        return nil if candidates.length == 0

        counter = Hash.new(0).tap { |h| candidates.each { |candidate| h[candidate.downcase] += 1 } }
        counter = counter.sort_by { |k,v| - v }
        counter&.first&.first
      end
    end
  end
end
