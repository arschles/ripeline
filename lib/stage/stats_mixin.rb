def do_requires
  begin    
    require 'redis'
    require 'json'
    require 'uuid'
    require 'redis-namespace'
  rescue LoadError
    require 'rubygems'
    do_requires
  end
end
do_requires

module Ripeline
  
  module Stats
    
    def all_stats
      @redis.hgetall self.stats_key
    end
    
    protected
    
    def stat_count key
      @redis.hincrby self.stats_hash_key, key, 1
    end
      
  end
  
end