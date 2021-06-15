class HTMLEntities
  class Decoder #:nodoc:
    def initialize(flavor, tolerate_forgotten_octothorpes: false)
      @flavor = flavor
      @map = HTMLEntities::MAPPINGS[@flavor]
      @tolerate_forgotten_octothorpes = tolerate_forgotten_octothorpes
      @entity_regexp = entity_regexp
    end

    def decode(source)
      prepare(source).gsub(@entity_regexp){
        if $1 && codepoint = @map[$1]
          codepoint.chr(Encoding::UTF_8)
        elsif $2
          $2.to_i(10).chr(Encoding::UTF_8)
        elsif $3
          $3.to_i(16).chr(Encoding::UTF_8)
        else
          $&
        end
      }
    end

  private

    def prepare(string) #:nodoc:
      string.to_s.encode(Encoding::UTF_8)
    end

    def entity_regexp
      min_key_length, max_key_length = @map.keys.map { |k| k.length }.minmax

      if @flavor == 'expanded'
        entity_name_pattern = '(?:b\.)?[a-z][a-z0-9]'
      else
        entity_name_pattern = '[a-z][a-z0-9]'
      end

      patterns = [
        "(#{entity_name_pattern}{#{min_key_length - 1},#{max_key_length + 1}})", # Named entities
        "##{@tolerate_forgotten_octothorpes ? "?" : ""}([0-9]{1,7})", # Numbered entities (decimal)
        "#x([0-9a-f]{1,6})", # Numbered entities (hexidecimal)
      ]

      patterns_alternation = patterns.join("|")

      /&(?:#{patterns_alternation});/i
    end
  end
end
