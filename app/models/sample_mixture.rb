class SampleMixture < ActiveRecord::Base
  has_many :samples, :dependent => :destroy, :validate => false
  has_many :flow_cell_lanes
  has_many :rnaseq_pipelines, :dependent => :destroy, :validate => false

  belongs_to :user, :foreign_key => "submitted_by_id"
  belongs_to :project
  belongs_to :eland_parameter_set
  belongs_to :sample_set
  belongs_to :sample_prep_kit

  validates_presence_of :name_on_tube, :submission_date, :budget_number,
    :desired_read_length, :project_id, :sample_prep_kit_id
  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1

  acts_as_state_machine :initial => :submitted, :column => 'status'
  
  state :submitted, :after => :status_notification
  state :clustered, :after => :status_notification
  state :sequenced, :after => :status_notification
  state :completed, :after => :status_notification

  event :cluster do
    transitions :from => :submitted, :to => :clustered
  end

  event :uncluster do
    transitions :from => :clustered, :to => :submitted
  end
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered
  end
  
  event :complete do
    transitions :from => :sequenced, :to => :completed
  end
  
  def validate
    # make sure date/name_on_tube combo is unique
    s = SampleMixture.find(:first,
      :conditions => {:name_on_tube => name_on_tube,
        :submission_date => submission_date}
    )
    if( s != nil && s.id != id )
      errors.add("Duplicate submission date/name on tube")
    end
  end
  
  def save(perform_validation = true)
    unless sample_description
      if samples.size > 1
        self.sample_description = "#{samples.size} multiplexed samples"
      else
        self.sample_description = samples.first && samples.first.sample_description
      end
    end

    super
  end

  # needed this to get fields_for to work in the view
  def samples_attributes=(attributes)
    attributes.keys.collect{|k| k.to_i}.sort.each do |index|
      self.samples[index].update_attributes(attributes[index.to_s])
    end
  end

  def submitted_by=(login)
    self.user = User.find_by_login(login)
  end

  def status_notification
    samples.each do |sample|
      ExternalService.sample_status_change(sample)
    end
  end

  def short_and_long_name
    "#{name_on_tube} (#{sample_description})"
  end

  def short_and_long_name_with_cycles
    "#{name_on_tube} (#{sample_description}) - #{desired_read_length} cycles"
  end
  
  def eland_seed_length
    if(eland_parameter_set)
      max_length = eland_parameter_set.eland_seed_length
    else
      gerald_defaults = GeraldDefaults.first
      max_length = gerald_defaults.eland_seed_length
    end

    if desired_read_length > max_length
      return max_length
    else
      return desired_read_length - 1
    end
  end

  def eland_max_matches
    if(eland_parameter_set)
      return eland_parameter_set.eland_max_matches
    else
      gerald_defaults = GeraldDefaults.find(:first)
      return gerald_defaults.eland_max_matches
    end
  end

  def self.accessible_to_user(user)
    sample_mixtures = SampleMixture.find(:all, 
      :include => :project,
      :conditions => [ "projects.lab_group_id IN (?) AND control = ?",
        user.get_lab_group_ids, false ],
      :order => "submission_date DESC, sample_mixtures.id ASC")
  end

  def associated_comments
    result = ""

    result = add_comment(result, comment, "sample_mixture")

    flow_cells = Array.new
    sequencing_runs = Array.new
    flow_cell_lanes.each do |l|
      result = add_comment(result, l.comment, "lane")
      flow_cells << l.flow_cell
      l.flow_cell.sequencing_runs.each do |s|
        sequencing_runs << s
      end
    end

    flow_cells.uniq.each do |f|
      result = add_comment(result, f.comment, "flow cell")
    end

    sequencing_runs.uniq.each do |s|
      result = add_comment(result, s.comment, "sequencing")
    end

    if(result.length > 0)
      return result
    else
      return "No comments"
    end
  end

  def self.find_by_sanitized_conditions(conditions)
    accepted_keys = {
      'project_id' => 'sample_mixtures.project_id',
      'submitted_by_id' => 'sample_mixtures.submitted_by_id',
      'submission_date' => 'sample_mixtures.submission_date',
      'insert_size' => 'samples.insert_size',
      'reference_genome_id' => 'samples.reference_genome_id',
      'organism_id' => 'reference_genomes.organism_id',
      'status' => 'sample_mixtures.status',
      'naming_scheme_id' => 'naming_scheme_id',
      'flow_cell_id' => 'flow_cell_lanes.flow_cell_id',
      'naming_term_id' => 'sample_terms.naming_term_id',
      'lab_group_id' => 'projects.lab_group_id',
      'sample_prep_kit_id' => 'sample_mixtures.sample_prep_kit_id'
    }

    sanitized_conditions = Array.new

    conditions.each do |key, value|
      if accepted_keys.include?(key)
        value.to_s.split(/,/).each do |subvalue|
          sanitized_conditions << {accepted_keys[key] => subvalue}
        end
      end
    end

    samples = Array.new

    sanitized_conditions.each do |condition|
      search_samples = Sample.find(
        :all,
        :include => [:sample_terms, :reference_genome, {
          :sample_mixture => [:project, :flow_cell_lanes]}
        ],
        :conditions => condition
      )

      if(samples.size > 0)
        samples = samples & search_samples
      else
        samples = search_samples
      end
    end

    # return the sample mixtures
    return samples.collect{|s| s.sample_mixture}
  end

  def self.browsing_categories
    categories = [
      ['Flow Cell', 'flow_cell'],
      ['Insert Size', 'insert_size'],
      ['Lab Group', 'lab_group'],
      ['Naming Scheme', 'naming_scheme'],
      ['Organism', 'organism'],
      ['Project', 'project'],
      ['Reference Genome', 'reference_genome'],
      ['Sample Prep Kit', 'sample_prep_kit'],
      ['Status', 'status'],
      ['Submission Date', 'submission_date'],
      ['Submitter', 'submitter'],
    ]

    NamingScheme.find(:all, :order => "name ASC").each do |scheme|
      scheme.naming_elements.find(:all, :order => "element_order ASC").each do |element|
        categories << ["#{scheme.name}: #{element.name}", "naming_element-#{element.id}"]
      end
    end

    return categories
  end

  def lane_paths=(lane_paths)
    lane_paths.each do |lane_id, path_hash|
      lane = FlowCellLane.find(lane_id)
      lane.raw_data_path = path_hash['raw_data_path']
    end
  end


########################################################################
# phonybone_additions:

  def rna_seq_ref_genome
    org_name=samples[0].reference_genome.organism.name
    conditions={:org=>org_name}

    real_readlen=real_read_length
    if real_readlen <= 75
      conditions[:read_length]=real_readlen
      conditions[:align]='bowtie'
    else
      conditions[:align]='blat'
    end
    
#    raise "conditions: #{conditions.inspect}"

    # first search:
    genomes=RnaSeqRefGenome.find(:all, :conditions=>conditions)
#    if genomes.length == 0
    if false
      # skip this until blat support is implemented:
      # second search, with relaxed conditions:
      conditions.delete :read_length
      conditions[:align]='blat'
      genomes=RnaSeqRefGenome.find(:all, :conditions=>conditions)
    end

    # report results if no perfect fit:
    if genomes.length == 0
      raise "no appropriate RNA-Seq ref. genomes."
#      raise "no appropriate RNA-Seq ref. genomes found for org=#{org_name} and read size=#{real_readlen}; please contact RNA-Seq admin for further help."
    elsif genomes.length > 1
      raise "multiple genomes found for org=#{org_name} and read size=#{real_readlen}??? (internal error)"
    else
      genome=genomes[0]
    end

    # have to expand genome file glob (BLAT case, but works for bowtie, too):
    genome
  end


  def real_read_length
    fcls=flow_cell_lanes()
    return nil if fcls.size==0
    export_file=fcls[0].eland_output_file
    return nil if export_file.nil?
    len=0
    begin
      File.open export_file do |f|
        l=f.gets
        read=l.split()[8]
        len=read.length
      end
    rescue Exception => e
      logger.warn "Sample#real_read_length (id=#{id}): error reading export_file: #{e.message}"
      len=0                     # I guess...
    end
    len
  end

  def rnaseq_aligner
    real_read_length >= 50? 'blat' : 'bowtie'
  end

  def n_jobs
    flow_cell_lanes.size
  end
  #-----------------------------------------------------------------------
  # check to see if all samples in a list 
  # throws an exception if they're not, so wrap call in a begin/rescue block.
  # exception.message contains reasons for why not compatible

  def self.rnaseq_compatible?(sample_mixtures)
    raise "sample_mixtures: #{sample_mixtures.class}: not an Array" unless sample_mixtures.class.to_s=='Array'

    readlen=sample_mixtures[0].real_read_length
    ref_genome_name=sample_mixtures[0].rna_seq_ref_genome.name
    @msgs=Array.new

    sample_mixtures.each do |sample_mixture|
      msg="Sample #{sample_mixture.name_on_tube}: "
      if sample_mixture.status != 'completed'
        msg+="not completed"
        @msgs<<msg
        next
      end
      if sample_mixture.sample_prep_kit.name != 'mRNASeq'
        msg+="not an RNA-Seq sample (as determined by prep kit: #{sample_mixture.sample_prep_kit.name})"
        @msgs<<msg
        next
      end
      if sample_mixture.real_read_length != readlen
        msg+="different read length: #{readlen.to_s} vs. #{sample_mixture.real_read_length.to_s}"
        @msgs<<msg
        next
      end
      if sample_mixture.rna_seq_ref_genome.name != ref_genome_name
        msg+="different reference genome: #{sample_mixture.rna_seq_ref_genome.name} vs. #{ref_genome_name}"
        @msgs<<msg
        next
      end
    end
    
    raise @msgs.join("<br />\n") if @msgs.length>0

  end

########################################################################

private

  def add_comment(base, comment, type)
    if(comment && comment.length > 0)
      base += ", " if base.length > 0
      base += "#{type}: #{comment}" 
    end

    return base
  end
end

