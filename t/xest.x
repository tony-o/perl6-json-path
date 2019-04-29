$.options
$..options
$['options']['code']
$.options.code
$.options[?(@.code=='AB1'&&@.quantity>3)].quantity
$.options[?( (@.code=='AB1'&&@.quantity>3) || @.code == 'AL' )].quantity
$.options[0].quantity
$.options[?(@.code=='AB1')].quantity
$.options[0:1]
$['options'][0:1]
$['options','config']
$['options','config'].quantity
$['options','config'][0:1]
$['options','config'].quantity[0:1]
$.options[?(@.sizes subsetof ['S','M','L'])]
$.options[?(@.sizes subsetof ['S','M','L'])].length()
$.math.stddev()
$.math.min()
$.math.max()
$.math.avg()
$.math.length()
$.options[?(@.length() > 5)].length()
$.store.book[0].title
$.store.book[*].title
$..book[3]
$['store']['book'][0].['title']
$['store']['book'][*].['title']
$..['book'][3]
$..['book'][0:1].title
$..book[0:1].title
