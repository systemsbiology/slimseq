#!/hpc/bin/ruby

# This is the main rnaseq_pipeline script.

require 'fileutils'
$:<<'/proj/hoodlab/share/vcassen/rna-seq/scripts/lib'
require 'options'
require 'app_config'

def parse_cmdline()
  all_opts=%w{working_dir=s export_file=s label=s pp_id=i org=s readlen=i max_mismatches=i dry_run erccs rnaseq_dir=s script_dir=s bin_dir=s}
  Options.use(all_opts)
  Options.required(%w{working_dir export_file label pp_id org readlen max_mismatches rnaseq_dir script_dir})
  Options.parse()
end



# config globals:
def config_globals
  $working_dir=Options.working_dir
  $export_file=Options.export_file

  rnaseq_dir=Options.rnaseq_dir
  $export_filepath="#{$working_dir}/#{Options.export_file}"
  $post_slimseq="#{script_dir}/post_to_slimseq.pl"
  $export2fasta="#{script_dir}/fq_all2std.pl"
  $bowtie_exe="#{rnaseq_dir}/bowtie/bowtie"
  $blat_exe='/package/genome/bin/blat'
  $erange_dir="#{rnaseq_dir}/ERANGE"
  $rds_dir="#{$working_dir}/rds"
  $erange_script="#{rnaseq_dir}/ERANGE/runStandardAnalysisNFS.sh"
  $makerds_script="#{rnaseq_dir}/ERANGE/makerdsfrombowtie.py"
  $stats_script="#{script_dir}/gather_stats.pl"
  $bowtie2count="#{script_dir}/bowtie2count.ercc.pl"
  $normalize_erccs="#{script_dir}/normalize_erccs.pl"
  $genomes_dir='/jdrf/data_var/solexa/genomes'
  $perl="#{Options.bin_dir}/perl"
  $python="#{Options.bin_dir}/python"
  $pslSort='/package/genome/bin/pslSort'
  $pslReps='/package/genome/bin/pslReps'

  config_file='/proj/hoodlab/share/vcassen/rna-seq/scripts/config/rnaseq.conf'
  AppConfig.load(config_file)
end

def main
  puts "hello"
  parse_cmdline()
  config_globals()
  post_status(Options.pp_id,'Starting')
  integrity_checks()
  mk_working_dir()
  export2fasta(fasta_format())
  alignment_outputalign(fasta_format())
  makerds(alignment_output,fasta_format())
  call_erange()
  stats()
  erccs()
  stats2()
  post_status(Options.pp_id,'Finished')
end


def integrity_checks
  messages=Array.new
  messages << "#{$export_filepath}: no such file or unreadable"  unless FileTest.readable? $export_filepath

  org=Options.org.downcase
  messages << "Unknown org '#{org}'" unless org=='mouse' or org=='human'

  # also need to test executable scripts, maybe write access to working_dir
  quit_flag=false
  exes=[$post_slimseq,
        $export2fasta,
        $bowtie_exe,
        $bowtie2count,
        $makerds_script,
        $erange_script,
        $stats_script,
        $bowtie2count,
        $pslSort,
        $pslReps,
        $normalize_erccs]
  exes.each do |exe|
    if (FileTest.executable?(exe))
        $stderr.puts "#{exe} found"
    else
        $stderr.puts "#{exe}: not found or not executable" 
        quit_flag=true
    end
  end

  exit if quit_flag
  $stderr.puts 'integrity checks passed'
end

def mk_working_dir()
  FileUtils.mkdir $working_dir unless FileTest.directory? $working_dir
  FileUtils.mkdir "#{$working_dir}/rds" unless FileTest.directory? "#{$working_dir}/rds"

  FileUtils.cd $working_dir
  puts <<"BANNER"
*****************************************************
writing output to:
#{$working_dir}
*****************************************************
   
BANNER
  
end

########################################################################
## translate export.txt file to fasta format

def export2fasta(fasta_format)
  translation_cmd="#{$perl} #{$export2fasta} solexa2fasta #{$working_dir}/#{export_file}"
  puts "translation cmd: #{translation_cmd} > #{$working_dir}/#{export_file}.#{fasta_format}"
  post_status(Options.pp_id,'extracting reads from ELAND file')

  # unlink converted export file if it exists (so that redirection, below, won't fail)
  if (FileTest.readable?("#{$working_dir}/#{export_file}.#{fasta_format}") and !Options.dry_run) then
    FileUtils.remove "#{$working_dir}/#{export_file}.#{fasta_format}"
  end

  launch("#{translation_cmd} > #{$working_dir}/#{export_file}.#{fasta_format}")
  puts "export2fasta: status is #{$?}"         # fixme
  exit $? if $?.to_i>0

# this writes #{$working_dir}/#{export_file}.#{fasta_format}
end

########################################################################
def align(fasta_format)
  if Options.readlen>=50
    return blat()
  else
    return bowtie(fasta_format)
  end
end

########################################################################
## bowtie-cmd.sh:
## Note: bowtie needs .ewbt files to work from; don"t exist yet for critters other than mouse

def bowtie(fasta_format)
  reads_file="#{$working_dir}/#{$export_file}.#{fasta_format}"	# export file converted to fasta format
  repeats="#{reads_file}.repeats.#{fasta_format}"
  unmapped="#{reads_file}.unmapped.#{fasta_format}"
  alignment_output="#{reads_file}.bowtie.out"
  alignment_cmd="#{$bowtie_exe} #{ref_genome} -n #{max_mismatches} #{bowtie_opts} #{reads_file} --un #{unmapped} --max #{repeats} #{alignment_output}"


  # reads_file is the input
  #export BOWTIE_INDEXES="#{$genomes_dir}/#{Options.org}"  
  ENV['BOWTIE_INDEXES']="#{$genomes_dir}/#{Options.org}"

  puts "alignment cmd: #{alignment_cmd}"
  post_status(Options.pp_id, 'aligning reads (bowtie)')
  launch alignment_cmd
  puts "bowtie: status is #{$?}"         # fixme
  exit $? if $?.to_i>0

  puts "#{alignment_output} written"
  puts ""
  alignment_output
end

#-----------------------------------------------------------------------

def blat()
  org=Options.org
  n_chrs={:human=>22, :mouse=>19}[org]
  raise "unkwown org '#{org}'" if n_chrs.nil?
  label=Options.label
  timepoints=[[Time.now,'start']]

  # crude flow control:
  run_fq_all2std=    false

  $run_blat_rna_all=  true
  $call_store_hits=  true
  $call_filter_hits= true
  run_pslReps=       false      # always false for now
  run_pslSort=       true

  # initialization:
  blat='/package/genome/bin/blat'
  genomes="#{$genomes_dir}/#{org}/fasta"
  readlen=Options.readlen
  maxMismatches=Options.max_mismatches
  minScore=readlen-maxMismatches
  blat_opts="-ooc=#{genomes}/11.ooc -out=pslx -minScore=#{minScore}"
  psl_ext='psl'
#  bin_dir='/tools/bin'
  bin_dir='/hpc/bin'
  db="#{$working_dir}/rds/#{$export_file}.rna"
  blat_output="#{$working_dir}/#{$export_file}.#{psl_ext}"
  reads_fasta="#{$working_dir}/#{$export_file}.fa" # has to be a .fa format, not .faq (I think)

  # build chr array; can't believe there's not a better way to convert a range to an array:
  chrs=Array.new
  (1..n_chrs).each {|i| chrs<<i}
  chrs<<'X'
  chrs<<'Y'

  # main processing starts here:
  if $run_blat_rna_all
    blat_result=blat_rna(working_dir,export_file,blat,reads_fasta,minScore) 
    timepoints<<[Time.now,'reads_fasta']
    table=store_hits(working_dir,export_file,blat_result,db,readlen) 
    timepoints<<[Time.now,'store_hits']
    reads_fasta=filter_hits(working_dir,reads_fasta,db,table) # overwrite name of reads file
    timepoints<<[Time.now,'filter_hits']
  end
  blat_chrs(reads_fasta,working_dir,export_file,psl_ext,blat,genomes,blat_opts,chrs,minScore,maxMismatches) 
  timepoints<<[Time.now,'blat_chrs']
  pslReps(working_dir,export_file) if run_pslReps
  timepoints<<[Time.now,'pslReps']
  blat_result=pslSort(working_dir,blat_output) if run_pslSort
  timepoints<<[Time.now,'pslSort']

  blat_result
end

#-----------------------------------------------------------------------
# run blat against the rna.fa file:
def blat_rna(working_dir,export_file,blat,reads_fasta,minScore)
  rna_genome="#{$genomes_dir}/#{Options.org}/fasta/rna.fa"
  rna_output="#{$working_dir}/#{$export_file}.rna.psl"
#  return rna_output if File.exists? rna_output and not $run_blat_rna_all # fixme: might need a separate global flag?
  rna_blat_opts="-out=pslx -minScore=#{minScore}"
  cmd="#{blat} #{rna_genome} #{reads_fasta} #{rna_blat_opts} #{rna_output}"
  puts "\n#{cmd}\n"
  ok=system cmd
  raise "\nblat_rna: #{cmd}: $? is #{$?}" unless ok

  filter_minScore(rna_output,minScore,maxMismatch)
  rna_output
end

#-----------------------------------------------------------------------
# run blat against all chrs using each .nib file:
def blat_chrs(reads_fasta,working_dir,export_file,psl_ext,blat,genomes,blat_opts,chrs,minScore,maxMismatch)
  chrs.each {|chr|
    blat_chr_output="#{$working_dir}/#{$export_file}.#{chr}.#{psl_ext}"
    cmd="#{blat} #{genomes}/chr#{chr}.nib #{reads_fasta} #{blat_opts} #{blat_chr_output}"
    puts "\n#{cmd}\n"

    ok=system cmd
    raise "\nblat: #{cmd}: $? is #{$?}" unless ok

    filter_minScore(blat_chr_output,minScore,maxMismatch)
  }
end


#-----------------------------------------------------------------------
# remove all hits below minScore (since I can't seem to get blat to do
# that for me :( 
def filter_minScore(blat_result, minScore, maxMismatch)
  tmp_filename="#{blat_result}.tmp"
  tmp_file=File.open(tmp_filename,"w")
  File.open(blat_result,"r").each do |l|
    stuff=l.split
    next if stuff[0].to_i<minScore
    next if stuff[1].to_i>maxMismatch
    tmp_file.puts l 
  end

  FileUtils.mv(tmp_filename,blat_result)
  
end

#-----------------------------------------------------------------------
# concat and sort blat results
# pslSort dirs[1|2] outFile tempDir inDir(s)
def pslSort(blat_output)


  FileUtils.rm blat_output if FileTest.exists? blat_output
  cmd="#{$pslSort} dirs #{blat_output} #{$working_dir}/tmp #{$working_dir}"
  puts "\n#{cmd}\n"
  ok=system cmd
  raise "#{cmd}: $? is #{$?}" unless ok
end

#-----------------------------------------------------------------------
# filter repeats
#$BLATPATH/pslReps -minNearTopSize=70 s3_1.hg18.blat s3_1.hg18.blatbetter s3_1.blatpsr
def run_pslReps()
  raise "pslReps nyi"
  pslOpts='-minNearTopSize=70'
  pslreps_output="#{$working_dir}/#{$export_file}.pslreps"

  cmd="#{$pslReps} #{pslOpts} #{pslreps_output}"
end

#check
########################################################################
## makeRdsFromBowtie-cmd.sh:

# due to an apparent bug in makerdsfrombowtie.py, we need to rm rds_output
# if it exists.  The bug (actually in commoncode.py) is that it uses the 
# sql "create table if not exists <tablename>", without dropping the table/db
# first.  The effect is that the tables get appended to, not re-written.

def makerds(alignment_output,fasta_format)
  gene_models="#{$genomes_dir}/#{Options.org}/knownGene.txt"
  rds_output="#{$rds_dir}/#{$export_file}.rds"
  rds_args="-forceRNA -RNA #{gene_models} -index -cache 1000 -rawreadID"
  makerds_cmd="#{$python} #{$makerds_script} #{label} #{alignment_output} #{rds_output} #{rds_args}"

  if (FileTest.readable? rds_output  and !Options.dry_run) then
    FileUtils.remove rds_output
  end

  post_status(Options.pp_id,'Creating RDS files from alignment')
  launch(makerds_cmd)
  puts "#{rds_output} written"
end

########################################################################
## runStandardAnalysisNFS-cmd.sh:

def call_erange
  puts " erange cmd: #{$erange_script}  #{Options.org} #{$rds_dir}/#{$export_file} #{$genomes_dir}/#{Options.org}/repeats_mask.db 5000"
  post_status(Options.pp_id,'running ELAND')
  launch("time sh #{$erange_script} #{Options.org} #{$rds_dir}/#{$export_file} #{$genomes_dir}/#{Options.org}/repeats_mask.db 5000")
  puts "call_erange: status is #{$?}"         # fixme
  exit $? if $?.to_i>0
end

########################################################################
# gather stats:

def stats
  stats_file="#{$working_dir}/#{$export_file}.stats"
  stats_cmd="#{$perl} #{$stats_script} -working_dir #{$working_dir} -export #{$export_file} -job_name #{label}"
  final_rpkm_file="#{$rds_dir}/#{$export_file}.final.rpkm"

  puts 'gathering stats...'
  post_status(Options.pp_id,'generating stats')

  launch(stats_cmd)
end


# ERCC section copied from ~vcassen/software/Solexa/RNA-seq/ERCC/ercc_pipeline.qsub
def erccs
  if Options.erccs
    ########################################################################
    # count ERCC alignments, utilizing original counts:
    
    ercc_counts="#{$working_dir}/#{$export_file}.ercc.counts" # output 
    count_erccs_cmd="#{$perl} #{$bowtie2count} #{alignment_output} > #{ercc_counts}"
    normalize_cmd="#{$perl} #{$normalize_erccs} -alignment_output #{alignment_output} -force" # fixme: need total_aligned_reads from script...
    
    raise "#{alignment_output} unreadable" unless FileTest.readable? alignment_output
    
    launch(count_erccs_cmd)
    puts "count_erccs: status is #{$?}"        # fixme
    exit $? if $?.to_i>0
    puts "#{ercc_counts} written"
    
    ########################################################################
    # get total aligned reads from the stats file:
    
    File.open(stats_file).each do |l|
      break if (total_aligned_reads=l.match(/(\d+) total aligned reads/).to_i > 0) 
    end
    puts "total_aligned_reads: #{total_aligned_reads}"
    
    
    ########################################################################
    # normalize read counts:
    # writes to #{alignment_output}.normalized (sorta; removes old suffix first, ie, "out"->"normalized").
    puts "normalize cmd: #{normalize_cmd}"
    launch("#{normalize_cmd} -total_aligned_reads #{total_aligned_reads}")
    
  end				# end ERCC section
end

########################################################################
## Stats2:

def stats2
  final_rpkm_file="#{$rds_dir}/#{$export_file}.final.rpkm"
  stats_file="#{$working_dir}/#{$export_file}.stats"
  n_genes=`wc -l #{final_rpkm_file}`.split(/\s+/)[0]
  stats=File.open(stats_file,'a')
  stats.puts "number of genes observed: #{n_genes}"
  stats.close

  # update slimseq with stats file and status:
end


def launch(cmd) 
  puts "\n#{cmd}"
  unless Options.dry_run
    success=system cmd
    raise "fail: #{cmd}: $? is #{$?}" unless success
  end
end

def post_status(pp_id, status)
  return if pp_id.nil? or pp_id.to_i<=0
  launch("#{$perl} #{$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value '#{status}'")
end

def fasta_format
  Options.readlen>=50 ? 'fa':'faq'
end

main()
