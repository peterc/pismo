# encoding: utf-8

module Pismo
  module Reader
    class Cluster < Base

      # Adapted from : http://rubyforge.org/projects/extractcontent/
      #
      # Portions of this code are :
      # Copyright (c) 2007/2008 Nakatani Shuyo / Cybozu Labs Inc. All rights reserved.
      #
      # Permission is hereby granted, free of charge, to any person obtaining
      # a copy of this software and associated documentation files (the
      # "Software"), to deal in the Software without restriction, including
      # without limitation the rights to use, copy, modify, merge, publish,
      # distribute, sublicense, and/or sell copies of the Software, and to
      # permit persons to whom the Software is furnished to do so, subject to
      # the following conditions:
      #
      # The above copyright notice and this permission notice shall be
      # included in all copies or substantial portions of the Software.
      #
      # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
      # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
      # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
      # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
      # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
      # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

      # Default option parameters
      DEFAULTS = {
        :threshold => 100,                                       # threshold for score of the text
        :min_length => 80,                                       # minimum length of evaluated blocks
        :decay_factor => 0.73,                                   # decay factor for block score
        :continuous_factor => 1.62,                              # continuous factor for block score ( the larger, the harder to continue )
        :no_body_factor => 0.72,                                 # no body factor that reduces block score if waste expressions are present
        :punctuation_weight => 10,                               # score weight for punctuation
        :punctuations => /(\.[^A-Za-z0-9]|,[^0-9]|!|\?)/,        # punctuation characters
        :waste_expressions => /Copyright|All Rights Reserved/i,  # characteristic keywords including footer
        :debug => false,                                         # if true, output block information to stdout
      }

      # Analyze the structure of the HTML document and score content blocks for likelihood of containing useful content
      def analyze

        opt = DEFAULTS.clone
        opt.merge!(@options)

        @sections = []
        factor = continuous = 1.0
        body = ''
        score = 0

        # The content is split into blocks of divs
        list = @raw_content.split(/<\/?(?:div)[^>]*>/)
        list.each do |block|
          next unless block
          block.gsub!(/\n/, '')

          # Ignore blocks that have no tex
          next if has_only_tags?(block)

          # Each new block iterated over makes it less likely for it to belong
          # to the existing block
          continuous /= opt[:continuous_factor] if body.length > 0

          # Clean up and strip block of html tags for scoring
          clean = clean_block(block)
          #clean = strip_tags(block)
          next if clean.length < opt[:min_length]

          # Calculate scores for clustering of blocks

          # c represents how probable it is for this block to be a content block
          c = (clean.length + clean.scan(opt[:punctuations]).length * opt[:punctuation_weight]) * factor

          # The further down the document we go (i.e. the more blocks we see),
          # the less likely they are to be valid content blocks
          factor *= opt[:decay_factor]

          # The not body rate represents how likely this is to be a junk block
          not_body_rate = block.scan(opt[:waste_expressions]).length

          # The block score is reduced if there is a not_body_rate
          c *= (opt[:no_body_factor] ** not_body_rate) if not_body_rate>0

          # c1 represents how probable it is for this block to belong to the
          # existing block or if it is a new one
          c1 = c * continuous

          puts "----- #{c}*#{continuous}=#{c1} #{clean.length} \n\n" if opt[:debug]

          if c1 > opt[:threshold]
            # Treat continuous blocks as cluster
            body += block + "\n"
            score += c1
            continuous = opt[:continuous_factor]
          elsif c > opt[:threshold]
            # Continuous block end
            @sections << { :body => body, :score => score }
            body = block + "\n"
            score = c
            continuous = opt[:continuous_factor]
          else
            # We drop blocks that don't have a high enough c score
          end
        end
        # Add the last block as we've finished iterating
        @sections << { :body => body, :score => score } if body
        # Sort the sections by score
        sorted_sections = @sections.sort_by { |section| section[:score] }
        # Convert to nokogiri representation for compatibility with the content method
        @content_candidates = sorted_sections.reverse.map { |section| Nokogiri::HTML(section[:body], nil, 'utf-8') }
      end

      def content_at(index)
        @content_candidates[index]
      end

      protected

      # Checks if the given block has only tags without text.
      def has_only_tags?(block)
        block.gsub(/<[^>]*>/im, '').strip.length == 0
      end

      # Eliminates link heavy blocks and blocks that are lists of links and
      # then returns block stripped of tags
      def clean_block(block)
        # Return empty block if it is a list of links
        return "" if is_link_list?(block)

        # Return empty block if it is a very link heavy block
        count = 0
        no_links = block.gsub(/<a\s[^>]*>.*?<\/a\s*>/im){count+=1;''}.gsub(/<form\s[^>]*>.*?<\/form\s*>/im, '')
        return "" if no_links.length < 20 * count

        strip_tags(no_links)
      end

      # Determines whether a block is link list or not
      def is_link_list?(st)
        if st =~ /<(?:ul|dl|ol)(.+?)<\/(?:ul|dl|ol)>/im
          listpart = $1
          outside = st.gsub(/<(?:ul|dl)(.+?)<\/(?:ul|dl)>/imn, '').gsub(/<.+?>/mn, '').gsub(/\s+/, ' ')
          list = listpart.split(/<li[^>]*>/)
          list.shift
          rate = evaluate_list(list)
          outside.length <= st.length / (45 / rate)
        end
      end

      # Estimates how much degree of link list
      def evaluate_list(list)
        return 1 if list.length == 0
        hit = 0
        list.each do |line|
          hit +=1 if line =~ /<a\s+href=(['"]?)([^"'\s]+)\1/imn
        end
        return 9 * (1.0 * hit / list.length) ** 2 + 1
      end

      # Removes all html tags and attributes from html
      def strip_tags(html)
        strip(Sanitize.clean(html, :elements => [], :attributes => []))
      end
    end
  end
end
