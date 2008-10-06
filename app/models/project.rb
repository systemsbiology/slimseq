class Project < ActiveRecord::Base
  has_many :samples
  belongs_to :lab_group
  
  validates_associated :lab_group

  validates_presence_of :name
  
  def validate_on_create
    if Project.find_by_name_and_lab_group_id(name, lab_group_id)
      errors.add("Multiple projects with same name and lab group")
    end
  end
  
  def name_and_lab_group_id
    return "#{name} (#{lab_group_id})"
  end
end
