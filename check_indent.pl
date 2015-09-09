#!/usr/bin/env perl
#
# Time-stamp: <2015-09-09 16:05:00 kurt>
#
# Perl script for checking indent of source files.
#
# Copyright (c) 2014-2015, Kurt Kanzenbach <kurt@kmk-computers.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

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
	my ($file, $line, $line_number, $error) = @_;
	my ($err_str);

	chomp $line;
	if ($error eq "tabs") {
		$err_str = "[$file]:$line_number tabs used instead of spaces: $line\n";
	} elsif ($error eq "spaces") {
		$err_str = "[$file]:$line_number spaces used instead of tabs: $line\n";
	} elsif ($error eq "trailing") {
		$err_str = "[$file]:$line_number trailing whitespaces found: $line\n";
	} else {
		die "Unknown error source.";
	}

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
		# tabs vs. spaces
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
		# trailing whitespaces
		if ($line =~ /[ \t]+$/) {
			add_error($file, $line, $cnt, "trailing");
			$error = 1;
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
