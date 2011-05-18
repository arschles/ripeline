begin
  require 'json'
rescue LoadError
  require 'rubygems'
  require 'json'
end

module Ripeline
  module StageInternalHash
    
    def internal_hash_set name, val
      raise "key name must be a string" if name.class != String
      
      @redis.hset self.hash_name, name, val.to_json
    end
    
    def internal_hash_get name
      raise "key name must be a string" if name.class != String
      @redis.hget self.hash_name name
    end
    
    private
    
    def hash_name name
      return "#{self.class.name}-internal-hash:#{name}"
    end
    
  end
end