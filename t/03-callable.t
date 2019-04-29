use JSON::Path2;
use JSON::Fast;
use Test;

my %data = (
  a => {
    b => 5
  }
);
my $modifier = sub ($val) {
  $val *= 2;
};
my $modifier-rw = sub ($val is rw) {
  $val *= 2;
};

my $path = '$.a.b';
plan 3;

use Data::Dump;
filter-json($path, %data, :assign($modifier-rw));

ok %data<a><b> == 10, 'pass by ref to assignment can affect original object';

dies-ok { filter-json($path, %data, :assign($modifier)) }, 'dies trying to assign';

ok %data<a><b> == 10, 'pass by non-ref also works';


# vi:syntax=perl6
