class AddSequencingRunBestAttribute < ActiveRecord::Migration
  def self.up
    add_column :sequencing_runs, :best, :boolean, :default => true
    
    SequencingRun.find(:all).each do |run|
      flow_cell = run.flow_cell
      
      # this run is the best if it is the most recent for a particular flow cell
      if(flow_cell.sequencing_runs.find(:first, :order => "date DESC") == run)
        run.update_attribute('best', true)
      else
        run.update_attribute('best', false)
      end
    end
  end

  def self.down
    remove_column :sequencing_runs, :best
  end
end
