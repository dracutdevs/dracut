#!/usr/bin/perl

sub create_patches {
    my $tag=shift;
    my $pdir=shift;
    my $num=0;
    open( GIT, 'git format-patch -M -N --no-signature -o "'.$pdir.'" '.$tag.' |');
    @lines=<GIT>;
    close GIT;         # be done
    return @lines;
};

use POSIX qw(strftime);
my $datestr = strftime "%Y%m%d", gmtime;

my $tag=shift;
my $pdir=shift;
$tag=`git describe --abbrev=0 --tags` if not defined $tag;
chomp($tag);
my @patches=&create_patches($tag, $pdir);
my $num=$#patches + 2;
$tag=~s/[^0-9]+?([0-9]+)/$1/;
my $release="$num.git$datestr";
$release="1" if $num == 1;

while(<>) {
    if (/^Version:/) {
	print "Version: $tag\n";
    }
    elsif (/^Release:/) {
	print "Release: $release%{?dist}\n";
    }
    elsif ((/^Source0:/) || (/^Source:/)) {
	print $_;
	$num=1;
	for(@patches) {
	    s/.*\///g;
	    print "Patch$num: $_";
	    $num++;
	}
	print "\n";
    }
    else {
	print $_;
    }
}
