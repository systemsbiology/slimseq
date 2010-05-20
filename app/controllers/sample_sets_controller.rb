class SampleSetsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections
  
  def new
    if(params[:step] == "2")
      @sample_set = SampleSet.new( params[:sample_set].merge(:submitted_by => current_user.login) )

      if(@sample_set.valid?)
        @samples_need_approval = @sample_set.project.lab_group.lab_group_profile.samples_need_approval

        @naming_scheme = @sample_set.naming_scheme
        if(@naming_scheme != nil)
          @naming_elements = @naming_scheme.ordered_naming_elements
        end

        @sample_mixtures = @sample_set.sample_mixtures
      else
        # if the sample set info is invalid, kick back to step 1
        params[:step] = "1"
      end
    else
      @sample_set = SampleSet.new
    end
  end

  def create
    @sample_set = SampleSet.new(params[:sample_set])

    respond_to do |format|
      if @sample_set.save
        format.html do
          flash[:notice] = 'Samples were successfully created.'
          redirect_to(samples_url)
        end
        format.json { render :json => {:message => "Samples recorded"} }
      else
        format.html do
          @sample_mixtures = @sample_set.sample_mixtures
          @naming_scheme = @sample_set.naming_scheme
          if(@naming_scheme != nil)
            @naming_elements = @naming_scheme.ordered_naming_elements
          end
          params[:step] = '2'
          render :action => 'new'
        end
        format.json do
          error_text = (@sample_set.errors.collect {|e| e[1].to_s}).join(", ")
          render :json => {:message => error_text}, :status => :unprocessable_entity
        end
      end
    end
  end

  def cancel_new_project
    render :partial => 'projects'
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
