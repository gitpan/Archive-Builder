require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Archive::Builder',
	'VERSION_FROM' => 'lib/Archive/Builder.pm',
	'PREREQ_PM'    => {
		# Need by Archive Builder
		Class::Autouse   => 0.7,
		File::Spec       => 0.83,
		File::Flat       => 0.6,
		Class::Inspector => 1,
		IO::Scalar       => 2.104,
		IO::Zlib         => 0,
		Scalar::Util     => 1.11,

		# Needed by tests
		Test::More       => 0,
		Class::Handle    => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'File tree generation and archiving framework',
	) : (),
);
