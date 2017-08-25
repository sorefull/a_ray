#!/usr/bin/env ruby -w
require "socket"
require 'encrypto_signo'

class AReiClient
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
        msg = decrypt get_key(@server.gets.chomp)
        puts "#{msg}"
      }
    end
  end

  def send
    @server_public_key = get_key(@server.gets.chomp)
    @server.puts encrypt(@public_key).gsub("\n", '')

    puts "Enter the username:"
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        next if msg == ''
        @server.puts encrypt(msg).gsub("\n", '')
        exit! if msg == 'exit!'
      }
    end
  end

  private

  def get_key(string)
    string.gsub!('-----BEGIN PUBLIC KEY-----', "-----BEGIN PUBLIC KEY-----\n")
    string.gsub!('-----END PUBLIC KEY-----', "\n-----END PUBLIC KEY-----")
    wrap_long_string(string, 66)
  end

  def wrap_long_string(text,max_width = 20)
    (text.length < max_width) ?
      text :
      text.scan(/.{1,#{max_width}}/).join("\n")
  end

  def encrypt(string)
    EncryptoSigno.encrypt(@server_public_key, string)
  end

  def decrypt(encrypted_string)
    EncryptoSigno.decrypt(@private_key, encrypted_string)
  end
end

server = TCPSocket.open("localhost", 3000)
AReiClient.new(server)
