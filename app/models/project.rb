class Project < ActiveRecord::Base
  has_many :samples
  belongs_to :lab_group
  
  validates_associated :lab_group
  validates_presence_of :name
  validates_format_of :file_folder, :with => /\A[a-z0-9_-]+\Z/i,
    :message => "can only have letters, numbers, dashes, and underscores"
  
  def validate_on_create
    if Project.find_by_name_and_lab_group_id(name, lab_group_id)
      errors.add("Multiple projects with same name and lab group")
    end
  end
  
  def name_and_lab_group_id
    return "#{name} (#{lab_group_id})"
  end
end
