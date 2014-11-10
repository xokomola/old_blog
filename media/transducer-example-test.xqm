xquery version "3.0";

(:~
 : Transducer example tests
 :)
module namespace test = 'http://xokomola.com/xquery/example/transducers/tests';

import module namespace tr = 'http://xokomola.com/xquery/example/transducers'
    at 'transducer-example.xqm';

import module namespace l = 'http://xokomola.com/xquery/example/luggage'
    at 'luggage.xqm';

declare %unit:test function test:handle-luggage-small() {
    unit:assert-equals(
        tr:handle-luggage($l:small-trolly),
        $l:small-loaded
    )
};

declare %unit:test function test:handle-luggage-huge() {
    unit:assert-equals(
        tr:handle-luggage($l:huge-trolly),
        $l:huge-loaded
    )
};
(:~
 : For demonstration purposes I wrap some functions in fn:trace so we can follow
 : the execution and compare with the reduce example.
 :)
declare function test:label-heavy($x) {
    l:label-heavy(trace($x, 'label-heavy: '))
};

declare function test:is-non-food($x) {
    l:is-non-food(trace($x, 'is-non-food: '))
};

declare function test:unbundle-pallet($x) {
    l:unbundle-pallet(trace($x, 'unbundle-pallet: '))
};

declare variable $test:luggage-handler :=
    tr:compose((
        tr:mapping(test:label-heavy#1),
        tr:filtering(test:is-non-food#1),
        tr:mapcatting(test:unbundle-pallet#1)
    ));

declare function test:handle-luggage-traced($seq) {
    fold-left($seq, tr:conj(), $test:luggage-handler(tr:conj#2))
};

declare %unit:test function test:handle-luggage-traced() {
    unit:assert-equals(
        test:handle-luggage-traced($l:small-trolly),
        $l:small-loaded
    )    
};