require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Archive::Builder',
	'VERSION_FROM' => 'lib/Archive/Builder.pm',
	'PREREQ_PM'    => {
		Test::More    => 0,
		Class::Handle => 0.2,
		File::Spec    => 0.82,
		File::Flat    => 0.6,
		IO::Scalar    => 0,
		Archive::Tar  => 0,
	},	
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (adam@ali.as)',
		'ABSTRACT' => 'File tree generation and archiving framework',
	) : (),
);
