package App::Dotfiles::Manager;
use 5.008005;
use strict;
use warnings;

our $VERSION = "v0.7.4";

1;
__END__

=encoding utf-8

=head1 NAME

dfm - a utility to manage dotfiles

=head1 SYNOPSIS

dfm is a small utility that manages dotfiles.  It:

=over 4

=item * makes it easy to install (and uninstall) your dotfiles on new servers

=item * easys fetching and merging changes that were pushed from other machines

=item * simplifies working with your dotfiles repository, no matter where your current directory is

=back

=head1 DESCRIPTION

dfm works best when it's included in your dotfiles repository.  If you don't
have a dotfiles repository already, you can use
L<this starter repository|https://github.com/justone/dotfiles>.

=head1 SEE ALSO

For more information, check out the L<wiki|http://github.com/justone/dotfiles/wiki>.

You can also run C<dfm --help>.

=head1 LICENSE

Copyright (C) Nate Jones.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nate Jones E<lt>nate@endot.orgE<gt>

=cut
