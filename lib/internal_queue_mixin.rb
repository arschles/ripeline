begin
  require 'json'
rescue LoadError
  require 'rubygems'
  require 'json'
end

module Ripeline
  module StageInternalQueue
    
    def internal_queue_pull name, pause_seconds = 5
      raise "queue name must be a string" if name.class != String
      
      elt = nil
      elt = @redis.brpop(self.queue_name name, pause_seconds) while elt == nil
      
      key = elt[0]
      val = elt[1]
      JSON::parse(val)
    end
    
    def internal_queue_push name, val
      raise "queue name must be a string" if name.class != String
      @redis.lpush(self.queue_name name, val.to_json)
      true
    end
    
    private
    
    def queue_name name
      return "#{self.class.name}-internal-queue:#{name}"
    end
    
  end
end