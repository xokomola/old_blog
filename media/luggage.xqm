xquery version "3.0";

module namespace l = 'http://xokomola.com/xquery/example/luggage';

(: some test luggage :)
declare variable $l:small-trolly := ('10 8 3 9 1', '2 1 1 9 8 12');
declare variable $l:small-loaded := (11, 9, 2, 9, 13);

declare variable $l:huge-trolly := 
    for $i in 1 to 1000
    return $l:small-trolly;
    
declare variable $l:huge-loaded :=
    for $i in 1 to 1000
    return $l:small-loaded;

(: the business logic / reducing functions :)

declare function l:label-heavy($x) {
 if ($x gt 6) then
    $x + 1
  else
    $x
};

declare function l:is-non-food($x) {
  $x mod 2 eq 0
};

declare function l:unbundle-pallet($x) {
  for $i in tokenize($x,'\s+') return xs:integer($i)
};
