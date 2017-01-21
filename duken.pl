#!/usr/bin/perl

use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

use duken::ArgHandler;

my $interprete = duken::ArgHandler->new(\@ARGV);
$interprete->do();

