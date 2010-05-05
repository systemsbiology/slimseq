"#!#{ruby}

#PBS -N #{label}
#PBS -m bea
#PBS -M #{email}
#PBS -o #{working_dir}/#{label}.out
#PBS -e #{working_dir}/#{label}.err
#PBS -l walltime=72:00:00

if (FileTest.directory?('#{working_dir}')) then
  mkdir '#{working_dir}'
  mkdir '#{working_dir}/rds'
end

cd '#{working_dir}'
puts '*****************************************************'
puts ' writing output to:'
puts ' #{working_dir}'
puts '*****************************************************'
puts ' '

unless (FileTest.readable?('#{working_dir}/#{export_file}')) then
  puts ' #{working_dir}/#{export_file}: no such file or unreadable'
  exit 1
end


# config:
rnaseq_dir=\"\#{script_dir}/RNA-Seq\"
post_slimseq=\"\#{script_dir}/post_to_slimseq.pl\"
bowtie_exe=\"\#{rnaseq_dir}/bowtie/bowtie\"
erange_dir=\"\#{rnaseq_dir}/commoncode\"

########################################################################
## translate export.txt file to fasta format

translation_cmd=\"#{perl} #{export2fasta} export2std #{working_dir}/#{export_file}\"
puts 'translation cmd: \#{translation_cmd} > #{working_dir}/#{export_file}.#{format}'
if ( #{pp_id} > 0 ) then
    system('perl \#{post_slimseq} -type post_pipelines -id #{pp_id} -field status -value \"extracting reads from ELAND file\"')
end

# unlink converted export file if it exists (so that redirection, below, won't fail)
if (FileTest.readable?('#{working_dir}/#{export_file}.#{format}')) then
  remove '#{working_dir}/#{export_file}.#{format}'
end

#{launch}('\#{translation_cmd} > #{working_dir}/#{export_file}.#{format}')
puts 'status is #{$?}'         # fixme


# this writes #{working_dir}/#{export_file}.#{format}

########################################################################
## bowtie-cmd.sh:
## Note: bowtie needs .ewbt files to work from; don\"t exist yet for critters other than mouse

reads_file=\"#{working_dir}/#{export_file}.#{format}\"	# export file converted to fasta format
repeats=\"\#{reads_file}.repeats.#{format}\"
unmapped=\"\#{reads_file}.unmapped.#{format}\"
genomes_dir=\"#{jdrf_dir}/genomes\"
bowtie_output=\"\#{reads_file}.bowtie.out\"
alignment_cmd=\"\#{bowtie_exe} #{ref_genome} #{bowtie_opts} \#{reads_file} --unfa \#{unmapped} --maxfa \#{repeats} \#{bowtie_output}\"


# reads_file is the input
#export BOWTIE_INDEXES=\"\#{genomes_dir}/#{org_name}\"  
ENV['BOWTIE_INDEXES']=\"\#{genomes_dir}/#{org_name}\"

puts \"alignment cmd: \#{alignment_cmd}\"
if [ #{pp_id} ]; then
    #{launch}('perl \#{post_slimseq} -type post_pipelines -id #{pp_id} -field status -value \"aligning reads (bowtie)\"')
end
#{launch}('\#{alignment_cmd}')
puts \" status is #{$?}\"         # fixme

puts \"\#{bowtie_output} written\"
puts \"\"

#check
########################################################################
## makeRdsFromBowtie-cmd.sh:

# due to an apparent bug in makerdsfrombowtie.py, we need to rm rds_output
# if it exists.  The bug (actually in commoncode.py) is that it uses the 
# sql \"create table if not exists <tablename>\", without dropping the table/db
# first.  The effect is that the tables get appended to, not re-written.

makerds_script=\"\#{erange_dir}/makerdsfrombowtie.py\"
rds_dir=\"#{working_dir}/rds\"
gene_models=\"\#{genomes_dir}/#{org_name}/knownGene.txt\"
rds_output=\"\#{rds_dir}/#{export_file}.rds\"
rds_args=\"-RNA \#{gene_models} -index -cache 1000 -rawreadID\"
makerds_cmd=\"#{python} \#{makerds_script} #{label} \#{bowtie_output} \#{rds_output} \#{rds_args}\"

if (FileTest.readable?('\#{rds_output}')) then
  rm '\#{rds_output}'
end

puts 'rds cmd: \#{makerds_cmd}'
puts ''
if ( #{pp_id} > 0 ) then
    #{launch}('#{perl} \#{post_slimseq} -type post_pipelines -id #{pp_id} -field status -value \"Creating RDS files from alignment\"')
end
#{launch}('\#{makerds_cmd}')
puts \" status is #{$?}\"         # fixme
puts '\#{rds_output} written'

########################################################################
## runStandardAnalysisNFS-cmd.sh:

puts \" erange cmd: \#{erange_dir}/runStandardAnalysisNFS.sh #{org_name} \#{rds_dir}/#{export_file} #{jdrf_dir}/genomes/#{org_name}/repeats_mask.db 5000\"
if ( #{pp_id} > 0 ) then
    #{launch}('#{perl} \#{post_slimseq} -type post_pipelines -id #{pp_id} -field status -value \"running ELAND\"')
end
#{launch}('time sh \#{erange_dir}/runStandardAnalysisNFS.sh #{org_name} \#{rds_dir}/#{export_file} #{jdrf_dir}/genomes/#{org_name}/repeats_mask.db 5000')
puts 'status is #{$?}'         # fixme

########################################################################
# gather stats:

stats_file=\"#{working_dir}/#{export_file}.stats\"
stats_script=\"#{script_dir}/gather_stats.pl\"
stats_cmd=\"#{perl} \#{stats_script} -working_dir #{working_dir} -export #{export_file} -job_name #{label}\"
final_rpkm_file=\"\#{rds_dir}/#{export_file}.final.rpkm\"

puts 'gathering stats...'
if ( #{pp_id} > 0 ) then
    #{launch}('#{perl} \#{post_slimseq} -type post_pipelines -id #{pp_id} -field status -value \"generating stats\"')
    #{launch}('#{perl} \#{post_slimseq} -type post_pipelines -id #{pp_id} -field stats_file -value \#{stats_file}')
end

#{launch}('\#{stats_cmd}')



# ERCC section copied from ~vcassen/software/Solexa/RNA-seq/ERCC/ercc_pipeline.qsub
if ( #{erccs} ) then
########################################################################
# count ERCC alignments, utilizing original counts:
    
    bowtie2count=\"#{script_dir}/bowtie2count.ercc.pl\"
    ercc_counts=\"#{working_dir}/#{export_file}.ercc.counts\" # output 
    count_erccs_cmd=\"#{perl} \#{bowtie2count} \#{bowtie_output} > \#{ercc_counts}\"
    normalize_erccs=\"#{script_dir}/normalize_erccs.pl\"
    normalize_cmd=\"#{perl} \#{normalize_erccs} -bowtie_output \#{bowtie_output} -force\" # fixme: need total_aligned_reads from script...

    if (!FileTest.readable?('\#{bowtie_output}')) then
      puts '\#{bowtie_output} unreadable'
      exit 1
    end
    
    puts '\#{count_erccs_cmd}'
    #{launch}('\#{count_erccs_cmd}')
    puts 'status is #{$?}'        # fixme
    puts '\#{ercc_counts} written'

########################################################################
# get total aligned reads from the stats file:
    
    File.open('\#{stats_file}') do |f|
      f.lines.each do |l|
        if (total_aligned_reads=l.match(/(\d+) total aligned reads/).to_i > 0) then
          break
        end
      end
    end
    puts \"total_aligned_reads: \#{total_aligned_reads}\"
      

########################################################################
# normalize read counts:
  # writes to \#{bowtie_output}.normalized (sorta; removes old suffix first, ie, \"out\"->\"normalized\").
  puts 'normalize cmd: \#{normalize_cmd}'
    #{launch}(\"\#{normalize_cmd} -total_aligned_reads \#{total_aligned_reads}\")
    
  end				# end ERCC section

########################################################################
## Stats2:

n_genes=`wc -l \#{final_rpkm_file} | cut -f1 -d\  `
stats=File.open('\#{stats_file}','a')
stats.puts \"number of genes observed: \#{n_genes}\"
stats.close



# update slimseq with stats file and status:
if ( #{pp_id} > 0 ) then
    #launch('#{perl} \#{post_slimseq} -type post_pipelines -id #{pp_id} -field status -value \"Finished\"')
end
"
