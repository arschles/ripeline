#!/usr/bin/env ruby

def do_requires
  require 'redis'
  require 'optparse'
  require "#{File.dirname(__FILE__)}/stage_description"
end

begin
  do_requires
rescue LoadError
  require 'rubygems'
  do_requires
end

options = {
  :max_iterations => 1,
  :autorun => false
}

option_parser = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  
  opts.on('-d DIRECTORY', '--directory DIRECTORY', 'the directory that holds all the pipeline stages - required') do |directory|
    options[:directory] = directory.to_s
  end
  
  opts.on('-m MAX_ITERATIONS', '--max_iterations MAX_ITERATIONS', 'the maximum iterations to run each stage with') do |max_iterations|
    options[:max_iterations] = max_iterations
  end
  
  opts.on('-s STAGE_NUM', '--stage STAGE_NUM', 'the individual stage number to run (starting with 0)') do |stagenum|
    options[:stage_num] = stagenum
  end
  
  opts.on('-a', '--autorun', 'run all desired stages without requiring you to type next after each stage') do |autorun|
    options[:autorun] = true
  end
  
end

begin
  option_parser.parse!(ARGV)
rescue OptionParser::ParseError
  $stderr.print "Error: " + $! + "\n"
  exit
end

raise "must specify --directory" if not options.has_key? :directory

if not File.directory? options[:directory]
  $stderr.puts "given directory #{options[:directory]} doesn't exist"
  exit(1)
end

old_dir = Dir.getwd
puts "chdir to #{options[:directory]}"
Dir.chdir(options[:directory])
stages = Dir.glob('[0-9]*.rb')
puts "got stages #{stages.join ', '}"
Dir.chdir(old_dir)
puts "chdir to #{old_dir}"

$:.push options[:directory]

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

if options.has_key? :stage_num
  stage_numbers = options[:stage_num].split ','
  new_stages = []
  stage_numbers.each do |stage_number|
    stage_number = stage_number.to_i
    raise "invalid stage number #{stage_number}" if stage_number < 0 or stage_number >= stages.length
    new_stages.push stages[stage_number]
  end
  stages = new_stages
end

puts "running stages #{stages.join ', '}"

stages.each_with_index do |stage, idx|
  Ripeline::Runner::StageDescription.new(stage, idx, stages.length, :debug => true).create_instance do |instance|
    puts "running #{instance.class.name}"
    instance.start :max_iterations => options[:max_iterations]
    puts "completed #{instance.class.name} (#{idx})"
  end
  
  input = nil
  while input != 'next' and idx < (stages.length - 1) and options[:autorun] = false
    puts "type 'next' to continue"
    input = $stdin.gets.chomp
  end
  
end

#$redis.flushdb
#Process.kill(9, redis_proc.pid)
