class JSON::Stream::Actions {
  method TOP ($/) {
    make $_ for $/.keys.map({ make $/{$_}.made; });
  }

  method key($/) {
    make $<str>;
  }

  method pair($/) {
    make Pair.new($<key><str>.made , $<value>.made);
  }

  method value($/) {
    make $_ for $/[0].keys.map({ make $/[0]{$_}.made; });
  }

  method array($/) {
    make [
      |$<value>.map({ make $_.made }),
    ];
  }
  
  method obj($/) {
    make %(
      $_.made for |$<pair>,
    );
  }

  method value-str($/) {
    make $<str>.made;
  }

  method str($/) {
    make $/.Str;
  }

  method value-num($/) {
    make $/.Num;
  }

  method value-nil($/) {
    make Nil;
  }
}
