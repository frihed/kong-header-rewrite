local cache_warmup = require "kong.cache_warmup"
local BasePlugin = require "kong.plugins.base_plugin"
local kong = kong
local HeaderRewriteHandler = BasePlugin:extend()

HeaderRewriteHandler.VERSION  = "1.0.0"
HeaderRewriteHandler.PRIORITY = 2900

local function load_from_db(key)
    local entity, err = kong.db.header_rewrite:select_by_match(key)
    if err then
        kong.log.err(err)
    end
    return entity
end

local function set_entity_cache(entity)
    kong.log("add header_rewrite cache, match: " .. entity.match)  -- default level is notice
    local cache_key = kong.db.header_rewrite:cache_key(entity.match)
    local ok, err = kong.cache:safe_set(cache_key, entity);
    if not ok then
        kong.log.err(err)
    end
end

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
            kong.log("rewrite to " .. entity.rewrite)
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
    -- listen to CRUD operation, note: Create and Update
    kong.worker_events.register(function(data)
        if data.operation == "create" or data.operation == "update" then
            set_entity_cache(data.entity)
            kong.log("broadcasting header_rewrite_update for key: '", key, "'")
            local ok, err = kong.cluster_events:broadcast("header_rewrite_update", key)
            if not ok then
                kong.log.err("header_rewrite failed to broadcast cached entity : ", err)
            end
        end
    end, "crud", "header_rewrite")

    local ok, err = kong.cluster_events:subscribe("header_rewrite_update", function(key)
        kong.log.notice("received header_rewrite_update event from cluster for key: '", key, "'")
        local entity = load_from_db(key)
        if entity then
            set_entity_cache(entity)
        end
    end)
    if not ok then
        kong.log.err("failed to subscribe to header_rewrite_update cluster events ", err)
    end
end


function HeaderRewriteHandler:rewrite(conf)
    HeaderRewriteHandler.super.rewrite(self)
    execute(conf)
end

return HeaderRewriteHandler