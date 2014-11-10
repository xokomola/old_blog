---
layout: post
title: Origami - XQuery Templating Reloaded!
tags: xquery xml html origami
excerpt: Introducing Origami Transformers for XQuery 3.0
---

I started to work on an XQuery templating library called
[Origami][origami]. In many other languages there are a gazillion
options when you are looking for a templating library. In XQuery not so
much. When a transformation gets more involved it's easy to jump over to
XQuery's brother XSLT but in many situations this is overkill. Origami
provides a templating option to users of XQuery 3.0.

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

## Node transformers

A node transformer is an ordinary function that takes a single argument,
the input node, and it returns the output nodes. It should not be
concerned with how it was selected or by whom. But it may have to look
elsewhere, outside the input node, to contextualize it's behaviour.

![Node Transformer]({{ site.url }}/media/node-transformer.png)

~~~xquery
declare function upper($node as element()) as item()* {
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

I do not want the node transformer to access global variables and I also
do not want to pass all the transformation templates around with each
individual template as this would complicate them and make them less
re-usable.

So, how can I tell the transformation engine which nodes have to be
copied to the output and which need to have the transformation templates
applied?

In XSLT we use the `xsl:apply-templates` instruction to do this.
Similarly, a node transformation function can call `xf:apply`. But we
cannot just call a normal function as it would need to know about all
the templates that are part of this transformation. Instead, the
function just wraps the nodes to be transformed in a "control" element
`<xf:apply/>`. Then when control is handed over to the transformer it
will notice the control node and switch from copy mode back to apply
mode.


## Transformers

When building up a transformation I can declare which node
transformation function to apply to which nodes. Here I use a simple
selector string which means, apply the node transformer to all elements.

~~~xquery
xf:template('*', upper(?))
~~~

The question mark will be filled in with the current input node when
running the transformation.

A transformer is defined by a sequence of these templates. The
`xf:xform` function returns a transformer function that can be used to
transform input nodes.

When this transformer function is then evaluated with a node sequence it
will use `xf:apply` to start the transformation process.

~~~xquery
declare function xf:xform($templates as map(*)*) as function(*) {
    function ($nodes as item()*) as item()* {
        xf:apply($nodes, $templates)
    }
};
~~~

So now we have to look at the piece that connects individual node
transformations to specific nodes.


## Transformation templates

In order to use a regular function like `upper` it needs to be wrapped
in `xf:template` together with a selector string or function.

Each template is represented by a map structure.

~~~xquery
declare variable $tpl := xf:template('*', upper(?));

$tpl

=> map {
     'match': xf:matches(?, '*'),
     'fn': upper(?)
   }
~~~

A template has two keys, `match` and `fn`. The first contains a function
that when called with a node returns `true()` or `false()`. The second
contains a function that performs the node transformation.

Instead of a string selector you may also pass in a function that
returns a boolean when passed a node. This function can employ any test
necessary to decide if this template should be fired for this node.

~~~xquery
declare variable $tpl := xf:template(
    function($n) { exists($n/@x) }, upper(?));
~~~

This template will only fire for nodes that have an `x` attribute.

Instead of passing a node transformation function you can also provide
a literal result fragment.

~~~xquery
declare variable $tpl := xf:template(
    'para', <p>There was a para here</p>);
~~~

Currently it is not yet possible to specify what to do with the matching
input node.


## Applying templates

Let's dive deeper into the guts of the transformation "engine".

It has two modes: apply and copy. Apply is the mode it starts in but
when a node transformation returns nodes it switches to copy mode until
it is explicitly told to go back to apply mode using the `<xf:apply/>`
control node.

For each node in the node sequence `xf:match` is used to determine which
template matches. It then evaluates the node transformation function
belonging to this template and starts copying the returned nodes. When
no matching template is found it copies the current node and applies the
child nodes looking for further transformation templates (apply mode).

~~~~xquery
declare function xf:apply($nodes, $xform) {
    for $node in $nodes
    let $fn := xf:match($node, $xform)
    return
        if ($fn instance of function(*)) then
            xf:copy($fn($node), $xform)
        else if ($node instance of element()) then
            element { name($node) } {
                xf:apply($node/@*, $xform),
                xf:apply($node/node(), $xform)   
            }
        else
            $node
};
~~~~

Copy mode is almost the same but here all nodes are simply copied unless
an `<xf:apply/>` control node is encountered.

~~~~xquery
declare function xf:copy($nodes, $xform) {
    for $node in $nodes
    return 
        if ($node/self::xf:apply) then
            xf:apply(($node/@*,$node/node()), $xform)
        else if ($node instance of element()) then
            element { name($node) } {
                $node/@*,
                xf:copy($node/node(), $xform)   
            }
        else
            $node
};
~~~~

I don't want to list `xf:match` here but what it does is iterate over
templates and returns the node transformation function for the first
template that matches. It currently uses a BaseX specific function from
the Higher Order Function module (`hof:until`) but I want to change it
to generic XQuery 3.0 eventually.

You can look at the transformer source code [on Github][xform.xqm].


## Control nodes

By giving them a name it becomes harder to kill them. I have to admit
that at first I thought: "bummer!". This frustrates many XPath
expressions. If you need to check the parent node, then you cannot just
do `$node/..` anymore but instead have to use something like:

~~~~xquery
$node/ancestor::*[not(self::xf:*)][1]
~~~~

But I'm not building an XSLT clone here. I'm making a little library for
folding small templates together into, say, some HTML page output or a
REST response. It's not likely that I will process DITA or TEI documents
with it.

I also started to see some advantages. Such control information in the
structure returned from a node transformation keeps the node
transformation away from the transformation engine.

## Wrap up

I haven't cared much for performance yet. The main point was the design.
Currently it only runs on BaseX 8.0 betas but I see no reason why it
could not be made to run on other XQuery 3.0 engines. BaseX is my main
database at the moment and I am not going to be investing a lot of time
in other database yet.

There is a lot more to do to make this a viable templating library but
I'm happy with the transformers so far.

I will be looking into the [Enlive][enlive] library for the other parts
because I like the ideas it implements.


[origami]: https://github.com/xokomola/origami
[enlive]: https://github.com/cgrand/enlive
[xquery-identity]: http://en.wikipedia.org/wiki/Identity_transform#Using_XQuery
[xform.xqm]: https://github.com/xokomola/origami/blob/master/xform.xqm
