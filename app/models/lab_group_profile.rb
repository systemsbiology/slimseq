class LabGroupProfile < ActiveRecord::Base
  belongs_to :lab_group

  validates_presence_of :lab_group_id

  class << self; attr_accessor :index_columns end
  @index_columns = ['file_folder']

  def destroy_warning
    projects = Project.find(:all, :conditions => ["lab_group_id = ?", lab_group_id])
    
    return "Destroying this lab group will also destroy:\n" + 
           projects.size.to_s + " project(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def detail_hash
    return {
      :file_folder => file_folder,
      :project_uris => project_ids.sort.
        collect {|x| "#{SiteConfig.site_url}/projects/#{x}" }
    }
  end

private
  
  def project_ids
    projects = Project.find(:all, :conditions => {:lab_group_id => lab_group_id})

    projects.collect {|p| p.id}
  end
end
