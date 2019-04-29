use Grammar::Tracer::Compact;
grammar X {
  token TOP {
    ^ '[?'\s* <nest> ** 1 \s* ']'
    {
      make $<nest>[0].made;
    }
  }

  token logic {
    \s* ('||'|'&&') \s*
    { make $/[0].Str.trim; }
  }

  token nest {
    '('\s* $<filters>=(<nest>|<bare>)+ % <logic> \s* ')'
    {
      my (@x, @l);
      my $i = 0;
      for $<logic> -> $logic {
        @l.push: make $logic.made;
      }
      for $<filters> -> $filter {
        if $filter<bare> {
          @x.push: make $filter<bare>.made;
          next;
        }
        if $filter<nest> {
          @x.push: make $filter<nest>.made;
          next;
        }
      }
      make {
        filters => @x,
        logic   => @l,
      };
    }
  }

  token bare {
    $<lhs>=<expr> \s* <op> \s* $<rhs>=<expr>
    {
      make %(
        lhs => (make $<lhs>.made),
        op  => (make $<op>.made),
        rhs => (make $<rhs>.made),
      )
    }

  }

  token expr {
    \d+
    { make $/.Int }
  }

  token op {
    '=='
    { make $/.Str.trim }
  }
}

(my $path = @*ARGS[0]) ~~ s:g/\"/\'/;
say 'PATH: ' ~ $path;
say X.parse($path).made;

# vi:syntax=perl6
