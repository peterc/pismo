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

      def call
        raise 'must be implemented in your child class'
      end
    end
  end
end
