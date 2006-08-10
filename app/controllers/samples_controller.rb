class SamplesController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    populate_arrays_from_tables

    if(@lab_groups != nil && @lab_groups.size > 0)
      # make an array of the accessible lab group ids, and use this
      # to find the current user's accessible samples in a nice sorted list
      lab_group_ids = Array.new
      for lab_group in @lab_groups
        lab_group_ids << lab_group.id
      end
      @samples = Sample.find(:all, :conditions => [ "lab_group_id IN (?)", lab_group_ids ],
                                :order => "submission_date DESC, sample_name ASC")
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

    # only add more sample slots if that's what was asked
    if(@add_samples.valid?) 
      for sample_number in previous_samples+1..previous_samples+@add_samples.number
        @samples << Sample.new(:submission_date => @add_samples.submission_date,      
              :lab_group_id => @add_samples.lab_group_id,
              :chip_type_id => @add_samples.chip_type_id,
              :sbeams_user => @add_samples.sbeams_user,                                              
              :sbeams_project => @add_samples.sbeams_project,
              :organism_id => ChipType.find( @add_samples.chip_type_id).organism_id,
              :status => 'submitted')
      end
      session[:sample_number] = previous_samples + @add_samples.number 
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
    Sample.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  private
  def populate_arrays_from_tables
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
    
    # Administrators can see all lab groups, otherwise users
    # are restricted to seeing only lab groups they belong to
    if(current_user.admin?)
      @lab_groups = LabGroup.find(:all, :order => "name ASC")
    else
      @lab_groups = current_user.lab_groups
    end
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")
  end

end
