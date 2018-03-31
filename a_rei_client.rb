#!/usr/bin/env ruby -w
require_relative "a_rei"

class AReiClient < ARei
  def initialize(server)
    @server = server
    @request = nil
    @response = nil
    set_keys
    listen
    send
    @request.join
    @response.join
  end

  private

  def listen
    @response = Thread.new do
      loop {
        msg = decrypt(@server.gets.chomp, @private_key)
        puts "#{msg}"
      }
    end
  end

  def send
    @server_public_key = parse_key(@server.gets.chomp)
    @server.puts encrypt(@public_key, @server_public_key).gsub("\n", '')

    puts "Enter the username:"
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        next if msg == ''
        @server.puts encrypt(msg, @server_public_key).gsub("\n", '')
        exit! if msg == 'exit!'
      }
    end
  end
end

server = TCPSocket.open('localhost', 3000)
AReiClient.new(server)
