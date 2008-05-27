class Project < ActiveRecord::Base
  has_many :samples
  belongs_to :lab_group
  
  validates_associated :lab_group

  validates_presence_of :name, :budget
  validates_length_of :name, :maximum => 250
  validates_length_of :budget, :maximum => 100
  
  def validate_on_create
    # make sure name/budget combo is unique
    if Project.find_by_name_and_budget(name, budget)
      errors.add("Multiple projects with same name and budget")
    end
  end
  
  def name_and_budget
    return "#{name} (#{budget})"
  end
end
