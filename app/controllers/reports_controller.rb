class ReportsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  def billing
    @paged_lanes = FlowCellLane.find(:all,
        :include => [:samples => [:sample_prep_kit] , :flow_cell => :sequencing_runs ],
        :order => 'sequencing_runs.date DESC, samples.budget_number ASC',
        :conditions => "(samples.status = 'completed' OR samples.status = 'sequenced')" +
          " AND samples.control = 'false'")
    @users_by_id = User.all_by_id
  end

end
