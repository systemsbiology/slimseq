class PipelineResultFile < ActiveRecord::Base
  belongs_to :pipeline_result

  validates_presence_of :file_path
end
