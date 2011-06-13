module Snuggie
  autoload :Version, "snuggie/version"
  autoload :Errors,  "snuggie/errors"
  autoload :Config,  "snuggie/config"
  autoload :NOC,     "snuggie/noc"

  class << self
    attr_accessor :config
  end

  def self.configure
    yield config if block_given?
    config
  end

  self.config = Config.new
end
