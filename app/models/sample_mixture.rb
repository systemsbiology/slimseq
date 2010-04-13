class SampleMixture < ActiveRecord::Base
  has_many :samples, :dependent => :destroy
  has_many :flow_cell_lanes

  belongs_to :user, :foreign_key => "submitted_by_id"
  belongs_to :project
  belongs_to :eland_parameter_set
  belongs_to :sample_set
  belongs_to :sample_prep_kit

  validates_presence_of :name_on_tube, :submission_date, :budget_number,
    :desired_read_length, :project_id, :sample_prep_kit_id
  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1

  acts_as_state_machine :initial => :submitted, :column => 'status'
  
  state :submitted, :after => :status_notification
  state :clustered, :after => :status_notification
  state :sequenced, :after => :status_notification
  state :completed, :after => :status_notification

  event :cluster do
    transitions :from => :submitted, :to => :clustered
  end

  event :uncluster do
    transitions :from => :clustered, :to => :submitted
  end
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered
  end
  
  event :complete do
    transitions :from => :sequenced, :to => :completed
  end
  
  def validate
    # make sure date/name_on_tube combo is unique
    s = SampleMixture.find(:first,
      :conditions => {:name_on_tube => name_on_tube,
        :submission_date => submission_date}
    )
    if( s != nil && s.id != id )
      errors.add("Duplicate submission date/name on tube")
    end
  end
  
  def valid?
    samples.each do |sample|
      return false unless sample.valid?
    end

    super
  end

  def save(perform_validates = true)
    unless sample_description
      self.sample_description = samples.collect{|sample| sample.sample_description}.join("_")
    end

    super
  end

  # needed this to get fields_for to work in the view
  def samples_attributes=(attributes)
  end

  def submitted_by=(login)
    self.user = User.find_by_login(login)
  end

  def status_notification
    samples.each do |sample|
      ExternalService.sample_status_change(sample)
    end
  end

  def short_and_long_name
    "#{name_on_tube} (#{sample_description})"
  end

  def short_and_long_name_with_cycles
    "#{name_on_tube} (#{sample_description}) - #{desired_read_length} cycles"
  end
  
  def eland_seed_length
    if(eland_parameter_set)
      max_length = eland_parameter_set.eland_seed_length
    else
      gerald_defaults = GeraldDefaults.first
      max_length = gerald_defaults.eland_seed_length
    end

    if desired_read_length > max_length
      return max_length
    else
      return desired_read_length - 1
    end
  end

  def eland_max_matches
    if(eland_parameter_set)
      return eland_parameter_set.eland_max_matches
    else
      gerald_defaults = GeraldDefaults.find(:first)
      return gerald_defaults.eland_max_matches
    end
  end

end
