require 'rubygems'
require 'test/unit'
require 'msgpack/rpc'

#requires that a ripelined daemon is running at localhost:1986, and that there is a stage called 'decodefiles' that ripeline has loaded
class RipelinedTest < Test::Unit::TestCase
  
  def setup
    @client = MessagePack::RPC::Client.new('localhost', 1986)
    @client.call :stop_all_stages
  end
  
  def teardown
    @client.close
  end
  
  #a test that starts up the 'decode_files' stage, makes sure that it is listed as running, and then stops it
  def test_run_list_stop
    self.assert_not_running 'decodefiles'
    pid = @client.call :start_stage, 'decodefiles'
    self.running_assert do |running|
      assert running.map{|r| true if r[0] == pid and r[1] == 'decodefiles'}, "[#{pid}, 'decodefiles'] wasn't present in running_stages"
    end
    @client.call :stop_stage, pid
    self.assert_not_running 'decodefiles'
  end
  
  def test_run_many_stop_all
    self.assert_not_running 'decodefiles'
    (1..10).each do |i|
      pid = @client.call :start_stage, 'decodefiles'
    end
    self.running_assert do |running|
      assert_equal running.length, 10, "expected 10 stages running, instead found #{running.length}"
    end
    @client.call :stop_all_stages
    
    self.running_assert do |running|
      assert_equal running.length, 0, "expected 0 stages running, found #{running.length} instead"
    end
  end
  
  protected
  
  def running_assert &block
    running = @client.call :running_stages
    assert running.class == Array, "running_stages didn't return an array"
    running.each_with_index do |r, idx|
      assert r.class == Array, "element #{idx} of running_stages isn't an Array"
      assert r.length == 2, "element #{idx} of running_stages isn't length 2"
      assert r[0].class == Fixnum, "first element of element #{idx} of running_stages isn't a Fixnum (pid expected)"
      assert r[1].class == String, "second element of element #{idx} of running_stages isn't a String (stage name expected)"
    end
    block.call running
  end
  
  def assert_not_running name
    self.running_assert do |running|
      running.each_with_index do |running, idx|
        assert_not_equal running[1], name, "element #{idx} of running was #{name}"
      end
    end
  end
    
    
  
end