require "socket"
require 'encrypto_signo'

class ARei
  def set_keys
    keypair = EncryptoSigno.generate_keypair
    @private_key = keypair.to_s
    @public_key = keypair.public_key.to_s
  end

  private

  def parse_key(string)
    string.gsub!('-----BEGIN PUBLIC KEY-----', "-----BEGIN PUBLIC KEY-----\n")
    string.gsub!('-----END PUBLIC KEY-----', "\n-----END PUBLIC KEY-----")
    wrap_long_string(string, 66)
  end

  def wrap_long_string(text,max_width = 20)
    (text.length < max_width) ?
      text :
      text.scan(/.{1,#{max_width}}/).join("\n")
  end

  def encrypt(string, key)
    EncryptoSigno.encrypt(key, string)
  end

  def decrypt(encrypted_string, key)
    EncryptoSigno.decrypt(key, encrypted_string)
  end
end

class TCPSocket
  attr_accessor :key
end
