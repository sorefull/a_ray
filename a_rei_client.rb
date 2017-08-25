#!/usr/bin/env ruby -w
require "socket"
require 'encrypto_signo'

class AReiClient
  CODE = 'secret'

  def initialize(server)
    @server = server
    @request = nil
    @response = nil

    keypair = EncryptoSigno.generate_keypair
    @private_key = keypair.to_s
    @public_key = keypair.public_key.to_s

    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response = Thread.new do
      loop {
        msg = decrypt(@server.gets.chomp.gsub(CODE, "\n"))
        puts "#{msg}"
      }
    end
  end

  def send
    @server_public_key = @server.gets.chomp.gsub(CODE, "\n")
    @server.puts encrypt(@public_key).gsub("\n", CODE)

    puts "Enter the username:"
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        next if msg == ''
        @server.puts encrypt(msg).gsub("\n", CODE)
        exit! if msg == 'exit!'
      }
    end
  end

  private

  def encrypt(string)
    EncryptoSigno.encrypt(@server_public_key, string)
  end

  def decrypt(encrypted_string)
    EncryptoSigno.decrypt(@private_key, encrypted_string)
  end
end

server = TCPSocket.open("localhost", 3000)
AReiClient.new(server)
