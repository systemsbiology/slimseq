class SampleSetsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections
  
  def new
  end

  def create
    respond_to do |format|
      format.html do
        @sample_set = SampleSet.parse_form( params[:sample_set].merge(:submitted_by => current_user.login) )

        if @sample_set.save
          flash[:notice] = 'Samples were successfully created.'
          redirect_to(samples_url)
        else
          render :action => 'new'
        end
      end
      format.json do
        @sample_set = SampleSet.parse_api( params[:sample_set].merge(:submitted_by => current_user.login) )

        if @sample_set.save
          render :json => {:message => "Samples recorded"}
        else
          error_text = (@sample_set.errors.collect {|e| e[1].to_s}).join(", ")
          render :json => {:message => error_text}, :status => :unprocessable_entity
        end
      end
    end
  end

  def cancel_new_project
    render :partial => 'projects'
  end
  
  def sample_mixture_fields
    @naming_scheme = NamingScheme.find(params[:sample_set][:naming_scheme_id]) if params[:sample_set][:naming_scheme_id]
    Rails.logger.info "naming_scheme id = #{@naming_scheme.id}" if @naming_scheme
    @number_of_samples = params[:sample_set][:number_of_samples].to_i
    @project = Project.find(params[:sample_set][:project_id])
    @multiplexing_scheme = MultiplexingScheme.find(params[:sample_set][:multiplexing_scheme_id]) if params[:sample_set][:multiplexing_scheme_id]
    @samples_need_approval = @project.lab_group.lab_group_profile.samples_need_approval
    @samples_per_mixture = params[:sample_set][:samples_per_mixture].to_i

    render :partial => 'sample_mixture_fields'
  end

private

  def load_dropdown_selections
    @projects = Project.accessible_to_user(current_user)
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @sample_prep_kits = SamplePrepKit.find(:all, :order => "name ASC")
    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
    @eland_parameter_sets = ElandParameterSet.find(:all, :order => "name ASC")
  end
end
