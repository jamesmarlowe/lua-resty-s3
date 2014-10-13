package = "lua-resty-s3"
version = "v1.0-1"

source = {
  url = "git://github.com/jamesmarlowe/lua-resty-s3.git"
}

description = {
  summary = "Upload content to amazon s3 with OpenResty",
  homepage = "https://github.com/jamesmarlowe/lua-resty-s3",
  license = "BSD",
  maintainer = "jameskmarlowe@gmail.com"
}

dependencies = {
  "lua >= 5.1",
  "lua-resty-hmac",
  "luasocket",
  "xxhash"
}

build = {
    type = "builtin",
    modules = {
        ["resty.s3"] = "lib/resty/s3.lua"
    }
}
