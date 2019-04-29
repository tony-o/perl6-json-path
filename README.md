# JSON::Path

A pure perl JSON path implementation for perl6.

## Implementation

This module implements most of the spec outlined [here](https://goessner.net/articles/JsonPath/)

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

## Note on Usage

### `use`

If you have `JSON::Path` from Jonathan Worthington installed then you can load/use either one with the following.

```perl6
# this module
use JSON::Path:auth<tonyo>

# Jonathan's, this doesn't work with his latest version because "auth" was removed from his META, the best bet at
# the time of writing this just a plain `use JSON::Path`
use JSON::Path:auth<jnthn>
```

## Note on WHY?

This module differs from the one jnthn wrote in that it implements the `[?()]` filter spec. The reason for not contributing to his module is that this is written for `zef` and would like to use code we've written to keep the install process for zef as efficient and depends-less as possible.
