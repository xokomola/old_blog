---
layout: post
title: Origami - Node transformer tutorial part 1
tags: xquery xml html origami
excerpt: A small tutorial for Origami node transformers
---

In this tutorial I will show how you can build and use node transformers
to perform small transformations such as convert a sequence of values
into an HTML list.

Node transformers are functions that can be composed (using combinator
functions such as `xf:do`, `xf:each` and `xf:at`). Most node
transformers are functions that when invoked with a single input
sequence perform a transformation.

Take a simple node transformer such as created by the single argument
`xf:wrap` function.

~~~xquery
xf:wrap(<ul/>)
~~~

This will return a node transformer function that takes one argument,
the input sequence.

You can call it with an input sequence.

~~~xquery
xf:wrap(<ul/>)((<li>a</li>,<li>b</li>,<li>c</li>))
:= 
  <ul>
    <li>a</li>
    <li>b</li>
    <li>c</li>
  </ul>
~~~

But `xf:wrap` also defines a two-argument version. This does the same as
the previous call. You won't get access to the node transformer function
itself though, so you cannot re-use it.

~~~xquery
xf:wrap((<li>a</li>,<li>b</li>,<li>c</li>), <ul/>)
~~~

All Origami node transformers use this convention which means they can
be called with the arrow operator.

~~~xquery
(<li>a</li>,<li>b</li>,<li>c</li>) => xf:wrap(<ul/>)
~~~

The other concept is transformation rules. The combinator functions such
as `xf:do` and `xf:each` receive an array argument that contains a
sequence of node transformer functions. The combinator function composes
these node transformer functions into a new function which is also a
node transformer.

The `xf:do` function applies the composed node transformation to all
then nodes, whereas the `xf:each` function will apply it to each node
indivdually.

~~~xquery
('a','b','c') => xf:each([xf:text(), xf:wrap(<li/>)])
~~~

~~~xml
(<li>a</li>,<li>b</li>,<li>c</li>)
~~~

Enough explaining. If this doesn't make sense right now, it probably
will with an example.

## Creating a list

Assume that we have a sequence of atomic values:

~~~xquery
('a',10,true())
~~~

We want to render this as an HTML list.

~~~xquery
<ul>
  <li>a</li>
  <li>10</li>
  <li>true</li>
</ul>
~~~

This would do.

~~~xquery
<ul>{ 
  for $item in ('a',10,true()) 
  return 
    <li>{ $item }</li> 
}</ul>
~~~

But, let's assume that we want to convert multiple sequences of values.
We want a re-usable function. No problem.

~~~xquery
let $input := ('a',10,true())
let $list := function($nodes) {
    <ul>{
        for $item in $nodes
        return
            <li>{ string($item) }</li> 
    }</ul>
}
return
  $list($input)
~~~

Now let's use Origami to do the same.

Take the first example.

~~~xquery
('a',10,true()) 
  => xf:each([xf:text(), xf:wrap(<li/>)])
  => xf:wrap(<ul/>)
~~~

This uses the arrow operator. To show what this operator does, here is
the equivalent code without the arrow operator.

~~~xquery
xf:wrap(
  xf:each(
    ('a',10,true()),
    [xf:text(), xf:wrap(<li/>)]
  ),
  <ul/>
)
~~~

Let's step through it. We have to unravel the code from the inside out.
Assume `$n` represents the current sequence of nodes, starting with
`('a',10,true())`.

~~~xquery
xf:each($n, [xf:text(), xf:wrap(<li/>)]) 
:= 
  (<li>a</li>,<li>10</li>,<li>true</li>)
~~~

This takes each item from the input sequence separately (the atomic
values `'a'`, `10` and `true()`) and applies the node transformation
rule to it. First the value is converted into a proper text node
(`xf:text`) and then it is wrapped in an `li` element.

Then we need to wrap this whole sequence in an `ul` element.

~~~xquery
xf:wrap($n, <ul/>) 
:= 
   <ul>
     <li>a</li>
     <li>10</li>
     <li>true</li>
   </ul>
~~~

This time the `$n` consists of the sequence of three `li` elements and
this is wrapped into a new `ul` element.

Essentially, the arrow "threads" the left-hand side through the function
on the right-hand side in place of it's first parameter (the `$n`). In
Origami all node transformers are functions that as their first argument
take a sequence of input nodes. This makes it easy to "thread"
operations like this example together using the arrow operator. This
often makes these types of transforms easier to read and readable from
left-to-right instead of inside-out.

However, we want to be able to re-use this as a function. Again we can
turn to a combinator function such as `xf:do` or `xf:each`. Instead of
directly invoking the functions we build, or compose, one
*über*-function that takes the input nodes as it's single argument. Each
sequence of transformations is provided to `xf:do` and `xf:each` as an
array. Try to mentally translate the example that uses the *arrow*
operator to the composition into an *über*-function below.

~~~xquery
let $input := ('a',10,true())
let $list := xf:do([
    xf:each([xf:text(), xf:wrap(<li/>)]),
    xf:wrap(<ul/>)
  ])
return
  $list($input)  
~~~

By using the two "combinator" functions `xf:do` and `xf:each` you can
build little transformation "engines" or functions composed of other
small functions. These combinator functions connect tranformation rules,
or pipelines (formed by the array arguments - which provide a nice
syntactic cue).

Finally, let's make one more addition which will show how to add your
own custom functions to these transformations.

~~~xquery
let $input := ('a',10,true())
let $uc := function($n) { upper-case(string($n)) }
let $list := xf:do([
    xf:each([$uc, xf:text(), xf:wrap(<li/>)]),
    xf:wrap(<ul/>)
  ])
return
  $list($input)  

:=
   <ul>
     <li>A</li>
     <li>10</li>
     <li>TRUE</li>
   </ul>
~~~

That's it for this tutorial. The next part will describe [how to create
a table using node transformers][1] and introduce another combinator
function called `xf:at`.

[1]: http://xokomola.com/2014/12/28/xquery-origami-5.html
