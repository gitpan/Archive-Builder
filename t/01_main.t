#!/usr/bin/perl

# Formal testing for Archive::Builder

use strict;
use lib '../../../modules'; # Development testing
use lib '../lib';           # Installation testing
use UNIVERSAL 'isa';
use Test::More qw{no_plan};
use Class::Autouse qw{:devel};
use Class::Handle;

# Set up any needed globals
BEGIN {
	$| = 1;
}




# Check their perl version
BEGIN {
	ok( $] >= 5.005, "Your perl is new enough" );
}
	




# Does the module load
BEGIN { use_ok( 'Archive::Builder' ) }
require_ok( 'Archive::Builder');


is( Archive::Builder->errstr, '', '->errstr correctly starts at ""' );



# Test the interface matches
my $methods = {
	'Archive::Builder' => [ qw{
		new errstr
		add_section new_section section sections section_list remove_section file_count
		} ],
	'Archive::Builder::Section' => [ qw{
		name path errstr new
		add_file new_file file files file_list remove_file file_count
		} ],
	'Archive::Builder::File' => [ qw{
		new path errstr generator arguments
		} ],
	'Archive::Builder::Archive' => [qw{
		types
		new type generate save
		} ],
	};
foreach my $class ( sort keys %$methods ) {
	my $Class = Class::Handle->new( $class )
		or die "Failed to get handle for class '$class'";
	foreach ( @{ $methods->{$class} } ) {	
		ok( $Class->can( $_ ), "$class has public API method '$_'" );
	}
}




####################################################################
# Section 1 - Test constructors

# Create a trivial Archive::Builder
my $Trivial = Archive::Builder->new();
ok( $Trivial, 'Archive::Builder constructor returns true' );
my $expected = bless { sections => {} }, 'Archive::Builder';
is_deeply( $Trivial, $expected, 'Creation of trivial Archive::Builder returns expected value' );
is( $Trivial->file_count, 0, 'Trivial builder has correct file count' );
my $Generator = $Trivial;

# Create a trivial section
ok( ! Archive::Builder::Section->new(), '->new() fails' );
foreach ( undef, '', ' asd ', 'a/b', 'a\b' ) {
	ok( ! Archive::Builder::Section->new( $_ ), '->new( name ) fails with bad name' );
}
my $Section = Archive::Builder::Section->new( 'name' );
ok( $Section, '->new( name ) with legal name returns true' );
my $expected2 = bless { name => 'name', path => 'name', zfiles => {} }, 'Archive::Builder::Section';
is_deeply( $Section, $expected2, 'Creation of simple Section returns expected value' );
ok( $Section->name eq 'name', '->name returns expected value' );
ok( $Section->path eq 'name', '->path returns expected value' );
ok( $Section->path eq 'name', '->path twice doesnt get a different value' );
foreach ( undef, '', 'bad/../path', 'bad\.\.path', '/path' ) {
	ok( ! $Section->path( $_ ), '->path change returns false for bad path' );
	is( $Section->path, 'name', '->path change does change for bad path' );
}
ok( $Section->path( 'path' ), '->path( path ) returns true' );
is( $Section->path , 'path', '->path( path ) changes the path' );
$expected2->{path} = 'path';
is( $Section->file_count, 0, '->file_count returns expected 0' );

# Create a simple file
ok( ! Archive::Builder::File->new(), '->new() fails' );
ok( ! Archive::Builder::File->new( 'path' ), '->new( path ) fails with valid path' );
my $File = Archive::Builder::File->new( 'path', 'main::generator' );
ok( $File, '->new( path, generator ) for simple case returns true' );
my $expected3 = bless { path => 'path', generator => 'main::generator', arguments => 0 }, 'Archive::Builder::File';
is_deeply( $File, $expected3, 'Creation of simple File returns expected value' );

# Check reasons file creation might fail
foreach ( undef, '', 'bad/../path', 'bad\.\.path', '/path' ) {
	ok( ! Archive::Builder::File->new( $_, 'main::generator' ), '->new( path, Archive::Builder ) fails correctly for bad paths' );
}
foreach ( undef, '', 'main::nonexistant', 'Foo::bar' ) {
	ok( ! Archive::Builder::File->new( 'path', $_ ), '->new( path, Archive::Builder ) fails correctly for bad Archive::Builders' );
}

ok( $File->path eq 'path', '->path returns expected value' );
ok( $File->generator eq 'main::generator', '->generator returns expected value' );
is( $File->arguments, 0, '->arguments returns expected value' );





###################################################################
# Test error handling

my @things = ( qw{Archive::Builder Archive::Builder::Section Archive::Builder::File
		  Archive::Builder::Archive},
	$Generator, $Section, $File );
my $i = 0;
foreach my $this ( @things ) {
	$i++;
	ok( ! defined $this->_error( 'this' . $i ), '->_error returns undef' );
	foreach my $that ( @things ) {
		is( 'this' . $i, $that->errstr, '->errstr picks up error' );
	}
	$this->_clear;
	foreach my $that ( @things ) {
		is( '', $that->errstr, '->errstr is cleared correctly' );
	}
}




#####################################################################
# Manipulating files in sections

is( $Section->files, 0, '->files returns expected value for empty Section' );
is( $Section->file_count, 0, '->file_count returns epected value for empty Section' );
ok( ! $Section->add_file(), '->add_file() returns false' );
is_deeply( $Section, $expected2, '->add_file() doesnt alter section' );
foreach ( undef, '', 1, bless( {}, 'blah' )) {
	ok( ! $Section->add_file( $_ ), '->add_file( File ) fails for bad value' );
	is_deeply( $Section, $expected2, '->add_file( File ) for bad value doesnt alter Section' );
}
ok( $Section->add_file( $File ), '->add_file( File ) returns true' );
$expected2->{zfiles}->{path} = $expected3;
is_deeply( $Section, $expected2, '->add_file( File ) alters Section correctly' );
is( $Section->file_count, 1, '->file_count goes up' );

ok( ! $Section->new_file(), '->new_file() returns false' );
is_deeply( $Section, $expected2, '->new_file() doesnt alter Section' );
ok( ! $Section->new_file( 'path' ), '->new_file( path ) returns false' );
is_deeply( $Section, $expected2, '->new_file( path ) doesnt alter Section' );
foreach ( undef, '', 'bad/../path', 'bad\.\.path', '/path' ) {
	ok( ! $Section->new_file( $_, 'main::generator' ), '->new_file( path, Archive::Builder ) returns false for bad path' );
	is_deeply( $Section, $expected2, '->new_file( path, Archive::Builder ) doesnt alter the section' );
}
foreach ( undef, '', 'main::nonexistant', 'Foo::bar' ) {
	ok( ! $Section->new_file( 'path2/path3', $_ ), '->new_file( path, Archive::Builder ) returns false for bad geneartor' );
	is_deeply( $Section, $expected2, '->new_file( path, Archive::Builder ) doesnt alter the section' );
}
ok( ! $Section->new_file( 'path', 'main::generator' ), '->new_file( path, Archive::Builder ) returns false for existing path' );
is_deeply( $Section, $expected2, '->new_file( path, Archive::Builder ) doesnt alter the section' );

my $rv = $Section->new_file( 'path2/path3', 'main::generator' );
ok( $rv, '->new_file( path, Archive::Builder ) returns true for good values' );
my $expected4 = bless { path => 'path2/path3', generator => 'main::generator', arguments => 0 }, 'Archive::Builder::File';
$expected2->{zfiles}->{'path2/path3'} = $expected4;
is_deeply( $rv, $expected4, '->new_file( path, generator ) returns the new file' );
is_deeply( $Section, $expected2, '->new_file( path, generator ) alters Section in expected way' );
is( $Section->file_count, 2, '->file_count goes up' );

is_deeply( $Section->files, { 'path', $expected3, 'path2/path3', $expected4 }, '->files returns expected value' );
my @List = $Section->file_list;
my @Expe = ( $expected3, $expected4 );
is_deeply( \@List, \@Expe, '->file_list returns expected value' );

# Files that fail because they clash
foreach ( 'path', 'path2/path3', 'path/path2', 'path2' ) {
	ok( ! $Section->new_file( $_, 'main::generator' ), '->new_file( path, Archive::Builder ) returns false for clashing' );
	is_deeply( $Section, $expected2, '->new_file( path, Archive::Builder ) doesnt alter the section' );
}


is_deeply( $expected3, $Section->file( 'path' ), '->file returns expected for existing file' );
ok( ! $Section->file( 'nonexistant' ), '->file returns false for nonexistant path' );
ok( ! $Section->file(), '->file returns false for no argument' );

ok( ! $Section->remove_file(), '->remove_file returns false for no argument' );
is_deeply( $Section, $expected2, '->remove_file for no argument doesnt modify Section' );
ok( ! $Section->remove_file( 'nonexistant' ), '->remove_file returns false for bad argument' );
is_deeply( $Section, $expected2, '->remove_file for bad argument doesnt modify Section' );
ok( $Section->remove_file( 'path' ), '->remove_file returns true for good argument' );
delete $expected2->{zfiles}->{path};
is_deeply( $Section, $expected2, '->remove_file removes File successfully' );






###############################################################################
# Manipulating sections in Archive::Builders

is( $Generator->sections, 0, '->sections returns 0 for empty Archive::Builder' );
ok( ! $Generator->add_section(), '->add_section() returns false' );
foreach ( undef, '', 'blah', bless( {}, 'blah') ) {
	ok( ! $Generator->add_section( $_ ), '->add_section( Section ) returns false for bad argument' );
	is_deeply( $Generator, $expected, '->add_section( Section ) doesnt changeArchive::Builder for bad argument' );
}

ok( $Generator->add_section( $Section ), '->add_section( Section ) returns true for valid section' );
$expected->{sections}->{name} = $expected2;
is_deeply( $Generator, $expected, '->add_section( Section ) modifies Archive::Builder as expected' );
ok( ! $Generator->add_section( $Section ), '->add_section( Section ) returns false for existing section' );
is_deeply( $Generator, $expected, '->add_section( SEction ) doesnt modify Archive::Builder for existing section' );

ok( ! $Generator->new_section(), '->new_section() returns false' );
is_deeply( $Generator, $expected, '->new_section() doesnt modify object' );
foreach ( undef, '', ' asd ', 'a/b', 'a\b' ) {
	ok( ! $Generator->new_section( $_ ), '->new_section( name ) returns false for bad name' );
	is_deeply( $Generator, $expected, '->new_section( name ) doesnt change Archive::Builder for bad name' );
}
ok( ! $Generator->new_section( 'name' ), '->new_section( name ) fails for existing name' );
is_deeply( $Generator, $expected , '->new_section( name ) doesnt change Archive::Builder for existing name' );

$rv = $Generator->new_section( 'name2' );
my $expected5 = bless { name => 'name2', path => 'name2', zfiles => {}, }, 'Archive::Builder::Section';
$expected->{sections}->{name2} = $expected5;
is_deeply( $rv, $expected5, '->new_section(name) returns the expected new object' );
is_deeply( $Generator, $expected, '->new_section(name) modifys the Archive::Builder as expected' );

is_deeply( $Generator->sections, { 'name' => $expected2, 'name2' => $expected5 }, 
	'->files returns the expected structure' );
@List = $Generator->section_list;
@Expe = ( $expected2, $expected5 );
is_deeply( \@List, \@Expe, '->section_list returns the expected structure' );

is( $Generator->file_count, 1, 'Generaotr has correct file count' );

is_deeply( $Generator->section( 'name' ), $expected2, '->section returns the expected structure' );
ok( ! $Generator->section(), '->section() fails as expected' );
ok( ! $Generator->section( 'nonexistant' ), '->section( bad ) fails as expected' );

ok( ! $Generator->remove_section(), '->remove_section() returns false' );
ok( ! $Generator->remove_section( 'bad' ), '->remove_section( bad ) returns false' );
is_deeply( $Generator, $expected, '->bad remove_section() calls dont modify Archive::Builder' );
ok( $Generator->remove_section( 'name2' ), '->remove_section( good ) returns true' );
delete $expected->{sections}->{name2};
is_deeply( $Generator, $expected, '->remove_section( good ) modifys Archive::Builder as expected' );
 




# Changing the path of a sect

# Test generation of the contents of a file
use vars qw{$call_count};
$call_count = 0;
my $contents = $File->contents;
ok( $contents, '->contents returns true' );
is( $call_count, 1, '->contents called the Archive::Builder' );
is_deeply( $contents, \'trivial', '->contents returned the correct contents' );
$contents = $File->contents;
is( $call_count, 1, '->contents didnt call the Archive::Builder the second time' );
is_deeply( $contents, \'trivial', '->contents cached correctly' );






######################################################################
# Resources for tests


sub generator {
	$call_count++;
	my $File = shift;
	return \'trivial';
}

1;

