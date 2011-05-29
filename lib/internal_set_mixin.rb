module Ripeline
  module StageMixins
    module InternalSet
    
      def internal_set_add name, val
        elt = nil
        elt = @redis.sadd((self.internal_set_name name), val)
      end
    
      def internal_set_include? name, val
        @redis.sismember((self.internal_set_name name), val)
      end
      
      def internal_set_pop name
        @redis.spop(self.internal_set_name name)
      end
      
      def internal_set_name name
        return "#{self.class.name}-internal-set:#{name}"
      end
    
    end
  end
end