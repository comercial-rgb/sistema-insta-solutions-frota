Rails.application.config.to_prepare do
  ActiveStorage::Blob.class_eval do
    before_create :prepend_folder_to_key

    private

    def prepend_folder_to_key
      # Customize this to use the folder structure you want
      folder = ENV['AWS_BUCKET_PREFIX'] # Example: "project_1/uploads/"
      
      # Check if key exists before manipulating it
      return if key.nil? || folder.nil?
      
      # Ensure we don't prepend the folder if it's already there (for reuploads, etc.)
      self.key = "#{folder}#{key}" unless key.start_with?(folder)
    end
  end
end