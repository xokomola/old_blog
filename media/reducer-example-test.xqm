xquery version "3.0";

(:~
 : Reducer example tests
 :)
module namespace test = 'http://xokomola.com/xquery/example/reducers/tests';

import module namespace re = 'http://xokomola.com/xquery/example/reducers'
    at 'reducer-example.xqm';

import module namespace l = 'http://xokomola.com/xquery/example/luggage'
    at 'luggage.xqm';

declare %unit:test function test:map() {
     unit:assert-equals(
        re:map(
            l:label-heavy#1,
            (8,11)
        ),
        (-8,-11)
    )
};

declare %unit:test function test:filter() {
    unit:assert-equals(
        re:filter(
            l:is-non-food#1,
            (1,2,3,4)
        ),
        (2,4)
    )
};

declare %unit:test function test:mapcat() {
    unit:assert-equals(
        re:mapcat(
            l:unbundle-pallet#1,
            ('1 2 3','4 5 6')
        ),
        (1,2,3,4,5,6)
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
    re:compose((
        re:mapcat(test:unbundle-pallet#1, ?),
        re:filter(test:is-non-food#1, ?),
        re:map(test:label-heavy#1, ?)
    ));

declare function test:handle-luggage-traced($seq) {
    $test:luggage-handler($seq)
};

(: ~
 : Luggage handling example using reduce.
 :)
declare %unit:test function test:handle-luggage-small() {
    unit:assert-equals(
        re:handle-luggage($l:small-trolly),
        $l:small-loaded
    )
};

declare %unit:test function test:handle-luggage-huge() {
    unit:assert-equals(
        re:handle-luggage($l:huge-trolly),
        $l:huge-loaded
    )
};

(: ~
 : Tracing luggage handling example using reduce.
 :)
declare %unit:test function test:handle-luggage-traced() {
    unit:assert-equals(
        test:handle-luggage-traced($l:small-trolly),
        $l:small-loaded
    )    
};