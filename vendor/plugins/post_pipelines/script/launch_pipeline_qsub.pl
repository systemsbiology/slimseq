#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

BEGIN: {
    Options::use(qw(d q v h ss_id=i));
    Options::required(qw(ss_id));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

MAIN: {
}
