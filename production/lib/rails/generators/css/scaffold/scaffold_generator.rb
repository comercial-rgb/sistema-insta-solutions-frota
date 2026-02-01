require "rails/generators/named_base"

module Css # :nodoc:
  module Generators # :nodoc:
    class ScaffoldGenerator < Rails::Generators::NamedBase # :nodoc:
      # In order to allow the Sass generators to pick up the default Rails CSS and
      # transform it, we leave it in a standard location for the CSS stylesheet
      # generators to handle. For the simple, default case, just copy it over.
      def copy_stylesheet
        
      end
    end
  end
end