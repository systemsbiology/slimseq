class Project < ActiveRecord::Base
  has_many :sample_mixtures
  has_many :studies

  belongs_to :lab_group
  
  named_scope :accessible_to_user, lambda {|*args|
    { :conditions => ["lab_group_id IN (?)", args.first.get_lab_group_ids],
      :order => "name ASC" }
  }

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
  
  def self.for_lab_group(lab_group)
    return Project.find(:all, :conditions => {:lab_group_id => lab_group.id})    
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
    sample_ids = sample_mixtures.collect{|m| m.sample_ids}

    return {
      :id => id,
      :name => name,
      :file_folder => file_folder,
      :lab_group => lab_group.name,
      :lab_group_uri => "#{SiteConfig.site_url}/lab_groups/#{lab_group.id}",
      :updated_at => updated_at,
      :sample_uris => sample_ids.sort.
        collect {|x| "#{SiteConfig.site_url}/samples/#{x}" }
    }
  end

  def tree_hash 
    site_url=ENV['RAILS_RELATIVE_URL_ROOT']
    children=studies.map {|st| st.tree_hash}
    { :id => "p_#{id}",
      :text=>name,
      :href => "#{site_url}/projects/edit/#{id}",
      :children=>children }
  end

end
