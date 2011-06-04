#!/usr/bin/env ruby
#this is a daemon that runs on each node, and it exposes an RPC interface for controlling ripeline processes running on this node

def do_requires
  begin
    require 'msgpack/rpc'
    require 'stage_description'
    require 'optparse'
  rescue LoadError
    require 'rubygems'
    do_requires
  end
end
do_requires

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
    stage_name.downcase!
    start_stage_impl stage_name, options
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
  
  def stop_stage pid
    self.dout "stop_stage(#{pid})"
    stop_stage_impl pid
  end
  
  def start_all_stages
    self.dout "start_all_stages"
    started = []
    @stages.each do |stage_name|
      started.push(start_stage_impl stage_name)
    end
    started
  end
  
  def stop_all_stages
    self.dout "stop_all_stages"
    killed = []
    @running.each do |pid, stage|
      killed.push(stop_stage_impl(pid))
    end
    killed
  end
  
  def all_commands
    self.class.public_instance_methods false
  end
  
  protected
  
  def dout s
    puts s if self.debug
  end
  
  def start_stage_impl stage_name, options = {}
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
    
    pid
  end
  
  def stop_stage_impl pid
    pid = pid.to_i
    raise "#{pid} is not running" if not @running.has_key? pid
    Process.kill "HUP", pid
    stage_name = @running[pid].class_name
    @running.delete pid
    return [stage_name, pid]
  end
  
end

svr = MessagePack::RPC::Server.new
svr.listen 'localhost', 1986, RipelinedHandler.new(options[:stages_dir], options[:debug])
puts "ripelined listening on localhost:1986"
svr.run