require 'rails/generators/erb'
require 'rails/generators/resource_helpers'

module Erb # :nodoc:
  module Generators # :nodoc:
    class ScaffoldGenerator < Base # :nodoc:
      include Rails::Generators::ResourceHelpers

      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      def create_root_folder
        empty_directory File.join("app/views", controller_file_path)
      end

      def copy_view_files
        available_views.each do |view|
          formats.each do |format|
            filename = filename_with_extensions(view, format)
            template filename, File.join("app/views", controller_file_path, filename)
          end
        end
        policy_file = "#{file_name}_policy.rb"
        template 'policy.rb', File.join("app/policies/", policy_file)

        locale_file = "#{file_name}.yml"
        template 'locale.yml', File.join("config/locales/", locale_file)

        datagrid_file = "#{plural_table_name}_grid.rb"
        template 'datagrid.rb', File.join("app/grids/", datagrid_file)
      end

      protected

      def available_views
        %w(index edit new _form _datagrid_actions)
      end

    end

  end
end