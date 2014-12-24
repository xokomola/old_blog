---
layout: post
title: Origami - HTML view templates
tags: xquery xml html origami
excerpt: Building an HTML view from HTML templates
---

It's been a while and work has progressed. Soon I will be tagging
[Origami][origami] as 0.4. I have revised my old posts so the code
examples work with the current code. I will also be updating the
project [wiki pages][wiki].

The [first post][origami-1] introduced `xf:transform` to build small
transformations similar to XSLT. The [second][origami-2] introduced
another useful type of transformation using the `xf:extract` function
and I showed how to implement a little screen-scraping example using it.

Now I want to combine both flavors of transformation and introduce the
`xf:template` function to create an HTML view from several template
files. I will be piecing the view together from three different HTML
files. Without introducing templating markup into the HTML.

The code in this example is a bit more involved but once you worked
through the code, I hope, you will appreciate it. Like in the
[screenscraper post][origami-2], this example is copied from an [Enlive
tutorial][nolen]. Enlive is a great example of a templating library. It
keeps all code where it belongs, in the code, and doesn't introduce any
markup into the template documents. Separation of concerns *avant la
lettre*. Implementing a moderately complex Enlive example will be a neat
testcase for Origami.

One word of warning, though, before I start. I lean very heavily on the
functional features that are part of XQuery 3.0 and 3.1 and also on
evaluating dynamic XPath strings. Some of my tests showed that this
approach has a performance penalty and if you expect to be able to
express more complex XSLT-type transformations using this library you
will be disappointed.

My guiding design principles are simplicity and composability. Not
performance. First I want to make it work well, then I can, hopefully,
also make it faster.

Some other limitations that still exist I will address in the next
release (0.5), this includes namespace support and more thorough
testing.


## Introducing templates

In previous posts I discussed two kind of transformations: extractors
(`xf:extract`) and transformers (`xf:transform`). The former uses rules
to pick specific nodes out of a document. The latter uses rules to
transform a complete document.

Now it's time to introduce the missing function: `xf:template`. This
function uses both of these transformation types.

But first we need to have some template files to work with. In this
example there are three HTML files:

- `base.html` contains the page "shell", the HTML document which
  contains the main areas of the view (title, header, main content area
  and footer).
  
- `3col.html` contains HTML to divide the main content area in three
  columns.
  
- `navs.html` contains three navigation panels that we'll plug into the
  main area.

The source for this example can be found on [Github][examples] in
particular [nolen.xq][example-a] and [nolen_rest.xqm][example-b].

The XQuery code starts with the usual declarations (you may have to
modify the path to the Origami core module) and an option that sets the
output serialization to HTML (which, among other things, ensures that
empty elements are output with HTML syntax rules). The last clause
declares a convenience function for loading a template relative to the
code directory.

~~~xquery
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare option output:method "html";

let $tpl := function($name) {
  xf:html-resource(file:base-dir() || $name)
}
~~~

The main focus of this post is the `xf:template` function. It comes in
two flavors.

### Templates

The first flavor requires two arguments. The first argument provides the
template nodes, the second provides the transformation rules.

~~~xquery
xf:template(
  $tpl('base.html'),
  (
    ['*[@id="title"]', xf:content(text { 'The Title' }) ],
    ['*[@id="header"]', xf:content(text { 'The Header' }) ],
    ['*[@id="main"]', xf:content(text { 'Main content area' }) ],
    ['*[@id="footer"]', xf:content(text { 'The Footer' }) ]
  )
)
~~~

If you read the [first post][origami-1] of this series, you recognize
this is similar to a transformer created with `xf:transform`. Well, to
make this a proper template we need to be able to provide input data
that will be used as content for the various areas.

When providing a sequence of rules `xf:template` will return a function
without any arguments. This doesn't have to stop you from directly
including code in the transform part of each rule but that is not much
of a template.

To make the template function use arguments you need to use a model
function. So let's create a model function that pushes data into
the template.

~~~xquery
let $base := xf:template(
    $tpl('base.html'),
    function($data as map(*)) {
      ['*[@id="title"]', xf:content($data('title')) ],
      ['*[@id="header"]', xf:content($data('header')) ],
      ['*[@id="main"]', xf:content($data('main')) ],
      ['*[@id="footer"]', xf:content($data('footer')) ]  
    }
)
~~~

The `$base` variable is a function that receives a map and it will use
the model rules to include the data in the correct places. So
`xf:template` glues input template and the transformation model rules
together to create a function that can be called like this:

~~~xquery
$base(map { 'title': 'The title', 'header': 'The Header })
~~~

This will output the base template with the title and header replaced.

### Snippets

To use the other templates we cannot use the whole document, we need to
select only specific parts. Hey, that's just what `xf:extract` already
does! Indeed. So just as the two argument flavor of `xf:template`
provides `xf:transform` functionality, the three argument flavor of
`xf:template` provides `xf:extract` functionality.

For example the three column template.

~~~xquery
let $three-col :=
  xf:template(
    $tpl('3col.html'),
    ['div[@id="main"]'],
    function ($left, $middle, $right) {
      ['div[@id="left"]', xf:content($left) ],
      ['div[@id="middle"]', xf:content($middle) ],
      ['div[@id="right"]', xf:content($right) ]
    }
  )
~~~

The extra (second) argument is a node selector that picks out the main
div element from the HTML file. The model is provided as an anonymous
function as it's not needed in other places.

Now I do the same for the three navigation panels. Here I choose to define
the model in a named function because it will be re-used for all three
panels.

~~~xquery
let $nav-model := function($list as element(list)) {
   ['span[@class="count"]', 
     xf:content(xf:text(count($list/item))) ],
   ['div[text()][1]', 
     xf:replace(for $item in $list/item return <div>{ string($item) }</div>) ],
   ['div[text()]', () ]
}
~~~

This is typical for this type of templating. We push the content in the
correct places but we sometimes also need to remove some example text
that the template may hold (see the `div[text()]` rule).

At this point I have to note that `xf:template` will inspect the model in order
to decide what type of function to return. However, it will only use functions
with 4 arguments or less. This seems like a reasonable value. If you need more
it may be better to use something like a map instead. Your models may use
any type of data even other XML nodes. It's up to you.

Here are the three navigation panels that use this model.

~~~xquery
let $nav1 := xf:template($tpl('navs.html'), ['div[@id="nav1"]'], $nav-model)
let $nav2 := xf:template($tpl('navs.html'), ['div[@id="nav2"]'], $nav-model)
let $nav3 := xf:template($tpl('navs.html'), ['div[@id="nav3"]'], $nav-model)
~~~

Now anytime you want to render a list in one of these panels it's a matter
of providing the list.

~~~xquery
$nav1(<list><item>A</item><item>B</item></list>)
~~~

## Baking the cake

Origami templates let you use all the power of XQuery and there are many
ways to combine these functions to create a flexible view system.

First a simple view without content. By now you won't be surprised when I tell
you that a view is .... just another function.

~~~xquery
let $viewa := function() {
  $base(
    map {
      'title': "View A", 
      'main': $three-col((),(),())
    }
  )  
}
~~~

What's happening here? When calling this function the `$base` template
function is called with a map with a title and some main content. This
main content is created by calling the `$three-col` function with the
three arguments (`$left`, `$middle` and `$right`). In this case they are
empty which means as much as don't change the existing content.

Another view.

~~~xquery
let $viewb := function($left, $right) {
  $base(
    map {
      'title': "View B", 
      'main': $three-col($left, (), $right)
    }
  )  
}
~~~

Almost the same except that it takes two arguments, one for the left
column and one for the right column. This content is passed through to
the `$three-col` template, leaving the middle column like it was.

And yet another.

~~~xquery
let $viewc := function($action) {
  let $navs :=
    if ($action = 'reverse') then
      ($nav2, $nav1)
    else
      ($nav1, $nav2)
  return
    $base(
      map {
        'title': "View C",
        'header': "Templates a go-go",
        'footer': "Origami Template",
        'main': $three-col($navs[1](), (), $navs[2]())
      }
    )
}
~~~

This demonstrates that you can use any trick in the XQuery book to use
the view arguments and turn them into calls into the templates. In this
case when you ask for `$view('reverse')` it will swap the two navigation
panels.

## Eating the cake

I have included two code examples based on the example in this post. The
[first][example-a] can be run as a stand-alone XQuery script. The
[other][example-b] is slightly different but shows how to use this code
in a RESTXQ web application.

The declarations for the different functions are slightly different
because RESTXQ uses an XQuery module but otherwise the code is the same.

To *wire-up* a template function using RESTXQ you should define a
handler function that invokes the template function. This may take
arguments from the HTTP request to modify the view or which data is
fetched.

~~~xquery
declare 
    %rest:path("origami") 
    %rest:GET 
    %output:method("html")
    function app:main() {
        app:index(
            map { 
                'title': 'My Index', 
                'header': 'A boring header', 
                'footer': 'A boring footer',
                'main': $app:three-col(
                            $app:nav1($app:list1), 
                            $app:nav2($app:list2), 
                            $app:nav3($app:list1))
            }
        )
};
~~~

I didn't show how the CSS file is served. A better way to do this would
be to serve it via Jetty directly (by modifying `web.xml`) and not via
another REST call as I did in the example.

## Wrap up

This was a long post and a lot of new things have been introduced. In
the next post I will use this example and hook it up to the Web using
[Fold][fold] (another library I created) but you may already start now
by using RESTXQ for example.


[wiki]: https://github.com/xokomola/origami/wiki
[example-a]: https://github.com/xokomola/origami/blob/master/examples/nolen.xq
[example-b]: https://github.com/xokomola/origami/blob/master/examples/nolen_rest.xqm
[nolen]: https://github.com/swannodette/enlive-tutorial
[examples]: https://github.com/xokomola/origami/tree/master/examples
[origami-2]: http://xokomola.com/2014/11/18/xquery-origami-2.html
[origami-1]: http://xokomola.com/2014/11/10/xquery-origami-1.html
[origami]: https://github.com/xokomola/origami
[fold]: https://github.com/xokomola/fold
