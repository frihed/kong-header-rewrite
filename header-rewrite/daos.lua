local typedefs = require "kong.db.schema.typedefs"

return {
    header_rewrite = {
    primary_key = { "id" },
    name = "header_rewrite",
    endpoint_key = "match",
    cache_key = { "match" },
    generate_admin_api = true,
    fields = {
      { id = typedefs.uuid },
      { created_at = typedefs.auto_timestamp_s },
      { match = { type = "string", required = true, unique = true }, },
      { rewrite = { type = "string", required = true }, },
    },
  },
}
