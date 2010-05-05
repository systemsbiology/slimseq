"#!#{ruby}

#PBS -N #{label}
#PBS -m bea
#PBS -M #{email}
#PBS -o #{working_dir}/#{label}.out
#PBS -e #{working_dir}/#{label}.err
#PBS -l walltime=72:00:00

require 'fileutils'

# config globals:
\$post_slimseq='#{script_dir}/post_to_slimseq.pl'
\$export2fasta='#{script_dir}/fq_all2std.pl'
\$bowtie_exe='#{rnaseq_dir}/bowtie/bowtie'
\$blat_exe='/package/genome/bin/blat'
\$erange_dir='#{rnaseq_dir}/ERANGE'
\$rds_dir='#{working_dir}/rds'
\$erange_script='#{rnaseq_dir}/ERANGE/runStandardAnalysisNFS.sh'
\$makerds_script='#{rnaseq_dir}/ERANGE/makerdsfrombowtie.py'
\$stats_script='#{script_dir}/gather_stats.pl'
\$bowtie2count='#{script_dir}/bowtie2count.ercc.pl'
\$normalize_erccs='#{script_dir}/normalize_erccs.pl'

def main
  integrity_checks()
  mk_working_dir()
  export2fasta()
  #{align}()                     
  makerds()
  call_erange()
  stats()
  erccs()
  stats2()
end


def integrity_checks
  messages=Array.new
  messages << '#{export_filepath}: no such file or unreadable'  unless (FileTest.readable?('#{export_filepath}'))


  # also need to test executable scripts, maybe write access to working_dir
  quit_flag=false
  exes=[\$post_slimseq,
        \$export2fasta,
        \$bowtie_exe,
        \$bowtie2count,
        \$makerds_script,
        \$erange_script,
        \$stats_script,
        \$bowtie2count,
        \$normalize_erccs]
  exes.each do |exe|
    if (FileTest.executable?(exe))
        \$stderr.puts \"\#{exe} found\"
    else
        \$stderr.puts \"\#{exe}: not found or not executable\" 
        quit_flag=true
    end
  end

  exit if quit_flag
  \$stderr.puts 'integrity checks passed'
end

def mk_working_dir
  FileUtils.mkdir '#{working_dir}' unless (FileTest.directory?('#{working_dir}')) 
  FileUtils.mkdir '#{working_dir}/rds' unless (FileTest.directory?('#{working_dir}/rds')) 

  FileUtils.cd '#{working_dir}'
  puts '*****************************************************'
  puts ' writing output to:'
  puts ' #{working_dir}'
  puts '*****************************************************'
  puts ' '
  
end

########################################################################
## translate export.txt file to fasta format

def export2fasta
  translation_cmd=\"#{perl} \#{\$export2fasta} solexa2fasta #{export_filepath}\"
  puts \"translation cmd: \#{translation_cmd} > #{working_dir}/#{export_file}.#{format}\"
  if ( #{pp_id} > 0 ) then
    system(\"perl \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'extracting reads from ELAND file'\")
  end

  # unlink converted export file if it exists (so that redirection, below, won't fail)
  if (FileTest.readable?(\"#{working_dir}/#{export_file}.#{format}\") and !#{dry_run}) then
    FileUtils.remove \"#{working_dir}/#{export_file}.#{format}\"
  end

  #{launch}(\"\#{translation_cmd} > #{working_dir}/#{export_file}.#{format}\")
  puts \"export2fasta: status is \#{$?}\"         # fixme
  exit \$? if \$?.to_i>0

# this writes #{working_dir}/#{export_file}.#{format}
end

########################################################################
## bowtie-cmd.sh:
## Note: bowtie needs .ewbt files to work from; don\"t exist yet for critters other than mouse

def bowtie
  reads_file=\"#{working_dir}/#{export_file}.#{format}\"	# export file converted to fasta format
  repeats=\"\#{reads_file}.repeats.#{format}\"
  unmapped=\"\#{reads_file}.unmapped.#{format}\"
  alignment_output=\"\#{reads_file}.bowtie.out\"
  alignment_cmd=\"\#{\$bowtie_exe} #{ref_genome} -n #{max_mismatches} #{bowtie_opts} \#{reads_file} --un \#{unmapped} --max \#{repeats} \#{alignment_output}\"


  # reads_file is the input
  #export BOWTIE_INDEXES=\"#{genomes_dir}/#{org_name}\"  
  ENV['BOWTIE_INDEXES']=\"#{genomes_dir}/#{org_name}\"

  puts \"alignment cmd: \#{alignment_cmd}\"
  if [ #{pp_id} ]; then
    #{launch}(\"perl \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'aligning reads (bowtie)'\")
  end
  #{launch}(\"\#{alignment_cmd}\")
  puts \"bowtie: status is \#{$?}\"         # fixme
  exit \$? if \$?.to_i>0

  puts \"\#{alignment_output} written\"
  puts \"\"
end

#-----------------------------------------------------------------------

def blat
  database='#{genomes_dir}/#{org_name}/#{ref_genome}'
  reads_file=\"#{working_dir}/#{export_file}.#{format}\"	# export file converted to fasta format
  alignment_output=\"\#{reads_file}.bowtie.out\" # fixme: wrong suffix
  alignment_cmd=\"\#{\$blat_exe} \#{database} \#{reads_file} \#{alignment_output}\"

  puts \"alignment cmd: \#{alignment_cmd}\"
  if [ #{pp_id} ]; then
    #{launch}(\"perl \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'aligning reads (bowtie)'\")
  end
  #{launch}(\"\#{alignment_cmd}\")
  puts \"blat: status is \#{$?}\"         # fixme
  exit \$? if \$?.to_i>0

  puts \"\#{alignment_output} written\"
  puts \"\"
end

#check
########################################################################
## makeRdsFromBowtie-cmd.sh:

# due to an apparent bug in makerdsfrombowtie.py, we need to rm rds_output
# if it exists.  The bug (actually in commoncode.py) is that it uses the 
# sql \"create table if not exists <tablename>\", without dropping the table/db
# first.  The effect is that the tables get appended to, not re-written.

def makerds
  reads_file=\"#{working_dir}/#{export_file}.#{format}\"	# export file converted to fasta format
  alignment_output=\"\#{reads_file}.bowtie.out\"
  gene_models=\"#{genomes_dir}/#{org_name}/knownGene.txt\"
  rds_output=\"\#{\$rds_dir}/#{export_file}.rds\"
  rds_args=\"-forceRNA -RNA \#{gene_models} -index -cache 1000 -rawreadID\"
  makerds_cmd=\"#{python} \#{\$makerds_script} #{label} \#{alignment_output} \#{rds_output} \#{rds_args}\"

  if (FileTest.readable?(\"\#{rds_output}\")  and !#{dry_run}) then
    FileUtils.remove(\"\#{rds_output}\")
  end

  puts \"rds cmd: \#{makerds_cmd}\"
  puts ''
  if ( #{pp_id} > 0 ) then
    #{launch}(\"#{perl} \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'Creating RDS files from alignment'\")
  end
  #{launch}(\"\#{makerds_cmd}\")
  puts \"makerds: status is \#{$?}\"         # fixme
  exit \$? if \$?.to_i>0
  puts \"\#{rds_output} written\"
end

########################################################################
## runStandardAnalysisNFS-cmd.sh:

def call_erange
  puts \" erange cmd: \#{\$erange_script}  #{org_name} \#{\$rds_dir}/#{export_file} #{genomes_dir}/#{org_name}/repeats_mask.db 5000\"
  if ( #{pp_id} > 0 ) then
    #{launch}(\"#{perl} \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'running ELAND'\")
  end
  #{launch}(\"time sh \#{\$erange_script} #{org_name} \#{\$rds_dir}/#{export_file} #{genomes_dir}/#{org_name}/repeats_mask.db 5000\")
  puts \"call_erange: status is \#{$?}\"         # fixme
  exit \$? if \$?.to_i>0
end

########################################################################
# gather stats:

def stats
  stats_file=\"#{working_dir}/#{export_file}.stats\"
  stats_cmd=\"#{perl} \#{\$stats_script} -working_dir #{working_dir} -export #{export_file} -job_name #{label}\"
  final_rpkm_file=\"\#{\$rds_dir}/#{export_file}.final.rpkm\"

  puts 'gathering stats...'
  if ( #{pp_id} > 0 ) then
    #{launch}(\"#{perl} \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'generating stats'\")
    #{launch}(\"#{perl} \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field stats_file -value \#{stats_file}\")
  end

  #{launch}(\"\#{stats_cmd}\")
end


# ERCC section copied from ~vcassen/software/Solexa/RNA-seq/ERCC/ercc_pipeline.qsub
def erccs
  if ( #{erccs} ) then
      ########################################################################
      # count ERCC alignments, utilizing original counts:
    
      ercc_counts=\"#{working_dir}/#{export_file}.ercc.counts\" # output 
      count_erccs_cmd=\"#{perl} \#{\$bowtie2count} \#{alignment_output} > \#{ercc_counts}\"
      normalize_cmd=\"#{perl} \#{\$normalize_erccs} -alignment_output \#{alignment_output} -force\" # fixme: need total_aligned_reads from script...

      if (!FileTest.readable?(\"\#{alignment_output}\")) then
        puts \"\#{alignment_output} unreadable\"
        exit 1
      end
    
      puts \"\#{count_erccs_cmd}\"
      #{launch}(\"\#{count_erccs_cmd}\")
      puts \"count_erccs: status is \#{$?}\"        # fixme
      exit \$? if \$?.to_i>0
      puts \"\#{ercc_counts} written\"

      ########################################################################
      # get total aligned reads from the stats file:
    
      File.open(\"\#{stats_file}\") do |f|
        f.lines.each do |l|
          if (total_aligned_reads=l.match(/(\d+) total aligned reads/).to_i > 0) then
            break
          end
        end
      end
      puts \"total_aligned_reads: \#{total_aligned_reads}\"
      

      ########################################################################
      # normalize read counts:
      # writes to \#{alignment_output}.normalized (sorta; removes old suffix first, ie, \"out\"->\"normalized\").
      puts \"normalize cmd: \#{normalize_cmd}\"
      #{launch}(\"\#{normalize_cmd} -total_aligned_reads \#{total_aligned_reads}\")
    
  end				# end ERCC section
end

########################################################################
## Stats2:

def stats2
  final_rpkm_file=\"\#{\$rds_dir}/#{export_file}.final.rpkm\"
  stats_file=\"#{working_dir}/#{export_file}.stats\"
  n_genes=\`wc -l \#{final_rpkm_file}\`.split(/\s+/)[0]
  stats=File.open(\"\#{stats_file}\",'a')
  stats.puts \"number of genes observed: \#{n_genes}\"
  stats.close



  # update slimseq with stats file and status:
  if ( #{pp_id} > 0 ) then
    #{launch}(\"#{perl} \#{\$post_slimseq} -type post_pipelines -id #{pp_id} -field status -value 'Finished'\")
  end
end

main()
"

