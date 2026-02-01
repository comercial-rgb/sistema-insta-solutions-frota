task :before_assets_precompile do

  # All bootstrap and dropify icons are traditional CSS file, so it points to
  # local fonts using relative way. To work property on production we need to
  # copy those files to the public folder, so we can receive NPM updates without
  # any issue

  # dropify
  system('mkdir -p public/fonts/')
  system('rm public/fonts/*')
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance ['before_assets_precompile']
