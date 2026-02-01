module Paperclip
  class WatermarkText < Processor

    def initialize(file, options = {}, attachment = nil)
      super
      @file = file
      @instance = attachment.instance
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
    end

    def make
      if @current_format == '.pdf'
        pdf = MiniMagick::Image.open(File.expand_path(@file.path))
        temp_file = TempfileFactory.new.generate()
        pdf.combine_options do |cmd|
          cmd.gravity 'south'
          cmd.draw 'text 10,10 "whatever"'
          cmd.fill 'black'
        end
        temp_file = File.open(pdf.path)
        return temp_file
      else
        return @file
      end
    end
  end
end