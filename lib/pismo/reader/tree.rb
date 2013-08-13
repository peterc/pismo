module Pismo
  module Reader
    class Tree < Base

      # Analyze the structure of the HTML document and score branches for likelihood of containing useful content
      def analyze
        @tree = {}
        subels = {}

        #t1 = Time.now.to_i + (Time.now.usec.to_f / 1000000)

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
        # t2 = Time.now.to_i + (Time.now.usec.to_f / 1000000)
        # puts t2 - t1
        #exit

      end

      def content_at(index)
        @doc.at(@content_candidates[index].first)
      end

    end
  end
end
