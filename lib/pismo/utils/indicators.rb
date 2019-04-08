module Pismo
  module Utils
    class Indicators
      class << self
        def link_search_locations
          %w[href class id rel src]
        end

        def registration_locations
          %w[login logout signup sign_up sign-up signin sign_in sign-in signout sign_out sign-out]
        end

        def css_search_locations
          %w[class id property]
        end

        def sectional
          %w[body nav section article aside footer details figcaption
             figure main mark summary header time cite blockquote head html]
        end

        def sectional_css
          sectional + %w[post-body post-title header entry-meta entry dc:created post-top PostTop]
        end

        def author_links
          Allusion::Parsers::AuthorLinkParser::AUTHOR_INDICATORS
        end
      end
    end
  end
end
