require_relative "./types.rb"
require_relative "../exrb.rb"

module Exrb
  class Encoder
    ENCODERS = {
      Fixnum       => :write_integer,
      Symbol       => :write_atom,
      Float        => :write_new_float,
      NewReference => :write_new_reference,
      Reference    => :write_reference,
      Port         => :write_port,
      Pid          => :write_pid,
      Tuple        => :write_large_tuple,
      Hash         => :write_map,
      ErlangNil    => :write_nil,
      Array        => :write_list,
      ImproperList => :write_improper_list,
      String       => :write_string,
      Binary       => :write_binary,
      Bignum       => :write_large_big,
      Function     => :write_fun,
      NewFunction  => :write_new_fun,
      Export       => :write_export,
      BitBinary    => :write_bit_binary,
      TrueClass    => :write_true_atom,
      FalseClass   => :write_false_atom,
      NilClass     => :write_nil_atom
    }.freeze

    @@custom_encoders = {}

    def self.register_encoder(klass, encoder)
      @@custom_encoders[klass] = encoder
    end

    def initialize(dataio)
      @dataio = dataio
    end

    def call(term)
      write_byte(PROTOCOL_VERSION)
      term(term)
    end

    private

    def term(term)
      klass = term.class
      if encoder = ENCODERS[klass]
        send(encoder, term)
      elsif encoder = @@custom_encoders[klass]
        encoder.call(term)
      else
        error(term)
      end
    end

    def write_integer(int)
      write_byte(98)
      write([int].pack("l>"))
    end

    def write_atom(sym)
      write_byte(100)
      atom = sym.to_s.encode("ASCII")
      write_short_len(atom.size)
      write(atom)
    end

    def write_new_float(float)
      write_byte(70)
      write([float].pack("G"))
    end

    def write_new_reference(ref)
      write_byte(114)
      write_short_len(ref.length)
      write_atom(ref.node)
      write(ref.value)
    end

    def write_reference(ref)
      write_byte(101)
      write_atom(ref.node)
      write(ref.value)
    end

    def write_port(port)
      write_byte(102)
      write_atom(port.node)
      write(port.value)
    end

    def write_pid(pid)
      write_byte(103)
      write_atom(pid.node)
      write(pid.value)
    end

    def write_large_tuple(tuple)
      write_byte(105)
      write_len(tuple.size)
      write_terms(tuple.values)
    end

    def write_map(hash)
      write_byte(116)
      write_len(hash.size)
      write_terms(hash.entries.flatten(1))
    end

    def write_nil(_nil = nil)
      write_byte(106)
    end

    def write_list(list)
      write_byte(108)
      write_len(list.size)
      write_terms(list)
      write_nil
    end

    def write_improper_list(list)
      write_byte(108)
      write_len(list.size)
      write_terms(list.list)
      term(list.tail)
    end

    def write_string(string)
      write_byte(109)
      write_len(string.size)
      write(string)
    end

    def write_binary(binary)
      write_byte(109)
      write_len(binary.size)
      write(binary.value)
    end

    def write_large_big(big)
      write_byte(111)
      len = (big.bit_length / 8.0).ceil
      write_len(len)
      write_byte(bit < 0 ? 1 : 0)
      (0..len).each {
        write_byte(big & 255)
        big >>= 8
      }
    end

    def write_fun(fun)
      write_byte(117)
      write_len(fun.size)
      write_pid(fun.pid)
      write_atom(fun.mod)
      write_integer(fun.idx)
      write_integer(fun.uniq)
      write_terms(fun.terms)
    end

    def write_new_fun(fun)
      write_byte(112)
      $stderr.puts fun.size, fun.data.size
      write_len(fun.size)
      write(fun.data)
    end

    def write_export(export)
      write_byte(113)
      write_atom(export.mod)
      write_atom(export.fun)
      write_integer(export.arity)
    end

    def write_bit_binary(binary)
      write_byte(77)
      write_len(binary.size)
      write_byte(binary.bits)
      write(binary.value)
    end

    def write_true_atom(_true = true)
      write_atom(:true)
    end

    def write_false_atom(_false = false)
      write_atom(:false)
    end

    def write_nil_atom(_nil = nil)
      write_atom(:nil)
    end

    def write_terms(terms)
      terms.each { |term| term(term) }
    end

    def write_byte(byte)
      write([byte].pack("C"))
    end

    def write_short_len(len)
      write([len].pack("S>"))
    end

    def write_len(len)
      write([len].pack("L>"))
    end

    def write(data)
      n = @dataio.write(data)
      raise IOError, "data truncated" if data.size < n
    end

    def error(term)
      raise "Unexpected term #{term.inspect}"
    end
  end
end
