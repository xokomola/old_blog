---
layout: post
title: Origami - XQuery screen scraping with Extractors
tags: xquery xml html origami
excerpt: Screen scraping with Origami
---

In a [previous post][origami-1] I introduced [Origami][origami] and
showed a little transformation "engine" inspired by XSLT. In this post I
want to look at extracting nodes from an XML or, in this case, an HTML
document.

I want to build a little screen scraper that returns the [New York
Times][nytimes] headline stories from it's frontpage. This example
is similar to the [example][nolen-scrape] in David Nolen's [Enlive
tutorial][nolen].

If you can't wait you can take a look at the [example
code][scrape-example].

## Extracting nodes

Selecting nodes from an XML document is the bread and butter of XPath
and something which can be done directly in regular XQuery
code. Why wrap it in a library function?

- To [decomplect][decomplecting] the process of selecting and extracting
  nodes from HTML documents (the longer term goal being to use them for
  templating).

- To compose extraction processes from smaller re-usable functions.

- To make such code easier to read which probably translates to easier
  to maintain.

Not convinced? Need proof? Good. Let me build a screen scraper that will
fetch the headline stories from the New York Times frontpage.

~~~xquery
let $url := 'http://www.nytimes.com'
let $input := xf:fetch-html($url)
~~~

Simple enough. The `$input` variable now contains an XML document which
was parsed from the New York Times frontpage using the
[TagSoup][tagsoup] parser that comes with BaseX.

Most of the HTML found in the wild is not nearly as neatly structured as
a markup-geek like me would like. It's tag soup. Hence, the name of the
process that tries to extract meaningful information from it: screen
*scraping*. That doesn't sound like a very clean process, does it?

What's more, the developers from the web site will probably not inform
me when they modify their HTML so my little screen scraper may fail
at any moment.

To find the pieces of information in such a tag soup I have to go in and
look at the source. One way to do this is looking at it from a web
browser using it's development tools. Another way is to save the parsed
XML and then use an XML IDE such as Oxygen to study it using some XPath
queries. Or a combination of the two.

Using the Clojure tutorial example, and some digging of my own I came up
with a way to select the story elements from the parsed HTML.

~~~xquery
let $stories := xf:extract(
        xf:select('article[contains(@class, "story")]'));
return
    count($stories($input))
    
=> 130
~~~

It found 130 'stories' but from looking at the web site I figure many of
these are not real stories. Studying the output confirms this. I'll get
back to that near the end of this post.

The `$stories` variable contains a function that, when provided with
some input nodes, will search for nodes matching the provided XPath
expression.

You may wonder why, if `xf:select` is already selecting nodes from the
input document, I wrapped it in `xf:extract`? When I tested this I
found 131 stories with `xf:select`. This is caused by a 'story' article
wrapped inside another one. The `xf:extract` will ensure that only the
unique nodes are returned and no node will also be a descendant of
another node.

Also, an extractor may be using several selectors.

~~~xquery
let $stories := xf:extract((
        xf:select('article[contains(@class, "story")]'),
        xf:select('article[contains(@class, "fairy-tale")]')
))
~~~

What `xf:extract` ensures is that no duplicate nodes are returned and
that all nodes will be returned in document order.

To get the meaningful bits from each story we need a few more
extractors. All of these will act upon a story node selected above.

~~~xquery
let $headline := xf:extract((
  xf:select(('h2', 'a')),
  xf:select(('h3', 'a')),
  xf:select(('h5', 'a'))
))

let $byline := xf:extract(
    xf:select('*[contains(@class, "byline")]')
)

let $summary := xf:extract(
    xf:select('*[contains(@class, "summary")]')
)
~~~

The headlines may be inside a `h2`, `h3`, or `h5`. In this case I've
written them using separate selectors to illustrate a feature of
extractors. But of course, this would be much better expressed as a
single XPath expression.

The headline selectors use two separate XPath expressions (selector
steps). One to find the heading element and then `a` to find the link
element inside the heading. This behaves a bit like a CSS selector such
as `h2 a` which would be equivalent to the XPath expression `h2//a`.

Let's apply them to each story and output some XML.

~~~xquery
for $story in $stories($input)
return
  <story>
    <headline>{ string($headline($story)[1]) }</headline>
    <byline>{ string($byline($story)[1]) }</byline>
    <summary>{ string($summary($story)[1]) }</summary> 
  </story>
~~~

It should be obvious by now that selectors and extractors can be
combined or composed in various ways. A selector for a specific job may
be re-used in different contexts. After all, they are just functions.

But there are a few things that could be improved.

- I want selectors to be a little bit smarter so they provide better
  results.

- There are still empty stories and stories that only have a headline. I
  want to exclude those.

## Smarter Selectors: selector steps

As the headlines selector already showed, a single selector, created by
`xf:select`, may be defined with multiple selector steps.

~~~xquery
let $headline := xf:extract(
    xf:select((
        '((h2|h3|h5)//a)[1]', 
        xf:text(), 
        xf:wrap(<headline/>))))

let $byline := xf:extract(
    xf:select((
        '*[contains(@class, "byline")][1]', 
        xf:text(), 
        xf:wrap(<byline/>))))

let $summary := xf:extract(
    xf:select((
        '*[contains(@class, "summary")][1]', 
        xf:text(), 
        xf:wrap(<summary/>))))
~~~

Besides improving the XPath for selecting the headlines the more
interesting part here is the use of the `xf:text` and `xf:wrap` functions.
There's also an `xf:unwrap` function which removes the outer element.

Together these selector steps form a small node transformation pipeline.
Each node found by the first step in the pipeline is fed into the next
until at the end nodes come out, ... or not.

The selector first looks for nodes satisfying the XPath expression, then
each of them is transformed into a text node and in the last step this
text node is wrapped in a new element. The result will be much more
appealing to a markup-geek like me. Much more so than a bunch of HTML
tags.

Removing incomplete stories is now a no-brainer. The following
FLOWR-expression takes care of that.

~~~xquery
for $story in $stories($input)
let $headline := $headline($story)
let $byline := $byline($story)
let $summary := $summary($story)
where $headline and $byline and $summary
return
  <story>{
    $headline,
    $byline,
    $summary
  }</story>
~~~

Mission accomplised we can get neat, semantic XML scraped from a live
web page. Let's run it now.

~~~xml
<story>
  <headline>Unlikely Allies, Insurers and Obama Defend Health Law</headline>
  <byline>By ROBERT PEAR</byline>
  <summary>Antagonism over profits and regulation has given way to rising 
  revenue for an industry, and legal and logistical support for the Obama 
  administration.</summary>
</story>
<story>
  <headline>Obstacle to Obama’s Immigration Plan: His Own Statements</headline>
  <byline>By MICHAEL D. SHEAR</byline>
  <summary>By using an executive order, President Obama is poised to ignore 
  his longtime opposition to a decision that would shield immigrants from 
  deportation without an act of Congress.</summary>
</story>
...
~~~

## Custom selector step functions

You are not limited to using the provided functions though. The code
for `xf:wrap` serves as a simple example for such a custom function.

~~~xquery
declare function xf:wrap($node) {
    function($nodes) {
        element { node-name($node) } {
            $node/@*, $nodes
        }
    }
};
~~~

The returned function should take one argument (the input nodes) and
produce some output nodes (in this case an element). The input nodes are
provided by the extractor function when you run it.


## Selecting on HTML class attributes

One final touch that I would like to add is a more correct way to select
on the class attribute. Doing `contains(@class, 'foo')` is not correct
because this would also match something like `<div class="foobar"/>`.
To do it correctly you can use `'foobar' = tokenize(@class, '\s+')` but
this would not read very well inside a selector. In an XPath expression
you can use the `$in` convenience function to do this without the
clutter.

~~~xquery
let $select-byline := xf:extract(
    xf:select((
        '*[$in(@class, "byline")][1]',
        xf:text(), 
        xf:wrap(<byline/>))))
~~~


## Wrap up

I have shown that coding a screen scraper in XQuery can be fun and even
lead to pretty code.

Next, I want to incorporate the same techniques used for the Extractors
into the [Transformers][origami-1]. The latter still use the quite lame
element name selectors and I would like that they also employ the much
more powerful selector functions. Along the way I'll probably be
refactoring the code once more so do expect changes to how things work.
Welcome to the cutting edge.

All this should conclude the groundwork necessary for building out the
full templating functionality which will be needed before calling this
1.0.

[decomplecting]: http://www.infoq.com/presentations/Simple-Made-Easy
[tagsoup]: http://home.ccil.org/~cowan/XML/tagsoup#program
[scrape-example]: https://github.com/xokomola/origami/blob/master/examples/ny-times.xq
[nytimes]: http://www.nytimes.com
[nolen]: https://github.com/swannodette/enlive-tutorial
[nolen-scrape]: https://github.com/swannodette/enlive-tutorial/#your-third-scrape--the-new-york-times
[origami-1]: http://xokomola.com/2014/11/10/xquery-origami-1.html
[origami]: https://github.com/xokomola/origami
[enlive]: https://github.com/cgrand/enlive
