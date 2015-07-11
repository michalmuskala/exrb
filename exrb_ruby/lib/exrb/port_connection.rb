require "stringio"

require_relative "./decoder.rb"

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
      while packed = read(4)
        len = packed.unpack("L>")[0]
        raw = read(len)
        payload = StringIO.new(raw)
        response = handle_message(decode(payload), handler)
        @streamout.write(packed)
        @streamout.write(raw)
      end
    end

    def handle_message(message, handler)
      ref = message.elem(0)
      response = handler.call(message.elem(1))
      message.put_elem(1, response)
    end

    def decode(payload)
      Decoder.new(payload).call
    end

    def prepare(stream)
      stream.sync = true
      stream.binmode
      stream
    end

    def read(n)
      data = @streamin.read(n)
      return data if data == nil
      return nil if data.size < n
      data
    end
  end
end
