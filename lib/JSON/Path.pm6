use JSON::Path::Grammar;
unit module JSON::Path;

sub filter-pass($filter where * ~~ Hash|Array, $obj, :$idx?, :$level? = 0 --> Bool:D) {
  if $filter ~~ Hash && $filter<from>.defined || $filter<to>.defined {
# TODO: this won't handle negatives properly
    return $filter<from> <= $idx < $filter<to>;
  } elsif $filter ~~ Array {
    return $filter.grep($idx) ?? True !! False;
  }

  my (@zipper, $lhs, $rhs, $op);
  for |$filter<statements> -> $stmt {
    if $stmt<statements> {
      @zipper.push: |filter-pass($stmt, $obj, :$idx);
    } elsif $stmt ~~ Hash {
      if ($stmt<lhs><type>//'') eq 'property' {
        if $stmt<lhs><val> ~~ /\(\s*\)$/ {
          if $stmt<lhs><val> ~~ /^'length'\s*\(/ {
            if $obj !~~ Array {
              @zipper.push: False;
              next;
            }
            $lhs = try $obj.elems;
          }
        } else {
          $lhs = try $obj{$stmt<lhs><val>};
        }
      } else {
        $lhs = $stmt<lhs><val>;
      }
      if ($stmt<rhs><type>//'') eq 'property' {
        if $stmt<lhs><val> ~~ /\(\s*\)$/ {
          if $stmt<lhs><val> ~~ /^'length'\s*\(/ {
            if $obj !~~ Array {
              @zipper.push: False;
              next;
            }
            $lhs = try $obj.elems;
          }
        } else {
          $rhs = $obj{$stmt<rhs><val>} // Nil;
        }
      } else {
        $rhs = $stmt<rhs><val>;
      }
      $op = $stmt<op>;
      given $op {
        when '==' {
          @zipper.push: $lhs eq $rhs;
        }
        when '>' {
          @zipper.push: $lhs gt $rhs;
        }
        when '>=' {
          @zipper.push: $lhs ge $rhs;
        }
        when '!=' {
          @zipper.push: $lhs ne $rhs;
        }
        when '<' {
          @zipper.push: $lhs lt $rhs;
        }
        when '<=' {
          @zipper.push: $lhs le $rhs;
        }
        when '=~' {
          @zipper.push: $lhs ~~ rx{<$rhs>} ?? True !! False;
        }
        when 'subsetof' {
          @zipper.push: $rhs.grep(*.defined && * eq $lhs) ?? True !! False;
        }
        default { die "$op not supported"; }
      }
    }
  }
  my $ltr = @zipper[0];
  for 1..^@zipper.elems -> $idx {
    if $filter<logic>[$idx-1] eq '&&' {
      $ltr &&= @zipper[$idx];
    } else {
      $ltr ||= @zipper[$idx];
    }
  }

  return $ltr;
}

sub all-keys ($json where * ~~ Hash, $filter-name, $filter, :$want-path = False, :@path? --> Hash) {
  my (@r, @p);
  my $p = @path.join('.') ~ (@path.elems??'.'!!'');
  for $json.keys -> $k {
    if $json{$k} ~~ Hash {
      my $r = all-keys($json{$k}, $filter-name, $filter, :$want-path, :path(@(|@path, $p ~ $k)));
      @r.push: |$r<r>;
      @p.push: |$r<p>;
    } elsif $json{$k} ~~ Array {
      for 0 ..^ $json{$k} -> $idx {
        if $json{$k}[$idx] ~~ Hash {
          my $r = all-keys(
            $json{$k}[$idx],
            $filter-name,
            $filter,
            :$want-path,
            :path(@(|@path, $p ~ $k ~ "\[$idx\]"))
          );
          @r.push: |$r<r>;
          @p.push: |$r<p>;
        }
        next if $filter && !filter-pass($filter, $json{$k}[$idx], :$idx);
        @r.push($json{$k}[$idx]);
        @p.push($p ~ "$k\[$idx]") if $want-path;
      }
    }
    next if $filter-name.defined && $filter-name ne $k;
    next if $json{$k} ~~ Array;
    @r.push($json{$k});
    @p.push($p ~ "$k") if $want-path;
  }
  return %( :@r, :@p, );
}

multi sub filter-json(Hash $path, $json where * ~~ Hash|Array, Bool :$want-path = False, :@path?, Callable :$assign? --> Array) is export {
  my $ctx = $path<identities>;
  my (@returns, @to-recurse, @pd);
  for @($path<identities>) {
    if $path<dot> eq '..' {
      my $all = all-keys($json, $_, $path<filter>, :$want-path, :@path);
      if $path<notation> {
        @to-recurse.push: |@($all<r>);
        @pd.push: |@($all<p>);
      } else {
        my @val = !$want-path
                    ?? |@($all<r>)
                    !! |@($all<p>).map({
                          @path.join('.') ~ (@path.elems??'.'!!'') ~ $_
                       });
        if $assign {
          $assign($_) for |@val;
        }
        @returns.push: |@val;
      }
    } elsif $_ eq '*' {
      if $json ~~ Hash {
        for $json.keys -> $k {
          @pd.push: $k if $path<notation>;
          @to-recurse.push: $json{$k} if $path<notation>;
          if $assign  && ! $path<notation> {
          }
          $assign($json{$k}) if !$path<notation> && $assign;
          @returns.push: $json{$k} unless $path<notation>;
        }
      } elsif $json ~~ Array { 
        die 'dunno what to do w *';
      }
    } elsif $json{$_} ~~ Array && $path<notation> {
      for ^$json{$_} -> $idx {
        next if $path<filter> && !filter-pass($path<filter>, $json{$_}[$idx], :$idx);
        @pd.push: "$_\[$idx\]";
        @to-recurse.push: $json{$_}[$idx];
      }
      if $path<notation><identities>.grep({ $_ ~~ /'('\s*')'\s*$/ }) {
        (my $func = ($path<notation><identities>[0]//'')) ~~ s/'('\s*')'\s*$//;
        warn "Calling method $func\() with :want-path will always return an empty list" if $want-path;
        return [] if $want-path;
        if $func eq 'length' {
          @returns.push: @to-recurse.elems;
        } elsif $func eq 'stddev' {
          @returns.push: $json{$_}.sum / $json{$_}.elems;
          @returns[*-1] = sqrt($json{$_}.map({ ($_ - @returns[*-1]) * ($_ - @returns[*-1]) }).sum
                               / $json{$_}.elems);
        } elsif $func eq 'min'|'max' {
          @returns.push: @to-recurse."$func"();
        } elsif $func eq 'avg' {
          @returns.push: @to-recurse.sum / @to-recurse.elems;
        }
        @to-recurse = ();
      }
    } elsif $json{$_} ~~ Hash {
      @pd.push: $_ if $json{$_}.defined;
      @to-recurse.push: $json{$_} if $json{$_}.defined;
    } elsif ! $path<notation>.defined {
      if $path<filter> && ($path<filter><from> || $path<filter><to>) {
        next unless $json{$_} ~~ Array;
        if $want-path {
          my $range = ($path<filter><from>//0) ..^ ($path<filter><to> ?? $path<filter><to> !! *-1);
          for $range -> $idx {
            @returns.push: @path.join('.') ~ (@path.elems??'.'!!'') ~ $_ ~ '[' ~ $idx ~ ']';
          }
        } else {
          @returns.push: |$json{$_}[ ($path<filter><from>//0) ..^ ($path<filter><to> ?? $path<filter><to> !! *-1) ];
        }
      } elsif $json{$_} ~~ Array {
        if $want-path {
          if $path<filter> {
            for ^$json{$_} -> $idx {
              next if $path<filter> && !filter-pass($path<filter>, $json{$_}[$idx], :$idx);
              @returns.push: @path.join('.') ~ (@path.elems??'.'!!'') ~ $_ ~ '[' ~ $idx ~ ']';
            }
          } else {
            @returns.push: @path.join('.') ~ (@path.elems??'.'!!'') ~ $_;
          }
        } else {
          if $path<filter> {
            @returns.push: [];
            for ^$json{$_} -> $idx {
              next if $path<filter> && !filter-pass($path<filter>, $json{$_}[$idx], :$idx);
              @returns[*-1].push: $json{$_}[$idx] unless $want-path;
            }
          } else {
            @returns.push: $json{$_};
          }
        }
      } else {
        if $want-path {
          @returns.push: @path.join('.') ~ (@path.elems??'.'!!'') ~ $_;
        } else {
          $assign($json{$_}) if $assign.defined;
          @returns.push: $json{$_};
        }
      }
    }
  }

  die 'internal problem' if @pd.elems != @to-recurse.elems && $want-path;
  for @to-recurse.grep(*.defined) -> $f {
    @returns.push( |filter-json($path<notation>, $f, :$want-path, :path( $want-path ?? @(|@path, @pd.shift) !! @() ), :$assign ) );
  }

  @returns;
}

multi sub filter-json(JSON::Path::Grammar $path, $json where * ~~ Hash|Array, Bool :$want-path = False, :@path?, Callable :$assign --> Array) is export {
  filter-json($path.made, $json, :$want-path, :@path, :$assign);
}
multi sub filter-json(Str $path, $json where * ~~ Hash|Array, Bool :$want-path = False, :@path?, Callable :$assign --> Array) is export {
  filter-json(JSON::Path::Grammar.parse($path), $json, :$want-path, :@path, :$assign);
}
