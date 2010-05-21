class SampleMixturesController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections, :only => :edit

  def edit
    @sample_mixture = SampleMixture.find(params[:id])
  end

  def update
    @sample_mixture = SampleMixture.find(params[:id])

    respond_to do |format|
      if @sample_mixture.update_attributes(params[:sample_mixture])
        flash[:notice] = 'Sample was successfully updated.'
        format.html { redirect_to(sample_mixtures_url) }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html {
          load_dropdown_selections
          render :action => "edit"
        }
        format.xml  { render :xml => @sample_mixture.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sample_mixture.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    sample_mixture = SampleMixture.find(params[:id])

    if(sample_mixture.status == "submitted")
      sample_mixture.destroy
    else
      flash[:warning] = "Unable to destroy sample mixtures that have already been clustered or sequenced."
    end
    
    redirect_to :back
  end
  
  def bulk_handler
    selected_sample_mixtures = params[:selected_sample_mixtures]
    
    @sample_mixtures = Array.new
    for sample_mixture_id in selected_sample_mixtures.keys
      if selected_sample_mixtures[sample_mixture_id] == '1'
        @sample_mixtures << SampleMixture.find(sample_mixture_id)
      end
    end

    if(params[:commit] == "Delete Selected Samples")
      if(current_user.staff_or_admin?)
        flash[:notice] = ""
        flash[:warning] = ""
        @sample_mixtures.each do |s|
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

      redirect_to(sample_mixtures_url)
    elsif(params[:commit] == "Show Details")
      render :action => "details"

    elsif(params[:commit] == "RNA Seq Pipeline")
      if AppConfig.rnaseq_pipelines_enabled
        if @sample_mixtures.length==0
          render :action=>"details"
          return
        end
        begin
          @ref_genome_name=@sample_mixtures[0].rna_seq_ref_genome.name
          @email=current_user.email
          @aligner_params=RnaseqPipeline.config[:bowtie_opts]
          @msgs=Array.new
          SampleMixture.rnaseq_compatible?(@sample_mixtures)

        rescue RuntimeError => e
          @disable_launch=true
          @why_disabled="Incompatible samples:<br /> #{e.message}"
        end


        render :template => "rnaseq_pipelines/launch_prep" 
        # only drawback is repeated code, here and in rnaseq_pipelines_controller.  Would prefer to consolidate...
        # What does code do?  Finds samples (from sample_ids) (now sample_mixture_ids), checks compatibility
      else
        flash[:notice]+= "RNA-Seq pipelines not enabled"
      end

    else
      raise "unknown submit: params[:commit]=#{params[:commit]}"


    end
  end
  
  def browse
    samples = Sample.accessible_to_user(current_user)
    categories = sorted_categories(params)

    @tree = Sample.browse_by(samples, categories)

    respond_to do |format|
      format.html  #browse.html
    end
  end

  def search
    accessible_sample_mixtures = SampleMixture.accessible_to_user(current_user)
    search_sample_mixtures = SampleMixture.find_by_sanitized_conditions(params)

    @sample_mixtures = accessible_sample_mixtures & search_sample_mixtures

    respond_to do |format|
      format.html { render :action => "list" }
    end
  end

  def all
    @sample_mixtures = SampleMixture.accessible_to_user(current_user)

    respond_to do |format|
      format.html { render :action => "list" }
    end
  end

private

  def sorted_categories(params)
    categories = Array.new

    params.keys.sort.each do |key|
      categories << params[key] if key.match(/category_\d+/)
    end

    return categories
  end
  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
    @users = current_user.accessible_users
    @projects = Project.accessible_to_user(current_user)
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @sample_prep_kits = SamplePrepKit.find(:all, :order => "name ASC")
    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
    @eland_parameter_sets = ElandParameterSet.find(:all, :order => "name ASC")
  end
end
