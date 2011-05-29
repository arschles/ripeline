module Ripeline
  module StageMixins
    module InternalQueue
      
      def internal_queue_pull name, pause_seconds = 5
        elt = nil
        elt = @redis.brpop(self.internal_queue_name(name), pause_seconds) while elt == nil
        
        key = elt[0]
        val = elt[1]
        val
      end
      
      def internal_queue_push name, val
        @redis.lpush(self.internal_queue_name(name), val)
        true
      end
      
      def internal_queue_name name
        return "#{self.class.name}-internal-queue:#{name}"
      end
      
    end
  end
end