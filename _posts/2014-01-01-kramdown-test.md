---
layout: post
title: Kramdown test
summary: Using the Kramdown renderer.
published: true
nocomments: true
---

#### Top                                                              {#top}

The [kramdown parser][kd] is a parser for a superset of markdown. This page
exercises some of them. GitHub supports it?! See the [syntax][kdsyn]
documentation.

#### Blockquotes                                                       {#bq}

The following shows one blockquote with two paragraphs.

> This is a blockquote.
>     on multiple lines
that may be lazy.
>
> This is the second paragraph.

Nested blockquotes.

> This is a paragraph.
>
> > A nested blockquote.
>
> #### Headers work
>
> * lists too
>
> and all other block-level elements

Code block in a blockquote.

> A code block:
>
>     ruby -e 'puts :works'

#### Code blocks                                                     {#code}

Normal code block (blank lines do not finish a code block).

    Here comes some code

    This text belongs to the same code block.

Two code blocks using an explicit EOB (end of block) marker.

    Here comes some code
^
    This one is separate.

Code block using separator lines (no indentation needed).

~~~~~~~~~~~~
~~~~~~~
code with tildes
~~~~~~~~
~~~~~~~~~~~~~~~~~~

Code block with language (using IAL). Note that this doesn't work as expected
(Pygments won't kick in) in Jekyll so instead use the Liquid instruction
variant below.

What this does (which can be used to make this work in CSS) is that it uses a generic notation to add a class attribute to the inserted `code` element.

~~~
def what?
  42
end
~~~
{: .language-ruby}

Code block with language (using Liquid)

{% highlight ruby %}
def print_hi(name)
  puts "Hi, #{name}"
end
print_hi('Tom')
#=> prints 'Hi, Tom' to STDOUT.
{% endhighlight %}

Or a so-called fenced code block.

~~~ ruby
def what?
  42
end
~~~

#### Lists                                                          {#lists}

An unordered and an ordered list.

* kram
+ down
- now

1. kram
2. down
3. now

Using more complex indentations.

* This is the first line. Since the first non-space characters appears in
  column 3, all other indented lines have to be indented 2 spaces.
However, one could be lazy and not indent a line but this is not
recommended.
*       This is the another item of the list. It uses a different number
   of spaces for indentation which is okay but should generally be avoided.
   * The list item marker is indented 3 spaces which is allowed but should
     also be avoided and starts the third list item. Note that the lazy
     line in the second list item may make you believe that this is a
     sub-list which it isn't! So avoid being lazy!

Compact lists

Note that the [syntax][kdsyn] documentation has many more special cases that
need to be taken into account with list rendering and lists.

*   This is just text.
    * this is a sub list item
      * this is a sub sub list item
* This is just text,
    spanning two lines
  * this is a nested list item.

Definition lists

**kramdown**
: A Markdown-superset converter

**Maruku**
:     Another Markdown-superset converter

A more complex example, also illustrating how indentation is handled.

definition term 1
definition term 2
: This is the first line. Since the first non-space characters appears in
column 3, all other lines have to be indented 2 spaces (or lazy syntax may
  be used after an indented line). This tells kramdown that the lines
  belong to the definition.
:       This is the another definition for the same term. It uses a
        different number of spaces for indentation which is okay but
        should generally be avoided.
   : The definition marker is indented 3 spaces which is allowed but
     should also be avoided.

#### Tables                                                        {#tables}

A simple table example

| First cell|Second cell|Third cell
| First | Second | Third |

First | Second | | Fourth |

A multi-line cell table

|-----------------+------------+-----------------+----------------|
| Default aligned |Left aligned| Center aligned  | Right aligned  |
|-----------------|:-----------|:---------------:|---------------:|
| First body part |Second cell | Third cell      | fourth cell    |
| Second line     |foo         | **strong**      | baz            |
| Third line      |quux        | baz             | bar            |
|-----------------+------------+-----------------+----------------|
| Second body     |            |                 |                |
| 2 line          |            |                 |                |
|=================+============+=================+================|
| Footer row      |            |                 |                |
|-----------------+------------+-----------------+----------------|

Which can also be written in a more compact form. The following table
should be identical to the one above.

|---
| Default aligned | Left aligned | Center aligned | Right aligned
|-|:-|:-:|-:
| First body part | Second cell | Third cell | fourth cell
| Second line |foo | **strong** | baz
| Third line |quux | baz | bar
|---
| Second body
| 2 line
|===
| Footer row

#### Math                                                            {#math}

Note that match blocks aren't shown when using Jekyll.

$$
\begin{align*}
  & \phi(x,y) = \phi \left(\sum_{i=1}^n x_ie_i, \sum_{j=1}^n y_je_j \right)
  = \sum_{i=1}^n \sum_{j=1}^n x_i y_j \phi(e_i, e_j) = \\
  & (x_1, \ldots, x_n) \left( \begin{array}{ccc}
      \phi(e_1, e_1) & \cdots & \phi(e_1, e_n) \\
      \vdots & \ddots & \vdots \\
      \phi(e_n, e_1) & \cdots & \phi(e_n, e_n)
    \end{array} \right)
  \left( \begin{array}{c}
      y_1 \\
      \vdots \\
      y_n
    \end{array} \right)
\end{align*}
$$

The following is a math block:

$$ 5 + 5 $$

But next comes a paragraph with an inline math statement:

\$$ 5 + 5 $$

#### Text Markdown                                                 {#markup}

Simple links

Information can be found on the <http://example.com> homepage.
You can also mail me: <me.example@example.com>

Inline links

This is [a link](http://rubyforge.org) to a page.
A [link](../test "local URI") can also have a title.
And [spaces](link with spaces.html)!

Reference links

This is a [reference style link][linkid] to a page. And [this]
[linkid] is also a link. As is [this][] and [THIS].

[linkid]: http://www.example.com/ "Optional Title"

Images

Here comes a ![smiley](/img/soc_rss.png)! And here
![too](/img/soc_rss.png 'Title text'). Or ![here].
With empty alt text ![](/img/soc_rss.png)

Emphasis

*some text*
_some text_
**some text**
__some text__

This is un*believe*able! This d_oe_s not work!

This is a ***text with light and strong emphasis***.
This **is _emphasized_ as well**.
This *does _not_ work*.
This **does __not__ work either**.

Code spans

Use `<html>` tags for this.

Footnotes

This is some text.[^1]. Other text.[^footnote].

[^1]: Some *crazy* footnote definition.

[^footnote]:
    > Blockquotes can be in a footnote.

        as well as code blocks

    or, naturally, simple paragraphs.

[^other-note]:       no code block here (spaces are stripped away)

[^codeblock-note]:
        this is now a code block (8 spaces indentation)

Note that the footnote definitions are moved to the bottom of the page (below
the next section).

Abbreviations

This is some text not written in HTML but in another language!

*[another language]: It's called Markdown
*[HTML]: HyperTextMarkupLanguage

Typographic Symbols

* --- (`---`) will become an em-dash (like this —)
* -- (`--`) will become an en-dash (like this –)
* ... (`...`) will become an ellipsis (like this …)
* << (`<<`) will become a left guillemet (like this «) – an optional following space will become a non-breakable space
*\ >> (`>>`) will become a right guillemet (like this ») – an optional leading space will become a non-breakable space

#### Indentation

Kramdown expands tabs to four spaces when doing calculations and applying
indentation rules.

---
Go to [top](#top)

[kd]: http://kramdown.gettalong.org
[kdsyn]: http://kramdown.gettalong.org/syntax.html
