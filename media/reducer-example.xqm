xquery version "3.0";

module namespace re = 'http://xokomola.com/xquery/example/reducers';

import module namespace l = 'http://xokomola.com/xquery/example/luggage'
    at 'luggage.xqm';

declare function re:map($fn, $seq) {
  fold-left(
      $seq,
      (),
      function($seq, $x) {
        ($seq, $fn($x))
      }
  ) 
};

declare function re:filter($fn, $seq) {
  fold-left(
    $seq,
    (),
    function($seq, $x) {
      ($seq, if ($fn($x)) then $x else ())
    }
  )
};

(: same as re:map because in XPath sequence are flattened :)
declare function re:mapcat($fn, $seq) {
  fold-left(
    $seq,
    (),
    function($seq, $x) {
      ($seq, $fn($x))
    }
  )
};

(: helper to compose reducers :)
declare function re:compose($fns) {
    function($input) {
        fold-left($fns, $input,
              function($args, $fn) { 
                    $fn($args) 
              }
        ) 
    }
};

declare variable $re:luggage-handler :=
    re:compose((
        re:mapcat(l:unbundle-pallet#1, ?),
        re:filter(l:is-non-food#1, ?),
        re:map(l:label-heavy#1, ?)
    ));

declare function re:handle-luggage($seq) {
    $re:luggage-handler($seq)
};
