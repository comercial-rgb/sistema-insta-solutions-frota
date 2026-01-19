module Paperclip
  class WatermarkImage < Processor


    def initialize(file, options = {}, attachment = nil)
      super
      @file = file
      @instance = attachment.instance
      @watermark_path = "spec/support/files/carimbo.png"
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
    end

    def make
      if @current_format == '.pdf'
        pdf = MiniMagick::Image.open(File.expand_path(@file.path))
        watermark = MiniMagick::Image.open(File.expand_path(@watermark_path))
        temp_file = TempfileFactory.new.generate()
        composited = pdf.pages.inject([]) do |composited, page|
          composited << page.composite(watermark) do |c|
            c.compose "Over"
            c.gravity "East"
          end
        end
        MiniMagick::Tool::Convert.new do |b|
          composited.each { |page| b << page.path }
          b << pdf.path
        end
        temp_file = File.open(pdf.path)
        return temp_file
      else
        return @file
      end
    end
  end
end