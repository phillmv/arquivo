namespace :static do
  desc 'Generate static site in ./out/ directory'
  task :import => :environment do
    SyncFromDisk.new(ENV["GITHUB_WORKSPACE"] || ENV["NOTEBOOK_PATH"]).import!
  end

  task :generate do
    Dir.mkdir 'out' unless File.exist? 'out'
    Dir.chdir 'out' do
      `wget localhost:3000 --domains localhost  --recursive  --page-requisites  --no-clobber  --html-extension  --convert-links -nH`
      #
      # Dir["*.html"].each do |file|
      #   next if file == "index.html"
      #   # we want to create symlinks from `foo.html` to `foo`
      #   # unless there's a directory, upon which we want
      #   # `foo/index.html`
      #
      #   identifier = file.chomp(".html")
      #
      #   if File.directory?(identifier)
      #     File.symlink(file, File.join(identifier, "index.html"))
      #
      #     thread_file = File.join(identifier, "thread.html")
      #     if File.exists?(thread_file)
      #       File.symlink(thread_file, File.join(identifier, "thread"))
      #     end
      #   else
      #     File.symlink(file, identifier)
      #   end
      # end
    end
  end
end
