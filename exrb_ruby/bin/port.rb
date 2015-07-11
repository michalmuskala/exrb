#!/usr/bin/env ruby

require_relative "../lib/exrb/port_connection.rb"

Exrb::PortConnection.new($stdin, $stdout).run do |message|
  message
end
