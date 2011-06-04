require 'rubygems'
$:.push "#{File.dirname(__FILE__)}/../lib/stage"
require 'test/unit'
require 'stage'
require 'stage_test_mixin'
require 'json'

TEST_PULL_QUEUE_PAYLOAD = Marshal.dump({:test => true, :queue_type => "pull"})
TEST_PUSH_QUEUE_PAYLOAD = Marshal.dump({:test => true, :queue_type => "push"})

class RealWorldSubclass < Ripeline::Stage
  def run arg
    return TEST_PUSH_QUEUE_PAYLOAD
  end
end

module Ripeline
  class Stage
    include Ripeline::StageMixins::Test
  end
end

class PracticalTest < Test::Unit::TestCase
  
  def setup
    @stage = RealWorldSubclass.new "test", "test"
    @stage.redis.flushdb
    @stage.insert_into_pull_queues TEST_PULL_QUEUE_PAYLOAD
  end
  
  def teardown
    @stage.redis.flushdb
    @stage = nil
  end
  
  def test_consume
    @stage.start :max_iterations => 1
    assert @stage.in_push_queue? TEST_PUSH_QUEUE_PAYLOAD
  end
  
end