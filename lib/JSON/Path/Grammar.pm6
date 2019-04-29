#use Grammar::Tracer::Compact;
grammar JSON::Path::Grammar {
  token TOP {
    ^ '$' <notation>+ % '.' $
  }

  token notation {
    [
         <dot> <func> '('\s*')'
      |  <dot> <expr>
      |  <dot>? '[' (
          <wild>
        | \' <ident> ** {1..∞} % '\',\'' \'
        
        )
        ']' <filter> ** 0..1
    ]
    <notation>*
    { make $/.made }
  }

  token func {
      'length'
    | 'stddev'
    | 'avg'
    | 'max'
    | 'min'
    { make $/.Str }
  }

  token dot {
      '.'
    | '..'
    { make $/.Str }
  }

  token wild {
    '*'
    { make '*'.Str }
  }

  token expr {
    <ident> <filter> ** 0..1
    { make $/.made }
  }

  token filter {
      '[?'\s*'(' \s* [<nest-filter>|<bare-filter>]+ % <logic> \s* ')'\s*']'
    | '[' <slice> ']'      #slice
    | '[' <indices> ']'    #indices
    { make $/.made }
  }

  token nest-filter {
    \s* '(' \s* <bare-filter>+ % <logic> \s* ')' \s*
  }
  token bare-filter {
    \s* <query> \s*
  }

  regex query {
     '*'
    | <lhs> \s* <op> \s* <rhs>
    | <lhs>
#    { make $/.made }
  }

  token ident {
    <- [.\[\-\>\<\=\&\|\'\?\s]>+
    { make $/.Str }
  }

  token int {
    \d+
    { make $/.Int }
  }

  token rhs {
      "'" <ident> "'"
    | <int>
    | '[' \' <ident> ** {1..∞} % '\',\'' '\']'
    { make $/.made }
  }

  token lhs {
    '@.' [<func> '('\s*')' | <ident>]
    { make $/.made }
  }

  token slice {
    <slice-from> ':' <slice-to>
    { make $/.made }
  }

  token indices {
    <int>+ % ','
  }

  token slice-from { \d+ { make $/.Int } }
  token slice-to   { \d+ { make $/.Int } }

  token logic {
      '||'
    | '&&'
    { make $/.Str }
  }

  regex op {
      '>'
    | '<'
    | '=='
    | '-'
    | '!='
    | '<='
    | '>='
    | '=~'
    | \s+ 'in' \s+
    | \s+ 'subsetof' \s+
    | \s+ 'size' \s+
    | \s+ 'empty' \s+
    { make $/.Str.trim }
  }
}
