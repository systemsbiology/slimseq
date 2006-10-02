class AddProjectsTable < ActiveRecord::Migration
  def self.up
    create_table "projects", :force => true do |t|
      t.column "name", :string, :limit => 50
      t.column "budget", :string, :limit => 8
      t.column "lab_group_id", :integer
      t.column "lock_version", :integer, :default => 0
    end
    
    add_column :samples, :project_id, :integer

    # migrate samples
    say "migrating samples"
    Sample.reset_column_information
    Sample.find(:all).each do |s|
      p = Project.find(:first, :conditions => ["name = ?", s.sbeams_project])
      
      # create a new project if one doesn't exist
      if(p.nil?)
        p = Project.new( :name => s.sbeams_project,
                         :budget => '0000',
                         :lab_group_id => s.lab_group_id
                       )
        p.save
      end
      
      s.update_attribute('project_id', p.id)
    end

    remove_column :samples, :sbeams_project
    remove_column :samples, :lab_group_id
  end

  def self.down
    add_column :samples, :sbeams_project, :string, :limit => 50
    add_column :samples, :lab_group_id, :integer
    
    # migrate back samples
    say "migrating samples"
    Sample.reset_column_information
    Sample.find(:all).each do |s|
      s.update_attributes(:sbeams_project => s.project.name,
                          :lab_group_id => s.project.lab_group_id
                         )
    end
        
    remove_column :samples, :project_id
    drop_table :projects
  end
end
