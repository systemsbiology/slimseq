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
  # Can't get both full and lite to build happily together (probably due to
  # change in database configuration between tasks), so instead only allow
  # the full and lite to be built separately
  #desc "Build both the full and lite packages"
  #task :all => [:full, :lite]

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
end