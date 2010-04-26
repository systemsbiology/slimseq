class CreateSampleMixtures < ActiveRecord::Migration
  # need these associations to migrate
  class Sample < ActiveRecord::Base
    has_and_belongs_to_many :flow_cell_lanes
  end
  class FlowCellLane < ActiveRecord::Base
    has_and_belongs_to_many :samples
  end

  def self.up
    create_table :sample_mixtures do |t|
      t.string :name_on_tube
      t.string :sample_description
      t.integer :project_id
      t.string :budget_number
      t.integer :desired_read_length
      t.integer :alignment_start_position, :default => 1
      t.integer :alignment_end_position
      t.boolean :control, :default => false
      t.string :comment
      t.boolean :ready_for_sequencing, :default => true
      t.integer :eland_parameter_set_id
      t.date :submission_date
      t.string :status
      t.integer :submitted_by_id
      t.integer :sample_prep_kit_id
      t.integer :sample_set_id

      t.timestamps
    end

    add_column :samples, :sample_mixture_id, :integer
    add_column :flow_cell_lanes, :sample_mixture_id, :integer

    Sample.reset_column_information
    FlowCellLane.reset_column_information
    
    puts "-- Migrating sample to flow cell lane associations"
    Sample.all.each do |sample|
      mixture = SampleMixture.create(
        :name_on_tube => sample.name_on_tube,
        :sample_description => sample.sample_description,
        :project_id => sample.project_id,
        :budget_number => sample.budget_number,
        :desired_read_length => sample.desired_read_length,
        :alignment_start_position => sample.alignment_start_position,
        :alignment_end_position => sample.alignment_end_position,
        :control => sample.control,
        :comment => sample.comment,
        :ready_for_sequencing => sample.ready_for_sequencing,
        :eland_parameter_set_id => sample.eland_parameter_set_id,
        :submission_date => sample.submission_date,
        :submitted_by_id => sample.submitted_by_id,
        :sample_prep_kit_id => sample.sample_prep_kit_id
      )

      # set status this way to bypass AASM
      mixture.update_attribute('status', sample.status)

      sample.update_attributes(:sample_mixture_id => mixture.id)

      sample.flow_cell_lane_ids.each do |lane_id|
        lane = FlowCellLane.find(lane_id)
        lane.update_attributes(:sample_mixture_id => mixture.id)
      end
    end

    drop_table :flow_cell_lanes_samples
    
    remove_column :samples, :name_on_tube
    remove_column :samples, :project_id
    remove_column :samples, :budget_number
    remove_column :samples, :desired_read_length
    remove_column :samples, :alignment_start_position
    remove_column :samples, :alignment_end_position
    remove_column :samples, :control
    remove_column :samples, :comment
    remove_column :samples, :ready_for_sequencing
    remove_column :samples, :eland_parameter_set_id
    remove_column :samples, :submission_date
    remove_column :samples, :status
    remove_column :samples, :submitted_by_id
    remove_column :samples, :sample_prep_kit_id
    remove_column :samples, :sample_set_id
  end

  def self.down
    add_column :samples, :name_on_tube, :string
    add_column :samples, :project_id, :integer
    add_column :samples, :budget_number, :string
    add_column :samples, :desired_read_length, :integer
    add_column :samples, :alignment_start_position, :integer, :default => 1
    add_column :samples, :alignment_end_position, :integer
    add_column :samples, :control, :boolean, :default => false
    add_column :samples, :comment, :string
    add_column :samples, :ready_for_sequencing, :boolean
    add_column :samples, :eland_parameter_set_id, :integer
    add_column :samples, :submission_date, :date
    add_column :samples, :status, :string, :default => 'submitted'
    add_column :samples, :submitted_by_id, :integer
    add_column :samples, :sample_prep_kit_id, :integer

    create_table :flow_cell_lanes_samples, :id => false do |t|
      t.integer :sample_id
      t.integer :flow_cell_lane_id
      t.integer :lock_id
    end

    puts "-- Migrating sample to flow cell lane associations"
    SampleMixture.all.each do |mixture|
      mixture.samples.each do |sample|
        # get around strange method missing error
        sample = Sample.find(sample.id)
        mixture.flow_cell_lanes.each do |lane|
          sample.flow_cell_lanes << lane
          sample.update_attributes(
            :name_on_tube => mixture.name_on_tube,
            :project_id => mixture.project_id,
            :budget_number => mixture.budget_number,
            :desired_read_length => mixture.desired_read_length,
            :alignment_start_position => mixture.alignment_start_position,
            :alignment_end_position => mixture.alignment_end_position,
            :control => mixture.control,
            :comment => mixture.comment,
            :ready_for_sequencing => mixture.ready_for_sequencing,
            :eland_parameter_set_id => mixture.eland_parameter_set_id,
            :submission_date => mixture.submission_date,
            :status => mixture.status,
            :submitted_by_id => mixture.submitted_by_id,
            :sample_prep_kit_id => mixture.sample_prep_kit_id
          )
          sample.save

          # set status this way to bypass AASM
          sample.update_attribute('status', mixture.status)
        end
      end
    end

    drop_table :sample_mixtures

    remove_column :samples, :sample_mixture_id
    remove_column :flow_cell_lanes, :sample_mixture_id
  end
end
