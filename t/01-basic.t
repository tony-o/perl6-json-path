use JSON::Path;
use JSON::Fast;
use Test;

my @lines = |'t/xest.x'.IO.slurp.lines;
my @jsons = |'t/xest.j'.IO.slurp.lines.map({ from-json($_) });
my @expec = |'t/xest.r'.IO.slurp.lines.map({ from-json($_) });

plan @expec.elems;

for ^@lines.elems -> $ln {
  is-deeply filter-json(@lines[$ln], @jsons[$ln]).sort, @expec[$ln].sort, "line {$ln+1}: {@lines[$ln]}";
}

# vi:syntax=perl6
