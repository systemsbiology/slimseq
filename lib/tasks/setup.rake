desc "Initial set up of SLIMseq"
task :setup => ["setup:naming_schemer", "setup:authorizer", "gems:install", "db:load"]

namespace :setup do
  task :naming_schemer do
    puts "== Downloading naming_schemer submodule =="
    `git submodule init`
    `git submodule update`
  end

  task :authorizer do
    puts "== Setting up authorizer plugin =="

    abort 'No authorizer was specified. Run using "rake setup authorizer=slimcore" or ' +
          '"rake setup authorizer=slimsolo"' unless ENV['authorizer']
    
    case ENV['authorizer']
    when "slimcore"
      `ruby script/plugin install git://github.com/bmarzolf/slimcore_authorizer.git`
    when "slimsolo"
      `ruby script/plugin install git://github.com/bmarzolf/slimsolo_authorizer.git`
    end
  end
end

