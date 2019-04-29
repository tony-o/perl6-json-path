# JSON::Path

A pure perl JSON path implementation for perl6.

## Usage

```perl6
use JSON::Path;

my $jpath = '$.options';
my $json  = from-json( '{ "options": { "is-rad": true } }' );

# Get results from the json:
my $results = filter-json($jpath, $json);

#`[
[ { "is-rad" => True } ]
]

# Get paths from the json:
my $results = filter-json($jpath, $json, :want-path);

#`[
[ "options" ]
]

# Alter the json:
my $modifier = sub ($val is rw) {
  $val = !$val;
};
filter-json($jpath, $json, :assign($modifier));

#`[
$json before: {"options":{"is-rad":true}}
 $json after: {"options":{"is-rad":false}}
]
```
