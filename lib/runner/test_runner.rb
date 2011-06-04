#!/usr/bin/env ruby

#runs each pipeline stage in sequence. no separate processes per stage, no concurrency.
#TODO: use a mock redis here

def do_requires
  begin
    require 'optparse'
    require "stage_description"
  rescue LoadError
    require 'rubygems'
    do_requires
  end
end
do_requires

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
stages = Ripeline::Runner::StageDescription.for_dir options[:directory], :debug => true

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

puts "running #{stages.length} stages"

stages.each_with_index do |stage, idx|
  stage.create_instance do |instance|
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
