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
  
  module Exception
    
    @@mongo_Exceptions_coll = nil
    protected
    
    def record_exception e
      
      raise "e must be an exception" if not e.is_a? Exception
      
      if @@mongo_exceptions_coll == nil
        mongo_conn = Mongo::Connection.new
        mongo_db = mongo_conn[:octodoc]
        @@mongo_exceptions_coll = monbo_db["#{self.name}-exceptions"]
      end
      
      @@mongo_exceptions_coll.insert :from => self.pipeline_identifier, :exception_message => e.message, :exception_backtrace => e.backtrace
      
    end
  
  end
  
end