class SamplesController < ApplicationController
  before_filter :load_dropdown_selections, :login_required
  
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
  
  def edit
    @sample = Sample.find(params[:id])
     
    @naming_scheme = @sample.naming_scheme
    if(@naming_scheme != nil)
      @naming_elements = @naming_scheme.ordered_naming_elements
    end
    
    # put Sample in an array
    @samples = [@sample]
  end

  def update
    @sample = Sample.find(params[:id])

    respond_to do |format|
      if @sample.update_attributes(params[:sample]["0"])
        flash[:notice] = 'Sample was successfully updated.'
        format.html { redirect_to(:action => 'list') }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sample.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sample.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    sample = Sample.find(params[:id])

    if(current_user.staff_or_admin? || sample.status == "submitted")
      sample.destroy
      redirect_to :back
    else
      flash[:warning] = "Unable to destroy samples that have already been clustered or sequenced."
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

  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
    @projects = current_user.accessible_projects
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @sample_prep_kits = SamplePrepKit.find(:all, :order => "name ASC")
    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
  end
end
