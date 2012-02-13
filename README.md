[![build_status](https://secure.travis-ci.org/fredemmott/my_stuff-multidb.png)](http://travis-ci.org/fredemmott/my_stuff-multidb)

Overview
========

This provides an API to easily use ActiveRecord with multiple connections - for example:

* Reading from slaves
* Using multiple shards

Usage
=====

````ruby

module MyDB
  class Widget < ActiveRecord::Base; end
  include MyStuff::MultiDB
end

MyDB.with_spec(:adapter => 'sqlite3', :database => ':memory:') do |db,spec|
  db::Widget.create(...)
end
````


How It Works
============

For every spec, it defines a new sub-module of MyStuff::MultiDB, which
encodes the database details, and creates new subclasses of your
ActiveRecord::Base classes, within these modules. For example:

````
$ bin/my_stuff-multidb-unmangle MyStuff::MultiDB::MYSTUFF_MULTIDB_DB_216c6f63616c686f7374213333303621::MyDB::Widget
MyStuff::MultiDB::<localhost:3306/>::MyDB::Widget
$
````

There's also lots of deep voodoo making the ActiveRecord stack use the right
connection details :)

Caveats
=======

You can not do cross-shard operations simply, eg joins.

License
=======

````
Copyright (c) 2011-2012, Fred Emmott <copyright@fredemmott.co.uk>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
````