use JSON::Path::Grammar;
unit module JSON::Path;
# returns true if item should be filtered out
sub filter(Grammar $filter, $obj, :$idx?, :$level? = 0 --> Bool:D) {
  if $filter<indices> {
    my @indices = $filter<indices><int>.map({ .Int });
    return @indices.grep($idx).elems ?? True !! False;
  } elsif $filter<slice> {
    my $from = $filter<slice><slice-from>.Int;
    my $to   = $filter<slice><slice-to>.Int;
    return $from <= $idx && $idx < $to;
  }

  my @nest = |@($filter<nest-filter>.grep({ .so }));
  my @bare = |@($filter<bare-filter>.grep({ .so }));
  my @logi = |@($filter<logic>.grep({ .so }));
  my @res;
  
  @res.push: filter($_, $obj, :$idx, :level($level+1)) for @nest;

  my @bare-queries = @bare.map({ $_<query> });

  my ($lhs, $rhs, $op);
  for @bare-queries -> $q {
    if ($q<lhs>.Str//'') ~~ /^'@.'/ {
      if ($q<lhs><ident>//'') ~~ /'('\s*')'\s*$/ || $q<lhs><func> {
        if ($q<lhs><ident>//$q<lhs><func>).Str ~~ /^'length'/ {
          if $obj !~~ Array {
            @res.push(False);
            next;
          }
          $lhs = $obj.elems;
        } else {
          die "{$q<lhs><ident>.Str} function not supported in filter";
        }
      } else {
        $lhs = $obj{$q<lhs><ident>}//Nil;
      }
    } else {
      $lhs = $q<lhs><ident>||$q<lhs><int>;
    }
    if ($q<rhs>.Str//'') ~~ /^'@.'/ {
      $rhs = $obj{$q<rhs><ident>}//Nil;
    } else {
      $rhs = $q<rhs><ident>||$q<rhs><int>;
    }
    $op = $q<op>.Str.trim;
    given $op {
      when '==' {
        @res.push: $lhs eq $rhs;
      }
      when '>' {
        @res.push: $lhs gt $rhs;
      }
      when '>=' {
        @res.push: $lhs ge $rhs;
      }
      when '!=' {
        @res.push: $lhs ne $rhs;
      }
      when '<' {
        @res.push: $lhs lt $rhs;
      }
      when '<=' {
        @res.push: $lhs le $rhs;
      }
      when '=~' {
        @res.push: $lhs ~~ rx{<$lhs>} ?? True !! False;
      }
      when 'subsetof' {
        @res.push: $rhs.map({ .Str }).grep(*.defined && * eq $lhs) ?? True !! False;
      }
      default {
        die "'$op' not supported";
      }
    }
  }
  my $result = @res[0];
  for 1..^@res.elems {
    if @logi[$_-1] eq '&&' {
      $result &&= @res[$_];
    } else {
      $result ||= @res[$_];
    }
  }
  $result;
}

sub all-keys ($json where * ~~ Hash, $filter-name, $filter --> Array) {
  my @r;
  for $json.keys -> $k {
    if $json{$k} ~~ Hash {
      @r.push(|@(all-keys($json{$k}, $filter-name, $filter)));
    } elsif $json{$k} ~~ Array {
      for 0 ..^ $json{$k} -> $idx {
        @r.push(|@(all-keys($json{$k}[$idx], $filter-name, $filter)))
          if $json{$k}[$idx] ~~ Hash;
      }
    }
    next if $filter-name.defined && $filter-name ne $k;
    my $ref := $json{$k};
    @r.push($ref);
  }
  @r;
}

multi sub filter-json(Grammar $path, $json where * ~~ Hash|Array) returns Array is export {
  my @return;
  my $c := $path<notation>[0];
  if ($c<dot>//'') eq '..' {
    my $key = $c<expr><ident> // $c[0]<ident>;
    my $fil = $c<expr><filter>//$c<filter>//Nil;
    my @refs = all-keys($json, $key, $fil);
    my @filt;
    if $fil {
      if $fil[0]<indices> {
        my @indices = $fil[0]<indices><int>.map({ .Int });
        for @refs -> $ref {
          for ^@indices.elems -> $idx {
            @filt.push: $ref[$idx] if $ref[$idx].defined;
          }
        }
      } else {
        my $from = $fil[0]<slice><slice-from>.Int;
        my $to   = $fil[0]<slice><slice-to>.Int;
        for @refs -> $ref {
          for $from ..^ $to -> $idx {
            @filt.push: $ref[$idx] if $ref[$idx].defined;
          }
        }
      }
    } else {
      @filt = @refs;
    }
    if $c<notation>.elems {
      for @filt -> $soul {
        @return.push: |filter-json($c, $soul);
      }
    } else {
      @return = |@filt;
    }
  } else {
    my $filter-key;
    my $func;
    if $c<notation>.elems {
      my @keys;
      if $c[0]<ident> {
        @keys = |@($c[0]<ident>.map({ .Str })).grep({ .defined });
      } elsif $c<notation>[0]<func> {
        $func = $c<notation>[0]<func>.Str;
        @return.push: Nil;
        @keys = |@($c<expr><ident>.Str);
      } else {
        @keys = $c<expr><ident>;
      }
      for @keys -> $filter-key {
        if $json ~~ Hash {
          if $c<expr><filter> || $c<filter> {
            return [] if ($func//'length') ne 'length';
            for ^$json{$filter-key}.elems -> $idx {
              next unless filter($c<expr><filter>[0]//$c<filter>[0], $json{$filter-key}[$idx], :$idx);
              if $func {
                @return[*-1]++;
              } else {
                @return.push: |filter-json($c, $json{$filter-key}[$idx]);
              }
            }
          } else {
            if $func {
              return [] if $json{$filter-key} !~~ Array;
              given $func {
                when 'min'|'max' {
                  @return[*-1] = $json{$filter-key}."$func"();
                }
                when 'avg' {
                  @return[*-1] = $json{$filter-key}.sum / $json{$filter-key}.elems;
                }
                when 'stddev' {
                  @return[*-1] = $json{$filter-key}.sum / $json{$filter-key}.elems; #mean
                  @return[*-1] = sqrt($json{$filter-key}.map({ ($_ - @return[*-1]) * ($_ - @return[*-1]) }).sum
                                 / $json{$filter-key}.elems);
                }
                when 'length' {
                  @return[*-1] = $json{$filter-key}.elems;
                }
              }
            } else {
              @return.push(|filter-json($c, $json{$filter-key})) if $json{$filter-key}.defined;
            }
          }
        } elsif $json ~~ Array {
          if $filter-key {
            warn 'jpath error, received key filter for array';
            return [];
          }
          if $c<expr><filter> {
            #nsay $c<expr><filter>;
          } else {
            for ^$json.elems -> $elem {
              @return.push: |filter-json($c, $json[$elem]);
            }
          }
        }
      }
    } else {
      my @keys;
      if $c[0]<ident> {
        @keys = |@($c[0]<ident>.map({ .Str }));
      } else {
        @keys.push: $c<expr><ident>;
      }
      for @keys -> $filter-key {
        if $json ~~ Hash && $json{$filter-key}.defined {
          if $c<filter> || $c<expr><filter> {
            my $sfil = $c<filter>[0]//$c<expr><filter>[0];
            for ^$json{$filter-key}.elems -> $idx {
              next unless filter($sfil, $json{$filter-key}[$idx], :$idx);
              my $container := $json{$filter-key}[$idx];
              @return.push: $container;
            }
          } else {
            my $container := $json{$filter-key};
            @return.push: $container;
          }
        }
      }
    }
  }
  
  @return;
}

multi sub filter-json(Str:D $path, $json) returns Array is export {
  filter-json(JSON::Path::Grammar.parse($path), $json);
}
