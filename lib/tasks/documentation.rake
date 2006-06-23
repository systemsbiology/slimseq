# This is a modification of the railities documentatation rake task
namespace :doc do

  desc "Generate documentation for SLIMarray"
  task :slimarray do
    options       = []
    files         = Rake::FileList.new
    options << "-o doc/app"
    options << "--title 'SLIMarray Documentation'"
    options << '--line-numbers --inline-source'
    options << '--all' # include protected methods
    options << '-T html'

#    files.include("lib/**/*.rb")
    files.include("app/**/*.rb") # include the app directory
    files.include("doc/*") # include the components directory
    files.include("README")    
    options << "--main 'README'"

    files.include("CHANGELOG") if File.exists?("CHANGELOG")
    
    options << files.to_s
    
    sh %(rdoc #{options * ' '})
  end

end
