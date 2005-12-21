#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Module::API');
}

diag("Testing Module::API $Module::API::VERSION, Perl $], $^X");
