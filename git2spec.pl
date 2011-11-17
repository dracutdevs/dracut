#!/usr/bin/perl

sub last_tag {
    open( GIT, 'git log  --pretty=format:%H |');
  LINE: while( <GIT> ) {
      open( GIT2, "git tag --contains $_ |");
      while( <GIT2> ) {
	  chomp;
	  last LINE if /..*/;
      }
      close GIT2;
  }
    $tag=$_;
    close GIT2;
    close GIT;         # be done
    return $tag;
};

sub create_patches {
    my $tag=shift;
    my $pdir=shift;
    my $num=0;
    open( GIT, 'git format-patch -N --no-signature -o "'.$pdir.'" '.$tag.' |');
    @lines=<GIT>;
    close GIT;         # be done
    return @lines;
};

use POSIX qw(strftime);
my $datestr = strftime "%Y%m%d", gmtime;

my $tag=shift;
my $pdir=shift;
$tag=&last_tag if not defined $tag;
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
