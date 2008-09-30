class SampleSet < ActiveRecord::BaseWithoutTable
  column :submission_date, :date
  column :number_of_samples, :string
  column :naming_scheme_id, :integer
  column :sample_prep_kit_id, :integer
  column :budget_number, :string
  column :reference_genome_id, :integer
  column :desired_read_length, :integer
  column :insert_size, :integer

  validates_numericality_of :number_of_samples, :greater_than_or_equal_to => 1
  validates_numericality_of :desired_read_length, :insert_size,
    :naming_scheme_id, :sample_prep_kit_id, :reference_genome_id
  validates_presence_of :budget_number
end