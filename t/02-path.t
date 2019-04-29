use JSON::Path2;
use JSON::Fast;
use Test;

my @lines = |'t/xest.x'.IO.slurp.lines;
my @jsons = |'t/xest.j'.IO.slurp.lines.map({ from-json($_) });
my @expec = |'t/xest.p'.IO.slurp.lines.map({ from-json($_) });

plan @expec.elems;

for ^@lines.elems -> $ln {
  is-deeply filter-json(@lines[$ln], @jsons[$ln], :want-path).sort, @expec[$ln].sort, "#{$ln+1}: {@lines[$ln]}";
}

# vi:syntax=perl6
