use Bench;
use JSON::Path;
use JSON::Path2;
use JSON::Path::CountryGrammar;
use JSON::Path::Grammar;
use JSON::Fast;

my Bench $b .=new;

my $data = from-json '{ "options": [ { "code": "AB2", "quantity": 5 }, { "code": "AB1", "quantity": 2 }, { "code": "AB1", "quantity": 5 }, { "code": "AL", "quantity": -1 } ] }';
my $path = '$.options.quantity';
#my $jpath = JSON::Path.new('$.foo[0]');
my $object = {
  'foo' => [
    {
        'bar' => 1,
    },
    {
        'bar' => 2,
    },
    {
        'bar' => 3,
    },
  ]
};

my $jp = JSON::Path::Grammar.parse($path);
my $jp2 = JSON::Path::CountryGrammar.parse($path).made;
$b.cmpthese((@*ARGS[0]//100000).Int, {
  to2-parse => sub {
    JSON::Path::CountryGrammar.parse($path);
  },
  to1-parse => sub {
    JSON::Path::Grammar.parse($path);
  },
});
$b.cmpthese((@*ARGS[0]//100000).Int, {
  to2-perform => sub {
    filter-json2($jp2, $object);
  },
  to1-perform => sub {
    filter-json($jp, $object);
  },
});
