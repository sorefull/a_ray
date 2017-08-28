#!/usr/bin/env ruby -w
require_relative "a_rei"

class AReiServer < ARei
  def initialize(port, ip)
    @server = TCPServer.open(ip, port)
    @connections = {}
    @connections[:server] = @server
    @connections[:clients] = {}
    set_keys
    run
  end

  private

  def run
    loop {
      Thread.start(@server.accept) do |client|
        client.puts @public_key.gsub("\n", '')
        client.key = decrypt(parse_key(client.gets.chomp), @private_key)

        nick_name = decrypt(client.gets.chomp, @private_key).to_sym
        @connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            client.puts encrypt('This username already exist', client.key).gsub("\n", '')
            Thread.kill self
          end
        end
        puts "Online: #{nick_name} - #{client}"
        @connections[:clients][nick_name] = client
        client.puts encrypt("Connection established, Thank you for joining! Happy chatting", client.key).gsub("\n", '')
        listen_user_messages(nick_name, client)
      end
    }.join
  end

  def listen_user_messages(username, client)
    loop {
      msg = decrypt(client.gets.chomp, @private_key)
      if msg == 'exit!'
        @connections[:clients].delete(username)
        puts "Offline: #{username} - #{client}"
        next
      end
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts encrypt("#{username.to_s}: #{msg}", other_client.key).gsub("\n", '')
        end
      end
    }
  end
end

AReiServer.new(3000, "localhost")
