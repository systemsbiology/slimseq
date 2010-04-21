class ReportsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  def billing
    @paged_lanes = FlowCellLane.find(:all,
        :include => [:sample_mixture => [:samples, :sample_prep_kit] , :flow_cell => :sequencing_runs ],
        :order => 'sequencing_runs.date DESC, sample_mixtures.budget_number ASC',
        :conditions => "(sample_mixtures.status = 'completed' OR sample_mixtures.status = 'sequenced')" +
          " AND sample_mixtures.control = 'false'")
    @users_by_id = User.all_by_id
  end

end
