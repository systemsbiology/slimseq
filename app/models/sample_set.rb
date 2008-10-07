class SampleSet < ActiveRecord::BaseWithoutTable
  column :submission_date, :date
  column :number_of_samples, :string
  column :project_id, :integer
  column :naming_scheme_id, :integer
  column :sample_prep_kit_id, :integer
  column :budget_number, :string
  column :reference_genome_id, :integer
  column :desired_read_length, :integer
  column :insert_size, :integer
  column :alignment_start_position, :integer, :default => 1
  column :alignment_end_position, :integer

  validates_numericality_of :number_of_samples, :greater_than_or_equal_to => 1
  validates_numericality_of :insert_size
  validates_presence_of :budget_number, :reference_genome_id,
    :sample_prep_kit_id, :desired_read_length, :project_id
  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1
  
  has_many :samples
  
  belongs_to :naming_scheme
end
