Name
====

lua-resty-s3 - upload content to amazon s3 with openresty

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [upload_url](#upload_url)
* [Limitations](#limitations)
* [Installation](#installation)
* [TODO](#todo)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library is still under early development and considered experimental.

Description
===========

This Lua library is a s3 uploading utility for the ngx_lua nginx module:

Synopsis
========

```
    lua_package_path "/path/to/lua-resty-s3/lib/?.lua;;";
    
    server {
        location /test {
            content_by_lua '
                local s3 = require "resty.s3"
                local s3, err = s3:new("aws-id", "aws-key")
                
                final_url, err = s3:upload_url("http://lorempixel.com/400/200/", "examplebucket", "lorempixel400x200")`
            ';
        }
        
        include conf/*.urls;
    }
```

[Back to TOC](#table-of-contents)

Methods
=======

All of the commands return either something that evaluates to true on success, or `nil` and an error message on failure.

new
---
`syntax: s3, err = s3:new(id, key)`

Creates a uploading object. In case of failures, returns `nil` and a string describing the error.

[Back to TOC](#table-of-contents)

upload_url_to_s3
----------------
`syntax: final_url, err = s3:upload_url(file_url, bucket, object_name, check_for_existance, add_to_existance)

`syntax: final_url, err = s3:upload_url("http://lorempixel.com/400/200/", "examplebucket", "lorempixel400x200")`

Attempts to upload content to s3 from the url set by file_url and the id/key set with new(). If object_name is supplied then that will be the name of the new file, otherwise it will hash the file_url to create a unique key for it.

Callbacks for checking something before uploading [again], and after uploading can be supplied in check_for_existance and add_to_existance. Each will be called with the object_name or a hash.

```
local uploaded_content = ngx.shared.uploaded_content

check = function (name)
  ok, err = uploaded_content:get(name)
  if ok then return true end
end

add = function (name)
  ok, err = uploaded_content:add(name)
  return true
end

final_url, err = s3:upload_url("http://lorempixel.com/400/200/", "examplebucket", "lorempixel400x200", check, add)
```

In case of success, returns the new url. In case of errors, returns `nil` with a string describing the error.

[Back to TOC](#table-of-contents)

Limitations
===========



[Back to TOC](#table-of-contents)

Installation
============

If you are using your own nginx + ngx_lua build, then you need to configure the lua_package_path directive to add the path of your lua-nginx-loggin source to ngx_lua's LUA_PATH search path, as in

```nginx
    # nginx.conf
    http {
        lua_package_path "/path/to/lua-resty-s3/lib/?.lua;;";
        ...
    }
```

This package also requires the luasocket and xxhash packages to be installed http://w3.impa.br/~diego/software/luasocket/ , https://github.com/mah0x211/lua-xxhash
```
luarocks install luasocket
```

Ensure that the system account running your Nginx ''worker'' proceses have
enough permission to read the `.lua` file.

[Back to TOC](#table-of-contents)

TODO
====



[Back to TOC](#table-of-contents)

Author
======

James Marlowe "jamesmarlowe" <jameskmarlowe@gmail.com>, Lumate LLC.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012-2014, by James Marlowe (jamesmarlowe) <jameskmarlowe@gmail.com>, Lumate LLC.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule
* the [lua-resty-hmac](https://github.com/jamesmarlowe/lua-resty-hmac) library

[Back to TOC](#table-of-contents)
