# frozen_string_literal: true

require 'pismo/parsers/base'

module Pismo
  module Parsers
    module Authorship
      class Reddit < Base
        AUTHOR_TEXT_MATCHES = [
          'u/'
        ]

        def call
          profiles&.first if valid?
        rescue => e
          Pismo.logger.warn "status=error message='#{e.message}' location=#{self.class.name}"
          nil
        end

        def valid?
          host.include?('reddit') || host.include?('redd.it')
        end

        def candidate_nodes
          @candidate_nodes ||= begin
            nodes = []
            AUTHOR_TEXT_MATCHES.each do |match_string|
              doc.xpath("//a[contains(text(), '#{match_string}')]").each do |node|
                nodes << node
              end
            end
            nodes = nodes.uniq
            nodes
          end
        end

        def profiles
          @profiles ||= begin
            return [] if candidate_nodes.length.zero?
            Utils::NodesToProfiles.call(matches: candidate_nodes, url: url, doc: doc).map do |profile|
              profile[:from] = :reddit
              profile[:name] = profile[:url].split('/').last if profile[:name].nil?
              profile
            end
          end
        end
      end
    end
  end
end
