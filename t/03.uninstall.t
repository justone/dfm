#!perl

use Test::More;
use strict;
use FindBin qw($Bin);
use English qw( -no_match_vars );

use Test::Trap qw/ :output(systemsafe) /;

require "$Bin/helper.pl";

# unset the repo env override so that test work properly
$ENV{'DFM_REPO'} = undef;

my $file_slurp_available = load_mod("File::Slurp qw(read_file)");

check_minimum_test_more_version();

my $profile_filename = ( lc($OSNAME) eq 'darwin' ) ? '.profile' : '.bashrc';

subtest 'uninstall dotfiles' => sub {
    focus('uninstall');

    my ( $home, $repo ) = minimum_home_with_ssh('uninstall');
    `touch $repo/.bashrc.load`;    # make sure there's a loader
    extra_setup($home);

    my $output;

    run_dfm( $home, $repo, 'install', '--verbose' );

    ok( -d "$home/.backup", 'main backup dir exists' );
    ok( -l "$home/bin",     'bin is a symlink' );

SKIP: {
        skip 'File::Slurp not found', 1 unless $file_slurp_available;

        ok( read_file("$home/$profile_filename") =~ /bashrc.load/,
            "loader present in $profile_filename" );
    }

    run_dfm( $home, $repo, 'uninstall', '--verbose' );

    ok( !-l "$home/bin",            'bin is no longer a symlink' );
    ok( -e "$home/bin/preexisting", 'bin from backup is restored' );
    ok( -l "$home/.other",          'other symlink still exists' );

    ok( !-l "$home/.ssh/config",            '.ssh/config is no longer a symlink' );
    ok( -e "$home/.ssh/config/preexisting", '.ssh/config from backup is restored' );

SKIP: {
        skip 'File::Slurp not found', 1 unless $file_slurp_available;

        ok( read_file("$home/$profile_filename") !~ /bashrc.load/,
            "loader absent in $profile_filename" );
    }
};

subtest 'uninstall dotfiles (with .shellrc.load)' => sub {
    focus('uninstall_shellrc');

    my ( $home, $repo ) = minimum_home_with_ssh('uninstall');
    `touch $repo/.shellrc.load`;    # make sure there's a loader
    extra_setup($home);

    my $output;

    run_dfm( $home, $repo, 'install', '--verbose' );

    ok( -d "$home/.backup", 'main backup dir exists' );
    ok( -l "$home/bin",     'bin is a symlink' );

SKIP: {
        skip 'File::Slurp not found', 1 unless $file_slurp_available;

        ok( read_file("$home/$profile_filename") =~ /shellrc.load/,
            "loader present in $profile_filename" );
    }

    run_dfm( $home, $repo, 'uninstall', '--verbose' );

    ok( !-l "$home/bin",            'bin is no longer a symlink' );
    ok( -e "$home/bin/preexisting", 'bin from backup is restored' );
    ok( -l "$home/.other",          'other symlink still exists' );

    ok( !-l "$home/.ssh/config",            '.ssh/config is no longer a symlink' );
    ok( -e "$home/.ssh/config/preexisting", '.ssh/config from backup is restored' );

SKIP: {
        skip 'File::Slurp not found', 1 unless $file_slurp_available;

        ok( read_file("$home/$profile_filename") !~ /shellrc.load/,
            "loader absent in $profile_filename" );
    }
};

subtest 'uninstall dotfiles (dry-run)' => sub {
    focus('uninstall_dry');

    my ( $home, $repo ) = minimum_home_with_ssh('uninstall');
    `touch $repo/.bashrc.load`;    # make sure there's a loader
    extra_setup($home);

    my $output;

    run_dfm( $home, $repo, 'install', '--verbose' );

    ok( -d "$home/.backup", 'main backup dir exists' );
    ok( -l "$home/bin",     'bin is a symlink' );

subtest 'exec-uninstall option' => sub {
    focus('exec_uninstall_option');

    my ( $home, $repo, $origin );
    ( $home, $repo, $origin )
        = minimum_home( 'exec-uninstall option',
        { dfminstall_contents => "script1.sh exec-uninstall\nscript1.sh skip\ntest2 recurse" } );

    # set up non-recurse script that needs to be set executable
    `echo "#!/bin/sh\n\necho 'message1';\ntouch testfile" > '$repo/script1.sh'`;

    # set up recurse script that is already executable
    `mkdir -p '$repo/test2'`;
    `echo "script2.sh exec-uninstall" > '$repo/test2/.dfminstall'`;
    `echo "#!/bin/sh\n\necho 'message2';\ntouch testfile2" > '$repo/test2/script2.sh'`;
    `chmod +x '$repo/test2/script2.sh'`;

    run_dfm( $home, $repo, 'install', '--verbose' );

    unlike( $trap->stdout, qr/message1/, 'output does not contain output from script1' );
    ok( !-e "$home/testfile",   'file created by script1 does not exist' );
    ok( !-e "$home/script1.sh", 'script1 is not symlinked into home' );;

    unlike( $trap->stdout, qr/message2/, 'output does not contain output from script2' );
    ok( !-e "$home/test2/testfile2",  'file created by script2 does not exist' );

    run_dfm( $home, $repo, 'uninstall', '--verbose' );

    like( $trap->stdout, qr/message1/, 'output contains output from script1' );
    ok( -e "$home/testfile",    'file created by script1 exists' );
    ok( !-e "$home/script1.sh", 'script1 is not symlinked into home' );
    ok( -x "$repo/script1.sh",  'script1 file is executable' );

    like( $trap->stdout, qr/message2/, 'output contains output from script2' );
    ok( -e "$home/test2/testfile2",  'file created by script2 exists' );
    ok( -x "$repo/test2/script2.sh", 'script2 file is executable' );
};

SKIP: {
        skip 'File::Slurp not found', 1 unless $file_slurp_available;

        ok( read_file("$home/$profile_filename") =~ /bashrc.load/,
            "loader present in $profile_filename" );
    }

    run_dfm( $home, $repo, 'uninstall', '--dry-run', '--verbose' );

    ok( -l "$home/bin", 'bin is still a symlink' );

    ok( -l "$home/.ssh/config", '.ssh/config is still a symlink' );

SKIP: {
        skip 'File::Slurp not found', 1 unless $file_slurp_available;

        ok( read_file("$home/$profile_filename") =~ /bashrc.load/,
            "loader still exists in $profile_filename"
        );
    }
};

done_testing;

sub extra_setup {
    my $home = shift;

    symlink( "/anywhere/else", "$home/.other" );
    mkdir("$home/.backup");
    mkdir("$home/.backup/bin");
    mkdir("$home/.backup/bin/preexisting");
    mkdir("$home/.ssh/.backup");
    mkdir("$home/.ssh/.backup/config");
    mkdir("$home/.ssh/.backup/config/preexisting");
}
