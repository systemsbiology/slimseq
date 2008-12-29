class Project < ActiveRecord::Base
  has_many :samples
  belongs_to :lab_group
  
  validates_associated :lab_group
  validates_presence_of :name
  validates_format_of :file_folder, :with => /\A([a-z0-9_-]+|)\Z/i,
    :message => "can only have letters, numbers, dashes, and underscores"
  
  def validate_on_create
    if Project.find_by_name_and_lab_group_id(name, lab_group_id)
      errors.add("Multiple projects with same name and lab group")
    end
  end
  
  def name_and_lab_group_id
    return "#{name} (#{lab_group_id})"
  end
  
  def summary_hash
    return {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/projects/#{id}"
    }
  end
  
  def detail_hash
    return {
      :id => id,
      :name => name,
      :file_folder => file_folder,
      :lab_group => lab_group.name,
      :updated_at => updated_at,
      :sample_uris => sample_ids.
        collect {|x| "#{SiteConfig.site_url}/samples/#{x}" }
    }
  end
end
