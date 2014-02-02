#!/usr/bin/env perl

use strict;
use warnings;

if (@ARGV != 1) {
	print STDERR "usage: $0 FILENAME\n";
	exit 0;
}

my @s = lstat $ARGV[0] or die $!;
printf "%06o\n", $s[2];
