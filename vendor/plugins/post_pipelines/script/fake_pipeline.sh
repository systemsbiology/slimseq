#!/bin/sh
pp_id=$1			# post_pipeline id

update_pipeline=/home/victor/sandbox/rails/slimseq/script/update_pipeline_status.pl

statuses='1 2 3 4 5 6'
for status in $statuses; do
  perl $update_pipeline -pp_id=$pp_id -status=$status
  sleep 10
done



