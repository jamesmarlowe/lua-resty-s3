-- Copyright (C) James Marlowe (jamesmarlowe), Lumate LLC.


local xxhash = require "xxhash"
local url = require "socket.url"
local hash_seed = 0x1db1e298


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.01'


local mt = { __index = _M }


function _M.new(self, id, key)
    local id, key = id, key
    
    if not id then
        return nil, "must provide id"
    end
    if not key then
        return nil, "must provide key"
    end
    
    return setmetatable({ id = id, key = key }, mt)
end


function _M.upload_url(self, file_url, bucket, object_name, check_for_existance, add_to_existance)
    local id, key = self.id, self.key
    
    if not id or not key then
        return nil, "not initialized"
    end
    
    if not file_url then
        return nil, "nothing to upload"
    end
    
    if not bucket then
        return nil, "unknown bucket"
    end
    
    if not object_name then object_name = xxhash.xxh32(file_url, hash_seed)
    
    local destination = bucket..url_hash
    local s3_url = "http://s3.amazonaws.com"
    local final_url = s3_url..destination
    local content_type = "binary/octet-stream"
    
    if check_for_existance and check_for_existance(object_name) then
        return final_url
    end
    
    file_url = url.parse(file_url)
    file_content = ngx.location.capture("/proxy/", {args={host=file_url.host,uri=file_url.path}})
    
    if file_content.status == 200 then 
        -- generate auth requirements for s3
        local date = os.date("%a, %d %b %Y %H:%M:%S +0000")
        local hm, err = hmac:new(key)
        local StringToSign = "PUT"..string.char(10)..string.char(10)..content_type..string.char(10)..date..string.char(10)..destination
        headers, err = hm:generate_headers("AWS", id, "sha1", StringToSign)
        
        -- upload the ad media to s3
        local retry = 0
        while (not res or res.status ~= 200) and retry < 3 do
            res = ngx.location.capture(
                  "/s3/upload/",
                { method = ngx.HTTP_PUT,
                  body = file_content.body,
                  args = {date=headers.date, auth=headers.auth, file=destination, mime=content_type}}
            )
            retry = retry + 1
        end

        if res.status == 200 then
            if add_to_existance then
                add_to_existance(object_name)
            end
            
            return final_url
        else
            return nil, "could not upload"
        end
    else
        return nil, "could not get url: "..url.build(file_url)
    end
end
