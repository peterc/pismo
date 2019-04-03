# frozen_string_literal: true

require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class JsonldAuthor < Base
        def call
          profile_or_name_helper
        rescue => e
          Pismo.logger.warn "status=error message='#{e.message}' location='#{e.backtrace.first}' class=#{self.class.name}"
          nil
        end

        def profile_or_name_helper
          if valid_author?
            author
          elsif profiles.length > 0
            profiles&.first
          elsif author_name.present?
            { type: 'help_data', name: author_name }
          else
            nil
          end
        end

        def valid_author?
          author && %i[type url name].all? { |key| author.dig(key).present? }
        end

        def profile
          author
        end

        def author
          @author ||= begin
            author = jsonld.dig(:author)
            author = author.merge(from: 'jsonld_author') if author
            author
          end
        end

        def author_name
          @author_name ||= author.dig(:name) if author
        end

        def nodes
          @nodes ||= begin
            return [] if author_name.blank?

            nodes = []
            author_name.split(' ').each do |text_item|
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
              profile[:from] = :jsonld
              profile[:name] = author_name
              profile
            end
          end
        end
      end
    end
  end
end
