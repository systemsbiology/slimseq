class CreateDesiredReads < ActiveRecord::Migration
  def self.up
    create_table :desired_reads do |t|
      t.integer :desired_read_length
      t.integer :alignment_start_position
      t.integer :alignment_end_position
      t.integer :sample_mixture_id

      t.timestamps
    end

    SampleMixture.all.each do |mixture|
      mixture.desired_reads.create(
        :desired_read_length => mixture.desired_read_length,
        :alignment_start_position => mixture.alignment_start_position,
        :alignment_end_position => mixture.alignment_end_position
      )
    end

    remove_column :sample_mixtures, :desired_read_length
    remove_column :sample_mixtures, :alignment_start_position
    remove_column :sample_mixtures, :alignment_end_position
  end

  def self.down
    drop_table :desired_reads
  end
end
