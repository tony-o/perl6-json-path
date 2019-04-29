use Bench;

my Bench $b .=new;

my $x = 'test.json'.IO.slurp;
$b.cmpthese(@*ARGS[0].Int//100000, {
  built-in => sub {
    from-json($x);#'{ "hello": "w0rld", "xyz": 5 }');
  },
  parser => sub {
    use JSON::Stream::Grammar; 
    use JSON::Stream::Actions;
    JSON::Stream::Grammar.parse(
      #'{ "hello": "w0rld", "xyz": 5 }',
      $x,
      :actions(JSON::Stream::Actions.new),
    );
  },
});
