local typedefs = require "kong.db.schema.typedefs"

return {
  name = "header-rewrite",
  fields = {
    { consumer = typedefs.no_consumer },
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { match = { type = "string", default = "accountId" }, },
          { rewrite = { type = "string", default = "groupName" }, },
        },
      }, 
    },
  },
}
