require 'pismo/parsers/base'
require 'pismo/parsers/jsonld'
require 'pismo/parsers/authors/twitter'
require 'pismo/parsers/authors/html'

module Pismo
  module Parsers
    class Author < Base
      def call
        twitter_author
      end

      def html_author
        @html_author ||= Parsers::Authors::Html.call(doc: doc)
      end

      def jsonld_author
        @jsonld_author ||= Parsers::Jsonld.call(doc: doc).dig(:author)
      end

      def twitter_author
        @twitter_author ||= Parsers::Authors::Twitter.call(meta: meta)
      end
    end
  end
end
