---
layout: post
title: Transducers in XQuery 3.0
tags: xquery xpath xml fp
---
The one where transducers finally clicked for me.

[Transducers][transducers] in Clojure[^2] are a novel functional
programming technique[^1] designed and implemented by Rich Hickey, the
designer of the Clojure language. With XQuery 3.0 we can quite easily
port some of it to XQuery, understanding it though was a bit harder and
this exercise helped me understand, and see, what transducers can do.
You might want to watch Rich's video now before returning here.

You can also [download the source code][source] for the reducer. I have
only tested the code in [BaseX][basex] but it uses only XQuery 3.0 so
should work with others too.

It took me quite a while to get my head around transducers. Especially
if you were never exposed to functional programming before this may be
challenging stuff[^3]. Hang in there, I promise you, it's worth it. FP
veterans on the other hand might want to skip ahead a few sections as
I'm trying to take things slowly. ≈ This is also a rather long post as I
want to take enough time to build up the story. Don't worry if it
doesn't click on the first read. Play with it and at some point the
light will go on.

I will use the analogy that Rich uses in his video. It's based on
luggage handlers at an airport. To a luggage handler it doesn't matter
were they get their luggage from, trolleys or conveyor belts. In the
same vein a transducer is a transformer function that doesn't care where
it gets its work from.

But, let's rewind and start with a simple example implemented in three
different ways using XPath 3.0. This is just warm-up exercise, a bit of
XPath stretching.

## Warm up

> `fn:filter($seq, $f)`: Returns those items from the sequence `$seq`
for which the supplied function `$f` returns true.

~~~~xquery
filter(
  1 to 10, 
  function($x) { 
    $x mod 2 eq 0 
  }
)
:= (2, 4, 6, 8, 10)
~~~~

The function in this example is a `filter` operation. It does not return
the item itself but a boolean flag. The XPath filter function uses this
flag to decide what to do with an item.

Another immplementation.

> `fn:for-each($seq, $f)`: Applies the function item `$f` to every item
from the sequence `$seq` in turn, returning the concatenation of the
resulting sequences in order.

~~~~xquery
for-each(
  1 to 10,
  function($x) {
    if ($x mod 2 eq 0) then
      $x 
    else 
      () 
  }
)
:= (2, 4, 6, 8, 10)
~~~~

This function looks a bit more conventional, a mapping operation, as it
returns the item if it matches the criteria and otherwise it returns
nothing (well, the empty sequence that is).

> `fn:fold-left($seq, $zero, $f)`: Processes the supplied sequence from
left to right, applying the supplied function repeatedly to each item in
turn, together with an accumulated value.
 
~~~~xquery
fold-left(
  1 to 10,
  (),
  function($seq, $x) {
    if ($x mod 2 eq 0) then
      ($seq, $x)
    else
      $seq
    }
)
:= (2, 4, 6, 8, 10)
~~~~

This is the most generic form of expressing the filter in a basic FP
constructs. Although this looks the most involved this is where the
transducer story really can start. Understanding `fold-left` will
already bring you quite a few benefits in your code. But transducers go
a few steps higher up the abstraction ladder. To understand the
reasoning let's return to the luggage handler example from the video.

## Luggage handling

Let's build a chain of luggage handlers each with it's own task. The
first passes the luggage to the next and so on.

Let's give the tasks a name and then define them as simple functions.

The tasks we want to implement is "put the baggage on the plane". This
task consists of the following individual actions.

* break apart pallets (`unbundle-pallet`)
* remove bags that smell like food (`is-non-food`)
* label heavy bags (`label-heavy`)

And this is how we could implement the different actions.

~~~~xquery
declare function label-heavy($x as xs:integer) as xs:integer? {
  if ($x gt 6) then
    -$x
  else
    ()
};

declare function is-non-food($x as xs:integer) as xs:boolean {
  $x mod 2 eq 0
};

declare function unbundle-pallet($x as xs:string) as xs:integer* {
  for $i in tokenize($x,'\s+') return xs:integer($i)
};
~~~~

A first instinct might be to compose these actions is such.

~~~~xquery
declare function handle-luggage-item($x) {
  label-heavy(is-non-food(unbundle-pallet($x)))
};
~~~~

Although this looks simple enough it's quite easy to see that this will
not work and that these functions cannot be composed like this. They
each do things differently like we also encountered in the Warm up
section. To highlight this I added the signatures that show clearly that
these functions are incompatible.

{::comment}

Someone could counter that you can re-write the functions to have
compatible signatures. But this will let "how things arrive" leak into
the function and they are thus not as composable anymore. And less
simple too.

{:/comment}

For example if we pass a pallet (a space-separate string of integers)
the first task unpacks it into a sequence of integers, but the next
function works on individual items and doesn't return the item itself
but rather only indicates to it's boss that a bag does not contain food.
So the `unbundle-pallet` has to hand the items to the next handler
individually. Furthermore neither of these handlers *should* be
concerned how the bags arrive. They just pick it up from the source and
put the good ones in the sink.

In FP terms:

* `label-heavy` is a `map` operation

* `is-non-food` is a `filter` operation

* `unbundle-pallet` is a `mapcat` operation (aka list flattening which
  in XPath comes for free as sequence)

To remind ourselves of our goal. We want to be able to do someting like
this and compose it of the above simple functions.

~~~~xquery
handle-luggage-items(('10 8 3 9 1', '2 1 1 9 8 12'))

:= (-10, -8, -8, -12)
~~~~

We want to make it from simple functions that each performs a single
action and which doesn't care how the work items arrive or where they
go.

## Using reduce (aka fold-left)

Let's look again at the last example from the warm up. The fold-left is
the same as what in FP is called a reduce. All the basic mapping,
filtering and mapcatting operations can be expressed using such a reduce
or in XPath a `fold-left`.

With that in mind the three functions above can be reformulated using
`fold-left`.

~~~~xquery
declare function label-heavy($seq as xs:integer*) as xs:integer* {
  fold-left(
    $seq,
    (),
    function($acc, $x) {
      if ($x gt 6) then
        ($acc, -$x)
      else
        $acc
    }
  )
};

declare function is-non-food($seq as xs:integer*) as xs:integer* {
  fold-left(
    $seq,
    (),
    function($acc, $x) {
      if ($x mod 2 eq 0) then
        ($acc, $x)
      else
        $acc
    }
  )
};

declare function unbundle-pallet($x as xs:string*) as xs:integer* {
  fold-left(
    $seq,
    (),
    function($acc, $x) {
      (
        $acc, 
        for $i in tokenize($x,'\s+') 
        return xs:integer($i)
      )
    }
  )
};
~~~~

Given these we can combine the actions.

~~~~xquery
declare function handle-luggage-items($seq) {
  label-heavy(is-non-food(unbundle-pallet($x)))  
};
~~~~

And to confirm that it's actually working.

~~~~xquery
handle-luggage-items(('10 8 3 9 1', '2 1 1 9 8 12'))

:= (-10, -8, -8, -12)
~~~~

Mission achieved, we can combine the individual functions the way we
wanted. We could stop here.

Admittedly, this could be written in a more succinct way by removing the
repetitions of the `fold-left` but this would tie the reducing function
tightly to what `fold-left` demands. This is not the direction we want
to take this.

## Picking reduce apart

Looking at the data flow through the above functions and using the
luggage handling analogy we could see some things that we might be able
to improve upon.

Each function receives a sequence, then processes it completely before
passing the result to the next function. This is like a luggage handling
line where the first worker processes all luggage, puts it on a new
trolley, the next worker takes the stuff from the trolley, processes it
and puts it on yet another trolley before, the last worker takes this
last trolley, processes the items and, finally, puts them on the plane.

Not only does it sound wasteful it is also impossible to parallelize as
each task needs to wait until the earlier one completes.

Let's look more closely at the algorithmic components of `fold-left`:

* A **seed** or initialization value (empty sequence in this case). Note
  that this depends on the particular data-structure and in the case of
  sequences this has to be the empty sequence.

* A **reducing function** which takes an **accumulator** `$acc` and the
  item to process `$x` and which returns a new sequence, this (in this
  case anonymous) function is what actually implements the business
  logic.

* A way to **combine** the accumulated sequence with a new item `($acc,
  $x)`. If we would want to work with other data structures this would
  have to change.

So we can conclude that the previous solution is bound to a particular
data-structure (the sequence). It proceeds in what in FP circles is
called a non-lazy way[^4]. Which means each processes the full sequence
before going to the next.

With this analysis in hand and some FP techniques we can build up such
transformation of sequences from it's constituent parts.

## Transducers

So far, I could be gentle with you. Not a lot of mind-bending going on.
But in order to implement transducers we have to climb a few stairs on
the abstraction ladder. I tried to build up to this slowly but now we
have to take the plunge.

We are still set on our goal to make this luggage handling business work
with the following, as simple as possible and independent, business
logic functions, our **transducing functions**.

~~~~xquery
declare function label-heavy($x) {
 if ($x gt 6) then
    -$x
  else
    $x
};

declare function is-non-food($x) {
  $x mod 2 eq 0
};

declare function unbundle-pallet($x) {
  for $i in tokenize($x,'\s+') return xs:integer($i)
};
~~~~

I left the function signatures off to highlight the fact that there is
nothing more in these functions than business logic. They do not concern
themselves with the data-structure they are operating on, just on
indivdual items. But they are still different in nature (remember, map,
filter, mapcat mentioned before).

So how to reconcile handling a sequence with these different basic
operations?

.. the seed & the stepper function

.. combining function 

----

[^1]: Transducers did not fall from the plain blue sky, like divine
inspiration. No, as an avid reader of classic CS papers it's based on a
couple of papers by R.S. Bird, [Lectures on Constructive Functional
Programming][bird-paper] and Graham Hutton, [A tutorial on the
universality and expressiveness of fold][hutton-paper].

[^2]: Some Clojurist that wanted to do a close reading of the Transducer
talk has, generously, made a [transscript of the talk][talk-transscript]
available.

[^3]: I also presuppose basic XQuery knowledge.

[^4]: XQuery does not have the ability to work with lazy sequences but this doesn't fundamentally matter for what we're discussing here. Clojure, for example, can handle an infinite sequence by handling it lazily.

[transducers]: http://www.youtube.com/watch?v=6mTbuzafcII
[source]: http://xokomola.github.com
[talk-transscript]: https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/Reducers.md
[bird-paper]: http://www.cs.ox.ac.uk/files/3390/PRG69.pdf
[hutton-paper]: http://www.cs.nott.ac.uk/~gmh/fold.pdf
[basex]: http://basex.org

*[FP]: Functional Programming

