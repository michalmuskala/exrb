require "stringio"

require_relative "./decoder.rb"
require_relative "./encoder.rb"

module Exrb
  class PortConnection
    def initialize(streamin, streamout)
      @streamin = prepare(streamin)
      @streamout = prepare(streamout)
    end

    def run(&block)
      loop(block)
    end

    private

    def loop(handler)
      while len = read_len
        decoded = decode(read(len))
        response = handle_message(decoded, handler)
        encoded = encode(response)
        write_len(encoded.size)
        write(encoded)
      end
    end

    def handle_message(message, handler)
      ref = message.elem(0)
      response = handler.call(message.elem(1))
      message.put_elem(1, response)
    end

    def encode(message)
      io = StringIO.new
      Encoder.new(io).call(message)
      io.string.force_encoding("ASCII")
    end

    def decode(payload)
      Decoder.new(StringIO.new(payload)).call
    end

    def prepare(stream)
      stream.sync = true
      stream.binmode
      stream
    end

    def read_len
      data = read(4)
      data && data.unpack("L>")[0]
    end

    def write_len(len)
      write([len].pack("L>"))
    end

    def write(data)
      n = @streamout.write(data)
      raise IOError, "data truncated" if n < data.size
    end

    def read(n)
      data = @streamin.read(n)
      return data if data == nil
      return nil if data.size < n
      data
    end
  end
end
