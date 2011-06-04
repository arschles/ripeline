def do_requires
  require 'redis'
  require 'uuid'
  require 'redis-namespace'
  require 'open-uri'
  require "stats_mixin"
  require "exception_mixin"
  require "util"
end
do_requires

module Ripeline
    
  class Stage
    include Ripeline::Stats
    include Ripeline::Exception
    
    STAGES_SET_KEY = :active_stages
    
    attr_reader :pipeline_id, :identifier, :name, :pull_queue_names, :push_queue_names, :parallelizable, :stats_hash_key, :queue_wait_seconds, :finalized, :debug
    
    def initialize pull_queue_names, push_queue_names, options = {:debug => false}
      
      @debug = true if options[:debug] == true
      
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
        @pull_queue_names.push pull_queue_name
      end
      
      push_queue_names.each do |push_queue_name|
        @push_queue_names.push push_queue_name
      end
      
      @redis = Redis.new
      @redis = Redis::Namespace.new(:Ripeline, :redis => @redis)
      
      @pipeline_id = UUID.new.generate
      @name = self.class.name
      @identifier = {:name => self.name, :pipeline_id => self.pipeline_id}
      @stats_hash_key = "#{@name}_stats"
            
      if options.has_key? :queue_wait_seconds and options[:queue_wait_seconds].class == Fixnum
        @queue_wait_seconds = options[:queue_wait_seconds]
      else
        @queue_wait_seconds = 5
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
    
    def start options = {:max_iterations => :infinity}
      @finalized = false
      self.stage_initialize
      
      begin        
        @redis.sadd STAGES_SET_KEY, self.identifier
        
        iteration_num = 0
        loop do
          elt = self.pull_queue_pull
          elt = {} if elt == nil
          begin
            vals = self.run elt
            if vals != nil
              vals = [vals] if vals.class != Array
              vals.each do |val|
                self.push_queue_push val if val != nil
              end
            else
              self.stat_count :stage_nil_return
            end
            
            self.stat_count :stage_success
            
            iteration_num += 1
            break if options[:max_iterations] != :infinity and iteration_num >= options[:max_iterations]
            
          rescue Exception, OpenURI::HTTPError => e
            puts "EXCEPTION THROWN in #{self.name}: #{e}"
            self.stat_count :stage_failure
            self.record_exception e
          end
          
        end
      
      ensure
        @redis.srem STAGES_SET_KEY, self.identifier
      end
      
      self.stage_finalize
      @finalized = true
      
    end
    
    protected
    
    def debug_out s
      puts "[debug] #{s}" if self.debug
    end
    
    #pull an element from a random pull queue
    def pull_queue_pull
      return nil if self.pull_queue_names.length == 0
      
      puts "pulling from queues #{self.pull_queue_names.join ', '}"
      
      elt = nil
      elt = @redis.brpop(self.pull_queue_names, self.queue_wait_seconds) while elt == nil
      
      key = elt[0]
      val = elt[1]
      self.debug_out "got data from pull queue #{key}"
      Marshal.load val
    end
    
    #push an element to a random push queue
    def push_queue_push val
      return nil if self.push_queue_names.length == 0
      key = self.push_queue_names[rand(self.push_queue_names.length - 1)]
      self.debug_out "pushing data onto push queue #{key}"
      @redis.lpush key, Marshal.dump(val)
      key
    end
    
  end
    
end