class ReportsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  def billing
    @paged_lanes = FlowCellLane.paginate :page => params[:page],
        :include => [:samples => [:sample_prep_kit, :user] , :flow_cell => :sequencing_runs ],
        :order => 'sequencing_runs.date DESC, samples.budget_number ASC',
        #:conditions => {:status => 'completed', :samples => {:control => 'false'} }
        :conditions => "samples.status = 'completed' AND samples.control = 'false'"
  end

  def run_summary
  end

end
