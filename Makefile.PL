require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Archive::Builder',
	'VERSION_FROM' => 'lib/Archive/Builder.pm',
	'PREREQ_PM'    => {
		# Need by Archive Builder
		Class::Autouse   => 0.7,
		File::Spec       => 0.82,
		File::Flat       => 0.6,
		Class::Inspector => 0,
		IO::Scalar       => 0,

		# Needed by tests		
		Test::More       => 0,
		Class::Handle    => 0,
	},	
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (adam@ali.as)',
		'ABSTRACT' => 'File tree generation and archiving framework',
	) : (),
);
