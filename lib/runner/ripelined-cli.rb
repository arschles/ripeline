#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require 'highline/import'
require 'msgpack/rpc'
require 'pp'

options = {
  :host => 'localhost',
  :port => 1986
}

option_parser = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  
  opts.on('-h HOST', '--host DIRECTORY', 'the host to connect to') do |host|
    options[:host] = host.to_s
  end
  
  opts.on('-p PORT', '--port PORT', 'the port to connect to') do |port|
    options[:port] = port.to_i
  end
  
end.parse!(ARGV)

loop do
  input = ask('> ', String)
  
  case input
  when 'host'
    puts "connected to #{options[:host]}:#{options[:port]}"
  when 'exit'
    puts "down, but not out"
    exit(0)
  when ''
    next
  else
    client = MessagePack::RPC::Client.new options[:host], options[:port]
    in_split = input.split ' '
    cmd = in_split[0]
    begin
      pp client.call(cmd, *in_split[Range.new(1, in_split.length-1)])
    rescue MessagePack::RPC::RuntimeError => boom
      pp boom
    end
  end
end