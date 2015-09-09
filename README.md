# Check Indent #

## About ##

Perl script that can be used to check the indention of source files.
The scripts can find the following issues:

- Mixed indent
- Check for spaces or tabs
- Trailing whitespaces

## Usage ##

    usage: check_indent.pl <options> -- <files|directories>

    options:
    -v, --verbose          : verbose output
    -t, --tabs             : tabs should be used for indention -> finds lines indented with spaces
    -s, --spaces           : spaces should be used for indention -> finds lines indented with tabs
    -c, --check            : checks whether mixed indention is used

    Notes: -t and -s cannot be used together.

## Author ##

Copyright (C) 2014-2015 Kurt Kanzenbach <kurt@kmk-computers.de>

## License ##

BSD 2-Clause License
