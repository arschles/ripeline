def do_requires
  require 'redis'
  require 'json'
  require 'uuid'
  require "#{File.dirname(__FILE__)}/../bootstrap"
  require 'object_additions'
  require 'redis-namespace'
end

begin
  do_requires
rescue LoadError
  require 'rubygems'
  do_requires
end

module Ripeline
  
  module Exception
    
    protected
    
    def record_exception e
      raise "e must be an Exception subclass" if not e.is_a? Exception
      #TODO: impl this
    end
  
  end
  
end