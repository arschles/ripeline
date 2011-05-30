module Ripeline
  module Runner
    class StageDescription
      
      attr_reader :stage_filename, :stage_num, :num_total_stages, :debug
      
      def initialize stage_filename, stage_num, num_total_stages, options = {:debug => false}
        @stage_filename = stage_filename
        @stage_num = stage_num
        @num_total_stages = num_total_stages
        @debug  = options[:debug]
      end
      
      def get_class
        #require the file
        stage_split = self.stage_filename.split '.'
        stage_no_rb = stage_split[Range.new(0, stage_split.length-2)].join

        #get the class name
        split_by_underscore = stage_no_rb.split('_')
        split_by_underscore = split_by_underscore[Range.new(1, split_by_underscore.length-1)]
        class_name = ""
        split_by_underscore.each do |piece|
          class_name << piece.capitalize
        end

        require stage_no_rb
        Object.const_get class_name
      end
      
      #returns an array of 2 arrays. first array is all the pull queues, second is all the push queues.
      #either element can be nil if it's the first or last stage
      def get_queue_names
        return [nil, "queue_1"] if self.stage_num == 0
        return [["queue_#{self.stage_num}"], nil] if self.stage_num == (self.num_total_stages - 1)
        return [["queue_#{self.stage_num}"], ["queue_#{self.stage_num + 1}"]]
      end
      
      def create_instance &block
        queues = self.get_queue_names
        stage_class = self.get_class
        instance = stage_class.new queues[0], queues[1], :debug => self.debug
        block.call instance
      end
    end
  end
end