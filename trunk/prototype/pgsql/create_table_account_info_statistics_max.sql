-- Table: info_statistics_max

-- DROP TABLE info_statistics_max;

CREATE TABLE account_info_statistics_max
(
  account_id integer NOT NULL,
  max_xp_tank_id integer,
  max_xp integer,
  max_damage_vehicle integer,
  max_damage_tank_id integer,
  max_damage integer,
  max_frags integer,
  max_frags_tank_id integer,
  trees_cut integer,
  CONSTRAINT account_info_statistics_max_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE account_info_statistics_max
  OWNER TO wotstatsadmins;
