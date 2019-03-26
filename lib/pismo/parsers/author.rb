require 'pismo/parsers/base'
require 'pismo/parsers/jsonld'
require 'pismo/parsers/authors/twitter'
require 'pismo/parsers/authors/html'

module Pismo
  module Parsers
    class Author < Base
      def call
        if doc.html?
          author_hash = {}
          if author_items.length.positive?
            author_items.each do |hsh|
              next if hsh.blank?   # use blank?  because   {}.nil? => false
              next unless hash_has_valid_identifier?(hsh)
              hsh = add_profile_name(hsh) if jsonld_author
              hsh = ensure_profile_url(hsh)
              author_hash[get_profile_identifier(hsh)] = hsh
            end
          end
          author_hash['publisher/profile'] = default_site_profile if author_hash.keys.length.zero?
          author_hash
        end
      end

      def author_items
        @author_items ||= begin
          arr = []
          arr << meta_author
          arr << twitter_author
          arr << pinterest_author
          arr << reddit_author
          arr << allusion_parsed_author
          arr << html_author
          arr.flatten.uniq.compact
        end
      end

      def hash_has_valid_identifier?(hsh)
        profile_service_keys.include?(hsh['identifier']) || profile_service_keys.include?(hsh['service'])
      end

      def profile_service_keys
        @profile_service_keys ||= ::Allusion::Generator.profile_service_keys
      end

      def add_profile_name(hsh)
        return hsh if hsh['profile_name'].present?
        hsh = hsh.merge(jsonld_author)        if jsonld_author && looks_like_a_name?(jsonld_author['profile_name'])
        hsh['profile_name'] = hsh['username'] if hsh['profile_name'].nil? && hsh['username'] && looks_like_a_name?(hsh['username'])
        hsh['profile_name'] = hsh['user_id']  if hsh['profile_name'].nil? && hsh['user_id'] && looks_like_a_name?(hsh['user_id'])
        hsh
      end

      def looks_like_a_name?(text)
        text.to_s.match(last_names_regex) || text.match(first_names_regex)
      end

      def last_names_regex
        @last_names_regex ||= Dewey::Data::Names.lastnames_regex
      end

      def first_names_regex
        @first_names_regex ||= Dewey::Data::Names.firstnames_regex
      end

      def ensure_profile_url(hsh)
        return hsh if hsh['profile_url'].present?
        hsh['profile_url'] = hsh['url'] if hsh['url'] && !hsh['profile_url']
        hsh['profile_url'] = hsh['uri'] if hsh['uri'] && !hsh['profile_url']
        hsh
      end

      # Defines the site profile for the domain. If we can't find an author,
      # we give "credit" to the publishing website for the article.
      def default_site_profile
        @default_site_profile ||= begin
          return nil if host.nil?
          dsp = {
              'service'    => 'publisher/profile',
              'profile_id' => "publisher/profile:#{host}",
              'type'       => 'Company',
              'username'   => "#{host}",
              'identifier' => 'publisher/profile',
              'id'         => "publisher/profile:#{host}"
          }
          dsp = dsp.merge(jsonld_publisher) unless jsonld_publisher.blank?
          dsp
        end
      end

      def host
        @host ||= URI.parse(url).host if url.present?
      end

      # If there is a plain meta/author this extracts it
      def meta_author
        @meta_author ||= Parsers::Authors::MetaAuthor.call(doc: doc)
      end

      def twitter_author
        @twitter_author ||= Parsers::Authors::Twitter.call(meta: meta)
      end

      def pinterest_author
        @pinterest_author ||= as_name_hash(meta['pinterestapp:pinner'])
      end

      # If there is a reddit author, we add that here
      def reddit_author
        @reddit_author ||= begin
          name = doc.css('.top-matter .author').map { |x| x&.text }
          as_name_hash(name)
        end
      end

      def allusion_parsed_author
        @allusion_parsed_author ||= begin
          if url
            parsed = Allusion.parse(url)
            profile_id = parsed&.dig(:profile_id)
            profile_url = Allusion::Generator.from_profile_id(profile_id) if profile_id
            allusion_parsed_profile = Allusion.parse(profile_url) if profile_url
            if allusion_parsed_profile
              allusion_parsed_author = allusion_parsed_profile.stringify_keys
            else
              allusion_parsed_author = parsed.stringify_keys if parsed
            end
            allusion_parsed_author
          end
        end
      end

      def html_author
        @html_author ||= Parsers::Authors::Html.call(doc: doc)
      end

      def jsonld_author
        @jsonld_author ||= Parsers::Jsonld.call(doc: doc).dig(:author)
      end

      def jsonld_publisher
        @json_ld_publisher ||= begin
          hsh = {}
          return hsh unless jsonld_author.is_a?(Hash) && jsonld_author.key?('publisher')
          hsh['profile_name']      = jsonld_author.dig('publisher', 'name')
          hsh['profile_type']      = jsonld_author.dig('publisher', '@type')
          hsh['profile_image_url'] = jsonld_author.dig('publisher', 'logo', 'url')
          hsh
        end
      end
    end
  end
end
