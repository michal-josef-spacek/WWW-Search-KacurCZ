use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WWW::Search::KacurCZ;

# Test.
is($WWW::Search::KacurCZ::VERSION, 0.03, 'Version.');
