require 'rubygems'
require 'test/unit'
require "#{File.dirname(__FILE__)}/../stage"
require 'stage_test_mixin'

class ThrowingFakeStageSubclass < Ripeline::Stage
  def run arg
    raise "expected exception here"
  end
  
  protected
  
  def record_exception e
    raise e
  end
end

module Ripeline
  class Stage
    include Ripeline::StageTest
  end
end

class ThrowingStageTest < Test::Unit::TestCase
  
  def setup
    @stage = ThrowingFakeStageSubclass.new [], []
    @stage.redis.flushdb
  end
  
  def teardown
    @stage.redis.flushdb
    @stage = nil
  end
  
  def test_exception
    thrown = false
    begin
      @stage.start
    rescue Exception => e
      thrown = true
    end
    
    assert thrown
  end
  
end