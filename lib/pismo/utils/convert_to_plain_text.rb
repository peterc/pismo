# The main method on this module +plain_text+ will convert a string of HTML
# to a plain text approximation.
module Pismo
  module Utils
    module ConvertToPlainText
      IGNORE_TAGS = %w(script style object applet iframe).inject({}){ |h, t| h[t] = true; h }.freeze
      PARAGRAPH_TAGS = %w(p h1 h2 h3 h4 h5 h6 table ol ul dl dd blockquote dialog figure aside section).inject({}){|h, t| h[t] = true; h}.freeze
      BLOCK_TAGS = %w(div address li dt center del article header header footer nav pre legend tr).inject({}){|h, t| h[t] = true; h}.freeze
      WHITESPACE = [" ", "\n", "\r"].freeze
      PLAINTEXT = "plaintext".freeze
      HEADING_TAGS = %w(h1 h2 h3 h4 h5 h6).freeze
      PRE = "pre".freeze
      BR = "br".freeze
      HR = "hr".freeze
      TD = "td".freeze
      TH = "th".freeze
      TR = "tr".freeze
      OL = "ol".freeze
      UL = "ul".freeze
      LI = "li".freeze
      IMG = 'img'.freeze
      A = "a".freeze
      TABLE = "table".freeze
      NUMBERS = ["1", "a"].freeze
      ABSOLUTE_URL_PATTERN = /^[a-z]+:\/\/[a-z0-9]/i.freeze
      HTML_PATTERN = /[<&]/.freeze
      TRAILING_WHITESPACE = /[ \t]+$/.freeze
      BODY_TAG_XPATH = "/html/body".freeze
      CARRIDGE_RETURN_PATTERN = /\r(\n?)/.freeze
      LINE_BREAK_PATTERN = /[\n\r]/.freeze
      NON_PROTOCOL_PATTERN = /:\/?\/?(.*)/.freeze
      NOT_WHITESPACE_PATTERN = /\S/.freeze
      SPACE = " ".freeze
      EMPTY = "".freeze
      NEWLINE = "\n".freeze
      HREF = "href".freeze
      TABLE_SEPARATOR = " | ".freeze

      # Helper instance method for converting HTML into plain text. This method simply calls HtmlToPlainText.plain_text.
      def call(html: html)
        HtmlToPlainText.plain_text(html)
      end

      class << self
        # Convert some HTML into a plain text approximation.
        def plain_text(html, options = {})
          return nil if html.nil?
          html = convert_to_utf8(html)
          return html.dup unless html =~ HTML_PATTERN
          body = Nokogiri::HTML::Document.parse(html).xpath(BODY_TAG_XPATH).first
          return unless body
          convert_node_to_plain_text(body, '', options).strip.gsub(CARRIDGE_RETURN_PATTERN, NEWLINE)
        end

        private

        def convert_to_utf8(html = nil)
          html = html.encode('UTF-8').scrub if html
          html
        end

        def not_obj?(text)
          text.scan(/(\{\s{1,2}|\s{1,2})\"\w{1,10}\"\s{0,2}(\:|\=\>)\s{0,2}/).blank?
        end

        # Convert an HTML node to plain text. This method is called recursively with the output and
        # formatting options for special tags.
        def convert_node_to_plain_text(parent, out = '', options = {})
          if PARAGRAPH_TAGS.include?(parent.name)
            append_paragraph_breaks(out)
          elsif BLOCK_TAGS.include?(parent.name)
            append_block_breaks(out)
          end

          format_list_item(out, options) if parent.name == LI
          out << "__HEADER_START__ " if HEADING_TAGS.include?(parent.name)
          out << "| " if parent.name == TR && data_table?(parent.parent)
          parent.children.each do |node|
            if (node.text? && not_obj?(node.text)) || node.cdata?
              text = "#{node.text} "
              unless options[:pre]
                text = node.text.gsub(LINE_BREAK_PATTERN, SPACE).squeeze(SPACE)
                text.lstrip! if WHITESPACE.include?(out[-1, 1])
              end
              out << "#{text} "
            elsif node.name == PLAINTEXT
              out << "#{node.text} "
            elsif node.element? && !IGNORE_TAGS.include?(node.name)
              convert_node_to_plain_text(node, out, child_options(node, options))

              if node.name == BR
                out.sub!(TRAILING_WHITESPACE, EMPTY)
                out << NEWLINE
              elsif node.name == HR
                out.sub!(TRAILING_WHITESPACE, EMPTY)
                out << NEWLINE unless out.end_with?(NEWLINE)
                out << "-------------------------------\n"
              elsif node.name == TD || node.name == TH
                out << (data_table?(parent.parent) ? TABLE_SEPARATOR : SPACE)
              elsif node.name == A
                href = node[HREF]
                if href &&
                    href =~ ABSOLUTE_URL_PATTERN &&
                    node.text =~ NOT_WHITESPACE_PATTERN &&
                    node.text != href &&
                    node.text != href[NON_PROTOCOL_PATTERN, 1] # use only text for <a href="mailto:a@b.com">a@b.com</a>
                  # out << " (#{href}) " # removed adding the link in parenthessis.
                end
              elsif node.name == IMG
                out << ' '
              elsif PARAGRAPH_TAGS.include?(node.name)
                append_paragraph_breaks(out)
              elsif BLOCK_TAGS.include?(node.name)
                append_block_breaks(out)
              end
            end
          end
          out
        end

        # Set formatting options that will be passed to child elements for a tag.
        def child_options(node, options)
          if node.name == UL
            level = options[:ul] || -1
            level += 1
            options.merge(:list => :ul, :ul => level)
          elsif node.name == OL
            level = options[:ol] || -1
            level += 1
            options.merge(:list => :ol, :ol => level, :number => NUMBERS[level % 2])
          elsif node.name == PRE
            options.merge(:pre => true)
          else
            options
          end
        end

        # Add double line breaks between paragraph elements. If line breaks already exist,
        # new ones will only be added to get to two.
        def append_paragraph_breaks(out)
          out.sub!(TRAILING_WHITESPACE, EMPTY)
          if out.end_with?(NEWLINE)
            out << NEWLINE unless out.end_with?("\n\n")
          else
            out << "\n\n"
          end
        end

        # Add a single line break between block elements. If a line break already exists,
        # none will be added.
        def append_block_breaks(out)
          out.sub!(TRAILING_WHITESPACE, EMPTY)
          out << NEWLINE unless out.end_with?(NEWLINE)
        end

        # Add an appropriate bullet or number to a list element.
        def format_list_item(out, options)
          if options[:list] == :ul
            # out << "#{'*' * (options[:ul] + 1)} "
          elsif options[:list] == :ol
            number = options[:number]
            options[:number] = number.next
            # out << "#{number}. "
          end
        end

        def data_table?(table)
          table.attributes['border'].to_s.to_i > 0
        end
      end
    end
  end
end
