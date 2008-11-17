class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  has_and_belongs_to_many :samples
  
  validates_numericality_of :starting_concentration, :loaded_concentration

  after_create :mark_samples_as_clustered
  before_destroy :mark_samples_as_submitted

  acts_as_state_machine :initial => :clustered, :column => 'status'
  
  state :clustered, :after => [:unsequence_samples, :clear_path]
  state :sequenced, :after => [:sequence_samples, :generate_path, :create_charge]
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced    
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered
  end

  def mark_samples_as_clustered
    samples.each do |sample|
      sample.reload.cluster!
    end
  end
  
  def mark_samples_as_submitted
    samples.each do |sample|
      sample.reload.unsequence!
      sample.uncluster!
    end
  end
  
  def summary_hash
    return {
      :id => id,
      :flow_cell_uri => "#{SiteConfig.site_url}/flow_cells/#{flow_cell_id}",
      :lane_number => lane_number,
      :uri => "#{SiteConfig.site_url}/flow_cell_lanes/#{id}"
    }
  end
  
  def detail_hash
    return {
      :id => id,
      :flow_cell_uri => "#{SiteConfig.site_url}/flow_cells/#{flow_cell_id}",
      :lane_number => lane_number,
      :starting_concentration => starting_concentration,
      :loaded_concentration => loaded_concentration,
      :raw_data_path => raw_data_path,
      :status => status,
      :comment => comment,
      :sample_uris => sample_ids.collect {|x| "#{SiteConfig.site_url}/samples/#{x}" }
    }
  end
  
private
  
  def sequence_samples
    samples.each do |s|
      s = Sample.find(s.id)
      s.sequence!
    end
  end
  
  def unsequence_samples
    samples.each do |s|
      s = Sample.find(s.id)
      s.unsequence!
    end
  end
  
  def generate_path
    path = "#{SiteConfig.raw_data_root_path}/#{samples[0].project.lab_group.file_folder}/" +
           "#{samples[0].project.file_folder}/#{flow_cell.sequencing_run.date_yymmdd}_" +
           "#{flow_cell.sequencing_run.instrument.serial_number}_#{flow_cell.name}"
    update_attribute("raw_data_path", path)
  end

  def clear_path
    update_attribute("raw_data_path", "")
  end

  def create_charge
    # charge tracking must be turned on, there must be a default charge,
    # and the sample can't be a control
    if( (SiteConfig.track_charges? || ChargeTemplate.default != nil) &&
        samples[0].control == false )
      charge_set = ChargeSet.find_or_create_for_latest_charge_period(
        samples[0].project,
        samples[0].budget_number
      )

      description = samples[0].name_on_tube
      (1..samples.size-1).each do |i|
        description << ", #{samples[i].name_on_tube}"
      end

      Charge.create(
        :charge_set => charge_set,
        :date => Date.today,
        :description => description,
        :cost => ChargeTemplate.default.cost)
    end
  end
end
