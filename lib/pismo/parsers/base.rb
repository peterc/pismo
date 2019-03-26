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

      def meta
        @meta ||= begin
          meta = args.dig(:meta)
          meta = Pismo::Parsers::Meta.call(doc: doc) if meta.blank? && doc.present?
          meta
        end
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
    end
  end
end
