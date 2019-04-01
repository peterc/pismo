module Pismo
  module Utils
    class Url
      class << self
        def host(url)
          uri(url)&.host
        end

        def uri(url)
          Addressable::URI.parse(url)
        end

        def absolutize(current_url, new_url)
          return new_url unless new_url.present?
          new_url = new_url.to_s.strip
          if new_url.start_with?('//')
            return "https:#{new_url}"
          else
            return new_url if uri(new_url).scheme.present?
            new_url = "/#{new_url}" if new_url&.chars[0] != '/'
            Addressable::URI.join(current_url, new_url).to_s
          end
        end
      end
    end
  end
end
