local cache_warmup = require "kong.cache_warmup"
local BasePlugin = require "kong.plugins.base_plugin"
local kong = kong
local HeaderRewriteHandler = BasePlugin:extend()

HeaderRewriteHandler.VERSION  = "1.0.0"
HeaderRewriteHandler.PRIORITY = 2900

local function get_cache(key)
    local cache_key = kong.db.header_rewrite:cache_key(key)
    return kong.cache:probe(cache_key)
end

local function rewrite_value(header)
    local ttl, err, value = get_cache(header)  -- ttl is nil
    if err then
      kong.log.err(err)
      return kong.response.exit(500, "An unexpected error occurred")
    end
    return value  --is table
end

local function execute(config)
    local header = ngx.req.get_headers()[config.match]

    if header then
        local entity = rewrite_value(header)
        if entity and entity.rewrite ~= ngx.req.get_headers()[config.rewrite] then 
            kong.log.info("rewrite to " .. entity.rewrite)
            ngx.req.set_header(config.rewrite, entity.rewrite)
        end
    end
end

function HeaderRewriteHandler:new()
    HeaderRewriteHandler.super.new(self, "header-rewrite")
end

function HeaderRewriteHandler:init_worker()
    HeaderRewriteHandler.super.init_worker(self)
    -- load all cache
    local ok, err = cache_warmup.execute({"header_rewrite"})
    if not ok then
        kong.log.err("load cache error" .. err)
      return nil, err
    end
    -- listen to CRUD operation, note: only Create 
    kong.worker_events.register(function(data)
        if data.operation == "create" or data.operation == "update" then
            local key = data.entity.match
            kong.log("add header_rewrite cache, match: " .. key)
            local cache_key = kong.db.header_rewrite:cache_key(key)
            local ok, err = kong.cache:safe_set(cache_key, data.entity);
            if err then
                kong.log.err(err)
            end
        end
    end, "crud", "header_rewrite")
end


function HeaderRewriteHandler:rewrite(conf)
    HeaderRewriteHandler.super.rewrite(self)
    execute(conf)
end

return HeaderRewriteHandler