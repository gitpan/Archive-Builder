package Archive::Builder::Section;

# A section is a tree of Archive::Builder::File's

require 5.005;
use strict;
use UNIVERSAL 'isa';
use Scalar::Util 'refaddr';
use Archive::Builder ();

use vars qw{$VERSION %_PARENT};
BEGIN {
	$VERSION = '0.8';
	%_PARENT = ();
}





#####################################################################
# Main interface methods

# A Section's only creation property is it's name
sub new {
	my $class = shift;
	my $name = Archive::Builder->_check( 'name', $_[0] ) ? shift
		: return $class->_error( 'Invalid section name format' );

	# Create the object
	my $self = bless {
		name   => $name,
		path   => $name,
		zfiles => {},
		}, $class;

	return $self;
}

# Get the name
sub name { $_[0]->{name} }

# Get or set the path
sub path {
	my $self = shift;
	return $self->{path} unless scalar @_;

	# Set the path
	my $path = Archive::Builder->_check( 'relative path', $_[0] ) ? shift
		: return undef;
	$self->{path} = $path;
	return 1;
}

# Test generate and cache all files
sub test {
	my $self = shift;

	# Generate each file
	foreach my $File ( $self->file_list ) {
		unless ( defined $File->contents ) {
			return $self->_error( "Generation failed for file '" . $File->path
				. "' in section '$self->{name}': "
				. $File->errstr );
		}
	}

	return 1;
}

# Save the entire section
sub save {
	my $self = shift;
	my $base = shift || '.';

	# Can we write to the base location
	unless ( File::Flat->canWrite( $base ) ) {
		return $self->_error( "Insufficient permissions to write below $base" );
	}

	# Save each of the files
	foreach my $File ( $self->file_list ) {
		my $filename = File::Spec->catfile( $base, $File->path );
		unless ( $File->save( $filename ) ) {
			return $self->_error( "Failed to save file '$filename' in Section '$self->{name}'" );
		}
	}

	return 1;
}

# Get the parent for the Section, if one exists
sub Builder { $_PARENT{refaddr $_[0]} }

# Delete this from from it's parent, and remove all our children
sub delete {
	my $self = shift;
	if ( $self->Builder ) {
		# Remove from our parent
		$self->Builder->remove_section( $self->path );
	}

	# Remove all our children
	foreach ( $self->file_list ) {
		delete $Archive::Builder::File::_PARENT{ refaddr $_ };
	}
	$self->{zfiles} = {};

	return 1;
}	

# If any files have been generated, flush the content cache
# so they will be generated again.
# Just pass the call down to the files.
sub reset { foreach ( $_[0]->file_list ) { $_->reset } 1 }

# Get an Archive for just this section
sub archive { Archive::Builder::Archive->new( $_[1], $_[0] ) }

# Get the archive content hash
sub _archive_content {
	my $self = shift;

	# Add from each of the Files
	my %tree = ();
	foreach my $File ( $self->file_list ) {
		my $contents = $File->contents or return undef;
		$tree{$File->path} = $contents;
	}

	return \%tree;
}





#####################################################################
# Working with files

# Add a new file and return it
sub new_file {
	my $self = shift;

	# Create the File
	my $File = Archive::Builder::File->new( @_ )
		or return undef;

	# Add the file
	return $self->add_file( $File ) ? $File : undef;
}

# Add a new file
sub add_file {
	my $self = shift;
	my $File = isa( $_[0], 'Archive::Builder::File' ) ? shift
		: return $self->_error( 'Did not pass a File as argument' );

	# Does the file clash with an existing one
	unless ( $self->_no_path_clashes( $File->path ) ) {
		return $self->_error( "Bad file path: " . $self->errstr );
	}

	# Add the File
	$self->{zfiles}->{$File->path} = $File;
	
	# Add it's parent reference
	$Archive::Builder::File::_PARENT{ refaddr $File } = $self;
	
	return 1;
}

# Get a copy of the hash of files
sub files { %{ $_[0]->{zfiles} } ? { %{ $_[0]->{zfiles} } } : 0 }

# Return the files as a List, sorted by file name
sub file_list {
	my $files = $_[0]->{zfiles};
	return map { $files->{$_} } sort keys %$files;
}

# Get a single file by name
sub file { $_[0]->{zfiles}->{$_[1]} }

# Remove a single file by name
sub remove_file {
	my $self = shift;
	my $name = $self->{zfiles}->{$_[0]} ? shift : return undef;
	my $File = $self->{zfiles}->{$name};

	# Delete from our files
	delete $self->{zfiles}->{$name};

	# Remove the parent link
	delete $Archive::Builder::File::_PARENT{ refaddr $File };

	return 1;
}

# Get a count of the number of files
sub file_count { scalar keys %{ $_[0]->{zfiles} } }

# Does a path clash with an existing path.
# A clash occurs if two paths are exactly the same,
# or a situation will occur where a file and directory
# of the same will would exist, which will fail on writing out
# to disk.
sub _no_path_clashes {
	my $self = shift;
	my $path = shift;

	# Iterate over the file paths
	foreach ( sort keys %{ $self->{zfiles} } ) {
		# Are they the same.
		if ( $path eq $_ ) {
			return $self->_error( "The file '$path' already exists" );
		}

		# Does our file already exist as a directory
		### THIS DOES NOT SUPPORT VMS...
		### I can't decifer File::Spec::VMS well enough
		my $directory_seperator = {
			MacOS   => ':',
			Win32   => '\\',
			dos     => '\\'
			}->{$0} || '/';
		if ( $_ =~ m!^$path$directory_seperator! ) {
			return $self->_error( "The file '$path' would clash with a directory of the same name" );
		}

		# Would the creation of our file involve a directory
		# that already exists as a file
		if ( $path =~ m!$_$directory_seperator! ) {
			return $self->_error( "The file '$path' would create a directory that clash with an existing file '$_'" );
		}
	}

	return 1;
}




#####################################################################
# Utility methods

# Pass through error
sub errstr { Archive::Builder->errstr }
sub _error { shift; Archive::Builder->_error(@_) }
sub _clear { Archive::Builder->_clear }

1;

__END__

=pod

The documentation for this class is part of L<Archive::Builder>.

=cut
