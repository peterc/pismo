require 'nokogiri'
require 'sanitize'
begin; require 'ap'; rescue LoadError; end

module Pismo
  module Reader
    class Document
      attr_reader :raw_content, :doc, :content_candidates
      
      # Elements to keep for /input/ sanitization
      OK_ELEMENTS = %w{a td br th tbody table tr div span img strong em b i body html head title p h1 h2 h3 h4 h5 h6 pre code tt ul li ol blockquote font big small section article abbr audio video cite dd dt figure caption sup form dl dt dd center}
  
      # Build a tree of attributes that are allowed for each element.. doing it this messy way due to how Sanitize works, alas
      OK_ATTRIBUTES = {}
      OK_CLEAN_ATTRIBUTES = {}
      OK_ELEMENTS.each { |el| OK_ATTRIBUTES[el] = %w{id class href name content type alt title src} }
      OK_ELEMENTS.each { |el| OK_CLEAN_ATTRIBUTES[el] = %w{href title src alt} }
      
      
      # Words that we'd like to see in class and ID names for "content"
      GOOD_WORDS = %w{content post blogpost main story body entry text desc asset hentry single entrytext postcontent bodycontent}.uniq
  
      # Words that indicate crap in general
      BAD_WORDS = %w{reply metadata options commenting comments comment about footer header outer credit sidebar widget subscribe clearfix date social bookmarks links share video watch excerpt related supplement accessibility offscreen meta title signup blq secondary feedback featured clearfix small job jobs listing listings navigation nav byline addcomment postcomment trackback neighbor ads commentform fbfans login similar thumb link blogroll grid twitter wrapper container nav sitesub printfooter editsection visualclear catlinks hidden toc contentsub caption disqus rss shoutbox sponsor blogcomments}.uniq
      
      # Words that kill a branch dead
      FATAL_WORDS = %w{comments comment bookmarks social links ads related similar footer digg totop metadata sitesub nav sidebar commenting options addcomment leaderboard offscreen job prevlink prevnext navigation reply-link hide hidden sidebox archives vcard}
      
      META_WORDS = %w{january february march april may june july august september october november december jan feb mar apr may jun jul aug sep oct nov dec st th rd nd comments written posted on at published 2000 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 updated last gmt est pst pdt edt cet cdt cst article feature featured filed under comment comments follow twitter facebook email e-mail register story continue continues reading read inside more page next related response responses respond contact street phone tel email e-mail fax info tags tagged tag thanks credit creative commons copy nbsp lt gt this friend printable version subscribe rss mail follow twitter article via leave}.uniq
  
      WONT_CONTAIN_FULL_CONTENT = %w{h1 h2 h3 h4 h5 h6 h6 li ol ul br a img meta cite strong em i b input head small big code title sup sub dd dt}
      COULD_CONTAIN_FULL_CONTENT = %w{body div p table tr td article pre blockquote tbody section}
  
      ## Output sanitization element sets
      BLOCK_OUTPUT_ELEMENTS = %w{div p h2 h3 h4 h5 h6 li dl pre ul ol blockquote section article audio video cite dd dt figure caption br table tr td thead tbody tfoot}
      INLINE_OUTPUT_ELEMENTS = %w{a img b strong em i br code sup font small big dd dt}
      OUTPUT_ELEMENTS = BLOCK_OUTPUT_ELEMENTS + INLINE_OUTPUT_ELEMENTS
      NON_HEADER_ELEMENTS = %w{p br}
  
      # Create a document object based on the raw HTML content provided
      def initialize(raw_content)
        @raw_content = Pismo::Document.clean_html(raw_content)
        build_doc
      end
  
      def build_doc
        @content = {}
        
        if RUBY_VERSION > "1.9"
          @raw_content.encode!("UTF-8", :invalid => :replace, :replace => '?') if @raw_content.encoding != "UTF-8"
          @raw_content.encode!("ASCII-8BIT", :invalid => :replace, :replace => '?') if !@raw_content.valid_encoding?
        end
  
        # Normalize whitespace (as much to make debugging sessions look nice as anything else)
        @raw_content.gsub!(/\s{2,}/, ' ')
        @raw_content.gsub!(/\r/, "\n")
        @raw_content.gsub!(/\n{3,}/, "\n\n")
        @raw_content.gsub!(/(\<br(\s\/)?\>){2,}/, "</p><p>")
        
        # Remove scripts manually, Sanitize and/or Nokogiri seem to go a bit funny with them
        @raw_content.gsub!(/\<script .*?\<\/script\>/im, '')
        
        # Get rid of bullshit "smart" quotes and other Unicode nonsense
        @raw_content.force_encoding("ASCII-8BIT") if RUBY_VERSION > "1.9"
        @raw_content.gsub!("\xe2\x80\x89", " ")
        @raw_content.gsub!("\xe2\x80\x99", "'")
        @raw_content.gsub!("\xe2\x80\x98", "'")
        @raw_content.gsub!("\xe2\x80\x9c", '"')
        @raw_content.gsub!("\xe2\x80\x9d", '"')
        @raw_content.gsub!("\xe2\x80\xf6", '.')
        @raw_content.force_encoding("UTF-8") if RUBY_VERSION > "1.9"
        
              
        # Sanitize the HTML
        @raw_content = Sanitize.clean(@raw_content,
          :elements => OK_ELEMENTS,
          :attributes => OK_ATTRIBUTES,
          :remove_contents => true,
          :output_encoding => 'utf-8'
        )
              
        @doc = Nokogiri::HTML(@raw_content, nil, 'utf-8')
        
        build_analysis_tree
      end
    
      
      # Analyze the structure of the HTML document and score branches for likelihood of containing useful content
      def build_analysis_tree
        @tree = {}    
        subels = {}
        
        t1 = Time.now.to_i + (Time.now.usec.to_f / 1000000)
        
        # Do a pre clean up of elements. 
        @doc.css("div, span, table, tr, td, pre").each do |el|
          # Any block elements with no child block elements can become paragraphs
          if (BLOCK_OUTPUT_ELEMENTS & el.inner_html.scan(/\<(\w+)/).flatten).empty?
            el.name = "p" 
          elsif el.name != "span"
            el.name = "div"
          end
          
          # Any SPANs that aren't within paragraphs can become paragraphs too
          el.name = "p" if el.name == "span" && !el.path.scan(/[a-z]+/).include?('p')
          
          el.remove if (FATAL_WORDS & (el['id'].to_s + ' ' + el['class'].to_s).downcase.strip.scan(/[a-z]+/)).size > 0
        end
                    
        @doc.css(COULD_CONTAIN_FULL_CONTENT.join(", ")).each do |el|
          # Assume that no content we'll want comes in a total package of fewer than 80 characters!
          next unless el.text.to_s.strip.length >= 80
  
          path_segments = el.path.scan(/[a-z]+/)[2..-1] || []
          depth = path_segments.length

          local_ids = (el['id'].to_s + ' ' + el['class'].to_s).downcase.strip.scan(/[a-z]+/)
          ids = local_ids
          
          cp = el.parent
          (depth - 1).times do
            ids += (cp['id'].to_s + ' ' + cp['class'].to_s).downcase.strip.scan(/[a-z]+/)
            cp = cp.parent
          end if depth > 1
          
          #puts "IDS"
          #ap ids
          #puts "LOCAL IDS"
          #ap local_ids
          
          branch = {}        
          branch[:ids] = ids
          branch[:local_ids] = local_ids
          branch[:score] = -(BAD_WORDS & ids).size
          branch[:score] += ((GOOD_WORDS & ids).size * 2)
          next if branch[:score] < -5
  
          #puts "#{ids.join(",")} - #{branch[:score].to_s} - #{el.text.to_s.strip.length}"
          
          # Elements that have an ID or class are more likely to be our winners
          branch[:score] += 2 unless local_ids.empty?
  
          branch[:name] = el.name
          branch[:depth] = depth
          branch[:path] = el.path
          
          branch[:raw_word_count] = 0
          branch[:word_count] = 0
          branch[:child_count] = 0
          branch[:bad_child_count] = 0
          branch[:score_steps] = []
          
          
          el.traverse do |subel|
            div_at_end_of_branch = false if subel.name == "div"
            path = subel.path
            subels[path] ||= {}
            subels[path][:path_segments] ||= (path.scan(/[a-z]+/)[2..-1] || [])
            subels[path][:is_text] ||= subel.text?
                      
            if subels[path][:is_text]
              subels[path][:text] ||= subel.text.downcase.scan(/[a-z]+/)
              next if subels[path][:text].empty?
  
              subels[path][:raw_word_count] ||= subels[path][:text].size
              subels[path][:word_count] ||= (%{a h1 h2 h3 h4 h5 h6 h6}.include?(subel.parent.name) ? 0 : subels[path][:text].select { |word| word.length > 3 }.size)
              subels[path][:meta_matches] ||= (subels[path][:text] & META_WORDS).size
              
              branch[:raw_word_count] += subels[path][:raw_word_count]
              branch[:word_count] += subels[path][:word_count] - subels[path][:meta_matches]
            end
            
            subels[path][:ids] ||= (subel['id'].to_s + ' ' + subel['class'].to_s).gsub(/[^a-z]/, ' ').downcase.strip.split(/\s+/)
            subels[path][:bad_child_count_inc] = (BAD_WORDS & subels[path][:ids]).size - (GOOD_WORDS & subels[path][:ids]).size
            subels[path][:child_count_inc] = subels[path][:ids].empty? ? 0 : 1
            
            branch[:bad_child_count] += subels[path][:bad_child_count_inc]
            branch[:child_count] += subels[path][:child_count_inc]
          end
                  
          branch[:score] += 2 if branch[:name] == "div"
          branch[:score] += 4 if el.text.scan(/\,\s/).size > 10
          branch[:score_steps] << "lots of commas!" if el.text.scan(/\,\s/).size > 5
          branch[:score] *= 3
          
          
          branch[:score] *= 0.7 if el.children && el.children.size < 3
          branch[:score] *= 1.25 if branch[:raw_word_count] > 10
          next if branch[:raw_word_count] < 10        
          branch[:score] += [branch[:word_count], 1].max ** 0.5
  
          
          word_child_count_ratio = branch[:word_count].to_f / [branch[:child_count], 1].max        
          branch[:word_child_count_ratio] = word_child_count_ratio
  
          if branch[:raw_word_count] > 100
            good_word_ratio = branch[:word_count].to_f / branch[:raw_word_count]
            branch[:score] += good_word_ratio * 12
  
            if word_child_count_ratio > 50
              branch[:score] *= 1.5
            elsif word_child_count_ratio > 30
              branch[:score] *= 1.2
            elsif word_child_count_ratio > 15
              branch[:score] *= 1.1
            elsif word_child_count_ratio < 4
              branch[:score] *= 0.9
            end   
          end
          
          branch[:score_steps] << "s1: #{branch[:score]}"
          
          bad_child_ratio = branch[:bad_child_count].to_f / [branch[:child_count], 1].max
          branch[:bad_child_ratio] = bad_child_ratio
          branch[:score] += 3 if bad_child_ratio < 0.0
          branch[:score] -= 3 if bad_child_ratio > 0.15
          branch[:score] -= 2 if bad_child_ratio > 0.25
          branch[:score] -= 2 if bad_child_ratio > 0.4
          branch[:score] -= 4 if bad_child_ratio > 0.5
          branch[:score] -= 5 if bad_child_ratio > 0.7
          branch[:score] -= 5 if branch[:bad_child_count] > 20
          
          branch[:score] += depth
          branch[:score] *= 0.8 if ids.length > 10
          
          
          
          @tree[el.path] = branch
        end
  
  
        sorted_tree = @tree.sort_by { |k, v| v[:score] }
        
        #ap @doc.at(sorted_tree.first[0]).text
        
        # Sort the branches by their score in reverse order
        @content_candidates = sorted_tree.reverse.first([5, sorted_tree.length].min)
        
        #ap @content_candidates #.map { |i| [i[0], i[1][:name], i[1][:ids].join(','), i[1][:score] ]}
        #t2 = Time.now.to_i + (Time.now.usec.to_f / 1000000)      
        #puts t2 - t1      
        #exit
        
      end
      
      
      # Return the content from best match number of index (default 0) and, optionally, clean it to plain-text
      def content(clean = false, index = 0)
        return @content[[clean, index]] if @content[[clean, index]]
        return '' if !@content_candidates || @content_candidates.empty?
        
        content_branch = @doc.at(@content_candidates[index].first)
        orphans_to_remove = []
        
        #ap content_branch.to_html
        #exit
        
        # Go through every piece of the content and rip out sections that contain too many tags compared to words
        # This is usually indicative of "widgets" or link bar sections
        content_branch.css('*').each_with_index do |el, i|
          next unless el
          
          if el.name == "h1"
            el.remove
            next
          end
          
          if el.name == "h2" && content_branch.inner_html.scan('<h2').size == 1
            el.remove
          end
          
          # Remove elements that contain words but there are more tags than words overall
          # First, count the words
          #word_count = 0
          #el.traverse do |subel|
          #  if subel.text? && subel.path !~ /\/a\// && subel.path !~ /\/(h1|h2|h3|h4|h5|h6)\//
          #    word_count += (subel.text.downcase.scan(/[a-z]{4,}/) - META_WORDS).size
          #  end
          #end
          #
          ## .. then count the tags
          #
          #inner_tags = el.inner_html.scan(/\<\w.*?\>/).size
          #if word_count < inner_tags && inner_tags > 3 && word_count < 250
          #  puts "At #{el.name} #{el['id']} #{el['class']} containing '#{el.text[0..20]}' we have #{word_count} valid words to #{el.inner_html.scan(/\<\w.*?\>/).size} tags"
          #  #puts "Removing #{el.name} #{el['id']} #{el['class']} TOO MANY TAGS FOR WORDS"
          #  el.remove
          #  next
          #end        
  
          # If there are at least 2 words and a third of them are "meta words," remove the element
          #inner_words = el.text.to_s.downcase.scan(/[a-z]{3,}/)
          #if BLOCK_OUTPUT_ELEMENTS.include?(el.name) && inner_words.size >= 2
          #  if ((inner_words & META_WORDS).size >= (inner_words.size / 3))
          #    el.remove
          #  end
          #end
          
          if el.text && el.text.strip.length < 3 && !%w{img}.include?(el.name) && el.inner_html !~ /\<img/
            el.remove
            next
          end
          
          if el.name == "p" && el.text !~ /(\.|\?|\!|\"|\')(\s|$)/ && el.inner_html !~ /\<img/
            el.remove
            next
          end
          
          # If the ID or class of the element contains a fatally bad word, get rid of it
          if (BAD_WORDS & (el['id'].to_s + ' ' + el['class'].to_s).downcase.scan(/[a-z]+/)).length > 0
            #puts "Removing #{el.name} #{el['id']} #{el['class']} BAD"          
            el.remove
            next
          end
        end
              
        # If a title was found early in the result document but had text before it, remove that text - it's probably crap
        orphans_to_remove.each { |el| el.remove }
        
        # Clean up the HTML again - Nokogiri outputs it with full doctype and crap
        clean_html = strip(Sanitize.clean(content_branch.to_html, :elements => (clean ? BLOCK_OUTPUT_ELEMENTS : OUTPUT_ELEMENTS), :attributes => (clean ? OK_CLEAN_ATTRIBUTES : OK_ATTRIBUTES)))
        
        # If the content is desired as "clean" (i.e. plain-text), do some quick fix-ups
        if clean
          # Get rid of line break tags, make list items look nice, remove all other HTML tags, and clean up spaces and newlines
          clean_html.gsub!(/<br.*?>/, "\n")
          clean_html.gsub!(/<li>/, '* ')
          clean_html.gsub!(/<\w+>/, '')
          clean_html.gsub!(/<\/\w+>/, "\n")
          clean_html.gsub!(/\ +/, ' ')
          clean_html.gsub!(/^\s+\n/, "\n")
          clean_html.gsub!(/\n{2,}/, "\n")
          clean_html.strip!
        end
        
        # If tags butt up against each other across lines, remove the line break(s)
        clean_html.gsub!(/\>\n+\</, '><')
        
        # Get rid of images whose sources are relative (TODO: Make this optional)
        clean_html.gsub!(/\<img .*?\>/i) do |img_tag|
          img_tag =~ /\Whttp/ ? img_tag : ''
        end
        
        # Remove empty tags
        clean_html.gsub!(/<(\w+)><\/\1>/, "")
        
        # Just a messy, hacky way to make output look nicer with subsequent paragraphs..
        clean_html.gsub!(/<\/(div|p|h1|h2|h3|h4|h5|h6)>/, '</\1>' + "\n\n")
        
        @content[[clean, index]] = clean_html
      end
          
      def sentences(qty = 3)
        clean_content = Sanitize.clean(content, :elements => NON_HEADER_ELEMENTS, :attributes => OK_CLEAN_ATTRIBUTES, :remove_contents => %w{h1 h2 h3 h4 h5 h6})

        fodder = ''
        doc = Nokogiri::HTML(clean_content, nil, 'utf-8')
  
        doc.traverse do |el|
          path_segments = el.path.scan(/[a-z]+/)[2..-1]
          next unless path_segments && path_segments.length > 1
          if el.text? && el.text.strip.length < 3
            el.remove
            next
          end
          if el.text? && NON_HEADER_ELEMENTS.include?(path_segments[-2]) 
            text = el.text.strip
            text += "." if text !~ /[\.\!\?\"\']$/
            fodder += text + "\n" 
          end
        end
        
        fodder = content(true) if fodder.to_s.length < 50
        fodder.gsub!(/\b\w\W\s/, '')
        
        #sentences = fodder.scan(/([\&\w\s\-\'\,\+\.\/\\\:\#\(\)\=\"\?\!]+?[\.\?\!])(\s|\Z)/im).map { |s| s.first }
        sentences = fodder.scan(/(.+?[\.\?\!])(\s|\Z)/im).map { |s| s.first.strip }
        
        sentences.compact!
        sentences.map! { |s| s.strip }
        sentences.map! { |s| s.sub(/^[^\"\'a-z0-9\(\[]+/im, '') }
        sentences.map! { |s| s.sub(/[^a-z0-9\'\"\)\]\.\!\:\?]+$/im, '') }
        sentences.map! { |s| s.gsub(/\s+/m, ' ') }
        sentences.first(qty)
      end
      
      def images(qty = 3)
        doc = Nokogiri::HTML(content, nil, 'utf-8')
        images = []
        doc.css("img").each do |img|
          images << img['src']
          break if images.length == qty
        end
        images
      end
      
      # Remove leading and trailing spaces on lines throughout a string (a bit like String#strip, but for multi-lines)
      def strip(s)
        s.gsub(/^\s+/, '').gsub(/\s+$/, '')
      end
    end  
  end
end