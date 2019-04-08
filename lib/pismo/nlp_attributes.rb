module Pismo
  # Extended attributes are ones taht leverage ML/AI, more intelligent
  # parsing, or are next level
  module NlpAttributes
    def concepts
      @concepts ||= nlp_helper.concepts
    end

    def entities
      @entities ||= nlp_helper.entities
    end

    def keywords
      @keywords ||= nlp_helper.entities
    end

    def predicates
      @predicates ||= nlp_helper.predicates
    end

    def emails
      @emails ||= nlp_helper.emails
    end

    def phones
      @phones ||= nlp_helper.phones
    end

    def addresses
      @addresses ||= nlp_helper.addresses
    end

    def nlp_helper
      @nlp_helper ||= Dewey.new(text: text)
    end

  end
end
