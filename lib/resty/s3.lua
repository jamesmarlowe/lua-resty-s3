-- Copyright (C) James Marlowe (jamesmarlowe), Lumate LLC.


local xxhash = require "xxhash"
local url = require "socket.url"
local hmac = require "hmac"
local hash_seed = 0x1db1e298
local upload_url = "/s3/upload/"


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


function _M.generate_auth_headers(self, content_type, destination)
    local id, key = self.id, self.key
    
    if not id or not key then
        return nil, "not initialized"
    end
    
    local date = os.date("%a, %d %b %Y %H:%M:%S +0000")
    local hm, err = hmac:new(key)
    local StringToSign = "PUT"..string.char(10)..string.char(10)..content_type..string.char(10)..date..string.char(10)..destination
    headers, err = hm:generate_headers("AWS", id, "sha1", StringToSign)
    
    return headers, err
end


function _M.try_upload(self, content, destination, content_type, headers)
    local id, key = self.id, self.key
    
    if not id or not key then
        return nil, "not initialized"
    end
    
    local retry = 0
    while (not resp or resp.status ~= 200) and retry < 3 do
        resp = ngx.location.capture(
              upload_url,
            { method = ngx.HTTP_PUT,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination, mime=content_type}}
        )
        retry = retry + 1
    end
    
    return resp
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
    
    if not object_name then object_name = xxhash.xxh32(file_url, hash_seed) end
    
    local destination = bucket..object_name
    local s3_url = "http://s3.amazonaws.com"
    local final_url = s3_url..destination
    local content_type = "binary/octet-stream"
    
    if check_for_existance and check_for_existance(object_name) then
        return final_url
    end
    
    file_url = url.parse(file_url)
    file_content = ngx.location.capture("/proxy/", {args={host=file_url.host,uri=file_url.path}})
    
    if file_content.status == 200 then 
        local headers = self:generate_auth_headers(content_type, destination)
        if not headers then return headers, err end
        
        local res = self:try_upload(file_content.body, destination, content_type, headers)

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


function _M.extract_urls(self, file_content, bucket)
    pos = 1
    for st,sp in function() return file_content:find([["]],pos, true) end do
        sp = file_content:find([["]],st+1, true)
        embedded_url = file_content:sub(st, sp)
        
        if embedded_url:find("//", 1, true) then
            embedded_url = embedded_url:sub(0,embedded_url:find("?", 1, true))
            
            if embedded_url:find(".", -6, true) then
                object_name = xxhash.xxh32(embedded_url, hash_seed)
                new_url, err = self:upload_url(embedded_url, bucket, object_name, check_for_existance, add_to_existance)
                
                if not new_url then 
                    file_content = file_content:sub(0,st)..file_content:sub(sp)
                    sp = st+1
                    
                else
                    file_content = file_content:sub(1,st)..new_url..[["]]..file_content:sub(sp)
                    sp= st+#new_url+1
                    
                end
            else
                file_content = file_content:sub(0,st)..file_content:sub(sp)
                sp = st+1
                
            end
        end
        pos = sp + 1
    end
    
    return file_content
end


function _M.upload_media_to_s3(self, file_content, bucket, object_name, check_for_existance, add_to_existance)
    local id, key = self.id, self.key
    
    if not id or not key then
        return nil, "not initialized"
    end
    
    if not file_content then
        return nil, "nothing to upload"
    end
    
    if not bucket then
        return nil, "unknown bucket"
    end
    
    if not object_name then object_name = xxhash.xxh32(file_content, hash_seed) end
    
    local destination = bucket..object_name
    local s3_url = "http://s3.amazonaws.com"
    local final_url = s3_url..destination
    local content_type = "text/html"
    
    if check_for_existance and check_for_existance(object_name) then
        return final_url
    end

    file_content = self:extract_urls(file_content, bucket)
    
    headers, err = self:generate_auth_headers(self, content_type, destination)
    if not headers then return headers, err end
    
    local resp = self:try_upload(file_content, destination, content_type, headers)
    
    if resp.status == 200 then
        if add_to_existance then
            add_to_existance(object_name)
        end
        return final_url
    else
        return nil, "could not upload"
    end
end



return _M
