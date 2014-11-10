xquery version "3.0";

module namespace tr = 'http://xokomola.com/xquery/example/transducers';

import module namespace l = 'http://xokomola.com/xquery/example/luggage'
    at 'luggage.xqm';

declare function tr:mapping($transform) {
  function($reduce) {
    function($result, $input) {
        $reduce($result, $transform($input)) 
    }
  }
};

declare function tr:filtering($predicate) {
  function($reduce) {
    function($result, $input) {
      if ($predicate($input)) then
        $reduce($result, $input)
      else
        $result
    }    
  }
};

declare function tr:mapcatting($transform) {
  function($reduce) {
    function($result, $input) {
        fold-left($transform($input), $result, $reduce)
    }    
  }
};

(: helper to compose reducers :)
declare function tr:compose($fns) {
    function($input) {
        fold-left($fns, $input,
              function($args, $fn) { 
                    $fn($args) 
              }
        ) 
    }
};

(:~
 : The step function. Just join the two as a sequence.
 :)
declare function tr:conj() {
    ()
};

declare function tr:conj($seq, $x) {
    ($seq, $x)
};

declare variable $tr:luggage-handler :=
  tr:compose((
    tr:mapping(l:label-heavy#1),
    tr:filtering(l:is-non-food#1),
    tr:mapcatting(l:unbundle-pallet#1)
  ));

declare function tr:handle-luggage($seq) {
    fold-left($seq, tr:conj(), $tr:luggage-handler(tr:conj#2))
};
