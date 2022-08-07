class ULID
  # Like a https://github.com/ahawker/ulid/blob/06289583e9de4286b4d80b4ad000d137816502ca/ulid/ulid.py#L21-L219
  # Not a https://github.com/ruby/ruby/blob/fb928f0ea0e35e06ecc96f592702ff21d28fbdd4/doc/memory_view.md, In my understanding, it is for C ext, not fit for pure ruby...
  class ByteTuple
    include(Comparable)

    attr_reader :uchars

    def initialize(integer, octets_length)
      @integer = integer
      @uchars = (
        digits = integer.digits(256)
        (octets_length - digits.size).times do
          digits.push(0)
        end
        digits.reverse!
      ).freeze

      freeze
    end

    def <=>(other)
      return nil unless ByteTuple === other

      @integer <=> other.to_int
    end

    def to_int
      @integer
    end
    alias_method(:to_i, :to_int)

    def to_s
      @uchars.pack('C*')
    end

    def crockford_base32
      CrockfordBase32.encode(@integer)
    end

    def binary
    end

    def hex
    end

    def bytes
    end

    def octet
    end

    def inspect
      "ULID::ByteTuple<0..255 x #{@uchars.size}>(#{uchars})"
    end
  end
end
