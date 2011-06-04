#!/usr/bin/env ruby
#this is a daemon that runs on each node, and it exposes an RPC interface for controlling ripeline processes running on this node
require 'rubygems'
require 'msgpack/rpc'
require "#{File.dirname(__FILE__)}/stage_description"
require 'optparse'

options = {
  :stages_dir => "#{File.dirname(__FILE__)}/stages/",
  :debug => false
}

OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  
  opts.on('-d DIRECTORY', '--dir DIRECTORY', 'the directory that holds all the pipeline stages - required') do |directory|
    options[:stages_dir] = directory.to_s
  end
  
  opts.on('--debug', 'whether to print debugging statements') do |debug|
    options[:debug] = true
  end  
end.parse!(ARGV)

class RipelinedHandler
  attr_reader :stages, :debug
  
  def initialize stages_dir, debug = false
    @debug = debug
    stage_descriptions = Ripeline::Runner::StageDescription.for_dir stages_dir
    @stages = {}
    stage_descriptions.each do |stage_description|
      class_name = stage_description.class_name
      self.dout "loaded stage #{class_name}"
      @stages[class_name.downcase] = stage_description
      @running = {}
    end
  end
  
  def start_stage stage_name, options = {}
    self.dout "start_stage(#{stage_name})"
    stage_name = stage_name.downcase
    raise "no known stage #{stage_name}" if not self.stages.has_key? stage_name
    
    devnull = File.new('/dev/null', 'w')
    
    pid = Process.fork do 
      stage = @stages[stage_name]
      stage.create_instance do |instance|
        $stdout = devnull
        $stderr = devnull
        if options.length == 0
          instance.start
        else
          instance.start options
        end
      end
    end.to_i
    
    @running[pid] = @stages[stage_name]
    
    [stage_name, pid]
  end
  
  def start_all_stages
    self.dout "start_all_stages"
    started = []
    @stages.each do |stage_info|
      stage_name = stage_info[0]
      self.disable_debug do
        started.push(start_stage stage_name)
      end
    end
    started
  end
  
  def stop_stage pid
    self.dout "stop_stage(#{pid})"
      pid = pid.to_i
      raise "#{pid} is not running" if not @running.has_key? pid
      Process.kill "HUP", pid
      stage_name = @running[pid].class_name
      @running.delete pid
      return [stage_name, pid]
  end
    
  def stop_all_stages
    self.dout "stop_all_stages"
    killed = []
    @running.each do |pid, stage|
      self.disable_debug do
        killed.push(stop_stage(pid))
      end
    end
    killed
  end
  
  
  def running_stages
    self.dout "running_stages"
    ret = []
    @running.each do |pid, stage|
        ret.push [pid, stage.class_name]
    end
    ret
  end
  
  def loaded_stages
    self.dout "loaded_stages"
    @stages.map {|stage| stage[0]}
  end
    
  def commands
    self.class.public_instance_methods false
  end
  
  def kill_server
    self.dout "kill_server"
    self.disable_debug do
      stop_all_stages
    end
    exit(0)
  end
  
  protected
  
  def disable_debug &block
    old_dbg = @debug
    @debug = false
    block.call
    @debug = old_dbg
  end
  
  def dout s
    puts s if self.debug
  end
    
end

svr = MessagePack::RPC::Server.new
svr.listen 'localhost', 1986, RipelinedHandler.new(options[:stages_dir], options[:debug])
puts "ripelined listening on localhost:1986"
svr.run