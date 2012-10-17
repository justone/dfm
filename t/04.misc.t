#!perl

use Test::More;
use strict;
use FindBin qw($Bin);

use Test::Trap qw/ :output(systemsafe) /;

require "$Bin/helper.pl";

# unset the repo env override so that test work properly
$ENV{'DFM_REPO'} = undef;

my $version = '0.6';

check_minimum_test_more_version();

subtest 'help works on all subcommands' => sub {
    focus('help');

    my ( $home, $repo ) = minimum_home('help');

    foreach my $command (
        qw(install mergeandinstall mi updatemergeandinstall umi updates import im uninstall un)
        )
    {
        run_dfm( $home, $repo, 'help', $command );
        like(
            $trap->stdout,
            qr/All Options/ms,
            "all options section for $command"
        );
        like( $trap->stdout, qr/Examples/ms,
            "examples section for $command" );
        like( $trap->stdout, qr/Description/ms,
            "description section for $command" );
    }
};

subtest 'version commandline flag' => sub {
    focus('version');

    my ( $home, $repo ) = minimum_home('version');

    run_dfm( $home, $repo, '--version' );
    like( $trap->stdout, qr/dfm version $version/msi, "version output ok" );
};

done_testing;
