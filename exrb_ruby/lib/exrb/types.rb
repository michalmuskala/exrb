require "adamantium"
require "base64"

module Exrb

  class Tuple
    include Adamantium

    def initialize(values)
      @values = values
    end

    def to_a
      @values
    end

    def elem(idx)
      @values[idx]
    end

    def put_elem(idx, value)
      new_values = @values.dup
      new_values[idx] = value

      transform do
        @values = new_values
      end
    end

    def inspect
      "#Tuple<#{@values.map(&:inspect).join(", ")}>"
    end
  end

  class ErlangString
    include Adamantium

    def initialize(value)
      @value = value
    end

    def to_s
      @value
    end

    def inspect
      "'#{@value}'"
    end
  end

  class ImproperList
    include Adamantium

    def initialize(list, tail)
      @list = list
      @tail = tail
    end

    def inspect
      "#{@list.inspect[0..-2]} | #{@tail.inspect}]"
    end
  end

  class BitBinary
    include Adamantium

    def initialize(bits, value)
      @bits = bits
      @value = value
    end

    def inspect
      *values, tail = @value.each_byte.to_a
      "<<#{values.join(", ")}, #{tail >> (8 - @bits)}::size(#{@bits})>>"
    end
  end

  class Opaque
    include Adamantium

    def initialize(tag, node, value)
      @tag = tag
      @node = node
      @value = value
    end

    def inspect
      "##{self.class.name.split("::").last}<#{hash}>"
    end
  end

  Reference = Class.new(Opaque)
  Port = Class.new(Opaque)
  Pid = Class.new(Opaque)

  class Function
    include Adamantium

    def initialize(pid, mod, idx, uniq, terms)
      @pid = pid
      @mod = mod
      @idx = idx
      @uniq = uniq
      @terms = terms
    end

    def inspect
      "#Function<#{hash}>"
    end
  end

  class NewFunction
    include Adamantium

    def initialize(size, data)
      @size = size
      @data = data
    end

    def inspect
      "#Function<#{hash}>"
    end
  end

  class Export
    include Adamantium

    def initialize(mod, fun, arity)
      @mod = mod
      @fun = fun
      @arity = arity
    end

    def inspect
      "#Export<#{hash}>"
    end
  end

  ErlangNil = Class.new
end
