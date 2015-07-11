require "adamantium"
require "base64"

module Exrb

  class Tuple
    include Adamantium
    attr_reader :values

    def initialize(values)
      @values = values
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

    def size
      @values.size
    end

    def inspect
      "#Tuple<#{@values.map(&:inspect).join(", ")}>"
    end
  end

  class Binary
    include Adamantium
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def size
      @value.size
    end

    def inspect
      "<<#{@value.each_byte.to_a.join(", ")}>>"
    end
  end

  class ImproperList
    include Adamantium
    attr_reader :list, :tail

    def initialize(list, tail)
      @list = list
      @tail = tail
    end

    def size
      @list.size
    end

    def inspect
      "#{@list.inspect[0..-2]} | #{@tail.inspect}]"
    end
  end

  class BitBinary
    include Adamantium
    attr_reader :bits, :value

    def initialize(bits, value)
      @bits = bits
      @value = value
    end

    def size
      @value.size
    end

    def inspect
      *values, tail = @value.each_byte.to_a
      "<<#{values.join(", ")}, #{tail >> (8 - @bits)}::size(#{@bits})>>"
    end
  end

  class Opaque
    include Adamantium
    attr_reader :node, :value

    def initialize(node, value)
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

  class NewReference
    include Adamantium
    attr_reader :node, :value

    def initialize(node, value)
      @node = node
      @value = value
    end

    def length
      (@value.size - 1) / 4
    end

    def inspect
      "#NewReference<#{hash}>"
    end
  end

  class Function
    include Adamantium
    attr_reader :pid, :mod, :idx, :uniq, :terms

    def initialize(pid, mod, idx, uniq, terms)
      @pid = pid
      @mod = mod
      @idx = idx
      @uniq = uniq
      @terms = terms
    end

    def size
      @terms.size
    end

    def inspect
      "#Function<#{hash}>"
    end
  end

  class NewFunction
    include Adamantium
    attr_reader :size, :data

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
    attr_reader :mod, :fun, :arity

    def initialize(mod, fun, arity)
      @mod = mod
      @fun = fun
      @arity = arity
    end

    def inspect
      "&#{@mod}.#{@fun}/#{@arity}"
    end
  end

  ErlangNil = Class.new
end
