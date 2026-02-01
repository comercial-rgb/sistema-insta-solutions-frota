module Paperclip
  class OfficePdf < Processor

    def initialize file, options = {}, attachment = nil
      @file                = file
      @options             = options
      @format              = "pdf"
      @instance            = attachment.instance
      @current_format      = File.extname(@file.path).gsub(".","")
      @basename            = File.basename(@file.path, @current_format).gsub(".","")
      @filename            = File.basename(@file.path)
      @whiny               = options[:whiny].nil? ? true : options[:whiny]
    end

    def make
      
      public_key  = 'project_public_5efb094045ac021a0070de805c0c5539_W3zwMcd98141f13ae25626cad45c031609863'
      private_key = 'secret_key_7e4f5614b441d61c2bbeb928b1434371_QIqv9de8435fae724a1647490f41699766009'

      ilovepdf = Ilovepdf::Ilovepdf.new(public_key, private_key)
      filename = [@basename, @format ? ".#{@format}" : ""].join
      original_filename = @filename
      pdf_name = "#{filename}"
      temp_file = Tempfile.new([@basename, @format].join("."))
      
      begin
        if @current_format == "docx" or @current_format == "doc"
          # Create a  task to convert
          my_task_convert_office = ilovepdf.new_task :officepdf
          
          my_task_convert_office.add_file @file.path.to_s

          # Execute the task
          my_task_convert_office.execute

          # Download the pdf file to public folder
          destination_folder = "tmp/"
          my_task_convert_office.download(destination_folder)

          temp_file = File.open("#{destination_folder}/#{pdf_name}")
        else
          temp_file = File.open(@file.path)
        end
        temp_file
      rescue Exception => e
        raise PaperclipError, "There was an error processing the file contents for #{@basename} - #{e}" if @whiny
      end
    end
  end
end
