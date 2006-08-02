class HybridizationsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    populate_arrays_from_tables
    @hybridizations = Hybridization.find(:all, :order => "date DESC, chip_number ASC")
  end

  def new
    populate_arrays_from_tables
    # clear out hybridization record since this is a 'new' set
    session[:hybridizations] = Array.new
    session[:hybridization_number] = 0
  end

  def add
    populate_arrays_from_tables
    
    @hybridizations = session[:hybridizations]
    previous_hybs = session[:hybridization_number]
    @add_hybs = AddHybs.new(params[:add_hybs])

    # only add more hyb slots if that's what was asked
    if(@add_hybs.valid?) 
      for hyb_number in previous_hybs+1..previous_hybs+@add_hybs.number
        @hybridizations << Hybridization.new(:date => @add_hybs.date,      
              :chip_number => hyb_number,
              :charge_template_id => @add_hybs.charge_template_id,
              :lab_group_id => @add_hybs.lab_group_id,
              :chip_type_id => @add_hybs.chip_type_id,
              :organism_id => ChipType.find(@add_hybs.chip_type_id).organism_id,
              :array_platform => @add_hybs.array_platform,
              :sbeams_user => @add_hybs.sbeams_user,                                              
              :sbeams_project => @add_hybs.sbeams_project)
      end
      session[:hybridization_number] = previous_hybs + @add_hybs.number 
    end
  end
  
  def create
    populate_arrays_from_tables  
    @hybridizations = session[:hybridizations]
    hyb_number = session[:hybridization_number]

    failed = false 
    for n in 0..hyb_number-1
      form_entries = params['hybridization-'+n.to_s]
      # add the user info from the forms
      @hybridizations[n].short_sample_name = form_entries['short_sample_name']
      @hybridizations[n].sample_name = form_entries['sample_name']
      @hybridizations[n].sample_group_name = form_entries['sample_group_name']
      @hybridizations[n].organism_id = form_entries['organism_id']
      
      # if any one hybridization record isn't valid,
      # we don't want to save any
      if !@hybridizations[n].valid?
        failed = true
      end
    end
    if failed
      @add_hybs = AddHybs.new(:number => 0)
      render :action => 'add'
    else
      # save now that all hybridizations have been tested as valid
      for n in 0..hyb_number-1
        @hybridizations[n].save
      end
      flash[:notice] = "Hybridization records"
      if SiteConfig.track_inventory?
        # add chip transactions for these hybridizations
        record_as_chip_transactions(@hybridizations)
        flash[:notice] += ", inventory changes"
      end
      if SiteConfig.create_gcos_files?
        begin    
          # output files for automated sample/experiment loading into GCOS
          create_gcos_import_files(@hybridizations)
          flash[:notice] += ", GCOS files"
        rescue Errno::EACCES, Errno::ENOENT
          flash[:warning] = "Couldn't write GCOS file(s) to " + SiteConfig.gcos_output_path + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end      
      end
      if SiteConfig.track_charges?
        # record charges incurred from these hybridizations
        record_charges(@hybridizations)
        flash[:notice] += ", charges"
      end
      if(flash[:notice] != nil)
        flash[:notice] += ' created successfully.'
      end
      redirect_to :action => 'show'
    end
  end
  
  def show
    if session[:hybridizations] == nil
      @hybridizations = Array.new
    else
      @hybridizations = session[:hybridizations]
    end
  end

  def clear
    session[:hybridizations] = Array.new
    session[:hybridization_number] = 0
    redirect_to :action => 'new'
  end

  def edit
    populate_arrays_from_tables
    @hybridization = Hybridization.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    hybridization = Hybridization.find(params[:id])

    begin
      if hybridization.update_attributes(params[:hybridization])
        flash[:notice] = 'Hybridization was successfully updated.'
        redirect_to :action => 'list'
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this hybridization."
      @hybridization = Hybridization.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    Hybridization.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  private
  def populate_arrays_from_tables
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")
    
    # only show templates where a chip is hybridized, so chips_used > 0
    @charge_templates = ChargeTemplate.find(:all, :order => "name ASC",
                        :conditions => ["chips_used > ?", 0])
  end
  
  def record_as_chip_transactions(hybridizations)
    hybs_per_group_chip = Hash.new(0)
    
    for hybridization in hybridizations
      date_group_chip_key = hybridization.date.to_s+"_"+hybridization.lab_group_id.to_s+"_"+hybridization.chip_type_id.to_s
      # if this date/lab group/chip type combo hasn't been seen, create a new object to track
      # number of chips of this combo
      if hybs_per_group_chip[date_group_chip_key] == 0
        hybs_per_group_chip[date_group_chip_key] = ChipTransaction.new(:lab_group_id => hybridization.lab_group_id,
                              :chip_type_id => hybridization.chip_type_id,
                              :date => hybridization.date,
                              :description => 'Hybridized on ' + hybridization.date.to_s,
                              :used => 1)                  
      else
        hybs_per_group_chip[date_group_chip_key][:used] += 1
      end
    end

    for date_group_chip_key in hybs_per_group_chip.keys
      hybs_per_group_chip[date_group_chip_key].save
    end
  end
  
  def create_gcos_import_files(hybridizations)
    for hybridization in hybridizations
      # only make hyb info record for GCOS if it's an affy array
      if hybridization.array_platform == "affy"
        date_number_string = hybridization.date.year.to_s + ("%02d" % hybridization.date.month) +
                             ("%02d" % hybridization.date.day) + "_" + ("%02d" % hybridization.chip_number)
        # open an output file for writing
        gcos_file = File.new(SiteConfig.gcos_output_path + "/" + date_number_string + 
                    "_" + hybridization.sample_name + ".txt", "w")
        # write out information needed by GCOS Object Importer tool
        gcos_file << "[SAMPLE]\n"
        gcos_file << "SampleName=" + hybridization.sample_group_name + "\n"
        gcos_file << "SampleType=" + Organism.find(hybridization.organism_id).name + "\n"
        gcos_file << "SampleProject=" + hybridization.sbeams_project + "\n"
        gcos_file << "SampleUser=affybot\n"
        gcos_file << "SampleUpdate=1\n"
        gcos_file << "SampleTemplate=AffyCore\n"
        gcos_file << "Array User Name=" + hybridization.sbeams_user + "\n"
        gcos_file << "\n"
        gcos_file << "[EXPERIMENT]\n"
        gcos_file << "ExperimentName=" + date_number_string + "_" + hybridization.sample_name + "\n"
        gcos_file << "ArrayType=" + ChipType.find(hybridization.chip_type_id).short_name + "\n"
        gcos_file << "ExperimentUser=affybot\n"
        gcos_file << "ExperimentUpdate=0\n"
        gcos_file.close
      end
    end
  end
  
  def record_charges(hybridizations)
    # find the latest charge period
    current_period = ChargePeriod.find(:first, :order => "name DESC")
    
    # if a charge period doesn't exist, create one
    if(current_period == nil)
      current_period = ChargePeriod.new(:name => 'Default Charge Period')
    end
    
    for hybridization in hybridizations
      # try to find an existing charge set
      charge_set = ChargeSet.find(:first, 
        :conditions => ["charge_period_id = ? AND lab_group_id = ?", current_period.id, hybridization.lab_group_id] )
      
      # if no existing charge set is found, create one
      if(charge_set == nil)
        lab_group = LabGroup.find(hybridization.lab_group_id)
        charge_set = ChargeSet.new(:lab_group_id => lab_group.id,
                                   :charge_period_id => current_period.id,
                                   :name => lab_group.name,
                                   :budget_manager => "To Be Entered",
                                   :budget => "To Be Entered")
        charge_set.save
      end
      
      template = ChargeTemplate.find(hybridization.charge_template_id)
      charge = Charge.new(:charge_set_id => charge_set.id,
                          :date => hybridization.date,
                          :description => hybridization.sample_name,
                          :chips_used => template.chips_used,
                          :chip_cost => template.chip_cost,
                          :labeling_cost => template.labeling_cost,
                          :hybridization_cost => template.hybridization_cost,
                          :qc_cost => template.qc_cost,
                          :other_cost => template.other_cost)
      charge.save
    end
  end
end
