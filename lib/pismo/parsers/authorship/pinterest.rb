# frozen_string_literal: true

require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Pinterest < Base
        def call
          meta_author if doc && doc.html?
        rescue => e
          Pismo.logger.warn "status=error message='#{e.message}' location=Pismo::Parsers::Authors::Pinterest"
          nil
        end

        # If there is a plain meta/author this extracts it
        def meta_author
          @meta_author ||= begin
            return nil unless meta.is_a?(Hash)
            meta_author = nil
            meta_attrs.each do |meta_attr|
              break if meta_author
              meta_values.each do |meta_val|
                meta_author = meta&.dig(meta_attr, meta_val) if meta_author.nil?
                break if meta_author
              end
              break if meta_author
            end
            as_name_hash(meta_author) if meta_author
          end
        end

        def meta_attrs
          %w[pinterest:pinner]
        end

        def meta_values
          %w[author byline dc.creator byl]
        end
      end
    end
  end
end
