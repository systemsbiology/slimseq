#!/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
use FileHandle;
use FindBin;

use lib '/net/dblocal/www/html/devVC/sbeams/lib/perl/SBEAMS/SolexaTrans';
use lib '/net/dblocal/www/html/devVC/sbeams/lib/perl';
use JSON;

# Run the SolexaTransPipeline
# lots of parameters; can use -config to specify many of them

use SBEAMS::SolexaTrans::Options;
use SBEAMS::SolexaTrans::SolexaTransPipeline;
use SBEAMS::SolexaTrans::SlimseqClient;
use SBEAMS::SolexaTrans::RestrictionSites;
use SBEAMS::SolexaTrans::AddamaClient;
use SBEAMS::SolexaTrans::ListUtilities qw(soft_copy);
use vars qw(%conf);


BEGIN: {
  SBEAMS::SolexaTrans::Options::use(qw(debug|d help|h verbose|v project_name=s config|conf=s
				       motif=s res_enzyme=s ref_genome=s tag_length=i
				       output_dir=s genome_dir=s
				       ref_fasta=s ref_org=s genome_id=i
				       export_file=s lane=i 
				       ss_sample_id|ssid=i ss_base_url=s
				       flowcell_id=i
				       use_old_patman_output patman_max_mismatches=i
				       db_host=s db_name=s db_user=s db_pass=s 
				       babel_db_host=s babel_db_name=s babel_db_user=s babel_db_pass=s
				       email=s fuse=i skip_lookup_tags
				       use_slimseq
				       verify_args_only
					 ));
    SBEAMS::SolexaTrans::Options::useDefaults(base_dir=>"$FindBin::Bin",
					      export_files=>[],
					      export_dir=>'export_files',
					      genome_dir=>'genomes',
					      export_filename_format=>'s_%d_export.txt',
#					      tag_length=>36,
					      genome_id=>[],
#					      db_host=>'grits', db_name=>'Solexa', db_user=>'', db_pass=>'',
					      db_host=>'mysql', db_name=>'solexa_1_0', db_user=>'SolexaTags', db_pass=>'STdv1230',
					      babel_db_host=>'grits', babel_db_name=>'disease_data_3_9',babel_db_user=>'root',babel_db_pass=>'',
					      use_slimseq=>1, verify_args_only=>0,
					      );
#    SBEAMS::SolexaTrans::Options::required(qw());
    SBEAMS::SolexaTrans::Options::get();
    @options{qw(d v h)}=@options{qw(debug verbose help)};
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
    
    
    if ($options{config} && -r $options{config}) {
	warn "reading options from $options{config}\n";
	my $conf=do $options{config};
	confess "$options{config} does not return a HASH ref" unless ref $conf eq 'HASH';
	soft_copy(\%options,$conf);
    }
#    confess "no project_name in ",Dumper(\%options) unless $options{project_name};
}



MAIN: {
    get_slimseq_options() if $options{use_slimseq};
    $options{genome_ids}=$options{genome_id};
    my $pipeline=SBEAMS::SolexaTrans::SolexaTransPipeline->new(%options); # doesn't actually use all %options, but I'm lazy
    if ($options{verify_args_only}) {
	$pipeline->verify_required_opts;
	my $dump=$options{verbose}? ': '.Dumper($pipeline):'';
	die "got valid pipeline object $dump\n";
    }
    my $status=$pipeline->run();
}


# Add information to %options based on slimseq's webservice
sub get_slimseq_options {
    my ($ss_base_url,$ss_user,$ss_pass,$ss_id)=@options{qw(ss_base_url ss_user ss_pass ss_sample_id)};
#    confess "no ss_base_url" unless $ss_base_url;
    confess "no ss_sample_id" unless $ss_id;

    my %ss_args=(ss_id=>$ss_id);
    foreach my $arg (qw(base_url ss_user ss_pass)) {
	$ss_args{$arg}=$options{$arg} if $options{$arg};
    }
    my $ss_client=SBEAMS::SolexaTrans::SlimseqClient->new(%ss_args);
    my $sample_info=$ss_client->get_slimseq_json('sample',$ss_id);
    warn "sample_info: ", Dumper($sample_info) if $ENV{DEBUG};

    # fill in info from slimseq:
    $options{project_name}||=$sample_info->{project};
    
    if (!$options{motif}) {
	if (my $res_en=$sample_info->{'sample_prep_kit_restriction_enzyme'}) {
	    $options{motif}=SBEAMS::SolexaTrans::RestrictionSites->new->motif($res_en);
	} else {
	    die "sample $ss_id doesn't seem to have a motif or res. site enzyme associated with it!\n";
	}
    }
    
    $options{tag_length}||=
	$sample_info->{alignment_end_position}-
	$sample_info->{alignment_start_position}+1;
    
    $options{ref_org}||=$sample_info->{reference_genome}->{organism};
    $options{ref_name}=$sample_info->{reference_genome}->{name};

    my $flowcell_uris=$sample_info->{flow_cell_lane_uris};
    die "no flowcell_uris for sample_id=$ss_id" unless @$flowcell_uris;
    my $flowcell_info;
    if (@$flowcell_uris==1) {
	my $fc_info=$ss_client->get_uri($flowcell_uris->[0]);
	if (ref $fc_info eq 'HASH') {
	    $flowcell_info=$fc_info if !$options{flowcell_id} || $options{flowcell_id}==$fc_info->{id};
	}
    } else {
	warn sprintf("multiple flow cell lanes for sample_id=$ss_id: fc_ids=%s\n", join(', ', map {/\d+$/; $&} @$flowcell_uris));
	unless ($options{flowcell_id}) {
	    die "and no -flowcell-id specified on cmd line\n";
	}
	foreach my $fc_uri (@$flowcell_uris) {
	    my $fc_info=$ss_client->get_uri($fc_uri) || {};
	    $flowcell_info=$fc_info if $options{flowcell_id}==$fc_info->{id};
	}
    }
    die "no flowcell info found\n" unless $flowcell_info;

    $options{export_file}||=$flowcell_info->{eland_output_file};
    $options{output_dir}||=$flowcell_info->{raw_data_path}.'/Data/SolexaTrans';	# or something; ask Denise
    $options{lane}||=$flowcell_info->{lane_number};


    # I believe this is sufficient for STP.pm; see STP::get_genomes();
}

sub update_jcr {
    my ($pipeline)=@_;
    my $jcr_info=$pipeline->jcr_info;
    my $ac=SBEAMS::SolexaTrans::AddamaClient->new(base_url=>'http://retina:8080/addama-rest',
			     repository=>'nextgen-pipelines');
    my $path=join('/','SolexaTrans',$jcr_info->{id});
    delete $jcr_info->{inputs}->{genome_ids}; # for now (nobody'll care but me (is the theory))
    warn "jcr_info is ",Dumper($jcr_info);
    my $ts=$jcr_info->{timestamp} || time;
    $ac->post($path,{$ts=>$jcr_info},1);
}
