require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Archive::Builder',
	'VERSION_FROM' => 'lib/Archive/Builder.pm',
	'PREREQ_PM'    => {
		# Needed by Archive Builder
		'File::Spec'       => '0.82',
		'File::Flat'       => '0.92',
		'Class::Autouse'   => '1.04',
		'Class::Inspector' => '1.06',
		'IO::Scalar'       => '2.104',
		'IO::Zlib'         => '0',
		'List::Util'       => '1.11',

		# Needed by tests
		'Test::More'       => '0.47',
		'Test::ClassAPI'   => '1.02',
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'In-memory file tree and archive generation framework',
	) : (),
);
