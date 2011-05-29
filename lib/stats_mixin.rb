def do_requires
  require 'redis'
  require 'json'
  require 'uuid'
  require 'redis-namespace'
end

begin
  do_requires
rescue LoadError
  require 'rubygems'
  do_requires
end

module Ripeline
  
  module Stats
    
    def all_stats
      @redis.hgetall self.stats_key
    end
    
    protected
    
    def stat_count key
      raise "invalid stats key #{key}" if not self.valid_stats_keys.include? key
      @redis.hincrby self.stats_hash_key, key, 1
    end
    
    def add_valid_stats_key key
      @valid_stats_keys.push key if not @valid_stats_keys.include? key
    end
  
  end
  
end