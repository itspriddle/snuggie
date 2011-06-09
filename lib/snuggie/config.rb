module Snuggie
  class Config
    attr_accessor :username
    attr_accessor :password

    def initialize
      @username = 'username'
      @password = 'password'
    end
  end
end
