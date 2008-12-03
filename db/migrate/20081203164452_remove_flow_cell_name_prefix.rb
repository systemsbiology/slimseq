class RemoveFlowCellNamePrefix < ActiveRecord::Migration
  def self.up
    FlowCell.find(:all).each do |flow_cell|
      flow_cell.name = flow_cell.name.gsub(/^FC/, '')
      flow_cell.save
    end
  end

  def self.down
    FlowCell.find(:all).each do |flow_cell|
      flow_cell.name = flow_cell.prefixed_name
      flow_cell.save
    end
  end
end
