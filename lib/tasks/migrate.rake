# Transfer users, lab groups and lab memberships between in-house db and SLIMcore
namespace :db do
  namespace :migrate do

    desc "Transfer users, lab groups and lab memberships from in-house database to SLIMcore"
    task :slimcore => :environment do
      puts "== Migrating to SLIMcore =="

      # custom model declarations here to prevent model name conflicts
      class CoreUser < ActiveResource::Base
        self.site = APP_CONFIG['slimcore_site']
        self.element_name = "user"
        self.user = APP_CONFIG['slimcore_user']
        self.password = APP_CONFIG['slimcore_password'] 

        def self.find_by_login(login)
          self.find(:all, :params => {:login => login}).first
        end
      end

      class CoreLabGroup < ActiveResource::Base
        self.site = APP_CONFIG['slimcore_site'] 
        self.element_name = "lab_group"
        self.user = APP_CONFIG['slimcore_user']
        self.password = APP_CONFIG['slimcore_password'] 

        def self.find_by_name(name)
          self.find(:all, :params => {:name => name}).first
        end
      end

      class CoreLabMembership < ActiveResource::Base
        self.site = APP_CONFIG['slimcore_site'] 
        self.element_name = "lab_membership"
        self.user = APP_CONFIG['slimcore_user']
        self.password = APP_CONFIG['slimcore_password'] 
      end

      class SoloUser < ActiveRecord::Base
        set_table_name "users"
      end

      class SoloLabGroup < ActiveRecord::Base
        set_table_name "lab_groups"
      end

      class SoloLabMembership < ActiveRecord::Base
        set_table_name "lab_memberships"
      end

      class UserProfile < ActiveRecord::Base; end

      class LabGroupProfile < ActiveRecord::Base; end

      def solo_to_core_user_id(id)
        solo_user = SoloUser.find(id)
        core_user = CoreUser.find_by_login(solo_user.login)

        return core_user.id
      end

      def solo_to_core_lab_group_id(id)
        solo_lab_group = SoloLabGroup.find(id)
        core_lab_group = CoreLabGroup.find_by_name(solo_lab_group.name) 

        return core_lab_group.id
      end

      puts "Migrating users"
      SoloUser.find(:all).each do |u|
        # Either find an existing Core user or create one
        core_user = CoreUser.find_by_login(u.login)
        if(core_user.nil?)
          core_user = CoreUser.create(:login => u.login, :firstname => u.firstname,
            :lastname => u.lastname, :email => u.email)
        end

        UserProfile.create(:user_id => core_user.id, :role => u.role,
                           :new_sample_notification => u.new_sample_notification,
                           :new_sequencing_run_notification => u.new_sequencing_run_notification)
      end

      puts "Migrating lab groups"
      SoloLabGroup.find(:all).each do |lg|
        lab_group = CoreLabGroup.find_by_name(lg.name)
        lab_group = CoreLabGroup.create(:name => lg.name) if lab_group.nil?

        LabGroupProfile.create(:lab_group_id => lab_group.id, :file_folder => lg.file_folder)
      end

      puts "Migrating lab memberships"
      # do SLIMcore ID lookup for users and lab groups here
      SoloLabMembership.find(:all).each do |lm|
        core_user_id = solo_to_core_user_id(lm.user_id)
        core_lab_group_id = solo_to_core_lab_group_id(lm.lab_group_id)
        CoreLabMembership.create(:user_id => core_user_id, :lab_group_id => core_lab_group_id)
      end

      puts "Migrating projects"
      # since the IDs of the newly-created records in SLIMcore won't necessarily match
      # the local database IDs, update anything referencing users, lab groups or lab
      # memberships
      Project.find(:all).each do |p|
        p.update_attribute( 'lab_group_id', solo_to_core_lab_group_id(p.lab_group_id) )
      end

      puts "Migrating samples"
      Sample.find(:all).each do |s|
        if(s.submitted_by_id)
          s.update_attribute( 'submitted_by_id', solo_to_core_user_id(s.submitted_by_id) )
        end
      end

      puts "Migrating charge sets"
      ChargeSet.find(:all).each do |c|
        c.update_attribute( 'lab_group_id', solo_to_core_lab_group_id(c.lab_group_id) )
      end

      puts "== Finished migrating to SLIMcore"
    end


    desc "Create user profiles and lab group profiles"
    task :slimsolo => :environment do
      puts "== Migrating to SLIMsolo =="

      class UserProfile < ActiveRecord::Base; end

      class LabGroupProfile < ActiveRecord::Base; end

      puts "Migrating users"
      User.find(:all).each do |u|
        UserProfile.create(:user_id => u.id, :role => u.role,
                           :new_sample_notification => u.new_sample_notification,
                           :new_sequencing_run_notification => u.new_sequencing_run_notification)
      end

      puts "Migrating lab groups"
      LabGroup.find(:all).each do |lg|
        LabGroupProfile.create(:lab_group_id => lg.id, :file_folder => lg.file_folder)
      end
    end
  end
end
