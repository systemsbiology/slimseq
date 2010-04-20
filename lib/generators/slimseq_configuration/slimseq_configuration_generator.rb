class SlimseqConfigurationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      require 'highline/import'
      HighLine.track_eof = false

      if ARGV[0] == "slimcore"
        rubycas_server = ask_or_nil("RubyCAS Server Address [http://localhost:3020]: ")
        slimcore_site = ask_or_nil("SLIMcore Address [http://localhost:3030]: ")
        slimcore_user = ask_or_nil("SLIMcore User [slimbot]: ")
        slimcore_password = ask_or_nil("SLIMcore Password [test]: ")
      end

      dev_mysql_server = ask_or_nil("Development MySQL Server [localhost]: ")
      dev_mysql_database = ask_or_nil("Development MySQL Database [slimseq_dev]: ")
      dev_mysql_username = ask_or_nil("Development MySQL username [slimseq]: ")
      dev_mysql_password = ask_or_nil("Development MySQL password [slimseq]: ")

      test_mysql_server = ask_or_nil("Test MySQL Server [localhost]: ")
      test_mysql_database = ask_or_nil("Test MySQL Database [slimseq_dev]: ")
      test_mysql_username = ask_or_nil("Test MySQL username [slimseq]: ")
      test_mysql_password = ask_or_nil("Test MySQL password [slimseq]: ")

      m.template "application.yml.erb", "config/application.yml", :assigns => {
        :rubycas_server => rubycas_server,
        :slimcore_site => slimcore_site, 
        :slimcore_user => slimcore_user,
        :slimcore_password => slimcore_password
      }
      m.template "database.yml.erb", "config/database.yml", :assigns => {
        :dev_mysql_server => dev_mysql_server,
        :dev_mysql_database => dev_mysql_database,
        :dev_mysql_username => dev_mysql_username,
        :dev_mysql_password => dev_mysql_password,
        :test_mysql_server => test_mysql_server,
        :test_mysql_database => test_mysql_database,
        :test_mysql_username => test_mysql_username,
        :test_mysql_password => test_mysql_password
      }
    end
  end

  def ask_or_nil(question)
    response = ask(question)
    response == "" ? nil : response
  end
end
