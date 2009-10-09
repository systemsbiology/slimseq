desc "Initial set up of SLIMseq"
task :setup => ["setup:naming_schemer", "setup:authorizer", "gems:install", "db:load",
                "setup:admin_user"]

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

  task :admin_user => :environment do
    puts "== Setting up an admin user =="

    require 'highline/import'

    return unless agree("Would you like to create an initial admin user? ")

    puts "If you are using SLIMcore Authorizer, make sure the login you choose " +
         "will authenticate on your RubyCAS server"
    firstname = ask("First Name: ")
    lastname = ask("Last Name: ")
    login = ask("Login: ")
    email = ask("Email Address: ")

    user = User.create(:firstname => firstname, :lastname => lastname,
                       :login => login, :email => email)
    UserProfile.create(:user_id => user.id, :role => "admin")
  end
end

