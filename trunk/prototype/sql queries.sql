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
  CONSTRAINT account_info_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE info_common
  OWNER TO wotstatsadmins;
---
CREATE TABLE info_statistics_max
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
  CONSTRAINT account_info_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE info_statistics_max
  OWNER TO wotstatsadmins;
---
CREATE TABLE info_statistics_all
(
  account_id integer NOT NULL,
  battles int,
  wins int,
  losses integer,
  draws int,
  survived_battles int,
  base_xp int,
  xp int,
  tanking_factor numeric,
  frags int,
  spotted integer,
  shots int,
  hits int,
  hits_percents int,
  piercings int,
  explosion_hits int,
  no_damage_direct_hits_received int,
  damage_dealt int,
  damage_received int,
  direct_hits_received int,
  piercings_received int,
  explosion_hits_received int,
  capture_points int,
  dropped_capture_points int,
  battle_avg_xp int,
  avg_damage_blocked numeric,
  avg_damage_assisted numeric,
  avg_damage_assisted_track numeric,
  avg_damage_assisted_radio numeric,
  CONSTRAINT account_info_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE info_statistics_max
  OWNER TO wotstatsadmins;
---
  