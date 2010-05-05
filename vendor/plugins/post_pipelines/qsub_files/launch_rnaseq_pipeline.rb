"#!/bin/sh

# This is a templated (eval'd) ruby script that calls rnaseq_pipeline.rb

#{ruby} #{rnaseq_pipeline} -working_dir #{working_dir} -export_file #{export_file} -label #{label} -org #{org} -readlen #{readlen} -max_mismatches #{max_mismatches} -script_dir #{script_dir} -rnaseq_dir #{rnaseq_dir} -bin_dir #{bin_dir} -pp_id #{pp_id} #{dry_run}
"
