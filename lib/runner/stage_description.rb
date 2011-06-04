module Ripeline
  module Runner
    class StageDescription
      
      attr_reader :stage_filename, :stage_num, :num_total_stages, :debug, :class_name, :stage_filename_no_rb
      
      #get the stage descriptions for a given directory, sorted by stage name
      def self.for_dir dir, options = {:debug => false}
        raise "#{dir} doesn't exist" if not File.directory? dir
        old_dir = Dir.getwd
        Dir.chdir(dir)
        stages = Dir.glob('[0-9]*.rb')
        Dir.chdir(old_dir)
        
        $:.push dir
        
        stages = stages.sort do |a, b|
          a_split = a.split '_'
          b_split = b.split '_'
          a_num = a_split[0].to_i
          b_num = b_split[0].to_i
          
          a_num <=> b_num
        end
        
        ret = []
        stages.each_with_index do |stage, idx|
          ret.push self.new stage, idx, stage.length, options
        end
        ret
      end
        
      
      def initialize stage_filename, stage_num, num_total_stages, options = {:debug => false}
        @stage_filename = stage_filename
        @stage_num = stage_num
        @num_total_stages = num_total_stages
        @debug  = options[:debug]
        
        stage_split = self.stage_filename.split '.'
        stage_no_rb = stage_split[Range.new(0, stage_split.length-2)].join
        @stage_filename_no_rb = stage_no_rb
        
        split_by_underscore = stage_no_rb.split('_')
        split_by_underscore = split_by_underscore[Range.new(1, split_by_underscore.length-1)]
        @class_name = ""
        split_by_underscore.each do |piece|
          @class_name << piece.capitalize
        end
      end
      
      def get_class
        require @stage_filename_no_rb
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