=begin rapidoc
name:: /samples

This resource can be used to list a summary of all samples, or show details for 
a particular sample.<br><br>
A sample can be be run on any number of different flow cells (and therefore 
flow cell lanes), and/or multiple lanes on a particular flow cell. It is also 
conceivable that multiple samples could be run in one flow cell lane, however 
SLIMseq does not yet support this ability.
=end

class SamplesController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections
  before_filter :staff_or_admin_required, :only => [:bulk_destroy]
  
=begin rapidoc
url:: /samples
method:: GET
example:: <%= SiteConfig.site_url %>/samples
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Sample.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= Sample.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of all summary information on all samples

Get a list of all samples, which doesn't have all the details that are 
available when retrieving single samples (see GET /samples/[sample id]).
=end
  
  def index
    if(@lab_groups != nil && @lab_groups.size > 0)
      @samples = Sample.find(:all, 
         :include => 'project',
         :conditions => [ "projects.lab_group_id IN (?) AND control = ?",
          current_user.get_lab_group_ids, false ],
         :order => "submission_date DESC, samples.id ASC")
      @paged_samples = #Sample.paginate :page => params[:page],
        Sample.find(:all,
        :include => [:project,{:flow_cell_lanes => :pipeline_results}],
        :order => 'submission_date DESC, samples.id ASC',
        :conditions => [ "projects.lab_group_id IN (?) AND control = ?",
          current_user.get_lab_group_ids, false ] )
      @users_by_id = User.all_by_id
    end
    
    respond_to do |format|
      format.html  #index.html
      format.xml   { render :xml => @samples.
        collect{|x| x.summary_hash}
      }
      format.json  { render :json => @samples.
        collect{|x| x.summary_hash}.to_json 
      }
    end
  end

=begin rapidoc
url:: /samples/[sample id]
method:: GET
example:: <%= SiteConfig.site_url %>/samples/100.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Sample.find(:first).detail_hash) %>
xml:: <%= Sample.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular sample

Get detailed information about a single sample.
=end
  
  def show
    @sample = Sample.find(
      params[:id],
      :include => {
        :sample_terms => {
          :naming_term => :naming_element
        }
      }
    )

    respond_to do |format|
      format.xml   { render :xml => @sample.detail_hash }
      format.json  { render :json => @sample.detail_hash.to_json }
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
        format.html { redirect_to(samples_url) }
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

    if(sample.status == "submitted")
      sample.destroy
    else
      flash[:warning] = "Unable to destroy samples that have already been clustered or sequenced."
    end
    
    redirect_to :back
  end
  
  def bulk_destroy
    selected_samples = params[:selected_samples]
    
    for sample_id in selected_samples.keys
      if selected_samples[sample_id] == '1'
        sample = Sample.find(sample_id)
        sample.destroy
      end
    end
    
    redirect_to(samples_url)
  end
  
private

  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
    @users = current_user.accessible_users
    @projects = current_user.accessible_projects
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @sample_prep_kits = SamplePrepKit.find(:all, :order => "name ASC")
    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
  end
end
