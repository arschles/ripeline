#!/usr/bin/env ruby

begin
  require 'redis'
  require 'optparse'
rescue LoadError
  require 'rubygems'
  require 'redis'
end

dir = nil
max_iterations = 1
stage_num = nil

optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  
  opts.on('-d', '--dir', 'the directory that holds all the pipeline stages') do |directory|
    dir = directory
  end
  
  opts.on('-m', '--max_iterations', 'the maximum iterations to run each stage with') do |maxiterations|
    max_iterations = maxiterations
  end
  
  #todo:implement this
  #opts.on('-s', '--stage', 'the individual stage number to run') do |stagenum|
  #  stage_num = stagenum
  #end
  
end


if dir == nil
  $stderr.puts "must specify directory that holds ripeline stages"
  exit(1)
end

if not File.directory? dir
  $stderr.puts "given directory #{dir} doesn't exist"
  exit(1)
end

old_dir = Dir.getwd
puts "chdir to #{dir}"
Dir.chdir(dir)
stages = Dir.glob('[0-9]*.rb')
puts "got stages #{stages.join ', '}"
Dir.chdir(old_dir)
puts "chdir to #{old_dir}"

$:.push dir

stages = stages.sort do |a, b|
  a_split = a.split '_'
  b_split = b.split '_'
  a_num = a_split[0].to_i
  b_num = b_split[0].to_i
  
  a_num <=> b_num
end

#puts "starting redis"
#redis_proc = IO.popen "redis-server"
#$redis = Redis.new

stages.each_with_index do |stage, idx|
  #require the file
  stage_split = stage.split '.'
  stage_no_rb = stage_split[Range.new(0, stage_split.length-2)].join
  
  #get the class name
  split_by_underscore = stage_no_rb.split('_')
  split_by_underscore = split_by_underscore[Range.new(1, split_by_underscore.length-1)]
  class_name = ""
  split_by_underscore.each do |piece|
    class_name << piece.capitalize
  end
  
  require stage_no_rb
  input_queue = nil
  output_queue = nil
  input_queue = "queue_#{idx}" if idx > 0
  output_queue = "queue_#{idx+1}" if idx < (stages.length - 1)
  
  puts "running stage #{stage_no_rb} (#{class_name})"
  stage_inst = Object.const_get(class_name).new(input_queue, output_queue)
  stage_inst.start :max_iterations => max_iterations
  
  puts "type 'next' to continue"
  input = $stdin.gets.chomp
  if input == 'next'
    next
  else
    puts "type 'next' to continue"
  end
  
end

#$redis.flushdb
#Process.kill(9, redis_proc.pid)
