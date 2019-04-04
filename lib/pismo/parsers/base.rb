module Pismo
  module Parsers
    class Base
      attr_reader :args

      class << self
        def call(*args)
          new(*args).call
        end
      end

      def initialize(args = {})
        @args = args
      end

      def text
        @text ||= args.dig(:text)
      end

      def doc
        @doc ||= args.dig(:doc)
      end

      def url
        @url ||= args.dig(:url)
      end

      def jsonld
        @jsonld ||= begin
          jsonld = args.dig(:jsonld)
          jsonld = args.dig(:jsonld_data) if jsonld.nil?
          jsonld = Parsers::Jsonld.call(doc: doc) if jsonld.nil? && doc.present?
          jsonld
        end
      end

      def host
        @host ||= Utils::Url.host(url)
      end

      def social_profiles
        @social_profiles ||= args.dig(:social_profiles)
      end

      def meta
        @meta ||= begin
          meta = args.dig(:meta)
          meta = Parsers::Meta.call(doc: doc) if meta.blank? && doc.present?
          meta
        end
      end

      def title
        @title ||= args.dig(:title)
      end

      def description
        @description ||= args.dig(:description)
      end

      def body
        @body ||= args.dig(:body)
      end

      def reader_doc
        @reader_doc ||= args.dig(:reader_doc)
      end

      def sentences
        @sentences ||= args.dig(:sentences)
      end

      def call
        raise 'must be implemented in your child class'
      end

      # Formats meta extracted information to the correct format
      def as_name_hash(name, key = 'profile_name')
        name = name.first if name.is_a?(Array)
        resp = { key => name }
        resp = nil if resp[key].nil?
        resp
      end

      def contains_text?(txt)
        doc.xpath("//*[contains(text(), '#{txt}')]")
      end

      def any_search_location_contains_text?(text, attr = '*')
        search_nodes = []
        %i[class id rel href title].uniq.each do |location|
          next if location == :href && !['a', 'link'].include?(attr)
          resp = attr_location_contains_text?(text, attr, location)
          resp.each { |node| search_nodes << node }
        end
        search_nodes.uniq
      end

      def text_search_location_contains_text?(text, attr = '*')
        search_nodes = []
        %i[title text alt].uniq.each do |location|
          next if location == :href && !['a', 'link'].include?(attr)
          resp = attr_location_contains_text?(text, attr, location)
          resp.each { |node| search_nodes << node }
        end
        search_nodes.uniq
      end

      def attr_location_contains_text?(txt, attr = '*', location = :text)
        location = location_map[location]
        doc.xpath("//#{attr}[
            contains(
              translate(#{location}, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
              '#{txt}'
            )
          ]"
        )
      end

      def location_map
        {
          'class' => '@class',
          :class  => '@class',
          'id'    => '@id',
          :id     => '@id',
          'rel'   => '@rel',
          :rel    => '@rel',
          :href   => '@href',
          'href'  => '@href',
          :text   => 'text()',
          'text'  => 'text()',
          :title  => '@title',
          'title' => '@title',
          :alt    => '@alt',
          'alt'   => '@alt'
        }
      end

      def default_search
        doc.xpath(compound_search_text.join(' | ')).select do |node|
          node.name == 'a' || node.css('a').length > 0
        end
      end

      def compound_search_text
        searches = []
        search_locations.each do |location|
          search_tag_types.each do |tag|
            search_identifiers.each do |text|
              searches << build_xpath_search(tag, location, text)
            end
          end
        end
        supplemental_matches.each { |search| searches << search }
        searches
      end

      def search_locations
        %w[@class @id @rel @href @title @alt @itemprop].freeze
      end

      def search_tag_types
        %w[a img div p span].freeze
      end

      def search_identifiers
        %w[author user profile member avatar creator writer byline shop owner organizer contributor].freeze
      end

      def supplemental_matches
        [
          '//*[@class="editorlink"]',
          '//*[@class="post_subheader_left"]/a',
          '//*[@class="byl"]',
          '//*[@class="info"]/a[@class="name"]',
          '//*[@class="auth"]/a',
          '//*[@class="timestamp"]',
          '//*[@class="fn"]',
          '//*[@class="poster"]/a',
          '//*[@class="blog_meta"]/a',
          '//cite/a',
          '//cite',
          '//span[@property="dc:created"]',
          '//*[@class="contributor_details"]/h4/a',
          '//*[@class="meta"]/a',
          '//*[@class="content-calendar-item-poster-linked"]/a'
        ]
      end

      def get_compound_results
        doc.xpath(compound_search_text.join(" | "))
      end

      def get_nodes_with_tag_attr_containing_text(tag_type, tag_attr, text)
        search_phrase = build_xpath_search(tag_type, tag_attr, text)
        doc.xpath(search_phrase)
      end

      def build_xpath_search(tag_type, tag_attr, text)
        "//#{tag_type}[contains(translate(#{tag_attr}, \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\", \"abcdefghijklmnopqrstuvwxyz\"), \"#{text}\")]"
      end

      def clean_node_text(node)
        node&.text.to_s.gsub(/\W/, ' ').squeeze(' ').strip
      end

      def find_profile_nodes_that_match_entities_in_text(node)
        node_text = clean_node_text(node)
        return [] if node_text.blank?

        find_nodes_matching_entity_text(node_text)
      end

      def find_nodes_matching_entity_text(text)
        nodes = []
        entity = Dewey::Extractor.entities(text)&.first
        if entity
          entity.split(' ').each do |text_item|
            contains_text?(text_item).each do |node|
              next if invalid_candidate_profile_node?(node)

              nodes << node
            end
          end
          nodes = nodes.uniq
        end
        nodes
      end

      def invalid_candidate_profile_node?(node)
        return true if node.name == 'script' || node.name == 'style'
        return true if !node.name == 'a'

        grandparent_node = get_grandparent_node(node)
        return true if grandparent_node.css('a').length.zero?

        false
      end

      def get_grandparent_node(node)
        Utils::NodesToProfiles.new(doc: doc).get_grandparent_node(node)
      end
    end
  end
end
