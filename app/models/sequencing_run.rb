class SequencingRun < ActiveRecord::Base
  has_one :flow_cell
end
