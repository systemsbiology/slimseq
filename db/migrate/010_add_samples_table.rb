class AddSamplesTable < ActiveRecord::Migration

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
        create_table "samples", :force => true do |t|
          t.column "submission_date", :date
          t.column "short_sample_name", :string, :limit => 20
          t.column "sample_name", :string, :limit => 48
          t.column "sample_group_name", :string, :limit => 50
          t.column "lab_group_id", :integer
          t.column "chip_type_id", :integer
          t.column "organism_id", :integer
          t.column "sbeams_user", :string, :limit => 20
          t.column "sbeams_project", :string, :limit => 50
          t.column "status", :string, :limit => 50
          t.column "lock_version", :integer, :default => 0
        end
        
        # add new fields for hybridizations, change 'date' to
        # eliminate ambiguity with samples
        add_column :hybridizations, :sample_id, :integer
        add_column :hybridizations, :charge_set_id, :integer
        rename_column :hybridizations, :date, :hybridization_date
        
        # copy information from hybridizations to samples and 
        # populate new fields in hybridizations
        Hybridization.reset_column_information
        Hybridization.find(:all).each do |h|
          s = Sample.new( :submission_date => h.hybridization_date,
                          :short_sample_name => h.short_sample_name,
                          :sample_name => h.sample_name,
                          :sample_group_name => h.sample_group_name,
                          :lab_group_id => h.lab_group_id,
                          :chip_type_id => h.chip_type_id,
                          :organism_id => h.organism_id,
                          :sbeams_user => h.sbeams_user,
                          :sbeams_project => h.sbeams_project,
                          :status => 'hybridized'
                         )
          if(!s.valid?)
            breakpoint
          end
          s.save
          h.update_attribute('sample_id', s.id)
        end
        
        # drop fields in hybridizations that are now in samples,
        # as well as array_platform, which is not necessary
        remove_column :hybridizations, :short_sample_name
        remove_column :hybridizations, :sample_name
        remove_column :hybridizations, :sample_group_name
        remove_column :hybridizations, :lab_group_id
        remove_column :hybridizations, :chip_type_id
        remove_column :hybridizations, :organism_id
        remove_column :hybridizations, :sbeams_user
        remove_column :hybridizations, :sbeams_project
        remove_column :hybridizations, :array_platform
    
        # put array platform in chip_types, and set them all to 'affy'
        # by default
        add_column :chip_types, :array_platform, :string, :limit => 50
        ChipType.reset_column_information
        ChipType.find(:all).each do |ct|
          ct.update_attribute('array_platform', 'affy')
        end
        
        # new sample entry doesn't need add_hybs table
        drop_table :add_hybs
      end
    end
  end
  
  def self.down
    if(using_Mysql?)
      transaction do
        # add old hybridizations columns back in
        add_column :hybridizations, :short_sample_name, :string, :limit => 8
        add_column :hybridizations, :sample_name, :string, :limit => 48
        add_column :hybridizations, :sample_group_name, :string, :limit => 50
        add_column :hybridizations, :lab_group_id, :integer
        add_column :hybridizations, :chip_type_id, :integer
        add_column :hybridizations, :organism_id, :integer
        add_column :hybridizations, :sbeams_user, :string, :limit => 20
        add_column :hybridizations, :sbeams_project, :string, :limit => 50
        add_column :hybridizations, :array_platform, :string, :limit => 20

        # move information back from samples to hybridizations
        Hybridization.reset_column_information
        Sample.find(:all).each do |s|
          h = Hybridization.find(:first, :conditions => [ "sample_id = ?", s.id ])
          if h != nil
            h.update_attributes( :short_sample_name => s.short_sample_name,
                                 :sample_name => s.sample_name,
                                 :sample_group_name => s.sample_group_name,
                                 :lab_group_id => s.lab_group_id,
                                 :chip_type_id => s.chip_type_id,
                                 :sbeams_user => s.sbeams_user,
                                 :sbeams_project => s.sbeams_project
                                )
          end
        end
        
        drop_table :samples
        remove_column :hybridizations, :sample_id
        remove_column :hybridizations, :charge_set_id
        rename_column :hybridizations, :hybridization_date, :date
                
        remove_column :chip_types, :array_platform
        
        create_table "add_hybs", :force => true do |t|
          t.column "number", :integer
          t.column "lab_group_id", :integer
          t.column "chip_type_id", :integer
          t.column "date", :date
          t.column "sbeams_user", :string, :limit => 20
          t.column "sbeams_project", :string, :limit => 50
        end
      end
    end
  end
end
