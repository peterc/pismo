# frozen_string_literal: true

require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Meta < Base
        def call
          profile_or_name_helper
        rescue => e
          Pismo.logger.warn "status=error message='#{e.message}' location=Pismo::Parsers::Authors::Meta"
          nil
        end

        def profile_or_name_helper
          if profiles.length > 0
            profiles&.first
          elsif meta_author.present?
            { type: 'help_data', name: meta_author }
          else
            nil
          end
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
            meta_author.delete_if { |item| item.nil? } if meta_author.is_a?(Array)
            meta_author = meta_author.first            if meta_author.is_a?(Array)
            meta_author
          end
        end

        def nodes
          @nodes ||= begin
            return [] if meta_author.blank?

            nodes = []
            meta_author.split(' ').each do |text_item|
              contains_text?(text_item).each do |node|
                next if invalid_candidate_profile_node?(node)
                nodes << node
              end
            end
            nodes = nodes.uniq
            nodes
          end
        end

        def profiles
          @profiles ||= begin
            return [] if nodes.length.zero?
            Utils::NodesToProfiles.call(matches: nodes, url: url, doc: doc).map do |profile|
              profile[:from] = :meta_html
              profile
            end
          end
        end

        def meta_attrs
          %w[name rel itemprop property]
        end

        def meta_values
          %w[author byline dc.creator byl dc:creator]
        end
      end
    end
  end
end
