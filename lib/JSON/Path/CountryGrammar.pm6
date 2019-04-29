#use Grammar::Tracer::Compact;
grammar JSON::Path::CountryGrammar {
  token TOP {
    ^ '$' <notation> $
    { make $<notation>.made }
  }

  token notation {
    [
      | <dot> <ident> ** 1 # dot then ident
      | <dot>? '[' (
            $<ident>='*'
          | \' <ident> ** {1..Inf} % (\' \s* \, \s* \') \'
        ) ']'
    ] [<filter>|<slice>|<indices>] ** 0..1
    <notation> ** 0..1
    { 
      my %val = (identities => (make @( ($/[0]<ident>//$<ident>).map({ $_.made//$_.Str }))));
      %val<dot>      = (make $<dot>.made // '.');
      %val<filter>   = (make $<filter>[0].made) if $<filter>[0];
      %val<filter>   = (make $<slice>[0].made) if $<slice>[0];
      %val<filter>   = (make $<indices>[0].made) if $<indices>[0];
      %val<notation> = (make $<notation>[0].made) if $<notation>[0];
      make %val;
    }
  }

  token dot    { ['..'|'.'] { make $/.Str.trim } }
  token ident  { <- [.\[\-\>\<\=\&\|\'\?\s]>+ { make $/.Str } }

  token filter {
    '[?' \s* <nest> ** 1 \s* ']'
    {
      make $<nest>[0].made;
    }
  }

  token nest {
    '(' \s* $<filters>=(<nest>|<bare>)+ % <logic> \s* ')'
    {
      my (@x, @l);
      @l.push: make $_.made for $<logic>;
      for $<filters> -> $filter {
        @x.push: make $filter<bare>.made if $filter<bare>;
        @x.push: make $filter<nest>.made if $filter<nest>;
      }
      make { statements => @x, logic => @l };
    }
  }

  token bare {
    \s* ($<lhs>=<fexpr> \s* <op> \s* $<rhs>=<fexpr> | $<lhs>=<fexpr>) \s*
    { 
      make ($/[0]<rhs> 
      ?? %(
        lhs => (make $/[0]<lhs>.made),
        op  => (make $/[0]<op>.made),
        rhs => (make $/[0]<rhs>.made),
      )
      !! %( lhs => ( make $/[0]<lhs>.made), ));
    }
  }
  token fexpr {
    [
        $<int>=('-' ** 0..1 \d+)
      | $<str>=(\' <ident> \')
      | $<str>=(\" <ident> \")
      | $<property>=('@.' <ident> )
      | $<array>=( '[' \s* \' <ident> ** {1..Inf} % (\'\s*','\s*\') \' \s* ']')
    ]
    {
      my %r;
      if $<int> { %r<type> = 'int'; %r<val> = $<int>.Int; }
      if $<str> { %r<type> = 'str'; %r<val> = $<str><ident>.Str; }
      if $<array> { %r<type> = 'array'; %r<val> = |make $<array><ident>.map({ $_.made }); }
      if $<property> { %r<type> = 'property'; %r<val> = make $<property>.Str.substr(2); }
      make %r;

    }
  }
  token op {
    [
        '=='
      | '<'
      | '<='
      | '>'
      | '>='
      | '-'
      | '!='
      | '=~'
      |  'in' 
      |  'subsetof' 
      |  'size' 
      |  'empty' 
    ]
    { make $/.Str.trim; }
  }
  token logic {
    \s*('&&'|'||') \s*
    { make $/[0].Str.trim; }
  }
  token slice {
    '[' \s* $<from>=('-' ** 0..1 \d+) ** 0..1 \s* ':' \s* $<to>=('-' ** 0..1 \d+) ** 0..1 \s* ']'
    {
      die "{$/.orig}\n{('=' x $/.from) ~ '^'}\n  array slice must contain at least one number"
        if ! $<from>[0].defined && !$<to>[0].defined;
      make %(
        from => $<from>[0] ?? $<from>[0].Int !! Nil,
        to   => $<to>[0] ?? $<to>[0].Int !! Nil,
      )
    }
  }
  token indices {
    '[' \s* ('-' ** 0..1 \d+)+ % (\s*','\s*) \s* ']'
    {
      my @indices;
      @indices.push: $_.Int for $/[0];
      make @indices;
    }
  }
};
