class SamplesController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    populate_arrays_from_tables

    if(@lab_groups != nil && @lab_groups.size > 0)
      # make an array of the accessible project ids, and use this
      # to find the current user's accessible samples in a nice sorted list
      project_ids = Array.new
      for project in @projects
        project_ids << project.id
      end
      @samples = Sample.find(:all, :conditions => [ "project_id IN (?)", project_ids ],
                                :order => "submission_date DESC, sample_name ASC", :include => 'project')
    end
  end

  def new
    populate_arrays_from_tables

    # clear out sample table since this is a 'new' set
    session[:samples] = Array.new
    session[:sample_number] = 0
    
    @add_samples = AddSamples.new
  end

  def add
    populate_arrays_from_tables
    
    @samples = session[:samples]
    previous_samples = session[:sample_number]

    @add_samples = AddSamples.new(params[:add_samples])
    # should a new project be created?
    if(@add_samples.project_id == -1)
      @project = Project.new(params[:project])
      if(@project.save)
        @add_samples.project_id = @project.id
      end
    end

    # only add more sample slots if that's what was asked
    if(@add_samples.project_id != -1 && @add_samples.valid?) 
      for sample_number in previous_samples+1..previous_samples+@add_samples.number
        @samples << Sample.new(:submission_date => @add_samples.submission_date,      
              :chip_type_id => @add_samples.chip_type_id,
              :sbeams_user => @add_samples.sbeams_user,                                              
              :project_id => @add_samples.project_id,
              :organism_id => ChipType.find( @add_samples.chip_type_id).organism_id,
              :status => 'submitted')
      end
      session[:sample_number] = previous_samples + @add_samples.number 
    else
      render :action => 'add'
    end
  end
  
  def create
    populate_arrays_from_tables  
    @samples = session[:samples]
    sample_number = session[:sample_number]

    failed = false 
    for n in 0..sample_number-1
      form_entries = params['sample-'+n.to_s]
      # add the user info from the forms
      @samples[n].short_sample_name = form_entries['short_sample_name']
      @samples[n].sample_name = form_entries['sample_name']
      @samples[n].sample_group_name = form_entries['sample_group_name']
      @samples[n].organism_id = form_entries['organism_id']
      
      # if any one sample record isn't valid,
      # we don't want to save any
      if !@samples[n].valid?
        failed = true
      end
    end
    if failed
      @add_samples = AddSamples.new(:number => 0)
      render :action => 'add'
    else
      # save now that all samples have been tested as valid
      for n in 0..sample_number-1
        @samples[n].save
      end
      flash[:notice] = "Samples created successfully"
      redirect_to :action => 'show'
    end
  end
  
  def show
    if session[:samples] == nil
      @samples = Array.new
    else
      @samples = session[:samples]
    end
  end

  def clear
    session[:samples] = Array.new
    session[:sample_number] = 0
    redirect_to :action => 'new'
  end

  def edit
    populate_arrays_from_tables
    @sample = Sample.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    @sample = Sample.find(params[:id])

    begin
      if @sample.update_attributes(params[:sample])
        flash[:notice] = 'Sample was successfully updated.'
        redirect_to :action => 'list'
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this sample."
      @sample = Sample.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    sample = Sample.find(params[:id])

    if(current_user.staff? || current_user.admin? || sample.status == "submitted")
      sample.destroy
      redirect_to :back
    else
      flash[:warning] = "Unable to destroy samples that have already been hybridized."
      list
      render :action => 'list'
    end
  end
  
  def bulk_destroy
    selected_samples = params[:selected_samples]
    for sample_id in selected_samples.keys
      if selected_samples[sample_id] == '1'
        sample = Sample.find(sample_id)
        sample.destroy
      end
    end
    redirect_to :action => 'list'
  end
  
  # handle different requests for sample submission
  # from quality traces
  def submit_traces
    selected_traces = params[:selected_traces]
    traces = Array.new
    for trace_id in selected_traces.keys
      if selected_traces[trace_id] == '1'
        trace = QualityTrace.find(trace_id)
        traces << trace
      end
    end
    if(params[:commit] == "Request Labeling")
      new_from_traces(traces)
      render :action => 'new_from_traces'
    elsif(params[:commit] == "Request Hybridization")
      match_traces(traces)
      render :action => 'match_traces'
    end
  end
  
  # labeling submission, from total RNA traces
  def new_from_traces(traces)
    populate_arrays_from_tables
    
    #@samples = samples
    @samples = Array.new
    for trace in traces
      if( trace.sample_type == "total" )
        @samples << Sample.new(:sample_name => trace.name,
              :starting_quality_trace_id => trace.id,
              :status => 'submitted')
      else
        flash[:warning] = "Only total RNA may be submitted"
      end
    end
    
    session[:samples] = @samples
  end
  
  # create samples from total RNA traces
  def create_from_traces
    populate_arrays_from_tables  
    @samples = session[:samples]

    @add_samples = AddSamples.new(params[:add_samples])

    # should a new project be created?
    if(@add_samples.project_id == -1)
      @project = Project.new(params[:project])
      if(@project.save)
        @add_samples.project_id = @project.id
      end
    end

    failed = false 
    for n in 0..@samples.size-1
      form_entries = params['sample-'+n.to_s]
      # add sample info from forms
      @samples[n].short_sample_name = form_entries['short_sample_name']
      @samples[n].sample_name = form_entries['sample_name']
      @samples[n].sample_group_name = form_entries['sample_group_name']
      
      # add meta info from forms, for newly-created samples only
      if( @samples[n].new_record? )
        @samples[n].submission_date = @add_samples.submission_date
        @samples[n].chip_type_id = @add_samples.chip_type_id
        @samples[n].sbeams_user = @add_samples.sbeams_user
        @samples[n].project_id = @add_samples.project_id
      end
      
      # if any one sample record isn't valid,
      # we don't want to save any
      if !@samples[n].valid?
        failed = true
      end
    end

    if failed
      render :action => 'new_from_traces'
    else
      # save now that all samples have been tested as valid
      for n in 0..@samples.size-1
        @samples[n].save
      end
      flash[:notice] = "Samples created successfully"
      redirect_to :action => 'show'
    end
  end

  # interface to match up traces and Samples
  def match_traces(traces)
    populate_arrays_from_tables
    
    lab_group_ids = current_user.get_lab_group_ids
    
    # make an array of the accessible project ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    project_ids = Array.new
    for project in @projects
      project_ids << project.id
    end
    
    # get samples for user's projects
    @available_samples = Sample.find(:all, :conditions => [ "project_id IN (?) AND status = 'submitted'", project_ids ],
                           :order => "sample_name ASC", :include => 'project')
    
    available_traces = QualityTrace.find(:all, :conditions => [ "lab_group_id IN (?)", lab_group_ids ],
                                   :order => "name ASC")
    
    # remove all traces associated with a hybridized sample from list of available traces
    hybridized_samples = Sample.find(:all, :conditions => [ "project_id IN (?) AND status = 'hybridized'", project_ids ],
                           :order => "sample_name ASC", :include => 'project')

    # remove traces that are associated with hybridized samples
    # there'd be less looping, but a lot more SQL queries if this was by Sample.find
    for sample in hybridized_samples
      for trace in available_traces
        if( sample.starting_quality_trace_id == trace.id ||
            sample.amplified_quality_trace_id == trace.id ||
            sample.fragmented_quality_trace_id == trace.id)
          available_traces.delete(trace) 
        end
      end
    end

    # check each trace to see if it belongs in one of the sets
    @total_traces = Array.new
    @cRNA_traces = Array.new
    @frag_traces = Array.new
    for trace in available_traces
      # put the trace in the appropriate Array
      if( trace.sample_type.downcase.match(/total/) != nil )
        @total_traces << trace
      elsif( trace.sample_type.downcase.match(/crna/) != nil )
        @cRNA_traces << trace
      elsif( trace.sample_type.downcase.match(/frag/) != nil ) 
        @frag_traces << trace
      end
    end

    # generate a list of unique names among available samples and selected traces
    @unique_names = Array.new
#    for sample in @available_samples
#      if( !@unique_names.include?(sample.sample_name) )
#        @unique_names << sample.sample_name
#      end
#    end
    for trace in traces
      if( !@unique_names.include?(trace.name) && trace.name != "Ladder"  )
        @unique_names << trace.name
      end
    end
    
    @samples = Array.new
    # make an array of samples, one per each unique name identified
    for name in @unique_names
      # see if there's already a sample for this name
      sample = Sample.find(:first, 
                           :conditions => [ "project_id IN (?) AND status = 'submitted' AND sample_name LIKE ?", project_ids, name ],
                           :order => "sample_name ASC", :include => 'project')
      
      # if no sample is found, create one
      if( sample == nil )
        sample = Sample.new
      end
      
      # find any traces with the same name, and associate them
      # put these into an array that holds the samples that'll be shown on the form
      starting_trace = QualityTrace.find(:first,
                                         :conditions => [ "name = ? AND sample_type LIKE ?", name, "total" ],
                                         :order => "name ASC")
      if(starting_trace != nil)
        sample.starting_quality_trace_id = starting_trace.id
      end
      
      amplified_trace = QualityTrace.find(:first,
                                          :conditions => [ "name = ? AND sample_type LIKE ?", name, "cRNA" ],
                                          :order => "name ASC")
      if(amplified_trace != nil)
        sample.amplified_quality_trace_id = amplified_trace.id
      end
      
      fragmented_trace = QualityTrace.find(:first,
                                           :conditions => [ "name = ? AND sample_type LIKE ?", name, "frag" ],
                                           :order => "name ASC")
      if(fragmented_trace != nil)
        sample.fragmented_quality_trace_id = fragmented_trace.id
      end
      
      @samples << sample
    end
    
  end

  # decide whether to take matched traces/samples and either directly create
  # new samples (if traces were matched to existing, complete samples, OR
  # go to new_from_traces, if user needs to provide further sample info
  def submit_matched_traces
    populate_arrays_from_tables

    num_samples = params['num_samples'].to_i
    
    @samples = Array.new
    all_samples_exist = true
    for n in 0..num_samples-1
      # get each matched set
      matched_set = params['sample-'+n.to_s]
      
      sample = Sample.new
      # use existing Sample if one was selected
      if( matched_set['id'].to_i > 0 )
        sample = Sample.find(matched_set['id'])    
      else
        # if any one sample doesn't yet exist in the database, take note
        all_samples_exist = false
        
        # set status to submitted and give a default sample name
        sample.status = 'submitted'
        sample.sample_name = matched_set['name']
      end
      
      # assign quality traces where they exist
      if( matched_set['starting_quality_trace_id'].to_i > 0 )
        sample.starting_quality_trace_id = matched_set['starting_quality_trace_id']
      end
      if( matched_set['amplified_quality_trace_id'].to_i > 0 )
        sample.amplified_quality_trace_id = matched_set['amplified_quality_trace_id']
      end
      if( matched_set['fragmented_quality_trace_id'].to_i > 0 )
        sample.fragmented_quality_trace_id = matched_set['fragmented_quality_trace_id']
      end
      
      @samples << sample
    end

    # If all samples already exist in database, just save them with their new trace
    # assignments. Otherwise, go to new_from_traces
    session[:samples] = @samples
    if( all_samples_exist )
      # save now that all samples have been tested as valid
      for n in 0..num_samples-1
        @samples[n].save
      end
      flash[:notice] = "Samples created successfully"
      redirect_to :action => 'show'
    else
      render :action => 'new_from_traces'
    end
  end
  
  private
  def populate_arrays_from_tables
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
    
    # Administrators and staff can see all projects, otherwise users
    # are restricted to seeing only projects for lab groups they belong to
    if(current_user.staff? || current_user.admin?)
      @lab_groups = LabGroup.find(:all, :order => "name ASC")
      @projects = Project.find(:all, :order => "name ASC")
    else
      @projects = Array.new
      @lab_groups = current_user.lab_groups
      @lab_groups.each do |g|
        @projects << g.projects
      end
      # put it all down to a 1D Array
      @projects = @projects.flatten
    end
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")
  end

end
