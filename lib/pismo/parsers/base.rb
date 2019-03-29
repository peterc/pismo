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

      def meta
        @meta ||= args.dig(:meta)
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
    end
  end
end
