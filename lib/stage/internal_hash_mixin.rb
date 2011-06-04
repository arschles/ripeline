module Ripeline
  module StageMixins
    module InternalHash
    
      def internal_hash_set name, val
        @redis.hset((self.internal_hash_name name), val)
      end
    
      def internal_hash_get hash_name, hash_key
        @redis.hget(self.internal_hash_name(name), hash_key)
      end
      
      def internal_hash_name name
        return "#{self.class.name}-internal-hash:#{name}"
      end
    
    end
  end
end