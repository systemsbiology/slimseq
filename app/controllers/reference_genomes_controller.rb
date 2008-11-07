class ReferenceGenomesController < ApplicationController
  before_filter :login_required
  before_filter :populate_organism_dropdown,
    :only => [:new, :create, :edit, :update]

  # GET /reference_genomes
  # GET /reference_genomes.xml
  def index
    @reference_genomes = ReferenceGenome.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @reference_genomes }
      format.json { render :json => @reference_genomes.to_json(
          :only => :name,
          :include => { :organism => {:only => :name} } ) 
      }
    end
  end

  # GET /reference_genomes/1
  # GET /reference_genomes/1.xml
  def show
    @reference_genome = ReferenceGenome.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @reference_genome }
      format.json  { render :json => @reference_genome }
    end
  end
  
  # GET /reference_genomes/new
  # GET /reference_genomes/new.xml
  def new
    @reference_genome = ReferenceGenome.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @reference_genome }
      format.json  { render :json => @reference_genome }
    end
  end

  # GET /reference_genomes/1/edit
  def edit
    @reference_genome = ReferenceGenome.find(params[:id])
  end

  # POST /reference_genomes
  # POST /reference_genomes.xml
  def create
    @reference_genome = ReferenceGenome.new(params[:reference_genome])

    respond_to do |format|
      if @reference_genome.save
        flash[:notice] = 'ReferenceGenome was successfully created.'
        format.html { redirect_to(reference_genomes_url) }
        format.xml  { render :xml => @reference_genome, :status => :created, :location => @reference_genome }
        format.json  { render :json => @reference_genome, :status => :created, :location => @reference_genome }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @reference_genome.errors, :status => :unprocessable_entity }
        format.json  { render :json => @reference_genome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /reference_genomes/1
  # PUT /reference_genomes/1.xml
  def update
    @reference_genome = ReferenceGenome.find(params[:id])

    respond_to do |format|
      if @reference_genome.update_attributes(params[:reference_genome])
        flash[:notice] = 'ReferenceGenome was successfully updated.'
        format.html { redirect_to(reference_genomes_url) }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @reference_genome.errors, :status => :unprocessable_entity }
        format.json  { render :json => @reference_genome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reference_genomes/1
  # DELETE /reference_genomes/1.xml
  def destroy
    @reference_genome = ReferenceGenome.find(params[:id])
    @reference_genome.destroy

    respond_to do |format|
      format.html { redirect_to(reference_genomes_url) }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end
end

private

def populate_organism_dropdown
  @organisms = Organism.find(:all, :order => "name ASC")
end