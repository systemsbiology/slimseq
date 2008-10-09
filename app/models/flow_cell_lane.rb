class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  has_and_belongs_to_many :samples
  
  validates_numericality_of :starting_concentration, :loaded_concentration

  after_create :mark_samples_as_clustered
  before_destroy :mark_samples_as_submitted

  def mark_samples_as_clustered
    mark_samples_as('clustered')
  end
  
  def mark_samples_as_submitted
    mark_samples_as('submitted')
  end
  
  def mark_samples_as(status)
    samples.each do |sample|
      sample.update_attribute('status', status)
    end
  end

end
