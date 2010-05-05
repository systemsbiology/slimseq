#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use URI::Escape;

BEGIN: {
    Options::use(qw(d q v h pp_id=i status=i ss_url=s pp_path=s));
    Options::required(qw(pp_id status));
    Options::useDefaults(ss_url=>'localhost:3000',
			 pp_path=>'post_pipelines/update',
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

MAIN: {
    my $ua=LWP::UserAgent->new;

    my $params=['post_pipeline[status]'=>$options{status},
		commit=>'Update',
		_method=>'put'
	];

    my $full_url="http://$options{ss_url}/$options{pp_path}/$options{pp_id}";
    warn "full_url is $full_url\n" if $ENV{DEBUG};

    my $headers=HTTP::Headers->new;
    my $res=$ua->post($full_url, $params);
    warn Dumper($res)if $ENV{DEBUG};
}
