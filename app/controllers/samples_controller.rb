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
  before_filter :load_dropdown_selections, :only => :edit
  
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
    @lab_groups = current_user.accessible_lab_groups

    @samples = Sample.accessible_to_user(current_user)

    @browse_categories = Sample.browsing_categories

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
        format.html {
          load_dropdown_selections
          render :action => "edit"
        }
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
  
  def bulk_handler
    selected_samples = params[:selected_samples]
    
    @samples = Array.new
    for sample_id in selected_samples.keys
      if selected_samples[sample_id] == '1'
        @samples << Sample.find(sample_id)
      end
    end

    if(params[:commit] == "Delete Selected Samples")
      if(current_user.staff_or_admin?)
        flash[:notice] = ""
        flash[:warning] = ""
        @samples.each do |s|
          if(s.submitted?)
            s.destroy
            flash[:notice] += "Sample #{s.name_on_tube} was destroyed<br>"
          else
            flash[:warning] += 
              "Sample #{s.name_on_tube} has already been clustered, and can't be destroyed<br>"
          end
        end
      else
        flash[:warning] = "Only facility staff can delete multiple samples at a time"
      end

      redirect_to(samples_url)
    elsif(params[:commit] == "Show Details")
      render :action => "details"
    end
  end
  
  def browse
    @samples = Sample.accessible_to_user(current_user)
    categories = sorted_categories(params)

    @tree = Sample.browse_by(@samples, categories)

    respond_to do |format|
      format.html  #browse.html
    end
  end

########################################################################
  
  def browseh
#    (project_id,study_id,experiment_id)=params.values_at(:project_id,:study_id,:experiment_id)

    # ok, what do we actually want to do here?
    # If only :project_id given, list all projects with chosen project
    # expanded to show studies.  If :project_id and :study_id given,
    # show same but with chosen study expanded (to show samples).
    # If all three given, show the sample as if /samples/display/id
    # had been called

    # HA! Turned out to be way simpler.

    @projects=Project.accessible_to_user(current_user)

  end

########################################################################

  def search
    accessible_samples = Sample.accessible_to_user(current_user)
    search_samples = Sample.find_by_sanitized_conditions(params)

    @samples = accessible_samples & search_samples

    respond_to do |format|
      format.html { render :action => "list" }
    end
  end

  def all
    @samples = Sample.accessible_to_user(current_user)

    respond_to do |format|
      format.html { render :action => "list" }
    end
  end

private

  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
    @users = current_user.accessible_users
    @projects = Project.accessible_to_user(current_user)
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @sample_prep_kits = SamplePrepKit.find(:all, :order => "name ASC")
    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
    @eland_parameter_sets = ElandParameterSet.find(:all, :order => "name ASC")
  end

  def sorted_categories(params)
    categories = Array.new

    params.keys.sort.each do |key|
      categories << params[key] if key.match(/category_\d+/)
    end

    return categories
  end
end
