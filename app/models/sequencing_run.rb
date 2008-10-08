class SequencingRun < ActiveRecord::Base
  belongs_to :flow_cell
  belongs_to :instrument
end
