-- Table: info_common

-- DROP TABLE info_common;

CREATE TABLE info_common
(
  account_id integer NOT NULL,
  clan_id integer,
  client_language character(2),
  global_rating integer,
  created_at timestamp without time zone,
  updated_at timestamp without time zone,
  last_battle_time timestamp without time zone,
  logout_at timestamp without time zone,
  CONSTRAINT info_common_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE info_common
  OWNER TO wotstatsadmins;
