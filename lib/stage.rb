def do_requires
  require 'redis'
  require 'json'
  require 'uuid'
  require 'redis-namespace'
  require "#{File.dirname(__FILE__)}/stats_mixin"
  require "#{File.dirname(__FILE__)}/exception_mixin"
  require "#{File.dirname(__FILE__)}/util"
end

begin
  do_requires
rescue LoadError
  require 'rubygems'
  do_requires
end

module Ripeline
    
  class Stage
    include Ripeline::Stats
    include Ripeline::Exception
    
    STAGES_SET_KEY = :active_stages
    
    attr_reader :pipeline_id, :identifier, :name, :pull_queue_names, :push_queue_names, :parallelizable, :stats_hash_key, :queue_wait_seconds, :valid_stats_keys, :finalized
    
    def initialize pull_queue_names, push_queue_names, options = {}
      
      pull_queue_names = [] if pull_queue_names == nil
      push_queue_names = [] if push_queue_names == nil
      
      pull_queue_names.require_type 'pull_queue_names', [Array, String, Symbol]
      push_queue_names.require_type 'push_queue_names', [Array, String, Symbol]
      
      pull_queue_names = [pull_queue_names] if pull_queue_names.class != Array
      push_queue_names = [push_queue_names] if push_queue_names.class != Array
      
      @pull_queue_names = []
      @push_queue_names = []
      @finalized = false
      
      pull_queue_names.each do |pull_queue_name|
        @pull_queue_names.push "pull_queue_#{pull_queue_name}"
      end
      
      push_queue_names.each do |push_queue_name|
        @push_queue_names.push "push_queue_#{push_queue_name}"
      end
      
      @redis = Redis.new
      @redis = Redis::Namespace.new(:Ripeline, :redis => @redis)
      
      @pipeline_id = UUID.new.generate
      @name = self.class.name
      @identifier = {:name => self.name, :pipeline_id => self.pipeline_id}
      @stats_hash_key = "#{@name}_stats"
      #a list of valid stats keys - to be used in a hash whose key is self.stats_hash_key. use these keys 
      @valid_stats_keys = [:stage_success, :stage_failure]
            
      if options.has_key? :queue_wait_seconds and options[:queue_wait_seconds].class == Fixnum
        @queue_wait_seconds = options[:queue_wait_seconds]
      else
        @queue_wait_seconds = 5
      end
      
      self.valid_stats_keys.each do |stats_key|
        @redis.hsetnx self.stats_hash_key, stats_key, 0
      end
      
    end
  
    #override these in your subclass
    def run elt
      raise "you must override the run(elt) method"
    end
    
    def stage_initialize
    end
    
    def stage_finalize
    end
    
    #####
    
    def start options = {}
      @finalized = false
      self.stage_initialize
      max_iterations = :infinity
      max_iterations = options[:max_iterations] if options.has_key? :max_iterations and options[:max_iterations].class == Fixnum
      
      begin
        
        @redis.sadd STAGES_SET_KEY, self.identifier.to_json
        
        puts "starting the #{self.name} stage (pull_queues = #{self.pull_queue_names.to_json}, push_queues = #{self.push_queue_names.to_json})"
        iteration_num = 0
        loop do
          elt = self.pull_queue_pull
          elt = {} if elt == nil
          begin
            vals = self.run elt
            self.process_run vals
            self.stat_count :stage_success
          rescue Exception => e
            puts "EXCEPTION THROWN in #{self.name}: #{e}"
            self.stat_count :stage_failure
            self.record_exception e
          end
          iteration_num += 1
          break if (max_iterations.class == Fixnum or max_iterations.class == Bignum) and iteration_num >= max_iterations
        end
      
      ensure
        @redis.srem STAGES_SET_KEY, self.identifier.to_json
      end
      
      self.stage_finalize
      @finalized = true
      
    end
    
    protected
    
    #process an individual run
    def process_run ret
      return if ret == nil
      vals = [vals] if vals.class != Array
      vals.each do |val|
        self.push_queue_push val
      end
    end
    
    #pull an element from a random pull queue
    def pull_queue_pull
      elt = nil
      return nil if self.pull_queue_names.length == 0
      
      elt = @redis.brpop(self.pull_queue_names, self.queue_wait_seconds) while elt == nil
      
      key = elt[0]
      val = elt[1]
      JSON::parse(val)
    end
    
    #push an element to a random push queue
    def push_queue_push val
      return nil if self.push_queue_names.length == 0
      key = self.push_queue_names[rand(self.push_queue_names.length - 1)]
      @redis.lpush key, val.to_json
      key
    end
    
  end
    
end