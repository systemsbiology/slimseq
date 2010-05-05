"#!/bin/sh

#PBS -N #{label}
#PBS -M bea
#PBS -o #{working_dir}/#{label}.out
#PBS -e #{working_dir}/#{label}.err
#PBS -l walltime=72:00:00

# input args:
# Note: if running from qsub, no args are allowed.  So anything labeled as 'arg' must actually be written
# into the script, template fasion.  OR, you have the qsub script call this script, and write the args
# into the qsub script

# should be able to get all of the following using the pp_id and slimseq
export_file=#{export_file}

base_directory=`dirname $export_file`
working_dir=$base_directory/post_pipeline
echo '*****************************************************'
echo writing output to:
echo $working_dir
echo '*****************************************************'
echo 

ref_genome=#{ref_genome}
org=#{org_name}


if [ ! -r $export_file ]; then
  echo ${export_file}: no such file or unreadable
  exit 1
fi
export_file=`basename $export_file`

if [ ! -d $working_dir ]; then
    mkdir $working_dir 
    mkdir $working_dir/rds
fi

# config:
script_dir=/users/vcassen/software/Solexa
rnaseq_dir=$script_dir/RNA-Seq
bowtie_exe=$rnaseq_dir/bowtie/bowtie
erange_dir=$rnaseq_dir/commoncode

jdrf_dir=/jdrf/data_var/solexa
genomes_dir=$jdrf_dir/genomes

update_status=$script_dir/update_pipeline_status.pl # needs pp_id and status

########################################################################
## translate export.txt file to fasta format
export2fasta=$script_dir/export2fasta.pl
cmd=\"$export2fasta $base_directory/$export_file $working_dir/$export_file.fa\"
echo \"translation cmd: $cmd\"
time $cmd
# this write $working_file/$export_file.fa

########################################################################
## bowtie-cmd.sh:
## Note: bowtie needs .ewbt files to work from; don't exist yet for critters other than mouse

# reads_file is the input
reads_file=$working_dir/$export_file.fa	# export file converted to fasta format
repeats=$reads_file.repeats.fa
unmapped=$reads_file.unmapped.fa
bowtie_output=$reads_file.bowtie.out

export BOWTIE_INDEXES=\"$genomes_dir/$org\"

cmd=\"$bowtie_exe $ref_genome -v 2 -k 11 -m 10 -t --best -f $reads_file --unfa $unmapped --maxfa $repeats $bowtie_output\"
echo \"alignment cmd: $cmd\"
time $cmd

echo $bowtie_output written
echo

#check
########################################################################
## makeRdsFromBowtie-cmd.sh:

# args:
label=label			  # arg; fixme

python=/tools/bin/python
script=$erange_dir/makerdsfrombowtie.py

# this is where the output (rds files) will go
rds_dir=$working_dir/rds

# from bowtie-cmd.sh:
input=$bowtie_output
output=$rds_dir/$export_file.rds

gene_models=$genomes_dir/$org/knownGene.txt
args=\"-RNA $gene_models -index -cache 1000 -rawreadID\"

cmd=\"$python $script $label $input $output $args\"
echo \"rds cmd: $cmd\"

echo $output written
echo
time $cmd

########################################################################
## runStandardAnalysisNFS-cmd.sh:

echo erange cmd: $erange_dir/runStandardAnalysisNFS.sh $org $working_dir/rds/$export_file $jdrf_dir/genomes/mouse/repeats_mask.db 5000
time sh $erange_dir/runStandardAnalysisNFS.sh $org $working_dir/rds/$export_file $jdrf_dir/genomes/mouse/repeats_mask.db 5000
"
