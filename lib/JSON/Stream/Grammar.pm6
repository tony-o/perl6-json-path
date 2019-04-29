grammar JSON::Stream::Grammar {
  token TOP {
    ^ \s* <pair>|<value> \s* $
  }

  token obj {
      '{' <pair> [\s* \, \s* <pair> \s*]* '}'
    | '{' \s* '}'
  }

  token array {
      '[' <value> [\s* \, \s* <value> \s*]* ']'
    | '[' \s* ']'
  }

  token pair {
    <key> ':' <value>
  }

  regex key {
    \s* '"' <str> '"' \s*
  }

  regex str {
    ('\\"'|.)+?
    <before \">
  }

  token value {
    \s* (<value-str>|<value-num>|<value-nil>|<obj>|<array>) \s*
  }

  token value-str {
    '"' <str> '"'
  }

  token value-num {
    \d+
  }

  token value-nil {
    'null'
  }
}
