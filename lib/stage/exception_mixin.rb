def do_requires
  begin
    require 'redis'
    require 'json'
    require 'uuid'
    require 'mongo'
    require 'redis-namespace'
  rescue LoadError
    require 'rubygems'
    do_requires
  end
end
do_requires

module Ripeline
  module Exception
    @@mongo_exceptions_coll = nil
    
    protected
    
    def record_exception e
      return
      if @@mongo_exceptions_coll == nil
        mongo_conn = Mongo::Connection.new
        mongo_db = mongo_conn[:octodoc]
        @@mongo_exceptions_coll = monbo_db["#{self.name}-exceptions"]
      end
      
      @@mongo_exceptions_coll.insert :from => self.pipeline_identifier, :exception_message => e.message, :exception_backtrace => e.backtrace
      
    end
  
  end
  
end