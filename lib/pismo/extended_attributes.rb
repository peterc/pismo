module Pismo
  # External attributes return data that comes from external services or programs (e.g. Delicious tags)
  module ExtendedAttributes
    def entities
      @entities ||= ::Pismo::Parsers::TwitterText.new(text: body).entities
    end
  end
end
