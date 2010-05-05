#!/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
use FileHandle;

use FindBin;
#use lib "$FindBin::Bin/lib";
use lib '/net/dblocal/www/html/devVC/sbeams/lib/perl';
use SBEAMS::SolexaTrans::Options;
use SBEAMS::SolexaTrans::SolexaTransPipeline;

use lib '/users/vcassen/software/Solexa/lib';
use SlimseqClient;

BEGIN: {
  Options::use(qw(debug|d h project_name|id=s 
		  motif=s res_enzyme=s genome=s export_index=s tag_length=i
		  base_dir=s output_dir=s export_dir=s genome_dir=s
		  ref_fasta=s
		  export_files=s
		  export_filename_format|eff=s
		  use_old_patman_output
		  db_host=s db_name=s db_user=s db_pass=s 
		  babel_db_host=s babel_db_name=s babel_db_user=s babel_db_pass=s
		  email=s
		  ));
    
    Options::useDefaults(base_dir=>"$FindBin::Bin",
			 output_dir=>'output', 
			 export_files=>[],
			 export_dir=>'export_files',
			 genome_dir=>'genomes',
#			 genome=>'hg18',
			 tag_length=>36,
			 export_filename_format=>'s_%d_export.txt',
			 db_host=>'mysql', db_name=>'solexa_1_0', db_user=>'SolexaTags', db_pass=>'STdv1230',
			 babel_db_host=>'grits', babel_db_name=>'disease_data_3_9',babel_db_user=>'root',babel_db_pass=>'',
			 );
    Options::required(qw(project_name
			 ));
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
}



MAIN: {
    my $pipeline=SBEAMS::SolexaTrans::SolexaTransPipeline->new(%options); # doesn't actually use all %options, but I'm lazy
    $pipeline->run();
    warn "report:",Dumper($pipeline->stats());
}
