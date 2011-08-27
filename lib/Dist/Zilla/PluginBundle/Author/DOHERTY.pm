package Dist::Zilla::PluginBundle::Author::DOHERTY;
# ABSTRACT: configure Dist::Zilla like DOHERTY
use strict;
use warnings;
our $VERSION = 'v0.22'; # VERSION


# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 4.102341; # dzil authordeps
use Dist::Zilla::Plugin::CheckChangesHasContent         qw();
use Dist::Zilla::Plugin::CheckExtraTests                qw();
use Dist::Zilla::Plugin::Clean                          qw();
use Dist::Zilla::Plugin::CopyFilesFromBuild             qw(); # to copy specified files
use Dist::Zilla::Plugin::Git::Check                     qw();
use Dist::Zilla::Plugin::Git::Commit                    qw();
use Dist::Zilla::Plugin::GitHub                    0.13 qw(); # Support for pointing to parent forks
use Dist::Zilla::Plugin::Git::NextVersion               qw();
use Dist::Zilla::Plugin::Git::Tag              1.112380 qw(); # Support for signed tags
use Dist::Zilla::Plugin::InstallGuide                   qw();
use Dist::Zilla::Plugin::InstallRelease           0.006 qw(); # to detect failed installs
use Dist::Zilla::Plugin::MinimumPerl              1.003 qw(); # to ignore non-perl files
use Dist::Zilla::Plugin::OurPkgVersion                  qw();
use Dist::Zilla::Plugin::PodWeaver                      qw();
use Dist::Zilla::Plugin::ReadmeFromPod                  qw();
use Dist::Zilla::Plugin::SurgicalPodWeaver       0.0015 qw(); # to avoid circular dependencies
use Dist::Zilla::Plugin::Twitter                  0.010 qw(); # Support for choosing WWW::Shorten::$site via WWW::Shorten::Simple
use Dist::Zilla::PluginBundle::TestingMania       0.009 qw(); # better deps tree & PodLinkTests; ChangesTests
use Pod::Weaver::PluginBundle::Author::DOHERTY    0.004 qw(); # new name
use Pod::Weaver::Section::BugsAndLimitations   1.102670 qw(); # to read from D::Z::P::Bugtracker
use WWW::Shorten::IsGd                                  qw(); # Shorten with WWW::Shorten::IsGd
use WWW::Shorten::Googl                                 qw();

with 'Dist::Zilla::Role::PluginBundle::Easy';


sub configure {
    my $self = shift;

    my $conf = do {
        my $defaults = {
            changelog       => 'Changes',
            twitter         => 1,
            version_regexp  => '^(v?.+)$',
            tag_format      => '%v%t',
            fake_release    => 0,
            surgical        => 0,
            push_to         => 'origin',
        };
        my $config = $self->config_slice(
            'version_regexp',
            'tag_format',
            'changelog',
            'fake_release',
            'twitter',
            'surgical',
            'critic_config',
            'push_to',
            { enable_tests  => 'enable'  },
            { disable_tests => 'disable' },
        );
        $defaults->merge($config);
    };
    my @dzil_files_for_scm = qw(Makefile.PL Build.PL README);

    $self->add_plugins(
        # Version number
        [ 'Git::NextVersion' => { version_regexp => $conf->{version_regexp} } ],
        'OurPkgVersion',

        # Gather & prune
        'GatherDir',
        [ 'PruneFiles' => { filenames => \@dzil_files_for_scm } ], # Required by CopyFilesFromBuild
        'PruneCruft',
        'ManifestSkip',

        # Generate dist files & metadata
        'ReadmeFromPod',
        'License',
        'MinimumPerl',
        'AutoPrereqs',
        'GitHub::Meta',
        'MetaJSON',
        'MetaYAML',

        # File munging
        ( $conf->{surgical}
            ? [ 'SurgicalPodWeaver' => { config_plugin => '@Author::DOHERTY' } ]
            : [ 'PodWeaver'         => { config_plugin => '@Author::DOHERTY' } ]
        ),

        # Build system
        'ExecDir',
        'ShareDir',
        'MakeMaker',
        'ModuleBuild',

        # Manifest stuff must come after generated files
        'Manifest',

        # Before release
        [ 'CheckChangesHasContent' => { changelog => $conf->{changelog} } ],
        [ 'Git::Check' => {
            changelog => $conf->{changelog},
            allow_dirty => [$conf->{changelog}, @dzil_files_for_scm],
        } ],
        'TestRelease',
        'CheckExtraTests',
        'ConfirmRelease',

        # Release
        ( $conf->{fake_release} ? 'FakeRelease' : 'UploadToCPAN' ),

        # After release
        [ 'CopyFilesFromBuild' => { copy => \@dzil_files_for_scm } ],
        [ 'NextRelease' => {
            filename => $conf->{changelog},
            format => '%-9v %{yyyy-MM-dd}d',
        } ],
        [ 'Git::Commit' => {
            allow_dirty => [$conf->{changelog}, @dzil_files_for_scm],
            commit_msg => 'Released %v%t',
        } ],
        [ 'Git::Tag' => {
            tag_format  => $conf->{tag_format},
            tag_message => "Released $conf->{tag_format}",
            signed      => 1,
        } ],
        [ 'Git::Push' => { push_to => $conf->{push_to} } ],
        [ 'GitHub::Update' => { metacpan => 1 } ],
    );
    $self->add_plugins([ 'Twitter' => {
            hash_tags => '#perl #cpan',
            url_shortener => 'Googl',
            tweet_url => 'https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}/',
        } ]) if ($conf->{twitter} and not $conf->{fake_release});

    $self->add_bundle(
        'TestingMania' => {
            enable          => $conf->{enable},
            disable         => $conf->{disable},
            changelog       => $conf->{changelog},
            critic_config   => $conf->{critic_config},
        }
     );

    $self->add_plugins(
        'InstallRelease',
        'Clean',
    );
}


__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::DOHERTY - configure Dist::Zilla like DOHERTY

=head1 VERSION

version v0.22

=head1 SYNOPSIS

    # in dist.ini
    [@Author::DOHERTY]

=head1 DESCRIPTION

C<Dist::Zilla::PluginBundle::Author::DOHERTY> provides shorthand for
a L<Dist::Zilla> configuration that does what Mike wants.

=head1 USAGE

Just put C<[@Author::DOHERTY]> in your F<dist.ini>. You can supply the following
options:

=over 4

=item *

C<fake_release> specifies whether to use C<L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>>
instead of C<< L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> >>.

Default is false.

=item *

C<enable_tests> is a comma-separated list of testing plugins to add
to C<< L<TestingMania|Dist::Zilla::PluginBundle::TestingMania> >>.

Default is none.

=item *

C<disable_tests> is a comma-separated list of testing plugins to skip in
C<< L<TestingMania|Dist::Zilla::PluginBundle::TestingMania> >>.

Default is none.

=item *

C<tag_format> specifies how a git release tag should be named. This is
passed to C<< L<Git::Tag|Dist::Zilla::Plugin::Git::Tag> >>.

Default is C< %v%t >.

=item *

C<version_regexp> specifies a regexp to find the version number part of
a git release tag. This is passed to
C<< L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion> >>.

Default is C<< ^(v.+)$ >>.

=item *

C<twitter> says whether releases of this module should be tweeted.

Default is true.

=item *

C<surgical> says to use L<Dist::Zilla::Plugin::SurgicalPodWeaver>.

Default is false.

=item *

C<changelog> is the filename of the changelog.

Default is F<Changes>.

=item *

C<push_to> is the git remote to push to; can be specified multiple times.

Default is C<origin>.

=back

=head1 SEE ALSO

C<L<Dist::Zilla>>

=for Pod::Coverage configure

=head1 AVAILABILITY

The project homepage is L<http://p3rl.org/Dist::Zilla::PluginBundle::Author::DOHERTY>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Author-DOHERTY/>.

The development version lives at L<http://github.com/doherty/Dist-Zilla-PluginBundle-Author-DOHERTY>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-PluginBundle-Author-DOHERTY.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-PluginBundle-Author-DOHERTY>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-PluginBundle-Author-DOHERTY.git>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<https://github.com/doherty/Dist-Zilla-PluginBundle-Author-DOHERTY/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

