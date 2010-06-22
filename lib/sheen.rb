require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'mongoid'
require 'bson'
require 'json'
require 'yaml'

module Sheen
  attr_accessor :config

  def self.env
    (ENV['SHEEN_ENV']) ? ENV['SHEEN_ENV'] : 'development'
  end

  def self.boot!
    # YAML.load(ERB.new(IO.read(config_file)).result)[Sheen.env]
    Mongoid.from_hash(YAML.load(ERB.new(IO.read(File.join('config', 'database.yml'))).result)[Sheen.env])

    $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'sheen'))

    # Dir['sheen/**/*.rb'].each { |f| require f }

    require 'cache_object'
    require 'admin'
    require 'server'
  end
end

Sheen.boot!
