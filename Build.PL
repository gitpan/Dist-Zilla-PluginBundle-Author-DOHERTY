
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "upload files to a Google Code project",
  "dist_author" => [
    "Fayland Lam <fayland\@gmail.com>",
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-PluginBundle-Author-DOHERTY",
  "dist_version" => "0.006",
  "license" => "perl",
  "module_name" => "Dist::Zilla::PluginBundle::Author::DOHERTY",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "HTTP::Request::Common" => 0,
    "LWP::Protocol::https" => 0,
    "LWP::UserAgent" => 0,
    "Scalar::Util" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
