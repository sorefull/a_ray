#!/usr/bin/env ruby -w
require "socket"
require 'encrypto_signo'

class TCPSocket
  attr_accessor :key
end

class AReiServer
  CODE = 'secret'

  def initialize(port, ip)
    @server = TCPServer.open(ip, port)
    @connections = {}
    @connections[:server] = @server
    @connections[:clients] = {}

    keypair = EncryptoSigno.generate_keypair
    @private_key = keypair.to_s
    @public_key = keypair.public_key.to_s

    run
  end

  def run
    loop {
      Thread.start(@server.accept) do |client|
        client.puts @public_key.gsub("\n", CODE)
        client.key = decrypt(client.gets.chomp.gsub(CODE, "\n"))

        nick_name = decrypt(client.gets.chomp.gsub(CODE, "\n")).to_sym
        @connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            client.puts encrypt('This username already exist', client.key).gsub("\n", CODE)
            Thread.kill self
          end
        end
        puts "Online: #{nick_name} - #{client}"
        @connections[:clients][nick_name] = client
        client.puts encrypt("Connection established, Thank you for joining! Happy chatting", client.key).gsub("\n", CODE)
        listen_user_messages(nick_name, client)
      end
    }.join
  end

  def listen_user_messages(username, client)
    loop {
      msg = decrypt(client.gets.chomp.gsub(CODE, "\n"))
      if msg == 'exit!'
        @connections[:clients].delete(username)
        puts "Offline: #{username} - #{client}"
        next
      end
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts encrypt("#{username.to_s}: #{msg}", other_client.key).gsub("\n", CODE)
        end
      end
    }
  end

  private

  def encrypt(string, client_public_key)
    EncryptoSigno.encrypt(client_public_key, string)
  end

  def decrypt(encrypted_string)
    EncryptoSigno.decrypt(@private_key, encrypted_string)
  end
end

AReiServer.new(3000, "localhost")
