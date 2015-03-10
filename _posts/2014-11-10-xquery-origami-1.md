---
layout: post
title: Origami - XQuery Templating Reloaded!
tags: xquery xml html origami
excerpt: Introducing Origami Transformers for XQuery 3.1
---

*2014-12-23: updated for Origami 0.4*

I started to work on an XQuery templating library called
[Origami][origami]. In many other languages there are a gazillion
options when you are looking for a templating library. In XQuery not so
much. When a transformation gets more involved it's easy to jump over to
XQuery's brother XSLT but in many situations this is overkill. Origami
provides a templating option to users of XQuery 3.1.

I must not get ahead of myself though. Before I can call Origami a
proper templating library I need to have a transformation "engine" on
which I can build further templating features.

My goals are modest at this point:

- Provide a simple way to define node transformations (or templates)
  through ordinary functions.

- Provide a transformation "engine" that recursively walks a node
  sequence applying the individual node transformations to the input
  nodes.


## The identity transform for XQuery

If you need to transform XML in XQuery and if you are familiar with XSLT
you might find XQuery a bit underwhelming at first. It was not designed
as a transformation language. This doesn't mean it's not capable.

A common starting point or pattern for these types of transformations is
the identity transform. A more or less [canonical
example][xquery-identity] is this one:

~~~xquery
xquery version "1.0";
 
(: copy the input to the output without modification :)
declare function local:copy($input as item()*) as item()* {
for $node in $input
   return 
      typeswitch($node)
        case element()
           return
              element {name($node)} {
 
                (: output each attribute in this element :)
                for $att in $node/@*
                   return
                      attribute {name($att)} {$att}
                ,
                (: output all the sub-elements of this element recursively :)
                for $child in $node
                   return local:copy($child/node())
 
              }
        (: otherwise pass it through.  Used for text(), comments, and PIs :)
        default return $node
};
~~~

It iterates over a structure of nodes and outputs them unmodified
recursively processing any of it's children.

Using this as a starting-point you can modify it to include the
individual node transformations you need. Of course you would use
functions to avoid mixing the smaller node transformations with the main
transformation engine (the typeswitch).

At the highest level such a transformer converts an input tree to an
output tree.

![Transformer]({{ site.url }}/media/transformer.png)

For XQuery I want to be able to define such a transformer as a function
that takes input nodes and returns the output nodes.

~~~xquery
transform(<input/>) => <output/>
~~~

An XSLT transformation consists of many small independent templates and
each of them transforms an input node into output nodes.

What I want is to define an XQuery transformation as a process that
transforms input nodes in output nodes using a set simple node
transformations.

What I don't want is to write a new transformation engine (similar
to the typeswitch example) every time I need to transform a few nodes.
This should be generic.

## What is a node transformer?

A node transformer is an ordinary function that takes a single argument,
the input nodes, and it returns the output nodes. It should not be
concerned with how the input nodes were selected or by which mechanism.
Of course, like in XSLT these transformers may query ancestor nodes that
are outside the original input nodes in other parts of the document they
are part of.

![Node Transformer]({{ site.url }}/media/node-transformer.png)

Every node transformer has the same, or a compatible signature.

~~~xquery
function($nodes as node()*) as node()*
~~~

So a transformer may declare that it only works with single element
nodes.

~~~xquery
declare function upper($node as element()) as node()* {
    element { upper-case(name($node)) } {
        $node/@*,
        xf:apply($node/node())
    }
};
~~~

This is equivalent to the body of this XSLT template.

~~~xml
<xsl:template match="*">
  <xsl:element name="{ upper-case(name($node)) }">
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>
~~~

So, how can I tell the transformation engine which nodes have to be
copied to the output and which need to have the transformation templates
applied to them?

In XSLT we use the `xsl:apply-templates` instruction to do this.
Similarly, a node transformation function can call `xf:apply`. But we
cannot just call a normal function as it would need to know about all
the templates that are part of this transformation. Instead, the
function just wraps the nodes to be transformed in a "control" element
`<xf:apply/>`. Then when control is handed over to the transformer it
will notice the control node and switch from copy mode back to apply
mode.


## Node transformations

Origami provides a small set of node transformers. But, as I showed
above it is also simple to define your own.

Here are a couple of provided node transformers:

- `xf:content` replace the child nodes of an element.
- `xf:replace` replace the input nodes
- `xf:wrap` wrap an element around the input nodes
- `xf:unwrap` remove all elements but not their child nodes
- `xf:append` insert nodes after the last child of each element node

There are more of these node transformers and you compose them to
form chains of transformations. Using the XQuery arrow operator they
are also quite easy to read.

~~~xquery
$input => xf:append(<new-element/>) => xf:wrap(<wrapper/>)
~~~

This reads much more easily then

~~~xquery
xf:wrap(xf:append($input, <new-element/>), <wrapper/>))
~~~

However, you can also combine them using `xf:do` to create a new
transformer function.

~~~xquery
let $transform := 
  xf:do((
    xf:append(<new-element/>),
    xf:wrap(, <wrapper/>)
  ))
return
  $transform($input)
~~~

## Node selectors

Given a template document, how can we select the nodes that require
transformation. In XSLT this is done using match templates.

In Origami you use node selectors which are XPath expressions just
like you would use in XSLT.

You use the `xf:at` function to create such node selectors.

~~~xquery
let $selector := xf:at(['li'])
let $input := <ul><li>item 1</li><li>item 2</li></ul>
return
    $selector($input)
~~~

This will return the two `li` element nodes.

The reason why the argument is an array is that you can combine multiple
selectors and transformations at the spot.

~~~xquery
xf:at(['li', xf:text()])
~~~

Now let's look at how we can combine the selectors with a transformation.

## Extractors

The first variety of transformations handles extraction. In this type of
transformer we are not looking for transformation of a whole document but
rather in picking out specific parts of a document and ignoring the rest.

Building an extractor function starts with `xf:extract` and providing it
a sequence of rules that are arrays consisting of a selector and
optionally some transformation functions.

~~~xquery
let $extractor := 
  xf:extract((
    ['li[1]', xf:wrap(<first/>)],
    ['li', xf:wrap(<other/>)]
  ))
return
  $extractor(<ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>)
  
=> <first><li>item 1</li></first>
   <other><li>item 2</li></other>
   <other><li>item 3</li></other>
~~~

Behind the scenes the extractor function creates an `xf:at` function
using the first array element and then feeds the resulting nodes one by
one to the transformations which are wrapped in a `xf:do`.

The extractor also takes care of returning the nodes in document order,
without duplicates and using the transformation of the first rule that
matches a node.

If you need only one rule you may just as well use:

~~~xquery
$input => xf:at(['li', xf:wrap(<other/>)])
~~~

## Transformers

Contrary to the Extractors above, the second variety of transformation
is much more similar to XSLT. It tranforms the whole input and outputs
any node not matched by a transformation rule. The rules, however, are
the same as with extractors.

~~~xquery
let $transformer := 
  xf:transform((
    ['li[1]', xf:wrap(<first/>)],
    ['li', xf:wrap(<other/>)]
  ))
return
  $transformer(<ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>)
  
=> <ul>
     <first><li>item 1</li></first>
     <other><li>item 2</li></other>
     <other><li>item 3</li></other>
   </ul>
~~~

## Wrap up

I haven't cared much for performance yet. The main point was the design.
Currently it only runs on BaseX 8.0 or higher
but I see no reason why it could not be made to run on other XQuery
engines that support XQuery 3.1. BaseX is my main database at the moment
and I am not going to be investing a lot of time in other database yet.

I still haven't discussed how proper templating is done. For that we'll
need to look at `xf:template` but using only the parts discussed here
may already be useful.


[origami]: https://github.com/xokomola/origami
[enlive]: https://github.com/cgrand/enlive
[xquery-identity]: http://en.wikipedia.org/wiki/Identity_transform#Using_XQuery
[xform.xqm]: https://github.com/xokomola/origami/blob/master/xform.xqm
