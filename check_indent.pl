#!/usr/bin/env perl
#
# Copyright (C) 2014 Kurt Kanzenbach <kurt@kmk-computers.de>
#

use 5;
use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor qw(:constants);

# arguments
my ($recursive, $use_tabs, $use_spaces, $check, @files, $verbose);

# internal stuff
my (@errors);

# begin with work :)
sub print_usage_and_exit
{
	select STDERR;
	local $| = 1;
	print <<"EOF";
usage: $0 <options> -- <files|directories>

options:
    -v, --verbose          : verbose output
    -r, --recursive        : going recursive in directories
    -t, --tabs             : tabs should be used for indention -> finds lines indented with spaces
    -s, --spaces           : spaces should be used for indention -> finds lines indented with tabs
    -c, --check            : checks whether mixed indention is used

Notes: -t and -s cannot be used together.
EOF

	exit -1;
}

sub get_args
{
	GetOptions("verbose"   => \$verbose,
			   "recursive" => \$recursive,
			   "tabs"      => \$use_tabs,
			   "spaces"    => \$use_spaces,
			   "check"     => \$check) || print_usage_and_exit();

	@files = @ARGV;

	# verify arguments
	print_usage_and_exit() unless (@files);
	print_usage_and_exit() if     ($use_spaces && $use_tabs);
	return if ($check);
	print_usage_and_exit() unless ($use_spaces || $use_tabs);

	return;
}

sub add_error
{
	my ($file, $line, $line_number, $t_or_s) = @_;
	my ($err_str);

	chomp $line;
	$err_str = "[$file]:$line_number $t_or_s used: $line\n";

	push(@errors, $err_str) if ($verbose);

	return;
}

sub check_indent
{
	my ($file) = @_;
	my ($fh, $cnt, $error, $line);

	open($fh, "<", $file) || die "Cannot open file \"$file\": $!";

	$cnt   = 1;
	$error = 0;
	while ($line = <$fh>) {
		if ($use_tabs) {
			if ($line =~ /^[ ]+/) {
				add_error($file, $line, $cnt, "spaces");
				$error = 1;
			}
		} elsif ($use_spaces) {
			if ($line =~ /^[\t]+/) {
				add_error($file, $line, $cnt, "tabs");
				$error = 1;
			}
		} else {
			die "This should never happen.";
		}
		++$cnt;
	}

	print STDERR BOLD RED "The file \"$file\" has false indention.\n" if ($error);
	print STDERR RESET if ($error);

	close $fh;

	return;
}

sub check
{
	my ($file) = @_;
	my ($tabs, $spaces, $line, $fh);

	open($fh, "<", $file) || die "Cannot open file \"$file\": $!";

	$tabs   = 0;
	$spaces = 0;
	# not the fastest variant, but it should work
	while ($line = <$fh>) {
		$spaces = 1 if ($line =~ /^[ ]+/);
		$tabs   = 1 if ($line =~ /^[\t]+/);

		if ($spaces == 1 && $tabs == 1) {
			print STDERR BOLD RED "The file \"$file\" has mixed indention!\n";
			print STDERR RESET;
			last;
		}
	}

	close $fh;

	return;
}

sub print_errors
{
	foreach my $err (@errors) {
		print STDERR "$err";
	}

	return;
}

sub run
{
	my ($file) = @_;
	my ($dh);

	if (-d $file) {
		opendir($dh, $file) || die "Cannot open directory \"$file\": $!";
		for (readdir $dh) {
			next if (/^\./);
			run($file . "/" . $_);
		}
		close $dh;
	} elsif (-f $file) {
		check($file)        if     ($check);
		check_indent($file) unless ($check);
	} else {
		print STDERR BOLD RED "The file \"$file\" is not valid.\n";
		print STDERR RESET;
	}

	return;
}

# main
get_args();
run($_) for (@files);
print_errors();

exit 0;
