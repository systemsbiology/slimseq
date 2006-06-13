class AddLdapConfig < ActiveRecord::Migration
  def self.using_Mysql?
    if(ActiveRecord::Base.connection.adapter_name == "MySQL")
      return true;
    else
      return false;
    end
  end

  def self.up
    if(using_Mysql?)
      transaction do
        add_column :site_config, :use_LDAP, :boolean
        add_column :site_config, :LDAP_server, :string, :limit => 200
        add_column :site_config, :LDAP_DN, :string, :limit => 200
        
        SiteConfig.update 1, :use_LDAP => false,
                          :LDAP_server => 'localhost',
                          :LDAP_DN => 'cn=users,dc=localhost'
      end
    else
      add_column :site_config, :use_LDAP, :boolean
      add_column :site_config, :LDAP_server, :string, :limit => 200
      add_column :site_config, :LDAP_DN, :string, :limit => 200
      
      SiteConfig.update 1, :use_LDAP => false,
                        :LDAP_server => 'localhost',
                        :LDAP_DN => 'cn=users,dc=localhost'      
    end
  end
  
  def self.down
    if(using_Mysql?)
      transaction do
        remove_column :site_config, :use_LDAP
        remove_column :site_config, :LDAP_server 
        remove_column :site_config, :LDAP_DN
      end
    else
      remove_column :site_config, :use_LDAP
      remove_column :site_config, :LDAP_server 
      remove_column :site_config, :LDAP_DN    
    end
  end
end
