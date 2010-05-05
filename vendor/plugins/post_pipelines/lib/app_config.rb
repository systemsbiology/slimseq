class AppConfig
  def self.load(config_file,section)
    config_file = File.join(RAILS_ROOT, "config", "application.yml") if config_file.nil?

    if File.exists?(config_file)
      yml_contents=YAML.load(File.read(config_file))
      section=ENV[RAILS_ENV] if section.nil?
      config = yml_contents[RAILS_ENV]

      config.keys.each do |key|
        cattr_accessor key
        send("#{key}=", config[key])
      end

      common=yml_contents['common']
      if common
        common.keys.each do |key|
          cattr_accessor key
          send("#{key}=",common[key])
        end
      end
    end
  end
end
