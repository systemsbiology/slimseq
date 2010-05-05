class PostPipeline < ActiveRecord::Base
  require 'app_config'

  belongs_to :pipeline_result
  belongs_to :sample
  belongs_to :reference_genome
  belongs_to :flow_cell_lane
  has_one :rnaseq_stats

  cattr_accessor :dry_run, :erccs, :current_user, :export_filepath


  ########################################################################
  # get the pp's sample object; shouldn't this method have been created via the belongs_to declaration????
  def sample
    Sample.find(self.sample_id)
  end

  def label
    "sample_#{sample_id}_fcl_#{flow_cell_lane_id}"
  end

  def get_sample_params!(sample)
    ref_gen=sample.reference_genome
    self.sample_id=sample.id
    self.org_name=ref_gen.organism.name
    self
  end

  def get_pipeline_result_params!(flow_cell_lane)
    # get the most recent pipeline_result object for this fcl:
    pipeline_result=PipelineResult.find(:all, :conditions=>{:flow_cell_lane_id=>flow_cell_lane.id}, 
                                        :order=>'updated_at ASC',:limit=>1)[0]

    raise "no pipeline_result w/id=#{flow_cell_lane.id}" if pipeline_result.nil?

    self.flow_cell_lane_id=flow_cell_lane.id
    self.pipeline_result_id=pipeline_result.id
    
    self.working_dir=make_working_dir
    raise "export_file missing or unreadable" unless FileTest.readable? pipeline_result.eland_output_file
    self.export_filepath=pipeline_result.eland_output_file
    self.export_file=self.export_filepath.split('/')[-1]

    self
  end

  def make_working_dir
    wd=['post_pipeline',sample_id.to_s,flow_cell_lane_id.to_s].join('_') # eg 'post_pipeline_412_585'
    ts=Time.now.strftime  "%d%b%y.%H%M%S" # eg 21Apr10.032723
    File.join(File.dirname(pipeline_result.eland_output_file),wd,ts)
  end    

  def parse_stats(stats_file,gene_file)
    if !(FileTest.readable? stats_file and FileTest.readable? gene_file)
      logger.warn "missing stats file: #{stats_file}" unless FileTest.readable? stats_file
      logger.warn "missing gene file: #{gene_file}" unless FileTest.readable? gene_file
      return
    end

    stats=File.read(stats_file)
    record=RnaseqStats.new
    regs=[ [/(\d+) total reads/,:total_reads],
           [/(\d+) total aligned reads/, :total_aligned],
           [/multi: (\d+)/, :multi_aligned],
           [/unique: (\d+)/, :unique_aligned],
           [/spliced: (\d+)/, :spliced_aligned]
         ]

    regs.each do |pair|
      regex=pair[0]
      symbol=pair[1]
      res=stats.match(regex)
      match=res[1]
      record.send("#{symbol}=",match)
    end

    # count all found genes (including putative)
    n_genes=`wc -l #{gene_file}`.chomp
    n_genes=n_genes.match(/^\d+/)[0]
    record.send("n_genes=",n_genes)

    record[:post_pipeline_id]=self.id # necessary?
    record.save
    record
  end

  def stats
    # return record from database if it exists; parse from file
    # and store, then return it if it doesn't.
    stats_record=self.rnaseq_stats
    stats_record=parse_stats(stats_file,gene_file) if stats_record.nil?
    self.rnaseq_stats=stats_record
    stats_record
  end

  def stats_file
    "#{working_dir}/#{export_file}.stats"
  end
  def gene_file
    "#{working_dir}/rds/#{export_file}.final.rpkm"
  end

  def entry_file
    "#{working_dir}/#{label}.entry.sh"
  end
  def entry_file_output
    "#{working_dir}/#{label}.entry.out"
  end
  def qsub_file
    "#{working_dir}/#{label}.qsub.sh"
  end
  def launch_file
    "#{working_dir}/#{label}.launch.sh"
  end

  ########################################################################
  # launch a pipeline by writing a qsub file and invoking it.
  # caller (post_pipeline_controller:launch) responsible for making sure
  # no other jobs for this sample/fcl are already running.

  def launch
    unless (FileTest.directory?(working_dir))
      FileUtils.mkdir_p(working_dir) 
      FileUtils.chmod 0777, working_dir # like chmod g+s
    end

    # write one qsub file for each flow_cell_lane/pipeline_result of the sample:
    # (collect invokes &writer once for each element in the list; synonym for 'map')
    raise "no flow control lanes associated with sample #{sample_id}???" if sample.flow_cell_lanes.length==0
    qsub_files=self.sample.flow_cell_lanes.map{|fcl| write_qsub_scripts(fcl)} 

    # clear output/err files if they exist:
    begin
      output_file="#{working_dir}/#{label}.out"
      FileUtils.remove(output_file, {:force=>true})
    end
    begin
      error_file="#{working_dir}/#{label}.err"
      FileUtils.remove(error_file, {:force=>true})
    end

    # call qsub one each of the qsub files:
    qsub_files.each do |entry_file| 
      cmd="/bin/sh #{entry_file}"
      
      success=system(cmd)
      raise "#{sample.name_on_tube}: failed to launch via qsub (#{cmd}, #{$?})" unless success

     end
  end

  # return job_id of a job is already running for this sample/flowcell
  # or 0 if no job found
  def already_running
    FileTest.exists? "#{working_dir}/lock.file"
  end


# scrap: we're running as user solxabot, so the 'sudo' bit is unnecessary
#      cmd="sudo -u solxabot /sge/bin/lx24-amd64/qsub #{qfile}"
# another one:


  ########################################################################
  # Write all scripts needed for job: controlling 'submit' script and
  # actual job script (ruby).  We need all these scripts to make sure
  # qsub actually works (grrrr).
  def write_qsub_scripts(flow_cell_lane)
    
    FileUtils.mkdir_p "#{working_dir}/rds" unless FileTest.directory? "#{working_dir}/rds"
    FileUtils.chmod 0777, "#{working_dir}/rds"
    FileUtils.ln_s "#{export_filepath}",working_dir unless FileTest.exists? "#{working_dir}/#{export_file}"

    write_entry_script
    write_launch_script
    write_qsub_script(flow_cell_lane)
    return entry_file()
  end

  ########################################################################
  # Write the script that qsub will invoke:
  def write_entry_script
    launch_qsub=launch_file()

    template_file=File.join(AppConfig.script_dir,AppConfig.entry_template)
    template=File.slurp template_file
    script=eval template
    File.spit(entry_file(),script)
  end

  def write_launch_script
    qsub=AppConfig.qsub
    qsub_file=qsub_file()
    
    template_file=File.join(AppConfig.script_dir,AppConfig.launch_template)
    template=File.slurp template_file
    script=eval template
    File.spit(launch_file(),script)
  end

  # Write the script that will launch the pipeline (invoked by the entry script)
  # see also make_launch_rnaseq_pipeline.rb
  def write_qsub_script(flow_cell_lane)
    pp_id=id
    ruby=AppConfig.ruby
    rnaseq_pipeline=File.join(AppConfig.script_dir,AppConfig.rnaseq_pipeline)
    readlen=sample.real_read_length # fixme: data in table is busted for some samples
    script_dir=AppConfig.script_dir
    rnaseq_dir=AppConfig.rnaseq_dir
    bin_dir=AppConfig.bin_dir
    dry_run_flag= dry_run.to_i<0 ? '-dry_run':'' # dry_run comes from form, so values are [0|1]
    email=current_user.email

    perl=AppConfig.perl
    gather_stats=File.join(AppConfig.script_dir,AppConfig.gather_stats)

    # ref_genome is only needed for bowtie, but include always anyway
    ref_genome=sample.rna_seq_ref_genome.name
    bowtie_opts=AppConfig.bowtie_opts
    
    template_file=File.join(AppConfig.script_dir,AppConfig.qsub_template)
    template=File.slurp template_file
    script=eval template
    File.spit(qsub_file(),script)
  end

end
