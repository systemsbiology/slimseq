desc "Initial set up of SLIMseq"
task :setup => ["setup:naming_schemer", "setup:authorizer", "gems:install",
                "db:load", "setup:external_data", "setup:admin_user"]

namespace :setup do
  desc "Install the naming schemer plugin"
  task :naming_schemer do
    puts "== Downloading naming_schemer submodule =="
    `git submodule init`
    `git submodule update`
  end

  desc "Install the authorizer plugin the user chooses"
  task :authorizer do
    puts "== Setting up authorizer plugin =="

    unless ENV['authorizer']
      raise "Please specify and authorizer e.g. rake setup:authorizer authorizer=slimsolo"
    end

    abort 'No authorizer was specified. Run using "rake setup authorizer=slimcore" or ' +
          '"rake setup authorizer=slimsolo"' unless ENV['authorizer']
    
    case ENV['authorizer']
    when "slimcore"
      `ruby script/plugin install git://github.com/bmarzolf/slimcore_authorizer.git`
    when "slimsolo"
      `ruby script/plugin install git://github.com/bmarzolf/slimsolo_authorizer.git`
    end
  end

  desc "Create initial lab group and project for the facility"
  task :external_data => :environment do
    puts "== Setting up external data =="

    facility_group = LabGroup.create(:name => "Sequencing Facility")
    LabGroupProfile.create(:lab_group_id => facility_group.id, :file_folder => "facility")
    facility_project = Project.find_by_name("Sequencing Facility")
    facility_project.update_attributes(:lab_group_id => facility_group.id)
  end

  desc "Create an admin user"
  task :admin_user => :environment do
    puts "== Setting up an admin user =="

    unless ENV['authorizer']
      raise "Please specify and authorizer e.g. rake setup:external_data authorizer=slimsolo"
    end

    # Reload gems in case highline was installed after the task was started
    Gem.clear_paths
    require 'highline/import'
    HighLine.track_eof = false

    return unless agree("Would you like to create an initial admin user? ")

    puts "If you are using SLIMcore Authorizer, make sure the login you choose " +
         "will authenticate on your RubyCAS server"
    firstname = ask("First Name: ")
    lastname = ask("Last Name: ")
    login = ask("Login: ")
    email = ask("Email Address: ")

    user = nil
    case ENV['authorizer']
    when "slimcore"
      user = User.create(
        :firstname => firstname, :lastname => lastname,
        :login => login, :email => email
      )
    when "slimsolo"
      password = ask("Password: ") { |q| q.echo = "x" }
      password_confirmation = ask("Password Confirmation: ") { |q| q.echo = "x" }

      user = User.create(
        :firstname => firstname, :lastname => lastname,
        :login => login, :email => email,
        :password => password, :password_confirmation => password_confirmation
      )
    end

    UserProfile.create(:user_id => user.id, :role => "admin")
  end
end

