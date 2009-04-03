# Transfer users, lab groups and lab memberships between in-house db and SLIMcore
namespace :db do
  namespace :migrate do

    desc "Transfer users, lab groups and lab memberships from in-house database to SLIMcore"
    task :slimcore => :environment do
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

      # create the users, lab groups and lab memberships in SLIMcore
      SoloUser.find(:all).each do |u|
        CoreUser.create(:login => u.login, :firstname => u.firstname,
                        :lastname => u.lastname, :email => u.email)
      end

      SoloLabGroup.find(:all).each do |lg|
        CoreLabGroup.create(:name => lg.name)
      end

      # do SLIMcore ID lookup for users and lab groups here
      SoloLabMembership.find(:all).each do |lm|
        core_user_id = solo_to_core_user_id(lm.user_id)
        core_lab_group_id = solo_to_core_lab_group_id(lm.lab_group_id)
        CoreLabMembership.create(:user_id => core_user_id, :lab_group_id => core_lab_group_id)
      end

      # since the IDs of the newly-created records in SLIMcore won't necessarily match
      # the local database IDs, update anything referencing users, lab groups or lab
      # memberships
      Project.find(:all).each do |p|
        p.update_attribute( 'lab_group_id', solo_to_core_lab_group_id(p.lab_group_id) )
      end

      Sample.find(:all).each do |s|
        if(s.submitted_by_id)
          s.update_attribute( 'submitted_by_id', solo_to_core_user_id(s.submitted_by_id) )
        end
      end

      ChargeSet.find(:all).each do |c|
        c.update_attribute( 'lab_group_id', solo_to_core_lab_group_id(c.lab_group_id) )
      end
    end

  end
end
