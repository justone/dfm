#!perl

use Test::More;
use strict;
use Cwd qw(getcwd);
use FindBin qw($Bin);

use Test::Trap qw/ :output(systemsafe) /;

require "$Bin/helper.pl";

my $file_slurp_available = load_mod('File::Slurp qw(read_file)');

check_minimum_test_more_version();

subtest 'single file or directory' => sub {
    focus('single');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    run_dfm( $home, $repo, 'import', 'newfile' );

    is_tracked_and_linked( $home, $repo, 'newfile' );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    is( length($status), 0, 'git working dir is clean' );
    like( $tracked, qr/newfile/,           'newfile is tracked' );
    like( $log,     qr/importing newfile/, 'commit message is correct' );

    subtest 'custom commit message' => sub {
        `echo "contents" > '$home/otherfile'`;

        run_dfm( $home, $repo, 'import', 'otherfile', '--message',
            'custom commit message' );

        is_tracked_and_linked( $home, $repo, 'otherfile' );

        my ( $tracked, $status, $log ) = inspect_repo($repo);

        is( length($status), 0, 'working directory clean' );
        like( $log, qr/custom commit message/, 'commit message is correct' );
    };

    subtest 'directory' => sub {
        `mkdir '$home/newdir'`;
        `echo "contents" > '$home/newdir/newfile'`;

        run_dfm( $home, $repo, 'import', 'newdir' );

        is_tracked_and_linked( $home, $repo, 'newdir' );

        my ( $tracked, $status, $log ) = inspect_repo($repo);

        is( length($status), 0, 'git working dir is clean' );
        like( $tracked, qr/newdir/,           'newdir is tracked' );
        like( $log,     qr/importing newdir/, 'commit message is correct' );
    };

    subtest 'symlink' => sub {
        `ln -s /tmp '$home/newlink'`;

        run_dfm( $home, $repo, 'import', 'newlink' );

        is_tracked_and_linked( $home, $repo, 'newlink' );

        my ( $tracked, $status, $log ) = inspect_repo($repo);

        is( length($status), 0, 'git working dir is clean' );
        like( $tracked, qr/newlink/,           'newlink is tracked' );
        like( $log,     qr/importing newlink/, 'commit message is correct' );
    };
};

subtest 'skip staged files' => sub {
    focus('staged_file');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    `echo "contents" > '$repo/otherfile'`;
    run_git( $repo, 'git add otherfile' );

    run_dfm( $home, $repo, 'import', 'newfile' );

    is_tracked_and_linked( $home, $repo, 'newfile' );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    like(
        $status,
        qr/A  otherfile/,
        'other staged file is still staged, not committed'
    );
};

subtest 'two files' => sub {
    focus('two_files');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;
    `echo "contents" > '$home/otherfile'`;

    run_dfm( $home, $repo, qw/import newfile otherfile/ );

    is_tracked_and_linked( $home, $repo, 'newfile' );
    is_tracked_and_linked( $home, $repo, 'otherfile' );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    is( length($status), 0, 'git working dir is clean' );
    like( $tracked, qr/newfile/,   'newfile is tracked' );
    like( $tracked, qr/otherfile/, 'otherfile is tracked' );
    like(
        $log,
        qr/importing newfile, otherfile/,
        'commit message is correct'
    );
    my @log_lines = split( /\n/, $log );
    cmp_ok( scalar @log_lines, '==', 2, 'only two log messages' );
};

subtest 'two files, one missing' => sub {
    focus('two_files_one_missing');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    run_dfm( $home, $repo, qw/import newfile otherfile/ );

    like(
        $trap->stdout,
        qr/otherfile not found/,
        'error message about file is present'
    );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    is( length($status), 0, 'git working dir is clean' );
    unlike( $tracked, qr/newfile/, 'newfile is not tracked' );
    unlike( $log, qr/importing/,
        'commit message contains no mention of importing' );
    my @log_lines = split( /\n/, $log );
    cmp_ok( scalar @log_lines, '==', 1, 'only one log messages' );
};

subtest 'full or relative paths to files' => sub {
    focus('odd_paths');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;
    `echo "contents" > '$home/otherfile'`;
    `ln -s /tmp '$home/newlink'`;
    `ln -s /usr '$home/newlink2'`;

    # change to another directory for testing relative paths
    `mkdir $home/dir`;
    chdir("$home/dir");

    run_dfm( $home, $repo, 'import', "$home/newfile", '../otherfile',
        '../newlink', "$home/dir/../newlink2", );

    is_tracked_and_linked( $home, $repo, 'newfile' );
    is_tracked_and_linked( $home, $repo, 'otherfile' );
    is_tracked_and_linked( $home, $repo, 'newlink' );
    is_tracked_and_linked( $home, $repo, 'newlink2' );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    is( length($status), 0, 'git working dir is clean' );
    like( $tracked, qr/newfile/,   'newfile is tracked' );
    like( $tracked, qr/otherfile/, 'otherfile is tracked' );
    like( $tracked, qr/newlink/,   'newlink is tracked' );
    like( $tracked, qr/newlink2/,  'newlink2 is tracked' );
    like(
        $log,
        qr/importing newfile, otherfile, newlink, newlink2/,
        'commit message is correct'
    );
    my @log_lines = split( /\n/, $log );
    cmp_ok( scalar @log_lines, '==', 2, 'only two log messages' );
};

subtest 'file in recursed directory' => sub {
    focus('recursed');

    my ( $home, $repo ) = minimum_home_with_ssh('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/.ssh/newfile'`;

    run_dfm( $home, $repo, 'import', '.ssh/newfile' );

    is_tracked_and_linked( $home, $repo, '.ssh/newfile',
        '../.dotfiles/.ssh/newfile' );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    is( length($status), 0, 'git working dir is clean' );
    like( $tracked, qr{\.ssh/newfile}, 'newfile is tracked' );
    like( $log, qr{importing \.ssh/newfile}, 'commit message is correct' );
    ok(1);
};

subtest 'no commit' => sub {
    focus('no_commit');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    run_dfm( $home, $repo, 'import', 'newfile', '--no-commit' );

    is_tracked_and_linked( $home, $repo, 'newfile' );

    my ( $tracked, $status, $log ) = inspect_repo($repo);

    like( $status, qr/A  newfile/, 'file is staged but not committed' );
};

subtest 'dry run' => sub {
    focus('dry_run');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    run_dfm( $home, $repo, '--dry-run', 'import', 'newfile' );

    ok( !-e "$repo/newfile", 'file not moved into repo' );
    ok( !-l "$home/newfile", 'file in homedir is a not a link' );
};

subtest 'fail on file that is already tracked' => sub {
    focus('already_tracked');

    my ( $home, $repo, $origin ) = minimum_home_with_ssh('host1');
    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    run_dfm( $home, $repo, 'import', 'newfile' );
    is_tracked_and_linked( $home, $repo, 'newfile' );

    run_dfm( $home, $repo, 'import', 'newfile', '--verbose' );

    like(
        $trap->stdout,
        qr/file newfile is already tracked/,
        'output contains indication that import was skipped'
    );

    subtest 'recursed file' => sub {

        `echo "contents" > '$home/.ssh/newfile'`;

        run_dfm( $home, $repo, 'import', '.ssh/newfile' );
        is_tracked_and_linked( $home, $repo, '.ssh/newfile',
            '../.dotfiles/.ssh/newfile' );

        run_dfm( $home, $repo, 'import', '.ssh/newfile' );

        like(
            $trap->stdout,
            qr/file .ssh\/newfile is already tracked/,
            'output contains indication that import was skipped'
        );
        ok(1);
    };
};

subtest 'fail on non-existant file' => sub {
    focus('non_existant');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    run_dfm( $home, $repo, 'import', 'newfile' );

    like( $trap->stdout, qr/not found/, 'correct error message' );
};

subtest 'fail for file that is not in $HOME' => sub {
    focus('fail_not_in_home');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    `mkdir -p '$Bin/notinhome'`;
    `echo "contents" > '$Bin/notinhome/newfile'`;
    run_dfm( $home, $repo, 'import', "$Bin/notinhome/newfile" );

    like( $trap->stdout, qr/not in your home/, 'correct error message' );
};

subtest 'fail for import $HOME' => sub {
    focus('fail_not_home');

    my ( $home, $repo, $origin ) = minimum_home('host1');
    run_dfm( $home, $repo, '--verbose' );

    run_dfm( $home, $repo, 'import', $home );

    like( $trap->stdout, qr/home directory itself/, 'correct error message' );
};

subtest 'fail for file that is in an untracked directory' => sub {
    focus('fail_untracked_dir');

    my ( $home, $repo, $origin ) = minimum_home_with_ssh('host1');
    run_dfm( $home, $repo, '--verbose' );

    `mkdir -p '$home/foo/bar'`;
    `echo "contents" > '$home/foo/bar/newfile'`;

    run_dfm( $home, $repo, 'import', 'foo/bar/newfile', '--verbose' );

    like(
        $trap->stdout,
        qr/is in a subdirectory that is not tracked/,
        'correct error message'
    );
    like(
        $trap->stdout,
        qr/consider using 'dfm import foo'/,
        'correct suggestion'
    );

    subtest 'recursed file' => sub {

        `mkdir '$home/.ssh/foo'`;
        `echo "contents" > '$home/.ssh/foo/newfile'`;

        run_dfm( $home, $repo, 'import', '.ssh/foo/newfile', '--verbose' );

        like(
            $trap->stdout,
            qr/is in a subdirectory that is not tracked/,
            'correct error message'
        );
        like(
            $trap->stdout,
            qr/consider using 'dfm import .ssh\/foo'/,
            'correct suggestion'
        );
    };
};

subtest 'fail for file that is in a tracked subdirectory' => sub {
    focus('fail_tracked_dir');

    my ( $home, $repo, $origin ) = minimum_home_with_ssh('host1');
    run_dfm( $home, $repo, '--verbose' );

    `mkdir '$home/foo'`;
    `echo "contents" > '$home/foo/newfile'`;

    run_dfm( $home, $repo, 'import', 'foo' );

    `echo "contents" > '$home/foo/otherfile'`;
    run_dfm( $home, $repo, 'import', 'foo/otherfile', '--verbose' );

    like(
        $trap->stdout,
        qr/is in a subdirectory that is already tracked/,
        'correct error message'
    );
    like(
        $trap->stdout,
        qr/consider using 'dfm add foo'/,
        'correct suggestion'
    );

    subtest 'recursed file' => sub {
        `mkdir '$home/.ssh/foo'`;
        `echo "contents" > '$home/.ssh/foo/newfile'`;

        run_dfm( $home, $repo, 'import', '.ssh/foo' );

        `echo "contents" > '$home/.ssh/foo/otherfile'`;
        run_dfm( $home, $repo, 'import', '.ssh/foo/otherfile', '--verbose' );

        like(
            $trap->stdout,
            qr/is in a subdirectory that is already tracked/,
            'correct error message'
        );
        like(
            $trap->stdout,
            qr/consider using 'dfm add .ssh\/foo'/,
            'correct suggestion'
        );

    };
};

subtest 'fail for file that is skipped' => sub {
    focus('fail_skipped');

    my ( $home, $repo, $origin )
        = minimum_home( 'host1', { dfminstall_contents => "newfile skip" } );

    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;

    run_dfm( $home, $repo, 'import', 'newfile' );

    like(
        $trap->stdout,
        qr/file newfile is skipped/,
        'correct error message'
    );
};

subtest 'fail for file in dotfiles repo' => sub {
    focus('fail_dotfiles_repo');

    my ( $home, $repo, $origin ) = minimum_home('host1');

    run_dfm( $home, $repo, '--verbose' );

    `echo "contents" > '$home/newfile'`;
    run_dfm( $home, $repo, 'import', 'newfile' );

    run_dfm( $home, $repo, 'import', '.dotfiles/newfile' );

    like( $trap->stdout, qr/is already tracked/, 'correct error message' );
};

done_testing;

sub run_git {
    my ( $repo_path, $command ) = @_;

    my $cwd_before = getcwd();
    chdir $repo_path;
    my $output = `$command`;
    chdir($cwd_before);

    return $output;
}

sub is_tracked_and_linked {
    my ( $home, $repo, $path, $link_target ) = @_;

    ok( -e "$repo/$path", 'file moved into repo' );
    ok( -l "$home/$path", 'file in homedir is a link' );
    is( readlink("$home/$path"),
        $link_target || ".dotfiles/$path",
        'symlink points to correct location'
    );
}

sub inspect_repo {
    my ($repo) = @_;

    my $tracked = run_git( $repo, 'git ls-files' );
    my $status  = run_git( $repo, 'git status --porcelain' );
    my $log     = run_git( $repo, 'git log --pretty=oneline' );

    return ( $tracked, $status, $log );
}
