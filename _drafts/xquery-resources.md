---
layout: post
title: An abstraction for resources in BaseX
tags: xquery xml
---

Need to process filesystem or database resources with XQuery or XSLT?
Use this resource module to make this easier.

## Background

Recently we integrated BaseX in one of our products which is a kind of
CMS. For more than a year we also started to offer this application in
several languages. This requires exporting all content as XML and
converting it to XLIFF[^1] using XSLT. For the first round of
translations I used Gradle to coordinate the various processing steps
for converting from and to XLIFF.

Now that this application has all content cached in a BaseX database we
can start adding content services API and also standardize the
processing of content for translation using XQuery.

This article describes a small XQuery module that I started to make a
certain type of document-processing easier. I use it in the XQuery
application that handles the localization for our products.

The source code for this module is available on Github. I am interested
in making this code available for other databases as well.

This article takes you through the module but for the details you should
go to he source code.

## Resource Sets

The first abstraction that I created for this module was the concept
of a resource set. It is modelled after Apach Ant's file set.

A resource set can be described as an XML structure.

~~~~xquery
declare variable $xml :=
  <resources id="xliff" base="outbox/_to-trans">
    <selectors>
      <include select="*_{lang}.xlf"/>
    </selectors>
  </resources>;
~~~~

How can we use this in XQuery code.

~~~~xquery
let $meta := map { 'lang': 'nl' }
let $set := res:resource-set($xml)
for $res in res:resources($set, $meta)
  return res:uri($res)
~~~~

The resource set is resolved into a sequence of resource references
using the `res:resources` function and you can iterate over them. In
this example the URI of the resource is returned.

Note that we can use metadata variables inside the paths that select
files. The `lang` variable is provided as part of the resource set
metadata or when resolving the set into conrete resources.

An XSLT transformation can be run over the entire resource set and the
resulting files stored.

~~~~xquery
let $meta := map { 'lang': 'nl' }
let $set := res:resource-set($xml)
let $xsl := res:file-ref('/project/foo.xsl')
for $res in res:resources($set, $meta)
  let $output := res:map-base($res, '/tmp')
  return
    res:write($output,
      xslt:transform(res:uri($res), res:uri($xsl)))
~~~~

## Resources

The module defines several different types of resources and in some
cases one type can be mapped onto another.

- Filesystem reference
- Database reference
- Inline documents
- Cached documents

A resource set is a kind of recipe for creating a sequence of resource
references. A resource sequence can also be created by just lining them
up. However, what is an indivdual resource. In fact it's a resource
reference and it may point to an existing or not (yet) existing
resource.

It can also be located in a database collection. When transforming
content like in the example above it is almost trivial to change the
output to be stored in the database instead of on the filesystem.

Inline documents store XML documents or small fragments. We can
serialize them but in many cases this will be used for transient XML
structured such as the intermediate document in between two XSLT
transformations.

Finally cached documents are similar are a mix of filesystem and
database resource references. You can update a database document based
on the last-modified date of the filesystem resource, in a way it's like
a file cache.

## Resource Mapping

## Resource Metadata

----

[^1]: XLIFF is an OASIS localization standard and offers a standardized
      way to interchange translatable content.
      
