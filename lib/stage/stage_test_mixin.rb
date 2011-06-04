def do_requires
  begin
    require 'json'
  rescue LoadError
    require 'rubygems'
    do_requires
  end
end
do_requires

module Ripeline
  module StageMixins
    module Test
    
      attr_reader :redis
    
      def insert_into_pull_queues elt
        @pull_queue_names.each do |pull_queue_name|
          @redis.lpush pull_queue_name, Marshal.dump(elt)
        end
      
      end
    
      def in_push_queue? elt
        elt = Marshal.dump(elt)
        @push_queue_names.each do |push_queue_name|
          len = @redis.llen push_queue_name
          all_elts = @redis.lrange push_queue_name, 0, len-1
          all_elts.each do |e|
            return true if elt == e
          end
        end
        false
      end
    
    end
  end
end