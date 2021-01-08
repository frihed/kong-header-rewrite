return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "header_rewrite" (
        "id"           UUID                         PRIMARY KEY,
        "created_at"   TIMESTAMP WITHOUT TIME ZONE  DEFAULT (CURRENT_TIMESTAMP(0) AT TIME ZONE 'UTC'),
        "match"   TEXT                         UNIQUE,
        "rewrite"   TEXT
      );
      DO $$
      BEGIN
        CREATE INDEX IF NOT EXISTS "header_rewrite_matchs" ON "header_rewrite" ("match");
      EXCEPTION WHEN UNDEFINED_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
  },

  cassandra = {
    up = [[
      CREATE TABLE IF NOT EXISTS header_rewrite(
        id          uuid PRIMARY KEY,
        created_at  timestamp,
        match  text,
        rewrite text
      );
      CREATE INDEX IF NOT EXISTS ON header_rewrite(match);
    ]],
  },
}