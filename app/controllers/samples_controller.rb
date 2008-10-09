class SamplesController < ApplicationController
  before_filter :login_required
  before_filter :populate_arrays_from_tables,
    :only => [:index, :list, :new, :add, :create, :edit, :update]
  
  def index
    list
    render :action => 'list'
  end

  def list
    if(@lab_groups != nil && @lab_groups.size > 0)
      @sample_pages, @samples =
        paginate :samples, :include => 'project',
          :conditions => [ "projects.lab_group_id IN (?) AND control = ?",
          current_user.get_lab_group_ids, false ],
          :per_page => 40, :order => "submission_date DESC, samples.id ASC"
    end
  end
  
  def new
    if( params[:number] )
      @samples = Array.new
      params[:number].to_i.times do
        @samples << Sample.new
      end
      
      render :partial => 'table'
    else
      render :action => 'new'
    end
  end

  def add
    @add_samples = AddSamples.new(params[:add_samples])

    # change current naming scheme to whatever was selected   
    if( @add_samples.naming_scheme_id != nil )
      current_user.update_attribute('current_naming_scheme_id', @add_samples.naming_scheme_id )
      populate_sample_naming_scheme_choices( NamingScheme.find(@add_samples.naming_scheme_id) )
    else
      current_user.update_attribute('current_naming_scheme_id', nil)
    end
 
    @naming_schemes = NamingScheme.find(:all)
    
    @samples = Array.new

    # should a new project be created?
    if(@add_samples.project_id == -1)
      @project = Project.new(params[:project])
      if(@project.save)
        @add_samples.project_id = @project.id
      end
    end

    # make sure there's a project and valid sample info
    if(@add_samples.project_id != -1 && @add_samples.valid?) 
      for sample_number in 1..@add_samples.number
        
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
    else
      render :action => 'new'
    end
  end
  
  def create
    populate_sample_naming_scheme_choices(current_user.naming_scheme)

    # store the non-naming scheme info in an array of Sample records
    @samples = Array.new
    params[:sample].keys.each do |n|
      @samples[n.to_i] = Sample.new(params[:sample][n])
    end

    # array of arrays terms per each sample
    sample_terms = Array.new
    sample_texts = Array.new
    
    failed = false
    for n in 0..@samples.size-1
      # see if a naming scheme was used
      schemed_name = params[:sample][n.to_s][:schemed_name]

      if(schemed_name != nil)
        @samples[n].naming_scheme_id = current_user.current_naming_scheme_id
        @samples[n].sample_name = ""
        @samples[n].sample_group_name = ""
        sample_terms[n] = Array.new
        sample_texts[n] = Array.new

        for element in @naming_elements
          # put underscores between terms
          if(element.include_in_sample_name && @samples[n].sample_name.length > 0)
            @samples[n].sample_name << "_"
            
            # add an underscore between group terms
            if(element.group_element == true)
              @samples[n].sample_group_name << "_"
            end
          end

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
            # if this element depends upon another one, and that element
            # is unselected, then nothing should be recorded for this one
            unselected_dependent = false

            if(element.dependent_element_id != nil &&
               element.dependent_element_id > 0)
              depends_on = NamingElement.find(element.dependent_element_id)
              unselected_dependent = schemed_name[depends_on.name] == "-1"
            end
            if( schemed_name[element.name].to_i > 0 &&
                unselected_dependent == false )
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
      end

      # shorten up sample and group names if needed
      if( @samples[n].sample_name.length > 59 )
        @samples[n].sample_name = @samples[n].sample_name[0..58]
      end
      if( @samples[0].sample_group_name.length > 59 )
        @samples[n].sample_group_name = @samples[n].sample_group_name[0..58]
      end
      
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
      for n in 0..@samples.size-1
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
      
      # notification of new samples
      Notifier.deliver_sample_submission_notification(@samples)
      
      flash[:notice] = "Samples created successfully"
      render :action => 'show'
    end
  end
  
  def edit
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
      
      # set sample_specific visibilities
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
      
      # put Sample in an array
      @samples = [@sample]
    end
    
    populate_arrays_for_edit(@sample)
  end

  def update
    @samples = [ Sample.find(params[:id]) ]

    # see if a naming scheme was used
    schemed_name = params[:sample]["0"][:schemed_name]
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
        if(element.include_in_sample_name && @samples[0].sample_name.length > 0)
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
          if(element.include_in_sample_name)
            @samples[0].sample_name << schemed_name[element.name].to_s

            # add to group name if this is a group element
            if(element.group_element == true)
              @samples[0].sample_group_name << schemed_name[element.name]
            end
          end
        else
          if( schemed_name[element.name].to_i > 0 )
            naming_term = NamingTerm.find(schemed_name[element.name])
            #naming_element = naming_term.naming_element
            sample_term = SampleTerm.new( :term_order => element.element_order,
                                          :naming_term_id => naming_term.id )
            sample_terms[0] << sample_term
            
            if(element.include_in_sample_name)
              @samples[0].sample_name << naming_term.abbreviated_term

              # add to group name if this is a group element
              if(element.group_element == true)
                @samples[0].sample_group_name << naming_term.abbreviated_term
              end
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
      if @samples[0].update_attributes(params[:sample]["0"])
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
      params[:id] = @samples[0].id
      edit
      render :action => 'edit'
    end
  end

  def destroy
    sample = Sample.find(params[:id])

    if(current_user.staff_or_admin? || sample.status == "submitted")
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
  
private

  def populate_arrays_from_tables
    @lab_groups = current_user.accessible_lab_groups

    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
    
    @naming_schemes = NamingScheme.find(:all)
  end

  def populate_arrays_for_edit(selected_sample)
    lab_group_ids = current_user.get_lab_group_ids    
  end
  
  def populate_sample_naming_scheme_choices(scheme)
    # only if the user has a specified scheme, find out what elements we need
    if( scheme != nil )
      @naming_elements = NamingElement.find(:all, :conditions => ["naming_scheme_id = ?", scheme.id],
                                            :order => "element_order ASC" )
    end
  end
end
