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
    my $num=0;
    open( GIT, 'git format-patch --no-renames -N --no-signature '.$tag.' |');
    @lines=<GIT>;
    close GIT;         # be done
    return @lines;
};
use POSIX qw(strftime);
my $datestr = strftime "%Y%m%d", gmtime;

my $tag=shift;
$tag=&last_tag if not defined $tag;
my @patches=&create_patches($tag);
my $num=$#patches + 2;
$tag=~s/[^0-9]+?([0-9]+)/$1/;
my $release="$num.git$datestr";
$release="1" if $num == 1;

while(<>) {
    if (/^Version:/) {
	print "Version: $tag\n";
    }
    elsif (/^Release:/) {
	print "Release: $release\n";
    }
    elsif ((/^Source0:/) || (/^Source:/)) {
	print $_;
	$num=1;
	for(@patches) {
	    print "Patch$num: $_";
	    $num++;
	}
	print "\n";
    }
    elsif (/^%setup/) {
	print $_;
	$num=1;
	for(@patches) {
	    print "%patch$num -p1\n";
	    $num++;
	}
	print "\n";
    }
    else {
	print $_;
    }
}
