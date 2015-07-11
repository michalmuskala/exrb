require "scanf"

require_relative "./types.rb"

module Exrb
  class Decoder
    PROTOCOL_VERSION = 131

    ParseError = Class.new(StandardError)

    INTEGER_DECODERS = {
      97 => :read_small_integer,
      98 => :read_ineteger
    }.freeze

    ATOM_DECODERS = {
      100 => :read_atom,
      118 => :read_atom_utf8,
      119 => :read_small_atom_utf8
    }.freeze

    DECODERS = {
      99  => :read_float,
      101 => :read_reference,
      102 => :read_port,
      103 => :read_pid,
      104 => :read_small_tuple,
      105 => :read_large_tuple,
      116 => :read_map,
      106 => :read_nil,
      107 => :read_string,
      108 => :read_list,
      109 => :read_binary,
      110 => :read_small_big,
      111 => :read_large_big,
      114 => :read_new_reference,
      115 => :read_small_atom,
      117 => :read_fun,
      112 => :read_new_fun,
      113 => :read_export,
      77  => :read_bit_binary,
      70  => :read_new_float,
    }.merge(INTEGER_DECODERS).merge(ATOM_DECODERS).freeze

    SPECIAL_ATOMS = {
      "true"  => true,
      "false" => false,
      "nil"   => nil
    }.freeze

    def initialize(dataio)
      @dataio = dataio
    end

    def call
      raise "Unsupported version" if read_byte != 131
      term
    end

    private

    def term
      send(DECODERS[read_byte] || :error)
    end

    def atom
      send(ATOM_DECODERS[read_byte] || :error)
    end

    def integer
      send(INTEGER_DECODERS[read_byte] || :error)
    end

    def read_small_integer
      read_byte
    end

    def read_integer
      read(4).unpack("l>")[0]
    end

    def read_float
      read(31).scanf("%f")
    end

    def read_atom
      len = read(2).unpack("S>")[0]
      decode_atom(read(len))
    end

    def read_reference
      Reference.new(101, atom, read(5))
    end

    def read_port
      Port.new(102, atom, read(5))
    end

    def read_pid
      Pid.new(103, atom, read(9))
    end

    def read_small_tuple
      Tuple.new(read_terms(read_byte))
    end

    def read_large_tuple
      Tuple.new(read_terms(read_len))
    end

    def read_map
      (0...read_len).each_with_object({}) { |_, hash| hash[term] = term }
    end

    def read_nil
      ErlangNil.new
    end

    def read_string
      read(read_len).unpack("C*")
    end

    def read_list
      terms = read_terms(read_len)
      tail = term
      if tail.is_a?(ErlangNil)
        terms
      else
        ImproperList.new(terms, tail)
      end
    end

    def read_binary
      read(read_len).force_encoding("UTF-8")
    end

    def read_small_big
      read_big(read_byte)
    end

    def read_large_big
      read_big(read_len)
    end

    def read_new_reference
      len = read(2).unpack("S>")[0]
      Reference.new(114, atom, read(len * 4 + 1))
    end

    def read_small_atom
      decode_atom(read(read_byte).to_sym)
    end

    def read_fun
      len = read_len
      Function.new(read_pid, atom, integer, integer, read_terms(len))
    end

    def read_new_fun
      len = read_len
      NewFunction.new(len, read(len - 4))
    end

    def read_export
      Export.new(atom, atom, integer)
    end

    def read_bit_binary
      len = read_len
      BitBinary.new(read_byte, read(len))
    end

    def read_new_float
      read(8).unpack("G")[0]
    end

    def read_atom_utf8
      len = read(2).unpack("S>")[0]
      decode_atom(read(len).to_sym)
    end

    def read_small_atom_utf8
      decode_atom(read(read_byte).to_sym)
    end

    def decode_atom(string)
      SPECIAL_ATOMS[string] || string.to_sym
    end

    def read_big(len)
      negative = read(1)
      raw =
        read(len).each_byte
          .reduce([0, 1]) { |(acc, exp), n| [acc + n * exp, exp * 256] }
      raw *= -1 if negative
      raw
    end

    def read_terms(n)
      (1..n).map { term }
    end

    def read_len
      read(4).unpack("L>")[0]
    end

    def read_byte
      @dataio.readbyte
    end

    def read(n)
      data = @dataio.read(n)
	    raise EOFError, "End of file reached" if data == nil
	    raise IOError, "data truncated" if data.size < n
      data
    end

    def error
      raise "Unexpected expression"
    end
  end
end
