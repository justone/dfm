# v0.7 (unreleased)

* dotfiles repository can now be outside of home directory, using $DFM_REPO
* add help subcommand and refactor help handling
* make 'help' the default subcommand (seth--)
* better parsing of arguments to preserve all arguments passed through to git subcommands

# v0.6 2012-09-30

* Added import subcommand to add new files.
* dfm can now be run from outside the dotfiles repository.
* dfm can adjust permissions on install (see 'chmod' option).
* dfm can run scripts on install (see 'exec' option). (seth--)
* Allow using regular .bashrc instead of .bashrc.load.
* Better tracking of upstream dotfiles branch for fetching updates. (Nate Parsons)
* Fixed bug where multiple recursed files would create invalid symlinks. (Jeremiah Snapp)
* Recursion should now be explicitly specified.  Implied recursion is deprecated.
* Now, even the bin directory can be recursed into.

# v0.5 2011-10-04

* Added updatemergeandinstall (or umi) subcommand to get latest dotfiles
  changes in one command.
* Clean up dangling symlinks.
* Added uninstall subcommand to remove dotfiles.
* More tests.
* Internal code refactoring for maintainability.

# v0.4 2011-08-24

* More tests.
* Use .profile on OSX (David Bartle)
* Skip empty lines in .dfminstall (Dani Perez)

# v0.3 2010-10-15

* Original public release.
