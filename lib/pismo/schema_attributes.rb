module Pismo
  module SchemaAttributes
    def microdata
      @microdata ||= begin
        hsh = {}
        microdata_parser.items.each do |item|
          hsh_item = ::HashWithIndifferentAccess.new(item.to_h)
          if hsh_item.keys.length > 1 && hsh_item.key?(:type)
            hsh[hsh_item[:type].gsub('http://schema.org/', '')] = hsh_item[:properties]
          end
        end
        hsh
      end
    end

    def microdata_parser
      @microdata_parser ||= Mida::Document.new(doc, url)
    end
  end
end
