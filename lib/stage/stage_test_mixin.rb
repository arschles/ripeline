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
  module StageTest
    
    attr_reader :redis
    
    def insert_into_pull_queues elt
      @pull_queue_names.each do |pull_queue_name|
        @redis.lpush pull_queue_name, elt.to_json
      end
      
    end
    
    def in_push_queue? elt
      @push_queue_names.each do |push_queue_name|
        len = @redis.llen push_queue_name
        all_elts = @redis.lrange push_queue_name, 0, len-1
        all_elts.each do |e|
          return true if elt.to_json == e
        end
      end
      false
    end
    
  end
end