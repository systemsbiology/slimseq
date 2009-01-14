class LabGroup < ActiveRecord::Base
  has_many :lab_memberships, :dependent => :destroy
  has_many :users, :through => :lab_memberships
  has_many :projects, :dependent => :destroy
  has_many :charge_sets, :dependent => :destroy

  validates_uniqueness_of :name

  def destroy_warning
    charge_sets = ChargeSet.find(:all, :conditions => ["lab_group_id = ?", id])
    
    return "Destroying this lab group will also destroy:\n" + 
           charge_sets.size.to_s + " charge set(s)\n" +
           projects.size.to_s + " project(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def summary_hash
    return {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/lab_groups/#{id}"
    }
  end

  def detail_hash
    return {
      :id => id,
      :name => name,
      :file_folder => file_folder,
      :updated_at => updated_at,
      :user_uris => user_ids.sort.
        collect {|x| "#{SiteConfig.site_url}/users/#{x}" }
    }
  end
end
