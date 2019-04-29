use JSON::Stream::Actions;
use JSON::Stream::Grammar;

module JSON::Walker {
  multi sub parse-json(IO:D $file where * ~~ :f) is export {
    parse-json($file.slurp);
  }
  
  multi sub parse-json(Str:D $str) is export {
    my $x = JSON::Stream::Grammar.parse($str, :actions(JSON::Stream::Actions.new)).made;
    $x;
  }
}
