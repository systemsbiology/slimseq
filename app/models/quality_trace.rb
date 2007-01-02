class QualityTrace < ActiveRecord::Base
  belongs_to :bioanalyzer_run
  validates_associated :bioanalyzer_run

  belongs_to :lab_group
  validates_associated :lab_group

  has_one :sample_starting, :class_name => "Sample", :foreign_key => "starting_quality_trace_id"
  has_one :sample_amplified, :class_name => "Sample", :foreign_key => "amplified_quality_trace_id"
  has_one :sample_fragmented, :class_name => "Sample", :foreign_key => "fragmented_quality_trace_id"

  # get rid of references to this trace in samples when it's being destroyed
  def before_destroy
    starting_associated_samples = Sample.find(:all, :conditions => ["starting_quality_trace_id = ?", id])
    for sample in starting_associated_samples
      sample.starting_quality_trace_id = ""
      sample.save
    end
    
    amplified_associated_samples = Sample.find(:all, :conditions => ["amplified_quality_trace_id = ?", id])
    for sample in amplified_associated_samples
      sample.amplified_quality_trace_id = ""
      sample.save
    end
    
    fragmented_associated_samples = Sample.find(:all, :conditions => ["fragmented_quality_trace_id = ?", id])
    for sample in fragmented_associated_samples
      sample.fragmented_quality_trace_id = ""
      sample.save
    end
  end
end
