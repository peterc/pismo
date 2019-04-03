module Pismo
  module Utils
    class NodesToProfiles
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

      # Takes the matching Nokogiri Nodes and removes ones where the
      # root nodes contain a child node that is one of the root nodes
      # essentailly, we have a "grandparent or parent" node in the root
      # and we need to remove it.
      def filtered_matches
        @filtered_matches ||= begin
          filtered_matches = []
          matches.each do |node|
            filtered_matches << node unless descendents_in_root?(node)
          end
          filtered_matches
        end
      end

      #  CHecks if the other nodes listed here are also in the root.
      # if so, we want to aremove them.
      def descendents_in_root?(node)
        check_ids = node_descendants_pointer_ids(node)
        return false if check_ids.length == 0

        (matches_pointer_ids & check_ids).length > 0
      end

      def node_descendants_pointer_ids(node)
        return [] if node.nil?

        node_ids = []
        # node_ids << node.pointer_id
        node.children.each do |child|
          node_ids << child.pointer_id
          child.children.each do |grandchild|
            node_ids << grandchild.pointer_id
            grandchild.children.each do |great_grandchild|
              node_ids << great_grandchild.pointer_id
            end
          end
        end
        node_ids
      end

      def matches_pointer_ids
        @matches_pointer_ids ||= matches.map { |node| node.pointer_id }
      end

      def profiles
        @profiles ||= begin
          profiles = []
          filtered_matches.each do |match|
            profile = handle_match(match)
            profiles << profile if profile
          end
          profiles
        end
      end

      # As we add additional extraction strategies, we can add them
      # here. (Text extraction strategy)
      def handle_match(node)
        handle_with_parsing_strategy(node)
      end

      def handle_with_parsing_strategy(node)
        grandparent_node = get_grandparent_node(node)
        return nil if grandparent_node.nil?

        profile_link = profile_links_from_node(grandparent_node)&.first
        return nil if profile_link.nil? || processed_profile_links.include?(profile_link[:url])

        processed_profile_links << profile_link[:url]
        name          = get_link_node_name(node)
        profile_image = images_from_node(grandparent_node)&.first

        hsh = {
          name:   name,
          url:    profile_link[:url],
          type:   profile_link[:identifier],
          image:  profile_image,
          from:  :html,
          line:  node.line
        }
        hsh
      end

      def profile_links_from_node(node)
        links = build_parsed_links_list_from_node(node)
        links = links.select { |link| valid_profile_link?(link) }
        links = links.map do |link|
          link[:identifier] = 'author/profile' if link[:identifier].nil? || link[:identifier] == 'web/page'
          link
        end
        links
      end

      def valid_profile_link?(hsh)
        hsh.dig(:profile) == true || candidate_profile_link_hash_has_indicator?(hsh)
      end

      def candidate_profile_link_hash_has_indicator?(hsh)
        Utils::Indicators.css_search_locations.any? do |location|
          text = hsh.dig(location.to_sym)&.to_s&.strip
          if text.nil? || text.blank?
            false
          else
            Utils::Indicators.author_links.any? do |indicator|
              text.include?(indicator)
            end
          end
        end
      end

      def build_links_list_from_node(node)
        links = []
        links = node.css('a').map do |link_node|
          hsh = {
            url:  Utils::Url.absolutize(url, link_node.attr('href')),
            rel:   link_node.attr('rel'),
            title: link_node.attr('title'),
            class: link_node.attr('class'),
            id:    link_node.attr('id')
          }
        end
        links = links.uniq { |hsh| hsh[:url] }
        links
      end

      def build_parsed_links_list_from_node(node)
        links = build_links_list_from_node(node)
        links = links.map do |hsh|
          hsh.merge(Allusion.parse(hsh[:url]))
        end
        links
      end

      def images_from_node(node)
        node.css('img')
            .map { |link| link['src'] }
            .delete_if { |link| link.include?('data:image') }
            .map { |link| Utils::Url.absolutize(url, link) }
      end

      def matches
        @matches ||= args.dig(:matches)
      end

      def url
        @url ||= args.dig(:url)
      end

      def doc
        @doc ||= args.dig(:doc)
      end

      def get_grandparent_node(node)
        grandparent_node = node
        begin
          4.times do
            before_node = grandparent_node
            grandparent_node = grandparent_node.parent if node_is_not_a_sectional_type?(grandparent_node.parent) || css_include_author_indicators?(grandparent_node.parent)
            if node_is_a_sectional_type?(grandparent_node) || css_include_sectional_indicators?(grandparent_node)
              grandparent_node = before_node
              break
            end
            break if break_css_attributes?(node)
            break if before_node == grandparent_node
          end
          if grandparent_node == node   # then do it only one time
            grandparent_node = grandparent_node.parent if node_is_not_a_sectional_type?(grandparent_node.parent) || css_include_author_indicators?(grandparent_node.parent)
          end
        end
        grandparent_node
      end

      def node_is_a_sectional_type?(node)
        Utils::Indicators.sectional.include?(node.name) || css_include_sectional_indicators?(node)
      end

      def break_css_attributes?(node)
        Utils::Indicators.sectional_css.any? do |indicator|
          Utils::Indicators.css_search_locations.any? do |location|
            node.attr(location).to_s.include?(indicator)
          end
        end
      end

      def node_is_not_a_sectional_type?(node)
        !Utils::Indicators.sectional.include?(node.name)
      end

      def css_include_author_indicators?(node)
        Utils::Indicators.author_links.any? do |indicator|
          Utils::Indicators.link_search_locations.any? do |location|
            node.attr(location).to_s.include?(indicator)
          end
        end
      end

      def css_include_sectional_indicators?(node)
        Utils::Indicators.sectional_css.any? do |indicator|
          Utils::Indicators.css_search_locations.any? do |location|
            node.attr(location).to_s.include?(indicator)
          end
        end
      end

      def cleanup_author_name(author)
        return author if author.blank?
        author.sub!(/^(post(ed)?\s)?by\W+/i, '')
        author.tr!('^a-zA-Z 0-9\'', '|')
        author = author.split(/\|{2,}/).first.to_s
        author.gsub!(/\s+/, ' ')
        author.gsub!(/\|/, '')
        author.strip!
        author.titleize
      end

      def get_link_node_name(node)
        name = extract_name_from_node_using_entities(node)   if name.blank?
        name = extract_name_from_node_image(node)            if name.blank?
        name = extract_name_from_node_using_regex_scan(node) if name.blank?
        name = extract_name_from_node_text(node)             if name.blank?
        # name = nil unless Utilities.looks_like_a_name?(name)
        name
      end

      def extract_name_from_node_using_entities(node)
        name = node.text.strip
        name = Utilities.extract_likely_name(name)
        name
      end

      def extract_name_from_node_image(node)
        name = extract_name_from_node_image_alt(node)
        name = cleanup_author_name(name) if name.present?
        name
      end

      def extract_name_from_node_using_regex_scan(node)
        name = node.text.to_s.scan(Dewey::Data::Names.firstnames_regex).flatten.first
        name
      end

      def extract_name_from_node_text(node)
        node.text.to_s.strip.titleize
      end

      def extract_name_from_node_image_alt(node)
        name = nil
        if node.name == 'a' && node.css('img')&.length&.to_i > 0
          name = node&.css('img')&.first&.attr('alt')
          name = node&.css('img')&.first&.attr('title') if name.nil?
        end
        name
      end

      def processed_profile_links
        @processed_profile_links ||= []
      end
    end
  end
end
