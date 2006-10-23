 require "rbconfig"
 
 def linux?
   not windows? and not cygwin?
 end
 
 def windows?
   not (target_os.downcase =~ /32/).nil?
 end
 
 def cygwin?
   not (target_os.downcase =~ /cyg/).nil?
 end
 
 def target_os 
   Config::CONFIG["target_os"] or ""
 end

namespace :build do
  desc "Build both the full and lite packages"
  task :all => [:full, :lite]

  desc "Alias for 'rake package'"
  task :full => [:create_default_mysql, :package]

  desc "Create default.mysql on-the-fly"
  task :create_default_mysql => :environment do
    if(ActiveRecord::Base.connection.adapter_name == "MySQL")
      puts "Generating default MySQL database..."
      
      # save current database
      abcs = ActiveRecord::Base.configurations
      `mysqldump -h #{abcs["development"]["host"]} -u #{abcs["development"]["username"]} -p#{abcs["development"]["password"]} #{abcs["development"]["database"]} > tmp.mysql`
    
      # trash current database
      ActiveRecord::Base.establish_connection(:development)
      ActiveRecord::Base.connection.recreate_database(abcs["development"]["database"])
    
      # create the default.mysql file on-the-fly
      ActiveRecord::Base.establish_connection(:development)
      Rake::Task[:migrate].invoke
      Rake::Task[:bootstrap].invoke
      `mysqldump -h #{abcs["development"]["host"]} -u #{abcs["development"]["username"]} -p#{abcs["development"]["password"]} #{abcs["development"]["database"]} > db/default.mysql`
    
      # restore temporarily saved database
      ActiveRecord::Base.establish_connection(:development)
      ActiveRecord::Base.connection.recreate_database(abcs["development"]["database"])
      `mysql -h #{abcs["development"]["host"]} -u #{abcs["development"]["username"]} -p#{abcs["development"]["password"]} #{abcs["development"]["database"]} < tmp.mysql`
      FileUtils.rm "tmp.mysql"
    end
  end

  desc "Build a single executable Lite version"
  task :lite do
    LITE_PKG_NAME = "#{PKG_NAME}_lite_#{PKG_VERSION}"
    LITE_PKG_FOLDER = "#{RAILS_ROOT}/pkg/#{LITE_PKG_NAME}"

    CMD_PREFIX = ""
    EXECUTABLE_EXTENSION = ""
    if windows?
      CMD_PREFIX = "cmd /c "
      EXECUTABLE_EXTENSION = ".exe"
    else
      EXECUTABLE_EXTENSION = "_linux"
    end
    
    # get rid of previous lite build
    FileUtils.rm_rf "#{LITE_PKG_FOLDER}"  
    FileUtils.rm_f "#{PKG_NAME}_lite_#{PKG_VERSION}.tar.gz"
    
    # if it exists, put existing database config away, and put the lite build 
    # version in place
    if( FileTest.exist?("config/database.yml") )
      FileUtils.move "config/database.yml", "config/database.backup"
    end
    FileUtils.copy "config/database.lite", "config/database.yml"

    # make a folder for the package files to live in
    if( !FileTest.exist?("#{RAILS_ROOT}/pkg") )
      Dir.mkdir "#{RAILS_ROOT}/pkg"
    end
    Dir.mkdir "#{LITE_PKG_FOLDER}"

    puts "Packaging all ruby into one file with tar2rubyscript..."
    cmd = "#{CMD_PREFIX}tar2rubyscript #{RAILS_ROOT} #{LITE_PKG_NAME}.rb"
    system cmd

    puts "Generating default SQLite database..."
    # create the default.sqlite file on-the-fly
    Rake::Task[:migrate].invoke
    Rake::Task[:bootstrap].invoke
    FileUtils.copy "slimarray_development.sqlite","db/default.sqlite"

    puts "Organizing files..."
    FileUtils.move "#{LITE_PKG_NAME}.rb", "#{LITE_PKG_FOLDER}"
    FileUtils.copy "db/default.sqlite", "#{LITE_PKG_FOLDER}/slimarray_production.sqlite"
    FileUtils.copy "db/default.sqlite", "#{LITE_PKG_FOLDER}/slimarray_development.sqlite"
    FileUtils.copy "db/default.sqlite", "#{LITE_PKG_FOLDER}/slimarray_test.sqlite"

    puts "Creating executable with rubyscript2exe (press Ctrl-C when WEBrick is finished booting..."
    cmd = "#{CMD_PREFIX}rubyscript2exe #{LITE_PKG_FOLDER}/#{LITE_PKG_NAME}.rb"
    system cmd
    FileUtils.move "#{LITE_PKG_NAME}#{EXECUTABLE_EXTENSION}", 
                   "#{LITE_PKG_FOLDER}/#{LITE_PKG_NAME}#{EXECUTABLE_EXTENSION}"
    FileUtils.rm "#{LITE_PKG_FOLDER}/#{LITE_PKG_NAME}.rb"
    FileUtils.rm "config/database.yml"

    # restore backed-up database config, if there was one
    if( FileTest.exist?("config/database.backup") )
      FileUtils.move "config/database.backup", "config/database.yml"
    end

    if windows?
      puts "Now just create a zip file from #{LITE_PKG_FOLDER}"
    else
      puts "Packaging everything into a .tar.gz file in #{RAILS_ROOT}/pkg..."
      cmd = "cd #{RAILS_ROOT}/pkg; tar zcf #{LITE_PKG_NAME}.tar.gz #{LITE_PKG_NAME}"
      system cmd
    end  
  end
end