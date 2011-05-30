#!/usr/bin/env ruby
def do_requires
  require "optparse"
  require "thread"
  require "#{File.dirname(__FILE__)}/stage_description"
end

begin
  do_requires
rescue LoadError
  require 'rubygems'
  do_requires
end

options = {}
option_parser = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  
  opts.on('-d DIRECTORY', '--directory DIRECTORY', 'the directory that holds all the pipeline stages - required') do |directory|
    options[:directory] = directory.to_s
  end
end.parse!

raise "must specify --directory" if not options.has_key? :directory
stages = Ripeline::Runner::StageDescription.for_dir options[:directory], :debug => true

#todo: one process per stage, each in its own thread so we can collect stdout separately
=begin
threads = []
stdout_mutex = Mutex.new

stages.each do |stage|
  thread = Thread.new do
    stage.create_instance do |instance|
      
      stdout_mutex.synchronize do
        puts "starting #{instance.class.name}"
      end
      
      instance.start
    end
  end
  threads.push thread
end

threads.each do |thread|
  thread.join
end
=end