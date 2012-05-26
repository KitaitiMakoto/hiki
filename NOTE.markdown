API for HikiDB_RDBMS
====================

* Methods around cache needed for diff display
* Use citext type field to search case insensitively
* Limit byte length of `pages.title` to `config.max_name_size`
* Move `HikiDBBase#load_cache` to `HikiDB_flatfile`
* Move method `#exist?`(abnel to accept block) or at lest calling for `@db.select` in `Command#exist?` from `Command` to `HikiDB_xxx` and remove `#select` from `HikiDB_xxx`

From HikiDBBase(hiki/storage.rb)
---------------

* `#open_db` - block acceptable
* `#close_db`
* `#pages`
* `#backup( page )`
* `#delete( page )`
* `#md5hex( page )`
* `#search( w )` - search from keyword, title and page content
* `#load_cache( page )`
* `#save_cache( page, tokens )`
* `#delete_cache( page )`

`load` is called from some method

From HikiDB_flatfile(hiki/db/flatfile.rb)
--------------------

* `attr_reader :pages_path`
* `#initialize( conf )`
* `#store( page, text, md5, update_timestamp = true )`
* `#unlink( page )`
* `#load( page )`
* `#load_backup( page )`
* `#exist?( page )`
* `#backup_exist?( page )`

### info DB

* `#info_exist?( p )`
* `#infodb_exist?`
* `#info( p )`
* `#page_info` - info of all page
* `#set_attribute(p, attr)` - `unescaped_pagename`, `{key => value}`
* `#get_attribute(p, attribute)` - returns default if `attribute` doesn't exist
* `#select` - acceptable block and pass arg `|page_info|`
* `#increment_hitcount( p )`
* `#get_hitcount( p )`
* `#freeze_page( p, freeze )` - `freeze` is true or false
* `#is_frozen?( p )`
* `#set_last_update( p, t )`
* `#get_last_update( p )`
* `#set_references(p ,r)`
* `#get_references(p)`

TODO
----

* `HikiDB_rdbms#search`
* `Remove Hiki::Cookie`, considering `Plugin#session_id`
  * Think about session secret
* Hikifarm
* XML-RPC
