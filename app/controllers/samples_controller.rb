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

    @browse_categories = SampleMixture.browsing_categories

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
  
end
