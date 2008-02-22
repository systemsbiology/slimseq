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

      # make sure at least one project exists
      if(project_ids.size > 0)
        @sample_pages, @samples =
          paginate :samples, :conditions => [ "project_id IN (?)", project_ids ], :per_page => 40,
                   :order => "submission_date DESC, samples.id ASC", :include => 'project'
      end
    end
  end
  
  def new
    populate_arrays_from_tables
    
    @naming_schemes = NamingScheme.find(:all)
    
    # clear out sample table since this is a 'new' set
    session[:samples] = Array.new
    session[:sample_number] = 0

    @add_samples = AddSamples.new
    @project = Project.new
  end

  def add
    populate_arrays_from_tables

    @add_samples = AddSamples.new(params[:add_samples])
    if( @add_samples.naming_scheme_id != nil )
      # change current naming scheme to whatever was selected
      current_user.current_naming_scheme_id = @add_samples.naming_scheme_id
      current_user.save
      populate_sample_naming_scheme_choices( NamingScheme.find(@add_samples.naming_scheme_id) )
    end
    
    @naming_schemes = NamingScheme.find(:all)
    
    @samples = session[:samples]
    previous_samples = session[:sample_number]

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
        
        # deal with initial visibility for schemed names
        if( @add_samples.naming_scheme_id == nil )
          visibility = nil
          text_values = nil
        else
          # set initial visibilities, text values
          visibility = Array.new
          text_values = Hash.new
          for element in @naming_elements
            if( element.dependent_element_id > 0 )
              visibility << false
            else
              visibility << true
            end
            
            # free text
            if( element.free_text )
              text_values[element.name] = ""
            end
          end
        end

        @samples << Sample.new(:submission_date => @add_samples.submission_date,      
              :chip_type_id => @add_samples.chip_type_id,
              :sbeams_user => @add_samples.sbeams_user,                                              
              :project_id => @add_samples.project_id,
              :organism_id => ChipType.find( @add_samples.chip_type_id).organism_id,
              :status => 'submitted',
              :naming_element_visibility => visibility,
              :text_values => text_values)
      end
      session[:sample_number] = previous_samples + @add_samples.number 
    else
      render :action => 'new'
    end
  end
  
  def update_add_form
    # find the number of the sample on the page (this is not the sample id)
    @n = params['sample_number'].to_i

    # the sample
    @sample = session[:samples][@n]

    # the element that is depended upon
    @dependent_element_id = params['dependent_id'].to_i

    # find the elements that are depending upon the altered field
    @dependent_elements = NamingElement.find(:all, :conditions => ["dependent_element_id = ?", @dependent_element_id])# iterate through naming elements in form

    choice_text = params['choice'].gsub(/\&\_\=/,"")
    @choice = choice_text.to_i

    populate_sample_naming_scheme_choices(current_user.naming_scheme)
  end
  
  def create
    populate_arrays_from_tables
    populate_sample_naming_scheme_choices(current_user.naming_scheme)

    @samples = session[:samples]
    sample_number = session[:sample_number]

    # array of arrays terms per each sample
    sample_terms = Array.new
    sample_texts = Array.new
    
    failed = false
    for n in 0..sample_number-1
      form_entries = params['sample-'+n.to_s]
      # add the user info from the forms
      @samples[n].short_sample_name = form_entries['short_sample_name']
      
      # see if a naming scheme was used
      schemed_name = params['sample-'+n.to_s+'_schemed_name']
      if(schemed_name != nil)
        naming_scheme = current_user.naming_scheme  
        @samples[n].naming_scheme_id = current_user.current_naming_scheme_id
        @samples[n].sample_name = ""
        @samples[n].sample_group_name = ""
        @samples[n].naming_element_selections = Array.new
        sample_terms[n] = Array.new
        sample_texts[n] = Array.new
        #term_count = 0

        for element in @naming_elements
          # put underscores between terms
          if(element.include_in_sample_name && @samples[n].sample_name.length > 0)
            @samples[n].sample_name << "_"
            
            # add an underscore between group terms
            if(element.group_element == true)
              @samples[n].sample_group_name << "_"
            end
          end

          # save user's selections in case page needs to be re-rendered
          @samples[n].naming_element_selections << schemed_name[element.name]
          
          
          if( element.free_text )
            sample_text = SampleText.new( :text => schemed_name[element.name],
                                          :naming_element_id => element.id )
            sample_texts[n] << sample_text

            # include in the sample name if desired, and field isn't blank
            if( element.include_in_sample_name && !schemed_name[element.name].nil? )
              @samples[n].sample_name << schemed_name[element.name]

              # add to group name if this is a group element
              if(element.group_element == true)
                @samples[n].sample_group_name << schemed_name[element.name]
              end
            end
          else
            if( schemed_name[element.name].to_i > 0 )
              naming_term = NamingTerm.find(schemed_name[element.name])
              naming_element = naming_term.naming_element
              sample_term = SampleTerm.new( :term_order => naming_element.element_order,
                                            :naming_term_id => naming_term.id )
              sample_terms[n] << sample_term
              
              if( element.include_in_sample_name )
                @samples[n].sample_name << naming_term.abbreviated_term

                # add to group name if this is a group element
                if(element.group_element == true)
                  @samples[n].sample_group_name << naming_term.abbreviated_term
                end
              end
            end
          end
        end
      else
        # if a schemed name was not used, just use the plain text name and group
        @samples[n].sample_name = form_entries['sample_name']
        @samples[n].sample_group_name = form_entries['sample_group_name']
      end
      @samples[n].organism_id = form_entries['organism_id']
      
      # if any one sample record isn't valid,
      # we don't want to save any
      if !@samples[n].valid?
        failed = true
      end
    end
    
    if failed
      @add_samples = AddSamples.new(:number => 0)
      populate_sample_naming_scheme_choices(current_user.naming_scheme)
      render :action => 'add'
    else
      # save now that all samples have been tested as valid
      for n in 0..sample_number-1
        @samples[n].save

        # if there are sample terms, save them
        if(sample_terms[n] != nil && sample_terms[n].size > 0)
          for sample_term in sample_terms[n]
            # grab the newly-generated sample id
            sample_term.sample_id = @samples[n].id
            sample_term.save
          end
        end
        
        # if there are sample texts, save them
        if(sample_texts[n] != nil && sample_texts[n].size > 0)
          for sample_text in sample_texts[n]
            # grab the newly-generated sample id
            sample_text.sample_id = @samples[n].id
            sample_text.save
          end
        end
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

    # if a naming scheme was used, populate the necessary fields
    if( @sample.naming_scheme_id != nil )
      populate_sample_naming_scheme_choices(@sample.naming_scheme)
      @sample_terms = SampleTerm.find(:all, :conditions => ["sample_id = ?", @sample.id],
                                      :order => "term_order ASC")
      @sample_texts = SampleText.find(:all, :conditions => ["sample_id = ?", @sample.id])
      
      # set default visibilities
      visibility = Array.new
      for element in @naming_elements
        if( element.dependent_element_id > 0 )
          visibility << false
        else
         visibility << true
        end
      end
      
      # set sample-specific visibilities
      for term in @sample_terms
        # see if there's a naming term for this element,
        # and if so show it
        i = @naming_elements.index( term.naming_term.naming_element )
        if( i != nil)
          visibility[i] = true
        end        
      end
      
      # find dependent elements, and show them
      # if the element they depend upon is shown
      for i in (0..@naming_elements.size-1)
        element = @naming_elements[i]
        
        # does this element depend upon another?
        if( element.dependent_element_id > 0 )
          dependent_element = NamingElement.find(element.dependent_element_id)
          # check each term to see if the dependent is used
          for term in @sample_terms
            if(term.naming_term.naming_element == dependent_element)
              visibility[i] = true
            end
          end
        end
      end
      
      
      @sample.naming_element_visibility = visibility
      
      # set current selections
      selections = Array.new(@naming_elements.size, -1)
      for term in @sample_terms
        # see if there's a naming term for this element,
        # and if so record selection
        naming_term = term.naming_term
        i = @naming_elements.index( naming_term.naming_element )
        if( i != nil)
          selections[i] = naming_term.id
        end
      end
      
      @sample.naming_element_selections = selections
      
      @sample.text_values = Hash.new
      # set sample texts
      for text in @sample_texts
        @sample.text_values[text.naming_element.name] = text.text
      end
      
      # put Sample in an array and store it in the session
      # for update_add_form
      @samples = Array.new
      @samples << @sample
      session[:samples] = @samples
    end
    
    populate_arrays_for_edit(@sample)
  end

  def update
    @sample = Sample.find(params[:id])
    @samples = Array.new
    @samples << @sample

    # see if a naming scheme was used
    schemed_name = params['sample-0_schemed_name']
    if(schemed_name != nil)
      naming_scheme = NamingScheme.find(@samples[0].naming_scheme_id)
      populate_sample_naming_scheme_choices(naming_scheme)
      @samples[0].sample_name = ""
      @samples[0].sample_group_name = ""
      @samples[0].naming_element_selections = Array.new
      sample_terms = Array.new
      sample_terms[0] = Array.new
      sample_texts = Array.new
      sample_texts[0] = Array.new
      term_count = 0

      for element in @naming_elements
        # put underscores between terms
        if(@samples[0].sample_name.length > 0)
          @samples[0].sample_name << "_"
          
          # add an underscore between group terms
          if(element.group_element == true)
            @samples[0].sample_group_name << "_"
          end
        end

        # save user's selections in case page needs to be re-rendered
        @samples[0].naming_element_selections << schemed_name[element.name]
        
        if( element.free_text )
          sample_text = SampleText.new( :text => schemed_name[element.name],
                                        :naming_element_id => element.id )
          sample_texts[0] << sample_text
          @samples[0].sample_name << schemed_name[element.name].to_s

          # add to group name if this is a group element
          if(element.group_element == true)
            @samples[0].sample_group_name << schemed_name[element.name]
          end
        else
          if( schemed_name[element.name].to_i > 0 )
            naming_term = NamingTerm.find(schemed_name[element.name])
            naming_element = naming_term.naming_element
            sample_term = SampleTerm.new( :term_order => naming_element.element_order,
                                          :naming_term_id => naming_term.id )
            sample_terms[0] << sample_term
            @samples[0].sample_name << naming_term.abbreviated_term

            # add to group name if this is a group element
            if(element.group_element == true)
              @samples[0].sample_group_name << naming_term.abbreviated_term
            end

            term_count += 1
          end
        end
      end
    end

    # shorten up sample and group names if needed
    if( @samples[0].sample_name.length > 59 )
      @samples[0].sample_name = @samples[0].sample_name[0..58]
    end
    if( @samples[0].sample_group_name.length > 59 )
      @samples[0].sample_group_name = @samples[0].sample_group_name[0..58]
    end
    
    begin
      # update main sample attributes, and if successful go
      # ahead and re-populate sample terms, if applicable
      if @samples[0].update_attributes(params[:sample])
        if(schemed_name != nil)
          # trash existing sample terms
          terms = @samples[0].sample_terms
          for term in terms
            term.destroy
          end
          
          # then re-populate this sample's terms
          for sample_term in sample_terms[0]
            sample_term.sample_id = @samples[0].id
            sample_term.save
          end
          
          # if there are sample texts, delete old and save new
          texts = @samples[0].sample_texts
          for text in texts
            text.destroy
          end
          
          if(sample_texts[0] != nil && sample_texts[0].size > 0)
            for sample_text in sample_texts[0]
              # grab the newly-generated sample id
              sample_text.sample_id = @samples[0].id
              sample_text.save
            end
          end
        end

        flash[:notice] = 'Sample was successfully updated.'
        redirect_to :action => 'list'
      else
        flash[:warning] = 'Resulting sample name or group name too long'
        params[:id] = @samples[0].id
        edit
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this sample."
      #@sample = Sample.find(params[:id])
      params[:id] = @samples[0].id
      edit
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
      # match traces to submitted (non-hybridized) arrays
      match_traces(traces, "submitted")
      render :action => 'match_traces'
    elsif(params[:commit] == "Match to Hybridized Samples")
      # match only to hybridized arrays
      match_traces(traces, "hybridized")
      render :action => 'match_traces'
    end
  end
  
  # labeling submission, from total RNA traces
  def new_from_traces(traces)
    populate_arrays_from_tables
    populate_sample_naming_scheme_choices(current_user.naming_scheme)
    
    @add_samples = AddSamples.new
    @project = Project.new
        
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
    populate_sample_naming_scheme_choices(current_user.naming_scheme)
    
    @samples = session[:samples]

    @add_samples = AddSamples.new(params[:add_samples])

    failed = false

    # should a new project be created?
    if(@add_samples.project_id == -1)
      @project = Project.new(params[:project])
      if(@project.save)
        @add_samples.project_id = @project.id
      else
        failed = true
      end
    end

    # only proceed if project creation succeeded or wasn't necessary
    if !failed
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
          @samples[n].organism_id = ChipType.find(@add_samples.chip_type_id).organism_id
          @samples[n].sbeams_user = @add_samples.sbeams_user
          @samples[n].project_id = @add_samples.project_id
        end
        
        # if any one sample record isn't valid,
        # we don't want to save any
        if !@samples[n].valid?
          failed = true
        end
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
  def match_traces(traces, sample_status)
    populate_arrays_from_tables
    
    lab_group_ids = current_user.get_lab_group_ids
    
    # make an array of the accessible project ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    project_ids = Array.new
    for project in @projects
      project_ids << project.id
    end
    
    # get samples for user's projects
    @available_samples = Sample.find(:all, :conditions => [ "project_id IN (?) AND status = '#{sample_status}'", project_ids ],
                           :order => "sample_name ASC", :include => 'project')
    
    available_traces = QualityTrace.find(:all, :conditions => [ "lab_group_id IN (?)", lab_group_ids ],
                                   :order => "name ASC")
    
    # remove all traces associated with a sample from list of available traces
    existing_samples = Sample.find(:all, :conditions => [ "project_id IN (?)", project_ids ],
                           :order => "sample_name ASC", :include => 'project')

    # remove traces that are associated with hybridized samples
    # there'd be less looping, but a lot more SQL queries if this was by Sample.find
    for sample in existing_samples
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
                           :conditions => [ "project_id IN (?) AND status = '#{sample_status}' AND sample_name LIKE ?", project_ids, name ],
                           :order => "sample_name ASC", :include => 'project')
      
      # find any traces with the same name, and associate them
      # put these into an array that holds the samples that'll be shown on the form
      starting_trace = QualityTrace.find(:first,
                                         :conditions => [ "name = ? AND sample_type LIKE ?", name, "total" ],
                                         :order => "name ASC")
      amplified_trace = QualityTrace.find(:first,
                                          :conditions => [ "name = ? AND sample_type LIKE ?", name, "cRNA" ],
                                          :order => "name ASC")
      fragmented_trace = QualityTrace.find(:first,
                                           :conditions => [ "name = ? AND sample_type LIKE ?", name, "frag" ],
                                           :order => "name ASC")


      # if a sample hasn't been found yet, see if starting trace is tied to a sample
      if( sample == nil && starting_trace != nil )
        sample = Sample.find(:first, 
                             :conditions => [ "starting_quality_trace_id = ? AND status = '#{sample_status}'", starting_trace.id ])
      end
      # if a sample hasn't been found yet, see if amplified trace is tied to a sample
      if( sample == nil && amplified_trace != nil )
        sample = Sample.find(:first, 
                             :conditions => [ "amplified_quality_trace_id = ? AND status = '#{sample_status}'", amplified_trace.id ])
      end      
      # if a sample hasn't been found yet, see if fragmented trace is tied to a sample
      if( sample == nil && fragmented_trace != nil )
        sample = Sample.find(:first, 
                             :conditions => [ "fragmented_quality_trace_id = ? AND status = '#{sample_status}'", fragmented_trace.id ])
      end

      # make use of any traces already tied to the sample, if a sample
      # has been identified
      if( sample != nil )
        if( sample.starting_quality_trace_id != nil )
          starting_trace = QualityTrace.find(sample.starting_quality_trace_id)
        end
        if( sample.amplified_quality_trace_id != nil )
          amplified_trace = QualityTrace.find(sample.amplified_quality_trace_id)
        end
        if( sample.fragmented_quality_trace_id != nil )
          fragmented_trace = QualityTrace.find(sample.fragmented_quality_trace_id)
        end
      end

      # if no sample is found has been found yet, create one
      if( sample == nil )
        sample = Sample.new
      end

      # tie all the traces specified to the sample, and make sure
      # they're in drop-down choices
      if( starting_trace != nil )
        sample.starting_quality_trace_id = starting_trace.id
        if( !@total_traces.include?(starting_trace) )
          @total_traces << starting_trace
        end
      end
      if( amplified_trace != nil )
        sample.amplified_quality_trace_id = amplified_trace.id
        if( !@cRNA_traces.include?(amplified_trace) )
          @cRNA_traces << amplified_trace
        end
      end
      if( fragmented_trace != nil )
        sample.fragmented_quality_trace_id = fragmented_trace.id
        if( !@frag_traces.include?(fragmented_trace) )
          @frag_traces << fragmented_trace
        end
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
        # if any one sample doesn't yet exist in the database AND the trace drop-downs
        # haven't been all blanked out, will need to collect further sample info
        if( matched_set['starting_quality_trace_id'].to_i > 0 ||
            matched_set['amplified_quality_trace_id'].to_i > 0 ||
            matched_set['fragmented_quality_trace_id'].to_i > 0)
          all_samples_exist = false
        end
        
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
      
      # only add the sample to our set if there's at least one trace associated with it
      if( sample.starting_quality_trace_id != nil || sample.amplified_quality_trace_id != nil ||
          sample.fragmented_quality_trace_id != nil )
        @samples << sample
      end
    end

    # If all samples already exist in database, just save them with their new trace
    # assignments. Otherwise, go to new_from_traces
    session[:samples] = @samples
    if( all_samples_exist )
      # save now that all samples have been tested as valid
      for n in 0..@samples.size-1
        @samples[n].save
      end
      flash[:notice] = "Samples created successfully"
      redirect_to :action => 'show'
    else
      @add_samples = AddSamples.new
      populate_sample_naming_scheme_choices(current_user.naming_scheme)
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

  def populate_arrays_for_edit(selected_sample)
    lab_group_ids = current_user.get_lab_group_ids
    
    # make an array of the accessible project ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    project_ids = Array.new
    for project in @projects
      project_ids << project.id
    end
    
    # remove all traces associated with a sample from list of available traces
    existing_samples = Sample.find(:all, :conditions => [ "project_id IN (?)", project_ids ],
                           :order => "sample_name ASC", :include => 'project')

    # remove traces that are associated with hybridized samples
    used_trace_ids = Array.new
    for sample in existing_samples
      if(sample.starting_quality_trace_id != nil)
        used_trace_ids << sample.starting_quality_trace_id
      end
      if(sample.amplified_quality_trace_id != nil)
        used_trace_ids << sample.amplified_quality_trace_id
      end
      if(sample.fragmented_quality_trace_id != nil)
        used_trace_ids << sample.fragmented_quality_trace_id
      end
    end

    # don't count traces for current sample, if it has any, since
    # we want this sample's traces to be in the list
    if(selected_sample.starting_quality_trace_id != nil)
      used_trace_ids.delete(selected_sample.starting_quality_trace_id)
    end
    if(selected_sample.amplified_quality_trace_id != nil)
      used_trace_ids.delete(selected_sample.amplified_quality_trace_id)
    end
    if(selected_sample.fragmented_quality_trace_id != nil)
      used_trace_ids.delete(selected_sample.fragmented_quality_trace_id)
    end

    if( used_trace_ids.size > 0 )
      available_traces = QualityTrace.find(:all, :conditions => [ "id NOT IN (?)", used_trace_ids ],
                                           :order => "name ASC")
    else
      available_traces = QualityTrace.find(:all, :order => "name ASC")
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
  end
  
  def populate_sample_naming_scheme_choices(scheme)
    # only if the user has a specified scheme, find out what elements we need
    if( scheme != nil )
      @naming_elements = NamingElement.find(:all, :conditions => ["naming_scheme_id = ?", scheme.id],
                                            :order => "element_order ASC" )
    end
  end
end
