#!/tools/bin/ruby

# Scaffold script to write the launch_rnaseq_pipeline.rb script for a given set of parameters

$:<<'/proj/hoodlab/share/vcassen/rna-seq/scripts/lib'
require 'options'

Options.use(%w{ruby rnaseq_pipeline=s working_dir=s export_file=s label=s org=s readlen=i max_mismatches=i script_dir=s rnaseq_dir=s pp_id=i template=s dry_run bin_dir=s host=s})
defaults={
:rnaseq_pipeline=>'/proj/hoodlab/share/vcassen/rna-seq/scripts/rnaseq_pipeline.rb',
:working_dir=>'/solexa/hood/022210_LYC/100309_HWI-EAS427_0014_FC61502AAXX/Data/Intensities/BaseCalls/GERALD_16-03-2010_sbsuser/post_pipeline_412/10K',
:export_file=>'s_1_export.10K.txt',
:label=>'sample_412_fcl_585',
:org=>'human',
:readlen=>75,
:max_mismatches=>1,
:script_dir=>'/proj/hoodlab/share/vcassen/rna-seq/scripts',
:rnaseq_dir=>'/proj/hoodlab/share/vcassen/rna-seq',
:pp_id=>0,
:template=>'/proj/hoodlab/share/vcassen/rna-seq/scripts/launch_rnaseq_pipeline.template.rb'
}
Options.use_defaults(defaults)
Options.parse

host=(!Options.host.nil? ? Options.host : `hostname`.chomp).split('.')[0].to_sym
bin_dir={:aegir=>'/hpc/bin',
          :bento=>'/tools/bin',
  :mimas=>'/tools/bin'}[host]
bin_dir='/tools/bin' if bin_dir.nil?
ruby=File.join(bin_dir,'ruby')

rnaseq_pipeline=Options.rnaseq_pipeline
working_dir=Options.working_dir
export_file=Options.export_file
label=Options.label
org=Options.org
readlen=Options.readlen
max_mismatches=Options.max_mismatches
script_dir=Options.script_dir
rnaseq_dir=Options.rnaseq_dir
pp_id=Options.pp_id
template=Options.template
dry_run=Options.dry_run ? '-dry_run' : ''


Options.use_defaults(defaults)
Options.parse()

template_text=''
File.open(Options.template).each do |l|
  template_text+=l
end
 
rnaseq_pipeline_script = eval template_text
output_filename="#{working_dir}/rnaseq_pipeline.#{label}.rb"
output=File.open(output_filename,"w")
output.puts rnaseq_pipeline_script
output.close
puts "#{output_filename} written"

