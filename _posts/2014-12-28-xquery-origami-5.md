---
layout: post
title: Origami - Node transformer tutorial part 2
tags: xquery xml html origami
excerpt: A small tutorial for Origami node transformers
---

In the previous tutorial I showed [how to build a simple HTML list using
node transformers][1]. In this part I will introduce another combinator
function called `xf:at`. I conclude this example I will compare our
transformation with performs relative to a traditional XQuery solution.

The `xf:at` function is similar to `xf:each` but it's transformation
rule starts with an XPath expression that selects nodes from the input
sequence. Only the matching nodes are processed with the rest of the
transformation rule. The non-matching nodes are dropped.

## Creating a table

The source code for this example (both the traditional and the Origami version
can be found in [create-table-xquery.xq][2] and [create-table-origami.xq][3].

For this exercise let's assume we have some data as XML and we want to display
the data as a simple HTML table.

Let's look at the data first.

~~~xml
let $input :=
  <result>
    <record name="Joe" age="34"/>
    <record name="Jane" age="31"/>
    <record name="Bill" age="42"/>
    <record name="Marc"/>
  </result>
~~~

And now let's look at the `xf:at` function which is similar to the `xf:do` and
`xf:each` shown before but it has a special feature in that it combines the use
of `xf:select-all` (a low-level XPath selection function) and `xf:each`.

~~~xquery
return
  count(xf:at($input, ['record']))
  
:= 4
~~~

This returns a sequence of 4 `record` elements. In our table each of these
records has to become a table row. Note that for convenience `xf:at` will
look at all nodes including descendants.

Next, I'll add a bit of business logic in the form of a function that
takes the `record` elements selected and picks out the data attributes
before wrapping this data in a table row element.

~~~xquery
$input 
=> xf:at(
     ['record', 
       function($rec) { ($rec/@name, $rec/@age) }, 
       xf:wrap(<tr/>) 
     ]
   )
~~~

~~~xml
<tr name="Joe" age="34"/>
<tr name="Jane" age="31"/>
<tr name="Bill" age="42"/>
<tr name="Marc"/>
~~~

Not what we wanted but interesting. The anonymous function retrieved the
two data attributes from each record and then re-wrapped it in a `tr`
element but as these data values are still attributes nodes they leech
onto the `tr` element.

Let's put a `xf:text()` step in between.

~~~xquery
$input 
=> xf:at(
     ['record', 
       function($rec) { ($rec/@name, $rec/@age) },      
       xf:text(), 
       xf:wrap(<tr/>) 
     ]
  )
~~~

~~~xml
<tr>Joe34</tr>
<tr>Jane31</tr>
<tr>Bill42</tr>
<tr>Marc</tr>
~~~

Not what we want either. Both text nodes are smushed together. Let's employ an
`xf:each` to wrap each data value in a table cell element.

~~~xquery
$input 
=> xf:at(
     ['record', 
       function($rec) { ($rec/@name, $rec/@age) },
       xf:each(
         [xf:text(), xf:wrap(<td/>)]
       ), 
       xf:wrap(<tr/>) 
     ]
  )

:=
    <tr>
      <td>Joe</td>
      <td>34</td>
    </tr>
    <tr>
      <td>Jane</td>
      <td>31</td>
    </tr>
    <tr>
      <td>Bill</td>
      <td>42</td>
    </tr>
    <tr>
      <td>Marc</td>
    </tr>
~~~

The missing value in the last row is easy to fix. Let's do that now and to finish the table, wrap everything in a table element.

~~~xquery
$input 
  => xf:at(
       ['record', 
         function($rec) { ($rec/@name, ($rec/@age,'unknown')[1]) },
         xf:each(
           [xf:text(), xf:wrap(<td/>)]
         ), 
         xf:wrap(<tr/>) 
       ]
     )
  => xf:wrap(<table/>)
~~~

This produces the following HTML table.

~~~xml
<table>
  <tr>
    <td>Joe</td>
    <td>34</td>
  </tr>
  <tr>
    <td>Jane</td>
    <td>31</td>
  </tr>
  <tr>
    <td>Bill</td>
    <td>42</td>
  </tr>
  <tr>
    <td>Marc</td>
    <td>unknown</td>
  </tr>
</table>
~~~

In order to re-use this as a function you can take the code and provide it as a
function by slapping an `xf:do` around it.

~~~xquery
let $table := xf:do([
    xf:at(
       ['record', 
         function($rec) { ($rec/@name, ($rec/@age,'unknown')[1]) },
         xf:each(
           [xf:text(), xf:wrap(<td/>)]
         ), 
         xf:wrap(<tr/>) 
       ]
    ),
    xf:wrap(<table/>)])
return
    $table($input)
~~~

As a final step let's turn this code into something more generally useful.

Almost all business logic is in the anonymous function. Let's apply a little
bit of "functional programming" and separate it out.

~~~xquery
let $rec := function($rec) { ($rec/@name, ($rec/@age,'unknown')[1]) }
let $table-builder := function($model) {
    xf:do([
        xf:at(
           ['record', 
             $model,
             xf:each(
               [xf:text(), xf:wrap(<td/>)]
             ), 
             xf:wrap(<tr/>) 
           ]
        ),
        xf:wrap(<table/>)])
    }
let $table := $table-builder($rec)
return
    $table($input)
~~~

The business logic could be designed differently. For example the
sequence of values could be modelled as a sequence or an array
(`['Bill', 42]`) or probably even better you could use a map with the
field names as the key (`map { 'name': 'Bill', 'age': 42 }`).

[1]: http://xokomola.com/2014/12/28/xquery-origami-4.html
[2]: https://github.com/xokomola/origami/blob/master/examples/create-table-xquery.xq
[3]: https://github.com/xokomola/origami/blob/master/examples/create-table-origami.xq




