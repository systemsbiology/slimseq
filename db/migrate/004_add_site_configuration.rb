class AddSiteConfiguration < ActiveRecord::Migration
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
        create_table "site_config", :force => true do |t|
          t.column "site_name", :string, :limit => 50
          t.column "organization_name", :string, :limit => 100
          t.column "facility_name", :string, :limit => 100
          t.column "array_platform", :string, :limit => 20
          t.column "track_inventory", :boolean
          t.column "track_hybridizations", :boolean
          t.column "track_charges", :boolean
          t.column "create_gcos_files", :boolean
          t.column "using_sbeams", :boolean
          t.column "gcos_output_path", :string, :limit => 250
        end
        
        SiteConfig.create :site_name => "SLIMarray",
                          :organization_name => "Name of Your Organization Here",
                          :facility_name => "Your Facility Name Here",
                          :array_platform => "both",
                          :track_inventory => true,
                          :track_hybridizations => true,
                          :track_charges => true,
                          :create_gcos_files => true,
                          :using_sbeams => true,
                          :gcos_output_path => "/tmp/"
                          
        add_column :add_hybs, :array_platform, :string, :limit => 20
        add_column :hybridizations, :array_platform, :string, :limit => 20
      end
    else
      create_table "site_config", :force => true do |t|
        t.column "site_name", :string, :limit => 50
        t.column "organization_name", :string, :limit => 100
        t.column "facility_name", :string, :limit => 100
        t.column "array_platform", :string, :limit => 20
        t.column "track_inventory", :boolean
        t.column "track_hybridizations", :boolean
        t.column "track_charges", :boolean
        t.column "create_gcos_files", :boolean
        t.column "using_sbeams", :boolean
        t.column "gcos_output_path", :string, :limit => 250
      end
      
      SiteConfig.create :site_name => "SLIMarray",
                        :organization_name => "Name of Your Organization Here",
                        :facility_name => "Your Facility Name Here",
                        :array_platform => "both",
                        :track_inventory => true,
                        :track_hybridizations => true,
                        :track_charges => true,
                        :create_gcos_files => true,
                        :using_sbeams => true,
                        :gcos_output_path => "/tmp/"
                        
      add_column :add_hybs, :array_platform, :string, :limit => 20
      add_column :hybridizations, :array_platform, :string, :limit => 20    
    end
  end
  
  def self.down
    if(using_Mysql?)
      transaction do
        drop_table "site_config"
        remove_column :add_hybs, :array_platform
        remove_column :hybridizations, :array_platform
      end
    else
      drop_table "site_config"
      remove_column :add_hybs, :array_platform
      remove_column :hybridizations, :array_platform    
    end
  end
end
