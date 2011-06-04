require 'rubygems'
$:.push "#{File.dirname(__FILE__)}/../lib/stage"
require 'test/unit'
require "stage"
require 'stage_test_mixin'

class FakeStageSubclass < Ripeline::Stage
  def run arg
    true
  end
end

module Ripeline
  class Stage
    include Ripeline::StageMixins::Test
  end
end

class SimpleStageTest < Test::Unit::TestCase
  
  def setup
    @stage = FakeStageSubclass.new [], []
    @stage.redis.flushdb
  end
  
  def teardown
    @stage.redis.flushdb
    @stage = nil
  end
    
  def test_initialize
    @stage = FakeStageSubclass.new ["stage_pull_queue"], ["stage_push_queue"]
    assert_equal @stage.pipeline_id.class, String
    assert @stage.identifier.has_key? :name
    assert @stage.identifier.has_key? :pipeline_id
    assert_equal @stage.pipeline_id.class, String
    assert_equal @stage.pull_queue_names.class, Array
    assert_equal @stage.push_queue_names.class, Array
  end
  
  def test_run
    assert @stage.run({:fake => true})
  end
    
end