desc "Initial set up of SLIMseq"
task :setup => ["setup:configuration", "gems:install", "setup:naming_schemer", "setup:authorizer",
                "db:load", "setup:external_data", "setup:admin_user"]

namespace :setup do
  desc "Use the example database and application YAML configuration files"
  task :configuration do
    puts "== Generating application and database configuration"

    unless ENV['authorizer']
      raise "Please specify and authorizer e.g. rake setup authorizer=slimsolo"
    end

    # need to have an application.yml and database.yml to run a generator, so put a temporary 
    # ones in place if needed
    unless File.exists?("config/database.yml") || File.exists?("config/application.yml")
      FileUtils.cp "lib/generators/slimseq_configuration/templates/database.yml.placeholder",
        "config/database.yml"
      FileUtils.cp "lib/generators/slimseq_configuration/templates/application.yml.placeholder",
        "config/application.yml"
    end

    system("ruby script/generate slimseq_configuration #{ENV['authorizer']}")
  end

  desc "Install the naming schemer plugin and ExtJSs"
  task :naming_schemer do
    puts "== Downloading Naming Schemer and ExtJS external components =="
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

    # Not sure why, but APP_CONFIG isn't always loaded when this task runs
    require 'config/initializers/1-load_application_config'

    # need this to get models from authorizer plugin if it was 
    # installed while rake has been running

    if File.exists? 'vendor/plugins/slimcore_authorizer'
      model_folder = 'vendor/plugins/slimcore_authorizer/app/models/'
    elsif File.exists? 'vendor/plugins/slimsolo_authorizer'
      model_folder = 'vendor/plugins/slimsolo_authorizer/app/models'
    end
    load model_folder + "lab_group.rb"
    load model_folder + "user.rb"

    facility_group = LabGroup.find_or_create_by_name("Microarray Facility")
    LabGroupProfile.create(:lab_group_id => facility_group.id)
    facility_project = Project.find_or_create_by_name("Microarray Facility")
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

